###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

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


# Helpers.

func _update_bounding_box() -> void:
	if elements.is_empty():
		rect.set_position(Vector2.ZERO)
		rect.set_size(Vector2.ZERO)
		
		property_changed.emit("rect:size")
		property_changed.emit("rect:position")
		properties_changed.emit()
		return
	
	var bounding_box := elements[0].rect.get_bounding_rect()
	for element in elements:
		var other_box := element.rect.get_bounding_rect()
		bounding_box = bounding_box.merge(other_box)
	
	rect.set_position(bounding_box.position + bounding_box.size / 2.0)
	rect.set_size(bounding_box.size)
	
	property_changed.emit("rect:size")
	property_changed.emit("rect:position")
	properties_changed.emit()


func _expand_bounding_box(new_element: BaseUIElement) -> void:
	pass


# Implementation.

func draw() -> void:
	for element in elements:
		if not element.visible:
			continue
		
		element.set_control_id(_control_id)
		element.draw()
		element.clear_control_id()


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
