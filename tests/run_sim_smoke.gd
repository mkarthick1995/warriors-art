extends SceneTree
## End-to-end smoke test: loads the real Match scene headless, injects inputs,
## and asserts a jab connects, blocking chips, and a fresh round resets health.
## Run:  godot --headless --path . -s res://tests/run_sim_smoke.gd

const MAX_FRAMES := 2000

var _failures := 0


func _initialize() -> void:
	var scene: Node = (load("res://scenes/Match.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	_run(scene)


func _run(scene: Node) -> void:
	var controller: MatchController = scene
	var p1: Fighter = controller.p1
	var p2: Fighter = controller.p2
	var p2_max: int = p2.data.max_health

	# 1. Wait out the pre-round freeze.
	await _until(func() -> bool: return controller.phase == MatchController.Phase.FIGHTING)
	_check(true, "round starts fighting phase")

	# 2. Walk P1 into jab range.
	await _walk_into_range(p1, p2)
	_check(p1.state() == FighterStateMachine.State.WALK, "p1 walked toward p2")

	# 3. Jab — must connect and damage P2.
	await _tap("p1_light")
	await _frames(20)
	_check(p2.health == p2_max - 40, "jab dealt exactly its authored damage")
	_check(p1.meter > 0, "attacker gained meter on hit")

	# 4. P2 blocks the next jab: holding away = chip damage only.
	await _until(func() -> bool: return not p2.is_stunned())
	var before_block: int = p2.health
	Input.action_press("p2_right")  # Away from P1 (P1 is on the left).
	await _frames(2)
	await _tap("p1_light")
	await _frames(20)
	Input.action_release("p2_right")
	_check(
		p2.state() == FighterStateMachine.State.BLOCKSTUN or p2.health >= before_block - 4,
		"blocked jab chipped instead of full damage"
	)

	# 5. Force a KO and confirm the round ends and the next round resets health.
	p2.health = 1
	await _until(func() -> bool: return not p2.is_stunned())
	await _walk_into_range(p1, p2)  # Knockback/pushback moved P2 out of reach.
	await _tap("p1_light")
	await _until(func() -> bool: return controller.phase == MatchController.Phase.ROUND_OVER)
	_check(controller.wins[0] == 1, "KO scores the round for p1")
	await _until(func() -> bool: return controller.phase == MatchController.Phase.FIGHTING)
	_check(p2.health == p2_max, "health resets for the new round")

	print("=== smoke: %s ===" % ("FAILED" if _failures > 0 else "OK"))
	quit(1 if _failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  PASS  " + label)
	else:
		_failures += 1
		printerr("  FAIL  " + label)


## Await physics ticks until `cond` is true; abort the test on timeout.
func _until(cond: Callable) -> void:
	for i in MAX_FRAMES:
		if cond.call():
			return
		await physics_frame
	printerr("  FAIL  timed out waiting for condition")
	_failures += 1
	print("=== smoke: FAILED (timeout) ===")
	quit(1)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


## Press an action for two ticks, then release (a clean tap).
func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _walk_into_range(p1: Fighter, p2: Fighter) -> void:
	Input.action_press("p1_right")
	await _until(func() -> bool: return p2.global_position.x - p1.global_position.x < 130.0)
	Input.action_release("p1_right")
