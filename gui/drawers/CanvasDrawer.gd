###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name CanvasDrawer extends PanelContainer

signal element_selected(element: UIElement, mode: CanvasView.SelectionMode)

const ELEMENT_ENTRY_SCENE := preload("res://gui/drawers/entries/ElementEntry.tscn")
const COMPOSITE_ENTRY_SCENE := preload("res://gui/drawers/entries/CompositeElementEntry.tscn")

var _edited_canvas: UICanvas = null
var _group_list_map: Dictionary = {}
var _element_entry_map: Dictionary = {}

@onready var _canvas_title: Label = %CanvasTitle
@onready var _canvas_elements: VBoxContainer = %CanvasElements


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
	
	_canvas_elements.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	
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
	
	_canvas_elements.remove_theme_constant_override("separation")
	
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
	_remove_all_entries()
	
	if _edited_canvas:
		_edited_canvas.element_created.disconnect(_handle_created_element)
		_edited_canvas.element_removed.disconnect(_handle_removed_element)
		_edited_canvas.element_sorted.disconnect(_handle_sorted_element)
		_edited_canvas.element_reparented.disconnect(_handle_reparented_element)
	
	_edited_canvas = Controller.get_current_canvas()
	
	if _edited_canvas:
		_edited_canvas.element_created.connect(_handle_created_element)
		_edited_canvas.element_removed.connect(_handle_removed_element)
		_edited_canvas.element_sorted.connect(_handle_sorted_element)
		_edited_canvas.element_reparented.connect(_handle_reparented_element)
	
	_update_title()
	_create_all_entries()


func _update_title() -> void:
	if not _edited_canvas:
		_clear_title()
		return
	
	_canvas_title.text = _edited_canvas.canvas_name


func _clear_title() -> void:
	_canvas_title.text = "Canvas"


func _handle_created_element(element: UIElement) -> void:
	var group_id := element.get_group_id()
	if not _group_list_map.has(group_id):
		printerr("CanvasDrawer: Trying to handle a newly created element (%s), but it has invalid group (%d)." % [ element, group_id ])
		return
	
	var group_container: VBoxContainer = _group_list_map[group_id]
	_create_element_entry(element, group_container)


func _handle_removed_element(element: UIElement) -> void:
	# Can't check the group here, because it's been erased already.
	_remove_element_entry(element)


func _handle_sorted_element(element: UIElement, to_index: int) -> void:
	var group_id := element.get_group_id()
	if not _group_list_map.has(group_id):
		printerr("CanvasDrawer: Trying to handle a reparented element (%s), but it has invalid group (%d)." % [ element, group_id ])
		return
	
	var group_container: VBoxContainer = _group_list_map[group_id]
	_sort_element_entry(element, group_container, to_index)


func _handle_reparented_element(element: UIElement, to_index: int) -> void:
	var group_id := element.get_group_id()
	if not _group_list_map.has(group_id):
		printerr("CanvasDrawer: Trying to handle a reparented element (%s), but it has invalid group (%d)." % [ element, group_id ])
		return
	
	var group_container: VBoxContainer = _group_list_map[group_id]
	_reparent_element_entry(element, group_container, to_index)


# Entry management.

func _create_element_entry(element: UIElement, group_container: VBoxContainer) -> void:
	var element_entry: ElementEntry = null
	var reference_node: Control = null # The one we consider when dragging entries around.
	
	if element is UICompositeElement:
		var composite_entry: CompositeElementEntry = COMPOSITE_ENTRY_SCENE.instantiate()
		group_container.add_child(composite_entry)
		reference_node = composite_entry
		
		_create_group_entries(element.element_group, composite_entry.get_element_sublist())
		
		element_entry = composite_entry.get_element_entry()
	else:
		element_entry = ELEMENT_ENTRY_SCENE.instantiate()
		group_container.add_child(element_entry)
		reference_node = element_entry
	
	element_entry.element = element
	_element_entry_map[element] = reference_node
	
	element_entry.set_drag_forwarding(
		_get_element_drag_data.bind(element_entry, reference_node),
		_can_drop_element_data.bind(element_entry.element, reference_node),
		_drop_element_data.bind(reference_node)
	)
	element_entry.entry_released.connect(_handle_entry_released.bind(element_entry))


func _create_group_entries(element_group: UIElementGroup, group_container: VBoxContainer) -> void:
	var group_id := element_group.get_instance_id()
	_group_list_map[group_id] = group_container
	
	for element in element_group.elements:
		_create_element_entry(element, group_container)


func _create_all_entries() -> void:
	if not _edited_canvas:
		return
	
	_create_group_entries(_edited_canvas.element_group, _canvas_elements)


func _remove_element_entry(element: UIElement) -> void:
	if not _element_entry_map.has(element):
		printerr("CanvasDrawer: Trying to remove an element (%s) entry, but it doesn't exist." % [ element ])
		return
	
	var element_entry: Control = _element_entry_map[element]
	_element_entry_map.erase(element)
	
	element_entry.get_parent().remove_child(element_entry)
	element_entry.queue_free()


func _remove_group_entries(element_group: UIElementGroup) -> void:
	var group_id := element_group.get_instance_id()
	if not _group_list_map.has(group_id):
		printerr("CanvasDrawer: Trying to remove a group of elements (%s), but it doesn't exist." % [ element_group ])
		return
	
	for element in element_group.elements:
		_remove_element_entry(element)


func _remove_all_entries() -> void:
	if not _edited_canvas:
		return
	
	_remove_group_entries(_edited_canvas.element_group)
	
	_group_list_map.clear()
	_element_entry_map.clear()


func _sort_element_entry(element: UIElement, group_container: VBoxContainer, to_index: int) -> void:
	if not _element_entry_map.has(element):
		printerr("CanvasDrawer: Trying to sort an element (%s) entry, but it doesn't exist." % [ element ])
		return
	
	var element_entry: Control = _element_entry_map[element]
	group_container.move_child(element_entry, to_index)


func _reparent_element_entry(element: UIElement, group_container: VBoxContainer, to_index: int) -> void:
	if not _element_entry_map.has(element):
		printerr("CanvasDrawer: Trying to reparent an element (%s) entry, but it doesn't exist." % [ element ])
		return
	
	var element_entry: Control = _element_entry_map[element]
	element_entry.get_parent().remove_child(element_entry)
	group_container.add_child(element_entry)
	group_container.move_child(element_entry, to_index)


# Interactions.

func _handle_entry_released(element_entry: ElementEntry) -> void:
	if not element_entry.element:
		return
	
	var selection_mode := CanvasView.SelectionMode.REPLACE_SELECTION
	if Input.is_key_pressed(KEY_SHIFT) && not Input.is_key_pressed(KEY_ALT):
		selection_mode = CanvasView.SelectionMode.ADD_TO_SELECTION
	elif Input.is_key_pressed(KEY_ALT) && not Input.is_key_pressed(KEY_SHIFT):
		selection_mode = CanvasView.SelectionMode.REMOVE_FROM_SELECTION
	
	element_selected.emit(element_entry.element, selection_mode)


func _get_element_drag_data(at_position: Vector2, source_entry: ElementEntry, source_node: Control) -> Variant:
	if not source_entry.is_sorting_drag(at_position):
		return null
	
	var preview_entry := ELEMENT_ENTRY_SCENE.instantiate()
	preview_entry.element = source_entry.element
	set_drag_preview(preview_entry)
	
	# Set the dragging state now; when the preview is removed, clear the state.
	source_entry.set_dragging(true)
	# Remember the original position, it can change without triggering the drop handler.
	var original_index := source_node.get_index()
	
	preview_entry.tree_exited.connect(func() -> void:
		source_entry.set_dragging(false)
		
		if source_node.get_index() != original_index:
			_edited_canvas.sort_element(source_entry.element, source_node.get_index())
	)
	
	var data := ElementSortingData.new()
	data.element_node = source_node
	data.element_data = source_entry.element
	return data


func _can_drop_element_data(_at_position: Vector2, data: Variant, target_data: UIElement, target_node: Control) -> bool:
	if data is not ElementSortingData:
		return false
	
	var sorting_data := data as ElementSortingData
	
	var source_group_id := sorting_data.element_data.get_group_id()
	var target_group_id := target_data.get_group_id()
	if source_group_id != target_group_id:
		return false
	
	var source_index := sorting_data.element_node.get_index()
	var target_index := target_node.get_index()
	if source_index != target_index:
		if not _group_list_map.has(source_group_id):
			return false
		
		var group_container: VBoxContainer = _group_list_map[source_group_id]
		group_container.move_child(sorting_data.element_node, target_index)
	
	return true


func _drop_element_data(_at_position: Vector2, data: Variant, target_node: Control) -> void:
	if not _edited_canvas:
		return
	if data is not ElementSortingData:
		return
	
	var sorting_data := data as ElementSortingData
	var target_index := target_node.get_index()
	
	_edited_canvas.sort_element(sorting_data.element_data, target_index)


class ElementSortingData:
	var element_node: Control = null
	var element_data: UIElement = null
