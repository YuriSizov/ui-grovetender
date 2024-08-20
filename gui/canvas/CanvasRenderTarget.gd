###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

# The special render target to generate a mask from displayed elements, to be used in the shader.
# This is experimental for now, enabled by setting the local mask texture in the grid shader.
extends SubViewport

const PADDING_SIZE := 64.0

var _edited_canvas: UICanvas = null
var _tracked_elements: Array[UIElement] = []

@onready var _renderer: Control = %Renderer


func _ready() -> void:
	_renderer.draw.connect(_draw_renderer)
	
	_update_viewport_size()
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


func _process(_delta: float) -> void:
	_renderer.queue_redraw()


func _draw_renderer() -> void:
	# Clear color.
	_renderer.draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	if not _edited_canvas:
		return
	
	for element in _tracked_elements:
		var element_rect := element.get_element_rect()
		var local_rect := _edited_canvas.from_canvas_rect(element_rect)
		local_rect = local_rect.grow(PADDING_SIZE)
		
		_renderer.draw_rect(local_rect, Color.WHITE)


# Viewport management.

func _update_viewport_size() -> void:
	size = get_tree().root.size


# Canvas management.

func _edit_current_canvas() -> void:
	if Engine.is_editor_hint():
		return
	
	_tracked_elements.clear()
	
	if _edited_canvas:
		_edited_canvas.element_created.disconnect(_track_element)
		_edited_canvas.element_removed.disconnect(_untrack_element)
		_edited_canvas.element_reparented.disconnect(_reparent_tracked_element)
		_edited_canvas.element_sorted.disconnect(_renderer.queue_redraw)
		_edited_canvas.canvas_transformed.disconnect(_renderer.queue_redraw)
	
	_edited_canvas = Controller.get_current_canvas()
	
	if _edited_canvas:
		_edited_canvas.element_created.connect(_track_element)
		_edited_canvas.element_removed.connect(_untrack_element)
		_edited_canvas.element_reparented.connect(_reparent_tracked_element)
		_edited_canvas.element_sorted.connect(_renderer.queue_redraw)
		_edited_canvas.canvas_transformed.connect(_renderer.queue_redraw)
	
	_track_all_elements()


func _track_element(element: UIElement) -> void:
	element.data_changed.connect(_renderer.queue_redraw)
	element.transform_changed.connect(_renderer.queue_redraw)
	element.visibility_changed.connect(_renderer.queue_redraw)
	_tracked_elements.push_back(element)
	
	if element is UICompositeElement:
		for sub_element in element.element_group.elements:
			_track_element(sub_element)


func _track_all_elements() -> void:
	if not _edited_canvas:
		return
	
	for element in _edited_canvas.element_group.elements:
		_track_element(element)


func _untrack_element(element: UIElement) -> void:
	element.data_changed.disconnect(_renderer.queue_redraw)
	element.transform_changed.disconnect(_renderer.queue_redraw)
	element.visibility_changed.disconnect(_renderer.queue_redraw)
	_tracked_elements.erase(element)


func _reparent_tracked_element(_element: UIElement, _to_index: int) -> void:
	_renderer.queue_redraw()
