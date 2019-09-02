extends PopupMenu

var delete_icon: Texture = preload("../icons/icon_delete.svg")

onready var graph_node_slot = get_parent()

func _ready():
	connect("about_to_show", self, "_on_about_to_show")
	connect("index_pressed", self, "_on_index_pressed")
	pass


func _on_about_to_show() -> void:
	clear()
	
	for connection in graph_node_slot.connections_received:
		var item_text = make_item_text(connection)
		add_icon_item(delete_icon, item_text)
		
	for child in graph_node_slot.get_children():
		if child is PGE.Edge:
			var item_text = make_item_text(child)
			add_icon_item(delete_icon, item_text)


func _on_index_pressed(index: int) -> void:
	var item_text = get_item_text(index)
	
	for connection in graph_node_slot.connections_received:
		if item_text == make_item_text(connection):
			connection.queue_free()
			return
	
	for child in graph_node_slot.get_children():
		if child is PGE.Edge:
			if item_text == make_item_text(child):
				child.queue_free()
				return


func make_item_text(graph_edge) -> String:
	if graph_edge.from_slot.graph_node.name == "GraphStart":
		return "%s.%s -> %s" % [
				graph_edge.from_slot.graph_node.name,
				graph_edge.to_slot.graph_node.name
			]
		
	else:
		return "%s.%s -> %s" % [
				graph_edge.from_slot.graph_node.name,
				graph_edge.from_slot.graph_node_item.name,
				graph_edge.to_slot.graph_node.name
			]