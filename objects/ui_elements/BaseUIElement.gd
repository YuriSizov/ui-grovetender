###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI elements. Encapsulates shared logic and universal data members.
class_name BaseUIElement extends Resource

signal rect_changed()
signal visibility_changed()
signal property_changed(property_name: String)
signal properties_changed()
signal states_changed()
signal active_states_changed()

signal editor_selected()
signal editor_deselected()

# Stealing this unused property usage flag for our needs. Let's hope it is never reclaimed by the engine.
const PROPERTY_USAGE_ELEMENT_MERGEABLE := PROPERTY_USAGE_SCRIPT_DEFAULT_VALUE

# Basic properties.

## The unique name of this UI element.
@export var element_name: String = "EmptyElement"
## The rectangle defining the size and position of this UI element.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_MERGEABLE)
var rect: UIRect = UIRect.new()
## The visibility flag, enabling or disabling rendering of this UI element.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_ELEMENT_MERGEABLE)
var visible: bool = true:
	set = set_visible

# Behavior properties.

## The pre-configured set of states and exposed elements used to create standard widgets.
@export var behavior_preset: int = BehaviorPreset.PRESET_CUSTOM
## The collection of states that this element and its children can take.
@export var states: Array[UIState] = []
## The collection of exposed slots, either to fulfill a preset role or for custom user-defined behavior.
@export var exposed_slots: Array[ExposedSlot] = []

# Runtime properties.

## The instance ID of the owner element. Runtime only.
var _owner_id: int = 0
## The instance ID of the control. Runtime only.
var _control_id: int = 0
## The selected status in the editor. Runtime only.
var _selected: bool = false
## The number of active states, used to determine if there are any states currently affecting this element.
## Runtime only.
var _states_active: int = 0
## The instance of this element that combines all active states into one for ease of reference. Runtime only.
var _merged_element: BaseUIElement = null


func _init() -> void:
	rect.changed.connect(rect_changed.emit) # Pass through the signal.


func draw() -> void:
	if _merged_element:
		_merged_element._draw()


# Metadata.

## Returns the element, normally a CompositeElement instance, that owns/is a parent of
## this UI element.
func get_owner() -> BaseUIElement:
	if not is_instance_id_valid(_owner_id):
		return null
	
	return instance_from_id(_owner_id)


## Returns the instance ID of the owner element for this UI element.
func get_owner_id() -> int:
	return _owner_id


## Returns whether there is a valid owner element for this UI element.
func has_owner() -> bool:
	return is_instance_id_valid(_owner_id)


## Sets the composite element that contains this UI element by its instance ID.
func set_owner_id(instance_id: int) -> void:
	if not is_instance_id_valid(instance_id):
		return
	
	_owner_id = instance_id


## Clears the composite element that contains this UI element.
func clear_owner_id() -> void:
	_owner_id = 0


## Returns the Control node responsible for rendering of this UI element.
func get_control() -> CanvasElementControl:
	if not is_instance_id_valid(_control_id):
		return null
	
	return instance_from_id(_control_id)


## Sets the Control node responsible for rendering this UI element by its instance ID.
func set_control_id(instance_id: int) -> void:
	if not is_instance_id_valid(instance_id):
		return
	
	_control_id = instance_id
	if _merged_element:
		_merged_element._control_id = _control_id


## Clears the Control node responsible for rendering this UI element.
func clear_control_id() -> void:
	_control_id = 0
	if _merged_element:
		_merged_element._control_id = _control_id


## Returns whether the element is selected in the editor.
func is_selected() -> bool:
	return _selected


## Marks the element as selected in the editor.
func set_selected(value: bool) -> void:
	if _selected == value:
		return
	
	_selected = value
	if _selected:
		editor_selected.emit()
	else:
		editor_deselected.emit()


# Position and sizing.

func get_owner_offset() -> Vector2:
	if not has_owner():
		return Vector2.ZERO
	
	var owner_element := get_owner()
	var owner_rect := owner_element.rect.get_bounding_rect()
	return owner_rect.position


## Returns the area for this UI element, relative to the control node.
func get_rect_in_control() -> Rect2:
	var control := get_control()
	if not control:
		return Rect2()
	
	var owner_offset := get_owner_offset()
	var bounding_rect := rect.get_bounding_rect()
	bounding_rect.position -= owner_offset + control.position
	
	return bounding_rect


# Properties.

func get_merged_element() -> BaseUIElement:
	return _merged_element


func initialize_merged_element() -> void:
	# I think this is the best way to make a new instance of the same type, since we cannot
	# pass the type itself as an argument.
	var class_script: GDScript = get_script()
	_merged_element = class_script.new()
	_merged_element._control_id = _control_id
	_rebuild_merged_element()


func _rebuild_merged_element() -> void:
	var all_properties := get_property_list()
	
	for property_info: Dictionary in all_properties:
		if property_info.usage & PROPERTY_USAGE_ELEMENT_MERGEABLE:
			var property_value: Variant = get_stateful_property(property_info.name)
			_merged_element.set(property_info.name, property_value)


func emit_properties_changed(properties: Array[String], updater_func: Callable = Callable()) -> void:
	# TODO: This must also be done when restoring projects from disk.
	if _merged_element:
		for property_name in properties:
			var property_value: Variant = get_stateful_property(property_name)
			_merged_element.set(property_name, property_value)
	
	if updater_func.is_valid():
		updater_func.call()
	
	for property_name in properties:
		property_changed.emit(property_name)
	properties_changed.emit()


# Behavior.

func add_state(state_type: int, state_name: String, mandatory: bool = false) -> bool:
	# For non-custom types check if we already have one. For now we assume all of them unique.
	if state_type != StateType.STATE_CUSTOM:
		for other_state in states:
			if other_state.state_type == state_type:
				return false
	
	# Sanitize the name before checking. This may be unnecessary in the long run, as the name
	# is always just a string. If we need a sanitized name for the API generation, we can do
	# it there. But let's keep it for now.
	state_name = state_name.to_lower().to_snake_case()
	
	# For all types check if the name is unique.
	for other_state in states:
		if other_state.state_name == state_name:
			return false
	
	var state := UIState.new()
	state.state_type = state_type
	state.state_name = state_name
	state.locked = mandatory
	
	state.state_activated.connect(func() -> void:
		_states_active += 1
		_rebuild_merged_element()
		active_states_changed.emit()
	)
	state.state_deactivated.connect(func() -> void:
		_states_active -= 1
		_rebuild_merged_element()
		active_states_changed.emit()
	)
	state.property_changed.connect(func(property_name: String) -> void:
		if _merged_element:
			var property_value: Variant = get_stateful_property(property_name)
			_merged_element.set(property_name, property_value)
	)
	
	state.connect_to_element(self)
	states.push_back(state)
	states_changed.emit()
	
	return true


func set_state_active(state: UIState, exclusive: bool = false) -> void:
	if state not in states:
		printerr("BaseUIElement: Trying to activate a state (%s) that doesn't belong to this element (%s)." % [ state, self ])
		return
	
	if exclusive:
		for other_state in states:
			other_state.deactivate()
	
	state.activate()


func has_active_states() -> bool:
	return _states_active > 0


func get_active_state() -> UIState:
	var states_amount := states.size()
	var i := states_amount - 1
	while i >= 0:
		var state := states[i]
		if state.is_active():
			return state
	
	return null


func get_stateful_property(prop_name: String) -> Variant:
	var prop_element := self
	
	var states_amount := states.size()
	var i := states_amount - 1
	while i >= 0:
		var state := states[i]
		if state.is_active() && state.is_property_overridden(prop_name):
			prop_element = state.overridden_element
			break
		
		i -=1
	
	if prop_name.contains(":"):
		return prop_element.get_indexed(prop_name)
	else:
		return prop_element.get(prop_name)


# Implementation.

## Renders this UI element. Extending classes override this method.
func _draw() -> void:
	pass


## Called to check if this element is overall selectable. Used together with has_point() and
## is_inside_area() to determine this element should be selected by clicks or selection drag.
## Extending classes may override this method.
func is_selectable() -> bool:
	return true


## Called to check if the given position belongs to this element. Extending classes may override
## this method.
func has_point(at_position: Vector2) -> bool:
	var element_rect := rect.get_bounding_rect()
	return element_rect.has_point(at_position)


## Called to check if the given area completely encloses this element. Extending classes may
## override this method.
func is_inside_area(area: Rect2) -> bool:
	var element_rect := rect.get_bounding_rect()
	return area.encloses(element_rect)


## Initializes and returns a set of gizmos for editing this UI element. Gizmos with lower indices
## are handled first. Extending classes override this method, but must call super() most of the time.
func get_gizmos(editing_mode: int) -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	# Always add this one, so no matter what there is a reference to the shape of the element.
	var boundary_gizmo := BoundaryGizmo.new(self)
	gizmos.push_back(boundary_gizmo)
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		var size_gizmo := SizeGizmo.new(self)
		gizmos.push_back(size_gizmo)
		
		# TODO: Keep track of the size at the start of the operation, accumulate deltas, and apply current modifier key effects retroactively.
		
		# TODO: Implement constraints, snapping, alignment.
		size_gizmo.corner_size_changed.connect(_resize_by_corner.bind(false))
		size_gizmo.corner_size_all_changed.connect(_resize_by_all_corners.bind(false))
		size_gizmo.corner_size_ratio_changed.connect(_resize_by_corner.bind(true))
		size_gizmo.corner_size_ratio_all_changed.connect(_resize_by_all_corners.bind(true))
		
		size_gizmo.side_size_changed.connect(_resize_by_side)
		size_gizmo.side_size_all_changed.connect(_resize_by_all_sides)
		size_gizmo.side_size_opposite_changed.connect(_resize_by_opposite_sides)
		
		var position_gizmo := PositionGizmo.new(self)
		gizmos.push_back(position_gizmo)
		# TODO: Implement constraints, snapping, alignment.
		position_gizmo.position_changed.connect(_reposition_by_center)
	
	return gizmos


## Initializes and returns a set of property editors for editing this UI element. Extending classes
## override this method, but must call super() most of the time.
func get_editable_properties(editing_mode: int) -> Array[PropertyEditor]:
	var properties: Array[PropertyEditor] = []
	
	if editing_mode == EditingMode.LAYOUT_TOOLS:
		var layout_section := PropertyEditorHelper.create_section(self, "Layout", preload("res://assets/icons/base-layout.png"))
		properties.push_back(layout_section)
		
		var size_property := PropertyEditorHelper.create_stepper_property(self, "rect:size", _set_size)
		size_property.label = "Size"
		size_property.set_value_limits(0.0, 200.0, false, true) # Max value doesn't matter.
		size_property.set_value_step(1.0)
		layout_section.connect_property_to_section(size_property)
		properties.push_back(size_property)
		
		# TODO: Add a property editor for position, when it's an offset inside a composite element.
		pass
	
	elif editing_mode == EditingMode.BEHAVIOR_TOOLS:
		# General behavior section.
		
		var behavior_section := PropertyEditorHelper.create_section(self, "Behavior", null)
		properties.push_back(behavior_section)
		
		# TODO: Implement preset selection.
		
		# Slots section.
		
		var slots_section := PropertyEditorHelper.create_section(self, "Slots", null)
		properties.push_back(slots_section)
		
		# TODO: Implement slot editor.
		
		# States section.
		
		var states_section := PropertyEditorHelper.create_section(self, "States", null)
		properties.push_back(states_section)
		
		var states_property := PropertyEditorHelper.create_state_property(self)
		states_section.connect_property_to_section(states_property)
		properties.push_back(states_property)
	
	return properties


# Property helpers.

func _set_size(value: Vector2) -> void:
	var center_size := _ensure_positive_size(value)
	
	rect.set_size(center_size)
	emit_properties_changed([ "rect:size" ])


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


func _resize_by_corner(corner: Corner, delta: Vector2, keep_ratio: bool) -> void:
	var center_rect := rect.get_size_and_position()
	
	match corner:
		CORNER_TOP_LEFT:
			center_rect.size -= delta # Inverted on both axes.
		CORNER_TOP_RIGHT:
			center_rect.size += Vector2(delta.x, -delta.y)
		CORNER_BOTTOM_RIGHT:
			center_rect.size += delta
		CORNER_BOTTOM_LEFT:
			center_rect.size += Vector2(-delta.x, delta.y)
	
	center_rect.size = _ensure_positive_size(center_rect.size)
	if keep_ratio:
		center_rect.size = _ensure_ratio_size(center_rect.size, rect.get_size())
	
	# Update position delta based on the actual size change.
	var effective_delta := Vector2(
		center_rect.size.x - rect.size.x,
		center_rect.size.y - rect.size.y
	)
	if corner == CORNER_TOP_LEFT || corner == CORNER_BOTTOM_LEFT:
		effective_delta.x *= -1
	if corner == CORNER_TOP_LEFT || corner == CORNER_TOP_RIGHT:
		effective_delta.y *= -1
	
	center_rect.position += effective_delta / 2.0
	rect.set_size_and_position(center_rect)
	emit_properties_changed([ "rect:size", "rect:position" ])


func _resize_by_all_corners(corner: Corner, delta: Vector2, keep_ratio: bool) -> void:
	var center_size := rect.get_size()
	
	match corner:
		CORNER_TOP_LEFT:
			center_size -= delta * 2.0 # Inverted on both axes.
		CORNER_TOP_RIGHT:
			center_size += Vector2(delta.x, -delta.y) * 2.0
		CORNER_BOTTOM_RIGHT:
			center_size += delta * 2.0
		CORNER_BOTTOM_LEFT:
			center_size += Vector2(-delta.x, delta.y) * 2.0
	
	center_size = _ensure_positive_size(center_size)
	if keep_ratio:
		center_size = _ensure_ratio_size(center_size, rect.get_size())
	
	rect.set_size(center_size)
	emit_properties_changed([ "rect:size" ])


func _resize_by_side(side: Side, delta: Vector2) -> void:
	var center_rect := rect.get_size_and_position()
	
	match side:
		SIDE_LEFT:
			center_rect.size.x -= delta.x
		SIDE_RIGHT:
			center_rect.size.x += delta.x
		SIDE_TOP:
			center_rect.size.y -= delta.y
		SIDE_BOTTOM:
			center_rect.size.y += delta.y
	
	center_rect.size = _ensure_positive_size(center_rect.size)
	
	# Update position delta based on the actual size change.
	var effective_delta := Vector2(
		center_rect.size.x - rect.size.x,
		center_rect.size.y - rect.size.y
	)
	if side == SIDE_LEFT:
		effective_delta.x *= -1
	if side == SIDE_TOP:
		effective_delta.y *= -1
	
	center_rect.position += effective_delta / 2.0
	rect.set_size_and_position(center_rect)
	emit_properties_changed([ "rect:size", "rect:position" ])


func _resize_by_all_sides(side: Side, delta: Vector2) -> void:
	var center_size := rect.get_size()
	
	match side:
		SIDE_LEFT:
			center_size.x -= delta.x * 2.0
			center_size.y -= delta.x * 2.0
		SIDE_RIGHT:
			center_size.x += delta.x * 2.0
			center_size.y += delta.x * 2.0
		SIDE_TOP:
			center_size.y -= delta.y * 2.0
			center_size.x -= delta.y * 2.0
		SIDE_BOTTOM:
			center_size.y += delta.y * 2.0
			center_size.x += delta.y * 2.0
	
	center_size = _ensure_positive_size(center_size)
	
	rect.set_size(center_size)
	emit_properties_changed([ "rect:size" ])


func _resize_by_opposite_sides(side: Side, delta: Vector2) -> void:
	var center_size := rect.get_size()
	
	match side:
		SIDE_LEFT:
			center_size.x -= delta.x * 2.0
		SIDE_RIGHT:
			center_size.x += delta.x * 2.0
		SIDE_TOP:
			center_size.y -= delta.y * 2.0
		SIDE_BOTTOM:
			center_size.y += delta.y * 2.0
	
	center_size = _ensure_positive_size(center_size)
	
	rect.set_size(center_size)
	emit_properties_changed([ "rect:size" ])


func _reposition_by_center(delta: Vector2) -> void:
	rect.position += delta
	emit_properties_changed([ "rect:position" ])


func set_visible(value: bool) -> void:
	if visible == value:
		return
	
	visible = value
	visibility_changed.emit()
