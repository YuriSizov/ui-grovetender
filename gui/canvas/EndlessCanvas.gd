###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The endless canvas on which the entire project is laid out.
class_name EndlessCanvas extends Control

var _hotspots: Array[CanvasHotspot] = []
var _selected_items: Array[BaseUIItem] = []

@onready var _hotspot_container: Control = %Hotspots
@onready var _gizmos_container: CanvasGizmos = %Gizmos
@onready var _context_menu: PopupMenu = %ContextMenu


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		
		if mb.pressed && mb.button_index == MOUSE_BUTTON_LEFT:
			_create_item(mb.position)
		if mb.pressed && mb.button_index == MOUSE_BUTTON_RIGHT:
			_select_item(mb.position)


# Item management.

func _create_item(at_position: Vector2) -> void:
	var hotspot_data := _find_or_create_hotspot(at_position)
	var item := ButtonItem.new()
	item.position = at_position
	
	hotspot_data.assign_item(item)


func _select_item(at_position: Vector2) -> void:
	# TODO: Support multiple selection modes, adding and subtracting items from the selection.
	_selected_items.clear()
	
	var hotspot_data := _find_hotspot(at_position)
	if hotspot_data:
		for ui_item in hotspot_data.items:
			if ui_item.get_rect().has_point(at_position):
				_selected_items.push_back(ui_item)
				break # For now, select the first match only.
	
	_update_gizmos()


# Hotspot management.

func _find_hotspot(at_position: Vector2) -> Hotspot:
	for hotspot_control in _hotspots:
		if not hotspot_control.is_visible_on_screen():
			continue
		
		if hotspot_control.get_rect().has_point(at_position):
			return hotspot_control.data
	
	return null


func _find_or_create_hotspot(at_position: Vector2) -> Hotspot:
	var hotspot_data := _find_hotspot(at_position)
	if hotspot_data:
		return hotspot_data
	
	hotspot_data = Controller.current_project.create_hotspot(at_position)
	
	var hotspot_control := CanvasHotspot.new()
	hotspot_control.data = hotspot_data
	
	_hotspot_container.add_child(hotspot_control)
	_hotspots.push_back(hotspot_control)
	
	return hotspot_data


# Gizmo management.

func _update_gizmos() -> void:
	_gizmos_container.clear_gizmos()
	
	if _selected_items.size() == 0:
		return
	
	# TODO: Support gizmos for multiple selected items.
	if _selected_items.size() > 1:
		return
	
	var selected_item := _selected_items[0]
	var active_gizmos := selected_item.get_gizmos()
	
	_gizmos_container.set_gizmos(active_gizmos)
