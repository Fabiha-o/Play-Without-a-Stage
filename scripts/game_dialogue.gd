class_name GameDialogue
extends RefCounted

## Helper so interactables can reach Mansion.show_message() without an autoload.


static func show(text: String, duration: float = 10.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var scene := tree.current_scene
	if scene and scene.has_method("show_message"):
		scene.show_message(text, duration)
