###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertiesDrawer extends PanelContainer

var _edited_property: PropertyEditor = null

@onready var _element_title: Label = %ElementTitle
@onready var _element_properties: Control = %PropertiesList


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

func clear_title() -> void:
	_element_title.text = "Nothing Selected"


func set_title(value: String) -> void:
	_element_title.text = value


func _update_edited_property(property: PropertyEditor) -> void:
	_edited_property = property


func clear_properties() -> void:
	_edited_property = null
	
	for property_editor: PropertyEditor in _element_properties.get_children():
		property_editor.editing_started.disconnect(_update_edited_property.bind(property_editor))
		property_editor.editing_stopped.disconnect(_update_edited_property.bind(null))
		
		_element_properties.remove_child(property_editor)
		property_editor.queue_free()


func set_properties(new_properties: Array[PropertyEditor]) -> void:
	for property_editor in new_properties:
		_element_properties.add_child(property_editor)
		
		property_editor.editing_started.connect(_update_edited_property.bind(property_editor))
		property_editor.editing_stopped.connect(_update_edited_property.bind(null))
