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

func closest_street_point(point: Vector2) -> Vector2:
	var edge := _nearest(point)
	return Geometry2D.get_closest_point_to_segment(point, graph.get_point_position(edge.x), graph.get_point_position(edge.y))

func path(start: Vector2, goal: Vector2, heading := Vector2.ZERO, wide_turns := false) -> PackedVector2Array:
	var driving := not heading.is_zero_approx()
	var first := _nearest(start + heading * 1.5 if driving else start)
	var axis := graph.get_point_position(first.x).direction_to(graph.get_point_position(first.y))
	var forward_id := first.y if axis.dot(heading) >= 0 else first.x
	var forward := axis if forward_id == first.y else -axis
	var last := _nearest(goal)
	var temporary: Array[int]=[]
	for pair in [[start,first],[goal,last]]:
		var edge: Vector2i=pair[1]
		var snap := Geometry2D.get_closest_point_to_segment(pair[0],graph.get_point_position(edge.x),graph.get_point_position(edge.y))
		var id := graph.get_available_point_id()
		graph.add_point(id,snap)
		if driving and temporary.is_empty():
			graph.connect_points(id,forward_id,false)
		else:
			graph.connect_points(id,edge.x)
			graph.connect_points(id,edge.y)
		temporary.append(id)
	if first==last and (not driving or (goal-start).dot(forward)>=0):
		graph.connect_points(temporary[0],temporary[1])
	# Long vehicles need more turning room than the gap between opposing lanes.
	# Route around the block if the shortest route doubles back at the junction.
	var points := graph.get_point_path(temporary[0],temporary[1])
	if wide_turns and driving and points.size() >= 3 and (points[2]-points[1]).dot(forward) < -.01:
		graph.disconnect_points(first.x,first.y)
		if first == last: graph.disconnect_points(temporary[1],forward_id)
		var detour := graph.get_point_path(temporary[0],temporary[1])
		graph.connect_points(first.x,first.y)
		if not detour.is_empty(): points = detour
	for id in temporary:
		graph.remove_point(id)
	if driving:
		points = _lane_path(points)
	points.append(goal)
	return points

func _lane_path(centres: PackedVector2Array) -> PackedVector2Array:
	var lane := PackedVector2Array()
	var previous := Vector2.ZERO
	for i in range(1, centres.size()):
		var a := centres[i-1]
		var b := centres[i]
		if a.is_equal_approx(b): continue
		var direction := a.direction_to(b)
		var right := Vector2(-direction.y, direction.x)
		var middle := (a+b)*.5
		var along_tracks := (middle.y in [-48.0,35.0] and middle.x > -420 and middle.x < -150) or (middle.x in [-420.0,-150.0] and middle.y > -48 and middle.y < 35)
		var offset := right * (6.0 if along_tracks else 2.35)
		if previous.dot(direction) < -.99:
			# Arc across the junction from the incoming lane to the returning lane.
			var incoming := lane[-1] - a
			for part in range(1, 8):
				var angle := PI*part/8.0
				lane.append(a + incoming*cos(angle) + previous*incoming.length()*sin(angle))
		if not previous.is_zero_approx() and absf(previous.dot(direction)) < .01:
			# Intersect the two lane lines, then round their corner with a tangent arc.
			var corner := lane[-1] + previous * offset.dot(previous)
			var approach := (corner - lane[-2]).dot(previous)
			var exit_length := (b + offset - corner).dot(direction)
			var radius := clampf(minf(approach, exit_length) * .5, 0.0, 3.5)
			if approach >= 0 and exit_length >= 0:
				var entry := corner - previous * radius
				var exit := corner + direction * radius
				lane[-1] = entry
				for part in range(1, 6):
					lane.append(entry.bezier_interpolate(entry.lerp(corner, 2.0/3.0), exit.lerp(corner, 2.0/3.0), exit, part/5.0))
			else:
				lane.append(a + offset)
		else:
			lane.append(a + offset)
		lane.append(b + offset)
		previous = direction
	return lane

# Keep the chosen junction while the vehicle follows a bend or U-turn.
var remaining_lane := PackedVector2Array()
var lane_goal := Vector2.INF
var cached_wide_turns := false

func driving_path(start: Vector2, goal: Vector2, heading: Vector2, wide_turns := false) -> PackedVector2Array:
	if goal.is_equal_approx(lane_goal) and wide_turns == cached_wide_turns:
		var distance_ahead := 0.0
		var best_gap := 4.0
		var best_segment := -1
		var nearest := start
		for i in range(1, remaining_lane.size()):
			var a := remaining_lane[i-1]
			var b := remaining_lane[i]
			if a.is_equal_approx(b): continue
			var snap := Geometry2D.get_closest_point_to_segment(start, a, b)
			var gap := snap.distance_to(start)
			if gap < best_gap and a.direction_to(b).dot(heading) > 0.0:
				best_segment = i
				best_gap = gap
				nearest = snap
			distance_ahead += a.distance_to(b)
			if distance_ahead > 30.0: break
		if best_segment >= 0:
			remaining_lane = remaining_lane.slice(best_segment-1)
			remaining_lane[0] = nearest
			return remaining_lane
	lane_goal = goal
	cached_wide_turns = wide_turns
	remaining_lane = path(start, goal, heading, wide_turns)
	return remaining_lane
