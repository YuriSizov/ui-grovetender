###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PropertyEditor extends MarginContainer

signal before_property_connected()
signal property_connected()
signal property_changed()

## The element object that owns the property.
var element: BaseUIElement = null
## The name of the property in the object.
var prop_name: String = ""
## The setter function that is triggered on changes.
var prop_setter: Callable = Callable()

## The custom label for the property. If left empty, the property name is humanized and used as
## a label.
var label: String = ""
## The callable that is called to check if the editor should be visible. If it's empty/invalid,
## the editor is always visible.
var _visibility_condition: Callable = Callable()

var _editing_active: bool = false


func _init() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	theme_type_variation = &"PropertyEditor"


func _enter_tree() -> void:
	_check_visibility_condition()


func _ready() -> void:
	_update_theme()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()
	
	# This is so hacky, but it allows us to use one theme definition for all elements of a complex
	# scene, with in-editor preview, without polluting saved scenes.
	elif what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_theme()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_update_theme()


## Called when it's a proper time to update visuals according to theme changes.
func _update_theme() -> void:
	pass


## Called when the theme overrides need to be reset, e.g. before the scene is saved.
func _clear_theme() -> void:
	pass


# Metadata.

func connect_to_property(_element: BaseUIElement, _name: String, _setter: Callable) -> void:
	if element == _element:
		return
	
	before_property_connected.emit()
	
	if element:
		element.property_changed.disconnect(_check_property_changes)
		element.properties_changed.disconnect(_check_visibility_condition)
		element.active_states_changed.disconnect(property_changed.emit)
	
	element = _element
	prop_name = _name
	prop_setter = _setter
	
	if element:
		element.property_changed.connect(_check_property_changes)
		element.properties_changed.connect(_check_visibility_condition)
		element.active_states_changed.connect(property_changed.emit)
	
	property_connected.emit()


func has_property() -> bool:
	return element && not prop_name.is_empty()


func get_property_value() -> Variant:
	if not element || prop_name.is_empty():
		return null
	
	return element.get_stateful_property(prop_name)


func set_property_value(value: Variant) -> void:
	if not element || not prop_setter.is_valid():
		return
	
	if not element.has_active_states():
		prop_setter.call(value)
		return
	
	var active_state := element.get_active_state()
	var state_setter := Callable(active_state.overridden_element, prop_setter.get_method())
	active_state.override_property(prop_name)
	state_setter.call(value)


func _check_property_changes(property_name: String) -> void:
	if has_property() && property_name == prop_name:
		property_changed.emit()


func set_visibility_condition(callable: Callable) -> void:
	if callable.is_valid():
		_visibility_condition = callable
	else:
		_visibility_condition = Callable()


func _check_visibility_condition() -> void:
	if not _visibility_condition.is_valid():
		visible = true
		return
	
	visible = _visibility_condition.call()


# Helpers.

func _get_editor_label() -> String:
	if not label.is_empty():
		return label
	return prop_name.capitalize()


func _start_editing() -> void:
	if _editing_active:
		return
	
	_editing_active = true


func _stop_editing() -> void:
	if not _editing_active:
		return
	
	_editing_active = false


# Implementation.

## Called when the editing state must be exited due to external circumstances, e.g. a click outside.
## Extending classes can implement and/or call this method.
func _cancel_editing() -> void:
	_stop_editing()
