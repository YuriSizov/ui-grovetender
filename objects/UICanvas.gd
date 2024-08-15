###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name UICanvas extends Resource

signal element_added(element: UIElement)
signal element_removed(element: UIElement)

@export var elements: Array[UIElement] = []


# Element management.

func create_element() -> UIElement:
	var element := UIElement.new(BaseElementData)
	elements.push_back(element)
	
	element_added.emit(element)
	return element


func remove_element(element: UIElement) -> void:
	if element not in elements:
		return
	
	elements.erase(element)
	element_removed.emit(element)
