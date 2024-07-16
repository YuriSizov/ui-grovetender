###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Global logic controller, orchestrating operations across the entire app.
extends Node

signal project_changed()

var current_project: Project = null


func _ready() -> void:
	_create_new_project()


# TODO: Handle existing project being destroyed.
func _create_new_project() -> void:
	current_project = Project.new()
	
	project_changed.emit()
