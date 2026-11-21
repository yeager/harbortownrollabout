extends RefCounted
# Centrelines of the connected streets, including both canal bridges.
const ROWS := [[-82,102,162],[-48,-510,-420,-330,-240,-150,-55,0,48,102,162],[0,-510,-420,-330,-240,-150,-55,0,48,102,162],[35,-510,-420,-330,-240,-150,-55,0,48],[60,102,162]]
const COLUMNS := [[-510,-48,0,35],[-420,-48,0,35],[-330,-48,0,35],[-240,-48,0,35],[-150,-48,0,35],[-55,-48,0,35],[0,-48,0,35],[48,-48,0,35],[102,-82,-48,0,60],[162,-82,-48,0,60]]
var graph := AStar2D.new()
var edges: Array[Vector2i] = []

func _init() -> void:
	var ids := {}
	for lines in [ROWS,COLUMNS]:
		for line in lines:
			var previous := -1
			for index in range(1,line.size()):
				var point := Vector2(line[index],line[0]) if lines==ROWS else Vector2(line[0],line[index])
				if not ids.has(point):
					ids[point]=graph.get_available_point_id()
					graph.add_point(ids[point],point)
				var id := int(ids[point])
				if previous>=0:
					graph.connect_points(previous,id)
					edges.append(Vector2i(previous,id))
				previous=id

func _nearest(point: Vector2) -> Vector2i:
	var best := INF
	var result := edges[0]
	for edge in edges:
		var snap := Geometry2D.get_closest_point_to_segment(point,graph.get_point_position(edge.x),graph.get_point_position(edge.y))
		if snap.distance_squared_to(point)<best:
			best=snap.distance_squared_to(point)
			result=edge
	return result

func path(start: Vector2, goal: Vector2) -> PackedVector2Array:
	var first := _nearest(start)
	var last := _nearest(goal)
	var temporary: Array[int]=[]
	for pair in [[start,first],[goal,last]]:
		var edge: Vector2i=pair[1]
		var snap := Geometry2D.get_closest_point_to_segment(pair[0],graph.get_point_position(edge.x),graph.get_point_position(edge.y))
		var id := graph.get_available_point_id()
		graph.add_point(id,snap)
		graph.connect_points(id,edge.x)
		graph.connect_points(id,edge.y)
		temporary.append(id)
	if first==last:
		graph.connect_points(temporary[0],temporary[1])
	var points := graph.get_point_path(temporary[0],temporary[1])
	for id in temporary:
		graph.remove_point(id)
	points.append(goal)
	return points
