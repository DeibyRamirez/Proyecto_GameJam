extends CharacterBody3D

@onready var head = $Cabeza
@onready var camera = $Cabeza/Camera3D
@onready var raycast = $Cabeza/Camera3D/RayCast3D 
# Al principio del script, bajo las otras variables @onready
@onready var linterna = $Cabeza/Camera3D/SpotLight3D

# Sonidos..
@onready var sonido_linterna = $SonidoLinterna
@onready var sonido_pasos = $SonidoPasos

const SPEED = 4.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003 

var llaves_recogidas = 0
var mascaras = 0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# 1. MOVIMIENTO DEL RATÓN
	if event is InputEventMouseMotion:
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
		
		# Opcional: Sonido de click
		print("Linterna: ", linterna.visible)

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

# --- FUNCIONES DE RECOLECCIÓN ---

func recoger_llave(objeto):
	llaves_recogidas += 1
	print("Llaves recogidas: ", llaves_recogidas, "/4")
	objeto.queue_free()

func recoger_mascara(objeto):
	mascaras += 1
	print("Máscaras recogidas: ", mascaras, "/3")
	objeto.queue_free()
