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

	# 2. Walk P1 into jab range (assert WALK while the key is still held).
	Input.action_press("p1_right")
	await _until(func() -> bool: return p1.state() == FighterStateMachine.State.WALK)
	_check(true, "p1 walks when holding forward")
	await _until(func() -> bool: return p2.global_position.x - p1.global_position.x < 130.0)
	Input.action_release("p1_right")
	await _frames(1)

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

	# 5. Double-tap forward = dash.
	await _until(func() -> bool: return not p2.is_stunned() and not p1.is_stunned())
	await _frames(10)  # Let stale directional inputs fall out of the tap window.
	Input.action_press("p1_right")
	await _frames(2)
	Input.action_release("p1_right")
	await _frames(3)
	Input.action_press("p1_right")
	await _frames(2)
	var dashed := p1.state() == FighterStateMachine.State.DASH
	Input.action_release("p1_right")
	_check(dashed, "double-tap forward dashes")
	await _until(func() -> bool: return p1.state() == FighterStateMachine.State.IDLE)

	# 6. Throw: light+medium at point-blank grabs, damages, knocks down.
	await _until(func() -> bool: return not p1.is_stunned() and not p2.is_stunned())
	var hp_before_throw: int = p2.health
	await _walk_into_range(p1, p2, 90.0)
	Input.action_press("p1_light")
	Input.action_press("p1_medium")
	await _frames(2)
	Input.action_release("p1_light")
	Input.action_release("p1_medium")
	await _until(func() -> bool: return p2.state() == FighterStateMachine.State.THROWN)
	_check(true, "throw grabs at point-blank")
	await _until(func() -> bool: return p2.state() == FighterStateMachine.State.KNOCKDOWN)
	_check(
		p2.health == hp_before_throw - MatchController.THROW_DAMAGE,
		"throw dealt its damage after the hold"
	)
	await _until(func() -> bool: return p2.state() == FighterStateMachine.State.IDLE)

	# 7. QCF special launches P2 into a knockdown, then P2 wakes up.
	await _walk_into_range(p1, p2)
	await _qcf("p1", "light")
	await _until(func() -> bool: return p2.state() == FighterStateMachine.State.KNOCKDOWN)
	_check(true, "launcher special causes knockdown")
	await _until(func() -> bool: return p2.state() == FighterStateMachine.State.IDLE)
	_check(true, "p2 wakes up from knockdown")

	# 8. Super: double-QCF with full meter spends it all and hits big.
	p1.meter = Fighter.MAX_METER
	var hp_before_super: int = p2.health
	await _walk_into_range(p1, p2)
	await _qcf("p1", "")
	await _qcf("p1", "light")
	await _frames(30)
	_check(p1.meter == 0, "super consumed the full meter")
	_check(p2.health <= hp_before_super - 80, "super connected for major damage")
	await _until(func() -> bool: return p2.state() == FighterStateMachine.State.IDLE)

	# 9. Projectile: P2 (Gatka) throws a chakram across the screen at P1.
	await _until(func() -> bool: return not p1.is_stunned() and not p2.is_stunned())
	var hp_before_chakram: int = p1.health
	await _qcf("p2", "light", "left")  # P2 faces left, so QCF rolls left.
	await _until(func() -> bool: return p1.health < hp_before_chakram)
	_check(
		p1.health == hp_before_chakram - 65,
		"chakram projectile crossed the screen and dealt its damage"
	)
	await _until(func() -> bool: return not p1.is_stunned())

	# 10. Force a KO and confirm the round ends and the next round resets health.
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


func _walk_into_range(p1: Fighter, p2: Fighter, gap: float = 130.0) -> void:
	Input.action_press("p1_right")
	await _until(func() -> bool: return p2.global_position.x - p1.global_position.x < gap)
	Input.action_release("p1_right")
	await _frames(1)


## Roll a quarter-circle toward `dir` ("right"/"left" = the fighter's
## forward), optionally ending in a button tap.
func _qcf(prefix: String, button: String, dir: String = "right") -> void:
	Input.action_press(prefix + "_down")
	await _frames(3)
	Input.action_press(prefix + "_" + dir)
	await _frames(3)
	Input.action_release(prefix + "_down")
	await _frames(2)
	if button != "":
		Input.action_press(prefix + "_" + button)
		await _frames(2)
		Input.action_release(prefix + "_" + button)
	Input.action_release(prefix + "_" + dir)
	await _frames(1)
