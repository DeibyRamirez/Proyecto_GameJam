extends CharacterBody3D

const SPEED = 2.0
const ATTACK_RANGE = 1.5
const OFFICE_POSITION = Vector3(0, 1, 0)

@onready var navAgent = $NavigationAgent3D
@onready var anim_player = $AnimationPlayer 
@onready var snd_attack = $SndAttack 

# --- CAMBIO AQUÍ: Ahora los asignaremos desde el Inspector ---
@export var target: Node3D
@export var fade_anim_player: AnimationPlayer

var start_position: Vector3
var is_attacking = false

func _ready() -> void:
	start_position = global_transform.origin
	# Asegurarnos de que la pantalla negra no se quede pegada al inicio
	if fade_anim_player.is_playing(): fade_anim_player.stop()
	fade_anim_player.play("fade_out") # Hack para resetear
	fade_anim_player.seek(0, true) # Ir al inicio (transparente)
	fade_anim_player.stop()

func _physics_process(delta: float) -> void:
	# ¡IMPORTANTE! Si está atacando, no hacemos nada más en este frame.
	# Esto congela al monstruo mientras ocurre la animación.
	if is_attacking:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
	
	if distance_to_player < ATTACK_RANGE:
		# En lugar de resetear de golpe, iniciamos la secuencia
		_play_attack_sequence()
		return 

	var currentLocation = global_transform.origin
	var nextLocation = navAgent.get_next_path_position()
	var nextVelocity = (nextLocation - currentLocation).normalized() * SPEED
	
	velocity = velocity.move_toward(nextVelocity, 0.2)
	_update_target_position()
	move_and_slide()

func _update_target_position():
	navAgent.target_position = target.global_transform.origin

func _play_attack_sequence():
	if is_attacking or not target:
		return

	is_attacking = true
	velocity = Vector3.ZERO
	
	# 1. JUMPSCARE VISUAL
	var forward_vector = -target.global_transform.basis.z 
	global_transform.origin = target.global_transform.origin + (forward_vector * 1.2)
	look_at(target.global_transform.origin, Vector3.UP)

	if snd_attack: snd_attack.play()
	if anim_player.has_animation("Susto"): anim_player.play("Susto")
	
	# Espera corta para el susto
	await get_tree().create_timer(1.0).timeout
	
	# 2. MOSTRAR INFORMACIÓN DIRECTAMENTE (Saltamos el fade_out)
	var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
	if pantalla_info:
		print("Llamando a pantalla de información...") # Verificalo en la consola
		pantalla_info.mostrar_pantalla("Perder")
	else:
		print("ERROR: No se encontró el grupo interfaz_info en la escena")

	# 3. TELETRANPORTE
	_teleport_positions()
	
	# 4. TIEMPO PARA VER LA IMAGEN
	await get_tree().create_timer(4.0).timeout
	
	# 5. OCULTAR INFO Y REINICIAR IA
	if pantalla_info:
		pantalla_info.ocultar_pantalla()
	
	is_attacking = false


func _teleport_positions():
	target.global_transform.origin = OFFICE_POSITION
	global_transform.origin = start_position
	navAgent.target_position = start_position
	print("Posiciones reiniciadas.")
