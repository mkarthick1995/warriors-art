extends Camera2D
## Frames both fighters: tracks their midpoint and widens as they separate.
## PRESENTATION ONLY — reads fighter positions, never affects the sim.

const FRAME_MARGIN := 500.0

@export var p1: Node2D
@export var p2: Node2D
@export var min_zoom := 0.75  ## Widest (fighters far apart).
@export var max_zoom := 1.1  ## Tightest (fighters close).
@export var follow_speed := 6.0


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	var mid := (p1.global_position + p2.global_position) * 0.5
	mid.y -= 150.0  # Bias upward so the floor doesn't dominate the frame.
	var spread := absf(p1.global_position.x - p2.global_position.x) + FRAME_MARGIN
	var target_zoom: float = clampf(1920.0 / maxf(spread, 1.0), min_zoom, max_zoom)
	global_position = global_position.lerp(mid, minf(follow_speed * delta, 1.0))
	var z: float = lerpf(zoom.x, target_zoom, minf(follow_speed * delta, 1.0))
	zoom = Vector2(z, z)
