###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CompositeElementData extends BaseElementData


static func get_default_name() -> String:
	return "CompositeElement"


# Property editors and gizmos.

func get_editable_properties(element: UIElement, editing_mode: int) -> Array[PropertyEditor]:
	var properties: Array[PropertyEditor] = []
	
	# Composite elements aren't directly editable right now. So most of properties
	# don't make sense. However, behavior tools have several additional editors for
	# composite elements, since they can have children.
	
	if editing_mode == EditingMode.BEHAVIOR_TOOLS:
		# Behavior presets.
		
		var preset_section := SectionPropertyEditor.create(element, self)
		preset_section.label = "Preset"
		properties.push_back(preset_section)
		
		# Slots.
		
		var slots_section := SectionPropertyEditor.create(element, self)
		slots_section.label = "Slots"
		properties.push_back(slots_section)
		
		# States.
		
		var states_section := SectionPropertyEditor.create(element, self)
		states_section.label = "States"
		states_section.icon = preload("res://assets/icons/behavior-states.png")
		properties.push_back(states_section)
		
		var states_list := StatePropertyEditor.create(element, self)
		states_section.connect_editor(states_list)
		properties.push_back(states_list)
	
	elif editing_mode == EditingMode.ANIMATION_TOOLS:
		# Default state doesn't use its transitions, because it's always active.
		if state.state_type != StateType.STATE_DEFAULT:
			
			# State IN/OUT preview.
			
			var preview_section := SectionPropertyEditor.create(element, self)
			preview_section.label = "Preview"
			preview_section.icon_hidden = true
			properties.push_back(preview_section)
			
			var preview_editor := TransitionPropertyPreview.create(element, self)
			preview_section.connect_editor(preview_editor)
			properties.push_back(preview_editor)
	
	return properties


func get_gizmos(_element: UIElement, _editing_mode: int) -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	# Composite elements aren't directly editable right now.
	return gizmos

