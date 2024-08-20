###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name PropertyEditorHelper extends Object

# Sections.
const SECTION_PROPERTY_EDITOR := preload("res://gui/drawers/properties/SectionPropertyEditor.tscn")

# Value editors.
const TOGGLE_PROPERTY_EDITOR := preload("res://gui/drawers/properties/TogglePropertyEditor.tscn")
const COLOR_PROPERTY_EDITOR := preload("res://gui/drawers/properties/ColorPropertyEditor.tscn")
const STEPPER_PROPERTY_EDITOR := preload("res://gui/drawers/properties/StepperPropertyEditor.tscn")
const VARIANT_PROPERTY_EDITOR := preload("res://gui/drawers/properties/VariantPropertyEditor.tscn")
const FONT_FILE_PROPERTY_EDITOR := preload("res://gui/drawers/properties/FontFilePropertyEditor.tscn")


# Sections.

static func create_section(element_data: BaseElementData, label: String, icon: Texture2D = null) -> SectionPropertyEditor:
	var section_editor: SectionPropertyEditor = SECTION_PROPERTY_EDITOR.instantiate()
	section_editor.connect_to_property(element_data, "", Callable())
	section_editor.label = label
	section_editor.icon = icon
	
	return section_editor


static func create_togglable_section(element_data: BaseElementData, prop_name: String, prop_setter: Callable, label: String, icon: Texture2D = null) -> SectionPropertyEditor:
	var section_editor: SectionPropertyEditor = SECTION_PROPERTY_EDITOR.instantiate()
	section_editor.connect_to_property(element_data, prop_name, prop_setter)
	section_editor.label = label
	section_editor.icon = icon
	
	return section_editor


# Value editors.

static func create_toggle_property(element_data: BaseElementData, prop_name: String, prop_setter: Callable) -> TogglePropertyEditor:
	var toggle_editor: TogglePropertyEditor = TOGGLE_PROPERTY_EDITOR.instantiate()
	toggle_editor.connect_to_property(element_data, prop_name, prop_setter)
	
	return toggle_editor


static func create_color_property(element_data: BaseElementData, prop_name: String, prop_setter: Callable) -> ColorPropertyEditor:
	var color_editor: ColorPropertyEditor = COLOR_PROPERTY_EDITOR.instantiate()
	color_editor.connect_to_property(element_data, prop_name, prop_setter)
	
	return color_editor


static func create_stepper_property(element_data: BaseElementData, prop_name: String, prop_setter: Callable) -> StepperPropertyEditor:
	var stepper_editor: StepperPropertyEditor = STEPPER_PROPERTY_EDITOR.instantiate()
	stepper_editor.connect_to_property(element_data, prop_name, prop_setter)
	
	return stepper_editor


static func create_variant_property(element_data: BaseElementData, prop_name: String, prop_setter: Callable) -> VariantPropertyEditor:
	var stepper_editor: VariantPropertyEditor = VARIANT_PROPERTY_EDITOR.instantiate()
	stepper_editor.connect_to_property(element_data, prop_name, prop_setter)
	
	return stepper_editor


static func create_font_file_property(element_data: BaseElementData, prop_name: String, prop_setter: Callable) -> FontFilePropertyEditor:
	var stepper_editor: FontFilePropertyEditor = FONT_FILE_PROPERTY_EDITOR.instantiate()
	stepper_editor.connect_to_property(element_data, prop_name, prop_setter)
	
	return stepper_editor
