###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasElements extends Control

const ELEMENT_PROXY_SCENE := preload("res://gui/canvas/ElementProxy.tscn")

var _current_proxy: ElementProxy = null


func _init() -> void:
	_current_proxy = ELEMENT_PROXY_SCENE.instantiate()
	_current_proxy.element = UIElement.new(BaseElementData)
	_current_proxy.element.set_anchor_point(Vector2(512, 256))
	_current_proxy.element.default_state.set_size(Vector2(64, 64))
	add_child(_current_proxy)
	
	for i in 3:
		var extra_state := _current_proxy.element.create_state(StateType.STATE_PRESSED, "pressed")
		
		if i == 0 || i == 2:
			# When doing this for real, we must set the value to the default state's current value.
			extra_state.state.override_property("size")
			extra_state.set_size(Vector2(randi_range(1, 3), randi_range(1, 3)) * 32)
		
		if i == 1 || i == 2:
			extra_state.state.override_property("debug_color")
			extra_state.set_debug_color(Color(randf(), randf(), randf()))
		
		extra_state.state_in_transition.duration = 0.3
		extra_state.state_out_transition.duration = 0.1

func _ready() -> void:
	if not Engine.is_editor_hint():
		_update_transform()
		
		CanvasView.get_instance().canvas_transformed.connect(_update_transform)


func _unhandled_key_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if not ke.pressed:
		
		if ke.keycode == KEY_0:
			var some_state := _current_proxy.element.variant_states[0]
			some_state.state.set_active(not some_state.state.is_active())
		if ke.keycode == KEY_9:
			var some_state := _current_proxy.element.variant_states[1]
			some_state.state.set_active(not some_state.state.is_active())
		if ke.keycode == KEY_8:
			var some_state := _current_proxy.element.variant_states[2]
			some_state.state.set_active(not some_state.state.is_active())


# Canvas transform.

func _update_transform() -> void:
	if not CanvasView.get_instance():
		return
	
	scale = CanvasView.get_instance().get_canvas_scale_vector()
	position = Vector2.ZERO - CanvasView.get_instance().get_canvas_offset()
