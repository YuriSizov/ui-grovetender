###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI items. Encapsulates shared logic and universal data members.
class_name BaseUIItem extends Resource

signal rect_changed()

## The instance ID of the owner. Runtime only.
var owner_id: int = 0

## The size of the UI item.
@export var size: Vector2 = Vector2(80, 80):
	set = set_size
## The center position of the UI item.
@export var position: Vector2 = Vector2.ZERO:
	set = set_position

# Cached position used for rendering and input handling.
var _topleft_position: Vector2 = Vector2.ZERO


func _init() -> void:
	_update_topleft_position()


# Metadata.

func get_owner() -> Hotspot:
	if not is_instance_id_valid(owner_id):
		return null
	
	return instance_from_id(owner_id)


func get_owner_control() -> CanvasHotspot:
	var owner := get_owner()
	if not owner:
		return null
	
	return owner.get_control()


# Position and sizing.

func _update_topleft_position() -> void:
	_topleft_position = position - size / 2.0


## Sets the size of this UI item.
func set_size(value: Vector2) -> void:
	size = value
	_update_topleft_position()
	
	rect_changed.emit()


## Sets the center position of this UI item.
func set_position(value: Vector2) -> void:
	position = value
	_update_topleft_position()
	
	rect_changed.emit()


## Sets both center position and size at the same time for this UI item.
func set_rect(value: Rect2) -> void:
	size = value.size
	position = value.position
	_update_topleft_position()
	
	rect_changed.emit()


## Returns the base area for this UI item.
func get_rect() -> Rect2:
	return Rect2(_topleft_position, size)


## Returns the are for this UI item, relative to the owner hotspot.
func get_rect_in_hotspot() -> Rect2:
	var owner_hotspot := get_owner()
	if not owner_hotspot:
		return Rect2()
	
	var owner_rect := owner_hotspot.get_rect()
	return Rect2(_topleft_position - owner_rect.position, size)


# Implementation.

## Renders this UI item. Extending classes override this method.
func render() -> void:
	pass


## Initializes and returns a set of gizmos for editing this UI item. Extending classes override this method.
func get_gizmos() -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	return gizmos
