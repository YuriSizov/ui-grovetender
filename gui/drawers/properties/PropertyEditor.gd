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

## The element that is being edited.
var _element: UIElement = null
## The element data object that owns the property.
var _element_data: BaseElementData = null
## The name of the property in the data object.
var _prop_name: String = ""
## The setter function that is triggered on changes.
var _prop_setter: Callable = Callable()

## The custom label for the property. If left empty, the property name is humanized and used as
## a label.
var label: String = ""
## The callable that is called to check if the editor should be visible. If it's empty/invalid,
## the editor is always visible.
var _visibility_condition: Callable = Callable()

var _editing_active: bool = false


# Static methods.

## The private factory method that instantiates the scene associated with this type. Extending
## classes must implement a public factory method for their scene and type.
static func _create(element: UIElement, element_data: BaseElementData, scene: PackedScene) -> PropertyEditor:
	var instance: PropertyEditor = scene.instantiate()
	instance.connect_to_state(element, element_data)
	
	return instance


# Instance methods.

func _init() -> void:
	name = &"PropertyEditor"
	theme_type_variation = &"PropertyEditor"
	mouse_filter = MOUSE_FILTER_PASS


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

func connect_to_state(element: UIElement, element_data: BaseElementData) -> void:
	if _element == element && _element_data == element_data:
		return
	
	if _element_data:
		_element_data.property_changed.disconnect(_check_property_changes)
		_element_data.properties_changed.disconnect(_check_visibility_condition)
	
	_element = element
	_element_data = element_data
	
	if _element_data:
		_element_data.property_changed.connect(_check_property_changes)
		_element_data.properties_changed.connect(_check_visibility_condition)


func connect_to_property(prop_name: String, prop_setter: Callable) -> void:
	if _prop_name == prop_name && _prop_setter == prop_setter:
		return
	
	before_property_connected.emit()
	
	_prop_name = prop_name
	_prop_setter = prop_setter
	
	property_connected.emit()


func has_property() -> bool:
	return _element_data && not _prop_name.is_empty()


func get_property_value() -> Variant:
	if not _element_data || _prop_name.is_empty():
		return null
	
	return _element_data.get(_prop_name)


func set_property_value(value: Variant) -> void:
	if not _element_data || not _prop_setter.is_valid():
		return
	
	_prop_setter.call(value, true)


func revert_property_value() -> void:
	if not _element_data || not _prop_setter.is_valid():
		return
	
	# HACK: This is a very ad-hoc solution, and should probably be reworked.
	var data_class: GDScript = _element_data.get_script()
	var default_data: BaseElementData = data_class.new()
	var value: Variant = default_data.get(_prop_name)
	_prop_setter.call(value, false)


func _check_property_changes(property_name: String) -> void:
	if has_property() && property_name == _prop_name:
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
	return _prop_name.capitalize()


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
