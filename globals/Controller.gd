###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Global logic controller, orchestrating operations across the entire app.
extends Node

var state_manager: StateManager = null


func _init() -> void:
	state_manager = StateManager.new()
	state_manager.state_changed.connect(func() -> void:
		pass
	)


func _ready() -> void:
	state_manager.clear_state_memory()


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo", false, true):
		state_manager.undo_state_change()
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_redo", false, true):
		state_manager.do_state_change()
		get_viewport().set_input_as_handled()
