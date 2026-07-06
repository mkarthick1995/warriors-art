class_name Projectile
extends Area2D
## A live projectile in the sim. Deterministic: advances on the fixed 60Hz
## tick, polls hurtbox overlaps (same model as Hitbox), despawns on hit,
## lifetime, or stage bounds. Built entirely in code — no scene needed.

signal hit_landed(victim: Fighter, frame: FrameData, dir: int)

const TICK_DELTA := 1.0 / 60.0
## Beyond this |x| the projectile is off-stage (walls are at ±1800).
const STAGE_BOUND := 2000.0

var _owner_fighter: Fighter = null
var _data: ProjectileData = null
var _dir := 1
var _ticks := 0
var _spin: Polygon2D = null


func setup(owner_fighter: Fighter, data: ProjectileData, dir: int) -> void:
	_owner_fighter = owner_fighter
	_data = data
	_dir = dir


func _ready() -> void:
	add_to_group("projectiles")  # The controller sweeps these on round reset.
	collision_layer = 0
	collision_mask = 4  # Hurtboxes.
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _data.frame.hitbox_rect.size
	shape.shape = rect
	shape.position = _data.frame.hitbox_rect.get_center()
	add_child(shape)
	_spin = Polygon2D.new()
	var r := _data.frame.hitbox_rect.size.x * 0.5
	var pts := PackedVector2Array()
	for i in 8:
		pts.append(Vector2.RIGHT.rotated(i * TAU / 8.0) * r)
	_spin.polygon = pts
	_spin.color = _data.color
	add_child(_spin)


func _physics_process(_delta: float) -> void:
	# Fixed-tick sim advance (projectiles fly through hit-stop by design).
	global_position.x += _dir * _data.speed * TICK_DELTA
	_ticks += 1
	if _spin != null:
		_spin.rotation += 0.35  # Presentation only: chakram spin.
	for area: Area2D in get_overlapping_areas():
		var hurt := area as Hurtbox
		if hurt == null or hurt.owner_fighter == _owner_fighter:
			continue
		var victim := hurt.owner_fighter as Fighter
		if victim == null:
			continue
		hit_landed.emit(victim, _data.frame, _dir)
		if not _data.pierce:
			queue_free()
			return
	if _ticks >= _data.lifetime_ticks or absf(global_position.x) > STAGE_BOUND:
		queue_free()
