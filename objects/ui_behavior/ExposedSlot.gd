###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

class_name ExposedSlot extends Resource

## The type of the role the assigned element fulfills.
@export var role_type: int = ExposedRole.EXPOSED_CUSTOM
## The unique name of the role. Used to distinguish it from others of a similar type,
## and when generating API on export.
@export var role_name: String = ExposedRole.get_role_name(role_type)
## The flag that locks this exposed slot. Locked slots cannot be removed or renamed
## because they are required by the current preset.
@export var locked: bool = false

## The element assigned to this slot.
@export var assigned_element: BaseUIElement = null
