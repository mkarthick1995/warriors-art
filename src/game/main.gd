extends Node2D
## Title/boot screen. Enter starts a local 1v1 — the vertical-slice flow.
## A real front-end (character/stage select) replaces this in Phase 4.


func _ready() -> void:
	Log.info("Warrior's Art — boot OK.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameState.set_mode(GameState.Mode.VERSUS_1V1)
		GameState.change_scene("res://scenes/Match.tscn")
