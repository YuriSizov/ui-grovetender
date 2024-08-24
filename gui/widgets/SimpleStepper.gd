###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

@tool
class_name SimpleStepper extends SpinBox


func _ready() -> void:
	_update_theme()


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
