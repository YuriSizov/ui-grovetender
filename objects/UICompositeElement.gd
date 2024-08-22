###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The composite UI element object. It acts as a group/collection of
## other UI elements and defines a widget or a significant part of a
## widget that must share configuration (states, behavior model, etc.)
class_name UICompositeElement extends UIElement

@export var element_group: UIElementGroup = null


func _init(data_class: GDScript) -> void:
	super(data_class)
	
	element_name = "CompositeElement"
	
	element_group = UIElementGroup.new(self)
	element_group.element_added.connect(_track_grouped_element)
	element_group.element_erased.connect(_untrack_grouped_element)
	
	_update_grouped_transform()


# Element management.

func _track_grouped_element(element: UIElement) -> void:
	element.transform_queued.connect(_update_grouped_transform)
	
	# Ensure that the grouped element has all the states from this composite element.
	var states: Array[Array] = []
	for state_data in variant_states:
		var state_tuple := [ state_data.state.state_type, state_data.state.state_name ]
		states.push_back(state_tuple)
	
	_ensure_grouped_states(states, [ element ])
	
	_extend_grouped_transform(element)


func _untrack_grouped_element(element: UIElement) -> void:
	element.transform_queued.disconnect(_update_grouped_transform)
	
	_update_grouped_transform()


func _update_grouped_transform() -> void:
	var global_rect := Rect2()
	
	if not element_group.is_empty():
		var first_element := element_group.fetch(0)
		global_rect = first_element.get_default_state_rect()
		
		for element in element_group.elements:
			var element_rect := element.get_default_state_rect()
			global_rect = global_rect.merge(element_rect)
	
	_set_global_transform(global_rect)


func _extend_grouped_transform(element: UIElement) -> void:
	if element_group.elements.size() == 1:
		_update_grouped_transform()
		return
	
	var global_rect := get_default_state_rect()
	var element_rect := element.get_default_state_rect()
	global_rect = global_rect.merge(element_rect)
	
	_set_global_transform(global_rect)


# State and data management.

func create_state(state_type: int, state_name: String) -> BaseElementData:
	var state_data := super(state_type, state_name)
	
	if state_data:
		# Ensure all grouped elements have the new state.
		var state_tuple := [ state_data.state.state_type, state_data.state.state_name ]
		_ensure_grouped_states([ state_tuple ], element_group.elements)
	
	return state_data


func _ensure_grouped_states(states: Array[Array], elements: Array[UIElement]) -> void:
	for element in elements:
		for state_tuple in states:
			element.ensure_state(state_tuple[0], state_tuple[1])
		
		# Propagate further.
		if element is UICompositeElement:
			element._ensure_grouped_states(states, element.element_group.elements)


# Transform management.

func _set_global_transform(global_rect: Rect2) -> void:
	# Nothing changed, no need to propagate further.
	if anchor_point == global_rect.position && default_state.size == global_rect.size:
		element_group.notify_transform()
		return
	
	# Do some changes manually to avoid triggering transform_queued multiple times. Hacky,
	# but works!
	anchor_point = global_rect.position
	default_state.size = global_rect.size
	default_state._notify_properties_changed([ "size" ])
