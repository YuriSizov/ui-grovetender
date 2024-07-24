###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the position of an element or a group of elements.
class_name PositionGizmo extends BaseGizmo

signal position_changed(delta: Vector2)

var _center_handle: Rect2 = Rect2()


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"PositionGizmo"
	theme_type_variation = &"PositionGizmo"


func _draw() -> void:
	var center_handle_default := get_theme_stylebox("center_handle")
	var center_handle_hover := get_theme_stylebox("center_handle_hover")
	var center_handle_pressed := get_theme_stylebox("center_handle_pressed")
	
	var center_handle_size := get_theme_constant("center_handle_size")
	var center_handle_thickness := get_theme_constant("center_handle_thickness")
	
	var horizontal_rect := Rect2()
	horizontal_rect.size = Vector2(center_handle_size, center_handle_thickness)
	horizontal_rect.position = Vector2.ZERO - horizontal_rect.size / 2.0
	
	var vertical_rect := Rect2()
	vertical_rect.size = Vector2(center_handle_thickness, center_handle_size)
	vertical_rect.position = Vector2.ZERO - vertical_rect.size / 2.0
	
	if is_hovering():
		if is_grabbing():
			draw_style_box(center_handle_pressed, horizontal_rect)
			draw_style_box(center_handle_pressed, vertical_rect)
		else:
			draw_style_box(center_handle_hover, horizontal_rect)
			draw_style_box(center_handle_hover, vertical_rect)
	else:
		draw_style_box(center_handle_default, horizontal_rect)
		draw_style_box(center_handle_default, vertical_rect)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


func _get_tooltip(_at_position: Vector2) -> String:
	if is_hovering():
		return "Move the element."
	return ""


# Implementation.

func _update_handles() -> void:
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var base_size := Vector2(handle_trigger_size, handle_trigger_size)
	
	_center_handle.position = position - base_size
	_center_handle.size = base_size * 2


func _is_hovering_at(mouse_position: Vector2) -> bool:
	return _center_handle.has_point(mouse_position)


func get_hovering_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	return Control.CURSOR_DRAG


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			var mouse_position := mb.global_position
			if _center_handle.has_point(mouse_position):
				return true
			
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			return true
	
	return false


func handle_input(event: InputEvent) -> void:
	if not is_hovering():
		return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not is_grabbing() && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			set_grabbing(true)
		
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			set_grabbing(false)
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / EndlessCanvas.get_instance().get_elements_scale()
		position_changed.emit(relative)
