###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name UIElement extends Resource

signal anchor_point_changed()
signal data_changed()
signal states_changed()

## The unique name of this element. User-facing and user-adjustible, can be
## used when generating the API on export.
@export var element_name: String = "Element"
## The anchor point for this element. Element's position is combined from this,
## global-facing relationship and the combined data's offset.
@export var anchor_point: Vector2 = Vector2.ZERO

# State data objects of this element. A data object is responsible for all
# unique properties and features each element type has.

## The default state data. This is the final fallback data object when resolving
## how the element should render. It is always enabled.
@export var default_state: BaseElementData = null
## The collection of variant states applied on top of the default one, overridding
## some or all of its properties. Multiple states can be enabled at the same time.
@export var variant_states: Array[BaseElementData] = []

# Runtime properties.

## The script class used to initialize data objects. Either BaseElementData or one
## of its derivatives.
var _data_class: GDScript = null
## The combined data object that contains all properties of this element, resolved
## to account for every enabled/active state, in their current transition state.
var _active_data: BaseElementData = null
## The collection of combined data objects which contain all properties of this element,
## resolved to account for each individual state, regardless of their activity flag.
var _combined_state_data: Array[BaseElementData] = []
## The size that can be used to roughly estimate the element's area, accounting for
## every possible state. Used to safely space out state previews in the editor.
var _combined_size: Vector2 = Vector2.ZERO
## The map of names and active tweeners for all properties of this element.
var _property_tweener_map: Dictionary = {}


func _init(data_class: GDScript) -> void:
	# This is only going to work with custom types, but that's fine in this case.
	_data_class = data_class
	
	_active_data = _data_class.new()
	default_state = _data_class.new()
	default_state.property_changed.connect(_update_stateful_property)
	default_state.property_changed.connect(_update_all_combined_states_property)


# State and data management.

func _update_stateful_property(property_name: String) -> void:
	_abort_transition_stateful_property(property_name)
	
	var value: Variant = default_state.get(property_name)
	
	var i := variant_states.size() - 1
	while i >= 0:
		var state_data := variant_states[i]
		if state_data.state.is_active() && state_data.state.has_property(property_name):
			value = state_data.get(property_name)
			break
		
		i -= 1
	
	_active_data.set(property_name, value)
	
	if property_name == "size":
		_update_combined_size()
	
	data_changed.emit()


func _transition_stateful_property(property_name: String, state_data: BaseElementData, transition: UITransition) -> void:
	_abort_transition_stateful_property(property_name)
	
	var value: Variant = state_data.get(property_name)
	var transition_duration := transition.duration
	
	if transition_duration <= 0.0: # No transition, set immediately.
		_active_data.set(property_name, value)
		return
	
	var scene_tree: SceneTree = Engine.get_main_loop()
	var tweener := scene_tree.create_tween()
	tweener\
		.tween_property(_active_data, property_name, value, transition_duration)\
		.set_trans(transition.curve)\
		.set_ease(transition.easing)
	
	_property_tweener_map[property_name] = tweener


func _abort_transition_stateful_property(property_name) -> void:
	if _property_tweener_map.has(property_name):
		var tweener: Tween = _property_tweener_map[property_name]
		tweener.kill()
		_property_tweener_map.erase(property_name)


func _update_combined_state_property(property_name: String, state_data: BaseElementData, combined_data: BaseElementData) -> void:
	var value: Variant = default_state.get(property_name)
	if state_data.state.has_property(property_name):
		value = state_data.get(property_name)
	
	combined_data.set(property_name, value)


func _update_all_combined_states_property(property_name: String) -> void:
	for i in variant_states.size():
		_update_combined_state_property(property_name, variant_states[i], _combined_state_data[i])


func _update_combined_state(state_data: BaseElementData, combined_data: BaseElementData) -> void:
	var all_properties := default_state.get_data_properties()
	for property_name in all_properties:
		_update_combined_state_property(property_name, state_data, combined_data)


func create_state(state_type: int, state_name: String) -> BaseElementData:
	# TODO: Ensure that the name is unique.
	
	var state_data: BaseElementData = _data_class.new()
	state_data.state.setup(state_type, state_name)
	
	var combined_data: BaseElementData = _data_class.new()
	state_data.state.setup(state_type, state_name)
	
	state_data.property_changed.connect(_update_stateful_property)
	state_data.property_changed.connect(_update_combined_state_property.bind(state_data, combined_data))
	state_data.state.state_activated.connect(_handle_activated_state.bind(state_data))
	state_data.state.state_deactivated.connect(_handle_deactivated_state.bind(state_data))
	
	variant_states.push_back(state_data)
	_combined_state_data.push_back(combined_data)
	_update_combined_state(state_data, combined_data)
	_update_combined_size()
	states_changed.emit()
	
	return state_data


func _handle_activated_state(state_data: BaseElementData) -> void:
	# Only consider properties that this state can potentially affect.
	var affected_properties := state_data.state.properties
	for property_name in affected_properties:
		var i := variant_states.size() - 1
		while i >= 0:
			# Check other states from the topmost.
			var other_state := variant_states[i]
			i -= 1
			
			# If we reach our just activated state, stop here and start the transition.
			if other_state == state_data:
				_transition_stateful_property(property_name, state_data, state_data.state_in_transition)
				break
			
			# If we reach another state before we reach our just activated one, there is nothing
			# to do, just break out of the loop.
			if other_state.state.is_active() && other_state.state.has_property(property_name):
				break
	
	data_changed.emit()


func _handle_deactivated_state(state_data: BaseElementData) -> void:
	# Only consider properties that this state can potentially affect.
	var affected_properties := state_data.state.properties
	for property_name in affected_properties:
		var affected := false
		var fallback_state := default_state
		
		var i := variant_states.size() - 1
		while i >= 0:
			# Check other states from the topmost.
			var other_state := variant_states[i]
			i -= 1
			
			# If we reach our just deactivated state, start looking for the next available value
			# in following states.
			if other_state == state_data:
				affected = true
				continue
			
			# If we reach another state at any point, we break out of the loop here.
			if other_state.state.is_active() && other_state.state.has_property(property_name):
				# If we are looking for the suitable fallback state, track it to start the transition.
				if affected:
					fallback_state = other_state
				break
		
		if affected:
			_transition_stateful_property(property_name, fallback_state, state_data.state_out_transition)
	
	data_changed.emit()


func get_active_data() -> BaseElementData:
	return _active_data


func get_default_state_data() -> BaseElementData:
	return default_state


func get_combined_state_data() -> Array[BaseElementData]:
	return _combined_state_data.duplicate()


# Positioning and anchors.

func get_anchor_point() -> Vector2:
	return anchor_point


func set_anchor_point(value: Vector2) -> void:
	if anchor_point == value:
		return
	
	anchor_point = value
	anchor_point_changed.emit()


func _update_combined_size() -> void:
	var base_size := default_state.size
	
	var i := variant_states.size() - 1
	while i >= 0:
		var state_data := variant_states[i]
		if state_data.state.has_property("size"):
			base_size = base_size.max(state_data.size)
		
		i -= 1
	
	_combined_size = base_size


func get_combined_size() -> Vector2:
	return _combined_size
