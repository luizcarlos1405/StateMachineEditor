extends Resource

export var connections: Dictionary

"""
	connections is an adjacency list in the following format:
	
	{
		'GraphStart' : {
			'editor_data' :{
				rect_position
			},
			'name': the node's name
			'start_node_name' : sarting node name,
		},
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