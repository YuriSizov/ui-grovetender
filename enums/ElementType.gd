###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ElementType extends Object

const ELEMENT_EMPTY := 0
const ELEMENT_PANEL := 1
const ELEMENT_TEXT  := 2
const ELEMENT_ICON  := 3
const MAX           := 4

const _element_name_map := {
	ELEMENT_EMPTY: "Empty",
	ELEMENT_PANEL: "Panel",
	ELEMENT_TEXT:  "Text",
	ELEMENT_ICON:  "Icon",
}

const _element_icon_map := {
	ELEMENT_EMPTY: preload("res://assets/icons/element-empty.png"),
	ELEMENT_PANEL: preload("res://assets/icons/element-panel.png"),
	ELEMENT_TEXT:  preload("res://assets/icons/element-text.png"),
	ELEMENT_ICON:  preload("res://assets/icons/element-icon.png"),
}


static func get_element_name(type: int) -> String:
	return _element_name_map[type]


static func get_element_icon(type: int) -> Texture2D:
	return _element_icon_map[type]
