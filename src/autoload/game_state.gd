extends Node
## Global game state + scene routing. Autoloaded as `GameState`.
##
## Holds the current mode and match configuration and is the single place
## that changes top-level scenes. Keep gameplay logic OUT of here — this is
## routing/config only (see docs/ARCHITECTURE.md).

signal mode_changed(new_mode: Mode)

enum Mode { NONE, VERSUS_1V1, VERSUS_2V2, TRAINING, ARCADE }

## The launch roster, in select-screen order (single source of truth).
const ROSTER: Array[String] = [
	"res://src/characters/bengal_lathi/bengal_lathi.tres",
	"res://src/characters/varanasi_musti/varanasi_musti.tres",
	"res://src/characters/tamilnadu_silambam/tamilnadu_silambam.tres",
	"res://src/characters/punjab_gatka/punjab_gatka.tres",
	"res://src/characters/kerala_kalari/kerala_kalari.tres",
	"res://src/characters/manipur_thangta/manipur_thangta.tres",
	"res://src/characters/maharashtra_mardani/maharashtra_mardani.tres",
	"res://src/characters/bihar_parikhanda/bihar_parikhanda.tres",
]

var current_mode: Mode = Mode.NONE
## Best-of-N rounds for a match (default best of 3 → first to 2).
var rounds_to_win: int = 2
## Character override paths chosen on the title screen ("" = scene default).
## The real character-select screen (Phase 4) replaces this.
var p1_character_path := ""
var p2_character_path := ""

## Arcade ladder: every other roster fighter, fought in order with rising
## difficulty. (The MatchController reads these via duck-typed access.)
var arcade_ladder: Array[String] = []
var arcade_index := 0


func set_mode(mode: Mode) -> void:
	if mode == current_mode:
		return
	current_mode = mode
	mode_changed.emit(mode)


func is_arcade() -> bool:
	return current_mode == Mode.ARCADE


func start_arcade(player_path: String) -> void:
	p1_character_path = player_path
	p2_character_path = ""
	arcade_ladder.assign(ROSTER.filter(func(p: String) -> bool: return p != player_path))
	arcade_index = 0


func arcade_opponent() -> String:
	return arcade_ladder[arcade_index]


## Difficulty ramps 1..7 through the ladder.
func arcade_difficulty() -> int:
	return arcade_index + 1


func arcade_total() -> int:
	return arcade_ladder.size()


## Advance after a win; returns true while opponents remain.
func arcade_advance() -> bool:
	arcade_index += 1
	return arcade_index < arcade_ladder.size()


func change_scene(path: String) -> void:
	# Deferred: safe to call from _physics_process / signal handlers mid-tick.
	get_tree().change_scene_to_file.call_deferred(path)
