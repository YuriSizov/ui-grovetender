###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name TogglePropertyEditor extends ValuePropertyEditor

const CHECKBOX_ICONS := [
	preload("res://assets/ui/checkbox-checked.png"),
	preload("res://assets/ui/checkbox-unchecked.png")
]

@onready var _property_toggle: TextureRect = %PropertyToggle


func _init() -> void:
	super()
	theme_type_variation = &"TogglePropertyEditor"


func _ready() -> void:
	super()
	
	_update_property_name()
	_update_property_toggle()
	
	edited_property_changed.connect(func() -> void:
		_update_property_name()
		_update_property_toggle()
	)


# Properties.

func _update_property_toggle() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	if prop_name.is_empty():
		_property_toggle.visible = false
		return
	
	_property_toggle.visible = true
	_property_toggle.texture = CHECKBOX_ICONS[0] if element.get(prop_name) else CHECKBOX_ICONS[1]


# Implementation.

func _handle_property_clicked() -> void:
	if not prop_setter.is_valid():
		return
	
	var current_value: bool = element.get(prop_name)
	prop_setter.call(not current_value)


func _handle_property_changes(property_name: String) -> void:
	if property_name == prop_name:
		_update_property_toggle()
