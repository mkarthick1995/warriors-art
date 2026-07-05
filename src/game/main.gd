extends Node2D
## Title/boot screen. Enter starts a local 1v1; T starts training mode.
## A real front-end (character/stage select) replaces this in Phase 4.


func _ready() -> void:
	Log.info("Warrior's Art — boot OK.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameState.set_mode(GameState.Mode.VERSUS_1V1)
		GameState.change_scene("res://scenes/Match.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).physical_keycode == KEY_T:
			GameState.set_mode(GameState.Mode.TRAINING)
			GameState.change_scene("res://scenes/Training.tscn")
