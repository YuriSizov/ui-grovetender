###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A generic button. Represents UI items that can be focused, clicked, toggled, either with a text,
## an icon, or both.
class_name ButtonItem extends BaseUIItem

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
	var hotspot_control := get_owner_control()
	var item_rect := get_rect_in_hotspot()
	
	if draw_background:
		hotspot_control.draw_rect(item_rect, background_color)
	
	if draw_border:
		hotspot_control.draw_rect(item_rect, border_color, false, border_width)


func get_gizmos() -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	# Basic property gizmos.
	var size_gizmo := SizeGizmo.new()
	size_gizmo.connect_to_item(self)
	gizmos.push_back(size_gizmo)
	
	# TODO: Implement constraints, snapping, alignment.
	size_gizmo.corner_size_changed.connect(_resize_by_corner)
	size_gizmo.side_size_changed.connect(_resize_by_side)
	
	var position_gizmo := PositionGizmo.new()
	position_gizmo.connect_to_item(self)
	gizmos.push_back(position_gizmo)
	
	# TODO: Implement constraints, snapping, alignment.
	position_gizmo.position_changed.connect(_reposition_by_center)
	
	return gizmos


# Helpers.

func _resize_by_corner(corner: Corner, delta: Vector2) -> void:
	var center_rect := Rect2(position, size)
	
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
	
	set_rect(center_rect)


func _resize_by_side(side: Side, delta: Vector2) -> void:
	var center_rect := Rect2(position, size)
	
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
	
	set_rect(center_rect)


func _reposition_by_center(delta: Vector2) -> void:
	set_position(position + delta)
