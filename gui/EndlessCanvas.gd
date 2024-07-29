###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The endless canvas on which the entire project is laid out.
class_name EndlessCanvas extends Control

signal canvas_transformed()

# Our singleton instance.
static var _instance: EndlessCanvas = null


var _editing_mode: int = EditingMode.LAYOUT_TOOLS

var _current_canvas: UICanvas = null
var _selected_elements: Array[BaseUIElement] = []

const ZOOM_STEP := 1.2
const ZOOM_MIN := 1 / pow(ZOOM_STEP, 8)
const ZOOM_MAX := 1 * pow(ZOOM_STEP, 4)

var _elements_scale: float = 1.0
var _elements_offset: Vector2 = Vector2.ZERO
var _canvas_dragging: bool = false
var _canvas_drag_position: Vector2 = Vector2.ZERO

@onready var _element_container: Control = %CanvasElements
@onready var _gizmos_container: CanvasGizmos = %CanvasGizmos
@onready var _canvas_drawer: CanvasDrawer = %CanvasDrawer
@onready var _properties_drawer: PropertiesDrawer = %PropertiesDrawer
@onready var _context_menu: CanvasContextMenu = %CanvasContextMenu

@onready var _zoom_label: Label = %ZoomLabel

var _editing_mode_buttons := preload("res://gui/canvas/editing_mode_button_group.tres")


static func get_instance() -> EndlessCanvas:
	return _instance


func _init() -> void:
	if _instance:
		printerr("EndlessCanvas: Only one instance of EndlessCanvas is allowed.")
	
	_instance = self


func _ready() -> void:
	_edit_current_canvas()
	_update_zoom_label()
	
	_editing_mode_buttons.pressed.connect(_change_editing_mode_by_button)
	_canvas_drawer.element_selected.connect(_select_element.bind(true))
	_gizmos_container.gizmos_input_consumed.connect(_context_menu.clear_options)
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		_context_menu.clear_options()
		
		if mb.pressed: # Events triggered on press.
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_canvas(ZOOM_STEP, mb.global_position)
			
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_canvas(1.0 / ZOOM_STEP, mb.global_position)
			
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				_start_canvas_dragging(mb)
		
		else: # Events triggered on release.
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_try_select_element(to_canvas_coordinates(mb.global_position))
			
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_show_create_context_menu(mb.global_position)
			
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				_stop_canvas_dragging()
	
	elif _canvas_dragging && event is InputEventMouseMotion:
		_process_canvas_dragging(event)



func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("grove_create_element", false, true):
		var mouse_position := get_global_mouse_position()
		_show_create_context_menu(mouse_position)
		
		get_viewport().set_input_as_handled()


# Canvas management.

func _edit_current_canvas() -> void:
	if _current_canvas:
		_current_canvas.element_created.disconnect(_select_element.bind(true))
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_current_canvas.element_created.connect(_select_element.bind(true))


func _change_editing_mode(new_mode: int) -> void:
	if _editing_mode == new_mode:
		return
	
	_editing_mode = new_mode
	_update_element_tools()


func _change_editing_mode_by_button(button: Button) -> void:
	var button_index := button.get_index()
	_change_editing_mode(button_index)


func _update_zoom_label() -> void:
	if not is_inside_tree():
		return
	
	_zoom_label.text = "%d%%" % [ _elements_scale * 100 ]


# Canvas transform.

func _update_canvas_transform() -> void:
	_element_container.scale = Vector2(_elements_scale, _elements_scale)
	_element_container.position = -_elements_offset
	canvas_transformed.emit()
	
	_update_zoom_label()


func _zoom_canvas(factor: float, center_at: Vector2) -> void:
	var old_offset := (_elements_offset + center_at) / _elements_scale
	
	_elements_scale = clampf(_elements_scale * factor, ZOOM_MIN, ZOOM_MAX)
	_elements_offset = old_offset * _elements_scale - center_at
	_update_canvas_transform()


func _start_canvas_dragging(event: InputEventMouseButton) -> void:
	_canvas_dragging = true
	_canvas_drag_position = event.global_position


func _stop_canvas_dragging() -> void:
	_canvas_dragging = false
	_canvas_drag_position = Vector2.ZERO


func _process_canvas_dragging(event: InputEventMouseMotion) -> void:
	if not _canvas_dragging:
		return
	
	# This accounts for skipped mouse events (e.g. consumed by something else).
	var relative := event.global_position - _canvas_drag_position
	_canvas_drag_position = event.global_position
	
	_elements_offset -= relative
	_update_canvas_transform()


func get_elements_scale() -> float:
	return _elements_scale


func to_canvas_coordinates(ui_position: Vector2) -> Vector2:
	return (ui_position + _elements_offset) / _elements_scale


func from_canvas_coordinates(canvas_position: Vector2) -> Vector2:
	return canvas_position * _elements_scale - _elements_offset


# Selection management.

func _show_create_context_menu(mouse_position: Vector2) -> void:
	_context_menu.clear_options()
	
	if not Controller.current_project || not _current_canvas:
		return
	
	var context_options: Array[CanvasContextMenu.Option] = []
	
	for i in ElementType.MAX:
		var create_option := CanvasContextMenu.Option.new()
		create_option.label = ElementType.get_element_name(i)
		create_option.icon = ElementType.get_element_icon(i)
		create_option.action = func() -> void:
			_current_canvas.create_element(i, to_canvas_coordinates(mouse_position))
		
		context_options.push_back(create_option)
	
	_context_menu.show_options(context_options, mouse_position)


func _unselect_all_elements() -> void:
	for element in _selected_elements:
		element.set_selected(false)
	
	_selected_elements.clear()


func _select_element(element: BaseUIElement, exclusive: bool = false) -> void:
	if exclusive:
		_unselect_all_elements()
	
	element.set_selected(true)
	_selected_elements.push_back(element)
	
	_update_element_tools()


func _try_select_element(canvas_position: Vector2) -> void:
	# TODO: Add support for multiple selection modes, adding and subtracting elements from the selection.
	# TODO: Add support for multi-element selections.
	_unselect_all_elements()
	
	var drawn_elements_count := _element_container.get_child_count()
	for i in drawn_elements_count:
		var element_index := drawn_elements_count - 1 - i # Iterate backwards, from the topmost.
		var canvas_element := _element_container.get_child(element_index)
		
		if not canvas_element.is_visible_on_screen() || not canvas_element.data:
			break
		
		if canvas_element.is_selectable(canvas_position):
			_select_element(canvas_element.data)
			break # For now, select the first match only.
	
	_update_element_tools()


# Editing tools.

func _update_element_tools() -> void:
	_gizmos_container.clear_gizmos()
	_properties_drawer.clear_title()
	_properties_drawer.clear_properties()
	
	if _selected_elements.size() == 0:
		return
	
	# TODO: Support gizmos for multiple selected elements.
	if _selected_elements.size() > 1:
		return
	
	var selected_element := _selected_elements[0]
	
	var active_gizmos := selected_element.get_gizmos(_editing_mode)
	_gizmos_container.set_gizmos(active_gizmos)
	
	_properties_drawer.set_title(selected_element.element_name)
	
	var active_properties := selected_element.get_editable_properties(_editing_mode)
	_properties_drawer.set_properties(active_properties)
