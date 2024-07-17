###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all canvas gizmos.
class_name BaseGizmo extends Control

signal grabbed()
signal released()

var _reference_item: BaseUIItem = null


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


# Position and sizing.

## Connects this gizmo to the given UI item's changes.
func connect_to_item(item: BaseUIItem) -> void:
	if _reference_item:
		_reference_item.rect_changed.disconnect(update_rect_by_item)
	
	_reference_item = item
	update_rect_by_item()
	
	if _reference_item:
		_reference_item.rect_changed.connect(update_rect_by_item)


## Sets the position and size of this gizmo according to the connected UI item.
func update_rect_by_item() -> void:
	if not _reference_item:
		return
	
	var item_rect := _reference_item.get_rect()
	position = item_rect.position
	size = item_rect.size


# Implementation.

## Returns whether the incoming input event can be handled, e.g. mouse is hovering over the trigger
## area. Extending classes implement this method.
func can_handle_input(event: InputEvent) -> bool:
	return false


## Handles the incoming input event. Extending classes implement this method.
func handle_input(event: InputEvent) -> void:
	pass
