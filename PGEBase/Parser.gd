var graph
var current_node: Dictionary setget set_current_node


func open_graph(graph_path: String) -> bool:
	graph = load(graph_path)
	
	var start_node_name = graph.connections.GraphStart.start_node_name
	
	if not start_node_name:
		return false
	
	set_current_node(graph.connections[start_node_name])
	
	return true


func next_node(item_id := 0, connection_id := 0) -> Dictionary:
	if current_node.empty():
		return {}
	
	var item = current_node.items[item_id]
	
	if item.connections.empty():
		print("[ERROR]: the item with id $s has no connections. Node not changed." % item_id)
		return {}
		
	if item.connections.size() <= connection_id:
		print("[ERROR]: trying to accesss connection id %s, but item has %s connections." % [connection_id, item.connections.size()])
		return {}
		
	var next_node_name = item.connections[connection_id]
	
	if not graph.connections.has(next_node_name):
		print("[ERROR]: node named $s not found in graph.connections." % next_node_name)
		return {}
	
	var next_node = graph.connections[next_node_name]
	
	set_current_node(next_node)
	
	return next_node


func print_node_items(node: Dictionary) -> void:
	if not node.has("items"):
		print("Not a node.")
	
	if node.items.empty():
		print("Empty node.")
		return
	
	for i in range(node.items.size()):
		print("Item %s:" % i)
		print("|       Data: ", node.items[i].item_data)
		print("| Connetions: ", node.items[i].connections)
		print(" ")


func set_current_node(value: Dictionary) -> void:
	var old_node := current_node
	current_node = value
	node_changed(old_node)


func node_changed(old_node: Dictionary): pass



