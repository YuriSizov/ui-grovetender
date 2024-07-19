###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ColorPropertyEditor extends ButtonPropertyEditor

const COLOR_PICKER_SCENE := preload("res://gui/widgets/SimpleColorPicker.tscn")
var _color_picker: SimpleColorPicker = null


func _init(_object: Object, _name: String, _setter: Callable) -> void:
	super(PropertyEditorType.PROPERTY_COLOR, _object, _name, _setter)
	
	theme_type_variation = &"ColorPropertyEditor"
	
	_color_picker = COLOR_PICKER_SCENE.instantiate()
	_color_picker.visible = false
	add_child(_color_picker)


func _ready() -> void:
	button_released.connect(func() -> void:
		var picker_offset := Vector2(
			get_theme_constant("picker_offset_x"),
			get_theme_constant("picker_offset_y")
		) + Vector2(size.x, 0)
		
		_color_picker.position = picker_offset
		_color_picker.get_picker().color = object.get(prop_name)
		_color_picker.visible = not _color_picker.visible
		
		if _color_picker.visible:
			editing_started.emit()
		else:
			editing_stopped.emit()
	)
	
	_color_picker.get_picker().color_changed.connect(func(color: Color) -> void:
		if prop_setter.is_valid():
			prop_setter.call(color)
		
		queue_redraw()
	)


func _draw() -> void:
	super()
	
	var available_rect := Rect2(Vector2.ZERO, size)
	var background_panel := get_current_panel()
	
	var preview_position := available_rect.position + Vector2(
		background_panel.content_margin_left,
		background_panel.content_margin_top
	)
	var preview_size := Vector2(
		get_theme_constant("color_preview_x"),
		get_theme_constant("color_preview_y")
	)
	
	var preview_color: Color = object.get(prop_name)
	draw_rect(Rect2(preview_position, preview_size), preview_color)


func _get_minimum_size() -> Vector2:
	var combined_size := Vector2(
		get_theme_constant("color_preview_x"),
		get_theme_constant("color_preview_y")
	)
	
	var background_panel := get_theme_stylebox("panel")
	combined_size.x += background_panel.content_margin_left + background_panel.content_margin_right
	combined_size.y += background_panel.content_margin_top + background_panel.content_margin_bottom
	
	return combined_size


# Implementation.

func _cancel_editing() -> void:
	_color_picker.visible = false
	
	super()
