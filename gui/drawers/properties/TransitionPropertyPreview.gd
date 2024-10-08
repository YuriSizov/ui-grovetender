###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name TransitionPropertyPreview extends PropertyEditor

const PLAYBACK_PLAY_ICON := preload("res://assets/ui/playback-handle-play.png")
const PLAYBACK_PAUSE_ICON := preload("res://assets/ui/playback-handle-pause.png")

const PLAYBACK_STEP_DELAY := 0.5

enum PlaybackDirection {
	PLAYBACK_IN,
	PLAYBACK_OUT,
}

var _playing: bool = false
var _playback_timer: SceneTreeTimer = null
var _playback_direction: PlaybackDirection = PlaybackDirection.PLAYBACK_OUT # It's inverted on call, so first direction is IN.

@onready var _preview_area: Panel = %PreviewArea
@onready var _preview_control: Control = %Preview
@onready var _playback_button: Button = %PlaybackHandle
@onready var _playback_label: Label = %PlaybackLabel


static func create(element: UIElement, element_data: BaseElementData) -> TransitionPropertyPreview:
	return _create(element, element_data, preload("res://gui/drawers/properties/TransitionPropertyPreview.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"TransitionPropertyPreview"


func _ready() -> void:
	super()
	
	_setup_preview()
	
	state_disconnected.connect(_clear_preview)
	state_connected.connect(_setup_preview)
	
	_preview_control.draw.connect(_draw_preview)
	_playback_button.pressed.connect(_toggle_playback)


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_preview_area.add_theme_stylebox_override("panel", get_theme_stylebox("preview_panel"))


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_preview_area.remove_theme_stylebox_override("panel")


func _process(_delta: float) -> void:
	if _playing:
		_update_preview_transform()


# Preview management.

func _setup_preview() -> void:
	if not _element:
		return
	
	_element.data_changed.connect(_clear_preview)
	
	_reset_playback()
	_element.deactivate_all_states()
	_update_preview_transform()


func _clear_preview() -> void:
	if not _element:
		return
	
	_element.data_changed.disconnect(_clear_preview)


func _update_preview_transform() -> void:
	var element_data := _element.get_active_data()
	
	_preview_control.size = _element.get_combined_size()
	_preview_control.position = (_preview_area.size - _preview_control.size) / 2.0 + element_data.offset
	_preview_control.queue_redraw()


func _draw_preview() -> void:
	if not _element:
		return
	
	var active_data := _element.get_active_data()
	active_data.draw(_preview_control)
	
	if _element is UICompositeElement:
		_draw_composite_preview(_element)


func _draw_composite_preview(composite_element: UICompositeElement) -> void:
	var base_position := composite_element.anchor_point
	
	for child_element in composite_element.element_group.elements:
		var child_data := child_element.get_active_data()
		var child_offset := child_element.anchor_point - base_position
		
		_preview_control.draw_set_transform(child_offset + child_data.offset)
		child_data.draw(_preview_control)
		_preview_control.draw_set_transform(Vector2.ZERO)
		
		if child_element is UICompositeElement:
			_draw_composite_preview(child_element)


# Playback management.

func _start_playback() -> void:
	if _playing:
		return
	
	_playing = true
	_update_playback_state()
	_start_playback_step()


func _stop_playback() -> void:
	if not _playing:
		return
	
	_reset_playback()
	_element.deactivate_all_states()
	_update_preview_transform()


func _toggle_playback() -> void:
	if _playing:
		_stop_playback()
	else:
		_start_playback()


func _reset_playback() -> void:
	_playing = false
	_playback_direction = PlaybackDirection.PLAYBACK_OUT
	if _playback_timer:
		_playback_timer.timeout.disconnect(_start_playback_step)
		_playback_timer = null
	
	_update_playback_state()


func _start_playback_step() -> void:
	if not _playing:
		return
	
	# FIXME: Currently for composite elements we don't respect the combined length of child transitions.
	
	if _playback_direction == PlaybackDirection.PLAYBACK_OUT:
		_playback_direction = PlaybackDirection.PLAYBACK_IN
		_playback_timer = get_tree().create_timer(_element_data.state_in_transition.get_full_duration() + PLAYBACK_STEP_DELAY)
		_playback_timer.timeout.connect(_start_playback_step)
		
		_element_data.state.set_active(true)
		_playback_label.text = "Transition: In"
	
	elif _playback_direction == PlaybackDirection.PLAYBACK_IN:
		_playback_direction = PlaybackDirection.PLAYBACK_OUT
		_playback_timer = get_tree().create_timer(_element_data.state_out_transition.get_full_duration() + PLAYBACK_STEP_DELAY)
		_playback_timer.timeout.connect(_start_playback_step)
		
		_element_data.state.set_active(false)
		_playback_label.text = "Transition: Out"


func _update_playback_state() -> void:
	if not is_node_ready():
		return
	
	if _playing:
		_playback_button.icon = PLAYBACK_PAUSE_ICON
		_playback_button.tooltip_text = "Pause the transition preview."
	else:
		_playback_button.icon = PLAYBACK_PLAY_ICON
		_playback_button.tooltip_text = "Play the transition preview."
		_playback_label.text = ""
