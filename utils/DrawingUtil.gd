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


## Draws a frame encompassing the given rectangle, using the given stylebox for each border.
static func draw_stylebox_frame(canvas_item: RID, frame_style: StyleBox, frame_rect: Rect2, frame_size: int) -> void:
	var horizontal_rect := Rect2()
	horizontal_rect.size = Vector2(frame_rect.size.x + 2 * frame_size, frame_size)
	var vertical_rect := Rect2()
	vertical_rect.size = Vector2(frame_size, frame_rect.size.y + 2 * frame_size)
	
	# Left border.
	vertical_rect.position = frame_rect.position - Vector2(frame_size, frame_size)
	frame_style.draw(canvas_item, vertical_rect)
	
	# Top border.
	horizontal_rect.position = frame_rect.position - Vector2(frame_size, frame_size)
	frame_style.draw(canvas_item, horizontal_rect)
	
	# Right border.
	vertical_rect.position = Vector2(frame_rect.end.x, frame_rect.position.y) - Vector2(0, frame_size)
	frame_style.draw(canvas_item, vertical_rect)
	
	# Bottom border.
	horizontal_rect.position = Vector2(frame_rect.position.x, frame_rect.end.y) - Vector2(frame_size, 0)
	frame_style.draw(canvas_item, horizontal_rect)
