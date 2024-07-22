###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

extends Control

var _default_window_title: String = ""


func _enter_tree() -> void:
	# Ensure that the minimum size of the UI is respected and
	# the main window cannot go any lower.
	get_window().wrap_controls = true
	
	_default_window_title = get_window().title


func _ready() -> void:
	_edit_current_project()
	
	if not Engine.is_editor_hint():
		Controller.project_loaded.connect(_edit_current_project)


# Window decorations.

func _edit_current_project() -> void:
	if Engine.is_editor_hint():
		return
	
	_update_window_title()
	if Controller.current_project:
		Controller.current_project.project_changed.connect(_update_window_title)


func _update_window_title() -> void:
	if Engine.is_editor_hint():
		return
	
	if not Controller.current_project:
		get_window().title = _default_window_title
		return
	
	var project_name := "<New Project>" if Controller.current_project.filename.is_empty() else Controller.current_project.filename.get_file()
	var project_dirty := "* " if Controller.current_project.is_dirty() else ""
	
	get_window().title = "%s%s - %s" % [ project_dirty, project_name, _default_window_title ]
