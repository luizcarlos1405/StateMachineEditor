extends Control

export(PackedScene) var graph_node_packed_scene = preload("../graph_node/GraphNode.tscn")

var popup_window_titles = {
	save = "Save Graph",
	load = "Load Graph",
	export = "Export Graph"
}

var panel_margin := 100
var moving_graph_node = null
var _renaming_graph_node = null
var _reference_position: Vector2

var save_key = KEY_S
var load_key = KEY_L
var export_key = KEY_E
var add_node_key = KEY_A

onready var scroll_container = $ScrollContainer
onready var panel = $ScrollContainer/Panel
onready var graph_start = $ScrollContainer/Panel/GraphStart


func _ready():
	panel.rect_min_size.x = OS.window_size.x
	panel.rect_min_size.y = OS.window_size.y - $Header.rect_size.y
	
	graph_start.connect("gui_input", self, "_on_graph_node_header_gui_input", [graph_start])
	graph_start.connect("moved", self, "_on_graph_node_moved", [graph_start])
	
	panel.connect("gui_input", self, "_on_Panel_gui_input")
	
	$FileDialog.connect("file_selected", self, "_on_FileDialog_file_selected")
	
	$Header/Items/SaveButton.connect("pressed", self, "_on_SaveButton_pressed")
	$Header/Items/LoadButton.connect("pressed", self, "_on_LoadButton_pressed")
	$Header/Items/ExportButton.connect("pressed", self, "_on_ExportButton_pressed")
	$Header/Items/DeleteButton.connect("pressed", self, "_on_DeleteButton_pressed")
	$Header/Items/AddNodeButton.connect("pressed", self, "_on_AddNodeButton_pressed")


func save_graph(path: String) -> int:
	var graph = PGE.Graph.new()
	graph.connections = serialize()
	
	if graph.connections.empty():
		return -1
	
	return ResourceSaver.save(path, graph)


func load_graph(path: String) -> void:
	clear()
	yield(get_tree().create_timer(0.3), "timeout")
	
	var graph = load(path)
	var start_node_name: String
	
	if not graph is PGE.Graph:
		$Messages.show_message("Not a valid graph file.")
		return
	
	for node_name in graph.connections:
		if node_name == graph_start.name:
			var graph_start_info = graph.connections[node_name]
			graph_start.set_editor_data(graph_start_info.editor_data)
			start_node_name = graph_start_info.start_node_name
			continue
		
		var graph_node = panel.get_node_or_null(node_name)
		
		if not graph_node:
			graph_node = add_node(Vector2())
		
		graph_node.set_editor_data(graph.connections[node_name].editor_data)
		
		for item_info in graph.connections[node_name].items:
			var graph_node_item = graph_node.add_item(item_info.editor_data.scene_path)
			graph_node_item.set_editor_data(item_info.editor_data)
			graph_node_item.set_item_data(item_info.item_data)
			
			for connected_node_name in item_info.connections:
				var connected_graph_node = panel.get_node_or_null(connected_node_name)
				
				if not connected_graph_node:
					connected_graph_node = add_node(Vector2())
				
				connected_graph_node.set_editor_data(graph.connections[connected_node_name].editor_data)
				
				graph_node_item.add_connection(connected_graph_node.slot)
	
	if start_node_name:
		var start_node = panel.get_node_or_null(start_node_name)
		graph_start.set_start_node(start_node)
	
	var focused: Control = get_focus_owner()
	if focused:
		focused.release_focus()


func export_graph(path: String) -> void:
	save_graph(path)


func serialize() -> Dictionary:
	var connections = {}
	
	for graph_node in panel.get_children():
		connections[graph_node.name] = graph_node.serialize()
	
	return connections


func add_node(node_position: Vector2):
	var new_graph_node = graph_node_packed_scene.instance()
	
	panel.add_child(new_graph_node, true)
	new_graph_node.header.connect("gui_input", self, "_on_graph_node_header_gui_input", [new_graph_node])
	new_graph_node.connect("tree_exited", self, "_on_graph_node_tree_exited", [new_graph_node])
	new_graph_node.connect("moved", self, "_on_graph_node_moved", [new_graph_node])
	
	node_position.x -= new_graph_node.rect_size.x / 2
	node_position.y -= new_graph_node.header.rect_size.y / 2
	new_graph_node.move_to(node_position)
	new_graph_node.grab_focus()
	
	return new_graph_node


func clear() -> void:
	for child in panel.get_children():
		if child == graph_start:
			continue
		
		child.queue_free()


func popup_save() -> void:
	$FileDialog.mode = FileDialog.MODE_SAVE_FILE
	$FileDialog.window_title = popup_window_titles.save
	$FileDialog.popup_centered(Vector2())


func popup_load() -> void:
	$FileDialog.mode = FileDialog.MODE_OPEN_FILE
	$FileDialog.window_title = popup_window_titles.load
	$FileDialog.popup_centered(Vector2())


func popup_export() -> void:
	if not graph_start.start_node_name:
		$Messages.show_message("Connect the Start before exporting.")
		return
	
	$FileDialog.mode = FileDialog.MODE_SAVE_FILE
	$FileDialog.window_title = popup_window_titles.export
	$FileDialog.popup_centered(Vector2())


func _on_graph_node_header_gui_input(event: InputEvent, graph_node) -> void:
	if event is InputEventMouseMotion:
		if moving_graph_node == graph_node:
			moving_graph_node.move(event.position - _reference_position)
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if event.doubleclick:
					_renaming_graph_node = graph_node
					
				else:
					if not get_tree().is_input_handled():
						_reference_position = event.position
						moving_graph_node = graph_node
				
			else:
				moving_graph_node = null


func _on_graph_node_tree_exited(graph_node) -> void:
	refresh_panel_size()


func _on_graph_node_moved(graph_node) -> void:
	if graph_node.rect_position.x < 0:
		graph_node.rect_position.x = 0
	
	if graph_node.rect_position.y < 0:
		graph_node.rect_position.y = 0
	
	refresh_panel_size()


func refresh_panel_size() -> void:
	var panel_size = Vector2()
	var window_size = OS.window_size
	
	for child in panel.get_children():
		var child_end = child.rect_position + child.rect_size

		if child_end.x > panel_size.x:
			panel_size.x = child_end.x
			pass
		if child_end.y > panel_size.y:
			panel_size.y = child_end.y
			pass
	
	if panel_size.x <= window_size.x:
		panel_size.x = window_size.x
	
	if panel_size.y <= window_size.y:
		panel_size.y = window_size.y - $Header.rect_size.y
	
	panel.rect_min_size.x = panel_size.x + panel_margin
	panel.rect_size.x = panel.rect_min_size.x
	
	panel.rect_min_size.y = panel_size.y + panel_margin
	panel.rect_size.y = panel.rect_min_size.y
	pass


func _on_Panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			scroll_container.scroll_horizontal -= event.relative.x
			scroll_container.scroll_vertical -= event.relative.y
			pass
		
	elif event is InputEventMouseButton:
		if event.pressed:
			var focused: Control = get_focus_owner()
			if focused:
				focused.release_focus()
			
			if event.button_index == BUTTON_MIDDLE:
				panel.mouse_default_cursor_shape = Control.CURSOR_DRAG
			
		else:
			panel.mouse_default_cursor_shape = Control.CURSOR_ARROW
			pass
		
#		if event.button_index == BUTTON_WHEEL_UP:
#			panel.rect_scale += Vector2(0.1, 0.1)
#			pass
#		elif event.button_index == BUTTON_WHEEL_DOWN:
#			panel.rect_scale -= Vector2(0.1, 0.1)
#			pass


func _on_FileDialog_file_selected(file_path: String) -> void:
	match $FileDialog.window_title:
		popup_window_titles.save:
			save_graph(file_path)
			
		popup_window_titles.load:
			load_graph(file_path)
		
		popup_window_titles.export:
			export_graph(file_path)

func _on_SaveButton_pressed() -> void:
	popup_save()
	pass


func _on_LoadButton_pressed() -> void:
	popup_load()
	pass


func _on_ExportButton_pressed() -> void:
	popup_export()
	pass


func _on_AddNodeButton_pressed() -> void:
	add_node(panel.get_local_mouse_position())


func _on_DeleteButton_pressed() -> void:
	var on_focus = get_focus_owner()
	if not on_focus: return
	
	if on_focus is PGE.GraphNode or on_focus is PGE.GraphNodeItem:
		on_focus.queue_free()


func _on_CloseButton_pressed() -> void:
	get_tree().quit()