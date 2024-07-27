###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name ElementEntry extends PanelContainer

signal entry_pressed()

@export var data: BaseUIElement = null:
	set = set_data

@onready var _element_icon: TextureRect = %Icon
@onready var _element_name: Label = %Name

var _hovering: bool = false
var _pressed: bool = false


func _ready() -> void:
	_update_entry()
	
	mouse_entered.connect(func() -> void:
		_hovering = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovering = false
		queue_redraw()
	)


func _draw() -> void:
	var available_rect := Rect2(Vector2.ZERO, size)
	
	var style_default := get_theme_stylebox("background")
	var style_hover := get_theme_stylebox("background_hover")
	var style_pressed := get_theme_stylebox("background_pressed")
	
	if _hovering:
		if _pressed:
			draw_style_box(style_pressed, available_rect)
		else:
			draw_style_box(style_hover, available_rect)
	else:
		draw_style_box(style_default, available_rect)
	
	if data && data.is_selected():
		var selected_style := get_theme_stylebox("panel_selected")
		
		draw_style_box(selected_style, available_rect)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = true
			accept_event()
			queue_redraw()
		
		elif not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = false
			accept_event()
			queue_redraw()
			
			entry_pressed.emit()


func set_data(value: BaseUIElement) -> void:
	if data == value:
		return
	
	if data:
		data.editor_selected.disconnect(queue_redraw)
		data.editor_deselected.disconnect(queue_redraw)
	
	data = value
	
	if data:
		data.editor_selected.connect(queue_redraw)
		data.editor_deselected.connect(queue_redraw)
	
	_update_entry()
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
