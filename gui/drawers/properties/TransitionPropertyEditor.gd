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


static func create(element: UIElement, element_data: BaseElementData) -> TransitionPropertyEditor:
	return _create(element, element_data, preload("res://gui/drawers/properties/TransitionPropertyEditor.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"TransitionPropertyEditor"


func _ready() -> void:
	super()
	
	_setup_editor_widgets()
	
	property_connected.connect(_update_editor_widgets)


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
