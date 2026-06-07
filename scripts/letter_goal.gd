extends Sprite2D

signal letter_collected

@export_multiline var letter_message := (
	"[b][color=red]The Letter[/color][/b]\n\n"
	+ "[i]Folded note, handwriting too calm:[/i]\n\n"
	+ "\"I don't kill strangers. I collect [b]mistakes[/b] — the ones who touch what isn't theirs. "
	+ "You found my note. Good. That means you're [i]almost[/i] worth letting leave.\"\n\n"
	+ "\"The front door only opens for guests who take the letter with them. "
	+ "Walk north to the exit. Don't step on my carpet again.\"\n\n"
	+ "[color=green][b]The Exit Door is passable now.[/b][/color]"
)

var _collected := false


func _ready() -> void:
	add_to_group("interactable")
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	z_index = 2


func interact(_player: Node) -> void:
	if _collected:
		GameDialogue.show("[i]The letter is in your pocket. The exit awaits.[/i]", 8.0)
		return
	_collected = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_paper_scrunch"):
		audio.play_paper_scrunch()
	GameDialogue.show(letter_message, 12.0)
	letter_collected.emit()
	modulate = Color(0.9, 0.85, 0.85, 1.0)
