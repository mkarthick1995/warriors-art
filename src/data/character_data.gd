class_name CharacterData
extends Resource
## Everything that makes one fighter, as data. A character = animations + this
## resource. Adding a fighter must NOT require engine changes (Phase 2 exit gate;
## see docs/IMPLEMENTATION_PLAN.md).

@export_group("Identity")
@export var display_name: String = ""
@export var state_region: String = ""  ## e.g. "Kerala"
@export var martial_art: String = ""  ## e.g. "Kalaripayattu"

## Speeds/impulses are pixels/second, integrated at the fixed 60Hz tick
## (CharacterBody2D convention). Deterministic because the tick delta is fixed.
@export_group("Movement (pixels/second)")
@export var walk_speed: float = 180.0
@export var dash_speed: float = 420.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2200.0

@export_group("Vitals")
@export var max_health: int = 1000
## Scales knockback taken (heavier = pushed less). Never scales damage.
@export var weight: float = 1.0

@export_group("Moveset")
@export var moves: Array[MoveData] = []
@export var super_move: MoveData

@export_group("Presentation")
@export var sprite_frames: SpriteFrames
## Percussion instrument for this fighter's rhythm, e.g. "chenda", "dhol".
@export var percussion: String = ""
