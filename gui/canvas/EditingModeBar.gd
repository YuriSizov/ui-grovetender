###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends VBoxContainer

@onready var _current_label: Label = %CurrentModeLabel

var _editing_mode_buttons := preload("res://gui/canvas/editing_mode_button_group.tres")


func _ready() -> void:
	_editing_mode_changed(_editing_mode_buttons.get_pressed_button())
	_editing_mode_buttons.pressed.connect(_editing_mode_changed)


func _editing_mode_changed(button: Button) -> void:
	var button_index := button.get_index()
	_current_label.text = EditingMode.get_editing_mode_name(button_index)
