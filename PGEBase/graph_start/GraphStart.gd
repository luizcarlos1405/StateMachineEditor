extends Panel

signal moved

var style_box_normal = preload("GraphStartPanelNormal.tres")
var style_box_focus = preload("GraphStartPanelFocus.tres")

var start_node_name: String


func _ready() -> void:
	$Slot.graph_node = self
	
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")


func set_start_node(start_node) -> void:
	$Slot.connect_to(start_node.slot)


func serialize() -> Dictionary:
	var slot_connections = $Slot.get_connections()
	var start_node_name: String
	
	if not slot_connections.empty():
		start_node_name = $Slot.get_connections()[0].graph_node.name
	
	var info = {
		editor_data = get_editor_data(),
		start_node_name = start_node_name
	}
	
	
	return info


func get_editor_data() -> Dictionary:
	var editor_data = {
		rect_position = rect_position
	}
	
	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
	rect_position = editor_data.rect_position


func move(ammount: Vector2) -> void:
	rect_position += ammount
	emit_signal("moved")


func move_to(position: Vector2) -> void:
	rect_position = position
	emit_signal("moved")


func _on_focus_entered() -> void:
	raise()
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)