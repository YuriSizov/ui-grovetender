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
signal transitions_changed()

signal anchor_changed_from_size(delta: Vector2)

# Stealing this unused property usage flag for our needs. Let's hope it is
# never reclaimed by the engine.
const PROPERTY_USAGE_ELEMENT_DATA := PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE

# State data.

## The instance of the state data object. Contains details about stateful
## property overrides and the activity flag.
@export var state: UIState = UIState.new()
## The instance of the transition object used when activating the state.
@export var state_in_transition: UITransition = null
## The instance of the transition object used when deactivating the state.
@export var state_out_transition: UITransition = null

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


func _init() -> void:
	state_in_transition = UITransition.new()
	state_out_transition = UITransition.new()
	
	state_in_transition.transition_changed.connect(transitions_changed.emit)
	state_out_transition.transition_changed.connect(transitions_changed.emit)


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
		# States.
		
		var states_section := SectionPropertyEditor.create(element, self)
		states_section.label = "States"
		states_section.icon = preload("res://assets/icons/behavior-states.png")
		properties.push_back(states_section)
		
		var states_list := StatePropertyEditor.create(element, self)
		states_section.connect_editor(states_list)
		properties.push_back(states_list)
	
	elif editing_mode == EditingMode.ANIMATION_TOOLS:
		# TODO: Add support for custom transitions?
		# TODO: Add support for complex transitions?
		
		# Default state doesn't use its transitions, because it's always active.
		if state.state_type != StateType.STATE_DEFAULT:
			
			# State IN transition.
			
			var transition_in_section := SectionPropertyEditor.create(element, self)
			transition_in_section.label = "In Transition"
			properties.push_back(transition_in_section)
			
			var transition_in_editor := TransitionPropertyEditor.create(element, self)
			transition_in_editor.connect_to_property("state_in_transition", Callable())
			transition_in_section.connect_editor(transition_in_editor)
			properties.push_back(transition_in_editor)
			
			# State OUT transition.
			
			var transition_out_section := SectionPropertyEditor.create(element, self)
			transition_out_section.label = "Out Transition"
			properties.push_back(transition_out_section)
			
			var transition_out_editor := TransitionPropertyEditor.create(element, self)
			transition_out_editor.connect_to_property("state_out_transition", Callable())
			transition_out_section.connect_editor(transition_out_editor)
			properties.push_back(transition_out_editor)
			
			# State IN/OUT preview.
			
			var preview_section := SectionPropertyEditor.create(element, self)
			preview_section.label = "Preview"
			preview_section.icon_hidden = true
			properties.push_back(preview_section)
			
			var preview_editor := TransitionPropertyPreview.create(element, self)
			preview_section.connect_editor(preview_editor)
			properties.push_back(preview_editor)
	
	return properties


func get_gizmos(element: UIElement, editing_mode: int) -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		# TODO: Implement constraints, snapping, alignment.
		# TODO: Keep track of the size at the start of the operation, accumulate deltas, and apply current modifier key effects retroactively.
		
		var size_gizmo := SizeGizmo.new(element, self)
		size_gizmo.corner_size_changed.connect(_resize_by_corner.bind(false, true))
		size_gizmo.corner_size_all_changed.connect(_resize_by_all_corners.bind(false, true))
		size_gizmo.corner_size_ratio_changed.connect(_resize_by_corner.bind(true, true))
		size_gizmo.corner_size_ratio_all_changed.connect(_resize_by_all_corners.bind(true, true))
		
		size_gizmo.side_size_changed.connect(_resize_by_side.bind(true))
		size_gizmo.side_size_all_changed.connect(_resize_by_all_sides.bind(true))
		size_gizmo.side_size_opposite_changed.connect(_resize_by_opposite_sides.bind(true))
		
		gizmos.push_back(size_gizmo)
		
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
	Controller.current_project.mark_dirty()


func _adjust_offset(delta: Vector2, override: bool) -> void:
	_set_offset(offset + delta, override)


func _set_size(value: Vector2, override: bool) -> void:
	var sanitized_value := _ensure_positive_size(value)
	if size == sanitized_value:
		return
	
	size = sanitized_value
	_notify_properties_changed([ "size" ], override)
	Controller.current_project.mark_dirty()


func _adjust_anchor_with_size(value: Vector2, x_factor: float, y_factor: float) -> void:
	var position_delta := value - size
	
	# These depend on which handle we're dragging.
	position_delta.x *= x_factor
	position_delta.y *= y_factor
	
	anchor_changed_from_size.emit(position_delta)


func _ensure_positive_size(value: Vector2) -> Vector2:
	if value.x < 0:
		value.x = 0
	if value.y < 0:
		value.y = 0
	
	return value


func _ensure_ratio_size(value: Vector2, ratio: Vector2) -> Vector2:
	if ratio.x == 0 || ratio.y == 0:
		return value
	
	if ratio.x > ratio.y:
		value.y = (ratio.y / ratio.x) * value.x
	else:
		value.x = (ratio.x / ratio.y) * value.y
	
	return _ensure_positive_size(value)


func _resize_by_corner(corner: Corner, delta: Vector2, keep_ratio: bool, override: bool) -> void:
	var adjusted_size := size
	
	match corner:
		CORNER_TOP_LEFT:
			adjusted_size -= delta # Inverted on both axes.
		CORNER_TOP_RIGHT:
			adjusted_size += Vector2(delta.x, -delta.y)
		CORNER_BOTTOM_RIGHT:
			adjusted_size += delta
		CORNER_BOTTOM_LEFT:
			adjusted_size += Vector2(-delta.x, delta.y)
	
	adjusted_size = _ensure_positive_size(adjusted_size)
	if keep_ratio:
		adjusted_size = _ensure_ratio_size(adjusted_size, size)
	
	_adjust_anchor_with_size(
		adjusted_size,
		-1.0 if corner == CORNER_TOP_LEFT || corner == CORNER_BOTTOM_LEFT else 0.0,
		-1.0 if corner == CORNER_TOP_LEFT || corner == CORNER_TOP_RIGHT else 0.0
	)
	_set_size(adjusted_size, override)


func _resize_by_all_corners(corner: Corner, delta: Vector2, keep_ratio: bool, override: bool) -> void:
	var adjusted_size := size
	
	match corner:
		CORNER_TOP_LEFT:
			adjusted_size -= delta * 2.0 # Inverted on both axes.
		CORNER_TOP_RIGHT:
			adjusted_size += Vector2(delta.x, -delta.y) * 2.0
		CORNER_BOTTOM_RIGHT:
			adjusted_size += delta * 2.0
		CORNER_BOTTOM_LEFT:
			adjusted_size += Vector2(-delta.x, delta.y) * 2.0
	
	adjusted_size = _ensure_positive_size(adjusted_size)
	if keep_ratio:
		adjusted_size = _ensure_ratio_size(adjusted_size, size)
	
	_adjust_anchor_with_size(
		adjusted_size,
		-0.5,
		-0.5
	)
	_set_size(adjusted_size, override)


func _resize_by_side(side: Side, delta: Vector2, override: bool) -> void:
	var adjusted_size := size
	
	match side:
		SIDE_LEFT:
			adjusted_size.x -= delta.x
		SIDE_RIGHT:
			adjusted_size.x += delta.x
		SIDE_TOP:
			adjusted_size.y -= delta.y
		SIDE_BOTTOM:
			adjusted_size.y += delta.y
	
	adjusted_size = _ensure_positive_size(adjusted_size)
	_adjust_anchor_with_size(
		adjusted_size,
		-1.0 if side == SIDE_LEFT else 0.0,
		-1.0 if side == SIDE_TOP else 0.0
	)
	_set_size(adjusted_size, override)


func _resize_by_all_sides(side: Side, delta: Vector2, override: bool) -> void:
	var adjusted_size := size
	
	match side:
		SIDE_LEFT:
			adjusted_size.x -= delta.x * 2.0
			adjusted_size.y -= delta.x * 2.0
		SIDE_RIGHT:
			adjusted_size.x += delta.x * 2.0
			adjusted_size.y += delta.x * 2.0
		SIDE_TOP:
			adjusted_size.y -= delta.y * 2.0
			adjusted_size.x -= delta.y * 2.0
		SIDE_BOTTOM:
			adjusted_size.y += delta.y * 2.0
			adjusted_size.x += delta.y * 2.0
	
	adjusted_size = _ensure_positive_size(adjusted_size)
	_adjust_anchor_with_size(
		adjusted_size,
		-0.5,
		-0.5
	)
	_set_size(adjusted_size, override)


func _resize_by_opposite_sides(side: Side, delta: Vector2, override: bool) -> void:
	var adjusted_size := size
	
	match side:
		SIDE_LEFT:
			adjusted_size.x -= delta.x * 2.0
		SIDE_RIGHT:
			adjusted_size.x += delta.x * 2.0
		SIDE_TOP:
			adjusted_size.y -= delta.y * 2.0
		SIDE_BOTTOM:
			adjusted_size.y += delta.y * 2.0
	
	adjusted_size = _ensure_positive_size(adjusted_size)
	_adjust_anchor_with_size(
		adjusted_size,
		-0.5 if side == SIDE_LEFT || side == SIDE_RIGHT else 0.0,
		-0.5 if side == SIDE_TOP || side == SIDE_BOTTOM else 0.0
	)
	_set_size(adjusted_size, override)
