###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasTransformMenu extends HBoxContainer

var _edited_canvas: UICanvas = null
var _label_pressed: bool = false

@onready var _zoom_label: Label = %ZoomLabel


func _ready() -> void:
	_zoom_label.gui_input.connect(_label_gui_input)
	_zoom_label.mouse_entered.connect(func() -> void:
		_label_pressed = false
	)
	
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


func _label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_label_pressed = true
			_zoom_label.accept_event()
		
		elif _label_pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_label_pressed = false
			_zoom_label.accept_event()
			
			if _edited_canvas:
				_edited_canvas.reset_canvas_transform()


# Helpers.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	if _edited_canvas:
		_edited_canvas.canvas_transformed.disconnect(_update_transform_menu)
	
	_edited_canvas = Controller.get_current_canvas()
	
	if _edited_canvas:
		_edited_canvas.canvas_transformed.connect(_update_transform_menu)
	
	_update_transform_menu()


func _update_transform_menu() -> void:
	if not _edited_canvas:
		return
	
	var canvas_scale := _edited_canvas.get_canvas_scale()
	var normalized_scale := roundi(canvas_scale * 100.0)
	_zoom_label.text = "%d%%" % [ normalized_scale ]
	_zoom_label.tooltip_text = "Current zoom: %d%%\nClick to reset zoom and position." % [ normalized_scale ]
