###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PropertyRevertButton extends Control

signal pressed()

@export var button_offset: int = 0:
	set = set_button_offset

@onready var _button: Button = %RevertButton


func _ready() -> void:
	_update_button_transform()
	
	_button.pressed.connect(pressed.emit)


# Properties.

func set_button_offset(value: int) -> void:
	if button_offset == value:
		return
	
	button_offset = value
	_update_button_transform()


func _update_button_transform() -> void:
	if not is_node_ready():
		return
	
	_button.position.x = button_offset
