class_name MoveData
extends Resource
## A single attack/special. A character's moveset is an Array[MoveData].
## Frame data drives all combat math — do not encode these in if-branches.

enum Kind { NORMAL, COMMAND_NORMAL, SPECIAL, SUPER }

@export var display_name: String = ""
@export var kind: Kind = Kind.NORMAL
## Numpad notation + button letter: "L" (standing light), "2M" (crouching
## medium), "236L" (quarter-circle-forward light). Button letter is last.
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


## Total move duration in ticks.
func duration() -> int:
	return startup + active + recovery


## The directional part of `input` ("", "2", "236", ...).
func motion_part() -> String:
	return input.left(input.length() - 1) if input.length() > 1 else ""


## The button part of `input` as an InputButtons name (&"light" etc.).
func button_part() -> StringName:
	if input.is_empty():
		return &""
	match input[input.length() - 1]:
		"L":
			return &"light"
		"M":
			return &"medium"
		"H":
			return &"heavy"
	return &""
