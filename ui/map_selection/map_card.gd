extends PanelContainer

signal map_selected(map_id: int)

@onready var map_name_label: Label = %MapNameLabel
@onready var map_thumbnail: TextureRect = %MapThumbnail
@onready var select_button: Button = %SelectButton

var map_id: int = -1

func setup(id: int) -> void:
	map_id = id
	map_name_label.text = MapRegistry.get_map_name(id)

	var screenshot_path = MapRegistry.get_screenshot_path(id)
	if ResourceLoader.exists(screenshot_path):
		map_thumbnail.texture = load(screenshot_path)

func setup_random() -> void:
	map_id = MapRegistry.ANY_MAP
	map_name_label.text = "Random"

	# Create a simple "?" label as placeholder
	var question_label = Label.new()
	question_label.text = "?"
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.add_theme_font_size_override("font_size", 96)
	map_thumbnail.add_child(question_label)
	question_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _on_select_button_pressed() -> void:
	map_selected.emit(map_id)
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)
