###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasDrawer extends PanelContainer

signal element_selected(element: BaseUIElement)

const ELEMENT_ENTRY_SCENE := preload("res://gui/canvas/elements/ElementEntry.tscn")

@onready var _canvas_title: Label = %CanvasTitle
@onready var _element_list: Control = %ElementsList


# Canvas data.

func clear_title() -> void:
	_canvas_title.text = "Canvas"


func set_title(value: String) -> void:
	_canvas_title.text = value


# Element management.

func _create_element_entry(element: BaseUIElement) -> void:
	var element_entry := ELEMENT_ENTRY_SCENE.instantiate()
	element_entry.data = element
	
	_element_list.add_child(element_entry)
	element_entry.entry_pressed.connect(_handle_entry_pressed.bind(element_entry))


func clear_elements() -> void:
	for element_entry: ElementEntry in _element_list.get_children():
		element_entry.entry_pressed.disconnect(_handle_entry_pressed.bind(element_entry))
		
		_element_list.remove_child(element_entry)
		element_entry.queue_free()


func set_elements(new_elements: Array[BaseUIElement]) -> void:
	for element in new_elements:
		_create_element_entry(element)


func add_element(new_element: BaseUIElement) -> void:
	_create_element_entry(new_element)


func _handle_entry_pressed(element_entry: ElementEntry) -> void:
	if not element_entry.data:
		return
	
	element_selected.emit(element_entry.data)
