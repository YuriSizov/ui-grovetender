###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ColorPropertyEditor extends ValuePropertyEditor

@onready var _color_preview: Control = %PropertyColor
@onready var _color_picker: SimpleColorPicker = %ColorPicker


func _init() -> void:
	super()
	theme_type_variation = &"ColorPropertyEditor"
	
	sort_children.connect(func() -> void:
		queue_redraw()
	)


func _ready() -> void:
	super()
	
	_update_property_name()
	
	edited_property_changed.connect(func() -> void:
		_update_property_name()
	)
	
	_color_picker.get_picker().color_changed.connect(func(color: Color) -> void:
		if prop_setter.is_valid():
			prop_setter.call(color)
		
		queue_redraw()
	)
	
	get_window().size_changed.connect(_update_color_picker_position)


func _draw() -> void:
	super()
	
	var preview_rect := _color_preview.get_global_rect()
	preview_rect.position -= global_position
	
	var preview_bg := get_theme_icon("sample_bg", "ColorPicker") # Godot already provides a nice icon for this.
	var preview_color: Color = Color.WHITE
	if not Engine.is_editor_hint():
		preview_color = element.get(prop_name)
	
	draw_texture_rect(preview_bg, preview_rect, true)
	draw_rect(preview_rect, preview_color)


# Properties.

func _update_color_picker_position() -> void:
	if not _color_picker.visible:
		return
	
	var picker_offset := Vector2(
		get_theme_constant("picker_offset_x"),
		get_theme_constant("picker_offset_y")
	)
	var picker_position := global_position + Vector2(
		0 - picker_offset.x - _color_picker.size.x,
		0
	)
	
	var window_size := get_window().size
	var picker_end_position := picker_position.y + _color_picker.size.y + picker_offset.y
	if picker_end_position > window_size.y:
		picker_position.y -= picker_end_position - window_size.y
	
	_color_picker.global_position = picker_position


# Implementation.

func _handle_property_clicked() -> void:
	_color_picker.visible = not _color_picker.visible
	
	if _color_picker.visible:
		_update_color_picker_position()
		if not Engine.is_editor_hint():
			_color_picker.get_picker().color = element.get(prop_name)
		
		editing_started.emit()
	else:
		editing_stopped.emit()


func _handle_outside_clicked(at_global_position: Vector2) -> void:
	if _color_picker.get_global_rect().has_point(at_global_position):
		return
	
	_cancel_editing()


func _handle_property_changes(property_name: String) -> void:
	if property_name == prop_name:
		queue_redraw()


func _cancel_editing() -> void:
	_color_picker.visible = false
	super()
