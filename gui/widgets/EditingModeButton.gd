###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name EditingModeButton extends Button

## The action associated with this button that triggers the shortcut.
@export var shortcut_action: StringName = &"":
	set = set_shortcut_action

@onready var _shortcut_label: Label = $Label


func _ready() -> void:
	_update_shortcut()


func set_shortcut_action(value: StringName) -> void:
	if shortcut_action == value:
		return
	
	shortcut_action = value
	_update_shortcut()


func _update_shortcut() -> void:
	if not is_inside_tree():
		return
	
	if not InputMap.has_action(shortcut_action):
		shortcut.events.clear()
		_shortcut_label.text = "?"
		return
	
	var action_events := InputMap.action_get_events(shortcut_action)
	shortcut.events.append_array(action_events)
	
	var shortcut_event := action_events[0] as InputEventKey
	var keycode := DisplayServer.keyboard_get_keycode_from_physical(shortcut_event.physical_keycode)
	_shortcut_label.text = OS.get_keycode_string(keycode)
