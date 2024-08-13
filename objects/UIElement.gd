###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name UIElement extends Resource

signal anchor_point_changed()
signal data_changed()

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

## The instance ID of the proxy control node.
var _control_id: int = 0
## The script class used to initialize data objects. Either BaseElementData or one
## of its derivatives.
var _data_class: GDScript = null
## The combined data object that contains all properties of this element, resolved
## to account for every enabled/active state.
var _data: BaseElementData = null


func _init(data_class: GDScript) -> void:
	# This is only going to work with custom types, but that's fine in this case.
	_data_class = data_class
	
	_data = _data_class.new()
	default_state = _data_class.new()
	default_state.property_changed.connect(_update_stateful_property)


# State and data management.

func _resolve_stateful_property(property_name: String) -> void:
	var value: Variant = default_state.get(property_name)
	
	var i := variant_states.size() - 1
	while i >= 0:
		var state_data := variant_states[i]
		if state_data.state_active && state_data.state_has_property(property_name):
			value = state_data.get(property_name)
			break
		
		i -= 1
	
	_data.set(property_name, value)


func _update_stateful_property(property_name: String) -> void:
	_resolve_stateful_property(property_name)
	data_changed.emit()


func _update_stateful_data() -> void:
	var data_properties := default_state.get_data_properties()
	for property_name in data_properties:
		_resolve_stateful_property(property_name)
	
	data_changed.emit()


func create_state(state_type: int, state_name: String) -> BaseElementData:
	# TODO: Ensure that the name is unique.
	
	var state_data: BaseElementData = _data_class.new()
	state_data.state_setup(state_type, state_name)
	state_data.property_changed.connect(_update_stateful_property)
	state_data.state_activated.connect(_update_stateful_data)
	state_data.state_deactivated.connect(_update_stateful_data)
	
	variant_states.push_back(state_data)
	return state_data


# Control proxy management.

func get_control() -> ElementProxy:
	if not is_instance_id_valid(_control_id):
		return null
	
	return instance_from_id(_control_id)


func set_control_id(instance_id: int) -> void:
	if is_instance_id_valid(instance_id):
		_control_id = instance_id
	else:
		_control_id = 0


func clear_control_id() -> void:
	_control_id = 0


func draw_element() -> void:
	var control := get_control()
	if not control || not _data:
		return
	
	_data.draw(control)


# Positioning and anchors.

func get_anchor_point() -> Vector2:
	return anchor_point


func set_anchor_point(value: Vector2) -> void:
	if anchor_point == value:
		return
	
	anchor_point = value
	anchor_point_changed.emit()


func get_local_rect() -> Rect2:
	if not _data:
		return Rect2()
	
	var local_rect := Rect2()
	local_rect.position = _data.offset
	local_rect.size = _data.size
	
	return local_rect
