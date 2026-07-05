class_name Hitbox
extends Area2D
## An active attack region for the current move frame. Enabled only during a
## move's active frames; its shape/damage come from FrameData (data-driven).
##
## Hit detection is POLLED (tick_active), not signal-driven: overlaps are
## resolved at one fixed point in the sim tick so resolution order is
## deterministic (see docs/ARCHITECTURE.md, Determinism).

signal hit_landed(target: Hurtbox, frame: FrameData)

@export var owner_fighter: Node = null

var _frame: FrameData = null
## Targets already hit during this activation — prevents multi-hitting per swing.
var _already_hit: Array[Hurtbox] = []
var _shape_node := CollisionShape2D.new()
var _rect := RectangleShape2D.new()


func _ready() -> void:
	# Hitboxes probe hurtboxes, never the other way round.
	monitoring = false
	monitorable = false
	# Shape is built in code: shapes defined in a shared .tscn would be one
	# resource shared by BOTH fighters — resizing one would resize the other.
	_shape_node.shape = _rect
	add_child(_shape_node)


## Enable for one active frame: position/size the box from data, flipped by
## facing. Safe to call every active tick; the hit list persists per swing.
func activate(frame: FrameData, facing: int) -> void:
	_frame = frame
	_rect.size = frame.hitbox_rect.size
	var center := frame.hitbox_rect.get_center()
	_shape_node.position = Vector2(center.x * facing, center.y)
	monitoring = true


## Turn off and clear the per-swing hit list (when the active window ends).
func deactivate() -> void:
	monitoring = false
	_frame = null
	_already_hit.clear()


## Local-space rect of the active box for debug drawing; zero-size if inactive.
func debug_rect() -> Rect2:
	if not monitoring or _frame == null:
		return Rect2()
	return Rect2(_shape_node.position - _rect.size * 0.5, _rect.size)


## Poll overlaps once per sim tick while active. The owner fighter calls this
## at a fixed point in the tick order.
func tick_active() -> void:
	if _frame == null:
		return
	for area: Area2D in get_overlapping_areas():
		var hurt := area as Hurtbox
		if hurt == null or hurt.owner_fighter == owner_fighter:
			continue
		if hurt in _already_hit:
			continue
		_already_hit.append(hurt)
		hit_landed.emit(hurt, _frame)
