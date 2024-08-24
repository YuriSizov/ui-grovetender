###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasSelection extends RefCounted

signal selection_changed()

var _selected_elements: Array[UIElement] = []


# Selection management.

func select(element: UIElement) -> void:
	if not element:
		return
	if _selected_elements.has(element):
		return
	
	_selected_elements.push_back(element)
	element.editor_state_selected.connect(selection_changed.emit)
	element.set_selected(true)
	selection_changed.emit()


func select_multiple(elements: Array[UIElement]) -> void:
	if elements.is_empty():
		return
	
	for element in elements:
		if _selected_elements.has(element):
			continue
		
		_selected_elements.push_back(element)
		element.editor_state_selected.connect(selection_changed.emit)
		element.set_selected(true)
	
	selection_changed.emit()


func deselect(element: UIElement) -> void:
	if not element:
		return
	if not _selected_elements.has(element):
		return
	
	_selected_elements.erase(element)
	element.editor_state_selected.disconnect(selection_changed.emit)
	element.set_selected(false)
	selection_changed.emit()


func deselect_multiple(elements: Array[UIElement]) -> void:
	if elements.is_empty():
		return
	
	for element in elements:
		if not _selected_elements.has(element):
			continue
		
		_selected_elements.erase(element)
		element.editor_state_selected.disconnect(selection_changed.emit)
		element.set_selected(false)
	
	selection_changed.emit()


func clear() -> void:
	if _selected_elements.is_empty():
		return
	
	for element in _selected_elements:
		element.editor_state_selected.disconnect(selection_changed.emit)
		element.set_selected(false)
	
	_selected_elements.clear()
	selection_changed.emit()


# Selection data.

func is_selected(element: UIElement) -> bool:
	return _selected_elements.has(element)


func get_selection_size() -> int:
	return _selected_elements.size()


func get_selection() -> Array[UIElement]:
	return _selected_elements.duplicate()


func get_first_selected() -> UIElement:
	if _selected_elements.is_empty():
		return null
	
	return _selected_elements[0]
