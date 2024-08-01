###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertiesDrawer extends PanelContainer

var _property_section_ranges: Array[Vector2i] = []

@onready var _element_title: Label = %ElementTitle
@onready var _element_properties: Control = %PropertiesList


func _ready() -> void:
	_update_element_title()
	_update_property_list()
	
	EndlessCanvas.get_instance().editing_mode_changed.connect(_update_property_list)
	EndlessCanvas.get_instance().selection_changed.connect(_update_property_list)
	EndlessCanvas.get_instance().selection_changed.connect(_update_element_title)


func _draw() -> void:
	var section_panel := get_theme_stylebox("section_panel")
	
	# Draw extra backgrounds behind opened sections.
	for property_range in _property_section_ranges:
		var from_index := property_range.x
		var to_index := property_range.y
		
		var section_editor: SectionPropertyEditor = _element_properties.get_child(from_index)
		if not section_editor.is_toggled():
			continue
		
		while to_index > from_index:
			var last_visible: Control = _element_properties.get_child(to_index)
			if last_visible.visible:
				break
			
			to_index -= 1
		
		var last_property: Control = _element_properties.get_child(to_index)
		
		var range_rect := Rect2()
		range_rect.position = section_editor.global_position
		range_rect = range_rect.expand(last_property.global_position + last_property.size)
		
		range_rect.position -= global_position
		draw_style_box(section_panel, range_rect)


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
	
	var current_range := Vector2i.ZERO
	for i in active_properties.size():
		var property_editor := active_properties[i]
		
		if property_editor is SectionPropertyEditor:
			if current_range.x != current_range.y:
				_property_section_ranges.push_back(current_range)
			
			current_range = Vector2i(i, i)
		else:
			current_range.y = i
		
		_element_properties.add_child(property_editor)
		property_editor.visibility_changed.connect(queue_redraw)
	
	if current_range.x != current_range.y:
		_property_section_ranges.push_back(current_range)
	
	queue_redraw()


func _clear_property_list() -> void:
	_property_section_ranges.clear()
	
	for property_editor: PropertyEditor in _element_properties.get_children():
		property_editor.visibility_changed.disconnect(queue_redraw)
		
		_element_properties.remove_child(property_editor)
		property_editor.queue_free()
	
	queue_redraw()
