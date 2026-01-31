extends Node3D

@onready var mi_interfaz_menu = $CanvasLayer # El nodo de UI de este menú

func _on_button_pressed() -> void:
	var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
	
	if pantalla_info:
		mi_interfaz_menu.visible = false
		
		# 1. Mostrar Advertencia 3 segundos
		pantalla_info.mostrar_pantalla("Advertencia")
		await get_tree().create_timer(3.0).timeout
		
		# 2. Limpiar pantalla de advertencia
		pantalla_info.get_node("ScrollContainer").visible = false
		
		# 3. Llamar a la función que reproduce el video sin errores
		pantalla_info.reproducir_video_intro()
		
		var video = pantalla_info.get_node("VideoStreamPlayer")
		await video.finished
		
		get_tree().change_scene_to_file("res://escenas/mundo.tscn")
	else:
		get_tree().change_scene_to_file("res://escenas/mundo.tscn")

func _on_button_2_pressed():
	get_tree().quit()

#func _on_button_3_pressed():
	## Botón de Controles
	#abrir_info("Creditos")

func _on_button_4_pressed():
	# Botón de Créditos
	abrir_info("Controles")

func abrir_info(tipo: String):
	var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
	if pantalla_info:
		mi_interfaz_menu.visible = false # Ocultamos el menú para que no se vea atrás
		pantalla_info.mostrar_pantalla(tipo)
