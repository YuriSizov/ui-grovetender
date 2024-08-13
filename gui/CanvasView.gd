###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasView extends Control

## Our singleton instance.
static var _instance: CanvasView = null

#

const SCALE_STEP := 1.2
const MIN_SCALE := 1.0 / pow(SCALE_STEP, 8.0)
const MAX_SCALE := 1.0 * pow(SCALE_STEP, 4.0)

signal canvas_transformed()

var _canvas_offset: Vector2 = Vector2.ZERO
var _canvas_scale: float = 1.0
var _canvas_dragging: bool = false
var _canvas_drag_last_position: Vector2 = Vector2.ZERO

@onready var _elements_container: CanvasElements = %Elements


static func get_instance() -> CanvasView:
	return _instance


func _init() -> void:
	if Engine.is_editor_hint():
		return
	if _instance:
		printerr("CanvasView: Only one instance of CanvasView is allowed.")
	
	_instance = self


func _ready() -> void:
	_update_canvas_grid()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed: # Events triggered on mouse press.
			match mb.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_adjust_canvas_scale(SCALE_STEP, mb.global_position)
				
				MOUSE_BUTTON_WHEEL_DOWN:
					_adjust_canvas_scale(1.0 / SCALE_STEP, mb.global_position)
			
				MOUSE_BUTTON_MIDDLE:
					_start_canvas_dragging(mb.global_position)
		
		else: # Events triggered on mouse release.
			match mb.button_index:
				MOUSE_BUTTON_MIDDLE:
					_stop_canvas_dragging()
	
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		
		if _canvas_dragging:
			_process_canvas_dragging(mm.global_position)


func _draw() -> void:
	# Draw anything just so we can use a shader.
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)


# Canvas transform.

func get_canvas_scale() -> float:
	return _canvas_scale


func get_canvas_scale_vector() -> Vector2:
	return Vector2(_canvas_scale, _canvas_scale)


func get_canvas_offset() -> Vector2:
	return _canvas_offset


func reset_canvas_transform() -> void:
	_canvas_scale = 1.0
	_canvas_offset = Vector2.ZERO
	
	_update_canvas_grid()
	canvas_transformed.emit()


func _set_canvas_scale(value: float, towards_position: Vector2) -> void:
	var clean_value := clampf(value, MIN_SCALE, MAX_SCALE)
	if _canvas_scale == clean_value:
		return
	
	var old_offset := (_canvas_offset + towards_position) / _canvas_scale
	_canvas_scale = clean_value
	_canvas_offset = old_offset * _canvas_scale - towards_position
	
	_update_canvas_grid()
	canvas_transformed.emit()


func _adjust_canvas_scale(factor: float, towards_position: Vector2) -> void:
	_set_canvas_scale(_canvas_scale * factor, towards_position)


func _start_canvas_dragging(from_position: Vector2) -> void:
	_canvas_dragging = true
	_canvas_drag_last_position = from_position


func _stop_canvas_dragging() -> void:
	_canvas_dragging = false
	_canvas_drag_last_position = Vector2.ZERO


func _process_canvas_dragging(current_position: Vector2) -> void:
	if not _canvas_dragging:
		return
	
	# This accounts for skipped mouse events (e.g. consumed by something else).
	var relative := current_position - _canvas_drag_last_position
	_canvas_drag_last_position = current_position
	
	_canvas_offset -= relative
	
	_update_canvas_grid()
	canvas_transformed.emit()


func to_canvas_coordinates(ui_position: Vector2) -> Vector2:
	return (ui_position + _canvas_offset) / _canvas_scale


func from_canvas_coordinates(canvas_position: Vector2) -> Vector2:
	return canvas_position * _canvas_scale - _canvas_offset


# Grid visuals.

func _update_canvas_grid() -> void:
	var shader := (material as ShaderMaterial)
	shader.set_shader_parameter("grid_offset", _canvas_offset)
	shader.set_shader_parameter("grid_scale", _canvas_scale)
