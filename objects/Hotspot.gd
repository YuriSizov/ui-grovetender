###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A subarea of the endless canvas, encapsulating a set of UI items, their layout and behavior.
## Used to define individual scenes and optimize rendering.
class_name Hotspot extends Resource

signal rect_changed()
signal items_changed()

const EXPAND_AREA_SIZE := 40

## The instance ID of the control node for this hotspot. Runtime only.
var control_id: int = 0

## The size of the area encompassing all UI items in this hotspot, plus padding on all sides.
@export var size: Vector2 = Vector2(EXPAND_AREA_SIZE * 2, EXPAND_AREA_SIZE * 2):
	set = set_size
## The position of this hotspot's center.
@export var position: Vector2 = Vector2.ZERO:
	set = set_position

# Cached position used for rendering and input handling.
var _topleft_position: Vector2 = Vector2.ZERO

## The collection of UI items in this hotspot.
@export var items: Array[BaseUIItem] = []


func _init() -> void:
	_update_topleft_position()


# Metadata.

func get_control() -> CanvasHotspot:
	if not is_instance_id_valid(control_id):
		return null
	
	return instance_from_id(control_id)


# Position and sizing.

func _update_topleft_position() -> void:
	_topleft_position = position - size / 2.0


func _update_size() -> void:
	var combined_rect := Rect2()
	
	if items.size() > 0:
		combined_rect = items[0].get_rect()
		for i in items.size():
			if i == 0:
				continue
			
			var item := items[i]
			combined_rect = combined_rect.merge(item.get_rect())
	
	size = combined_rect.size + Vector2(EXPAND_AREA_SIZE * 2, EXPAND_AREA_SIZE * 2)
	position = combined_rect.position + combined_rect.size / 2.0
	_update_topleft_position()


## Sets the size of this hotspot.
func set_size(value: Vector2) -> void:
	size = value
	_update_topleft_position()
	
	rect_changed.emit()


## Sets the center position of this hotspot.
func set_position(value: Vector2) -> void:
	position = value
	_update_topleft_position()
	
	rect_changed.emit()


## Returns the area for this hotspot.
func get_rect() -> Rect2:
	return Rect2(_topleft_position, size)


# Item management.

func assign_item(new_item: BaseUIItem) -> void:
	new_item.owner_id = get_instance_id()
	items.push_back(new_item)
	
	_update_size()
	new_item.rect_changed.connect(_update_size)
	
	items_changed.emit()
