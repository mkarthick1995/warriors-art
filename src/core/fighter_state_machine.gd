class_name FighterStateMachine
extends RefCounted
## Minimal, deterministic state machine for a fighter.
##
## Phase-1 skeleton: owns the current State, gates transitions, and times
## hit/block stun. Per-state behaviour (movement, attack timing, cancel rules)
## is filled in during the vertical slice — see docs/IMPLEMENTATION_PLAN.md.

signal state_changed(from: State, to: State)

enum State {
	IDLE,
	WALK,
	DASH,
	JUMP,
	CROUCH,
	BLOCK,
	ATTACK,
	HITSTUN,
	BLOCKSTUN,
	KNOCKDOWN,
	KO,
	THROW,  ## Attempting/holding a throw (attacker side).
	THROWN,  ## Grabbed by the opponent (victim side).
}

var current: State = State.IDLE
## Ticks spent in the current state (for timing recovery, stun, etc.).
var time_in_state: int = 0

var _stun_ticks: int = 0


## Hard reset for a new round (no state_changed signal — this isn't gameplay).
func reset() -> void:
	current = State.IDLE
	time_in_state = 0
	_stun_ticks = 0


## Call once per fixed tick. Auto-exits stun states when their timer expires.
func tick() -> void:
	time_in_state += 1
	if _stun_ticks > 0:
		_stun_ticks -= 1
		if _stun_ticks == 0 and is_stunned():
			change_to(State.IDLE)


func is_stunned() -> bool:
	return (
		current == State.HITSTUN
		or current == State.BLOCKSTUN
		or current == State.KNOCKDOWN
		or current == State.THROWN
	)


func is_actionable() -> bool:
	return (
		current == State.IDLE
		or current == State.WALK
		or current == State.CROUCH
		or current == State.JUMP
		or current == State.BLOCK
	)


func can_transition(to: State) -> bool:
	if current == State.KO:
		return false
	if is_stunned():
		# Locked in until the stun timer expires; only KO/knockdown interrupts.
		return _stun_ticks <= 0 or to == State.KO or to == State.KNOCKDOWN
	return true


func change_to(to: State) -> void:
	if to == current or not can_transition(to):
		return
	var from := current
	current = to
	time_in_state = 0
	state_changed.emit(from, to)


## Force the fighter into hit/block stun or a knockdown for `ticks`. Bypasses
## can_transition because stun is never refusable; re-entering the same stun
## refreshes it (combos extend stun rather than being ignored).
func enter_stun(kind: State, ticks: int) -> void:
	assert(
		(
			kind == State.HITSTUN
			or kind == State.BLOCKSTUN
			or kind == State.KNOCKDOWN
			or kind == State.THROWN
		)
	)
	if current == State.KO:
		return
	_stun_ticks = ticks
	if current == kind:
		time_in_state = 0
		return
	var from := current
	current = kind
	time_in_state = 0
	state_changed.emit(from, kind)
