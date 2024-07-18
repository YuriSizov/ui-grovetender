###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertyEditor extends RefCounted

signal mouse_entered()
signal mouse_exited()

## The type of the property editor.
var type: int = PropertyEditorType.PROPERTY_TOGGLE

## The object that owns the property.
var object: Object = null
## The name of the property in the object.
var name: String = "":
	set = set_name
## The setter function that is triggered on changes.
var setter: Callable = Callable()

## The custom label for the property. If left empty, the property name is humanized and used as a label.
var label: String = "":
	set = set_label
var _label_text_buffer: TextLine = TextLine.new()

## The Control node that is responsible for managing and rendering this property editor.
var owner_control: Control = null
## The type used for fetching theme properties in sizing and rendering.
var theme_type: StringName = &"PropertyEditor":
	set = set_theme_type

var _hovering: bool = false


func _init(prop_type: int, prop_object: Object, prop_name: String, prop_setter: Callable) -> void:
	type = prop_type
	object = prop_object
	name = prop_name
	setter = prop_setter


# Metadata.

func set_name(value: String) -> void:
	if name == value:
		return
	name = value
	
	if label.is_empty():
		_shape_text()


func set_label(value: String) -> void:
	if label == value:
		return
	label = value
	_shape_text()


func set_theme_type(value: StringName) -> void:
	if theme_type == value:
		return
	theme_type = value
	_shape_text()


func _shape_text() -> void:
	var editor_label := _get_editor_label()
	var font := get_theme_font("")
	var font_size := get_theme_font_size("font_size")
	
	_label_text_buffer.clear()
	_label_text_buffer.add_string(editor_label, font, font_size)


# Helpers.

func _get_editor_label() -> String:
	if not label.is_empty():
		return label
	return name.capitalize()


# Interactions.

## Returns whether this property editor is being currently hovered.
func is_hovering() -> bool:
	return _hovering


## Marks, or unmarks, this property editor as being currently hovered.
func set_hovering(value: bool) -> void:
	if _hovering == value:
		return
	_hovering = value
	
	if _hovering:
		mouse_entered.emit()
	else:
		mouse_exited.emit()


# Theming.

func get_theme_item(data_type: Theme.DataType, item_name: String) -> Variant:
	var project_theme := ThemeDB.get_project_theme()
	var current_type := theme_type
	
	# Since these classes are not UI nodes, we don't expect to override any default styles. So we
	# only check the chain of type variations here.
	while not current_type.is_empty():
		if project_theme.has_theme_item(data_type, item_name, current_type):
			return project_theme.get_theme_item(data_type, item_name, current_type)
		
		current_type = project_theme.get_type_variation_base(current_type)
	
	return project_theme.get_theme_item(data_type, "", "")


func get_theme_color(color_name: String) -> Color:
	return get_theme_item(Theme.DATA_TYPE_COLOR, color_name)


func get_theme_constant(constant_name: String) -> int:
	return get_theme_item(Theme.DATA_TYPE_CONSTANT, constant_name)


func get_theme_font(font_name: String) -> Font:
	return get_theme_item(Theme.DATA_TYPE_FONT, font_name)


func get_theme_font_size(font_size_name: String) -> int:
	return get_theme_item(Theme.DATA_TYPE_FONT_SIZE, font_size_name)


func get_theme_icon(icon_name: String) -> Texture2D:
	return get_theme_item(Theme.DATA_TYPE_ICON, icon_name)


func get_theme_stylebox(style_name: String) -> StyleBox:
	return get_theme_item(Theme.DATA_TYPE_STYLEBOX, style_name)


# Implementation.

## Returns the size required by this editor. Extending classes implement this method.
func get_size() -> Vector2:
	return Vector2.ZERO


## Handles incoming input events. Extending classes implement this method.
func handle_input(_event: InputEvent) -> void:
	pass


## Renders the editor in the given Control node and at the given position. Extending classes implement
## this method.
func render(_target_position: Vector2) -> void:
	pass
