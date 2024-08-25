###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The base UI element object, responsible for the overall management of each
## element, while BaseElementData and its derivatives handle element type-
## specific details, implementation, and drawing.
##
## Note that here data objects are often referred to as states. A data object
## is a state when it has a configured UIState instance. It can also exist
## without being a state.
class_name UIElement extends Resource

signal data_changed()
signal transform_queued()
signal transform_changed()
signal states_changed()
signal visibility_changed()

signal editor_selected()
signal editor_deselected()
signal editor_state_selected()

# TODO: Make this adjustible, probably. Possibly together with the "combined size" too.
const STATE_RENDERER_PADDING := 64.0

## The unique name of this element. User-facing and user-adjustible, can be
## used when generating the API on export.
@export var element_name: String = ""
## The anchor point for this element. Element's position is combined from this,
## global-facing relationship and the combined data's offset.
@export var anchor_point: Vector2 = Vector2.ZERO
## The visibility flag. Making an element invisible also hides all of its sub-
## elements.
@export var visible: bool = true

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
## The size that can be used to roughly estimate the element's area, accounting for
## every possible state. Used to safely space out state previews in the editor.
var _combined_size: Vector2 = Vector2.ZERO
## The map of names and active tweeners for all properties of this element.
var _property_tweener_map: Dictionary = {}

## The instance ID of the element group this element belongs to. This can be either
## the group of the owner canvas, or the group of one of the composite elements.
var _group_id: int = 0
## The selected flag for the editor.
var _selected: bool = false
## The selected state, default or variant, that must be edited.
var _selected_state: BaseElementData = null

## The safeguard flag that keeps track of transform queued requests. It's enough to
## signal it once until we receive a call to trigger transform_changed. Note, that
## it can be set out of canvas, which must be accounted for when elements are added.
var _transform_queued: bool = false


func _init(data_class: GDScript) -> void:
	element_name = data_class.get_default_name()
	
	# This is only going to work with custom types, but that's fine in this case.
	_data_class = data_class
	
	_active_data = _data_class.new()
	default_state = _data_class.new()
	# The order matters here. First we update it for states, then for the active data.
	default_state.property_changed.connect(_update_property_in_all_variant_states)
	default_state.property_changed.connect(_update_stateful_property)
	
	_update_combined_size()


# State management.

func _check_state_exists(state_type: int, state_name: String) -> BaseElementData:
	if state_type == StateType.STATE_DEFAULT:
		return default_state
	
	if state_type == StateType.STATE_CUSTOM:
		for state_data in variant_states:
			if state_data.state.state_type != StateType.STATE_CUSTOM:
				continue
			
			if state_data.state.state_name == state_name:
				return state_data
	else:
		for state_data in variant_states:
			if state_data.state.state_type == state_type:
				return state_data
	
	return null


func _create_state_nocheck(state_type: int, state_name: String) -> BaseElementData:
	var state_index := variant_states.size()
	var preview_spacing_size := get_state_preview_spacing()
	
	var state_data: BaseElementData = _data_class.new()
	state_data.state.setup(state_type, state_name)
	state_data.preview_offset = Vector2(
		preview_spacing_size.x,
		preview_spacing_size.y * state_index
	)

	variant_states.push_back(state_data)
	
	# The order matters here. First we update it for the state, then for the active data.
	state_data.property_changed.connect(_update_property_in_variant_state.bind(state_data))
	state_data.property_changed.connect(_update_stateful_property)
	state_data.state.state_activated.connect(_handle_activated_state.bind(state_data))
	state_data.state.state_deactivated.connect(_handle_deactivated_state.bind(state_data))
	
	_update_variant_state(state_data)
	_update_combined_size()
	states_changed.emit()
	
	return state_data


func create_state(state_type: int, state_name: String) -> BaseElementData:
	if state_type == StateType.STATE_DEFAULT:
		printerr("UIElement: Cannot create a variant state typed as default, use the implicit default_state instead.")
		return null
	
	# Normalize the state name.
	state_name = state_name.strip_edges()
	
	# Normalize the state type if the name matches one of the default ones.
	if state_type == StateType.STATE_CUSTOM:
		state_type = StateType.get_state_type_from_name(state_name)
	
	# Make sure the state is unique (only one per special type, unique name for the custom type).
	if _check_state_exists(state_type, state_name) != null:
		printerr("UIElement: Cannot create a variant state typed as %s (%s), only one state of this type and name is allowed." % [ StateType.get_state_name(state_type), state_name ])
		return null
	
	return _create_state_nocheck(state_type, state_name)


func ensure_state(state_type: int, state_name: String) -> void:
	# FIXME: States might exist but be in a different order, which breaks state previews.
	
	# We skip the checks like the ones in create_state() because this method should only
	# be called for a state that is already present on one of the elements. So it should
	# be valid already.
	
	if _check_state_exists(state_type, state_name) != null:
		return
	
	_create_state_nocheck(state_type, state_name)


func find_state(state_type: int, state_name: String) -> BaseElementData:
	return _check_state_exists(state_type, state_name)


func find_state_on_canvas(at_position: Vector2) -> BaseElementData:
	var default_rect := get_element_state_rect(default_state)
	if default_rect.has_point(at_position):
		return default_state
	
	for state_data in variant_states:
		var state_rect := get_element_state_rect(state_data)
		if state_rect.has_point(at_position):
			return state_data
	
	return null


func deactivate_all_states() -> void:
	for state_data in variant_states:
		state_data.state.set_active(false, true)
	
	for property_name in default_state.get_data_properties():
		var value: Variant = default_state.get(property_name)
		_active_data.set(property_name, value)
	
	_update_combined_size()
	data_changed.emit()
	queue_transform()


func _handle_activated_state(state_data: BaseElementData) -> void:
	# Only consider properties that this state can potentially affect.
	var state_properties := state_data.state.properties
	var affected_properties: PackedStringArray = PackedStringArray()
	
	for property_name in state_properties:
		var i := variant_states.size() - 1
		while i >= 0:
			# Check other states from the topmost.
			var other_state := variant_states[i]
			i -= 1
			
			# If we reach our just activated state, stop here and start the transition.
			if other_state == state_data:
				_transition_stateful_property(property_name, state_data, state_data.state_in_transition)
				affected_properties.push_back(property_name)
				break
			
			# If we reach another state before we reach our just activated one, there is nothing
			# to do, just break out of the loop.
			if other_state.state.is_active() && other_state.state.has_property(property_name):
				break
	
	if not affected_properties.is_empty():
		data_changed.emit()
		if affected_properties.has("size") || affected_properties.has("offset"):
			queue_transform()


func _handle_deactivated_state(state_data: BaseElementData) -> void:
	# Only consider properties that this state can potentially affect.
	var state_properties := state_data.state.properties
	var affected_properties: PackedStringArray = PackedStringArray()
	
	for property_name in state_properties:
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
			affected_properties.push_back(property_name)
	
	if not affected_properties.is_empty():
		data_changed.emit()
		if affected_properties.has("size") || affected_properties.has("offset"):
			queue_transform()


# Data management.

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
	if property_name == "size" || property_name == "offset":
		queue_transform()


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


func _update_property_in_variant_state(property_name: String, state_data: BaseElementData) -> void:
	if state_data.state.has_property(property_name):
		return
	
	var value: Variant = default_state.get(property_name)
	state_data.set(property_name, value)


func _update_property_in_all_variant_states(property_name: String) -> void:
	for i in variant_states.size():
		_update_property_in_variant_state(property_name, variant_states[i])


func _update_variant_state(state_data: BaseElementData) -> void:
	var all_properties := default_state.get_data_properties()
	for property_name in all_properties:
		_update_property_in_variant_state(property_name, state_data)


func get_active_data() -> BaseElementData:
	return _active_data


func get_default_state_data() -> BaseElementData:
	return default_state


func get_variant_state_data() -> Array[BaseElementData]:
	return variant_states.duplicate()


# Group metadata.

func get_group() -> UIElementGroup:
	if not is_instance_id_valid(_group_id):
		return null
	
	return instance_from_id(_group_id)


func has_group() -> bool:
	return is_instance_id_valid(_group_id)


func get_group_id() -> int:
	return _group_id


func set_group_id(instance_id: int) -> void:
	if not is_instance_id_valid(instance_id):
		return
	
	_group_id = instance_id


func clear_group_id() -> void:
	_group_id = 0


# Visibility.

func is_visible() -> bool:
	return visible


func set_visible(value: bool) -> void:
	if visible == value:
		return
	
	visible = value
	visibility_changed.emit()


# Selection.

func is_selected() -> bool:
	return _selected


func set_selected(value: bool) -> void:
	if _selected == value:
		return
	
	_selected = value
	
	if _selected:
		editor_selected.emit()
	else:
		editor_deselected.emit()


func get_selected_state_data() -> BaseElementData:
	if not _selected_state:
		return default_state
	
	return _selected_state


func set_selected_state(state_data: BaseElementData) -> void:
	_selected_state = state_data
	editor_state_selected.emit()


# Transform management.

func get_anchor_point() -> Vector2:
	return anchor_point


func set_anchor_point(value: Vector2) -> void:
	if anchor_point == value:
		return
	
	anchor_point = value
	queue_transform()


func adjust_anchor_point(delta: Vector2) -> void:
	set_anchor_point(anchor_point + delta)


func queue_transform() -> void:
	if _transform_queued:
		return
	
	_transform_queued = true
	transform_queued.emit()


func is_transform_queued() -> bool:
	return _transform_queued


func notify_transform_changed() -> void:
	var preview_spacing_size := get_state_preview_spacing()
	
	for i in variant_states.size():
		var state_data := variant_states[i]
		state_data.preview_offset = Vector2(
			preview_spacing_size.x,
			preview_spacing_size.y * i
		)
	
	transform_changed.emit()
	_transform_queued = false


func get_element_state_rect(state_data: BaseElementData) -> Rect2:
	var state_rect := Rect2()
	state_rect.position = anchor_point + state_data.offset + state_data.preview_offset
	state_rect.size = state_data.size
	
	return state_rect


func get_active_state_rect() -> Rect2:
	return get_element_state_rect(_active_data)


func get_default_state_rect() -> Rect2:
	return get_element_state_rect(default_state)


func get_selected_rect() -> Rect2:
	if not _selected_state:
		return get_element_state_rect(default_state)
	
	return get_element_state_rect(_selected_state)


func _update_combined_size() -> void:
	var base_size := default_state.size
	
	var i := variant_states.size() - 1
	while i >= 0:
		var state_data := variant_states[i]
		if state_data.state.has_property("size"):
			base_size = base_size.max(state_data.size)
		
		i -= 1
	
	_combined_size = base_size


func get_state_preview_spacing() -> Vector2:
	var owner := get_group().get_owner()
	if owner is UIElement:
		return owner.get_state_preview_spacing()
	
	return _combined_size + Vector2(STATE_RENDERER_PADDING, STATE_RENDERER_PADDING)


func has_point(at_position: Vector2) -> bool:
	var default_rect := get_element_state_rect(default_state)
	if default_rect.has_point(at_position):
		return true
	
	for state_data in variant_states:
		var state_rect := get_element_state_rect(state_data)
		if state_rect.has_point(at_position):
			return true
	
	return false


func is_inside_area(area: Rect2) -> bool:
	# For area selection state previews are ignored, because there doesn't seem
	# to be any logical behavior for this case.
	
	var default_rect := get_element_state_rect(default_state)
	return area.encloses(default_rect)
