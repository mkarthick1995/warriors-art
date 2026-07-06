extends CanvasLayer
## Match HUD: health/meter bars, round timer, win pips, center messages.
## PRESENTATION ONLY — polls the sim every render frame, never writes to it.

@export var controller: MatchController

@onready var _p1_health: ProgressBar = %P1Health
@onready var _p2_health: ProgressBar = %P2Health
@onready var _p1_meter: ProgressBar = %P1Meter
@onready var _p2_meter: ProgressBar = %P2Meter
@onready var _timer_label: Label = %TimerLabel
@onready var _p1_wins: Label = %P1Wins
@onready var _p2_wins: Label = %P2Wins
@onready var _message: Label = %Message


func _ready() -> void:
	assert(controller != null, "MatchHud needs the MatchController assigned.")


func _process(_delta: float) -> void:
	_update_bar(_p1_health, controller.p1.health, controller.p1.data.max_health)
	_update_bar(_p2_health, controller.p2.health, controller.p2.data.max_health)
	_update_bar(_p1_meter, controller.p1.meter, Fighter.MAX_METER)
	_update_bar(_p2_meter, controller.p2.meter, Fighter.MAX_METER)
	_timer_label.text = str(controller.time_left_seconds())
	_p1_wins.text = "●".repeat(controller.wins[0])
	_p2_wins.text = "●".repeat(controller.wins[1])
	_message.text = _phase_message()


func _update_bar(bar: ProgressBar, value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value = value


func _phase_message() -> String:
	match controller.phase:
		MatchController.Phase.PREROUND:
			return "ROUND %d" % controller.round_number
		MatchController.Phase.ROUND_OVER:
			return "K.O." if controller.timer_ticks > 0 else "TIME"
		MatchController.Phase.MATCH_OVER:
			var winner := 1 if controller.wins[0] > controller.wins[1] else 2
			return "PLAYER %d WINS\n[Enter] rematch" % winner
	# No phase message → transient banners (technique cam move names).
	return controller.announcement
