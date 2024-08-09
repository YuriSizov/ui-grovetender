###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PropertyEditorButton extends Button

var _button_text_buffer: TextLine = TextLine.new()


func _ready() -> void:
	_update_text_buffer()


# This is just a hack to have a label with a shadow on a regular button. Note that the default
# text is still rendered, but with a clear/transparent color.
func _draw() -> void:
	var label_color := get_theme_color("label_color")
	var label_shadow_color := get_theme_color("label_shadow_color")
	var label_shadow_offset := Vector2(
		get_theme_constant("label_shadow_offset_x"),
		get_theme_constant("label_shadow_offset_y")
	)
	
	var label_position := (size - _button_text_buffer.get_size()) / 2.0
	var shadow_position := label_position + label_shadow_offset
	
	_button_text_buffer.draw(get_canvas_item(), shadow_position, label_shadow_color)
	_button_text_buffer.draw(get_canvas_item(), label_position, label_color)


# Helpers.

func _update_text_buffer() -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("button_font_size")
	
	_button_text_buffer.clear()
	_button_text_buffer.add_string(text, font, font_size)
