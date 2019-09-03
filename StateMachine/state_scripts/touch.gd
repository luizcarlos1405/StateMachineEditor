extends "res://StateMachine/state_scripts/StateScript.gd"


func enter(fsm: Object) -> void:
	fsm.timer.start(0.3)
	pass