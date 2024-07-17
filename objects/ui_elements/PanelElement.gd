###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A panel UI element, which can be used as a background or foreground plane element. Configurable with
## background and border properties, or with a 9-patch texture.
# TODO: Implement support for 9-patch textures.
class_name PanelElement extends BaseUIElement

## The flag that enables background drawing.
@export var draw_background: bool = true
## The color of the background.
@export var background_color: Color = Color.ANTIQUE_WHITE

## The flag that enables border drawing.
@export var draw_border: bool = false
## The color of the border.
@export var border_color: Color = Color.BLACK
## The width/size of the border.
@export var border_width: float = 2.0


func render() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	if draw_background:
		canvas_control.draw_rect(element_rect, background_color)
	
	if draw_border:
		canvas_control.draw_rect(element_rect, border_color, false, border_width)


func get_gizmos() -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	# Basic property gizmos.
	var size_gizmo := SizeGizmo.new()
	size_gizmo.connect_to_element(self)
	gizmos.push_back(size_gizmo)
	
	# TODO: Implement constraints, snapping, alignment.
	size_gizmo.corner_size_changed.connect(_resize_by_corner)
	size_gizmo.side_size_changed.connect(_resize_by_side)
	
	var position_gizmo := PositionGizmo.new()
	position_gizmo.connect_to_element(self)
	gizmos.push_back(position_gizmo)
	
	# TODO: Implement constraints, snapping, alignment.
	position_gizmo.position_changed.connect(_reposition_by_center)
	
	return gizmos


# Helpers.

func _resize_by_corner(corner: Corner, delta: Vector2) -> void:
	var center_rect := rect.get_center_rect()
	
	match corner:
		CORNER_TOP_LEFT:
			center_rect.size -= delta # Inverted on both axes.
			center_rect.position += delta / 2.0
		CORNER_TOP_RIGHT:
			center_rect.size += Vector2(delta.x, -delta.y) 
			center_rect.position += delta / 2.0
		CORNER_BOTTOM_RIGHT:
			center_rect.size += delta
			center_rect.position += delta / 2.0
		CORNER_BOTTOM_LEFT:
			center_rect.size += Vector2(-delta.x, delta.y) 
			center_rect.position += delta / 2.0
	
	rect.set_size_and_position(center_rect)


func _resize_by_side(side: Side, delta: Vector2) -> void:
	var center_rect := rect.get_center_rect()
	
	match side:
		SIDE_LEFT:
			center_rect.size.x -= delta.x
			center_rect.position.x += delta.x / 2.0
		SIDE_RIGHT:
			center_rect.size.x += delta.x
			center_rect.position.x += delta.x / 2.0
		SIDE_TOP:
			center_rect.size.y -= delta.y
			center_rect.position.y += delta.y / 2.0
		SIDE_BOTTOM:
			center_rect.size.y += delta.y
			center_rect.position.y += delta.y / 2.0
	
	rect.set_size_and_position(center_rect)


func _reposition_by_center(delta: Vector2) -> void:
	rect.position += delta
