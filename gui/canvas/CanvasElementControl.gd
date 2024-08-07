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


func _enter_tree() -> void:
	_update_global_rect()


func _draw() -> void:
	if not data || not is_visible_on_screen():
		return
	
	data.draw()


## Sets the UI element data.
func set_data(value: BaseUIElement) -> void:
	if data:
		data.clear_control_id()
		data.rect_changed.disconnect(_propagate_update_global_rect)
		data.visibility_changed.disconnect(_update_visibility)
		data.properties_changed.disconnect(queue_redraw)
	
	data = value
	
	if data:
		data.set_control_id(get_instance_id())
		data.rect_changed.connect(_propagate_update_global_rect)
		data.visibility_changed.connect(_update_visibility)
		data.properties_changed.connect(queue_redraw)
	
	_update_global_rect()
	_update_visibility()


# Position and sizing.

func _update_global_rect() -> void:
	if not data || not is_inside_tree():
		return
	
	var owner_offset := data.get_owner_offset()
	var element_rect := data.rect.get_bounding_rect()
	position = element_rect.position - owner_offset
	size = element_rect.size
	
	queue_redraw()


func _propagate_update_global_rect() -> void:
	if not data:
		return
	
	# FIXME: Avoid unnecessary calls/propagations because of the bidirectional feedback on rect changes.
	# Right now we have checks to prevent excessive data changes, but the calls are still propagated here,
	# which will result in lags at some point. This should be avoided, perhaps with some dirty flag.
	
	if data is CompositeElement:
		propagate_call("_update_global_rect", [], true)
	else:
		_update_global_rect()


func _update_visibility() -> void:
	if not data:
		return
	
	visible = data.visible


func is_selectable(at_position: Vector2) -> bool:
	if not data:
		return false
	
	return data.can_select(at_position)


## Returns whether this proxy control is currently visible on screen.
# FIXME: Can be optimized with caching.
func is_visible_on_screen() -> bool:
	if not visible || not is_inside_tree() || not is_visible_in_tree():
		return false
	
	var global_rect := get_global_rect()
	if global_rect.end.x < 0 || global_rect.end.y < 0:
		return false
	
	var window_size := get_window().size
	if global_rect.position.x > window_size.x || global_rect.position.y > window_size.y:
		return false
	
	return true
