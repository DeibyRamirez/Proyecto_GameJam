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

# --- NUEVA FUNCIÓN CON SECUENCIA DE TIEMPO ---
func _play_attack_sequence():
	if is_attacking or not target or not fade_anim_player:
		return

	is_attacking = true
	velocity = Vector3.ZERO
	
	# 1. POSICIONAR AL MONSTRUO EN LA CARA DEL JUGADOR
	# Calculamos una posición a 1.2 metros frente al jugador basándonos en hacia dónde mira
	var forward_vector = -target.global_transform.basis.z 
	global_transform.origin = target.global_transform.origin + (forward_vector * 1.2)
	
	# Hacemos que el monstruo mire directamente al jugador
	look_at(target.global_transform.origin, Vector3.UP)
	# Si tu modelo queda de espaldas, descomenta la línea de abajo:
	# rotate_y(deg_to_rad(180)) 

	# 2. INICIAR AUDIO Y ANIMACIÓN
	if snd_attack:
		snd_attack.play()
	
	if anim_player.has_animation("Susto"):
		anim_player.play("Susto")
	
	# 3. TIEMPO DE "SHOW" (Jumpscare visual)
	# Esperamos 2.5 segundos viendo al monstruo antes de empezar a oscurecer
	await get_tree().create_timer(2.5).timeout
	
	# 4. FUNDIDO A NEGRO LENTO
	# El tercer parámetro (0.4) hace que la animación sea más lenta (1.0 es normal)
	fade_anim_player.play("fade_out", -1, 0.4) 
	await fade_anim_player.animation_finished
	
	# 5. TELETRANPORTE (En la oscuridad)
	_teleport_positions()
	
	# 6. ESPERAR A QUE TERMINE EL AUDIO DE 7 SEGUNDOS
	# Como ya pasaron ~2.5s de susto + ~2.5s de fundido, esperamos el resto en negro
	await get_tree().create_timer(2.0).timeout
	
	# 7. REGRESAR LA VISIÓN
	fade_anim_player.play_backwards("fade_out")
	await fade_anim_player.animation_finished
	
	is_attacking = false
func _teleport_positions():
	target.global_transform.origin = OFFICE_POSITION
	global_transform.origin = start_position
	navAgent.target_position = start_position
	print("Posiciones reiniciadas.")
