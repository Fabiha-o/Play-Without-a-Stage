extends Node

const BASE_MODULATE := Color(0.1893278, 0.18932778, 0.1893278, 1.0)

@export var lamp_path: NodePath = ^"../Floating Lamp"
@export var room_light_path: NodePath = ^"../PointLight2D"
@export var canvas_modulate_path: NodePath = ^"../CanvasModulate"
@export var drift_prop_paths: Array[NodePath] = [^"../Chair"]

var _lamp: Sprite2D
var _room_light: PointLight2D
var _canvas_modulate: CanvasModulate
var _drift_props: Array[Node2D] = []
var _drift_origins: Array[Vector2] = []

var _lamp_hovering := true
var _lamp_base := Vector2.ZERO
var _time := 0.0

var _flicker_timer := 0.0
var _drift_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("chaos_manager")
	_rng.randomize()
	_lamp = get_node_or_null(lamp_path) as Sprite2D
	_room_light = get_node_or_null(room_light_path) as PointLight2D
	_canvas_modulate = get_node_or_null(canvas_modulate_path) as CanvasModulate
	for path in drift_prop_paths:
		var node := get_node_or_null(path) as Node2D
		if node:
			_drift_props.append(node)
			_drift_origins.append(node.position)
	if _lamp:
		_lamp_base = _lamp.position
	_schedule_flicker()
	_schedule_drift()
	var letter := get_node_or_null("../Letter-Goal")
	if letter and letter.has_signal("letter_collected"):
		letter.letter_collected.connect(_stop_lamp_hover)


func _process(delta: float) -> void:
	_time += delta
	_flicker_timer -= delta
	_drift_timer -= delta

	if _lamp_hovering and _lamp:
		_lamp.position = _lamp_base + Vector2(
			sin(_time * 1.4) * 5.0,
			cos(_time * 1.9) * 7.0
		)
		_lamp.rotation = sin(_time * 0.9) * 0.04

	if _flicker_timer <= 0.0:
		_do_light_flicker()
		_schedule_flicker()

	if _drift_timer <= 0.0:
		_apply_prop_drift()
		_schedule_drift()


func flicker_light_now() -> void:
	_do_light_flicker()


func _stop_lamp_hover() -> void:
	_lamp_hovering = false
	if _lamp:
		_lamp.position = _lamp_base
		_lamp.rotation = 0.0


func _schedule_flicker() -> void:
	_flicker_timer = _rng.randf_range(3.0, 8.0)


func _schedule_drift() -> void:
	_drift_timer = _rng.randf_range(5.0, 12.0)


func _do_light_flicker() -> void:
	if _room_light:
		var base_energy := 1.01
		var tween := create_tween()
		tween.tween_property(_room_light, "energy", _rng.randf_range(0.35, 0.75), 0.05)
		tween.tween_property(_room_light, "energy", base_energy, _rng.randf_range(0.1, 0.35))
	if _canvas_modulate:
		var flash := BASE_MODULATE * _rng.randf_range(0.75, 1.1)
		var tween2 := create_tween()
		tween2.tween_property(_canvas_modulate, "color", flash, 0.04)
		tween2.tween_property(_canvas_modulate, "color", BASE_MODULATE, 0.2)


func _apply_prop_drift() -> void:
	for i in _drift_props.size():
		var prop := _drift_props[i]
		var origin := _drift_origins[i]
		var offset := Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-4.0, 4.0))
		var tween := create_tween()
		tween.tween_property(prop, "position", origin + offset, _rng.randf_range(0.8, 1.6))
		tween.tween_property(prop, "position", origin, _rng.randf_range(0.8, 1.4))
