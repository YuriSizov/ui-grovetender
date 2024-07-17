###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## An abstract representation of a rectangle with a central position and size. Used by UI elements
## and other UI canvas items to define rough boundaries (actual visuals and interactive areas can
## differ, and aren't required to be rectangular at all).
class_name UIRect extends Resource

## The size of the rectangle.
@export var size: Vector2:
	set = set_size, get = get_size
## The center position of the rectangle.
@export var position: Vector2:
	set = set_position, get = get_position

# Internal values for size and position, used to set values without triggering the setter.
var _size: Vector2 = Vector2(80, 80)
var _position: Vector2 = Vector2.ZERO
# Cached position used by rendering and input handling.
var _topleft_position: Vector2 = Vector2.ZERO


func _init() -> void:
	_update_topleft_position()


func _update_topleft_position() -> void:
	_topleft_position = _position - _size / 2.0


## Returns the size of this rectangle.
func get_size() -> Vector2:
	return _size


## Sets the size of this rectangle.
func set_size(value: Vector2) -> void:
	_size = value
	_update_topleft_position()
	emit_changed()


## Returns the center position of this rectangle.
func get_position() -> Vector2:
	return _position


## Sets the center position of this rectangle.
func set_position(value: Vector2) -> void:
	_position = value
	_update_topleft_position()
	emit_changed()


## Sets both center position and size at the same time for this rectangle.
func set_size_and_position(value: Rect2) -> void:
	_size = value.size
	_position = value.position
	_update_topleft_position()
	emit_changed()


func get_center_rect() -> Rect2:
	return Rect2(position, size)


## Returns the base area for this rectangle.
func get_boundary_rect() -> Rect2:
	return Rect2(_topleft_position, _size)
