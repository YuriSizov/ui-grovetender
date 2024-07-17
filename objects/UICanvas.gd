###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name UICanvas extends Resource

signal element_created(element: BaseUIElement)

@export var elements: Array[BaseUIElement] = []


func create_element(element_type: int, at_position: Vector2) -> BaseUIElement:
	var element: BaseUIElement = null
	
	match element_type:
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
		
		elements.push_back(element)
		element_created.emit(element)
	
	return element
