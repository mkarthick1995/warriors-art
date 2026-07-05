class_name Hurtbox
extends Area2D
## The vulnerable region of a fighter. A Hitbox polling its overlaps and
## finding this = a hit. Kept on its own collision layer so hitboxes only
## ever test against hurtboxes.

## The fighter that owns this hurtbox (so the resolver can apply damage to it).
@export var owner_fighter: Node = null


func _ready() -> void:
	# Hurtboxes are passive: detectable by hitboxes, never probing themselves.
	monitoring = false
	monitorable = true
