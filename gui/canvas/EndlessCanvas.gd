###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The endless canvas on which the entire project is laid out.
class_name EndlessCanvas extends Control

var _current_canvas: UICanvas = null

var _drawn_elements: Array[CanvasUIElement] = []
var _selected_elements: Array[BaseUIElement] = []

@onready var _element_container: Control = %Elements
@onready var _gizmos_container: CanvasGizmos = %Gizmos
@onready var _context_menu: PopupMenu = %ContextMenu


func _ready() -> void:
	_edit_current_canvas()
	
	if not Engine.is_editor_hint():
		Controller.canvas_changed.connect(_edit_current_canvas)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_try_select_element(mb.position)
		if mb.pressed && mb.button_index == MOUSE_BUTTON_RIGHT:
			_create_element(mb.position)


# Canvas management.

func _edit_current_canvas() -> void:
	if _current_canvas:
		_current_canvas.element_created.disconnect(_add_canvas_element)
	
	_current_canvas = Controller.get_current_canvas()
	
	if _current_canvas:
		_current_canvas.element_created.connect(_add_canvas_element)


# Element management.

func _create_element(at_position: Vector2) -> void:
	if not Controller.current_project || not _current_canvas:
		return
	
	_current_canvas.create_element(ElementType.ELEMENT_PANEL, at_position)


func _add_canvas_element(element: BaseUIElement) -> void:
	var canvas_element := CanvasUIElement.new()
	canvas_element.data = element
	
	_element_container.add_child(canvas_element)
	_drawn_elements.push_back(canvas_element)
	
	# Auto-select the added element.
	_selected_elements.clear()
	_selected_elements.push_back(element)
	_update_gizmos()


func _try_select_element(at_position: Vector2) -> void:
	# TODO: Add support for multiple selection modes, adding and subtracting elements from the selection.
	# TODO: Add support for multi-element selections.
	_selected_elements.clear()
	
	for element in _drawn_elements:
		if not element.is_visible_on_screen() || not element.data:
			return
		
		var element_rect := element.data.rect.get_boundary_rect()
		if element_rect.has_point(at_position):
			_selected_elements.push_back(element.data)
			break # For now, select the first match only.
	
	_update_gizmos()


# Gizmo management.

func _update_gizmos() -> void:
	_gizmos_container.clear_gizmos()
	
	if _selected_elements.size() == 0:
		return
	
	# TODO: Support gizmos for multiple selected elements.
	if _selected_elements.size() > 1:
		return
	
	var selected_element := _selected_elements[0]
	var active_gizmos := selected_element.get_gizmos()
	_gizmos_container.set_gizmos(active_gizmos)
