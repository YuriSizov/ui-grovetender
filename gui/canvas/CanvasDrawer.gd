###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasDrawer extends PanelContainer

signal element_selected(element: BaseUIElement)

const ELEMENT_ENTRY_SCENE := preload("res://gui/canvas/entries/ElementEntry.tscn")
const COMPOSITE_ENTRY_SCENE := preload("res://gui/canvas/entries/CompositeElementEntry.tscn")

var _current_canvas: UICanvas = null
var _element_data_map: Dictionary = {}
var _composite_data_map: Dictionary = {}

@onready var _canvas_title: Label = %CanvasTitle
@onready var _element_list: VBoxContainer = %ElementsList


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
		_current_canvas.element_removed.disconnect(_remove_element_entry)
		_current_canvas.elements_sorted.disconnect(_resort_element_entries)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_current_canvas.element_created.connect(_create_element_entry)
		_current_canvas.element_removed.connect(_remove_element_entry)
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

func _get_element_list(owner_element: BaseUIElement) -> VBoxContainer:
	if not owner_element:
		return _element_list
	
	if _composite_data_map.has(owner_element):
		var composite_entry: CompositeElementEntry = _composite_data_map[owner_element]
		return composite_entry.get_element_sublist()
	
	return null


func _get_owner_element_list(element: BaseUIElement) -> VBoxContainer:
	if not element.has_owner():
		return _element_list
	
	var owner_element := element.get_owner()
	if _composite_data_map.has(owner_element):
		var composite_entry: CompositeElementEntry = _composite_data_map[owner_element]
		return composite_entry.get_element_sublist()
	
	return null


func _create_element_entry(element: BaseUIElement) -> void:
	var owner_list := _get_owner_element_list(element)
	if not owner_list:
		printerr("CanvasDrawer: Attempting to create an entry but the owner context is invalid.")
		return
	
	# Instantiate the appropriate scene based on the element type.
	
	var element_entry: ElementEntry = null
	var composite_entry: CompositeElementEntry = null
	
	if element is CompositeElement:
		composite_entry = COMPOSITE_ENTRY_SCENE.instantiate()
		_composite_data_map[element] = composite_entry
		element_entry = composite_entry.get_element_entry()
	
	else:
		element_entry = ELEMENT_ENTRY_SCENE.instantiate()
	
	# Set up the element entry.
	
	element_entry.data = element
	_element_data_map[element] = element_entry
	
	var drag_ref_node: Control = composite_entry
	if not composite_entry:
		drag_ref_node = element_entry
	
	element_entry.set_drag_forwarding(
		_get_element_drag_data.bind(element_entry, drag_ref_node),
		_can_drop_element_data.bind(element_entry.data, drag_ref_node),
		_drop_element_data.bind(drag_ref_node)
	)
	element_entry.entry_released.connect(_handle_entry_released.bind(element_entry))
	
	# Add the entry to the owner element list, and then create sub-entries if necessary.
	
	if element is CompositeElement:
		owner_list.add_child(composite_entry)
		
		for sub_element in element.elements:
			_create_element_entry(sub_element)
	
	else:
		owner_list.add_child(element_entry)


func _remove_element_entry(element: BaseUIElement) -> void:
	if not _element_data_map.has(element):
		return
	
	var element_entry: ElementEntry = _element_data_map[element]
	_free_element_entry(element_entry)
	
	_element_data_map.erase(element)
	if _composite_data_map.has(element):
		_composite_data_map.erase(element)


func _free_element_entry(element_entry: ElementEntry) -> void:
	element_entry.entry_released.disconnect(_handle_entry_released.bind(element_entry))
	
	if element_entry.data is CompositeElement:
		var composite_entry: CompositeElementEntry = _composite_data_map[element_entry.data]
		composite_entry.get_parent().remove_child(composite_entry)
		composite_entry.queue_free()
	
	else:
		element_entry.get_parent().remove_child(element_entry)
		element_entry.queue_free()


func _set_element_entries() -> void:
	if not _current_canvas:
		return
	
	for element in _current_canvas.elements:
		_create_element_entry(element)


func _clear_element_entries() -> void:
	for element_entry: ElementEntry in _element_data_map.values():
		_free_element_entry(element_entry)
	
	_element_data_map.clear()
	_composite_data_map.clear()


func _resort_element_entries(owner_element: CompositeElement) -> void:
	if not _current_canvas:
		return
	
	var owner_elements := owner_element.elements if owner_element else _current_canvas.elements
	var owner_list := _get_element_list(owner_element)
	if not owner_list:
		return
	
	# First remove all elements from the owner list, keeping track of the nodes.
	# We creat an ad-hoc list because nodes can have varying types.
	# TODO: Potentially optimize this to avoid doing excessive work when the state is already correct.
	
	var unsorted_list: Dictionary = {}
	
	for child_node: Control in owner_list.get_children():
		if child_node is CompositeElementEntry:
			unsorted_list[child_node.get_element_entry().data] = child_node
		elif child_node is ElementEntry:
			unsorted_list[child_node.data] = child_node
		
		owner_list.remove_child(child_node)
	
	# Then reinsert the nodes based on the order in the owner element or canvas list.
	
	for element in owner_elements:
		if not unsorted_list.has(element):
			continue # This shouldn't happen.
		
		var element_entry: Control = unsorted_list[element]
		owner_list.add_child(element_entry)


# Interactions.

func _handle_entry_released(element_entry: ElementEntry) -> void:
	if not element_entry.data:
		return
	
	element_selected.emit(element_entry.data)


func _get_element_drag_data(at_position: Vector2, source_entry: ElementEntry, source_node: Control) -> Variant:
	if not source_entry.is_sorting_drag(at_position):
		return null
	
	var preview_entry := ELEMENT_ENTRY_SCENE.instantiate()
	preview_entry.data = source_entry.data
	set_drag_preview(preview_entry)
	
	# Set the dragging state now; when the preview is removed, clear the state.
	source_entry.set_dragging(true)
	# Remember the original position, it can change without triggering the drop handler.
	var original_index := source_node.get_index()
	
	preview_entry.tree_exited.connect(func() -> void:
		source_entry.set_dragging(false)
		
		if source_node.get_index() != original_index:
			_current_canvas.sort_element(source_entry.data, source_node.get_index())
	)
	
	var data := ElementSortingData.new()
	data.element_node = source_node
	data.element_data = source_entry.data
	return data


func _can_drop_element_data(_at_position: Vector2, data: Variant, target_data: BaseUIElement, target_node: Control) -> bool:
	if data is not ElementSortingData:
		return false
	
	var sorting_data := data as ElementSortingData
	
	var source_owner_id := sorting_data.element_data.get_owner_id()
	var target_owner_id := target_data.get_owner_id()
	if source_owner_id != target_owner_id:
		return false
	
	var source_index := sorting_data.element_node.get_index()
	var target_index := target_node.get_index()
	if source_index != target_index:
		var owner_list := _get_owner_element_list(sorting_data.element_data)
		if not owner_list:
			return false
		
		owner_list.move_child(sorting_data.element_node, target_index)
	
	return true


func _drop_element_data(_at_position: Vector2, data: Variant, target_node: Control) -> void:
	if not _current_canvas:
		return
	if data is not ElementSortingData:
		return
	
	var sorting_data := data as ElementSortingData
	var target_index := target_node.get_index()
	
	_current_canvas.sort_element(sorting_data.element_data, target_index)


class ElementSortingData:
	var element_node: Control = null
	var element_data: BaseUIElement = null
