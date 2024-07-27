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
	var boundary_style := get_theme_stylebox("boundary")
	var boundary_size := get_theme_constant("boundary_size")
	
	var element_size := get_element_global_size()
	
	var horizontal_rect := Rect2()
	horizontal_rect.size = Vector2(element_size.x, boundary_size)
	
	# Top border.
	horizontal_rect.position = get_element_global_corner(CORNER_TOP_LEFT) - position
	horizontal_rect.position.y -= boundary_size
	draw_style_box(boundary_style, horizontal_rect)
	
	# Bottom border.
	horizontal_rect.position = get_element_global_corner(CORNER_BOTTOM_LEFT) - position
	draw_style_box(boundary_style, horizontal_rect)
	
	var vertical_rect := Rect2()
	vertical_rect.size = Vector2(boundary_size, element_size.y)
	
	# Left border.
	vertical_rect.position = get_element_global_corner(CORNER_TOP_LEFT) - position
	vertical_rect.position.x -= boundary_size
	draw_style_box(boundary_style, vertical_rect)
	
	# Right border.
	vertical_rect.position = get_element_global_corner(CORNER_TOP_RIGHT) - position
	draw_style_box(boundary_style, vertical_rect)
