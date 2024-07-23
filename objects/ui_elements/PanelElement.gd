###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A panel UI element, which can be used as a background or foreground plane element. Configurable with
## background and border properties, or with a 9-patch texture.
# TODO: Implement support for 9-patch textures.
class_name PanelElement extends BaseUIElement

enum CornerStyle {
	RIGHT_ANGLE,
	CURVED,
}

const CORNER_CURVED_BASE_DETAIL := 4
const SHADOW_BASE_CURVED_RADIUS := 8

## The flag that enables background drawing.
@export var draw_background: bool = true
## The color of the background.
@export var background_color: Color = Color.WHITE

## The flag that enables border drawing.
@export var draw_border: bool = false
## The color of the border.
@export var border_color: Color = Color.BLACK
## The width/size of the border.
@export var border_width: Vector4 = Vector4(2.0, 2.0, 2.0, 2.0)

## The style of each corner of this panel.
@export var corner_styles: PackedInt32Array = [ CornerStyle.RIGHT_ANGLE, CornerStyle.RIGHT_ANGLE, CornerStyle.RIGHT_ANGLE, CornerStyle.RIGHT_ANGLE ]
## The radius for the curved corner style.
@export var corner_curved_radius: Vector4 = Vector4(4.0, 4.0, 4.0, 4.0)
## The level of detail for the curved corner style.
@export var corner_curved_detail: int = 4

## The flag that enables shadow drawing.
@export var draw_shadow: bool = false
## The color of the shadow.
@export var shadow_color: Color = Color(0, 0, 0, 0.4)
## The offset of the shadow from the panel position.
@export var shadow_offset: Vector2 = Vector2(2.0, 2.0)
## The size of the shadow, expanding upon the size of the base panel.
@export var shadow_size: Vector2 = Vector2(8.0, 8.0)

# Runtime properties and rendering data.

var _base_style: StyleBoxFlat = StyleBoxFlat.new()
var _border_style: StyleBoxFlat = StyleBoxFlat.new()
var _shadow_style: StyleBoxFlat = StyleBoxFlat.new()

# Gizmo references for active updates.

var _border_gizmo: BorderStyleGizmo = null


func _init() -> void:
	super()
	
	_update_base_style()
	_update_border_style()
	_update_shadow_style()


# Implementation.

func draw() -> void:
	var canvas_control := get_control()
	var element_rect := get_rect_in_control()
	
	if draw_shadow:
		var shadow_rect = element_rect
		shadow_rect.position += shadow_offset
		canvas_control.draw_style_box(_shadow_style, shadow_rect)
	
	if draw_background:
		canvas_control.draw_style_box(_base_style, element_rect)
	
	if draw_border:
		canvas_control.draw_style_box(_border_style, element_rect)


func get_gizmos(editing_mode: EndlessCanvas.EditingMode) -> Array[BaseGizmo]:
	_clear_gizmo_references()
	var gizmos := super(editing_mode)
	
	if editing_mode == EndlessCanvas.EditingMode.STYLING_TOOLS:
		_border_gizmo = BorderStyleGizmo.new(self)
		_border_gizmo.visible = draw_border
		gizmos.push_back(_border_gizmo)
		_border_gizmo.width_changed.connect(_set_border_width)
		_border_gizmo.width_all_changed.connect(_set_border_all_width)
		
		var corner_gizmo := CornerStyleGizmo.new(self)
		corner_gizmo.set_curved_radius_property("corner_curved_radius")
		gizmos.push_back(corner_gizmo)
		corner_gizmo.curved_radius_changed.connect(_set_corner_curve_radius)
		corner_gizmo.curved_radius_all_changed.connect(_set_corner_curve_all_radius)
	
	return gizmos


func get_editable_properties(editing_mode: EndlessCanvas.EditingMode) -> Array[PropertyEditor]:
	var properties := super(editing_mode)
	
	if editing_mode == EndlessCanvas.EditingMode.STYLING_TOOLS:
		var background_property := TogglePropertyEditor.new(self, "draw_background", _toggle_draw_background)
		background_property.label = "Background"
		properties.push_back(background_property)
		properties.push_back(ColorPropertyEditor.new(self, "background_color", _set_background_color))
		
		var border_property := TogglePropertyEditor.new(self, "draw_border", _toggle_draw_border)
		border_property.label = "Border"
		properties.push_back(border_property)
		properties.push_back(ColorPropertyEditor.new(self, "border_color", _set_border_color))
		
		var shadow_property := TogglePropertyEditor.new(self, "draw_shadow", _toggle_draw_shadow)
		shadow_property.label = "Shadow"
		properties.push_back(shadow_property)
		properties.push_back(ColorPropertyEditor.new(self, "shadow_color", _set_shadow_color))
	
	return properties


# Helpers.

func _clear_gizmo_references() -> void:
	if is_instance_valid(_border_gizmo):
		_border_gizmo.queue_free()
	
	_border_gizmo = null


# Properties.

func _update_base_style() -> void:
	_base_style.bg_color = background_color
	
	_base_style.corner_detail = corner_curved_detail
	_base_style.corner_radius_top_left     = int(corner_curved_radius[0])
	_base_style.corner_radius_top_right    = int(corner_curved_radius[1])
	_base_style.corner_radius_bottom_right = int(corner_curved_radius[2])
	_base_style.corner_radius_bottom_left  = int(corner_curved_radius[3])
	
	_base_style.expand_margin_left   = 0 if border_width[0] < 0 else int(border_width[0])
	_base_style.expand_margin_top    = 0 if border_width[1] < 0 else int(border_width[1])
	_base_style.expand_margin_right  = 0 if border_width[2] < 0 else int(border_width[2])
	_base_style.expand_margin_bottom = 0 if border_width[3] < 0 else int(border_width[3])


func _toggle_draw_background(value: bool) -> void:
	if draw_background == value:
		return
		
	draw_background = value
	properties_changed.emit()


func _set_background_color(value: Color) -> void:
	if background_color == value:
		return
	background_color = value
	
	_update_base_style()
	properties_changed.emit()


func _update_border_style() -> void:
	_border_style.bg_color = Color(0, 0, 0, 0)
	_border_style.border_color = border_color
	
	_border_style.corner_detail = corner_curved_detail
	_border_style.corner_radius_top_left     = int(corner_curved_radius[0])
	_border_style.corner_radius_top_right    = int(corner_curved_radius[1])
	_border_style.corner_radius_bottom_right = int(corner_curved_radius[2])
	_border_style.corner_radius_bottom_left  = int(corner_curved_radius[3])
	
	_border_style.expand_margin_left   = 0 if border_width[0] < 0 else int(border_width[0])
	_border_style.expand_margin_top    = 0 if border_width[1] < 0 else int(border_width[1])
	_border_style.expand_margin_right  = 0 if border_width[2] < 0 else int(border_width[2])
	_border_style.expand_margin_bottom = 0 if border_width[3] < 0 else int(border_width[3])
	
	_border_style.border_width_left   = int(abs(border_width[0]))
	_border_style.border_width_top    = int(abs(border_width[1]))
	_border_style.border_width_right  = int(abs(border_width[2]))
	_border_style.border_width_bottom = int(abs(border_width[3]))


func _toggle_draw_border(value: bool) -> void:
	if draw_border == value:
		return
		
	draw_border = value
	if is_instance_valid(_border_gizmo):
		_border_gizmo.visible = draw_border
	
	properties_changed.emit()


func _set_border_color(value: Color) -> void:
	if border_color == value:
		return
	border_color = value
	
	_update_border_style()
	properties_changed.emit()


func _set_border_width(side: Side, delta: float) -> void:
	if not draw_border:
		return
	
	if side == SIDE_LEFT || side == SIDE_TOP:
		delta = -delta
	border_width[side] += delta
	
	_update_base_style()
	_update_border_style()
	_update_shadow_style()
	properties_changed.emit()


func _set_border_all_width(side: Side, delta: float) -> void:
	if not draw_border:
		return
	
	if side == SIDE_LEFT || side == SIDE_TOP:
		delta = -delta
	var new_value := border_width[side] + delta
	
	border_width[0] = new_value
	border_width[1] = new_value
	border_width[2] = new_value
	border_width[3] = new_value
	
	_update_base_style()
	_update_border_style()
	_update_shadow_style()
	properties_changed.emit()


func _set_corner_curve_radius(corner: Corner, delta: float) -> void:
	# TODO: Sanitize values which result in artifacts and bugs.
	var new_value := maxf(0.0, corner_curved_radius[corner] + delta)
	
	corner_curved_radius[corner] = new_value
	_update_corner_curved_detail()
	
	_update_base_style()
	_update_border_style()
	_update_shadow_style()
	properties_changed.emit()


func _set_corner_curve_all_radius(corner: Corner, delta: float) -> void:
	# TODO: Sanitize values which result in artifacts and bugs.
	var new_value := maxf(0.0, corner_curved_radius[corner] + delta)
	
	corner_curved_radius[0] = new_value
	corner_curved_radius[1] = new_value
	corner_curved_radius[2] = new_value
	corner_curved_radius[3] = new_value
	_update_corner_curved_detail()
	
	_update_base_style()
	_update_border_style()
	_update_shadow_style()
	properties_changed.emit()


func _update_corner_curved_detail() -> void:
	var biggest_radius := 0.0
	
	for i in 4:
		if corner_curved_radius[i] > biggest_radius:
			biggest_radius = corner_curved_radius[i]
	
	corner_curved_detail = max(CORNER_CURVED_BASE_DETAIL, int(biggest_radius / 2.0))


func _update_shadow_style() -> void:
	_shadow_style.bg_color = shadow_color
	_shadow_style.border_color = Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.0)
	_shadow_style.border_blend = true
	
	_shadow_style.corner_detail = corner_curved_detail
	# TODO: This value should be affected by the shadow size.
	_shadow_style.corner_radius_top_left     = SHADOW_BASE_CURVED_RADIUS + int(corner_curved_radius[0])
	_shadow_style.corner_radius_top_right    = SHADOW_BASE_CURVED_RADIUS + int(corner_curved_radius[1])
	_shadow_style.corner_radius_bottom_right = SHADOW_BASE_CURVED_RADIUS + int(corner_curved_radius[2])
	_shadow_style.corner_radius_bottom_left  = SHADOW_BASE_CURVED_RADIUS + int(corner_curved_radius[3])
	
	_shadow_style.expand_margin_left   = int(shadow_size.x) + _border_style.expand_margin_left
	_shadow_style.expand_margin_right  = int(shadow_size.x) + _border_style.expand_margin_right
	_shadow_style.expand_margin_top    = int(shadow_size.y) + _border_style.expand_margin_top
	_shadow_style.expand_margin_bottom = int(shadow_size.y) + _border_style.expand_margin_bottom
	
	_shadow_style.border_width_left   = int(shadow_size.x)
	_shadow_style.border_width_right  = int(shadow_size.x)
	_shadow_style.border_width_top    = int(shadow_size.y)
	_shadow_style.border_width_bottom = int(shadow_size.y)


func _toggle_draw_shadow(value: bool) -> void:
	if draw_shadow == value:
		return
		
	draw_shadow = value
	properties_changed.emit()


func _set_shadow_color(value: Color) -> void:
	if shadow_color == value:
		return
	shadow_color = value
	
	_update_shadow_style()
	properties_changed.emit()
