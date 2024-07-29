###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI elements. Encapsulates shared logic and universal data members.
class_name BaseUIElement extends Resource

signal editor_selected()
signal editor_deselected()

signal rect_changed()
signal visibility_changed()
@warning_ignore("unused_signal") # Used in extending classes.
signal property_changed(property_name: String)
@warning_ignore("unused_signal") # Used in extending classes.
signal properties_changed()

## The unique name of this UI element.
@export var element_name: String = "EmptyElement"
## The rectangle defining the size and position of this UI element.
@export var rect: UIRect = UIRect.new()
## The visibility flag, enabling or disabling rendering of this UI element.
@export var visible: bool = true:
	set = set_visible

## The instance ID of the control. Runtime only.
var _control_id: int = 0
## Selected status in the editor.
var _selected: bool = false


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


func is_selected() -> bool:
	return _selected


func set_selected(value: bool) -> void:
	if _selected == value:
		return
	
	_selected = value
	if _selected:
		editor_selected.emit()
	else:
		editor_deselected.emit()


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
func get_gizmos(editing_mode: int) -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	# Always add this one, so no matter what there is a reference to the shape of the element.
	var boundary_gizmo := BoundaryGizmo.new(self)
	gizmos.push_back(boundary_gizmo)
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		var size_gizmo := SizeGizmo.new(self)
		gizmos.push_back(size_gizmo)
		
		# TODO: Keep track of the size at the start of the operation, accumulate deltas, and apply current modifier key effects retroactively.
		
		# TODO: Implement constraints, snapping, alignment.
		size_gizmo.corner_size_changed.connect(_resize_by_corner.bind(false))
		size_gizmo.corner_size_all_changed.connect(_resize_by_all_corners.bind(false))
		size_gizmo.corner_size_ratio_changed.connect(_resize_by_corner.bind(true))
		size_gizmo.corner_size_ratio_all_changed.connect(_resize_by_all_corners.bind(true))
		
		size_gizmo.side_size_changed.connect(_resize_by_side)
		size_gizmo.side_size_all_changed.connect(_resize_by_all_sides)
		size_gizmo.side_size_opposite_changed.connect(_resize_by_opposite_sides)
		
		var position_gizmo := PositionGizmo.new(self)
		gizmos.push_back(position_gizmo)
		# TODO: Implement constraints, snapping, alignment.
		position_gizmo.position_changed.connect(_reposition_by_center)
	
	return gizmos


func get_editable_properties(editing_mode: int) -> Array[PropertyEditor]:
	var properties: Array[PropertyEditor] = []
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		# TODO: Add a property editor for size.
		# TODO: Add a property editor for position, when it's an offset inside a composite element.
		pass
	
	return properties


# Properties.

func _ensure_positive_size(value: Vector2) -> Vector2:
	if value.x < 0:
		value.x = 0
	if value.y < 0:
		value.y = 0
	
	return value


func _ensure_ratio_size(value: Vector2, ratio: Vector2) -> Vector2:
	if ratio.x == 0 || ratio.y == 0:
		return value
	
	if ratio.x > ratio.y:
		value.y = (ratio.y / ratio.x) * value.x
	else:
		value.x = (ratio.x / ratio.y) * value.y
	
	return _ensure_positive_size(value)


func _resize_by_corner(corner: Corner, delta: Vector2, keep_ratio: bool) -> void:
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
	
	center_rect.size = _ensure_positive_size(center_rect.size)
	if keep_ratio:
		center_rect.size = _ensure_ratio_size(center_rect.size, rect.get_size())
	
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


func _resize_by_all_corners(corner: Corner, delta: Vector2, keep_ratio: bool) -> void:
	var center_size := rect.get_size()
	
	match corner:
		CORNER_TOP_LEFT:
			center_size -= delta * 2.0 # Inverted on both axes.
		CORNER_TOP_RIGHT:
			center_size += Vector2(delta.x, -delta.y) * 2.0
		CORNER_BOTTOM_RIGHT:
			center_size += delta * 2.0
		CORNER_BOTTOM_LEFT:
			center_size += Vector2(-delta.x, delta.y) * 2.0
	
	center_size = _ensure_positive_size(center_size)
	if keep_ratio:
		center_size = _ensure_ratio_size(center_size, rect.get_size())
	
	rect.set_size(center_size)


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
	
	center_rect.size = _ensure_positive_size(center_rect.size)
	
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


func _resize_by_all_sides(side: Side, delta: Vector2) -> void:
	var center_size := rect.get_size()
	
	match side:
		SIDE_LEFT:
			center_size.x -= delta.x * 2.0
			center_size.y -= delta.x * 2.0
		SIDE_RIGHT:
			center_size.x += delta.x * 2.0
			center_size.y += delta.x * 2.0
		SIDE_TOP:
			center_size.y -= delta.y * 2.0
			center_size.x -= delta.y * 2.0
		SIDE_BOTTOM:
			center_size.y += delta.y * 2.0
			center_size.x += delta.y * 2.0
	
	center_size = _ensure_positive_size(center_size)
	
	rect.set_size(center_size)


func _resize_by_opposite_sides(side: Side, delta: Vector2) -> void:
	var center_size := rect.get_size()
	
	match side:
		SIDE_LEFT:
			center_size.x -= delta.x * 2.0
		SIDE_RIGHT:
			center_size.x += delta.x * 2.0
		SIDE_TOP:
			center_size.y -= delta.y * 2.0
		SIDE_BOTTOM:
			center_size.y += delta.y * 2.0
	
	center_size = _ensure_positive_size(center_size)
	
	rect.set_size(center_size)


func _reposition_by_center(delta: Vector2) -> void:
	rect.position += delta


func set_visible(value: bool) -> void:
	if visible == value:
		return
	
	visible = value
	visibility_changed.emit()
