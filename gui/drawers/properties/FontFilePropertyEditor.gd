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

var _font_resource_getter: Callable = Callable()


func _init() -> void:
	super()
	theme_type_variation = &"FontFilePropertyEditor"


func _ready() -> void:
	super()
	
	_update_font_name()
	property_connected.connect(_update_font_name)
	property_changed.connect(_update_font_name)
	
	_file_button.pressed.connect(_show_dialog)
	_file_button.focus_entered.connect(_start_editing)
	_file_button.focus_exited.connect(_stop_editing)
	
	_file_dialog.file_selected.connect(_select_font)


func _update_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	_font_name_label.begin_bulk_theme_override()
	_font_name_label.add_theme_font_override("font", get_theme_font("font"))
	_font_name_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_font_name_label.add_theme_color_override("font_color", get_theme_color("preview_font_color"))
	_font_name_label.add_theme_color_override("font_shadow_color", get_theme_color("preview_font_shadow_color"))
	_font_name_label.add_theme_constant_override("shadow_offset_x", get_theme_constant("preview_font_shadow_offset_x"))
	_font_name_label.add_theme_constant_override("shadow_offset_y", get_theme_constant("preview_font_shadow_offset_y"))
	_font_name_label.end_bulk_theme_override()


func _clear_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	_font_name_label.begin_bulk_theme_override()
	_font_name_label.remove_theme_font_override("font")
	_font_name_label.remove_theme_font_size_override("font_size")
	_font_name_label.remove_theme_color_override("font_color")
	_font_name_label.remove_theme_color_override("font_shadow_color")
	_font_name_label.remove_theme_constant_override("shadow_offset_x")
	_font_name_label.remove_theme_constant_override("shadow_offset_y")
	_font_name_label.end_bulk_theme_override()


# Helpers.

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
	_font_name_label.tooltip_text = font_name


func _select_font(value: String) -> void:
	set_property_value(value)


# Implementation.

func _cancel_editing() -> void:
	if _file_button.has_focus():
		_file_button.release_focus()
	super()
