###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The canvas object defines an infinite page in the project, which can
## contain multiple elements and widgets. Users can export canvas as a
## whole, or in parts, as it exists mainly for the convenience of having
## multiple entities in the same visual space, but doesn't limit anything
## otherwise.
class_name UICanvas extends Resource

signal element_created(element: UIElement)
signal element_removed(element: UIElement)
signal element_sorted(element: UIElement, to_index: int)
signal element_reparented(element: UIElement, to_index: int)

signal canvas_transformed()

## The display name of this canvas.
@export var canvas_name: String = "Canvas"
## The collection of topmost elements in this canvas.
@export var element_group: UIElementGroup = null

# Runtime properties.

const SCALE_STEP := 1.2
const MIN_SCALE := 1.0 / pow(SCALE_STEP, 8.0)
const MAX_SCALE := 1.0 * pow(SCALE_STEP, 4.0)

## The runtime offset of the canvas view, i.e. the camera position.
var _canvas_offset: Vector2 = Vector2.ZERO
## The runtime scale of the canvas view, i.e. the camera zoom.
var _canvas_scale: float = 1.0

## The safeguard flag that keeps track of queued transforms for canvas
## elements.
var _element_transform_queued: bool = false
## The set of elements with their transforms queued. We don't need to
## update the entire canvas, since top level elements are independent
## from each other.
var _element_transform_set: Dictionary = {} # Kind of like a hashset, since keys are unique.


func _init() -> void:
	element_group = UIElementGroup.new(self)
	element_group.element_added.connect(_track_grouped_element)
	element_group.element_erased.connect(_untrack_grouped_element)


# Element management.

func create_element(owner_element: UICompositeElement, data_type: GDScript, at_position: Vector2) -> void:
	var element := UIElement.new(data_type)
	element.set_anchor_point(at_position)
	
	var owner_group := owner_element.element_group if owner_element else element_group
	owner_group.add(element)
	element_created.emit(element)


func remove_element(element: UIElement) -> void:
	# TODO: Dissolve empty composite elements.
	
	if element is UICompositeElement:
		for sub_element in element.element_group.elements:
			remove_element(sub_element)
	
	var owner_group := element.get_group()
	if owner_group.erase(element):
		element_removed.emit(element)


func sort_element(element: UIElement, to_index: int) -> void:
	var owner_group := element.get_group()
	if owner_group.move(element, to_index):
		element_sorted.emit(element, to_index)


func _find_common_owner_group(elements: Array[UIElement]) -> UIElementGroup:
	# Find the closest common owner for every element. This is a very naive approach.
	
	# First, collect all owner chains for each element.
	var owner_chains := [] # Array of Array[UIElementGroup]
	var longest_chain: Array[UIElementGroup] = []
	for element in elements:
		var chain: Array[UIElementGroup] = []
		
		var group := element.get_group()
		while group:
			chain.push_front(group)
			group = group.get_owner_group()
		
		owner_chains.push_back(chain)
		if chain.size() > longest_chain.size():
			longest_chain = chain
	
	# Then, move through the chains until a discrepancy is found. The last matching group
	# is our owner.
	var owner_group := element_group # The group from this canvas is always the first for every chain.
	for i in longest_chain.size():
		var match_against := longest_chain[i]
		var match_found := false
		
		for chain in owner_chains:
			if i >= chain.size():
				match_found = true
				break
			
			var chain_item: UIElementGroup = chain[i]
			if chain_item != match_against:
				match_found = true
				break
		
		if match_found:
			break
		
		owner_group = longest_chain[i]
	
	return owner_group


func group_elements(elements: Array[UIElement]) -> void:
	var owner_group := _find_common_owner_group(elements)
	
	# FIXME: Respect global order of elements when grouping.
	
	# Remove each element from its current group.
	# TODO: Dissolve empty composite elements.
	for element in elements:
		var group := element.get_group()
		group.erase(element)
	
	var composite := UICompositeElement.new(BaseElementData)
	
	# TODO: Insert at the position of the highest (lowest index) affected element in the common owner.
	owner_group.add(composite)
	element_created.emit(composite)
	
	for i in elements.size():
		var element := elements[i]
		composite.element_group.add(element)
		element_reparented.emit(element, i)


func _track_grouped_element(element: UIElement) -> void:
	if element.is_transform_queued():
		_queue_element_transform(element)
	
	element.transform_queued.connect(_queue_element_transform.bind(element))


func _untrack_grouped_element(element: UIElement) -> void:
	element.transform_queued.disconnect(_queue_element_transform.bind(element))


func _queue_element_transform(element: UIElement) -> void:
	# Only the key is relevant, we use it as a hashset.
	_element_transform_set[element] = true
	
	if _element_transform_queued:
		return
	
	_element_transform_queued = true
	_notify_element_transform.call_deferred()


func _notify_element_transform() -> void:
	if not _element_transform_queued:
		return
	
	for element in _element_transform_set:
		element.notify_transform_changed()
	_element_transform_set.clear()
	_element_transform_queued = false


# Transform management.

func get_canvas_scale() -> float:
	return _canvas_scale


func get_canvas_scale_vector() -> Vector2:
	return Vector2(_canvas_scale, _canvas_scale)


func set_canvas_scale(value: float, towards_position: Vector2) -> void:
	var clean_value := clampf(value, MIN_SCALE, MAX_SCALE)
	if _canvas_scale == clean_value:
		return
	
	var old_offset := (_canvas_offset + towards_position) / _canvas_scale
	_canvas_scale = clean_value
	_canvas_offset = old_offset * _canvas_scale - towards_position
	canvas_transformed.emit()


func get_canvas_offset() -> Vector2:
	return _canvas_offset


func set_canvas_offset(value: Vector2) -> void:
	if _canvas_offset == value:
		return
	
	_canvas_offset = value
	canvas_transformed.emit()


func reset_canvas_transform() -> void:
	_canvas_scale = 1.0
	_canvas_offset = Vector2.ZERO
	canvas_transformed.emit()


func to_canvas_coordinates(ui_position: Vector2) -> Vector2:
	return (ui_position + _canvas_offset) / _canvas_scale


func from_canvas_coordinates(canvas_position: Vector2) -> Vector2:
	return canvas_position * _canvas_scale - _canvas_offset


func to_canvas_rect(ui_rect: Rect2) -> Rect2:
	var canvas_rect := Rect2()
	canvas_rect.position = to_canvas_coordinates(ui_rect.position)
	canvas_rect.size = ui_rect.size / _canvas_scale
	
	return canvas_rect


func from_canvas_rect(canvas_rect: Rect2) -> Rect2:
	var ui_rect := Rect2()
	ui_rect.position = from_canvas_coordinates(canvas_rect.position)
	ui_rect.size = canvas_rect.size * _canvas_scale
	
	return ui_rect
