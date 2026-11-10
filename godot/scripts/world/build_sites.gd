class_name BuildSites
extends RefCounted
## Konoha dışındaki köyler ve önemli yerler (anime ölçeği: köyler kilometrelerce, simge yapılar yüzlerce metre).
## Konoha ve hikâye yerleri yüklemede kurulur; diğer köyler oyuncu yaklaşınca akışla (birkaç karede) kurulur,
## uzaktan ise ucuz siluetleri (far_silhouette) görünür.

const VILLAGE_BUILD_R := 4500.0   # köy bu mesafede kurulur
const VILLAGE_FREE_R := 6500.0
static var _fx_done := {}          # şelale/buhar gibi kalıcı efektler bir kez eklenir


static func build_all(parent: Node3D) -> void:
	for v in Game.world_info["villages"]:
		if v["id"] == "konoha":
			if VillageBake.try_load(parent, "konoha") == null:
				var snap = VillageBake.snapshot("konoha")
				BuildKonoha.build(parent, v)
				while Builder.dressing > 0:   # peyzaj (ara arsa evleri vb.) bitmeden pişirme yok: yarım köy kaydediliyordu
					await Engine.get_main_loop().process_frame
				VillageBake.save(parent.get_node_or_null("Konoha"), "konoha", snap)
	for l in Game.world_info["landmarks"]:
		match l["id"]:
			"valley_end": valley_end(parent, l)
			"forest_death": forest_death(parent, l)
			"sage_falls": sage_falls(parent, l)
			"naruto_bridge": naruto_bridge(parent, l)
			"hideout": hideout(parent, l)
			"bandit_camp": camp(parent, l, "bandit")
			"border_post": outpost(parent, l)
			"storm_canyon": storm_canyon(parent, l)
	# diğer köyler: akış düğümü + uzak siluetler
	var vs = VillageStream.new()
	vs.name = "VillageStream"
	parent.add_child(vs)
	for v in Game.world_info["villages"]:
		if v["id"] != "konoha":
			far_silhouette(parent, v)


## Akışla köy kuran düğüm: yaklaşınca kur (eşzamansız, kare kare), uzaklaşınca sil
class VillageStream extends Node3D:
	var built := {}   # id -> {node, inter, done}
	var _t := 0.0

	func _build(node: Node3D, v: Dictionary, rec: Dictionary) -> void:
		var id = String(v["id"])
		var before = Interact.items.size()
		var cached = VillageBake.try_load(node, id)
		if cached != null:
			rec["inter"] = Interact.items.slice(before)
			rec["done"] = true
			return
		var snap = VillageBake.snapshot(id)
		await BuildSites.build_village(node, v, rec)
		while Builder.dressing > 0 and is_instance_valid(node):   # peyzaj (ara arsa evleri, ağaçlar, sokaklar) bitmeden pişirme: yarım köy kaydediliyordu
			await Engine.get_main_loop().process_frame
		if is_instance_valid(node):
			# pişirme kökü: köy düğümünün çocukları tek bir kökte toplanır
			var bake_root = Node3D.new()
			bake_root.name = "Pisirilmis"
			for ch in node.get_children():
				ch.reparent(bake_root, false)
			node.add_child(bake_root)
			VillageBake.split_bodies(bake_root)
			VillageBake.save(bake_root, id, snap)
		rec["done"] = true

	## Hızlı seyahat: hedef köyü hemen kurmaya başla (yükleme ekranı bunu bekler)
	func request(id: String) -> Dictionary:
		if built.has(id):
			return built[id]
		var v = Game.village(id)
		var node = Node3D.new()
		node.name = "Koy_" + id
		add_child(node)
		built[id] = {"node": node, "inter": [], "before": Interact.items.size(), "done": false}
		_build(node, v, built[id])
		return built[id]

	func _process(dt: float) -> void:
		_t -= dt
		if _t > 0.0:
			return
		_t = 1.0
		var cam = get_viewport().get_camera_3d()
		var p: Vector3 = Game.player.global_position if Game.player else (cam.global_position if cam else Vector3.ZERO)
		var m = Vector2(p.x, -p.z)
		for v in Game.world_info["villages"]:
			var id: String = v["id"]
			if id == "konoha":
				continue
			var d = m.distance_to(Vector2(v["x"], v["y"])) - float(v["r"])
			if d < VILLAGE_BUILD_R and not built.has(id):
				var node = Node3D.new()
				node.name = "Koy_" + id
				add_child(node)
				built[id] = {"node": node, "inter": [], "before": Interact.items.size(), "done": false}
				_build(node, v, built[id])
			elif d > VILLAGE_FREE_R and built.has(id) and built[id]["done"]:
				# köyün noktaları SIRAYA göre değil KONUMA göre silinir: kurulum kareler boyunca sürerken başka sistemler de listeye
				# ekleyip sildiği için dilim kayıyordu -> başka yerlerin (akademi, sınav...) harita noktaları siliniyor, köyünkiler kalıyordu
				# etiketli (Builder: _koy) noktalar + kurulumda eklenen etiketsizlerden köy alanında kalanlar; kalıcı noktalar korunur
				var vc = Vector2(float(v["x"]), float(v["y"]))
				var vr = float(v["r"]) * 1.35 + 60.0
				var mine = built[id]["inter"]
				Interact.items = Interact.items.filter(func(it):
					if String(it.get("_koy", "")) == id:
						return false
					if it.has("_koy") or it.get("interior", false) or it.get("relocate", false):
						return true
					return not (mine.has(it) and Game.to_map(it["pos"]).distance_to(vc) < vr))
				built[id]["node"].queue_free()
				built.erase(id)


static func build_village(node: Node3D, v: Dictionary, rec: Dictionary) -> void:
	Builder.roof_points.erase(String(v["id"]).to_lower())
	var before = Interact.items.size()
	match v["id"]:
		"suna": await suna(node, v)
		"kiri": await kiri(node, v)
		"kumo": await kumo(node, v)
		"iwa": await iwa(node, v)
		"ame": await ame(node, v)
		"oto": await oto(node, v)
		"kusa": await kusa(node, v)
		"taki": await taki(node, v)
		"yu": await yu(node, v)
		"shimo": await small_town(node, v, "snow")
		"tani": await tani(node, v)
		"nami": await nami(node, v)
		"uzushio": uzushio(node, v)
		"tetsu": await tetsu(node, v)
	if is_instance_valid(node):
		_gates(node, v)
		rec["inter"] = Interact.items.slice(before)


## Yolların köye girdiği yerlere köy tarzında dev giriş kapısı
const GATE_STYLE := {
	"suna": [Color(0.78, 0.62, 0.42), Color(0.6, 0.45, 0.3)], "kiri": [Color(0.45, 0.52, 0.58), Color(0.28, 0.38, 0.5)],
	"kumo": [Color(0.85, 0.85, 0.82), Color(0.25, 0.45, 0.7)], "iwa": [Color(0.5, 0.4, 0.3), Color(0.35, 0.27, 0.2)],
	"ame": [Color(0.4, 0.42, 0.45), Color(0.3, 0.31, 0.33)], "oto": [Color(0.35, 0.3, 0.4), Color(0.45, 0.3, 0.55)],
	"shimo": [Color(0.6, 0.62, 0.66), Color(0.92, 0.94, 0.97)], "tetsu": [Color(0.4, 0.4, 0.42), Color(0.22, 0.22, 0.25)],
}
## Örülü sur halkası olan köyler: [yükseklik, kalınlık, duvar rengi, başlık rengi]
const RING_WALLS := {
	"iwa": [20.0, 7.0, Color(0.52, 0.42, 0.32), Color(0.58, 0.24, 0.17)],
	"kumo": [18.0, 6.0, Color(0.7, 0.71, 0.7), Color(0.25, 0.45, 0.7)],
	"ame": [24.0, 5.0, Color(0.34, 0.36, 0.39), Color(0.24, 0.25, 0.28)],
	"oto": [12.0, 5.0, Color(0.36, 0.33, 0.38), Color(0.45, 0.3, 0.55)],
	"tetsu": [14.0, 6.0, Color(0.6, 0.6, 0.62), Color(0.22, 0.26, 0.3)],
	"yu": [10.0, 4.0, Color(0.62, 0.55, 0.48), Color(0.55, 0.22, 0.18)],
	"kusa": [9.0, 3.5, Color(0.48, 0.36, 0.24), Color(0.3, 0.45, 0.25)],
	"taki": [10.0, 4.0, Color(0.45, 0.34, 0.22), Color(0.25, 0.42, 0.3)],
	"shimo": [10.0, 4.0, Color(0.7, 0.72, 0.76), Color(0.92, 0.94, 0.97)],
	"tani": [9.0, 4.0, Color(0.55, 0.48, 0.38), Color(0.45, 0.3, 0.2)],
}


static func _gates(parent: Node3D, v: Dictionary) -> void:
	var angles: Array = v.get("gates", [])
	if angles.is_empty():
		return
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Gate_" + String(v["id"]))
	b.view_dist = 5000.0
	var st: Array = GATE_STYLE.get(v["id"], [Color(0.45, 0.3, 0.2), Color(0.62, 0.2, 0.18)])
	var r = float(v["r"]) * 0.95
	# kayalık surlu köy (Suna, Kiri): kapı kanatları sur boşluğunu kayalara kadar kapatır (eskiden boşluğun ortasında yalnız duruyordu)
	var gap = {"suna": 9.0, "kiri": 13.0}.get(v["id"], 0.0)
	var ring = RING_WALLS.get(v["id"])
	if ring != null:
		# örülü sur: kapı dikmeleri surun boşluğuna tam oturur (kanat/kule gerekmez)
		var half = 12.0 + 3.2
		var gdeg = rad_to_deg(half * 2.0 / r)
		var gaps = []
		for a in angles:
			gaps.append([float(a), gdeg])
		b.wall_ring(r, ring[0], ring[1], ring[2], gaps, 1.0, ring[3])
		gap = 0.001   # kanatsız kapı
	for a in angles:
		if v["id"] == "yu":
			_yu_gate(b, float(a), r)
		else:
			b.village_gate(float(a), r, 12.0, 30.0 if v["id"] != "suna" else 40.0, st[0], st[1], String(v["id"]), gap)
		# kapı nöbetçileri: kapının iç tarafında iki yanda, dışarı bakar (köy hayatı onları doldurur)
		var ar = deg_to_rad(float(a))
		var out = Vector2(sin(ar), cos(ar))
		var side = Vector2(cos(ar), -sin(ar))
		for sx in [-1.0, 1.0]:
			var gp = out * (r - 9.0) + side * 17.0 * sx
			KageHall._site(String(v["id"]), {"type": "guard", "pos": KageHall._gp(b, gp.x, gp.y), "face": atan2(-out.x, out.y)})
	b.finish()


## Yugakure karşılama kapısı (anime ref): yeşil iki direk, uçları kalkık kavisli yeşil çatı, tepede bıyık süsleri,
## "ようこそ!! 温泉郷へ / 隠れ湯の里" tabelası, kırmızı fenerler; yanında hediyelik (おみやげ) dükkânı
static func _yu_gate(b: Builder, ang: float, r: float) -> void:
	var a = deg_to_rad(ang)
	var c = Vector2(r * sin(a), r * cos(a))
	var Y = ang + 180.0
	var g = b._ground_off(c.x, c.y, 14.0).x
	var green = Color(0.24, 0.38, 0.3)
	var at = func(lx: float, y: float, ln: float) -> Vector3:
		var o = Builder.rot(lx, ln, Y)
		return Vector3(c.x + o.x, g + y, c.y + o.y)
	for sx in [-1.0, 1.0]:
		b.cyl(at.call(7.5 * sx, 7.0, 0), 1.8, 14.0, green, true, 12)
		b.cyl(at.call(7.5 * sx, 0.6, 0), 2.6, 1.2, Color(0.5, 0.48, 0.44), true, 12)
		b.box(at.call(9.6 * sx, 14.6, 0), Vector3(4.6, 0.9, 2.6), green.darkened(0.2), Y, false, Vector3(0, 0, -16 * sx))   # kalkık uç
		for k in 4:   # bıyık süsleri
			b.box(at.call(8.5 * sx + sx * k * 0.5, 16.6 + k * 0.3, 0), Vector3(0.18, 3.0, 0.18), Color(0.82, 0.7, 0.42), Y, false, Vector3(0, 0, (-28 - k * 12) * sx))
		b.sphere(at.call(5.2 * sx, 8.6, -0.4), Vector3(1.1, 1.5, 1.1), Color(0.86, 0.22, 0.16), 10)   # kırmızı fener
	b.box(at.call(0, 13.6, 0), Vector3(18.0, 1.2, 1.8), green.darkened(0.1), Y, false)
	b.roof(at.call(0, 14.2, 0), Vector3(17.0, 2.0, 3.0), green.darkened(0.25), Y)
	b.box(at.call(0, 10.8, -0.1), Vector3(12.0, 3.8, 0.5), Color(0.42, 0.3, 0.2), Y, false)
	b.kanji(at.call(0, 11.6, -0.45), "ようこそ!! 温泉郷へ", 0.8, Color(0.96, 0.92, 0.8), Y)
	b.kanji(at.call(0, 10.1, -0.45), "隠れ湯の里", 1.4, Color(0.96, 0.92, 0.8), Y)
	# hediyelik dükkânı (kapının iç yanında)
	var sp = at.call(-15.0, 0.0, 10.0)
	b.box(Vector3(sp.x, g + 2.4, sp.z), Vector3(9.0, 4.8, 6.0), Color(0.82, 0.74, 0.62), Y)
	b.roof(Vector3(sp.x, g + 4.8, sp.z), Vector3(10.0, 2.2, 7.0), Color(0.58, 0.3, 0.2), Y)
	var sf = at.call(-15.0, 3.2, 6.9)
	b.box(Vector3(sf.x, sf.y, sf.z), Vector3(5.0, 1.2, 0.2), Color(0.86, 0.2, 0.16), Y, false)
	var st2 = at.call(-15.0, 3.2, 6.75)
	b.kanji(st2, "おみやげ", 0.8, Color(0.98, 0.95, 0.9), Y)


static func _rng(s: int) -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = s
	return r


## Kare kare kurulum için bekleme noktası
static var budget_ms := 8.0     # kare başına kurulum süresi; hızlı seyahat yükleme ekranında 120 ms
static var _ylast := 0
static func _yield() -> void:
	if Time.get_ticks_msec() - _ylast < budget_ms:
		return   # bütçe dolmadı: aynı karede devam (her 12 evde bir kare beklemek binlerce evde dakikalar sürüyordu)
	await Engine.get_main_loop().process_frame
	_ylast = Time.get_ticks_msec()


## Evlerle doldur: merkezde sık, dışa doğru seyrek (anime köyü: yoğun merkez + dağınık dış mahalleler).
## keep_clear: [[x, n, yarıçap]]. En fazla max_houses ev; her 12 evde bir karede bekler.
## Köy dükkânları: [oda, etiket, renk, alias, kanji]
const SHOPS := [["pharmacy", "[F] Gir: Eczane", Color(0.3, 0.6, 0.4), "shop_items", "薬"],
	["weapon_shop", "[F] Gir: Silah Dükkânı", Color(0.2, 0.2, 0.24), "shop_weapons", "武器"],
	["scrolls", "[F] Gir: Parşömenci", Color(0.72, 0.56, 0.22), "shop_scrolls", "巻物"],
	["tailor", "[F] Gir: Terzi (kıyafet, zırh)", Color(0.35, 0.25, 0.45), "tailor", "呉服"],
	["teahouse", "[F] Gir: Dango ve Çay Evi", Color(0.85, 0.45, 0.55), "teahouse", "茶屋"],
	["inn", "[F] Gir: Han (konaklama)", Color(0.25, 0.4, 0.6), "inn", "宿"]]


## Ana caddenin (merkezden ilk kapıya) iki yanına köy mimarisinde dükkânlar: kapısı caddeye bakar, içine girilir.
## Büyük köylerde 6, küçüklerde 4 dükkân. Evlerden önce kurulur (Builder katı alanı: evler üstüne binmez).
static func _shop_row(b: Builder, style: String, rng: RandomNumberGenerator, inner := 40.0) -> void:
	var v = Game.village(b.key)
	if v.is_empty() or b.has_meta("shops"):
		return
	b.set_meta("shops", true)
	var gates: Array = v.get("gates", [])
	var ga = float(gates[0]) if not gates.is_empty() else 180.0
	var r = float(v["r"])
	var dir = Vector2(sin(deg_to_rad(ga)), cos(deg_to_rad(ga)))   # yerel (x doğu, n kuzey)
	var nrm = Vector2(-dir.y, dir.x)
	var list: Array = SHOPS if r >= 700.0 else [SHOPS[0], SHOPS[1], SHOPS[4], SHOPS[5]]
	var d0 = minf(inner + 14.0, r * 0.6)   # merkez meydan / Kage binası dışında, ilk ev halkasında
	# dükkânlar köye dağılır: her biri ayrı bir yönde (kapı caddeleri + aralar), merkezden farklı uzaklıkta;
	# eskiden hepsi ana caddede 24 m arayla iç içe kümeleniyordu (Kiri'nin geniş kuleleri üst üste biniyordu)
	var spread = clampf(r * 0.12, 30.0, 140.0)
	for i in list.size():
		var sh: Array = list[i]
		var sd = 1.0 if i % 2 == 0 else -1.0
		var ang = ga + 360.0 * i / list.size() + rng.randf_range(-12.0, 12.0)
		if i < gates.size():
			ang = float(gates[i]) + rng.randf_range(-6.0, 6.0)   # önce kapı caddelerinin kenarına
		dir = Vector2(sin(deg_to_rad(ang)), cos(deg_to_rad(ang)))
		nrm = Vector2(-dir.y, dir.x)
		var along = d0 + rng.randf_range(0.2, 1.0) * spread
		var q = dir * along + nrm * sd * 18.0
		for tries in 8:
			var wq = b.w(Vector3(q.x, 0, q.y))
			if b.area_free(Vector2(wq.x, wq.z), 12.0):
				break
			q += dir * 22.0   # yer doluysa caddenin ilerisine
		var fd = -nrm * sd   # cadde yönü
		var yaw = rad_to_deg(atan2(-fd.x, -fd.y))
		b.shift_off_road = true
		b.house(q.x, q.y, 15.0, 12.0, 2, yaw, style, rng)
		b.shift_off_road = false
		q = b.placed_xn   # bina yoldan kaydırıldıysa tente/kapı onunla gelir
		var hd = float(b.last_house.get("d", 12.0))
		var front = q + fd * (hd * 0.5 + 0.2)
		var g = b._ground_off(front.x, front.y, 2.0).y
		var col: Color = sh[2]
		# tente + noren + kanji tabela (caddeye dönük)
		var tw = q + fd * (hd * 0.5 + 1.3)
		b.box(Vector3(tw.x, g + 3.3, tw.y), Vector3(7.0, 0.14, 2.4), col.darkened(0.2), yaw, false, Vector3(12, 0, 0))
		for k in 4:
			var o = Builder.rot(-1.5 + k * 1.0, -hd * 0.5 - 0.35, yaw)
			b.box(Vector3(q.x + o.x, g + 2.4, q.y + o.y), Vector3(0.92, 0.9, 0.04), col, yaw, false)
		var so = Builder.rot(0, -hd * 0.5 - 0.3, yaw)
		b.box(Vector3(q.x + so.x, g + 4.3, q.y + so.y), Vector3(2.6, 1.0, 0.12), Color(0.96, 0.93, 0.85), yaw, false)
		b.kanji(Vector3(q.x + so.x * 1.01, g + 4.3, q.y + so.y * 1.01), String(sh[4]), 0.8, Color(0.12, 0.1, 0.1), yaw)
		var door = q + fd * (hd * 0.5 + 1.4)
		b.interact(Vector3(door.x, g, door.y), 3.0, "enter", String(sh[1]), {"room": sh[0], "alias": sh[3], "vid": v["id"], "out": b.w(Vector3(door.x, g, door.y))})


static func _fill(b: Builder, r: float, inner: float, spacing: float, style: String, rng: RandomNumberGenerator, keep_clear: Array = [], max_houses := 420, big := 1.0) -> void:
	_shop_row(b, style, rng, inner)
	# Bitişik nizam halkalar: evler halka boyunca gerçek genişlikleriyle yan yana (0.4-1.2 m ara), 5-7 evde bir dar ara sokak;
	# halkalar arası = ev derinliği + 2.5 m arka sokak (sırt sırta). Eskiden sabit aralıklı tek tek evler ayrık duruyordu.
	var count = 0
	var ring = inner + 8.0
	var rows_since = 0
	max_houses *= 4   # bitişik nizam aynı alana ~4 kat ev sığdırır (sınır eskiden ayrık dizilime göreydi)
	while ring < r - 8.0 and count < max_houses:
		var hd = rng.randf_range(11, 15) * big
		var circ = TAU * ring
		var t = rng.randf() * 8.0
		var run = 0
		var alley_at = rng.randi_range(5, 7)
		while t < circ - 6.0 and count < max_houses:
			var hw = rng.randf_range(12, 19) * big
			var a = (t + hw * 0.5) / ring
			var px = ring * sin(a)
			var pn = ring * cos(a)
			var placed = false
			var ok = true
			for k in keep_clear:
				if Vector2(px - k[0], pn - k[1]).length() < k[2]:
					ok = false
					break
			if ok and not _on_road(b, px, pn, maxf(hw, hd) * 0.55 + 1.0):
				var wq = b.w(Vector3(px, 0, pn))
				if b.area_free(Vector2(wq.x, wq.z), minf(hw, hd) * 0.4):
					var yaw = rad_to_deg(a) + 180.0
					b.house(px, pn, hw, hd, [2, 2, 3, 3, 4, 5].pick_random(), yaw, style, rng)
					count += 1
					placed = true
					if count % 12 == 0:
						await _yield()
						if not is_instance_valid(b.root):
							return
			t += (hw + rng.randf_range(0.4, 1.2)) if placed else 5.0
			run += 1
			if run >= alley_at:
				t += rng.randf_range(3.0, 4.5)   # dar ara sokak
				run = 0
				alley_at = rng.randi_range(5, 7)
		rows_since += 1
		# iki sıra sırt sırta, sonra bir arka sokak (daha geniş)
		ring += hd + (2.0 if rows_since % 2 == 1 else 6.0)


## Ev yerleşimi yolun/caddenin üstüne düşmesin (yerel x, n; pay = evin yarı boyu + kaldırım)
static func _on_road(b: Builder, px: float, pn: float, pad: float) -> bool:
	var q = Vector2(b.origin.x + px, -b.origin.z + pn)
	for e in Game.road_segments_near(q, pad + 12.0):
		var rd: Dictionary = Game.roads[e.x]
		var pa: Vector2 = rd["pts"][e.y]
		var pb: Vector2 = rd["pts"][e.y + 1]
		var half = 4.5 if rd["kind"] == "street" else 4.0
		if Geometry2D.get_closest_point_to_segment(q, pa, pb).distance_to(q) < pad + half:
			return true
	return false


## Dev kaya halkası (krater/uçurum duvarı): boşluklar kapı açılarında
static func _rock_ring(b: Builder, r: float, hmin: float, hmax: float, thick: float, col: Color, gates: Array, rng: RandomNumberGenerator, step := 4.0, gap := 8.0) -> void:
	var a = 0.0
	while a < 360.0:
		var open = false
		for ga in gates:
			if absf(fmod(a - float(ga) + 540.0, 360.0) - 180.0) <= gap:
				open = true
		if not open:
			var rad = deg_to_rad(a)
			var hh = rng.randf_range(hmin, hmax)
			var L = TAU * r * step / 360.0 + 8.0
			b.box(Vector3(r * sin(rad), hh * 0.5 - 6, r * cos(rad)), Vector3(L, hh, thick * rng.randf_range(0.85, 1.15)), col.darkened(rng.randf_range(0.0, 0.15)), a)
			# tabaka çizgileri / üst kenar
			b.box(Vector3((r - thick * 0.3) * sin(rad), hh - 6 + 1.5, (r - thick * 0.3) * cos(rad)), Vector3(L * 0.9, 3.0, thick * 0.5), col.lightened(0.06), a)   # üst kenar katı: sur tepesinde gömülme
		a += step


# ------------------------------------------------------------------ uzak siluetler (köy kurulmamışken ufukta görünür)
static func far_silhouette(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Silhouet_" + String(v["id"]))
	b.view_dist = 30000.0
	var r = float(v["r"])
	var rng = _rng(hash(v["id"]) + 5)
	match v["id"]:
		"suna":
			for k in 24:
				var a = TAU * k / 24
				b.box(Vector3(r * 0.95 * sin(a), 60, r * 0.95 * cos(a)), Vector3(TAU * r / 24 + 20, 140, 100), Color(0.78, 0.62, 0.42), rad_to_deg(a), false)
			b.dome(Vector3(0, 0, 0), 110, 70, Color(0.86, 0.74, 0.55), 12)
		"kumo":
			for k in 26:
				var a = rng.randf() * TAU
				var rr = rng.randf_range(80, r * 0.9)
				var h = rng.randf_range(120, 300)
				if k % 5 == 1 or k % 5 == 3:
					b.cone(Vector3(rr * sin(a), h * 0.675, rr * cos(a)), rng.randf_range(50, 90), h * 1.35, Color(0.6, 0.57, 0.52), 8)
				else:
					b.cyl(Vector3(rr * sin(a), h * 0.5, rr * cos(a)), rng.randf_range(40, 80), h, Color(0.6, 0.57, 0.52), false, 8)
			b.cyl(Vector3(0, 130, 0), 70, 260, Color(0.58, 0.55, 0.5), false, 10)
			b.sphere(Vector3(0, 312, 0), Vector3(88, 104, 88), Color(0.27, 0.46, 0.64), 10)   # Raikage "ampul" binası
		"iwa":
			for k in 18:
				var a = rng.randf() * TAU
				var rr = rng.randf_range(80, r * 0.9)
				var h = rng.randf_range(70, 160)
				b.box(Vector3(rr * sin(a), h * 0.5, rr * cos(a)), Vector3(50, h, 50), Color(0.56, 0.56, 0.57), rng.randf() * 90, false)
			b.cyl(Vector3(0, 90, 0), 56, 120, Color(0.58, 0.58, 0.6), false, 10)
			b.cone(Vector3(0, 150, 0), 46, 22, Color(0.58, 0.58, 0.6), 10)
			for k in 24:   # çevredeki gri dağ duvarı
				var a = TAU * k / 24.0
				var mh = rng.randf_range(240, 440)
				b.cone(Vector3(r * 1.3 * sin(a), mh * 0.5 - 10.0, r * 1.3 * cos(a)), 180, mh, Color(0.54, 0.54, 0.56), 8)
		"ame":
			for k in 16:
				var a = rng.randf() * TAU
				var rr = rng.randf_range(60, r * 0.85)
				var h = rng.randf_range(100, 220)
				b.box(Vector3(rr * sin(a), h * 0.5, rr * cos(a)), Vector3(30, h, 30), Color(0.38, 0.4, 0.43), 0, false)
			b.box(Vector3(0, 150, 0), Vector3(50, 300, 50), Color(0.34, 0.36, 0.4), 0, false)
		"taki":
			b.cyl(Vector3(0, 130, 0), 70, 260, Color(0.4, 0.28, 0.18), false, 10)
			b.sphere(Vector3(0, 270, 0), Vector3(300, 110, 300), Color(0.22, 0.48, 0.24), 10)
		"kiri":
			for k in 20:
				var a = TAU * k / 20
				b.box(Vector3(r * 0.95 * sin(a), 50, r * 0.95 * cos(a)), Vector3(TAU * r / 20 + 20, 110, 80), Color(0.55, 0.6, 0.62), rad_to_deg(a), false)
			b.cyl(Vector3(0, 25, 0), 94, 50, Color(0.68, 0.6, 0.58), false, 12)
			for k in 22:   # sisli sivri dağ fonu
				var a = TAU * k / 22.0
				var mh = rng.randf_range(220, 460)
				b.cone(Vector3(r * 1.45 * sin(a), mh * 0.5 - 10.0, r * 1.45 * cos(a)), rng.randf_range(120, 220), mh, Color(0.6, 0.64, 0.66), 8)
		"tetsu":
			b.box(Vector3(0, 40, 0), Vector3(90, 80, 90), Color(0.9, 0.9, 0.9), 0, false)
		_:
			b.cyl(Vector3(0, 20, 0), r * 0.6, 30, Color(0.55, 0.45, 0.35), false, 10)
	b.finish()
	# köy kurulunca (yakında) siluet gizlensin
	for c in b.root.get_children():
		if c is GeometryInstance3D:
			c.visibility_range_begin = VILLAGE_BUILD_R + r * 0.5
			c.visibility_range_begin_margin = 300.0
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ------------------------------------------------------------------ Sunagakure: katmanlı kaya krateri içinde kerpiç kubbe şehir
static func suna(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Suna")
	b.view_dist = 2500.0   # köy içinden/surdan tümü görünür; uzakta siluet devralır (6000 m'de 14M üçgen hep çiziliyordu)
	var rng = _rng(2)
	var sand = Color(0.87, 0.74, 0.54)
	var r = float(v["r"])
	await _crag_ring(b, r * 0.97, 120, 175, 120, Color(0.78, 0.6, 0.4), v.get("gates", []), rng, 3.6, 5.0)
	# Kazekage binası (anime ref): yuvarlak alçak kaide duvarı içinde şişkin "soğan" gövde; gövdeyi saran çıkıntılı bantlarda
	# yuvarlak köşeli yarık pencereler, önde çerçeveli 風 arması ve yanında dikey levha, tepede iki küçük başlık
	b.cyl(Vector3(0, 2, 0), 140, 4, sand.darkened(0.1), true, 40)
	b.cyl(Vector3(0, 6, 0), 116, 8, sand.darkened(0.04), true, 40)   # kaide: kapı noktası (-62) dışarıda kalsın
	b.sphere(Vector3(0, 52, 0), Vector3(114, 96, 114), sand.lightened(0.06), 36, true)
	for f in [-0.32, 0.02, 0.36, 0.62]:
		var ry = 57.0 * sqrt(maxf(0.0, 1.0 - f * f))
		var by = 52.0 + f * 48.0
		b.cyl(Vector3(0, by, 0), ry * 2.0 + 2.4, 2.2, sand.darkened(0.14), false, 36)
		var cnt = int(ry * 0.55)
		for k in cnt:
			var wa = 360.0 * k / cnt
			if absf(wrapf(wa - 180.0, -180.0, 180.0)) < 16.0 and f > -0.1 and f < 0.4:
				continue   # armanın önü boş
			var o = Builder.rot(0, ry + 1.3, wa)
			b.box(Vector3(o.x, by + 3.0, o.y), Vector3(2.6, 3.2, 0.4), VillageStyles.DARK, wa, false)
	for sx in [-1.0, 1.0]:
		b.cyl(Vector3(sx * 9.0, 101, 4.0), 6.0, 4.0, sand.darkened(0.04), false, 14)
		b.dome(Vector3(sx * 9.0, 103, 4.0), 6.0, 2.0, sand, 12)
	b.disc(Vector3(0, 56, -57.2), 30, 1.0, sand.darkened(0.2), 0, 28)
	b.disc(Vector3(0, 56, -57.8), 26, 0.6, Color(0.82, 0.8, 0.74), 0, 28)
	b.kanji(Vector3(0, 56, -58.3), "風", 19.0, Color(0.5, 0.16, 0.1), 0)
	b.box(Vector3(16.0, 56, -55.2), Vector3(2.2, 14.0, 1.0), sand.darkened(0.16), 0, false)
	b.box(Vector3(0, 3.5, -58), Vector3(12, 7, 6), VillageStyles.DARK, 0, false)
	# giriş revakı: kubbeli kemer, iki sütun, yeşil perde
	for sx in [-1.0, 1.0]:
		b.cyl(Vector3(sx * 8.0, 10.0, -62.0), 2.4, 12.0, sand.lightened(0.06), true, 12)
		b.cyl(Vector3(sx * 8.0, 16.4, -62.0), 3.0, 0.8, sand.darkened(0.15), false, 12)
	b.box(Vector3(0, 17.6, -60.0), Vector3(20.0, 2.0, 6.0), sand.darkened(0.06), 0, false)
	b.dome(Vector3(0, 18.6, -60.0), 12.0, 4.0, sand.lightened(0.1), 20)
	b.box(Vector3(0, 9.0, -58.6), Vector3(9.0, 9.0, 0.3), Color(0.16, 0.45, 0.38), 0, false)
	b.kanji(Vector3(0, 10.5, -58.9), "風影", 2.4, Color(0.98, 0.95, 0.88), 0)
	KageHall.door(b, 0, -62.0, 4.0, "suna", "[F] Gir: Kazekage Ofisi (Kazekage ile görüş, görevler)", 6.0)
	KageHall.plaza(b, {"vid": "suna", "front": -70.0, "hw": 34.0, "depth": 48.0, "climate": "desert", "stone": Color(0.86, 0.74, 0.56),
		"trim": Color(0.66, 0.52, 0.36), "acc": Color(0.16, 0.45, 0.38), "gate": Color(0.62, 0.48, 0.32), "kanji": "風",
		"terrace_h": 4.0, "terrace_w": 24.0, "terrace_d": 0.6})
	await _yield()
	# kubbeli kuleler halkası + aralarında yüksek geçitler
	var towers = []
	for k in 10:
		var a = TAU * k / 10
		var o = Vector2(sin(a), cos(a)) * 210
		var h = rng.randf_range(34, 52)
		b.cyl(Vector3(o.x, h * 0.5, o.y), 38, h, sand.darkened(0.05), true, 22)
		b.cyl(Vector3(o.x, h + 0.6, o.y), 40, 1.2, sand.darkened(0.15), false, 22)
		b.dome(Vector3(o.x, h + 1.2, o.y), 36, 14, sand, 22)
		for f in int(h / 9):
			for j in 8:
				var aa = 360.0 * j / 8.0 + f * 22.0
				var oo = Builder.rot(0, 19.1, aa)
				b.disc(Vector3(o.x + oo.x, 6 + f * 9, o.y + oo.y), 2.0, 0.3, VillageStyles.DARK, aa + 180.0, 10)
		towers.append(Vector3(o.x, h * 0.6, o.y))
	for k in 10:
		var p0: Vector3 = towers[k]
		var p1: Vector3 = towers[(k + 1) % 10]
		var y = minf(p0.y, p1.y)
		var d = Vector3(p1.x - p0.x, 0, p1.z - p0.z)
		b.box(Vector3((p0.x + p1.x) * 0.5, y, (p0.z + p1.z) * 0.5), Vector3(4.5, 1.2, d.length() - 36), sand.darkened(0.08), rad_to_deg(atan2(d.x, d.z)))
		# köprü korkulukları: iki yanda alçak duvar (eskiden yürüyüş yolunun üstünü kaplayan 1.6 m'lik çarpışmasız blok vardı -> köprüde gömülüyordun)
		var sd = Vector3(d.z, 0, -d.x).normalized()
		for sx in [-1.0, 1.0]:
			var rp = Vector3((p0.x + p1.x) * 0.5, y + 1.1, (p0.z + p1.z) * 0.5) + sd * sx * 2.1
			b.box(rp, Vector3(0.4, 1.0, d.length() - 36), sand.darkened(0.02), rad_to_deg(atan2(d.x, d.z)))
	await _yield()
	# pazar: tenteli tezgâhlar meydan çevresinde
	for k in 16:
		var a = 360.0 * k / 16.0
		if absf(a - 180.0) < 40.0:
			continue  # Kazekage meydanı
		var o = Builder.rot(0, 95, a)
		var aw = [Color(0.75, 0.25, 0.2), Color(0.25, 0.45, 0.6), Color(0.85, 0.65, 0.25), Color(0.55, 0.35, 0.55)][k % 4]
		b.box(Vector3(o.x, 0.6, o.y), Vector3(5, 1.2, 2.4), Color(0.55, 0.4, 0.26), a)
		b.box(Vector3(o.x, 3.4, o.y), Vector3(6, 0.15, 4), aw, a, false, Vector3(-10, 0, 0))
		for sx in [-1.0, 1.0]:
			var po = Builder.rot(2.6 * sx, 0, a)
			b.box(Vector3(o.x + po.x, 1.7, o.y + po.y), Vector3(0.15, 3.4, 0.15), VillageStyles.WOOD, a, false)
	b.interact(Vector3(0, 0, 95), 6, "shop_items", "[F] Suna Pazarı")
	# kum yığıntıları (duvar diplerinde, sokaklarda)
	for k in 70:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(r * 0.3, r * 0.93)
		b.dome(Vector3(rr * sin(a), -0.2, rr * cos(a)), rng.randf_range(10, 30), rng.randf_range(0.8, 2.5), Color(0.9, 0.78, 0.56), 12)
	await _fill(b, r * 0.88, 140, 28, "suna", rng, _site_clear(v), 1900)
	await _streets(b, v, "suna", rng)
	b.finish()


## Akademi yerleşkesinin alanı (köy evleri buraya kurulmaz): [x, n, yarıçap] köy merkezine göre
static func _site_clear(v: Dictionary) -> Array:
	# önemli yapıların her biri için boş alan: [[x, n, yarıçap], ...] köy merkezine göre
	var out = []
	var sites: Dictionary = BuildVillageStory._sites(v)
	for k in sites:
		var s: Vector2 = sites[k]
		out.append([s.x - float(v["x"]), s.y - float(v["y"]), float(BuildVillageStory.CLEAR.get(k, 40.0))])
	return out


## Kapılardan merkeze uzanan ana caddeler: fenerler, ağaçlar, tezgâhlar, bayraklar (köyün havasına göre)
static func _streets(b: Builder, v: Dictionary, style: String, rng: RandomNumberGenerator) -> void:
	var r = float(v["r"])
	var gates: Array = v.get("gates", [])
	if gates.is_empty():
		gates = [180.0, 0.0, 90.0, 270.0]
	var flag = {"suna": Color(0.55, 0.3, 0.2), "kiri": Color(0.25, 0.4, 0.6), "kumo": Color(0.85, 0.85, 0.82), "iwa": Color(0.6, 0.25, 0.18), "ame": Color(0.35, 0.36, 0.42)}.get(style, Color(0.6, 0.2, 0.2))
	var count = 0
	for ga in gates:
		var a = float(ga)
		var d = 140.0
		while d < r * 0.9:
			for sx in [-1.0, 1.0]:
				var o = Builder.rot(9.0 * sx, d, a)
				var g = b._ground_off(o.x, o.y, 1.0).x
				match int(d / 40.0) % 3:
					0:
						BuildFeatures._build(b, {"t": "lantern", "x": o.x, "y": o.y, "g": g, "yaw": a}, rng)
					1:
						if style == "suna" or style == "ame":
							b.cyl(Vector3(o.x, g + 2.5, o.y), 0.25, 5.0, Color(0.35, 0.3, 0.25), false, 6)
							b.box(Vector3(o.x, g + 3.8, o.y), Vector3(0.05, 2.4, 1.4), flag, a + 90.0, false)
						else:
							b.tree(o.x, o.y, rng.randf_range(0.8, 1.2), rng, g)
					2:
						b.box(Vector3(o.x, g + 0.5, o.y), Vector3(1.6, 1.0, 1.0), Color(0.5, 0.38, 0.25), a + rng.randf() * 30.0, false)
			count += 1
			if count % 20 == 0:
				await _yield()
				if not is_instance_valid(b.root):
					return
			d += 40.0


## Katmanlı kaya sütunlarından krater/uçurum duvarı (kapı açılarında boşluk)
static func _crag_ring(b: Builder, r: float, hmin: float, hmax: float, thick: float, col: Color, gates: Array, rng: RandomNumberGenerator, step := 4.0, gap := 8.0) -> void:
	var a = 0.0
	var i = 0
	while a < 360.0:
		var open = false
		for ga in gates:
			if absf(fmod(a - float(ga) + 540.0, 360.0) - 180.0) <= gap:
				open = true
		if not open:
			var rad = deg_to_rad(a)
			var rr = r + rng.randf_range(-thick * 0.15, thick * 0.15)
			var hh = rng.randf_range(hmin, hmax)
			var c = col.darkened(rng.randf_range(0.0, 0.14))
			var cx = rr * sin(rad)
			var cn = rr * cos(rad)
			var gl = minf(b._ground_off(cx, cn, thick * 0.5).x, 0.0) - 12.0  # dış yamaç alçaksa kaya oraya kadar insin
			b.crag(Vector3(cx, gl, cn), thick * rng.randf_range(0.95, 1.3), hh - 8.0 - gl, c, 100 + i, true, rng.randf() * 360.0)
			# önde alçak kayalar (taban kırığı)
			if i % 2 == 0:
				var r2 = rr - thick * 0.55
				b.crag(Vector3(r2 * sin(rad), -20, r2 * cos(rad)), thick * 0.55, hh * rng.randf_range(0.25, 0.45) + 16, c.lightened(0.05), i + 7, false, rng.randf() * 360.0)
			i += 1
			if i % 12 == 0:
				await _yield()
				if not is_instance_valid(b.root):
					return
		a += step


# ------------------------------------------------------------------ Kirigakure: göl kıyısında sisli kule şehri, kanallar, iskeleler
static func kiri(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kiri")
	b.view_dist = 6000.0
	var rng = _rng(3)
	var r = float(v["r"])
	await _crag_ring(b, r * 0.97, 70, 130, 90, Color(0.5, 0.56, 0.58), v.get("gates", []), rng, 4.0, 5.0)
	# kuzeyde göl + iskeleler
	VillageStyles.water(b, Vector3(0, -0.4, r * 0.55), Vector2(r * 1.5, r * 0.7))
	for k in 9:
		var x = -r * 0.55 + k * r * 0.14
		b.box(Vector3(x, 0.4, r * 0.24), Vector3(5, 0.5, 70), Color(0.42, 0.33, 0.24), 0)
		for j in 6:
			for sx in [-1.0, 1.0]:
				b.cyl(Vector3(x + 2.3 * sx, -1.0, r * 0.24 - 30 + j * 12), 0.6, 3.0, Color(0.3, 0.24, 0.18), false, 6)
		if k % 3 == 1:
			b.box(Vector3(x + 5, 0.0, r * 0.24 + 25), Vector3(3.2, 1.0, 9), Color(0.5, 0.36, 0.24), 0, false)  # tekne
	# Mizukage binası (anime/manga ref): geniş alçak silindir gövde, üstte pencereli kızıl-kahve taç bandı, düz bahçe çatı
	# (çalı/ağaç), önde taş kaide duvarına açılmış büyük kemerli kapı
	var kc = Color(0.74, 0.66, 0.64)
	var crown = Color(0.5, 0.27, 0.27)
	b.cyl(Vector3(0, 19, 0), 90, 38, kc, true, 36)
	for f in 3:
		b.cyl(Vector3(0, 8 + f * 10, 0), 90.6, 0.5, kc.darkened(0.16), false, 36)
	b.cyl(Vector3(0, 44, 0), 94, 12, crown, true, 36)
	b.cyl(Vector3(0, 38.2, 0), 96, 0.8, crown.darkened(0.25), false, 36)
	b.cyl(Vector3(0, 50.3, 0), 96, 0.8, crown.darkened(0.25), false, 36)
	for k in 36:   # taç bandında pencere sırası
		var wa = 360.0 * k / 36.0
		var wo = Builder.rot(0, 47.1, wa)
		b.box(Vector3(wo.x, 44, wo.y), Vector3(3.6, 3.2, 0.3), Color(0.16, 0.12, 0.13), wa, false)
	for k in 4:   # gövdede dikey pencere sütunları
		for f in 3:
			var wa = -60.0 + k * 40.0 + 180.0
			var wo = Builder.rot(0, 45.2, wa)
			b.box(Vector3(wo.x, 12 + f * 9, wo.y), Vector3(2.4, 3.6, 0.3), Color(0.2, 0.18, 0.2), wa, false)
	b.cyl(Vector3(0, 50.6, 0), 90, 0.6, Color(0.36, 0.42, 0.3), false, 36)   # bahçe toprağı
	for k in 16:   # çatı bahçesi
		var ga = rng.randf() * 360.0
		var go = Builder.rot(0, rng.randf_range(0, 38), ga)
		b.sphere(Vector3(go.x, 53 + rng.randf_range(0, 2), go.y), Vector3(rng.randf_range(10, 18), rng.randf_range(6, 10), rng.randf_range(10, 18)), Color(0.28, 0.46, 0.27).lightened(rng.randf() * 0.12), 8)
	b.disc(Vector3(0, 30, -45.3), 14, 0.6, Color(0.92, 0.94, 0.96), 0, 24)
	b.kanji(Vector3(0, 30, -45.8), "水", 11.0, Color(0.15, 0.32, 0.55), 0)
	# kaide duvarı + büyük kemerli kapı
	var wallc = kc.darkened(0.08)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(sx * 16.0, 7.0, -47.0), Vector3(14.0, 14.0, 6.0), wallc, 0)
	b.box(Vector3(0, 15.5, -47.0), Vector3(46.0, 3.0, 6.4), wallc.darkened(0.1), 0, false)
	b.disc(Vector3(0, 8.2, -47.2), 18.0, 6.0, wallc, 0, 24)              # kemer taşı (yarım disk görünür)
	b.box(Vector3(0, 4.1, -48.4), Vector3(18.0, 8.2, 4.0), Color(0.12, 0.1, 0.11), 0, false)   # kemer boşluğu (karanlık)
	b.disc(Vector3(0, 8.2, -48.5), 16.6, 4.2, Color(0.12, 0.1, 0.11), 0, 24)
	b.box(Vector3(0, -1.0, -47.2), Vector3(18.4, 2.0, 6.6), Color(0.62, 0.6, 0.58), 0, false)   # kemer altı yolu (yarım diskin alt yarısını gizler)
	b.kanji(Vector3(0, 19.2, -50.3), "水影", 1.6, Color(0.95, 0.97, 1.0), 0)
	KageHall.door(b, 0, -50.0, 0.6, "kiri", "[F] Gir: Mizukage Ofisi (Mizukage ile görüş, görevler)", 6.0)
	KageHall.plaza(b, {"vid": "kiri", "front": -52.0, "hw": 36.0, "depth": 34.0, "climate": "mist", "stone": Color(0.68, 0.72, 0.74),
		"trim": Color(0.46, 0.5, 0.54), "acc": Color(0.18, 0.38, 0.72), "gate": Color(0.3, 0.36, 0.42), "kanji": "水", "terrace_h": 0.6, "terrace_w": 20.0, "terrace_d": 3.0})
	# köyü saran sisli sivri dağ sırası (ref: arka planda sıra sıra sivri zirveler)
	var peaks_mist = []
	for k in 46:
		var pa = 360.0 * k / 46.0 + rng.randf_range(-3, 3)
		var prr = r * rng.randf_range(1.25, 1.7)
		var po = Builder.rot(0, prr, pa)
		var ph = rng.randf_range(220, 480)
		var pd = ph * rng.randf_range(0.42, 0.6)
		b.crag(Vector3(po.x, -10, po.y), pd, ph, Color(0.6, 0.64, 0.66).darkened(rng.randf() * 0.12), 200 + k, false, rng.randf() * 360.0)
		for j in 3:
			var mo = Builder.rot(rng.randf_range(-pd, pd) * 0.5, prr - pd * 0.4, pa)
			peaks_mist.append(Vector3(mo.x, ph * rng.randf_range(0.2, 0.45), mo.y))
	VillageStyles.mist_points(b, peaks_mist, 90.0, rng, 0.55)
	await _yield()
	# yüksek boru kuleleri
	for k in 16:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(90, r * 0.7)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		if pn > r * 0.2:
			continue
		VillageStyles.kiri_house(b, px, pn, rng.randf_range(14, 22), 14, rng.randi_range(5, 10), rng.randf() * 360.0, rng)
	# kanallar (radyal) + küçük köprüler
	for k in 6:
		var a = k * 60.0 + 30.0
		var o = Builder.rot(0, r * 0.4, a)
		VillageStyles.water(b, Vector3(o.x, 0.15, o.y), Vector2(7, r * 0.6), a)
		var bo = Builder.rot(0, r * 0.3, a)
		b.box(Vector3(bo.x, 0.8, bo.y), Vector3(10, 0.5, 4), VillageStyles.WOOD, a + 90.0)
	VillageStyles.mist(b, 90, 0, r * 0.95, 3, 28, 40, rng, 0.3)
	await _fill(b, r * 0.85, 60, 26, "kiri", rng, [[0, r * 0.55, r * 0.4], [0, -70, 40]] + _site_clear(v), 1600)
	await _streets(b, v, "kiri", rng)
	b.finish()


# ------------------------------------------------------------------ Kumogakure: bulutlar arasında katmanlı kaya sütunları, tepelerinde şehir
static func kumo(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kumo")
	b.view_dist = 6000.0
	var rng = _rng(4)
	var rock = Color(0.6, 0.57, 0.52)   # ref: ılık gri-kahve kaya
	var mist_pts = []
	var r = float(v["r"])
	var pillars = []
	for k in 40:
		var a = TAU * (k + rng.randf_range(-0.3, 0.3)) / 40.0 * 3.0
		var rr = lerpf(130, r * 0.9, sqrt(rng.randf()))
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var d = rng.randf_range(55, 100)
		var h = rng.randf_range(110, 290)
		var c = rock.darkened(rng.randf_range(0.0, 0.14))
		# ref (anime Kumo panoraması): köyü saran kayaların çoğu ucu incelen sivri iğne; bir kısmı üstü evli mesa
		var spire = k % 5 == 1 or k % 5 == 3
		if spire:
			var H = h * 1.35
			b.crag(Vector3(px, -6, pn), d, H + 6, c, 200 + k, true, rng.randf() * 360.0)
			for j in 4:   # yamaçlara tutunan yeşillik
				var gy = H * rng.randf_range(0.25, 0.8)
				var gr = d * lerpf(0.5, 0.025, pow(gy / H, 0.85)) * 0.92
				var go = Builder.rot(0, gr, rng.randf() * 360.0)
				b.sphere(Vector3(px + go.x, gy, pn + go.y), Vector3(d * 0.22, d * 0.1, d * 0.22), Color(0.3, 0.5, 0.26).darkened(rng.randf() * 0.15), 8)
			var my = H * rng.randf_range(0.3, 0.55)
			var mr = d * lerpf(0.5, 0.025, pow(my / H, 0.85))
			for j in 6:
				var mo = Builder.rot(0, mr + 6.0, j * 60.0 + rng.randf() * 30.0)
				mist_pts.append(Vector3(px + mo.x, my + rng.randf_range(-6, 6), pn + mo.y))
			pillars.append([px, pn, d * 0.75, H * 0.5])
			if k % 4 == 3:
				await _yield()
				if not is_instance_valid(b.root):
					return
			continue
		b.crag(Vector3(px, -6, pn), d, h + 6, c, 100 + k, true, rng.randf() * 360.0)
		for j in 5:   # mesa belini saran bulut kuşağı
			var mo = Builder.rot(0, d * 0.48 + 6.0, j * 72.0 + rng.randf() * 30.0)
			mist_pts.append(Vector3(px + mo.x, h * rng.randf_range(0.35, 0.55), pn + mo.y))
		# yan kayalık çıkıntılar
		for j in 2:
			var oa = rng.randf() * 360.0
			var oo = Builder.rot(0, d * 0.35, oa)
			b.crag(Vector3(px + oo.x, -6, pn + oo.y), d * 0.45, h * rng.randf_range(0.3, 0.6), c.lightened(0.04), k + 20 + j, false, oa)
		var top_r = d * 0.34   # mesa tepe yarıçapı
		# tepe: taş platform + 2-4 beyaz kubbeli kule kümesi
		b.cyl(Vector3(px, h - 0.4, pn), top_r * 2.1, 1.6, Color(0.8, 0.8, 0.77), true, 18)
		var nh = rng.randi_range(2, 4)
		for j in nh:
			var ja = 360.0 * j / nh + rng.randf_range(-20, 20)
			var jo = Builder.rot(0, top_r * 0.5 if nh > 1 else 0.0, ja)
			var hd = top_r * rng.randf_range(0.55, 0.8)
			var yo = b.yoff
			b.yoff = h + 0.4
			VillageStyles.kumo_house(b, px + jo.x, pn + jo.y, hd, hd, rng.randi_range(2, 5), ja, rng)
			b.yoff = yo
		# yamaca tutunan ev (konsol platform + payandalar)
		if k % 2 == 0:
			var sa = rng.randf() * 360.0
			var sy = h * rng.randf_range(0.45, 0.75)
			var sr = d * (0.5 - 0.14 * pow(sy / h, 1.3)) + 6.0
			var so = Builder.rot(0, sr, sa)
			b.cyl(Vector3(px + so.x, sy, pn + so.y), 14, 1.2, Color(0.75, 0.75, 0.72), true, 12)
			for sx in [-1.0, 1.0]:
				var po = Builder.rot(4.0 * sx, sr - 4.0, sa)
				b.box(Vector3(px + po.x, sy - 4, pn + po.y), Vector3(0.6, 8, 0.6), VillageStyles.WOOD, sa, false, Vector3(30, 0, 0))
			var yo2 = b.yoff
			b.yoff = sy + 0.6
			VillageStyles.kumo_house(b, px + so.x, pn + so.y, 9, 9, 2, sa, rng)
			b.yoff = yo2
		pillars.append([px, pn, d, h])
		if k % 4 == 3:
			await _yield()
			if not is_instance_valid(b.root):
				return
	# yakın sütunlar arası asma köprüler
	for i in pillars.size():
		var p0: Array = pillars[i]
		for j in range(i + 1, pillars.size()):
			var p1: Array = pillars[j]
			var L = Vector2(p1[0] - p0[0], p1[1] - p0[1]).length()
			if L < 170 and L > 60:
				var y = minf(p0[3], p1[3]) * 0.92
				var dir = Vector3(p1[0] - p0[0], 0, p1[1] - p0[1]).normalized()
				var a0 = Vector3(p0[0], y, p0[1]) + dir * (p0[2] * 0.3)
				var a1 = Vector3(p1[0], y, p1[1]) - dir * (p1[2] * 0.3)
				VillageStyles.rope_bridge(b, a0, a1, 3.0, 4.0)
				break
	await _yield()
	# Raikage kulesi: en yüksek sütun, çevresinde sarmal merdiven, tepede beyaz kule + "雷"
	b.crag(Vector3(0, -6, 0), 120, 266, rock.darkened(0.06), 115, true, 0)
	for s in 140:
		var t = float(s) / 140.0
		var y = t * 250.0
		var rr = 60.0 * (1.0 - 0.28 * pow(t, 1.3)) + 4.0
		var a = t * 360.0 * 4.0
		var o = Builder.rot(0, rr, a)
		b.box(Vector3(o.x, y, o.y), Vector3(6, 0.6, 3.2), Color(0.72, 0.7, 0.66), a + 90.0)
	b.cyl(Vector3(0, 260.5, 0), 70, 2, Color(0.85, 0.85, 0.82), true, 24)
	# Raikage binası (anime ref): zirveye oturan dev mavi "ampul" gövde, sarı balkon bantları, cam pencere kuşağı,
	# önde sarı çerçeveli 雷 arması; üstünde yeşillikli kaya tepesi ve ince kule ucu
	var bc = 312.0
	var bR = 44.0
	var bH = 52.0
	var blue_b = Color(0.27, 0.46, 0.64)
	var yel = Color(0.93, 0.76, 0.18)
	b.sphere(Vector3(0, bc, 0), Vector3(bR * 2.0, bH * 2.0, bR * 2.0), blue_b, 28, true)
	for f in [-0.55, -0.12, 0.3, 0.62]:   # yatay sarı bantlar (balkon kenarı)
		var ry = bR * sqrt(maxf(0.0, 1.0 - f * f))
		b.cyl(Vector3(0, bc + f * bH, 0), ry * 2.0 + 2.2, 1.6 if f != -0.12 else 2.6, yel, false, 28)
	for k in 28:   # cam kuşağı: iki bant arası pencereler + dikmeler
		var a = 360.0 * k / 28.0
		for row in 3:
			var fy = 0.0 + row * 0.1
			var ry = bR * sqrt(1.0 - fy * fy)
			var o = Builder.rot(0, ry + 0.3, a)
			b.box(Vector3(o.x, bc + fy * bH + 3.0, o.y), Vector3(ry * TAU / 28.0 * 0.8, 4.6, 0.4), Color(0.55, 0.78, 0.86), a, false)
		var mo = Builder.rot(0, bR + 0.6, a + 180.0 / 28.0)
		b.box(Vector3(mo.x, bc + 9.0, mo.y), Vector3(0.6, 18.0, 0.6), yel.darkened(0.15), a, false)
	# arma: sarı çerçeve + beyaz disk + mavi 雷 (gövdenin önü, güneye bakar)
	var ez = -bR * sqrt(1.0 - 0.12 * 0.12) - 1.2
	b.disc(Vector3(0, bc - 0.12 * bH, ez + 0.4), 19, 1.0, yel, 0, 24)
	b.disc(Vector3(0, bc - 0.12 * bH, ez), 15, 0.6, Color(0.96, 0.96, 0.94), 0, 24)
	b.kanji(Vector3(0, bc - 0.12 * bH, ez - 0.45), "雷", 10.0, Color(0.12, 0.14, 0.2), 0)
	# tepe: kaya başlık + yeşillik + ince kule ucu (çatılı)
	b.crag(Vector3(0, bc + bH * 0.82, 0), 52, 40, rock.darkened(0.04), 205, true, 20)
	for k in 7:
		var go = Builder.rot(0, rng.randf_range(10, 22), k * 51.0)
		b.sphere(Vector3(go.x, bc + bH * 0.82 + rng.randf_range(4, 14), go.y), Vector3(12, 7, 12), Color(0.3, 0.52, 0.26).darkened(rng.randf() * 0.15), 8)
	var sy = bc + bH * 0.82 + 34.0
	b.cyl(Vector3(0, sy + 9, 0), 2.2, 18, Color(0.92, 0.92, 0.9), false, 10)
	b.cone(Vector3(0, sy + 18.5, 0), 7.0, 3.0, Color(0.62, 0.32, 0.22), 12)
	b.cyl(Vector3(0, sy + 24, 0), 0.5, 9, Color(0.85, 0.75, 0.3), false, 6)
	# kaya dibinde oyma giriş: beyaz revak, mavi saçak, sarı perde
	b.box(Vector3(0, 6.0, -58.0), Vector3(16.0, 12.0, 8.0), Color(0.9, 0.9, 0.88))
	b.box(Vector3(0, 12.4, -58.5), Vector3(18.0, 0.8, 9.0), Color(0.22, 0.45, 0.72), 0, false)
	b.box(Vector3(0, 4.0, -62.1), Vector3(7.0, 8.0, 0.3), Color(0.15, 0.15, 0.18), 0, false)
	b.box(Vector3(0, 7.2, -62.3), Vector3(7.4, 1.4, 0.1), Color(0.92, 0.74, 0.14), 0, false)
	b.kanji(Vector3(0, 9.9, -62.4), "雷影", 1.7, Color(0.2, 0.4, 0.66), 0)
	KageHall.door(b, 0, -64.0, 0.0, "kumo", "[F] Gir: Raikage Ofisi (Raikage ile görüş, görevler)", 6.0)
	KageHall.plaza(b, {"vid": "kumo", "front": -62.4, "hw": 34.0, "depth": 30.0, "climate": "cloud", "stone": Color(0.82, 0.82, 0.8),
		"trim": Color(0.55, 0.56, 0.6), "acc": Color(0.2, 0.42, 0.7), "gate": Color(0.92, 0.92, 0.9), "kanji": "雷", "terrace_h": 0.0})
	# bulutlar sütunlar arasında
	VillageStyles.mist(b, 70, 40, r * 0.9, 60, 200, 70, rng, 0.42)
	VillageStyles.mist_points(b, mist_pts, 46.0, rng, 0.6)
	if not _fx_done.has("kumo_falls"):
		_fx_done["kumo_falls"] = true
		for k in 2:
			var p: Array = pillars[k * 7]
			Waterfalls.add(b.w(Vector3(p[0], 0, p[1] - p[2] * 0.45)), p[3] * 0.7, 14.0, 0.0)
	await _fill(b, r * 0.85, 80, 34, "kumo", rng, [[0, -80, 34]] + _site_clear(v), 1100)
	await _streets(b, v, "kumo", rng)
	b.finish()


# ------------------------------------------------------------------ Iwagakure: kayaya oyulmuş kule şehir, asma köprüler
static func iwa(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Iwa")
	b.view_dist = 6000.0
	var rng = _rng(5)
	var r = float(v["r"])
	var stone = Color(0.56, 0.56, 0.57)   # ref (anime Iwa): soğuk gri taş
	var red = Color(0.58, 0.24, 0.17)
	var towers = []
	for k in 30:
		var a = TAU * (k + rng.randf_range(-0.3, 0.3)) / 30.0 * 2.0
		var rr = lerpf(150, r * 0.88, sqrt(rng.randf()))
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var h = rng.randf_range(90, 230)
		var d = rng.randf_range(60, 110)
		var c = stone.darkened(rng.randf_range(0.0, 0.14))
		b.crag(Vector3(px, -4, pn), d, h + 4, c, 100 + k, true, rng.randf() * 360.0)
		# oyma pencereler ve balkonlar (yamaçta)
		for f in int(h / 14):
			var y = 8 + f * 14
			var rad_here = d * (0.5 - 0.14 * pow(y / h, 1.3)) * 0.92
			for j in 3:
				var wa = rng.randf() * 360.0
				var o = Builder.rot(0, rad_here, wa)
				b.box(Vector3(px + o.x, y, pn + o.y), Vector3(2.4, 3.2, 1.0), VillageStyles.DARK, wa, false)
				if j == 0:
					var bo = Builder.rot(0, rad_here + 1.5, wa)
					b.box(Vector3(px + bo.x, y - 1.8, pn + bo.y), Vector3(5, 0.5, 3), c.darkened(0.2), wa)
					b.box(Vector3(px + bo.x, y + 2.3, pn + bo.y), Vector3(5.6, 0.4, 3.4), red, wa, false)
		# tepede taş ev kümesi + kırmızı çatılar
		var tr = d * 0.34
		b.cyl(Vector3(px, h - 0.4, pn), tr * 2.0, 1.6, c.darkened(0.12), true, 12)
		for j in rng.randi_range(1, 3):
			var ja = rng.randf() * 360.0
			var jo = Builder.rot(0, tr * 0.45 * j / 2.0, ja)
			var yo = b.yoff
			b.yoff = h + 0.4
			VillageStyles.iwa_house(b, px + jo.x, pn + jo.y, tr * 0.7, tr * 0.6, rng.randi_range(1, 3), ja, rng)
			b.yoff = yo
		towers.append([px, pn, h, d])
		if k % 5 == 4:
			await _yield()
			if not is_instance_valid(b.root):
				return
	for i in towers.size():
		var t0: Array = towers[i]
		for j in range(i + 1, towers.size()):
			var t1: Array = towers[j]
			var L = Vector2(t1[0] - t0[0], t1[1] - t0[1]).length()
			if L < 160 and L > 50:
				var y = minf(t0[2], t1[2]) * 0.6
				var dir = Vector3(t1[0] - t0[0], 0, t1[1] - t0[1]).normalized()
				VillageStyles.rope_bridge(b, Vector3(t0[0], y, t0[1]) + dir * t0[3] * 0.32, Vector3(t1[0], y, t1[1]) - dir * t1[3] * 0.32, 3.0, 3.5)
				break
	await _yield()
	# Tsuchikage kulesi (ref): alçak kaya tepesi üstünde kat kat taş davul gövde, pencere kuşakları, basamaklı halka koni çatı,
	# tepede küçük fener başlık; önde "土" arması
	b.crag(Vector3(0, -4, 0), 130, 60, stone.darkened(0.08), 77, true, 0)
	var tw = stone.lightened(0.04)
	var ty = 50.0
	var tiers = [[60.0, 34.0], [50.0, 30.0], [40.0, 24.0]]
	for ti in tiers.size():
		var td: float = tiers[ti][0]
		var th: float = tiers[ti][1]
		b.cyl(Vector3(0, ty + th * 0.5, 0), td, th, tw.darkened(0.05 * ti), true, 24)
		b.cyl(Vector3(0, ty + th, 0), td + 3.0, 1.4, tw.darkened(0.22), true, 24)   # kademe saçağı
		var rows = int(th / 8.0)
		for f in rows:
			var cnt = int(td * 0.42)
			for k in cnt:
				var wa = 360.0 * k / cnt + f * 9.0
				var o = Builder.rot(0, td * 0.5 + 0.1, wa)
				b.box(Vector3(o.x, ty + 5.0 + f * 8.0, o.y), Vector3(2.0, 3.0, 0.3), VillageStyles.DARK, wa, false)
		ty += th + 1.4
	var cy = ty
	for k in 7:   # basamaklı halka koni çatı
		var rd = 44.0 * (1.0 - float(k) / 7.0 * 0.85)
		b.cyl(Vector3(0, cy + 1.3, 0), rd, 2.6, tw.lightened(0.03 * (k % 2)), true, 24)
		cy += 2.6
	b.cyl(Vector3(0, cy + 3.0, 0), 5.0, 6.0, tw, true, 12)
	b.cone(Vector3(0, cy + 6.0, 0), 8.0, 4.0, red, 12)
	b.cyl(Vector3(0, cy + 13.0, 0), 0.5, 10.0, Color(0.3, 0.3, 0.32), false, 6)
	b.disc(Vector3(0, 50 + 17, -30.6), 14, 0.6, Color(0.88, 0.86, 0.8), 0, 20)
	b.kanji(Vector3(0, 50 + 17, -31.1), "土", 10.0, Color(0.42, 0.18, 0.12), 0)
	# çevreyi saran dev sivri gri dağ duvarı + şelaleler + sis kuşakları (ref: köy kayalık dağ halkasının içinde)
	var wall_mist = []
	for k in 50:
		var pa = 360.0 * k / 50.0 + rng.randf_range(-2.5, 2.5)
		var prr = r * rng.randf_range(1.12, 1.45)
		var po = Builder.rot(0, prr, pa)
		var ph = rng.randf_range(240, 460)
		var pd = ph * rng.randf_range(0.45, 0.65)
		var near_gate = false
		for ga in v.get("gates", []):
			if absf(wrapf(pa - float(ga), -180.0, 180.0)) < 9.0:
				near_gate = true
		if near_gate:
			continue
		b.crag(Vector3(po.x, -10, po.y), pd, ph, stone.darkened(rng.randf_range(0.0, 0.16)), (200 + k) if k % 3 != 0 else (100 + k), false, rng.randf() * 360.0)
		for j in 2:
			var mo = Builder.rot(rng.randf_range(-pd, pd) * 0.4, prr - pd * 0.45, pa)
			wall_mist.append(Vector3(mo.x, ph * rng.randf_range(0.25, 0.5), mo.y))
		if k % 12 == 5 and not _fx_done.has("iwa_fall_%d" % k):
			_fx_done["iwa_fall_%d" % k] = true
			var fo = Builder.rot(0, prr - pd * 0.42, pa)
			Waterfalls.add(b.w(Vector3(fo.x, 0, fo.y)), ph * 0.55, 10.0, pa + 180.0)
	VillageStyles.mist_points(b, wall_mist, 80.0, rng, 0.5)
	b.box(Vector3(0, 54.5, -30.4), Vector3(8, 9, 1.0), VillageStyles.DARK, 0, false)   # kule kapısı
	# taş kapı: kalın sütunlar, kırmızı katlı saçak, kanji
	for sx in [-1.0, 1.0]:
		b.box(Vector3(sx * 9.0, 6.0, -68.0), Vector3(3.6, 12.0, 3.6), stone.darkened(0.12))
		b.box(Vector3(sx * 9.0, 12.4, -68.0), Vector3(4.4, 0.8, 4.4), stone.darkened(0.25), 0, false)
	b.box(Vector3(0, 13.4, -68.0), Vector3(24.0, 2.0, 5.0), stone.darkened(0.18), 0, false)
	b.roof(Vector3(0, 14.4, -68.0), Vector3(27.0, 3.0, 7.0), red)
	b.box(Vector3(0, 10.4, -70.6), Vector3(5.0, 2.2, 0.3), Color(0.9, 0.84, 0.72), 0, false)
	b.kanji(Vector3(0, 10.4, -70.8), "土影", 1.7, Color(0.42, 0.18, 0.12), 0)
	KageHall.door(b, 0, -68.0, 0.0, "iwa", "[F] Gir: Tsuchikage Ofisi (Tsuchikage ile görüş, görevler)", 6.0)
	KageHall.plaza(b, {"vid": "iwa", "front": -71.0, "hw": 36.0, "depth": 32.0, "climate": "rock", "stone": Color(0.62, 0.52, 0.42),
		"trim": Color(0.44, 0.34, 0.26), "acc": Color(0.58, 0.24, 0.17), "gate": Color(0.5, 0.4, 0.32), "kanji": "土", "terrace_h": 0.0})
	await _fill(b, r * 0.85, 110, 30, "iwa", rng, [[0, -96, 34]] + _site_clear(v), 1400)
	await _streets(b, v, "iwa", rng)
	b.finish()


# ------------------------------------------------------------------ Amegakure: göl üstünde koyu sanayi kuleleri, borular, yüzlü merkez kule
static func ame(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Ame")
	b.view_dist = 6000.0
	var rng = _rng(6)
	var metal = Color(0.36, 0.38, 0.41)
	var r = float(v["r"])
	VillageStyles.water(b, Vector3(0, 0.45, 0), Vector2(r * 1.85, r * 1.85))
	# merkez kule: basamaklı gövde, borular, tepede dikenli antenler, cephede yüz
	b.box(Vector3(0, 110, 0), Vector3(60, 220, 60), metal.darkened(0.12))
	b.box(Vector3(0, 250, 0), Vector3(46, 60, 46), metal.darkened(0.08))
	b.box(Vector3(0, 292, 0), Vector3(30, 24, 30), metal)
	for k in 6:
		b.cone(Vector3(-12 + k * 5, 312, 0), 2.5, 16 + (k % 3) * 6, metal.darkened(0.2), 6)
	for k in 4:
		var a = k * 90.0 + 45.0
		var o = Builder.rot(0, 34, a)
		b.cyl(Vector3(o.x, 120, o.y), 4.5, 240, metal.lightened(0.05), false, 10)
	# yüz (kule cephesi, güneye bakar): kaş, göz çukurları, burun, sivri dişli ağız, borudan piercingler
	var fz = -30.6
	for sx in [-1.0, 1.0]:
		b.box(Vector3(12 * sx, 200, fz), Vector3(14, 3, 2), metal.darkened(0.35), 0, false, Vector3(0, 0, -18 * sx))
		b.box(Vector3(12 * sx, 190, fz), Vector3(10, 6, 1.5), Color(0.05, 0.05, 0.06), 0, false)
		b.box(Vector3(12 * sx, 190, fz - 0.4), Vector3(3, 3, 1), Color(0.9, 0.75, 0.3), 0, false)
		for k in 3:
			b.cyl(Vector3(20 * sx, 175 - k * 5, fz - 1.5), 1.2, 1.2, Color(0.65, 0.67, 0.7), false, 8)
	b.box(Vector3(0, 178, fz - 1.5), Vector3(5, 14, 3), metal.darkened(0.2), 0, false)
	b.box(Vector3(0, 158, fz), Vector3(30, 12, 1.5), Color(0.04, 0.04, 0.05), 0, false)
	for k in 9:
		var tx = -13 + k * 3.25
		b.box(Vector3(tx, 163, fz - 0.6), Vector3(1.6, 3.5, 1.2), Color(0.85, 0.85, 0.8), 0, false, Vector3(0, 0, 180))
		b.box(Vector3(tx + 1.6, 153, fz - 0.6), Vector3(1.6, 3.5, 1.2), Color(0.85, 0.85, 0.8), 0, false)
	b.interact(Vector3(0, 0, -36), 7, "mission_board", "[F] Ame Kulesi (görevler)")
	await _yield()
	var tw = []
	for k in 26:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(80, r * 0.85)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var h = rng.randf_range(60, 200)
		var w = rng.randf_range(18, 34)
		b.box(Vector3(px, h * 0.5, pn), Vector3(w, h, w), metal.darkened(rng.randf_range(0, 0.15)))
		b.box(Vector3(px, h + 4, pn), Vector3(w * 0.6, 8, w * 0.6), metal.darkened(0.2))
		# ref (anime Ame): kule tepelerinde kademeli daralan gövde + sivri iğne tacı
		b.box(Vector3(px, h + 12, pn), Vector3(w * 0.36, 8, w * 0.36), metal.darkened(0.12))
		b.cone(Vector3(px, h + 16, pn), w * 0.3, rng.randf_range(22, 40), metal.darkened(0.25), 8)
		for j in rng.randi_range(2, 4):
			var so = Builder.rot((w * 0.26) * (1 if j % 2 == 0 else -1), (w * 0.26) * (1 if j < 2 else -1), 0)
			b.cone(Vector3(px + so.x, h + 8, pn + so.y), w * 0.1, rng.randf_range(8, 18), metal.darkened(0.3), 6)
		for f in int(h / 8):
			if rng.randf() < 0.5:
				var o = Builder.rot(rng.randf_range(-w * 0.35, w * 0.35), -w * 0.5 - 0.1, 0)
				b.box(Vector3(px + o.x, f * 8 + 5, pn + o.y), Vector3(2, 2.5, 0.2), Color(0.95, 0.8, 0.45) if rng.randf() < 0.35 else Color(0.12, 0.13, 0.16), 0, false)
		for j in 2:
			var po = Builder.rot((w * 0.5 + 1.5) * (1 if j == 0 else -1), 0, 0)
			b.cyl(Vector3(px + po.x, h * 0.45, pn + po.y), 3.0, h * 0.9, metal.lightened(0.04), false, 8)
		tw.append([px, pn, h])
		if k % 6 == 5:
			await _yield()
			if not is_instance_valid(b.root):
				return
	# kuleler arası yatay boru köprüleri
	for i in tw.size() - 1:
		var t0: Array = tw[i]
		var t1: Array = tw[i + 1]
		var d = Vector3(t1[0] - t0[0], 0, t1[1] - t0[1])
		if d.length() < 200:
			var y = minf(t0[2], t1[2]) * 0.55
			var mid = Vector3((t0[0] + t1[0]) * 0.5, y, (t0[1] + t1[1]) * 0.5)
			var wpm = b.w(mid)
			b._mb(wpm).add("cyl", wpm, Vector3(2.5, d.length(), 2.5), metal.lightened(0.08), Vector3(90, rad_to_deg(atan2(d.x, d.z)), 0), 8)
	await _fill(b, r * 0.85, 90, 28, "ame", rng, [], 1100)
	await _streets(b, v, "ame", rng)
	b.finish()


# ------------------------------------------------------------------ Otogakure: kaya tepesine gizlenmiş yeraltı sığınağı
static func oto(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Oto")
	var rng = _rng(7)
	var rock = Color(0.42, 0.4, 0.38)
	b.boulder(Vector3(0, 6, 40), Vector3(150, 60, 120), rock, 3, true)
	for k in 10:
		var a = rng.randf() * 360.0
		var o = Builder.rot(0, rng.randf_range(60, 110), a)
		b.boulder(Vector3(o.x, 2, o.y + 40), Vector3(rng.randf_range(12, 30), rng.randf_range(8, 20), rng.randf_range(12, 26)), rock.darkened(rng.randf() * 0.15), k)
	# mağara ağzı: koyu kemer, taş çerçeve, mor fenerler, yılan heykelleri
	b.box(Vector3(0, 6, -16), Vector3(16, 12, 6), Color(0.04, 0.03, 0.05), 0, false)
	b.disc(Vector3(0, 12, -19.2), 16, 0.6, Color(0.04, 0.03, 0.05), 0, 16)
	b.box(Vector3(0, 19, -19), Vector3(22, 3, 3), rock.darkened(0.2), 0, false)
	b.box(Vector3(-26, 12.5, -19.4), Vector3(4, 4, 0.3), Color(0.5, 0.35, 0.6), 0, false)
	b.kanji(Vector3(-26, 12.5, -19.7), "音", 3.2, Color(0.95, 0.9, 1.0), 0)
	for sx in [-1.0, 1.0]:
		b.cyl(Vector3(11 * sx, 3, -18), 1.6, 6, rock.darkened(0.25), false, 8)
		b.sphere(Vector3(11 * sx, 6.5, -18), Vector3(1.6, 1.6, 1.6), Color(0.6, 0.3, 0.75), 8)
	# mağara ağzını saran taş yılan (ref: girişin üstüne kavis yapan oyma yılan gövdesi, açık ağızlı baş)
	var sk = Color(0.4, 0.42, 0.38)
	var pts = []
	for k in 46:
		var t = float(k) / 45.0
		var ang = PI * t
		pts.append(Vector3(-cos(ang) * 17.0, sin(ang) * 18.0 + 1.0 - (1.0 - sin(ang)) * 1.5, -20.5 - sin(ang * 2.0) * 1.2))
	for k in pts.size():
		var th = 4.6 - 1.4 * absf(float(k) / pts.size() - 0.35)
		b.sphere(pts[k], Vector3(th, th, th), sk.darkened(0.06 * (k % 3)), 10, k % 4 == 0)
		if k % 3 == 0:   # pul sırtı
			b.box(pts[k] + Vector3(0, th * 0.42, 0), Vector3(1.2, 0.5, 1.6), sk.darkened(0.2), 0, false)
	var hp = Vector3(0, 25.0, -28.0)
	var hs = 1.7   # baş: kemerin tepesinden öne uzanır, aşağı bakar
	b.sphere(Vector3(0, 21.5, -23.0), Vector3(6.4, 6.0, 8.0), sk, 10)
	var ux = b.w(hp + Vector3(0, 0.8, -1.0) * hs)
	b._mb(ux).add("sphere", ux, Vector3(6.0, 2.8, 8.6) * hs, sk.darkened(0.04), Vector3(16, 0, 0), 12)        # üst çene / kafatası
	var lx = b.w(hp + Vector3(0, -2.2, -0.6) * hs)
	b._mb(lx).add("sphere", lx, Vector3(4.8, 1.5, 7.2) * hs, sk.darkened(0.12), Vector3(-10, 0, 0), 10)       # alt çene
	b.sphere(hp + Vector3(0, -0.8, -1.2) * hs, Vector3(4.2, 1.8, 6.4) * hs, Color(0.32, 0.12, 0.14), 10)          # ağız içi
	for sx in [-1.0, 1.0]:
		var f = b.w(hp + Vector3(1.5 * sx, -1.0, -4.4) * hs)
		b._mb(f).add("cone", f, Vector3(0.55, 2.0, 0.55) * hs, Color(0.92, 0.9, 0.84), Vector3(180, 0, 0), 6)   # diş
		b.sphere(hp + Vector3(2.3 * sx, 1.8, -1.0) * hs, Vector3(1.0, 0.8, 1.2) * hs, Color(0.92, 0.78, 0.2), 8)      # göz
		b.box(hp + Vector3(2.1 * sx, 2.6, -0.6) * hs, Vector3(1.6, 0.5, 2.4) * hs, sk.darkened(0.25), 0, false, Vector3(0, 0, -20 * sx))   # kaş
	b.interact(Vector3(0, 0, -24), 7, "oto_lair", "[F] Ses Sığınağı")
	await _fill(b, float(v["r"]) * 0.8, 180, 30, "rock", rng, [[0, 40, 110]], 90)
	b.finish()


# ------------------------------------------------------------------ Kusagakure: dev mantar ormanı + çimen köyü
static func kusa(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kusa")
	var rng = _rng(8)
	var r = float(v["r"])
	for k in 30:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(60, r * 0.85)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var h = rng.randf_range(20, 55)
		b.cyl(Vector3(px, h * 0.5, pn), h * 0.12, h, Color(0.9, 0.88, 0.8), true, 10)
		var cap = [Color(0.72, 0.22, 0.17), Color(0.62, 0.3, 0.2), Color(0.8, 0.5, 0.28)][k % 3]   # ref: kırmızı/kahve şapkalar
		b.dome(Vector3(px, h - 1, pn), h * 0.9, h * 0.25, cap, 14)
		b.box(Vector3(px, h - 0.6, pn), Vector3(h * 0.8, 0.5, h * 0.8), cap.darkened(0.2))
		if k % 15 == 14:
			await _yield()
	# Kusa hastanesi / meclis (anime ref): beton gri-kahve bloklar, kızıl-kahve kırma çatılar, önde "医" yuvarlak armalı kule,
	# bloklar arası camlı köprü, kapıda "草隠れ病院" taş levhası
	var con = Color(0.56, 0.52, 0.46)
	var rf = Color(0.48, 0.26, 0.22)
	b.box(Vector3(-16, 9, 4), Vector3(22, 18, 18), con)                      # sol blok (3 kat)
	b.box(Vector3(18, 7, 6), Vector3(20, 14, 16), con.darkened(0.05))         # sağ blok
	b.roof(Vector3(18, 14, 6), Vector3(22, 5, 18), rf)
	b.box(Vector3(-16, 18.4, 4), Vector3(22.6, 0.8, 18.6), con.darkened(0.2), 0, false)
	for f in 3:   # pencere sıraları
		for k in 4:
			b.box(Vector3(-24 + k * 5.4, 3.5 + f * 5.5, -5.1), Vector3(3.6, 2.4, 0.3), Color(0.24, 0.3, 0.36), 0, false)
	for k in 3:
		b.box(Vector3(11 + k * 6.5, 4.5, -2.1), Vector3(4.0, 2.6, 0.3), Color(0.24, 0.3, 0.36), 0, false)
	b.box(Vector3(2, 15, 6), Vector3(14, 4, 5), con.lightened(0.04), 0, false)   # camlı köprü
	b.box(Vector3(2, 15, 3.4), Vector3(13, 2.2, 0.3), Color(0.5, 0.62, 0.7), 0, false)
	b.box(Vector3(2, 12, -2), Vector3(7, 24, 7), con.darkened(0.08))          # arma kulesi
	b.roof(Vector3(2, 24, -2), Vector3(8.5, 3.0, 8.5), rf)
	b.disc(Vector3(2, 17, -5.8), 5.6, 0.5, Color(0.7, 0.32, 0.22), 0, 20)
	b.disc(Vector3(2, 17, -6.1), 4.4, 0.3, Color(0.92, 0.9, 0.84), 0, 20)
	b.kanji(Vector3(2, 17, -6.4), "医", 3.4, Color(0.2, 0.18, 0.16), 0)
	b.box(Vector3(2, 4, -5.7), Vector3(2.6, 8, 0.3), Color(0.4, 0.26, 0.2), 0, false)   # uzun dar kapı
	b.box(Vector3(-6, 2.6, -14), Vector3(2.6, 5.2, 1.0), Color(0.6, 0.6, 0.58), 0)      # taş levha
	b.kanji(Vector3(-6, 3.4, -14.6), "草隠れ", 0.9, Color(0.2, 0.2, 0.2), 0)
	# dev ağaç gövdeleri + gövdeye raf gibi yapışmış kırmızı mantarlar (ref)
	for k in 14:
		var ta = rng.randf() * TAU
		var tr = rng.randf_range(70, r * 0.8)
		var tx = tr * sin(ta)
		var tn = tr * cos(ta)
		var th = rng.randf_range(40, 70)
		var td = rng.randf_range(9, 15)
		b.crag(Vector3(tx, -2, tn), td, th, Color(0.48, 0.38, 0.28).darkened(rng.randf() * 0.15), 120 + k, true, rng.randf() * 360.0)
		b.sphere(Vector3(tx, th + 4, tn), Vector3(td * 3.2, td * 1.6, td * 3.2), Color(0.28, 0.48, 0.24).darkened(rng.randf() * 0.12), 10)
		for j in 7:
			var my = rng.randf_range(4, th * 0.85)
			var ma = rng.randf() * 360.0
			var mo = Builder.rot(0, td * 0.48 * (1.0 - 0.3 * my / th) + 1.2, ma)
			var md = rng.randf_range(3.0, 6.0)
			b.dome(Vector3(tx + mo.x, my, tn + mo.y), md, md * 0.32, Color(0.72, 0.2, 0.16).lightened(rng.randf() * 0.1), 10)
			b.cyl(Vector3(tx + mo.x, my - 0.1, tn + mo.y), md * 0.95, 0.25, Color(0.92, 0.88, 0.8), false, 10)
		if k % 5 == 4:
			await _yield()
			if not is_instance_valid(b.root):
				return
	b.interact(Vector3(0, 0, -18), 7, "mission_board", "[F] Kusa Köy Meclisi (görevler)")
	await _fill(b, r * 0.8, 50, 22, "wood", rng, [], 200)
	b.finish()


# ------------------------------------------------------------------ Takigakure: göl ortasında dev ağaç, arkada şelaleli uçurumlar
static func taki(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Taki")
	b.view_dist = 6000.0
	var rng = _rng(9)
	var r = float(v["r"])
	VillageStyles.water(b, Vector3(0, -0.5, 0), Vector2(420, 420))
	var bark = Color(0.42, 0.29, 0.19)
	# gövde: pürüzlü kabuk sütunu + kök payandaları
	b.crag(Vector3(0, -6, 0), 80, 256, bark, 5, true, 0)
	for k in 9:
		var a = k * 40.0 + rng.randf_range(-10, 10)
		var o = Builder.rot(0, 42, a)
		var wp = b.w(Vector3(o.x, 10, o.y))
		b._mb(wp).add("crag", wp, Vector3(18, 60, 18), bark.darkened(0.1), Vector3(-55, a, 0), k)
	# taç: kat kat yaprak kümeleri
	for k in 18:
		var a = rng.randf() * 360.0
		var rr = rng.randf_range(0, 150)
		var o = Builder.rot(0, rr, a)
		var y = rng.randf_range(215, 285) - rr * 0.18
		var s = rng.randf_range(70, 130)
		var wp2 = b.w(Vector3(o.x, y, o.y))
		b._mb(wp2).add_grad("sphere", wp2, Vector3(s, s * 0.5, s), Color(0.34, 0.62, 0.3), Color(0.16, 0.38, 0.18), Vector3.ZERO, 12)
	# gövdeye sarılan merdiven-platformlar + dallara asılı evler
	for k in 14:
		var a = k * 26.0
		var o = Builder.rot(0, 41 - k * 0.6, a)
		b.box(Vector3(o.x, 16 + k * 14, o.y), Vector3(22, 1.5, 16), Color(0.55, 0.4, 0.25), a)
		if k % 3 == 1:
			var ho = Builder.rot(0, 50, a)
			b.box(Vector3(ho.x, 15.2 + k * 14, ho.y), Vector3(12, 1.2, 12), Color(0.5, 0.36, 0.22), a)
			var yo = b.yoff
			b.yoff = 15.8 + k * 14
			b._house_body(ho.x, ho.y, 9, 8, 1, a, "wood", rng)
			b.yoff = yo
	await _yield()
	for k in 3:
		var a = k * 120.0 + 30.0
		var o = Builder.rot(0, r * 0.8, a)
		b.crag(Vector3(o.x, -6, o.y), 150, 140, Color(0.5, 0.48, 0.44), 30 + k, true, a)
		b.crag(Vector3(o.x + 60, -6, o.y + 20), 110, 110, Color(0.46, 0.45, 0.42), 33 + k, true, a + 40)
		if not _fx_done.has("taki_%d" % k):
			_fx_done["taki_%d" % k] = true
			var fo = Builder.rot(0, r * 0.8 - 62, a)
			Waterfalls.add(b.w(Vector3(fo.x, 0, fo.y)), 120.0, 40.0, a)
	VillageStyles.mist(b, 30, 150, r * 0.8, 2, 20, 40, rng, 0.25)
	# ref: tacın arasından göle inen ışık huzmeleri + suyun yüzünde parıltılar
	var shafts = []
	for k in 22:
		var so = Builder.rot(0, rng.randf_range(40, 170), rng.randf() * 360.0)
		shafts.append(Vector3(so.x, rng.randf_range(80, 130), so.y))
	VillageStyles.light_shafts(b, shafts, 210.0, 18.0, rng, Color(0.85, 1.0, 0.92, 0.22))
	var glints = []
	for k in 160:
		var go = Builder.rot(0, rng.randf_range(50, 200), rng.randf() * 360.0)
		glints.append(Vector3(go.x, 0.3, go.y))
	VillageStyles.mist_points(b, glints, 2.2, rng, 0.75, Color(0.8, 1.0, 0.95))
	# lider evi (anime ref): ahşap iki katlı, sivri pembe-kızıl çatılı kuleler, cephede 滝 levhası, merdivenli tepe
	var hx = -88.0
	var hn = -232.0
	var hy = b._ground_off(hx, hn, 20.0).x
	var wd = Color(0.52, 0.36, 0.24)
	var pk = Color(0.74, 0.38, 0.36)
	b.box(Vector3(hx, hy + 1.0, hn), Vector3(30, 2.0, 20), Color(0.5, 0.47, 0.42))
	b.box(Vector3(hx, hy + 6.0, hn), Vector3(26, 8.0, 16), wd)
	b.box(Vector3(hx, hy + 6.5, hn - 8.3), Vector3(24, 0.4, 1.2), wd.darkened(0.25), 0, false)   # balkon korkuluğu
	for k in 6:
		b.box(Vector3(hx - 11 + k * 4.4, hy + 4.2, hn - 8.6), Vector3(0.5, 4.4, 0.5), wd.darkened(0.3), 0, false)
	b.roof(Vector3(hx, hy + 10.0, hn), Vector3(30, 7.0, 20), pk)
	for sx in [-1.0, 1.0]:   # sivri çatılı yan kuleler
		b.box(Vector3(hx + 11 * sx, hy + 12.0, hn - 4), Vector3(6, 6, 6), wd.lightened(0.04))
		var cp = b.w(Vector3(hx + 11 * sx, hy + 18.5, hn - 4))
		b._mb(cp).add("cone", cp, Vector3(8.0, 7.0, 8.0), pk, Vector3(0, 45, 0), 4)
	var cp2 = b.w(Vector3(hx, hy + 19.0, hn + 2))
	b._mb(cp2).add("cone", cp2, Vector3(7.0, 8.0, 7.0), pk.darkened(0.06), Vector3(0, 45, 0), 4)
	b.box(Vector3(hx, hy + 11.8, hn - 9.6), Vector3(5.0, 2.4, 0.4), Color(0.95, 0.88, 0.5), 0, false)
	b.kanji(Vector3(hx, hy + 11.8, hn - 9.9), "滝", 2.0, Color(0.15, 0.15, 0.2), 0)
	b.box(Vector3(hx, hy + 4.0, hn - 8.1), Vector3(3.2, 6.0, 0.3), Color(0.25, 0.18, 0.14), 0, false)
	b.interact(Vector3(hx, hy, hn - 12), 7, "mission_board", "[F] Taki Liderleri (görevler)")
	await _fill(b, r * 0.75, 240, 26, "wood", rng, [[hx, hn, 30]], 180)
	b.finish()


# ------------------------------------------------------------------ Yugakure: kaplıca kasabası, kayalarla çevrili havuzlar, fenerler
static func yu(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Yu")
	var rng = _rng(10)
	for k in 10:
		var a = k * 36.0
		var o = Builder.rot(0, 110, a)
		VillageStyles.water(b, Vector3(o.x, 0.05, o.y), Vector2(24, 24), a)
		for j in 14:
			var ja = j * 360.0 / 14.0
			var jo = Builder.rot(0, 13.5, ja)
			b.boulder(Vector3(o.x + jo.x, 0.4, o.y + jo.y), Vector3(rng.randf_range(2.5, 4.5), rng.randf_range(1.5, 2.6), rng.randf_range(2.5, 4.0)), Color(0.5, 0.48, 0.45).darkened(rng.randf() * 0.15), j, false)
		for sx in [-1.0, 1.0]:
			var lo = Builder.rot(16 * sx, 0, a)
			BuildFeatures._build(b, {"t": "lantern", "x": o.x + lo.x, "y": o.y + lo.y, "g": 0.0, "yaw": a}, rng)
		# bambu paravan
		var so = Builder.rot(0, 17, a)
		b.box(Vector3(o.x + so.x, 1.2, o.y + so.y), Vector3(20, 2.4, 0.3), Color(0.62, 0.55, 0.32), a)
		if not _fx_done.has("yu_%d" % k):
			_fx_done["yu_%d" % k] = true
			Steam.add(b.w(Vector3(o.x, 0.3, o.y)))
	# büyük han (iki katlı, noren, fenerler)
	b.house(0, 0, 28, 18, 2, 0, "konoha", rng)
	b.house(-30, 6, 16, 12, 2, 0, "konoha", rng)
	b.house(30, 6, 16, 12, 2, 0, "konoha", rng)
	b.interact(Vector3(0, 0, -14), 7, "onsen", "[F] Kaplıcaya gir (tam iyileşme)")
	await _fill(b, float(v["r"]) * 0.8, 170, 22, "konoha", rng, [], 180)
	b.finish()


static func small_town(parent: Node3D, v: Dictionary, style: String) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], v["id"])
	var rng = _rng(hash(v["id"]))
	b.house(0, 0, 30, 20, 2, 0, style, rng)
	b.interact(Vector3(0, 0, -16), 7, "mission_board", "[F] Köy Meclisi (görevler)")
	if style == "snow":
		for k in 40:
			var a = rng.randf() * TAU
			var rr = rng.randf_range(20, float(v["r"]) * 0.8)
			b.dome(Vector3(rr * sin(a), -0.2, rr * cos(a)), rng.randf_range(4, 12), rng.randf_range(0.6, 1.6), Color(0.95, 0.97, 1.0), 10)
	await _fill(b, float(v["r"]) * 0.8, 40, 22, style, rng, [[0, 0, 25]], 200)
	b.finish()


# ------------------------------------------------------------------ Tanigakure: dev kanyon duvarlarına oyulmuş
static func tani(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Tani")
	var rng = _rng(11)
	var L = float(v["r"]) * 1.6
	for sx in [-1.0, 1.0]:
		for k in 14:
			var n = -L * 0.5 + (k + 0.5) * L / 14.0
			b.crag(Vector3(150 * sx + rng.randf_range(-15, 15), -6, n), 120, rng.randf_range(110, 150), Color(0.58, 0.46, 0.35).darkened(rng.randf() * 0.12), k + (20 if sx > 0 else 0), true, rng.randf() * 360.0)
		for k in 30:
			var n = -L * 0.45 + k * L * 0.9 / 30.0
			var y = 10 + (k % 4) * 22
			b.box(Vector3(102 * sx, y, n), Vector3(4, 8, 12), VillageStyles.DARK, 0, false)
			b.box(Vector3(99 * sx, y - 4.3, n), Vector3(9, 0.6, 16), Color(0.45, 0.33, 0.22))
			b.box(Vector3(99 * sx, y + 4.6, n), Vector3(10, 0.4, 17), Color(0.55, 0.25, 0.18), 0, false)
			if k % 3 == 0:
				for j in 4:
					b.box(Vector3(95 * sx, y - 4.3 - j * 5.5, n + 8 + j * 1.5), Vector3(3, 0.4, 3), Color(0.45, 0.33, 0.22), 0, false)
	b.interact(Vector3(0, 0, -30), 7, "mission_board", "[F] Tani Muhtarı (görevler)")
	await _fill(b, 90, 0, 20, "wood", rng, [], 60)
	# vadi boyunca iki sıra ev/dükkân (ortada cadde), arada ara sokaklar
	var k2 = 0
	for sx in [-1.0, 1.0]:
		for row in 2:
			var nn = -L * 0.42
			while nn < L * 0.42:
				var hx = sx * (34.0 + row * 24.0) + rng.randf_range(-2.0, 2.0)
				var ww = rng.randf_range(10.0, 14.0)
				if absf(nn) > 100.0 or absf(hx) > 60.0:
					b.house(hx, nn, ww, rng.randf_range(8.0, 11.0), [1, 2, 2, 3].pick_random(), 90.0 * sx, "wood", rng)
					k2 += 1
					if k2 % 10 == 0:
						await _yield()
						if not is_instance_valid(b.root):
							return
				nn += ww + rng.randf_range(4.0, 9.0) + (8.0 if rng.randf() < 0.18 else 0.0)
	b.finish()


# ------------------------------------------------------------------ Dalga Ülkesi kasabası: denize uzanan kazık evler, iskeleler, Büyük Köprü
static func nami(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Nami")
	var rng = _rng(12)
	var r = float(v["r"])
	# denizin olduğu yönü bul (en alçak kıyı)
	var sea_a = 0.0
	var lowest = 1e9
	for k in 24:
		var a = 360.0 * k / 24.0
		for dd in [r * 1.2, r * 2.0, r * 3.0, r * 4.5, r * 6.0]:
			var o = Builder.rot(0, dd, a)
			var g = b._ground_off(o.x, o.y, 1.0).x
			if g < lowest:
				lowest = g
				sea_a = a
	var shore = -1.0
	for k in 40:
		var o = Builder.rot(0, r * 0.6 + k * 30.0, sea_a)
		if b._ground_off(o.x, o.y, 1.0).x < -1.5:
			shore = r * 0.6 + k * 30.0 - 30.0
			break
	await _fill(b, r * 0.6, 20, 20, "wood", rng, [], 160)
	b.interact(Vector3(0, 0, 0), 7, "mission_board", "[F] Kasaba Halkı (görevler)")
	if shore < 0.0 or shore > 1400.0:
		b.finish()   # yakında deniz yok: kazık evler ve köprü kurulmaz
		return
	# kıyıda ve suyun üstünde kazık evler + yürüme iskeleleri
	for k in 30:
		var lx = -150.0 + (k % 10) * 32.0
		var ln = shore + 10.0 + int(k / 10) * 28.0
		var o = Builder.rot(lx, ln, sea_a)
		var g = b._ground_off(o.x, o.y, 6.0).y
		var deck = maxf(g, -1.0) + 2.6
		b.box(Vector3(o.x, deck, o.y), Vector3(13, 0.6, 13), Color(0.45, 0.34, 0.24), sea_a)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var po = Builder.rot(lx + 5.5 * sx, ln + 5.5 * sz, sea_a)
				b.cyl(Vector3(po.x, deck - 6.0, po.y), 0.7, 12.0, Color(0.32, 0.24, 0.17), false, 6)
		var yo = b.yoff
		b.yoff = deck + 0.3
		b._house_body(o.x, o.y, 9, 8, 1, sea_a + 180.0, "wood", rng)
		b.yoff = yo
		var wo = Builder.rot(lx, ln - 12.0, sea_a)
		b.box(Vector3(wo.x, deck, wo.y), Vector3(3, 0.4, 12), Color(0.45, 0.34, 0.24), sea_a, false)
		if k % 10 == 9:
			await _yield()
			if not is_instance_valid(b.root):
				return
	# Büyük Köprü: kıyıdan denize uzanan geniş köprü, ayaklar ve kemer kirişleri
	var bl = 900.0
	var bs = shore - 40.0
	var mid = Builder.rot(180.0, bs + bl * 0.5, sea_a)
	b.box(Vector3(mid.x, 8, mid.y), Vector3(16, 1.6, bl), Color(0.62, 0.6, 0.57), sea_a)
	for sx in [-1.0, 1.0]:
		var ro = Builder.rot(180.0 + 7.6 * sx, bs + bl * 0.5, sea_a)
		b.box(Vector3(ro.x, 9.4, ro.y), Vector3(0.6, 1.4, bl), Color(0.5, 0.48, 0.45), sea_a, false)
	for k in 16:
		var po = Builder.rot(180.0, bs + k * bl / 15.0, sea_a)
		b.box(Vector3(po.x, -6, po.y), Vector3(12, 28, 6), Color(0.55, 0.53, 0.5), sea_a)
		if k % 3 == 0:
			for sx in [-1.0, 1.0]:
				var to = Builder.rot(180.0 + 8 * sx, bs + k * bl / 15.0, sea_a)
				b.box(Vector3(to.x, 15, to.y), Vector3(1.2, 12, 1.2), Color(0.45, 0.32, 0.22), sea_a, false)
			b.box(Vector3(po.x, 21, po.y), Vector3(20, 1.2, 1.6), Color(0.45, 0.32, 0.22), sea_a, false)
	b.finish()


static func uzushio(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Uzushio")
	var rng = _rng(13)
	var r = float(v["r"])
	# ref (anime Uzushio harabeleri): yıkık bina kabukları (kırık üst kenarlı duvarlar), devrik sütunlar ve yüzüne
	# girdap (渦) oyulmuş dev eğik taş levhalar
	var ruin = Color(0.6, 0.5, 0.42)
	for k in 46:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(30, r * 0.85)
		var cx = rr * sin(a)
		var cn = rr * cos(a)
		var yaw = rng.randf() * 180.0
		var ww = rng.randf_range(10, 22)
		var dd = rng.randf_range(8, 16)
		var hh = rng.randf_range(6, 16)
		var col = ruin.darkened(rng.randf_range(0.0, 0.18))
		for side in 4:   # dört duvar, her biri kırık parçalardan (bazıları tamamen yıkık)
			if rng.randf() < 0.3:
				continue
			var along = ww if side % 2 == 0 else dd
			var segs = int(along / 2.5)
			for j in segs:
				var sh = hh * rng.randf_range(0.25, 1.0) * (1.0 - 0.5 * absf(float(j) / segs - 0.5))
				var lx = -along * 0.5 + (j + 0.5) * along / segs
				var o = Builder.rot(lx, (dd if side % 2 == 0 else ww) * 0.5 * (1 if side < 2 else -1), yaw + (0.0 if side % 2 == 0 else 90.0))
				b.box(Vector3(cx + o.x, sh * 0.5, cn + o.y), Vector3(along / segs + 0.05, sh, 1.2), col, yaw + (0.0 if side % 2 == 0 else 90.0), j % 2 == 0)
		if k % 3 == 0:   # devrik sütun
			var po = Builder.rot(rng.randf_range(-8, 8), rng.randf_range(-8, 8), yaw)
			var pc = b.w(Vector3(cx + po.x, 1.2, cn + po.y))
			b._mb(pc).add("cyl", pc, Vector3(2.4, rng.randf_range(8, 14), 2.4), col.lightened(0.05), Vector3(90, yaw, rng.randf_range(-10, 10)), 10)
		if k % 5 == 0:
			b.boulder(Vector3(cx + 4, 1, cn), Vector3(5, 3, 4), ruin.darkened(0.1), k)
		if k % 8 == 7:
			await _yield()
			if not is_instance_valid(b.root):
				return
	for k in 9:   # girdap oymalı eğik levhalar
		var a = 360.0 * k / 9.0 + rng.randf_range(-15, 15)
		var o = Builder.rot(0, rng.randf_range(60, r * 0.75), a)
		var sz = rng.randf_range(10, 18)
		var tilt = rng.randf_range(-24, 24)
		var yaw = a + rng.randf_range(-40, 40)
		b.box(Vector3(o.x, sz * 0.45, o.y), Vector3(sz, sz, 2.4), ruin.darkened(0.08), yaw, true, Vector3(0, 0, tilt))
		var face = Builder.rot(0, -1.25, yaw)
		var ctr = Vector3(o.x + face.x, sz * 0.45, o.y + face.y)
		for j in 34:   # sarmal: dışa açılan nokta dizisi (levhanın ön yüzünde)
			var t = float(j) / 33.0
			var sa = t * TAU * 2.2
			var sr = 0.6 + t * sz * 0.38
			var lx = cos(sa) * sr
			var ly = sin(sa) * sr
			var rz = deg_to_rad(tilt)
			var px = lx * cos(rz) - ly * sin(rz)
			var py = lx * sin(rz) + ly * cos(rz)
			var so = Builder.rot(px, 0, yaw)
			b.box(Vector3(ctr.x + so.x, ctr.y + py, ctr.z + so.y), Vector3(1.0, 1.0, 0.4), ruin.darkened(0.42), yaw, false, Vector3(0, 0, tilt))
	# Uzumaki sarmalı (yerde kırmızı halka + sarmal)
	b.cyl(Vector3(0, 0.6, 0), 40, 1.2, Color(0.6, 0.25, 0.22), false, 24)
	for k in 40:
		var t = float(k) / 40.0
		var a = t * 720.0
		var o = Builder.rot(0, 4 + t * 14, a)
		b.box(Vector3(o.x, 1.3, o.y), Vector3(2.4, 0.3, 1.2), Color(0.85, 0.82, 0.75), a, false)
	b.interact(Vector3(0, 0, 0), 10, "ruins", "[F] Harabeleri incele")
	# Uzumaki maske tapınağı (kanon: Uzumaki klanının maske iblisi odası — Shinigami maskesi burada saklanır)
	var sx = 60.0
	var wood = Color(0.42, 0.18, 0.14)
	b.box(Vector3(sx, 0.4, 0), Vector3(14, 0.8, 12), Color(0.5, 0.47, 0.42))
	b.box(Vector3(sx, 3.6, 1.5), Vector3(11, 5.6, 8), Color(0.62, 0.3, 0.26))
	b.box(Vector3(sx, 6.9, 1.5), Vector3(13.5, 0.8, 10.5), Color(0.25, 0.22, 0.24))
	b.box(Vector3(sx, 7.6, 1.5), Vector3(9, 0.7, 6), Color(0.25, 0.22, 0.24))
	for tx in [-3.2, 3.2]:   # kırmızı torii
		b.box(Vector3(sx + tx, 3.5, -7.5), Vector3(0.6, 7, 0.6), wood)
	b.box(Vector3(sx, 7.2, -7.5), Vector3(9, 0.6, 0.8), wood)
	b.box(Vector3(sx, 6.2, -7.5), Vector3(7.5, 0.4, 0.5), wood)
	b.cyl(Vector3(sx, 4.2, -2.55), 1.4, 0.15, Color(0.6, 0.25, 0.22), false, 20)   # kapının üstünde Uzumaki sarmalı arması
	b.interact(Vector3(sx, 0, -4), 4, "uzumaki_shrine", "[F] Uzumaki maske tapınağı")
	b.finish()


# ------------------------------------------------------------------ Demir Ülkesi: karlı dağlarda samuray şatosu
static func tetsu(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Tetsu")
	b.view_dist = 6000.0
	var rng = _rng(14)
	var stone = Color(0.55, 0.55, 0.57)
	var white = Color(0.95, 0.95, 0.95)
	var roofc = Color(0.22, 0.26, 0.3)
	var snow = Color(0.95, 0.97, 1.0)
	# eğimli taş kaide (ishigaki) + sur
	for t in 4:
		var s = 170.0 - t * 12.0
		b.box(Vector3(0, 3 + t * 6, 0), Vector3(s, 6, s), stone.darkened(0.04 * t))
	b.wall_rect(0, 0, 230, 230, 10, stone.darkened(0.1), 14)
	# beş katlı beyaz şato kulesi: her katta kavisli koyu çatı + kar
	for t in 5:
		var s = 100.0 - t * 17.0
		var y = 24 + t * 16
		b.box(Vector3(0, y + 6, 0), Vector3(s, 12, s), white)
		for k in int(s / 9):
			var lx = -s * 0.5 + (k + 0.5) * s / int(s / 9)
			b.box(Vector3(lx, y + 7, -s * 0.5 - 0.1), Vector3(2.2, 3.0, 0.3), VillageStyles.DARK, 0, false)
		b.roof(Vector3(0, y + 12, 0), Vector3(s + 16, 7, s + 16), roofc)
		b.roof(Vector3(0, y + 12.4, 0), Vector3(s + 15, 6.6, s + 15), snow)
		b.box(Vector3(0, y + 12, 0), Vector3(s + 18, 0.8, s + 18), roofc.darkened(0.2), 0, false)
	b.cone(Vector3(0, 112, 0), 10, 8, Color(0.8, 0.65, 0.25), 8)
	b.kanji(Vector3(0, 56, -59.5), "侍", 12.0, Color(0.12, 0.12, 0.14), 0)
	# kalenin önündeki açık zirve salonu (avluda, sur kapısının karşısında): sütunlar, kat kat çatı, yuvarlak masa, beş Kage koltuğu
	var hn = -101.0
	var plat = Color(0.62, 0.62, 0.64)
	b.box(Vector3(0, 0.02, hn), Vector3(44, 0.5, 22), plat, 0, false)   # zemin: yerle aynı hiza, çarpışmasız (NPC'ler gömülmesin)
	for k in 10:
		var x = -20.0 + (k % 5) * 10.0
		var n = hn + (9.0 if k < 5 else -9.0)
		b.cyl(Vector3(x, 5.5, n), 1.1, 9.4, Color(0.32, 0.22, 0.14), true, 10)
	b.box(Vector3(0, 10.3, hn), Vector3(46, 0.8, 24), roofc.darkened(0.1), 0, false)
	b.roof(Vector3(0, 10.7, hn), Vector3(50, 5, 28), roofc)
	b.roof(Vector3(0, 11.0, hn), Vector3(48, 4.6, 26), snow)
	# çatı kirişinden sarkan "beş kage" levhası (arka duvar yok: kalenin kapısı açık kalsın)
	b.box(Vector3(0, 8.6, hn - 9.2), Vector3(9, 2.6, 0.3), white, 0, false)
	b.kanji(Vector3(0, 8.6, hn - 9.45), "五影", 2.2, Color(0.12, 0.12, 0.14), 0)
	b.cyl(Vector3(0, 1.3, hn), 12.0, 0.25, stone.darkened(0.15), true, 24)   # yuvarlak taş masa
	b.cyl(Vector3(0, 1.0, hn), 10.8, 0.6, stone.darkened(0.3), true, 24)
	var kcol = [Color(0.85, 0.3, 0.15), Color(0.25, 0.55, 0.85), Color(0.85, 0.8, 0.25), Color(0.55, 0.4, 0.25), Color(0.4, 0.75, 0.55)]
	for i in 5:
		var a = TAU * i / 5.0
		var x = sin(a) * 7.8
		var n = hn + cos(a) * 7.8
		b.box(Vector3(x, 1.25, n), Vector3(1.6, 0.25, 1.6), Color(0.35, 0.24, 0.15))
		b.box(Vector3(x, 4.0, n + cos(a) * 1.6), Vector3(1.8, 3.0, 0.08), kcol[i], rad_to_deg(a), false)   # köy sancağı
	b.interact(Vector3(0, 0, -112), 6, "mission_board", "[F] Samuray Generali (görevler)")
	# kalenin kendi kapısı: içeride Beş Kage Zirve Salonu (iç mekân)
	b.box(Vector3(0, 3.5, -85.6), Vector3(6, 7, 0.6), Color(0.3, 0.2, 0.12), 0, false)
	b.box(Vector3(0, 7.4, -85.8), Vector3(7.6, 0.8, 0.8), roofc, 0, false)
	b.interact(Vector3(0, 0, -88.5), 4, "enter", "[F] Gir: Demir Kalesi — Zirve Salonu", {"room": "summit", "out": b.w(Vector3(0, 0, -90.5))})
	for k in 60:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(130, float(v["r"]) * 0.85)
		b.dome(Vector3(rr * sin(a), -0.2, rr * cos(a)), rng.randf_range(6, 16), rng.randf_range(0.8, 2.0), snow, 10)
	await _fill(b, float(v["r"]) * 0.8, 150, 26, "snow", rng, [], 200)
	b.finish()


# ------------------------------------------------------------------ Sonun Vadisi: 130 m kanyon, 99 m şelale, 100 m'lik iki heykel
static func valley_end(parent: Node3D, l: Dictionary) -> void:
	var spec: Dictionary = l.get("spec", {"rim": 130.0, "river": -3.0, "upper": 96.0, "fall_dy": 520.0, "half": 95.0})
	var b = Builder.new(parent, l["x"], l["y"], 0.0, "SonunVadisi")
	b.view_dist = 30000.0
	var rock = Color(0.6, 0.57, 0.53)
	var fall_n: float = spec["fall_dy"]
	var rim: float = spec["rim"]
	if not _fx_done.has("valley"):
		_fx_done["valley"] = true
		# destansı şelale: kavisli perde, sis, gökkuşağı, yan sızıntılar, akan nehir, uğultu
		Waterfalls.add_epic(b.w(Vector3(0, spec["river"], fall_n - 4.0)), float(spec["upper"]) - float(spec["river"]) + 2.0, 120.0,
			{"throw": 16.0, "arch": 7.0, "back": 4.0, "river_len": 600.0, "river_w": float(spec["half"]) * 1.6, "upper_len": 900.0, "upper_w": 124.0,
			"trickles": [[-72.0, 5.0, 0.75], [-86.0, 3.0, 0.45], [70.0, 4.0, 0.6], [84.0, 3.5, 0.85]]})
	# iki dev heykel şelalenin iki yanında kanyon kenarında, birbirine bakıyor (hayran modeli; yoksa prosedürel)
	_valley_cliffs(b, spec)
	if not _valley_statues(b, float(spec["half"]), fall_n - 75.0, float(spec["river"])):
		for sx in [-1.0, 1.0]:
			_statue(b, (float(spec["half"]) + 55.0) * sx, fall_n - 40.0, rim, -90.0 * sx, rock, sx > 0.0)
	b.interact(Vector3(0, spec["river"] + 0.5, fall_n - 160.0), 20, "valley", "[F] Sonun Vadisi'nde meditasyon yap")
	b.finish()


## Sonun Vadisi hayran modeli (Sketchfab, Valledelfin.fbx): yalnızca iki heykel gövdesi kullanılır (kanyon, şelale ve nehir
## bizim arazimiz). Orijinal kafalar ve saçlar boyun üstünden kesilir; yerine kendi efsanevi ninjalarımızın taş büstleri konur.
const VALLEY_MODEL := "res://assets/sketchfab/valley_of_end/source/Valledelfin.fbx"
const VALLEY_HIDE := ["40_Cliff_0_1_0_0", "Plane", "Plane_001", "Material_003", "Material_004"]
const VALLEY_HAIR := "Material_014"   # saç ile hakama aynı parça: saç kısmı bel üstünden kesilir
const VALLEY_HAIR_CUT := 4.3
const VALLEY_SC := 14.5                # model ~7.3 birim -> ~105 m heykel (animedeki gibi şelale boyunda, dipten yükselir)
## [modelde heykel merkezi x, z, kesim x aralığı, boyun y, büst görünümü (özgün iki kurucu ninja)]
const VALLEY_STATUE := [
	{"x": -2.8, "z": -20.4, "lo": -1e9, "hi": -0.36, "neck": 6.22,
		"look": {"gender": "m", "hair_style": "geriye", "face_id": 0, "band": Color.WHITE, "band_style": "head"}},   # sakin kurucu (erkek yüz)
	{"x": 2.08, "z": -20.7, "lo": -0.36, "hi": 1e9, "neck": 6.36,
		"look": {"gender": "m", "hair_style": "diken", "face_id": 1, "band": null}},   # öfkeli rakip (erkek yüz)
]


## Kanyon duvarlarını modelin oyuk kayalarıyla giydirir (düz arazi duvarının önünde, şelalenin aşağısında).
## Model kanyonu ~12 birim geniş, 7 birim yüksek: iç yüzleri arazi duvarının biraz önüne (±%82) gelecek, 133 m derinliğe ölçeklenir.
static func _valley_cliffs(b: Builder, spec: Dictionary) -> void:
	if not ResourceLoader.exists(VALLEY_MODEL):
		return
	var ps = load(VALLEY_MODEL)
	if ps == null:
		return
	var river = float(spec["river"])
	var fall_n = float(spec["fall_dy"])
	var sc = Vector3(float(spec["half"]) * 0.82 / 5.7, (float(spec["rim"]) - river) / 7.0, 11.0)
	var root: Node3D = ps.instantiate()
	b.root.add_child(root)
	# modelde z=0 şelaleye yakın dar boğaz; aşağı akış +z (bizde de dünyada aşağı akış +z)
	root.scale = sc
	root.global_position = b.w(Vector3(0, river, fall_n))
	var z_clip = b.w(Vector3(0, 0, fall_n - 6.0)).z
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/valley_statue.gdshader")
	m.set_shader_parameter("stone", Color(0.6, 0.55, 0.48))
	m.set_shader_parameter("moss", 0.55)
	m.set_shader_parameter("z_min", z_clip)
	var cliff: MeshInstance3D = null
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name) == "40_Cliff_0_1_0_0":
			cliff = mi
		else:
			mi.queue_free()
	if cliff == null:
		return
	cliff.material_override = m
	cliff.visibility_range_end = 30000.0
	# çarpışma: ölçekli üçgenler dünya koordinatında (Jolt eşit olmayan ölçekli şekli sevmez); şelale üstü atlanır
	var xf = cliff.global_transform
	var src: PackedVector3Array = cliff.mesh.get_faces()
	var faces = PackedVector3Array()
	for t in range(0, src.size(), 3):
		var a = xf * src[t]
		var c2 = xf * src[t + 1]
		var d = xf * src[t + 2]
		if a.z < z_clip and c2.z < z_clip and d.z < z_clip:
			continue
		faces.append(a); faces.append(c2); faces.append(d)
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var body = StaticBody3D.new()
	b.root.add_child(body)
	var cs = CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	body.global_transform = Transform3D.IDENTITY


static func _valley_statues(b: Builder, half: float, n: float, g: float) -> bool:
	if not ResourceLoader.exists(VALLEY_MODEL):
		return false
	var ps = load(VALLEY_MODEL)
	if ps == null:
		return false
	var rock = Color(0.62, 0.58, 0.52)
	var sh = load("res://shaders/valley_statue.gdshader")
	for i in 2:
		var d: Dictionary = VALLEY_STATUE[i]
		var sx = -1.0 if i == 0 else 1.0
		# kaide: nehirden yükselen kaya blok (heykel suyun içinden yükselir), üstü düz
		var px = half * 0.7 * sx
		var ped_top = g + 7.0
		b.cyl(Vector3(px, (g - 6.0 + ped_top) * 0.5, n), 44.0, ped_top - g + 6.0, rock.darkened(0.12), true, 14)
		b.cyl(Vector3(px, ped_top - 0.4, n), 40.0, 0.8, rock.darkened(0.05), false, 14)
		var feet_l = Vector3(px, ped_top, n)
		var feet = b.w(feet_l)
		var root: Node3D = ps.instantiate()
		b.root.add_child(root)
		# modelde heykeller kanyonun dışına bakıyor: 180° çevir -> birbirlerine ve aşağı akışa (izleyene) bakarlar
		root.scale = Vector3.ONE * VALLEY_SC
		root.rotation.y = PI
		root.global_position = feet + Vector3(float(d["x"]), 0.0, float(d["z"])) * VALLEY_SC
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			if String(mi.name) in VALLEY_HIDE:
				mi.queue_free()
				continue
			var m = ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("stone", rock)
			m.set_shader_parameter("x_min", root.global_position.x - float(d["hi"]) * VALLEY_SC)
			m.set_shader_parameter("x_max", root.global_position.x - float(d["lo"]) * VALLEY_SC)
			var cut = VALLEY_HAIR_CUT if String(mi.name) == VALLEY_HAIR else float(d["neck"])
			m.set_shader_parameter("y_cut", feet.y + cut * VALLEY_SC)
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			# kesilen öbür heykel yarısı gölge/görünürlük sınırını büyütmesin
			mi.visibility_range_end = 30000.0
		# çarpışma: gövde sütunu (omuzlara çıkılabilir) + kaide
		var body = StaticBody3D.new()
		b.root.add_child(body)
		var cs = CollisionShape3D.new()
		var bx = BoxShape3D.new()
		bx.size = Vector3(2.4, 5.9, 1.9) * VALLEY_SC
		cs.shape = bx
		body.add_child(cs)
		body.global_position = feet + Vector3(0, 2.95 * VALLEY_SC, 0)
		# taş büst: modelin kafası ~1 birim; gövde gibi öbür heykele ve biraz aşağı akışa bakar
		# (büst yüzü yaw'da (-sin, 0, -cos) yönündedir: hedef (-sx, 0, +0.6) -> yaw = atan2(sx, -0.6))
		var head_at = feet_l + Vector3(0, (float(d["neck"]) + 0.42) * VALLEY_SC, 0)
		# yüz öbür heykele ve aşağı akışa (izleyene) dönük: eskiden yukarı akışa (şelaleye) bakıyordu -> "kafalar ters"
		BuildKonoha._stone_head(b, i, head_at, 0.95 * VALLEY_SC, rock.lightened(0.04), d["look"], atan2(sx, -0.6))
	return true


## 100 m'lik dev shinobi heykeli: kaide, hakama etekli bacaklar, zırhlı gövde, saç, mühür yapan el
static func _statue(b: Builder, x: float, n: float, g: float, face_yaw: float, rock: Color, spiky: bool) -> void:
	var f = Builder.rot(0, -1.0, face_yaw)   # yüz yönü (yerel)
	var s = Builder.rot(1.0, 0, face_yaw)    # yan
	var P = func(dx: float, dy: float, dn: float) -> Vector3:
		return Vector3(x + s.x * dx + f.x * dn, g + dy, n + s.y * dx + f.y * dn)
	b.box(P.call(0, 6, 0), Vector3(46, 12, 46), rock.darkened(0.12), face_yaw)
	b.box(P.call(0, 13, 0), Vector3(40, 3, 40), rock.darkened(0.05), face_yaw)
	# bacaklar + hakama
	for sd in [-1.0, 1.0]:
		b.box(P.call(7 * sd, 26, 0), Vector3(10, 24, 11), rock, face_yaw)
	b.box(P.call(0, 32, 0), Vector3(28, 16, 18), rock.darkened(0.05), face_yaw)
	b.box(P.call(0, 25, -2), Vector3(30, 4, 20), rock.darkened(0.1), face_yaw)
	# gövde, zırh plakaları, omuzlar
	b.box(P.call(0, 52, 0), Vector3(24, 28, 15), rock.lightened(0.03), face_yaw)
	for k in 3:
		b.box(P.call(0, 44 + k * 7, 7.8), Vector3(22, 5, 1.6), rock.darkened(0.08), face_yaw)
	for sd in [-1.0, 1.0]:
		b.box(P.call(15 * sd, 64, 0), Vector3(10, 7, 17), rock.lightened(0.05), face_yaw)
	# kollar: biri göğüste mühür, diğeri yanda
	b.box(P.call(-14, 50, 2), Vector3(7, 22, 7), rock, face_yaw)
	b.box(P.call(8, 58, 9), Vector3(7, 7, 14), rock, face_yaw)
	b.box(P.call(2, 64, 14), Vector3(5, 12, 5), rock.lightened(0.05), face_yaw)
	# boyun, kafa, saç
	b.box(P.call(0, 69, 0), Vector3(7, 5, 7), rock, face_yaw)
	b.box(P.call(0, 78, 1), Vector3(13, 15, 13), rock.lightened(0.06), face_yaw)
	b.box(P.call(0, 77, 7.8), Vector3(9, 3, 1), rock.darkened(0.15), face_yaw)
	if spiky:
		for k in 7:
			var a = -60.0 + k * 20.0
			var o = Builder.rot(0, -1.0, a)
			b.cone(P.call(o.x * 5.0, 88 + absf(o.y) * 2.0, -o.y * 5.0 - 2.0), 5.0, 9.0, rock.darkened(0.04), 5)
	else:
		b.box(P.call(0, 86, -1), Vector3(15, 5, 15), rock.darkened(0.06), face_yaw)
		b.box(P.call(0, 70, -8), Vector3(14, 30, 4), rock.darkened(0.06), face_yaw)  # uzun saç
	b.box(P.call(0, 82.5, 7.0), Vector3(14, 2.2, 1.5), rock.darkened(0.2), face_yaw)    # alın bandı


# ------------------------------------------------------------------ Ölüm Ormanı: 1.4 km çitli alan + merkez kule
static func forest_death(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "OlumOrmani")
	b.view_dist = 4000.0
	var r = float(l["r"])
	Roadside._add_clear(float(l["x"]), float(l["y"]), 70.0)   # kulenin çevresi açıklık (ağaçlar kuleyi ve kapıyı örtmesin)
	b.wall_ring_at(0, 0, r, 12.0, Color(0.35, 0.3, 0.25), [[270.0, 2.0]], 1.5)
	b.box(Vector3(-r, 14, 0), Vector3(3, 3, 20), Color(0.6, 0.15, 0.12), 0, false)
	exam_tower(b, Color(0.62, 0.24, 0.18), Color(0.9, 0.84, 0.66), "天")
	b.interact(Vector3(-r + 6, 0, 0), 8, "fod_gate", "[F] 44. Alan Kapısı")
	b.finish()


## Chūnin Sınavı 2. aşama kulesi (referans: Ölüm Ormanı kulesi): yukarı daralan katlar, aralarda saçak kuşakları, pencere sıraları,
## dışa taşan odacıklar, tepede gözlem kulübesi; önünde çatılı, fenerli kapı (levha: köyün karakteri). Builder yerel (0,0) merkezde.
static func exam_tower(b: Builder, red: Color, cream: Color, sign: String) -> void:
	var y = 0.0
	for t in 7:
		var rr = 22.0 - t * 1.4
		var hh = 10.0
		b.cyl(Vector3(0, y + hh * 0.5, 0), rr * 2.0, hh, red if t % 2 == 0 else red.darkened(0.08), true, 28)
		for k in 14:   # pencere sırası
			var a = TAU * k / 14.0
			b.box(Vector3(sin(a) * (rr + 0.05), y + hh * 0.55, cos(a) * (rr + 0.05)), Vector3(1.6, 1.8, 0.3), Color(0.24, 0.16, 0.12), rad_to_deg(a), false)
		b.frustum(Vector3(0, y + hh + 0.6, 0), (rr + 3.0) * 2.0, 1.4, cream, false, 28)   # saçak kuşağı
		for q in 3:   # dışa taşan odacıklar
			var aq = deg_to_rad(40.0 + t * 53.0 + q * 120.0)
			var pq = Vector3(sin(aq) * (rr + 1.4), y + hh * 0.45, cos(aq) * (rr + 1.4))
			b.box(pq, Vector3(4.4, 4.2, 3.2), red.darkened(0.05), rad_to_deg(aq), false)
			b.roof(pq + Vector3(0, 2.8, 0), Vector3(5.2, 1.4, 4.0), cream, rad_to_deg(aq))
			b.box(pq + Vector3(sin(aq) * 1.65, 0.2, cos(aq) * 1.65), Vector3(1.6, 1.4, 0.2), Color(0.24, 0.16, 0.12), rad_to_deg(aq), false)
		y += hh + 1.2
	b.cyl(Vector3(0, y + 3.0, 0), 12.0, 6.0, red.darkened(0.15), true, 16)   # gözlem kulübesi
	b.cone(Vector3(0, y + 8.0, 0), 16.0, 5.0, cream, 16, true)
	b.cyl(Vector3(0, y + 12.0, 0), 0.4, 4.0, Color(0.3, 0.3, 0.32), false, 6)   # anten
	var dn = -22.6
	b.box(Vector3(0, 3.2, dn), Vector3(6.0, 6.4, 1.0), Color(0.12, 0.08, 0.06), 0, false)   # kapı boşluğu
	for sx in [-1.0, 1.0]:
		b.box(Vector3(sx * 3.6, 4.0, dn - 0.6), Vector3(0.9, 8.0, 0.9), Color(0.75, 0.15, 0.12))
		b.cyl(Vector3(sx * 5.2, 5.4, dn - 1.4), 1.0, 1.6, Color(1.0, 0.85, 0.55), false, 10)   # fener
	b.box(Vector3(0, 8.4, dn - 0.6), Vector3(9.6, 0.8, 1.2), Color(0.75, 0.15, 0.12))
	b.roof(Vector3(0, 9.6, dn - 1.0), Vector3(11.0, 1.8, 3.6), cream, 0.0)
	b.kanji(Vector3(0, 7.0, dn - 0.62), sign, 1.4, Color(0.95, 0.9, 0.8), 0.0)
	for k in 6:   # kapıya giden taş yol
		b.box(Vector3(0, 0.1, dn - 4.0 - k * 5.0), Vector3(5.0, 0.2, 4.4), Color(0.6, 0.58, 0.52), 0, false)
	b.interact(Vector3(0, 0, dn - 2.0), 6, "fod_tower", "[F] Merkez Kule")


static func sage_falls(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], 0.0, "GizliSelale")
	if not _fx_done.has("sage"):
		_fx_done["sage"] = true
		Waterfalls.add(b.w(Vector3(0, -2, 138)), 108.0, 40.0, 0.0)
	for k in 9:
		b.box(Vector3(-45 + k * 11, 0.5, 0 + (k % 2) * 8), Vector3(6, 1.5 + (k % 3), 6), Color(0.5, 0.5, 0.48))
	b.interact(Vector3(0, 0.5, 40), 14, "sage", "[F] Doğa enerjisini hisset (Sennin eğitimi)")
	b.finish()


## Büyük Naruto Köprüsü: Ateş kıyısından Dalga adasına, iki yakayı bulana kadar uzar
static func naruto_bridge(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], 0.0, "NarutoKoprusu")
	b.view_dist = 12000.0
	var cx = float(l["x"])
	var cy = float(l["y"])
	var n0 = 0.0
	var n1 = 0.0
	while n1 < 6000.0 and Game.terrain_height(cx, -(cy + n1)) < 2.0:
		n1 += 20.0
	while n0 > -6000.0 and Game.terrain_height(cx, -(cy + n0)) < 2.0:
		n0 -= 20.0
	n0 -= 40.0
	n1 += 40.0
	var L = n1 - n0
	var mid = (n0 + n1) * 0.5
	var k = n0
	while k < n1:
		var seg = minf(60.0, n1 - k)
		b.box(Vector3(0, 9, k + seg * 0.5), Vector3(16, 1.4, seg + 0.2), Color(0.72, 0.68, 0.6))
		for sx in [-1.0, 1.0]:
			b.box(Vector3(7.8 * sx, 10.4, k + seg * 0.5), Vector3(0.5, 1.6, seg + 0.2), Color(0.6, 0.55, 0.48), 0, false)
		b.box(Vector3(0, -12, k), Vector3(5, 42, 5), Color(0.6, 0.57, 0.5), 0, false)
		k += 60.0
	b.interact(Vector3(0, 9.6, n0 + 30), 10, "bridge", "[F] Büyük Naruto Köprüsü (%.1f km)" % (L / 1000.0))
	b.finish()


static func hideout(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "Siginak")
	b.box(Vector3(0, 60, 50), Vector3(180, 120, 100), Color(0.42, 0.4, 0.38))
	b.box(Vector3(0, 14, -1), Vector3(26, 28, 2), Color(0.3, 0.29, 0.28))
	b.box(Vector3(0, 22, -2.2), Vector3(7, 2, 0.3), Color(0.7, 0.1, 0.12), 0, false)
	b.interact(Vector3(0, 0, -8), 8, "hideout", "[F] Mühürlü taş kapı")
	b.finish()


static func camp(parent: Node3D, l: Dictionary, kind: String) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "Kamp")
	var rng = _rng(21)
	for k in 9:
		var a = k * 40.0
		var o = Builder.rot(0, 30, a)
		b.roof(Vector3(o.x, 0, o.y), Vector3(7, 4, 8), Color(0.55, 0.45, 0.32).darkened(rng.randf() * 0.2), a)
	b.cyl(Vector3(0, 0.3, 0), 3, 0.6, Color(0.3, 0.25, 0.2), false, 8)
	Spawner.camp(b.w(Vector3.ZERO), kind, 6)
	b.finish()


static func outpost(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "Karakol")
	b.wall_rect(0, 0, 90, 90, 8.0, Color(0.55, 0.45, 0.32))
	for sx in [-1.0, 1.0]:
		for sn in [-1.0, 1.0]:
			b.box(Vector3(45 * sx, 11, 45 * sn), Vector3(8, 22, 8), Color(0.5, 0.4, 0.28))
	b.interact(Vector3(0, 0, -36), 7, "mission_board", "[F] Sınır Komutanı (görevler)")
	b.finish()


static func storm_canyon(parent: Node3D, l: Dictionary) -> void:
	var b = Builder.new(parent, l["x"], l["y"], l["base"], "FirtinaKanyonu")
	b.view_dist = 8000.0
	var rng = _rng(31)
	var r = float(l["r"]) * 0.5
	for k in 24:
		var a = k * 15.0
		var o = Builder.rot(0, r, a)
		var h = rng.randf_range(120, 220)
		b.box(Vector3(o.x, h * 0.5, o.y), Vector3(TAU * r / 24 + 10, h, 60), Color(0.4, 0.42, 0.45), a)
	b.interact(Vector3(0, 0, 0), 14, "raiju", "[F] Fırtınanın kalbi... (S-rank)")
	b.finish()
