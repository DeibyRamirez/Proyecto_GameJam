extends Area3D
@export var id_mascara: String = "M1" # M1, M2, M3...
@onready var brillo_nodo = $Brillo # Asegúrate de que el nombre coincida con el paso 1

func set_highlight(valor: bool):
	if brillo_nodo:
		brillo_nodo.visible = valor
