extends Node
## Leveled logging. Autoloaded as `Log`. Use this instead of stray print().
##
## WARN/ERROR also route to push_warning/push_error so they show up in the
## editor's Debugger panel, not just the console.

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
	var line := "[%s] %s" % [Level.keys()[level], msg]
	match level:
		Level.WARN:
			push_warning(line)
		Level.ERROR:
			push_error(line)
	print(line)
