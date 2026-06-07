extends Area2D

var _triggered := false

@onready var _canvas_modulate: CanvasModulate = get_node("../../CanvasModulate")


func _ready() -> void:
	collision_mask = 1
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	monitoring = false
	await _flash_red()
	var soul := get_node_or_null("/root/SoulManager")
	if soul:
		soul.mark_carpet_restart()
	await get_tree().create_timer(0.6).timeout
	get_tree().reload_current_scene()


func _flash_red() -> void:
	if _canvas_modulate == null:
		var scene := get_tree().current_scene
		if scene:
			_canvas_modulate = scene.get_node_or_null("CanvasModulate") as CanvasModulate
	if _canvas_modulate:
		var original := _canvas_modulate.color
		var tween := create_tween()
		tween.tween_property(_canvas_modulate, "color", Color(0.85, 0.12, 0.12, 1.0), 0.12)
		tween.tween_property(_canvas_modulate, "color", original, 0.18)
		await tween.finished
	else:
		await get_tree().create_timer(0.3).timeout
