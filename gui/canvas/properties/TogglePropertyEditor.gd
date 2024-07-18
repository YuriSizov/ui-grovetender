###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name TogglePropertyEditor extends PropertyEditor

var _pressed: bool = false


func _init(prop_object: Object, prop_name: String, prop_setter: Callable) -> void:
	super(PropertyEditorType.PROPERTY_TOGGLE, prop_object, prop_name, prop_setter)
	
	theme_type = &"TogglePropertyEditor"


# Implementation.

func get_size() -> Vector2:
	var combined_size := _label_text_buffer.get_size()
	
	var background_panel := get_theme_stylebox("panel")
	combined_size.x += background_panel.content_margin_left + background_panel.content_margin_right
	combined_size.y += background_panel.content_margin_top + background_panel.content_margin_bottom
	
	return combined_size


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = true
			
		elif not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			var current_value: bool = object.get(name)
			setter.call(not current_value)
			
			_pressed = false


func render(target_position: Vector2) -> void:
	var available_size := get_size()
	var background_panel := get_theme_stylebox("panel")
	if is_hovering():
		if _pressed:
			background_panel = get_theme_stylebox("panel_pressed")
		else:
			background_panel = get_theme_stylebox("panel_hover")
	
	owner_control.draw_style_box(background_panel, Rect2(target_position, available_size))
	
	var label_position := target_position + Vector2(
		background_panel.content_margin_left,
		background_panel.content_margin_top
	)
	var label_color := get_theme_color("font_color")
	var label_shadow_position := label_position + Vector2(
		get_theme_constant("font_shadow_offset_x"),
		get_theme_constant("font_shadow_offset_y")
	)
	var label_shadow_color := get_theme_color("font_shadow_color")
	
	_label_text_buffer.draw(owner_control.get_canvas_item(), label_shadow_position, label_shadow_color)
	_label_text_buffer.draw(owner_control.get_canvas_item(), label_position, label_color)
