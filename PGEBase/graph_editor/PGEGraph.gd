extends Resource

class_name PGEGraph

export var connections: Dictionary

"""
	connections is an adjacency list in the following format:
	
	{
		start : node_name,
		node_name : {
			'editor_data' : {
				data the editor needs to load and edit the node
			},
			'items' : [
				{
					'editor_data' : {
						...
					},
					'item_data' : {
						custom data to be exported
					},
					'connections' : [
						the names of the nodes this item is connected
					]
				}
			]
		},
		...
	}
"""