###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A visual representation of a hotspot.
class_name CanvasHotspot extends Control

## The data resource for the hotspot.
@export var data: Hotspot = null:
	set = set_data


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	theme_type_variation = &"CanvasHotspot"


func _draw() -> void:
	if not data || not is_visible_on_screen():
		return
	
	var available_rect := Rect2(Vector2.ZERO, size)
	
	# Draw faint background for the hotspot.
	var background_color := get_theme_color("background_color")
	var border_color := get_theme_color("border_color")
	var border_size := get_theme_constant("border_size")
	
	draw_rect(available_rect, background_color)
	draw_rect(available_rect, border_color, false, border_size)
	
	# Draw items.
	for ui_item in data.items:
		ui_item.render()


## Sets the hotspot data.
func set_data(value: Hotspot) -> void:
	if data:
		data.rect_changed.disconnect(_on_data_rect_changed)
		data.items_changed.disconnect(queue_redraw)
	
	data = value
	
	if data:
		data.control_id = get_instance_id()
		
		data.rect_changed.connect(_on_data_rect_changed)
		data.items_changed.connect(queue_redraw)


# Position and sizing.

func _on_data_rect_changed() -> void:
	var hotspot_rect := data.get_rect()
	position = hotspot_rect.position
	size = hotspot_rect.size
	
	queue_redraw()


## Returns whether the hotspot is currently visible on screen.
# FIXME: Can be optimized with caching.
func is_visible_on_screen() -> bool:
	if not is_inside_tree():
		return false
	
	if not visible || not is_visible_in_tree():
		return false
	
	var hotspot_rect := get_global_rect()
	var window_size := get_window().size
	if hotspot_rect.position.x > window_size.x || hotspot_rect.position.y > window_size.y || hotspot_rect.end.x < 0 || hotspot_rect.end.y < 0:
		return false
	
	return true
