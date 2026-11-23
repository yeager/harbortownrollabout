extends Node3D

const SHOPS := ["Café", "Kiosk", "Pizzeria", "Sweet shop","Grocery store","Momo & Bori","Hot dog stand"]
const SWEETS := [
	"Pick and mix",
	"Frog choir",
	"Sour shoelaces",
	"Rocket fudge",
	"Cloud cone",
	"Penguin pop",
	"Lunar sundae",
	"Dill disco popcorn",
	"Dragon curls",
	"Chocolate puddles",
]
const SWEET_INGREDIENTS := [
	"Gummy boots and raspberry raindrops",
	"Pear jelly frogs with fizzy lime dust",
	"Apple laces with lemon sugar",
	"Caramel with popping strawberry sparks",
	"Vanilla ice cream with cotton candy clouds",
	"Licorice ice cream with a mango beak",
	"Blueberry ice cream with biscuit craters",
	"Popcorn with dill and crunchy cheese stars",
	"Corn twists with sweet paprika scales",
	"Chocolate buttons with crispy rice bubbles",
]
const MENUS := [["Cinnamon bun","Berry cordial"],["Ice cream","Hot dog"],["Margherita pizza", "Popcorn Party", "Pickle Carousel", "Banana Moon", "Berry Blizzard"],SWEETS,["Apple","Milk"],["Japanese haori jacket","Korean jeogori jacket","Red panda plush","Moon rabbit figurine"],["Hot dog","Moon mash dog","Pickle rocket","Crunchy onion comet"]]
const SNACK_SHOPS := [1, 2, 3, 6]
const PRODUCT_ICONS := {
	0: preload("res://branding/cafe-products.svg"),
	4: preload("res://branding/grocery-products.svg"),
	6: preload("res://branding/grill-products.svg"),
	2: preload("res://branding/pizza-products.png"),
	3: preload("res://branding/sweet-products.png"),
	5: preload("res://branding/boutique-products.png"),
}
const PRICES := [[3,2],[4,5],[8,7,8,9,10],[4,3,2,4,5,4,6,3,3,4],[2,4],[9,9,5,4],[5,7,6,8]]
const GRILL_TOPPINGS := ["Grilled sausage in a soft bun", "Sausage with a moon of mash and pea craters", "Pickle fins and a carrot nose cone", "Crispy onion tail and a mustard star"]
const PIZZA_TOPPINGS := ["Mozzarella, tomato and carrot stars", "Popcorn, sweetcorn and cheese", "Pickle wheels and crispy onions", "Banana moons and coconut snow", "Blueberries, vanilla cream and raspberry swirls"]
const SIGNS := ["CINNAMON BUN CAFÉ","HARBOR KIOSK","PIZZERIA","GODISBODEN","HARBOR GROCER","MOMO & BORI"]
const COLORS := ["#a86343","#427868","#b65f51","#927198","#355e4b","#375c68"]
const FRONT_Z := 42.5
var grill_neon_finishes: Array[StandardMaterial3D] = []
var grill_neon_light: OmniLight3D
var grill_neon_phase := 0.0
var grill_neon_lit := true
var candy_letters: Array[Label3D] = []
var serving_arm: Node3D
var serving_dish := Sprite3D.new()
var serving_motion: Tween
var kiosk_menu_signs: Array[Label3D] = []
var grill_price_signs: Array[Label3D] = []
var order_recipe := 0
var order_slip := Sprite3D.new()
var order_picture: TextureRect
var pizza_price_signs: Array[Label3D] = []
var awnings: Array[Node3D] = []
var shop_sign_font := SystemFont.new()
var carried_toy := ""
var toy_in_hand: Node3D
var inside := -1
var shop_card := PanelContainer.new()
var panel := VBoxContainer.new()
var first_product: Button
var till_sound := AudioStreamPlayer.new()
enum ReceiptKind { NONE, PURCHASE, SHORTFALL, SNACK, ORDER_MATCH }
var receipt_kind := ReceiptKind.NONE
var receipt_subject := ""
var receipt_amount := 0
var receipt: Label
var snack_buttons := {}
var balance: Label
var basket: RichTextLabel

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
	var pavement: MeshInstance3D = get_parent()._make_driving_surface("Shop pavement",Vector3(street_width,.12,3.7),Vector3(street_center,-.07,40.65),Color("#bcb3a6"),false,self)
	pavement.material_override = get_parent().sidewalk_finish
	for i in SHOPS.size():
		var x:=storefront_x(i)
		if i == 6:
			_hot_dog_stand(x)
			continue
		var color:=Color(COLORS[i])
		var cream:=Color("#e9debf")
		get_parent()._make_driving_surface("Shop floor",Vector3(8.4,.2,7),Vector3(x,-.12,46),Color("#eee6da") if i == 3 else Color("#ad9274"),false,self)
		for side in [-1,1]:
			part("Party wall",Vector3(x+side*4.13,1.6,46),Vector3(.18,3.4,7),color,true)
			var pane := part("Shop window",Vector3(x+side*2.55,1.65,FRONT_Z),Vector3(3.2,2.65,.15),Color("#668b91"),true)
			if i in [1,2,3,4,5]:
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
			var fascia := _lettering(SIGNS[i],Vector3(x,3.0,FRONT_Z-.41),.009,Color.WHITE)
			fascia.outline_size = 48
			get_parent()._size_world_sign(fascia,7.4)
		if i != 3:
			part("Counter",Vector3(x,.48,47.8),Vector3(5.7,1,1),color,true)
			part("Worktop",Vector3(x,1.02,47.8),Vector3(5.9,.10,1.1),cream)
		if i not in [2,3,5]:
			for shelf in [1.55,2.18]:
				part("Display shelf",Vector3(x,shelf,49.1),Vector3(6,.09,.45),cream)
				for jar in 8:
					var tint:=Color.from_hsv(fmod(.08*i+.105*jar,1),.52,.86)
					part("Display tin",Vector3(x-2.5+.7*jar,shelf+.19,49.08),Vector3(.32,.3,.26),tint)

		if i == 1:
			_kiosk(x)
		elif i == 3:
			_sweet_shop(x)
		elif i == 5:
			_boutique(x)
		elif i == 4:
			_grocery(x)
		elif i == 0:
			_display_cinnamon_buns(Vector3(x-1.3,1.09,47.55))

		elif i == 2:
			_pizzeria(x)
			order_slip.position = Vector3(x+2.92,1.31,47.50)
			order_slip.rotation.y = PI
			order_slip.pixel_size = .014
			add_child(order_slip)
			_update_order_slip()
			for recipe in MENUS[2].size():
				_display_pizza(Vector3(x+(recipe-2)*1.04,1.09,47.59),recipe)

const PIZZA_TEXTURES := [
	preload("res://branding/pizza-0.png"),
	preload("res://branding/pizza-1.png"),
	preload("res://branding/pizza-2.png"),
	preload("res://branding/pizza-3.png"),
	preload("res://branding/pizza-4.png"),
]

func _update_order_slip() -> void:
	var slip := AtlasTexture.new()
	slip.atlas = preload("res://branding/pizza-order-slips.svg")
	slip.region = Rect2(order_recipe*64,0,64,48)
	order_slip.texture = slip
	if is_instance_valid(order_picture):
		order_picture.texture = slip
		order_picture.tooltip_text = tr(PIZZA_TOPPINGS[order_recipe])
		order_picture.accessibility_name = order_picture.tooltip_text

func _display_pizza(center: Vector3, recipe: int) -> void:
	part("Pizza board",center,Vector3(.91,.032,.88),Color("#b28658"))
	var crust := CylinderMesh.new()
	crust.top_radius=.39
	crust.bottom_radius=.38
	crust.height=.047
	crust.material=get_parent()._material(Color("#cc9554"),.87)
	var pizza := MeshInstance3D.new()
	pizza.name=MENUS[2][recipe]
	pizza.mesh=crust
	pizza.position=center+Vector3.UP*.04
	add_child(pizza)
	var face := PlaneMesh.new()
	face.size = Vector2(.80,.80)
	var finish := StandardMaterial3D.new()
	finish.albedo_texture = PIZZA_TEXTURES[recipe]
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	finish.roughness = .74
	face.material = finish
	var surface := MeshInstance3D.new()
	surface.mesh = face
	surface.position.y = .024
	pizza.add_child(surface)

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

func set_large_text(enabled: bool) -> void:
	var reading_theme := Theme.new()
	if enabled:
		reading_theme.set_font_size("font_size", "Label", 22)
		reading_theme.set_font_size("font_size", "Button", 22)
	shop_card.theme = reading_theme
	if shop_card.is_inside_tree():
		shop_card.offset_left = -362 if enabled else -302

func build_menu(ui: CanvasLayer) -> void:
	ui.add_child(shop_card)
	shop_card.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	shop_card.offset_left = -362 if get_parent().large_text else -302
	shop_card.offset_right = -22
	shop_card.offset_top = 108
	shop_card.offset_bottom = -155
	var finish := StyleBoxFlat.new()
	finish.bg_color = Color("#20343bf5")
	finish.set_corner_radius_all(14)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		finish.set_content_margin(side,14)
	shop_card.add_theme_stylebox_override("panel",finish)
	var layout := VBoxContainer.new()
	shop_card.add_child(layout)
	balance = Label.new()
	balance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(balance)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	layout.add_child(scroll)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	receipt = Label.new()
	receipt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(receipt)
	shop_card.hide()

func grill_counter() -> Vector3:
	return Vector3(storefront_x(SHOPS.find("Hot dog stand")), 0, FRONT_Z - 0.9)

func at_grill_counter(pos: Vector3) -> bool:
	var counter := grill_counter()
	return absf(pos.x-counter.x) < 1.45 and pos.z > FRONT_Z-1.6 and pos.z < FRONT_Z-.15

func customer_is_indoors() -> bool:
	return inside >= 0 and inside != 6

func update_customer(foot: bool, pos: Vector3, active: bool) -> void:
	var index:=-1
	if foot:
		for i in SHOPS.size():
			if i == 6:
				if at_grill_counter(pos):
					index=i
				continue
			if absf(pos.x-storefront_x(i))<4 and pos.z>FRONT_Z and pos.z<49.4:
				index=i
				break
	var entering := index!=inside or not shop_card.visible
	if index!=inside:
		receipt_kind = ReceiptKind.NONE
		if inside>=0: awnings[inside].show()
		inside=index
		if inside>=0:
			if inside != 6: awnings[inside].hide()
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
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(title)
	var keyboard_hint := Label.new()
	keyboard_hint.text = "Tab to choose · Enter to buy" if MENUS[inside].size()>1 else "Enter to buy"
	if inside in SNACK_SHOPS:
		keyboard_hint.text = "Tab to choose · Enter to buy or eat"
	keyboard_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(keyboard_hint)
	if inside == 2:
		var prompt := Label.new()
		prompt.text = "Can you match the order slip?"
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(prompt)
		order_picture = TextureRect.new()
		order_picture.custom_minimum_size.y = 54
		order_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(order_picture)
		_update_order_slip()
	for i in MENUS[inside].size():
		var button:=Button.new()
		button.custom_minimum_size.y=44
		button.icon = _product_icon(inside,i)
		button.add_theme_constant_override("icon_max_width",44)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = _product_price(inside, i)
		if inside == 2:
			button.text += "\n" + tr(PIZZA_TOPPINGS[i])
		elif inside == 3:
			button.text += "\n" + tr(SWEET_INGREDIENTS[i])
		elif inside == 6:
			button.text += "\n" + tr(GRILL_TOPPINGS[i])
		button.pressed.connect(purchase.bind(inside,i))
		panel.add_child(button)
		if i==0: first_product=button
	_refresh_receipt()
	basket = RichTextLabel.new()
	basket.fit_content = true
	basket.scroll_active = false
	basket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(basket)
	if inside in SNACK_SHOPS:
		for i in MENUS[inside].size():
			var product: String = MENUS[inside][i]
			var purchase_button := panel.get_child(first_product.get_index()+i) as Button
			var eat := Button.new()
			eat.icon = purchase_button.icon
			eat.add_theme_constant_override("icon_max_width",44)
			match product:
				"Ice cream": eat.text = "Eat ice cream"
				"Hot dog": eat.text = "Eat hot dog"
				_: eat.text = tr("Eat %s") % tr(product)
			eat.custom_minimum_size.y = 44
			eat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if inside not in SNACK_SHOPS or not shop_card.is_visible_in_tree() or not game.walker.visible or game.paused: return
	if not product in MENUS[inside] or int(game.purchases.get(product, 0)) <= 0: return
	var restore_focus: bool = snack_buttons[product].has_focus() and game.purchases[product] == 1
	game.purchases[product] -= 1
	game._save_preferences()
	game.happy_seconds = 25
	game._refresh_ui()
	receipt_kind = ReceiptKind.SNACK
	receipt_subject = "Alma" if game.play_as_alma else "Axel"
	_refresh_receipt()
	refresh_basket()
	if restore_focus:
		for eat: Button in snack_buttons.values():
			if eat.visible:
				eat.grab_focus()
				return
		first_product.grab_focus()

func _product_icon(shop: int, item: int) -> Texture2D:
	if shop == 1:
		return _product_icon(3,4) if item == 0 else _product_icon(6,0)
	if not PRODUCT_ICONS.has(shop): return null
	var thumbnail := AtlasTexture.new()
	thumbnail.atlas = PRODUCT_ICONS[shop]
	thumbnail.region = Rect2(item*64,0,64,64)
	return thumbnail

func refresh_basket() -> void:
	var coins: int = get_parent().wallet
	balance.text = tr("Wallet") + " · " + (tr_n("%d coin", "%d coins", coins) % coins)
	basket.clear()
	basket.add_text(tr("Your purchases"))
	var purchases: Dictionary = get_parent().purchases
	for product in snack_buttons:
		snack_buttons[product].visible = int(purchases.get(product,0)) > 0
	# Keep Tab and Shift+Tab on the counter, including newly available snacks.
	var choices: Array[Button] = []
	for control in panel.get_children():
		if control is Button and control.visible:
			choices.append(control)
	for i in choices.size():
		var choice := choices[i]
		choice.focus_previous = choice.get_path_to(choices[posmod(i-1, choices.size())])
		choice.focus_next = choice.get_path_to(choices[(i+1) % choices.size()])
	var listed: Array[String] = []
	for shop in MENUS.size():
		for item in MENUS[shop].size():
			var product: String = MENUS[shop][item]
			var count := int(purchases.get(product,0))
			if count <= 0 or product in listed: continue
			listed.append(product)
			basket.newline()
			var icon := _product_icon(shop,item)
			if icon:
				basket.add_image(icon,40,40)
				basket.add_text("  ")
			basket.add_text(tr("%s × %d") % [tr(product),count])
	basket.visible = not listed.is_empty()

func purchase(shop: int, item: int) -> void:
	var game=get_parent()
	if shop!=inside or not shop_card.is_visible_in_tree() or not game.walker.visible or game.paused: return
	var cost:int=PRICES[shop][item]
	if game.wallet<cost:
		receipt_kind = ReceiptKind.SHORTFALL
		receipt_amount = cost-game.wallet
		_refresh_receipt()
		return
	var product:String=MENUS[shop][item]
	game.wallet-=cost
	if shop == 6:
		_serve_grill_order(item)
	till_sound.play()
	game.purchases[product]=int(game.purchases.get(product,0))+1
	if shop == 5 and item in [0,1]:
		game.boutique_jacket = product
		game._apply_player_appearance()
	if shop == 5 and item in [2,3]:
		carried_toy = product
		show_carried_toy()
	refresh_basket()
	game._save_preferences()
	game._refresh_ui()
	receipt_kind = ReceiptKind.PURCHASE
	receipt_subject = product
	receipt_amount = cost
	if shop == 2 and item == order_recipe:
		order_recipe = (order_recipe+1) % MENUS[2].size()
		_update_order_slip()
		receipt_kind = ReceiptKind.ORDER_MATCH
	_refresh_receipt()

func _refresh_receipt() -> void:
	receipt.visible = receipt_kind != ReceiptKind.NONE
	match receipt_kind:
		ReceiptKind.PURCHASE, ReceiptKind.ORDER_MATCH:
			receipt.text = tr_n("%s · Paid %d coin. Thank you!", "%s · Paid %d coins. Thank you!", receipt_amount) % [tr(receipt_subject),receipt_amount]
			if receipt_kind == ReceiptKind.ORDER_MATCH:
				receipt.text += " " + tr("Order matched!")
		ReceiptKind.SHORTFALL:
			var missing := tr_n("You need %d more coin.", "You need %d more coins.", receipt_amount) % receipt_amount
			receipt.text = missing+" "+tr("Complete a mission to earn coins.")
		ReceiptKind.SNACK:
			receipt.text = tr("%s feels extra happy!") % receipt_subject
		ReceiptKind.NONE:
			receipt.text = ""

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

func _staff_grill_hatch(x: float) -> void:
	var game := get_parent()
	game._make_walker("Grill cook",0,0,1,Color("#e6dfc9"),Color("#42484c"))
	var cook: Node3D = game.walker_data.pop_back().actor
	cook.reparent(self,false)
	cook.position = Vector3(x,.21,42.96)
	cook.rotation.y = 0
	serving_arm = cook.get_meta("arms")[1]
	serving_arm.add_child(serving_dish)
	serving_dish.position = Vector3(0,-.70,-.075)
	serving_dish.pixel_size = .005
	serving_dish.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	serving_dish.hide()

func _serve_grill_order(item: int) -> void:
	if serving_motion:
		serving_motion.kill()
	var picture := AtlasTexture.new()
	picture.atlas = PRODUCT_ICONS[6]
	picture.region = Rect2(item*64,0,64,64)
	serving_dish.texture = picture
	serving_motion = create_tween()
	serving_arm.rotation.x = .55
	serving_dish.show()
	serving_motion.tween_property(serving_arm,"rotation:x",1.5,.35).set_trans(Tween.TRANS_SINE)
	serving_motion.tween_interval(.9)
	serving_motion.tween_callback(serving_dish.hide)
	serving_motion.tween_property(serving_arm,"rotation:x",0.0,.4)

func _hot_dog_stand(x: float) -> void:
	_staff_grill_hatch(x)
	var cream := Color("#f3e2b9")
	var red := Color("#a73b32")
	var steel := Color("#82898a")
	var patio_x := x-3.78
	get_parent()._make_driving_surface("Grill patio",Vector3(2.56,.10,3.48),Vector3(patio_x,-.061,44.17),Color("#aa9c8c"),false,self)
	var green := Color("#527b62")
	for offset in [-.66,.66]:
		part("Picnic trestle",Vector3(patio_x,.36,44.18+offset),Vector3(.15,.70,.10),steel,true)
		part("Bench cross brace",Vector3(patio_x,.32,44.18+offset),Vector3(1.50,.09,.10),steel)
	for plank in [-1,0,1]:
		part("Table slat",Vector3(patio_x+plank*.21,.75,44.18),Vector3(.20,.08,1.81),green,true)
	for side in [-1,1]:
		part("Bench seat",Vector3(patio_x+side*.68,.43,44.18),Vector3(.32,.09,1.81),green,true)
		for offset in [-.66,.66]:
			part("Bench foot",Vector3(patio_x+side*.68,.195,44.18+offset),Vector3(.13,.39,.12),steel)
	part("Kiosk plinth",Vector3(x,.10,44.5),Vector3(4.7,.22,3.9),steel,true)
	part("Front wainscot",Vector3(x,.55,42.63),Vector3(4.7,.94,.20),cream,true)
	part("Kitchen back wall",Vector3(x,1.45,46.34),Vector3(4.7,2.75,.18),cream,true)
	for side in [-1,1]:
		part("Timber side wall",Vector3(x+side*2.27,1.45,44.5),Vector3(.18,2.75,3.8),cream,true)
		part("Hatch jamb",Vector3(x+side*1.29,1.85,42.63),Vector3(.07,1.7,.13),steel)
		part("Menu slate",Vector3(x+side*1.77,1.84,42.63),Vector3(.89,1.63,.12),Color("#25382e"),true)
		var pane_x: float = x+side*.99
		var pane := part("Sliding hatch glass",Vector3(pane_x,1.89,42.62),Vector3(.56,1.56,.023),Color.WHITE)
		var glass := pane.material_override as StandardMaterial3D
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.albedo_color = Color(.74,.88,.91,.23)
		glass.roughness = .13
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part("Sliding sash stile",Vector3(x+side*.70,1.89,42.62),Vector3(.035,1.58,.05),steel)
		part("Sash pull",Vector3(x+side*.75,1.62,42.57),Vector3(.032,.16,.055),Color("#354448"))
	# The staff entrance faces the picnic tables, as on a freestanding street kiosk.
	var door_z := 45.22
	part("Staff door frame",Vector3(x-2.37,1.22,door_z),Vector3(.07,2.14,.99),steel)
	part("Painted staff door",Vector3(x-2.41,1.21,door_z),Vector3(.028,2.04,.88),cream)
	part("Door kick plate",Vector3(x-2.429,.35,door_z),Vector3(.012,.29,.84),steel)
	part("Lever mount",Vector3(x-2.436,1.14,door_z-.32),Vector3(.023,.14,.047),steel)
	part("Lever handle",Vector3(x-2.465,1.16,door_z-.27),Vector3(.054,.025,.13),steel)
	for rail_y in [1.12,2.68]:
		part("Hatch guide rail",Vector3(x,rail_y,42.62),Vector3(2.64,.042,.083),steel)
	for i in 23:
		part("Panel seam",Vector3(x+(i-11)*.20,.56,42.521),Vector3(.014,.87,.016),Color("#c6b591"))
	part("Serving ledge",Vector3(x,1.06,42.55),Vector3(4.8,.10,.64),steel,true)
	var roof := part("Grill kiosk roof",Vector3(x,2.91,44.23),Vector3(5.08,.24,4.68),red)
	awnings.append(roof)
	var midnight := Color("#292733")
	var amber := Color("#ffb34b")
	var tomato := Color("#ff6049")
	part("Grill sign backplate",Vector3(x,3.40,42.15),Vector3(4.18,.71,.15),midnight)
	var sign_label := _lettering("Hot dog stand",Vector3(x-.44,3.40,42.045),.012,Color(1.9,1.36,.58))
	sign_label.shaded = false
	sign_label.outline_size = 9
	sign_label.outline_modulate = tomato
	get_parent()._size_world_sign(sign_label,2.95)
	var emblem := Vector3(x+1.53,3.4,42.03)
	_bent_neon_tube(emblem,PackedVector2Array([Vector2(-.47,-.06),Vector2(-.36,-.17),Vector2(.18,-.11),Vector2(.43,.02),Vector2(.48,.13)]),amber)
	_bent_neon_tube(emblem,PackedVector2Array([Vector2(-.42,.04),Vector2(-.45,.10),Vector2(-.39,.15),Vector2(-.03,.14),Vector2(.28,.23),Vector2(.39,.22),Vector2(.42,.16),Vector2(.35,.11),Vector2(.01,.02),Vector2(-.42,.04)]),tomato)
	var mustard := PackedVector2Array()
	for i in 33:
		var t := i/32.0
		mustard.append(Vector2(lerpf(-.34,.33,t),.081+.066*t+.021*sin(TAU*2.5*t)))
	_bent_neon_tube(emblem-Vector3.BACK*.014,mustard,Color("#ffd53d"),.009)
	grill_neon_light = _shop_light(emblem + Vector3.FORWARD * .25, tomato, .48)
	grill_neon_light.omni_range = 1.35
	for dx in [-1.40,1.40]:
		part("Hatch lamp housing",Vector3(x+dx,2.77,42.05),Vector3(.78,.075,.18),steel)
		var diffuser := part("Hatch lamp diffuser",Vector3(x+dx,2.72,42.05),Vector3(.71,.045,.14),cream)
		diffuser.material_override = get_parent()._material(cream,.3,true)
		_shop_light(Vector3(x+dx,2.58,42.09),Color("#ffd69a"),.95)
	part("Stainless extraction hood",Vector3(x+.59,2.38,44.10),Vector3(1.83,.25,.81),steel)
	part("Extraction duct",Vector3(x+.60,2.65,44.22),Vector3(.52,.45,.38),steel)
	part("Kitchen shelf",Vector3(x-.81,1.77,45.95),Vector3(1.48,.07,.49),cream)
	for jar in 5:
		_turned("Pickle jar",Vector3(x-1.3+jar*.25,1.91,45.91),.082,.082,.22,Color("#849852"))
		_turned("Jar lid",Vector3(x-1.3+jar*.25,2.04,45.91),.086,.086,.034,red)
	part("Kitchen prep counter",Vector3(x, .54,43.42),Vector3(3.90,1.06,.79),cream)
	part("Bread tray",Vector3(x-.61,1.10,43.1),Vector3(.91,.05,.61),steel)
	for i in 3:
		var bun := MeshInstance3D.new()
		bun.mesh = SphereMesh.new()
		bun.scale = Vector3(.19,.13,.39)
		bun.material_override = get_parent()._material(Color("#d89a58"),.8)
		bun.position = Vector3(x-.89+.25*i,1.18,43.11)
		add_child(bun)
	part("Grill hotplate",Vector3(x+.62,1.09,43.07),Vector3(1.22,.13,.70),Color("#484343"))
	var roller_mesh := CylinderMesh.new()
	roller_mesh.top_radius = .042
	roller_mesh.bottom_radius = .042
	roller_mesh.height = 1.07
	roller_mesh.radial_segments = 16
	var roller_finish: StandardMaterial3D = get_parent()._material(steel,.29)
	roller_finish.metallic = .77
	roller_mesh.material = roller_finish
	for row in 6:
		var roller := MeshInstance3D.new()
		roller.mesh = roller_mesh
		roller.rotation.z = PI*.5
		roller.position = Vector3(x+.62,1.186,42.82+row*.10)
		add_child(roller)
	for side in [-1,1]:
		part("Roller bearing cover",Vector3(x+.62+side*.555,1.17,43.07),Vector3(.063,.14,.65),steel)
	var frank := CapsuleMesh.new()
	frank.radius = .049
	frank.height = .36
	frank.radial_segments = 16
	frank.rings = 5
	frank.material = get_parent()._material(Color("#ac5032"),.43)
	for i in 6:
		var sausage := MeshInstance3D.new()
		sausage.mesh = frank
		add_child(sausage)
		if i < 5:
			sausage.position = Vector3(x+.62+(.22 if i%2 else -.22),1.262,42.87+i*.10)
			sausage.rotation.z = PI*.5
		else:
			sausage.position = Vector3(x+.03,1.20,42.39)
			sausage.rotation.z = PI*.5
	var tray := Vector3(x+.03,1.119,42.39)
	part("Folded paper tray",tray,Vector3(.40,.018,.18),cream)
	for side in [-1,1]:
		var fold := part("Paper tray lip",tray+Vector3(0,.019,side*.095),Vector3(.40,.046,.009),cream)
		fold.rotation.x = side*.32
		var half_roll := MeshInstance3D.new()
		half_roll.mesh = SphereMesh.new()
		half_roll.position = tray+Vector3(0,.052,side*.046)
		half_roll.scale = Vector3(.33,.103,.090)
		half_roll.material_override = get_parent()._material(Color("#dfaa61"),.80)
		add_child(half_roll)
	var mustard_finish: StandardMaterial3D = get_parent()._material(Color("#f5c22b"),.5)
	var previous := tray+Vector3(-.12,.129,0)
	for step in range(1,17):
		var t := step/16.0
		var point := tray+Vector3(lerpf(-.12,.12,t),.129,.012*sin(t*TAU*2))
		get_parent()._tube_between(self,previous,point,.006,mustard_finish)
		previous = point
	for i in 2:
		var sauce := Color("#c9442e") if i == 0 else Color("#eabe36")
		_turned("Condiment bottle",Vector3(x-.85+i*.16,1.25,42.49),.058,.062,.26,sauce)
		_turned("Bottle nozzle",Vector3(x-.85+i*.16,1.41,42.49),.036,.009,.08,cream)
	for i in 4:
		var poster := Sprite3D.new()
		poster.texture = PRODUCT_ICONS[6]
		poster.region_enabled = true
		poster.region_rect = Rect2(i*64,0,64,64)
		poster.pixel_size = .010
		poster.position = Vector3(x+(1.5-i)*.95,.57,42.50)
		poster.rotation.y = PI
		poster.shaded = true
		add_child(poster)
		var ticket := _lettering(MENUS[6][i],Vector3(x+(-1.77 if i<2 else 1.77),2.18-.66*(i%2),42.55),.003,cream)
		get_parent()._size_world_sign(ticket,.82)
		var price := _lettering(_grill_price(i),ticket.position-Vector3.UP*.18,.003,Color("#ffcf74"))
		get_parent()._size_world_sign(price,.82)
		grill_price_signs.append(price)

func _grill_price(item: int) -> String:
	var coins: int = PRICES[6][item]
	return tr_n("%d coin","%d coins",coins) % coins

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
	for i in MENUS[1].size():
		var row := _lettering(_product_price(1,i),Vector3(x+2.8,1.89-.40*i,42.21),.0044,ivory)
		get_parent()._size_world_sign(row,1.52)
		kiosk_menu_signs.append(row)
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

func _product_price(shop: int, item: int) -> String:
	var price: int = PRICES[shop][item]
	return tr_n("%s · %d coin", "%s · %d coins", price) % [tr(MENUS[shop][item]), price]

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_candy_letters.call_deferred()
		for i in kiosk_menu_signs.size():
			kiosk_menu_signs[i].text = _product_price(1,i)
			get_parent()._fit_world_sign(kiosk_menu_signs[i])
		for i in grill_price_signs.size():
			grill_price_signs[i].text = _grill_price(i)
			get_parent()._fit_world_sign(grill_price_signs[i])
		for sign_label in pizza_price_signs:
			sign_label.text = _product_price(2, 0)
			get_parent()._fit_world_sign(sign_label)

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

func _bent_neon_tube(center: Vector3, points: PackedVector2Array, hue: Color, radius := .021) -> void:
	var path := PackedVector2Array([points[0]])
	for i in range(1,points.size()):
		path.append(points[i-1].lerp(points[i],.25))
		path.append(points[i-1].lerp(points[i],.75))
	path.append(points[-1])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 8
	for i in path.size():
		var tangent := (path[mini(i+1,path.size()-1)]-path[maxi(i-1,0)]).normalized()
		for j in SIDES:
			var angle := TAU*j/SIDES
			var normal := Vector3(-tangent.y*cos(angle),tangent.x*cos(angle),sin(angle))
			surface.set_normal(normal)
			surface.add_vertex(Vector3(path[i].x,path[i].y,0)+radius*normal)
			if i > 0:
				var a := (i-1)*SIDES+j
				var b := (i-1)*SIDES+(j+1)%SIDES
				for index in [a,a+SIDES,b,b,a+SIDES,b+SIDES]:
					surface.add_index(index)
	var tube := MeshInstance3D.new()
	tube.mesh = surface.commit()
	var finish: StandardMaterial3D = get_parent()._material(hue,.26,true)
	tube.material_override = finish
	grill_neon_finishes.append(finish)
	tube.position = center
	add_child(tube)

func advance_grill_sign(delta: float, steady := false) -> void:
	grill_neon_phase = fmod(grill_neon_phase+delta,3.6)
	var lit := steady or grill_neon_phase < 2.8
	if lit == grill_neon_lit: return
	grill_neon_lit = lit
	grill_neon_light.visible = lit
	for finish in grill_neon_finishes:
		finish.emission_enabled = lit
		finish.albedo_color = finish.emission if lit else finish.emission.darkened(.86)

func _neon_outline(center: Vector3, points: PackedVector2Array, hue: Color) -> void:
	var finish: Material = get_parent()._material(hue,.32,true)
	for i in range(1,points.size()):
		var segment := points[i]-points[i-1]
		var mid := (points[i]+points[i-1])*.5
		var tube := part("Neon tube",center+Vector3(mid.x,mid.y,0),Vector3(segment.length()+.025,.047,.047),hue)
		tube.rotation.z = segment.angle()
		tube.material_override = finish

func _pizzeria_front(x: float) -> void:
	_neon_outline(Vector3(x-2.4,2.05,42.01),PackedVector2Array([Vector2(-.46,.26),Vector2(-.2,.37),Vector2(.18,.36),Vector2(.48,.23),Vector2(.1,-.39),Vector2(-.46,.26)]),Color("#ff9953"))
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
	var nameplate := _lettering("HARBOR TOWN PIZZERIA",Vector3(x,3.07,41.951),.0175,wine)
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
		for inside_face in [false,true]:
			var z := 42.58 if inside_face else 42.35
			var letters := _lettering(window_text,Vector3(cx,1.68,z),.0081,Color("#fff1ce"))
			letters.rotation.y = 0.0 if inside_face else PI
			letters.double_sided = false
			letters.font = shop_sign_font
			get_parent()._size_world_sign(letters,2.9)
		part("Window menu strip",Vector3(cx,1.04,42.32),Vector3(2.97,.22,.027),wine)
		var menu_text := _product_price(2, 0) if side == 1 else "EAT IN  ·  TAKEAWAY"
		var menu_strip := _lettering(menu_text,Vector3(cx,1.04,42.29),.0048,Color("#fff3d5"))
		get_parent()._size_world_sign(menu_strip,2.9)
		if side == 1:
			pizza_price_signs.append(menu_strip)
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
		var card := _lettering(["PIZZA", _product_price(2, 0), "TAKEAWAY"][i],Vector3(cx,2.61,49.17),.0058,wine)
		get_parent()._size_world_sign(card,1.96)
		if i == 1:
			pizza_price_signs.append(card)
	_shop_light(Vector3(x,2.8,46.0),Color("#ffddab"),1.15)

func _update_candy_letters() -> void:
	var title := tr("Candy Cabin").to_upper()
	var spacing := minf(.55,5.92/maxi(1,title.length()))
	var palette := [Color("#ff78a6"),Color("#ffd25b"),Color("#64dfd0"),Color("#fc8a47"),Color("#b4a6fc")]
	while candy_letters.size() < title.length():
		var index := candy_letters.size()
		var letter := _lettering("",Vector3.ZERO,.0255,palette[index%palette.size()])
		letter.font = shop_sign_font
		letter.rotation.z = sin(index*2.0)*.045
		candy_letters.append(letter)
	for i in candy_letters.size():
		var letter := candy_letters[i]
		letter.visible = i < title.length()
		if letter.visible:
			letter.text = title[i]
			letter.pixel_size = .0255*.25*spacing/.55
			letter.position = Vector3(storefront_x(3)+(.5*(title.length()-1)-i)*spacing,3.04+.028*sin(i*1.65),41.94)

func _sweet_shop(x: float) -> void:
	var spiral := PackedVector2Array()
	for i in 33:
		var angle := float(i)*TAU/20
		spiral.append(Vector2(cos(angle),sin(angle))*(.04+.009*i))
	var center := Vector3(x+2.4,2.08,42.02)
	_neon_outline(center,spiral,Color("#ff70ac"))
	_neon_outline(center,PackedVector2Array([Vector2(0,-.22),Vector2(.13,-.58)]),Color("#70ffdc"))
	var frame := Color("#28282c")
	var pearl := Color("#fff4df")
	var palette := [Color("#ff78a6"),Color("#ffd25b"),Color("#64dfd0"),Color("#fc8a47"),Color("#b4a6fc")]
	part("Ebony candy fascia",Vector3(x,3.04,42.12),Vector3(8.5,.91,.30),frame)
	for y in [2.64,3.44]:
		part("Fascia rolled rim",Vector3(x,y,41.95),Vector3(8.45,.041,.035),Color("#4b4951"))
	_update_candy_letters()
	# Two wrapped boiled sweets at opposite ends complete the shop's sign.
	for side in [-1,1]:
		var cx:float=x+side*3.56
		var candy := _turned("Wrapped sweet medallion",Vector3(cx,3.04,41.91),.155,.155,.043,palette[0])
		candy.rotation.x = PI*.5
		for edge in [-1,1]:
			var twist := _turned("Sweet wrapper",Vector3(cx+edge*.17,3.04,41.91),.11,.03,.13,palette[1])
			twist.rotation.z = edge*PI*.5
		part("Dark display plinth",Vector3(x+side*2.54,.30,42.34),Vector3(3.22,.60,.23),frame)
		for slot in 5:
			# The street-facing side looks along +Z, so its left edge is +X.
			var product := slot if side == 1 else 5 + slot
			var decal := Sprite3D.new()
			decal.name = "Window " + SWEETS[product]
			decal.texture = PRODUCT_ICONS[3]
			decal.hframes = SWEETS.size()
			decal.frame = product
			decal.pixel_size = .0078
			decal.position = Vector3(x + side*2.54 + (2-slot)*.59, .36, 42.20)
			decal.rotation.y = PI
			decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(decal)
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
			part("Flavour ticket",Vector3(cx,height-.032,z-.166),Vector3(.30,.065,.012),charcoal)
			var flavours := ["Raspberry","Lemon","Apple","Liquorice","Vanilla","Strawberry","Orange","Grape"]
			var ticket := _lettering(flavours[flavour],Vector3(cx,height-.032,z-.174),.00135,Color.WHITE)
			get_parent()._size_world_sign(ticket,.28)
			ticket.visibility_range_end = 5.0
			get_parent()._size_world_sign(ticket,.28)

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

func _shop_light(pos: Vector3, hue: Color, power: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = hue
	light.light_energy = power
	light.omni_range = 5.5
	light.distance_fade_enabled = true
	light.distance_fade_begin = 18
	light.distance_fade_length = 10
	add_child(light)
	return light

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

func _boutique(x: float) -> void:
	var maple := Color("#c99e76")
	var plum := Color("#724467")
	var jade := Color("#467c75")
	_open_glass_door(x, maple)
	for side: float in [-1,1]:
		var center := Vector3(x+side*2.6,.66,43.18)
		part("Window plinth",center,Vector3(2.36,.18,.81),maple,true)
		_shop_light(center+Vector3(0,1.95,.12),Color("#ffe4be"),.85)
	# Haori with open front and broad sleeves; short jeogori with crossed collar and goreum ties.
	for i in 4:
		var korean := i%2 == 1
		var pos := Vector3(x-2.6+(i%2-.5)*1.04,1.22,43.2) if i < 2 else Vector3(x-1.9+(i%2)*1.04,1.58,48.92)
		var cloth := plum if korean else jade
		var trim := Color("#f2dbae")
		var length := .46 if korean else .71
		part("Garment stand",pos+Vector3(0,-.19,.08),Vector3(.05,.53,.05),maple)
		part("Jacket back",pos,Vector3(.46,length,.14),cloth)
		for side: float in [-1,1]:
			var sleeve := part("Wide sleeve",pos+Vector3(side*.31,length*.23,0),Vector3(.23,.30,.18),cloth)
			sleeve.rotation.z = side*.19
			var lapel := part("Woven lapel",pos+Vector3(side*(.059 if korean else .078),.025,-.083),Vector3(.040,length*.9,.025),trim)
			lapel.rotation.z = side*(.48 if korean else .13)
		if korean:
			var tie := part("Ribbon tie",pos+Vector3(.112,-.074,-.11),Vector3(.045,.18,.024),plum.lightened(.46))
			tie.rotation.z = -.40
	for i in 8:
		var window := i < 4
		var pos := Vector3(x+2.60+(i%4-1.5)*.47,.76,43.14) if window else Vector3(x+.59+(i%4)*.65,1.09,47.59)
		if i%2 == 0:
			_boutique_toy(pos,false)
		else:
			_boutique_toy(pos,true)
	part("Garment rail",Vector3(x-1.38,2.02,48.97),Vector3(2.28,.045,.045),maple)
	_lettering("Momo & Bori",Vector3(x,2.47,49.28),.014,Color("#fff1dd"))

func show_carried_toy() -> void:
	if is_instance_valid(toy_in_hand):
		toy_in_hand.hide()
		toy_in_hand.queue_free()
		toy_in_hand = null
	var item: int = MENUS[5].find(carried_toy)
	if item not in [2,3] or int(get_parent().purchases.get(carried_toy,0)) < 1:
		return
	var arm: Node3D = get_parent().walker.get_meta("arms")[0]
	toy_in_hand = _boutique_toy(Vector3.ZERO,item == 3)
	toy_in_hand.reparent(arm,false)
	toy_in_hand.name = "MoonRabbit" if item == 3 else "RedPanda"
	toy_in_hand.position = Vector3(-.085,-.85,-.095)
	toy_in_hand.scale = Vector3.ONE * .8

func _boutique_toy(base: Vector3, rabbit: bool) -> Node3D:
	var toy := Node3D.new()
	toy.name = "MoonRabbit" if rabbit else "RedPanda"
	add_child(toy)
	toy.position = base
	var fur := Color("#eadbb7") if rabbit else Color("#b45b3d")
	var dark := Color("#493334")
	var cream := Color("#fff0d5")
	var sphere := SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 8
	var oval := func(offset: Vector3, size: Vector3, color: Color):
		var piece := MeshInstance3D.new()
		piece.mesh = sphere
		piece.material_override = get_parent()._material(color,.48 if rabbit else .98)
		piece.position = offset
		piece.scale = size
		toy.add_child(piece)
	if rabbit:
		var stand := _turned("Figure base",Vector3.UP*.023,.126,.126,.046,Color("#809bb0"))
		stand.reparent(toy,false)
	oval.call(Vector3(0,.15,0),Vector3(.21,.25,.18),fur)
	oval.call(Vector3(0,.30,-.01),Vector3(.255,.21,.19),fur)
	for side: float in [-1,1]:
		oval.call(Vector3(side*.071,.415 if rabbit else .386,-.006),Vector3(.064,.17 if rabbit else .083,.052),fur)
		if not rabbit:
			oval.call(Vector3(side*.067,.30,-.087),Vector3(.097,.059,.039),cream)
		oval.call(Vector3(side*.052,.316,-.102),Vector3(.025,.027,.02),dark)
		oval.call(Vector3(side*.065,.065,-.044),Vector3(.078,.073,.093),fur)
	oval.call(Vector3(0,.274,-.108),Vector3(.038,.025,.025),dark)
	return toy
