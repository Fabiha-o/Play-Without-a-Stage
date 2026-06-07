extends Sprite2D

@export_multiline var mock_message := (
	"[color=yellow][b]Congratulations![/b][/color] You found the [s]Legendary Sword of Plot Armor[/s] "
	+ "— a coffee stain on cheap stationery.\n\n"
	+ "[i]Try the shelves. Or don't. The house is laughing.[/i]"
)


func _ready() -> void:
	add_to_group("interactable")


func interact(_player: Node) -> void:
	GameDialogue.show(mock_message, 10.0)
	var audio := get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_comedy()
