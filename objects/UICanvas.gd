###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The canvas object defines an infinite page in the project, which can
## contain multiple elements and widgets. Users can export canvas as a
## whole, or in parts, as it exists mainly for the convenience of having
## multiple entities in the same visual space, but doesn't limit anything
## otherwise.
class_name UICanvas extends Resource

signal element_created(element: UIElement)
signal element_removed(element: UIElement)
signal element_sorted(element: UIElement, to_index: int)

signal canvas_transformed()

@export var element_group: UIElementGroup = UIElementGroup.new()

# Runtime properties.

const SCALE_STEP := 1.2
const MIN_SCALE := 1.0 / pow(SCALE_STEP, 8.0)
const MAX_SCALE := 1.0 * pow(SCALE_STEP, 4.0)

var _canvas_offset: Vector2 = Vector2.ZERO
var _canvas_scale: float = 1.0


# Element management.

func create_element(owner_element: UICompositeElement, at_position: Vector2) -> void:
	var element := UIElement.new(BaseElementData)
	element.set_anchor_point(at_position)
	
	var owner_group := owner_element.element_group if owner_element else element_group
	owner_group.add(element)
	element_created.emit(element)


func remove_element(element: UIElement) -> void:
	var owner_group := element.get_group()
	if owner_group.erase(element):
		element_removed.emit(element)


func sort_element(element: UIElement, to_index: int) -> void:
	var owner_group := element.get_group()
	if owner_group.move(element, to_index):
		element_sorted.emit(element, to_index)


func group_elements(elements: Array[UIElement]) -> void:
	pass


# Transform management.

func get_canvas_scale() -> float:
	return _canvas_scale


func get_canvas_scale_vector() -> Vector2:
	return Vector2(_canvas_scale, _canvas_scale)


func set_canvas_scale(value: float, towards_position: Vector2) -> void:
	var clean_value := clampf(value, MIN_SCALE, MAX_SCALE)
	if _canvas_scale == clean_value:
		return
	
	var old_offset := (_canvas_offset + towards_position) / _canvas_scale
	_canvas_scale = clean_value
	_canvas_offset = old_offset * _canvas_scale - towards_position
	canvas_transformed.emit()


func get_canvas_offset() -> Vector2:
	return _canvas_offset


func set_canvas_offset(value: Vector2) -> void:
	if _canvas_offset == value:
		return
	
	_canvas_offset = value
	canvas_transformed.emit()


func reset_canvas_transform() -> void:
	_canvas_scale = 1.0
	_canvas_offset = Vector2.ZERO
	canvas_transformed.emit()


func to_canvas_coordinates(ui_position: Vector2) -> Vector2:
	return (ui_position + _canvas_offset) / _canvas_scale


func from_canvas_coordinates(canvas_position: Vector2) -> Vector2:
	return canvas_position * _canvas_scale - _canvas_offset
