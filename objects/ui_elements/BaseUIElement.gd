###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI elements. Encapsulates shared logic and universal data members.
class_name BaseUIElement extends Resource

signal rect_changed()
@warning_ignore("unused_signal") # Used in extending classes.
signal properties_changed()

## The unique name of this UI element.
@export var element_name: String = "BaseElement0"
## The rectangle defining the size and position of this UI element.
@export var rect: UIRect = UIRect.new()

## The instance ID of the control. Runtime only.
var _control_id: int = 0



func _init() -> void:
	rect.changed.connect(rect_changed.emit) # Pass through the signal.


# Metadata.

## Returns the Control node responsible for rendering of this UI element.
func get_control() -> CanvasElementControl:
	if not is_instance_id_valid(_control_id):
		return null
	
	return instance_from_id(_control_id)


## Sets the Control node responsible for rendering this UI element by its instance ID.
func set_control_id(instance_id: int) -> void:
	if not is_instance_id_valid(instance_id):
		return

	_control_id = instance_id


## Clears the Control node responsible for renderingt this UI element.
func clear_control_id() -> void:
	_control_id = 0


# Position and sizing.

## Returns the area for this UI element, relative to the control node.
func get_rect_in_control() -> Rect2:
	var control := get_control()
	if not control:
		return Rect2()
	
	var bounding_rect := rect.get_bounding_rect()
	bounding_rect.position -= control.position
	
	return bounding_rect


# Implementation.

## Renders this UI element. Extending classes override this method.
func draw() -> void:
	pass


## Initializes and returns a set of gizmos for editing this UI element. Gizmos with lower indices
## are handled first. Extending classes override this method, but must call super() most of the time.
func get_gizmos(editing_mode: EndlessCanvas.EditingMode) -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	if editing_mode == EndlessCanvas.EditingMode.DIMENSIONAL_TOOLS:
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


func get_editable_properties(editing_mode: EndlessCanvas.EditingMode) -> Array[PropertyEditor]:
	var properties: Array[PropertyEditor] = []
	
	if editing_mode == EndlessCanvas.EditingMode.DIMENSIONAL_TOOLS:
		# TODO: Add a property editor for size.
		# TODO: Add a property editor for position, when it's an offset inside a composite element.
		pass
	
	return properties


# Properties.

func _resize_by_corner(corner: Corner, delta: Vector2) -> void:
	var center_rect := rect.get_size_and_position()
	
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
	var center_rect := rect.get_size_and_position()
	
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
