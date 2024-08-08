###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## An icon/image UI element, handy for displaying graphics associated with more complex widgets.
class_name IconElement extends BaseUIElement

## The texture/image of the icon.
@export var icon: Texture2D = null


func _init() -> void:
	super()
	element_name = "IconElement"
