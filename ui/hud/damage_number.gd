extends Label

const FLOAT_SPEED := 50.0
const LIFETIME := 1.0
const FADE_START := 0.5

var velocity := Vector2.ZERO
var life_timer := 0.0

func _ready() -> void:
	# Random horizontal spread
	velocity = Vector2(randf_range(-30, 30), -FLOAT_SPEED)

func _process(delta: float) -> void:
	life_timer += delta

	# Move upward
	position += velocity * delta

	# Fade out after FADE_START seconds
	if life_timer > FADE_START:
		modulate.a = 1.0 - ((life_timer - FADE_START) / (LIFETIME - FADE_START))

	# Delete after lifetime
	if life_timer >= LIFETIME:
		queue_free()

func set_damage(damage: int, is_headshot := false) -> void:
	text = str(damage)

	if is_headshot:
		add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		text += "!"
	else:
		add_theme_color_override("font_color", Color(1, 1, 1))
