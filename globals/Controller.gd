###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Global logic controller, orchestrating operations across the entire app.
extends Node

signal project_loaded()
signal canvas_changed()

var state_manager: StateManager = null

var current_project: Project = null
var current_canvas_index: int = -1



func _init() -> void:
	state_manager = StateManager.new()
	
	state_manager.state_changed.connect(func() -> void:
		current_project.mark_dirty()
	)


func _ready() -> void:
	_create_new_project()


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo", false, true):
		if current_project:
			state_manager.undo_state_change()
		
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_redo", false, true):
		if current_project:
			state_manager.do_state_change()
		
		get_viewport().set_input_as_handled()


# Project management.

# TODO: Handle existing project being destroyed.
func _create_new_project() -> void:
	state_manager.clear_state_memory()
	
	current_project = Project.new()
	current_project.initialize_new_project()
	current_canvas_index = 0
	
	project_loaded.emit()


# Canvas management.

func get_current_canvas() -> UICanvas:
	if not current_project:
		return null
	
	if current_canvas_index < 0 || current_canvas_index >= current_project.canvases.size():
		return null
	
	return current_project.canvases[current_canvas_index]
