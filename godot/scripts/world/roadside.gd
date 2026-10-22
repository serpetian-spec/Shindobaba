class_name Roadside
extends RefCounted
## Yol kenarı ve kırsal dolgu (WorldStream bölge kurarken çağırır).
## init(): yolların tamamı bir kez yürünür -> ~400 m'de bir yol kenarı noktası (tapınak, kamp ateşi, tezgâh, harabe kule,
## heykel, savaş alanı, dev ağaç, kaya oluşumu, mağara, kuyu-bank, saman, tabela), ~1.4 km'de bir çiftlik evi,
## 1 km'de bir mil taşı, nehir geçişlerinde köprü. Evlere / POI'lere giden toprak patikalar Game.roads'a "path" olarak eklenir
## (yol dokusu bunları da çizer, çimen çıkmaz). build_region(): o 1 km'lik bölgedeki noktaları + yol boyu süsleri kurar.

const REGION := 1024.0
const SLOT_STEP := 410.0
const FARM_STEP := 1400.0
const MILE := 1000.0
const ROADSIDE_KINDS := ["shrine", "campfire", "stall", "ruin_tower", "statue", "battlefield", "giant_tree", "rocks", "cave",
	"rest", "haystack", "jizo_row", "teahouse", "well", "torii"]

static var slots_by_region := {}   # Vector2i -> [slot]
static var _bridges: Array = []
## Bitki örtüsü dışlama: 64 m hücre -> [[x, y(harita), r]] (yapıların içine ağaç bitmesin; iş parçacığından salt okunur)
static var clear_grid := {}
const CLEAR_CELL := 64.0


static func _bridge_near(p: Vector2, r: float) -> bool:
	for q in _bridges:
		if q.distance_to(p) < r:
			return true
	return false


static func _add_clear(x: float, y: float, r: float) -> void:
	for cx in range(floori((x - r) / CLEAR_CELL), floori((x + r) / CLEAR_CELL) + 1):
		for cy in range(floori((y - r) / CLEAR_CELL), floori((y + r) / CLEAR_CELL) + 1):
			var k := Vector2i(cx, cy)
			if not clear_grid.has(k):
				clear_grid[k] = []
			clear_grid[k].append([x, y, r])


## Bu noktada bitki çıkabilir mi (harita koordinatı)
static func is_clear(x: float, y: float, pad := 0.0, scale := 1.0) -> bool:
	var lst = clear_grid.get(Vector2i(floori(x / CLEAR_CELL), floori(y / CLEAR_CELL)))
	if lst == null:
		return true
	for c in lst:
		var dx: float = x - c[0]
		var dy: float = y - c[1]
		var r: float = c[2] * scale + pad
		if dx * dx + dy * dy < r * r:
			return false
	return true
static var _inited := false


static func _key(x: float, y: float) -> Vector2i:
	return Vector2i(floori(x / REGION), floori(y / REGION))


const CLEAR_R := {"farm": 62.0, "teahouse": 16.0, "stall": 12.0, "campfire": 10.0, "giant_tree": 16.0, "battlefield": 18.0,
	"ruin_tower": 12.0, "cave": 14.0, "rocks": 10.0, "statue": 9.0, "rest": 11.0, "haystack": 11.0, "shrine": 10.0, "torii": 9.0,
	"jizo_row": 7.0, "well": 8.0, "bridge": 0.0, "milestone": 0.0}
static func _add_slot(s: Dictionary) -> void:
	var cr: float = CLEAR_R.get(s["t"], 10.0)
	if cr > 0.0:
		_add_clear(s["x"], s["y"], cr)
	var k := _key(s["x"], s["y"])
	if not slots_by_region.has(k):
		slots_by_region[k] = []
	slots_by_region[k].append(s)


static var _road_regions := {}
static func has_region(k: Vector2i) -> bool:
	if not _road_regions.has(k):
		_road_regions[k] = slots_by_region.has(k) or not Game.road_segments_near(Vector2((k.x + 0.5) * REGION, (k.y + 0.5) * REGION), REGION * 0.75).is_empty()
	return _road_regions[k]


## Köy içi mi (yol kenarı süsü köylerin içine girmesin; köye yakınsa fenerli yol)
static func _village_near(x: float, y: float) -> float:
	var best := 1e9
	for v in Game.world_info["villages"]:
		best = minf(best, Vector2(x - float(v["x"]), y - float(v["y"])).length() - float(v["r"]))
	return best


static func _near_poi(x: float, y: float, r: float) -> bool:
	for p in Game.pois:
		if absf(float(p["x"]) - x) < r and absf(float(p["y"]) - y) < r:
			return true
	return false


## Yol ağına patika ekle (Game.roads + ızgara): yol dokusu çizer, yol_at bulur, bitki üretimi kaçınır
static func add_path(pts: PackedVector2Array) -> void:
	if pts.size() < 2:
		return
	var ri: int = Game.roads.size()
	Game.roads.append({"a": "", "b": "", "kind": "path", "pts": pts})
	for si in range(pts.size() - 1):
		var a2 := pts[si]
		var b2 := pts[si + 1]
		var lo := Vector2(minf(a2.x, b2.x), minf(a2.y, b2.y)) - Vector2.ONE * 20.0
		var hi := Vector2(maxf(a2.x, b2.x), maxf(a2.y, b2.y)) + Vector2.ONE * 20.0
		for cx in range(floori(lo.x / Game.ROAD_CELL), floori(hi.x / Game.ROAD_CELL) + 1):
			for cy in range(floori(lo.y / Game.ROAD_CELL), floori(hi.y / Game.ROAD_CELL) + 1):
				var k := Vector2i(cx, cy)
				if not Game._road_grid.has(k):
					Game._road_grid[k] = []
				Game._road_grid[k].append([ri, si])


## Hafif kıvrımlı patika: a -> b arası 3 ara nokta
static func _wiggle_path(a: Vector2, b: Vector2, seed_v: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var out := PackedVector2Array([a])
	var d := b - a
	var side := Vector2(-d.y, d.x).normalized()
	for i in range(1, 4):
		var t := i / 4.0
		out.append(a + d * t + side * rng.randf_range(-1.0, 1.0) * minf(d.length() * 0.06, 12.0))
	out.append(b)
	return out


## Bir noktaya en yakın ana yol noktası
static func _nearest_road_point(m: Vector2, max_d: float) -> Vector2:
	var best := Vector2.INF
	var bd := max_d
	for e in Game.road_segments_near(m, max_d):
		var rl: Dictionary = Game.roads[e.x]
		if rl["kind"] == "path":
			continue
		var pts: PackedVector2Array = rl["pts"]
		var q := Geometry2D.get_closest_point_to_segment(m, pts[e.y], pts[e.y + 1])
		var d := q.distance_to(m)
		if d < bd:
			bd = d
			best = q
	return best


static func init() -> void:
	if _inited:
		return
	_inited = true
	var road_count := Game.roads.size()
	for ri in road_count:
		var rl: Dictionary = Game.roads[ri]
		if rl["kind"] != "road":
			continue
		var pts: PackedVector2Array = rl["pts"]
		var cum := 0.0
		var next_slot := SLOT_STEP * 0.5 + float(hash(ri) % 200)
		var next_farm := FARM_STEP * 0.6 + float(hash(ri * 7) % 500)
		var next_mile := MILE
		for si in range(pts.size() - 1):
			var a := pts[si]
			var b := pts[si + 1]
			var L := a.distance_to(b)
			if L < 0.01:
				continue
			var dir := (b - a) / L
			var side := Vector2(-dir.y, dir.x)
			var yaw := rad_to_deg(atan2(dir.x, dir.y))
			# nehir geçişi -> köprü
			for rv in Game.rivers:
				for k in range(rv.size() - 1):
					var c1 := Vector2(rv[k][0], rv[k][1])
					var c2 := Vector2(rv[k + 1][0], rv[k + 1][1])
					var hit = Geometry2D.segment_intersects_segment(a, b, c1, c2)
					if hit != null and Game.terrain_height(hit.x, -hit.y) < 0.8 and not _bridge_near(hit, 80.0):
						_bridges.append(hit)
						_add_slot({"t": "bridge", "x": hit.x, "y": hit.y, "yaw": yaw, "dx": dir.x, "dy": dir.y, "seed": hash(Vector2i(hit))})
			var t := 0.0
			while t < L:
				var here := cum + t
				var p := a + dir * t
				var vnear := _village_near(p.x, p.y)
				if here >= next_mile:
					next_mile += MILE
					if vnear > 60.0:
						var sd := 1.0 if (hash(int(here)) % 2) == 0 else -1.0
						var q := p + side * 7.5 * sd
						_add_slot({"t": "milestone", "x": q.x, "y": q.y, "yaw": yaw, "seed": int(here)})
				if here >= next_slot:
					var h := hash(Vector3i(ri, si, int(here)))
					next_slot += SLOT_STEP + float(h % 160) - 60.0
					if vnear > 120.0 and not _near_poi(p.x, p.y, 140.0):
						var sd := 1.0 if (h >> 3) % 2 == 0 else -1.0
						var q := p + side * (15.0 + float((h >> 5) % 8)) * sd
						var kind: String = ROADSIDE_KINDS[(h >> 8) % ROADSIDE_KINDS.size()]
						_add_slot({"t": kind, "x": q.x, "y": q.y, "yaw": yaw + (90.0 * sd), "seed": h})
				if here >= next_farm:
					var h2 := hash(Vector3i(ri, si, int(here) * 3))
					next_farm += FARM_STEP + float(h2 % 600) - 200.0
					if vnear > 250.0 and not _near_poi(p.x, p.y, 260.0):
						var sd2 := 1.0 if (h2 >> 2) % 2 == 0 else -1.0
						var fq := p + side * (55.0 + float((h2 >> 4) % 30)) * sd2
						var b_bio := Game.biome_at(fq.x, -fq.y)
						if not b_bio in [0, 1, 8, 9, 11, 12, 13, 14, 15]:
							_add_slot({"t": "farm", "x": fq.x, "y": fq.y, "yaw": rad_to_deg(atan2(-side.x * sd2, -side.y * sd2)), "seed": h2})
							add_path(_wiggle_path(p, fq, h2))
				t += 20.0
			cum += L
	# mevcut POI'ler: ağaç dışlama + en yakın yola patika; mezralarda evlere dallanan patikalar
	for p in Game.pois:
		_add_clear(float(p["x"]), float(p["y"]), {"hamlet": 75.0, "inn": 34.0, "camp": 30.0, "ruin": 26.0, "shrine": 18.0, "onsen": 24.0,
			"dock": 22.0, "checkpoint": 30.0, "tower": 14.0, "monument": 30.0}.get(p["t"], 20.0))
		if p["t"] in ["monument"]:
			continue
		var m := Vector2(float(p["x"]), float(p["y"]))
		var q := _nearest_road_point(m, 900.0)
		if q != Vector2.INF and q.distance_to(m) > 12.0:
			add_path(_wiggle_path(q, m, hash(p["id"])))
		if p["t"] == "hamlet":
			for s in PoiBuilder.hamlet_spots(p):
				add_path(PackedVector2Array([m, m + Vector2(s.x, s.z) * 0.82]))


# ------------------------------------------------------------------ bölge kurulumu
## Bölge kurulumunu küçük adımlara böler (ana iş parçacığında, karede bütçeyle çalıştırılır).
## Dönen iş: {steps: [Callable], i: 0, holder: {npcs, inter}}
static func make_job(node: Node3D, k: Vector2i) -> Dictionary:
	var holder := {"npcs": [], "inter": []}
	var b := Builder.new(node, 0.0, 0.0, 0.0, "YolKenari")
	b.defer_interact = holder["inter"]
	b.view_dist = 1400.0
	var steps: Array = []
	for s in slots_by_region.get(k, []):
		var parts := 3 if s["t"] == "farm" else 1
		for part in parts:
			steps.append(func():
				var rng := RandomNumberGenerator.new()
				rng.seed = int(s["seed"])
				_npc_out = holder["npcs"]
				_farm_part = part if parts > 1 else -1
				_slot(b, node, s, rng)
				_farm_part = -1
				_npc_out = null)
	var x0 := k.x * REGION
	var y0 := k.y * REGION
	for e in Game.road_segments_near(Vector2(x0 + REGION * 0.5, y0 + REGION * 0.5), REGION * 0.75):
		var rl: Dictionary = Game.roads[e.x]
		if rl["kind"] != "road":
			continue
		var pts: PackedVector2Array = rl["pts"]
		var L := pts[e.y].distance_to(pts[e.y + 1])
		var c0 := 0.0
		while c0 < L:   # uzun parçaları 120 m'lik adımlara böl
			var a0 := c0
			steps.append(func(): _along_segment(b, k, e, a0, a0 + 120.0))
			c0 += 120.0
	steps.append(func(): _wild(b, k))
	steps.append(func(): b.finish())
	return {"steps": steps, "i": 0, "holder": holder}


static func _g(x: float, n: float) -> float:
	return Game.terrain_height(x, -n)


## Yol boyu süs: köy yakınında fenerler ve ağaç sıraları, kırda ağaç/çalı kümeleri, ara sıra çit ve taş
static func _along_segment(b: Builder, k: Vector2i, e: Vector2i, t_from := 0.0, t_to := 1e9) -> void:
	var x0 := k.x * REGION
	var y0 := k.y * REGION
	if true:
		var rl: Dictionary = Game.roads[e.x]
		if rl["kind"] != "road":
			return
		var pts: PackedVector2Array = rl["pts"]
		var a := pts[e.y]
		var bb := pts[e.y + 1]
		var L := a.distance_to(bb)
		if L < 1.0:
			return
		var dir := (bb - a) / L
		var side := Vector2(-dir.y, dir.x)
		var t := fmod(float(hash(e) % 23), 23.0)
		while t < t_from:
			t += 23.0
		while t < minf(L, t_to):
			var p := a + dir * t
			t += 23.0
			if p.x < x0 or p.x >= x0 + REGION or p.y < y0 or p.y >= y0 + REGION:
				continue
			var h := hash(Vector2i(int(p.x), int(p.y)))
			if not is_clear(p.x, p.y, 10.0):
				continue
			var vnear := _village_near(p.x, p.y)
			if vnear < 0.0:
				continue
			var bio := Game.biome_at(p.x, -p.y)
			if vnear < 700.0:
				# köye giden yol: iki yanda taş fener ve sıra ağaç
				for sd in [-1.0, 1.0]:
					var q: Vector2 = p + side * 9.0 * sd
					if (h % 3) == 0:
						_stone_lantern(b, q.x, q.y)
					elif bio in [2, 6, 7, 4]:
						var rng := RandomNumberGenerator.new()
						rng.seed = h + int(sd)
						b.tree(q.x, q.y + side.y * 3.0 * sd, rng.randf_range(0.8, 1.15), rng, _g(q.x, q.y))
				continue
			if (h % 5) == 0 and bio in [2, 4, 6, 7, 10]:
				var sd2 := 1.0 if (h >> 4) % 2 == 0 else -1.0
				var q2 := p + side * (11.0 + float((h >> 6) % 6)) * sd2
				var rng2 := RandomNumberGenerator.new()
				rng2.seed = h
				b.tree(q2.x, q2.y, rng2.randf_range(0.7, 1.2), rng2, _g(q2.x, q2.y))
			elif (h % 7) == 1:
				var sd3 := 1.0 if (h >> 5) % 2 == 0 else -1.0
				var q3 := p + side * 9.0 * sd3
				_rock(b, q3.x, q3.y, 0.5 + float(h % 10) * 0.08, bio)
			elif (h % 11) == 2 and bio in [6, 7, 2]:
				# kısa çit parçası
				var sd4 := 1.0 if (h >> 2) % 2 == 0 else -1.0
				var q4 := p + side * 8.0 * sd4
				var yaw := rad_to_deg(atan2(dir.x, dir.y))
				for j in 5:
					var o := q4 + dir * (j - 2) * 2.5
					b.box(Vector3(o.x, _g(o.x, o.y) + 0.55, o.y), Vector3(0.14, 1.1, 0.14), Color(0.5, 0.38, 0.25), 0, false)
				var gy := _g(q4.x, q4.y)
				b.box(Vector3(q4.x, gy + 0.85, q4.y), Vector3(0.08, 0.1, 10.0), Color(0.5, 0.38, 0.25), yaw, false)
				b.box(Vector3(q4.x, gy + 0.45, q4.y), Vector3(0.08, 0.1, 10.0), Color(0.5, 0.38, 0.25), yaw, false)


## Yoldan uzakta: bölge başına 1-3 küçük vahşi nokta (kaya oluşumu, terk edilmiş kulübe, kamp izi, dev kütük, tapınak kalıntısı)
static func _wild(b: Builder, k: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(k.x, k.y, 911))
	for i in rng.randi_range(1, 3):
		var x := (k.x + rng.randf()) * REGION
		var y := (k.y + rng.randf()) * REGION
		if _village_near(x, y) < 150.0 or Game.road_dist(x, -y) < 40.0 or Game.wet_at(x, -y) > 0.3:
			continue
		var g := _g(x, y)
		if g < 1.0:
			continue
		var bio := Game.biome_at(x, -y)
		match rng.randi() % 5:
			0:
				_rock_formation(b, x, y, rng, bio)
			1:
				_hut(b, x, y, rng)
			2:
				_campfire_remains(b, x, y, rng)
			3:
				_fallen_giant(b, x, y, rng)
			_:
				_ruined_shrine(b, x, y, rng)


# ------------------------------------------------------------------ yol kenarı noktaları
static func _slot(b: Builder, node: Node3D, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var x: float = s["x"]
	var n: float = s["y"]
	var yaw: float = s.get("yaw", 0.0)
	var g := _g(x, n)
	if s["t"] != "bridge" and g < 0.6:
		return
	var f := {"x": x, "y": n, "g": g, "yaw": yaw}
	match s["t"]:
		"bridge":
			_bridge(b, s)
		"milestone":
			b.box(Vector3(x, g + 0.6, n), Vector3(0.5, 1.2, 0.35), Color(0.62, 0.6, 0.56), yaw)
			b.box(Vector3(x, g + 1.25, n), Vector3(0.55, 0.12, 0.4), Color(0.55, 0.53, 0.5), yaw, false)
			b.box(Vector3(x, g + 0.75, n - 0.18), Vector3(0.08, 0.6, 0.02), Color(0.15, 0.12, 0.12), yaw, false)
		"shrine":
			f["t"] = "shrine"
			BuildFeatures._build(b, f, rng)
			_flowers(b, x + 2.5, n + 1.5)
		"torii":
			BuildFeatures._torii(b, x, n, g, yaw, 0.7)
			_stone_lantern(b, x + 3.0, n - 2.0)
			_stone_lantern(b, x - 3.0, n - 2.0)
		"jizo_row":
			for j in 4:
				var o := Builder.rot(-2.4 + j * 1.6, 0, yaw)
				f["x"] = x + o.x
				f["y"] = n + o.y
				f["g"] = _g(f["x"], f["y"])
				f["t"] = "jizo"
				BuildFeatures._build(b, f, rng)
		"teahouse":
			f["t"] = "teahouse"
			BuildFeatures._build(b, f, rng)
			_villager(node, b, "vendor", Vector3(x, g, n - 5.0))
			_villager(node, b, "sitter", Vector3(x + 2.0, g, n - 6.5))
		"campfire":
			_campfire(b, x, n, g)
			for j in 3:
				var a := rng.randf() * TAU
				b.box(Vector3(x + cos(a) * 2.6, g + 0.25, n + sin(a) * 2.6), Vector3(1.8, 0.45, 0.45), Color(0.42, 0.3, 0.2), rad_to_deg(a), false)
			b.box(Vector3(x + 3.5, g + 0.08, n - 1.0), Vector3(1.0, 0.15, 2.2), Color(0.55, 0.35, 0.3), yaw, false)  # yatak
			_villager(node, b, "sitter", Vector3(x + 2.2, g, n + 1.2))
			_villager(node, b, "sitter", Vector3(x - 2.0, g, n - 1.4))
		"stall":
			var wood := Color(0.55, 0.4, 0.26)
			b.box(Vector3(x, g + 0.5, n), Vector3(3.6, 1.0, 1.6), wood, yaw)
			for sx in [-1.0, 1.0]:
				var o := Builder.rot(1.7 * sx, 0.6, yaw)
				b.box(Vector3(x + o.x, g + 1.4, n + o.y), Vector3(0.12, 2.8, 0.12), wood.darkened(0.2), yaw, false)
			b.box(Vector3(x, g + 2.8, n), Vector3(4.2, 0.12, 2.6), [Color(0.85, 0.25, 0.2), Color(0.25, 0.45, 0.75), Color(0.9, 0.75, 0.3)][rng.randi() % 3], yaw, false, Vector3(-12, 0, 0))
			for j in 4:
				var o2 := Builder.rot(-1.2 + j * 0.8, 0, yaw)
				b.box(Vector3(x + o2.x, g + 1.15, n + o2.y), Vector3(0.6, 0.3, 0.6), [Color(0.9, 0.5, 0.2), Color(0.5, 0.75, 0.3), Color(0.85, 0.2, 0.25), Color(0.95, 0.9, 0.6)][j], yaw, false)
			PoiBuilder._cart(b, x + 4.0, n + 2.0, yaw + 20.0)
			_villager(node, b, "vendor", Vector3(x, g, n + 1.5))
		"ruin_tower":
			var st := Color(0.55, 0.52, 0.48)
			b.cyl(Vector3(x, g + 4.5, n), 5.0, 9.0, st.darkened(rng.randf() * 0.1), true, 8)
			b.cyl(Vector3(x + 0.8, g + 10.0, n), 4.2, 2.5, st, false, 7)
			for j in 6:
				var a2 := rng.randf() * TAU
				b.box(Vector3(x + cos(a2) * 5.0, g + 0.4, n + sin(a2) * 5.0), Vector3(1.2, 0.8, 0.9) * rng.randf_range(0.6, 1.4), st.darkened(0.1), rng.randf() * 90.0)
			b.box(Vector3(x, g + 5.0, n - 2.45), Vector3(1.4, 2.2, 0.2), Color(0.12, 0.1, 0.1), yaw, false)
		"statue":
			var st2 := Color(0.62, 0.6, 0.57)
			b.box(Vector3(x, g + 0.8, n), Vector3(3.0, 1.6, 3.0), st2.darkened(0.1), yaw)
			b.box(Vector3(x, g + 3.4, n), Vector3(1.6, 3.6, 1.0), st2, yaw)
			b.sphere(Vector3(x, g + 5.7, n), Vector3(1.1, 1.2, 1.1), st2, 8)
			b.box(Vector3(x, g + 6.15, n), Vector3(1.2, 0.25, 1.15), st2.darkened(0.15), yaw, false)  # alın bandı
			for sx in [-1.0, 1.0]:
				var o3 := Builder.rot(0.7 * sx, -0.3, yaw)
				b.box(Vector3(x + o3.x, g + 4.2, n + o3.y), Vector3(0.45, 0.45, 1.4), st2, yaw, false, Vector3(-35, 0, 0))  # mühür yapan kollar
			_flowers(b, x + 1.8, n - 2.2)
		"battlefield":
			for j in 18:
				var a3 := rng.randf() * TAU
				var r := rng.randf_range(1.0, 14.0)
				var px := x + cos(a3) * r
				var pn := n + sin(a3) * r
				var gy := _g(px, pn)
				match j % 4:
					0:  # yere saplanmış kılıç
						b.box(Vector3(px, gy + 0.7, pn), Vector3(0.06, 1.4, 0.18), Color(0.7, 0.72, 0.76), rng.randf() * 180.0, false, Vector3(rng.randf_range(-20, 20), 0, rng.randf_range(-20, 20)))
						b.box(Vector3(px, gy + 1.45, pn), Vector3(0.35, 0.06, 0.08), Color(0.4, 0.32, 0.2), 0, false)
					1:  # kunai
						b.box(Vector3(px, gy + 0.2, pn), Vector3(0.05, 0.4, 0.1), Color(0.6, 0.62, 0.66), rng.randf() * 180.0, false, Vector3(25, 0, 10))
					2:  # kırık kalkan / zırh
						b.disc(Vector3(px, gy + 0.1, pn), 0.9, 0.08, Color(0.45, 0.42, 0.38), rng.randf() * 180.0)
					3:  # yanık iz
						b.box(Vector3(px, gy + 0.03, pn), Vector3(2.0, 0.04, 2.0), Color(0.18, 0.16, 0.15), rng.randf() * 90.0, false)
			_rock(b, x + 6.0, n + 3.0, 1.2, 7)
		"giant_tree":
			var tk := Color(0.42, 0.28, 0.17)
			b.cyl(Vector3(x, g + 11.0, n), 4.2, 22.0, tk, true, 12)
			for j in 6:
				var a4 := j * TAU / 6.0
				b.cone(Vector3(x + cos(a4) * 2.4, g + 1.2, n + sin(a4) * 2.4), 2.0, 4.0, tk.darkened(0.1), 6)
			for j in 5:
				var a5 := j * TAU / 5.0 + 0.3
				b.sphere(Vector3(x + cos(a5) * 6.0, g + 22.0 + (j % 2) * 3.0, n + sin(a5) * 6.0), Vector3(11, 7, 11), Color(0.3, 0.55, 0.22).lightened(j * 0.02), 9)
			b.sphere(Vector3(x, g + 27.0, n), Vector3(15, 9, 15), Color(0.33, 0.6, 0.24), 10)
			# shimenawa (kutsal ip)
			b.cyl(Vector3(x, g + 3.0, n), 4.6, 0.3, Color(0.92, 0.88, 0.75), false, 14)
			b.box(Vector3(x, g + 2.6, n - 2.35), Vector3(0.5, 0.6, 0.05), Color(0.97, 0.97, 0.95), yaw, false)
		"rocks":
			_rock_formation(b, x, n, rng, Game.biome_at(x, -n))
		"cave":
			var rc := Color(0.5, 0.47, 0.43)
			b.sphere(Vector3(x, g + 3.0, n + 3.0), Vector3(14, 9, 10), rc, 9, true)
			b.sphere(Vector3(x + 5.0, g + 1.5, n + 1.0), Vector3(6, 4, 6), rc.darkened(0.08), 7)
			var o4 := Builder.rot(0, -1.9, yaw)
			b.box(Vector3(x + o4.x, g + 1.8, n + o4.y), Vector3(3.6, 3.6, 0.3), Color(0.06, 0.05, 0.06), yaw, false)
			for j in 4:
				var a6 := rng.randf() * TAU
				b.sphere(Vector3(x + cos(a6) * 7.0, g + 0.5, n + sin(a6) * 5.0), Vector3(1.5, 1.0, 1.4), rc, 6)
		"rest":
			for j in 2:
				var o5 := Builder.rot(-1.6 + j * 3.2, 0, yaw)
				b.box(Vector3(x + o5.x, g + 0.45, n + o5.y), Vector3(2.0, 0.12, 0.6), Color(0.55, 0.4, 0.26), yaw)
				b.box(Vector3(x + o5.x, g + 0.22, n + o5.y), Vector3(1.8, 0.45, 0.4), Color(0.45, 0.32, 0.2), yaw, false)
			_well(b, x + 4.0, n - 2.0, _g(x + 4.0, n - 2.0))
			b.tree(x - 4.0, n + 3.0, 1.0, rng, _g(x - 4.0, n + 3.0))
		"haystack":
			for j in rng.randi_range(2, 4):
				var a7 := rng.randf() * TAU
				var px2 := x + cos(a7) * rng.randf_range(2.0, 7.0)
				var pn2 := n + sin(a7) * rng.randf_range(2.0, 7.0)
				var gy2 := _g(px2, pn2)
				b.cone(Vector3(px2, gy2 + 1.3, pn2), 3.2, 2.6, Color(0.85, 0.72, 0.38), 9)
				b.cyl(Vector3(px2, gy2 + 0.5, pn2), 3.0, 1.0, Color(0.8, 0.66, 0.34), false, 9)
			PoiBuilder._cart(b, x + 5.0, n, yaw)
		"well":
			_well(b, x, n, g)
			_flowers(b, x + 2.5, n + 2.0)
			_flowers(b, x - 2.0, n - 2.5)
		"farm":
			_farm(b, node, s, rng)


static var _farm_part := -1   # -1 hepsi; 0 evler, 1 süsler, 2 bahçe/tarla
static var _npc_out = null   # iş parçacığı kurulumunda NPC istekleri buraya toplanır
static func _villager(node: Node3D, b: Builder, role: String, p: Vector3) -> void:
	var wp := b.w(p)
	wp.y = Game.terrain_height(wp.x, wp.z) + 0.1
	if _npc_out != null:
		_npc_out.append([role, wp])


## Kurulum bittikten sonra ana iş parçacığında: NPC'leri karelere yayarak ekle
static func spawn_npcs_deferred(node: Node3D, reqs: Array) -> void:
	var i := 0
	for r in reqs:
		i += 1
		node.get_tree().create_timer(0.15 * i).timeout.connect(func():
			if not is_instance_valid(node):
				return
			var vg = Villager.new()
			vg.role = r[0]
			node.add_child(vg)
			vg.global_position = r[1]
			vg.home = r[1]
			vg.goal = r[1])


# ------------------------------------------------------------------ çiftlik evi: ev, ambar, sebze bahçesi, pirinç tarlası, çit, kuyu, çamaşır ipi, odun yığını
static func _farm(b: Builder, node: Node3D, s: Dictionary, rng: RandomNumberGenerator) -> void:
	var x: float = s["x"]
	var n: float = s["y"]
	var yaw: float = s["yaw"]
	var style := "wood"
	var bio := Game.biome_at(x, -n)
	if bio == 3 or bio == 13:
		style = "suna"
	elif bio == 8 or bio == 15:
		style = "snow"
	elif bio == 5 or bio == 9 or bio == 14:
		style = "iwa"
	var hw := rng.randf_range(8, 11)
	var hd := rng.randf_range(7, 9)
	var hf := rng.randi_range(1, 2)
	if _farm_part in [-1, 0]:
		b.house(x, n, hw, hd, hf, yaw, style, rng)
		var so := Builder.rot(11.0, 3.0, yaw)
		b.house(x + so.x, n + so.y, 6.0, 5.0, 1, yaw + 90.0, "wood", rng)   # ambar
	if _farm_part == 0:
		return
	var go := Builder.rot(0.0, 22.0, yaw)
	var gx := x + go.x
	var gn := n + go.y
	var paddy := bio in [6, 4, 10] or rng.randf() < 0.4
	if _farm_part == 2:
		_garden(b, node, rng, x, n, gx, gn, yaw, paddy)
		return
	var wo := Builder.rot(-8.0, -6.0, yaw)
	_well(b, x + wo.x, n + wo.y, _g(x + wo.x, n + wo.y))
	# çamaşır ipi
	var lo := Builder.rot(0.0, -9.0, yaw)
	var lx := x + lo.x
	var ln := n + lo.y
	var ly := _g(lx, ln)
	for sx in [-1.0, 1.0]:
		var po := Builder.rot(3.0 * sx, 0, yaw)
		b.box(Vector3(lx + po.x, ly + 1.1, ln + po.y), Vector3(0.1, 2.2, 0.1), Color(0.45, 0.33, 0.22), 0, false)
	b.box(Vector3(lx, ly + 2.1, ln), Vector3(6.0, 0.03, 0.03), Color(0.3, 0.3, 0.3), yaw, false)
	for j in 4:
		var co := Builder.rot(-2.2 + j * 1.4, 0, yaw)
		b.box(Vector3(lx + co.x, ly + 1.65, ln + co.y), Vector3(0.9, 0.8, 0.03), [Color(0.9, 0.9, 0.95), Color(0.3, 0.45, 0.75), Color(0.85, 0.3, 0.3), Color(0.95, 0.85, 0.5)][j], yaw, false)
	# odun yığını
	var wpo := Builder.rot(6.5, -5.0, yaw)
	var wy := _g(x + wpo.x, n + wpo.y)
	for j in 3:
		for kk in 4 - j:
			var o2 := Builder.rot(-0.6 + kk * 0.42 + j * 0.21, 0, yaw)
			b.cyl(Vector3(x + wpo.x + o2.x, wy + 0.22 + j * 0.38, n + wpo.y + o2.y), 0.4, 1.8, Color(0.55, 0.4, 0.26), false, 6)
	if _farm_part == -1:
		_garden(b, node, rng, x, n, gx, gn, yaw, paddy)


## Sebze bahçesi (çitli) veya pirinç tarlası + çiftçiler
static func _garden(b: Builder, node: Node3D, rng: RandomNumberGenerator, x: float, n: float, gx: float, gn: float, yaw: float, paddy: bool) -> void:
	if paddy:
		var f := {"t": "paddy", "x": gx, "y": gn, "g": _g(gx, gn), "yaw": yaw, "r": 22.0}
		BuildFeatures._build(b, f, rng)
		var f2 := f.duplicate()
		var o3 := Builder.rot(24.0, 0.0, yaw)
		f2["x"] = gx + o3.x
		f2["y"] = gn + o3.y
		f2["g"] = _g(f2["x"], f2["y"])
		BuildFeatures._build(b, f2, rng)
	else:
		var cols := [Color(0.35, 0.62, 0.25), Color(0.55, 0.72, 0.3), Color(0.7, 0.45, 0.25), Color(0.4, 0.55, 0.35), Color(0.85, 0.5, 0.2)]
		for row in 7:
			var ro := Builder.rot(-8.0 + row * 2.6, 0, yaw)
			var rx := gx + ro.x
			var rn := gn + ro.y
			b.box(Vector3(rx, _g(rx, rn) + 0.12, rn), Vector3(1.3, 0.24, 14.5), Color(0.42, 0.3, 0.2), yaw, false)  # toprak sırt
			var c: Color = cols[row % cols.size()]
			for j in 15:
				var po := Builder.rot(-8.0 + row * 2.6, -6.6 + j * 0.95, yaw)
				var px := gx + po.x
				var pn := gn + po.y
				var gy := _g(px, pn)
				if row % 3 == 2:  # sırıklı fasulye / domates
					b.box(Vector3(px, gy + 0.8, pn), Vector3(0.05, 1.4, 0.05), Color(0.55, 0.42, 0.28), 0, false)
					b.sphere(Vector3(px, gy + 0.9, pn), Vector3(0.45, 0.8, 0.45), Color(0.3, 0.55, 0.22), 5)
					b.sphere(Vector3(px + 0.15, gy + 0.85, pn), Vector3(0.14, 0.14, 0.14), Color(0.85, 0.2, 0.15), 4)
				else:
					b.sphere(Vector3(px, gy + 0.32, pn), Vector3(0.6, 0.4, 0.6), c, 6)
		PoiBuilder._fence(b, gx, gn, 22.0, 18.0, rng)
	_villager(node, b, "walker", Vector3(gx, 0, gn))
	_villager(node, b, "sitter", Vector3(x + 2.0, 0, n - 5.0))


# ------------------------------------------------------------------ küçük yapı taşları
static func _stone_lantern(b: Builder, x: float, n: float) -> void:
	var g := _g(x, n)
	BuildFeatures._build(b, {"t": "lantern", "x": x, "y": n, "g": g, "yaw": 0.0}, RandomNumberGenerator.new())


static func _flowers(b: Builder, x: float, n: float) -> void:
	var g := _g(x, n)
	var cols := [Color(0.95, 0.85, 0.3), Color(0.95, 0.5, 0.6), Color(0.85, 0.85, 1.0), Color(0.95, 0.95, 0.95), Color(0.9, 0.35, 0.3)]
	var h := hash(Vector2i(int(x * 10.0), int(n * 10.0)))
	for j in 7:
		var a := float((h >> j) % 628) / 100.0
		var r := 0.4 + float((h >> (j + 3)) % 10) * 0.12
		b.sphere(Vector3(x + cos(a) * r, g + 0.35, n + sin(a) * r), Vector3(0.28, 0.16, 0.28), cols[(h + j) % cols.size()], 5)
	b.sphere(Vector3(x, g + 0.2, n), Vector3(1.8, 0.4, 1.8), Color(0.3, 0.55, 0.25), 7)


static func _rock(b: Builder, x: float, n: float, s: float, bio: int) -> void:
	var g := _g(x, n)
	var c := Color(0.6, 0.57, 0.52) if bio != 3 else Color(0.78, 0.6, 0.42)
	b.sphere(Vector3(x, g + 0.4 * s, n), Vector3(1.8, 1.2, 1.5) * s, c, 6, s > 0.9)
	b.sphere(Vector3(x + 0.8 * s, g + 0.25 * s, n + 0.5 * s), Vector3(1.0, 0.7, 0.9) * s, c.darkened(0.1), 5)
	if bio in [2, 4, 10]:
		b.sphere(Vector3(x, g + 0.95 * s, n), Vector3(1.4, 0.3, 1.2) * s, Color(0.35, 0.55, 0.28), 5)  # yosun


static func _rock_formation(b: Builder, x: float, n: float, rng: RandomNumberGenerator, bio: int) -> void:
	var g := _g(x, n)
	var c := Color(0.58, 0.55, 0.5) if bio != 3 else Color(0.8, 0.6, 0.42)
	if bio == 3 and rng.randf() < 0.5:
		BuildFeatures._build(b, {"t": "arch", "x": x, "y": n, "g": g, "yaw": rng.randf() * 180.0, "r": 14.0, "h": 10.0}, rng)
		return
	# dengede duran kayalar + sivri taşlar
	b.sphere(Vector3(x, g + 2.0, n), Vector3(6, 4.5, 5), c, 8, true)
	b.sphere(Vector3(x + 0.6, g + 5.6, n + 0.3), Vector3(3.6, 2.8, 3.2), c.lightened(0.04), 7, true)
	for j in 4:
		var a := rng.randf() * TAU
		b.cone(Vector3(x + cos(a) * 5.5, g + 2.0, n + sin(a) * 5.5), 2.2, rng.randf_range(3.0, 6.0), c.darkened(0.08), 6)
	if bio == 8:
		b.sphere(Vector3(x, g + 4.3, n), Vector3(5.2, 0.8, 4.4), Color(0.95, 0.97, 1.0), 7)  # kar örtüsü


static func _well(b: Builder, x: float, n: float, g: float) -> void:
	b.cyl(Vector3(x, g + 0.5, n), 2.0, 1.0, Color(0.55, 0.53, 0.5), true, 10)
	b.cyl(Vector3(x, g + 0.98, n), 1.6, 0.05, Color(0.2, 0.3, 0.38), false, 10)
	for sx in [-1.0, 1.0]:
		b.box(Vector3(x + 1.1 * sx, g + 1.5, n), Vector3(0.16, 2.0, 0.16), Color(0.45, 0.32, 0.2), 0, false)
	b.roof(Vector3(x, g + 2.4, n), Vector3(3.0, 0.9, 2.4), Color(0.3, 0.3, 0.36), 0.0)


static func _campfire(b: Builder, x: float, n: float, g: float) -> void:
	for kk in 7:
		var a := TAU * kk / 7
		b.sphere(Vector3(x + cos(a) * 1.0, g + 0.15, n + sin(a) * 1.0), Vector3(0.45, 0.3, 0.45), Color(0.45, 0.43, 0.4), 5)
	for kk in 3:
		b.box(Vector3(x, g + 0.25, n), Vector3(1.4, 0.18, 0.18), Color(0.35, 0.22, 0.12), kk * 60.0, false)
	b.cone(Vector3(x, g + 0.75, n), 0.9, 1.1, Color(1.0, 0.55, 0.15))
	b.cone(Vector3(x, g + 0.65, n), 0.55, 0.8, Color(1.0, 0.85, 0.35))


static func _campfire_remains(b: Builder, x: float, n: float, rng: RandomNumberGenerator) -> void:
	var g := _g(x, n)
	for kk in 7:
		var a := TAU * kk / 7
		b.sphere(Vector3(x + cos(a) * 1.0, g + 0.15, n + sin(a) * 1.0), Vector3(0.45, 0.3, 0.45), Color(0.45, 0.43, 0.4), 5)
	b.box(Vector3(x, g + 0.05, n), Vector3(1.4, 0.08, 1.4), Color(0.12, 0.1, 0.1), 0, false)
	b.box(Vector3(x + 2.5, g + 0.25, n), Vector3(1.8, 0.45, 0.45), Color(0.42, 0.3, 0.2), rng.randf() * 90.0, false)
	_tent_small(b, x - 4.0, n + 2.0, rng.randf() * 360.0, Color(0.55, 0.5, 0.4))


static func _tent_small(b: Builder, x: float, n: float, yaw: float, col: Color) -> void:
	var g := _g(x, n)
	b.roof(Vector3(x, g, n), Vector3(3.0, 1.9, 3.6), col, yaw)


static func _hut(b: Builder, x: float, n: float, rng: RandomNumberGenerator) -> void:
	var g := _g(x, n)
	var wood := Color(0.5, 0.38, 0.26).darkened(rng.randf() * 0.15)
	b.box(Vector3(x, g + 1.4, n), Vector3(5.0, 2.8, 4.0), wood, rng.randf() * 90.0)
	b.roof(Vector3(x, g + 2.8, n), Vector3(6.0, 1.8, 5.0), Color(0.55, 0.48, 0.3), 0.0)   # saman çatı
	b.box(Vector3(x + 3.2, g + 0.3, n), Vector3(1.6, 0.6, 1.0), Color(0.45, 0.33, 0.2), 0, false)
	_flowers(b, x - 3.0, n - 2.5)


static func _fallen_giant(b: Builder, x: float, n: float, rng: RandomNumberGenerator) -> void:
	var g := _g(x, n)
	var tk := Color(0.42, 0.29, 0.18)
	var yaw := rng.randf() * 180.0
	b.box(Vector3(x, g + 1.6, n), Vector3(3.2, 3.2, 26.0), tk, yaw, true)
	b.box(Vector3(x, g + 3.25, n), Vector3(2.4, 0.3, 22.0), Color(0.35, 0.55, 0.28), yaw, false)  # yosun
	var o := Builder.rot(0, 13.5, yaw)
	b.cyl(Vector3(x + o.x, g + 2.5, n + o.y), 5.5, 5.0, tk.darkened(0.15), true, 8)  # kök kütlesi
	for j in 3:
		var o2 := Builder.rot(rng.randf_range(-3, 3), rng.randf_range(-10, 10), yaw)
		b.sphere(Vector3(x + o2.x, g + 3.6, n + o2.y), Vector3(0.6, 0.4, 0.6), Color(0.85, 0.3, 0.25), 6)  # mantar


static func _ruined_shrine(b: Builder, x: float, n: float, rng: RandomNumberGenerator) -> void:
	var g := _g(x, n)
	var st := Color(0.55, 0.53, 0.5)
	b.box(Vector3(x, g + 0.3, n), Vector3(8, 0.6, 6), st.darkened(0.1), 0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			if rng.randf() < 0.7:
				b.cyl(Vector3(x + 3.2 * sx, g + 1.6, n + 2.2 * sz), 0.6, rng.randf_range(1.0, 3.2), Color(0.5, 0.3, 0.2), true, 6)
	BuildFeatures._torii(b, x, n - 6.0, _g(x, n - 6.0), 0.0, 0.6)
	b.box(Vector3(x + 2.0, g + 0.2, n + 3.5), Vector3(2.0, 0.4, 0.6), Color(0.55, 0.3, 0.22), 25.0, false)  # devrik kiriş


# ------------------------------------------------------------------ köprü (nehir geçişi)
static func _bridge(b: Builder, s: Dictionary) -> void:
	var x: float = s["x"]
	var n: float = s["y"]
	var d := Vector2(s["dx"], s["dy"])
	# iki yakayı bul: yükseklik su seviyesinin üstüne çıkana kadar yürü
	var half_a := 8.0
	var half_b := 8.0
	while half_a < 90.0 and _g(x - d.x * half_a, n - d.y * half_a) < 1.2:
		half_a += 4.0
	while half_b < 90.0 and _g(x + d.x * half_b, n + d.y * half_b) < 1.2:
		half_b += 4.0
	var L := half_a + half_b + 8.0
	var cx := x + d.x * (half_b - half_a) * 0.5
	var cn := n + d.y * (half_b - half_a) * 0.5
	var deck := maxf(maxf(_g(x - d.x * half_a, n - d.y * half_a), _g(x + d.x * half_b, n + d.y * half_b)), 1.5) + 0.6
	var yaw: float = s["yaw"]
	var wood := Color(0.55, 0.38, 0.24)
	var segs := int(L / 4.0) + 1
	for kk in segs:
		var t := (kk + 0.5) / segs
		var lift := sin(t * PI) * 2.5
		var o := Vector2(d.x, d.y) * (t - 0.5) * L
		var tilt := rad_to_deg(atan(2.5 * PI * cos(t * PI) / L))
		b.box(Vector3(cx + o.x, deck + lift, cn + o.y), Vector3(9.0, 0.5, L / segs + 0.6), wood, yaw, true, Vector3(tilt, 0, 0))
		for sx in [-1.0, 1.0]:
			var ro := Builder.rot(4.3 * sx, 0, yaw)
			b.box(Vector3(cx + o.x + ro.x, deck + lift + 0.9, cn + o.y + ro.y), Vector3(0.18, 1.4, 0.18), Color(0.82, 0.2, 0.15), yaw, false)
			b.box(Vector3(cx + o.x + ro.x, deck + lift + 1.55, cn + o.y + ro.y), Vector3(0.12, 0.12, L / segs + 0.4), Color(0.82, 0.2, 0.15), yaw, false, Vector3(tilt, 0, 0))
	for kk in 4:
		var o2 := Vector2(d.x, d.y) * (kk / 3.0 - 0.5) * L * 0.75
		b.box(Vector3(cx + o2.x, deck - 4.0, cn + o2.y), Vector3(7.0, 8.0, 1.2), wood.darkened(0.25), yaw, false)
