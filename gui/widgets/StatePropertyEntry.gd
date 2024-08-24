###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name StatePropertyEntry extends HBoxContainer

var _state_data: BaseElementData = null

@onready var _state_name_label: Label = %StateName
@onready var _rename_state_button: Button = %RenameHandle
@onready var _delete_state_button: Button = %DeleteHandle
@onready var _locked_state_icon: TextureRect = %LockedHandle


func _ready() -> void:
	_update_name_label()
	_update_locked_state()


# Properties.

func get_state_data() -> BaseElementData:
	return _state_data


func set_state_data(data: BaseElementData) -> void:
	_state_data = data
	
	_update_name_label()
	_update_locked_state()


func _update_name_label() -> void:
	if not is_inside_tree():
		return
	
	if _state_data:
		_state_name_label.text = _state_data.state.state_name
	else:
		_state_name_label.text = "Empty"


func _update_locked_state() -> void:
	if not is_inside_tree():
		return
	
	if not _state_data:
		_rename_state_button.visible = false
		_delete_state_button.visible = false
		_locked_state_icon.visible = false
		return
	
	if _state_data.state.locked || _state_data.state.state_type == StateType.STATE_DEFAULT:
		_rename_state_button.visible = false
		_delete_state_button.visible = false
		_locked_state_icon.visible = true
	else:
		_rename_state_button.visible = true
		_delete_state_button.visible = true
		_locked_state_icon.visible = false
	
	if _state_data.state.state_type == StateType.STATE_DEFAULT:
		_locked_state_icon.tooltip_text = "The default state cannot be renamed or removed."
	else:
		_locked_state_icon.tooltip_text = "This state cannot be renamed or removed because it's required by the preset."
