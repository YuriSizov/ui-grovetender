###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI states. Encapsulates shared logic and universal data members.
class_name UIState extends Resource

signal state_activated()
signal state_deactivated()
signal property_overridden(property_name: String)
signal property_cleared(property_name: String)
signal property_changed(property_name: String)

## The type of the state. Pre-defined states imply behavior that must be implemented on export.
@export var state_type: int = StateType.STATE_CUSTOM
## The unique name of the state. Used to distinguish it from others of a similar type, and when
## generating API on export.
@export var state_name: String = StateType.get_state_name(state_type)
## The flag that locks this state. Locked states cannot be removed or renamed because they are
## required by the current preset.
@export var locked: bool = false

## The collection of names for properties which are overridden for this state, deviating from the
## default state.
@export var overridden_properties: PackedStringArray = PackedStringArray()
## The element instance containing overridden property values. For properties not present in
## overridden_properties values should be ignored.
@export var overridden_element: BaseUIElement = null

## The instance ID of the element that this state belongs to. Runtime only.
var _base_element_id: int = 0
## The flag that determines whether the state is currently active. Runtime only.
var _active: bool = false


# Element management.

func connect_to_element(element: BaseUIElement) -> void:
	_base_element_id = element.get_instance_id()
	
	# I think this is the best way to make a new instance of the same type, since we cannot
	# pass the type itself as an argument.
	var class_script: GDScript = element.get_script()
	overridden_element = class_script.new()
	overridden_element.property_changed.connect(property_changed.emit)


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
	if overridden_properties.has(property_name):
		return
	
	overridden_properties.push_back(property_name)
	property_overridden.emit(property_name)


func clear_property(property_name: String) -> void:
	var property_index := overridden_properties.find(property_name)
	if property_index < 0:
		return
	
	overridden_properties.remove_at(property_index)
	property_cleared.emit(property_name)


func is_property_overridden(property_name: String) -> bool:
	return overridden_properties.has(property_name)
