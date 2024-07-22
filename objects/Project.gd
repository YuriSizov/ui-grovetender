###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Project data.
class_name Project extends Resource

signal project_changed()

const FILE_FORMAT := 1
const FILE_EXTENSION := "gtend"
const FILE_DEFAULT_NAME := "new_project"

# Metadata.

## File format version.
@export var format_version: int = FILE_FORMAT
## Project's title.
@export var name: String = ""
## File name on disk, if available.
@export var filename: String = ""

# Project data.

## A collection of canvases in this project.
@export var canvases: Array[UICanvas] = []

# Runtime properties.

var _dirty: bool = false


## Sets up the necessary properties to their default state for a new project.
## This is not called for loaded or imported projects.
func initialize_new_project() -> void:
	var canvas := UICanvas.new()
	canvases.push_back(canvas)


# Runtime.

func mark_dirty() -> void:
	_dirty = true
	project_changed.emit()


func mark_clean() -> void:
	_dirty = false


func is_dirty() -> bool:
	return _dirty
