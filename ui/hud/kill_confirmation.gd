extends Label

const DISPLAY_DURATION := 1.5
const FADE_DURATION := 0.5

var display_timer := 0.0

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if display_timer > 0:
		display_timer -= delta

		# Fade out in last FADE_DURATION seconds
		if display_timer < FADE_DURATION:
			modulate.a = display_timer / FADE_DURATION

		if display_timer <= 0:
			hide()

func show_kill() -> void:
	text = "ELIMINATED"
	modulate.a = 1.0
	display_timer = DISPLAY_DURATION
	show()

	# Play kill sound
	AudioManager.play_sfx(AudioManager.SFXKeys.Kill, Vector3.ZERO, 0.3)
