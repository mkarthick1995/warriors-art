extends Node
## Seeded, replayable RNG for the deterministic simulation. Autoloaded as `Rng`.
##
## NEVER call bare randf()/randi() inside sim code — route it through here so a
## match is fully reproducible from (seed + input stream). This is what keeps
## future rollback netcode possible (see docs/ARCHITECTURE.md, Determinism).

var _rng := RandomNumberGenerator.new()


## Reseed at the start of every match. Setting `seed` fully resets the internal
## state; both sides of a future netcode session must agree on the seed.
func seed_match(seed_value: int) -> void:
	_rng.seed = seed_value


## Deterministic integer in [from, to] (inclusive).
func next_int(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


## Deterministic float in [0, 1).
func next_float() -> float:
	return _rng.randf()
