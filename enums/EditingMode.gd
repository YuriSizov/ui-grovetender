###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name EditingMode extends Object

const LAYOUT_TOOLS    := 0
const STYLING_TOOLS   := 1
const BEHAVIOR_TOOLS  := 2
const ANIMATION_TOOLS := 3
const MAX             := 4

const _editing_mode_name_map := {
	LAYOUT_TOOLS:    "Layout",
	STYLING_TOOLS:   "Styling",
	BEHAVIOR_TOOLS:  "Behavior",
	ANIMATION_TOOLS: "Animation",
}


static func get_editing_mode_name(mode: int) -> String:
	return _editing_mode_name_map[mode]
