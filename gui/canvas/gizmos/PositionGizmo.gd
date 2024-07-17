###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the position of an item or a group of items.
class_name PositionGizmo extends BaseGizmo

signal position_changed(delta: Vector2)

const TRIGGER_AREA_WIDTH := 24.0
var _center_handle: Rect2 = Rect2()

var _grabbing: bool = false


func _ready() -> void:
	_update_handles()
	
	item_rect_changed.connect(_update_handles)


func _draw() -> void:
	var visual_padding := -TRIGGER_AREA_WIDTH / 2.0
	
	var handle_rect := Rect2()
	handle_rect.position = _center_handle.position - position
	handle_rect.size = _center_handle.size
	handle_rect = handle_rect.grow(visual_padding)
	
	draw_rect(handle_rect, Color.WHITE)
	draw_rect(handle_rect, Color.SEA_GREEN, false, 2.0)


func _update_handles() -> void:
	var base_size := Vector2(TRIGGER_AREA_WIDTH, TRIGGER_AREA_WIDTH)
	
	_center_handle.position = position + size / 2.0 - base_size
	_center_handle.size = base_size * 2


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			var mouse_position := mb.global_position
			if _center_handle.has_point(mouse_position):
				return true
			
		elif _grabbing && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			return true
	
	if _grabbing && event is InputEventMouseMotion:
		return true
	
	return false


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not _grabbing && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_grabbing = true
			grabbed.emit()
		
		elif _grabbing && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_grabbing = false
			released.emit()
	
	if _grabbing && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		position_changed.emit(mm.relative)
