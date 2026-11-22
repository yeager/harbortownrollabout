extends Node3D

const SHOPS := ["Café", "Kiosk", "Pizzeria", "Sweet shop","Grocery store"]
const MENUS := [["Cinnamon bun","Berry cordial"],["Ice cream","Hot dog"],["Margherita pizza"],["Pick and mix"],["Apple","Milk"]]
const PRICES := [[3,2],[4,5],[8],[4],[2,4]]
const SIGNS := ["KAFÉ BULLEN","SJÖKIOSKEN","PIZZERIA","GODISBODEN","SJÖSTADENS LIVS"]
const COLORS := ["#a86343","#427868","#b65f51","#927198","#355e4b"]
const FRONT_Z := 42.5
var awnings: Array[Node3D] = []
var shop_sign_font := SystemFont.new()
var inside := -1
var shop_card := PanelContainer.new()
var panel := VBoxContainer.new()
var first_product: Button
var till_sound := AudioStreamPlayer.new()
var receipt: Label
var snack_buttons := {}
var balance: Label
var basket: Label

func storefront_x(index: int) -> float:
	return -39.0+index*9.4

func part(label: String, pos: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var game=get_parent()
	var mesh: MeshInstance3D=game._make_box(label,size,pos,color,false,self)
	if solid: game.building_bounds.append(AABB(pos-size*.5,size))
	return mesh

func _ready() -> void:
	till_sound.stream = preload("res://audio/till.wav")
	till_sound.volume_db = -10
	add_child(till_sound)
	shop_sign_font.font_names = PackedStringArray(["DejaVu Sans", "Arial"])
	shop_sign_font.font_weight = 800
	var street_width := storefront_x(SHOPS.size()-1)-storefront_x(0)+8.7
	var street_center := .5*(storefront_x(0)+storefront_x(SHOPS.size()-1))
	var pavement := part("Shop pavement",Vector3(street_center,-.07,40.65),Vector3(street_width,.12,3.7),Color("#bcb3a6"))
	pavement.material_override = get_parent().sidewalk_finish
	for i in SHOPS.size():
		var x:=storefront_x(i)
		var color:=Color(COLORS[i])
		var cream:=Color("#e9debf")
		part("Shop floor",Vector3(x,-.12,46),Vector3(8.4,.2,7),Color("#eee6da") if i == 3 else Color("#ad9274"))
		for side in [-1,1]:
			part("Party wall",Vector3(x+side*4.13,1.6,46),Vector3(.18,3.4,7),color,true)
			var pane := part("Shop window",Vector3(x+side*2.55,1.65,FRONT_Z),Vector3(3.2,2.65,.15),Color("#668b91"),true)
			if i in [1,2,3,4]:
				var glass := pane.material_override as StandardMaterial3D
				glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				glass.albedo_color = Color(.65,.84,.84,.16)
				glass.roughness = .18
				pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			part("Display sill",Vector3(x+side*2.55,.4,FRONT_Z-.09),Vector3(3.3,.65,.22),color)
			part("Window mullion",Vector3(x+side*2.55,1.68,FRONT_Z-.1),Vector3(.08,2.4,.08),cream)
		part("Rear wall",Vector3(x,1.6,49.45),Vector3(8.4,3.4,.18),color,true)
		var roof:=part("Roof",Vector3(x,3.48,46),Vector3(8.7,.28,7.6),Color("#515b5e"))
		awnings.append(roof)
		if i not in [2,3]:
			part("Shop fascia",Vector3(x,2.98,FRONT_Z-.22),Vector3(8.35,.80,.35),color)
			_lettering(SIGNS[i],Vector3(x,3.0,FRONT_Z-.41),.009,Color.WHITE).outline_size = 48
		if i != 3:
			part("Counter",Vector3(x,.48,47.8),Vector3(5.7,1,1),color,true)
			part("Worktop",Vector3(x,1.02,47.8),Vector3(5.9,.10,1.1),cream)
		if i not in [2,3]:
			for shelf in [1.55,2.18]:
				part("Display shelf",Vector3(x,shelf,49.1),Vector3(6,.09,.45),cream)
				for jar in 8:
					var tint:=Color.from_hsv(fmod(.08*i+.105*jar,1),.52,.86)
					part("Display tin",Vector3(x-2.5+.7*jar,shelf+.19,49.08),Vector3(.32,.3,.26),tint)

		if i == 1:
			_kiosk(x)
		elif i == 3:
			_sweet_shop(x)
		elif i == 4:
			_grocery(x)
		elif i == 0:
			_display_cinnamon_buns(Vector3(x-1.3,1.09,47.55))

		elif i == 2:
			_pizzeria(x)
			_display_margherita(Vector3(x,1.09,47.65))

func _display_margherita(center: Vector3) -> void:
	part("Pizza board",center,Vector3(.91,.032,.88),Color("#b28658"))
	var crust := CylinderMesh.new()
	crust.top_radius=.39
	crust.bottom_radius=.38
	crust.height=.047
	crust.material=get_parent()._material(Color("#cc9554"),.87)
	var pizza := MeshInstance3D.new()
	pizza.name="Margherita"
	pizza.mesh=crust
	pizza.position=center+Vector3.UP*.04
	add_child(pizza)
	var sauce := CylinderMesh.new()
	sauce.top_radius=.35
	sauce.bottom_radius=.35
	sauce.height=.008
	sauce.material=get_parent()._material(Color("#aa4326"),.62)
	var tomato := MeshInstance3D.new()
	tomato.mesh=sauce
	tomato.position.y=.027
	pizza.add_child(tomato)
	var cheese := SphereMesh.new()
	cheese.radius=.077
	cheese.height=.023
	cheese.material=get_parent()._material(Color("#f2dfac"),.57)
	for i in 7:
		var topping := MeshInstance3D.new()
		topping.mesh=cheese
		var angle := i*2.4
		var radius := .105*sqrt(float(i))
		topping.position=Vector3(cos(angle)*radius,.034,sin(angle)*radius)
		topping.scale.x=1.2
		topping.rotation.y=angle
		pizza.add_child(topping)

func _display_cinnamon_buns(center: Vector3) -> void:
	part("Bakery tray",center,Vector3(1.35,.035,.76),Color("#605859"))
	var dough := SphereMesh.new()
	dough.radius=.155
	dough.height=.14
	dough.radial_segments=24
	dough.rings=10
	dough.material=get_parent()._material(Color("#c98040"),.78)
	var swirl := SurfaceTool.new()
	swirl.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	swirl.set_material(get_parent()._material(Color("#744023"),.86))
	for step in 49:
		var t := step/48.0
		var angle := t*TAU*2.25
		for edge in [-.007,.007]:
			var r := .014+.122*t+float(edge)
			var height := .07*sqrt(1.0-pow(r/.155,2))+.002
			swirl.set_normal(Vector3.UP)
			swirl.add_vertex(Vector3(r*cos(angle),height,r*sin(angle)))
	var filling := swirl.commit()
	for row in 2:
		for column in 3:
			var bun := MeshInstance3D.new()
			bun.mesh=dough
			bun.position=center+Vector3((column-1)*.39,.072,(row-.5)*.34)
			bun.rotation.y=(row*3+column)*1.17
			add_child(bun)
			var spiral := MeshInstance3D.new()
			spiral.mesh=filling
			bun.add_child(spiral)

func build_menu(ui: CanvasLayer) -> void:
	ui.add_child(shop_card)
	shop_card.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	shop_card.offset_left = -302
	shop_card.offset_right = -22
	shop_card.offset_top = 108
	shop_card.offset_bottom = -155
	var finish := StyleBoxFlat.new()
	finish.bg_color = Color("#20343bf5")
	finish.set_corner_radius_all(14)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		finish.set_content_margin(side,14)
	shop_card.add_theme_stylebox_override("panel",finish)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	shop_card.add_child(scroll)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	shop_card.hide()

func update_customer(foot: bool, pos: Vector3, active: bool) -> void:
	var index:=-1
	if foot:
		for i in SHOPS.size():
			if absf(pos.x-storefront_x(i))<4 and pos.z>FRONT_Z and pos.z<49.4:
				index=i
				break
	var entering := index!=inside or not shop_card.visible
	if index!=inside:
		if inside>=0: awnings[inside].show()
		inside=index
		if inside>=0:
			awnings[inside].hide()
			rebuild_menu()
	shop_card.visible=inside>=0 and active
	if entering and shop_card.visible:
		first_product.grab_focus()

func rebuild_menu() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var focus_index := focused.get_index() if focused and focused.get_parent() == panel else -1
	snack_buttons.clear()
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	var title:=Label.new()
	title.text=tr(SHOPS[inside])
	panel.add_child(title)
	balance = Label.new()
	panel.add_child(balance)
	var keyboard_hint := Label.new()
	keyboard_hint.text = "Tab to choose · Enter to buy" if MENUS[inside].size()>1 else "Enter to buy"
	if inside == 1:
		keyboard_hint.text = "Tab to choose · Enter to buy or eat"
	keyboard_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(keyboard_hint)
	for i in MENUS[inside].size():
		var button:=Button.new()
		button.custom_minimum_size.y=44
		button.text=tr("%s · %d coins") % [tr(MENUS[inside][i]),PRICES[inside][i]]
		button.pressed.connect(purchase.bind(inside,i))
		panel.add_child(button)
		if i==0: first_product=button
	receipt=Label.new()
	receipt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(receipt)
	basket = Label.new()
	basket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(basket)
	if inside == 1:
		for product: String in MENUS[1]:
			var eat := Button.new()
			eat.text = "Eat ice cream" if product == "Ice cream" else "Eat hot dog"
			eat.custom_minimum_size.y = 44
			eat.pressed.connect(eat_snack.bind(product))
			panel.add_child(eat)
			snack_buttons[product] = eat
	refresh_basket()
	if focus_index >= 0 and focus_index < panel.get_child_count():
		var replacement := panel.get_child(focus_index) as Button
		if replacement and replacement.is_visible_in_tree():
			replacement.grab_focus()

func eat_snack(product: String) -> void:
	var game = get_parent()
	if inside != 1 or not shop_card.is_visible_in_tree() or not game.walker.visible or game.paused: return
	if not product in MENUS[1] or int(game.purchases.get(product, 0)) <= 0: return
	var restore_focus: bool = snack_buttons[product].has_focus() and game.purchases[product] == 1
	game.purchases[product] -= 1
	game._save_preferences()
	game.happy_seconds = 25
	game._refresh_ui()
	receipt.text = tr("%s feels extra happy!") % ("Alma" if game.play_as_alma else "Axel")
	refresh_basket()
	if restore_focus:
		for eat: Button in snack_buttons.values():
			if eat.visible:
				eat.grab_focus()
				return
		first_product.grab_focus()

func refresh_basket() -> void:
	var coins: int = get_parent().wallet
	balance.text = tr("Wallet") + " · " + (tr_n("%d coin", "%d coins", coins) % coins)
	var lines := PackedStringArray()
	var purchases: Dictionary = get_parent().purchases
	for product in snack_buttons:
		snack_buttons[product].visible = int(purchases.get(product,0)) > 0
	for menu in MENUS:
		for product in menu:
			var count := int(purchases.get(product,0))
			if count > 0: lines.append(tr("%s × %d") % [tr(product),count])
	basket.text = tr("Your purchases") + "\n" + "\n".join(lines)
	basket.visible = not lines.is_empty()

func purchase(shop: int, item: int) -> void:
	var game=get_parent()
	if shop!=inside or not shop_card.is_visible_in_tree() or not game.walker.visible or game.paused: return
	var cost:int=PRICES[shop][item]
	if game.wallet<cost:
		var missing: int = cost-game.wallet
		var amount := tr_n("You need %d more coin.", "You need %d more coins.", missing) % missing
		receipt.text=amount+" "+tr("Complete a mission to earn coins.")
		return
	var product:String=MENUS[shop][item]
	game.wallet-=cost
	till_sound.play()
	game.purchases[product]=int(game.purchases.get(product,0))+1
	refresh_basket()
	game._save_preferences()
	game._refresh_ui()
	receipt.text=tr("%s · Paid %d coins. Thank you!") % [tr(product),cost]

func _lettering(words: String, pos: Vector3, pixel_size: float, color: Color) -> Label3D:
	var letters := Label3D.new()
	letters.text = words
	letters.font_size = 128
	letters.pixel_size = pixel_size*.25
	letters.modulate = color
	letters.outline_size = 0
	letters.position = pos
	letters.rotation.y = PI
	add_child(letters)
	return letters

func _turned(label_text: String, pos: Vector3, lower: float, upper: float, height: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = lower
	shape.top_radius = upper
	shape.height = height
	shape.radial_segments = 20
	shape.rings = 1
	var piece := MeshInstance3D.new()
	piece.name = label_text
	piece.mesh = shape
	piece.material_override = get_parent()._material(color)
	piece.position = pos
	add_child(piece)
	return piece

func _kiosk(x: float) -> void:
	var ivory := Color("#fff1d9")
	var red := Color("#b84138")
	for i in 15:
		var stripe := red if i % 2 == 0 else ivory
		var canopy := part("Canvas stripe",Vector3(x+(i-7)*.52,2.57,41.96),Vector3(.521,.075,1.20),stripe)
		canopy.rotation.x = -.16
		part("Awning hem",Vector3(canopy.position.x,2.39,41.39),Vector3(.52,.17,.065),stripe)
	part("Hatch ledge",Vector3(x-2.52,1.06,42.16),Vector3(3.18,.12,.62),ivory)
	part("Enamel menu frame",Vector3(x+2.8,1.66,42.34),Vector3(1.78,1.24,.12),ivory)
	part("Menu board",Vector3(x+2.8,1.66,42.26),Vector3(1.65,1.12,.06),Color("#244338"))
	_lettering("ICE CREAM  4\nHOT DOG  5",Vector3(x+2.8,1.68,42.21),.0044,ivory)
	_turned("Wafer cone sign",Vector3(x-3.38,3.51,42.31),.035,.29,.74,Color("#cb914f"))
	var scoop := SphereMesh.new()
	scoop.radius = .32
	scoop.height = .52
	var top := MeshInstance3D.new()
	top.name = "Strawberry scoop"
	top.position = Vector3(x-3.38,3.95,42.31)
	top.mesh = scoop
	top.material_override = get_parent()._material(Color("#ec9db1"))
	add_child(top)

func _pizzeria(x: float) -> void:
	_pizzeria_front(x)
	var walnut := Color("#704c3c")
	var leather := Color("#bd663c")
	var marble := Color("#ede5d5")
	part("Banquette base",Vector3(x-3.57,.28,44.95),Vector3(.78,.56,3.65),walnut,true)
	part("Banquette seat",Vector3(x-3.54,.56,44.95),Vector3(.83,.18,3.65),leather)
	part("Banquette back",Vector3(x-3.90,.94,44.95),Vector3(.15,.78,3.65),leather)
	for z in [44.0,45.85]:
		_turned("Pedestal foot",Vector3(x-2.65,.07,z),.31,.25,.12,walnut)
		_turned("Pedestal",Vector3(x-2.65,.42,z),.09,.09,.67,walnut)
		part("Marble tabletop",Vector3(x-2.65,.83,z),Vector3(1.08,.10,1.02),marble,true)
		part("Pendant flex",Vector3(x-2.65,2.94,z),Vector3(.025,.65,.025),walnut)
		_turned("Brass pendant",Vector3(x-2.65,2.56,z),.25,.08,.22,Color("#b38b55"))
	for side in [-1,1]:
		var frame_x: float = x+side*2.55
		for edge in [-1,1]:
			part("Walnut jamb",Vector3(frame_x+edge*1.56,1.55,42.38),Vector3(.11,2.20,.16),walnut)
	part("Kitchen tile back",Vector3(x,.98,49.31),Vector3(7.95,1.94,.055),Color("#d3c9ae"))
	for row in 4:
		part("Tile joint",Vector3(x,.48+row*.38,49.27),Vector3(7.83,.018,.025),Color("#9e9a89"))
	var hatch := part("Pizza pass",Vector3(x-1.45,1.48,48.68),Vector3(2.75,.10,.48),walnut)
	for side in [-1,1]:
		part("Pass support",hatch.position+Vector3(side*1.23,-.22,0),Vector3(.065,.45,.065),walnut)
	var arch := _turned("Oven brick arch",Vector3(x+1.85,1.48,48.30),.78,.78,.66,Color("#a6553b"))
	arch.rotation.x = PI/2
	var opening := _turned("Oven opening",Vector3(x+1.85,1.44,47.95),.50,.50,.06,Color("#302724"))
	opening.rotation.x = PI/2
	part("Oven hearth",Vector3(x+1.85,1.23,47.91),Vector3(1.6,.15,.78),walnut)

func _grocery(x: float) -> void:
	var wood := Color("#a67647")
	var dark := Color("#2d4d3c")
	var ivory := Color("#f3e8c8")
	part("Market canopy",Vector3(x,2.57,42.03),Vector3(8.3,.17,1.02),dark)
	_lettering("FRUIT  &  VEG",Vector3(x-2.5,1.95,42.36),.0045,ivory)
	var fruit := SphereMesh.new()
	fruit.radius = .11
	fruit.height = .19
	fruit.radial_segments = 12
	fruit.rings = 5
	for crate in 3:
		var cx := x-3.5+crate*.94
		part("Produce crate",Vector3(cx,.65,41.97),Vector3(.88,.31,.69),wood,true)
		part("Crate rim",Vector3(cx,.80,41.60),Vector3(.90,.11,.055),wood)
		part("Crate pedestal",Vector3(cx,.24,41.97),Vector3(.72,.49,.55),dark)
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = fruit
		batch.instance_count = 12
		for n in 12:
			var offset := Vector3((n%4-1.5)*.193,.025*sin(n*1.7),(floori(n/4.0)-1)*.18)
			batch.set_instance_transform(n,Transform3D(Basis.IDENTITY,Vector3(cx,.84,41.98)+offset))
		var produce := MultiMeshInstance3D.new()
		produce.name = "Market fruit"
		produce.multimesh = batch
		produce.material_override = get_parent()._material([Color("#a54035"),Color("#95ac55"),Color("#df8a34")][crate])
		add_child(produce)
	part("Checkout screen",Vector3(x+1.8,1.35,47.72),Vector3(.56,.38,.11),dark)
	_lettering("CHECKOUT",Vector3(x+1.8,2.55,49.20),.0058,ivory)
	for carton in 5:
		var cx := x-2.2+carton*.29
		part("Milk carton",Vector3(cx,1.29,47.69),Vector3(.20,.42,.19),ivory)
		part("Carton label",Vector3(cx,1.26,47.58),Vector3(.18,.12,.025),Color("#679fc3"))

func _pizzeria_front(x: float) -> void:
	var wine := Color("#951d20")
	var gold := Color("#ffdb72")
	var timber := Color("#54372c")
	var mortar := Color("#a89076")
	var brick_positions: Array[Transform3D] = []
	var brick_tints := PackedColorArray()
	for side in [-1,1]:
		# A running bond wraps the deep window sills and both outer piers.
		for strip in [Vector3(side*2.52,.68,3.22),Vector3(side*3.91,2.75,.49)]:
			part("Mortar bed",Vector3(x+strip.x,strip.y*.5,42.30),Vector3(strip.z,strip.y,.22),mortar)
			var rows := roundi(strip.y/.135)
			for row in rows:
				var low: float = x+strip.x-strip.z*.5
				var high: float = low+strip.z
				var cursor := low-.14*(row%2)
				while cursor < high:
					var left := maxf(low,cursor)
					var right := minf(high,cursor+.285)
					if right-left > .025:
						var at := Vector3((left+right)*.5,(row+.5)*strip.y/rows,42.173)
						var scale_to := Vector3(right-left-.014,strip.y/rows-.012,.066)
						brick_positions.append(Transform3D(Basis.from_scale(scale_to),at))
						var tone := posmod(brick_positions.size()*13+row*7,5)
						brick_tints.append([Color("#9f553a"),Color("#b76f4d"),Color("#ac6142"),Color("#a36c50"),Color("#94583a")][tone])
					cursor += .285
	_stamp_meshes("Running bond brickwork",BoxMesh.new(),brick_positions,brick_tints)
	part("Enamel fascia surround",Vector3(x,3.06,42.19),Vector3(8.47,.90,.30),timber)
	var lit_sign := part("Pizzeria illuminated sign",Vector3(x,3.07,42.02),Vector3(8.31,.76,.09),gold)
	lit_sign.material_override = get_parent()._material(gold,.38,true)
	for h in [2.75,3.39]:
		part("Vermilion enamel pinstripe",Vector3(x,h,41.967),Vector3(8.16,.037,.014),wine)
	var nameplate := _lettering("SJÖSTADENS  PIZZERIA",Vector3(x,3.07,41.951),.0175,wine)
	nameplate.font = shop_sign_font
	# A two-sided blade sign is readable along the pavement in either direction.
	var blade_x := x + 3.94
	part("Projecting sign bracket",Vector3(blade_x,3.30,41.77),Vector3(.07,.07,1.09),timber)
	part("Projecting enamel sign",Vector3(blade_x,2.98,41.63),Vector3(.10,.58,1.02),wine)
	for facing in [-1,1]:
		var blade := _lettering("PIZZA",Vector3(blade_x+facing*.056,2.98,41.63),.0087,gold)
		blade.rotation.y = facing*PI*.5
		blade.font = shop_sign_font
	for side in [-1,1]:
		var cx:float = x+side*2.52
		var canopy := part("Wine canvas canopy",Vector3(cx,2.60,41.94),Vector3(3.41,.075,1.17),wine)
		canopy.rotation.x = -.22
		part("Scalloped valance rail",Vector3(cx,2.40,41.375),Vector3(3.43,.18,.07),wine)
		part("Gold awning welt",Vector3(cx,2.325,41.333),Vector3(3.43,.022,.018),gold)
		for edge in [-1,1]:
			var bracket := part("Awning brace",Vector3(cx+edge*1.49,2.38,41.98),Vector3(.035,.035,1.0),timber)
			bracket.rotation.x = .23
		var window_text := "PIZZERIA" if side == 1 else "WOOD-FIRED PIZZA"
		var script := _lettering(window_text,Vector3(cx,1.68,42.35),.0081,Color("#fff1ce"))
		script.font = shop_sign_font
		part("Window menu strip",Vector3(cx,1.04,42.32),Vector3(2.97,.22,.027),wine)
		var menu_text := "MARGHERITA  ·  8 COINS" if side == 1 else "EAT IN  ·  TAKEAWAY"
		_lettering(menu_text,Vector3(cx,1.04,42.29),.0048,Color("#fff3d5"))
	for edge in [-1,1]:
		part("Recessed door jamb",Vector3(x+edge*.90,1.30,42.53),Vector3(.087,2.60,.22),timber)
	part("Door lintel",Vector3(x,2.57,42.53),Vector3(1.88,.12,.22),timber)
	_open_glass_door(x,timber)
	part("Woven entrance mat",Vector3(x,-.004,42.88),Vector3(1.40,.03,.88),Color("#514c47"))
	# Menus are behind the counter and can be read from the dining room.
	part("Backlit menu case",Vector3(x,2.60,49.27),Vector3(6.70,.59,.11),timber)
	for i in 3:
		var cx := x+(i-1)*2.17
		part("Kitchen menu card",Vector3(cx,2.61,49.20),Vector3(2.10,.49,.04),Color("#f1db9e"))
		_lettering(["PIZZA", "MARGHERITA   8", "TAKEAWAY"][i],Vector3(cx,2.61,49.17),.0058,wine)
	_shop_light(Vector3(x,2.8,46.0),Color("#ffddab"),1.15)

func _sweet_shop(x: float) -> void:
	var frame := Color("#28282c")
	var pearl := Color("#fff4df")
	var palette := [Color("#ff78a6"),Color("#ffd25b"),Color("#64dfd0"),Color("#fc8a47"),Color("#b4a6fc")]
	var sign_box := part("Ebony candy fascia",Vector3(x,3.04,42.12),Vector3(8.5,.91,.30),frame)
	for y in [2.64,3.44]:
		part("Fascia rolled rim",Vector3(x,y,41.95),Vector3(8.45,.041,.035),Color("#4b4951"))
	var nameplate := "GODISBODEN"
	for i in nameplate.length():
		var cx := x+(.5*(nameplate.length()-1)-i)*.55
		var letter := _lettering(nameplate[i],Vector3(cx,3.04+.028*sin(i*1.65),sign_box.position.z-.18),.0255,palette[i%palette.size()])
		letter.font = shop_sign_font
		letter.rotation.z = sin(i*2.0)*.045
	# Two wrapped boiled sweets at opposite ends complete the shop's sign.
	for side in [-1,1]:
		var cx:float=x+side*3.56
		var candy := _turned("Wrapped sweet medallion",Vector3(cx,3.04,41.91),.155,.155,.043,palette[0])
		candy.rotation.x = PI*.5
		for edge in [-1,1]:
			var twist := _turned("Sweet wrapper",Vector3(cx+edge*.17,3.04,41.91),.11,.03,.13,palette[1])
			twist.rotation.z = edge*PI*.5
		part("Dark display plinth",Vector3(x+side*2.54,.30,42.34),Vector3(3.22,.60,.23),frame)
		for edge in [-1,1]:
			part("Bronze shopfront frame",Vector3(x+side*2.54+edge*1.57,1.49,42.37),Vector3(.07,2.45,.15),frame)
		part("Window top rail",Vector3(x+side*2.54,2.67,42.36),Vector3(3.20,.085,.14),frame)
	part("Rear display lining",Vector3(x,1.62,49.31),Vector3(8.03,3.22,.09),pearl)
	for side in [-1,1]:
		part("Cream shop lining",Vector3(x+side*4.01,1.6,46),Vector3(.07,3.20,6.87),pearl)
		part("Door surround",Vector3(x+side*.90,1.33,42.48),Vector3(.08,2.66,.17),frame)
	part("Door transom",Vector3(x,2.62,42.48),Vector3(1.85,.09,.17),frame)
	_open_glass_door(x,frame)
	var shapes: Array[Array] = [[],[],[]]
	var colors: Array[PackedColorArray] = [PackedColorArray(),PackedColorArray(),PackedColorArray()]
	# Shallow displays fill each shop window and flank a clear central aisle.
	for side in [-1,1]:
		_candy_bank(Vector3(x+side*2.54,0,43.48),4,2,shapes,colors)
	_candy_bank(Vector3(x-.83,0,47.40),8,3,shapes,colors)
	var bonbon := SphereMesh.new()
	bonbon.radial_segments=10
	bonbon.rings=5
	var ring := TorusMesh.new()
	ring.inner_radius=.24
	ring.outer_radius=.5
	ring.rings=12
	ring.ring_segments=7
	var gumdrop := CylinderMesh.new()
	gumdrop.bottom_radius=.48
	gumdrop.top_radius=.30
	gumdrop.height=.60
	gumdrop.radial_segments=8
	gumdrop.rings=1
	for i in 3:
		_stamp_meshes(["Fruit bonbons","Sour rings","Gumdrops"][i],[bonbon,ring,gumdrop][i],shapes[i],colors[i])
	_lettering("PICK AND MIX",Vector3(x-.85,2.63,49.24),.0155,Color("#b44364")).font = shop_sign_font
	part("Candy till counter",Vector3(x+2.94,.47,47.98),Vector3(1.67,.95,.95),Color("#e7adbf"),true)
	part("Till worktop",Vector3(x+2.94,.99,47.98),Vector3(1.74,.10,1.03),pearl)
	part("Cash register",Vector3(x+3.03,1.12,47.91),Vector3(.43,.19,.34),frame)
	part("Bag dispenser",Vector3(x+2.44,1.24,47.93),Vector3(.24,.38,.20),Color("#bd936f"))
	for side in [-1,1]:
		var bar := part("Ceiling light",Vector3(x+side*2.15,3.17,46.17),Vector3(.14,.07,4.83),pearl)
		bar.material_override = get_parent()._material(Color("#fff8dd"),.32,true)
		_shop_light(Vector3(x+side*2.15,2.58,45.79),Color("#fff3e1"),1.5)

func _candy_bank(origin: Vector3, columns: int, tiers: int, shapes: Array[Array], colors: Array[PackedColorArray]) -> void:
	var white := Color("#f3efe4")
	var charcoal := Color("#43474a")
	var pitch := .70
	var width := columns*pitch
	var depth := tiers*.39+.18
	part("Pick and mix cabinet",origin+Vector3(0,.28,depth*.45),Vector3(width+.09,.56,depth),white,true)
	for tier in tiers:
		var z := origin.z+tier*.39
		var height := .57+tier*.39
		part("Stepped display tray",Vector3(origin.x,height-.055,z+.10),Vector3(width,.14,.49),white)
		var strip := part("Under-shelf LED",Vector3(origin.x,height-.045,z-.158),Vector3(width-.04,.025,.013),white)
		strip.material_override = get_parent()._material(Color("#fff7d6"),.30,true)
		var lip := part("Clear bin front",Vector3(origin.x,height+.104,z-.121),Vector3(width,.215,.027),Color.WHITE)
		var acrylic := lip.material_override as StandardMaterial3D
		acrylic.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		acrylic.albedo_color = Color(.78,.92,.96,.18)
		acrylic.roughness = .15
		lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part("Clear acrylic top edge",Vector3(origin.x,height+.21,z-.122),Vector3(width,.014,.021),Color("#d6e6e0"))
		for k in columns+1:
			part("Bin divider",Vector3(origin.x+(k-.5*columns)*pitch,height+.12,z+.095),Vector3(.026,.25,.44),white)
		for column in columns:
			var cx := origin.x+(column-.5*(columns-1))*pitch
			var flavour := posmod(column+3*tier+roundi(origin.x),8)
			var tint:Color=[Color("#f5506d"),Color("#f4b53e"),Color("#79cfa2"),Color("#44343d"),Color("#f6e4c3"),Color("#f48998"),Color("#e58640"),Color("#a773ac")][flavour]
			var style := flavour%3
			# A base layer and a smaller mound sit behind the clear scooping lip.
			for i in 44:
				var stacked := i >= 28
				var across := 6 if stacked else 7
				var k := i-28 if stacked else i
				var phase := i*12.9+column*3.1+tier
				var dx := (k%across-(across-1)*.5)*.084+.029*sin(phase*2.37)
				var dz: float = (floori(float(k)/across)-(1 if stacked else 1.5))*.086+.029*cos(phase*1.83)
				# The upper layer settles toward the centre of each compartment.
				if stacked:
					dx *= .87
					dz *= .88
				var crown := .037 * maxf(0.0, 1.0 - absf(dx)/.26 - absf(dz)/.18) if stacked else 0.0
				var pos := Vector3(cx+dx,height+(.154 if stacked else .085)+crown+.019*sin(phase*.7),z+.11+dz)
				var size := Vector3(.106,.092,.109) if style != 1 else Vector3(.109,.087,.109)
				size *= 1.0 + .10*sin(phase*1.41)
				var orientation := Basis.from_euler(Vector3(.66*sin(phase),phase,.58*cos(phase)))
				shapes[style].append(Transform3D(orientation*Basis.from_scale(size),pos))
				colors[style].append(tint.lightened(.14 if i%4==0 else 0.0))
			part("Flavour ticket",Vector3(cx,height-.032,z-.166),Vector3(.23,.054,.012),charcoal)
			var flavours := ["Raspberry","Lemon","Apple","Liquorice","Vanilla","Strawberry","Orange","Grape"]
			var ticket := _lettering(flavours[flavour],Vector3(cx,height-.032,z-.174),.00135,Color.WHITE)
			ticket.visibility_range_end = 5.0

func _stamp_meshes(label_text: String, mesh: Mesh, poses: Array, colors: PackedColorArray) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = mesh
	batch.instance_count = poses.size()
	for i in poses.size():
		batch.set_instance_transform(i,poses[i])
		batch.set_instance_color(i,colors[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = label_text
	instance.multimesh = batch
	var finish := StandardMaterial3D.new()
	finish.vertex_color_use_as_albedo = true
	finish.vertex_color_is_srgb = true
	finish.roughness = .70
	instance.material_override = finish
	add_child(instance)

func _shop_light(pos: Vector3, hue: Color, power: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = hue
	light.light_energy = power
	light.omni_range = 5.5
	light.distance_fade_enabled = true
	light.distance_fade_begin = 18
	light.distance_fade_length = 10
	add_child(light)

func _open_glass_door(x: float, trim: Color) -> void:
	# The leaf is held open along the inside jamb, leaving the aisle unobstructed.
	var center := Vector3(x+.85,1.24,43.12)
	var pane := part("Open shop door",center,Vector3(.044,2.40,1.20),Color.WHITE)
	var glazing := pane.material_override as StandardMaterial3D
	glazing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glazing.albedo_color = Color(.71,.87,.90,.17)
	glazing.roughness = .15
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for edge in [-1,1]:
		part("Door stile",center+Vector3(0,0,edge*.58),Vector3(.060,2.40,.052),trim)
		part("Door rail",center+Vector3(0,edge*1.17,0),Vector3(.060,.066,1.21),trim)
	part("Pull handle",center+Vector3(-.081,-.16,.38),Vector3(.035,.37,.035),Color("#c5c2b9"))
