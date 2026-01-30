extends CharacterBody3D

@onready var head = $Cabeza
@onready var camera = $Cabeza/Camera3D
@onready var raycast = $Cabeza/Camera3D/RayCast3D 
# Al principio del script, bajo las otras variables @onready
@onready var linterna = $Cabeza/Camera3D/SpotLight3D

# Sonidos..
@onready var sonido_linterna = $SonidoLinterna
@onready var sonido_pasos = $SonidoPasos

# Canvas Layer
@onready var hud = $HUD # Asegúrate de que el HUD sea hijo del jugador o esté en la escena
@onready var interfaz_fija = $InterfazPermanente # O como hayas nombrado el nuevo CanvasLayer
@onready var icono_linterna = $InterfazPermanente/IconoLinterna
@onready var interzar_salir = $Salir


# --- Precarga de imágenes ---
var img_linterna_on = preload("res://assets/Imagenes/linterna on .png")
var img_linterna_off = preload("res://assets/Imagenes/linterna.png")

const SPEED = 4.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003 

var llaves_recogidas = 0
var mascaras = 0

# Variables de inventario (Listas de nombres)
var inventario_llaves = []
var inventario_mascaras = []

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	hud.visible = false
	interzar_salir.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# 1. MOVIMIENTO DEL RATÓN
	if event is InputEventMouseMotion and not hud.visible:
		rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_x(-event.relative.y * SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	# 2. INTERACCIÓN (F, Tab o Click Derecho si lo configuraste)
	if event.is_action_pressed("interactuar"):
		if raycast.is_colliding():
			var objeto = raycast.get_collider()
			
			if objeto.is_in_group("interactuable"):
				# Usamos elif para que solo entre en una categoría a la vez
				if objeto.is_in_group("llaves"):
					recoger_llave(objeto)
				elif objeto.is_in_group("mascaras"):
					recoger_mascara(objeto)
	
	# Lógica para encender/apagar la linterna
	if event.is_action_pressed("linterna"):
		# El símbolo "!" invierte el estado actual (si está prendida, la apaga)
		linterna.visible = !linterna.visible
		sonido_linterna.play() # Reproduce el click
		
		# CAMBIO DE ICONO:
		if linterna.visible:
			icono_linterna.texture = img_linterna_on
			icono_linterna.modulate = Color(1, 1, 0.5) # Un tono amarillento brillante
		else: 
			icono_linterna.texture = img_linterna_off
			icono_linterna.modulate = Color(1, 1, 1, 0.5) # Blanco semitransparente
			
		# Opcional: Sonido de click
		print("Linterna: ", linterna.visible)
	
	# Lógica para abrir/cerrar el inventario
	if event.is_action_pressed("abrir_inventario"):
		if hud:
			# Cambiamos la visibilidad (si es true pasa a false y viceversa)
			hud.visible = !hud.visible
			
			# Manejo del ratón al abrir el inventario
			if hud.visible:
				# Si el inventario se ve, liberamos el ratón
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				# Si se cierra, volvemos a atrapar el ratón para jugar
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				
	# Salir del juego
	if event.is_action_pressed("ui_cancel"): # Por defecto es la tecla ESC
		interzar_salir.visible = true
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# --- LÓGICA DE PASOS ---
	# Verificamos si el personaje está en el suelo y si realmente se está moviendo
	# Usamos velocity.length() > 1.0 para ignorar micromovimientos
	if is_on_floor() and velocity.length() > 1.0:
		if not sonido_pasos.playing:
			sonido_pasos.play()
	else:
		# Si se detiene o salta, paramos el sonido
		if sonido_pasos.playing:
			sonido_pasos.stop()

# --- FUNCIONES DE RECOLECCIÓN ACTUALIZADAS ---

func recoger_llave(objeto):
	var id = objeto.id_llave # Obtenemos el ID (K1, K2, etc.)
	if not inventario_llaves.has(id):
		inventario_llaves.append(id)
		print("Inventario Llaves: ", inventario_llaves)
		# Llamamos a la función del HUD pasando la lista actualizada
		hud.actualizar_visual_inventario(inventario_llaves)
		
		if inventario_llaves.size() == 4:
			print("¡Tienes todas las llaves! Ya puedes abrir la puerta principal.")
			# Aquí podrías activar una animación o un sonido especial
	objeto.queue_free()

func recoger_mascara(objeto):
	var id = objeto.id_mascara
	if not inventario_mascaras.has(id):
		inventario_mascaras.append(id)
		print("Inventario Máscaras: ", inventario_mascaras)
		# Llamamos a la función del HUD pasando la lista actualizada
		hud.actualizar_visual_inventario(inventario_mascaras)
	objeto.queue_free()
