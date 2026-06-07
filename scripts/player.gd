extends CharacterBody2D

enum ControlState { PLAYER_CONTROL, SOUL_CONTROL, INTERFERENCE }

const SPEED := 240.0
const INTERFERENCE_SPEED_MULT := 0.55
const INTERACT_RANGE := 140.0
const FOOTSTEP_INTERVAL := 0.42

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var control_state: ControlState = ControlState.PLAYER_CONTROL
var _shader_mat: ShaderMaterial
var _nudge_velocity := Vector2.ZERO
var _footstep_timer := 0.0
var _was_moving := false

const COLOR_PLAYER := Color(0.35, 0.65, 1.0, 1.0)
const COLOR_SOUL := Color(1.0, 0.28, 0.32, 1.0)
const COLOR_INTERFERENCE := Color(0.72, 0.38, 1.0, 1.0)


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 2
	_setup_outline_shader()
	_setup_camera()
	var soul := get_node("/root/SoulManager")
	soul.control_state_changed.connect(_on_control_state_changed)
	soul.player_nudge.connect(_apply_nudge)
	_on_control_state_changed(soul.get_control_state())


func _setup_camera() -> void:
	camera.position = Vector2.ZERO
	camera.make_current()


func _setup_outline_shader() -> void:
	var shader := load("res://scripts/soul_outline.gdshader") as Shader
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	sprite.material = _shader_mat
	_update_outline_visuals()


func _physics_process(delta: float) -> void:
	if control_state == ControlState.SOUL_CONTROL:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * 4.0 * delta)
		if _nudge_velocity != Vector2.ZERO:
			velocity += _nudge_velocity
			_nudge_velocity = _nudge_velocity.move_toward(Vector2.ZERO, 400.0 * delta)
		move_and_slide()
		_update_footsteps(delta, velocity.length() > 8.0)
		return

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var speed := SPEED
	if control_state == ControlState.INTERFERENCE:
		speed *= INTERFERENCE_SPEED_MULT

	velocity = input_dir * speed
	if _nudge_velocity != Vector2.ZERO:
		velocity += _nudge_velocity
		_nudge_velocity = _nudge_velocity.move_toward(Vector2.ZERO, 500.0 * delta)

	move_and_slide()
	_update_footsteps(delta, input_dir != Vector2.ZERO)

	if Input.is_action_just_pressed("interact") and control_state == ControlState.PLAYER_CONTROL:
		_try_interact()


func _update_footsteps(delta: float, is_moving: bool) -> void:
	if not is_moving:
		_footstep_timer = 0.0
		_was_moving = false
		return
	_footstep_timer -= delta
	if not _was_moving or _footstep_timer <= 0.0:
		_play_footstep()
		_footstep_timer = FOOTSTEP_INTERVAL
	_was_moving = true


func _play_footstep() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_footstep"):
		audio.play_footstep()


func _on_control_state_changed(state: int) -> void:
	control_state = state as ControlState
	_update_outline_visuals()


func _update_outline_visuals() -> void:
	if _shader_mat == null:
		return
	match control_state:
		ControlState.PLAYER_CONTROL:
			_shader_mat.set_shader_parameter("outline_color", COLOR_PLAYER)
			_shader_mat.set_shader_parameter("flicker_enabled", false)
		ControlState.SOUL_CONTROL:
			_shader_mat.set_shader_parameter("outline_color", COLOR_SOUL)
			_shader_mat.set_shader_parameter("flicker_enabled", false)
		ControlState.INTERFERENCE:
			_shader_mat.set_shader_parameter("outline_color", COLOR_INTERFERENCE)
			_shader_mat.set_shader_parameter("flicker_enabled", true)


func _apply_nudge(direction: Vector2, strength: float) -> void:
	_nudge_velocity = direction.normalized() * strength


func _try_interact() -> void:
	var nearest: Node = null
	var best := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("interact"):
			continue
		var target := node as Node2D
		if target == null:
			continue
		var dist := global_position.distance_to(target.global_position)
		if dist <= INTERACT_RANGE and dist < best:
			best = dist
			nearest = node
	if nearest:
		nearest.interact(self)
