###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing borders of an element, their style and adjustible properties.
class_name BorderStyleGizmo extends BaseGizmo

signal width_changed(side: Side, delta: float)
signal width_all_changed(side: Side, delta: float)
signal width_opposite_changed(side: Side, delta: float)

var _side_handles: Array[Rect2] = []
var _side_index: int = -1


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"BorderStyleGizmo"
	theme_type_variation = &"BorderStyleGizmo"
	
	_side_handles.resize(4)


func _draw() -> void:
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
		
		if is_hovering() && _side_index == i:
			if is_grabbing():
				draw_style_box(side_handle_pressed, visual_rect)
			else:
				draw_style_box(side_handle_hover, visual_rect)
		else:
			draw_style_box(side_handle_default, visual_rect)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


func _get_tooltip(_at_position: Vector2) -> String:
	if not is_hovering():
		return ""
	
	return "Adjust thickness of the border.\nHold Ctrl to adjust all borders.\nHold Alt to adjust opposite borders."


# Implementation.

func _update_handles() -> void:
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var base_size := Vector2(handle_trigger_size, handle_trigger_size)
	var half_element_size := get_element_global_size() / 2.0
	
	for i in 4:
		if i % 2 == 0: # Left/Right.
			_side_handles[i].position = get_element_global_side(i) - Vector2(base_size.x, half_element_size.y - base_size.y)
			_side_handles[i].size = Vector2(base_size.x * 2, (half_element_size.y - base_size.y) * 2).max(Vector2.ZERO)
		else: # Top/Bottom.
			_side_handles[i].position = get_element_global_side(i) - Vector2(half_element_size.x - base_size.x, base_size.y)
			_side_handles[i].size = Vector2((half_element_size.x - base_size.x) * 2, base_size.y * 2).max(Vector2.ZERO)


func _is_hovering_at(mouse_position: Vector2) -> bool:
	# We use this opportunity to pre-determine which handle we're going to interact with.
	_side_index = -1
	
	# First, test the rough area of this gizmo to exclude all obviously wrong events.
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var rough_rect := get_element_global_rect().grow(handle_trigger_size)
	if not rough_rect.has_point(mouse_position):
		return false
	
	# Then, test side handles.
	for i in 4:
		var handle := _side_handles[i]
		if handle.has_point(mouse_position):
			_side_index = i
			return true
	
	return false


func get_hovering_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	match _side_index:
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
			if _side_index < 0:
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
			_side_index = -1
			set_grabbing(false)
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / EndlessCanvas.get_instance().get_elements_scale()
		var relative_side := 0.0
		
		if _side_index == SIDE_LEFT || _side_index == SIDE_RIGHT:
			relative_side = relative.x
		else:
			relative_side = relative.y
		
		# Hold Ctrl to adjust all sides at the same time.
		if Input.is_key_pressed(KEY_CTRL):
			width_all_changed.emit(_side_index, relative_side)
		
		# Hold Alt to adjust opposite sides at the same time.
		elif Input.is_key_pressed(KEY_ALT):
			width_opposite_changed.emit(_side_index, relative_side)
		
		else:
			width_changed.emit(_side_index, relative_side)
