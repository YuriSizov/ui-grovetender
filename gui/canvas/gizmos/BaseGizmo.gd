###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all canvas gizmos.
class_name BaseGizmo extends Control

signal grabbed()
signal released()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


## Sets the position and size of this gizmo according to the given UI item.
func set_rect_by_item(item: BaseUIItem) -> void:
	var item_rect := item.get_rect()
	position = item_rect.position
	size = item_rect.size


## Returns whether the incoming input event can be handled, e.g. mouse is hovering over the trigger
## area. Extending classes implement this method.
func can_handle_input(event: InputEvent) -> bool:
	return false


## Handles the incoming input event. Extending classes implement this method.
func handle_input(event: InputEvent) -> void:
	pass
