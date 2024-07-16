###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasGizmos extends Control


func _gui_input(event: InputEvent) -> void:
	# This back-propagates the event to children, which allows us to handle or pass events between
	# siblings.
	for gizmo: BaseGizmo in get_children():
		if gizmo.can_handle_input(event):
			gizmo.handle_input(event)
			accept_event()
			break


func clear_gizmos() -> void:
	for gizmo in get_children():
		remove_child(gizmo)
		gizmo.queue_free()


func set_gizmos(new_gizmos: Array[BaseGizmo]) -> void:
	for gizmo in new_gizmos:
		add_child(gizmo)
