class_name FighterStateMachine
extends RefCounted
## Minimal, deterministic state machine for a fighter.
##
## This is a Phase-1 skeleton: it owns the current State and gates transitions.
## Per-state behaviour (movement, attack timing, cancel rules) is filled in as
## the vertical slice is built — see docs/IMPLEMENTATION_PLAN.md, Phase 1.

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
}

signal state_changed(from: State, to: State)

var current: State = State.IDLE
## Ticks spent in the current state (for timing recovery, stun, etc.).
var time_in_state: int = 0

## Transitions that are always illegal once KO'd, etc. are enforced here.
func can_transition(to: State) -> bool:
	if current == State.KO:
		return false
	# You cannot act out of hit/block stun until it expires (checked by owner via time_in_state).
	if current in [State.HITSTUN, State.BLOCKSTUN] and to not in [State.KO, State.KNOCKDOWN]:
		return false
	return true

func change_to(to: State) -> void:
	if to == current or not can_transition(to):
		return
	var from := current
	current = to
	time_in_state = 0
	state_changed.emit(from, to)

## Call once per fixed tick.
func tick() -> void:
	time_in_state += 1

func is_actionable() -> bool:
	return current in [State.IDLE, State.WALK, State.CROUCH, State.JUMP, State.BLOCK]
