extends Node2D

signal dialogue_finished

@onready var _dialogue_layer: CanvasLayer = $Dialogue
@onready var _rich_label: RichTextLabel = $Dialogue/RichTextLabel
@onready var _exit_door: StaticBody2D = $"Exit Door"
@onready var _shelves: Sprite2D = $"Shelves-Clue"
@onready var _letter: Sprite2D = $"Letter-Goal"

var _typewriter_tween: Tween
var _hide_timer: SceneTreeTimer
var _fade_rect: ColorRect

const INTRO_TEXT := (
	"[center][b]Act I — The Devil is in the Details[/b][/center]\n\n"
	+ "You've slipped inside a [color=red]serial killer's ruined mansion[/color]. "
	+ "The city outside hums like nothing's wrong. [i]Something in your limbs disagrees.[/i]\n\n"
	+ "[b]Move:[/b] WASD or Arrow keys\n"
	+ "[b]Interact:[/b] E\n\n"
	+ "[b]Goal:[/b] Find [b]The Letter[/b] (press [b]E[/b]), "
	+ "then reach the [b]Exit Door[/b] above you.\n"
	+ "[color=gray]Avoid the carpet. Trust nothing that flickers.[/color]"
)

const CARPET_RETURN_TEXT := (
	"[color=red][b]The carpet buckles.[/b][/color]\n\n"
	+ "Not a rug — a [i]trap[/i]. The room lurches and resets, as if the house refuses "
	+ "to let you forget that detail. [color=gray]Stay off the carpet.[/color]\n\n"
	+ "You're back at the exit. Interference will return. "
	+ "Read the [b]shelf clue[/b], find [b]The Letter[/b], then leave."
)


func _ready() -> void:
	_configure_physics_layers()
	_dialogue_layer.visible = false
	_rich_label.bbcode_enabled = true
	_rich_label.visible_characters = 0
	_setup_fade_overlay()
	_connect_signals()
	_start_music()
	var soul := get_node_or_null("/root/SoulManager")
	if soul and soul.has_method("reset_cycle"):
		soul.reset_cycle()
	await get_tree().process_frame
	if soul and soul.consume_carpet_restart():
		show_message(CARPET_RETURN_TEXT, 10.0)
	else:
		show_message(INTRO_TEXT, 10.0)


func _configure_physics_layers() -> void:
	for node in find_children("*", "StaticBody2D", true, false):
		node.collision_layer = 2
		node.collision_mask = 0


func _setup_fade_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "FadeLayer"
	add_child(canvas)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_fade_rect)


func _connect_signals() -> void:
	var soul := get_node_or_null("/root/SoulManager")
	if soul:
		soul.takeover_complete.connect(_on_takeover_complete)
	if _shelves.has_signal("clue_found"):
		_shelves.clue_found.connect(_on_clue_found)
	if _letter.has_signal("letter_collected"):
		_letter.letter_collected.connect(_on_letter_collected)


func _start_music() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music_loop"):
		audio.play_music_loop()


func show_message(bbcode_text: String, duration: float = 10.0) -> void:
	_cancel_active_message()
	_dialogue_layer.visible = true
	_rich_label.text = bbcode_text
	_rich_label.visible_characters = 0

	var char_count := _rich_label.get_total_character_count()
	var type_time := clampf(float(char_count) * 0.028, 0.5, 5.0)

	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(_rich_label, "visible_characters", char_count, type_time)

	_hide_timer = get_tree().create_timer(duration)
	_hide_timer.timeout.connect(_hide_dialogue, CONNECT_ONE_SHOT)


func _hide_dialogue() -> void:
	if _dialogue_layer:
		_dialogue_layer.visible = false
		_rich_label.visible_characters = 0
	dialogue_finished.emit()


func _cancel_active_message() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()


func _on_takeover_complete() -> void:
	show_message("[wave]...you felt it too.[/wave]", 10.0)


func _on_clue_found() -> void:
	show_message(
		"[i]The shelf note burns in your mind. [b]The letter is by the fireplace[/b] — "
		+ "it's always there if you look. Press [b]E[/b] on it to leave.[/i]",
		10.0
	)


func _on_letter_collected() -> void:
	if _exit_door.has_method("open_for_exit"):
		_exit_door.open_for_exit()
	show_message(
		"[center][color=green][b]Exit Door — PASSABLE[/b][/color][/center]\n\n"
		+ "The killer's letter burns in your hand. The north door unlatches. "
		+ "[b]Walk up through the exit[/b] to finish Act I.",
		12.0
	)


func complete_level() -> void:
	show_message(
		"[center][b]Act I Complete[/b][/center]\n\nYou cross the threshold. The mansion shrugs behind you.",
		10.0
	)
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_fade_rect, "color:a", 1.0, 2.0)
	await tween.finished
	print("Level complete — Act I prototype finished.")
	get_tree().paused = true
