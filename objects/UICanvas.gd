###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name UICanvas extends Resource

signal element_created(element: BaseUIElement)
signal element_removed(element: BaseUIElement)
signal elements_sorted(owner_element: CompositeElement)

## The display name of the canvas.
@export var canvas_name: String = "Canvas"
## The collection of elements in this canvas.
@export var elements: Array[BaseUIElement] = []
## The index used to generate unique element names.
@export var element_increment: int = 0


func create_element(element_type: int, at_position: Vector2) -> BaseUIElement:
	var element: BaseUIElement = null
	
	match element_type:
		ElementType.ELEMENT_EMPTY:
			element = BaseUIElement.new()
		ElementType.ELEMENT_PANEL:
			element = PanelElement.new()
		ElementType.ELEMENT_TEXT:
			element = TextElement.new()
		ElementType.ELEMENT_ICON:
			element = IconElement.new()
		_:
			printerr("UICanvas: Unknown element type %d." % [ element_type ])
	
	if element:
		element.rect.position = at_position
		_name_created_element(element)
		elements.push_back(element)
		element_created.emit(element)
	
	return element


func _name_created_element(element: BaseUIElement) -> void:
	# TODO: Implement a more robust system for avoiding name collisions.
	element.element_name += "%d" % [ element_increment ]
	element_increment += 1


func remove_element(element: BaseUIElement) -> void:
	if not _is_element_owned_by_canvas(element):
		printerr("UICanvas: Cannot remove the element that doesn't belong to this canvas, %s." % [ element ])
		return
	
	if element.has_owner():
		var owner_element: CompositeElement = element.get_owner()
		owner_element.elements.erase(element)
		element_removed.emit(element)
		
		if owner_element.elements.is_empty():
			remove_element(owner_element)
	
	else:
		elements.erase(element)
		element_removed.emit(element)


func sort_element(element: BaseUIElement, to_index: int) -> void:
	if not _is_element_owned_by_canvas(element):
		printerr("UICanvas: Cannot sort element that doesn't belong to this canvas, %s." % [ element ])
		return
	
	if element.has_owner():
		var owner_element: CompositeElement = element.get_owner()
		owner_element.elements.erase(element)
		owner_element.elements.insert(to_index, element)
		elements_sorted.emit(owner_element)
	
	else:
		elements.erase(element)
		elements.insert(to_index, element)
		elements_sorted.emit(null)


func group_elements(grouped_elements: Array[BaseUIElement]) -> void:
	if grouped_elements.is_empty():
		return
	
	var common_owner_id := grouped_elements[0].get_owner_id()
	for element in grouped_elements:
		if not _is_element_owned_by_canvas(element):
			printerr("UICanvas: Cannot group elements, because not all of them belong to this canvas.")
			return
		
		if element.get_owner_id() != common_owner_id:
			printerr("UICanvas: Cannot group elements, because not all of them have the same owner.")
			return
	
	# Use the element list either from the canvas or from the common owner element.
	var owner_elements := elements
	if is_instance_id_valid(common_owner_id):
		var common_owner_element: CompositeElement = instance_from_id(common_owner_id)
		owner_elements = common_owner_element.elements
	
	for element in grouped_elements:
		owner_elements.erase(element)
		element_removed.emit(element)
	
	var composite_element := CompositeElement.new()
	composite_element.set_elements(grouped_elements)
	_name_created_element(composite_element)
	
	owner_elements.push_back(composite_element)
	element_created.emit(composite_element)


func _is_element_owned_by_canvas(element: BaseUIElement) -> bool:
	var topmost_element := element
	
	while topmost_element.has_owner():
		topmost_element = topmost_element.get_owner()
	
	return elements.has(topmost_element)
