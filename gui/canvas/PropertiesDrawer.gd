###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertiesDrawer extends PanelContainer

var _edited_property: PropertyEditor = null

@onready var _element_title: Label = %ElementTitle
@onready var _element_properties: Control = %PropertiesList


func _ready() -> void:
	_update_element_title()
	_update_property_list()
	
	EndlessCanvas.get_instance().editing_mode_changed.connect(_update_property_list)
	EndlessCanvas.get_instance().selection_changed.connect(_update_property_list)
	EndlessCanvas.get_instance().selection_changed.connect(_update_element_title)


func _gui_input(event: InputEvent) -> void:
	# Property editors don't handle input directly (although they catch hover events
	# for convenience). Instead, the drawer propagates events back. This allows us to
	# check for currently active editors and give them priority, always.
	
	if _edited_property:
		_edited_property.handle_input(event)
		return
	
	for property_editor: PropertyEditor in _element_properties.get_children():
		if property_editor.is_visible_in_tree() && property_editor.is_hovering():
			property_editor.handle_input(event)
			break
	
	# Additionally, check if we click in between editors. These clicks should be captured,
	# to avoid accidentally closing the panel by slight misclicks.
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_LEFT && _element_properties.get_global_rect().has_point(mb.global_position):
			accept_event()


# Element data.

func _update_element_title() -> void:
	_clear_element_title()
	
	if not EndlessCanvas.get_instance():
		return
	
	var selected_element := EndlessCanvas.get_instance().get_selected_element()
	if not selected_element:
		return
	
	_element_title.text = selected_element.element_name


func _clear_element_title() -> void:
	_element_title.text = "Nothing Selected"


func _update_property_list() -> void:
	_clear_property_list()
	
	if not EndlessCanvas.get_instance():
		return
	
	var selected_element := EndlessCanvas.get_instance().get_selected_element()
	if not selected_element:
		return
	
	var editing_mode := EndlessCanvas.get_instance().get_editing_mode()
	var active_properties := selected_element.get_editable_properties(editing_mode)
	
	for property_editor in active_properties:
		_element_properties.add_child(property_editor)
		
		property_editor.editing_started.connect(_update_edited_property.bind(property_editor))
		property_editor.editing_stopped.connect(_update_edited_property.bind(null))


func _clear_property_list() -> void:
	_edited_property = null
	
	for property_editor: PropertyEditor in _element_properties.get_children():
		property_editor.editing_started.disconnect(_update_edited_property.bind(property_editor))
		property_editor.editing_stopped.disconnect(_update_edited_property.bind(null))
		
		_element_properties.remove_child(property_editor)
		property_editor.queue_free()


func _update_edited_property(property: PropertyEditor) -> void:
	_edited_property = property
