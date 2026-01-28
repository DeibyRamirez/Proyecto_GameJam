extends CharacterBody3D

@onready var head = $Cabeza
@onready var camera = $Cabeza/Camera3D
@onready var raycast = $Cabeza/Camera3D/RayCast3D 

const SPEED = 5.0
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

# --- FUNCIONES DE RECOLECCIÓN ---

func recoger_llave(objeto):
	llaves_recogidas += 1
	print("Llaves recogidas: ", llaves_recogidas, "/4")
	objeto.queue_free()

func recoger_mascara(objeto):
	mascaras += 1
	print("Máscaras recogidas: ", mascaras, "/3")
	objeto.queue_free()
