tool
extends Panel

signal moved
signal item_added(item)
signal item_removed(item)

enum SlotSide {LEFT, RIGHT}

export(PoolStringArray) var item_scene_paths = ["res://PGEBase/graph_node_item/GraphNodeItem.tscn"]
export(SlotSide) var node_slot_side := SlotSide.LEFT setget set_node_slot_side
export(SlotSide) var items_slot_side := SlotSide.RIGHT setget set_items_slot_side
export(StyleBox) var style_box_normal = preload("GraphNodePanelNormal.tres")
export(StyleBox) var style_box_focus = preload("GraphNodePanelFocus.tres")

var resizing := false
var _reference_position: Vector2

onready var slot = $Parts/Menu/GraphNodeSlot
onready var header = $Parts/Header
onready var items = $Parts/Items
onready var add_item_popup = $Parts/Menu/AddItemButton.get_popup()


func _ready() -> void:
	if not Engine.editor_hint:
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")
		
		$Parts/Header/Label.text = name
		
		$Parts/Menu/GraphNodeSlot.graph_node = self
		rect_min_size = rect_size
		
		$Parts.connect("sort_children", self, "_on_Parts_sort_children")
		$ResizerRight.connect("gui_input", self, "_on_Resizer_gui_input", [$ResizerRight])
		$ResizerLeft.connect("gui_input", self, "_on_Resizer_gui_input", [$ResizerLeft])
		$Parts/Header/CloseButton.connect("pressed", self, "_on_CloseButton_pressed")
		add_item_popup.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
		
		for item_scene_path in item_scene_paths:
			var item: PackedScene = load(item_scene_path)
			
			if not item:
				print("[ERROR]: item not found at %s." % item_scene_path)
				continue
			
			var scene_state: SceneState = item.get_state()
			
			add_item_popup.add_item(scene_state.get_node_name(0))
		
		for item in $Parts/Items.get_children():
			item.connect("resized", self, "_on_item_resized", [item])
			item.graph_node = self
			item.slot.graph_node = self
			item.slot_side = items_slot_side


func serialize() -> Dictionary:
	var info = {
		editor_data = get_editor_data(),
		items = []
	}
	
	for graph_node_item in $Parts/Items.get_children():
		var item_info: Dictionary = graph_node_item.serialize()
		info.items.append(item_info)
	
	return info


func get_editor_data() -> Dictionary:
	var editor_data := {
		name = name,
		rect_position = rect_position,
		rect_min_size = rect_min_size,
		rect_size = rect_size,
		node_slot_side = node_slot_side,
		items_slot_side = items_slot_side,
		item_scene_paths = item_scene_paths
	}
	
	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
#	print(editor_data.name)
	set_name(editor_data.name)
	set_position(editor_data.rect_position)
	set_custom_minimum_size(editor_data.rect_min_size)
	set_size(editor_data.rect_size)
	set_node_slot_side(editor_data.node_slot_side)
	set_items_slot_side(editor_data.items_slot_side)
	item_scene_paths = editor_data.item_scene_paths
	
	$Parts/Header/Label.text = name


func add_item(item_scene_path: String):
	var packed_scene: PackedScene = load(item_scene_path)
	var new_item = packed_scene.instance()
	
	$Parts/Items.add_child(new_item, true)
	
	new_item.connect("resized", self, "_on_item_resized", [new_item])
	new_item.connect("tree_exiting", self, "_on_item_tree_exiting", [new_item])
	new_item.graph_node = self
	new_item.slot.graph_node = self
	new_item.slot_side = items_slot_side
	new_item.scene_path = item_scene_path
	
	emit_signal("item_added", new_item)
	
	return new_item


func move(ammount: Vector2) -> void:
	rect_position += ammount
	emit_signal("moved")


func move_to(position: Vector2) -> void:
	rect_position = position
	emit_signal("moved")


func _on_focus_entered() -> void:
	add_stylebox_override("panel", style_box_focus)
#	get_stylebox("panel", "").border_color = Color(focus_border_color)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)
#	get_stylebox("panel", "").border_color = Color(normal_border_color)


func _on_CloseButton_pressed() -> void:
	queue_free()


func _on_Resizer_gui_input(event: InputEvent, resizer) -> void:
	if event is InputEventMouseMotion:
		if resizing:
			var variation = event.position.x - _reference_position.x
			
			if resizer == $ResizerLeft:
				# Stop the resizing from actually moving to the right
				if variation > 0:
					if variation > rect_size.x - rect_min_size.x:
						variation = rect_size.x - rect_min_size.x
					pass
				
				var old_x_position = rect_position.x
				move(Vector2(variation, 0))
				
				# If moved to the same place cancel the resizing
				if rect_position.x == old_x_position: return
				
				# It could be moved less than the variation
				variation = rect_position.x - old_x_position
				
				rect_size.x -= variation
				
			elif resizer == $ResizerRight:
				rect_size.x += variation
		
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			resizing = event.pressed
			_reference_position = event.position


func _on_PopupMenu_index_pressed(id: int) -> void:
	add_item(item_scene_paths[id])


func _on_item_resized(item: VBoxContainer) -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func _on_item_tree_exiting(item) -> void:
	emit_signal("item_removed", item)
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2
	pass


func _on_Parts_sort_children() -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func set_node_slot_side(value: int) -> void:
	node_slot_side = value
	
	if node_slot_side == SlotSide.LEFT:
		$Parts/Menu.move_child(slot, 0)
		
	elif node_slot_side == SlotSide.RIGHT:
		$Parts/Menu.move_child(slot, 1)


func set_items_slot_side(value: int) -> void:
	items_slot_side = value
	
	if not Engine.editor_hint:
		for item in items.get_children():
			item.set_slot_side(value)