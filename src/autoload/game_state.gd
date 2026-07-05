extends Node
## Global game state + scene routing. Autoloaded as `GameState`.
##
## Holds the current mode and match configuration and is the single place
## that changes top-level scenes. Keep gameplay logic OUT of here — this is
## routing/config only (see docs/ARCHITECTURE.md).

enum Mode { NONE, VERSUS_1V1, VERSUS_2V2, TRAINING, ARCADE }

signal mode_changed(new_mode: Mode)

var current_mode: Mode = Mode.NONE
## Best-of-N rounds for a match (default best of 3 → first to 2).
var rounds_to_win: int = 2

func set_mode(mode: Mode) -> void:
	if mode == current_mode:
		return
	current_mode = mode
	mode_changed.emit(mode)

func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
