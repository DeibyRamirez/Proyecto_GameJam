extends Light3D # Funciona para Omni y Spot

@export var energia_normal: float = 2.0
@export var energia_parpadeo: float = 0.2

func _process(_delta):
	# Usamos randf para que el parpadeo sea totalmente irregular
	if randf() > 0.96: # 4% de probabilidad cada frame de fallar
		light_energy = energia_parpadeo
	else:
		# Regresa a la energía normal con un pequeño suavizado
		light_energy = lerp(light_energy, energia_normal, 0.3)
