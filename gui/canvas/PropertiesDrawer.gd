###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name PropertiesDrawer extends PanelContainer

var _selected_element: BaseUIElement = null
var _active_editors: Array[PropertyEditor] = []
var _section_containers: Array[VBoxContainer] = []

@onready var _element_title: Label = %ElementTitle
@onready var _element_properties: Control = %PropertiesList


func _ready() -> void:
	_update_theme()
	
	resized.connect(queue_redraw)
	sort_children.connect(queue_redraw)
	
	_edit_selected_element()
	
	if not Engine.is_editor_hint():
		EndlessCanvas.get_instance().selection_changed.connect(_edit_selected_element)
		EndlessCanvas.get_instance().editing_mode_changed.connect(_update_property_list)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()
	
	# This is so hacky, but it allows us to use one theme definition for all elements of a complex
	# scene, with in-editor preview, without polluting saved scenes.
	elif what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_theme()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_update_theme()


## Called when it's a proper time to update visuals according to theme changes.
func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_element_properties.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	
	for section_container in _section_containers:
		section_container.add_theme_constant_override("separation", get_theme_constant("section_separation"))
	
	_element_title.begin_bulk_theme_override()
	_element_title.add_theme_font_override("font", get_theme_font("font"))
	_element_title.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_element_title.add_theme_color_override("font_color", get_theme_color("font_color"))
	_element_title.add_theme_color_override("font_outline_color", get_theme_color("font_outline_color"))
	_element_title.add_theme_color_override("font_shadow_color", get_theme_color("font_shadow_color"))
	_element_title.add_theme_constant_override("outline_size", get_theme_constant("font_outline_size"))
	_element_title.add_theme_constant_override("shadow_offset_x", get_theme_constant("font_shadow_offset_x"))
	_element_title.add_theme_constant_override("shadow_offset_y", get_theme_constant("font_shadow_offset_y"))
	_element_title.end_bulk_theme_override()


## Called when the theme overrides need to be reset, e.g. before the scene is saved.
func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_element_properties.remove_theme_constant_override("separation")
	
	for section_container in _section_containers:
		section_container.remove_theme_constant_override("separation")
	
	_element_title.begin_bulk_theme_override()
	_element_title.remove_theme_font_override("font")
	_element_title.remove_theme_font_size_override("font_size")
	_element_title.remove_theme_color_override("font_color")
	_element_title.remove_theme_color_override("font_outline_color")
	_element_title.remove_theme_color_override("font_shadow_color")
	_element_title.remove_theme_constant_override("outline_size")
	_element_title.remove_theme_constant_override("shadow_offset_x")
	_element_title.remove_theme_constant_override("shadow_offset_y")
	_element_title.end_bulk_theme_override()


func _draw() -> void:
	var section_panel := get_theme_stylebox("section_panel")
	var section_panel_collapsed := get_theme_stylebox("section_panel_collapsed")
	
	# Draw extra backgrounds behind sections.
	for section_container in _section_containers:
		var section_index := section_container.get_index() - 1
		var section_editor: SectionPropertyEditor = _element_properties.get_child(section_index)
		var section_style := section_panel if section_editor.is_toggled() else section_panel_collapsed
		
		var container_rect := section_container.get_global_rect()
		if section_container.visible:
			container_rect = container_rect.expand(section_editor.global_position)
		else:
			container_rect = section_editor.get_global_rect()
		
		container_rect.position -= global_position
		draw_style_box(section_style, container_rect)


# Element data.

func _edit_selected_element() -> void:
	if Engine.is_editor_hint():
		return
	if not EndlessCanvas.get_instance():
		return
	
	var next_element := EndlessCanvas.get_instance().get_selected_element()
	if _selected_element == next_element:
		return
	
	_selected_element = next_element
	
	_update_element_title()
	_update_property_list()


func _update_element_title() -> void:
	_clear_element_title()
	
	if not _selected_element:
		return
	
	_element_title.text = _selected_element.element_name


func _clear_element_title() -> void:
	_element_title.text = "Nothing Selected"


func _update_property_list() -> void:
	_clear_property_list()
	
	if not _selected_element:
		return
	
	var editing_mode := EndlessCanvas.get_instance().get_editing_mode()
	var active_properties := _selected_element.get_editable_properties(editing_mode)
	
	var current_section_container: VBoxContainer = null
	
	for i in active_properties.size():
		var property_editor := active_properties[i]
		
		if property_editor is SectionPropertyEditor:
			if current_section_container:
				_section_containers.push_back(current_section_container)
			
			_element_properties.add_child(property_editor)
			
			current_section_container = VBoxContainer.new()
			current_section_container.name = "SectionEditors"
			current_section_container.visible = property_editor.is_toggled()
			current_section_container.add_theme_constant_override("separation", get_theme_constant("section_separation"))
			_element_properties.add_child(current_section_container)
			
			property_editor.section_toggled.connect(_update_section_visibility.bind(property_editor, current_section_container))
		
		else:
			current_section_container.add_child(property_editor)
		
		_active_editors.push_back(property_editor)
	
	if current_section_container:
		_section_containers.push_back(current_section_container)
	
	queue_redraw()


func _clear_property_list() -> void:	
	# First remove all property editors.
	for property_editor in _active_editors:
		property_editor.get_parent().remove_child(property_editor)
		property_editor.queue_free()
	
	_active_editors.clear()
	_section_containers.clear()
	
	# Then remove all extra controls.
	for child_node: Node in _element_properties.get_children():
		_element_properties.remove_child(child_node)
		child_node.queue_free()
	
	queue_redraw()


func _update_section_visibility(section_editor: SectionPropertyEditor, section_container: VBoxContainer) -> void:
	section_container.visible = section_editor.is_toggled()
	queue_redraw()
