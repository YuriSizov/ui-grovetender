###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Global logic controller, orchestrating operations across the entire app.
extends Node

signal project_changed()
signal canvas_changed()

var current_project: Project = null
var current_canvas_id: int = -1


func _ready() -> void:
	_create_new_project()


# TODO: Handle existing project being destroyed.
func _create_new_project() -> void:
	current_project = Project.new()
	current_project.create_new_canvas()
	current_canvas_id = 0
	
	project_changed.emit()


func get_current_canvas() -> UICanvas:
	if not current_project:
		return null
	
	if current_canvas_id < 0 || current_canvas_id >= current_project.canvases.size():
		return null
	
	return current_project.canvases[current_canvas_id]
