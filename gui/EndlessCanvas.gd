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

enum EditingMode {
	DIMENSIONAL_TOOLS,
	STYLING_TOOLS,
	BEHAVIOR_TOOLS,
	ANIMATION_TOOLS,
}
var _editing_mode: EditingMode = EditingMode.DIMENSIONAL_TOOLS

var _current_canvas: UICanvas = null
var _drawn_elements: Array[CanvasElementControl] = []
var _selected_elements: Array[BaseUIElement] = []

const ZOOM_STEP := 1.2
const ZOOM_MIN := 1 / pow(ZOOM_STEP, 8)
const ZOOM_MAX := 1 * pow(ZOOM_STEP, 4)

var _elements_scale: float = 1.0
var _elements_offset: Vector2 = Vector2.ZERO
var _canvas_dragging: bool = false
var _canvas_drag_position: Vector2 = Vector2.ZERO

@onready var _element_container: Control = %Elements
@onready var _gizmos_container: CanvasGizmos = %Gizmos
@onready var _properties_drawer: PropertiesDrawer = %PropertiesDrawer

var _editing_mode_buttons := preload("res://gui/canvas/editing_mode_button_group.tres")


static func get_instance() -> EndlessCanvas:
	return _instance


func _init() -> void:
	if _instance:
		printerr("EndlessCanvas: Only one instance of EndlessCanvas is allowed.")
	
	_instance = self


func _ready() -> void:
	_edit_current_canvas()
	
	_editing_mode_buttons.pressed.connect(_change_editing_mode_by_button)
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
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
				_create_element(to_canvas_coordinates(mb.global_position))
			
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				_stop_canvas_dragging()
	
	elif _canvas_dragging && event is InputEventMouseMotion:
		_process_canvas_dragging(event)


# Canvas management.

func _edit_current_canvas() -> void:
	if _current_canvas:
		_current_canvas.element_created.disconnect(_add_canvas_element)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_current_canvas.element_created.connect(_add_canvas_element)


func _change_editing_mode(new_mode: EditingMode) -> void:
	if _editing_mode == new_mode:
		return
	
	_editing_mode = new_mode
	_update_element_tools()


func _change_editing_mode_by_button(button: Button) -> void:
	var button_index := button.get_index()
	_change_editing_mode(button_index)


# Canvas transform.

func _update_canvas_transform() -> void:
	_element_container.scale = Vector2(_elements_scale, _elements_scale)
	_element_container.position = -_elements_offset
	canvas_transformed.emit()


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


# Element management.

func _create_element(canvas_position: Vector2) -> void:
	if not Controller.current_project || not _current_canvas:
		return
	
	_current_canvas.create_element(ElementType.ELEMENT_PANEL, canvas_position)


func _add_canvas_element(element: BaseUIElement) -> void:
	var canvas_element := CanvasElementControl.new()
	canvas_element.data = element
	
	_element_container.add_child(canvas_element)
	_drawn_elements.push_back(canvas_element)
	
	# Auto-select the added element.
	_selected_elements.clear()
	_selected_elements.push_back(element)
	
	_update_element_tools()


func _try_select_element(canvas_position: Vector2) -> void:
	# TODO: Add support for multiple selection modes, adding and subtracting elements from the selection.
	# TODO: Add support for multi-element selections.
	_selected_elements.clear()
	
	for element in _drawn_elements:
		if not element.is_visible_on_screen() || not element.data:
			break
		
		if element.is_selectable(canvas_position):
			_selected_elements.push_back(element.data)
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
