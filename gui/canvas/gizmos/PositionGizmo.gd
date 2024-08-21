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
	draw_circle(_center_handle_position, _center_handle_radius, Color.RED, true, -1.0, true)


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
	_cursor_shape = Control.CURSOR_DRAG
	
	return _center_handle_position.distance_to(point) <= (size.x / 2.0)
