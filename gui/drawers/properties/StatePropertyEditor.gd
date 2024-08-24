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


static func create(element: UIElement, element_data: BaseElementData) -> StatePropertyEditor:
	return _create(element, element_data, preload("res://gui/drawers/properties/StatePropertyEditor.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"StatePropertyEditor"


func _ready() -> void:
	super()
	
	_setup_element_connection()
	
	state_disconnected.connect(_clear_element_connection)
	state_connected.connect(_setup_element_connection)
	
	_create_state_button.pressed.connect(_create_element_state)
	_create_state_name.text_submitted.connect(_create_element_state.unbind(1))


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
	if not _element:
		return
	
	_element.states_changed.disconnect(_update_state_list)


func _setup_element_connection() -> void:
	if not _element:
		return
	
	_update_state_list()
	_element.states_changed.connect(_update_state_list)
	_element.editor_state_selected.connect(_update_selected_state)


func _update_state_list() -> void:
	for state_entry: StatePropertyEntry in _states_container.get_children():
		if state_entry.state_selected.is_connected(_select_element_state):
			state_entry.state_selected.disconnect(_select_element_state)
		_states_container.remove_child(state_entry)
		state_entry.queue_free()
	
	if not _element:
		return
	
	var default_entry := STATE_ENTRY_SCENE.instantiate()
	default_entry.set_state_data(_element.default_state)
	_states_container.add_child(default_entry)
	default_entry.state_selected.connect(_select_element_state)
	
	for state_data in _element.variant_states:
		var state_entry := STATE_ENTRY_SCENE.instantiate()
		state_entry.set_state_data(state_data)
		_states_container.add_child(state_entry)
		state_entry.state_selected.connect(_select_element_state)
	
	_update_selected_state()


func _update_selected_state() -> void:
	if not _element:
		return
	
	var selected_state := _element.get_selected_state_data()
	for state_entry: StatePropertyEntry in _states_container.get_children():
		var state_data := state_entry.get_state_data()
		state_entry.set_selected(state_data == selected_state)


# State management.

func _create_element_state() -> void:
	if not _element:
		return
	
	var state_name := _create_state_name.text.strip_edges()
	if state_name.is_empty():
		return
	
	# TODO: Handle errors with some user feedback.
	var state_data := _element.create_state(StateType.STATE_CUSTOM, state_name)
	if state_data:
		_element.set_selected_state(state_data)
		_create_state_name.clear()


func _select_element_state(state_data: BaseElementData) -> void:
	if not _element:
		return
	
	_element.set_selected_state(state_data)
