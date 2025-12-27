extends TextureRect

func update_mask(health_scalar : float) -> void:
	modulate.a = 1 - health_scalar
