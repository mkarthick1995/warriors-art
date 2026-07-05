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


## True if `button` went from released to pressed on the current tick.
func just_pressed(button: StringName) -> bool:
	return current().is_pressed(button) and not peek(1).is_pressed(button)


## True if the numpad motion (e.g. "236" = quarter-circle-forward) was
## completed within the last `leniency` ticks. Directions are matched as an
## ordered subsequence, so brief stray inputs between steps don't break it.
func has_motion(motion: String, facing_right: bool, leniency: int = 12) -> bool:
	if motion.is_empty():
		return true
	var idx := 0
	var window := mini(leniency, CAPACITY)
	for t in range(window - 1, -1, -1):  # oldest → newest
		var digit := str(peek(t).numpad(facing_right))
		if digit == motion[idx]:
			idx += 1
			if idx == motion.length():
				return true
	return false
