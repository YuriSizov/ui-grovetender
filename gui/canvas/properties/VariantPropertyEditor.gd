###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name VariantPropertyEditor extends ValuePropertyEditor

var _variants: Array[Item] = []

@onready var _variant_buttons: HBoxContainer = %VariantButtons

var _focused_button: Button = null


func _init() -> void:
	super()
	theme_type_variation = &"VariantPropertyEditor"


func _ready() -> void:
	super()
	
	_create_variant_buttons()
	_update_variant_buttons()
	property_connected.connect(_update_variant_buttons)


func _update_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	for variant_button: Button in _variant_buttons.get_children():
		_update_variant_button_theme(variant_button)


func _update_variant_button_theme(variant_button: Button) -> void:
	variant_button.begin_bulk_theme_override()
	
	variant_button.add_theme_stylebox_override("normal", get_theme_stylebox("button_normal"))
	variant_button.add_theme_stylebox_override("hover", get_theme_stylebox("button_hover"))
	variant_button.add_theme_stylebox_override("pressed", get_theme_stylebox("button_pressed"))
	
	variant_button.end_bulk_theme_override()


func _clear_theme() -> void:
	super()
	
	if not is_node_ready():
		return
	
	for variant_button: Button in _variant_buttons.get_children():
		variant_button.begin_bulk_theme_override()
		
		variant_button.remove_theme_stylebox_override("normal")
		variant_button.remove_theme_stylebox_override("hover")
		variant_button.remove_theme_stylebox_override("pressed")
		
		variant_button.end_bulk_theme_override()


# Properties.

func add_variant_item(item_id: int, item_label: String, item_icon: Texture2D) -> void:
	var item := Item.new()
	item.id = item_id
	item.label = item_label
	item.icon = item_icon
	
	_variants.push_back(item)


func _create_variant_buttons() -> void:
	var button_group := ButtonGroup.new()
	
	for item in _variants:
		var variant_button := Button.new()
		variant_button.set_meta("variant_id", item.id)
		variant_button.tooltip_text = item.label
		variant_button.icon = item.icon
		variant_button.expand_icon = true
		variant_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		variant_button.custom_minimum_size = Vector2(36, 36)
		_update_variant_button_theme(variant_button)
		
		variant_button.toggle_mode = true
		variant_button.button_group = button_group
		
		_variant_buttons.add_child(variant_button)
		variant_button.pressed.connect(_select_property_variant.bind(item.id))
		variant_button.focus_entered.connect(_handle_variant_button_focused.bind(variant_button))
		variant_button.focus_exited.connect(_handle_variant_button_unfocused.bind(variant_button))


func _update_variant_buttons() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	if not has_property():
		return
	
	var value: int = get_property_value()
	
	for variant_button: Button in _variant_buttons.get_children():
		var variant_id: int = variant_button.get_meta("variant_id", -1)
		if variant_id == value:
			variant_button.button_pressed = true
		else:
			variant_button.button_pressed = false


func _handle_variant_button_focused(variant_button: Button) -> void:
	if _focused_button == variant_button:
		return
	
	_focused_button = variant_button
	_start_editing()


func _handle_variant_button_unfocused(variant_button: Button) -> void:
	if _focused_button == variant_button:
		_focused_button = null
		_stop_editing()


func _select_property_variant(variant_id: int) -> void:
	if not prop_setter.is_valid():
		return
	
	prop_setter.call(variant_id)


# Implementation.

func _cancel_editing() -> void:
	if _focused_button:
		_focused_button.release_focus()
	super()


class Item:
	var id: int = -1
	var label: String = ""
	var icon: Texture2D = null
