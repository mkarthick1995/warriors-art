extends Node
## Audio service. Autoloaded as `Sfx`. PRESENTATION ONLY — the sim never
## depends on audio.
##
## Buses (created in code at boot, no bus-layout resource needed):
##   Master ← SFX (hit/block/whiff/ko/throw layers)
##   Master ← Music (per-character regional percussion loops)

const SFX_BUS := "SFX"
const MUSIC_BUS := "Music"
const POOL_SIZE := 10
## At/above this damage a hit uses the heavy layer (matches juice's shake tier).
const HEAVY_HIT_DAMAGE := 60
const PERCUSSION_DIR := "res://assets/audio/percussion"

const SFX_DIR := "res://assets/audio/sfx"
const SOUND_NAMES: Array[StringName] = [
	&"hit_light", &"hit_heavy", &"block", &"whiff", &"throw", &"ko"
]

## Loaded in _ready and released in _exit_tree (a const preload dictionary
## would hold the resources past engine teardown and warn at exit).
var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next_player := 0
var _music := AudioStreamPlayer.new()
## Presentation-only pitch jitter — never part of the sim.
var _jitter := RandomNumberGenerator.new()
## Headless (CI/tests) has no ears, and the dummy audio driver leaks active
## playbacks at teardown — disable audio entirely there.
var _enabled := true


func _ready() -> void:
	_enabled = DisplayServer.get_name() != "headless"
	if not _enabled:
		return
	for sound in SOUND_NAMES:
		var path := "%s/%s.wav" % [SFX_DIR, sound]
		if ResourceLoader.exists(path):
			_streams[sound] = load(path)
	_create_bus(SFX_BUS)
	_create_bus(MUSIC_BUS)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)
	_music.bus = MUSIC_BUS
	_music.volume_db = -8.0
	add_child(_music)
	# WAV streams don't loop by default; restart when the loop ends.
	_music.finished.connect(_music.play)


func _exit_tree() -> void:
	if not _enabled:
		return
	# Stop playback and release resource references before engine teardown —
	# an active playback keeps its stream alive and warns "still in use".
	_music.finished.disconnect(_music.play)
	_music.stop()
	_music.stream = null
	for p in _pool:
		p.stop()
		p.stream = null
	_streams.clear()


func play(name: StringName, volume_db: float = 0.0) -> void:
	if not _enabled:
		return
	var stream: AudioStream = _streams.get(name)
	if stream == null:
		return
	var p := _pool[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = _jitter.randf_range(0.94, 1.06)  # Keeps repeats from droning.
	p.play()


func hit(damage: int) -> void:
	play(&"hit_heavy" if damage >= HEAVY_HIT_DAMAGE else &"hit_light")


func block() -> void:
	play(&"block", -4.0)


func whiff() -> void:
	play(&"whiff", -8.0)


func throw_grab() -> void:
	play(&"throw")


func ko() -> void:
	play(&"ko", 2.0)


## Start the regional percussion loop for a percussion id (e.g. "dhak").
## Missing loops are fine — silence until that instrument is recorded.
func play_percussion(percussion_id: String) -> void:
	if not _enabled:
		return
	var path := "%s/%s_loop.wav" % [PERCUSSION_DIR, percussion_id]
	if not ResourceLoader.exists(path):
		stop_percussion()
		return
	_music.stream = load(path)
	_music.play()


func stop_percussion() -> void:
	if _enabled:
		_music.stop()


func _create_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
