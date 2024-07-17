###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A panel UI element, which can be used as a background or foreground plane element. Configurable with
## background and border properties, or with a 9-patch texture.
# TODO: Implement support for 9-patch textures.
class_name PanelElement extends BaseUIElement

## The flag that enables background drawing.
@export var draw_background: bool = true
## The color of the background.
@export var background_color: Color = Color.ANTIQUE_WHITE

## The flag that enables border drawing.
@export var draw_border: bool = false
## The color of the border.
@export var border_color: Color = Color.BLACK
## The width/size of the border.
@export var border_width: float = 2.0


func render() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	if draw_background:
		canvas_control.draw_rect(element_rect, background_color)
	
	if draw_border:
		canvas_control.draw_rect(element_rect, border_color, false, border_width)
