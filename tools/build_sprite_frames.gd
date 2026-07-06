extends SceneTree
## Builds SpriteFrames resources from sprite-strip PNGs (the art pipeline).
##
## Scans assets/sprites/<character>/<anim>@<frames>x<fps>.png (horizontal
## strips, one frame every FRAME_W px) and saves a SpriteFrames resource to
## src/characters/<character>/<character>_frames.tres.
##
## Run after adding/changing sprites (from the repo root):
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/build_sprite_frames.gd
## Commit the PNGs (Git LFS) AND the generated .tres together.

const SPRITES_ROOT := "res://assets/sprites"
const OUT_DIR_FMT := "res://src/characters/%s/%s_frames.tres"
const FRAME_W := 128
const FRAME_H := 192
## Animations that repeat while the state holds; everything else plays once.
const LOOPING := ["idle", "walk", "crouch", "jump"]

var _errors := 0


func _initialize() -> void:
	var root := DirAccess.open(SPRITES_ROOT)
	if root == null:
		printerr("cannot open " + SPRITES_ROOT)
		quit(1)
		return
	for character in root.get_directories():
		_build_character(character)
	quit(1 if _errors > 0 else 0)


func _build_character(character: String) -> void:
	var dir_path := SPRITES_ROOT + "/" + character
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var pattern := RegEx.create_from_string(r"^(\w+)@(\d+)x(\d+)\.png$")
	var count := 0
	for file in DirAccess.open(dir_path).get_files():
		var m := pattern.search(file)
		if m == null:
			if file.ends_with(".png"):
				printerr("  SKIP (bad name, want anim@FRAMESxFPS.png): " + file)
				_errors += 1
			continue
		var anim := m.get_string(1)
		var frame_count := int(m.get_string(2))
		var fps := int(m.get_string(3))
		var tex: Texture2D = load(dir_path + "/" + file)
		if tex == null:
			printerr("  FAIL to load " + file)
			_errors += 1
			continue
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, anim in LOOPING)
		for i in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
			frames.add_frame(anim, atlas)
		count += 1
	if count == 0:
		print("%s: no strips found, skipped" % character)
		return
	var out := OUT_DIR_FMT % [character, character]
	var err := ResourceSaver.save(frames, out)
	if err != OK:
		printerr("%s: save failed (%d)" % [out, err])
		_errors += 1
		return
	print("%s: %d animations -> %s" % [character, count, out])
