###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name BaseElementData extends Resource

signal property_changed(property_name: String)
signal properties_changed()

# Stealing this unused property usage flag for our needs. Let's hope it is
# never reclaimed by the engine.
const PROPERTY_USAGE_ELEMENT_DATA := PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE

# State data.

## The instance of the state data object. Contains details about stateful
## property overrides and the activity flag.
@export var state: UIState = UIState.new()
## The instance of the transition object used when activating the state.
@export var state_in_transition: UITransition = UITransition.new()
## The instance of the transition object used when deactivating the state.
@export var state_out_transition: UITransition = UITransition.new()

# Common element data.

## The position relative to the owner element's anchor point. Used to do
## smaller adjustments for various states and animations.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var offset: Vector2 = Vector2.ZERO
## The size of the owner element.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var size: Vector2 = Vector2.ZERO

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var debug_color: Color = Color.WHITE


func draw(proxy: Control) -> void:
	proxy.draw_rect(Rect2(offset, size), debug_color)


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


func set_debug_color(value: Color) -> void:
	if debug_color == value:
		return
	
	debug_color = value
	_notify_properties_changed([ "debug_color" ])
