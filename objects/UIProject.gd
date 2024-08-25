###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The project is a collection of canvases and their global settings,
## as well as export options and other such information.
class_name UIProject extends Resource

signal project_changed()

const FILE_FORMAT := 3
const FILE_EXTENSION := "grvt"
const FILE_DEFAULT_NAME := "new_project"

# Metadata.

## File format version.
@export var format_version: int = FILE_FORMAT
## Project's title.
@export var name: String = ""
## File name on disk, if available.
@export var filename: String = ""

# Project data.

@export var canvases: Array[UICanvas] = []

# Runtime properties.

var _dirty: bool = false


static func create_default_project() -> UIProject:
	var project := UIProject.new()
	
	# There must always be a canvas.
	var default_canvas := UICanvas.new()
	project.canvases.push_back(default_canvas)
	
	return project


func get_safe_filename(extension: String = FILE_EXTENSION) -> String:
	if filename.is_empty():
		return "%s.%s" % [ FILE_DEFAULT_NAME, extension ]
	
	var base_name := filename.get_file().get_basename()
	return "%s.%s" % [ base_name, extension ]


# Runtime.

func mark_dirty() -> void:
	_dirty = true
	project_changed.emit()


func mark_clean() -> void:
	_dirty = false


func is_dirty() -> bool:
	return _dirty
