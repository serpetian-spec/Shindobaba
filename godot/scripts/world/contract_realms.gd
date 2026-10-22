class_name ContractRealms
extends RefCounted
## Gizli sözleşme diyarları (dünyanın uzak köşelerinde): sözleşme imzalama + sennin eğitimi.
## Gamayama: dev mantarlar, kurbağa yağı şelalesi, taşa dönmüş öğrenci heykelleri.
## Hebiana: kaya kemer girişi, dev yılan iskeletleri, karanlık havuz.  Namekumori: yosunlu dev ağaçlar, sis, kabuklar.
## Ayrıca büyük köylerde Sözleşme Ustası (dağsız sözleşmeler).

static var _pos := {}


## Hedef koordinatın çevresinde karada, köylerden uzak bir nokta (deterministik)
static func realm_pos(id: String) -> Vector3:
	if _pos.has(id):
		return _pos[id]
	var d: Dictionary = Contracts.DEFS.get(id, {})
	if d.is_empty() or d["realm"] == "":
		return Vector3.ZERO
	var target: Vector2 = d["realm_target"]
	var best = Vector3.ZERO
	var best_s = -1e9
	for ring in 12:
		for k in 16:
			var a = k * TAU / 16.0 + ring * 0.37
			var m = target + Vector2(cos(a), sin(a)) * ring * 600.0
			var wp = Game.from_map(m)
			var h = Game.terrain_height(wp.x, wp.z)
			if h < 4.0:
				continue
			var near_v = false
			for v in Game.world_info["villages"]:
				if Vector2(float(v["x"]), float(v["y"])).distance_to(m) < float(v.get("r", 300)) + 1500.0:
					near_v = true
					break
			if near_v:
				continue
			# düzlük puanı
			var flat = 0.0
			for o in [Vector2(30, 0), Vector2(-30, 0), Vector2(0, 30), Vector2(0, -30)]:
				flat -= absf(Game.terrain_height(wp.x + o.x, wp.z + o.y) - h)
			var s = flat - ring * 8.0
			if s > best_s:
				best_s = s
				best = Vector3(wp.x, h, wp.z)
		if best_s > -20.0:
			break
	_pos[id] = best
	return best


static func build_all(parent: Node3D) -> void:
	for id in ["kurbağa", "yılan", "sümüklü"]:
		var c = realm_pos(id)
		if c == Vector3.ZERO:
			continue
		var root = Node3D.new()
		root.name = "Realm_" + id
		parent.add_child(root)
		root.global_position = c
		match id:
			"kurbağa":
				_toad_mountain(root, c)
			"yılan":
				_snake_cave(root, c)
			"sümüklü":
				_slug_forest(root, c)
		Interact.add({"pos": c + Vector3(0, 1.0, -6.0), "radius": 5.0, "kind": "contract_realm", "contract": id,
			"label": "Konuş: %s" % Contracts.DEFS[id]["elder"]})
	_keepers(parent)


static func _mesh(root: Node3D, b: MB, at := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = b.build(Props.toon())
	mi.position = at
	root.add_child(mi)
	return mi


static func _solid(root: Node3D, shape: Shape3D, at: Vector3) -> void:
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	var cs = CollisionShape3D.new()
	cs.shape = shape
	sb.add_child(cs)
	sb.position = at
	root.add_child(sb)


static func _h(c: Vector3, lx: float, lz: float) -> float:
	return Game.terrain_height(c.x + lx, c.z + lz) - c.y


static func _elder(root: Node3D, model: String, h: float, length: float, at: Vector3, name: String, tint = null) -> void:
	var parts = SummonModels.build(model, h, length)
	var n: Node3D = parts["root"]
	n.position = at
	n.rotation.y = PI
	root.add_child(n)
	if tint != null:
		var m = StandardMaterial3D.new()
		m.albedo_color = tint
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = m
	var l = Label3D.new()
	l.text = name
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 48
	l.pixel_size = 0.01
	l.outline_size = 10
	l.position = at + Vector3(0, h + 1.2, 0)
	root.add_child(l)


static func _stone(col: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.95
	return m


# ------------------------------------------------------------------ Gamayama: Kurbağa Dağı
static func _toad_mountain(root: Node3D, c: Vector3) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 1101
	var b = MB.new()
	# dev mantarlar (sap + şapka + benekler)
	for i in 11:
		var a = i * TAU / 11.0 + rng.randf_range(-0.2, 0.2)
		var r = rng.randf_range(35.0, 80.0)
		var lx = cos(a) * r
		var lz = sin(a) * r
		var y = _h(c, lx, lz)
		var sh = rng.randf_range(16.0, 42.0)
		var sr = rng.randf_range(2.0, 4.5)
		var cap_r = sr * rng.randf_range(3.5, 5.0)
		var col = [Color(0.95, 0.45, 0.2), Color(0.9, 0.25, 0.25), Color(0.98, 0.7, 0.25)][i % 3]
		b.add("cyl", Vector3(lx, y + sh * 0.5, lz), Vector3(sr * 2.0, sh, sr * 2.0), Color(0.95, 0.9, 0.78), Vector3.ZERO, 12)
		b.add("hemi", Vector3(lx, y + sh - cap_r * 0.15, lz), Vector3(cap_r * 2.0, cap_r * 1.1, cap_r * 2.0), col, Vector3.ZERO, 16)
		for k in 6:
			var sa = rng.randf() * TAU
			b.add("sphere", Vector3(lx + cos(sa) * cap_r * 0.6, y + sh + cap_r * 0.25, lz + sin(sa) * cap_r * 0.6), Vector3.ONE * cap_r * 0.25, Color(1, 0.95, 0.85), Vector3.ZERO, 6)
		var cs = CylinderShape3D.new()
		cs.radius = sr
		cs.height = sh
		_solid(root, cs, Vector3(lx, y + sh * 0.5, lz))
		var cap = CylinderShape3D.new()
		cap.radius = cap_r
		cap.height = 1.0
		_solid(root, cap, Vector3(lx, y + sh + 0.3, lz))
	# kurbağa yağı şelalesi: kayalık + şelale
	var fy = _h(c, 0, 70)
	b.add("box", Vector3(0, fy + 18.0, 75.0), Vector3(40.0, 36.0, 14.0), Color(0.45, 0.42, 0.38))
	var cliff = BoxShape3D.new()
	cliff.size = Vector3(40, 36, 14)
	_solid(root, cliff, Vector3(0, fy + 18.0, 75.0))
	b.add("cyl", Vector3(0, fy + 0.3, 64.0), Vector3(22.0, 0.6, 12.0), Color(0.75, 0.55, 0.2), Vector3.ZERO, 16)  # yağ havuzu
	Waterfalls.add(c + Vector3(0, fy, 67.8), 34.0, 10.0, 0.0)
	# meditasyon platformu ve bilge kayası
	b.add("cyl", Vector3(0, _h(c, 0, -6) + 0.4, -6.0), Vector3(9.0, 0.8, 9.0), Color(0.55, 0.52, 0.48), Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, _h(c, 0, -10) + 1.2, -10.0), Vector3(3.0, 2.4, 3.0), Color(0.5, 0.47, 0.42), Vector3.ZERO, 10)
	_mesh(root, b)
	# taşa dönmüş öğrenciler (uyarı heykelleri)
	for i in 7:
		var a = PI + (i - 3) * 0.32
		var lx = cos(a) * 22.0
		var lz = sin(a) * 22.0 + 6.0
		var parts = SummonModels.build("toad_mid", rng.randf_range(1.6, 2.4), 0.0)
		var n: Node3D = parts["root"]
		n.position = Vector3(lx, _h(c, lx, lz), lz)
		n.rotation.y = rng.randf() * TAU
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = _stone(Color(0.55, 0.55, 0.52))
		root.add_child(n)
	_elder(root, "toad_small", 1.2, 0.0, Vector3(0, _h(c, 0, -10) + 2.4, -10.0), Contracts.DEFS["kurbağa"]["elder"])
	Steam.add(c + Vector3(0, fy + 1.0, 64.0))


# ------------------------------------------------------------------ Hebiana: Yılan Mağarası
static func _snake_cave(root: Node3D, c: Vector3) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 2202
	var b = MB.new()
	var dark = Color(0.28, 0.25, 0.3)
	# kaya kemer (mağara ağzı) + çevresinde kaya kütleleri
	var y0 = _h(c, 0, 20)
	for sx in [-1.0, 1.0]:
		b.add("box", Vector3(12.0 * sx, y0 + 14.0, 20.0), Vector3(8.0, 28.0, 10.0), dark, Vector3(0, 0, 4 * sx))
		var s = BoxShape3D.new()
		s.size = Vector3(8, 28, 10)
		_solid(root, s, Vector3(12.0 * sx, y0 + 14.0, 20.0))
	b.add("box", Vector3(0, y0 + 30.0, 20.0), Vector3(34.0, 7.0, 12.0), dark.darkened(0.1))
	# mağaranın oyulduğu kaya tepesi + kemerin içindeki karanlık ağız
	b.add("sphere", Vector3(0, y0 + 6.0, 46.0), Vector3(90.0, 70.0, 60.0), dark.darkened(0.05), Vector3.ZERO, 14)
	var hill = SphereShape3D.new()
	hill.radius = 28.0
	_solid(root, hill, Vector3(0, y0 + 6.0, 48.0))
	b.add("box", Vector3(0, y0 + 11.0, 22.5), Vector3(16.0, 22.0, 3.0), Color(0.03, 0.02, 0.05))
	for i in 14:
		var a = rng.randf() * TAU
		var r = rng.randf_range(28.0, 70.0)
		var lx = cos(a) * r
		var lz = sin(a) * r + 20.0
		var s = rng.randf_range(5.0, 16.0)
		b.add("sphere", Vector3(lx, _h(c, lx, lz) + s * 0.3, lz), Vector3(s, s * 0.8, s * 1.1), dark.lightened(rng.randf_range(0.0, 0.2)), Vector3.ZERO, 8)
	# dev yılan iskeleti (kaburga kemerleri)
	for i in 12:
		var lz = -30.0 + i * 3.2
		var lx = sin(i * 0.5) * 8.0 - 20.0
		b.add("torus", Vector3(lx, _h(c, lx, lz) + 3.0, lz), Vector3(9.0 - i * 0.35, 9.0 - i * 0.35, 1.2), Color(0.88, 0.85, 0.78), Vector3(0, 90, 0), 12)
	b.add("sphere", Vector3(-20.0, _h(c, -20, -34) + 3.0, -34.0), Vector3(7.0, 5.0, 9.0), Color(0.88, 0.85, 0.78), Vector3.ZERO, 10)
	# karanlık havuz ve mumlar
	b.add("cyl", Vector3(10.0, _h(c, 10, -8) + 0.2, -8.0), Vector3(14.0, 0.3, 14.0), Color(0.1, 0.12, 0.2), Vector3.ZERO, 16)
	for k in 10:
		var a = k * TAU / 10.0
		var lx = cos(a) * 7.0
		var lz = sin(a) * 7.0 - 6.0
		b.add("cyl", Vector3(lx, _h(c, lx, lz) + 0.4, lz), Vector3(0.25, 0.8, 0.25), Color(0.95, 0.93, 0.85), Vector3.ZERO, 6)
		b.add("sphere", Vector3(lx, _h(c, lx, lz) + 0.95, lz), Vector3(0.22, 0.32, 0.22), Color(1.0, 0.75, 0.3), Vector3.ZERO, 6)
	b.add("cyl", Vector3(0, _h(c, 0, -6) + 0.3, -6.0), Vector3(8.0, 0.6, 8.0), Color(0.35, 0.3, 0.38), Vector3.ZERO, 12)
	_mesh(root, b)
	_elder(root, "snake_giant", 0.9, 5.0, Vector3(0, _h(c, 0, -11) + 0.6, -11.0), Contracts.DEFS["yılan"]["elder"], Color(0.95, 0.95, 0.92))


# ------------------------------------------------------------------ Namekumori: Sisli Sümüklüböcek Ormanı
static func _slug_forest(root: Node3D, c: Vector3) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 3303
	var b = MB.new()
	for i in 16:
		var a = rng.randf() * TAU
		var r = rng.randf_range(25.0, 85.0)
		var lx = cos(a) * r
		var lz = sin(a) * r
		var y = _h(c, lx, lz)
		var th = rng.randf_range(30.0, 55.0)
		var tr = rng.randf_range(2.0, 3.5)
		b.add("cyl", Vector3(lx, y + th * 0.5, lz), Vector3(tr * 2.0, th, tr * 2.0), Color(0.35, 0.3, 0.25), Vector3.ZERO, 10)
		for k in 4:
			b.add("sphere", Vector3(lx + rng.randf_range(-6, 6), y + th * rng.randf_range(0.65, 1.0), lz + rng.randf_range(-6, 6)), Vector3.ONE * rng.randf_range(9.0, 15.0), Color(0.25, 0.55, 0.35).lightened(rng.randf_range(0.0, 0.15)), Vector3.ZERO, 10)
		b.add("cyl", Vector3(lx, y + 3.0, lz), Vector3(tr * 2.3, 6.0, tr * 2.3), Color(0.35, 0.6, 0.35), Vector3.ZERO, 10)  # yosun
		var cs = CylinderShape3D.new()
		cs.radius = tr
		cs.height = th
		_solid(root, cs, Vector3(lx, y + th * 0.5, lz))
	# dev sümüklüböcek kabukları ve parlayan mantarlar
	for i in 6:
		var a = rng.randf() * TAU
		var lx = cos(a) * rng.randf_range(15.0, 40.0)
		var lz = sin(a) * rng.randf_range(15.0, 40.0)
		b.add("hemi", Vector3(lx, _h(c, lx, lz), lz), Vector3(8.0, 5.0, 10.0), Color(0.88, 0.9, 0.95), Vector3.ZERO, 12)
	for i in 30:
		var lx = rng.randf_range(-40, 40)
		var lz = rng.randf_range(-40, 40)
		b.add("sphere", Vector3(lx, _h(c, lx, lz) + 0.4, lz), Vector3(0.8, 0.5, 0.8), Color(0.55, 0.95, 0.85), Vector3.ZERO, 6)
	b.add("cyl", Vector3(0, _h(c, 0, -6) + 0.3, -6.0), Vector3(8.0, 0.6, 8.0), Color(0.45, 0.55, 0.45), Vector3.ZERO, 12)
	_mesh(root, b)
	for k in 5:
		Steam.add(c + Vector3(rng.randf_range(-30, 30), 1.0, rng.randf_range(-30, 30)))
	_elder(root, "slug_frag", 1.6, 0.0, Vector3(0, _h(c, 0, -11) + 0.2, -11.0), Contracts.DEFS["sümüklü"]["elder"])


# ------------------------------------------------------------------ köy sözleşme ustaları
static func _keepers(parent: Node3D) -> void:
	var seen = {}
	for id in Contracts.DEFS:
		var k = String(Contracts.DEFS[id].get("keeper", ""))
		if k != "":
			seen[k] = true
	for vid in seen:
		var v = Game.village(vid)
		if v.is_empty():
			continue
		var a = deg_to_rad(205.0)
		var r = float(v.get("r", 300)) * 0.33
		var m = Vector2(float(v["x"]) + cos(a) * r, float(v["y"]) + sin(a) * r)
		var wp = Game.from_map(m)
		wp.y = Game.terrain_height(wp.x, wp.z)
		var b = MB.new()
		b.add("box", Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 2.0), Color(0.45, 0.3, 0.2))
		b.add("box", Vector3(0, 3.0, 0), Vector3(3.6, 0.3, 2.6), Color(0.7, 0.15, 0.15))
		b.add("cyl", Vector3(0, 2.0, -1.05), Vector3(0.25, 1.6, 0.25), Color(0.9, 0.85, 0.7), Vector3(0, 0, 90), 8)  # açık parşömen
		b.add("box", Vector3(0, 2.0, -1.05), Vector3(1.5, 0.9, 0.02), Color(0.95, 0.9, 0.78))
		var mi = MeshInstance3D.new()
		mi.mesh = b.build(Props.toon())
		parent.add_child(mi)
		mi.global_position = wp
		Interact.add({"pos": wp + Vector3(0, 1.0, -1.5), "radius": 4.0, "kind": "contract_keeper", "village": vid, "label": "Sözleşme Ustası"})
