###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name SimpleColorPicker extends PanelContainer

@onready var _color_picker: ColorPicker = $ColorPicker


func get_picker() -> ColorPicker:
	return _color_picker
