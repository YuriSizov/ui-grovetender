###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ValuePropertyEditor extends PropertyEditor

@onready var _layout_container: HBoxContainer = %Layout
@onready var _property_name: Label = %PropertyName
@onready var _revert_button: PropertyRevertButton = %RevertButton

var _pressed: bool = false
var _name_pressed: bool = false


func _init() -> void:
	super()
	theme_type_variation = &"ValuePropertyEditor"
	
	mouse_entered.connect(func() -> void:
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_pressed = false
		_name_pressed = false
		queue_redraw()
	)


func _ready() -> void:
	super()
	
	_update_property_name()
	property_connected.connect(_update_property_name)
	
	_property_name.gui_input.connect(_handle_property_name_input)
	_revert_button.pressed.connect(revert_property_value)


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	
	_property_name.begin_bulk_theme_override()
	_property_name.add_theme_font_override("font", get_theme_font("font"))
	_property_name.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_property_name.add_theme_color_override("font_color", get_theme_color("font_color"))
	_property_name.add_theme_color_override("font_outline_color", get_theme_color("font_outline_color"))
	_property_name.add_theme_color_override("font_shadow_color", get_theme_color("font_shadow_color"))
	_property_name.add_theme_constant_override("outline_size", get_theme_constant("font_outline_size"))
	_property_name.add_theme_constant_override("shadow_offset_x", get_theme_constant("font_shadow_offset_x"))
	_property_name.add_theme_constant_override("shadow_offset_y", get_theme_constant("font_shadow_offset_y"))
	_property_name.end_bulk_theme_override()


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.remove_theme_constant_override("separation")
	
	_property_name.begin_bulk_theme_override()
	_property_name.remove_theme_font_override("font")
	_property_name.remove_theme_font_size_override("font_size")
	_property_name.remove_theme_color_override("font_color")
	_property_name.remove_theme_color_override("font_outline_color")
	_property_name.remove_theme_color_override("font_shadow_color")
	_property_name.remove_theme_constant_override("outline_size")
	_property_name.remove_theme_constant_override("shadow_offset_x")
	_property_name.remove_theme_constant_override("shadow_offset_y")
	_property_name.end_bulk_theme_override()


func _input(event: InputEvent) -> void:
	# Capture input events before GUI input in case we are going to click outside of this
	# editor and need to gracefully exit the active state.
	
	if not _editing_active:
		return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not get_global_rect().has_point(mb.global_position):
			_handle_outside_clicked(mb.global_position)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = true
			accept_event()
			queue_redraw()
		
		elif _pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = false
			accept_event()
			queue_redraw()
			
			_handle_inside_clicked(mb.global_position)

# Properties.

func _update_property_name() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	_property_name.text = _get_editor_label()


func _handle_property_name_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_name_pressed = true
			accept_event()
			queue_redraw()
		
		elif _name_pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_name_pressed = false
			accept_event()
			queue_redraw()
			
			_handle_property_name_clicked()


# Implementation.

## Called when the property name was clicked. Extending classes should treat this as editing toggle.
func _handle_property_name_clicked() -> void:
	pass


## Called when the background was clicked. This has lower priority than property name clicks or GUI
## input events handled by sub-editors. Extending classes can implement this to cancel editing.
func _handle_inside_clicked(_at_global_position: Vector2) -> void:
	_cancel_editing()


## Called when there is a click event originating from outside of the editor's bounding box. This
## only happens to active editors via _input.
func _handle_outside_clicked(_at_global_position: Vector2) -> void:
	_cancel_editing()
