###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A text label element. Configurable with editable text, font properties, and text decorations.
class_name TextElement extends BaseUIElement

## The text value to display.
@export var text: String = "Text"

## The font used for rendering text.
@export var font: Font = null
## The size of the rendered font.
@export var font_size: int = 12
## The color of the rendered font.
@export var font_color: Color = Color.BLACK

## The flag that enables shadow drawing.
@export var draw_shadow: bool = false
## The offset of the text shadow.
@export var shadow_offset: Vector2 = Vector2(2.0, 2.0)
## The color of the text shadow.
@export var shadow_color: Color = Color.BLACK


func _init() -> void:
	super()
	element_name = "TextElement"
