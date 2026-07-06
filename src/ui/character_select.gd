extends Control
## Character select: both players move a cursor over the roster grid and lock
## in. P1 = WASD + J (K unlocks), P2 = arrows + numpad 1 (2 unlocks); gamepads
## work through the same input actions. Esc returns to the title.

const COLS := 4
const P1_COLOR := Color(1, 0.55, 0.15)
const P2_COLOR := Color(0.15, 0.7, 0.35)
const START_DELAY := 0.7

var _datas: Array[CharacterData] = []
var _tiles: Array[Panel] = []
var _cursor: Array[int] = [0, 3]  ## Per-player grid index.
var _locked: Array[bool] = [false, false]
var _starting := false

var _grid: GridContainer
var _status: Array[Label] = []
## Arcade: only P1 picks; P2 is the CPU ladder.
var _arcade := false


func _ready() -> void:
	_arcade = GameState.is_arcade()
	for path in GameState.ROSTER:
		_datas.append(load(path))
	_build_ui()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).physical_keycode == KEY_ESCAPE:
			GameState.change_scene("res://scenes/Main.tscn")
			return
	for p in 2:
		_handle_player(event, p)
	_refresh()


func _handle_player(event: InputEvent, p: int) -> void:
	if _arcade and p == 1:
		return
	var prefix := "p%d_" % (p + 1)
	if _locked[p]:
		if event.is_action_pressed(prefix + "medium"):
			_locked[p] = false
		return
	var delta := 0
	if event.is_action_pressed(prefix + "left"):
		delta = -1
	elif event.is_action_pressed(prefix + "right"):
		delta = 1
	elif event.is_action_pressed(prefix + "up"):
		delta = -COLS
	elif event.is_action_pressed(prefix + "down"):
		delta = COLS
	if delta != 0:
		_cursor[p] = wrapi(_cursor[p] + delta, 0, _datas.size())
		Sfx.whiff()
		return
	if event.is_action_pressed(prefix + "light"):
		_locked[p] = true
		Sfx.hit(1)
		if _locked[0] and (_arcade or _locked[1]):
			_start_match()


func _start_match() -> void:
	_starting = true
	if _arcade:
		GameState.start_arcade(GameState.ROSTER[_cursor[0]])
	else:
		GameState.p1_character_path = GameState.ROSTER[_cursor[0]]
		GameState.p2_character_path = GameState.ROSTER[_cursor[1]]
		GameState.set_mode(GameState.Mode.VERSUS_1V1)
	await get_tree().create_timer(START_DELAY).timeout
	GameState.change_scene("res://scenes/Match.tscn")


func _refresh() -> void:
	for i in _tiles.size():
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.13, 0.11, 0.18)
		style.set_corner_radius_all(6)
		style.set_border_width_all(4)
		var p1_here := _cursor[0] == i
		var p2_here := _cursor[1] == i
		if p1_here and p2_here:
			style.border_color = P1_COLOR.lerp(P2_COLOR, 0.5)
		elif p1_here:
			style.border_color = P1_COLOR
		elif p2_here:
			style.border_color = P2_COLOR
		else:
			style.border_color = Color(0.25, 0.22, 0.32)
		_tiles[i].add_theme_stylebox_override("panel", style)
	for p in 2:
		if _arcade and p == 1:
			_status[p].text = "CPU LADDER\n%d battles await" % (GameState.ROSTER.size() - 1)
			continue
		var data := _datas[_cursor[p]]
		var state := "LOCKED IN" if _locked[p] else "choosing…"
		_status[p].text = "P%d: %s (%s)\n%s" % [p + 1, data.martial_art, data.state_region, state]
	if _starting:
		_status[0].text += "\n\nFIGHT!"


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 24)
	add_child(root)

	var title := Label.new()
	title.text = "CHOOSE YOUR FIGHTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	root.add_child(title)

	var center := CenterContainer.new()
	root.add_child(center)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	center.add_child(_grid)

	for data in _datas:
		_grid.add_child(_make_tile(data))

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 160)
	root.add_child(bottom)
	for p in 2:
		var status := Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 26)
		status.add_theme_color_override("font_color", P1_COLOR if p == 0 else P2_COLOR)
		bottom.add_child(status)
		_status.append(status)

	var hint := Label.new()
	hint.text = "move: WASD / arrows · lock: R / I · unlock: T / O · Esc: back"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.modulate = Color(1, 1, 1, 0.6)
	root.add_child(hint)


func _make_tile(data: CharacterData) -> Panel:
	var tile := Panel.new()
	tile.custom_minimum_size = Vector2(210, 250)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_child(box)

	var portrait := TextureRect.new()
	portrait.texture = data.sprite_frames.get_frame_texture(&"idle", 0)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.custom_minimum_size = Vector2(140, 168)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(portrait)

	var art := Label.new()
	art.text = data.martial_art
	art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art.add_theme_font_size_override("font_size", 22)
	box.add_child(art)

	var region := Label.new()
	region.text = data.state_region
	region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region.add_theme_font_size_override("font_size", 16)
	region.modulate = Color(1, 1, 1, 0.65)
	box.add_child(region)

	_tiles.append(tile)
	return tile
