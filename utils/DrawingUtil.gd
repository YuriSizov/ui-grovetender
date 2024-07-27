###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name DrawingUtil extends Object


## Draws a TextLine instance at the given position with the given color,
## optionally draws its shadow and outline, if conditions are met.
static func draw_text_buffer(canvas_item: RID, buffer: TextLine, position: Vector2, color: Color, shadow_offset: Vector2 = Vector2.ZERO, shadow_color: Color = Color.BLACK, outline_size: int = 0, outline_color: Color = Color.BLACK) -> void:
	if shadow_offset.x > 0 || shadow_offset.y > 0:
		buffer.draw(canvas_item, position + shadow_offset, shadow_color)
	
	if outline_size > 0:
		buffer.draw_outline(canvas_item, position, outline_size, outline_color)
	
	buffer.draw(canvas_item, position, color)
