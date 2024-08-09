###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name BehaviorPreset extends Object

const PRESET_CUSTOM     := 0
const PRESET_BUTTON     := 1
const PRESET_TEXT_INPUT := 2
const MAX               := 3

const _preset_name_map := {
	PRESET_CUSTOM:     "Custom",
	PRESET_BUTTON:     "Button",
	PRESET_TEXT_INPUT: "Text Input",
}


static func get_preset_name(type: int) -> String:
	return _preset_name_map[type]
