extends Line2D

enum SlotSide {LEFT, RIGHT}

var _min_x_bezier_tangent := 30.0

var _connecting = false
var _curve := Curve2D.new()

var from_slot setget set_from
var to_slot setget set_to


func _ready() -> void:
	z_index = -1
	default_color = Color(1, 1, 1, 0.5)
	width = 2
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
#	set_as_toplevel(true)


func refresh() -> void:
	var from_slot_direction := 0
	var to_slot_direction := 0
	
	if from_slot:
#		_curve.set_point_position(0, from_slot.rect_global_position + from_slot.rect_size / 2)
		_curve.set_point_position(0, from_slot.rect_size / 2)
		from_slot_direction = from_slot.tangent_x_direction
	
	if to_slot:
#		_curve.set_point_position(1, to_slot.rect_global_position + to_slot.rect_size / 2)
		_curve.set_point_position(1, to_local(to_slot.rect_global_position) + to_slot.rect_size / 2)
		to_slot_direction = to_slot.tangent_x_direction
	
	var tangents = get_bezier_tangents(_curve.get_point_position(0),
			_curve.get_point_position(1), from_slot_direction, to_slot_direction)
	
	_curve.set_point_out(0, tangents.from_out)
	_curve.set_point_in(1, tangents.to_in)
	
	points = _curve.get_baked_points()


func get_bezier_tangents(from_point: Vector2, to_point: Vector2,
		from_slot_direction: int,
		to_slot_direction: int) -> Dictionary:
	
	var x_distance = to_point.x - from_point.x
	var tangents = {
		from_in = Vector2(),
		from_out = Vector2(),
		to_in = Vector2(),
		to_out = Vector2(),
	}
	
	if x_distance >= 0:
		if from_slot_direction == 1:
			tangents.from_out = Vector2(_min_x_bezier_tangent, 0)
			
		elif from_slot_direction == -1:
			tangents.from_out = Vector2(-get_x_bezier_from_distance(x_distance), 0)
			
		if to_slot_direction == 1:
			tangents.to_in = Vector2(get_x_bezier_from_distance(x_distance), 0)
			
		elif to_slot_direction == -1:
			tangents.to_in = Vector2(-_min_x_bezier_tangent, 0)
		
	else:
		if from_slot_direction == 1:
			tangents.from_out = Vector2(get_x_bezier_from_distance(x_distance), 0)
			
		elif from_slot_direction == -1:
			tangents.from_out = Vector2(-_min_x_bezier_tangent, 0)
			
		if to_slot_direction == 1:
			tangents.to_in = Vector2(_min_x_bezier_tangent, 0)
			
		elif to_slot_direction == -1:
			tangents.to_in = Vector2(-get_x_bezier_from_distance(x_distance), 0)
	
	return tangents


func get_x_bezier_from_distance(x_distance: float) -> float:
	return _min_x_bezier_tangent * log(abs(x_distance)) + _min_x_bezier_tangent
	pass


func _input(event: InputEvent) -> void:
	if _connecting:
		if event is InputEventMouseMotion:
#			_curve.set_point_position(1, event.global_position)
			_curve.set_point_position(1, to_local(event.global_position))
			points = _curve.get_baked_points()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if not to_slot:
			queue_free()
	pass


func _on_to_tree_exiting() -> void:
	queue_free()


func _on_from_item_reordered(item) -> void:
	# The item was moved, but it's position doesn't update instantly, let's wait
	# a little.
	yield(get_tree().create_timer(0.01), "timeout")
	refresh()


func _on_Slot_rect_changed() -> void:
	# Sometimes the rect changes, but the refresh is called after tha values
	# change for real. Let's wait a little
	yield(get_tree().create_timer(0.01), "timeout")
	refresh()


func _on_Slot_node_moved() -> void:
#	print("node_moved")
	refresh()


func _on_from_GraphNode_resized() -> void:
#	print("resized")
	refresh()


func _on_GraphNode_sort_children() -> void:
#	print("resorted")
	refresh()


func set_from(value) -> void:
	from_slot = value
	
	_curve.clear_points()
#	_curve.add_point(from_slot.rect_global_position + from_slot.rect_size / 2, Vector2(), from_tangent)
	_curve.add_point(from_slot.rect_size / 2, Vector2(), Vector2())
	_curve.add_point(get_local_mouse_position(), Vector2(), Vector2())
	refresh()
	points = _curve.get_baked_points()
	
	_connecting = true


func set_to(value) -> void:
	to_slot = value
	to_slot.connections_received.append(self)
	
	if not to_slot:
		queue_free()
		return
	
	if from_slot.graph_node == to_slot.graph_node:
		from_slot.self_modulate = from_slot.graph_node.self_connection_slot_color
		
		hide()
		return
	
	
#	_curve.set_point_position(1, to_slot.rect_global_position + to_slot.rect_size / 2)
	_curve.set_point_position(1, to_local(to_slot.rect_global_position) + to_slot.rect_size / 2)
	refresh()
	points = _curve.get_baked_points()
	
	to_slot.connect("tree_exiting", self, "_on_to_tree_exiting")
	
	
	from_slot.graph_node.connect("moved", self, "_on_Slot_node_moved")
	to_slot.graph_node.connect("moved", self, "_on_Slot_node_moved")
	
	from_slot.graph_node.connect("resized", self, "_on_from_GraphNode_resized")
	
	if from_slot.graph_node.name != "GraphStart":
		from_slot.graph_node.connect("item_reordered", self, "_on_from_item_reordered")
		
		from_slot.connect("item_rect_changed", self, "_on_Slot_rect_changed")
		to_slot.connect("item_rect_changed", self, "_on_Slot_rect_changed")
	
	_connecting = false