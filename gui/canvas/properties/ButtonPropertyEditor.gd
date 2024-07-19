###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ButtonPropertyEditor extends PropertyEditor

signal button_pressed()
signal button_released()

var _pressed: bool = false


func _init(_type: int, _object: Object, _name: String, _setter: Callable) -> void:
	super(_type, _object, _name, _setter)
	
	theme_type_variation = &"ButtonPropertyEditor"


func _draw() -> void:
	var available_rect := Rect2(Vector2.ZERO, size)
	
	var background_panel := get_current_panel()
	draw_style_box(background_panel, available_rect)


# Helpers.

func get_current_panel() -> StyleBox:
	var background_panel := get_theme_stylebox("panel")
	if is_hovering():
		if _pressed:
			background_panel = get_theme_stylebox("panel_pressed")
		else:
			background_panel = get_theme_stylebox("panel_hover")
	
	return background_panel


# Implementation.

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not get_global_rect().has_point(mb.global_position):
			_cancel_editing()
			return
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = true
			queue_redraw()
			
			button_pressed.emit()
		
		elif not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = false
			queue_redraw()
			
			button_released.emit()
