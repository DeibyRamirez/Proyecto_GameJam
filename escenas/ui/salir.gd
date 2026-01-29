extends CanvasLayer

# Si este menú es un popup que aparece durante el juego, 
# asegúrate de que el Process Mode del CanvasLayer esté en "Always"
# para que no se congele junto con el juego.

func _on_si_pressed():
	get_tree().paused = false # Limpiamos la pausa
	# Esta es la función estándar de Godot para cerrar la aplicación
	get_tree().change_scene_to_file("res://escenas/principal_render.tscn")

func _on_no_pressed():
	# Si es una escena independiente, vuelve al menú principal
	# get_tree().change_scene_to_file("res://principal_render.tscn")
	
	# Si es un panel dentro de la partida (Pause Menu):
	self.visible = false # Oculta este menú
	get_tree().paused = false # Reanuda el tiempo del juego
