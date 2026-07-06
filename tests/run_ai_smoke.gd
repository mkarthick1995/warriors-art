extends SceneTree
## AI smoke test: attach a CPU brain to P2 in the real Match scene and verify
## it closes distance and lands hits on a passive P1 within a time budget.
## Run:  godot --headless --path . -s res://tests/run_ai_smoke.gd

const MAX_FRAMES := 3000

var _failures := 0


func _initialize() -> void:
	var scene: Node = (load("res://scenes/Match.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	_run(scene)


func _run(scene: Node) -> void:
	var controller: MatchController = scene
	var p1: Fighter = controller.p1
	var p2: Fighter = controller.p2
	var brain := FighterAI.new()
	brain.setup(p2, p1, 5, 42)
	p2.ai_brain = brain

	await _until(func() -> bool: return controller.phase == MatchController.Phase.FIGHTING)
	var p1_max: int = p1.data.max_health
	await _until(func() -> bool: return p1.health < p1_max)
	_check(true, "CPU closed distance and landed a hit on a passive opponent")
	var first_hit_health: int = p1.health
	await _until(func() -> bool: return p1.health < first_hit_health)
	_check(true, "CPU kept attacking (second hit landed)")

	print("=== ai smoke: %s ===" % ("FAILED" if _failures > 0 else "OK"))
	quit(1 if _failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  PASS  " + label)
	else:
		_failures += 1
		printerr("  FAIL  " + label)


func _until(cond: Callable) -> void:
	for i in MAX_FRAMES:
		if cond.call():
			return
		await physics_frame
	printerr("  FAIL  timed out waiting for condition")
	print("=== ai smoke: FAILED (timeout) ===")
	quit(1)
