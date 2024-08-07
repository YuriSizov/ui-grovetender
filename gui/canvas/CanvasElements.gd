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
		_current_canvas.elements_sorted.disconnect(_resort_canvas_elements)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_set_canvas_elements()
		
		_current_canvas.element_created.connect(_create_canvas_element)
		_current_canvas.element_removed.connect(_remove_canvas_element)
		_current_canvas.elements_sorted.connect(_resort_canvas_elements)


func _update_canvas_transform() -> void:
	if not EndlessCanvas.get_instance():
		return
	
	scale = EndlessCanvas.get_instance().get_elements_scale_vector()
	position = Vector2.ZERO - EndlessCanvas.get_instance().get_elements_offset()


# Element management.

func _get_owner_control(owner_element: BaseUIElement) -> Control:
	if not owner_element:
		return self
	
	return owner_element.get_control()


func _create_canvas_element(element: BaseUIElement) -> void:
	var owner_control := _get_owner_control(element.get_owner())
	if not owner_control:
		printerr("CanvasElements: Attempting to create an element control but the owner control is invalid.")
		return
	
	var canvas_element := CanvasElementControl.new()
	canvas_element.name = "%sControl" % [ element.element_name ]
	canvas_element.data = element
	_element_data_map[element] = canvas_element
	
	owner_control.add_child(canvas_element)
	
	if element is CompositeElement:
		for sub_element in element.elements:
			_create_canvas_element(sub_element)


func _remove_canvas_element(element: BaseUIElement) -> void:
	if not _element_data_map.has(element):
		return
	
	var canvas_element: CanvasElementControl = _element_data_map[element]
	canvas_element.get_parent().remove_child(canvas_element)
	canvas_element.queue_free()
	
	_element_data_map.erase(element)


func _set_canvas_elements() -> void:
	if not _current_canvas:
		return
	
	for element in _current_canvas.elements:
		_create_canvas_element(element)


func _clear_canvas_elements() -> void:
	for canvas_element: CanvasElementControl in _element_data_map.values():
		canvas_element.get_parent().remove_child(canvas_element)
		canvas_element.queue_free()
	
	_element_data_map.clear()


func _resort_canvas_elements(owner_element: CompositeElement) -> void:
	if not _current_canvas:
		return
	
	var owner_elements := owner_element.elements if owner_element else _current_canvas.elements
	var owner_control := _get_owner_control(owner_element)
	if not owner_control:
		return
	
	# First remove all elements from the owner control.
	# TODO: Potentially optimize this to avoid doing excessive work when the state is already correct.
	
	for canvas_element: CanvasElementControl in owner_control.get_children():
		owner_control.remove_child(canvas_element)
	
	# Then reinsert the nodes based on the order in the owner element or the current canvas.
	
	for element in owner_elements:
		var canvas_element := element.get_control()
		if not canvas_element:
			continue # This shouldn't happen.
		
		owner_control.add_child(canvas_element)


func _find_child_at_position(owner_control: Control, canvas_position: Vector2) -> BaseUIElement:
	var drawn_elements_count := owner_control.get_child_count()
	for i in drawn_elements_count:
		var element_index := drawn_elements_count - 1 - i # Iterate backwards, from the topmost.
		var canvas_element: CanvasElementControl = owner_control.get_child(element_index)
		if not canvas_element.is_visible_on_screen():
			continue
		
		if canvas_element.data is CompositeElement:
			var child_element := _find_child_at_position(canvas_element, canvas_position)
			if child_element:
				return child_element
		
		if canvas_element.is_selectable(canvas_position):
			return canvas_element.data
	
	return null


func find_element_at_position(canvas_position: Vector2) -> BaseUIElement:
	return _find_child_at_position(self, canvas_position)
