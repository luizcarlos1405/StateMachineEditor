extends Line2D

class_name GraphEdge

var from_tangent := Vector2(50, 0)
var to_tangent := Vector2(-50, 0)
var _connecting = false
var _curve := Curve2D.new()

var from setget set_from
var to setget set_to


func _ready() -> void:
	default_color = Color(1, 1, 1, 0.3)
	width = 4
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	set_as_toplevel(true)


func refresh() -> void:
	if from:
		_curve.set_point_position(0, from.rect_global_position + from.rect_size / 2)
	
	if to:
		_curve.set_point_position(1, to.rect_global_position + to.rect_size / 2)
	
	points = _curve.get_baked_points()


func _input(event: InputEvent) -> void:
	if _connecting:
		if event is InputEventMouseMotion:
			_curve.set_point_position(1, event.global_position)
			points = _curve.get_baked_points()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not to:
			queue_free()
	pass


func _on_from_tree_exiting() -> void:
	if to:
		to.connections_received.erase(self)


func _on_to_tree_exiting() -> void:
	to = null
	queue_free()


func _on_Slot_rect_changed() -> void:
	refresh()


func _on_Slot_node_moved() -> void:
	refresh()


func _on_GraphNode_sort_children() -> void:
	refresh()


func set_from(value) -> void:
	from = value
	
	_curve.clear_points()
	_curve.add_point(from.rect_global_position + from.rect_size / 2, Vector2(), from_tangent)
	_curve.add_point(get_global_mouse_position(), to_tangent, Vector2())
	points = _curve.get_baked_points()
	
	_connecting = true


func set_to(value) -> void:
	to = value
	
	if not to:
		queue_free()
		return
	
	_curve.set_point_position(1, to.rect_global_position + to.rect_size / 2)
	points = _curve.get_baked_points()
	
	from.connect("tree_exiting", self, "_on_from_tree_exiting")
	to.connect("tree_exiting", self, "_on_to_tree_exiting")
	to.connections_received.append(self)
	
	from.graph_node.connect("moved", self, "_on_Slot_node_moved")
	to.graph_node.connect("moved", self, "_on_Slot_node_moved")
	
	if from.graph_node.name != "GraphStart":
		from.connect("item_rect_changed", self, "_on_Slot_rect_changed")
		to.connect("item_rect_changed", self, "_on_Slot_rect_changed")
	
	_connecting = false