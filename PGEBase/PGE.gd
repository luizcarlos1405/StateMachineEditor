extends Node

var path = {
	Graph = "graph_editor/Gaph.gd",
	GraphEditor = "graph_editor/GraphEditor.gd",
	Messages = "graph_editor/Messages.gd",
	
	GraphNode = "graph_node/GraphNode.gd",
	
	GraphNodeItem = "graph_node_item/GraphNodeItem.gd",
	
	Slot = "slot/Slot.gd",
	Edge = "slot/Edge.gd",
	SlotPopupMenu = "slot/SlotPopupMenu.gd",
	
	GraphStart = "graph_start/GraphStart.gd",
	
	Parser = "Parser.gd",
}

var Graph = preload("graph_editor/Gaph.gd")
var GraphEditor = preload("graph_editor/GraphEditor.gd")
var Messages = preload("graph_editor/Messages.gd")

var GraphNode = preload("graph_node/GraphNode.gd")

var GraphNodeItem = preload("graph_node_item/GraphNodeItem.gd")

var Slot = preload("slot/Slot.gd")
var Edge = preload("slot/Edge.gd")
var SlotPopupMenu = preload("slot/SlotPopupMenu.gd")

var GraphStart = preload("graph_start/GraphStart.gd")

var Parser = preload("Parser.gd")