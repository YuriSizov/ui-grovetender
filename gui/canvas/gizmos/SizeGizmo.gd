###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the size of an item or a group of items.
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
var _grabbing: bool = false


func _init() -> void:
	super()
	
	_corner_handles.resize(4)
	_side_handles.resize(4)


func _ready() -> void:
	_update_handles()
	
	resized.connect(_update_handles)


func _draw() -> void:
	var gizmo_rect := Rect2(Vector2.ZERO, size)
	
	draw_rect(gizmo_rect, Color.BLUE, false, 2.0)
	
	for handle in _corner_handles:
		var handle_rect := Rect2()
		handle_rect.position = handle.position - position
		handle_rect.size = handle.size
		handle_rect = handle_rect.grow(-TRIGGER_AREA_WIDTH / 2.0)
		
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
	
	pass


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_resize_type = ResizeType.NONE
			_resize_index = -1
			
			var mouse_position := mb.global_position
			
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
		
		elif _grabbing && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			return true
	
	if event is InputEventMouseMotion && _grabbing:
		return true
	
	return false


func handle_input(event: InputEvent) -> void:
	if _resize_type == ResizeType.NONE || _resize_index < 0:
		return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not _grabbing && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_grabbing = true
			grabbed.emit()
		
		elif _grabbing && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_resize_type = ResizeType.NONE
			_resize_index = -1
			_grabbing = false
			released.emit()
	
	if event is InputEventMouseMotion && _grabbing:
		var mm := event as InputEventMouseMotion
		
		match _resize_type:
			ResizeType.CORNER:
				corner_size_changed.emit(_resize_index, mm.relative)
			ResizeType.SIDE:
				side_size_changed.emit(_resize_index, mm.relative)
