###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasElements extends Control

var _current_canvas: UICanvas = null
var _elements_data_map: Dictionary = {}


func _ready() -> void:
	_edit_current_canvas()
	_update_canvas_transform()
	
	EndlessCanvas.get_instance().canvas_transformed.connect(_update_canvas_transform)
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


# Canvas management.

func _edit_current_canvas() -> void:
	if _current_canvas:
		_clear_canvas_elements()
		
		_current_canvas.element_created.disconnect(_create_canvas_element)
		_current_canvas.elements_sorted.disconnect(_sort_canvas_elements)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_set_canvas_elements()
		
		_current_canvas.element_created.connect(_create_canvas_element)
		_current_canvas.elements_sorted.connect(_sort_canvas_elements)


func _update_canvas_transform() -> void:
	if not EndlessCanvas.get_instance():
		return
	
	scale = EndlessCanvas.get_instance().get_elements_scale_vector()
	position = Vector2.ZERO - EndlessCanvas.get_instance().get_elements_offset()


# Element management.

func _create_canvas_element(element: BaseUIElement) -> void:
	var canvas_element := CanvasElementControl.new()
	canvas_element.data = element
	_elements_data_map[element] = canvas_element
	
	add_child(canvas_element)


func _set_canvas_elements() -> void:
	if not _current_canvas:
		return
	
	for element in _current_canvas.elements:
		_create_canvas_element(element)


func _clear_canvas_elements() -> void:
	_elements_data_map.clear()
	
	for canvas_element: CanvasElementControl in get_children():
		remove_child(canvas_element)
		canvas_element.queue_free()


func _sort_canvas_elements() -> void:
	if not _current_canvas:
		return
	
	# TODO: Potentially optimize this to avoid doing excessive work when the state is already correct.
	for canvas_element: CanvasElementControl in get_children():
		remove_child(canvas_element)
	
	for element in _current_canvas.elements:
		if not _elements_data_map.has(element):
			continue # This shouldn't happen.
		
		var canvas_element: CanvasElementControl = _elements_data_map[element]
		add_child(canvas_element)
