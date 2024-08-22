###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PositionGizmo extends BaseGizmo

signal anchor_changed(delta: Vector2)
signal offset_changed(delta: Vector2)

enum HandleType {
	HANDLE_NONE = -1,
	HANDLE_OFFSET,
	HANDLE_ANCHOR,
}

var _hovered_handle_id: HandleType = HandleType.HANDLE_NONE


func _init(element: UIElement, element_data: BaseElementData) -> void:
	super(element, element_data)
	name = &"PositionGizmo"
	theme_type_variation = &"PositionGizmo"


func _draw() -> void:
	var handle_default_tint := get_theme_color("handle_default_tint")
	var handle_hover_tint := get_theme_color("handle_hover_tint")
	var handle_pressed_tint := get_theme_color("handle_pressed_tint")
	
	var offset_handle_icon := get_theme_icon("offset_handle")
	
	for handle_data in get_handles():
		var handle_modulate := handle_default_tint
		if is_hovering() && handle_data.id == _hovered_handle_id:
			if is_grabbing():
				handle_modulate = handle_pressed_tint
			else:
				handle_modulate = handle_hover_tint
		
		draw_texture_rect(offset_handle_icon, handle_data.get_render_rect(), false, handle_modulate)


# Implementation.

# Override.
func _update_handles_transform() -> void:
	var render_size := get_theme_constant("handle_render_size")
	var trigger_size := get_theme_constant("handle_trigger_size")
	
	var render_area := Vector2(render_size, render_size)
	var trigger_area := Vector2(trigger_size, trigger_size)
	
	set_handle(HandleType.HANDLE_OFFSET, _local_element_rect.get_center(), trigger_area, render_area)
	set_handle(HandleType.HANDLE_ANCHOR, _local_element_anchor, trigger_area, render_area)


# Override.
func _test_point(point: Vector2) -> bool:
	var handles := get_handles()
	
	# Iterate in reverse, so the topmost drawn handle is the first to receive the input.
	for i in range(handles.size() - 1, -1, -1):
		var handle_data := handles[i]
		if handle_data.test_point_in_trigger(point):
			_hovered_handle_id = handle_data.id as HandleType
			
			match _hovered_handle_id:
				HandleType.HANDLE_OFFSET:
					set_handle_feedback(Control.CURSOR_DRAG, "Adjust the offset of the element.")
				HandleType.HANDLE_ANCHOR:
					set_handle_feedback(Control.CURSOR_DRAG, "Move the element on canvas.")
			return true
	
	return false


# Override.
func _handle_mouse_input(event: InputEventMouse) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not is_grabbing() && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			start_grabbing()
			accept_event()
		
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			stop_grabbing()
			accept_event()
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / _canvas.get_canvas_scale()
		
		match _hovered_handle_id:
			HandleType.HANDLE_OFFSET:
				offset_changed.emit(relative)
			HandleType.HANDLE_ANCHOR:
				anchor_changed.emit(relative)
		
		accept_event()
