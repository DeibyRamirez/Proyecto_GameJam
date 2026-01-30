extends CanvasLayer

# Diccionario de rutas de imágenes
var imagenes_dict = {
	"Advertencia": "res://assets/Imagenes/Advertencia.jpeg",
	"Ganar": "res://assets/Imagenes/Ganar.jpeg",
	"Controles": "res://assets/Imagenes/Controles.jpg",
	"Creditos": "res://assets/Imagenes/Creditos.jpg"
}

# RUTAS CORREGIDAS (Asegúrate de que los nombres en la escena sean idénticos)
@onready var texture_rect = $ScrollContainer/CenterContainer/ImagenVisual
@onready var scroll_container = $ScrollContainer
@onready var center_container = $ScrollContainer/CenterContainer
@onready var video_player = $VideoStreamPlayer
@onready var boton_volver = $BotonVolver

func _ready():
	# Al empezar el juego, ocultamos todo
	self.visible = false
	boton_volver.visible = false
	video_player.visible = false

# Función principal para mostrar imágenes (Normales y con Scroll)
func mostrar_pantalla(tipo: String):
	if imagenes_dict.has(tipo):
		# 1. Cargar la imagen
		var nueva_textura = load(imagenes_dict[tipo])
		texture_rect.texture = nueva_textura
		
		# 2. Configurar el tamaño del contenedor para que el scroll funcione
		# Esto ajusta el área de desplazamiento al tamaño real de la imagen
		center_container.custom_minimum_size = nueva_textura.get_size()
		
		# 3. Resetear posición y visibilidad
		scroll_container.scroll_vertical = 0
		scroll_container.visible = true
		
		# 4. Asegurar que el video esté apagado
		video_player.stop()
		video_player.visible = false
		
		# 5. Lógica del Botón Volver (Solo en pantallas largas)
		if tipo == "Controles" or tipo == "Creditos":
			boton_volver.visible = true
		else:
			boton_volver.visible = false
			
		self.visible = true
	else:
		print("Error: El ID ", tipo, " no existe en el diccionario.")

# Función especial para la intro (Evita el error de video acelerado)
func reproducir_video_intro():
	# Ocultamos la parte de imágenes
	scroll_container.visible = false
	boton_volver.visible = false
	
	# Preparamos y reseteamos el video
	video_player.visible = true
	video_player.stop() 
	video_player.stream_position = 0.0
	
	# Pequeña espera para que el buffer del video se estabilice
	await get_tree().create_timer(0.1).timeout 
	video_player.play()

func ocultar_pantalla():
	video_player.stop()
	self.visible = false
	get_tree().paused = false

# Función conectada a la señal 'pressed' del BotónVolver
func _on_boton_volver_pressed():
	print("Cambiando a escena: principal_render")
	get_tree().paused = false
	
	# Ruta a tu escena principal
	var ruta_menu = "res://escenas/principal_render.tscn"
	
	# Intentar el cambio de escena
	var error = get_tree().change_scene_to_file(ruta_menu)
	
	if error != OK:
		print("Error crítico: No se pudo cargar la escena en ", ruta_menu)
