extends Node

var Parser = preload("res://StateMachine/Parser.gd")

var state_script: Object
var touch_position: Vector2
var timer = Timer.new()

onready var parser = Parser.new()


func _ready():
	add_child(timer)
	timer.connect("timeout", self, "_on_Timer_timeout")
	parser.open_fsm_graph(self, "res://StateMachine/TouchGesturesFSM.res")


func _process(delta: float) -> void:
	if parser.current_state_script:
		parser.current_state_script._process(self, delta)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_position = event.position
			parser.run_event(self, "Touch")

		else:
			parser.run_event(self, "Release")

	elif event is InputEventScreenDrag:
		parser.run_event(self, "Drag")
	pass


func _on_Timer_timeout() -> void:
	parser.run_event(self, "Timeout")