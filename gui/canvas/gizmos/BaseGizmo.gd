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

## The callable that is called to check if the gizmo should be visible. If it's empty/invalid,
## the gizmo is always visible.
var _visibility_condition: Callable = Callable()

## The flag that indicates that the gizmo is being hovered.
var _hovering: bool = false
## The flag that indicates that the gizmo is being grabbed.
var _grabbing: bool = false
## The current cursor shape for the hovered/grabbed gizmo.
var _handle_cursor_shape: Control.CursorShape = Control.CURSOR_ARROW
## Th current tooltip for the hovered/grabbed gizmo.
var _handle_tooltip: String = ""

## The cached value of the element rect, translated into UI coordinates.
var _local_element_rect: Rect2 = Rect2()


func _init(element: UIElement, element_data: BaseElementData) -> void:
	connect_to_state(element, element_data)
	
	mouse_filter = MOUSE_FILTER_IGNORE


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
		_element.transform_queued.disconnect(_update_transform)
	if _element_data:
		_element_data.properties_changed.disconnect(_check_visibility_condition)
	
	_element = element
	_element_data = element_data
	
	if _element:
		_element.transform_queued.connect(_update_transform)
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
	
	queue_redraw()
	
	var element_rect := _element.get_element_state_rect(_element_data)
	_local_element_rect = _canvas.from_canvas_rect(element_rect)
	
	_update_handles_transform()


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


func stop_grabbing() -> void:
	if not _grabbing:
		return
	
	_grabbing = false
	gizmo_released.emit()


# Implementation.

# Virtual. Called to update the position and size of the gizmo and its handles.
func _update_handles_transform() -> void:
	# By default just center it with no size.
	position = _local_element_rect.get_center()
	size = Vector2.ZERO


# Virtual. Called to test if a point belongs to this gizmo, or not. Extending
# classes may introduce side-effects while testing, to optimize future actions.
func _test_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


# Virtual. Called when this gizmo should receive the incoming input event. The
# event is automatically accepted after this call. For this method to be called
# _test_point must return true.
func _handle_mouse_input(_event: InputEventMouse) -> void:
	pass
