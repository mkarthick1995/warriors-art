extends Node
## Instances one stage backdrop when the match loads. PRESENTATION ONLY —
## backdrops are pure visuals; the floor/walls in Match.tscn are the sim's
## unchanging arena, identical on every stage.

@export var stages: Array[PackedScene] = []

## Presentation-only randomness (stage variety) — never part of the sim.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if stages.is_empty():
		return
	add_child(stages[_rng.randi_range(0, stages.size() - 1)].instantiate())
