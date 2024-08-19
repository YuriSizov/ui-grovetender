###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name StateType extends Object

const STATE_CUSTOM  := 0
const STATE_DEFAULT := 1
const STATE_FOCUSED := 2
const STATE_HOVERED := 3
const STATE_PRESSED := 4
const MAX           := 5

const _state_name_map := {
	STATE_CUSTOM:  "custom",
	STATE_DEFAULT: "default",
	STATE_FOCUSED: "focused",
	STATE_HOVERED: "hovered",
	STATE_PRESSED: "pressed",
}


static func get_state_name(type: int) -> String:
	return _state_name_map[type]


static func get_state_type_from_name(name: String) -> int:
	for type in _state_name_map:
		if type == STATE_CUSTOM || type == STATE_DEFAULT:
			continue
		
		var type_name: String = _state_name_map[type]
		if type_name == name:
			return type
	
	return STATE_CUSTOM
