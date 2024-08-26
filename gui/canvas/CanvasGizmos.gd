###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasGizmos extends Control

var _edited_canvas: UICanvas = null
var _selection: CanvasSelection = null
var _edited_element: UIElement = null

var _grabbed_gizmo: BaseGizmo = null

var _gizmo_container: Control = null


func _init() -> void:
	# We use an extra node here, because tooltips are added as a node
	# to CanvasGizmos and get in the way.
	_gizmo_container = Control.new()
	_gizmo_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gizmo_container)


func _ready() -> void:
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)
		Controller.editing_mode_changed.connect(_update_gizmos)


func _draw() -> void:
	if not _selection || _selection.get_selection_size() == 0:
		return
	
	# Under all gizmos always draw the boundary box for every selected
	# element.
	
	var boundary_style := get_theme_stylebox("boundary_frame")
	var boundary_size := get_theme_constant("boundary_size")
	
	for element in _selection.get_selection():
		var element_state := element.get_selected_state_data()
		var element_rect := element.get_selected_rect()
		element_rect.position -= element_state.offset
		
		var boundary_rect := _edited_canvas.from_canvas_rect(element_rect)
		DrawingUtil.draw_stylebox_frame(get_canvas_item(), boundary_style, boundary_rect, boundary_size)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		
		# Pass the event to the grabbed gizmo, if there is one.
		if _grabbed_gizmo && _try_gizmo_input(_grabbed_gizmo, event, true):
			return
		
		# If not, check every gizmo. We iterate through all of them to clear
		# some intermediate states, if necessary.
		var handled := false
		var gizmos := _gizmo_container.get_children()
		gizmos.reverse() # Iterate backwards, so gizmos drawn on top are handled first.
		
		for gizmo: BaseGizmo in gizmos:
			if not handled && _try_gizmo_input(gizmo, event):
				handled = true
				continue
			
			gizmo.set_hovering(false)
		
		if handled:
			return
		
	_update_gizmo_cursor_shape(Control.CURSOR_ARROW)


func _get_tooltip(_at_position: Vector2) -> String:
	return _get_gizmo_tooltip()


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
	
	if _edited_element:
		_edited_element.transform_changed.disconnect(queue_redraw)
	
	if _selection.get_selection_size() != 1:
		_edited_element = null
		_update_gizmos()
		return
	
	_edited_element = _selection.get_first_selected()
	
	if _edited_element:
		_edited_element.transform_changed.connect(queue_redraw)
	
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
		gizmo.gizmo_grabbed.connect(_update_grabbed_gizmo.bind(gizmo))
		gizmo.gizmo_released.connect(_update_grabbed_gizmo.bind(null))
		
		_gizmo_container.add_child(gizmo)


func _clear_gizmos() -> void:
	_grabbed_gizmo = null
	
	for gizmo: BaseGizmo in _gizmo_container.get_children():
		gizmo.gizmo_grabbed.disconnect(_update_grabbed_gizmo.bind(gizmo))
		gizmo.gizmo_released.disconnect(_update_grabbed_gizmo.bind(null))
		
		gizmo.get_parent().remove_child(gizmo)
		gizmo.queue_free()


# Gizmo helpers.

func _try_gizmo_input(gizmo: BaseGizmo, mouse_event: InputEventMouse, forced: bool = false) -> bool:
	var local_position := mouse_event.global_position - gizmo.global_position
	# Forcing input without point tests helps when gizmos don't update in time with element
	# changes, which happens pretty much all the time.
	if not forced && not gizmo.test_point(local_position):
		return false
	
	gizmo.set_hovering(true)
	gizmo.handle_mouse_input(mouse_event)
	_update_gizmo_cursor_shape(gizmo.get_handle_cursor_shape())
	
	return true


func _update_grabbed_gizmo(gizmo: BaseGizmo) -> void:
	_grabbed_gizmo = gizmo


# HACK: Ideally Godot should have an overridable counterpart to get_cursor_shape exposed to scripting.
# If this ever happens, this can be simplified by simply implementing the method in gizmo code. For now,
# we have to change this node's property. Setting the cursor shape directly via DisplayServer is impossible
# as well, because Viewport logic overrides it with the node property below. So we have to set the property.
func _update_gizmo_cursor_shape(cursor_shape: CursorShape) -> void:
	if mouse_default_cursor_shape == cursor_shape:
		return
	
	mouse_default_cursor_shape = cursor_shape


func _get_gizmo_tooltip() -> String:
	if _grabbed_gizmo:
		return ""
	
	for gizmo: BaseGizmo in _gizmo_container.get_children():
		if gizmo.is_hovering():
			return gizmo.get_handle_tooltip()
	
	return ""
