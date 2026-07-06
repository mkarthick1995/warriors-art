extends Node2D
## Title/boot screen. Enter starts a local 1v1; T starts training mode;
## number keys pick P2's character (a stopgap until the Phase 4 select screen).

## Order matches the 1–6 keys shown on the title screen.
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

@onready var _subtitle: Label = $UI/Center/VBox/Subtitle


func _ready() -> void:
	Log.info("Warrior's Art — boot OK.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		GameState.set_mode(GameState.Mode.VERSUS_1V1)
		GameState.change_scene("res://scenes/Match.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).physical_keycode
		if key == KEY_T:
			GameState.set_mode(GameState.Mode.TRAINING)
			GameState.change_scene("res://scenes/Training.tscn")
			return
		var idx := -1
		if key >= KEY_1 and key <= KEY_8:
			idx = key - KEY_1
		elif key >= KEY_KP_1 and key <= KEY_KP_8:  # Numpad works too.
			idx = key - KEY_KP_1
		if idx >= 0:
			# Shift+number picks P1; plain number picks P2.
			if (event as InputEventKey).shift_pressed:
				GameState.p1_character_path = ROSTER[idx]
			else:
				GameState.p2_character_path = ROSTER[idx]
			var picks := [
				_pick_name(GameState.p1_character_path),
				_pick_name(GameState.p2_character_path),
			]
			_subtitle.text = (
				">>> P1: %s   vs   P2: %s <<<\n[Shift+1-8] pick P1 · [Enter] fight · [T] training"
				% picks
			)


func _pick_name(path: String) -> String:
	if path == "":
		return "(default)"
	var data: CharacterData = load(path)
	return "%s — %s" % [data.martial_art, data.state_region]
