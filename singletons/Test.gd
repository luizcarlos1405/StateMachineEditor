extends Node

var Parser = preload("res://StateMachine/Parser.gd")
onready var parser = Parser.new()

func _ready():
	parser.open_graph("res://InputControlFSM.res")
	parser.run_event("Touch")
	
	parser.print_node_items(parser.current_node)
	print(parser.current_node.items[2])
	
	
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			parser.run_event("Touch")
			
		else:
			parser.run_event("Release")
			
#		parser.print_node_items(parser.current_node)
#		print("Touch")
		pass
	pass
