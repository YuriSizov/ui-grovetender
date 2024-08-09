###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ExposedRole extends Object

const EXPOSED_CUSTOM := 0
const EXPOSED_LABEL  := 1
const EXPOSED_ICON   := 2
const MAX            := 3

const _role_name_map := {
	EXPOSED_CUSTOM: "custom",
	EXPOSED_LABEL:  "label",
	EXPOSED_ICON:   "icon",
}


static func get_role_name(type: int) -> String:
	return _role_name_map[type]
