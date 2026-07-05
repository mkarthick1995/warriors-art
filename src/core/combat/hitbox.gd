class_name Hitbox
extends Area2D
## An active attack region for the current move frame. Enabled only during a
## move's active frames; its shape/damage come from FrameData (data-driven).

signal hit_landed(target: Hurtbox, frame: FrameData)

@export var owner_fighter: Node = null

var _frame: FrameData = null
var _already_hit: Array[Node] = []  ## prevents double-hitting the same target per activation.

## Turn this hitbox on for one move frame with its data.
func activate(frame: FrameData) -> void:
	_frame = frame
	monitoring = true
	monitorable = false

## Turn off and clear the per-activation hit list (call when the move's active window ends).
func deactivate() -> void:
	monitoring = false
	_frame = null
	_already_hit.clear()

func _on_area_entered(area: Area2D) -> void:
	if _frame == null:
		return
	var hurt := area as Hurtbox
	if hurt == null or hurt.owner_fighter == owner_fighter:
		return
	if hurt in _already_hit:
		return
	_already_hit.append(hurt)
	hit_landed.emit(hurt, _frame)
