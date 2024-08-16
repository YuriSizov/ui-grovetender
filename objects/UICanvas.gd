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

@export var element_group: UIElementGroup = UIElementGroup.new()


# Element management.

func create_element(owner_element: UICompositeElement, at_position: Vector2) -> void:
	var element := UIElement.new(BaseElementData)
	element.set_anchor_point(at_position)
	
	var owner_group := owner_element.element_group if owner_element else element_group
	owner_group.add(element)
	element_created.emit(element)


func remove_element(element: UIElement) -> void:
	var owner_group := element.get_group()
	if owner_group.erase(element):
		element_removed.emit(element)


func sort_element(element: UIElement, to_index: int) -> void:
	var owner_group := element.get_group()
	if owner_group.move(element, to_index):
		element_sorted.emit(element, to_index)


func group_elements(elements: Array[UIElement]) -> void:
	pass
