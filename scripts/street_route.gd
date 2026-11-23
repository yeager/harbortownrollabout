extends RefCounted
# Centrelines of the connected streets, including both canal bridges.
const ROWS := [[-82,102,162],[-48,-510,-420,-330,-240,-150,-55,0,48,102,162],[0,-510,-420,-330,-240,-150,-55,0,48,102,162],[35,-510,-420,-330,-240,-150,-55,0,48],[60,102,162]]
const COLUMNS := [[-510,-48,0,35],[-420,-48,0,35],[-330,-48,0,35],[-240,-48,0,35],[-150,-48,0,35],[-55,-48,0,35],[0,-48,0,35],[48,-48,0,35],[102,-82,-48,0,60],[162,-82,-48,0,60]]
const TRAM_LANE_OFFSET := 6.0
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

func _nearest(point: Vector2, heading := Vector2.ZERO) -> Vector2i:
	var best := INF
	var best_alignment := 0.0
	var result := edges[0]
	for edge in edges:
		var snap := Geometry2D.get_closest_point_to_segment(point,graph.get_point_position(edge.x),graph.get_point_position(edge.y))
		var cost := snap.distance_squared_to(point)
		var alignment := 0.0
		if not heading.is_zero_approx():
			# Inside a junction the crossing centreline can be closer than our own lane.
			var axis := graph.get_point_position(edge.x).direction_to(graph.get_point_position(edge.y))
			alignment = absf(axis.dot(heading))
			cost += TRAM_LANE_OFFSET * TRAM_LANE_OFFSET * (1.0 - alignment)
		if cost < best or (cost == best and alignment > best_alignment):
			best = cost
			best_alignment = alignment
			result=edge
	return result

func closest_street_point(point: Vector2) -> Vector2:
	var edge := _nearest(point)
	return Geometry2D.get_closest_point_to_segment(point, graph.get_point_position(edge.x), graph.get_point_position(edge.y))

func path(start: Vector2, goal: Vector2, heading := Vector2.ZERO, wide_turns := false) -> PackedVector2Array:
	var driving := not heading.is_zero_approx()
	var first := _nearest(start + heading * 1.5, heading) if driving else _nearest(start)
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
		if wide_turns and points.size() >= 2:
			var corner := points[-1]
			var approach := points[-2].direction_to(corner)
			var departure := corner.direction_to(goal)
			if absf(approach.dot(departure)) < .01 and corner.distance_to(goal) > 6:
				var radius := minf(3.5, points[-2].distance_to(corner)*.5)
				var entry := corner - approach*radius
				var exit := corner + departure*radius
				points[-1] = entry
				for part in range(1, 6):
					points.append(entry.bezier_interpolate(entry.lerp(corner, 2.0/3.0), exit.lerp(corner, 2.0/3.0), exit, part/5.0))
	if points.is_empty() or not points[-1].is_equal_approx(goal):
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
		var offset := right * (TRAM_LANE_OFFSET if along_tracks else 2.35)
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
		elif lane.is_empty() or not lane[-1].is_equal_approx(a + offset):
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

# Proper names are shared by all interface languages. Match the centreline,
# since the driving path runs beside it in the vehicle's lane.
const AVENUE_NAMES := {-82:"Norra kajgatan",-48:"Verkstadsgatan",0:"Storgatan",35:"Stationsallén",60:"Södra kajgatan"}
const CROSS_STREET_NAMES := {-510:"Ändhållplatsvägen",-420:"Lindgatan",-330:"Vagnhallsgatan",-240:"Spårgatan",-150:"Mackvägen",-55:"Depågatan",0:"Torggatan",48:"Parkgatan",102:"Kajhusgatan",162:"Strandgatan"}

func _street_name(point: Vector2, horizontal: bool) -> String:
	var names := AVENUE_NAMES if horizontal else CROSS_STREET_NAMES
	var axis := point.y if horizontal else point.x
	var nearest: int = names.keys()[0]
	for coordinate: int in names:
		if absf(axis-coordinate) < absf(axis-nearest): nearest = coordinate
	if horizontal and nearest in [-48,0] and point.x >= 87: return "Östra allén"
	if horizontal and nearest == 0 and point.x >= 50: return "Kajgatan"
	if not horizontal and nearest == 0 and point.y > 24: return "Torgets förlängning"
	return names[nearest]

# Read the straight approaches on either side of the sampled junction curves.
func turn_preview(points: PackedVector2Array, heading: Vector2, show_street := false) -> String:
	var incoming := heading.normalized()
	var distance := 0.0
	var turns := PackedStringArray()
	var first_distance := 0.0
	var first_street := ""
	for i in range(1, points.size()):
		var segment := points[i] - points[i-1]
		var length := segment.length()
		if distance > 75: break
		if length >= 3 and minf(absf(segment.x),absf(segment.y)) < .02:
			var outgoing := segment / length
			var angle := incoming.angle_to(outgoing)
			if absf(angle) > PI*.32:
				if turns.is_empty():
					first_distance = distance
					if show_street:
						first_street = _street_name((points[i]+points[i-1])*.5,absf(outgoing.x)>.5)
				turns.append("↶" if absf(angle) > PI*.78 else ("↱" if angle > 0 else "↰"))
				if turns.size() == 2: break
			incoming = outgoing
		distance += length
	if turns.is_empty() or first_distance > 35: return ""
	if show_street: return turns[0]+"  "+first_street
	if turns.size() == 1:
		turns.insert(0, "↑")
	return "   ›   ".join(turns)
