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

@onready var _property_toggle: Button = %PropertyToggle


func _init() -> void:
	super()
	theme_type_variation = &"TogglePropertyEditor"


func _ready() -> void:
	super()
	
	_update_property_toggle()
	property_connected.connect(_update_property_toggle)
	property_changed.connect(_update_property_toggle)
	
	_property_toggle.pressed.connect(_change_toggle_value)
	_property_toggle.focus_entered.connect(_start_editing)
	_property_toggle.focus_exited.connect(_stop_editing)


func _update_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	_property_toggle.begin_bulk_theme_override()
	_property_toggle.add_theme_stylebox_override("normal", get_theme_stylebox("toggle_panel"))
	_property_toggle.add_theme_stylebox_override("hover", get_theme_stylebox("toggle_panel"))
	_property_toggle.add_theme_stylebox_override("pressed", get_theme_stylebox("toggle_panel"))
	_property_toggle.end_bulk_theme_override()


func _clear_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	_property_toggle.begin_bulk_theme_override()
	_property_toggle.remove_theme_stylebox_override("normal")
	_property_toggle.remove_theme_stylebox_override("hover")
	_property_toggle.remove_theme_stylebox_override("pressed")
	_property_toggle.end_bulk_theme_override()


# Properties.

func _update_property_toggle() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	if not has_property():
		_property_toggle.visible = false
		return
	
	_property_toggle.visible = true
	_property_toggle.icon = CHECKBOX_ICONS[0] if get_property_value() else CHECKBOX_ICONS[1]


func _change_toggle_value() -> void:
	if not _prop_setter.is_valid():
		return
	
	var current_value: bool = get_property_value()
	set_property_value(not current_value)


# Implementation.

func _handle_property_name_clicked() -> void:
	_change_toggle_value()


func _cancel_editing() -> void:
	if _property_toggle.has_focus():
		_property_toggle.release_focus()
	super()
