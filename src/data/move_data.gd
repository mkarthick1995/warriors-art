class_name MoveData
extends Resource
## A single attack/special. A character's moveset is an Array[MoveData].
## Frame data drives all combat math — do not encode these in if-branches.

enum Kind { NORMAL, COMMAND_NORMAL, SPECIAL, SUPER }

@export var display_name: String = ""
@export var kind: Kind = Kind.NORMAL
## Motion input, e.g. "236LP" (QCF + light) or "5MP" (standing medium). Empty = auto.
@export var input: String = ""
@export var animation_name: String = ""

@export_group("Timing (in 60Hz ticks)")
@export var startup: int = 0
@export var active: int = 0
@export var recovery: int = 0
## Frame advantage on block (negative = punishable).
@export var on_block: int = 0

@export_group("Economy")
@export var meter_gain: int = 0
@export var meter_cost: int = 0

@export_group("Per-frame hit data")
## One FrameData per active frame (or a shared one). Length ideally == active.
@export var hitbox_frames: Array[FrameData] = []

@export_group("Presentation")
## Super only: trigger the slow-motion technique cam on activation.
@export var technique_cam: bool = false
