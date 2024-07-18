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


# Implementation.

func render() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	if draw_background:
		canvas_control.draw_rect(element_rect, background_color)
	
	if draw_border:
		canvas_control.draw_rect(element_rect, border_color, false, border_width)


func get_gizmos() -> Array[BaseGizmo]:
	var gizmos := super()
	
	var properties_gizmo := PropertiesGizmo.new()
	properties_gizmo.connect_to_element(self)
	gizmos.push_front(properties_gizmo)
	
	var background_property := properties_gizmo.add_property_editor(PropertyEditorType.PROPERTY_TOGGLE, "draw_background", _toggle_draw_background)
	background_property.label = "Background"
	properties_gizmo.add_property_editor(PropertyEditorType.PROPERTY_COLOR, "background_color", _set_background_color)
	
	var border_property := properties_gizmo.add_property_editor(PropertyEditorType.PROPERTY_TOGGLE, "draw_border", _toggle_draw_border)
	border_property.label = "Border"
	properties_gizmo.add_property_editor(PropertyEditorType.PROPERTY_COLOR, "border_color", _set_border_color)
	
	return gizmos


# Helpers.

func _toggle_draw_background(value: bool) -> void:
	if draw_background == value:
		return
		
	draw_background = value
	redraw_needed.emit()


func _set_background_color(value: Color) -> void:
	pass


func _toggle_draw_border(value: bool) -> void:
	if draw_border == value:
		return
		
	draw_border = value
	redraw_needed.emit()


func _set_border_color(value: Color) -> void:
	pass
