###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The state transition sub-object that contains data related to enter
## and exit transitions when a stateful element data object is (de)activated.
## It is owned by a BaseElementData instance.
class_name UITransition extends Resource

signal transition_changed()

## The duration of this transition.
@export var duration: float = 0.0
## The type of curve for this transition.
@export var curve: Tween.TransitionType = Tween.TRANS_LINEAR
## The easing type of this transition.
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT


func set_duration(value: float) -> void:
	if duration == value:
		return
	
	duration = value
	transition_changed.emit()


func set_curve(value: Tween.TransitionType) -> void:
	if curve == value:
		return
	
	curve = value
	transition_changed.emit()


func set_easing(value: Tween.EaseType) -> void:
	if easing == value:
		return
	
	easing = value
	transition_changed.emit()
