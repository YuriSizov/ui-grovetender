###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasElements extends Control

var _current_canvas: UICanvas = null
var _element_data_map: Dictionary = {}


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
		_current_canvas.element_removed.disconnect(_remove_canvas_element)
		_current_canvas.elements_sorted.disconnect(_sort_canvas_elements)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_set_canvas_elements()
		
		_current_canvas.element_created.connect(_create_canvas_element)
		_current_canvas.element_removed.connect(_remove_canvas_element)
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
	_element_data_map[element] = canvas_element
	
	add_child(canvas_element)


func _remove_canvas_element(element: BaseUIElement) -> void:
	if not _element_data_map.has(element):
		return
	
	var canvas_element: CanvasElementControl = _element_data_map[element]
	remove_child(canvas_element)
	canvas_element.queue_free()
	
	_element_data_map.erase(element)


func _set_canvas_elements() -> void:
	if not _current_canvas:
		return
	
	for element in _current_canvas.elements:
		_create_canvas_element(element)


func _clear_canvas_elements() -> void:
	_element_data_map.clear()
	
	for canvas_element: CanvasElementControl in get_children():
		remove_child(canvas_element)
		canvas_element.queue_free()


func _sort_canvas_elements(owner_element: CompositeElement) -> void:
	if not _current_canvas:
		return
	
	# TODO: Potentially optimize this to avoid doing excessive work when the state is already correct.
	for canvas_element: CanvasElementControl in get_children():
		remove_child(canvas_element)
	
	for element in _current_canvas.elements:
		if not _element_data_map.has(element):
			continue # This shouldn't happen.
		
		var canvas_element: CanvasElementControl = _element_data_map[element]
		add_child(canvas_element)


func find_element_at_position(canvas_position: Vector2) -> BaseUIElement:
	var drawn_elements_count := get_child_count()
	for i in drawn_elements_count:
		var element_index := drawn_elements_count - 1 - i # Iterate backwards, from the topmost.
		var canvas_element: CanvasElementControl = get_child(element_index)
		
		if not canvas_element.is_visible_on_screen():
			continue
		
		if canvas_element.is_selectable(canvas_position):
			return canvas_element.data
	
	return null
