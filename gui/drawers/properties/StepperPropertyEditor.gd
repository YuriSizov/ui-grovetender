###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name StepperPropertyEditor extends ValuePropertyEditor

var _min_value: float = 0.0
var _max_value: float = 100.0
var _value_step: float = 1.0
var _allow_lesser_values: bool = false
var _allow_greater_values: bool = false

@onready var _stepper_grid: GridContainer = %StepperGrid
@onready var _property_stepper1: SpinBox = %PropertyValue1
@onready var _property_stepper2: SpinBox = %PropertyValue2
@onready var _property_stepper3: SpinBox = %PropertyValue3
@onready var _property_stepper4: SpinBox = %PropertyValue4

var _focused_stepper: SpinBox = null


static func create(element: UIElement, element_data: BaseElementData) -> StepperPropertyEditor:
	return _create(element, element_data, preload("res://gui/drawers/properties/StepperPropertyEditor.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"StepperPropertyEditor"
	
	resized.connect(queue_redraw)
	sort_children.connect(queue_redraw)


func _ready() -> void:
	super()
	
	_update_property_steppers()
	property_connected.connect(_update_property_steppers)
	property_changed.connect(_update_stepper_values)
	
	for stepper: SpinBox in _stepper_grid.get_children():
		stepper.value_changed.connect(_change_property_value.bind(stepper.get_index()))
		stepper.get_line_edit().focus_entered.connect(_handle_stepper_focused.bind(stepper))
		stepper.get_line_edit().focus_exited.connect(_handle_stepper_unfocused.bind(stepper))
	
	_stepper_grid.sort_children.connect(queue_redraw)


# Properties.

func _update_property_steppers() -> void:
	if not is_inside_tree():
		return
	if not has_property():
		return
	
	var value: Variant = get_property_value()
	var value_type := typeof(value)
	
	# Update stepper limits.
	
	_property_stepper1.min_value = _min_value
	_property_stepper1.max_value = _max_value
	_property_stepper1.step = _value_step
	_property_stepper1.allow_lesser = _allow_lesser_values
	_property_stepper1.allow_greater = _allow_greater_values
	
	_property_stepper2.min_value = _min_value
	_property_stepper2.max_value = _max_value
	_property_stepper2.step = _value_step
	_property_stepper2.allow_lesser = _allow_lesser_values
	_property_stepper2.allow_greater = _allow_greater_values
	
	_property_stepper3.min_value = _min_value
	_property_stepper3.max_value = _max_value
	_property_stepper3.step = _value_step
	_property_stepper3.allow_lesser = _allow_lesser_values
	_property_stepper3.allow_greater = _allow_greater_values
	
	_property_stepper4.min_value = _min_value
	_property_stepper4.max_value = _max_value
	_property_stepper4.step = _value_step
	_property_stepper4.allow_lesser = _allow_lesser_values
	_property_stepper4.allow_greater = _allow_greater_values
	
	# Update steppers based on the type size.
	match value_type:
		TYPE_INT, TYPE_FLOAT:
			_stepper_grid.columns = 1
			_property_stepper1.visible = true
			_property_stepper2.visible = false
			_property_stepper3.visible = false
			_property_stepper4.visible = false
		
		TYPE_VECTOR2I, TYPE_VECTOR2:
			_stepper_grid.columns = 2
			_property_stepper1.visible = true
			_property_stepper2.visible = true
			_property_stepper3.visible = false
			_property_stepper4.visible = false
		
		TYPE_VECTOR3I, TYPE_VECTOR3:
			_stepper_grid.columns = 3
			_property_stepper1.visible = true
			_property_stepper2.visible = true
			_property_stepper3.visible = true
			_property_stepper4.visible = false
		
		TYPE_VECTOR4I, TYPE_VECTOR4:
			_stepper_grid.columns = 2 # Display as a 2x2 grid.
			_property_stepper1.visible = true
			_property_stepper2.visible = true
			_property_stepper3.visible = true
			_property_stepper4.visible = true
	
	_update_stepper_values()


func _update_stepper_values() -> void:
	if not is_inside_tree():
		return
	if not has_property():
		return
	
	var value: Variant = get_property_value()
	var value_type := typeof(value)
	
	match value_type:
		TYPE_INT, TYPE_FLOAT:
			_set_stepper_value_safe(_property_stepper1, value)
		
		TYPE_VECTOR2I, TYPE_VECTOR2:
			_set_stepper_value_safe(_property_stepper1, value.x)
			_set_stepper_value_safe(_property_stepper2, value.y)
		
		TYPE_VECTOR3I, TYPE_VECTOR3:
			_set_stepper_value_safe(_property_stepper1, value.x)
			_set_stepper_value_safe(_property_stepper2, value.y)
			_set_stepper_value_safe(_property_stepper3, value.z)
		
		TYPE_VECTOR4I, TYPE_VECTOR4:
			_set_stepper_value_safe(_property_stepper1, value.x)
			_set_stepper_value_safe(_property_stepper2, value.y)
			_set_stepper_value_safe(_property_stepper3, value.z)
			_set_stepper_value_safe(_property_stepper4, value.w)


func _set_stepper_value_safe(stepper: SpinBox, value: float) -> void:
	if stepper == _focused_stepper:
		return # Avoid overriding if we're currently editing.
	
	stepper.set_value_no_signal(value)


func set_value_limits(min_value: float, max_value: float, allow_lesser: bool = false, allow_greater: bool = false) -> void:
	_min_value = min_value
	_max_value = max_value
	_allow_lesser_values = allow_lesser
	_allow_greater_values = allow_greater
	
	_update_property_steppers()


func set_value_step(step: float) -> void:
	_value_step = step
	
	_update_property_steppers()


func _handle_stepper_focused(stepper: SpinBox) -> void:
	_focused_stepper = stepper
	_start_editing()


func _handle_stepper_unfocused(stepper: SpinBox) -> void:
	if _focused_stepper == stepper: # In case we've already gained focus elsewhere.
		_focused_stepper = null
		_stop_editing()


func _change_property_value(value: float, value_index: int) -> void:
	if not has_property() || not _prop_setter.is_valid():
		return
	
	var full_value: Variant = get_property_value()
	var value_type := typeof(full_value)
	
	if value_type == TYPE_INT || value_type == TYPE_FLOAT:
		set_property_value(value) # For single-unit values, just replace it as a whole.
		return
	
	full_value[value_index] = value
	set_property_value(full_value)


# Implementation.

func _handle_property_name_clicked() -> void:
	if _focused_stepper:
		_focused_stepper.get_line_edit().release_focus()
		return
	
	_property_stepper1.get_line_edit().grab_focus()


func _cancel_editing() -> void:
	if _focused_stepper:
		_focused_stepper.get_line_edit().release_focus()
	super()
