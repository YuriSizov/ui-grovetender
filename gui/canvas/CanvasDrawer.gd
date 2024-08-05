###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasDrawer extends PanelContainer

signal element_selected(element: BaseUIElement)

const ELEMENT_ENTRY_SCENE := preload("res://gui/canvas/entries/ElementEntry.tscn")

var _current_canvas: UICanvas = null
var _element_data_map: Dictionary = {}

@onready var _canvas_title: Label = %CanvasTitle
@onready var _element_list: Control = %ElementsList

var _dragging_element: ElementEntry = null


func _ready() -> void:
	_update_theme()
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


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
	
	_element_list.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	
	_canvas_title.begin_bulk_theme_override()
	_canvas_title.add_theme_font_override("font", get_theme_font("font"))
	_canvas_title.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_canvas_title.add_theme_color_override("font_color", get_theme_color("font_color"))
	_canvas_title.add_theme_color_override("font_outline_color", get_theme_color("font_outline_color"))
	_canvas_title.add_theme_color_override("font_shadow_color", get_theme_color("font_shadow_color"))
	_canvas_title.add_theme_constant_override("outline_size", get_theme_constant("font_outline_size"))
	_canvas_title.add_theme_constant_override("shadow_offset_x", get_theme_constant("font_shadow_offset_x"))
	_canvas_title.add_theme_constant_override("shadow_offset_y", get_theme_constant("font_shadow_offset_y"))
	_canvas_title.end_bulk_theme_override()


## Called when the theme overrides need to be reset, e.g. before the scene is saved.
func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_element_list.remove_theme_constant_override("separation")
	
	_canvas_title.begin_bulk_theme_override()
	_canvas_title.remove_theme_font_override("font")
	_canvas_title.remove_theme_font_size_override("font_size")
	_canvas_title.remove_theme_color_override("font_color")
	_canvas_title.remove_theme_color_override("font_outline_color")
	_canvas_title.remove_theme_color_override("font_shadow_color")
	_canvas_title.remove_theme_constant_override("outline_size")
	_canvas_title.remove_theme_constant_override("shadow_offset_x")
	_canvas_title.remove_theme_constant_override("shadow_offset_y")
	_canvas_title.end_bulk_theme_override()


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	_clear_title()
	_clear_element_entries()
	
	if _current_canvas:
		_current_canvas.element_created.disconnect(_create_element_entry)
		_current_canvas.elements_sorted.disconnect(_resort_element_entries)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_current_canvas.element_created.connect(_create_element_entry)
		_current_canvas.elements_sorted.connect(_resort_element_entries)
	
	_update_title()
	_set_element_entries()


func _clear_title() -> void:
	_canvas_title.text = "Canvas"


func _update_title() -> void:
	if not _current_canvas:
		_clear_title()
		return
	
	_canvas_title.text = _current_canvas.canvas_name


# Element management.

func _create_element_entry(element: BaseUIElement) -> void:
	var element_entry := ELEMENT_ENTRY_SCENE.instantiate()
	element_entry.data = element
	_element_data_map[element] = element_entry
	
	_element_list.add_child(element_entry)
	element_entry.entry_released.connect(_handle_entry_released.bind(element_entry))
	
	element_entry.set_drag_forwarding(
		_get_element_drag_data.bind(element_entry),
		_can_drop_element_data.bind(element_entry),
		_drop_element_data.bind(element_entry)
	)


func _set_element_entries() -> void:
	if not _current_canvas:
		return
	
	for element in _current_canvas.elements:
		_create_element_entry(element)


func _clear_element_entries() -> void:
	_element_data_map.clear()
	
	for element_entry: ElementEntry in _element_list.get_children():
		element_entry.entry_released.disconnect(_handle_entry_released.bind(element_entry))
		
		_element_list.remove_child(element_entry)
		element_entry.queue_free()


func _resort_element_entries() -> void:
	if not _current_canvas:
		return
	
	# TODO: Potentially optimize this to avoid doing excessive work when the state is already correct.
	
	for element_entry: ElementEntry in _element_list.get_children():
		_element_list.remove_child(element_entry)
	
	for element in _current_canvas.elements:
		if not _element_data_map.has(element):
			continue # This shouldn't happen.
		
		var element_entry: ElementEntry = _element_data_map[element]
		_element_list.add_child(element_entry)


# Interactions.

func _handle_entry_released(element_entry: ElementEntry) -> void:
	if not element_entry.data:
		return
	
	element_selected.emit(element_entry.data)


func _get_element_drag_data(at_position: Vector2, element_entry: ElementEntry) -> Variant:
	if not element_entry.is_sorting_drag(at_position):
		return null
	
	element_entry.set_dragging(true)
	_dragging_element = element_entry
	
	var preview_entry := ELEMENT_ENTRY_SCENE.instantiate()
	preview_entry.data = element_entry.data
	set_drag_preview(preview_entry)
	
	# When drag ends, clear the state.
	preview_entry.tree_exited.connect(func() -> void:
		element_entry.set_dragging(false)
		_dragging_element = null
	)
	
	var data := ElementSortingData.new()
	data.element = element_entry.data
	return data


func _can_drop_element_data(_at_position: Vector2, data: Variant, element_entry: ElementEntry) -> bool:
	if data is not ElementSortingData:
		return false
	
	var drop_index := element_entry.get_index()
	if drop_index != _dragging_element.get_index():
		_element_list.move_child(_dragging_element, drop_index)
	
	return true


func _drop_element_data(_at_position: Vector2, data: Variant, element_entry: ElementEntry) -> void:
	if not _current_canvas:
		return
	if data is not ElementSortingData:
		return
	
	var drop_index := element_entry.get_index()
	_current_canvas.sort_element(data.element, drop_index)


class ElementSortingData:
	var element: BaseUIElement = null
