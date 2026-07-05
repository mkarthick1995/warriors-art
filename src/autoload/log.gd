extends Node
## Leveled logging. Autoloaded as `Log`. Use this instead of stray print().

enum Level { DEBUG, INFO, WARN, ERROR }

## Set to Level.INFO or higher for release builds.
var min_level: Level = Level.DEBUG

func debug(msg: String) -> void:
	_emit(Level.DEBUG, msg)

func info(msg: String) -> void:
	_emit(Level.INFO, msg)

func warn(msg: String) -> void:
	_emit(Level.WARN, msg)

func error(msg: String) -> void:
	_emit(Level.ERROR, msg)

func _emit(level: Level, msg: String) -> void:
	if level < min_level:
		return
	var tag := Level.keys()[level]
	print("[%s] %s" % [tag, msg])
