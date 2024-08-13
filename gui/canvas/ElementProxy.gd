###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ElementProxy extends Control

@export var element: UIElement = null:
	set = set_element

@onready var _renderer: Control = %ElementRenderer


func _enter_tree() -> void:
	_update_anchor_position()
	_update_renderer()


func _ready() -> void:
	_renderer.draw.connect(_renderer_draw)


func _notification(what: int) -> void:
	# Since we're working with a packaged scene here, child nodes are available
	# way ahead of ready and can be used pretty much immediately. This fixes the
	# references.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_renderer = %ElementRenderer


func _renderer_draw() -> void:
	if element:
		element.draw_element()


# Element management.

func set_element(value: UIElement) -> void:
	if element == value:
		return
	
	if element:
		element.clear_control_id()
		element.data_changed.disconnect(_update_renderer)
		element.anchor_point_changed.disconnect(_update_anchor_position)
	
	element = value
	
	if element:
		element.set_control_id(_renderer.get_instance_id())
		element.data_changed.connect(_update_renderer)
		element.anchor_point_changed.connect(_update_anchor_position)
	
	_update_anchor_position()
	_update_renderer()


func _update_anchor_position() -> void:
	if not element || not is_inside_tree():
		return
	
	global_position = element.get_anchor_point()


func _update_renderer() -> void:
	if not element || not is_inside_tree():
		return
	
	var element_rect := element.get_local_rect()
	_renderer.position = element_rect.position
	_renderer.size = element_rect.size
	_renderer.queue_redraw()
