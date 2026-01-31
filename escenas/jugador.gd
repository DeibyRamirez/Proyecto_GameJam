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

# La mascara Tu lla sabe
@export var sonido_mascara: AudioStreamPlayer
@export var anim_mascara: AnimationPlayer
@export var vista_mascara: TextureRect # O ColorRect, según lo que uses
@onready var sonido_respiracion = $SonidoRespiracion # El nuevo sonido
@onready var sonido_susto = $SonidoSusto # El nuevo sonido

# --- Precarga de imágenes ---
var img_linterna_on = preload("res://assets/Imagenes/linterna on .png")
var img_linterna_off = preload("res://assets/Imagenes/linterna.png")

const SPEED = 4.3
const SPEED_NORMAL = 4.0
const SPEED_MASCARA = 2.6 # Velocidad muy baja
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003 

var llaves_recogidas = 0
var mascaras = 0

# Variables de inventario (Listas de nombres)
var inventario_llaves = []
var inventario_mascaras = []

var mascara_equipada_id: String = "M1" # <--- AÑADE ESTA LÍNEA (Variable NUEVA)

# Mascara locooooo
var esta_usando_mascara: bool = false
var puede_usar_mascara: bool = true # Para el cooldown
var tiempo_mascara_actual: float = 0.0
const TIEMPO_MAX_MASCARA = 5.0
const TIEMPO_COOLDOWN = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	hud.visible = false
	interzar_salir.visible = false
	
	# --- Lógica para arrancar con linterna apagada ---
	linterna.visible = false # Apaga la luz físicamente
	icono_linterna.texture = img_linterna_off # Cambia el icono a apagado
	icono_linterna.modulate = Color(1, 1, 1, 0.5) # Color blanco semitransparente
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# 1. MOVIMIENTO DEL RATÓN
	if event is InputEventMouseMotion and not hud.visible:
		rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_x(-event.relative.y * SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	# 2. INTERACCIÓN (F, Tab o Click Derecho si lo configuraste)
	if event.is_action_pressed("interactuar"):
		# --- NUEVA CONDICIÓN ---
		if esta_usando_mascara:
			print("No puedes recoger objetos con la máscara puesta.")
			return # Detiene la función aquí mismo
			
		if raycast.is_colliding():
			var objeto = raycast.get_collider()
			
			if objeto.is_in_group("interactuable"):
				# Usamos elif para que solo entre en una categoría a la vez
				if objeto.is_in_group("llaves"):
					recoger_llave(objeto)
				elif objeto.is_in_group("mascaras"):
					recoger_mascara(objeto)
	
	# --- LÓGICA DE LA MÁSCARA ---
	if event.is_action_pressed("tecla_mascara"):
		# NUEVA CONDICIÓN: Solo puede usar la máscara si YA TIENE la M1 recogida
		if not inventario_mascaras.has("M1"):
			print("Aún no tienes la máscara base (M1) para usar esta habilidad.")
			return

		if not hud.visible:
			if esta_usando_mascara:
				_quitar_mascara()
			elif puede_usar_mascara:
				_poner_mascara()
			else:
				print("La máscara está en cooldown...")
	
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
		# NUEVA CONDICIÓN: Si tiene la máscara puesta, no puede abrir el inventario
		if esta_usando_mascara:
			print("No puedes abrir el inventario con la máscara puesta.")
			return # Bloquea el resto de la función
			
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
	
	# --- CONTROL DE TIEMPO DE LA MÁSCARA ---
	if esta_usando_mascara:
		tiempo_mascara_actual += delta
		if tiempo_mascara_actual >= TIEMPO_MAX_MASCARA:
			_quitar_mascara() # Se quita sola al agotarse el tiempo
	
	# --- VELOCIDAD DINÁMICA ---
	var velocidad_actual = SPEED_NORMAL
	if esta_usando_mascara:
		velocidad_actual = SPEED_MASCARA

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("moverse_izquierda", "moverse_derecha", "moverse_adelante", "moverse_atras")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_gestionar_sonido_pasos()
	
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
			
# Mascaras con visiones....
func _poner_mascara():
	esta_usando_mascara = true
	tiempo_mascara_actual = 0.0
	
	var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
	
	if sonido_mascara: sonido_mascara.play()
	if sonido_respiracion: sonido_respiracion.play()
	if anim_mascara: anim_mascara.play("poner_mascara")
	
	# --- ACTIVAR VISIONES SEGÚN EL ID SELECCIONADO ---
	match mascara_equipada_id:
		"M2":
			activar_vision_grupo("grupo_monstruo", true)
		"M3":
			activar_vision_grupo("grupo_mascaras", true)
		"M4":
			activar_vision_grupo("grupo_llaves", true)
		"M1":
			print("M1 no tiene visión especial")
	
	print("Máscara puesta: ", mascara_equipada_id)

func _quitar_mascara():
	esta_usando_mascara = false
	if sonido_mascara: sonido_mascara.play()
	if sonido_respiracion: sonido_respiracion.stop()
	if anim_mascara: anim_mascara.play_backwards("poner_mascara")
	
	# --- APAGAR TODAS LAS VISIONES ---
	activar_vision_grupo("grupo_monstruo", false)
	activar_vision_grupo("grupo_mascaras", false)
	activar_vision_grupo("grupo_llaves", false)
	
	# Iniciar Cooldown
	puede_usar_mascara = false
	await get_tree().create_timer(TIEMPO_COOLDOWN).timeout
	puede_usar_mascara = true

# Función auxiliar para encender/apagar los brillos
func activar_vision_grupo(nombre_grupo: String, activado: bool):
	get_tree().call_group(nombre_grupo, "set_highlight", activado)
	

func _gestionar_sonido_pasos():
	if is_on_floor() and velocity.length() > 1.0:
		if not sonido_pasos.playing: sonido_pasos.play()
	else:
		if sonido_pasos.playing: sonido_pasos.stop()

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
			var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
			if pantalla_info:
				# 2. Mostrar pantalla de Ganar
				pantalla_info.mostrar_pantalla("Ganar")
				
				# 3. Esperar 5 segundos
				# Usamos un Timer de la escena para no bloquear el juego
				await get_tree().create_timer(5.0).timeout
				
				# --- LIBERAR EL MOUSE AQUÍ ---
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				# 2. Mostrar pantalla de Creditos
				pantalla_info.mostrar_pantalla("Creditos")
				
				# Usamos un Timer de la escena para no bloquear el juego
				await get_tree().create_timer(15.0).timeout
				
				# 4. Regresar al menú principal (PrincipalRender)
				# Asegúrate de que la ruta a tu escena de menú sea la correcta
				
				get_tree().change_scene_to_file("res://escenas/principal_render.tscn")
			else:
				print("ERROR: No se encontró el grupo interfaz_info")
				# Si falla la info, regresamos al menú de todos modos
				get_tree().change_scene_to_file("res://escenas/principal_render.tscn")
				
	objeto.queue_free()

func recoger_mascara(objeto):
	var id = objeto.id_mascara
	if not inventario_mascaras.has(id):
		inventario_mascaras.append(id)
		print("Inventario Máscaras: ", inventario_mascaras)
		# Llamamos a la función del HUD pasando la lista actualizada
		hud.actualizar_visual_inventario(inventario_mascaras)
		
		# --- NUEVA LÓGICA DE SUSTO AL RECOGER ---
		if id == "M5" or id == "M6":
			var pantalla_info = get_tree().get_first_node_in_group("interfaz_info")
			if pantalla_info:
				# 1. Mostramos la imagen y sonido
				pantalla_info.mostrar_pantalla("Susto")
				if sonido_susto: sonido_susto.play()
				
				# 2. Esperamos 3 segundos y ocultamos
				await get_tree().create_timer(3.0).timeout
				pantalla_info.ocultar_pantalla()
				
	objeto.queue_free()


func _on_hud_mascara_seleccionada(id_mascara):
	mascara_equipada_id = id_mascara # Aquí guardas M2, M3 o M4
