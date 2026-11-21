extends Node3D

const SHOPS := ["Café", "Kiosk", "Pizzeria", "Sweet shop"]
const MENUS := [["Cinnamon bun","Berry cordial"],["Ice cream","Hot dog"],["Margherita pizza"],["Pick and mix"]]
const PRICES := [[3,2],[4,5],[8],[4]]
const SIGNS := ["KAFÉ BULLEN","SJÖKIOSKEN","PIZZERIA","GODISBODEN"]
const COLORS := ["#a86343","#427868","#b65f51","#927198"]
const FRONT_Z := 42.5
var awnings: Array[Node3D] = []
var inside := -1
var shop_card := PanelContainer.new()
var panel := VBoxContainer.new()
var receipt: Label
var basket: Label

func storefront_x(index: int) -> float:
	return -39.0+index*9.4

func part(label: String, pos: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
	var game=get_parent()
	var mesh: MeshInstance3D=game._make_box(label,size,pos,color,false,self)
	if solid: game.building_bounds.append(AABB(pos-size*.5,size))
	return mesh

func _ready() -> void:
	for i in SHOPS.size():
		var x:=storefront_x(i)
		var color:=Color(COLORS[i])
		var cream:=Color("#e9debf")
		part("Shop floor",Vector3(x,-.12,46),Vector3(8.4,.2,7),Color("#ad9274"))
		for side in [-1,1]:
			part("Party wall",Vector3(x+side*4.13,1.6,46),Vector3(.18,3.4,7),color,true)
			part("Shop window",Vector3(x+side*2.55,1.65,FRONT_Z),Vector3(3.2,2.65,.15),Color("#668b91"),true)
			part("Display sill",Vector3(x+side*2.55,.4,FRONT_Z-.09),Vector3(3.3,.65,.22),color)
			part("Window mullion",Vector3(x+side*2.55,1.68,FRONT_Z-.1),Vector3(.08,2.4,.08),cream)
		part("Rear wall",Vector3(x,1.6,49.45),Vector3(8.4,3.4,.18),color,true)
		var roof:=part("Roof",Vector3(x,3.48,46),Vector3(8.7,.28,7.6),Color("#515b5e"))
		awnings.append(roof)
		part("Shop fascia",Vector3(x,2.98,FRONT_Z-.22),Vector3(8.35,.80,.35),color)
		var sign_label:=Label3D.new()
		sign_label.text=SIGNS[i]
		sign_label.position=Vector3(x,3.0,FRONT_Z-.41)
		sign_label.rotation.y=PI
		sign_label.pixel_size=.009
		add_child(sign_label)
		part("Counter",Vector3(x, .48,47.8),Vector3(5.7,1,1),color,true)
		part("Worktop",Vector3(x,1.02,47.8),Vector3(5.9,.10,1.1),cream)
		for shelf in [1.55,2.18]:
			part("Display shelf",Vector3(x,shelf,49.1),Vector3(6,.09,.45),cream)
			for jar in 8:
				var tint:=Color.from_hsv(fmod(.08*i+.105*jar,1),.52,.86)
				part("Display tin",Vector3(x-2.5+.7*jar,shelf+.19,49.08),Vector3(.32,.3,.26),tint)

		if i == 0:
			_display_cinnamon_buns(Vector3(x-1.3,1.09,47.55))

		elif i == 2:
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
	if index!=inside:
		if inside>=0: awnings[inside].show()
		inside=index
		if inside>=0:
			awnings[inside].hide()
			rebuild_menu()
	shop_card.visible=inside>=0 and active

func rebuild_menu() -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	var title:=Label.new()
	title.text=tr(SHOPS[inside])
	panel.add_child(title)
	for i in MENUS[inside].size():
		var button:=Button.new()
		button.custom_minimum_size.y=44
		button.text=tr("%s · %d coins") % [tr(MENUS[inside][i]),PRICES[inside][i]]
		button.pressed.connect(purchase.bind(inside,i))
		panel.add_child(button)
	receipt=Label.new()
	receipt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(receipt)
	basket = Label.new()
	basket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(basket)
	refresh_basket()

func refresh_basket() -> void:
	var lines := PackedStringArray()
	var purchases: Dictionary = get_parent().purchases
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
		var amount := tr("You need one more coin.") if missing==1 else tr("You need %d more coins.") % missing
		receipt.text=amount+" "+tr("Complete a mission to earn coins.")
		return
	var product:String=MENUS[shop][item]
	game.wallet-=cost
	game.purchases[product]=int(game.purchases.get(product,0))+1
	refresh_basket()
	game._save_preferences()
	game._refresh_ui()
	receipt.text=tr("Bought %s. Thank you!") % tr(product)
