###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A text label element. Configurable with editable text, font properties, and text decorations.
class_name TextElement extends BaseUIElement

enum TextAlignment {
	BEGIN,
	CENTER,
	END,
}

## The text value to display.
@export var text: String = "Text"
## The horizontal alignment of the text within the bounding box.
@export var text_horizontal_alignment: TextAlignment = TextAlignment.CENTER
## The vertical alignment of the text within the bounding box.
@export var text_vertical_alignment: TextAlignment = TextAlignment.CENTER

## The font used for rendering text.
@export var font: Font = null
## The size of the rendered font.
@export var font_size: float = 18.0
## The color of the rendered font.
@export var font_color: Color = Color.BLACK

## The flag that enables shadow drawing.
@export var draw_shadow: bool = false
## The offset of the text shadow.
@export var shadow_offset: Vector2 = Vector2(2.0, 2.0)
## The color of the text shadow.
@export var shadow_color: Color = Color.BLACK

## The flag that enables outline drawing.
@export var draw_outline: bool = false
## The size of the text outline.
@export var outline_size: float = 2.0
## The color of the text outline.
@export var outline_color: Color = Color.BLACK

# Runtime properties and rendering data.

var _text_buffer: TextLine = TextLine.new()


func _init() -> void:
	super()
	element_name = "TextElement"
	
	# Use whatever default as a placeholder.
	# TODO: Add some nice built-in open font as a default option?
	font = ThemeDB.get_project_theme().get_font("", "")
	
	_update_text_buffer()


# Implementation.

func draw() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	if element_rect.size.x == 0 || element_rect.size.y == 0:
		return
	
	if draw_shadow:
		var shadow_rect = element_rect
		shadow_rect.position += shadow_offset
		_text_buffer.draw(canvas_control.get_canvas_item(), shadow_rect.position, shadow_color)
	
	if draw_outline:
		_text_buffer.draw_outline(canvas_control.get_canvas_item(), element_rect.position, int(outline_size), outline_color)
	
	_text_buffer.draw(canvas_control.get_canvas_item(), element_rect.position, font_color)


func get_editable_properties(editing_mode: int) -> Array[PropertyEditor]:
	var properties := super(editing_mode)
	
	if editing_mode == EditingMode.STYLING_TOOLS:
		# Font properties.
		
		var font_section := PropertyEditorHelper.create_section(self, "Font", null) #preload("res://assets/icons/text-fill.png")
		properties.push_back(font_section)
		
		var font_color_property := PropertyEditorHelper.create_color_property(self, "font_color", _set_font_color)
		font_color_property.label = "Color"
		font_section.connect_property_to_section(font_color_property)
		properties.push_back(font_color_property)
		
		# Shadow properties.
		
		var shadow_section := PropertyEditorHelper.create_togglable_section(
			self, "draw_shadow", _toggle_draw_shadow,
			"Shadow", null #preload("res://assets/icons/text-shadow.png")
		)
		properties.push_back(shadow_section)
		
		var shadow_color_property := PropertyEditorHelper.create_color_property(self, "shadow_color", _set_shadow_color)
		shadow_color_property.label = "Color"
		shadow_section.connect_property_to_section(shadow_color_property)
		properties.push_back(shadow_color_property)
		
		# Outline properties.
		
		var outline_section := PropertyEditorHelper.create_togglable_section(
			self, "draw_outline", _toggle_draw_outline,
			"Outline", null #preload("res://assets/icons/text-outline.png")
		)
		properties.push_back(outline_section)
		
		var outline_color_property := PropertyEditorHelper.create_color_property(self, "outline_color", _set_outline_color)
		outline_color_property.label = "Color"
		outline_section.connect_property_to_section(outline_color_property)
		properties.push_back(outline_color_property)
		
	return properties


# Properties - Basic.

func _update_text_buffer() -> void:
	_text_buffer.clear()
	_text_buffer.add_string(text, font, int(font_size))


func _set_text(value: String) -> void:
	if text == value:
		return
	text = value
	
	_update_text_buffer()
	property_changed.emit("text")
	properties_changed.emit()


# Properties - Font.

func _set_font_color(value: Color) -> void:
	if font_color == value:
		return
	font_color = value
	
	property_changed.emit("font_color")
	properties_changed.emit()


# Properties - Shadow.

func _toggle_draw_shadow(value: bool) -> void:
	if draw_shadow == value:
		return
	draw_shadow = value
	
	property_changed.emit("draw_shadow")
	properties_changed.emit()


func _set_shadow_color(value: Color) -> void:
	if shadow_color == value:
		return
	shadow_color = value
	
	property_changed.emit("shadow_color")
	properties_changed.emit()

# Properties - Outline.

func _toggle_draw_outline(value: bool) -> void:
	if draw_outline == value:
		return
	draw_outline = value
	
	property_changed.emit("draw_outline")
	properties_changed.emit()


func _set_outline_color(value: Color) -> void:
	if outline_color == value:
		return
	outline_color = value
	
	property_changed.emit("outline_color")
	properties_changed.emit()
