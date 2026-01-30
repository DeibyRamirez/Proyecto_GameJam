extends Node3D

func _on_button_pressed() -> void:
	# 1. Buscamos los nodos necesarios
	# Asumiendo que tus botones están dentro de un CanvasLayer o un Control en esta escena
	var mi_interfaz_menu = $CanvasLayer # Ajusta este nombre al de tu nodo de UI del menú
	var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
	
	if pantalla_info:
		# 1. Ocultar el menú
		if mi_interfaz_menu: mi_interfaz_menu.visible = false
		
		# 2. Mostrar Advertencia (3 segundos)
		pantalla_info.mostrar_pantalla("Advertencia")
		await get_tree().create_timer(3.0).timeout
		
		# 3. Quitar Advertencia y preparar Video
		pantalla_info.ocultar_pantalla() 
		
		# 4. Reproducir Video
		# Accedemos al VideoStreamPlayer dentro de tu Canvas
		var video = pantalla_info.get_node("VideoStreamPlayer") 
		pantalla_info.visible = true # Volvemos a hacer visible el canvas para el video
		video.play()
		
		# 5. Esperar a que el video termine
		await video.finished
		
		# 6. Cambio de escena final
		get_tree().change_scene_to_file("res://escenas/mundo.tscn")
	else:
		get_tree().change_scene_to_file("res://escenas/mundo.tscn")

func _on_button_2_pressed():
	get_tree().quit()
