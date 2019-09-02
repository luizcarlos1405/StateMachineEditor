tool
extends Panel

signal moved
signal item_added(item)
signal item_removed(item)
signal item_reordered(item)

enum SlotSide {LEFT, RIGHT}

export(PoolStringArray) var item_scene_paths = ["res://PGEBase/graph_node_item/GraphNodeItem.tscn"]
export(SlotSide) var slot_side := SlotSide.LEFT setget set_slot_side
export(StyleBox) var style_box_normal = preload("GraphNodePanelNormal.tres")
export(StyleBox) var style_box_focus = preload("GraphNodePanelFocus.tres")
export(Color) var self_connection_slot_color = Color("5268c0")

var item_counter := {}
var resizing := false
var _moving_item = null
var _reference_position: Vector2
var _min_x_bezier_tangent := 60.0

onready var slot := $Parts/Menu/GraphNodeSlot
onready var header := $Parts/Header
onready var items := $Parts/Items
onready var add_item_popup: PopupMenu = $Parts/Menu/AddItemButton.get_popup()


func _ready() -> void:
	if not Engine.editor_hint:
		$Parts/Menu/GraphNodeSlot.graph_node = self
#		rect_min_size = rect_size
		
		connect("gui_input", self, "_on_gui_input")
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")
		
		$PopupMenu.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
		$Parts/Header.connect("gui_input", self, "_on_Header_gui_input")
		$Parts/Header/Name.connect("text_entered", self, "_on_LineEdit_text_entered")
		$Parts/Header/Name.connect("focus_exited", self, "_on_LineEdit_focus_exited")
		$Parts/Header/Name.text = name
		
		$Parts.connect("sort_children", self, "_on_Parts_sort_children")
		$ResizerRight.connect("gui_input", self, "_on_Resizer_gui_input", [$ResizerRight])
		$ResizerLeft.connect("gui_input", self, "_on_Resizer_gui_input", [$ResizerLeft])
		$Parts/Header/CloseButton.connect("pressed", self, "_on_CloseButton_pressed")
		add_item_popup.connect("index_pressed", self, "_on_AddItemButton_popup_menu_index_pressed")
		
		for i in range(item_scene_paths.size()):
			var item: PackedScene = load(item_scene_paths[i])
			
			if not item:
				print("[ERROR]: item not found at %s." % item_scene_paths[i])
				continue
			
			var scene_state: SceneState = item.get_state()
			
			# Get the type defined on the editor, I'm not sure if it will aways work
			var item_type = "Item"
			var type_variable_id = Array(item._bundled.names).find("type")
			
			if type_variable_id > -1:
				item_type = scene_state.get_node_property_value(0, type_variable_id - 1)
				pass
			
			add_item_popup.add_item(item_type)
			item_counter[item_scene_paths[i]] = {
				popup_menu_id = i,
				count = 0
			}


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
		slot_side = slot_side,
		item_scene_paths = item_scene_paths
	}
	
	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
	set_name(editor_data.name)
	set_position(editor_data.rect_position)
#	set_custom_minimum_size(editor_data.rect_min_size)
	set_size(editor_data.rect_size)
	set_slot_side(editor_data.slot_side)
	item_scene_paths = editor_data.item_scene_paths
	
	$Parts/Header/Name.text = name


func add_item(item_scene_path: String):
	var packed_scene: PackedScene = load(item_scene_path)
	var new_item = packed_scene.instance()
	
	$Parts/Items.add_child(new_item, true)
	
	new_item.connect("gui_input", self, "_on_item_gui_input", [new_item])
	new_item.connect("resized", self, "_on_item_resized", [new_item])
	new_item.connect("tree_exiting", self, "_on_item_tree_exiting", [new_item])
	new_item.graph_node = self
	new_item.slot.graph_node = self
	new_item.scene_path = item_scene_path
	new_item.name = new_item.type
	
	emit_signal("item_added", new_item)
	
	item_counter[item_scene_path].count += 1
	if item_counter[item_scene_path].count >= new_item.max_per_node:
		add_item_popup.set_item_disabled(item_counter[item_scene_path].popup_menu_id, true)
		pass
	
	return new_item


func move(ammount: Vector2) -> void:
	rect_position += ammount
	emit_signal("moved")


func move_to(position: Vector2) -> void:
	rect_position = position
	emit_signal("moved")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if not get_tree().is_input_handled():
					$PopupMenu.popup(Rect2(get_global_mouse_position(), Vector2(1, 1)))
					pass


func _on_focus_entered() -> void:
	raise()
	add_stylebox_override("panel", style_box_focus)


func _on_focus_exited() -> void:
	add_stylebox_override("panel", style_box_normal)


func _on_PopupMenu_index_pressed(index: int) -> void:
	match index:
		0:
			
			if slot_side == SlotSide.LEFT:
				set_slot_side(SlotSide.RIGHT)
				
			elif slot_side == SlotSide.RIGHT:
				set_slot_side(SlotSide.LEFT)
		_:
			print("[WARNING]: nothing implemented for index %s." % index)


func _on_Header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.doubleclick:
				$Parts/Header/Name.grab_focus()
				$Parts/Header/Name.select_all()
				$Parts/Header/Name.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_LineEdit_text_entered(new_text: String)  -> void:
	$Parts/Header/Name.release_focus()
	
	if new_text:
		name = new_text
		$Parts/Header/Name.text = name


func _on_LineEdit_focus_exited() -> void:
	$Parts/Header/Name.deselect()
	$Parts/Header/Name.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_CloseButton_pressed() -> void:
	queue_free()


func _on_Resizer_gui_input(event: InputEvent, resizer) -> void:
	if event is InputEventMouseMotion:
		if resizing:
			var variation = event.position.x - _reference_position.x
			
			if resizer == $ResizerLeft:
				# Stop the resizing from_slot actually moving to the right
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


func _on_AddItemButton_popup_menu_index_pressed(id: int) -> void:
	add_item(item_scene_paths[id])


func _on_item_gui_input(event: InputEvent, item) -> void:
	if event is InputEventMouseMotion:
		if _moving_item:
			var move_to_index = 0
			
			for item in items.get_children():
				if items.get_local_mouse_position().y > item.rect_position.y:
					move_to_index = item.get_index()
					
				pass
				
			if move_to_index != _moving_item.get_index():
				items.move_child(_moving_item, move_to_index)
				emit_signal("item_reordered", _moving_item)
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not get_tree().is_input_handled():
			if event.pressed:
				item.set_default_cursor_shape(Input.CURSOR_DRAG)
				_moving_item = item
				
			else:
				item.set_default_cursor_shape(Input.CURSOR_ARROW)
				_moving_item = null


func _on_item_resized(item: VBoxContainer) -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2


func _on_item_tree_exiting(item) -> void:
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2
	
	item_counter[item.scene_path].count -= 1
	add_item_popup.set_item_disabled(item_counter[item.scene_path].popup_menu_id, false)
	
	emit_signal("item_removed", item)


func _on_Parts_sort_children() -> void:
	$Parts.rect_size.y = 0 # Workaround for a weird bug on resizing
	rect_size.y = $Parts.rect_size.y + $Parts.margin_top * 2
	


func set_slot_side(value: int) -> void:
	slot_side = value
	
	var menu = get_node_or_null("Parts/Menu")
	if menu and $Parts/Menu/GraphNodeSlot:
		if slot_side == SlotSide.LEFT:
			$Parts/Menu.move_child($Parts/Menu/GraphNodeSlot, 0)
			$Parts/Menu/GraphNodeSlot.tangent_x_direction = -1
			
		elif slot_side == SlotSide.RIGHT:
			$Parts/Menu.move_child($Parts/Menu/GraphNodeSlot, 1)
			$Parts/Menu/GraphNodeSlot.tangent_x_direction = 1