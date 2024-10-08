###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PanelElementData extends BaseElementData

## The flag that enables background drawing.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var draw_background: bool = true
## The color of the background.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var background_color: Color = Color.WHITE


static func get_default_name() -> String:
	return "PanelElement"


func draw(proxy: Control) -> void:
	if debug_drawing:
		proxy.draw_rect(Rect2(Vector2.ZERO, proxy.size).grow(2), Color.RED)
	
	if draw_background:
		proxy.draw_rect(Rect2(Vector2.ZERO, size), background_color)


# Property editors and gizmos.

func get_editable_properties(element: UIElement, editing_mode: int) -> Array[PropertyEditor]:
	var properties := super(element, editing_mode)
	
	if editing_mode == EditingMode.STYLING_TOOLS:
		
		# Background properties.
		
		var background_section := SectionPropertyEditor.create(element, self)
		background_section.connect_to_property("draw_background", _toggle_draw_background)
		background_section.label = "Fill"
		background_section.icon = preload("res://assets/icons/panel-fill.png")
		properties.push_back(background_section)
		
		var background_color_property := ColorPropertyEditor.create(element, self)
		background_color_property.connect_to_property("background_color", _set_background_color)
		background_color_property.label = "Color"
		background_section.connect_editor(background_color_property)
		properties.push_back(background_color_property)
	
	return properties


# Properties.

func _toggle_draw_background(value: bool, override: bool) -> void:
	if draw_background == value:
		return
	
	draw_background = value
	_notify_properties_changed([ "draw_background" ], override)
	Controller.current_project.mark_dirty()


func _set_background_color(value: Color, override: bool) -> void:
	if background_color == value:
		return
	
	background_color = value
	_notify_properties_changed([ "background_color" ], override)
	Controller.current_project.mark_dirty()
