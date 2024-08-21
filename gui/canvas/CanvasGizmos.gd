###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasGizmos extends Control

var _edited_canvas: UICanvas = null
var _selection: CanvasSelection = null
var _edited_element: UIElement = null


func _ready() -> void:
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)
		Controller.editing_mode_changed.connect(_update_gizmos)


func _draw() -> void:
	if not _selection || _selection.get_selection_size() == 0:
		return
	
	var boundary_style := get_theme_stylebox("boundary_frame")
	var boundary_size := get_theme_constant("boundary_size")
	
	for element in _selection.get_selection():
		var element_rect := element.get_selected_rect()
		var boundary_rect := _edited_canvas.from_canvas_rect(element_rect)
		DrawingUtil.draw_stylebox_frame(get_canvas_item(), boundary_style, boundary_rect, boundary_size)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var me := event as InputEventMouse
		var mouse_position := me.global_position
		
		for gizmo: BaseGizmo in get_children():
			var local_position := mouse_position - gizmo.global_position
			if gizmo.test_point(local_position):
				_update_cursor_shape(gizmo.get_handle_cursor_shape())
				gizmo.handle_gui_input(event)
				
				# Always accept event.
				accept_event()
				return
	
	_update_cursor_shape(Control.CURSOR_ARROW)


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	if _edited_canvas:
		_edited_canvas.canvas_transformed.disconnect(queue_redraw)
	
	_edited_canvas = Controller.get_current_canvas()
	
	if _edited_canvas:
		_edited_canvas.canvas_transformed.connect(queue_redraw)


func connect_to_selection(selection: CanvasSelection) -> void:
	_selection = selection
	_selection.selection_changed.connect(_edit_selected_element)
	_selection.selection_changed.connect(queue_redraw)
	
	_edit_selected_element()
	queue_redraw()


# Element management.

func _edit_selected_element() -> void:
	if Engine.is_editor_hint():
		return
	if not _selection:
		return
	
	if _selection.get_selection_size() != 1:
		_edited_element = null
		_update_gizmos()
		return
	
	var next_element := _selection.get_first_selected()
	if _edited_element == next_element:
		return
	
	_edited_element = next_element
	_update_gizmos()


func _update_gizmos() -> void:
	_clear_gizmos()
	
	if not _edited_element:
		return
	
	var editing_mode := Controller.get_editing_mode()
	var selected_state := _edited_element.get_selected_state_data()
	var active_gizmos := selected_state.get_gizmos(_edited_element, editing_mode)
	
	for gizmo in active_gizmos:
		gizmo.connect_to_canvas(_edited_canvas)
		
		add_child(gizmo)


func _clear_gizmos() -> void:
	for gizmo: BaseGizmo in get_children():
		gizmo.get_parent().remove_child(gizmo)
		gizmo.queue_free()


# Gizmo helpers.

# HACK: Ideally Godot should have an overridable counterpart to get_cursor_shape exposed to scripting.
# If this ever happens, this can be simplified by simply implementing the method in gizmo code. For now,
# we have to change this node's property. Setting the cursor shape directly via DisplayServer is impossible
# as well, because Viewport logic overrides it with the node property below. So we have to set the property.
func _update_cursor_shape(cursor_shape: CursorShape) -> void:
	if mouse_default_cursor_shape == cursor_shape:
		return
	
	mouse_default_cursor_shape = cursor_shape
