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
		_update_transform()
		
		CanvasView.get_instance().canvas_transformed.connect(_update_transform)
		Controller.canvas_changed.connect(_edit_current_canvas)


# Canvas transform.

func _update_transform() -> void:
	if not CanvasView.get_instance():
		return
	
	scale = CanvasView.get_instance().get_canvas_scale_vector()
	position = Vector2.ZERO - CanvasView.get_instance().get_canvas_offset()


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	_clear_element_proxies()
	if _edited_canvas:
		_edited_canvas.element_added.disconnect(_create_element_proxy)
		_edited_canvas.element_removed.disconnect(_destroy_element_proxy)
	
	_edited_canvas = Controller.get_current_canvas()
	
	_create_element_proxies()
	if _edited_canvas:
		_edited_canvas.element_added.connect(_create_element_proxy)
		_edited_canvas.element_removed.connect(_destroy_element_proxy)


func _clear_element_proxies() -> void:
	for element in _element_proxy_map:
		_destroy_element_proxy(element)


func _destroy_element_proxy(element: UIElement) -> void:
	if not _element_proxy_map.has(element):
		return
	
	var proxy_node: ElementProxy = _element_proxy_map[element]
	proxy_node.get_parent().remove_child(proxy_node)
	proxy_node.queue_free()


func _create_element_proxies() -> void:
	if not _edited_canvas:
		return
	
	for element in _edited_canvas.elements:
		_create_element_proxy(element)


func _create_element_proxy(element: UIElement) -> void:
	var proxy_node := ELEMENT_PROXY_SCENE.instantiate()
	proxy_node.element = element
	add_child(proxy_node)
	
	_element_proxy_map[element] = proxy_node
