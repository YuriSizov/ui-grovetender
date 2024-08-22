###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name CanvasContextMenu extends Control

var _current_options: Array[Option] = []
var _option_text_buffers: Array[TextLine] = []
var _option_rects: Array[Rect2] = []
var _option_shortcut_buffers: Array[TextLine] = []

var _hovering: bool = false
var _hovered_option: int = -1
var _pressed: bool = false


func _init() -> void:
	theme_type_variation = &"CanvasContextMenu"
	
	mouse_entered.connect(func() -> void:
		_hovering = true
		_hovered_option = -1
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hovering = false
		_hovered_option = -1
		queue_redraw()
	)


func _draw() -> void:
	var target_color := get_theme_color("target_color")
	var target_size := get_theme_constant("target_size")
	
	var option_panel_default := get_theme_stylebox("option_panel")
	var option_panel_hover := get_theme_stylebox("option_panel_hover")
	var option_panel_pressed := get_theme_stylebox("option_panel_pressed")
	
	var option_icon_size := get_theme_constant("option_icon_size")
	var option_icon_separation := get_theme_constant("option_icon_separation")
	
	var option_font_color := get_theme_color("option_font_color")
	var option_font_shadow_color := get_theme_color("option_font_shadow_color")
	var option_font_shadow_offset := Vector2(
		get_theme_constant("option_font_shadow_offset_x"),
		get_theme_constant("option_font_shadow_offset_y")
	)
	
	var shortcut_label_style := get_theme_stylebox("normal", "ShortcutLabel")
	
	var shortcut_label_size := Vector2(
		get_theme_constant("label_size", "ShortcutLabel"),
		get_theme_constant("label_size", "ShortcutLabel")
	)
	var shortcut_label_color := get_theme_color("font_color", "ShortcutLabel")
	
	var shortcut_label_shadow_color := get_theme_color("font_shadow_color", "ShortcutLabel")
	var shortcut_label_shadow_offset := Vector2(
		get_theme_constant("shadow_offset_x", "ShortcutLabel"),
		get_theme_constant("shadow_offset_y", "ShortcutLabel")
	)
	
	# Draw the target/click point for the reference.
	draw_circle(Vector2.ZERO, target_size, target_color, true, -1, true)
	
	# Draw all options.
	
	for i in _current_options.size():
		var option := _current_options[i]
		var option_label := _option_text_buffers[i]
		var option_rect := _option_rects[i]
		
		# Draw the background.
		var option_style := option_panel_default
		if _hovering && _hovered_option == i:
			if _pressed:
				option_style = option_panel_pressed
			else:
				option_style = option_panel_hover
		
		draw_style_box(option_style, option_rect)
		
		# Draw the content.
		
		var content_offset := option_style.get_offset()
		
		# Draw the icon, if present.
		
		if option.icon:
			var icon_position := option_rect.position + content_offset
			var icon_size := Vector2(option_icon_size, option_icon_size)
			
			draw_texture_rect(option.icon, Rect2(icon_position, icon_size), false)
			
			content_offset.x += icon_size.x + option_icon_separation
		
		# Draw the label.
		
		var label_position := option_rect.position + content_offset
		
		DrawingUtil.draw_text_buffer(
			get_canvas_item(), option_label, label_position, option_font_color,
			option_font_shadow_offset, option_font_shadow_color
		)
		
		# Draw the shortcut label on top.
		
		var shortcut_position := option_rect.end - shortcut_label_size / 2.0
		draw_style_box(shortcut_label_style, Rect2(shortcut_position, shortcut_label_size))
		
		var shortcut_label := _option_shortcut_buffers[i]
		var shortcut_label_position := shortcut_position + (shortcut_label_size - shortcut_label.get_size()) / 2.0
		
		DrawingUtil.draw_text_buffer(
			get_canvas_item(), shortcut_label, shortcut_label_position, shortcut_label_color,
			shortcut_label_shadow_offset, shortcut_label_shadow_color
		)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if not _hovering && mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			clear_options()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			if _hovering && _hovered_option >= 0:
				_pressed = true
				accept_event()
				queue_redraw()
		
		elif not mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_option_pressed()
			accept_event()
			queue_redraw()
	
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var mouse_position := mm.position
		
		for i in _option_rects.size():
			var option_rect := _option_rects[i]
			
			if option_rect.has_point(mouse_position):
				_hovering = true
				_hovered_option = i
				queue_redraw()
				break


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ik := event as InputEventKey
		
		if not ik.pressed && ik.keycode >= KEY_1 && ik.keycode <= KEY_9:
			var option_index := ik.keycode - KEY_1
			
			if _handle_option_activated(option_index):
				accept_event()
				queue_redraw()


func _has_point(point: Vector2) -> bool:
	for option_rect in _option_rects:
		if option_rect.has_point(point):
			return true
	
	return false


# Option management.

func clear_options() -> void:
	_option_text_buffers.clear()
	_option_rects.clear()
	_option_shortcut_buffers.clear()
	_current_options.clear()
	
	_hovering = false
	_hovered_option = -1
	_pressed = false
	
	hide()


func show_options(options: Array[Option], at_position: Vector2) -> void:
	if options.is_empty():
		clear_options()
		return
	
	_option_text_buffers.clear()
	_option_rects.clear()
	_option_shortcut_buffers.clear()
	_current_options = options
	
	_update_option_sizes()
	
	position = at_position
	show()


func _update_option_sizes() -> void:
	var option_panel := get_theme_stylebox("option_panel")
	var option_separation := get_theme_constant("option_separation")
	var option_pushback := get_theme_constant("option_pushback")
	
	var option_icon_size := get_theme_constant("option_icon_size")
	var option_icon_separation := get_theme_constant("option_icon_separation")
	
	var label_font := get_theme_font("option_font")
	var label_font_size := get_theme_font_size("option_font_size")
	
	var shortcut_label_font := get_theme_font("font", "ShortcutLabel")
	var shortcut_label_font_size := get_theme_font_size("font_size", "ShortcutLabel")
	
	var minimum_size := Vector2(
		option_panel.content_margin_left + option_panel.content_margin_right,
		option_panel.content_margin_top + option_panel.content_margin_bottom
	)
	var height_accumulation := 0.0
	
	for i in _current_options.size():
		var option := _current_options[i]
		var option_size := minimum_size
		if i > 0:
			height_accumulation += option_separation
		
		# Create text buffers.
		var text_buffer := TextLine.new()
		text_buffer.add_string(option.label, label_font, label_font_size)
		_option_text_buffers.push_back(text_buffer)
		
		option_size += text_buffer.get_size()
		
		if option.icon:
			option_size.x += option_icon_size + option_icon_separation
		
		# Create position and size information.
		var rect := Rect2()
		rect.size = option_size
		rect.position = Vector2(0.0, height_accumulation)
		_option_rects.push_back(rect)
		
		height_accumulation += rect.size.y
		
		# Create text buffers for the shortcut._add_constant_central_force
		var shortcut_buffer := TextLine.new()
		shortcut_buffer.add_string("%d" % [ i + 1 ], shortcut_label_font, shortcut_label_font_size)
		_option_shortcut_buffers.push_back(shortcut_buffer)
	
	# Update positions to center items around the target point in a slight arc.
	# TODO: Do a proper arc instead of this linear offset.
	# This also only works well for a small number of options; consider doing a full circle based on the number of options?
	var center_index := _current_options.size() / 2.0 - 0.5
	for i in _option_rects.size():
		var rect = _option_rects[i]
		
		var pushback_factor := 1.0
		var distance_to_center := absf(center_index - i)
		if distance_to_center < 1.0: # Everything close to center must be fully pushed back.
			pushback_factor = 1.0
		else:
			pushback_factor = (center_index - distance_to_center) / center_index
		
		rect.position.x += option_pushback * pushback_factor
		rect.position.y -= height_accumulation / 2.0
		
		_option_rects[i] = rect


func _handle_option_pressed() -> void:
	if not _hovering || _hovered_option < 0:
		return
	
	var option := _current_options[_hovered_option]
	if option.action.is_valid():
		option.action.call()
	clear_options()


func _handle_option_activated(option_index: int) -> bool:
	if option_index < 0 || option_index >= _current_options.size():
		return false
	
	var option := _current_options[option_index]
	if option.action.is_valid():
		option.action.call()
	clear_options()
	
	return true


class Option:
	var label: String = ""
	var icon: Texture2D = null
	var action: Callable = Callable()
