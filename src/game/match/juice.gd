extends Node
## Game-feel ("juice") service: screen-shake, hit sparks, KO and technique-cam
## slow-motion. PRESENTATION ONLY — listens to sim signals, never writes sim
## state. Slow-mo uses Engine.time_scale, which stretches real time but never
## changes the tick sequence, so determinism is untouched.

const HEAVY_HIT_DAMAGE := 60  ## At/above this, hits get the big shake.
const KO_SLOWMO := 0.35
const KO_SLOWMO_SECONDS := 0.9
const SUPER_SLOWMO := 0.25
const SUPER_SLOWMO_SECONDS := 0.7

@export var controller: MatchController
@export var camera: MatchCamera

## Guards overlapping slow-mos: only the newest one restores time_scale.
var _slowmo_token := 0


func _ready() -> void:
	for f: Fighter in [controller.p1, controller.p2]:
		f.took_damage.connect(_on_fighter_damaged.bind(f))
		f.knocked_out.connect(_on_fighter_ko.bind(f))
		f.super_started.connect(_on_super_started)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # Never leak slow-mo past this scene.


func _on_fighter_damaged(amount: int, _health_remaining: int, victim: Fighter) -> void:
	camera.add_trauma(0.55 if amount >= HEAVY_HIT_DAMAGE else 0.25)
	_spawn_hit_spark(victim.global_position + Vector2(0, -100))


func _on_fighter_ko(victim: Fighter) -> void:
	camera.add_trauma(1.0)
	_spawn_hit_spark(victim.global_position + Vector2(0, -100))
	_slow_mo(KO_SLOWMO, KO_SLOWMO_SECONDS)


## The "technique cam": a brief slow-motion beat when a super starts.
## TODO(phase2): add the camera punch-in + move-name banner per Game Design §6.
func _on_super_started(_move: MoveData) -> void:
	camera.add_trauma(0.4)
	_slow_mo(SUPER_SLOWMO, SUPER_SLOWMO_SECONDS)


func _slow_mo(time_scale: float, real_seconds: float) -> void:
	_slowmo_token += 1
	var token := _slowmo_token
	Engine.time_scale = time_scale
	# ignore_time_scale=true → the timer runs in real seconds, not slowed ones.
	await get_tree().create_timer(real_seconds, true, false, true).timeout
	if token == _slowmo_token and is_inside_tree():
		Engine.time_scale = 1.0


func _spawn_hit_spark(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.25
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 250.0
	p.initial_velocity_max = 520.0
	p.gravity = Vector2(0, 800)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Color(1.0, 0.85, 0.4)
	p.global_position = at
	add_child(p)
	p.finished.connect(p.queue_free)
