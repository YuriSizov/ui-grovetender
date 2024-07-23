###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all canvas gizmos.
class_name BaseGizmo extends Control

@warning_ignore("unused_signal") # Used by extending classes.
signal grabbed()
@warning_ignore("unused_signal") # Used by extending classes.
signal released()

var _reference_element: BaseUIElement = null
var _element_global_position: Vector2 = Vector2.ZERO
var _element_global_size: Vector2 = Vector2.ZERO
var _element_global_rect: Rect2 = Rect2()

var _hovering: bool = false
var _grabbing: bool = false


func _init() -> void:
	name = &"BaseGizmo"
	mouse_filter = MOUSE_FILTER_IGNORE
	
	EndlessCanvas.get_instance().canvas_transformed.connect(_update_rect_by_element)


func _ready() -> void:
	_update_handles()


# Position and sizing.

func _update_rect_by_element() -> void:
	if not _reference_element:
		return
	
	var canvas_position := _reference_element.rect.get_position()
	_element_global_position = EndlessCanvas.get_instance().from_canvas_coordinates(canvas_position)
	
	var canvas_size := _reference_element.rect.get_size()
	_element_global_size = canvas_size * EndlessCanvas.get_instance().get_elements_scale()
	
	var canvas_rect := _reference_element.rect.get_bounding_rect()
	canvas_rect.position = EndlessCanvas.get_instance().from_canvas_coordinates(canvas_rect.position)
	canvas_rect.size = canvas_rect.size * EndlessCanvas.get_instance().get_elements_scale()
	_element_global_rect = canvas_rect
	
	position = get_element_global_position()
	_update_handles()
	queue_redraw()


## Connects this gizmo to the given UI element's changes.
func connect_to_element(element: BaseUIElement) -> void:
	if _reference_element:
		_reference_element.rect_changed.disconnect(_update_rect_by_element)
	
	_reference_element = element
	_update_rect_by_element()
	
	if _reference_element:
		_reference_element.rect_changed.connect(_update_rect_by_element)


func get_element_global_position() -> Vector2:
	return _element_global_position


func get_element_global_size() -> Vector2:
	return _element_global_size


func get_element_global_rect() -> Rect2:
	return _element_global_rect


func get_element_global_corner(corner: Corner) -> Vector2:
	match corner:
		CORNER_TOP_LEFT:
			return _element_global_rect.position
		CORNER_TOP_RIGHT:
			return Vector2(_element_global_rect.end.x, _element_global_rect.position.y)
		CORNER_BOTTOM_RIGHT:
			return _element_global_rect.end
		CORNER_BOTTOM_LEFT:
			return Vector2(_element_global_rect.position.x, _element_global_rect.end.y)
	
	return _element_global_position


func get_element_global_side(side: Side) -> Vector2:
	match side:
		SIDE_LEFT:
			return _element_global_rect.position + Vector2(0, _element_global_rect.size.y / 2.0)
		SIDE_TOP:
			return _element_global_rect.position + Vector2(_element_global_rect.size.x / 2.0, 0)
		SIDE_RIGHT:
			return _element_global_rect.end - Vector2(0, _element_global_rect.size.y / 2.0)
		SIDE_BOTTOM:
			return _element_global_rect.end - Vector2(_element_global_rect.size.x / 2.0, 0)
	
	return _element_global_position


# Interactions.

## Returns whether this gizmo is being currently hovered.
func is_hovering() -> bool:
	return _hovering


## Tests whether interactive parts of this gizmo are being currently hovered, and returns the
## result. See also [method _is_hovering_at].
func test_hovering(mouse_position: Vector2) -> bool:
	if _hovering:
		queue_redraw() # Queue a forced redraw in case we're exiting the gizmo right now.
	
	var new_value := _is_hovering_at(mouse_position)
	if new_value != _hovering:
		_hovering = new_value
	
	return _hovering


## Returns whether this gizmo is being currently grabbed.
func is_grabbing() -> bool:
	return _grabbing


## Marks, or unmarks, this gizmo as being currently grabbed.
func set_grabbing(value: bool) -> void:
	if _grabbing == value:
		return
	
	_grabbing = value
	if _grabbing:
		grabbed.emit()
	else:
		released.emit()


# Implementation.

## Called when it's an opportune time to update gizmo's handles/interactive areas. Extending classes
## implement this method.
func _update_handles() -> void:
	pass


## Called to update the hovered status of this gizmo. Extending classes implement this method.
func _is_hovering_at(_mouse_position: Vector2) -> bool:
	return false


## Returns the cursor shape based on the position from the input event. Extending classes implement
## this method.
func get_hovering_cursor_shape(_mouse_position: Vector2) -> CursorShape:
	return Control.CURSOR_ARROW


## Returns whether the incoming input event can be handled, e.g. mouse is hovering over the trigger
## area. Extending classes implement this method.
func can_handle_input(_event: InputEvent) -> bool:
	return false


## Handles the incoming input event. Extending classes implement this method.
func handle_input(_event: InputEvent) -> void:
	pass
