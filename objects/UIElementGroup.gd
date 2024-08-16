###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The element group object, abstracting management of a list of elements,
## either in the canvas or in one of the UICompositeElement instances.
class_name UIElementGroup extends Resource

@export var elements: Array[UIElement] = []


# Element management.

# Because get() is taken...
func fetch(index: int) -> UIElement:
	if index < 0 || index >= elements.size():
		printerr("UIElementGroup: Invalid element index %d when fetching an element from a group (%s)." % [ index, self ])
		return null
	
	return elements[index]


func add(element:UIElement) -> bool:
	if element.has_group():
		printerr("UIElementGroup: Cannot add an element (%s) to a group (%s) because it belongs to a group (%d) already." % [ element, self, element.get_group_id() ])
		return false
	
	elements.push_back(element)
	element.set_group_id(get_instance_id())
	return true


func erase(element: UIElement) -> bool:
	if element.get_group_id() != get_instance_id():
		printerr("UIElementGroup: Cannot erase an element (%s) from a group (%s) because it doesn't belong to it." % [ element, self ])
		return false
	
	elements.erase(element)
	element.clear_group_id()
	return true


func move(element: UIElement, to_index: int) -> bool:
	if element.get_group_id() != get_instance_id():
		printerr("UIElementGroup: Cannot move an element (%s) in a group (%s) because it doesn't belong to it." % [ element, self ])
		return false
	
	var element_index := elements.find(element)
	if element_index == to_index:
		return false # Already at the target index, abort early without an error.
	
	elements.erase(element)
	elements.insert(to_index, element)
	return true


func is_empty() -> bool:
	return elements.is_empty()
