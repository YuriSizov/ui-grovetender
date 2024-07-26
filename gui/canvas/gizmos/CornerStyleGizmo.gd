###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing corners of an element, their style and adjustible properties.
class_name CornerStyleGizmo extends BaseGizmo

signal curved_radius_changed(corner: Corner, delta: float)
signal curved_radius_all_changed(corner: Corner, delta: float)
signal curved_radius_opposite_changed(corner: Corner, delta: float)

var _corner_handles: Array[Rect2] = []
var _corner_index: int = -1

var _curved_radius_property: String = ""


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"CornerStyleGizmo"
	theme_type_variation = &"CornerStyleGizmo"
	
	_corner_handles.resize(4)


func _draw() -> void:
	var corner_handle_default := get_theme_stylebox("corner_handle")
	var corner_handle_hover := get_theme_stylebox("corner_handle_hover")
	var corner_handle_pressed := get_theme_stylebox("corner_handle_pressed")
	
	var corner_handle_size := get_theme_constant("corner_handle_size")
	var corner_connection_size := get_theme_constant("corner_connection_size")
	var corner_radius_values := get_element_curved_radius_values()
	
	for i in 4:
		var handle_base := get_element_global_corner(i) - position
		var handle_angle := (i + 0.5) * (TAU / 4.0) + PI
		var handle_offset := Vector2(
			corner_radius_values[i] * cos(handle_angle),
			corner_radius_values[i] * sin(handle_angle)
		) * EndlessCanvas.get_instance().get_elements_scale()
		
		var handle_rect := Rect2()
		handle_rect.size = Vector2(corner_handle_size, corner_handle_size)
		handle_rect.position = handle_base - handle_rect.size / 2.0 - handle_offset
		
		var connection_rect := Rect2()
		connection_rect.size = Vector2(-handle_offset.length(), corner_connection_size)
		connection_rect.position = Vector2.ZERO - Vector2(0.0, connection_rect.size.y / 2.0)
		
		var handle_style := corner_handle_default
		if is_hovering() && _corner_index == i:
			if is_grabbing():
				handle_style = corner_handle_pressed
			else:
				handle_style = corner_handle_hover
		
		draw_set_transform(handle_base, handle_angle)
		draw_style_box(corner_handle_default, connection_rect)
		draw_set_transform(Vector2.ZERO, 0.0)
		
		draw_style_box(handle_style, handle_rect)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


func _get_tooltip(_at_position: Vector2) -> String:
	if not is_hovering():
		return ""
	
	return "Adjust radius of the corner.\nHold Ctrl to adjust all corners.\nHold Alt to adjust opposite corners."


# Properties.

func set_curved_radius_property(value: String) -> void:
	_curved_radius_property = value
	
	_update_handles()
	queue_redraw()


func get_element_curved_radius_values() -> Vector4:
	var element_radius_values := Vector4(0.0, 0.0, 0.0, 0.0)
	
	if _reference_element && not _curved_radius_property.is_empty():
		element_radius_values = _reference_element.get(_curved_radius_property)
	
	return element_radius_values

# Implementation.

func _handle_property_changes(property_name: String) -> void:
	if property_name == _curved_radius_property:
		_update_handles()
		queue_redraw()


func _update_handles() -> void:
	var handle_trigger_size := get_theme_constant("handle_trigger_size") / 2.0
	var base_size := Vector2(handle_trigger_size, handle_trigger_size)
	var corner_radius_values := get_element_curved_radius_values()
	
	for i in 4:
		var handle_angle := (i + 0.5) * (TAU / 4.0) + PI
		var handle_offset := Vector2(
			corner_radius_values[i] * cos(handle_angle),
			corner_radius_values[i] * sin(handle_angle)
		) * EndlessCanvas.get_instance().get_elements_scale()
		
		_corner_handles[i].size = base_size * 2
		_corner_handles[i].position = get_element_global_corner(i) - base_size - handle_offset


func _is_hovering_at(mouse_position: Vector2) -> bool:
	# We use this opportunity to pre-determine which handle we're going to interact with.
	_corner_index = -1
	
	# Test corner handle areas directly, because they may be outside of element bounds.
	for i in 4:
		var handle := _corner_handles[i]
		if handle.has_point(mouse_position):
			_corner_index = i
			return true
	
	return false


func get_hovering_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	match _corner_index:
		CORNER_TOP_LEFT:
			return Control.CURSOR_FDIAGSIZE
		CORNER_TOP_RIGHT:
			return Control.CURSOR_BDIAGSIZE
		CORNER_BOTTOM_RIGHT:
			return Control.CURSOR_FDIAGSIZE
		CORNER_BOTTOM_LEFT:
			return Control.CURSOR_BDIAGSIZE
	
	return super(mouse_position)


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			if _corner_index < 0:
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
			_corner_index = -1
			set_grabbing(false)
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / EndlessCanvas.get_instance().get_elements_scale()
		
		# Adjust the vector so that outwards direction is pointing to the top.
		match _corner_index:
			CORNER_TOP_LEFT:
				relative = relative.rotated(deg_to_rad(45))
			CORNER_TOP_RIGHT:
				relative = relative.rotated(deg_to_rad(-45))
			CORNER_BOTTOM_RIGHT:
				relative = relative.rotated(deg_to_rad(-135))
			CORNER_BOTTOM_LEFT:
				relative = relative.rotated(deg_to_rad(135))
		
		var relative_corner := relative.y
		
		# Hold Ctrl to adjust all corners at the same time.
		if Input.is_key_pressed(KEY_CTRL):
			curved_radius_all_changed.emit(_corner_index, relative_corner)
		
		# Hold Alt to adjust opposite corners at the same time.
		elif Input.is_key_pressed(KEY_ALT):
			curved_radius_opposite_changed.emit(_corner_index, relative_corner)
		
		else:
			curved_radius_changed.emit(_corner_index, relative_corner)
