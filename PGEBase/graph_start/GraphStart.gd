extends Panel

signal moved


var style_box_normal = preload("GraphStartPanelNormal.tres")
var style_box_focus = preload("GraphStartPanelFocus.tres")


func _ready() -> void:
	$GraphNodeSlot.graph_node = self
	
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")


func get_start_node_name() -> String:
	var connections: Array = $GraphNodeSlot.get_connections()
	
	if connections.empty():
		return ""
	
	return connections[0].to.graph_node.name


func move(ammount: Vector2) -> void:
	rect_position += ammount
	emit_signal("moved")


func move_to(position: Vector2) -> void:
	rect_position = position
	emit_signal("moved")


func _on_focus_entered() -> void:
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)