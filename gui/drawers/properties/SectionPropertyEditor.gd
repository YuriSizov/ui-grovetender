###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name SectionPropertyEditor extends PropertyEditor

signal section_toggled()

const CHECKBOX_ICONS := [
	preload("res://assets/ui/checkbox-checked.png"),
	preload("res://assets/ui/checkbox-unchecked.png")
]

var icon: Texture2D = null:
	set = set_icon

@onready var _layout_container: HBoxContainer = %Layout
@onready var _section_icon: TextureRect = %SectionIcon
@onready var _section_name: Label = %SectionName
@onready var _section_toggle: TextureRect = %SectionToggle
@onready var _revert_button: PropertyRevertButton = %RevertButton

var _hovered: bool = false
var _pressed: bool = false


static func create(element: UIElement, element_data: BaseElementData) -> SectionPropertyEditor:
	return _create(element, element_data, preload("res://gui/drawers/properties/SectionPropertyEditor.tscn"))


func _init() -> void:
	super()
	theme_type_variation = &"SectionPropertyEditor"
	
	mouse_entered.connect(func() -> void:
		_hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovered = false
		_pressed = false
		queue_redraw()
	)


func _ready() -> void:
	super()
	
	_update_section_icon()
	_update_section_name()
	_update_section_toggle()
	
	property_connected.connect(func() -> void:
		_update_section_icon()
		_update_section_name()
		_update_section_toggle()
	)
	property_changed.connect(func() -> void:
		_update_section_toggle()
	)
	
	_revert_button.pressed.connect(revert_property_value)
	_revert_button.pressed.connect(section_toggled.emit)


func _update_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.add_theme_constant_override("separation", get_theme_constant("base_separation"))
	
	_section_name.begin_bulk_theme_override()
	_section_name.add_theme_font_override("font", get_theme_font("font"))
	_section_name.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	_section_name.add_theme_color_override("font_color", get_theme_color("font_color"))
	_section_name.add_theme_color_override("font_outline_color", get_theme_color("font_outline_color"))
	_section_name.add_theme_color_override("font_shadow_color", get_theme_color("font_shadow_color"))
	_section_name.add_theme_constant_override("outline_size", get_theme_constant("font_outline_size"))
	_section_name.add_theme_constant_override("shadow_offset_x", get_theme_constant("font_shadow_offset_x"))
	_section_name.add_theme_constant_override("shadow_offset_y", get_theme_constant("font_shadow_offset_y"))
	_section_name.end_bulk_theme_override()


func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	_layout_container.remove_theme_constant_override("separation")
	
	_section_name.begin_bulk_theme_override()
	_section_name.remove_theme_font_override("font")
	_section_name.remove_theme_font_size_override("font_size")
	_section_name.remove_theme_color_override("font_color")
	_section_name.remove_theme_color_override("font_outline_color")
	_section_name.remove_theme_color_override("font_shadow_color")
	_section_name.remove_theme_constant_override("outline_size")
	_section_name.remove_theme_constant_override("shadow_offset_x")
	_section_name.remove_theme_constant_override("shadow_offset_y")
	_section_name.end_bulk_theme_override()


func _draw() -> void:
	var background_style := get_theme_stylebox("panel")
	if not _prop_name.is_empty() && _hovered:
		if _pressed:
			background_style = get_theme_stylebox("panel_pressed")
		else:
			background_style = get_theme_stylebox("panel_hover")
	
	draw_style_box(background_style, Rect2(Vector2.ZERO, size))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = true
			accept_event()
			queue_redraw()
		
		elif _pressed && not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = false
			accept_event()
			queue_redraw()
			
			_toggle_section()


# Properties.

func set_icon(value: Texture2D) -> void:
	if icon == value:
		return
	icon = value
	
	_update_section_icon()


func _update_section_icon() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	_section_icon.texture = icon


func _update_section_name() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	_section_name.text = _get_editor_label()


func _update_section_toggle() -> void:
	if not is_inside_tree() || Engine.is_editor_hint():
		return
	
	if not has_property():
		_revert_button.visible = false
		_section_toggle.visible = false
		return
	
	_revert_button.visible = true
	_section_toggle.visible = true
	_section_toggle.texture = CHECKBOX_ICONS[0] if get_property_value() else CHECKBOX_ICONS[1]


func _toggle_section() -> void:
	if not has_property() || not _prop_setter.is_valid():
		return
	
	var current_value: bool = get_property_value()
	set_property_value(not current_value)
	
	section_toggled.emit()


func is_toggled() -> bool:
	if not has_property():
		return true
	
	return get_property_value()


func connect_property_to_section(property_editor: PropertyEditor) -> void:
	if not has_property():
		return # Nothing to do if this is not a togglable section.
	
	property_editor.set_visibility_condition(func() -> bool:
		return get_property_value()
	)
