###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name StatePropertyEntry extends HBoxContainer

signal preview_toggled()

var _state: UIState = null

@onready var _state_name_label: Label = %StateName
@onready var _preview_state_button: Button = %PreviewButton
@onready var _rename_state_button: Button = %RenameButton
@onready var _delete_state_button: Button = %DeleteButton
@onready var _locked_state_icon: TextureRect = %LockedIcon


func _ready() -> void:
	_update_theme()
	_update_name_label()
	_update_locked_state()
	
	_preview_state_button.pressed.connect(preview_toggled.emit)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()
	
	# This is so hacky, but it allows us to use one theme definition for all elements of a complex
	# scene, with in-editor preview, without polluting saved scenes.
	elif what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_theme()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_update_theme()


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	var buttons: Array[Button] = [ _preview_state_button, _rename_state_button, _delete_state_button ]
	for button in buttons:
		button.begin_bulk_theme_override()
		button.add_theme_stylebox_override("normal", get_theme_stylebox("button_normal"))
		button.add_theme_stylebox_override("hover", get_theme_stylebox("button_hover"))
		button.add_theme_stylebox_override("pressed", get_theme_stylebox("button_pressed"))
		button.add_theme_stylebox_override("focus", get_theme_stylebox("button_focus"))
		button.end_bulk_theme_override()
	
	_state_name_label.begin_bulk_theme_override()
	_state_name_label.add_theme_font_override("font", get_theme_font("font"))
	_state_name_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_state_name_label.add_theme_color_override("font_color", get_theme_color("font_color"))
	_state_name_label.add_theme_color_override("font_shadow_color", get_theme_color("font_shadow_color"))
	_state_name_label.add_theme_constant_override("shadow_offset_x", get_theme_constant("font_shadow_offset_x"))
	_state_name_label.add_theme_constant_override("shadow_offset_y", get_theme_constant("font_shadow_offset_y"))
	_state_name_label.end_bulk_theme_override()


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	var buttons: Array[Button] = [ _preview_state_button, _rename_state_button, _delete_state_button ]
	for button in buttons:
		button.begin_bulk_theme_override()
		button.remove_theme_stylebox_override("normal")
		button.remove_theme_stylebox_override("hover")
		button.remove_theme_stylebox_override("pressed")
		button.remove_theme_stylebox_override("focus")
		button.end_bulk_theme_override()
	
	_state_name_label.begin_bulk_theme_override()
	_state_name_label.remove_theme_font_override("font")
	_state_name_label.remove_theme_font_size_override("font_size")
	_state_name_label.remove_theme_color_override("font_color")
	_state_name_label.remove_theme_color_override("font_shadow_color")
	_state_name_label.remove_theme_constant_override("shadow_offset_x")
	_state_name_label.remove_theme_constant_override("shadow_offset_y")
	_state_name_label.end_bulk_theme_override()


# Properties.

func get_state_data() -> UIState:
	return _state


func set_state_data(state: UIState) -> void:
	_state = state
	
	_update_name_label()
	_update_locked_state()


func _update_name_label() -> void:
	if not is_inside_tree():
		return
	
	if _state:
		_state_name_label.text = _state.state_name
	else:
		_state_name_label.text = "Empty"


func _update_locked_state() -> void:
	if not is_inside_tree():
		return
	
	if not _state:
		_rename_state_button.visible = false
		_delete_state_button.visible = false
		_locked_state_icon.visible = false
		return
	
	if _state.locked:
		_rename_state_button.visible = false
		_delete_state_button.visible = false
		_locked_state_icon.visible = true
	else:
		_rename_state_button.visible = true
		_delete_state_button.visible = true
		_locked_state_icon.visible = false
