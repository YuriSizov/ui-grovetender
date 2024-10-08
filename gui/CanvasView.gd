###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasView extends Control

var _edited_canvas: UICanvas = null

# Selection properties.

enum SelectionMode {
	REPLACE_SELECTION,
	ADD_TO_SELECTION,
	REMOVE_FROM_SELECTION,
}

var _selection: CanvasSelection = CanvasSelection.new()

const SELECTION_DRAG_THRESHOLD := 16.0 # 4 pixels squared?

var _selection_dragging: bool = false
var _selection_drag_rect: Rect2 = Rect2()
var _selection_drag_last_position: Vector2 = Vector2.ZERO
var _selection_drag_total_distance: float = 0.0

# Canvas transform properties.

var _canvas_dragging: bool = false
var _canvas_drag_last_position: Vector2 = Vector2.ZERO

@onready var _canvas_elements: CanvasElements = %Elements
@onready var _canvas_gizmos: CanvasGizmos = %Gizmos
@onready var _canvas_overlay: Control = %Overlay
@onready var _canvas_drawer: CanvasDrawer = %CanvasDrawer
@onready var _properties_drawer: PropertiesDrawer = %PropertiesDrawer
@onready var _canvas_context_menu: CanvasContextMenu = %CanvasContextMenu


func _ready() -> void:
	_update_canvas_grid()
	_edit_current_canvas()
	
	_canvas_overlay.draw.connect(_draw_canvas_overlay)
	_canvas_drawer.element_selected.connect(_select_element)
	
	if not Engine.is_editor_hint():
		_canvas_gizmos.connect_to_selection(_selection)
		_properties_drawer.connect_to_selection(_selection)
	
		Controller.canvas_changed.connect(_edit_current_canvas)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		_canvas_context_menu.clear_options()
		
		if mb.pressed: # Events triggered on mouse press.
			match mb.button_index:
				MOUSE_BUTTON_LEFT:
					_start_selection_dragging(mb)
				
				MOUSE_BUTTON_MIDDLE:
					_start_canvas_dragging(mb.global_position)
				
				MOUSE_BUTTON_WHEEL_UP:
					_adjust_canvas_scale(UICanvas.SCALE_STEP, mb.global_position)
				
				MOUSE_BUTTON_WHEEL_DOWN:
					_adjust_canvas_scale(1.0 / UICanvas.SCALE_STEP, mb.global_position)
			
		else: # Events triggered on mouse release.
			match mb.button_index:
				MOUSE_BUTTON_LEFT:
					var selection_mode := SelectionMode.REPLACE_SELECTION
					if mb.shift_pressed && not mb.alt_pressed:
						selection_mode = SelectionMode.ADD_TO_SELECTION
					elif mb.alt_pressed && not mb.shift_pressed:
						selection_mode = SelectionMode.REMOVE_FROM_SELECTION
					
					# If we're dragging a selection, handle that and try to select/deselect all matching elements.
					if _selection_dragging && _selection_drag_total_distance >= SELECTION_DRAG_THRESHOLD:
						_stop_selection_dragging(selection_mode)
					
					# Alternatively, treat it as a click and try to select/deselect one element.
					else:
						_cancel_selection_dragging()
						_try_select_element(mb.global_position, selection_mode)
				
				MOUSE_BUTTON_RIGHT:
					_show_create_context_menu(mb.global_position)
				
				MOUSE_BUTTON_MIDDLE:
					_stop_canvas_dragging()
	
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		
		if _selection_dragging:
			_process_selection_dragging(mm.global_position)
		
		if _canvas_dragging:
			_process_canvas_dragging(mm.global_position)


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("grove_create_element", false, true):
		var mouse_position := get_global_mouse_position()
		_show_create_context_menu(mouse_position)
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("grove_remove_elements", false, true):
		_remove_elements_from_canvas()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("grove_group_elements", false, true):
		_group_elements_on_canvas()
		
		get_viewport().set_input_as_handled()


func _draw() -> void:
	# Draw anything just so we can use a shader.
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)


func _draw_canvas_overlay() -> void:
	if _selection_dragging && _selection_drag_total_distance >= SELECTION_DRAG_THRESHOLD:
		var selection_style := get_theme_stylebox("selection_frame", "CanvasOverlay")
		var selection_size := get_theme_constant("selection_size", "CanvasOverlay")
		var selection_rect := _selection_drag_rect.abs()
		
		DrawingUtil.draw_stylebox_frame(_canvas_overlay.get_canvas_item(), selection_style, selection_rect, selection_size)


# Canvas transform.

func _adjust_canvas_scale(factor: float, towards_position: Vector2) -> void:
	if not _edited_canvas:
		return
	
	var current_scale := _edited_canvas.get_canvas_scale()
	_edited_canvas.set_canvas_scale(current_scale * factor, towards_position)


func _start_canvas_dragging(from_position: Vector2) -> void:
	_canvas_dragging = true
	_canvas_drag_last_position = from_position


func _stop_canvas_dragging() -> void:
	_canvas_dragging = false
	_canvas_drag_last_position = Vector2.ZERO


func _process_canvas_dragging(current_position: Vector2) -> void:
	if not _edited_canvas:
		return
	if not _canvas_dragging:
		return
	
	# This accounts for skipped mouse events (e.g. consumed by something else).
	var relative := current_position - _canvas_drag_last_position
	_canvas_drag_last_position = current_position
	
	var current_offset := _edited_canvas.get_canvas_offset()
	_edited_canvas.set_canvas_offset(current_offset - relative)


# Grid visuals.

func _update_canvas_grid() -> void:
	if not _edited_canvas:
		return
	
	var shader := (material as ShaderMaterial)
	shader.set_shader_parameter("grid_offset", _edited_canvas.get_canvas_offset())
	shader.set_shader_parameter("grid_scale", _edited_canvas.get_canvas_scale())


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	_selection.clear()
	
	if _edited_canvas:
		_edited_canvas.element_created.disconnect(_handle_created_element)
		_edited_canvas.element_removed.disconnect(_handle_removed_element)
		_edited_canvas.canvas_transformed.disconnect(_update_canvas_grid)
	
	_edited_canvas = Controller.get_current_canvas()
	
	if _edited_canvas:
		_edited_canvas.element_created.connect(_handle_created_element)
		_edited_canvas.element_removed.connect(_handle_removed_element)
		_edited_canvas.canvas_transformed.connect(_update_canvas_grid)
	
	_update_canvas_grid()


func _add_element_to_canvas(element_type: int, mouse_position: Vector2) -> void:
	if not _edited_canvas:
		return
	
	# TODO: Add support for other data types, eventually.
	var data_type: Object = BaseElementData
	match element_type:
		ElementType.ELEMENT_PANEL:
			data_type = PanelElementData
		_:
			data_type = BaseElementData
	
	var canvas_position := _edited_canvas.to_canvas_coordinates(mouse_position)
	_edited_canvas.create_element(null, data_type, canvas_position)


func _handle_created_element(element: UIElement) -> void:
	_select_element(element, SelectionMode.REPLACE_SELECTION)


func _remove_elements_from_canvas() -> void:
	if not _edited_canvas:
		return
	
	for element in _selection.get_selection():
		_edited_canvas.remove_element(element)


func _handle_removed_element(element: UIElement) -> void:
	_select_element(element, SelectionMode.REMOVE_FROM_SELECTION)


func _group_elements_on_canvas() -> void:
	if not _edited_canvas:
		return
	
	var selected_elements := _selection.get_selection()
	if not selected_elements.is_empty():
		_edited_canvas.group_elements(selected_elements)


# Canvas actions.

func _show_create_context_menu(mouse_position: Vector2) -> void:
	_canvas_context_menu.clear_options()
	
	if not _edited_canvas:
		return
	
	var context_options: Array[CanvasContextMenu.Option] = []
	
	for i in ElementType.MAX:
		var create_option := CanvasContextMenu.Option.new()
		create_option.label = ElementType.get_element_name(i)
		create_option.icon = ElementType.get_element_icon(i)
		create_option.action = func() -> void:
			_add_element_to_canvas(i, mouse_position)
		
		context_options.push_back(create_option)
	
	_canvas_context_menu.show_options(context_options, mouse_position)


# Selection management.

func _start_selection_dragging(event: InputEventMouseButton) -> void:
	_selection_dragging = true
	
	_selection_drag_rect.position = event.global_position
	_selection_drag_rect.size = Vector2.ZERO
	_selection_drag_last_position = event.global_position
	_selection_drag_total_distance = 0.0
	
	_canvas_overlay.queue_redraw()


func _stop_selection_dragging(mode: SelectionMode) -> void:
	_selection_dragging = false
	
	# Normalize the rectangle.
	_selection_drag_rect = _selection_drag_rect.abs()
	
	if _edited_canvas:
		var canvas_rect := _edited_canvas.to_canvas_rect(_selection_drag_rect)
		_try_select_multiple_elements(canvas_rect, mode)
	
	_selection_drag_rect = Rect2()
	_selection_drag_last_position = Vector2.ZERO
	_selection_drag_total_distance = 0.0
	
	_canvas_overlay.queue_redraw()


func _cancel_selection_dragging() -> void:
	_selection_dragging = false
	_selection_drag_rect = Rect2()
	_selection_drag_last_position = Vector2.ZERO
	_selection_drag_total_distance = 0.0
	
	_canvas_overlay.queue_redraw()


func _process_selection_dragging(current_position: Vector2) -> void:
	if not _selection_dragging:
		return
	
	# This accounts for skipped mouse events (e.g. consumed by something else).
	var relative := current_position - _selection_drag_last_position
	_selection_drag_last_position = current_position
	
	_selection_drag_rect.size += relative
	_selection_drag_total_distance += relative.length_squared()
	# We don't really care for the exact value once it's past the threshold. So truncate the accumulator here.
	_selection_drag_total_distance = clampf(_selection_drag_total_distance, 0.0, SELECTION_DRAG_THRESHOLD + 1.0)
	
	_canvas_overlay.queue_redraw()


func _select_element(element: UIElement, mode: SelectionMode) -> void:
	if mode == SelectionMode.REPLACE_SELECTION:
		_selection.clear()
	
	if element:
		if mode == SelectionMode.REMOVE_FROM_SELECTION:
			_selection.deselect(element)
		else:
			_selection.select(element)


func _try_select_element(mouse_position: Vector2, mode: SelectionMode) -> void:
	if not _edited_canvas:
		return
	
	var canvas_position := _edited_canvas.to_canvas_coordinates(mouse_position)
	var found_element := _canvas_elements.find_element_at_position(canvas_position)
	# A bit hacky, but allows us to manipulate this only when selecting via the viewport.
	if found_element && mode != SelectionMode.REMOVE_FROM_SELECTION:
		var state_data := found_element.find_state_on_canvas(canvas_position)
		found_element.set_selected_state(state_data)
	
	_select_element(found_element, mode)


func _select_multiple_elements(elements: Array[UIElement], mode: SelectionMode) -> void:
	if mode == SelectionMode.REPLACE_SELECTION:
		_selection.clear()
	
	if not elements.is_empty():
		if mode == SelectionMode.REMOVE_FROM_SELECTION:
			_selection.deselect_multiple(elements)
		else:
			_selection.select_multiple(elements)


func _try_select_multiple_elements(canvas_rect: Rect2, mode: SelectionMode) -> void:
	# For area selection state previews are ignored, because there doesn't seem
	# to be any logical behavior for this case.
	
	var found_elements := _canvas_elements.find_elements_in_rect(canvas_rect)
	_select_multiple_elements(found_elements, mode)
