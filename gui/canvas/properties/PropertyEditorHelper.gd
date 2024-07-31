###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertyEditorHelper extends Object

const SECTION_PROPERTY_EDITOR := preload("res://gui/canvas/properties/SectionPropertyEditor.tscn")
const TOGGLE_PROPERTY_EDITOR := preload("res://gui/canvas/properties/TogglePropertyEditor.tscn")
const COLOR_PROPERTY_EDITOR := preload("res://gui/canvas/properties/ColorPropertyEditor.tscn")
const STEPPER_PROPERTY_EDITOR := preload("res://gui/canvas/properties/StepperPropertyEditor.tscn")


static func create_section(element: BaseUIElement, label: String, icon: Texture2D = null) -> SectionPropertyEditor:
	var section_editor := SECTION_PROPERTY_EDITOR.instantiate()
	section_editor.connect_to_property(element, "", Callable())
	section_editor.label = label
	section_editor.icon = icon
	
	return section_editor


static func create_togglable_section(element: BaseUIElement, prop_name: String, prop_setter: Callable, label: String, icon: Texture2D = null) -> SectionPropertyEditor:
	var section_editor := SECTION_PROPERTY_EDITOR.instantiate()
	section_editor.connect_to_property(element, prop_name, prop_setter)
	section_editor.label = label
	section_editor.icon = icon
	
	return section_editor


static func create_toggle_property(element: BaseUIElement, prop_name: String, prop_setter: Callable) -> TogglePropertyEditor:
	var toggle_editor := TOGGLE_PROPERTY_EDITOR.instantiate()
	toggle_editor.connect_to_property(element, prop_name, prop_setter)
	
	return toggle_editor


static func create_color_property(element: BaseUIElement, prop_name: String, prop_setter: Callable) -> ColorPropertyEditor:
	var color_editor := COLOR_PROPERTY_EDITOR.instantiate()
	color_editor.connect_to_property(element, prop_name, prop_setter)
	
	return color_editor


static func create_stepper_property(element: BaseUIElement, prop_name: String, prop_setter: Callable) -> StepperPropertyEditor:
	var stepper_editor := STEPPER_PROPERTY_EDITOR.instantiate()
	stepper_editor.connect_to_property(element, prop_name, prop_setter)
	
	return stepper_editor
