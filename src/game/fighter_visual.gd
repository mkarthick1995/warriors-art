extends Node2D
## Placeholder presentation for a Fighter until real sprites land: a colored
## body that flips with facing, flashes on hit-stop, and tints by state.
## PRESENTATION ONLY — reads sim state every render frame, never writes it.

@onready var _fighter: Fighter = get_parent()
@onready var _body: Polygon2D = $Body
@onready var _state_label: Label = $StateLabel


func _ready() -> void:
	_body.color = _fighter.body_color


func _process(_delta: float) -> void:
	scale.x = float(_fighter.facing)
	_state_label.scale.x = scale.x  # Keep the debug text readable when flipped.
	_state_label.text = FighterStateMachine.State.keys()[_fighter.state()]
	_body.modulate = _state_tint()


func _state_tint() -> Color:
	if _fighter.hitstop_ticks > 0:
		return Color(1.6, 1.6, 1.6)  # Overbright flash on connect.
	match _fighter.state():
		FighterStateMachine.State.HITSTUN:
			return Color(1.0, 0.4, 0.4)
		FighterStateMachine.State.BLOCKSTUN:
			return Color(0.5, 0.7, 1.0)
		FighterStateMachine.State.ATTACK:
			return Color(1.2, 1.2, 0.9)
		FighterStateMachine.State.KO:
			return Color(0.4, 0.4, 0.4)
	return Color.WHITE
