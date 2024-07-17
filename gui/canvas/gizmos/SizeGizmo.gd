###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the size of an element or a group of elements.
class_name SizeGizmo extends BaseGizmo

signal corner_size_changed(corner: Corner, delta: Vector2)
signal side_size_changed(side: Side, delta: Vector2)

const TRIGGER_AREA_WIDTH := 12.0
var _corner_handles: Array[Rect2] = []
var _side_handles: Array[Rect2] = []

enum ResizeType {
	NONE,
	CORNER,
	SIDE,
}

var _resize_type: ResizeType = ResizeType.NONE
var _resize_index: int = -1


func _init() -> void:
	super()
	name = &"SizeGizmo"
	
	_corner_handles.resize(4)
	_side_handles.resize(4)


func _ready() -> void:
	_update_handles()
	
	item_rect_changed.connect(_update_handles)


func _draw() -> void:
	var visual_padding := -TRIGGER_AREA_WIDTH / 2.0
	
	for i in 4:
		var handle := _side_handles[i]
		
		var handle_rect := Rect2()
		handle_rect.position = handle.position - position
		handle_rect.size = handle.size
		
		if i % 2 == 0:
			handle_rect = handle_rect.grow_individual(visual_padding, 0, visual_padding, 0)
		else:
			handle_rect = handle_rect.grow_individual(0, visual_padding, 0, visual_padding)
		
		draw_rect(handle_rect, Color.WHITE)
		draw_rect(handle_rect, Color.BLUE, false, 2.0)
	
	for handle in _corner_handles:
		var handle_rect := Rect2()
		handle_rect.position = handle.position - position
		handle_rect.size = handle.size
		handle_rect = handle_rect.grow(visual_padding)
		
		draw_rect(handle_rect, Color.WHITE)
		draw_rect(handle_rect, Color.BLACK, false, 2.0)


func _update_handles() -> void:
	var base_size := Vector2(TRIGGER_AREA_WIDTH, TRIGGER_AREA_WIDTH)
	
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
	_side_handles[SIDE_LEFT].size = Vector2(base_size.x * 2, size.y - base_size.y * 2)
	
	_side_handles[SIDE_RIGHT].position = position + Vector2(size.x, 0) + Vector2(-base_size.x, base_size.y)
	_side_handles[SIDE_RIGHT].size = Vector2(base_size.x * 2, size.y - base_size.y * 2)
	
	_side_handles[SIDE_TOP].position = position + Vector2(base_size.x, -base_size.y)
	_side_handles[SIDE_TOP].size = Vector2(size.x - base_size.x * 2, base_size.y * 2)
	
	_side_handles[SIDE_BOTTOM].position = position + Vector2(0, size.y) + Vector2(base_size.x, -base_size.y)
	_side_handles[SIDE_BOTTOM].size = Vector2(size.x - base_size.x * 2, base_size.y * 2)


# Implementation.


func is_hovering(mouse_position: Vector2) -> bool:
	_resize_type = ResizeType.NONE
	_resize_index = -1
	
	# First, test the rough area of this gizmo to exclude all obviously wrong events.
	var rough_rect := Rect2(position, size).grow(TRIGGER_AREA_WIDTH)
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


func get_hovered_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if _resize_type == ResizeType.NONE || _resize_index < 0:
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
	if _resize_type == ResizeType.NONE || _resize_index < 0:
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
