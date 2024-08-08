###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A fake element used for storing selection data. Doesn't belong to any canvas and isn't saved
## to disk alongside the project.
class_name SelectionElement extends BaseUIElement

signal selection_changed()

## The collection of selected elements.
var _elements: Array[BaseUIElement] = []


func _init() -> void:
	super()
	element_name = "Multiple Selected"


# Selection management.

func select_element(element: BaseUIElement) -> void:
	if _elements.has(element):
		return
	
	_elements.push_back(element)
	element.set_selected(true)
	selection_changed.emit()


func deselect_element(element: BaseUIElement) -> void:
	if not _elements.has(element):
		return
	
	_elements.erase(element)
	element.set_selected(false)
	selection_changed.emit()


func is_element_selected(element: BaseUIElement) -> bool:
	return _elements.has(element)


func get_selection_size() -> int:
	return _elements.size()


func get_selection() -> Array[BaseUIElement]:
	return _elements.duplicate()


func get_first_element() -> BaseUIElement:
	if _elements.is_empty():
		return null
	
	return _elements[0]


func clear_selection() -> void:
	for element in _elements:
		element.set_selected(false)
	
	_elements.clear()
	selection_changed.emit()


# Implementation.

func can_select(_at_position: Vector2) -> bool:
	# Selecting a selection, wouldn't that be something?
	return false


func get_gizmos(_editing_mode: int) -> Array[BaseGizmo]:
	# Selection itself is not editable, but we show the boundary gizmo for each selected element.
	var gizmos: Array[BaseGizmo] = []
	
	for element in _elements:
		var boundary_gizmo := BoundaryGizmo.new(element)
		gizmos.push_back(boundary_gizmo)
	
	return gizmos


func get_editable_properties(_editing_mode: int) -> Array[PropertyEditor]:
	# Selection itself is not editable.
	var properties: Array[PropertyEditor] = []
	
	return properties
