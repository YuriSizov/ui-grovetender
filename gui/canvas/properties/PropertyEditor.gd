###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertyEditor extends Control

@warning_ignore("unused_signal") # Used in extending classes.
signal editing_started()
signal editing_stopped()

## The object that owns the property.
var object: Object = null
## The name of the property in the object.
var prop_name: String = "":
	set = set_prop_name
## The setter function that is triggered on changes.
var prop_setter: Callable = Callable()

## The custom label for the property. If left empty, the property name is humanized and used as a label.
var label: String = "":
	set = set_label
var _label_text_buffer: TextLine = TextLine.new()

var _hovering: bool = false


func _init(_object: Object, _name: String, _setter: Callable) -> void:
	object = _object
	prop_name = _name
	prop_setter = _setter
	
	mouse_filter = MOUSE_FILTER_PASS
	theme_type_variation = &"PropertyEditor"
	
	mouse_entered.connect(func() -> void:
		_hovering = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovering = false
		queue_redraw()
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_shape_text()


func _get_minimum_size() -> Vector2:
	var minimum_size := Vector2(
		get_theme_constant("minimum_size_x"),
		get_theme_constant("minimum_size_y")
	)
	
	return minimum_size


# Metadata.

func set_prop_name(value: String) -> void:
	if prop_name == value:
		return
	prop_name = value
	
	if label.is_empty():
		_shape_text()


func set_label(value: String) -> void:
	if label == value:
		return
	label = value
	_shape_text()


func _shape_text() -> void:
	var editor_label := _get_editor_label()
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	
	_label_text_buffer.clear()
	_label_text_buffer.add_string(editor_label, font, font_size)
	
	update_minimum_size()
	queue_redraw()


# Helpers.

func _get_editor_label() -> String:
	if not label.is_empty():
		return label
	return prop_name.capitalize()


# Interactions.

## Returns whether this property editor is being currently hovered.
func is_hovering() -> bool:
	return _hovering


# Implementation.

## Called when the editing state must be exited due to external circumstances, e.g. a click outside.
func _cancel_editing() -> void:
	editing_stopped.emit()


## Handles incoming input events. Extending classes implement this method.
func handle_input(_event: InputEvent) -> void:
	pass
