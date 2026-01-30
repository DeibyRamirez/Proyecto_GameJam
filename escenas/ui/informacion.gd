extends CanvasLayer

# Diccionario que funciona como un MAP (ID: Ruta de la imagen)
var imagenes_dict = {
	"Advertencia": "res://assets/Imagenes/Advertencia.jpeg",
	"Ganar": "res://assets/Imagenes/Ganar.jpeg",
	"Perder": "res://assets/Imagenes/Perder.jpeg"
}

@onready var texture_rect = $ImagenVisual

func _ready():
	# Al empezar el juego, ocultamos el canvas
	self.visible = false

# Esta función es la que llamarás desde otros scripts
func mostrar_pantalla(tipo: String):
	if imagenes_dict.has(tipo):
		# Cargamos la imagen desde la ruta guardada en el diccionario
		var ruta = imagenes_dict[tipo]
		texture_rect.texture = load(ruta)
		
		# Mostramos el canvas y pausamos el juego si es necesario
		self.visible = true
		# get_tree().paused = true # Descomenta esto si quieres pausar el juego al mostrar el mensaje
	else:
		print("Error: El ID ", tipo, " no existe en el diccionario de imágenes.")

func ocultar_pantalla():
	self.visible = false
	get_tree().paused = false
