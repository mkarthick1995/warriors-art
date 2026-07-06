class_name MatchController
extends Node2D
## Owns the round loop: best-of-N rounds, round timer, KO/timeout resolution,
## and hit resolution between the two fighters. Runs on the fixed sim tick.

signal round_started(round_number: int)
signal round_ended(winner_index: int)  ## 0 = draw, 1/2 = player.
signal match_ended(winner_index: int)
## A throw grab connected (presentation plays the grab sound).
signal throw_connected

enum Phase { PREROUND, FIGHTING, ROUND_OVER, MATCH_OVER }

const ROUND_SECONDS := 99
const PREROUND_TICKS := 90
const ROUND_OVER_TICKS := 150
const SPAWN_OFFSET := 400.0
## Throw resolution (system-wide; per-character command grabs are later data).
const THROW_RANGE := 100.0
const THROW_TECH_WINDOW := 8  ## Victim ticks to input a tech after the grab.
const THROW_HOLD_TICKS := 26  ## Grab duration before damage resolves.
const THROW_DAMAGE := 90
const THROW_KNOCKBACK := Vector2(320, -260)
const THROW_HITSTOP := 8
const TECH_PUSHBACK := 260.0
const TECH_STUN := 12

@export var p1: Fighter
@export var p2: Fighter
## First to this many round wins takes the match (best of 3 = 2).
## Kept as an export (not read from GameState) so the match is self-contained
## and testable; the front-end configures it when launching a match.
@export var rounds_to_win: int = 2
## Training mode: timer frozen, nothing is scored, fighters refill on KO.
@export var training: bool = false
## Optional character overrides (null = keep the fighter's scene default).
## The future character-select screen sets these; Training uses p2 for the
## dummy. Applied in _ready, before the first round starts.
@export var p1_character: CharacterData
@export var p2_character: CharacterData

var phase: Phase = Phase.PREROUND
var round_number: int = 1
var wins: Array[int] = [0, 0]
var timer_ticks: int = ROUND_SECONDS * 60

## Transient center-screen banner (technique cam move names etc.). The HUD
## shows it whenever no phase message is active.
var announcement := ""

var _phase_ticks: int = 0
var _center := Vector2.ZERO
var _throw_attacker: Fighter = null
var _throw_victim: Fighter = null
var _throw_ticks: int = 0
var _announce_ticks: int = 0


func _ready() -> void:
	assert(p1 != null and p2 != null, "MatchController needs both fighters assigned.")
	if p1_character != null:
		p1.set_character(p1_character)
	if p2_character != null:
		p2.set_character(p2_character)
	# Title-screen pick (fetched dynamically: no compile-time autoload
	# dependency, so headless -s test runs still load this script).
	var gs: Node = get_node_or_null("/root/GameState")
	if p2_character == null and gs != null and gs.p2_character_path != "":
		p2.set_character(load(gs.p2_character_path))
	_center = (p1.global_position + p2.global_position) * 0.5
	p1.landed_hit.connect(_on_hit.bind(p1))
	p2.landed_hit.connect(_on_hit.bind(p2))
	p1.landed_projectile_hit.connect(_on_projectile_hit)
	p2.landed_projectile_hit.connect(_on_projectile_hit)
	p1.knocked_out.connect(_on_ko.bind(2))
	p2.knocked_out.connect(_on_ko.bind(1))
	_start_round()


func _physics_process(_delta: float) -> void:
	_phase_ticks += 1
	if _announce_ticks > 0:
		_announce_ticks -= 1
		if _announce_ticks == 0:
			announcement = ""
	match phase:
		Phase.PREROUND:
			if _phase_ticks >= PREROUND_TICKS:
				_set_fighters_frozen(false)
				phase = Phase.FIGHTING
				_phase_ticks = 0
		Phase.FIGHTING:
			p1.face_opponent(p2.global_position.x)
			p2.face_opponent(p1.global_position.x)
			_tick_throws()
			if not training:
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


## Show a center-screen banner for `ticks` (technique cam move names etc.).
func announce(text: String, ticks: int) -> void:
	announcement = text
	_announce_ticks = ticks


## Central hit resolution: victim takes the hit, BOTH fighters share hit-stop
## (the classic fighting-game freeze that sells impact).
func _on_hit(victim: Fighter, frame: FrameData, attacker: Fighter) -> void:
	if phase != Phase.FIGHTING:
		return
	victim.apply_hit(frame, attacker.facing)
	attacker.hitstop_ticks = frame.hitstop
	victim.hitstop_ticks = frame.hitstop


## Throws are resolved centrally: grab check during the attempt's active
## ticks, then a tech window for the victim, then damage into a knockdown.
## If both attempt on the same tick, P1's is checked first (known bias; a
## simultaneous-throw auto-tech is a TODO).
func _tick_throws() -> void:
	if _throw_attacker == null:
		for pair: Array in [[p1, p2], [p2, p1]]:
			var attacker: Fighter = pair[0]
			var victim: Fighter = pair[1]
			var in_range := (
				absf(attacker.global_position.x - victim.global_position.x) <= THROW_RANGE
			)
			if attacker.is_throw_active() and victim.is_throwable() and in_range:
				_throw_attacker = attacker
				_throw_victim = victim
				_throw_ticks = 0
				attacker.hold_throw()
				victim.get_thrown(THROW_HOLD_TICKS + 30)
				throw_connected.emit()
				break
		return
	_throw_ticks += 1
	if _throw_ticks <= THROW_TECH_WINDOW and _throw_victim.wants_throw():
		var push := TECH_PUSHBACK * float(_throw_attacker.facing)
		_throw_victim.throw_teched(push, TECH_STUN)
		_throw_attacker.throw_teched(-push, TECH_STUN)
		_clear_throw()
		return
	if _throw_ticks >= THROW_HOLD_TICKS:
		var frame := FrameData.new()
		frame.damage = THROW_DAMAGE
		frame.knockback = THROW_KNOCKBACK
		frame.knockdown = true
		frame.hitstun = 20
		frame.hitstop = THROW_HITSTOP
		var attacker_facing := _throw_attacker.facing
		_throw_attacker.hitstop_ticks = THROW_HITSTOP
		_throw_attacker.release_throw()
		var victim := _throw_victim
		_clear_throw()
		victim.apply_hit(frame, attacker_facing)


func _clear_throw() -> void:
	_throw_attacker = null
	_throw_victim = null
	_throw_ticks = 0


## Projectile hits: victim takes the hit and hit-stop; the firer (far away)
## gets none. Knockback follows the projectile's travel direction.
func _on_projectile_hit(victim: Fighter, frame: FrameData, dir: int) -> void:
	if phase != Phase.FIGHTING:
		return
	victim.apply_hit(frame, dir)
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
	if training:
		# Nothing is scored; refill both fighters where they stand.
		_clear_throw()
		p1.reset_for_round(p1.global_position, p1.facing)
		p2.reset_for_round(p2.global_position, p2.facing)
		return
	phase = Phase.ROUND_OVER
	_phase_ticks = 0
	if winner_index > 0:
		wins[winner_index - 1] += 1
	round_ended.emit(winner_index)
	if wins.max() >= rounds_to_win:
		phase = Phase.MATCH_OVER
		match_ended.emit(1 if wins[0] > wins[1] else 2)


func _start_round() -> void:
	_clear_throw()
	for p in get_tree().get_nodes_in_group("projectiles"):
		p.queue_free()  # No projectiles survive into a new round.
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
