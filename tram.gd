extends Node3D

const STATION_NAMES := ["Sjöstads kaj", "Kanalparken", "Brotorget"]

var track := Curve3D.new()
var sections: Array[Node3D] = []
var platform_door_leaves: Array[Node3D] = []
var next_stop_display: Label3D
var stops: Array[float] = []
var next_stop := 1
var distance := 0.0
var velocity := 0.0
var dwell := 6.0

func beam(a: Vector3, b: Vector3, width: float, height: float, color: Color, mount: Node3D = self) -> void:
	var piece = get_parent()._make_box("Track", Vector3(width,height,a.distance_to(b)+.015), (a+b)/2, color,false,mount)
	piece.look_at(mount.to_global(b))

func sign_at(parent: Node3D, words: String, at: Vector3, angle: float, scale_factor: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.rotation.y = angle
	label.pixel_size = scale_factor
	label.font_size = 42
	label.outline_size = 4
	parent.add_child(label)
	return label

func _ready() -> void:
	var world := get_parent()
	for i in 97:
		var a := TAU*i/96
		track.add_point(Vector3(71+11*cos(a),5,-24+41*sin(a)))
	var length := track.get_baked_length()
	for i in 120:
		var a := track.sample_baked(length*i/120)
		var b := track.sample_baked(length*(i+1)/120)
		var side := (b-a).normalized().cross(Vector3.UP)
		beam(a-Vector3.UP*.25,b-Vector3.UP*.25,3.4,.46,Color("#888983"))
		for s in [-1,1]:
			beam(a+side*.72*s,b+side*.72*s,.07,.12,Color("#939c9c"))
		beam(a+Vector3.UP*4.2,b+Vector3.UP*4.2,.028,.032,Color("#60594e"))
		if i%8==0:
			var pole := a+side*1.95
			world._make_box("Overhead mast",Vector3(.14,4.7,.14),pole+Vector3.UP*2.12,Color("#758083"),false,self)
			beam(pole+Vector3.UP*4.42,a+Vector3.UP*4.42,.075,.075,Color("#717c7d"))
			world._make_box("Wire suspension",Vector3(.045,.23,.045),a+Vector3.UP*4.31,Color("#554f46"),false,self)
		if i%10==0 and absf(a.z)>6 and absf(a.z+48)>6:
			world._make_box("Viaduct pier",Vector3(1.1,6.3,1.4),a-Vector3.UP*3.45,Color("#a9aaa5"),false,self)
	for i in 3:
		var offset := length*i/3
		stops.append(offset)
		var station := Node3D.new()
		add_child(station)
		station.position = track.sample_baked(offset)
		station.look_at(track.sample_baked(offset+.2))
		world._make_box("Platform",Vector3(2.6,.55,8),Vector3(2.8,.05,0),Color("#c4bbaa"),false,station)
		world._make_box("Shelter roof",Vector3(2.1,.12,5.2),Vector3(3,2.7,0),Color("#475963"),false,station)
		for z in [-2,2]:
			world._make_box("Shelter post",Vector3(.1,2.4,.1),Vector3(3.8,1.5,z),Color("#697778"),false,station)
		world._make_box("Platform edge marking",Vector3(.14,.012,7.9),Vector3(1.69,.332,0),Color("#f3da85"),false,station)
		world._make_box("Bench seat",Vector3(.43,.085,2.5),Vector3(3.53,.80,0),Color("#a87547"),false,station)
		world._make_box("Bench back",Vector3(.07,.29,2.5),Vector3(3.72,1.06,0),Color("#a87547"),false,station)
		for z in [-.9,.9]:
			world._make_box("Bench leg",Vector3(.25,.44,.08),Vector3(3.53,.55,z),Color("#49565c"),false,station)
		world._make_box("Station name board",Vector3(.08,.43,3.8),Vector3(2.15,2.45,0),Color("#16496a"),false,station)
		for side in [-1,1]:
			sign_at(station,STATION_NAMES[i],Vector3(2.15+side*.045,2.45,0),side*PI/2,.0068)
	for i in 3:
		var car := Node3D.new()
		add_child(car)
		sections.append(car)
		# Leave a vestibule between the two saloon modules.
		for span in [Vector2(-2.325,-.39),Vector2(.65,2.325)]:
			var depth: float = span.y-span.x
			var middle: float = (span.x+span.y)*.5
			world._make_box("Lower sill",Vector3(2.38,.86,depth),Vector3(0,.76,middle),Color("#b8c7cd"),false,car)
			world._make_box("Panoramic glazing",Vector3(2.32,1.18,depth),Vector3(0,1.76,middle),Color("#172e39"),false,car)
		world._make_box("Vestibule floor",Vector3(2.38,.10,1.05),Vector3(0,.36,.13),Color("#676c70"),false,car)
		world._make_box("Roof fascia",Vector3(2.38,.38,4.65),Vector3(0,2.49,0),Color("#e2e4e1"),false,car)
		for s in [-1,1]:
			for z in [-.82,.82]:
				world._make_box("Window mullion",Vector3(.06,1.18,.09),Vector3(s*1.16,1.76,z),Color("#43515a"),false,car)
			for opening_direction in [-1,1]:
				var leaf := Node3D.new()
				car.add_child(leaf)
				leaf.position = Vector3(s*1.21,1.49,.13+opening_direction*.26)
				world._make_box("Door panel",Vector3(.08,2.22,.51),Vector3.ZERO,Color("#147db0"),false,leaf)
				world._make_box("Door glazing",Vector3(.02,1.10,.38),Vector3(s*.048,.26,0),Color("#213744"),false,leaf)
				if i==0 and s==1:
					platform_door_leaves.append(leaf)
		if i==1:
			var steel := Color("#384448")
			world._make_box("Pantograph base",Vector3(1.05,.18,1.26),Vector3(0,2.78,.25),steel,false,car)
			for side in [-1,1]:
				var heel := Vector3(side*.33,2.87,.67)
				var elbow := Vector3(side*.28,3.53,-.54)
				var crown := Vector3(side*.39,4.13,0)
				beam(heel,elbow,.065,.083,steel,car)
				beam(elbow,crown,.048,.065,steel,car)
			world._make_box("Contact shoe",Vector3(1.22,.065,.13),Vector3(0,4.16,0),steel,false,car)
		if i==0:
			car.add_child(preload("res://vehicles/tram_cab.glb").instantiate())
			sign_at(car,"Sjöstaden",Vector3(0,2.32,-2.528),PI,.0036)
			world._make_box("Next stop display",Vector3(.04,.32,1.74),Vector3(1.20,2.48,-1.32),Color("#192426"),false,car)
			next_stop_display = sign_at(car,STATION_NAMES[next_stop],Vector3(1.23,2.48,-1.32),PI/2,.0044)
			next_stop_display.modulate = Color("#ffbd58")
			next_stop_display.outline_size = 0
			world._make_box("Door notice",Vector3(.035,.32,1.4),Vector3(1.21,1.04,1.46),Color("#174460"),false,car)
			sign_at(car,"Vi åker inte till Ekerö",Vector3(1.24,1.04,1.46),PI/2,.003)
	place_sections()

func distance_to_next_stop() -> float:
	return fposmod(stops[next_stop]-distance,track.get_baked_length())

func advance(delta: float, manual: bool, gas: bool, brake: bool) -> void:
	if dwell>0:
		dwell=maxf(0,dwell-delta)
		var opening := smoothstep(0,.85,minf(6-dwell,dwell))
		for i in platform_door_leaves.size():
			var direction := -1 if i==0 else 1
			platform_door_leaves[i].position.z = .13+direction*(.26+.51*opening)
		return
	var length := track.get_baked_length()
	var remaining := distance_to_next_stop()
	var target := 7.0
	if manual:
		target = 0 if brake else (7 if gas else velocity)
	velocity = move_toward(velocity,minf(target,sqrt(3.6*remaining)),delta*(3 if brake else 1.8))
	var step := velocity*delta
	if remaining<=step+.015:
		distance=stops[next_stop]
		next_stop=(next_stop+1)%stops.size()
		next_stop_display.text = STATION_NAMES[next_stop]
		velocity=0
		dwell=6
	else:
		distance=fposmod(distance+step,length)
	place_sections()

func place_sections() -> void:
	var length := track.get_baked_length()
	for i in sections.size():
		var p := fposmod(distance-4.83*i,length)
		sections[i].position=track.sample_baked(p)
		sections[i].look_at(track.sample_baked(fposmod(p+.2,length)))
