extends "res://PGEBase/Parser.gd"

var state_scripts_folder := "res://StateMachine/state_scripts/"
var current_state_script: Object
var current_state: String


func open_fsm_graph(fsm: Object, path: String) -> String:
	open_graph(path)
	
	load_current_state_script()
	
	if current_state_script:
		current_state_script.enter(fsm)
	
	current_state = current_node.name
	return current_state


func run_event(fsm: Object, event_name: String) -> String:
	var next_node := {}
	var next_script_item := {}
	
	for i in range(current_node.items.size()):
		var item = current_node.items[i]
		
		if item.type != "Script":
			if item.item_data.event_name == event_name:
				if current_state_script:
					current_state_script.exit(fsm)
				
				next_node = next_node(i)
				
				if next_node.empty():
					return ""
					
				elif next_node.items.empty():
					print("Gesture: %s" % next_node.name)
					reset_graph()
				
				break
	
	load_current_state_script()
	
	if current_state_script:
		current_state_script.enter(fsm)
	
	current_state = current_node.name
	return current_state


func load_current_state_script() -> Object:
	var script: GDScript
	var next_script_item := {}
	
	for i in range(current_node.items.size()):
		var item = current_node.items[i]
		
		if item.type == "Script":
			next_script_item = item
			
			break
	
	if not next_script_item.empty():
		script = load(state_scripts_folder + next_script_item.item_data.script_name + ".gd")
	
	current_state_script = script.new() if script else null
	
	return current_state_script