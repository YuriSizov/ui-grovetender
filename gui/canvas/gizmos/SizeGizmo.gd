###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the size of an element or a group of elements.
class_name SizeGizmo extends BaseGizmo

signal corner_size_changed(corner: Corner, delta: Vector2)
signal side_size_changed(side: Side, delta: Vector2)

var _corner_handles: Array[Rect2] = []
var _side_handles: Array[Rect2] = []

enum ResizeType {
	NONE,
	CORNER,
	SIDE,
}

var _resize_type: ResizeType = ResizeType.NONE
var _resize_index: int = -1


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"SizeGizmo"
	theme_type_variation = &"SizeGizmo"
	
	_corner_handles.resize(4)
	_side_handles.resize(4)


func _draw() -> void:
	# Side handles.
	
	var side_handle_default := get_theme_stylebox("side_handle")
	var side_handle_hover := get_theme_stylebox("side_handle_hover")
	var side_handle_pressed := get_theme_stylebox("side_handle_pressed")
	
	var side_handle_ratio := get_theme_constant("side_handle_percent") / 100.0
	var side_handle_thickness := get_theme_constant("side_handle_thickness")
	
	for i in 4:
		var handle_data := _side_handles[i]
		var handle_base := get_element_global_side(i) - position
		var visual_rect := Rect2()
		
		if i % 2 == 0: # Left/Right.
			visual_rect.size = Vector2(side_handle_thickness, handle_data.size.y * side_handle_ratio)
		else: # Top/Bottom.
			visual_rect.size = Vector2(handle_data.size.x * side_handle_ratio, side_handle_thickness)
		
		match i:
			SIDE_LEFT:
				visual_rect.position = handle_base - Vector2(visual_rect.size.x, visual_rect.size.y / 2.0)
			SIDE_RIGHT:
				visual_rect.position = handle_base - Vector2(0, visual_rect.size.y / 2.0)
			SIDE_TOP:
				visual_rect.position = handle_base - Vector2(visual_rect.size.x / 2.0, visual_rect.size.y)
			SIDE_BOTTOM:
				visual_rect.position = handle_base - Vector2(visual_rect.size.x / 2.0, 0)
		
		if is_hovering() && _resize_type == ResizeType.SIDE && _resize_index == i:
			if is_grabbing():
				draw_style_box(side_handle_pressed, visual_rect)
			else:
				draw_style_box(side_handle_hover, visual_rect)
		else:
			draw_style_box(side_handle_default, visual_rect)
	
	# Corner handles.
	
	var corner_handle_default := get_theme_stylebox("corner_handle")
	var corner_handle_hover := get_theme_stylebox("corner_handle_hover")
	var corner_handle_pressed := get_theme_stylebox("corner_handle_pressed")
	
	var corner_handle_size := get_theme_constant("corner_handle_size")
	var corner_handle_thickness := get_theme_constant("corner_handle_thickness")
	
	for i in 4:
		var handle_base := get_element_global_corner(i) - position
		
		var horizontal_rect := Rect2()
		horizontal_rect.size = Vector2(corner_handle_size, corner_handle_thickness)
		var vertical_rect := Rect2()
		vertical_rect.size = Vector2(corner_handle_thickness, corner_handle_size)
		
		match i:
			CORNER_TOP_LEFT:
				horizontal_rect.position = handle_base - Vector2(vertical_rect.size.x, horizontal_rect.size.y)
				vertical_rect.position = handle_base - Vector2(vertical_rect.size.x, horizontal_rect.size.y)
			CORNER_TOP_RIGHT:
				horizontal_rect.position = handle_base - Vector2(horizontal_rect.size.x - vertical_rect.size.x, horizontal_rect.size.y)
				vertical_rect.position = handle_base - Vector2(0, horizontal_rect.size.y)
			CORNER_BOTTOM_RIGHT:
				horizontal_rect.position = handle_base - Vector2(horizontal_rect.size.x - vertical_rect.size.x, 0)
				vertical_rect.position = handle_base - Vector2(0, vertical_rect.size.y - horizontal_rect.size.y)
			CORNER_BOTTOM_LEFT:
				horizontal_rect.position = handle_base - Vector2(vertical_rect.size.x, 0)
				vertical_rect.position = handle_base - Vector2(vertical_rect.size.x, vertical_rect.size.y - horizontal_rect.size.y)
		
		if is_hovering() && _resize_type == ResizeType.CORNER && _resize_index == i:
			if is_grabbing():
				draw_style_box(corner_handle_pressed, horizontal_rect)
				draw_style_box(corner_handle_pressed, vertical_rect)
			else:
				draw_style_box(corner_handle_hover, horizontal_rect)
				draw_style_box(corner_handle_hover, vertical_rect)
		else:
			draw_style_box(corner_handle_default, horizontal_rect)
			draw_style_box(corner_handle_default, vertical_rect)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


func _get_tooltip(_at_position: Vector2) -> String:
	if not is_hovering():
		return ""
	
	if _resize_type == ResizeType.CORNER:
		match _resize_index:
			CORNER_TOP_LEFT:
				return "Resize by top-left corner"
			CORNER_TOP_RIGHT:
				return "Resize by top-right corner"
			CORNER_BOTTOM_RIGHT:
				return "Resize by bottom-right corner"
			CORNER_BOTTOM_LEFT:
				return "Resize by bottom-left corner"
			
	elif _resize_type == ResizeType.SIDE:
		match _resize_index:
			SIDE_LEFT:
				return "Resize by left side"
			SIDE_TOP:
				return "Resize by top side"
			SIDE_RIGHT:
				return "Resize by right side"
			SIDE_BOTTOM:
				return "Resize by bottom side"
	
	return ""


# Implementation.

func _update_handles() -> void:
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var base_size := Vector2(handle_trigger_size, handle_trigger_size)
	var half_element_size := get_element_global_size() / 2.0
	
	# Corner handles.
	
	for i in 4:
		_corner_handles[i].position = get_element_global_corner(i) - base_size
		_corner_handles[i].size = base_size * 2
	
	# Side handles.
	
	for i in 4:
		if i % 2 == 0: # Left/Right.
			_side_handles[i].position = get_element_global_side(i) - Vector2(base_size.x, half_element_size.y - base_size.y)
			_side_handles[i].size = Vector2(base_size.x * 2, (half_element_size.y - base_size.y) * 2).max(Vector2.ZERO)
		else: # Top/Bottom.
			_side_handles[i].position = get_element_global_side(i) - Vector2(half_element_size.x - base_size.x, base_size.y)
			_side_handles[i].size = Vector2((half_element_size.x - base_size.x) * 2, base_size.y * 2).max(Vector2.ZERO)


func _is_hovering_at(mouse_position: Vector2) -> bool:
	# We use this opportunity to pre-determine which handle we're going to interact with.
	_resize_type = ResizeType.NONE
	_resize_index = -1
	
	# First, test the rough area of this gizmo to exclude all obviously wrong events.
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var rough_rect := get_element_global_rect().grow(handle_trigger_size)
	if not rough_rect.has_point(mouse_position):
		return false
	
	# Then, test corner handles, they take priority over sides.
	for i in 4:
		var handle := _corner_handles[i]
		if handle.has_point(mouse_position):
			_resize_type = ResizeType.CORNER
			_resize_index = i
			return true
	
	# Finally, test side handles.
	for i in 4:
		var handle := _side_handles[i]
		if handle.has_point(mouse_position):
			_resize_type = ResizeType.SIDE
			_resize_index = i
			return true
	
	return false


func get_hovering_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	if _resize_type == ResizeType.CORNER:
		match _resize_index:
			CORNER_TOP_LEFT:
				return Control.CURSOR_FDIAGSIZE
			CORNER_TOP_RIGHT:
				return Control.CURSOR_BDIAGSIZE
			CORNER_BOTTOM_RIGHT:
				return Control.CURSOR_FDIAGSIZE
			CORNER_BOTTOM_LEFT:
				return Control.CURSOR_BDIAGSIZE
			
	elif _resize_type == ResizeType.SIDE:
		match _resize_index:
			SIDE_LEFT:
				return Control.CURSOR_HSIZE
			SIDE_TOP:
				return Control.CURSOR_VSIZE
			SIDE_RIGHT:
				return Control.CURSOR_HSIZE
			SIDE_BOTTOM:
				return Control.CURSOR_VSIZE
	
	return super(mouse_position)


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			if _resize_type == ResizeType.NONE || _resize_index < 0:
				return false
			return true
			
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			return true
	
	return false


func handle_input(event: InputEvent) -> void:
	if not is_hovering():
		return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not is_grabbing() && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			set_grabbing(true)
		
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_resize_type = ResizeType.NONE
			_resize_index = -1
			set_grabbing(false)
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / EndlessCanvas.get_instance().get_elements_scale()
		
		match _resize_type:
			ResizeType.CORNER:
				corner_size_changed.emit(_resize_index, relative)
			ResizeType.SIDE:
				side_size_changed.emit(_resize_index, relative)
