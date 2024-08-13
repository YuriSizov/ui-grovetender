###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name BaseElementData extends Resource

signal property_changed(property_name: String)
signal properties_changed()

signal state_activated()
signal state_deactivated()

# Stealing this unused property usage flag for our needs. Let's hope it is
# never reclaimed by the engine.
const PROPERTY_USAGE_ELEMENT_DATA := PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE

# State data.

## The type of state this data object represents. This can be ignored when
## the data object is used for other purposes. Defaults to default, which
## is an always-on, mandatory state for every element.
@export var state_type: int = StateType.STATE_DEFAULT
## The unique name for the state this object represents. Used to distinguish
## between multiple states of the same type, mainly custom states.
@export var state_name: String = StateType.get_state_name(StateType.STATE_DEFAULT)
## The state activitity flag. Only used by variant states. The default state
## is always on, so this flag defaults to false to require variant states
## to be explicitly enabled.
@export var state_active: bool = false
## The collection of properties this state overrides. Only used by variant
## states.
@export var state_properties: PackedStringArray = PackedStringArray()

# Common element data.

## The position relative to the owner element's anchor point. Used to do
## smaller adjustments for various states and animations.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var offset: Vector2 = Vector2.ZERO
## The size of the owner element.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var size: Vector2 = Vector2.ZERO


func draw(proxy: Control) -> void:
	proxy.draw_rect(Rect2(offset, size), Color.BLUE_VIOLET)


# Property management.

func _notify_properties_changed(property_names: Array[String]) -> void:
	for property_name in property_names:
		property_changed.emit(property_name)
	
	properties_changed.emit()


func get_data_properties() -> PackedStringArray:
	var data_properties := PackedStringArray()
	var all_properties := get_property_list()
	
	for property_info: Dictionary in all_properties:
		if property_info.usage & PROPERTY_USAGE_ELEMENT_DATA:
			data_properties.push_back(property_info.name)
	
	return data_properties


# State management.

func state_setup(type: int, unique_name: String) -> void:
	state_type = type
	state_name = unique_name


func state_set_active(value: bool) -> void:
	if state_active == value:
		return
	
	state_active = value
	
	if state_active:
		state_activated.emit()
	else:
		state_deactivated.emit()


func state_override_property(property_name: String) -> void:
	if state_properties.has(property_name):
		return
	
	state_properties.push_back(property_name)


func state_clear_property(property_name: String) -> void:
	var property_index := state_properties.find(property_name)
	if property_index < 0:
		return
	
	state_properties.remove_at(property_index)


func state_has_property(property_name: String) -> bool:
	return state_properties.has(property_name)


# Properties.

func set_offset(value: Vector2) -> void:
	if offset == value:
		return
	
	offset = value
	_notify_properties_changed([ "offset" ])


func set_size(value: Vector2) -> void:
	if size == value:
		return
	
	size = value
	_notify_properties_changed([ "size" ])
