###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasView extends Control

## Our singleton instance.
static var _instance: CanvasView = null

# Instance members.

const SCALE_STEP := 1.2
const MIN_SCALE := 1.0 / pow(SCALE_STEP, 8.0)
const MAX_SCALE := 1.0 * pow(SCALE_STEP, 4.0)

signal canvas_transformed()

var _edited_canvas: UICanvas = null

var _canvas_offset: Vector2 = Vector2.ZERO
var _canvas_scale: float = 1.0
var _canvas_dragging: bool = false
var _canvas_drag_last_position: Vector2 = Vector2.ZERO


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
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


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
				MOUSE_BUTTON_RIGHT:
					_add_element_to_canvas(mb.global_position)
				MOUSE_BUTTON_MIDDLE:
					_stop_canvas_dragging()
	
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		
		if _canvas_dragging:
			_process_canvas_dragging(mm.global_position)


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("grove_create_element", false, true):
		var mouse_position := get_global_mouse_position()
		_add_element_to_canvas(mouse_position)
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("grove_remove_elements", false, true):
		_remove_element_from_canvas()
		
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _edited_canvas:
		return
	
	var ke := event as InputEventKey
	if not ke.pressed && not _edited_canvas.elements.is_empty():
		var some_element := _edited_canvas.elements[0]
		
		if ke.keycode == KEY_0:
			var some_state := some_element.variant_states[0]
			some_state.state.set_active(not some_state.state.is_active())
		if ke.keycode == KEY_9:
			var some_state := some_element.variant_states[1]
			some_state.state.set_active(not some_state.state.is_active())
		if ke.keycode == KEY_8:
			var some_state := some_element.variant_states[2]
			some_state.state.set_active(not some_state.state.is_active())


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


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	_edited_canvas = Controller.get_current_canvas()


func _add_element_to_canvas(at_position: Vector2) -> void:
	if not _edited_canvas:
		return
	
	var element := _edited_canvas.create_element()
	element.set_anchor_point(at_position)
	
	for i in 3:
		var state_type := 2 + i # Focused, hovered, pressed
		var extra_state := element.create_state(state_type, StateType.get_state_name(state_type))
		
		if i == 0 || i == 2:
			# When doing this for real, we must set the value to the default state's current value.
			extra_state.state.override_property("size")
			extra_state.set_size(Vector2(randi_range(1, 3), randi_range(1, 3)) * 32)
		
		if i == 1 || i == 2:
			extra_state.state.override_property("debug_color")
			extra_state.set_debug_color(Color(randf(), randf(), randf()))
		
		extra_state.state_in_transition.duration = 0.3
		extra_state.state_out_transition.duration = 0.1


func _remove_element_from_canvas() -> void:
	if not _edited_canvas:
		return
	if _edited_canvas.elements.is_empty():
		return
	
	_edited_canvas.remove_element(_edited_canvas.elements[0])
