extends Control

@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider
@onready var master_volume_label: Label = %MasterVolumeLabel
@onready var music_volume_label: Label = %MusicVolumeLabel
@onready var sfx_volume_label: Label = %SFXVolumeLabel
@onready var mute_checkbox: CheckBox = %MuteCheckBox
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox
@onready var vsync_checkbox: CheckBox = %VsyncCheckBox
@onready var resolution_option_button: OptionButton = %ResolutionOptionButton
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_label: Label = %SensitivityLabel
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	hide()
	connect_signals()

	# Graphics
	fullscreen_checkbox.button_pressed = SettingsManager.fullscreen_enabled
	vsync_checkbox.button_pressed = SettingsManager.vsync_enabled
	resolution_option_button.selected = SettingsManager.resolution_index

	# Controls
	sensitivity_slider.value = SettingsManager.mouse_sensitivity
	update_sensitivity_label()

func connect_signals() -> void:
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_checkbox.toggled.connect(_on_mute_toggled)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	resolution_option_button.item_selected.connect(_on_resolution_selected)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	close_button.pressed.connect(_on_close_pressed)

func update_volume_labels() -> void:
	master_volume_label.text = "%d%%" % (master_volume_slider.value * 100)
	music_volume_label.text = "%d%%" % (music_volume_slider.value * 100)
	sfx_volume_label.text = "%d%%" % (sfx_volume_slider.value * 100)

func update_sensitivity_label() -> void:
	sensitivity_label.text = "%.2f" % sensitivity_slider.value

# Audio callbacks
func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	update_volume_labels()

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	update_volume_labels()

func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	update_volume_labels()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func _on_mute_toggled(enabled: bool) -> void:
	SettingsManager.set_audio_mute(enabled)

# Graphics callbacks
func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)

func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.set_vsync(enabled)

func _on_resolution_selected(index: int) -> void:
	SettingsManager.set_resolution(index)

# Controls callbacks
func _on_sensitivity_changed(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value)
	update_sensitivity_label()

func _on_close_pressed() -> void:
	hide()
	AudioManager.play_sfx(AudioManager.SFXKeys.UIClick)

func open_settings() -> void:
	show()
