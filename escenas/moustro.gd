extends CharacterBody3D

const SPEED = 2.0
const ATTACK_RANGE = 1.5
const OFFICE_POSITION = Vector3(0, 1, 0)

@onready var navAgent = $NavigationAgent3D
@onready var snd_attack = $SndAttack 

# --- REFERENCIAS A LOS 2 ANIMATION PLAYERS ---
# El que usas para el "Susto" manual
@export var anim_player_susto: AnimationPlayer 
# El que tiene la animación de Mixamo (arrástralo en el inspector)
@export var anim_player_mixamo: AnimationPlayer 

@export var target: Node3D # Este es tu Jugador
@export var fade_anim_player: AnimationPlayer

var start_position: Vector3
var is_attacking = false

func _ready() -> void:
	start_position = global_transform.origin
	# Reset del fundido negro
	if fade_anim_player:
		fade_anim_player.play("fade_out")
		fade_anim_player.seek(0, true)
		fade_anim_player.stop()

func _physics_process(delta: float) -> void:
	if is_attacking: return

	# --- NUEVA LÓGICA DE LA MÁSCARA ---
	# 2. Revisamos si el target existe y si tiene la variable 'esta_usando_mascara' en true
	if target and target.get("esta_usando_mascara") == true:
		# Frenar en seco
		velocity = Vector3.ZERO
		# Detener animación de correr
		if anim_player_mixamo.is_playing():
			anim_player_mixamo.stop()
		# Salimos de la función aquí mismo. El monstruo no calculará rutas ni te atacará.
		return 
	# ----------------------------------

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var distance_to_player = global_transform.origin.distance_to(target.global_transform.origin)
	
	# Solo atacará si no salimos arriba por culpa de la máscara
	if distance_to_player < ATTACK_RANGE:
		_play_attack_sequence()
		return 

	# Movimiento normal
	var currentLocation = global_transform.origin
	var nextLocation = navAgent.get_next_path_position()
	var nextVelocity = (nextLocation - currentLocation).normalized() * SPEED
	
	velocity = velocity.move_toward(nextVelocity, 0.2)
	
	_orientar_monstruo(nextLocation)

	# Animación de correr
	if velocity.length() > 0.1:
		if anim_player_mixamo.current_animation != "mixamo_com":
			anim_player_mixamo.play("mixamo_com")
	else:
		anim_player_mixamo.stop()

	_update_target_position()
	move_and_slide()

func _orientar_monstruo(objetivo: Vector3):
	# Evitamos que el monstruo mire hacia arriba o abajo (solo rotación Y)
	var look_at_pos = Vector3(objetivo.x, global_transform.origin.y, objetivo.z)
	if global_transform.origin.distance_squared_to(look_at_pos) > 0.001:
		look_at(look_at_pos, Vector3.UP)
		# IMPORTANTE: Los modelos de Mixamo suelen venir rotados 180 grados.
		# Si camina de espaldas, mantén la línea de abajo sin el '#'
		rotate_y(deg_to_rad(180))

func _update_target_position():
	navAgent.target_position = target.global_transform.origin

func _play_attack_sequence():
	if is_attacking or not target or not fade_anim_player: return
	is_attacking = true
	velocity = Vector3.ZERO
	
	# Detener animación de correr para que no se vea raro en el susto
	anim_player_mixamo.stop()
	
	# Posicionamiento frente a la cámara
	var forward_vector = -target.global_transform.basis.z 
	global_transform.origin = target.global_transform.origin + (forward_vector * 1.2)
	look_at(target.global_transform.origin, Vector3.UP)
	rotate_y(deg_to_rad(180)) # Ajuste de cara para Mixamo

	if snd_attack: snd_attack.play()
	if anim_player_susto.has_animation("mixamo_com"): 
		anim_player_susto.play("mixamo_com")
	
	await get_tree().create_timer(2.5).timeout
	fade_anim_player.play("fade_out", -1, 0.4) 
	await fade_anim_player.animation_finished
	
	_teleport_positions()
	await get_tree().create_timer(2.0).timeout
	fade_anim_player.play_backwards("fade_out")
	await fade_anim_player.animation_finished
	is_attacking = false

func _teleport_positions():
	target.global_transform.origin = OFFICE_POSITION
	global_transform.origin = start_position
	navAgent.target_position = start_position
