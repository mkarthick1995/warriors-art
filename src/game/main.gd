extends Node2D
## Title/boot screen. Enter opens the character select; T starts training.


func _ready() -> void:
	Log.info("Warrior's Art — boot OK.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameState.set_mode(GameState.Mode.VERSUS_1V1)
		GameState.change_scene("res://scenes/CharacterSelect.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_T:
				GameState.set_mode(GameState.Mode.TRAINING)
				GameState.change_scene("res://scenes/Training.tscn")
			KEY_A:
				GameState.set_mode(GameState.Mode.ARCADE)
				GameState.change_scene("res://scenes/CharacterSelect.tscn")
