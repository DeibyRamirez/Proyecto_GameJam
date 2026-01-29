# En hud.gd
extends CanvasLayer

func actualizar_visual_inventario(lista_objetos):
	for id in lista_objetos:
		# Buscamos el nodo por su nombre (K1, K2, etc.)
		# El segundo parámetro 'true' permite buscar en hijos de hijos
		var slot = find_child(id, true, false) 
		
		if slot:
			# Si lo encuentra, le devolvemos su color original (Blanco/Visible)
			slot.modulate = Color(1, 1, 1, 1) 
		else:
			print("Error: No se encontró un nodo llamado ", id, " en el HUD")
