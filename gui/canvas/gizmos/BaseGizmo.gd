###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name BaseGizmo extends Control

signal gizmo_grabbed()
signal gizmo_released()

## The canvas that owns the element (directly or indirectly).
var _canvas: UICanvas = null
## The element that is being edited.
var _element: UIElement = null
## The state data object that is being edited.
var _element_data: BaseElementData = null

## The callable that is called to check if the gizmo should be visible. If it's
## empty/invalid, the gizmo is always visible.
var _visibility_condition: Callable = Callable()

## The flag that indicates that the gizmo is being hovered.
var _hovering: bool = false
## The flag that indicates that the gizmo is being grabbed.
var _grabbing: bool = false

##
var _handles: Dictionary = {}
## The current cursor shape for the hovered/grabbed gizmo.
var _handle_cursor_shape: Control.CursorShape = Control.CURSOR_ARROW
## Th current tooltip for the hovered/grabbed gizmo.
var _handle_tooltip: String = ""

## The cached value of the element anchor position, translated into UI coordinates.
var _local_element_anchor: Vector2 = Vector2.ZERO
## The cached value of the element rect, translated into UI coordinates.
var _local_element_rect: Rect2 = Rect2()
## The cached values for element corners, translated into UI coordinates.
var _local_element_corner: PackedVector2Array = PackedVector2Array()
## The cached values for element sides, translated into UI coordinates. Vector4 values
## should be read as x1, y1, x2, y2, defining a rectangle.
var _local_element_side: PackedVector4Array = PackedVector4Array()


func _init(element: UIElement, element_data: BaseElementData) -> void:
	name = &"BaseGizmo"
	theme_type_variation = &"BaseGizmo"
	mouse_filter = MOUSE_FILTER_IGNORE
	
	connect_to_state(element, element_data)


func _enter_tree() -> void:
	_check_visibility_condition()
	_update_transform()


# Metadata.

func connect_to_canvas(canvas: UICanvas) -> void:
	if _canvas == canvas:
		return
	
	if _canvas:
		_canvas.canvas_transformed.disconnect(_update_transform)
	
	_canvas = canvas
	
	if _canvas:
		_canvas.canvas_transformed.connect(_update_transform)
	
	_update_transform()


func connect_to_state(element: UIElement, element_data: BaseElementData) -> void:
	if _element == element && _element_data == element_data:
		return
	
	if _element:
		_element.transform_changed.disconnect(_update_transform)
	if _element_data:
		_element_data.properties_changed.disconnect(_check_visibility_condition)
	
	_element = element
	_element_data = element_data
	
	if _element:
		_element.transform_changed.connect(_update_transform)
	if _element_data:
		_element_data.properties_changed.connect(_check_visibility_condition)
	
	_update_transform()


func set_visibility_condition(callable: Callable) -> void:
	if callable.is_valid():
		_visibility_condition = callable
	else:
		_visibility_condition = Callable()


func _check_visibility_condition() -> void:
	if not _visibility_condition.is_valid():
		visible = true
		return
	
	visible = _visibility_condition.call()


# Position and size.

func _update_transform() -> void:
	if not _canvas || not _element:
		return
	
	# Always request a redraw.
	queue_redraw()
	
	# Update value caches.
	
	var element_rect := _element.get_element_state_rect(_element_data)
	_local_element_rect = _canvas.from_canvas_rect(element_rect)
	_local_element_anchor = _canvas.from_canvas_coordinates(_element.anchor_point)
	
	_local_element_corner.resize(4)
	_local_element_corner[CORNER_TOP_LEFT]     = Vector2(_local_element_rect.position.x, _local_element_rect.position.y)
	_local_element_corner[CORNER_TOP_RIGHT]    = Vector2(_local_element_rect.end.x,      _local_element_rect.position.y)
	_local_element_corner[CORNER_BOTTOM_RIGHT] = Vector2(_local_element_rect.end.x,      _local_element_rect.end.y)
	_local_element_corner[CORNER_BOTTOM_LEFT]  = Vector2(_local_element_rect.position.x, _local_element_rect.end.y)
	
	_local_element_side.resize(4)
	_local_element_side[SIDE_LEFT] = Vector4(
		_local_element_corner[CORNER_TOP_LEFT].x, _local_element_corner[CORNER_TOP_LEFT].y,
		_local_element_corner[CORNER_BOTTOM_LEFT].x, _local_element_corner[CORNER_BOTTOM_LEFT].y
	)
	_local_element_side[SIDE_TOP] = Vector4(
		_local_element_corner[CORNER_TOP_LEFT].x, _local_element_corner[CORNER_TOP_LEFT].y,
		_local_element_corner[CORNER_TOP_RIGHT].x, _local_element_corner[CORNER_TOP_RIGHT].y
	)
	_local_element_side[SIDE_RIGHT] = Vector4(
		_local_element_corner[CORNER_TOP_RIGHT].x, _local_element_corner[CORNER_TOP_RIGHT].y,
		_local_element_corner[CORNER_BOTTOM_RIGHT].x, _local_element_corner[CORNER_BOTTOM_RIGHT].y
	)
	_local_element_side[SIDE_BOTTOM] = Vector4(
		_local_element_corner[CORNER_BOTTOM_LEFT].x, _local_element_corner[CORNER_BOTTOM_LEFT].y,
		_local_element_corner[CORNER_BOTTOM_RIGHT].x, _local_element_corner[CORNER_BOTTOM_RIGHT].y
	)
	
	# Let gizmo implementations update their transforms.
	_update_handles_transform()


# Handle management.

func get_handles() -> Array[GizmoHandle]:
	# Godot is weird about array types...
	var handle_values: Array[GizmoHandle] = []
	handle_values.assign(_handles.values())
	return handle_values


func set_handle(handle_id: int, handle_position: Vector2, trigger_size: Vector2, render_size: Vector2) -> void:
	var handle_data: GizmoHandle = null
	
	if not _handles.has(handle_id):
		handle_data = GizmoHandle.new(handle_id)
		_handles[handle_id] = handle_data
	else:
		handle_data = _handles[handle_id]
	
	handle_data.position = handle_position
	handle_data.trigger_size = trigger_size
	handle_data.render_size = render_size


# Interactions.

func test_point(point: Vector2) -> bool:
	return is_visible_in_tree() && _test_point(point)


func handle_mouse_input(event: InputEventMouse) -> void:
	_handle_mouse_input(event)


func is_hovering() -> bool:
	return _hovering


func set_hovering(value: bool) -> void:
	if _hovering == value:
		return
	
	_hovering = value
	queue_redraw()


func get_handle_cursor_shape() -> Control.CursorShape:
	return _handle_cursor_shape


func get_handle_tooltip() -> String:
	return _handle_tooltip


func set_handle_feedback(cursor_shape: Control.CursorShape, tooltip: String) -> void:
	_handle_cursor_shape = cursor_shape
	_handle_tooltip = tooltip


func is_grabbing() -> bool:
	return _grabbing


func start_grabbing() -> void:
	if _grabbing:
		return
	
	_grabbing = true
	gizmo_grabbed.emit()
	queue_redraw()


func stop_grabbing() -> void:
	if not _grabbing:
		return
	
	_grabbing = false
	gizmo_released.emit()
	queue_redraw()


# Implementation.

# Virtual. Called to update positions and sizes gizmo's handles.
func _update_handles_transform() -> void:
	pass


# Virtual. Called to test if a point belongs to this gizmo, or not. Extending
# classes may introduce side-effects while testing, to optimize future actions.
func _test_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


# Virtual. Called when this gizmo should receive the incoming input event. For
# this method to be called _test_point must return true.
func _handle_mouse_input(_event: InputEventMouse) -> void:
	pass


class GizmoHandle:
	var id: int = -1
	var position: Vector2 = Vector2.ZERO
	var trigger_size: Vector2 = Vector2.ZERO
	var render_size: Vector2 = Vector2.ZERO
	
	
	func _init(handle_id: int) -> void:
		id = handle_id
	
	
	func get_trigger_rect() -> Rect2:
		var trigger_rect := Rect2()
		trigger_rect.size = trigger_size
		trigger_rect.position = position - trigger_size / 2.0
		
		return trigger_rect
	
	
	func test_point_in_trigger(point: Vector2) -> bool:
		var trigger_rect := get_trigger_rect()
		return trigger_rect.has_point(point)
	
	
	func get_render_rect() -> Rect2:
		var render_rect := Rect2()
		render_rect.size = render_size
		render_rect.position = (position - render_size / 2.0).round()
		
		return render_rect
