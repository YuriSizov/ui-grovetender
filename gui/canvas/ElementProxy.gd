###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ElementProxy extends Control

# TODO: Make this adjustible, probably. Possibly together with the "combined size" too.
const STATE_RENDERER_PADDING := 32.0

@export var element: UIElement = null:
	set = set_element

var _renderer_data_map: Dictionary = {}

@onready var _main_renderer: Control = %MainRenderer
@onready var _transition_renderer: Control = %TransitionRenderer
@onready var _state_renderers: Control = %States
@onready var _children_root: Control = %Children


func _enter_tree() -> void:
	_update_anchor_position()
	_create_renderers()


func _ready() -> void:
	_main_renderer.draw.connect(_renderer_draw.bind(_main_renderer))
	_transition_renderer.draw.connect(_renderer_draw.bind(_transition_renderer))


func _notification(what: int) -> void:
	# Since we're working with a packed scene here, child nodes are available
	# way ahead of ready and can be used pretty much immediately. This fixes the
	# references.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_main_renderer = %MainRenderer
		_transition_renderer = %TransitionRenderer
		_state_renderers = %States


# HACK: This is temporary to test the system, ideally the transition-aware view should be separate from the canvas.
func _process(_delta: float) -> void:
	if _transition_renderer:
		_transition_renderer.queue_redraw()


func _renderer_draw(renderer: Control) -> void:
	if renderer not in _renderer_data_map:
		return
	
	var element_data: BaseElementData = _renderer_data_map[renderer]
	element_data.draw(renderer)


# Element management.

func set_element(value: UIElement) -> void:
	if element == value:
		return
	
	if element:
		element.states_changed.disconnect(_create_renderers)
		element.data_changed.disconnect(_redraw_renderers)
		element.transform_changed.disconnect(_update_element_transform)
		element.visibility_changed.disconnect(_update_visibility)
	
	element = value
	
	if element:
		element.states_changed.connect(_create_renderers)
		element.data_changed.connect(_redraw_renderers)
		element.transform_changed.connect(_update_element_transform)
		element.visibility_changed.connect(_update_visibility)
	
	_update_anchor_position()
	_create_renderers()


func _update_anchor_position() -> void:
	if not element || not is_inside_tree():
		return
	
	var group_owner := element.get_group().get_owner()
	if group_owner is UICompositeElement:
		position = element.get_anchor_point() - group_owner.get_anchor_point()
	else:
		position = element.get_anchor_point()


func _update_element_transform() -> void:
	print("updating proxy transform")
	
	_update_anchor_position()
	_update_renderers()


func _update_visibility() -> void:
	if not element:
		visible = false
		return
	
	visible = element.is_visible()


func get_children_root() -> Control:
	return _children_root


# Renderer management.

func _create_renderers() -> void:
	if not element:
		_remove_renderers()
		return
	
	# Make sure the main renderer is always present in the map. We don't
	# need to create a node for it.
	if _main_renderer not in _renderer_data_map:
		_renderer_data_map[_main_renderer] = element.get_default_state_data()
	if _transition_renderer not in _renderer_data_map:
		_renderer_data_map[_transition_renderer] = element.get_active_data()
	
	# Update renderer nodes for variant states.
	
	var renderers_to_remove: Array[Control] = []
	var states_to_add := element.get_combined_state_data()
	
	# Check existing renderers and track the ones which are no longer needed.
	# Also ignore the ones which are present and don't need to be added.
	for renderer: Control in _renderer_data_map:
		if renderer == _main_renderer || renderer == _transition_renderer:
			continue
		
		var element_data: BaseElementData = _renderer_data_map[renderer]
		if element_data not in states_to_add:
			renderers_to_remove.push_back(renderer)
		else:
			states_to_add.erase(element_data)
	
	# Removes the ones to be removed.
	for renderer in renderers_to_remove:
		renderer.draw.disconnect(_renderer_draw.bind(renderer))
		renderer.get_parent().remove_child(renderer)
		renderer.queue_free()
	
	# Add the ones to be added.
	for element_data in states_to_add:
		var renderer := Control.new()
		renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_state_renderers.add_child(renderer)
		renderer.draw.connect(_renderer_draw.bind(renderer))
		
		_renderer_data_map[renderer] = element_data
	
	_update_renderers()
	_redraw_renderers()


func _remove_renderers() -> void:
	for renderer: Control in _renderer_data_map:
		if renderer == _main_renderer || renderer == _transition_renderer:
			continue
		
		renderer.draw.disconnect(_renderer_draw.bind(renderer))
		renderer.get_parent().remove_child(renderer)
		renderer.queue_free()
	
	_renderer_data_map.clear()


func _redraw_renderers() -> void:
	if not element || not is_inside_tree():
		return
	
	for renderer: Control in _renderer_data_map:
		renderer.queue_redraw()


func _update_renderers() -> void:
	if not element || not is_inside_tree():
		return
	
	var variant_states := element.get_combined_state_data()
	var combined_size := element.get_state_preview_spacing()
	
	for renderer: Control in _renderer_data_map:
		var element_data: BaseElementData = _renderer_data_map[renderer]
		renderer.position = element_data.offset
		renderer.size = element_data.size
		
		# For the main renderer, nothing else needs updating changes.
		if renderer == _main_renderer:
			continue
		
		# For the transition renderer, small adjustment is made.
		if renderer == _transition_renderer:
			renderer.position.y += combined_size.y + STATE_RENDERER_PADDING
			continue
		
		# Renderers and states are out of sync, this shouldn't happen.
		var data_index := variant_states.find(element_data)
		if data_index < 0:
			continue
		
		renderer.position.x += combined_size.x + STATE_RENDERER_PADDING
		renderer.position.y += (combined_size.y + STATE_RENDERER_PADDING) * data_index


# Helpers.

func is_visible_on_screen() -> bool:
	# FIXME: Can be optimized with caching.
	
	if not visible || not is_inside_tree() || not is_visible_in_tree():
		return false
	
	var global_rect := get_global_rect()
	if global_rect.end.x < 0 || global_rect.end.y < 0:
		return false
	
	var window_size := get_window().size
	if global_rect.position.x > window_size.x || global_rect.position.y > window_size.y:
		return false
	
	return true
