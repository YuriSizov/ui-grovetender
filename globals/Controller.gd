###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Global logic controller, orchestrating operations across the entire app.
extends Node

signal editing_mode_changed()
signal canvas_changed()

var state_manager: StateManager = null

var _editing_mode: int = EditingMode.LAYOUT_TOOLS
var _editing_mode_buttons := preload("res://gui/widgets/editing_mode_button_group.tres")

var _current_canvas: UICanvas = null


func _init() -> void:
	state_manager = StateManager.new()
	state_manager.state_changed.connect(func() -> void:
		pass
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


# Canvas management.

func get_current_canvas() -> UICanvas:
	return _current_canvas


func create_new_canvas() -> void:
	_current_canvas = UICanvas.new()
	canvas_changed.emit()
