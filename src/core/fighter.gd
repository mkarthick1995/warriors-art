class_name Fighter
extends CharacterBody2D
## A fighter in the sim. Deterministic: all gameplay advances in _physics_process
## at the fixed 60Hz tick. Rendering/VFX/audio must only REACT to this state,
## never drive it (see docs/ARCHITECTURE.md).
##
## Phase-1 skeleton: wires the state machine + input buffer + health/hit-stop.
## Movement/attack execution is filled in during the vertical slice.

signal took_damage(amount: int, health_remaining: int)
signal knocked_out

## Fixed sim step. Matches physics_ticks_per_second in project.godot; use this,
## never wall-clock delta, for gameplay math.
const TICK_DELTA := 1.0 / 60.0

@export var data: CharacterData
## 1 = facing right, -1 = facing left. Auto-managed by the match later.
@export_enum("Left:-1", "Right:1") var facing: int = 1
## Which player controls this fighter (drives the p1_/p2_ input actions).
@export_range(1, 2) var player_index: int = 1

var health: int = 0
var meter: int = 0
## Ticks of hit-stop remaining (sim freeze for game feel). The hit resolver
## applies it to BOTH fighters when a hit connects.
var hitstop_ticks: int = 0

var _sm := FighterStateMachine.new()
var _inputs := InputBuffer.new()


func _ready() -> void:
	assert(data != null, "Fighter needs a CharacterData resource assigned.")
	health = data.max_health


func _physics_process(_delta: float) -> void:
	# Fixed 60Hz sim tick (see project.godot [physics]); never scale by wall-clock.
	_inputs.push(_sample_inputs())
	if hitstop_ticks > 0:
		hitstop_ticks -= 1  # Frozen for game feel; inputs above still buffer.
		return
	_sm.tick()
	if not is_on_floor():
		velocity.y += data.gravity * TICK_DELTA
	# TODO(phase1): drive movement + attacks from _inputs through _sm.
	move_and_slide()


## Apply an incoming hit. Called by the hit resolver, never by the attacker
## directly. `attacker_facing` sets knockback direction (correct on cross-ups,
## where using the victim's own facing would push the wrong way).
func apply_hit(frame: FrameData, attacker_facing: int) -> void:
	if _sm.current == FighterStateMachine.State.KO:
		return
	health = maxi(0, health - frame.damage)
	took_damage.emit(frame.damage, health)
	hitstop_ticks = frame.hitstop
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
