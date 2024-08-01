###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the size of an element or a group of elements.
class_name TextEditGizmo extends BaseGizmo

signal text_changed(value: String)

var _hidden_input: TextEdit = null

var _text_value_property: String = ""
var _text_value_buffer: TextParagraph = null
var _text_shape_getter: Callable = Callable()

var _text_shape_handle: Rect2 = Rect2()
var _text_caret_handle: Rect2 = Rect2()
var _text_selection_handles: Array[Rect2] = []


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"TextEditGizmo"
	theme_type_variation = &"TextEditGizmo"
	
	_hidden_input = TextEdit.new()
	_hidden_input.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hidden_input.focus_mode = Control.FOCUS_CLICK # So it can be focused but only through code.
	_hidden_input.modulate.a = 0.0
	_hidden_input.caret_multiple = false
	add_child(_hidden_input)
	
	_hidden_input.text_changed.connect(_change_text_value)
	_hidden_input.focus_exited.connect(_stop_text_editing.bind(false))
	_hidden_input.caret_changed.connect(_update_gizmo_caret_from_hidden)
	_hidden_input.caret_changed.connect(_update_gizmo_selection_from_hidden)


func _draw() -> void:
	if not is_grabbing():
		return
	
	var base_position := _text_shape_handle.position - position
	
	for selection_handle in _text_selection_handles:
		var selection_rect := selection_handle
		selection_rect.position += base_position
		var selection_color := get_theme_color("selection_color")
		
		draw_rect(selection_rect, selection_color)
	
	# TODO: Add caret blinking.
	var caret_rect := _text_caret_handle
	caret_rect.position += base_position
	var caret_color := get_theme_color("caret_color")
	
	draw_rect(caret_rect, caret_color)


func _get_tooltip(_at_position: Vector2) -> String:
	if is_hovering():
		return "Edit the text value."
	return ""


# Properties.

func set_text_value_property(value: String) -> void:
	_text_value_property = value
	
	_update_handles()
	queue_redraw()


func set_text_buffer(value: TextParagraph) -> void:
	_text_value_buffer = value
	
	_update_handles()
	queue_redraw()


func set_text_shape_getter(callable: Callable) -> void:
	_text_shape_getter = callable
	
	_update_handles()
	queue_redraw()


func update_text_shape() -> void:
	_update_handles()
	queue_redraw()


func _start_text_editing() -> void:
	if _text_value_property.is_empty():
		return
	
	_hidden_input.text = _reference_element.get(_text_value_property)
	_hidden_input.grab_focus()
	_hidden_input.select_all()
	
	set_grabbing(true)
	queue_redraw()


func _stop_text_editing(unfocus: bool = true) -> void:
	if unfocus && _hidden_input.has_focus():
		_hidden_input.release_focus()
	
	set_grabbing(false)
	queue_redraw()


func _from_hidden_input_position(line_idx: int, char_idx: int) -> Vector2:
	var TS := TextServerManager.get_primary_interface()
	var is_newline := false
	
	# A new, empty line doesn't exist in the shaped paragraph, so we improvise.
	if line_idx >= _text_value_buffer.get_line_count():
		line_idx = _text_value_buffer.get_line_count() - 1
		char_idx = 0
		is_newline = true
	
	var line_char_offset := _text_value_buffer.get_line_range(line_idx).x
	var line_rid := _text_value_buffer.get_line_rid(line_idx)
	# It's a range on one axis represented with a Vector2.
	var line_char_bounds := TS.shaped_text_get_grapheme_bounds(line_rid, char_idx + line_char_offset)
	
	var gizmo_position := Vector2.ZERO
	
	# First position is before the first character.
	if char_idx == 0:
		gizmo_position.x = line_char_bounds.x
	else:
		gizmo_position.x = line_char_bounds.y
	
	for i in line_idx:
		gizmo_position.y += _text_value_buffer.get_line_size(i).y
	if is_newline:
		gizmo_position.y += _text_value_buffer.get_line_size(line_idx).y
	
	return gizmo_position


func _update_gizmo_caret_from_hidden() -> void:
	var caret_line := _hidden_input.get_caret_line(0)
	var caret_char := _hidden_input.get_caret_column(0)
	_text_caret_handle.position = _from_hidden_input_position(caret_line, caret_char)
	
	# A new, empty line doesn't exist in the shaped paragraph, so we improvise.
	var last_valid_line := caret_line
	if last_valid_line >= _text_value_buffer.get_line_count():
		last_valid_line = _text_value_buffer.get_line_count() - 1
	
	_text_caret_handle.size.x = get_theme_constant("caret_size")
	_text_caret_handle.size.y = _text_value_buffer.get_line_size(last_valid_line).y
	
	queue_redraw()


func _update_gizmo_selection_from_hidden() -> void:
	_text_selection_handles.clear()
	
	var from_line := _hidden_input.get_selection_from_line(0)
	var from_char := _hidden_input.get_selection_from_column(0)
	var to_line := _hidden_input.get_selection_to_line(0)
	var to_char := _hidden_input.get_selection_to_column(0)
	
	if from_line == to_line && from_char == to_char:
		queue_redraw()
		return
	
	var current_line := from_line
	while current_line <= to_line:
		if current_line >= _text_value_buffer.get_line_count():
			break # Nothing to draw on the empty line.
		
		var line_char_range := _text_value_buffer.get_line_range(current_line)
		var left_char := from_char if current_line == from_line else 0
		var right_char := to_char if current_line == to_line else (line_char_range.y - line_char_range.x)
		
		var left_position := _from_hidden_input_position(current_line, left_char)
		var right_position := _from_hidden_input_position(current_line, right_char)
		var line_height := _text_value_buffer.get_line_size(current_line).y
		
		var handle_rect := Rect2()
		handle_rect.position = left_position
		handle_rect.size = Vector2(right_position.x - left_position.x, line_height)
		_text_selection_handles.push_back(handle_rect)
		
		current_line += 1
	
	queue_redraw()


func _change_text_value() -> void:
	text_changed.emit(_hidden_input.text)
	
	_update_gizmo_caret_from_hidden()
	_update_gizmo_selection_from_hidden()


func _set_hidden_caret_from_click(_at_position: Vector2) -> void:
	pass


# Implementation.

func _handle_property_changes(property_name: String) -> void:
	if property_name == _text_value_property:
		_update_handles()
		queue_redraw()


func _update_handles() -> void:
	if _text_shape_getter.is_valid():
		_text_shape_handle = _text_shape_getter.call()
		_text_shape_handle.position = EndlessCanvas.get_instance().from_canvas_coordinates(_text_shape_handle.position)
		_text_shape_handle.size = _text_shape_handle.size * EndlessCanvas.get_instance().get_elements_scale()
	else:
		_text_shape_handle = get_element_global_rect()


func _is_hovering_at(mouse_position: Vector2) -> bool:
	var element_rect := get_element_global_rect()
	return element_rect.has_point(mouse_position) || _text_shape_handle.has_point(mouse_position)


func get_hovering_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	var element_rect := get_element_global_rect()
	if element_rect.has_point(mouse_position) || _text_shape_handle.has_point(mouse_position):
		return Control.CURSOR_IBEAM
	
	return super(mouse_position)


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			var mouse_position := mb.global_position
			var element_rect := get_element_global_rect()
			
			if element_rect.has_point(mouse_position) || _text_shape_handle.has_point(mouse_position):
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
			_start_text_editing()
		
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			if _text_shape_handle.has_point(mb.global_position):
				_set_hidden_caret_from_click(mb.global_position)
				return
			
			var element_rect := get_element_global_rect()
			if not element_rect.has_point(mb.global_position):
				_stop_text_editing()
		
