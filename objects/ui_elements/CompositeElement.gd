###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A grouping element. Doesn't have properties of its own, doesn't render. It is used
## to define a UI widget or a complex part of a UI widget. It typically owns the behavior
## setup (but states are defined on individual elements).
class_name CompositeElement extends BaseUIElement

## The collection of elements grouped by this composite element.
@export var elements: Array[BaseUIElement] = []


func _init() -> void:
	super()
	element_name = "CompositeElement"


# Properties.

func set_elements(grouped_elements: Array[BaseUIElement]) -> void:
	if not elements.is_empty():
		printerr("CompositeElement: Cannot set elements of this composite element (%d) because it's not empty." % [ get_instance_id() ])
		return
	
	for element in grouped_elements:
		_add_element(element)
	_update_bounding_box()


func add_element(element: BaseUIElement) -> void:
	_add_element(element)
	_expand_bounding_box(element)


func _add_element(element: BaseUIElement) -> void:
	if elements.has(element):
		printerr("CompositeElement: Trying to add an element (%d) that is already owned by this composite element (%d)." % [ element.get_instance_id(), get_instance_id() ])
		return
	if element.has_owner():
		printerr("CompositeElement: Cannot add an element (%d) that already has an owner (%d)." % [ element.get_instance_id(), element.get_owner_id() ])
		return
	
	element.set_owner_id(get_instance_id())
	elements.push_back(element)
	
	element.rect_changed.connect(_update_bounding_box)


func remove_element(element: BaseUIElement) -> void:
	if not elements.has(element):
		printerr("CompositeElement: Trying to remove an element (%d) that is not owned by this composite element (%d)." % [ element.get_instance_id(), get_instance_id() ])
		return
	
	element.rect_changed.disconnect(_update_bounding_box)
	
	elements.erase(element)
	element.clear_owner_id()
	_update_bounding_box()


# Helpers.

func _update_bounding_box() -> void:
	var center_rect := Rect2()

	if elements.is_empty():
		center_rect.position = Vector2.ZERO
		center_rect.size = Vector2.ZERO
	
	else:
		var bounding_box := elements[0].rect.get_bounding_rect()
		for element in elements:
			var element_box := element.rect.get_bounding_rect()
			bounding_box = bounding_box.merge(element_box)
		
		center_rect.position = bounding_box.position + bounding_box.size / 2.0
		center_rect.size = bounding_box.size
	
	if rect.position == center_rect.position && rect.size == center_rect.size:
		return
	
	rect.set_size_and_position(center_rect)
	emit_properties_changed([ "rect:size", "rect:position" ])


func _expand_bounding_box(new_element: BaseUIElement) -> void:
	if elements.size() < 2:
		_update_bounding_box() # There is only one element, just do a full update.
		return
	
	var bounding_box := rect.get_bounding_rect()
	var element_box := new_element.rect.get_bounding_rect()
	bounding_box = bounding_box.merge(element_box)
	
	var center_rect := Rect2()
	center_rect.position = bounding_box.position + bounding_box.size / 2.0
	center_rect.size = bounding_box.size
	
	if rect.position == center_rect.position && rect.size == center_rect.size:
		return
	
	rect.set_size_and_position(center_rect)
	emit_properties_changed([ "rect:size", "rect:position" ])


# Implementation.

func is_selectable() -> bool:
	# Composite elements are used for grouping, but they are otherwise invisible. Making them
	# selectable on canvas can be confusing, so disabling this for now.
	return false


func get_gizmos(_editing_mode: int) -> Array[BaseGizmo]:
	# For now, composite elements are not editable so we override default gizmos.
	var gizmos: Array[BaseGizmo] = []
	
	# Always add this one, so no matter what there is a reference to the shape of the element.
	var boundary_gizmo := BoundaryGizmo.new(self)
	gizmos.push_back(boundary_gizmo)
	
	return gizmos


func get_editable_properties(_editing_mode: int) -> Array[PropertyEditor]:
	# For now, composite elements are not editable so we override default property editors.
	var properties: Array[PropertyEditor] = []
	
	return properties
