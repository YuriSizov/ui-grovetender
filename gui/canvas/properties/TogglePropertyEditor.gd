###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name TogglePropertyEditor extends ButtonPropertyEditor

const CHECKBOX_ICONS := [
	preload("res://assets/ui/checkbox-checked.png"),
	preload("res://assets/ui/checkbox-unchecked.png")
]

var icon: Texture2D = null:
	set = set_icon


func _init(_element: Object, _name: String, _setter: Callable) -> void:
	super(_element, _name, _setter)
	
	theme_type_variation = &"TogglePropertyEditor"


func _ready() -> void:
	button_released.connect(func() -> void:
		if prop_setter.is_valid():
			var current_value: bool = element.get(prop_name)
			prop_setter.call(not current_value)
	)


func _draw() -> void:
	super()
	var available_rect := get_content_rect()
	
	# Draw the editor's custom icon, if present.
	if icon:
		var icon_size := Vector2(
			get_theme_constant("icon_size"),
			get_theme_constant("icon_size")
		)
		var icon_position := Vector2(
			available_rect.position.x,
			available_rect.position.y + (available_rect.size.y - icon_size.y) / 2.0
		)
		
		draw_texture_rect(icon, Rect2(icon_position, icon_size), false)
		available_rect = available_rect.grow_side(SIDE_LEFT, -(icon_size.x + get_theme_constant("icon_separation")))
	
	# Draw the checkbox in its current state.
	if CHECKBOX_ICONS[0]:
		var checkbox_size := Vector2(
			get_theme_constant("checkbox_size"),
			get_theme_constant("checkbox_size")
		)
		var checkbox_position := Vector2(
			available_rect.position.x + available_rect.size.x - checkbox_size.x,
			available_rect.position.y + (available_rect.size.y - checkbox_size.y) / 2.0
		)
		var checkbox_icon: Texture2D = CHECKBOX_ICONS[0] if element.get(prop_name) else CHECKBOX_ICONS[1]
		
		draw_texture_rect(checkbox_icon, Rect2(checkbox_position, checkbox_size), false)
		available_rect = available_rect.grow_side(SIDE_RIGHT, -(checkbox_size.x + get_theme_constant("checkbox_separation")))
	
	# Draw the label in between the two icons.
	
	var label_position := Vector2(
		available_rect.position.x,
		available_rect.position.y + (available_rect.size.y - _label_text_buffer.get_size().y) / 2.0
	)
	var label_color := get_theme_color("font_color")
	var label_shadow_offset := Vector2(
		get_theme_constant("font_shadow_offset_x"),
		get_theme_constant("font_shadow_offset_y")
	)
	var label_shadow_color := get_theme_color("font_shadow_color")
	var label_outline_size := get_theme_constant("font_outline_size")
	var label_outline_color := get_theme_color("font_outline_color")
	
	DrawingUtil.draw_text_buffer(
		get_canvas_item(), _label_text_buffer, label_position, label_color,
		label_shadow_offset, label_shadow_color,
		label_outline_size, label_outline_color
	)


func _get_minimum_size() -> Vector2:
	var minimum_size := Vector2(
		get_theme_constant("minimum_size_x"),
		get_theme_constant("minimum_size_y")
	)
	var combined_size := _label_text_buffer.get_size()
	
	if icon:
		var icon_size := get_theme_constant("icon_size")
		combined_size.x += icon_size + get_theme_constant("icon_separation")
		combined_size.y = maxf(combined_size.y, icon_size)
	
	if CHECKBOX_ICONS[0]:
		var checkbox_size := get_theme_constant("checkbox_size")
		combined_size.x += checkbox_size + get_theme_constant("checkbox_separation")
		combined_size.y = maxf(combined_size.y, checkbox_size)
	
	var background_panel := get_theme_stylebox("panel")
	combined_size.x += background_panel.content_margin_left + background_panel.content_margin_right
	combined_size.y += background_panel.content_margin_top + background_panel.content_margin_bottom
	
	return minimum_size.max(combined_size)


# Properties.

func set_icon(value: Texture2D) -> void:
	icon = value
	
	update_minimum_size()
	queue_redraw()
