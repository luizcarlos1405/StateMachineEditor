extends "res://StateMachine/state_scripts/StateScript.gd"


var time_passed: int


func enter() -> void:
	time_passed = 0


func exit() -> void:
	
	pass


func _process(delta: float) -> void:
	time_passed += delta
	pass