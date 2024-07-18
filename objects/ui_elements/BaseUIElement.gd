###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI elements. Encapsulates shared logic and universal data members.
class_name BaseUIElement extends Resource

signal rect_changed()
@warning_ignore("unused_signal") # Used in extending classes.
signal redraw_needed()

## The instance ID of the control. Runtime only.
var control_id: int = 0

@export var rect: UIRect = UIRect.new()


func _init() -> void:
	rect.changed.connect(rect_changed.emit) # Pass through the signal.


# Metadata.

func get_control() -> CanvasUIElement:
	if not is_instance_id_valid(control_id):
		return null
	
	return instance_from_id(control_id)


# Position and sizing.

## Returns the area for this UI element, relative to the control node.
func get_rect_in_control() -> Rect2:
	var control := get_control()
	if not control:
		return Rect2()
	
	var owner_rect := control.get_rect()
	var local_position := rect.get_boundary_rect()
	local_position.position -= owner_rect.position
	
	return local_position


# Implementation.

## Renders this UI element. Extending classes override this method.
func render() -> void:
	pass


## Initializes and returns a set of gizmos for editing this UI element. Gizmos with lower indices
## are handled first. Extending classes override this method, but must call super() most of the time.
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
		CORNER_TOP_RIGHT:
			center_rect.size += Vector2(delta.x, -delta.y)
		CORNER_BOTTOM_RIGHT:
			center_rect.size += delta
		CORNER_BOTTOM_LEFT:
			center_rect.size += Vector2(-delta.x, delta.y)
	
	# Constrain the size to be non-negative.
	if center_rect.size.x < 0:
		center_rect.size.x = 0
	if center_rect.size.y < 0:
		center_rect.size.y = 0
	
	# Update position delta based on the actual size change.
	var effective_delta := Vector2(
		center_rect.size.x - rect.size.x,
		center_rect.size.y - rect.size.y
	)
	if corner == CORNER_TOP_LEFT || corner == CORNER_BOTTOM_LEFT:
		effective_delta.x *= -1
	if corner == CORNER_TOP_LEFT || corner == CORNER_TOP_RIGHT:
		effective_delta.y *= -1
	
	center_rect.position += effective_delta / 2.0
	rect.set_size_and_position(center_rect)


func _resize_by_side(side: Side, delta: Vector2) -> void:
	var center_rect := rect.get_center_rect()
	
	match side:
		SIDE_LEFT:
			center_rect.size.x -= delta.x
		SIDE_RIGHT:
			center_rect.size.x += delta.x
		SIDE_TOP:
			center_rect.size.y -= delta.y
		SIDE_BOTTOM:
			center_rect.size.y += delta.y
	
	# Constrain the size to be non-negative.
	if center_rect.size.x < 0:
		center_rect.size.x = 0
	if center_rect.size.y < 0:
		center_rect.size.y = 0
	
	# Update position delta based on the actual size change.
	var effective_delta := Vector2(
		center_rect.size.x - rect.size.x,
		center_rect.size.y - rect.size.y
	)
	if side == SIDE_LEFT:
		effective_delta.x *= -1
	if side == SIDE_TOP:
		effective_delta.y *= -1
	
	center_rect.position += effective_delta / 2.0
	rect.set_size_and_position(center_rect)


func _reposition_by_center(delta: Vector2) -> void:
	rect.position += delta
