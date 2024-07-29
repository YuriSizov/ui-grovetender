###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A proxy element for rendering UI elements.
class_name CanvasElementControl extends Control

## The data resource for the rendered UI element.
@export var data: BaseUIElement = null:
	set = set_data


func _init() -> void:
	name = &"CanvasElementControl"
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	if not data || not is_visible_on_screen():
		return
	
	if data.visible:
		data.draw()


## Sets the UI element data.
func set_data(value: BaseUIElement) -> void:
	if data:
		data.clear_control_id()
		data.rect_changed.disconnect(_on_data_rect_changed)
		data.visibility_changed.disconnect(queue_redraw)
		data.properties_changed.disconnect(queue_redraw)
	
	data = value
	
	if data:
		data.set_control_id(get_instance_id())
		data.rect_changed.connect(_on_data_rect_changed)
		data.visibility_changed.connect(queue_redraw)
		data.properties_changed.connect(queue_redraw)
		_on_data_rect_changed()


# Position and sizing.

func _on_data_rect_changed() -> void:
	var element_rect := data.rect.get_bounding_rect()
	position = element_rect.position
	size = element_rect.size
	
	queue_redraw()


func is_selectable(at_position: Vector2) -> bool:
	if not data:
		return false
	
	var element_rect := data.rect.get_bounding_rect()
	return element_rect.has_point(at_position)


## Returns whether this proxy control is currently visible on screen.
# FIXME: Can be optimized with caching.
func is_visible_on_screen() -> bool:
	if not is_inside_tree() || not visible || not is_visible_in_tree():
		return false
	
	var global_rect := get_global_rect()
	if global_rect.end.x < 0 || global_rect.end.y < 0:
		return false
	
	var window_size := get_window().size
	if global_rect.position.x > window_size.x || global_rect.position.y > window_size.y:
		return false
	
	return true
