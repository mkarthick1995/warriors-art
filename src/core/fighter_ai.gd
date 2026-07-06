class_name FighterAI
extends RefCounted
## CPU brain for a fighter. Operates at the INPUT level: each tick it returns
## an InputButtons snapshot, so the sim treats a CPU exactly like a human and
## determinism is preserved. Decisions come from a locally seeded RNG (not the
## shared Rng autoload, to avoid an autoload dependency in sim code) — same
## seed + same fight = same decisions, so replays stay possible.

## Ticks a directional hold lasts, and tap length for buttons.
const TAP_TICKS := 2
const CLOSE_RANGE := 150.0
const THROW_RANGE := 95.0
const FAR_RANGE := 240.0

var _me: Fighter = null
var _opp: Fighter = null
var _difficulty := 3
var _rng := RandomNumberGenerator.new()
## Pending input frames (motions, taps, holds are pre-baked into this queue).
var _queue: Array[InputButtons] = []
var _cooldown := 0


func setup(me: Fighter, opponent: Fighter, difficulty: int, seed_value: int) -> void:
	_me = me
	_opp = opponent
	_difficulty = clampi(difficulty, 1, 7)
	_rng.seed = seed_value


## Called once per sim tick by Fighter._sample_inputs.
func decide() -> InputButtons:
	if not _queue.is_empty():
		return _queue.pop_front()
	if _cooldown > 0:
		_cooldown -= 1
		return InputButtons.new()
	_choose_action()
	if _queue.is_empty():
		return InputButtons.new()
	return _queue.pop_front()


func _choose_action() -> void:
	# Reaction time shrinks as difficulty grows (ticks between decisions).
	_cooldown = maxi(2, 16 - _difficulty * 2)
	if _me.is_stunned() or _me.state() == FighterStateMachine.State.KO:
		return
	var fwd := 1 if _opp.global_position.x > _me.global_position.x else -1
	var dist := absf(_opp.global_position.x - _me.global_position.x)

	# Defend: opponent is swinging nearby → hold back to block.
	var block_chance := 0.12 + 0.1 * _difficulty
	if (
		_opp.state() == FighterStateMachine.State.ATTACK
		and dist < FAR_RANGE
		and _rng.randf() < block_chance
	):
		_push_hold(-fwd, 16 + _rng.randi_range(0, 10))
		return

	# Too far: close in (occasionally by air).
	if dist > FAR_RANGE:
		if _rng.randf() < 0.12:
			_push_jump(fwd)
		else:
			_push_hold(fwd, 12 + _rng.randi_range(0, 12))
		return

	# In range: mix up offense.
	var roll := _rng.randf()
	var special_chance := 0.06 + 0.035 * _difficulty
	if roll < special_chance:
		_push_qcf(fwd, false)
	elif roll < special_chance + 0.05 and _me.meter >= 250:
		_push_qcf(fwd, true)  # EX version.
	elif roll < special_chance + 0.13 and dist < THROW_RANGE:
		_push_throw()
	elif roll < 0.55:
		_push_tap(true, false)  # Light.
	elif roll < 0.78 and dist < CLOSE_RANGE:
		_push_tap(false, true)  # Medium.
	elif roll < 0.9:
		_push_hold(fwd, 6)  # Inch forward.
	else:
		_push_hold(-fwd, 8 + _rng.randi_range(0, 8))  # Give ground.


func _btn(x: int = 0, y: int = 0, light := false, medium := false) -> InputButtons:
	var b := InputButtons.new()
	b.left = x < 0
	b.right = x > 0
	b.up = y < 0
	b.down = y > 0
	b.light = light
	b.medium = medium
	return b


func _push_frames(frame: InputButtons, ticks: int) -> void:
	for i in ticks:
		_queue.append(frame)


func _push_hold(dir_x: int, ticks: int) -> void:
	_push_frames(_btn(dir_x), ticks)


func _push_tap(light: bool, medium: bool) -> void:
	_push_frames(_btn(0, 0, light, medium), TAP_TICKS)
	_queue.append(InputButtons.new())


func _push_throw() -> void:
	_push_frames(_btn(0, 0, true, true), TAP_TICKS)
	_queue.append(InputButtons.new())


func _push_jump(dir_x: int) -> void:
	_push_frames(_btn(dir_x, -1), 3)
	_push_frames(_btn(dir_x), 8)


## Quarter-circle-forward + light (or medium for the EX version).
func _push_qcf(fwd: int, ex: bool) -> void:
	_push_frames(_btn(0, 1), 3)
	_push_frames(_btn(fwd, 1), 3)
	_push_frames(_btn(fwd), 2)
	_push_frames(_btn(fwd, 0, not ex, ex), TAP_TICKS)
	_queue.append(InputButtons.new())
