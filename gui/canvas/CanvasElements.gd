###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasElements extends Control

const ELEMENT_PROXY_SCENE := preload("res://gui/canvas/ElementProxy.tscn")

var _edited_canvas: UICanvas = null
var _element_proxy_map: Dictionary = {}


func _ready() -> void:
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


# Canvas transform.

func _update_transform() -> void:
	if not _edited_canvas:
		return
	
	scale = _edited_canvas.get_canvas_scale_vector()
	position = Vector2.ZERO - _edited_canvas.get_canvas_offset()


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	_clear_element_proxies()
	
	if _edited_canvas:
		_edited_canvas.element_created.disconnect(_create_element_proxy)
		_edited_canvas.element_removed.disconnect(_destroy_element_proxy)
		_edited_canvas.element_sorted.disconnect(_sort_element_proxy)
		_edited_canvas.canvas_transformed.disconnect(_update_transform)
	
	_edited_canvas = Controller.get_current_canvas()
	
	if _edited_canvas:
		_edited_canvas.element_created.connect(_create_element_proxy)
		_edited_canvas.element_removed.connect(_destroy_element_proxy)
		_edited_canvas.element_sorted.connect(_sort_element_proxy)
		_edited_canvas.canvas_transformed.connect(_update_transform)
	
	_update_transform()
	_create_element_proxies()


func _create_element_proxy(element: UIElement) -> void:
	var proxy_node := ELEMENT_PROXY_SCENE.instantiate()
	proxy_node.element = element
	add_child(proxy_node)
	
	_element_proxy_map[element] = proxy_node


func _create_element_proxies() -> void:
	if not _edited_canvas:
		return
	
	for element in _edited_canvas.element_group.elements:
		_create_element_proxy(element)


func _destroy_element_proxy(element: UIElement) -> void:
	if not _element_proxy_map.has(element):
		return
	
	var proxy_node: ElementProxy = _element_proxy_map[element]
	proxy_node.get_parent().remove_child(proxy_node)
	proxy_node.queue_free()


func _clear_element_proxies() -> void:
	for element in _element_proxy_map:
		_destroy_element_proxy(element)


func _sort_element_proxy(element: UIElement, to_index: int) -> void:
	if not _element_proxy_map.has(element):
		return
	
	var proxy_node: ElementProxy = _element_proxy_map[element]
	proxy_node.get_parent().move_child(proxy_node, to_index)


# Element lookup.

func find_element_at_position(canvas_position: Vector2) -> UIElement:
	return _find_child_at_position(self, canvas_position)


func _find_child_at_position(owner_control: Control, canvas_position: Vector2) -> UIElement:
	var drawn_elements_count := owner_control.get_child_count()
	for i in drawn_elements_count:
		var element_index := drawn_elements_count - 1 - i # Iterate backwards, from the topmost.
		var proxy_node: ElementProxy = owner_control.get_child(element_index)
		if not proxy_node.is_visible_on_screen() || not proxy_node.element:
			continue
		
		if proxy_node.element.has_point(canvas_position):
			return proxy_node.element
	
	return null


func find_elements_in_rect(canvas_rect: Rect2) -> Array[UIElement]:
	var elements: Array[UIElement] = []
	_find_children_in_rect(self, canvas_rect, elements)
	
	return elements


func _find_children_in_rect(owner_control: Control, canvas_rect: Rect2, found_children: Array) -> void:
	var drawn_elements_count := owner_control.get_child_count()
	for i in drawn_elements_count:
		var element_index := drawn_elements_count - 1 - i # Iterate backwards, from the topmost.
		var proxy_node: ElementProxy = owner_control.get_child(element_index)
		if not proxy_node.is_visible_on_screen() || not proxy_node.element:
			continue
		
		if proxy_node.element.is_inside_area(canvas_rect):
			found_children.push_back(proxy_node.element)
