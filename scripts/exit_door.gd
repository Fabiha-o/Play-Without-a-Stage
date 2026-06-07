extends StaticBody2D

signal level_complete

@onready var _passage_area: Area2D = get_node_or_null("PassageArea")
@onready var _door_sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _blocker: CollisionShape2D = get_node_or_null("CollisionShape2D2")

var _passable := false
var _completed := false


func _ready() -> void:
	add_to_group("interactable")
	if _passage_area:
		_passage_area.collision_mask = 1
		_passage_area.monitoring = true
		_passage_area.body_entered.connect(_on_passage_entered)


func open_for_exit() -> void:
	_passable = true
	if _blocker:
		_blocker.set_deferred("disabled", true)
	if _door_sprite:
		_door_sprite.modulate = Color(0.85, 1.0, 0.85, 1.0)


func interact(_player: Node) -> void:
	if _completed:
		return
	if not _passable:
		GameDialogue.show("[color=gray]It won't budge.[/color]", 10.0)
		return
	GameDialogue.show(
		"[center][color=green][b]The exit is open.[/b][/color][/center]\n\n"
		+ "Walk through the doorway to leave.",
		8.0
	)


func _on_passage_entered(body: Node2D) -> void:
	if _completed or not _passable:
		return
	if not body.is_in_group("player"):
		return
	_complete_level()


func _complete_level() -> void:
	if _completed:
		return
	_completed = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_door_creak"):
		audio.play_door_creak()
	level_complete.emit()
	var scene := get_tree().current_scene
	if scene and scene.has_method("complete_level"):
		scene.complete_level()
