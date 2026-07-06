extends CanvasLayer
## Pause menu: Esc freezes the match and shows the controls; Q quits to the
## title. Runs while the tree is paused (PROCESS_MODE_ALWAYS).

const CONTROLS_TEXT := """PAUSED

                 PLAYER 1                    PLAYER 2
Move             W A S D                     Arrow keys
Light / Medium   R / T                       I / O
Throw            R + T together              I + O together
Dash             double-tap A or D           double-tap arrow
Block            hold away from opponent     hold away

Special          down, down-forward, forward + light   (QCF)
EX special       QCF + medium  (needs 250 meter)
Super            QCF, QCF + light  (needs full meter)

Gamepads: pad 1 = P1, pad 2 = P2 (D-pad/stick + face buttons)
Training only: H toggles the hitbox overlay

[Esc] resume        [Q] quit to title"""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var label := Label.new()
	label.text = CONTROLS_TEXT
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	# Monospace-ish alignment for the columns.
	label.add_theme_font_override("font", ThemeDB.fallback_font)
	add_child(label)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_ESCAPE:
			_set_paused(not get_tree().paused)
		KEY_Q:
			if get_tree().paused:
				_set_paused(false)
				Engine.time_scale = 1.0  # Never carry slow-mo out of the match.
				get_tree().change_scene_to_file.call_deferred("res://scenes/Main.tscn")


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
