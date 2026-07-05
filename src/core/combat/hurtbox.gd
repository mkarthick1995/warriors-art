class_name Hurtbox
extends Area2D
## The vulnerable region of a fighter. Overlap with an enemy Hitbox → a hit.
## Kept on its own collision layer so hitboxes only test against hurtboxes.

## The fighter that owns this hurtbox (so the resolver can apply damage to it).
@export var owner_fighter: Node = null
