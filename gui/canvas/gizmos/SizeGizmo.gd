###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name SizeGizmo extends BaseGizmo

signal corner_size_changed(corner: Corner, delta: Vector2)
signal corner_size_all_changed(corner: Corner, delta: Vector2)
signal corner_size_ratio_changed(corner: Corner, delta: Vector2)
signal corner_size_ratio_all_changed(corner: Corner, delta: Vector2)

signal side_size_changed(side: Side, delta: Vector2)
signal side_size_all_changed(side: Side, delta: Vector2)
signal side_size_opposite_changed(side: Side, delta: Vector2)

enum HandleType {
	HANDLE_CORNER,
	HANDLE_SIDE,
}

var _hovered_handle_id: int = -1


func _init(element: UIElement, element_data: BaseElementData) -> void:
	super(element, element_data)
	name = &"SizeGizmo"
	theme_type_variation = &"SizeGizmo"


func _draw() -> void:
	var handle_default_tint := get_theme_color("handle_default_tint")
	var handle_hover_tint := get_theme_color("handle_hover_tint")
	var handle_pressed_tint := get_theme_color("handle_pressed_tint")
	
	var corner_tl_handle_icon := get_theme_icon("corner_tl_handle")
	var corner_tr_handle_icon := get_theme_icon("corner_tr_handle")
	var corner_br_handle_icon := get_theme_icon("corner_br_handle")
	var corner_bl_handle_icon := get_theme_icon("corner_bl_handle")
	var corner_icons: Array[Texture2D] = [
		corner_tl_handle_icon,
		corner_tr_handle_icon,
		corner_br_handle_icon,
		corner_bl_handle_icon,
	]
	
	var side_handle_icon := get_theme_icon("side_handle")
	var side_handle_stretch_margin := get_theme_constant("side_handle_stretch_margin")
	
	for handle_data in get_handles():
		var handle_modulate := handle_default_tint
		if is_hovering() && handle_data.id == _hovered_handle_id:
			if is_grabbing():
				handle_modulate = handle_pressed_tint
			else:
				handle_modulate = handle_hover_tint
		
		var handle_type := handle_data.id >> 4
		var handle_index := handle_data.id & 0x0F
		
		match handle_type:
			HandleType.HANDLE_CORNER:
				var corner_handle_icon := corner_icons[handle_index]
				draw_texture_rect(corner_handle_icon, handle_data.get_render_rect(), false, handle_modulate)
			
			HandleType.HANDLE_SIDE:
				var handle_margins := [ side_handle_stretch_margin, side_handle_stretch_margin, side_handle_stretch_margin, side_handle_stretch_margin ]
				handle_margins[handle_index % 2 + 0] = 0
				handle_margins[handle_index % 2 + 2] = 0
				
				DrawingUtil.draw_texture_ninepatch(
					get_canvas_item(), side_handle_icon, handle_data.get_render_rect(),
					handle_margins, RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH,
					handle_modulate
				)


# Implementation.

# Override.
func _update_handles_transform() -> void:
	var corner_render_size := get_theme_constant("corner_handle_render_size")
	var corner_trigger_size := get_theme_constant("corner_handle_trigger_size")
	var side_render_size := get_theme_constant("side_handle_render_size")
	var side_trigger_size := get_theme_constant("side_handle_trigger_size")
	var side_handle_ratio := get_theme_constant("side_handle_percent") / 100.0
	
	# Side handles.
	for i in 4:
		var handle_id := (HandleType.HANDLE_SIDE << 4) | i
		
		var side_bounds := _local_element_side[i]
		var side_rect := Rect2(side_bounds.x, side_bounds.y, side_bounds.z - side_bounds.x, side_bounds.w - side_bounds.y)
		var side_position := side_rect.get_center()
		
		var side_render_area := Vector2(side_render_size, side_render_size)
		var side_trigger_area := Vector2(side_trigger_size, side_trigger_size)
		
		if i % 2 == 0: # Left/Right
			side_render_area.y = side_rect.size.y * side_handle_ratio
			side_trigger_area.y = side_rect.size.y * side_handle_ratio + side_trigger_size
		
		else: # Top/Bottom
			side_render_area.x = side_rect.size.x * side_handle_ratio
			side_trigger_area.x = side_rect.size.x * side_handle_ratio + side_trigger_size
		
		set_handle(handle_id, side_position, side_trigger_area, side_render_area)
	
	# Corner handles.
	for i in 4:
		var handle_id := (HandleType.HANDLE_CORNER << 4) | i
		
		var corner_position := _local_element_corner[i]
		var corner_render_area := Vector2(corner_render_size, corner_render_size)
		var corner_trigger_area := Vector2(corner_trigger_size, corner_trigger_size)
		
		set_handle(handle_id, corner_position, corner_trigger_area, corner_render_area)


# Override.
func _test_point(point: Vector2) -> bool:
	var handles := get_handles()
	
	# Iterate in reverse, so the topmost drawn handle is the first to receive the input.
	for i in range(handles.size() - 1, -1, -1):
		var handle_data := handles[i]
		if handle_data.test_point_in_trigger(point):
			if _hovered_handle_id == handle_data.id:
				return true
			
			_hovered_handle_id = handle_data.id
			queue_redraw()
			
			var handle_type := _hovered_handle_id >> 4
			var handle_index := _hovered_handle_id & 0x0F
			match handle_type:
				HandleType.HANDLE_CORNER:
					var cursor_type := Control.CURSOR_ARROW
					match handle_index:
						CORNER_TOP_LEFT:
							cursor_type = Control.CURSOR_FDIAGSIZE
						CORNER_TOP_RIGHT:
							cursor_type = Control.CURSOR_BDIAGSIZE
						CORNER_BOTTOM_RIGHT:
							cursor_type = Control.CURSOR_FDIAGSIZE
						CORNER_BOTTOM_LEFT:
							cursor_type = Control.CURSOR_BDIAGSIZE
					
					set_handle_feedback(cursor_type, "Resize by the corner.\nHold Ctrl to resize in all directions.\nHold Shift to resize maintaining proportions.")
				
				HandleType.HANDLE_SIDE:
					var cursor_type := Control.CURSOR_ARROW
					match handle_index:
						SIDE_LEFT:
							cursor_type = Control.CURSOR_HSIZE
						SIDE_TOP:
							cursor_type = Control.CURSOR_VSIZE
						SIDE_RIGHT:
							cursor_type = Control.CURSOR_HSIZE
						SIDE_BOTTOM:
							cursor_type = Control.CURSOR_VSIZE
					
					set_handle_feedback(cursor_type, "Resize by the side.\nHold Ctrl to resize in all directions.\nHold Alt to resize by opposite sides.")
			return true
	
	return false


# Override.
func _handle_mouse_input(event: InputEventMouse) -> void:
	if _hovered_handle_id == -1:
		return
	
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
		
		var handle_type := _hovered_handle_id >> 4
		var handle_index := _hovered_handle_id & 0x0F
		match handle_type:
			HandleType.HANDLE_CORNER:
				# Hold Ctrl and Shift to adjust all corners at the same time, keeping proportions.
				if Input.is_key_pressed(KEY_CTRL) && Input.is_key_pressed(KEY_SHIFT):
					corner_size_ratio_all_changed.emit(handle_index, relative)
				
				# Hold Shift to adjust one corner, keeping proportions.
				elif Input.is_key_pressed(KEY_SHIFT):
					corner_size_ratio_changed.emit(handle_index, relative)
				
				# Hold Ctrl to adjust all corners at the same time.
				elif Input.is_key_pressed(KEY_CTRL):
					corner_size_all_changed.emit(handle_index, relative)
				
				else:
					corner_size_changed.emit(handle_index, relative)
				
			HandleType.HANDLE_SIDE:
				# Hold Ctrl to adjust all sides at the same time.
				if Input.is_key_pressed(KEY_CTRL):
					side_size_all_changed.emit(handle_index, relative)
				
				# Hold Alt to adjust opposite sides at the same time.
				elif Input.is_key_pressed(KEY_ALT):
					side_size_opposite_changed.emit(handle_index, relative)
				
				else:
					side_size_changed.emit(handle_index, relative)
		
		accept_event()
