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

var _toggle_pressed: bool = false


func _init() -> void:
	super()
	theme_type_variation = &"TogglePropertyEditor"


func _ready() -> void:
	super()
	
	_update_property_toggle()
	edited_property_changed.connect(_update_property_toggle)
	
	_property_toggle.gui_input.connect(_handle_property_toggle_input)
	_property_toggle.mouse_exited.connect(func() -> void:
		_toggle_pressed = false
	)


# Properties.

func _update_property_toggle() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	if not has_property():
		_property_toggle.visible = false
		return
	
	_property_toggle.visible = true
	_property_toggle.texture = CHECKBOX_ICONS[0] if get_property_value() else CHECKBOX_ICONS[1]


func _handle_property_toggle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle_pressed = true
			accept_event()
			queue_redraw()
		
		elif _toggle_pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle_pressed = false
			accept_event()
			queue_redraw()
			
			_change_toggle_value()


func _change_toggle_value() -> void:
	if not prop_setter.is_valid():
		return
	
	var current_value: bool = get_property_value()
	prop_setter.call(not current_value)


# Implementation.

func _handle_property_name_clicked() -> void:
	_change_toggle_value()


func _handle_property_changes(property_name: String) -> void:
	if property_name == prop_name:
		_update_property_toggle()
