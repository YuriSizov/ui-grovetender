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
	
	# Make the styleboxes into an arrow shape, fitting each direction.
	
	var corner_handle_default := get_theme_stylebox("corner_handle")
	var corner_handle_hover := get_theme_stylebox("corner_handle_hover")
	var corner_handle_pressed := get_theme_stylebox("corner_handle_pressed")
	
	for i in 4:
		var corner_arrow_default: StyleBoxFlat = corner_handle_default.duplicate()
		var corner_arrow_hover: StyleBoxFlat = corner_handle_hover.duplicate()
		var corner_arrow_pressed: StyleBoxFlat = corner_handle_pressed.duplicate()
		
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
		
		_corner_styleboxes[i * 3 + 0] = corner_arrow_default
		_corner_styleboxes[i * 3 + 1] = corner_arrow_hover
		_corner_styleboxes[i * 3 + 2] = corner_arrow_pressed


func _draw() -> void:
	var side_handle_default := get_theme_stylebox("side_handle")
	var side_handle_hover := get_theme_stylebox("side_handle_hover")
	var side_handle_pressed := get_theme_stylebox("side_handle_pressed")
	var side_handle_size := get_theme_constant("side_handle_size")
	
	var corner_handle_size := get_theme_constant("corner_handle_size")
	
	for i in 4: # Side handles.
		var handle := _side_handles[i]
		
		var handle_rect := Rect2()
		handle_rect.position = handle.position - position
		handle_rect.size = handle.size
		
		if i % 2 == 0: # Left/Right.
			var handle_padding_x := -(handle_rect.size.x - side_handle_size) / 2.0
			var handle_padding_y := -(handle_rect.size.y / 3.0)
			handle_rect = handle_rect.grow_individual(handle_padding_x, handle_padding_y, handle_padding_x, handle_padding_y)
		else: # Top/Bottom.
			var handle_padding_x := -(handle_rect.size.x / 3.0)
			var handle_padding_y := -(handle_rect.size.y - side_handle_size) / 2.0
			handle_rect = handle_rect.grow_individual(handle_padding_x, handle_padding_y, handle_padding_x, handle_padding_y)
		
		if handle_rect.size.x < 0 || handle_rect.size.y < 0:
			continue
		
		match i:
			SIDE_LEFT:
				handle_rect.position.x -= handle_rect.size.x / 2.0
			SIDE_RIGHT:
				handle_rect.position.x += handle_rect.size.x / 2.0
			SIDE_TOP:
				handle_rect.position.y -= handle_rect.size.y / 2.0
			SIDE_BOTTOM:
				handle_rect.position.y += handle_rect.size.y / 2.0
		
		if is_hovering() && _resize_type == ResizeType.SIDE && _resize_index == i:
			if is_grabbing():
				draw_style_box(side_handle_pressed, handle_rect)
			else:
				draw_style_box(side_handle_hover, handle_rect)
		else:
			draw_style_box(side_handle_default, handle_rect)
	
	for i in 4: # Corner handles.
		var handle = _corner_handles[i]
		
		var handle_rect := Rect2()
		handle_rect.position = handle.position - position
		handle_rect.size = handle.size
		
		var handle_padding_x := -(handle_rect.size.x - corner_handle_size) / 2.0
		var handle_padding_y := -(handle_rect.size.y - corner_handle_size) / 2.0
		handle_rect = handle_rect.grow_individual(handle_padding_x, handle_padding_y, handle_padding_x, handle_padding_y)
		
		if is_hovering() && _resize_type == ResizeType.CORNER && _resize_index == i:
			if is_grabbing():
				draw_style_box(_corner_styleboxes[i * 3 + 2], handle_rect)
			else:
				draw_style_box(_corner_styleboxes[i * 3 + 1], handle_rect)
		else:
			draw_style_box(_corner_styleboxes[i * 3 + 0], handle_rect)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


# Implementation.

func _update_handles() -> void:
	var handle_trigger_size := get_theme_constant("handle_trigger_size")
	var base_size := Vector2(handle_trigger_size, handle_trigger_size)
	
	# Corner handles.
	
	_corner_handles[CORNER_TOP_LEFT].position = position - base_size
	_corner_handles[CORNER_TOP_LEFT].size = base_size * 2
	
	_corner_handles[CORNER_TOP_RIGHT].position = position + Vector2(size.x, 0) - base_size
	_corner_handles[CORNER_TOP_RIGHT].size = base_size * 2
	
	_corner_handles[CORNER_BOTTOM_RIGHT].position = position + size - base_size
	_corner_handles[CORNER_BOTTOM_RIGHT].size = base_size * 2
	
	_corner_handles[CORNER_BOTTOM_LEFT].position = position + Vector2(0, size.y) - base_size
	_corner_handles[CORNER_BOTTOM_LEFT].size = base_size * 2
	
	# Side handles.
	
	_side_handles[SIDE_LEFT].position = position + Vector2(-base_size.x, base_size.y)
	_side_handles[SIDE_LEFT].size = Vector2(base_size.x * 2, size.y - base_size.y * 2).max(Vector2.ZERO)
	
	_side_handles[SIDE_RIGHT].position = position + Vector2(size.x, 0) + Vector2(-base_size.x, base_size.y)
	_side_handles[SIDE_RIGHT].size = Vector2(base_size.x * 2, size.y - base_size.y * 2).max(Vector2.ZERO)
	
	_side_handles[SIDE_TOP].position = position + Vector2(base_size.x, -base_size.y)
	_side_handles[SIDE_TOP].size = Vector2(size.x - base_size.x * 2, base_size.y * 2).max(Vector2.ZERO)
	
	_side_handles[SIDE_BOTTOM].position = position + Vector2(0, size.y) + Vector2(base_size.x, -base_size.y)
	_side_handles[SIDE_BOTTOM].size = Vector2(size.x - base_size.x * 2, base_size.y * 2).max(Vector2.ZERO)


func check_hovering(mouse_position: Vector2) -> void:
	if is_hovering():
		queue_redraw() # Queue a forced redraw in case we're exiting the gizmo right now.
	
	_resize_type = ResizeType.NONE
	_resize_index = -1
	
	# First, test the rough area of this gizmo to exclude all obviously wrong events.
	var handle_trigger_size := get_theme_constant("handle_trigger_size")
	var rough_rect := Rect2(position, size).grow(handle_trigger_size)
	if not rough_rect.has_point(mouse_position):
		set_hovering(false)
		return
	
	# Then, test corner handles, they take priority over sides.
	for i in 4:
		var handle := _corner_handles[i]
		if handle.has_point(mouse_position):
			_resize_type = ResizeType.CORNER
			_resize_index = i
			set_hovering(true)
			return
	
	# Finally, test side handles.
	for i in 4:
		var handle := _side_handles[i]
		if handle.has_point(mouse_position):
			_resize_type = ResizeType.SIDE
			_resize_index = i
			set_hovering(true)
			return
	
	set_hovering(false)


func get_hovered_cursor_shape(mouse_position: Vector2) -> CursorShape:
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
		
		match _resize_type:
			ResizeType.CORNER:
				corner_size_changed.emit(_resize_index, mm.relative)
			ResizeType.SIDE:
				side_size_changed.emit(_resize_index, mm.relative)
