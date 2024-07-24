###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the position of an element or a group of elements.
class_name ShadowStyleGizmo extends BaseGizmo

signal offset_changed(delta: Vector2)
signal size_changed(delta: float)

var _sun_handle_position: Vector2 = Vector2.ZERO
var _sun_handle_size: float = 0.0
var _ray_handle_size: float = 0.0

enum HandleType {
	NONE,
	SUN,
	RAY,
}
var _handle_type: HandleType = HandleType.NONE

var _shadow_size_property: String = ""


func _init(element: BaseUIElement) -> void:
	super(element)
	name = &"ShadowStyleGizmo"
	theme_type_variation = &"ShadowStyleGizmo"


func _draw() -> void:
	var sun_handle_default := get_theme_stylebox("sun_handle")
	var sun_handle_hover := get_theme_stylebox("sun_handle_hover")
	var sun_handle_pressed := get_theme_stylebox("sun_handle_pressed")
	
	var sun_handle_size := get_theme_constant("sun_handle_size")
	
	var ray_handle_size := get_theme_constant("ray_handle_size")
	var ray_handle_thickness := get_theme_constant("ray_handle_thickness")
	var ray_handle_separation := get_theme_constant("ray_handle_separation")
	var ray_handle_count := get_theme_constant("ray_count")
	
	var sun_rect := Rect2()
	sun_rect.size = Vector2(sun_handle_size, sun_handle_size)
	sun_rect.position = Vector2.ZERO - sun_rect.size / 2.0
	
	if is_hovering() && _handle_type == HandleType.SUN:
		if is_grabbing():
			draw_style_box(sun_handle_pressed, sun_rect)
		else:
			draw_style_box(sun_handle_hover, sun_rect)
	else:
		draw_style_box(sun_handle_default, sun_rect)
	
	var shadow_size_values := get_element_shadow_size_values()
	var max_shadow_size := maxf(shadow_size_values.x, shadow_size_values.y) * EndlessCanvas.get_instance().get_elements_scale()
	
	var ray_rect := Rect2()
	ray_rect.size = Vector2(ray_handle_size + max_shadow_size, ray_handle_thickness)
	ray_rect.position = Vector2(ray_handle_separation, 0.0 - ray_rect.size.y / 2.0)
	
	var ray_handle_style := sun_handle_default
	if is_hovering() && _handle_type == HandleType.RAY:
		if is_grabbing():
			ray_handle_style = sun_handle_pressed
		else:
			ray_handle_style = sun_handle_hover
	
	for i in ray_handle_count:
		var ray_rotation := i * TAU / ray_handle_count
		
		draw_set_transform(Vector2.ZERO, ray_rotation)
		draw_style_box(ray_handle_style, ray_rect)
		draw_set_transform(Vector2.ZERO, 0.0)


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.


func _get_tooltip(_at_position: Vector2) -> String:
	if not is_hovering():
		return ""
	
	if _handle_type == HandleType.SUN:
		return "Adjust position of the shadow."
	elif _handle_type == HandleType.RAY:
		return "Adjust size of the shadow."
	
	return ""


# Properties.

func set_shadow_size_property(value: String) -> void:
	_shadow_size_property = value
	
	_update_handles()
	queue_redraw()


func get_element_shadow_size_values() -> Vector2:
	var element_shadow_size_values := Vector2(0.0, 0.0)
	
	if _reference_element && not _shadow_size_property.is_empty():
		element_shadow_size_values = _reference_element.get(_shadow_size_property)
	
	return element_shadow_size_values

# Implementation.

func _handle_property_changes(property_name: String) -> void:
	if property_name == _shadow_size_property:
		_update_handles()
		queue_redraw()


func _update_handles() -> void:
	_sun_handle_position = position
	_sun_handle_size = get_theme_constant("sun_handle_trigger_size") / 2.0
	
	var ray_base_size := get_theme_constant("ray_handle_trigger_size")
	var shadow_size_values := get_element_shadow_size_values()
	var max_shadow_size := maxf(shadow_size_values.x, shadow_size_values.y) * EndlessCanvas.get_instance().get_elements_scale()
	
	_ray_handle_size = ray_base_size + max_shadow_size


func _is_hovering_at(mouse_position: Vector2) -> bool:
	var relative_position := mouse_position - _sun_handle_position
	var relative_length := relative_position.length_squared()
	
	if relative_length > pow(_sun_handle_size + _ray_handle_size, 2):
		_handle_type = HandleType.NONE
		return false
	
	# We use this opportunity to pre-determine which handle we're going to interact with.
	if relative_length > pow(_sun_handle_size, 2):
		_handle_type = HandleType.RAY
	else:
		_handle_type = HandleType.SUN
	
	return true


func get_hovering_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	if _handle_type == HandleType.SUN:
		return Control.CURSOR_DRAG
	elif _handle_type == HandleType.RAY:
		var relative_position := mouse_position - _sun_handle_position
		var relative_angle := relative_position.angle()
		
		var snapping_angle_step := PI / 4.0
		var snapping_angle_range := PI / 8.0
		
		# Horizontal axes.
		if relative_angle < 1 * snapping_angle_step - snapping_angle_range && relative_angle > -1 * snapping_angle_step + snapping_angle_range:
			return Control.CURSOR_HSIZE
		if relative_angle > 4 * snapping_angle_step - snapping_angle_range || relative_angle < -4 * snapping_angle_step + snapping_angle_range:
			return Control.CURSOR_HSIZE
		
		# Forward diagonal axes.
		if relative_angle >= 1 * snapping_angle_step - snapping_angle_range && relative_angle < 2 * snapping_angle_step - snapping_angle_range:
			return Control.CURSOR_FDIAGSIZE
		if relative_angle <= -3 * snapping_angle_step + snapping_angle_range && relative_angle > -4 * snapping_angle_step + snapping_angle_range:
			return Control.CURSOR_FDIAGSIZE
		
		# Backward diagonal axes.
		if relative_angle >= 3 * snapping_angle_step - snapping_angle_range && relative_angle < 4 * snapping_angle_step - snapping_angle_range:
			return Control.CURSOR_BDIAGSIZE
		if relative_angle <= -1 * snapping_angle_step + snapping_angle_range && relative_angle > -2 * snapping_angle_step + snapping_angle_range:
			return Control.CURSOR_BDIAGSIZE
		
		return Control.CURSOR_VSIZE
	
	return super(mouse_position)


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			if _handle_type == HandleType.NONE:
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
			_handle_type = HandleType.NONE
			set_grabbing(false)
	
	if is_grabbing() && event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var relative := mm.relative / EndlessCanvas.get_instance().get_elements_scale()
		
		match _handle_type:
			HandleType.SUN:
				offset_changed.emit(relative)
			
			HandleType.RAY:
				var relative_distance := relative.length()
				
				# Inwards.
				if (mm.position - _sun_handle_position).length_squared() < (mm.position - mm.relative - _sun_handle_position).length_squared():
					size_changed.emit(-relative_distance)
				
				# Outwards.
				else:
					size_changed.emit(relative_distance)
