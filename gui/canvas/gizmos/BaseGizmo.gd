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
var _hovering: bool = false
var _grabbing: bool = false


func _init() -> void:
	name = &"BaseGizmo"
	mouse_filter = MOUSE_FILTER_IGNORE


func _ready() -> void:
	_update_handles()
	item_rect_changed.connect(_update_handles)


# Position and sizing.

## Connects this gizmo to the given UI element's changes.
func connect_to_element(element: BaseUIElement) -> void:
	if _reference_element:
		_reference_element.rect_changed.disconnect(update_rect_by_element)
	
	_reference_element = element
	update_rect_by_element()
	
	if _reference_element:
		_reference_element.rect_changed.connect(update_rect_by_element)


## Sets the position and size of this gizmo according to the connected UI element.
func update_rect_by_element() -> void:
	if not _reference_element:
		return
	
	var element_rect := _reference_element.rect.get_boundary_rect()
	var position_changed := position != element_rect.position
	var size_changed := size != element_rect.size
	
	position = element_rect.position
	size = element_rect.size
	
	# Inexplicably, Godot doesn't trigger item_rect_changed when position changes, but not the size.
	if not size_changed && position_changed:
		item_rect_changed.emit()


# Interactions.

## Returns whether this gizmo is being currently hovered.
func is_hovering() -> bool:
	return _hovering


## Marks, or unmarks, this gizmo as being currently hovered.
func set_hovering(value: bool) -> void:
	if _hovering == value:
		return
	
	_hovering = value


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


## Checks whether the interactive parts of the gizmo are being hovered. Extending classes implement
## this method.
func check_hovering(_mouse_position: Vector2) -> void:
	return


## Returns the cursor shape based on the position from the input event. Extending classes implement
## this method.
func get_hovered_cursor_shape(_mouse_position: Vector2) -> CursorShape:
	return Control.CURSOR_ARROW


## Returns whether the incoming input event can be handled, e.g. mouse is hovering over the trigger
## area. Extending classes implement this method.
func can_handle_input(_event: InputEvent) -> bool:
	return false


## Handles the incoming input event. Extending classes implement this method.
func handle_input(_event: InputEvent) -> void:
	pass
