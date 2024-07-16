###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A gizmo for editing the position of an item or a group of items.
class_name PositionGizmo extends BaseGizmo

signal size_changed(delta: Vector2)


func can_handle_input(event: InputEvent) -> bool:
	return false


func handle_input(event: InputEvent) -> void:
	pass
