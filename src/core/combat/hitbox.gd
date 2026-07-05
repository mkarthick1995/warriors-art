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


func _ready() -> void:
	# Hitboxes probe hurtboxes, never the other way round.
	monitoring = false
	monitorable = false


## Turn this hitbox on with one active frame's data.
func activate(frame: FrameData) -> void:
	_frame = frame
	monitoring = true


## Turn off and clear the per-activation hit list (when the active window ends).
func deactivate() -> void:
	monitoring = false
	_frame = null
	_already_hit.clear()


## Poll overlaps once per sim tick while active. The owner (hit resolver)
## calls this at a fixed point in the tick order.
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
