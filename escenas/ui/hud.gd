# En hud.gd
extends CanvasLayer

signal mascara_seleccionada(id_mascara)

func _ready():
	for boton in $GridMascaras.get_children():
		if boton is Button:
			boton.pressed.connect(_on_mascara_pressed.bind(boton.name))
			# 1. Totalmente oscuras al inicio (Negro casi total)
			boton.modulate = Color(0.05, 0.05, 0.05, 1) 

func _on_mascara_pressed(id: String):
	var slot = find_child(id, true, false)
	# Verificamos si ya no está oscura (es decir, si ya se encontró)
	if slot and slot.modulate.r > 0.1: 
		emit_signal("mascara_seleccionada", id)
		_resaltar_seleccion(id)

func _resaltar_seleccion(id_activa: String):
	for boton in $GridMascaras.get_children():
		if boton is Button:
			if boton.name == id_activa:
				# 2. Recuadro/Brillo para la máscara activa según su ID
				match id_activa:
					"M1":
						# Brillo normal (Blanco puro o un poco más brillante)
						boton.self_modulate = Color(1.5, 1.5, 1.5, 1) 
					"M2":
						# Brillo Rojo
						boton.self_modulate = Color(2, 0, 0, 1) 
					"M3":
						# Brillo Azul (Cian/Azul eléctrico)
						boton.self_modulate = Color(0, 0.5, 2, 1) 
					"M4":
						# Brillo Amarillo
						boton.self_modulate = Color(2, 2, 0, 1)
					_:
						# Color por defecto si hay otros IDs
						boton.self_modulate = Color(1, 1, 1, 1)
			else:
				# Volver al color normal (sin brillo) si no está seleccionada
				# IMPORTANTE: Usamos (1,1,1,1) para que se vea la imagen original
				boton.self_modulate = Color(1, 1, 1, 1)

func actualizar_visual_inventario(lista_objetos):
	for id in lista_objetos:
		var slot = find_child(id, true, false) 
		if slot:
			# 3. Al encontrarla, le devolvemos su color original
			slot.modulate = Color(1, 1, 1, 1) 
		else:
			# Evitamos el spam de errores si recoges IDs que no existen en el HUD
			pass
