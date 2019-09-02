extends "res://PGEBase/Parser.gd"


func _ready():
	pass


func run_event(event_name: String) -> Dictionary:
	if not current_node.has("items"): return {}
	var next_node := {}
	
	for i in range(current_node.items.size()):
		if current_node.items[i].item_data.event_name == event_name:
			next_node = next_node(i)
	
	print(next_node.editor_data.name)
	return next_node
