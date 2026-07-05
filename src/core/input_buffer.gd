class_name InputBuffer
extends RefCounted
## Fixed-size ring buffer of recent InputButtons, one entry per 60Hz tick.
##
## Buffering is what gives fighting games their responsiveness (leniency) and
## enables motion-input parsing. It is deterministic: a match is reproducible
## from the recorded input stream. See docs/ARCHITECTURE.md.

const CAPACITY := 60  ## ~1 second of history at 60Hz.

var _frames: Array[InputButtons] = []
var _head: int = 0


func _init() -> void:
	_frames.resize(CAPACITY)
	for i in CAPACITY:
		_frames[i] = InputButtons.new()


## Record this tick's inputs. Call once per _physics_process tick.
func push(buttons: InputButtons) -> void:
	_head = (_head + 1) % CAPACITY
	_frames[_head] = buttons


## Most recent inputs.
func current() -> InputButtons:
	return _frames[_head]


## Inputs `ticks_ago` in the past (0 == current). Returns oldest if out of range.
func peek(ticks_ago: int) -> InputButtons:
	var idx := (_head - clampi(ticks_ago, 0, CAPACITY - 1) + CAPACITY) % CAPACITY
	return _frames[idx]


## STUB: return true if a motion command (e.g. "236" = quarter-circle-forward)
## was completed within the leniency window. Real parser lands in Phase 1.
func has_motion(_motion: String, _facing_right: bool, _leniency: int = 12) -> bool:
	# TODO(phase1): walk the buffer and match the directional sequence.
	return false
