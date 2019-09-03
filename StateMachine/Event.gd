extends "res://PGEBase/graph_node_item/GraphNodeItem.gd"


func _ready():
	$Parts/Content/Label.text = type
	pass


func get_item_data() -> Dictionary:
	var item_data := {
		event_name = type
	}
	
	return item_data