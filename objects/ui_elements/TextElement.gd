###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A text label element. Configurable with editable text, font properties, and text decorations.
class_name TextElement extends BaseUIElement

signal text_shape_changed()

const PROJECT_DEFAULT_FONT := preload("res://gui/theme/fonts/project_default_font.tres")

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

## The file path for the font used for rendering text.
@export var font_path: String = ""
## The flag that enables automatic adjustment of the font size to fit the element size.
@export var font_size_fit: bool = true
## The size of the rendered font.
@export var font_size: float = 18.0
## The color of the rendered font.
@export var font_color: Color = Color.BLACK

## The flag that enables shadow drawing.
@export var draw_shadow: bool = false
## The color of the text shadow.
@export var shadow_color: Color = Color(0, 0, 0, 0.4)
## The offset of the text shadow.
@export var shadow_offset: Vector2 = Vector2(2.0, 2.0)

## The flag that enables outline drawing.
@export var draw_outline: bool = false
## The color of the text outline.
@export var outline_color: Color = Color.WHITE
## The size of the text outline.
@export var outline_size: float = 2.0

# Runtime properties and rendering data.

var _font: Font = null

var _text_buffer_font_size: int = 0
var _text_buffer: TextParagraph = TextParagraph.new()
var _text_buffer_position: Vector2 = Vector2.ZERO


func _init() -> void:
	super()
	element_name = "TextElement"
	
	_update_font_resource()
	_update_text_buffer()
	rect_changed.connect(func() -> void:
		if font_size_fit:
			_update_text_buffer()
		else:
			_update_text_buffer_position()
	)


# Implementation.

func draw() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	var text_position := element_rect.position + _text_buffer_position
	
	if draw_shadow:
		var shadow_position := text_position + shadow_offset
		_text_buffer.draw(canvas_control.get_canvas_item(), shadow_position, shadow_color)
	
	if draw_outline:
		_text_buffer.draw_outline(canvas_control.get_canvas_item(), text_position, int(outline_size), outline_color)
	
	_text_buffer.draw(canvas_control.get_canvas_item(), text_position, font_color)


func can_select(at_position: Vector2) -> bool:
	if _text_buffer:
		var element_rect := rect.get_bounding_rect()
		var text_rect := Rect2(element_rect.position + _text_buffer_position, _text_buffer.get_size())
		
		if text_rect.has_point(at_position):
			return true
	
	return super(at_position)


func get_gizmos(editing_mode: int) -> Array[BaseGizmo]:
	var gizmos := super(editing_mode)
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		var text_edit_gizmo := TextEditGizmo.new(self)
		text_edit_gizmo.set_text_value_property("text")
		text_edit_gizmo.connect_text_buffer(text_shape_changed, _get_text_buffer_data)
		gizmos.push_back(text_edit_gizmo)
		text_edit_gizmo.text_changed.connect(_set_text)
	
	elif editing_mode == EditingMode.STYLING_TOOLS:
		# TODO: Implement constraints, snapping, alignment.
		var shadow_gizmo := ShadowStyleGizmo.new(self)
		shadow_gizmo.set_visibility_condition(func() -> bool:
			return draw_shadow
		)
		gizmos.push_back(shadow_gizmo)
		shadow_gizmo.offset_changed.connect(_adjust_shadow_offset)
	
	return gizmos


func get_editable_properties(editing_mode: int) -> Array[PropertyEditor]:
	var properties := super(editing_mode)
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		# Text layout properties.
		
		# FIXME: This is not very reliable and will break with refactoring, so fix it perhaps?
		var layout_section := properties[0]
		
		var font_h_alignment_property := PropertyEditorHelper.create_variant_property(self, "text_horizontal_alignment", _set_text_horizontal_alignment)
		font_h_alignment_property.label = "Hor. align"
		font_h_alignment_property.add_variant_item(TextAlignment.BEGIN, "Align to the left.", preload("res://assets/icons/text-halign-left.png"))
		font_h_alignment_property.add_variant_item(TextAlignment.CENTER, "Align to the center.", preload("res://assets/icons/text-halign-center.png"))
		font_h_alignment_property.add_variant_item(TextAlignment.END, "Align to the right.", preload("res://assets/icons/text-halign-right.png"))
		layout_section.connect_property_to_section(font_h_alignment_property)
		properties.push_back(font_h_alignment_property)
	
		var font_v_alignment_property := PropertyEditorHelper.create_variant_property(self, "text_vertical_alignment", _set_text_vertical_alignment)
		font_v_alignment_property.label = "Ver. align"
		font_v_alignment_property.add_variant_item(TextAlignment.BEGIN, "Align to the top.", preload("res://assets/icons/text-valign-top.png"))
		font_v_alignment_property.add_variant_item(TextAlignment.CENTER, "Align to the middle.", preload("res://assets/icons/text-valign-middle.png"))
		font_v_alignment_property.add_variant_item(TextAlignment.END, "Align to the bottom.", preload("res://assets/icons/text-valign-bottom.png"))
		layout_section.connect_property_to_section(font_v_alignment_property)
		properties.push_back(font_v_alignment_property)
		
		# Text properties.
		
		var text_section := PropertyEditorHelper.create_section(self, "Text", preload("res://assets/icons/text-layout.png"))
		properties.push_back(text_section)
		
		var font_property := PropertyEditorHelper.create_font_file_property(self, "font_path", _set_font_path)
		font_property.label = "Font"
		font_property.set_font_resource_getter(_get_font_resource)
		text_section.connect_property_to_section(font_property)
		properties.push_back(font_property)
		
		var font_size_fit_property := PropertyEditorHelper.create_toggle_property(self, "font_size_fit", _toggle_fit_font_size)
		font_size_fit_property.label = "Fit to height"
		text_section.connect_property_to_section(font_size_fit_property)
		properties.push_back(font_size_fit_property)
		
		var font_size_property := PropertyEditorHelper.create_stepper_property(self, "font_size", _set_font_size)
		font_size_property.label = "Font size"
		font_size_property.set_value_limits(0.0, 120.0, false, true)
		font_size_property.set_value_step(1.0)
		text_section.connect_property_to_section(font_size_property)
		properties.push_back(font_size_property)
	
	elif editing_mode == EditingMode.STYLING_TOOLS:
		# Text properties.
		
		var text_section := PropertyEditorHelper.create_section(self, "Fill", preload("res://assets/icons/text-fill.png"))
		properties.push_back(text_section)
		
		var font_color_property := PropertyEditorHelper.create_color_property(self, "font_color", _set_font_color)
		font_color_property.label = "Color"
		text_section.connect_property_to_section(font_color_property)
		properties.push_back(font_color_property)
		
		# Shadow properties.
		
		var shadow_section := PropertyEditorHelper.create_togglable_section(
			self, "draw_shadow", _toggle_draw_shadow,
			"Shadow", preload("res://assets/icons/text-shadow.png")
		)
		properties.push_back(shadow_section)
		
		var shadow_color_property := PropertyEditorHelper.create_color_property(self, "shadow_color", _set_shadow_color)
		shadow_color_property.label = "Color"
		shadow_section.connect_property_to_section(shadow_color_property)
		properties.push_back(shadow_color_property)
		
		var shadow_offset_property := PropertyEditorHelper.create_stepper_property(self, "shadow_offset", _set_shadow_offset)
		shadow_offset_property.label = "Offset"
		shadow_offset_property.set_value_limits(-40.0, 40.0, true, true) # Max value doesn't matter.
		shadow_offset_property.set_value_step(1.0)
		shadow_section.connect_property_to_section(shadow_offset_property)
		properties.push_back(shadow_offset_property)
		
		# Outline properties.
		
		var outline_section := PropertyEditorHelper.create_togglable_section(
			self, "draw_outline", _toggle_draw_outline,
			"Outline", preload("res://assets/icons/text-outline.png")
		)
		properties.push_back(outline_section)
		
		var outline_color_property := PropertyEditorHelper.create_color_property(self, "outline_color", _set_outline_color)
		outline_color_property.label = "Color"
		outline_section.connect_property_to_section(outline_color_property)
		properties.push_back(outline_color_property)
		
		var outline_size_property := PropertyEditorHelper.create_stepper_property(self, "outline_size", _set_outline_size)
		outline_size_property.label = "Size"
		outline_size_property.set_value_limits(0.0, 40.0, false, true) # Max value doesn't matter.
		outline_size_property.set_value_step(1.0)
		outline_section.connect_property_to_section(outline_size_property)
		properties.push_back(outline_size_property)
	
	return properties


# Properties - Basic.

func _update_text_buffer() -> void:
	if font_size_fit:
		# TODO: This is a naive approach, can likely be improved.
		var number_of_lines := text.split("\n").size()
		var maximum_height := int(rect.size.y / number_of_lines)
		
		# We want to fit the entire shaped rectangle into the element size, but we can only
		# control the font size. The actual shaped height includes font's own sizing considerations,
		# as well as descent, and extra spacing. So we try to approximate a good value before
		# shaping, although this may not always produce perfect results.
		_text_buffer_font_size = maximum_height
		while (_font.get_ascent(_text_buffer_font_size) + _font.get_descent(_text_buffer_font_size)) > maximum_height:
			_text_buffer_font_size -= 1
	
	else:
		_text_buffer_font_size = int(font_size)
	
	_text_buffer.clear()
	if _text_buffer_font_size > 0:
		_text_buffer.add_string(text, _font, _text_buffer_font_size)
	
	_update_text_buffer_position()


func _update_text_buffer_position() -> void:
	var text_size := _text_buffer.get_size()
	var text_position := Vector2.ZERO
	
	match text_horizontal_alignment:
		TextAlignment.BEGIN:
			text_position.x += 0.0
		TextAlignment.CENTER:
			text_position.x += (rect.size.x - text_size.x) / 2.0
		TextAlignment.END:
			text_position.x += rect.size.x - text_size.x
	
	match text_vertical_alignment:
		TextAlignment.BEGIN:
			text_position.y += 0.0
		TextAlignment.CENTER:
			text_position.y += (rect.size.y - text_size.y) / 2.0
		TextAlignment.END:
			text_position.y += rect.size.y - text_size.y
	
	_text_buffer_position = text_position
	text_shape_changed.emit()


func _get_text_buffer_data() -> Array:
	return [ _text_buffer, _text_buffer_position ]


func _set_text(value: String) -> void:
	if text == value:
		return
	text = value
	
	_update_text_buffer()
	property_changed.emit("text")
	properties_changed.emit()


func _set_text_horizontal_alignment(value: TextAlignment) -> void:
	if text_horizontal_alignment == value:
		return
	text_horizontal_alignment = value
	
	_update_text_buffer_position()
	property_changed.emit("text_horizontal_alignment")
	properties_changed.emit()


func _set_text_vertical_alignment(value: TextAlignment) -> void:
	if text_vertical_alignment == value:
		return
	text_vertical_alignment = value
	
	_update_text_buffer_position()
	property_changed.emit("text_vertical_alignment")
	properties_changed.emit()


# Properties - Font.

func _update_font_resource() -> void:
	if font_path.is_empty() || not FileAccess.file_exists(font_path):
		# TODO: Add some nice built-in open font as a default option? NotoSans is okay for now.
		_font = PROJECT_DEFAULT_FONT
		return
	
	var font_data := FileAccess.get_file_as_bytes(font_path)
	
	_font = FontFile.new()
	_font.data = font_data
	_font.multichannel_signed_distance_field = true
	_font.msdf_pixel_range = 8
	_font.msdf_size = 48


func _get_font_resource() -> Font:
	return _font


func _set_font_path(value: String) -> void:
	if font_path == value:
		return
	font_path = value
	
	_update_font_resource()
	_update_text_buffer()
	property_changed.emit("font_path")
	properties_changed.emit()


func _set_font_size(value: float) -> void:
	if font_size == value:
		return
	font_size = value
	
	_update_text_buffer()
	property_changed.emit("font_size")
	properties_changed.emit()


func _toggle_fit_font_size(value: bool) -> void:
	if font_size_fit == value:
		return
	font_size_fit = value
	
	_update_text_buffer()
	property_changed.emit("font_size_fit")
	properties_changed.emit()


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


func _set_shadow_offset(value: Vector2) -> void:
	if not draw_shadow:
		return
	shadow_offset = value
	
	property_changed.emit("shadow_offset")
	properties_changed.emit()


func _adjust_shadow_offset(delta: Vector2) -> void:
	if not draw_shadow:
		return
	
	shadow_offset += delta
	
	property_changed.emit("shadow_offset")
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


func _set_outline_size(value: float) -> void:
	if not draw_outline:
		return
	outline_size = value
	
	property_changed.emit("outline_size")
	properties_changed.emit()
