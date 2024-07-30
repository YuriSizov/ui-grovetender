###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PropertyEditor extends MarginContainer

@warning_ignore("unused_signal") # Used in extending classes.
signal editing_started()
signal editing_stopped()
signal edited_property_changed()

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


func _gui_input(event: InputEvent) -> void:
	handle_input(event)


# Metadata.

func connect_to_property(_element: BaseUIElement, _name: String, _setter: Callable) -> void:
	if element == _element:
		return
	
	if element:
		element.property_changed.disconnect(_handle_property_changes)
		element.properties_changed.disconnect(_check_visibility_condition)
	
	element = _element
	prop_name = _name
	prop_setter = _setter
	
	if element:
		element.property_changed.connect(_handle_property_changes)
		element.properties_changed.connect(_check_visibility_condition)
	
	edited_property_changed.emit()


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

func get_editor_label() -> String:
	if not label.is_empty():
		return label
	return prop_name.capitalize()


# Implementation.

## Handles incoming input events. Extending classes implement this method.
func handle_input(_event: InputEvent) -> void:
	pass


## Called when one of the reference element properties changes. Extending classes implement this
## method.
func _handle_property_changes(_property_name: String) -> void:
	pass


## Called when the editing state must be exited due to external circumstances, e.g. a click outside.
## Extending classes can implement and/or call this method.
func _cancel_editing() -> void:
	editing_stopped.emit()
