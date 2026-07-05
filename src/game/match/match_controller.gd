class_name MatchController
extends Node2D
## Owns the round loop: best-of-N rounds, round timer, KO/timeout resolution,
## and hit resolution between the two fighters. Runs on the fixed sim tick.

signal round_started(round_number: int)
signal round_ended(winner_index: int)  ## 0 = draw, 1/2 = player.
signal match_ended(winner_index: int)

enum Phase { PREROUND, FIGHTING, ROUND_OVER, MATCH_OVER }

const ROUND_SECONDS := 99
const PREROUND_TICKS := 90
const ROUND_OVER_TICKS := 150
const SPAWN_OFFSET := 400.0

@export var p1: Fighter
@export var p2: Fighter
## First to this many round wins takes the match (best of 3 = 2).
## Kept as an export (not read from GameState) so the match is self-contained
## and testable; the front-end configures it when launching a match.
@export var rounds_to_win: int = 2

var phase: Phase = Phase.PREROUND
var round_number: int = 1
var wins: Array[int] = [0, 0]
var timer_ticks: int = ROUND_SECONDS * 60

var _phase_ticks: int = 0
var _center := Vector2.ZERO


func _ready() -> void:
	assert(p1 != null and p2 != null, "MatchController needs both fighters assigned.")
	_center = (p1.global_position + p2.global_position) * 0.5
	p1.landed_hit.connect(_on_hit.bind(p1))
	p2.landed_hit.connect(_on_hit.bind(p2))
	p1.knocked_out.connect(_on_ko.bind(2))
	p2.knocked_out.connect(_on_ko.bind(1))
	_start_round()


func _physics_process(_delta: float) -> void:
	_phase_ticks += 1
	match phase:
		Phase.PREROUND:
			if _phase_ticks >= PREROUND_TICKS:
				_set_fighters_frozen(false)
				phase = Phase.FIGHTING
				_phase_ticks = 0
		Phase.FIGHTING:
			p1.face_opponent(p2.global_position.x)
			p2.face_opponent(p1.global_position.x)
			timer_ticks -= 1
			if timer_ticks <= 0:
				_resolve_timeout()
		Phase.ROUND_OVER:
			if _phase_ticks >= ROUND_OVER_TICKS:
				_start_round()
		Phase.MATCH_OVER:
			if Input.is_action_just_pressed("ui_accept"):
				_rematch()


func time_left_seconds() -> int:
	return ceili(timer_ticks / 60.0)


## Central hit resolution: victim takes the hit, BOTH fighters share hit-stop
## (the classic fighting-game freeze that sells impact).
func _on_hit(victim: Fighter, frame: FrameData, attacker: Fighter) -> void:
	if phase != Phase.FIGHTING:
		return
	victim.apply_hit(frame, attacker.facing)
	attacker.hitstop_ticks = frame.hitstop
	victim.hitstop_ticks = frame.hitstop


func _on_ko(winner_index: int) -> void:
	if phase != Phase.FIGHTING:
		return
	_end_round(winner_index)


func _resolve_timeout() -> void:
	var winner := 0
	if p1.health > p2.health:
		winner = 1
	elif p2.health > p1.health:
		winner = 2
	_end_round(winner)


func _end_round(winner_index: int) -> void:
	phase = Phase.ROUND_OVER
	_phase_ticks = 0
	if winner_index > 0:
		wins[winner_index - 1] += 1
	round_ended.emit(winner_index)
	if wins.max() >= rounds_to_win:
		phase = Phase.MATCH_OVER
		match_ended.emit(1 if wins[0] > wins[1] else 2)


func _start_round() -> void:
	round_number = wins[0] + wins[1] + 1
	timer_ticks = ROUND_SECONDS * 60
	p1.reset_for_round(_center + Vector2(-SPAWN_OFFSET, 0), 1)
	p2.reset_for_round(_center + Vector2(SPAWN_OFFSET, 0), -1)
	phase = Phase.PREROUND
	_phase_ticks = 0
	_set_fighters_frozen(true)
	round_started.emit(round_number)


func _rematch() -> void:
	wins = [0, 0]
	# Meter resets on a full rematch (it carries over between rounds only).
	p1.meter = 0
	p2.meter = 0
	_start_round()


## During pre-round/round-over the fighters don't advance their sim.
func _set_fighters_frozen(frozen: bool) -> void:
	p1.set_physics_process(not frozen)
	p2.set_physics_process(not frozen)
