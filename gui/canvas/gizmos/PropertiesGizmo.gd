###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing an assertment of properties of an element.
class_name PropertiesGizmo extends BaseGizmo

var _base_rect: Rect2 = Rect2()

var _properties: Array[PropertyEditor] = []
var _hovered_property: PropertyEditor = null
var _editing_property: PropertyEditor = null


func _init() -> void:
	super()
	name = &"PropertiesGizmo"
	theme_type_variation = &"PropertiesGizmo"


# Implementation.

func _update_handles() -> void:
	var base_offset := Vector2(
		get_theme_constant("base_offset_x"),
		get_theme_constant("base_offset_y")
	)
	var prop_separation := get_theme_constant("prop_separation")
	
	_base_rect.size = Vector2(0, prop_separation * (_properties.size() - 1))
	
	# Contribute sizes of individual property editors to the combined size.
	for property in _properties:
		var prop_size := property.get_combined_minimum_size()
		_base_rect.size.y += prop_size.y
		
		if prop_size.x > _base_rect.size.x:
			_base_rect.size.x = prop_size.x
	
	# Position the gizmo to the right of the object.
	_base_rect.position = position + Vector2(size.x, 0) + base_offset
	# If it doesn't fit to the right, position it to the left instead.
	var window_size := get_window().size
	if (_base_rect.position.x + _base_rect.size.x + base_offset.x) > window_size.x:
		_base_rect.position.x = position.x - _base_rect.size.x - base_offset.x
	
	# Center the gizmo vertically.
	_base_rect.position.y = position.y + size.y / 2.0 - _base_rect.size.y / 2.0
	
	# If the gizmo goes off screen, adjust for that.
	
	if (_base_rect.position.x - base_offset.x) < 0:
		_base_rect.position.x = base_offset.x
	if (_base_rect.position.x + _base_rect.size.x + base_offset.x) > window_size.x:
		_base_rect.position.x -= (_base_rect.position.x + _base_rect.size.x + base_offset.x) - window_size.x
	
	if (_base_rect.position.y - base_offset.y) < 0:
		_base_rect.position.y = base_offset.y
	if (_base_rect.position.y + _base_rect.size.y + base_offset.y) > window_size.y:
		_base_rect.position.y -= (_base_rect.position.y + _base_rect.size.y + base_offset.y) - window_size.y
	
	# Update sizes and positions of property editors.
	var prop_position := _base_rect.position
	for property in _properties:
		var prop_size := property.get_combined_minimum_size()
		property.size.x = _base_rect.size.x
		property.size.y = prop_size.y
		property.global_position = prop_position
		
		prop_position.y += prop_size.y + prop_separation
	
	queue_redraw()


func check_hovering(mouse_position: Vector2) -> void:
	if is_hovering():
		queue_redraw() # Queue a forced redraw in case we're exiting the gizmo right now.
	
	# Consume all hovering over the general area of the gizmo.
	if _base_rect.has_point(mouse_position):
		
		# Check which property we're hovering over and update its state.
		var next_hovered_property: PropertyEditor = null
		for property in _properties:
			var prop_rect := property.get_global_rect()
			if prop_rect.has_point(mouse_position):
				next_hovered_property = property
				break
		
		if next_hovered_property != _hovered_property:
			if _hovered_property:
				_hovered_property.set_hovering(false)
			
			_hovered_property = next_hovered_property
			
			if _hovered_property:
				_hovered_property.set_hovering(true)
		
		set_hovering(true)
	else:
		if _hovered_property:
			_hovered_property.set_hovering(false)
			_hovered_property = null
		
		set_hovering(false)


func get_hovered_cursor_shape(mouse_position: Vector2) -> CursorShape:
	if not is_hovering():
		return super(mouse_position)
	
	if _hovered_property:
		return Control.CURSOR_POINTING_HAND
	return Control.CURSOR_ARROW


func can_handle_input(event: InputEvent) -> bool:
	if _editing_property:
		return true # If one of the editors is active, we consume the event eagerly.
	
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
	if _editing_property:
		_editing_property.handle_input(event)
		return
	
	if not is_hovering():
		return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not is_grabbing() && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			set_grabbing(true)
		
		elif is_grabbing() && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			set_grabbing(false)
	
	if _hovered_property:
		_hovered_property.handle_input(event)


# Property management.

func add_property_editor(property_type: int, property_name: String, property_setter: Callable) -> PropertyEditor:
	if not _reference_element:
		return null
	
	var prop_editor: PropertyEditor = null
	
	match property_type:
		PropertyEditorType.PROPERTY_TOGGLE:
			prop_editor = TogglePropertyEditor.new(_reference_element, property_name, property_setter)
		
		PropertyEditorType.PROPERTY_COLOR:
			prop_editor = ColorPropertyEditor.new(_reference_element, property_name, property_setter)
	
	if prop_editor:
		_properties.push_back(prop_editor)
		add_child(prop_editor)
		
		prop_editor.editing_started.connect(func() -> void:
			_editing_property = prop_editor
			set_grabbing(true)
		)
		prop_editor.editing_stopped.connect(func() -> void:
			_editing_property = null
			set_grabbing(false)
		)
	
	return prop_editor
