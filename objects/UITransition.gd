###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The state transition sub-object that contains data related to enter
## and exit transitions when a stateful element data object is (de)activated.
## It is owned by a BaseElementData instance.
class_name UITransition extends Resource

## The duration of this transition.
@export var duration: float = 0.0
## The type of curve for this transition.
@export var curve: Tween.TransitionType = Tween.TRANS_LINEAR
## The easing type of this transition.
@export var easing: Tween.EaseType = Tween.EASE_IN_OUT
