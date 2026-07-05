class_name FrameData
extends Resource
## One frame's worth of a move's active hitbox + combat properties.
## Authored as data (.tres), never hard-coded — see docs/ARCHITECTURE.md.

## Rectangle of the hitbox in local space, in pixels. Zero size = no hitbox this frame.
@export var hitbox_rect: Rect2 = Rect2()
@export var damage: int = 0
## Frames the victim is stunned on hit.
@export var hitstun: int = 0
## Frames both fighters freeze on connect (game feel).
@export var hitstop: int = 0
## Knockback impulse applied to the victim, in pixels/second. Positive x is
## "away from the attacker" — the resolver flips it by attacker facing.
@export var knockback: Vector2 = Vector2.ZERO
