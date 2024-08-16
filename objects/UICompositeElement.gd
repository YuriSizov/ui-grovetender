###################################################
# Part of UI Grovetender                          #
# Copyright (c) 2024 Yuri Sizov and contributors  #
# Provided under MIT                              #
###################################################

## The composite UI element object. It acts as a group/collection of
## other UI elements and defines a widget or a significant part of a
## widget that must share configuration (states, behavior model, etc.)
class_name UICompositeElement extends UIElement

@export var element_group: UIElementGroup = UIElementGroup.new(self)
