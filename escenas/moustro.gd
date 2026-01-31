extends CharacterBody3D

const SPEED = 2.0
const ATTACK_RANGE = 1.5
const OFFICE_POSITION = Vector3(-5, 1.6, 8.4)

@onready var navAgent = $NavigationAgent3D
@onready var snd_attack = $SndAttack 

@onready var brillo_nodo = $Brillo # Asegúrate de que el nombre coincida con el paso 1

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
	# Asegurarnos de que la pantalla negra no se quede pegada al inicio
	if fade_anim_player.is_playing(): 
		fade_anim_player.stop()
		fade_anim_player.play("fade_out") # Hack para resetear
		fade_anim_player.seek(0, true) # Ir al inicio (transparente)
		fade_anim_player.stop()

func _physics_process(delta: float) -> void:
	# ¡IMPORTANTE! Si está atacando, no hacemos nada más en este frame.
	# Esto congela al monstruo mientras ocurre la animación.
	if is_attacking:
		return
		
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
	
	if distance_to_player < ATTACK_RANGE:
		# En lugar de resetear de golpe, iniciamos la secuencia
		_play_attack_sequence()
		return 

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
	
	# 1. Detener animaciones del monstruo
	anim_player_mixamo.stop()
	
	# 2. Posicionar al monstruo frente a la cara del jugador para el susto 3D
	var forward_vector = -target.global_transform.basis.z 
	global_transform.origin = target.global_transform.origin + (forward_vector * 1.2)
	look_at(target.global_transform.origin, Vector3.UP)
	rotate_y(deg_to_rad(180)) 

	# 3. ACTIVAR SUSTO (Imagen y Sonido)
	var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
	if pantalla_info:
		pantalla_info.mostrar_pantalla("Susto")
		
	# Buscamos el sonido en el target (Jugador) y lo reproducimos
	if target.has_node("SonidoSusto"):
		target.get_node("SonidoSusto").play()
	
	# 4. Iniciar efecto de parpadeo negro (fade out)
	fade_anim_player.play("fade_out", -1, 0.4) 
	
	# Esperamos un momento para que el susto se vea bien
	await get_tree().create_timer(2.0).timeout
	
	# 5. MOSTRAR PANTALLA DE PERDER
	if pantalla_info:
		# Cambiamos la imagen de "Susto" por la de "Perder"
		pantalla_info.mostrar_pantalla("Perder")
	
	# 6. REINICIAR POSICIONES (Teletransporte)
	_teleport_positions()
	
	# 7. TIEMPO PARA VER LA IMAGEN DE DERROTA
	await get_tree().create_timer(3.5).timeout
	
	# 8. QUITAR PANTALLA NEGRA Y OCULTAR INFO
	fade_anim_player.play_backwards("fade_out")
	if pantalla_info:
		pantalla_info.ocultar_pantalla()
		
	is_attacking = false
	

func _teleport_positions():
	target.global_transform.origin = OFFICE_POSITION
	global_transform.origin = start_position
	navAgent.target_position = start_position
	print("Posiciones reiniciadas.")

func set_highlight(valor: bool):
	if brillo_nodo:
		brillo_nodo.visible = valor
