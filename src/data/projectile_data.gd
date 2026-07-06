class_name ProjectileData
extends Resource
## A projectile fired by a move (chakram, thrown weapons). Referenced from
## MoveData.projectile; spawned on the move's first active tick. Fully
## deterministic: advanced on the fixed sim tick, no randomness.

## Horizontal speed in pixels/second, in the firer's facing direction.
@export var speed: float = 700.0
## Despawns after this many ticks (stage bounds also despawn it).
@export var lifetime_ticks: int = 200
## Spawn point relative to the fighter origin (x is flipped by facing).
@export var spawn_offset: Vector2 = Vector2(60, -110)
## Damage/stun/knockback and the hitbox rect CENTERED on the projectile
## (e.g. Rect2(-25, -25, 50, 50)).
@export var frame: FrameData
## If true, keeps flying after a hit (default: despawn on first hit).
@export var pierce: bool = false
## Placeholder visual tint until real sprites land.
@export var color: Color = Color(1.0, 0.85, 0.3)
