###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Global logic controller, orchestrating operations across the entire app.
extends Node

signal project_loaded()
signal canvas_changed()
signal editing_mode_changed()

var state_manager: StateManager = null

var _editing_mode: int = EditingMode.LAYOUT_TOOLS
var _editing_mode_buttons := preload("res://gui/widgets/editing_mode_button_group.tres")

var current_project: UIProject = null
var current_canvas_index: int = -1


func _init() -> void:
	state_manager = StateManager.new()
	state_manager.state_changed.connect(func() -> void:
		# TODO: It would be nice to track the last saved state and if we undo changes to get to it, mark as clean instead.
		current_project.mark_dirty()
	)
	
	_editing_mode_buttons.pressed.connect(_change_editing_mode_by_button)


func _ready() -> void:
	state_manager.clear_state_memory()


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo", false, true):
		state_manager.undo_state_change()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_redo", false, true):
		state_manager.do_state_change()
		get_viewport().set_input_as_handled()


# Editing mode management.

func get_editing_mode() -> int:
	return _editing_mode


func change_editing_mode(mode: int) -> void:
	if _editing_mode == mode:
		return
	
	_editing_mode = mode
	editing_mode_changed.emit()


func _change_editing_mode_by_button(button: Button) -> void:
	var button_index := button.get_index()
	change_editing_mode(button_index)


# Project management.

func initialize_project() -> void:
	var project := UIProject.create_default_project()
	
	# TODO: Gracefully unload existing project.
	current_project = project
	current_canvas_index = 0
	project_loaded.emit()
	canvas_changed.emit()


# Canvas management.

func get_current_canvas() -> UICanvas:
	if not current_project:
		return null
	if current_canvas_index < 0 || current_canvas_index >= current_project.canvases.size():
		return null
	
	return current_project.canvases[current_canvas_index]
