###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The endless canvas on which the entire project is laid out.
class_name EndlessCanvas extends Control

signal canvas_transformed()
signal editing_mode_changed()
signal selection_changed()

# Our singleton instance.
static var _instance: EndlessCanvas = null

enum SelectionMode {
	REPLACE_SELECTION,
	ADD_TO_SELECTION,
	REMOVE_FROM_SELECTION,
}

var _editing_mode: int = EditingMode.LAYOUT_TOOLS

var _current_canvas: UICanvas = null
var _selection_object: SelectionElement = SelectionElement.new()

const ZOOM_STEP := 1.2
const ZOOM_MIN := 1 / pow(ZOOM_STEP, 8)
const ZOOM_MAX := 1 * pow(ZOOM_STEP, 4)

var _elements_scale: float = 1.0
var _elements_offset: Vector2 = Vector2.ZERO
var _canvas_dragging: bool = false
var _canvas_drag_position: Vector2 = Vector2.ZERO

@onready var _editing_mode_bar: EditingModeBar = %EditingModeBar
@onready var _element_container: CanvasElements = %CanvasElements
@onready var _gizmos_container: CanvasGizmos = %CanvasGizmos
@onready var _canvas_drawer: CanvasDrawer = %CanvasDrawer
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
	
	_selection_object.selection_changed.connect(selection_changed.emit)
	_editing_mode_buttons.pressed.connect(_change_editing_mode_by_button)
	_canvas_drawer.element_selected.connect(_select_element)
	_gizmos_container.gizmos_input_consumed.connect(_context_menu.clear_options)
	
	if not Engine.is_editor_hint():
		_editing_mode_bar.set_editing_mode(_editing_mode)
		
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
				var selection_mode := SelectionMode.REPLACE_SELECTION
				if mb.shift_pressed && not mb.alt_pressed:
					selection_mode = SelectionMode.ADD_TO_SELECTION
				elif mb.alt_pressed && not mb.shift_pressed:
					selection_mode = SelectionMode.REMOVE_FROM_SELECTION
				
				_try_select_element(to_canvas_coordinates(mb.global_position), selection_mode)
			
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
	
	elif event.is_action_pressed("grove_remove_elements", false, true):
		_remove_selected_elements()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("grove_group_elements", false, true):
		_group_selected_elements()
		
		get_viewport().set_input_as_handled()


# Canvas management.

func _edit_current_canvas() -> void:
	if _current_canvas:
		_current_canvas.element_created.disconnect(_handle_created_element)
		_current_canvas.element_removed.disconnect(_handle_removed_element)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_current_canvas.element_created.connect(_handle_created_element)
		_current_canvas.element_removed.connect(_handle_removed_element)


func _change_editing_mode(new_mode: int) -> void:
	if _editing_mode == new_mode:
		return
	
	_editing_mode = new_mode
	editing_mode_changed.emit()


func _change_editing_mode_by_button(button: Button) -> void:
	var button_index := button.get_index()
	_change_editing_mode(button_index)


func get_editing_mode() -> int:
	return _editing_mode


func _update_zoom_label() -> void:
	if not is_inside_tree():
		return
	
	_zoom_label.text = "%d%%" % [ _elements_scale * 100 ]


# Canvas transform.

func get_elements_scale() -> float:
	return _elements_scale


func get_elements_scale_vector() -> Vector2:
	return Vector2(_elements_scale, _elements_scale)


func get_elements_offset() -> Vector2:
	return _elements_offset


func _zoom_canvas(factor: float, center_at: Vector2) -> void:
	var old_offset := (_elements_offset + center_at) / _elements_scale
	
	_elements_scale = clampf(_elements_scale * factor, ZOOM_MIN, ZOOM_MAX)
	_elements_offset = old_offset * _elements_scale - center_at
	
	canvas_transformed.emit()
	_update_zoom_label()


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
	
	canvas_transformed.emit()
	_update_zoom_label()


func to_canvas_coordinates(ui_position: Vector2) -> Vector2:
	return (ui_position + _elements_offset) / _elements_scale


func from_canvas_coordinates(canvas_position: Vector2) -> Vector2:
	return canvas_position * _elements_scale - _elements_offset


# Canvas actions.

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


# Element management.

func _handle_created_element(element: BaseUIElement) -> void:
	_select_element(element, SelectionMode.REPLACE_SELECTION)


func _handle_removed_element(element: BaseUIElement) -> void:
	_selection_object.deselect_element(element)


# Selection management.

func _select_element(element: BaseUIElement, mode: SelectionMode) -> void:
	if mode == SelectionMode.REPLACE_SELECTION:
		_selection_object.clear_selection()
	
	if element:
		if mode == SelectionMode.REMOVE_FROM_SELECTION:
			_selection_object.deselect_element(element)
		else:
			_selection_object.select_element(element)


func _try_select_element(canvas_position: Vector2, mode: SelectionMode) -> void:
	var found_element := _element_container.find_element_at_position(canvas_position)
	_select_element(found_element, mode)


func get_selected_element() -> BaseUIElement:
	if _selection_object.get_selection_size() < 2:
		return _selection_object.get_first_element()
	
	return _selection_object


func _remove_selected_elements() -> void:
	if not Controller.current_project || not _current_canvas:
		return
	
	var selection := _selection_object.get_selection()
	for element in selection:
		_current_canvas.remove_element(element)


func _group_selected_elements() -> void:
	if not Controller.current_project || not _current_canvas:
		return
	
	var selection := _selection_object.get_selection()
	_current_canvas.group_elements(selection)
