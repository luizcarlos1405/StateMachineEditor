extends "res://PGEBase/graph_node_item/GraphNodeItem.gd"

func _ready():
	pass


func get_item_data() -> Dictionary:
	var item_data = {
		script_name = $Parts/Content/ScriptName.text
	}
	
	return item_data


func set_item_data(item_data: Dictionary) -> void:
	$Parts/Content/ScriptName.text = item_data.script_name
