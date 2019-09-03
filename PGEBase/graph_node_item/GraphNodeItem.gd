tool
extends PanelContainer

enum SlotSide {LEFT, RIGHT}

export var type := "Item"
export var max_per_node := 0
export var slot_active := true setget set_slot_active
export var resizable := true
export(SlotSide) var slot_side := SlotSide.RIGHT setget set_slot_side
export(StyleBox) var style_box_normal = preload("GraphNodeItemPanelNormal.tres")
export(StyleBox) var style_box_focus = preload("GraphNodeItemPanelFocus.tres")

var resizing = false
var scene_path: String
var graph_node
var _reference_position: Vector2

onready var content: PanelContainer = $Parts/Content
onready var slot = $Parts/GraphNodeSlot


func _ready() -> void:
	if slot:
		slot.set_visible(slot_active)
	
	if not Engine.editor_hint:
		$Resizer.set_visible(resizable)
		slot.graph_node_item = self
		
		connect("gui_input", self, "_on_gui_input")
		connect("focus_entered", self, "_on_focus_entered")
		connect("focus_exited", self, "_on_focus_exited")
		
		$PopupMenu.connect("index_pressed", self, "_on_PopupMenu_index_pressed")
		$Parts/DeleteButton.connect("pressed", self, "_on_DeleteButton_pressed")
		$Resizer.connect("gui_input", self, "_on_Resizer_gui_input")


func add_connection(to_slot) -> void:
	slot.connect_to(to_slot)


func serialize() -> Dictionary:
	var info := {
		type = type,
		editor_data = get_editor_data(),
		item_data = get_item_data(),
		connections = []
	}
	var path = get_path()
	
	if slot_active:
		for connected_slot in slot.get_connections():
			info.connections.append(connected_slot.graph_node.name)
	
	return info


func get_editor_data() -> Dictionary:
	var editor_data := {
		name = name,
		graph_node_editor_data = graph_node.get_editor_data(),
		rect_position = rect_position,
		rect_min_size = rect_min_size,
		rect_size = rect_size,
		slot_active = slot_active,
		slot_side = slot_side,
		scene_path = scene_path
	}
	
	return editor_data


func set_editor_data(editor_data: Dictionary) -> void:
	set_name(editor_data.name)
	set_position(editor_data.rect_position)
	set_custom_minimum_size(editor_data.rect_min_size)
	set_size(editor_data.rect_size)
	set_slot_active(editor_data.slot_active)
	set_slot_side(editor_data.slot_side)
	scene_path = editor_data.scene_path


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if not get_tree().is_input_handled():
					$PopupMenu.popup(Rect2(get_global_mouse_position(), Vector2(1, 1)))
					pass


func _on_focus_entered() -> void:
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
			pass
		_:
			print("[WARNING]: nothing implemented for index %s." % index)


func _on_Resizer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if resizing:
			
			rect_min_size.y += event.position.y - _reference_position.y
			rect_size.y = rect_min_size.y
			rect_min_size.y = rect_size.y
#			if rect_size.y > rect_min_size.y:
#				rect_min_size.y = rect_size.y
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			resizing = event.pressed
			_reference_position = event.position


func _on_DeleteButton_pressed() -> void:
	queue_free()


func set_slot_active(value: bool) -> void:
	slot_active = value
	
	var slot = get_node_or_null("Parts/GraphNodeSlot")
	if slot:
		slot.set_visible(value)


func set_slot_side(value: int) -> void:
	slot_side = value
	
	if slot_side == SlotSide.LEFT:
		$Parts.move_child($Parts/DeleteButton, 2)
		$Parts.move_child($Parts/GraphNodeSlot, 0)
		$Parts/GraphNodeSlot.tangent_x_direction = -1
		
	elif slot_side == SlotSide.RIGHT:
		$Parts.move_child($Parts/DeleteButton, 0)
		$Parts.move_child($Parts/GraphNodeSlot, 2)
		$Parts/GraphNodeSlot.tangent_x_direction = 1


func get_item_data(): pass
func set_item_data(data): pass
