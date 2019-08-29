tool
extends Button

enum Mode {BOTH, IN, OUT}
export(Mode) var mode = Mode.BOTH
export var max_connections := 0

var popup_menu_rect_min_size = Vector2(50, 2)

var color := Color(1,1,1) setget set_color
var radius := 20.0 setget set_radius

var dragging := false
var graph_node
var graph_node_item

var connections_received := []


func _ready() -> void:
	connect("gui_input", self, "_on_gui_input")


func get_connections() -> Array:
	var connections = []
	
	for child in get_children():
		if child is GraphEdge:
			connections.append(child)
	
	return connections


func get_drag_data(position: Vector2) -> Object:
	if max_connections:
		if get_child_count() > max_connections:
			return null
	
	if mode != Mode.IN:
		var graph_edge := GraphEdge.new()
		dragging = true
		
		add_child(graph_edge, true)
		graph_edge.from = self
		
		return graph_edge
		
	else:
		return null


func can_drop_data(position: Vector2, graph_edge: GraphEdge) -> bool:
	return graph_edge is GraphEdge and mode != Mode.OUT and graph_edge.from.graph_node != graph_node
	pass


func drop_data(position: Vector2, graph_edge: GraphEdge) -> void:
	graph_edge.to = self
	pass


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and not event.pressed:
			$PopupMenu.clear()
			
			if connections_received.size() > 0 or get_child_count() > 1:
				$PopupMenu.popup(Rect2(event.global_position, popup_menu_rect_min_size))


func set_color(value: Color) -> void:
	color = value
	self_modulate = color

func set_radius(value: float) -> void:
	radius = value
	rect_min_size = Vector2(radius * 2, radius * 2)
	rect_size = rect_min_size