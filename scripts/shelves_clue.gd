extends Sprite2D

signal clue_found

const HIDDEN_ALPHA := 0.42
const REVEALED_ALPHA := 1.0

@export_multiline var clue_message := (
	"[b][color=yellow]Clue — margin note on the shelves[/color][/b]\n\n"
	+ "[i]Ink cramped in the binding:[/i]\n\n"
	+ "\"Guests never look up. I left the truth [b]above the fireplace[/b] — "
	+ "tucked in the soot line where the [b]mantel meets smoke[/b]. "
	+ "A folded page. The devil is in the details.\"\n\n"
	+ "[color=cyan]→ Search the fireplace. Press [b]E[/b] when you find the letter.[/color]"
)

var _revealed := false
var _read := false
var _pulse_tween: Tween


func _ready() -> void:
	add_to_group("interactable")
	modulate = Color(1.0, 1.0, 1.0, HIDDEN_ALPHA)


func reveal() -> void:
	if _revealed:
		return
	_revealed = true
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", REVEALED_ALPHA, 0.35)
	tween.tween_property(self, "modulate", Color(1.15, 1.1, 0.85, 1.0), 0.25)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	_start_pulse()


func _start_pulse() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "modulate", Color(1.1, 1.05, 0.9, 1.0), 0.7)
	_pulse_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.7)


func interact(_player: Node) -> void:
	if not _revealed or modulate.a < 0.35:
		GameDialogue.show(
			"[color=gray]Old shelves. Something's scratched into the wood — "
			+ "wait for the interference to sharpen your eye.[/color]",
			10.0
		)
		return
	if _read:
		GameDialogue.show(clue_message, 10.0)
		return
	_read = true
	GameDialogue.show(clue_message, 12.0)
	clue_found.emit()
	var soul := get_node_or_null("/root/SoulManager")
	if soul and soul.has_method("notify_shelves_read"):
		soul.notify_shelves_read()
