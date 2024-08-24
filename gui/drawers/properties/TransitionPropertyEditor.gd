###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name TransitionPropertyEditor extends PropertyEditor

@onready var _layout_container: VBoxContainer = %Layout

@onready var _duration_label: Label = %DurationLabel
@onready var _duration_value: SpinBox = %DurationValue
@onready var _curve_label: Label = %CurveLabel
@onready var _curve_value: OptionButton = %CurveValue
@onready var _easing_label: Label = %EasingLabel
@onready var _easing_value: OptionButton = %EasingValue

var _pressed: bool = false
var _label_pressed: Label = null
var _focused_widget: Control = null


static func create(element: UIElement, element_data: BaseElementData) -> TransitionPropertyEditor:
	return _create(element, element_data, preload("res://gui/drawers/properties/TransitionPropertyEditor.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"TransitionPropertyEditor"
	
	mouse_exited.connect(func() -> void:
		_pressed = false
		_label_pressed = null
	)


func _ready() -> void:
	super()
	
	_setup_editor_widgets()
	property_connected.connect(_update_editor_widgets)
	
	_duration_value.value_changed.connect(_change_transition_duration)
	_curve_value.item_selected.connect(_change_transition_curve)
	_easing_value.item_selected.connect(_change_transition_easing)
	
	_duration_label.gui_input.connect(_label_gui_input.bind(_duration_label))
	_curve_label.gui_input.connect(_label_gui_input.bind(_curve_label))
	_easing_label.gui_input.connect(_label_gui_input.bind(_easing_label))
	
	var widgets: Array[Control] = [ _duration_value.get_line_edit(), _curve_value, _easing_value ]
	for widget_control in widgets:
		widget_control.focus_entered.connect(_handle_widget_focused.bind(widget_control))
		widget_control.focus_exited.connect(_handle_widget_unfocused.bind(widget_control))


func _input(event: InputEvent) -> void:
	# Capture input events before GUI input in case we are going to click outside of this
	# editor and need to gracefully exit the active state.
	
	if not _editing_active:
		return
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not get_global_rect().has_point(mb.global_position):
			_cancel_editing()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = true
			accept_event()
			queue_redraw()
		
		elif _pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = false
			accept_event()
			queue_redraw()
			
			_cancel_editing()


func _label_gui_input(event: InputEvent, label_node: Label) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_label_pressed = label_node
			accept_event()
			queue_redraw()
		
		elif _label_pressed == label_node && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_label_pressed = null
			accept_event()
			queue_redraw()
			
			_activate_widget_by_label(label_node)


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.add_theme_constant_override("separation", get_theme_constant("base_separation"))


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.remove_theme_constant_override("separation")


# Editor management.

func _setup_editor_widgets() -> void:
	_curve_value.clear()
	_curve_value.add_item("Linear",      Tween.TransitionType.TRANS_LINEAR)
	_curve_value.add_item("Sine",        Tween.TransitionType.TRANS_SINE)
	_curve_value.add_item("Quintic",     Tween.TransitionType.TRANS_QUINT)
	_curve_value.add_item("Quartic",     Tween.TransitionType.TRANS_QUART)
	_curve_value.add_item("Quadratic",   Tween.TransitionType.TRANS_QUAD)
	_curve_value.add_item("Exponential", Tween.TransitionType.TRANS_EXPO)
	_curve_value.add_item("Elastic",     Tween.TransitionType.TRANS_ELASTIC)
	_curve_value.add_item("Cubic",       Tween.TransitionType.TRANS_CUBIC)
	_curve_value.add_item("Square Root", Tween.TransitionType.TRANS_CIRC)
	_curve_value.add_item("Bounce",      Tween.TransitionType.TRANS_BOUNCE)
	_curve_value.add_item("Back out",    Tween.TransitionType.TRANS_BACK)
	_curve_value.add_item("Spring",      Tween.TransitionType.TRANS_SPRING)
	
	_easing_value.clear()
	_easing_value.add_item("Ease In",     Tween.EaseType.EASE_IN)
	_easing_value.add_item("Ease Out",    Tween.EaseType.EASE_OUT)
	_easing_value.add_item("Ease In/Out", Tween.EaseType.EASE_IN_OUT)
	_easing_value.add_item("Ease Out/In", Tween.EaseType.EASE_OUT_IN)
	
	_update_editor_widgets()


func _update_editor_widgets() -> void:
	if not has_property():
		return
	
	var transition_data: UITransition = get_property_value()
	_duration_value.set_value_no_signal(transition_data.duration)
	_curve_value.select(_curve_value.get_item_index(transition_data.curve))
	_easing_value.select(_easing_value.get_item_index(transition_data.easing))


func _activate_widget_by_label(widget_label: Label) -> void:
	var widget_control: Control = null
	
	if widget_label == _duration_label:
		widget_control = _duration_value.get_line_edit()
	elif widget_label == _curve_label:
		widget_control = _curve_value
	elif widget_label == _easing_label:
		widget_control = _easing_value
	
	if not widget_control:
		return
	if widget_control == _focused_widget:
		_focused_widget.release_focus()
	else:
		widget_control.grab_focus()


func _handle_widget_focused(widget_control: Control) -> void:
	_focused_widget = widget_control
	_start_editing()


func _handle_widget_unfocused(widget_control: Control) -> void:
	if _focused_widget == widget_control: # In case we've already gained focus elsewhere.
		_focused_widget = null
		_stop_editing()


# Transition management.

func _change_transition_duration(value: float) -> void:
	if not has_property():
		return
	
	var transition_data: UITransition = get_property_value()
	transition_data.set_duration(value)


func _change_transition_curve(value_index: int) -> void:
	if not has_property():
		return
	
	var transition_data: UITransition = get_property_value()
	var value := _curve_value.get_item_id(value_index)
	transition_data.set_curve(value)


func _change_transition_easing(value_index: int) -> void:
	if not has_property():
		return
	
	var transition_data: UITransition = get_property_value()
	var value := _easing_value.get_item_id(value_index)
	transition_data.set_easing(value)


# Implementation.

func _cancel_editing() -> void:
	if _focused_widget:
		_focused_widget.release_focus()
	super()
