###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasGizmos extends Control

signal gizmos_input_consumed()

var _grabbed_gizmo: BaseGizmo = null

@onready var _gizmo_container: Control = %Gizmos


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		# When there is a grabbed gizmo, we pass events to it directly.
		if _grabbed_gizmo:
			var cursor_shape := _grabbed_gizmo.get_hovering_cursor_shape(event.global_position)
			_update_cursor_shape(cursor_shape)
			_grabbed_gizmo.handle_input(event)
			accept_event()
			gizmos_input_consumed.emit()
			return
		
		# This back-propagates the event to children, which allows us to handle or pass events between
		# siblings.
		for gizmo: BaseGizmo in _gizmo_container.get_children():
			if gizmo.is_visible_in_tree() && gizmo.can_handle_input(event):
				var cursor_shape := gizmo.get_hovering_cursor_shape(event.global_position)
				_update_cursor_shape(cursor_shape)
				gizmo.handle_input(event)
				accept_event()
				gizmos_input_consumed.emit()
				return
		
		# If we aren't grabbing or clicking anything, then just check for hover and new cursor shape.
		for gizmo: BaseGizmo in _gizmo_container.get_children():
			if gizmo.is_visible_in_tree() && gizmo.test_hovering(event.global_position):
				var cursor_shape := gizmo.get_hovering_cursor_shape(event.global_position)
				_update_cursor_shape(cursor_shape)
				return
	
	_update_cursor_shape(Control.CURSOR_ARROW)


func _get_tooltip(at_position: Vector2) -> String:
	if _grabbed_gizmo:
		return ""
	
	for gizmo: BaseGizmo in _gizmo_container.get_children():
		if gizmo.is_visible_in_tree() && gizmo.is_hovering():
			return gizmo.get_tooltip(at_position)
	
	return ""


func _update_grabbed_gizmo(gizmo: BaseGizmo) -> void:
	_grabbed_gizmo = gizmo


# TODO: Ideally Godot should have an overridable counter-part to get_cursor_shape exposed to scripting.
# If this ever happens, this can be simplified by simply implementing the method in gizmo code. For now,
# we have to change this node's property. Setting the cursor shape directly via DisplayServer is impossible
# as well, because Viewport logic overrides it with the node property below. So we have to set the property.
func _update_cursor_shape(cursor_shape: CursorShape) -> void:
	if mouse_default_cursor_shape == cursor_shape:
		return
	
	mouse_default_cursor_shape = cursor_shape


func clear_gizmos() -> void:
	_grabbed_gizmo = null
	
	for gizmo: BaseGizmo in _gizmo_container.get_children():
		gizmo.grabbed.disconnect(_update_grabbed_gizmo.bind(gizmo))
		gizmo.released.disconnect(_update_grabbed_gizmo.bind(null))
		
		_gizmo_container.remove_child(gizmo)
		gizmo.queue_free()


func set_gizmos(new_gizmos: Array[BaseGizmo]) -> void:
	var mouse_position := get_global_mouse_position()
	
	for gizmo in new_gizmos:
		_gizmo_container.add_child(gizmo)
		
		# Update the cursor immediately, if the new gizmo is hovered.
		if gizmo.is_visible_in_tree() && gizmo.test_hovering(mouse_position):
			var cursor_shape := gizmo.get_hovering_cursor_shape(mouse_position)
			_update_cursor_shape(cursor_shape)
		
		gizmo.grabbed.connect(_update_grabbed_gizmo.bind(gizmo))
		gizmo.released.connect(_update_grabbed_gizmo.bind(null))
