###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A complex editor for UI element's states. Piggy-backing off of the property editor system,
## but isn't really a property editor.
@tool
class_name StatePropertyEditor extends PropertyEditor

const STATE_ENTRY_SCENE := preload("res://gui/widgets/StatePropertyEntry.tscn")

@onready var _layout_container: VBoxContainer = $Layout
@onready var _layout_separator: HSeparator = %HSeparator
@onready var _create_container: HBoxContainer = %CreateContainer

@onready var _states_container: VBoxContainer = %AvailableStates
@onready var _create_state_name: LineEdit = %CreateName
@onready var _create_state_button: Button = %CreateButton


func _init() -> void:
	super()
	theme_type_variation = &"StatePropertyEditor"


func _ready() -> void:
	super()
	
	_update_state_list()
	_setup_element_connection()
	
	before_property_connected.connect(_clear_element_connection)
	property_connected.connect(_setup_element_connection)
	
	_create_state_button.pressed.connect(_create_state)
	_create_state_name.text_submitted.connect(_create_state.unbind(1))


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	_create_container.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	_layout_separator.add_theme_stylebox_override("separator", get_theme_stylebox("separator"))


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.remove_theme_constant_override("separation")
	_create_container.remove_theme_constant_override("separation")
	_layout_separator.remove_theme_stylebox_override("separator")


# Element management.

func _clear_element_connection() -> void:
	if not element:
		return
	
	element.states_changed.disconnect(_update_state_list)


func _setup_element_connection() -> void:
	if not element:
		return
	
	_update_state_list()
	element.states_changed.connect(_update_state_list)


# State management.

func _create_state() -> void:
	if not element:
		return
	
	var state_name := _create_state_name.text.strip_edges()
	if state_name.is_empty():
		return
	
	var success := element.add_state(StateType.STATE_CUSTOM, state_name)
	if success:
		_create_state_name.clear()


# Implementation.

func _update_state_list() -> void:
	for state_entry: StatePropertyEntry in _states_container.get_children():
		_states_container.remove_child(state_entry)
		state_entry.queue_free()
	
	_layout_separator.visible = false
	_states_container.visible = false
	
	if not element:
		return
	
	if not element.states.is_empty():
		_layout_separator.visible = true
		_states_container.visible = true
	
	for state in element.states:
		var state_entry := STATE_ENTRY_SCENE.instantiate()
		state_entry.set_state_data(state)
		
		_states_container.add_child(state_entry)
