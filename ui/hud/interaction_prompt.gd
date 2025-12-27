extends Control
class_name InteractionPrompt

@onready var label: Label = $Panel/MarginContainer/Label

func _ready() -> void:
	add_to_group("InteractionPrompt")
	hide()

func show_prompt(text: String) -> void:
	label.text = text
	show()

func hide_prompt() -> void:
	hide()
