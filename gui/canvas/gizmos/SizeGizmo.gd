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

var _corner_styleboxes: Array[StyleBox] = []


func _init() -> void:
	super()
	name = &"SizeGizmo"
	theme_type_variation = &"SizeGizmo"
	
	_corner_handles.resize(4)
	_side_handles.resize(4)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()


func _update_theme() -> void:
	_corner_styleboxes.clear()
	_corner_styleboxes.resize(4 * 3)
	
	# Make the styleboxes into arrow shapes, pointing in corresponding directions.
	
	var corner_handle_default := get_theme_stylebox("corner_handle")
	var corner_handle_hover := get_theme_stylebox("corner_handle_hover")
	var corner_handle_pressed := get_theme_stylebox("corner_handle_pressed")
	
	for i in 4:
		var corner_arrow_default: StyleBoxFlat = corner_handle_default.duplicate()
		var corner_arrow_hover: StyleBoxFlat = corner_handle_hover.duplicate()
		var corner_arrow_pressed: StyleBoxFlat = corner_handle_pressed.duplicate()
		
		# Only draw the sides which form an arrow in the corresponding direction.
		
		if i == CORNER_TOP_RIGHT || i == CORNER_BOTTOM_RIGHT:
			corner_arrow_default.border_width_left = 0
			corner_arrow_hover.border_width_left = 0
			corner_arrow_pressed.border_width_left = 0
		
		if i == CORNER_TOP_LEFT || i == CORNER_BOTTOM_LEFT:
			corner_arrow_default.border_width_right = 0
			corner_arrow_hover.border_width_right = 0
			corner_arrow_pressed.border_width_right = 0
		
		if i == CORNER_BOTTOM_LEFT || i == CORNER_BOTTOM_RIGHT:
			corner_arrow_default.border_width_top = 0
			corner_arrow_hover.border_width_top = 0
			corner_arrow_pressed.border_width_top = 0
		
		if i == CORNER_TOP_LEFT || i == CORNER_TOP_RIGHT:
			corner_arrow_default.border_width_bottom = 0
			corner_arrow_hover.border_width_bottom = 0
			corner_arrow_pressed.border_width_bottom = 0
		
		# Avoid bending artifacts on partially rendered corners.
		
		if i == CORNER_TOP_LEFT || i == CORNER_BOTTOM_RIGHT:
			corner_arrow_default.corner_radius_top_right = 0
			corner_arrow_default.corner_radius_bottom_left = 0
			corner_arrow_hover.corner_radius_top_right = 0
			corner_arrow_hover.corner_radius_bottom_left = 0
			corner_arrow_pressed.corner_radius_top_right = 0
			corner_arrow_pressed.corner_radius_bottom_left = 0
		
		elif i == CORNER_TOP_RIGHT || i == CORNER_BOTTOM_LEFT:
			corner_arrow_default.corner_radius_top_left = 0
			corner_arrow_default.corner_radius_bottom_right = 0
			corner_arrow_hover.corner_radius_top_left = 0
			corner_arrow_hover.corner_radius_bottom_right = 0
			corner_arrow_pressed.corner_radius_top_left = 0
			corner_arrow_pressed.corner_radius_bottom_right = 0
		
		_corner_styleboxes[i * 3 + 0] = corner_arrow_default
		_corner_styleboxes[i * 3 + 1] = corner_arrow_hover
		_corner_styleboxes[i * 3 + 2] = corner_arrow_pressed


func _draw() -> void:
	var side_handle_default := get_theme_stylebox("side_handle")
	var side_handle_hover := get_theme_stylebox("side_handle_hover")
	var side_handle_pressed := get_theme_stylebox("side_handle_pressed")
	var side_handle_size := get_theme_constant("side_handle_size")
	
	var corner_handle_default := get_theme_stylebox("corner_handle")
	var corner_handle_hover := get_theme_stylebox("corner_handle_hover")
	var corner_handle_pressed := get_theme_stylebox("corner_handle_pressed")
	var corner_handle_size := get_theme_constant("corner_handle_size")
	
	# Side handles.
	for i in 4:
		var handle := _side_handles[i]
		
		var visual_rect := Rect2()
		visual_rect.position = handle.position - position
		visual_rect.size = handle.size
		
		if i % 2 == 0: # Left/Right.
			var handle_padding_x := -(visual_rect.size.x - side_handle_size) / 2.0
			var handle_padding_y := -(visual_rect.size.y / 4.0)
			visual_rect = visual_rect.grow_individual(handle_padding_x, handle_padding_y, handle_padding_x, handle_padding_y)
		else: # Top/Bottom.
			var handle_padding_x := -(visual_rect.size.x / 4.0)
			var handle_padding_y := -(visual_rect.size.y - side_handle_size) / 2.0
			visual_rect = visual_rect.grow_individual(handle_padding_x, handle_padding_y, handle_padding_x, handle_padding_y)
		
		if visual_rect.size.x < 0 || visual_rect.size.y < 0:
			continue
		
		match i:
			SIDE_LEFT:
				visual_rect.position.x -= visual_rect.size.x / 2.0
			SIDE_RIGHT:
				visual_rect.position.x += visual_rect.size.x / 2.0
			SIDE_TOP:
				visual_rect.position.y -= visual_rect.size.y / 2.0
			SIDE_BOTTOM:
				visual_rect.position.y += visual_rect.size.y / 2.0
		
		if is_hovering() && _resize_type == ResizeType.SIDE && _resize_index == i:
			if is_grabbing():
				draw_style_box(side_handle_pressed, visual_rect)
			else:
				draw_style_box(side_handle_hover, visual_rect)
		else:
			draw_style_box(side_handle_default, visual_rect)
	
	# Corner handles.
	for i in 4:
		var handle = _corner_handles[i]
		
		var visual_rect := Rect2()
		visual_rect.position = handle.position - position
		visual_rect.size = Vector2(corner_handle_size, corner_handle_size)
		var visual_offset := Vector2.ONE
		
		match i:
			CORNER_TOP_LEFT:
				visual_rect.position += Vector2(handle.size.x, handle.size.y) / 2.0
				visual_offset.x = -1
				visual_offset.y = -1
			CORNER_TOP_RIGHT:
				visual_rect.position += Vector2(0, handle.size.y) / 2.0
				visual_offset.x = 1
				visual_offset.y = -1
			CORNER_BOTTOM_RIGHT:
				visual_rect.position += Vector2(0, 0) / 2.0
				visual_offset.x = 1
				visual_offset.y = 1
			CORNER_BOTTOM_LEFT:
				visual_rect.position += Vector2(handle.size.x, 0) / 2.0
				visual_offset.x = -1
				visual_offset.y = 1
		
		if is_hovering() && _resize_type == ResizeType.CORNER && _resize_index == i:
			if is_grabbing():
				var border_width := (corner_handle_pressed as StyleBoxFlat).border_width_left
				visual_rect.position += visual_offset * border_width
				
				draw_style_box(_corner_styleboxes[i * 3 + 2], visual_rect)
			else:
				var border_width := (corner_handle_hover as StyleBoxFlat).border_width_left
				visual_rect.position += visual_offset * border_width
				
				draw_style_box(_corner_styleboxes[i * 3 + 1], visual_rect)
		else:
			var border_width := (corner_handle_default as StyleBoxFlat).border_width_left
			visual_rect.position += visual_offset * border_width
			
			draw_style_box(_corner_styleboxes[i * 3 + 0], visual_rect)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


# Implementation.

func _update_handles() -> void:
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var base_size := Vector2(handle_trigger_size, handle_trigger_size)
	var half_element_size := get_element_global_size() / 2.0
	
	# Corner handles.
	
	_corner_handles[CORNER_TOP_LEFT].position = position + Vector2(-half_element_size.x, -half_element_size.y) - base_size
	_corner_handles[CORNER_TOP_LEFT].size = base_size * 2
	
	_corner_handles[CORNER_TOP_RIGHT].position = position + Vector2(half_element_size.x, -half_element_size.y) - base_size
	_corner_handles[CORNER_TOP_RIGHT].size = base_size * 2
	
	_corner_handles[CORNER_BOTTOM_RIGHT].position = position + Vector2(half_element_size.x, half_element_size.y) - base_size
	_corner_handles[CORNER_BOTTOM_RIGHT].size = base_size * 2
	
	_corner_handles[CORNER_BOTTOM_LEFT].position = position + Vector2(-half_element_size.x, half_element_size.y) - base_size
	_corner_handles[CORNER_BOTTOM_LEFT].size = base_size * 2
	
	# Side handles.
	
	_side_handles[SIDE_LEFT].position = position + Vector2(-half_element_size.x, -half_element_size.y) + Vector2(-base_size.x, base_size.y)
	_side_handles[SIDE_LEFT].size = Vector2(base_size.x * 2, (half_element_size.y - base_size.y) * 2).max(Vector2.ZERO)
	
	_side_handles[SIDE_RIGHT].position = position + Vector2(half_element_size.x, -half_element_size.y) + Vector2(-base_size.x, base_size.y)
	_side_handles[SIDE_RIGHT].size = Vector2(base_size.x * 2, (half_element_size.y - base_size.y) * 2).max(Vector2.ZERO)
	
	_side_handles[SIDE_TOP].position = position + Vector2(-half_element_size.x, -half_element_size.y) + Vector2(base_size.x, -base_size.y)
	_side_handles[SIDE_TOP].size = Vector2((half_element_size.x - base_size.x) * 2, base_size.y * 2).max(Vector2.ZERO)
	
	_side_handles[SIDE_BOTTOM].position = position + Vector2(-half_element_size.x, half_element_size.y) + Vector2(base_size.x, -base_size.y)
	_side_handles[SIDE_BOTTOM].size = Vector2((half_element_size.x - base_size.x) * 2, base_size.y * 2).max(Vector2.ZERO)


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
