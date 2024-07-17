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


func _init() -> void:
	name = &"BaseGizmo"
	mouse_filter = MOUSE_FILTER_IGNORE


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
	position = element_rect.position
	size = element_rect.size


# Implementation.

## Returns whether the incoming input event can be handled, e.g. mouse is hovering over the trigger
## area. Extending classes implement this method.
func can_handle_input(_event: InputEvent) -> bool:
	return false


## Handles the incoming input event. Extending classes implement this method.
func handle_input(_event: InputEvent) -> void:
	pass
