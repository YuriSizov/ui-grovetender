###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name TransitionPropertyPreview extends PropertyEditor

@onready var _preview_area: Panel = %PreviewArea
@onready var _preview_control: Control = %Preview


static func create(element: UIElement, element_data: BaseElementData) -> TransitionPropertyPreview:
	return _create(element, element_data, preload("res://gui/drawers/properties/TransitionPropertyPreview.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"TransitionPropertyPreview"


func _ready() -> void:
	super()
	
	_update_preview()
	state_connected.connect(_update_preview)
	_preview_control.draw.connect(_draw_preview)


# Preview management.

func _update_preview() -> void:
	if not _element:
		return
	
	var element_rect := _element.get_active_state_rect()
	_preview_control.size = element_rect.size
	_preview_control.position = (_preview_area.size - _preview_control.size) / 2.0
	_preview_control.queue_redraw()


func _draw_preview() -> void:
	if not _element:
		return
	
	var active_data := _element.get_active_data()
	active_data.draw(_preview_control)
