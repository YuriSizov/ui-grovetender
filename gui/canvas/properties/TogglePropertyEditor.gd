###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name TogglePropertyEditor extends ButtonPropertyEditor


func _init(_object: Object, _name: String, _setter: Callable) -> void:
	super(_object, _name, _setter)
	
	theme_type_variation = &"TogglePropertyEditor"


func _ready() -> void:
	button_released.connect(func() -> void:
		if prop_setter.is_valid():
			var current_value: bool = object.get(prop_name)
			prop_setter.call(not current_value)
	)


func _draw() -> void:
	super()
	
	var available_rect := Rect2(Vector2.ZERO, size)
	var background_panel := get_current_panel()
	
	var label_position := available_rect.position + Vector2(
		background_panel.content_margin_left,
		background_panel.content_margin_top
	)
	var label_color := get_theme_color("font_color")
	var label_shadow_offset := Vector2(
		get_theme_constant("font_shadow_offset_x"),
		get_theme_constant("font_shadow_offset_y")
	)
	var label_shadow_color := get_theme_color("font_shadow_color")
	var label_outline_size := get_theme_constant("font_outline_size")
	var label_outline_color := get_theme_color("font_outline_color")
	
	if label_shadow_offset.x > 0 || label_shadow_offset.y > 0:
		_label_text_buffer.draw(get_canvas_item(), label_position + label_shadow_offset, label_shadow_color)
	
	if label_outline_size > 0:
		_label_text_buffer.draw_outline(get_canvas_item(), label_position, label_outline_size, label_outline_color)
	
	_label_text_buffer.draw(get_canvas_item(), label_position, label_color)


func _get_minimum_size() -> Vector2:
	var combined_size := _label_text_buffer.get_size()
	
	var background_panel := get_theme_stylebox("panel")
	combined_size.x += background_panel.content_margin_left + background_panel.content_margin_right
	combined_size.y += background_panel.content_margin_top + background_panel.content_margin_bottom
	
	return combined_size
