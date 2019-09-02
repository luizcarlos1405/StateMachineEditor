tool
extends Button

enum Mode {BOTH, IN, OUT}

export(Mode) var mode = Mode.BOTH
export var max_connections := 0
export(int, -1, 1) var tangent_x_direction := 0 setget set_tangent_x_direction

var popup_menu_rect_min_size = Vector2(50, 2)

var color := Color(1,1,1) setget set_color
var radius := 20.0 setget set_radius

var dragging := false
var graph_node
onready var graph_node_item

var connections_received := []


func _ready() -> void:
	connect("gui_input", self, "_on_gui_input")


func start_connection():
	if max_connections:
		if get_child_count() > max_connections:
			return null
	
	if mode != Mode.IN:
		var graph_edge = PGE.Edge.new()
		dragging = true
		
		add_child(graph_edge, true)
		graph_edge.from_slot = self
		
		return graph_edge
		
	else:
		return null


func connect_to(slot) -> void:
	var edge = start_connection()
	if edge:
		edge.to_slot = slot


func get_connections() -> Array:
	var connections = []
	
	for child in get_children():
		if child is PGE.Edge:
			connections.append(child.to_slot)
	
	return connections


func get_drag_data(position: Vector2) -> Object:
	return start_connection()


func can_drop_data(position: Vector2, graph_edge) -> bool:
	return graph_edge is PGE.Edge and mode != Mode.OUT
	pass


func drop_data(position: Vector2, graph_edge) -> void:
	graph_edge.to_slot = self
	graph_edge.connect("tree_exiting", self, "_on_edge_tree_exiting", [graph_edge])


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		get_tree().set_input_as_handled()
		
		if event.button_index == BUTTON_RIGHT and event.pressed:
			$PopupMenu.clear()
			
			if connections_received.size() > 0 or get_child_count() > 1:
				$PopupMenu.popup(Rect2(event.global_position, popup_menu_rect_min_size))


func _on_edge_tree_exiting(graph_edge) -> void:
	connections_received.erase(graph_edge)
	pass


func set_tangent_x_direction(value: int) -> void:
	tangent_x_direction = value


func set_color(value: Color) -> void:
	color = value
	self_modulate = color

func set_radius(value: float) -> void:
	radius = value
	rect_min_size = Vector2(radius * 2, radius * 2)
	rect_size = rect_min_size