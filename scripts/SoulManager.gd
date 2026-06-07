extends Node

signal takeover_complete
signal control_state_changed(state: int)
signal player_nudge(direction: Vector2, strength: float)
signal letter_revealed
signal shelves_revealed

enum ControlState { PLAYER_CONTROL, SOUL_CONTROL, INTERFERENCE }

const STATE_PLAYER := ControlState.PLAYER_CONTROL
const STATE_SOUL := ControlState.SOUL_CONTROL
const STATE_INTERFERENCE := ControlState.INTERFERENCE

var _control_state: ControlState = ControlState.PLAYER_CONTROL
var _takeover_done := false
var _interference_active := false
var _interference_timer := 0.0
var _first_interference := true
var _shelves_hint_read := false
var _run_generation := 0
var _pending_carpet_restart := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)
	reset_cycle()


func _on_scene_changed(_scene: Node) -> void:
	reset_cycle()


func mark_carpet_restart() -> void:
	_pending_carpet_restart = true


func consume_carpet_restart() -> bool:
	var was_restart := _pending_carpet_restart
	_pending_carpet_restart = false
	return was_restart


func notify_shelves_read() -> void:
	_shelves_hint_read = true


func reset_cycle() -> void:
	_run_generation += 1
	_takeover_done = false
	_interference_active = false
	_first_interference = true
	_control_state = ControlState.PLAYER_CONTROL
	_interference_timer = 4.0
	control_state_changed.emit(_control_state)


func _process(delta: float) -> void:
	if _takeover_done or _interference_active:
		return
	_interference_timer -= delta
	if _interference_timer <= 0.0 and _control_state == ControlState.PLAYER_CONTROL:
		_start_interference()


func get_control_state() -> ControlState:
	return _control_state


func _schedule_next_interference() -> void:
	if _first_interference:
		_interference_timer = _rng.randf_range(4.0, 6.0)
	else:
		_interference_timer = _rng.randf_range(6.0, 10.0)


func _set_control_state(state: ControlState) -> void:
	if _control_state == state:
		return
	_control_state = state
	control_state_changed.emit(state)


func _start_interference() -> void:
	if _takeover_done:
		return
	var run_id := _run_generation
	_interference_active = true
	_set_control_state(ControlState.INTERFERENCE)

	if _first_interference:
		_reveal_shelves()
	else:
		var roll := _rng.randi_range(0, 3)
		match roll:
			0:
				_flicker_light()
			1:
				_flicker_light()
			2:
				_nudge_player()
			3:
				_reveal_shelves()

	_first_interference = false

	if not _takeover_done and _rng.randf() < 0.35:
		await get_tree().create_timer(_rng.randf_range(0.6, 1.2)).timeout
		if run_id != _run_generation:
			return
		await _run_takeover(run_id)
	else:
		var duration := _rng.randf_range(0.8, 1.6)
		await get_tree().create_timer(duration).timeout
		if run_id != _run_generation:
			return
		_end_interference()


func _end_interference() -> void:
	_interference_active = false
	if _control_state == ControlState.INTERFERENCE:
		_set_control_state(ControlState.PLAYER_CONTROL)
	_schedule_next_interference()


func _reveal_shelves() -> void:
	var shelves := _find_shelves()
	if shelves and shelves.has_method("reveal"):
		shelves.reveal()
		shelves_revealed.emit()


func _flicker_light() -> void:
	var chaos := _find_chaos_manager()
	if chaos and chaos.has_method("flicker_light_now"):
		chaos.flicker_light_now()
	var modulate := _find_canvas_modulate()
	if modulate:
		var tween := create_tween()
		tween.tween_property(modulate, "color", Color(0.35, 0.15, 0.2, 1.0), 0.06)
		tween.tween_property(modulate, "color", Color(0.1893278, 0.18932778, 0.1893278, 1.0), 0.25)


func _nudge_player() -> void:
	var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-1, 1).normalized()]
	player_nudge.emit(dirs[_rng.randi_range(0, dirs.size() - 1)], _rng.randf_range(80.0, 160.0))


func _run_takeover(run_id: int) -> void:
	if _takeover_done or run_id != _run_generation:
		return
	_takeover_done = true
	_set_control_state(ControlState.SOUL_CONTROL)

	var player := _find_player()
	var target := _find_takeover_point()
	if player == null or target == null:
		_set_control_state(ControlState.PLAYER_CONTROL)
		takeover_complete.emit()
		_interference_active = false
		return

	var tween := create_tween()
	tween.tween_property(player, "global_position", target.global_position, 2.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if run_id != _run_generation:
		return
	await get_tree().create_timer(0.3).timeout
	if run_id != _run_generation:
		return

	_set_control_state(ControlState.PLAYER_CONTROL)
	takeover_complete.emit()
	_interference_active = false
	_schedule_next_interference()


func _find_player() -> CharacterBody2D:
	var scene := get_tree().current_scene
	if scene:
		var p := scene.get_node_or_null("Player")
		if p is CharacterBody2D:
			return p
	return get_tree().get_first_node_in_group("player") as CharacterBody2D


func _find_takeover_point() -> Node2D:
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("Take Over Point") as Node2D
	return null


func _find_shelves() -> Node:
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("Shelves-Clue")
	return null


func _find_canvas_modulate() -> CanvasModulate:
	var scene := get_tree().current_scene
	if scene:
		return scene.get_node_or_null("CanvasModulate") as CanvasModulate
	return null


func _find_chaos_manager() -> Node:
	return get_tree().get_first_node_in_group("chaos_manager")
