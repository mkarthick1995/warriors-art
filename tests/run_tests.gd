extends SceneTree
## Headless test runner for pure sim logic (no GUT dependency).
## Run:  godot --headless --path . -s res://tests/run_tests.gd
## Exits 0 on success, 1 on any failure — CI runs this.

var _checks := 0
var _failures := 0


func _initialize() -> void:
	print("=== Warrior's Art — sim tests ===")
	_test_input_buttons_numpad()
	_test_input_buffer_edges()
	_test_motion_parser()
	_test_double_tap()
	_test_state_machine_stun()
	_test_state_machine_ko()
	_test_move_data_parsing()
	_test_character_resource_loads()
	print("=== %d checks, %d failures ===" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	_checks += 1
	if cond:
		print("  PASS  " + label)
	else:
		_failures += 1
		printerr("  FAIL  " + label)


func _buttons(dir_x: int = 0, dir_y: int = 0, light := false) -> InputButtons:
	var b := InputButtons.new()
	b.left = dir_x < 0
	b.right = dir_x > 0
	b.up = dir_y < 0
	b.down = dir_y > 0
	b.light = light
	return b


func _test_input_buttons_numpad() -> void:
	_check(_buttons(0, 0).numpad(true) == 5, "numpad: neutral = 5")
	_check(_buttons(1, 0).numpad(true) == 6, "numpad: forward (facing right) = 6")
	_check(_buttons(1, 0).numpad(false) == 4, "numpad: same key is back when facing left")
	_check(_buttons(0, 1).numpad(true) == 2, "numpad: down = 2")
	_check(_buttons(1, 1).numpad(true) == 3, "numpad: down-forward = 3")
	_check(_buttons(-1, -1).numpad(true) == 7, "numpad: up-back = 7")


func _test_input_buffer_edges() -> void:
	var buf := InputBuffer.new()
	buf.push(_buttons())
	buf.push(_buttons(0, 0, true))
	_check(buf.just_pressed(&"light"), "just_pressed: rising edge detected")
	buf.push(_buttons(0, 0, true))
	_check(not buf.just_pressed(&"light"), "just_pressed: held is not a new press")


func _test_motion_parser() -> void:
	var buf := InputBuffer.new()
	buf.push(_buttons(0, 1))  # 2
	buf.push(_buttons(1, 1))  # 3
	buf.push(_buttons(1, 0))  # 6
	_check(buf.has_motion("236", true), "motion: QCF right recognized")
	_check(not buf.has_motion("236", false), "motion: QCF is facing-relative")
	_check(not buf.has_motion("623", true), "motion: DP not matched by QCF input")
	var buf2 := InputBuffer.new()
	buf2.push(_buttons(1, 0))  # 6 first — wrong order
	buf2.push(_buttons(1, 1))
	buf2.push(_buttons(0, 1))
	_check(not buf2.has_motion("236", true), "motion: reversed QCF rejected")
	var buf3 := InputBuffer.new()
	for i in InputBuffer.CAPACITY:  # QCF way outside the leniency window
		buf3.push(_buttons())
	buf3.push(_buttons(0, 1))
	buf3.push(_buttons(1, 1))
	for i in 20:
		buf3.push(_buttons())
	buf3.push(_buttons(1, 0))
	_check(not buf3.has_motion("236", true, 12), "motion: stale inputs outside leniency rejected")
	var dp := InputBuffer.new()
	dp.push(_buttons(1, 0))  # 6
	dp.push(_buttons(0, 1))  # 2
	dp.push(_buttons(1, 1))  # 3
	_check(dp.has_motion("623", true), "motion: DP (623) recognized")
	_check(not dp.has_motion("236", true), "motion: DP input does not satisfy QCF")


func _test_double_tap() -> void:
	var buf := InputBuffer.new()
	buf.push(_buttons(1, 0))
	buf.push(_buttons(0, 0))
	buf.push(_buttons(1, 0))
	_check(buf.double_tapped(1), "dash: tap-release-tap detected")
	buf.push(_buttons(1, 0))
	_check(not buf.double_tapped(1), "dash: only fires on the second tap's rising edge")
	var opposite := InputBuffer.new()
	opposite.push(_buttons(1, 0))
	opposite.push(_buttons(-1, 0))
	opposite.push(_buttons(1, 0))
	_check(not opposite.double_tapped(1), "dash: opposite direction breaks the tap chain")
	var held := InputBuffer.new()
	held.push(_buttons(1, 0))
	held.push(_buttons(1, 0))
	_check(not held.double_tapped(1), "dash: held direction is not a double tap")


func _test_state_machine_stun() -> void:
	var sm := FighterStateMachine.new()
	sm.enter_stun(FighterStateMachine.State.HITSTUN, 5)
	_check(sm.current == FighterStateMachine.State.HITSTUN, "stun: enters hitstun")
	sm.change_to(FighterStateMachine.State.WALK)
	_check(sm.current == FighterStateMachine.State.HITSTUN, "stun: cannot act out of stun")
	for i in 5:
		sm.tick()
	_check(
		sm.current == FighterStateMachine.State.IDLE, "stun: auto-exits to idle when timer expires"
	)


func _test_state_machine_ko() -> void:
	var sm := FighterStateMachine.new()
	sm.change_to(FighterStateMachine.State.KO)
	sm.change_to(FighterStateMachine.State.IDLE)
	_check(sm.current == FighterStateMachine.State.KO, "ko: is terminal")
	sm.reset()
	_check(sm.current == FighterStateMachine.State.IDLE, "ko: reset clears it for a new round")


func _test_move_data_parsing() -> void:
	var m := MoveData.new()
	m.input = "236L"
	m.startup = 4
	m.active = 3
	m.recovery = 9
	_check(m.motion_part() == "236", "move input: motion part extracted")
	_check(m.button_part() == &"light", "move input: button part extracted")
	_check(m.duration() == 16, "move: duration = startup + active + recovery")
	var n := MoveData.new()
	n.input = "M"
	_check(n.motion_part() == "" and n.button_part() == &"medium", "move input: plain normal")
	var s := MoveData.new()
	s.input = "236236L"
	_check(s.motion_part() == "236236", "move input: double-QCF super motion extracted")


func _test_character_resource_loads() -> void:
	var paths: Array[String] = [
		"res://src/characters/bengal_lathi/bengal_lathi.tres",
		"res://src/characters/varanasi_musti/varanasi_musti.tres",
	]
	for path in paths:
		var short := path.get_file()
		var data: CharacterData = load(path)
		_check(data != null, "resource: %s loads" % short)
		if data == null:
			continue
		_check(data.moves.size() == 6, "resource: %s has 6 moves" % short)
		_check(data.max_health > 0 and data.walk_speed > 0, "resource: %s sane stats" % short)
		_check(
			(
				data.super_move != null
				and data.super_move.technique_cam
				and data.super_move.meter_cost > 0
			),
			"resource: %s super has technique cam and a meter cost" % short
		)
		for m in data.moves:
			_check(
				not m.hitbox_frames.is_empty() and m.duration() > 0,
				"resource: %s move '%s' has frames and timing" % [short, m.display_name]
			)
			_check(
				m.button_part() != &"",
				"resource: %s move '%s' input parses" % [short, m.display_name]
			)
		if data.sprite_frames != null:
			# Sprite contract: idle/walk must exist; attack anims should match
			# the moves so the right animation plays (fallback is idle).
			for required in ["idle", "walk"]:
				_check(
					data.sprite_frames.has_animation(required),
					"sprites: %s has required '%s' animation" % [short, required]
				)
			for m in data.moves:
				_check(
					data.sprite_frames.has_animation(m.animation_name),
					"sprites: %s has animation for move '%s'" % [short, m.display_name]
				)
