extends Node3D

func _on_button_pressed() -> void:
	# Cambia "res://mundo.tscn" por la ruta exacta de tu escena de nivel
	get_tree().change_scene_to_file("res://escenas/mundo.tscn")


func _on_button_2_pressed():
	get_tree().quit()
