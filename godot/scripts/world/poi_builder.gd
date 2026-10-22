class_name PoiBuilder
extends RefCounted
## Vahşi doğa noktalarını kurar (WorldStream çağırır). Yerel koordinat: Builder (x doğu, y yukarı, n kuzey), POI merkezinde.
## NPC ve düşmanlar POI'nin bölge düğümüne eklenir: bölge silinince onlar da gider.

const STYLE := {"fire": "wood", "waves": "wood", "rivers": "wood", "grass": "wood", "sound": "wood", "rain": "ame",
	"wind": "suna", "earth": "iwa", "stone": "iwa", "north": "iwa", "lightning": "kumo", "frost": "snow", "iron": "snow",
	"water": "kiri", "hotwater": "wood", "waterfall": "wood", "whirlpool": "wood"}


static func build(parent: Node3D, p: Dictionary) -> void:
	var x := float(p["x"])
	var y := float(p["y"])
	var g := Game.terrain_height(x, -y)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p["id"])
	var node := Node3D.new()
	node.name = p["id"]
	parent.add_child(node)
	var b := Builder.new(node, x, y, g, p["id"])
	b.view_dist = 1800.0
	var style: String = STYLE.get(p.get("country", "fire"), "wood")
	match p["t"]:
		"hamlet":
			_hamlet(b, node, p, rng, style)
		"inn":
			_inn(b, node, p, rng, style)
		"camp":
			_camp(b, node, p, rng)
		"ruin":
			_ruin(b, node, p, rng)
		"shrine":
			_shrine(b, p, rng)
		"onsen":
			_onsen(b, node, p, rng)
		"dock":
			_dock(b, node, p, rng, style)
		"checkpoint":
			_checkpoint(b, node, p, rng, style)
		"tower":
			_tower(b, node, p, rng)
		"monument":
			_monument(b, p, rng)
	b.finish()


# ------------------------------------------------------------------ yardımcılar
static func _villager(node: Node3D, b: Builder, role: String, lp: Vector3, pts: Array) -> void:
	var vg = Villager.new()
	vg.role = role
	var wpts: Array = []
	for q in pts:
		var wp = b.w(q)
		wp.y = Game.terrain_height(wp.x, wp.z)
		wpts.append(wp)
	vg.points = wpts
	node.add_child(vg)
	var wp0 = b.w(lp)
	wp0.y = Game.terrain_height(wp0.x, wp0.z) + 0.1
	vg.global_position = wp0
	vg.home = wp0
	vg.goal = wp0


static func _enemy(node: Node3D, b: Builder, kind: String, i: int, lp: Vector3) -> void:
	var e = Enemy.new()
	e.setup(Enemy.archetype(kind, i))
	node.add_child(e)
	var wp = b.w(lp)
	wp.y = Game.terrain_height(wp.x, wp.z) + 0.2
	e.global_position = wp
	e.home = wp


static func _ring_pts(r: float, n: int) -> Array:
	var out = []
	for i in n:
		var a = TAU * i / n
		out.append(Vector3(cos(a) * r, 0, sin(a) * r))
	return out


static func _ground(b: Builder, x: float, n: float) -> float:
	var wp = b.w(Vector3(x, 0, n))
	return Game.terrain_height(wp.x, wp.z) - b.origin.y


static func _fence(b: Builder, cx: float, cn: float, w: float, d: float, rng: RandomNumberGenerator) -> void:
	var wood = Color(0.5, 0.38, 0.25)
	for side in 4:
		var L = w if side % 2 == 0 else d
		var steps = int(L / 2.5)
		for k in steps + 1:
			var t = -L * 0.5 + k * 2.5
			var px = cx + (t if side % 2 == 0 else (w * 0.5 if side == 1 else -w * 0.5))
			var pn = cn + ((d * 0.5 if side == 0 else -d * 0.5) if side % 2 == 0 else t)
			var gy = _ground(b, px, pn)
			b.box(Vector3(px, gy + 0.6, pn), Vector3(0.15, 1.2, 0.15), wood, 0, false)
		var mx = cx + (0.0 if side % 2 == 0 else (w * 0.5 if side == 1 else -w * 0.5))
		var mn = cn + ((d * 0.5 if side == 0 else -d * 0.5) if side % 2 == 0 else 0.0)
		var gy2 = _ground(b, mx, mn)
		b.box(Vector3(mx, gy2 + 0.9, mn), Vector3(L if side % 2 == 0 else 0.1, 0.1, 0.1 if side % 2 == 0 else L), wood, 0, false)


static func _tent(b: Builder, x: float, n: float, yaw: float, col: Color) -> void:
	var gy = _ground(b, x, n)
	b.roof(Vector3(x, gy, n), Vector3(4.2, 2.6, 5.0), col, yaw)
	b.box(Vector3(x, gy + 0.05, n), Vector3(4.0, 0.1, 4.8), col.darkened(0.4), yaw, false)


static func _campfire(b: Builder, x: float, n: float) -> void:
	var gy = _ground(b, x, n)
	for k in 7:
		var a = TAU * k / 7
		b.sphere(Vector3(x + cos(a) * 1.0, gy + 0.15, n + sin(a) * 1.0), Vector3(0.45, 0.3, 0.45), Color(0.45, 0.43, 0.4), 5)
	for k in 3:
		b.box(Vector3(x, gy + 0.25, n), Vector3(1.4, 0.18, 0.18), Color(0.35, 0.22, 0.12), k * 60.0, false)
	b.cone(Vector3(x, gy + 0.75, n), 0.9, 1.1, Color(1.0, 0.55, 0.15))
	b.cone(Vector3(x, gy + 0.65, n), 0.55, 0.8, Color(1.0, 0.85, 0.35))


# ------------------------------------------------------------------ mezra: birkaç ev, tarla, çit, kuyu, köylüler
## Mezra ev konumları (Roadside patikaları da aynı noktaları kullanır: ayrı, deterministik tohum)
static func hamlet_spots(p: Dictionary) -> Array:
	var r2 := RandomNumberGenerator.new()
	r2.seed = hash(String(p["id"]) + "_evler")
	var out: Array = []
	var nh = r2.randi_range(4, 8)
	for i in nh:
		var a = TAU * i / nh + r2.randf_range(-0.3, 0.3)
		var r = r2.randf_range(16, 38)
		out.append(Vector3(cos(a) * r, 0, sin(a) * r))
	return out


static func _hamlet(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator, style: String) -> void:
	var spots: Array = hamlet_spots(p)
	for sp in spots:
		var a = atan2(sp.z, sp.x)
		b.house(sp.x, sp.z, rng.randf_range(7, 11), rng.randf_range(6, 9), rng.randi_range(1, 2),
			rad_to_deg(-a) + 90.0, style, rng)
	# mezra süsleri: ambar, odun yığını, saman, çiçek, taş fenerler, bank
	for i in spots.size():
		var sp: Vector3 = spots[i]
		var q = sp * 1.35 + Vector3(sp.z, 0, -sp.x).normalized() * 6.0
		match i % 4:
			0:
				var gy = _ground(b, q.x, q.z)
				b.cone(Vector3(q.x, gy + 1.3, q.z), 3.0, 2.6, Color(0.85, 0.72, 0.38), 9)
				b.cyl(Vector3(q.x, gy + 0.5, q.z), 2.8, 1.0, Color(0.8, 0.66, 0.34), false, 9)
			1:
				_cart(b, q.x, q.z, rng.randf() * 360.0)
			2:
				BuildFeatures._build(b, {"t": "lantern", "x": q.x, "y": q.z, "g": _ground(b, q.x, q.z), "yaw": 0.0}, rng)
			3:
				var gy3 = _ground(b, q.x, q.z)
				b.box(Vector3(q.x, gy3 + 0.45, q.z), Vector3(2.0, 0.12, 0.6), Color(0.55, 0.4, 0.26), rng.randf() * 180.0)
	# kuyu
	var gy = _ground(b, 0, 0)
	b.cyl(Vector3(0, gy + 0.5, 0), 2.0, 1.0, Color(0.55, 0.53, 0.5), true, 10)
	b.box(Vector3(0, gy + 2.2, 0), Vector3(2.6, 0.2, 0.2), Color(0.45, 0.32, 0.2), 0, false)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(1.2 * sx, gy + 1.4, 0), Vector3(0.18, 1.8, 0.18), Color(0.45, 0.32, 0.2), 0, false)
	# tarla + çit
	var fx = rng.randf_range(45, 60) * (1 if rng.randf() < 0.5 else -1)
	_fence(b, fx, 0, 26, 20, rng)
	for k in 6:
		var rowx = fx - 10 + k * 4
		b.box(Vector3(rowx, _ground(b, rowx, 0) + 0.35, 0), Vector3(1.0, 0.7, 17), Color(0.4, 0.62, 0.25), 0, false)
	# köylüler
	var pts = _ring_pts(30, 6)
	for i in rng.randi_range(3, 5):
		_villager(node, b, ["walker", "walker", "sitter", "kid"][i % 4], spots[i % spots.size()] * 0.6, pts)


# ------------------------------------------------------------------ han: büyük iki katlı yapı, tabela, banklar, ahır
static func _inn(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator, style: String) -> void:
	var yaw := float(p.get("yaw", 0.0))
	b.house(0, 0, 18, 12, 2, yaw, style, rng)
	var fo = Builder.rot(0, -8.5, yaw)
	var gy = _ground(b, fo.x, fo.y)
	b.box(Vector3(fo.x, gy + 3.4, fo.y), Vector3(4.0, 1.2, 0.2), Color(0.45, 0.3, 0.18), yaw, false)
	b.box(Vector3(fo.x, gy + 3.4, fo.y - 0.12), Vector3(3.2, 0.7, 0.05), Color(0.9, 0.85, 0.7), yaw, false)
	for k in 3:
		var bo = Builder.rot(-5 + k * 5, -10.0, yaw)
		var by = _ground(b, bo.x, bo.y)
		b.box(Vector3(bo.x, by + 0.5, bo.y), Vector3(2.2, 0.15, 0.7), Color(0.85, 0.2, 0.18), yaw)
	# kırmızı fenerler (ışıksız süs)
	for sx in [-1.0, 1.0]:
		var lo = Builder.rot(4.0 * sx, -7.0, yaw)
		var ly = _ground(b, lo.x, lo.y)
		b.box(Vector3(lo.x, ly + 1.6, lo.y), Vector3(0.12, 3.2, 0.12), Color(0.3, 0.22, 0.15), 0, false)
		b.sphere(Vector3(lo.x, ly + 3.2, lo.y), Vector3(0.6, 0.8, 0.6), Color(0.9, 0.25, 0.15), 8)
	# ahır + öküz arabası
	var so = Builder.rot(14, 4, yaw)
	b.house(so.x, so.y, 8, 6, 1, yaw + 90, "wood", rng)
	var co = Builder.rot(10, -6, yaw)
	_cart(b, co.x, co.y, yaw + 30)
	b.interact(Vector3(fo.x, gy, fo.y), 5, "teahouse", "[F] %s: yemek ye (20 Ryō)" % p["name"])
	var io = Builder.rot(-6, -7, yaw)
	b.interact(Vector3(io.x, gy, io.y), 3.5, "inn_sleep", "[F] %s: odada uyu (30 Ryō, oyun kaydedilir)" % p["name"])
	_villager(node, b, "vendor", Vector3(fo.x, 0, fo.y - 1.5), [])
	for i in 2:
		_villager(node, b, "sitter", Vector3(-4 + i * 8, 0, -10), [])
	_villager(node, b, "walker", Vector3(8, 0, -12), _ring_pts(14, 5))


static func _cart(b: Builder, x: float, n: float, yaw: float) -> void:
	var gy = _ground(b, x, n)
	var wood = Color(0.5, 0.36, 0.22)
	b.box(Vector3(x, gy + 1.1, n), Vector3(2.2, 0.25, 3.6), wood, yaw)
	for sx in [-1.0, 1.0]:
		var so = Builder.rot(1.2 * sx, 0, yaw)
		b.box(Vector3(x + so.x, gy + 1.5, n + so.y), Vector3(0.15, 0.6, 3.6), wood.darkened(0.1), yaw, false)
		b.disc(Vector3(x + so.x * 1.05, gy + 0.75, n + so.y * 1.05), 1.5, 0.15, wood.darkened(0.3), yaw + 90)
	var ho = Builder.rot(0, -2.6, yaw)
	b.box(Vector3(x + ho.x, gy + 0.9, n + ho.y), Vector3(0.12, 0.12, 2.2), wood, yaw, false)
	b.box(Vector3(x, gy + 1.6, n), Vector3(1.8, 0.8, 2.0), Color(0.75, 0.68, 0.5), yaw, false)


# ------------------------------------------------------------------ haydut kampı: çit, çadırlar, ateş, sandıklar, düşmanlar
static func _camp(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var r = 22.0
	b.wall_ring_at(0, 0, r, 3.2, Color(0.45, 0.32, 0.2), [[rng.randf_range(0, 360), 30.0]], 8.0)
	for i in 5:
		var a = TAU * i / 5 + 0.3
		_tent(b, cos(a) * 12, sin(a) * 12, rad_to_deg(-a), [Color(0.55, 0.45, 0.32), Color(0.4, 0.35, 0.3), Color(0.5, 0.2, 0.18)][i % 3])
	_campfire(b, 0, 0)
	for k in 4:
		var a = rng.randf() * TAU
		var cx = cos(a) * 6; var cn = sin(a) * 6
		b.box(Vector3(cx, _ground(b, cx, cn) + 0.5, cn), Vector3(1.0, 1.0, 1.0), Color(0.55, 0.42, 0.25), rng.randf() * 90)
	# uzaklığa göre güç: Konoha'dan uzak kamplar kaçak ninjalarla dolu
	var kv = Game.village("konoha")
	var far = Vector2(float(p["x"]), float(p["y"])).distance_to(Vector2(kv["x"], kv["y"]))
	var kind = "bandit" if far < 14000.0 else "rogue"
	for i in rng.randi_range(3, 6):
		var a = rng.randf() * TAU
		_enemy(node, b, kind if i % 3 else "bandit", i, Vector3(cos(a) * 8, 0, sin(a) * 8))


# ------------------------------------------------------------------ harabe: yıkık taş duvarlar, devrik sütunlar, tapınak kaidesi
static func _ruin(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var stone = Color(0.6, 0.57, 0.52)
	var gy = _ground(b, 0, 0)
	b.box(Vector3(0, gy + 0.6, 0), Vector3(30, 1.6, 24), stone.darkened(0.1))
	for k in 14:
		var a = TAU * k / 14
		var hgt = rng.randf_range(1.5, 9.0)
		var px = cos(a) * 13; var pn = sin(a) * 10
		if rng.randf() < 0.7:
			b.box(Vector3(px, gy + 1.4 + hgt * 0.5, pn), Vector3(4.5, hgt, 1.2), stone.lightened(rng.randf_range(-0.06, 0.06)), rad_to_deg(-a) + 90)
	for k in 4:
		var cx = rng.randf_range(-9, 9); var cn = rng.randf_range(-7, 7)
		b.cyl(Vector3(cx, gy + 1.4 + 3.0, cn), 1.4, 6.0 * rng.randf_range(0.4, 1.0), stone, true, 8)
	var fx = rng.randf_range(-6, 6)
	b.box(Vector3(fx, gy + 2.0, 8), Vector3(1.4, 1.4, 9), stone.darkened(0.05), rng.randf_range(0, 180))
	for k in 6:
		b.sphere(Vector3(rng.randf_range(-15, 15), gy + 1.2, rng.randf_range(-12, 12)), Vector3(2.5, 1.2, 2.5), Color(0.3, 0.5, 0.25), 6)
	if rng.randf() < 0.5:
		for i in 2:
			_enemy(node, b, "rogue", i, Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-5, 5)))


# ------------------------------------------------------------------ tepe tapınağı: merdiven, ardışık torii, tapınak
static func _shrine(b: Builder, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var yaw := float(p.get("yaw", 0.0))
	var gy = _ground(b, 0, 0)
	b.box(Vector3(0, gy + 0.5, 0), Vector3(16, 1.0, 14), Color(0.62, 0.6, 0.56), yaw)
	b.box(Vector3(0, gy + 3.2, 0), Vector3(9, 4.4, 7), Color(0.88, 0.84, 0.74), yaw)
	b.roof(Vector3(0, gy + 5.4, 0), Vector3(12, 3.4, 10), Color(0.2, 0.22, 0.28), yaw)
	var fo = Builder.rot(0, -4.0, yaw)
	b.box(Vector3(fo.x, gy + 2.6, fo.y), Vector3(2.0, 2.4, 0.1), Color(0.8, 0.15, 0.12), yaw, false)
	for k in 5:
		var to = Builder.rot(0, -12.0 - k * 6.0, yaw)
		BuildFeatures._torii(b, to.x, to.y, _ground(b, to.x, to.y), yaw, 0.9)
	for sx in [-1.0, 1.0]:
		var lo = Builder.rot(5.0 * sx, -8.0, yaw)
		BuildFeatures._build(b, {"t": "lantern", "x": lo.x, "y": lo.y, "g": _ground(b, lo.x, lo.y), "yaw": yaw, "h": 0, "r": 0}, rng)
	b.interact(Vector3(fo.x, gy, fo.y - 1.5), 4.0, "shrine", "[F] %s: dua et" % p["name"])


# ------------------------------------------------------------------ kaplıca: kayalarla çevrili sıcak havuz + buhar
static func _onsen(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var gy = _ground(b, 0, 0)
	b.cyl(Vector3(0, gy + 0.2, 0), 18.0, 0.4, Color(0.4, 0.66, 0.72), false, 18)
	for k in 18:
		var a = TAU * k / 18
		b.sphere(Vector3(cos(a) * 9.5, gy + 0.6, sin(a) * 9.5), Vector3(2.4, 1.6, 2.0) * rng.randf_range(0.8, 1.3), Color(0.5, 0.48, 0.44), 6, k % 2 == 0)
	b.house(16, 0, 8, 6, 1, 90, "wood", rng)
	b.box(Vector3(-12, gy + 1.0, 0), Vector3(0.3, 2.0, 12), Color(0.55, 0.4, 0.26), 0)
	Steam.add(b.w(Vector3(0, gy + 0.6, 0)))
	b.interact(Vector3(0, gy, -10), 6.0, "onsen", "[F] %s: sıcak suya gir" % p["name"])
	_villager(node, b, "sitter", Vector3(14, 0, -5), [])


# ------------------------------------------------------------------ iskele: denize uzanan ahşap iskele, kayıklar, kulübe
static func _dock(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator, style: String) -> void:
	var yaw := float(p.get("yaw", 0.0))
	var wood = Color(0.52, 0.38, 0.24)
	for k in 12:
		var o = Builder.rot(0, 4.0 + k * 3.0, yaw)
		b.box(Vector3(o.x, 1.0 - b.origin.y + maxf(0.0, b.origin.y), o.y), Vector3(4.0, 0.3, 3.1), wood, yaw)
		for sx in [-1.0, 1.0]:
			var po = Builder.rot(1.8 * sx, 4.0 + k * 3.0, yaw)
			b.box(Vector3(po.x, -2.0 - b.origin.y + maxf(0.0, b.origin.y), po.y), Vector3(0.3, 6.0, 0.3), wood.darkened(0.2), yaw, false)
	for k in 2:
		var bo = Builder.rot(5.0 * (1 if k == 0 else -1), 20 + k * 8, yaw)
		b.box(Vector3(bo.x, 0.3 - b.origin.y, bo.y), Vector3(1.6, 0.6, 5.0), Color(0.45, 0.3, 0.18), yaw + 8)
	b.house(0, -8, 7, 5, 1, yaw, style, rng)
	_villager(node, b, "sitter", Vector3(0, 0, -3), [])
	_villager(node, b, "walker", Vector3(3, 0, -10), _ring_pts(10, 4))


# ------------------------------------------------------------------ sınır karakolu: yol üstünde kapı, kule, nöbetçiler
static func _checkpoint(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator, style: String) -> void:
	var yaw := float(p.get("yaw", 0.0))
	var wood = Color(0.5, 0.36, 0.22)
	var gy = _ground(b, 0, 0)
	for sx in [-1.0, 1.0]:
		var o = Builder.rot(7.0 * sx, 0, yaw)
		b.box(Vector3(o.x, gy + 4.0, o.y), Vector3(1.4, 8.0, 1.4), wood, yaw)
		var wo = Builder.rot(16.0 * sx, 0, yaw)
		b.box(Vector3(wo.x, gy + 2.2, wo.y), Vector3(16.0, 4.4, 1.0), Color(0.62, 0.58, 0.5), yaw)
	b.box(Vector3(0, gy + 8.4, 0), Vector3(16.5, 0.9, 1.8), wood.darkened(0.2), yaw)
	b.roof(Vector3(0, gy + 8.8, 0), Vector3(18, 1.6, 3.2), Color(0.25, 0.25, 0.3), yaw)
	var ho = Builder.rot(14, -8, yaw)
	b.house(ho.x, ho.y, 7, 6, 1, yaw, style, rng)
	_watchtower_at(b, -14, -6, yaw)
	var kinds = {"wind": "suna", "earth": "iwa", "lightning": "kumo", "water": "kiri"}
	for i in 2:
		_villager(node, b, "patrol", Vector3((-3 + i * 6), 0, -4), [Vector3(-4, 0, -4), Vector3(4, 0, -4), Vector3(0, 0, 6)])
	b.interact(Vector3(0, gy, -3), 4.0, "gate", "[F] Sınır nöbetçisiyle konuş")


static func _watchtower_at(b: Builder, x: float, n: float, yaw: float) -> void:
	var wood = Color(0.48, 0.34, 0.2)
	var gy = _ground(b, x, n)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(x + 1.6 * sx, gy + 6.0, n + 1.6 * sz), Vector3(0.4, 12.0, 0.4), wood, yaw)
	b.box(Vector3(x, gy + 12.2, n), Vector3(4.6, 0.4, 4.6), wood.lightened(0.05), yaw)
	for k in 4:
		var o = Builder.rot(0, 2.2, yaw + k * 90)
		b.box(Vector3(x + o.x, gy + 13.0, n + o.y), Vector3(4.6, 1.2, 0.2), wood, yaw + k * 90, false)
	b.roof(Vector3(x, gy + 14.6, n), Vector3(5.6, 2.0, 5.6), Color(0.3, 0.28, 0.3), yaw)
	for k in 10:
		b.box(Vector3(x + 2.6, gy + 0.6 + k * 1.2, n), Vector3(0.6, 0.1, 1.0), wood, yaw, false)


static func _tower(b: Builder, node: Node3D, p: Dictionary, rng: RandomNumberGenerator) -> void:
	_watchtower_at(b, 0, 0, float(p.get("yaw", 0.0)))
	_villager(node, b, "patrol", Vector3(4, 0, 2), _ring_pts(10, 4))


# ------------------------------------------------------------------ anıt: uzaktan görünen dev yapı (dev ağaç, taş muhafız, kızıl pagoda, büyük torii)
static func _monument(b: Builder, p: Dictionary, rng: RandomNumberGenerator) -> void:
	var gy = _ground(b, 0, 0)
	var name: String = p["name"]
	if name.contains("Ağaç"):
		var bark = Color(0.42, 0.3, 0.2)
		b.cyl(Vector3(0, gy + 45, 0), 12.0, 90.0, bark, true, 14)
		for k in 6:
			var a = TAU * k / 6
			b.box(Vector3(cos(a) * 7, gy + 2, sin(a) * 7), Vector3(3.0, 4.0, 10.0), bark.darkened(0.1), rad_to_deg(-a) + 90)
		for k in 7:
			var a = TAU * k / 7 + 0.4
			var hgt = 50 + k * 6
			b.box(Vector3(cos(a) * 14, gy + hgt, sin(a) * 14), Vector3(2.6, 2.0, 22.0), bark, rad_to_deg(-a) + 90)
			b.sphere(Vector3(cos(a) * 26, gy + hgt + 6, sin(a) * 26), Vector3(26, 16, 26), Color(0.3, 0.58, 0.25).lightened(rng.randf() * 0.1), 9)
		b.sphere(Vector3(0, gy + 100, 0), Vector3(48, 30, 48), Color(0.32, 0.6, 0.26), 10)
	elif name.contains("Muhafız"):
		var st = Color(0.6, 0.58, 0.54)
		b.box(Vector3(0, gy + 3, 0), Vector3(22, 6, 22), st.darkened(0.15))
		b.box(Vector3(0, gy + 22, 0), Vector3(12, 32, 8), st)
		b.sphere(Vector3(0, gy + 43, 0), Vector3(9, 10, 9), st.lightened(0.05), 10)
		for sx in [-1.0, 1.0]:
			b.box(Vector3(8.5 * sx, gy + 24, 0), Vector3(4, 24, 4), st)
		b.box(Vector3(0, gy + 30, 4.4), Vector3(2.0, 40, 0.8), st.darkened(0.1))
	elif name.contains("Pagoda"):
		var red = Color(0.78, 0.18, 0.14)
		for k in 7:
			var s = 18.0 - k * 2.0
			b.box(Vector3(0, gy + 3 + k * 9, 0), Vector3(s * 0.7, 7, s * 0.7), Color(0.9, 0.86, 0.76))
			b.roof(Vector3(0, gy + 6.5 + k * 9, 0), Vector3(s + 4, 3, s + 4), red.darkened(0.3), 0)
			b.roof(Vector3(0, gy + 6.5 + k * 9, 0), Vector3(s + 4, 3, s + 4), red.darkened(0.3), 90)
		b.cyl(Vector3(0, gy + 75, 0), 0.8, 14, Color(0.7, 0.6, 0.3), false, 6)
	else:
		BuildFeatures._torii(b, 0, 0, gy, float(p.get("yaw", 0.0)), 6.0)
