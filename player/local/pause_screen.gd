extends Control

@onready var chat_input: LineEdit = $VBoxContainer/LineEdit

signal chat_message_sent(message: String)

func _on_resume_button_pressed() -> void:
	get_tree().call_group("PlayerLocal", "unpause")

func _on_exit_button_pressed() -> void:
	get_tree().call_group("LocalGameSceneManager", "change_scene", "res://ui/main_menu/main_menu.tscn")
	get_tree().call_group("Lobby", "exit_game")

func _ready() -> void:
	chat_input.text_submitted.connect(_on_chat_input_submitted)
	
func _on_chat_input_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
		
	chat_message_sent.emit(text)
	chat_input.clear()
