extends Node2D
## Fighter presentation: plays SpriteFrames animations driven by sim state,
## or falls back to the colored placeholder box when the character has no
## sprites yet. Flips with facing, flashes on hit-stop, tints by state.
## PRESENTATION ONLY — reads sim state every render frame, never writes it.

## Sim state → animation name (attack states use the move's animation_name).
const STATE_ANIMS := {
	FighterStateMachine.State.IDLE: &"idle",
	FighterStateMachine.State.WALK: &"walk",
	FighterStateMachine.State.DASH: &"walk",
	FighterStateMachine.State.JUMP: &"jump",
	FighterStateMachine.State.CROUCH: &"crouch",
	FighterStateMachine.State.BLOCK: &"idle",
	FighterStateMachine.State.HITSTUN: &"hit",
	FighterStateMachine.State.BLOCKSTUN: &"hit",
	FighterStateMachine.State.KNOCKDOWN: &"knockdown",
	FighterStateMachine.State.KO: &"knockdown",
	FighterStateMachine.State.THROW: &"jab",
	FighterStateMachine.State.THROWN: &"hit",
}

var _use_sprites := false
## Tracks character swaps (set_character can run after our _ready).
var _configured_data: CharacterData = null

@onready var _fighter: Fighter = get_parent()
@onready var _body: Polygon2D = $Body
@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _state_label: Label = $StateLabel


func _ready() -> void:
	_configure()


func _configure() -> void:
	_configured_data = _fighter.data
	_use_sprites = _fighter.data != null and _fighter.data.sprite_frames != null
	_sprite.visible = _use_sprites
	_body.visible = not _use_sprites
	if _use_sprites:
		_sprite.sprite_frames = _fighter.data.sprite_frames
	else:
		_body.color = _fighter.body_color


func _process(_delta: float) -> void:
	if _fighter.data != _configured_data:
		_configure()
	scale.x = float(_fighter.facing)
	_state_label.scale.x = scale.x  # Keep the debug text readable when flipped.
	_state_label.text = FighterStateMachine.State.keys()[_fighter.state()]
	var tint := _state_tint()
	if _use_sprites:
		_play_current_animation()
		# body_color identifies the player; state tint layers on top.
		_sprite.modulate = _fighter.body_color.lerp(Color.WHITE, 0.35) * tint
	else:
		_body.modulate = tint


func _play_current_animation() -> void:
	var anim: StringName = STATE_ANIMS.get(_fighter.state(), &"idle")
	var move := _fighter.current_move()
	if _fighter.state() == FighterStateMachine.State.ATTACK and move != null:
		anim = StringName(move.animation_name)
	if not _sprite.sprite_frames.has_animation(anim):
		anim = &"idle"
	# Restart when the animation changes OR the state just re-entered (a
	# second identical jab must replay its one-shot animation).
	if _sprite.animation != anim or (_fighter.state_ticks() <= 1 and not _sprite.is_playing()):
		_sprite.play(anim)
	# Freeze the animation during hit-stop so the freeze reads visually.
	_sprite.speed_scale = 0.0 if _fighter.hitstop_ticks > 0 else 1.0


func _state_tint() -> Color:
	if _fighter.hitstop_ticks > 0:
		return Color(1.6, 1.6, 1.6)  # Overbright flash on connect.
	match _fighter.state():
		FighterStateMachine.State.HITSTUN, FighterStateMachine.State.THROWN:
			return Color(1.0, 0.4, 0.4)
		FighterStateMachine.State.BLOCKSTUN:
			return Color(0.5, 0.7, 1.0)
		FighterStateMachine.State.ATTACK:
			return Color(1.2, 1.2, 0.9)
		FighterStateMachine.State.KO:
			return Color(0.4, 0.4, 0.4)
	return Color.WHITE
