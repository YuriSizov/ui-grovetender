###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ColorPropertyEditor extends ButtonPropertyEditor

const COLOR_PICKER_SCENE := preload("res://gui/widgets/SimpleColorPicker.tscn")
var _color_picker: SimpleColorPicker = null


func _init(_element: Object, _name: String, _setter: Callable) -> void:
	super(_element, _name, _setter)
	
	theme_type_variation = &"ColorPropertyEditor"
	
	_color_picker = COLOR_PICKER_SCENE.instantiate()
	_color_picker.visible = false
	add_child(_color_picker)
	_color_picker.set_anchors_and_offsets_preset(PRESET_TOP_LEFT)


func _ready() -> void:
	button_released.connect(func() -> void:
		_color_picker.visible = not _color_picker.visible
		
		if _color_picker.visible:
			_update_picker_position()
			_color_picker.get_picker().color = element.get(prop_name)
			
			editing_started.emit()
		else:
			editing_stopped.emit()
	)
	
	_color_picker.get_picker().color_changed.connect(func(color: Color) -> void:
		if prop_setter.is_valid():
			prop_setter.call(color)
		
		queue_redraw()
	)
	
	get_window().size_changed.connect(_update_picker_position)


func _draw() -> void:
	super()
	var available_rect := get_content_rect()
	
	var preview_size := Vector2(
		get_theme_constant("color_preview_x"),
		get_theme_constant("color_preview_y")
	)
	var preview_position := Vector2(
		available_rect.position.x + available_rect.size.x - preview_size.x,
		available_rect.position.y + (available_rect.size.y - preview_size.y) / 2.0
	)
	
	var preview_rect := Rect2(preview_position, preview_size)
	var preview_bg := get_theme_icon("sample_bg", "ColorPicker") # Godot already provides a nice icon for this.
	var preview_color: Color = element.get(prop_name)
	
	draw_texture_rect(preview_bg, preview_rect, true)
	draw_rect(preview_rect, preview_color)


func _get_minimum_size() -> Vector2:
	var minimum_size := Vector2(
		get_theme_constant("minimum_size_x"),
		get_theme_constant("minimum_size_y")
	)
	var combined_size := Vector2(
		get_theme_constant("color_preview_x"),
		get_theme_constant("color_preview_y")
	)
	
	var background_panel := get_theme_stylebox("panel")
	combined_size.x += background_panel.content_margin_left + background_panel.content_margin_right
	combined_size.y += background_panel.content_margin_top + background_panel.content_margin_bottom
	
	return minimum_size.max(combined_size)


# Helpers.

func _update_picker_position() -> void:
	if not _color_picker.visible:
		return
	
	var picker_offset := Vector2(
		get_theme_constant("picker_offset_x"),
		get_theme_constant("picker_offset_y")
	)
	var picker_position := Vector2(
		0 - picker_offset.x - _color_picker.size.x,
		0
	)
	
	var window_size := get_window().size
	var picker_end_position := global_position.y + picker_position.y + _color_picker.size.y + picker_offset.y
	if picker_end_position > window_size.y:
		picker_position.y -= picker_end_position - window_size.y
	
	_color_picker.position = picker_position


# Implementation.

func _cancel_editing() -> void:
	_color_picker.visible = false
	
	super()
