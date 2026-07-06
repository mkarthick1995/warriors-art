extends SceneTree
## Dev tool: run a scene for a moment and save a screenshot (visual review).
## Needs a window (not --headless):
##   godot --path . -s res://tools/capture_screenshot.gd -- \
##       [scene=res://...] [frames=120] [out=path.png]

var _scene_path := "res://scenes/Match.tscn"
var _wait_frames := 120
var _out_path := "screenshot.png"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"scene":
				_scene_path = kv[1]
			"frames":
				_wait_frames = int(kv[1])
			"out":
				_out_path = kv[1]
	var scene: Node = (load(_scene_path) as PackedScene).instantiate()
	root.add_child(scene)
	_capture()


func _capture() -> void:
	for i in _wait_frames:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var err := img.save_png(_out_path)
	print("screenshot %s -> %s" % ["saved" if err == OK else "FAILED", _out_path])
	quit(0 if err == OK else 1)
