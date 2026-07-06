extends Node
## Game-feel ("juice") service: screen-shake, hit sparks, sound, technique cam
## (slow-mo + banner + punch-in), percussion. PRESENTATION ONLY — listens to
## sim signals, never writes sim state. Slow-mo uses Engine.time_scale, which
## stretches real time but never changes the tick sequence, so determinism is
## untouched.

const HEAVY_HIT_DAMAGE := 60  ## At/above this, hits get the big shake.
const KO_SLOWMO := 0.35
const KO_SLOWMO_SECONDS := 0.9
const SUPER_SLOWMO := 0.25
const SUPER_SLOWMO_SECONDS := 0.7
const SUPER_BANNER_TICKS := 80

@export var controller: MatchController
@export var camera: MatchCamera

## Guards overlapping slow-mos: only the newest one restores time_scale.
var _slowmo_token := 0
## The audio autoload, fetched dynamically so headless -s test runs (which
## compile without autoload globals) still load this script.
@onready var _sfx: Node = get_node_or_null("/root/Sfx")


func _ready() -> void:
	for f: Fighter in [controller.p1, controller.p2]:
		f.took_damage.connect(_on_fighter_damaged.bind(f))
		f.knocked_out.connect(_on_fighter_ko.bind(f))
		f.attack_started.connect(_on_attack_started)
		f.super_started.connect(_on_super_started)
	controller.throw_connected.connect(_on_throw_connected)
	if _sfx != null:
		_sfx.play_percussion(controller.p1.data.percussion)


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # Never leak slow-mo past this scene.
	if _sfx != null:
		_sfx.stop_percussion()


func _on_fighter_damaged(amount: int, _health_remaining: int, victim: Fighter) -> void:
	camera.add_trauma(0.55 if amount >= HEAVY_HIT_DAMAGE else 0.25)
	_spawn_hit_spark(victim.global_position + Vector2(0, -100))
	if _sfx == null:
		return
	if victim.state() == FighterStateMachine.State.BLOCKSTUN:
		_sfx.block()
	else:
		_sfx.hit(amount)


func _on_fighter_ko(victim: Fighter) -> void:
	camera.add_trauma(1.0)
	_spawn_hit_spark(victim.global_position + Vector2(0, -100))
	if _sfx != null:
		_sfx.ko()
	_slow_mo(KO_SLOWMO, KO_SLOWMO_SECONDS)


func _on_attack_started(_move: MoveData) -> void:
	if _sfx != null:
		_sfx.whiff()


func _on_throw_connected() -> void:
	camera.add_trauma(0.3)
	if _sfx != null:
		_sfx.throw_grab()


## The technique cam: slow-mo beat + camera punch-in + the move's name as a
## center-screen banner (Game Design §6).
func _on_super_started(move: MoveData) -> void:
	camera.add_trauma(0.4)
	camera.punch(0.22)
	controller.announce(move.display_name.to_upper(), SUPER_BANNER_TICKS)
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
