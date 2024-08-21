###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name EditingModeBar extends MarginContainer

var _editing_mode_buttons := preload("res://gui/widgets/editing_mode_button_group.tres")

@onready var _layout: VBoxContainer = %Layout
@onready var _current_label: Label = %CurrentModeLabel
@onready var _button_section: VBoxContainer = %ButtonSection
@onready var _button_separator: Panel = %ButtonSeparator
@onready var _button_container: HBoxContainer = %Buttons


func _ready() -> void:
	_update_theme()
	
	if not Engine.is_editor_hint():
		_update_mode_button()
		_update_mode_label()
		
		_editing_mode_buttons.pressed.connect(_update_mode_label.unbind(1))


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
	if not is_node_ready():
		return
	
	_layout.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	_button_section.add_theme_constant_override("separation", get_theme_constant("section_separation"))
	_button_container.add_theme_constant_override("separation", get_theme_constant("button_separation"))
	_button_separator.add_theme_stylebox_override("panel", get_theme_stylebox("separator_panel"))
	
	_current_label.begin_bulk_theme_override()
	_current_label.add_theme_font_override("font", get_theme_font("font"))
	_current_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_current_label.add_theme_color_override("font_color", get_theme_color("font_color"))
	_current_label.add_theme_color_override("font_outline_color", get_theme_color("font_outline_color"))
	_current_label.add_theme_color_override("font_shadow_color", get_theme_color("font_shadow_color"))
	_current_label.add_theme_constant_override("outline_size", get_theme_constant("font_outline_size"))
	_current_label.add_theme_constant_override("shadow_offset_x", get_theme_constant("font_shadow_offset_x"))
	_current_label.add_theme_constant_override("shadow_offset_y", get_theme_constant("font_shadow_offset_y"))
	_current_label.end_bulk_theme_override()


## Called when the theme overrides need to be reset, e.g. before the scene is saved.
func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_layout.remove_theme_constant_override("separation")
	_button_section.remove_theme_constant_override("separation")
	_button_container.remove_theme_constant_override("separation")
	_button_separator.remove_theme_stylebox_override("panel")
	
	_current_label.begin_bulk_theme_override()
	_current_label.remove_theme_font_override("font")
	_current_label.remove_theme_font_size_override("font_size")
	_current_label.remove_theme_color_override("font_color")
	_current_label.remove_theme_color_override("font_outline_color")
	_current_label.remove_theme_color_override("font_shadow_color")
	_current_label.remove_theme_constant_override("outline_size")
	_current_label.remove_theme_constant_override("shadow_offset_x")
	_current_label.remove_theme_constant_override("shadow_offset_y")
	_current_label.end_bulk_theme_override()


# Mode management.

func _update_mode_button() -> void:
	var mode := Controller.get_editing_mode()
	var buttons := _editing_mode_buttons.get_buttons()
	if mode < 0 || mode >= buttons.size():
		return
	
	buttons[mode].button_pressed = true


func _update_mode_label() -> void:
	var button := _editing_mode_buttons.get_pressed_button()
	if not button:
		_current_label.text = ""
		return
	
	var button_index := button.get_index()
	_current_label.text = EditingMode.get_editing_mode_name(button_index)
