extends Node2D
## Training-mode debug overlay: draws hurtboxes (green), active hitboxes (red),
## and a per-fighter state/input readout. Toggle with H.
## PRESENTATION ONLY — reads the sim each render frame.
##
## Must sit at the scene origin with no transform so local drawing coordinates
## equal world coordinates.

const HURTBOX_COLOR := Color(0.2, 1.0, 0.3, 0.25)
const HURTBOX_DISABLED_COLOR := Color(0.5, 0.5, 0.5, 0.15)
const HITBOX_COLOR := Color(1.0, 0.15, 0.15, 0.45)
const TEXT_COLOR := Color(1, 1, 1, 0.9)
## Matches the fixed body/hurtbox shape in Fighter.tscn (feet origin).
const HURTBOX_LOCAL := Rect2(-30, -160, 60, 160)

@export var controller: MatchController

var _font: Font = ThemeDB.fallback_font


func _process(_delta: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).physical_keycode == KEY_H:
			visible = not visible


func _draw() -> void:
	if controller == null:
		return
	for f: Fighter in [controller.p1, controller.p2]:
		_draw_fighter(f)


func _draw_fighter(f: Fighter) -> void:
	var downed := f.state() == FighterStateMachine.State.KNOCKDOWN
	var hurt := Rect2(HURTBOX_LOCAL.position + f.global_position, HURTBOX_LOCAL.size)
	draw_rect(hurt, HURTBOX_DISABLED_COLOR if downed else HURTBOX_COLOR)
	draw_rect(hurt, Color(1, 1, 1, 0.4), false, 1.0)

	var hb := f.debug_hitbox()
	if hb.size != Vector2.ZERO:
		draw_rect(Rect2(hb.position + f.global_position, hb.size), HITBOX_COLOR)

	var state_name: String = FighterStateMachine.State.keys()[f.state()]
	var now: InputButtons = f.inputs().current()
	var buttons := (
		"%s%s%s"
		% ["L" if now.light else "·", "M" if now.medium else "·", "H" if now.heavy else "·"]
	)
	var line := (
		"%s  in:%d %s  hp:%d meter:%d"
		% [state_name, now.numpad(f.facing > 0), buttons, f.health, f.meter]
	)
	draw_string(
		_font,
		f.global_position + Vector2(-110, 40),
		line,
		HORIZONTAL_ALIGNMENT_LEFT,
		240,
		14,
		TEXT_COLOR
	)
