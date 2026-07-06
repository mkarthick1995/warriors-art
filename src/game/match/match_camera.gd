class_name MatchCamera
extends Camera2D
## Frames both fighters: tracks their midpoint, widens as they separate, and
## shakes on impact (trauma model: intensity = trauma², decays over time).
## PRESENTATION ONLY — reads fighter positions, never affects the sim.

const FRAME_MARGIN := 500.0
const SHAKE_MAX_OFFSET := 26.0
const TRAUMA_DECAY := 2.2

@export var p1: Node2D
@export var p2: Node2D
@export var min_zoom := 0.75  ## Widest (fighters far apart).
@export var max_zoom := 1.1  ## Tightest (fighters close).
@export var follow_speed := 6.0

var _trauma := 0.0
## Extra zoom-in that decays — the technique cam's "punch-in".
var _punch := 0.0
## Presentation-only randomness — NOT part of the sim, so it doesn't go
## through the seeded Rng autoload.
var _shake_rng := RandomNumberGenerator.new()


## Add shake energy (0–1). Stacks and clamps; big hits pass bigger values.
func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


## Momentary zoom punch-in (technique cam); decays back out over ~a second.
func punch(amount: float) -> void:
	_punch = minf(_punch + amount, 0.35)


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	var mid := (p1.global_position + p2.global_position) * 0.5
	mid.y -= 150.0  # Bias upward so the floor doesn't dominate the frame.
	var spread := absf(p1.global_position.x - p2.global_position.x) + FRAME_MARGIN
	var target_zoom: float = clampf(1920.0 / maxf(spread, 1.0), min_zoom, max_zoom)
	if _punch > 0.0:
		target_zoom *= 1.0 + _punch
		_punch = maxf(0.0, _punch - 0.35 * delta)
	global_position = global_position.lerp(mid, minf(follow_speed * delta, 1.0))
	var z: float = lerpf(zoom.x, target_zoom, minf(follow_speed * delta, 1.0))
	zoom = Vector2(z, z)
	_tick_shake(delta)


func _tick_shake(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
	var strength := _trauma * _trauma * SHAKE_MAX_OFFSET
	offset = Vector2(
		_shake_rng.randf_range(-1.0, 1.0) * strength, _shake_rng.randf_range(-1.0, 1.0) * strength
	)
