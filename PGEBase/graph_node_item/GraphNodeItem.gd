tool
extends VBoxContainer

enum SlotSide {LEFT, RIGHT}

export var slot_active := true setget set_slot_active
export(SlotSide) var slot_side := SlotSide.RIGHT setget set_slot_side

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
		slot.graph_node_item = self
		
		$Parts/DeleteButton.connect("pressed", self, "_on_DeleteButton_pressed")
		
		$Resizer.connect("gui_input", self, "_on_Resizer_gui_input")


func add_connection(to) -> void:
	var graph_edge = GraphEdge.new()
	$Parts/GraphNodeSlot.add_child(graph_edge)
	
	graph_edge.set_from($Parts/GraphNodeSlot)
	graph_edge.set_to(to)


func serialize() -> Dictionary:
	var info := {
		editor_data = get_editor_data(),
		item_data = get_data(),
		connections = []
	}
	var path = get_path()
	
	if slot_active:
		for connection in slot.get_connections():
			info.connections.append(connection.to.graph_node.name)
	
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


func get_data():pass
func set_data(data): pass


func _on_Resizer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if resizing:
			if event.relative.y > 0:
				if event.position.y < 0:
					return
			
			rect_min_size.y += event.position.y - _reference_position.y
		
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			resizing = event.pressed
			_reference_position = event.position


func _on_DeleteButton_pressed() -> void:
	queue_free()


func set_slot_active(value: bool) -> void:
	slot_active = value
	
	if Engine.editor_hint and slot:
		slot.set_visible(value)


func set_slot_side(value: int) -> void:
	slot_side = value
	
	if slot_side == SlotSide.LEFT:
		$Parts.move_child($Parts/DeleteButton, 2)
		$Parts.move_child(slot, 0)
		
	elif slot_side == SlotSide.RIGHT:
		$Parts.move_child($Parts/DeleteButton, 0)
		$Parts.move_child(slot, 2)