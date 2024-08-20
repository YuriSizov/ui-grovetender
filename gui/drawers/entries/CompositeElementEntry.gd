###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CompositeElementEntry extends VBoxContainer

@onready var _element_entry: ElementEntry = %ElementEntry
@onready var _element_sublist: VBoxContainer = %ElementList


func _ready() -> void:
	_update_theme()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()
	
	# This is so hacky, but it allows us to use one theme definition for all elements of a complex
	# scene, with in-editor preview, without polluting saved scenes.
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_theme()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_update_theme()
	
	# This happens before the node is ready, but for instantiated scenes these references are already
	# valid.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_element_entry = %ElementEntry
		_element_sublist = %ElementList


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_element_sublist.add_theme_constant_override("separation", get_theme_constant("base_separation"))


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_element_sublist.remove_theme_constant_override("separation")


# Helpers.

func get_element_entry() -> ElementEntry:
	return _element_entry


func get_element_sublist() -> VBoxContainer:
	return _element_sublist
