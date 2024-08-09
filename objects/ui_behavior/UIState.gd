###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI states. Encapsulates shared logic and universal data members.
class_name UIState extends Resource

signal state_activated()
signal state_deactivated()

## The type of the state. Pre-defined states imply behavior that must be implemented on export.
@export var state_type: int = StateType.STATE_CUSTOM
## The unique name of the state. Used to distinguish it from others of a similar type, and when
## generating API on export.
@export var state_name: String = StateType.get_state_name(state_type)
## The flag that locks this state. Locked states cannot be removed or renamed because they are
## required by the current preset.
@export var locked: bool = false

## The element that this state extends and overrides.
@export var overridden_element: BaseUIElement = null
## The collection of names for properties which are overridden for this state, deviating from the
## default state.
@export var overridden_properties: PackedStringArray = PackedStringArray()

## The flag that determines whether the state is currently active. Runtime only.
var _active: bool = false


# Element management.

func connect_to_element(element: BaseUIElement) -> void:
	# I think this is the best way to make a new instance of the same type, since we cannot
	# pass the type itself as an argument.
	var class_script: GDScript = element.get_script()
	overridden_element = class_script.new()


# State management.

func activate() -> void:
	if _active:
		return
	
	_active = true
	state_activated.emit()


func deactivate() -> void:
	if not _active:
		return
	
	_active = false
	state_deactivated.emit()


func is_active() -> bool:
	return _active


# Override management.

func override_property(property_name: String) -> void:
	pass


func clear_property(property_name: String) -> void:
	pass


func is_property_overridden(property_name: String) -> bool:
	return false
