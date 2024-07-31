###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ColorPropertyEditor extends ValuePropertyEditor

@onready var _color_preview: Control = %PropertyColor
@onready var _color_picker: SimpleColorPicker = %ColorPicker

var _color_pressed: bool = false


func _init() -> void:
	super()
	theme_type_variation = &"ColorPropertyEditor"
	
	resized.connect(queue_redraw)
	sort_children.connect(queue_redraw)


func _ready() -> void:
	super()
	
	get_window().size_changed.connect(_update_color_picker_position)
	
	_color_picker.get_picker().color_changed.connect(_change_color_value)
	_color_preview.gui_input.connect(_handle_color_preview_input)
	_color_preview.mouse_exited.connect(func() -> void:
		_color_pressed = false
	)


func _draw() -> void:
	var preview_rect := _color_preview.get_global_rect()
	preview_rect.position -= global_position
	
	var preview_bg := get_theme_icon("sample_bg", "ColorPicker") # Godot already provides a nice icon for this.
	var preview_color: Color = Color.WHITE
	if not Engine.is_editor_hint():
		preview_color = get_property_value()
	
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


func _handle_color_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_color_pressed = true
			accept_event()
			queue_redraw()
		
		elif _color_pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_color_pressed = false
			accept_event()
			queue_redraw()
			
			_toggle_color_picker()


func _toggle_color_picker() -> void:
	_color_picker.visible = not _color_picker.visible
	
	if _color_picker.visible:
		_update_color_picker_position()
		if not Engine.is_editor_hint():
			_color_picker.get_picker().color = get_property_value()
		
		editing_started.emit()
	else:
		editing_stopped.emit()


func _change_color_value(color: Color) -> void:
	if prop_setter.is_valid():
		prop_setter.call(color)
	
	queue_redraw()


# Implementation.

func _handle_property_name_clicked() -> void:
	_toggle_color_picker()


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
