extends "res://StateMachine/state_scripts/StateScript.gd"

var hold_time = 0.3


func enter(fsm: Object) -> void:
	fsm.timer.start(hold_time)
	pass