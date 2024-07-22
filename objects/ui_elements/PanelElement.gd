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
@export var background_color: Color = Color.WHITE

## The flag that enables border drawing.
@export var draw_border: bool = false
## The color of the border.
@export var border_color: Color = Color.BLACK
## The width/size of the border.
@export var border_width: int = 2

## The flag that enables shadow drawing.
@export var draw_shadow: bool = false
## The color of the shadow.
@export var shadow_color: Color = Color(0, 0, 0, 0.4)
## The offset of the shadow from the panel position.
@export var shadow_offset: Vector2 = Vector2(2.0, 2.0)
## The size of the shadow, expanding upon the size of the base panel.
@export var shadow_size: Vector2i = Vector2i(8, 8)

# Runtime properties and rendering data.

var _base_style: StyleBoxFlat = StyleBoxFlat.new()
var _border_style: StyleBoxFlat = StyleBoxFlat.new()
var _shadow_style: StyleBoxFlat = StyleBoxFlat.new()


func _init() -> void:
	super()
	
	_update_base_style()
	_update_border_style()
	_update_shadow_style()


# Implementation.

func draw() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	if draw_shadow:
		var shadow_rect = element_rect
		shadow_rect.position += shadow_offset
		canvas_control.draw_style_box(_shadow_style, shadow_rect)
	
	if draw_background:
		canvas_control.draw_style_box(_base_style, element_rect)
	
	if draw_border:
		canvas_control.draw_style_box(_border_style, element_rect)


func get_editable_properties(editing_mode: EndlessCanvas.EditingMode) -> Array[PropertyEditor]:
	var properties := super(editing_mode)
	
	if editing_mode == EndlessCanvas.EditingMode.STYLING_TOOLS:
		var background_property := TogglePropertyEditor.new(self, "draw_background", _toggle_draw_background)
		background_property.label = "Background"
		properties.push_back(background_property)
		properties.push_back(ColorPropertyEditor.new(self, "background_color", _set_background_color))
		
		var border_property := TogglePropertyEditor.new(self, "draw_border", _toggle_draw_border)
		border_property.label = "Border"
		properties.push_back(border_property)
		properties.push_back(ColorPropertyEditor.new(self, "border_color", _set_border_color))
		
		var shadow_property := TogglePropertyEditor.new(self, "draw_shadow", _toggle_draw_shadow)
		shadow_property.label = "Shadow"
		properties.push_back(shadow_property)
		properties.push_back(ColorPropertyEditor.new(self, "shadow_color", _set_shadow_color))
	
	return properties


# Properties.

func _update_base_style() -> void:
	_base_style.bg_color = background_color


func _toggle_draw_background(value: bool) -> void:
	if draw_background == value:
		return
		
	draw_background = value
	properties_changed.emit()


func _set_background_color(value: Color) -> void:
	if background_color == value:
		return
	background_color = value
	
	_update_base_style()
	properties_changed.emit()


func _update_border_style() -> void:
	_border_style.bg_color = Color(0, 0, 0, 0)
	_border_style.border_color = border_color
	_border_style.set_border_width_all(border_width)


func _toggle_draw_border(value: bool) -> void:
	if draw_border == value:
		return
		
	draw_border = value
	properties_changed.emit()


func _set_border_color(value: Color) -> void:
	if border_color == value:
		return
	border_color = value
	
	_update_border_style()
	properties_changed.emit()


func _update_shadow_style() -> void:
	_shadow_style.bg_color = shadow_color
	_shadow_style.border_color = Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.0)
	_shadow_style.border_blend = true
	
	# TODO: This value should be affected by the corner radius of the main panel and the shadow size.
	_shadow_style.set_corner_radius_all(8)
	
	_shadow_style.expand_margin_left = shadow_size.x
	_shadow_style.expand_margin_right = shadow_size.x
	_shadow_style.expand_margin_top = shadow_size.y
	_shadow_style.expand_margin_bottom = shadow_size.y
	
	_shadow_style.border_width_left = shadow_size.x
	_shadow_style.border_width_right = shadow_size.x
	_shadow_style.border_width_top = shadow_size.y
	_shadow_style.border_width_bottom = shadow_size.y


func _toggle_draw_shadow(value: bool) -> void:
	if draw_shadow == value:
		return
		
	draw_shadow = value
	properties_changed.emit()


func _set_shadow_color(value: Color) -> void:
	if shadow_color == value:
		return
	shadow_color = value
	
	_update_shadow_style()
	properties_changed.emit()
