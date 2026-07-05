class_name InputButtons
extends RefCounted
## The digital input state for one player on one tick. Deliberately tiny and
## copyable so it can be stored per-tick and (later) sent over the network.

var left: bool = false
var right: bool = false
var up: bool = false
var down: bool = false
var light: bool = false
var medium: bool = false
var heavy: bool = false


func direction() -> Vector2i:
	return Vector2i((1 if right else 0) - (1 if left else 0), (1 if down else 0) - (1 if up else 0))


## Numpad-notation direction (1–9, 5 = neutral) relative to facing:
## 6 is always "toward the opponent", 4 is "away" (fighting-game convention).
func numpad(facing_right: bool) -> int:
	var d := direction()
	var x := d.x if facing_right else -d.x
	return 5 + x - 3 * d.y


func is_pressed(button: StringName) -> bool:
	match button:
		&"light":
			return light
		&"medium":
			return medium
		&"heavy":
			return heavy
	return false
