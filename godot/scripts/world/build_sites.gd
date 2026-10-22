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
			BuildKonoha.build(parent, v)
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
	var built := {}   # id -> {node, inter}
	var _t := 0.0

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
				built[id] = {"node": node, "inter": [], "before": Interact.items.size()}
				BuildSites.build_village(node, v, built[id])
			elif d > VILLAGE_FREE_R and built.has(id):
				for it in built[id]["inter"]:
					Interact.items.erase(it)
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
static func _gates(parent: Node3D, v: Dictionary) -> void:
	var angles: Array = v.get("gates", [])
	if angles.is_empty():
		return
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Gate_" + String(v["id"]))
	b.view_dist = 5000.0
	var st: Array = GATE_STYLE.get(v["id"], [Color(0.45, 0.3, 0.2), Color(0.62, 0.2, 0.18)])
	var r = float(v["r"]) * 0.95
	for a in angles:
		b.village_gate(float(a), r, 12.0, 30.0 if v["id"] != "suna" else 40.0, st[0], st[1], String(v["id"]))
	b.finish()


static func _rng(s: int) -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = s
	return r


## Kare kare kurulum için bekleme noktası
static func _yield() -> void:
	await Engine.get_main_loop().process_frame


## Evlerle doldur: merkezde sık, dışa doğru seyrek (anime köyü: yoğun merkez + dağınık dış mahalleler).
## keep_clear: [[x, n, yarıçap]]. En fazla max_houses ev; her 12 evde bir karede bekler.
static func _fill(b: Builder, r: float, inner: float, spacing: float, style: String, rng: RandomNumberGenerator, keep_clear: Array = [], max_houses := 420, big := 1.0) -> void:
	var count = 0
	var ring = inner
	while ring < r and count < max_houses:
		var dens = clampf(1.0 - (ring - inner) / maxf(r - inner, 1.0) * 0.75, 0.2, 1.0)
		var circ = TAU * ring
		var n = int(circ / spacing * dens)
		var off = rng.randf() * TAU
		for i in n:
			if count >= max_houses:
				break
			var a = off + TAU * i / maxf(n, 1)
			var rr = ring + rng.randf_range(-spacing * 0.3, spacing * 0.3)
			var px = rr * sin(a)
			var pn = rr * cos(a)
			var ok = true
			for k in keep_clear:
				if Vector2(px - k[0], pn - k[1]).length() < k[2]:
					ok = false
					break
			if not ok or rng.randf() < 0.15:
				continue
			var yaw = rad_to_deg(a) + 180.0
			b.house(px, pn, rng.randf_range(9, 15) * big, rng.randf_range(8, 12) * big, [1, 2, 2, 3, 3, 4].pick_random(), yaw, style, rng)
			count += 1
			if count % 12 == 0:
				await _yield()
				if not is_instance_valid(b.root):
					return
		ring += spacing * (1.0 + (1.0 - dens) * 1.5)


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
			b.box(Vector3((r - thick * 0.3) * sin(rad), hh - 6 + 1.5, (r - thick * 0.3) * cos(rad)), Vector3(L * 0.9, 3.0, thick * 0.5), col.lightened(0.06), a, false)
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
				b.cyl(Vector3(rr * sin(a), h * 0.5, rr * cos(a)), rng.randf_range(40, 80), h, Color(0.55, 0.57, 0.58), false, 8)
			b.cyl(Vector3(0, 130, 0), 70, 260, Color(0.55, 0.57, 0.58), false, 10)
		"iwa":
			for k in 18:
				var a = rng.randf() * TAU
				var rr = rng.randf_range(80, r * 0.9)
				var h = rng.randf_range(70, 160)
				b.box(Vector3(rr * sin(a), h * 0.5, rr * cos(a)), Vector3(50, h, 50), Color(0.52, 0.42, 0.32), rng.randf() * 90, false)
			b.cone(Vector3(0, 90, 0), 140, 180, Color(0.5, 0.4, 0.3), 10)
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
			b.cyl(Vector3(0, 45, 0), 60, 90, Color(0.58, 0.66, 0.7), false, 12)
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


# ------------------------------------------------------------------ Sunagakure: dev kayalık krater içinde kubbe şehir
static func suna(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Suna")
	b.view_dist = 6000.0
	var rng = _rng(2)
	var sand = Color(0.84, 0.7, 0.5)
	var r = float(v["r"])
	_rock_ring(b, r * 0.97, 120, 170, 120, Color(0.78, 0.6, 0.4), v.get("gates", []), rng, 3.0, 4.0)
	await _yield()
	# Kazekage kulesi: dev kubbe + "風"
	b.cyl(Vector3(0, 24, 0), 110, 48, sand.lightened(0.05), true, 40)
	b.dome(Vector3(0, 48, 0), 110, 40, sand.lightened(0.1), 40)
	b.disc(Vector3(0, 36, -55.2), 18, 0.8, Color(0.35, 0.55, 0.35))
	b.interact(Vector3(0, 0, -60), 8, "mission_board", "[F] Kazekage Ofisi (görevler)")
	# kubbeli kuleler halkası
	for k in 10:
		var a = TAU * k / 10
		var o = Vector2(sin(a), cos(a)) * 200
		b.cyl(Vector3(o.x, 20, o.y), 36, 40, sand.darkened(0.05), true, 20)
		b.dome(Vector3(o.x, 40, o.y), 36, 16, sand, 20)
	await _fill(b, r * 0.85, 130, 26, "suna", rng, [], 380)
	b.interact(Vector3(90, 0, 30), 6, "shop_items", "[F] Suna Pazarı")
	b.finish()


# ------------------------------------------------------------------ Kirigakure: sisli uçurumlar, kanallar, kubbeli kuleler
static func kiri(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kiri")
	b.view_dist = 6000.0
	var rng = _rng(3)
	var r = float(v["r"])
	_rock_ring(b, r * 0.97, 80, 130, 90, Color(0.55, 0.6, 0.62), v.get("gates", []), rng, 3.0, 4.0)
	await _yield()
	b.cyl(Vector3(0, 45, 0), 60, 90, Color(0.58, 0.66, 0.7), true, 32)
	b.dome(Vector3(0, 90, 0), 64, 24, Color(0.3, 0.42, 0.55), 32)
	b.disc(Vector3(0, 60, -30.2), 14, 0.6, Color(0.25, 0.45, 0.65))
	b.interact(Vector3(0, 0, -34), 7, "mission_board", "[F] Mizukage Ofisi (görevler)")
	for k in 8:
		var a = TAU * k / 8 + 0.2
		var o = Vector2(sin(a), cos(a)) * rng.randf_range(160, 420)
		var h = rng.randf_range(40, 80)
		b.cyl(Vector3(o.x, h * 0.5, o.y), 26, h, Color(0.6, 0.66, 0.68), true, 18)
		b.dome(Vector3(o.x, h, o.y), 28, 10, Color(0.3, 0.42, 0.55), 18)
	for k in 6:
		var a = k * 60.0 + 30.0
		var o = Builder.rot(0, 300, a)
		b.box(Vector3(o.x, 0.5, o.y), Vector3(8, 1.0, 60), Color(0.4, 0.33, 0.25), a)
	await _fill(b, r * 0.85, 60, 24, "kiri", rng, [], 360)
	b.finish()


# ------------------------------------------------------------------ Kumogakure: yüzlerce metrelik kaya sivri tepeleri, tepelerinde şehir
static func kumo(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kumo")
	b.view_dist = 6000.0
	var rng = _rng(4)
	var rock = Color(0.55, 0.57, 0.55)
	var r = float(v["r"])
	var pillars = []
	for k in 30:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(90, r * 0.85)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var d = rng.randf_range(40, 85)
		var h = rng.randf_range(110, 290)
		# katmanlı sivri tepe: aşağıda geniş, yukarıda daralan
		var y = -4.0
		var layers = 5
		for i in layers:
			var lh = (h + 4.0) / layers
			var dd = d * (1.0 - float(i) / layers * 0.35)
			b.cyl(Vector3(px, y + lh * 0.5, pn), dd, lh, rock.darkened(0.1 * float(i % 2) + rng.randf_range(0, 0.08)), true, 12)
			y += lh
		pillars.append([px, pn, d * 0.65, h])
		# tepede beyaz kubbeli yapılar
		b.cyl(Vector3(px, h + 7, pn), d * 0.5, 14, Color(0.88, 0.88, 0.85), true, 14)
		b.dome(Vector3(px, h + 14, pn), d * 0.52, 7, Color(0.3, 0.5, 0.7), 14)
		if k % 6 == 5:
			await _yield()
	for i in pillars.size() - 1:
		var p0: Array = pillars[i]
		var p1: Array = pillars[i + 1]
		var L = Vector2(p1[0] - p0[0], p1[1] - p0[1]).length()
		if L < 260:
			var mid = Vector3((p0[0] + p1[0]) * 0.5, minf(p0[3], p1[3]) - 6, (p0[1] + p1[1]) * 0.5)
			b.box(mid, Vector3(5, 1.0, L - p0[2] * 0.5), Color(0.45, 0.35, 0.25), rad_to_deg(atan2(p1[0] - p0[0], p1[1] - p0[1])))
	# Raikage kulesi
	b.cyl(Vector3(0, 130, 0), 80, 260, rock, true, 24)
	b.cyl(Vector3(0, 268, 0), 60, 18, Color(0.9, 0.9, 0.88), true, 24)
	b.dome(Vector3(0, 277, 0), 64, 18, Color(0.25, 0.45, 0.7), 24)
	b.interact(Vector3(0, 0, -44), 7, "mission_board", "[F] Raikage Ofisi (görevler) — tepeye duvardan koş!")
	await _fill(b, r * 0.85, 70, 30, "rock", rng, [], 300)
	b.finish()


# ------------------------------------------------------------------ Iwagakure: dev kaya kuleler, taş köprüler
static func iwa(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Iwa")
	b.view_dist = 6000.0
	var rng = _rng(5)
	var r = float(v["r"])
	var towers = []
	for k in 22:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(100, r * 0.85)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var h = rng.randf_range(60, 150)
		var w = rng.randf_range(30, 56)
		var yaw = rng.randf() * 90
		b.box(Vector3(px, h * 0.5, pn), Vector3(w, h, w * rng.randf_range(0.8, 1.2)), Color(0.52, 0.42, 0.32).darkened(rng.randf() * 0.1), yaw)
		b.box(Vector3(px, h + 2, pn), Vector3(w * 1.1, 4, w * 1.1), Color(0.45, 0.35, 0.26), yaw)
		for f in int(h / 12):
			var o = Builder.rot(0, -w * 0.5 - 0.3, yaw)
			b.box(Vector3(px + o.x, f * 12 + 6, pn + o.y), Vector3(5, 3, 0.4), Color(0.95, 0.8, 0.45) if f % 3 == 0 else Color(0.25, 0.2, 0.15), yaw, false)
		towers.append([px, pn, h])
		if k % 6 == 5:
			await _yield()
	for i in towers.size() - 1:
		var t0: Array = towers[i]
		var t1: Array = towers[i + 1]
		var L = Vector2(t1[0] - t0[0], t1[1] - t0[1]).length()
		if L < 220:
			b.box(Vector3((t0[0] + t1[0]) * 0.5, minf(t0[2], t1[2]) * 0.7, (t0[1] + t1[1]) * 0.5), Vector3(8, 3, L), Color(0.5, 0.42, 0.34), rad_to_deg(atan2(t1[0] - t0[0], t1[1] - t0[1])))
	b.cone(Vector3(0, 90, 0), 140, 180, Color(0.5, 0.4, 0.3), 16, true)
	b.box(Vector3(0, 60, -40), Vector3(16, 16, 1), Color(0.35, 0.28, 0.2), 0, false)
	b.interact(Vector3(0, 0, -52), 7, "mission_board", "[F] Tsuchikage Ofisi (görevler)")
	await _fill(b, r * 0.85, 90, 28, "iwa", rng, [], 300)
	b.finish()


# ------------------------------------------------------------------ Amegakure: devasa sanayi kuleleri, borular, sürekli yağmur
static func ame(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Ame")
	b.view_dist = 6000.0
	var rng = _rng(6)
	var metal = Color(0.38, 0.4, 0.43)
	var r = float(v["r"])
	b.box(Vector3(0, 150, 0), Vector3(50, 300, 50), metal.darkened(0.1))
	b.cyl(Vector3(0, 306, 0), 36, 16, metal, true, 16)
	for k in 10:
		b.cyl(Vector3(0, 260 - k * 24, 26), 5, 5, metal.lightened(0.1), false, 8)
	b.interact(Vector3(0, 0, -30), 7, "mission_board", "[F] Ame Kulesi (görevler)")
	for k in 26:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(70, r * 0.85)
		var h = rng.randf_range(60, 200)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var w = rng.randf_range(18, 34)
		b.box(Vector3(px, h * 0.5, pn), Vector3(w, h, w), metal.darkened(rng.randf_range(0, 0.15)))
		b.cyl(Vector3(px + w * 0.5 + 2, h * 0.4, pn), 3.6, h * 0.8, metal.lightened(0.05), false, 8)
		if k % 8 == 7:
			await _yield()
	await _fill(b, r * 0.85, 80, 26, "ame", rng, [], 260)
	b.finish()


# ------------------------------------------------------------------ Otogakure: gizli yeraltı sığınakları
static func oto(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Oto")
	var rng = _rng(7)
	for k in 8:
		var a = k * 45.0
		var o = Builder.rot(0, 120, a)
		b.dome(Vector3(o.x, 0, o.y), 40, 16, Color(0.42, 0.4, 0.36), 14)
		b.box(Vector3(o.x, 4, o.y - 18), Vector3(8, 8, 3), Color(0.15, 0.13, 0.12), a, false)
	b.box(Vector3(0, 10, 0), Vector3(50, 20, 50), Color(0.32, 0.3, 0.33))
	b.box(Vector3(0, 14, -25.2), Vector3(8, 8, 0.4), Color(0.5, 0.35, 0.6), 0, false)
	b.interact(Vector3(0, 0, -30), 7, "oto_lair", "[F] Ses Sığınağı")
	await _fill(b, float(v["r"]) * 0.8, 160, 28, "rock", rng, [], 120)
	b.finish()


# ------------------------------------------------------------------ Kusagakure: dev mantar ormanı + çimen köyü
static func kusa(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Kusa")
	var rng = _rng(8)
	var r = float(v["r"])
	for k in 45:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(60, r * 0.85)
		var px = rr * sin(a)
		var pn = rr * cos(a)
		var h = rng.randf_range(20, 55)
		b.cyl(Vector3(px, h * 0.5, pn), h * 0.12, h, Color(0.9, 0.88, 0.8), true, 10)
		var cap = [Color(0.75, 0.3, 0.25), Color(0.85, 0.6, 0.3), Color(0.55, 0.4, 0.6)][k % 3]
		b.dome(Vector3(px, h - 1, pn), h * 0.9, h * 0.25, cap, 14)
		b.box(Vector3(px, h - 0.6, pn), Vector3(h * 0.8, 0.5, h * 0.8), cap.darkened(0.2))
		if k % 15 == 14:
			await _yield()
	b.box(Vector3(0, 8, 0), Vector3(40, 16, 30), Color(0.6, 0.5, 0.32))
	b.roof(Vector3(0, 16, 0), Vector3(45, 8, 35), Color(0.35, 0.5, 0.28))
	b.interact(Vector3(0, 0, -18), 7, "mission_board", "[F] Kusa Köy Meclisi (görevler)")
	await _fill(b, r * 0.8, 50, 22, "wood", rng, [], 200)
	b.finish()


# ------------------------------------------------------------------ Takigakure: göl ortasında 250 m'lik dev ağaç + şelaleler
static func taki(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Taki")
	b.view_dist = 6000.0
	var rng = _rng(9)
	var r = float(v["r"])
	b.box(Vector3(0, -1.5, 0), Vector3(360, 0.2, 360), Color(0.25, 0.5, 0.6), 0, false)
	var bark = Color(0.4, 0.28, 0.18)
	b.cyl(Vector3(0, 125, 0), 70, 250, bark, true, 20)
	for k in 8:
		var a = TAU * k / 8
		b.box(Vector3(cos(a) * 40, 8, sin(a) * 40), Vector3(10, 18, 40), bark.darkened(0.1), rad_to_deg(-a) + 90)
	b.sphere(Vector3(0, 270, 0), Vector3(300, 110, 300), Color(0.22, 0.48, 0.24), 16)
	b.sphere(Vector3(80, 240, 50), Vector3(160, 70, 160), Color(0.26, 0.52, 0.26), 12)
	b.sphere(Vector3(-70, 230, -60), Vector3(150, 60, 150), Color(0.24, 0.5, 0.25), 12)
	for k in 12:
		var a = k * 30.0
		var o = Builder.rot(0, 42, a)
		b.box(Vector3(o.x, 20 + k * 16, o.y), Vector3(24, 1.5, 18), Color(0.55, 0.4, 0.25), a)
	await _yield()
	for k in 3:
		var a = k * 120.0 + 30.0
		var o = Builder.rot(0, r * 0.8, a)
		b.box(Vector3(o.x, 60, o.y), Vector3(160, 130, 60), Color(0.5, 0.48, 0.44), a)
		if not _fx_done.has("taki_%d" % k):
			_fx_done["taki_%d" % k] = true
			var fo = Builder.rot(0, r * 0.8 - 32, a)
			Waterfalls.add(b.w(Vector3(fo.x, 0, fo.y)), 120.0, 40.0, a)
	b.interact(Vector3(0, 0, -40), 7, "mission_board", "[F] Taki Liderleri (görevler)")
	await _fill(b, r * 0.75, 220, 26, "wood", rng, [], 180)
	b.finish()


# ------------------------------------------------------------------ Yugakure: kaplıca kasabası
static func yu(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Yu")
	var rng = _rng(10)
	for k in 10:
		var a = k * 36.0
		var o = Builder.rot(0, 110, a)
		b.cyl(Vector3(o.x, -0.6, o.y), 30, 1.2, Color(0.55, 0.52, 0.48), false, 18)
		b.cyl(Vector3(o.x, 0.05, o.y), 27, 0.1, Color(0.55, 0.78, 0.82), false, 18)
		if not _fx_done.has("yu_%d" % k):
			_fx_done["yu_%d" % k] = true
			Steam.add(b.w(Vector3(o.x, 0.3, o.y)))
	b.box(Vector3(0, 9, 0), Vector3(50, 18, 32), Color(0.58, 0.4, 0.26))
	b.roof(Vector3(0, 18, 0), Vector3(56, 9, 38), Color(0.25, 0.25, 0.3))
	b.interact(Vector3(0, 0, -20), 7, "onsen", "[F] Kaplıcaya gir (tam iyileşme)")
	await _fill(b, float(v["r"]) * 0.8, 160, 22, "wood", rng, [], 200)
	b.finish()


static func small_town(parent: Node3D, v: Dictionary, style: String) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], v["id"])
	var rng = _rng(hash(v["id"]))
	b.box(Vector3(0, 8, 0), Vector3(36, 16, 26), Color(0.6, 0.5, 0.4))
	b.roof(Vector3(0, 16, 0), Vector3(40, 8, 30), Color(0.9, 0.92, 0.95) if style == "snow" else Color(0.3, 0.3, 0.35))
	b.interact(Vector3(0, 0, -16), 7, "mission_board", "[F] Köy Meclisi (görevler)")
	await _fill(b, float(v["r"]) * 0.8, 40, 22, style, rng, [], 200)
	b.finish()


# ------------------------------------------------------------------ Tanigakure: dev kanyon duvarlarına oyulmuş
static func tani(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Tani")
	var rng = _rng(11)
	var L = float(v["r"]) * 1.6
	for sx in [-1.0, 1.0]:
		b.box(Vector3(150 * sx, 60, 0), Vector3(100, 130, L), Color(0.55, 0.45, 0.35))
		for k in 30:
			var n = -L * 0.45 + k * L * 0.9 / 30.0
			b.box(Vector3(99 * sx, 10 + (k % 4) * 22, n), Vector3(4, 10, 14), Color(0.62, 0.5, 0.36))
			b.box(Vector3(96 * sx, 5 + (k % 4) * 22, n), Vector3(8, 0.6, 16), Color(0.45, 0.33, 0.22))
	b.interact(Vector3(0, 0, -30), 7, "mission_board", "[F] Tani Muhtarı (görevler)")
	await _fill(b, 90, 0, 20, "wood", rng, [], 60)
	b.finish()


# ------------------------------------------------------------------ Dalga Kasabası: iskeleler
static func nami(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Nami")
	var rng = _rng(12)
	await _fill(b, float(v["r"]) * 0.75, 20, 20, "wood", rng, [], 220)
	for k in 8:
		var a = k * 22.0 + 120.0
		var o = Builder.rot(0, float(v["r"]) * 0.95, a)
		b.box(Vector3(o.x, -3.5, o.y), Vector3(6, 0.5, 80), Color(0.5, 0.38, 0.25), a)
	b.interact(Vector3(0, 0, 0), 7, "mission_board", "[F] Kasaba Halkı (görevler)")
	b.finish()


static func uzushio(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Uzushio")
	var rng = _rng(13)
	var r = float(v["r"])
	for k in 70:
		var a = rng.randf() * TAU
		var rr = rng.randf_range(20, r * 0.85)
		var h = rng.randf_range(2, 18)
		b.box(Vector3(rr * sin(a), h * 0.5, rr * cos(a)), Vector3(rng.randf_range(6, 24), h, rng.randf_range(2, 5)), Color(0.55, 0.5, 0.45), rng.randf() * 180)
	b.cyl(Vector3(0, 1, 0), 40, 2, Color(0.6, 0.25, 0.22), false, 24)
	b.interact(Vector3(0, 0, 0), 10, "ruins", "[F] Harabeleri incele")
	b.finish()


# ------------------------------------------------------------------ Demir Kalesi: dev samuray şatosu
static func tetsu(parent: Node3D, v: Dictionary) -> void:
	var b = Builder.new(parent, v["x"], v["y"], v["base"], "Tetsu")
	b.view_dist = 6000.0
	var rng = _rng(14)
	b.box(Vector3(0, 12, 0), Vector3(140, 24, 140), Color(0.5, 0.5, 0.52))
	for t in 5:
		var s = 100.0 - t * 18.0
		b.box(Vector3(0, 30 + t * 16, 0), Vector3(s, 16, s), Color(0.95, 0.95, 0.95))
		b.roof(Vector3(0, 38 + t * 16, 0), Vector3(s + 14, 8, s + 14), Color(0.25, 0.3, 0.35))
	b.interact(Vector3(0, 0, -74), 7, "mission_board", "[F] Samuray Generali (görevler)")
	await _fill(b, float(v["r"]) * 0.8, 120, 26, "snow", rng, [], 200)
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
		Waterfalls.add(b.w(Vector3(0, spec["river"], fall_n - 4.0)), float(spec["upper"]) - float(spec["river"]) + 2.0, 120.0, 0.0)
	# iki dev heykel şelalenin iki yanında kanyon kenarında, birbirine bakıyor
	for sx in [-1.0, 1.0]:
		_statue(b, (float(spec["half"]) + 55.0) * sx, fall_n - 40.0, rim, -90.0 * sx, rock, sx > 0.0)
	b.interact(Vector3(0, spec["river"] + 0.5, fall_n - 160.0), 20, "valley", "[F] Sonun Vadisi'nde meditasyon yap")
	b.finish()


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
	b.wall_ring_at(0, 0, r, 12.0, Color(0.35, 0.3, 0.25), [[270.0, 2.0]], 1.5)
	b.box(Vector3(-r, 14, 0), Vector3(3, 3, 20), Color(0.6, 0.15, 0.12), 0, false)
	b.cyl(Vector3(0, 35, 0), 80, 70, Color(0.75, 0.7, 0.62), true, 24)
	b.cone(Vector3(0, 82, 0), 92, 26, Color(0.4, 0.4, 0.45), 24, true)
	b.interact(Vector3(0, 0, -42), 7, "fod_tower", "[F] Merkez Kule")
	b.interact(Vector3(-r + 6, 0, 0), 8, "fod_gate", "[F] 44. Alan Kapısı")
	b.finish()


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
