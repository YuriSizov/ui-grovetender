###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasElements extends Control

const ELEMENT_PROXY_SCENE := preload("res://gui/canvas/ElementProxy.tscn")

var _current_proxy: ElementProxy = null
var _extra_state: BaseElementData = null


func _init() -> void:
	_current_proxy = ELEMENT_PROXY_SCENE.instantiate()
	_current_proxy.element = UIElement.new(BaseElementData)
	_current_proxy.element.set_anchor_point(Vector2(512, 256))
	_current_proxy.element.default_state.set_size(Vector2(64, 64))
	add_child(_current_proxy)
	
	_extra_state = _current_proxy.element.create_state(StateType.STATE_PRESSED, "pressed")
	# When doing this for real, we must set the value to the default state's current value.
	_extra_state.state_override_property("size")
	_extra_state.set_size(Vector2(randi_range(1, 6), randi_range(1, 6)) * 32)


func _ready() -> void:
	if not Engine.is_editor_hint():
		_update_transform()
		
		CanvasView.get_instance().canvas_transformed.connect(_update_transform)


func _unhandled_key_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if not ke.pressed:
		
		if ke.keycode == KEY_0:
			_extra_state.state_set_active(not _extra_state.state_active)


# Canvas transform.

func _update_transform() -> void:
	if not CanvasView.get_instance():
		return
	
	scale = CanvasView.get_instance().get_canvas_scale_vector()
	position = Vector2.ZERO - CanvasView.get_instance().get_canvas_offset()
