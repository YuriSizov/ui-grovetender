###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo visualizing the element boundaries.
class_name BoundaryGizmo extends BaseGizmo


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"BoundaryGizmo"
	theme_type_variation = &"BoundaryGizmo"


func _draw() -> void:
	var boundary_style := get_theme_stylebox("boundary_frame")
	var boundary_size := get_theme_constant("boundary_size")
	
	var boundary_rect := Rect2()
	boundary_rect.position = get_element_global_corner(CORNER_TOP_LEFT) - position
	boundary_rect.size = get_element_global_size()
	
	DrawingUtil.draw_stylebox_frame(get_canvas_item(), boundary_style, boundary_rect, boundary_size)
