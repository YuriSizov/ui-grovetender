###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The element group object, abstracting management of a list of elements,
## either in the canvas or in one of the UICompositeElement instances.
class_name UIElementGroup extends Resource

signal element_added(element: UIElement)
signal element_erased(element: UIElement)
signal element_moved(element: UIElement, to_index: int)

@export var elements: Array[UIElement] = []

var _owner_id: int = 0


func _init(owner: Object) -> void:
	_owner_id = owner.get_instance_id()


func get_owner() -> Object:
	if not is_instance_id_valid(_owner_id):
		return null
	
	return instance_from_id(_owner_id)


func get_owner_group() -> UIElementGroup:
	var owner := get_owner()
	
	if owner && owner is UICompositeElement:
		var owner_element := owner as UICompositeElement
		return owner_element.get_group()
	
	return null


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
	element_added.emit(element)
	return true


func erase(element: UIElement) -> bool:
	if element.get_group_id() != get_instance_id():
		printerr("UIElementGroup: Cannot erase an element (%s) from a group (%s) because it doesn't belong to it." % [ element, self ])
		return false
	
	elements.erase(element)
	element.clear_group_id()
	element_erased.emit(element)
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
	element_moved.emit(element, to_index)
	return true


func is_empty() -> bool:
	return elements.is_empty()


# Transform management.

func notify_transform() -> void:
	for element in elements:
		element.notify_transform_changed()
		
		if element is UICompositeElement:
			element.element_group.notify_transform()
