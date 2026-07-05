class_name Fighter
extends CharacterBody2D
## A fighter in the sim. Deterministic: all gameplay advances in _physics_process
## at the fixed 60Hz tick. Rendering/VFX/audio must only REACT to this state,
## never drive it (see docs/ARCHITECTURE.md).
##
## Phase-1 skeleton: wires the state machine + input buffer + a health value.
## Movement/attack execution is filled in during the vertical slice.

signal took_damage(amount: int, health_remaining: int)
signal ko()

@export var data: CharacterData
## 1 = facing right, -1 = facing left. Auto-managed by the match later.
@export var facing: int = 1
## Which player controls this fighter (drives the p1_/p2_ input actions).
@export var player_index: int = 1

var health: int = 0
var meter: int = 0
var _sm := FighterStateMachine.new()
var _inputs := InputBuffer.new()

func _ready() -> void:
	assert(data != null, "Fighter needs a CharacterData resource assigned.")
	health = data.max_health

func _physics_process(_delta: float) -> void:
	# Fixed-tick sim. NOTE: use the fixed tick, not _delta wall-clock, for gameplay.
	_inputs.push(_sample_inputs())
	_sm.tick()
	# TODO(phase1): read _inputs, drive movement + attacks through _sm, apply gravity.

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

## Apply an incoming hit. Called by the match/hit-resolver, not by the attacker directly.
func apply_hit(frame: FrameData) -> void:
	if _sm.current == FighterStateMachine.State.KO:
		return
	var dmg := int(round(frame.damage * data.weight))
	health = maxi(0, health - dmg)
	took_damage.emit(dmg, health)
	velocity += frame.knockback * float(-facing)
	if health == 0:
		_sm.change_to(FighterStateMachine.State.KO)
		ko.emit()
	else:
		_sm.change_to(FighterStateMachine.State.HITSTUN)

func state() -> FighterStateMachine.State:
	return _sm.current
