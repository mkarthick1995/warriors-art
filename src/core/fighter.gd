class_name Fighter
extends CharacterBody2D
## A fighter in the sim. Deterministic: all gameplay advances in _physics_process
## at the fixed 60Hz tick. Rendering/VFX/audio must only REACT to this state,
## never drive it (see docs/ARCHITECTURE.md).

## Emitted when this fighter's attack connects; the MatchController resolves it.
signal landed_hit(victim: Fighter, frame: FrameData)
signal took_damage(amount: int, health_remaining: int)
signal knocked_out
## Emitted when a technique_cam move starts — presentation runs the slow-mo cam.
signal super_started(move: MoveData)

## Fixed sim step. Matches physics_ticks_per_second in project.godot; use this,
## never wall-clock delta, for gameplay math.
const TICK_DELTA := 1.0 / 60.0
const MAX_METER := 1000
## Blockstun is shorter than hitstun so blocking gives frame advantage.
const BLOCKSTUN_REDUCTION := 6
## Blocked hits deal this fraction of damage as chip (never below 1 health).
const CHIP_DIVISOR := 10
const BLOCK_PUSHBACK_SCALE := 0.6
const DASH_TICKS := 14
const BACKDASH_TICKS := 10
const KNOCKDOWN_TICKS := 45
## Extra motion-window ticks granted per motion digit (longer inputs need
## more time: QCF gets ~20 ticks, a double-QCF super ~32).
const MOTION_LENIENCY_BASE := 8
const MOTION_LENIENCY_PER_DIGIT := 4

@export var data: CharacterData
## 1 = facing right, -1 = facing left. The MatchController updates this.
@export_enum("Left:-1", "Right:1") var facing: int = 1
## Which player controls this fighter (drives the p1_/p2_ input actions).
@export_range(1, 2) var player_index: int = 1
## Placeholder body tint until real sprites land (presentation reads this).
@export var body_color: Color = Color(0.9, 0.5, 0.2)

var health: int = 0
var meter: int = 0
## Ticks of sim freeze for game feel. The MatchController sets it on BOTH
## fighters when a hit connects.
var hitstop_ticks: int = 0

var _sm := FighterStateMachine.new()
var _inputs := InputBuffer.new()
var _current_move: MoveData = null
## Moves sorted longest-motion-first so "236L" wins over "2L" wins over "L".
var _sorted_moves: Array[MoveData] = []
var _dash_dir: int = 1
## Set per hit from FrameData.knockdown: fall into knockdown when landing.
var _knockdown_pending: bool = false

@onready var _hitbox: Hitbox = $Hitbox
@onready var _hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	assert(data != null, "Fighter needs a CharacterData resource assigned.")
	health = data.max_health
	_hitbox.owner_fighter = self
	_hurtbox.owner_fighter = self
	_hitbox.hit_landed.connect(_on_hitbox_landed)
	_sorted_moves = data.moves.duplicate()
	if data.super_move != null:
		_sorted_moves.append(data.super_move)
	_sorted_moves.sort_custom(
		func(a: MoveData, b: MoveData) -> bool:
			return a.motion_part().length() > b.motion_part().length()
	)


func _physics_process(_delta: float) -> void:
	# Fixed 60Hz sim tick (see project.godot [physics]); never scale by wall-clock.
	_inputs.push(_sample_inputs())
	if hitstop_ticks > 0:
		hitstop_ticks -= 1  # Frozen for game feel; inputs above still buffer.
		return
	_sm.tick()
	_tick_state()
	# Downed fighters can't be hit (no OTG hits for now).
	_hurtbox.monitorable = _sm.current != FighterStateMachine.State.KNOCKDOWN
	move_and_slide()


## Apply an incoming hit. Called by the MatchController, never by the attacker
## directly. `attacker_facing` sets knockback direction (correct on cross-ups).
func apply_hit(frame: FrameData, attacker_facing: int) -> void:
	if _sm.current == FighterStateMachine.State.KO:
		return
	if _is_blocking(attacker_facing):
		_apply_blocked_hit(frame, attacker_facing)
		return
	health = maxi(0, health - frame.damage)
	took_damage.emit(frame.damage, health)
	_interrupt_attack()
	_knockdown_pending = frame.knockdown
	# Weight scales knockback taken (heavier fighters move less) — NOT damage.
	# Only x flips with facing; vertical knockback keeps its authored direction.
	var kb := Vector2(frame.knockback.x * attacker_facing, frame.knockback.y)
	velocity = kb / maxf(data.weight, 0.1)
	if health == 0:
		_sm.change_to(FighterStateMachine.State.KO)
		knocked_out.emit()
	else:
		_sm.enter_stun(FighterStateMachine.State.HITSTUN, frame.hitstun)


func state() -> FighterStateMachine.State:
	return _sm.current


## Read-only access for the training-mode overlay (debug display).
func inputs() -> InputBuffer:
	return _inputs


## Active hitbox rect in this fighter's local space, or zero-size when inactive.
func debug_hitbox() -> Rect2:
	return _hitbox.debug_rect()


func is_stunned() -> bool:
	return _sm.is_stunned()


## Fresh state for a new round. Meter deliberately carries over between rounds.
func reset_for_round(spawn: Vector2, face: int) -> void:
	global_position = spawn
	velocity = Vector2.ZERO
	facing = face
	health = data.max_health
	hitstop_ticks = 0
	_knockdown_pending = false
	_interrupt_attack()
	_sm.reset()


## The MatchController calls this while both fighters are grounded and free.
func face_opponent(opponent_x: float) -> void:
	if _sm.is_actionable() and is_on_floor():
		facing = 1 if opponent_x > global_position.x else -1


func _tick_state() -> void:
	if _sm.is_stunned():  # HITSTUN / BLOCKSTUN / KNOCKDOWN
		_tick_stunned()
		return
	match _sm.current:
		FighterStateMachine.State.IDLE, FighterStateMachine.State.WALK:
			_tick_grounded()
		FighterStateMachine.State.CROUCH:
			_tick_crouch()
		FighterStateMachine.State.JUMP:
			_tick_airborne()
		FighterStateMachine.State.DASH:
			_tick_dash()
		FighterStateMachine.State.ATTACK:
			_tick_attack()
		FighterStateMachine.State.KO:
			_apply_gravity()
			velocity.x = move_toward(velocity.x, 0.0, data.walk_speed * TICK_DELTA * 10.0)
		_:
			_apply_gravity()


func _tick_grounded() -> void:
	if not is_on_floor():  # Walked off an edge or exited a state mid-air.
		_sm.change_to(FighterStateMachine.State.JUMP)
		return
	if _try_start_attack():
		return
	# No dash while a down-based motion (QCF etc.) is being rolled — the
	# re-tapped forward of a double-QCF super must not read as a dash.
	if not _recent_down():
		if _inputs.double_tapped(1):
			_start_dash(1)
			return
		if _inputs.double_tapped(-1):
			_start_dash(-1)
			return
	var now := _inputs.current()
	var x := now.direction().x
	if _inputs_jump_pressed():
		velocity.y = data.jump_velocity
		velocity.x = x * data.walk_speed
		_sm.change_to(FighterStateMachine.State.JUMP)
		return
	if now.direction().y > 0:
		velocity.x = 0
		_sm.change_to(FighterStateMachine.State.CROUCH)
		return
	velocity.x = x * data.walk_speed
	_sm.change_to(FighterStateMachine.State.WALK if x != 0 else FighterStateMachine.State.IDLE)


func _tick_crouch() -> void:
	velocity.x = 0
	if _try_start_attack():
		return
	if _inputs.current().direction().y <= 0:
		_sm.change_to(FighterStateMachine.State.IDLE)


func _tick_airborne() -> void:
	_apply_gravity()
	if _try_start_attack():
		return
	if is_on_floor() and velocity.y >= 0:
		velocity.x = 0
		_sm.change_to(FighterStateMachine.State.IDLE)


## Dash covers a fixed distance in a fixed time; not actionable until it ends.
func _start_dash(dir: int) -> void:
	_dash_dir = dir
	velocity.x = dir * data.dash_speed
	_sm.change_to(FighterStateMachine.State.DASH)


func _tick_dash() -> void:
	velocity.x = _dash_dir * data.dash_speed
	var duration := DASH_TICKS if _dash_dir == facing else BACKDASH_TICKS
	if _sm.time_in_state >= duration:
		velocity.x = 0
		_sm.change_to(FighterStateMachine.State.IDLE)


func _tick_attack() -> void:
	_apply_gravity()
	var m := _current_move
	if m == null:  # Defensive: state and move should always agree.
		_sm.change_to(FighterStateMachine.State.IDLE)
		return
	var t := _sm.time_in_state
	var active_start := m.startup
	var active_end := m.startup + m.active
	if t >= active_start and t < active_end and not m.hitbox_frames.is_empty():
		var fi := mini(t - active_start, m.hitbox_frames.size() - 1)
		_hitbox.activate(m.hitbox_frames[fi], facing)
		_hitbox.tick_active()
	elif t >= active_end:
		_hitbox.deactivate()
	if t >= m.duration():
		_current_move = null
		var landed := is_on_floor()
		_sm.change_to(FighterStateMachine.State.IDLE if landed else FighterStateMachine.State.JUMP)


func _tick_stunned() -> void:
	_apply_gravity()
	if _sm.current == FighterStateMachine.State.HITSTUN and _knockdown_pending:
		if is_on_floor() and velocity.y >= 0:
			_knockdown_pending = false
			velocity.x = 0
			_sm.enter_stun(FighterStateMachine.State.KNOCKDOWN, KNOCKDOWN_TICKS)
		else:
			# Launched: held in air-stun until landing, then falls into knockdown.
			_sm.enter_stun(FighterStateMachine.State.HITSTUN, 2)
		return
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, data.walk_speed * TICK_DELTA * 8.0)


func _apply_gravity() -> void:
	if not is_on_floor():
		velocity.y += data.gravity * TICK_DELTA


## Try to start the best matching attack for this tick's inputs.
func _try_start_attack() -> bool:
	var airborne := not is_on_floor()
	for move in _sorted_moves:
		if move.air != airborne:
			continue
		if move.meter_cost > meter:
			continue
		if not _inputs.just_pressed(move.button_part()):
			continue
		if not _move_input_satisfied(move):
			continue
		meter -= move.meter_cost
		if not airborne:
			velocity.x = 0  # Air attacks keep jump momentum.
		_current_move = move
		_sm.change_to(FighterStateMachine.State.ATTACK)
		if move.technique_cam:
			super_started.emit(move)
		return true
	return false


func _move_input_satisfied(move: MoveData) -> bool:
	var motion := move.motion_part()
	if motion == "2":  # Crouching normal: just needs down held.
		return _inputs.current().direction().y > 0
	var leniency := MOTION_LENIENCY_BASE + motion.length() * MOTION_LENIENCY_PER_DIGIT
	return _inputs.has_motion(motion, facing > 0, leniency)


func _inputs_jump_pressed() -> bool:
	return _inputs.current().direction().y < 0 and _inputs.peek(1).direction().y >= 0


func _recent_down(window: int = 8) -> bool:
	for t in window:
		if _inputs.peek(t).direction().y > 0:
			return true
	return false


## Holding away from the attacker while grounded and free = block.
func _is_blocking(attacker_facing: int) -> bool:
	if not is_on_floor() or not _sm.is_actionable():
		return false
	var x := _inputs.current().direction().x
	return x != 0 and x == attacker_facing


func _apply_blocked_hit(frame: FrameData, attacker_facing: int) -> void:
	var chip := frame.damage / CHIP_DIVISOR
	health = maxi(1, health - chip)  # Chip never KOs.
	if chip > 0:
		took_damage.emit(chip, health)
	velocity.x = frame.knockback.x * attacker_facing * BLOCK_PUSHBACK_SCALE
	_sm.enter_stun(
		FighterStateMachine.State.BLOCKSTUN, maxi(1, frame.hitstun - BLOCKSTUN_REDUCTION)
	)


func _interrupt_attack() -> void:
	_current_move = null
	_hitbox.deactivate()


func _on_hitbox_landed(target: Hurtbox, frame: FrameData) -> void:
	if _current_move != null:
		meter = mini(MAX_METER, meter + _current_move.meter_gain)
	var victim := target.owner_fighter as Fighter
	if victim != null:
		landed_hit.emit(victim, frame)


## Read this player's mapped actions into an InputButtons snapshot.
func _sample_inputs() -> InputButtons:
	var b := InputButtons.new()
	var p := "p%d_" % player_index
	b.left = Input.is_action_pressed(p + "left")
	b.right = Input.is_action_pressed(p + "right")
	b.up = Input.is_action_pressed(p + "up")
	b.down = Input.is_action_pressed(p + "down")
	b.light = Input.is_action_pressed(p + "light")
	b.medium = Input.is_action_pressed(p + "medium")
	b.heavy = Input.is_action_pressed(p + "heavy")
	return b
