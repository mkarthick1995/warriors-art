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
	return Vector2i(
		(1 if right else 0) - (1 if left else 0),
		(1 if down else 0) - (1 if up else 0)
	)
