###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing an assertment of properties of an element.
class_name PropertiesGizmo extends BaseGizmo

var _base_rect: Rect2 = Rect2()
var _properties: Array[PropertyEditor] = []

var _hovered_property: int = -1


func _init() -> void:
	super()
	name = &"PropertiesGizmo"
	theme_type_variation = &"PropertiesGizmo"


func _draw() -> void:
	var prop_separation := get_theme_constant("prop_separation")
	var prop_position := _base_rect.position - position
	
	for property in _properties:
		property.render(prop_position)
		
		prop_position.y += property.get_size().y + prop_separation


func _process(_delta: float) -> void:
	if is_hovering():
		queue_redraw() # Redraw constantly when hovering.

# Implementation.

func _update_handles() -> void:
	var base_offset := Vector2(
		get_theme_constant("base_offset_x"),
		get_theme_constant("base_offset_y")
	)
	var prop_separation := get_theme_constant("prop_separation")
	
	_base_rect.position = position + Vector2(size.x, 0) + base_offset
	_base_rect.size = Vector2(0, prop_separation * (_properties.size() - 1))
	
	for property in _properties:
		var prop_size := property.get_size()
		_base_rect.size.y += prop_size.y
		
		if prop_size.x > _base_rect.size.x:
			_base_rect.size.x = prop_size.x
	
	var window_size := get_window().size
	if (_base_rect.position.x + _base_rect.size.x + base_offset.x) > window_size.x:
		_base_rect.position = position - Vector2(_base_rect.size.x, 0) - base_offset
	
	queue_redraw()


func check_hovering(mouse_position: Vector2) -> void:
	if is_hovering():
		queue_redraw() # Queue a forced redraw in case we're exiting the gizmo right now.
	
	# Consume all hovering over the general area of the gizmo.
	if _base_rect.has_point(mouse_position):
		
		# Check which property we're hovering over and update its state.
		var next_hovered_property := _hovered_property
		
		var prop_separation := get_theme_constant("prop_separation")
		var prop_rect := Rect2()
		prop_rect.position = _base_rect.position
		
		for i in _properties.size():
			var property := _properties[i]
			prop_rect.size = property.get_size()
			
			if prop_rect.has_point(mouse_position):
				next_hovered_property = i
				break
			
			prop_rect.position.y += prop_rect.size.y + prop_separation
		
		if next_hovered_property != _hovered_property:
			if _hovered_property >= 0:
				_properties[_hovered_property].set_hovering(false)
			
			_hovered_property = next_hovered_property
			_properties[_hovered_property].set_hovering(true)
		
		set_hovering(true)
	else:
		if _hovered_property >= 0:
			_properties[_hovered_property].set_hovering(false)
			_hovered_property = -1
		
		set_hovering(false)


func get_hovered_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	if _hovered_property >= 0:
		return Control.CURSOR_POINTING_HAND
	return Control.CURSOR_ARROW


func can_handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			var mouse_position := mb.global_position
			if _base_rect.has_point(mouse_position):
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
			set_grabbing(false)
	
	if _hovered_property >= 0:
		var property := _properties[_hovered_property]
		property.handle_input(event)


# Property management.

func add_property_editor(property_type: int, property_name: String, property_setter: Callable) -> PropertyEditor:
	if not _reference_element:
		return null
	
	var prop_editor: PropertyEditor = null
	
	match property_type:
		PropertyEditorType.PROPERTY_TOGGLE:
			prop_editor = TogglePropertyEditor.new(_reference_element, property_name, property_setter)
		
		PropertyEditorType.PROPERTY_COLOR:
			pass
	
	if prop_editor:
		prop_editor.owner_control = self
		_properties.push_back(prop_editor)
		queue_redraw()
	
	return prop_editor
