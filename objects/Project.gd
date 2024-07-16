###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## Project data.
class_name Project extends Resource

## A collection of this project's hotspots.
@export var hotspots: Array[Hotspot] = []


## Creates a new hotspot with the given center position. No checks for overlaps are performed.
func create_hotspot(position: Vector2) -> Hotspot:
	var hotspot := Hotspot.new()
	hotspot.position = position
	
	hotspots.push_back(hotspot)
	
	return hotspot
