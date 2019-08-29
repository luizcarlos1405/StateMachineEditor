extends Control

export(PackedScene) var graph_node_packed_scene = preload("../graph_node/GraphNode.tscn")

var popup_window_titles = {
	save = "Save Graph",
	load = "Load Graph",
	export = "Export Graph"
}

var moving_window_reference_position = Vector2()
var moving_graph_node = null
var _reference_position: Vector2

var save_key = KEY_S
var load_key = KEY_L
var export_key = KEY_E
var add_node_key = KEY_A

onready var graph_start = $Parts/ScrollContainer/Panel/GraphStart


func _ready():
	graph_start.connect("gui_input", self, "_on_graph_node_header_gui_input", [graph_start])
	graph_start.connect("moved", self, "_on_graph_node_moved", [graph_start])
#	for graph_node in $Parts/ScrollContainer/Panel.get_children():
#		if graph_node.name != "GraphStart":
#			graph_node.header.connect("gui_input", self, "_on_graph_node_header_gui_input", [graph_node])
	
	$Parts/ScrollContainer/Panel.connect("gui_input", self, "_on_Panel_gui_input")
	
	$FileDialog.connect("file_selected", self, "_on_FileDialog_file_selected")
	$Parts/Header/SaveButton.connect("pressed", self, "_on_SaveButton_pressed")
	$Parts/Header/LoadButton.connect("pressed", self, "_on_LoadButton_pressed")
	$Parts/Header/ExportButton.connect("pressed", self, "_on_ExportButton_pressed")
	$Parts/Header/CloseButton.connect("pressed", self, "_on_CloseButton_pressed")
	pass


func save_graph(path: String) -> int:
	var graph = PGEGraph.new()
	graph.connections = serialize()
	
	if graph.connections.empty():
		return -1
	
	return ResourceSaver.save(path, graph)


func load_graph(path: String) -> void:
	clear()
	yield(get_tree().create_timer(0.3), "timeout")
	
	var graph: PGEGraph = load(path)
	
	for node_name in graph.connections:
		var graph_node = $Parts/ScrollContainer/Panel.get_node_or_null(node_name)
		
		if not graph_node:
			graph_node = add_node(Vector2())
		
		graph_node.set_editor_data(graph.connections[node_name].editor_data)
		
		for item_info in graph.connections[node_name].items:
			var graph_node_item = graph_node.add_item(item_info.editor_data.scene_path)
			graph_node_item.set_editor_data(item_info.editor_data)
			graph_node_item.set_data(item_info.item_data)
			
			for connected_node_name in item_info.connections:
				var connected_graph_node = $Parts/ScrollContainer/Panel.get_node_or_null(connected_node_name)
				
				if not connected_graph_node:
					connected_graph_node = add_node(Vector2())
				
				connected_graph_node.set_editor_data(graph.connections[connected_node_name].editor_data)
				
				graph_node_item.add_connection(connected_graph_node.slot)


func export_graph(path: String) -> void:
	save_graph(path)
	pass


func serialize() -> Dictionary:
	var connections = {}
	
	connections.start = graph_start.get_start_node_name()
	
	for graph_node in $Parts/ScrollContainer/Panel.get_children():
		if graph_node.name == "GraphStart":
			continue
		
		connections[graph_node.name] = graph_node.serialize()
	
	return connections


func add_node(node_position: Vector2):
	var new_graph_node = graph_node_packed_scene.instance()
	
	$Parts/ScrollContainer/Panel.add_child(new_graph_node, true)
	new_graph_node.header.connect("gui_input", self, "_on_graph_node_header_gui_input", [new_graph_node])
	new_graph_node.connect("moved", self, "_on_graph_node_moved", [new_graph_node])
	
	node_position.x -= new_graph_node.rect_size.x / 2
	node_position.y -= new_graph_node.header.rect_size.y / 2
	new_graph_node.move_to(node_position)
	
	return new_graph_node


func clear() -> void:
	for child in $Parts/ScrollContainer/Panel.get_children():
		if child.name == "GraphStart":
			continue
		
		child.queue_free()


func popup_save() -> void:
	$FileDialog.window_title = popup_window_titles.save
	$FileDialog.mode = FileDialog.MODE_SAVE_FILE
	$FileDialog.popup_centered(Vector2())


func popup_load() -> void:
	$FileDialog.window_title = popup_window_titles.load
	$FileDialog.mode = FileDialog.MODE_OPEN_FILE
	$FileDialog.popup_centered(Vector2())


func popup_export() -> void:
	if not graph_start.get_start_node_name():
		$Messages.show_message("Connect the Start before exporting.")
		return
	
	$FileDialog.window_title = popup_window_titles.export
	$FileDialog.mode = FileDialog.MODE_SAVE_FILE
	$FileDialog.popup_centered(Vector2())


func _on_Title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if moving_window_reference_position:
			OS.window_position += get_local_mouse_position() - moving_window_reference_position
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				moving_window_reference_position = get_local_mouse_position()
			else:
				moving_window_reference_position = Vector2()


func _on_graph_node_header_gui_input(event: InputEvent, graph_node) -> void:
	if event is InputEventMouseMotion:
		if moving_graph_node == graph_node:
			moving_graph_node.move(event.position - _reference_position)
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_reference_position = event.position
				moving_graph_node = graph_node
				moving_graph_node.raise()
				
			else:
				moving_graph_node = null


func _on_graph_node_moved(graph_node) -> void:
	if graph_node.rect_position.x < 0:
		graph_node.rect_position.x = 0
	
	if graph_node.rect_position.y < 0:
		graph_node.rect_position.y = 0
	
	var graph_node_end = graph_node.rect_position + graph_node.rect_size
	var panel_end = $Parts/ScrollContainer/Panel.rect_size
	
	if graph_node_end.x > panel_end.x:
#		$Parts/ScrollContainer/Panel.rect_min_size.x = graph_node_end.x
		graph_node.rect_position.x = panel_end.x - graph_node.rect_size.x
	
	if graph_node_end.y > panel_end.y:
#		$Parts/ScrollContainer/Panel.rect_min_size.y = graph_node_end.y
		graph_node.rect_position.y = panel_end.y - graph_node.rect_size.y


func _on_Panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
#			add_node(event.position)
			pass


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


func _on_CloseButton_pressed() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == save_key and event.pressed and Input.is_key_pressed(KEY_CONTROL):
			save_graph("res://Test.res")
			
		elif event.scancode == add_node_key and event.pressed and Input.is_key_pressed(KEY_CONTROL):
			add_node($Parts/ScrollContainer/Panel.get_local_mouse_position())
			
		elif event.scancode == load_key and event.pressed and Input.is_key_pressed(KEY_CONTROL):
			load_graph("res://Test.res")
			
		elif event.scancode == KEY_P and event.pressed:
			print(serialize())