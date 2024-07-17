###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## A base class for all types of UI elements. Encapsulates shared logic and universal data members.
class_name BaseUIElement extends Resource

signal rect_changed()

## The instance ID of the control. Runtime only.
var control_id: int = 0

@export var rect: UIRect = UIRect.new()


func _init() -> void:
	rect.changed.connect(rect_changed.emit) # Pass through the signal.


# Metadata.

func get_control() -> CanvasUIElement:
	if not is_instance_id_valid(control_id):
		return null
	
	return instance_from_id(control_id)


# Position and sizing.

## Returns the area for this UI element, relative to the control node.
func get_rect_in_control() -> Rect2:
	var control := get_control()
	if not control:
		return Rect2()
	
	var owner_rect := control.get_rect()
	var local_position := rect.get_boundary_rect()
	local_position.position -= owner_rect.position
	
	return local_position


# Implementation.

## Renders this UI element. Extending classes override this method.
func render() -> void:
	pass


## Initializes and returns a set of gizmos for editing this UI element. Extending classes override this method.
func get_gizmos() -> Array[BaseGizmo]:
	var gizmos: Array[BaseGizmo] = []
	
	return gizmos
