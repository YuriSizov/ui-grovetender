###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name FontFilePropertyEditor extends ValuePropertyEditor

@onready var _file_button: Button = %FileButton
@onready var _font_name_label: Label = %FontName
@onready var _file_dialog: FileDialog = %FileDialog

var _button_text_buffer: TextLine = TextLine.new()
var _font_resource_getter: Callable = Callable()


func _init() -> void:
	super()
	theme_type_variation = &"FontFilePropertyEditor"


func _ready() -> void:
	super()
	
	_update_font_name()
	_update_text_buffer()
	
	_file_button.pressed.connect(_show_dialog)
	_file_button.draw.connect(_draw_file_button)
	_file_button.focus_entered.connect(_start_editing)
	_file_button.focus_exited.connect(_stop_editing)
	
	_file_dialog.file_selected.connect(_select_font)


func _update_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	_file_button.begin_bulk_theme_override()
	
	_file_button.add_theme_stylebox_override("normal", get_theme_stylebox("button_normal"))
	_file_button.add_theme_stylebox_override("hover", get_theme_stylebox("button_hover"))
	_file_button.add_theme_stylebox_override("pressed", get_theme_stylebox("button_pressed"))
	_file_button.add_theme_font_size_override("font_size", get_theme_font_size("button_font_size"))
	
	# Set a transparent color for the font because we only use the built-in label for sizing.
	_file_button.add_theme_color_override("font_color", get_theme_color("button_font_clear_color"))
	_file_button.add_theme_color_override("font_hover_color", get_theme_color("button_font_clear_color"))
	_file_button.add_theme_color_override("font_pressed_color", get_theme_color("button_font_clear_color"))
	
	_file_button.end_bulk_theme_override()
	
	_font_name_label.begin_bulk_theme_override()
	_font_name_label.add_theme_font_override("font", get_theme_font("font"))
	_font_name_label.add_theme_font_size_override("font_size", get_theme_font_size("button_font_size"))
	_font_name_label.add_theme_color_override("font_color", get_theme_color("button_font_color"))
	_font_name_label.add_theme_color_override("font_shadow_color", get_theme_color("button_font_shadow_color"))
	_font_name_label.add_theme_constant_override("shadow_offset_x", get_theme_constant("button_font_shadow_offset_x"))
	_font_name_label.add_theme_constant_override("shadow_offset_y", get_theme_constant("button_font_shadow_offset_y"))
	_font_name_label.end_bulk_theme_override()


func _clear_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	_file_button.begin_bulk_theme_override()
	_file_button.remove_theme_stylebox_override("normal")
	_file_button.remove_theme_stylebox_override("hover")
	_file_button.remove_theme_stylebox_override("pressed")
	_file_button.remove_theme_font_size_override("font_size")
	_file_button.remove_theme_color_override("font_color")
	_file_button.remove_theme_color_override("font_hover_color")
	_file_button.remove_theme_color_override("font_pressed_color")
	_file_button.end_bulk_theme_override()
	
	_font_name_label.begin_bulk_theme_override()
	_font_name_label.remove_theme_font_override("font")
	_font_name_label.remove_theme_font_size_override("font_size")
	_font_name_label.remove_theme_color_override("font_color")
	_font_name_label.remove_theme_color_override("font_shadow_color")
	_font_name_label.remove_theme_constant_override("shadow_offset_x")
	_font_name_label.remove_theme_constant_override("shadow_offset_y")
	_font_name_label.end_bulk_theme_override()


# This is just a hack to have a label with a shadow on a regular button. Probably should
# be reworked into a custom button component. See also button_font_clear_color.
func _draw_file_button() -> void:
	var label_color := get_theme_color("button_font_color")
	var label_shadow_color := get_theme_color("button_font_shadow_color")
	var label_shadow_offset := Vector2(
		get_theme_constant("button_font_shadow_offset_x"),
		get_theme_constant("button_font_shadow_offset_y")
	)
	
	var label_position := (_file_button.size - _button_text_buffer.get_size()) / 2.0
	var shadow_position := label_position + label_shadow_offset
	
	_button_text_buffer.draw(_file_button.get_canvas_item(), shadow_position, label_shadow_color)
	_button_text_buffer.draw(_file_button.get_canvas_item(), label_position, label_color)


# Helpers.

func _update_text_buffer() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("button_font_size")
	
	_button_text_buffer.clear()
	_button_text_buffer.add_string(_file_button.text, font, font_size)


func _show_dialog() -> void:
	_file_dialog.popup_centered(Vector2i(800, 600))


func set_font_resource_getter(callable: Callable) -> void:
	if callable.is_valid():
		_font_resource_getter = callable
	else:
		_font_resource_getter = Callable()


func _update_font_name() -> void:
	if not _font_resource_getter.is_valid():
		return
	
	var font_resource: Font = _font_resource_getter.call()
	var font_name := font_resource.get_font_name()
	_font_name_label.text = font_name


func _select_font(value: String) -> void:
	if not prop_setter.is_valid():
		return
	
	prop_setter.call(value)


# Implementation.

func _cancel_editing() -> void:
	if _file_button.has_focus():
		_file_button.release_focus()
	super()


func _handle_property_changes(property_name: String) -> void:
	if property_name == prop_name:
		_update_font_name()
