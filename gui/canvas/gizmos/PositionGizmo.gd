###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PositionGizmo extends BaseGizmo

signal position_changed(delta: Vector2)

var _center_handle_position: Vector2 = Vector2.ZERO
var _center_handle_radius: float = 0.0


func _draw() -> void:
	var handle_color := Color.RED
	if is_hovering():
		handle_color = handle_color.lightened(0.5)
	
	draw_circle(_center_handle_position, _center_handle_radius, handle_color, true, -1.0, true)


# Implementation.

# Override.
func _update_handles_transform() -> void:
	var center_position := _local_element_rect.get_center()
	size = Vector2(32.0, 32.0)
	position = center_position - size / 2.0
	
	_center_handle_radius = 8.0
	_center_handle_position = Vector2.ZERO + size / 2.0


# Override.
func _test_point(point: Vector2) -> bool:
	set_handle_feedback(Control.CURSOR_DRAG, "Move the element.")
	
	return _center_handle_position.distance_to(point) <= (size.x / 2.0)


# Override.
func _handle_mouse_input(event: InputEventMouse) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not is_grabbing() && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			start_grabbing()
		
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			stop_grabbing()
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / _canvas.get_canvas_scale()
		position_changed.emit(relative)
