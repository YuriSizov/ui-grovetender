###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The base element data object defines properties and methods shared by
## all possible data objects. It can exist as a standalone data object,
## or as a state. It also describes how properties should be transitioned,
## if this state object is activated or deactivated.
class_name BaseElementData extends Resource

signal property_changed(property_name: String)
signal properties_changed()

# Stealing this unused property usage flag for our needs. Let's hope it is
# never reclaimed by the engine.
const PROPERTY_USAGE_ELEMENT_DATA := PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE

# State data.

## The instance of the state data object. Contains details about stateful
## property overrides and the activity flag.
@export var state: UIState = UIState.new()
## The instance of the transition object used when activating the state.
@export var state_in_transition: UITransition = UITransition.new()
## The instance of the transition object used when deactivating the state.
@export var state_out_transition: UITransition = UITransition.new()

# Common element data.

## The position relative to the owner element's anchor point. Used to do
## smaller adjustments for various states and animations.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var offset: Vector2 = Vector2.ZERO
## The size of the owner element.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_DATA)
var size: Vector2 = Vector2(64, 64)

# Runtime properties.

## The flag that enables debug drawing for this data object.
var debug_drawing: bool = false
## The additional offset for the displaying a preview of this state on
## canvas.
var preview_offset: Vector2 = Vector2.ZERO


static func get_default_name() -> String:
	return "EmptyElement"


## Virtual. Called by the proxy control to render this state.
func draw(_proxy: Control) -> void:
	pass


# Property management.

func _notify_properties_changed(property_names: Array[String], override: bool) -> void:
	# Update the state metadata, if applicable.
	
	if state.state_type != StateType.STATE_DEFAULT:
		for property_name in property_names:
			if override:
				state.override_property(property_name)
			else:
				state.clear_property(property_name)
	
	# Notify property changes.
	
	for property_name in property_names:
		property_changed.emit(property_name)
	properties_changed.emit()


func get_data_properties() -> PackedStringArray:
	var data_properties := PackedStringArray()
	var all_properties := get_property_list()
	
	for property_info: Dictionary in all_properties:
		if property_info.usage & PROPERTY_USAGE_ELEMENT_DATA:
			data_properties.push_back(property_info.name)
	
	return data_properties


# Property editors and gizmos.

func get_editable_properties(element: UIElement, editing_mode: int) -> Array[PropertyEditor]:
	var properties: Array[PropertyEditor] = []
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		
		var layout_section := SectionPropertyEditor.create(element, self)
		layout_section.label = "Layout"
		layout_section.icon = preload("res://assets/icons/base-layout.png")
		properties.push_back(layout_section)
		
		var offset_property := StepperPropertyEditor.create(element, self)
		offset_property.connect_to_property("offset", _set_offset)
		offset_property.label = "Offset"
		offset_property.set_value_limits(-100.0, 100.0, true, true) # Max value doesn't matter.
		offset_property.set_value_step(1.0)
		layout_section.connect_editor(offset_property)
		properties.push_back(offset_property)
		
		var size_property := StepperPropertyEditor.create(element, self)
		size_property.connect_to_property("size", _set_size)
		size_property.label = "Size"
		size_property.set_value_limits(0.0, 200.0, false, true) # Max value doesn't matter.
		size_property.set_value_step(1.0)
		layout_section.connect_editor(size_property)
		properties.push_back(size_property)
	
	elif editing_mode == EditingMode.BEHAVIOR_TOOLS:
		# These sections only make sense for composite elements, as they can have children.
		if element is UICompositeElement:
			
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
	
	return properties


func get_gizmos(element: UIElement, editing_mode: int) -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		var position_gizmo := PositionGizmo.new(element, self)
		position_gizmo.anchor_changed.connect(element.adjust_anchor_point)
		position_gizmo.offset_changed.connect(_adjust_offset.bind(true))
		gizmos.push_back(position_gizmo)
	
	return gizmos


# Properties.

func _set_offset(value: Vector2, override: bool) -> void:
	if offset == value:
		return
	
	offset = value
	_notify_properties_changed([ "offset" ], override)


func _adjust_offset(delta: Vector2, override: bool) -> void:
	_set_offset(offset + delta, override)


func _set_size(value: Vector2, override: bool) -> void:
	if size == value:
		return
	
	size = value
	_notify_properties_changed([ "size" ], override)
