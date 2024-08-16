###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The state sub-object that contains state-specific data of the parent element
## data object. It is owned by a BaseElementData instance.
class_name UIState extends Resource

signal state_activated()
signal state_deactivated()

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
@export var active: bool = false
## The collection of properties this state overrides. Only used by variant
## states.
@export var properties: PackedStringArray = PackedStringArray()


# Initialization.

func setup(type: int, unique_name: String) -> void:
	state_type = type
	state_name = unique_name


# Activity management.

func is_active() -> bool:
	return active


func set_active(value: bool) -> void:
	if active == value:
		return
	
	active = value
	
	if active:
		state_activated.emit()
	else:
		state_deactivated.emit()


# Property management.

func override_property(property_name: String) -> void:
	if properties.has(property_name):
		return
	
	properties.push_back(property_name)


func clear_property(property_name: String) -> void:
	var property_index := properties.find(property_name)
	if property_index < 0:
		return
	
	properties.remove_at(property_index)


func has_property(property_name: String) -> bool:
	return properties.has(property_name)

