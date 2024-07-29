###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ElementEntry extends PanelContainer

signal entry_pressed()
signal entry_released()

const VISIBILITY_ICON_CHECKED := preload("res://assets/ui/visibility-handle-checked.png")
const VISIBILITY_ICON_UNCHECKED := preload("res://assets/ui/visibility-handle-unchecked.png")

@export var data: BaseUIElement = null:
	set = set_data

@onready var _element_icon: TextureRect = %Icon
@onready var _element_name: Label = %Name
@onready var _layout_container: Control = $Layout
@onready var _sorting_handle: TextureRect = %SortingHandle
@onready var _visibility_handle: TextureRect = %VisibilityHandle

var _hovering: bool = false
var _pressed: bool = false
var _dragging: bool = false

enum InteractedArea {
	NONE,
	WHOLE_ENTRY,
	SORTING_HANDLE,
	VISIBILITY_HANDLE,
}
var _interacted_area: InteractedArea = InteractedArea.NONE


func _ready() -> void:
	_update_entry()
	_update_visibility_icon()
	
	mouse_entered.connect(_handle_hovered)
	mouse_exited.connect(_handle_unhovered)


func _draw() -> void:
	var available_rect := Rect2(Vector2.ZERO, size)
	
	if _dragging:
		var background_style_dragging := get_theme_stylebox("background_dragging")
		draw_style_box(background_style_dragging, available_rect)
		return # Leave empty space when dragging.
	
	# Draw background.
	
	var background_style_default := get_theme_stylebox("background")
	var background_style_hover := get_theme_stylebox("background_hover")
	var background_style_pressed := get_theme_stylebox("background_pressed")
	
	var background_style := background_style_default
	if _hovering && _interacted_area == InteractedArea.WHOLE_ENTRY:
		if _pressed:
			background_style = background_style_pressed
		else:
			background_style = background_style_hover
	
	draw_style_box(background_style, available_rect)
	
	# Draw selected cover layer.
	
	if data && data.is_selected():
		var selected_style := get_theme_stylebox("panel_selected")
		
		draw_style_box(selected_style, available_rect)
	
	# Draw extra styles when interacting with handles.
	
	var handle_style_hover := get_theme_stylebox("handle_hover")
	var handle_style_pressed := get_theme_stylebox("handle_pressed")
	
	if _hovering:
		var handle_style: StyleBoxFlat = null
		var handle_rect := Rect2()
		
		if _pressed:
			handle_style = handle_style_pressed
		else:
			handle_style = handle_style_hover
		
		match _interacted_area:
			InteractedArea.SORTING_HANDLE:
				handle_rect = _sorting_handle.get_global_rect()
			
			InteractedArea.VISIBILITY_HANDLE:
				handle_rect = _visibility_handle.get_global_rect()
		
		if handle_style && handle_rect.size.x > 0 && handle_rect.size.y > 0:
			handle_rect.position -= global_position
			draw_style_box(handle_style, handle_rect)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_pressed()
		
		elif not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_released()
	
	elif _hovering && event is InputEventMouseMotion:
		_handle_hovered()


# Interactions.

func _get_handle_trigger_rect(handle: Control) -> Rect2:
	var handle_rect := handle.get_global_rect()
	var handle_size_diff := (size.y - handle_rect.size.y) / 2.0
	
	return handle_rect.grow(handle_size_diff)


func _handle_hovered() -> void:
	_hovering = true
	
	var mouse_position := get_global_mouse_position()
	
	if _get_handle_trigger_rect(_sorting_handle).has_point(mouse_position):
		_interacted_area = InteractedArea.SORTING_HANDLE
	
	elif _get_handle_trigger_rect(_visibility_handle).has_point(mouse_position):
		_interacted_area = InteractedArea.VISIBILITY_HANDLE
	
	else:
		_interacted_area = InteractedArea.WHOLE_ENTRY
	
	queue_redraw()


func _handle_unhovered() -> void:
	if not _hovering:
		return
	
	_hovering = false
	_pressed = false
	_interacted_area = InteractedArea.NONE
	
	queue_redraw()


func _handle_pressed() -> void:
	_pressed = true
	entry_pressed.emit()
	
	accept_event()
	queue_redraw()


func _handle_released() -> void:
	if not _pressed:
		return
	
	match _interacted_area:
		InteractedArea.SORTING_HANDLE:
			pass
		
		InteractedArea.VISIBILITY_HANDLE:
			if data:
				data.visible = not data.visible
		
		_:
			entry_released.emit()
	
	_pressed = false
	
	accept_event()
	queue_redraw()


func is_sorting_drag(from_position: Vector2) -> bool:
	var sorting_rect := _get_handle_trigger_rect(_sorting_handle)
	sorting_rect.position -= global_position
	
	if sorting_rect.has_point(from_position):
		return true
	return false


func set_dragging(value: bool) -> void:
	if _dragging == value:
		return
	
	_dragging = value
	_layout_container.modulate.a = 0.0 if _dragging else 1.0
	
	queue_redraw()


# Data and state.

func set_data(value: BaseUIElement) -> void:
	if data == value:
		return
	
	if data:
		data.editor_selected.disconnect(queue_redraw)
		data.editor_deselected.disconnect(queue_redraw)
		data.visibility_changed.disconnect(_update_visibility_icon)
	
	data = value
	
	if data:
		data.editor_selected.connect(queue_redraw)
		data.editor_deselected.connect(queue_redraw)
		data.visibility_changed.connect(_update_visibility_icon)
	
	_update_entry()
	_update_visibility_icon()
	queue_redraw()


func _update_entry() -> void:
	if not is_inside_tree():
		return
	
	if not data:
		_element_name.text = "Nothing"
		_element_icon.texture = ElementType.get_element_icon(ElementType.ELEMENT_EMPTY)
		return
	
	_element_name.text = data.element_name
	
	if data is PanelElement:
		_element_icon.texture = ElementType.get_element_icon(ElementType.ELEMENT_PANEL)
	elif data is IconElement:
		_element_icon.texture = ElementType.get_element_icon(ElementType.ELEMENT_ICON)
	elif data is TextElement:
		_element_icon.texture = ElementType.get_element_icon(ElementType.ELEMENT_TEXT)
	else:
		_element_icon.texture = ElementType.get_element_icon(ElementType.ELEMENT_EMPTY)


func _update_visibility_icon() -> void:
	if not is_inside_tree():
		return
	
	if not data:
		_visibility_handle.visible = false
		return
	
	_visibility_handle.visible = true
	if data.visible:
		_visibility_handle.texture = VISIBILITY_ICON_CHECKED
	else:
		_visibility_handle.texture = VISIBILITY_ICON_UNCHECKED
