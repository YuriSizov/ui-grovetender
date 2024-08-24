###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name SimpleStepper extends SpinBox


func _ready() -> void:
	_update_theme()
	
	# FIXME: When value changes not through numeric input, but via the arrows or the mouse wheel
	# and the length of the resulting string increases, the selection is not updated.
	
	# TODO: Maybe keep a simplified version for copy/paste operations?
	get_line_edit().context_menu_enabled = false
	get_line_edit().gui_input.connect(_lineedit_gui_input)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_theme()
	
	# This is so hacky, but it allows us to use one theme definition for all elements of a complex
	# scene, with in-editor preview, without polluting saved scenes.
	elif what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear_theme()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_update_theme()


## Called when it's a proper time to update visuals according to theme changes.
func _update_theme() -> void:
	if not is_node_ready():
		return
	
	get_line_edit().add_theme_stylebox_override("normal", get_theme_stylebox("lineedit_panel"))
	# Allows to set a more flexible minimum width via control properties.
	get_line_edit().add_theme_constant_override("minimum_character_width", 1)


## Called when the theme overrides need to be reset, e.g. before the scene is saved.
func _clear_theme() -> void:
	if not is_node_ready():
		return
	
	get_line_edit().remove_theme_stylebox_override("normal")
	get_line_edit().remove_theme_constant_override("minimum_character_width")


func _draw() -> void:
	if not is_visible_in_tree():
		return
	
	var panel_style := get_theme_stylebox("stepper_panel")
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	
	# Draw the default icon in its default place, because by default it is drawn before
	# our panel (by native code), so the panel obscures it. Hacky, but fixes the looks.
	var updown_icon := get_theme_icon("updown")
	var updown_size := updown_icon.get_size()
	var updown_position := Vector2(size.x - updown_size.x, (size.y - updown_size.y) / 2.0)
	draw_texture_rect(updown_icon, Rect2(updown_position, updown_size), false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		# When attempting to use the mouse wheel over the stepper, make it active.
		if mb.pressed && (mb.button_index == MOUSE_BUTTON_WHEEL_DOWN || mb.button_index == MOUSE_BUTTON_WHEEL_UP):
			if not get_line_edit().has_focus():
				get_line_edit().grab_focus()
				accept_event()


func _lineedit_gui_input(event: InputEvent) -> void:
	# Spinboxes have hidden behavior where right-clicking sets the value to min/max.
	# Normally it's activated only by arrows, but if the context menu on the line edit is
	# disabled, right clicks pass to the parent spinbox and it consumes it no mattere where
	# the click lands. This is pretty annoying, and doubtfully expected.
	
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
