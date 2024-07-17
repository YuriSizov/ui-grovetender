###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Project data.
class_name Project extends Resource

## A collection of canvases in this project.
@export var canvases: Array[UICanvas] = []


func create_new_canvas() -> UICanvas:
	var canvas := UICanvas.new()
	canvases.push_back(canvas)
	
	return canvas
