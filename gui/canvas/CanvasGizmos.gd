###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasGizmos extends Control

var _grabbed_gizmo: BaseGizmo = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		# When there is a grabbed gizmo, we pass events to it directly.
		if _grabbed_gizmo:
			var cursor_shape := _grabbed_gizmo.get_hovered_cursor_shape(event.global_position)
			_update_cursor_shape(cursor_shape)
			_grabbed_gizmo.handle_input(event)
			accept_event()
			return
		
		# This back-propagates the event to children, which allows us to handle or pass events between
		# siblings.
		for gizmo: BaseGizmo in get_children():
			if gizmo.can_handle_input(event):
				var cursor_shape := gizmo.get_hovered_cursor_shape(event.global_position)
				_update_cursor_shape(cursor_shape)
				gizmo.handle_input(event)
				accept_event()
				return
		
		# If we aren't grabbing or clicking anything, then just check for hover and new cursor shape.
		for gizmo: BaseGizmo in get_children():
			if gizmo.is_hovering(event.global_position):
				var cursor_shape := gizmo.get_hovered_cursor_shape(event.global_position)
				_update_cursor_shape(cursor_shape)
				return
	
	_update_cursor_shape(Control.CURSOR_ARROW)


func _update_grabbed_gizmo(gizmo: BaseGizmo) -> void:
	_grabbed_gizmo = gizmo


func _update_cursor_shape(cursor_shape: CursorShape) -> void:
	if mouse_default_cursor_shape == cursor_shape:
		return
	
	mouse_default_cursor_shape = cursor_shape


func clear_gizmos() -> void:
	for gizmo: BaseGizmo in get_children():
		gizmo.grabbed.disconnect(_update_grabbed_gizmo.bind(gizmo))
		gizmo.released.disconnect(_update_grabbed_gizmo.bind(null))
		
		remove_child(gizmo)
		gizmo.queue_free()


func set_gizmos(new_gizmos: Array[BaseGizmo]) -> void:
	var mouse_position := get_global_mouse_position()
	
	for gizmo in new_gizmos:
		add_child(gizmo)
		
		# Update the cursor immediately, if the new gizmo is hovered.
		if gizmo.is_hovering(mouse_position):
			var cursor_shape := gizmo.get_hovered_cursor_shape(mouse_position)
			_update_cursor_shape(cursor_shape)
		
		gizmo.grabbed.connect(_update_grabbed_gizmo.bind(gizmo))
		gizmo.released.connect(_update_grabbed_gizmo.bind(null))
