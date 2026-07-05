class_name CharacterData
extends Resource
## Everything that makes one fighter, as data. A character = animations + this
## resource. Adding a fighter must NOT require engine changes (Phase 2 exit gate;
## see docs/IMPLEMENTATION_PLAN.md).

@export_group("Identity")
@export var display_name: String = ""
@export var state_region: String = ""   ## e.g. "Kerala"
@export var martial_art: String = ""    ## e.g. "Kalaripayattu"

@export_group("Movement (pixels/tick unless noted)")
@export var walk_speed: float = 3.0
@export var dash_speed: float = 6.0
@export var jump_velocity: float = -14.0
@export var gravity: float = 0.8

@export_group("Vitals")
@export var max_health: int = 1000
@export var weight: float = 1.0        ## scales knockback taken

@export_group("Moveset")
@export var moves: Array[MoveData] = []
@export var super_move: MoveData

@export_group("Presentation")
@export var sprite_frames: SpriteFrames
## Percussion instrument for this fighter's rhythm, e.g. "chenda", "dhol".
@export var percussion: String = ""
