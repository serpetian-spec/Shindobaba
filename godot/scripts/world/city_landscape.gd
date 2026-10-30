class_name CityLandscape
extends RefCounted
## Şehir peyzajı: köylerin içi dümdüz çimen/taş kalmasın diye evlerin bahçeleri, sokak ağaçları ve
## boş alanlara küçük parklar. Builder.finish() içinden (ev sayısı yeterliyse) bir kez çağrılır.
## - Bahçeler: pencere altı çiçek kutuları, kapı yanı saksılar, basamak taşları, çit/budanmış çalı,
##   yan bahçede küçük ağaç, kuyu, çamaşır ipi, bambu öbeği (iklime göre: çöl, kaya, sis, kar)
## - Sokak ağaçları: cadde kenarında evlerin arasındaki boşluklarda, taş bordürlü
## - Parklar: büyük boş çimenliklerde göl (nilüfer, saz), taş fenerler, banklar, ağaç halkası, çiçek tarhı
## Çiçekler yalnız beyaz/sarı ve düzenli (kutularda/tarhlarda); dağınık kırmızı/mor çiçek yok.
## Tekrarlanan her şey 256 m hücrelerde MultiMesh (çizim çağrısı az); çakışma Builder.solids ızgarasıyla.

const PCELL := 256.0
const VL = preload("res://scripts/world/village_life.gd")

const WOOD := Color(0.47, 0.32, 0.2)
const WOOD_D := Color(0.32, 0.22, 0.14)
const STONE := Color(0.66, 0.63, 0.58)
const STONE_D := Color(0.46, 0.44, 0.41)
const LEAF := Color(0.36, 0.66, 0.26)
const LEAF_D := Color(0.12, 0.32, 0.12)
const WHITE_F := Color(0.98, 0.97, 0.92)
const YELLOW_F := Color(1.0, 0.86, 0.3)

## Köye özel geniş işlev alanları (yerel x, n, yarıçap): buralara park/ağaç konmaz
const KEEP := {
	"konoha": [[0.0, 600.0, 105.0], [1050.0, 560.0, 85.0], [1050.0, -700.0, 100.0], [-540.0, 585.0, 90.0],
		[520.0, -620.0, 24.0], [-520.0, -250.0, 80.0], [0.0, 0.0, 30.0]],
}

## iklim -> bahçe takımı
const KITS := {
	"green": {"tree": [0, 0, 0, 1], "bush": 18, "planter": true, "hedge": LEAF, "pots": true, "well": true, "laundry": true,
		"bamboo": true, "sakura": true, "pond": true, "street_tree": [0, 0, 1], "ring": STONE},
	"mist": {"tree": [1, 1, 0], "bush": 18, "planter": true, "hedge": Color(0.28, 0.5, 0.3), "pots": true, "well": true, "laundry": true,
		"bamboo": true, "sakura": false, "pond": true, "street_tree": [1, 0], "ring": Color(0.55, 0.6, 0.64)},
	"rock": {"tree": [1, 1, 0], "bush": 18, "planter": false, "hedge": Color(0.3, 0.5, 0.26), "pots": true, "well": true, "laundry": true,
		"bamboo": false, "sakura": false, "pond": false, "street_tree": [1], "ring": Color(0.55, 0.47, 0.38), "rocks": true},
	"desert": {"tree": [7, 7, 3], "bush": 17, "planter": false, "hedge": Color(0.45, 0.55, 0.3), "pots": false, "well": true, "laundry": true,
		"bamboo": false, "sakura": false, "pond": false, "street_tree": [7], "ring": Color(0.78, 0.66, 0.48), "jars": true},
	"rain": {"tree": [1, 0], "bush": 18, "planter": true, "hedge": Color(0.26, 0.46, 0.3), "pots": true, "well": false, "laundry": false,
		"bamboo": true, "sakura": false, "pond": false, "street_tree": [1], "ring": Color(0.42, 0.44, 0.47)},
	"snow": {"tree": [1, 1], "bush": 18, "planter": false, "hedge": Color(0.3, 0.45, 0.32), "pots": false, "well": true, "laundry": false,
		"bamboo": false, "sakura": false, "pond": false, "street_tree": [1], "ring": Color(0.6, 0.62, 0.66)},
}

static var _meshes := {}
static var parks_by := {}  # köy -> [yerel park merkezi] (testler/harita için)
static var _veg := {}


static func veg(t: int) -> Mesh:
	if not _veg.has(t):
		_veg[t] = Props.vegetation_mesh(t)
	return _veg[t]


# ------------------------------------------------------------------ meshler (bir kez kurulur)
static func mesh(name: String) -> Mesh:
	if _meshes.has(name):
		return _meshes[name]
	var b = MB.new()
	var leafy := false
	match name:
		"planter_w", "planter_y", "planter_g":  # pencere altı ahşap çiçek kutusu (1.4 m)
			b.add("box", Vector3(0, 0.24, 0), Vector3(1.4, 0.42, 0.42), WOOD)
			b.add("box", Vector3(0, 0.46, 0), Vector3(1.46, 0.05, 0.48), WOOD_D)
			for i in 3:
				b.add_grad("sphere", Vector3(-0.45 + i * 0.45, 0.6, 0), Vector3(0.5, 0.36, 0.38), LEAF, LEAF_D, Vector3.ZERO, 7)
			if name != "planter_g":
				var fc = WHITE_F if name == "planter_w" else YELLOW_F
				for i in 6:
					b.add("sphere", Vector3(-0.55 + i * 0.22, 0.76 + 0.03 * (i % 2), 0.08 * (1 - 2 * (i % 2))), Vector3(0.11, 0.09, 0.11), fc, Vector3.ZERO, 5)
		"pot":  # kapı yanı toprak saksı + yuvarlak budanmış çalı
			b.add("cyl", Vector3(0, 0.28, 0), Vector3(0.62, 0.56, 0.62), Color(0.6, 0.36, 0.24), Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0.57, 0), Vector3(0.7, 0.06, 0.7), Color(0.5, 0.3, 0.2), Vector3.ZERO, 10)
			b.add_grad("sphere", Vector3(0, 0.98, 0), Vector3(0.85, 0.8, 0.85), LEAF.lightened(0.05), LEAF_D, Vector3.ZERO, 9)
			leafy = true
		"bonsai":  # mavi sırlı saksıda küçük çam
			b.add("box", Vector3(0, 0.18, 0), Vector3(0.9, 0.36, 0.55), Color(0.24, 0.36, 0.55))
			b.add("cyl", Vector3(0, 0.55, 0), Vector3(0.09, 0.5, 0.09), WOOD_D, Vector3(0, 0, 18), 5)
			b.add_grad("sphere", Vector3(0.12, 0.85, 0), Vector3(0.75, 0.3, 0.55), Color(0.3, 0.55, 0.3), Color(0.1, 0.28, 0.14), Vector3.ZERO, 7)
			b.add_grad("sphere", Vector3(-0.15, 0.72, 0.05), Vector3(0.45, 0.22, 0.4), Color(0.3, 0.55, 0.3), Color(0.1, 0.28, 0.14), Vector3.ZERO, 6)
		"jar":  # çöl: toprak küp öbeği
			b.add_grad("sphere", Vector3(0, 0.4, 0), Vector3(0.7, 0.8, 0.7), Color(0.78, 0.5, 0.32), Color(0.5, 0.3, 0.2), Vector3.ZERO, 9)
			b.add("cyl", Vector3(0, 0.82, 0), Vector3(0.36, 0.12, 0.36), Color(0.6, 0.38, 0.25), Vector3.ZERO, 8)
			b.add_grad("sphere", Vector3(0.55, 0.28, 0.2), Vector3(0.5, 0.56, 0.5), Color(0.82, 0.62, 0.42), Color(0.55, 0.38, 0.25), Vector3.ZERO, 8)
		"hedge":  # 1.6 m budanmış çit parçası (yuvarlak üst)
			b.add_grad("box", Vector3(0, 0.42, 0), Vector3(1.6, 0.84, 0.75), Color(1, 1, 1), Color(0.55, 0.6, 0.55))
			for i in 2:
				b.add_grad("sphere", Vector3(-0.4 + i * 0.8, 0.86, 0), Vector3(0.95, 0.36, 0.78), Color(1.08, 1.08, 1.08), Color(0.8, 0.82, 0.8), Vector3.ZERO, 8)
			leafy = true
		"step":  # basamak taşı
			b.add_grad("cyl", Vector3(0, 0.04, 0), Vector3(0.95, 0.14, 0.8), STONE.lightened(0.08), STONE_D, Vector3.ZERO, 7)
		"well":  # taş kuyu + ahşap çatı + kova
			b.add_grad("cyl", Vector3(0, 0.42, 0), Vector3(1.9, 0.84, 1.9), STONE.lightened(0.05), STONE_D, Vector3.ZERO, 12)
			b.add("cyl", Vector3(0, 0.85, 0), Vector3(2.0, 0.08, 2.0), STONE_D, Vector3.ZERO, 12)
			b.add("cyl", Vector3(0, 0.8, 0), Vector3(1.5, 0.05, 1.5), Color(0.12, 0.2, 0.3), Vector3.ZERO, 12)
			for sx in [-0.85, 0.85]:
				b.add("box", Vector3(sx, 1.3, 0), Vector3(0.14, 2.6, 0.14), WOOD)
			b.add("cyl", Vector3(0, 2.0, 0), Vector3(0.12, 1.8, 0.12), WOOD_D, Vector3(0, 0, 90), 6)
			for sz in [-1.0, 1.0]:
				b.add("box", Vector3(0, 2.75, sz * 0.48), Vector3(2.3, 0.08, 1.15), Color(0.36, 0.3, 0.27), Vector3(sz * 28.0, 0, 0))
			b.add("cyl", Vector3(0.3, 1.45, 0), Vector3(0.32, 0.36, 0.32), WOOD_D, Vector3.ZERO, 8)
			b.add("cyl", Vector3(0.3, 1.8, 0), Vector3(0.015, 0.4, 0.015), Color(0.8, 0.75, 0.6), Vector3.ZERO, 4)
		"bench":  # 1.8 m park bankı (arkalıklı); ön +z (Builder yerelinde -n, evlerin önü gibi)
			b.add("box", Vector3(0, 0.45, 0), Vector3(1.8, 0.08, 0.46), WOOD)
			b.add("box", Vector3(0, 0.78, -0.22), Vector3(1.8, 0.32, 0.06), WOOD, Vector3(10, 0, 0))
			for sx in [-0.75, 0.75]:
				b.add("box", Vector3(sx, 0.22, 0), Vector3(0.1, 0.44, 0.42), WOOD_D)
				b.add("box", Vector3(sx, 0.62, -0.22), Vector3(0.08, 0.4, 0.08), WOOD_D)
		"laundry":  # iki direk + ip + kurumaya asılmış çamaşırlar
			for sx in [-1.6, 1.6]:
				b.add("box", Vector3(sx, 1.0, 0), Vector3(0.1, 2.0, 0.1), WOOD)
			b.add("box", Vector3(0, 1.85, 0), Vector3(3.2, 0.025, 0.025), Color(0.9, 0.88, 0.82))
			var cc = [Color(0.96, 0.96, 0.98), Color(0.55, 0.7, 0.88), Color(0.93, 0.88, 0.72), Color(0.96, 0.96, 0.98)]
			for i in 4:
				b.add("box", Vector3(-1.1 + i * 0.72, 1.5, 0), Vector3(0.55, 0.65 - 0.1 * (i % 2), 0.03), cc[i])
		"fence":  # 2 m alçak ahşap çit
			for sx in [-1.0, 1.0]:
				b.add("box", Vector3(sx, 0.55, 0), Vector3(0.12, 1.1, 0.12), WOOD_D)
			for y in [0.4, 0.85]:
				b.add("box", Vector3(0, y, 0), Vector3(2.0, 0.09, 0.05), WOOD)
			for i in 5:
				b.add("box", Vector3(-0.8 + i * 0.4, 0.55, 0.04), Vector3(0.1, 0.95, 0.03), WOOD.lightened(0.06))
		"stone_lantern":  # taş fener (tōrō)
			b.add_grad("box", Vector3(0, 0.12, 0), Vector3(0.7, 0.24, 0.7), STONE, STONE_D)
			b.add("cyl", Vector3(0, 0.75, 0), Vector3(0.26, 1.05, 0.26), STONE, Vector3.ZERO, 8)
			b.add("box", Vector3(0, 1.32, 0), Vector3(0.6, 0.1, 0.6), STONE_D)
			b.add("box", Vector3(0, 1.58, 0), Vector3(0.46, 0.42, 0.46), STONE)
			b.add("box", Vector3(0, 1.58, -0.235), Vector3(0.24, 0.24, 0.02), Color(1.0, 0.86, 0.55))
			b.add("box", Vector3(0, 1.58, 0.235), Vector3(0.24, 0.24, 0.02), Color(1.0, 0.86, 0.55))
			b.add("cone", Vector3(0, 1.98, 0), Vector3(1.0, 0.42, 1.0), STONE_D, Vector3.ZERO, 6)
			b.add("sphere", Vector3(0, 2.25, 0), Vector3(0.18, 0.2, 0.18), STONE, Vector3.ZERO, 6)
		"flowerbed":  # taş kenarlı yükseltilmiş tarh: ortada yeşil, kenarlarda düzenli beyaz-sarı sıra
			b.add_grad("box", Vector3(0, 0.18, 0), Vector3(3.0, 0.36, 1.4), STONE, STONE_D)
			b.add("box", Vector3(0, 0.37, 0), Vector3(2.8, 0.04, 1.2), Color(0.36, 0.26, 0.18))
			for i in 5:
				b.add_grad("sphere", Vector3(-1.1 + i * 0.55, 0.55, 0), Vector3(0.55, 0.4, 0.5), LEAF, LEAF_D, Vector3.ZERO, 7)
				for sz in [-0.42, 0.42]:
					b.add("sphere", Vector3(-1.1 + i * 0.55, 0.5, sz), Vector3(0.16, 0.12, 0.16), WHITE_F if sz < 0 else YELLOW_F, Vector3.ZERO, 5)
		"lily":  # nilüfer yaprağı (+ beyaz çiçek)
			b.add("cyl", Vector3(0, 0.0, 0), Vector3(0.9, 0.03, 0.9), Color(0.3, 0.6, 0.28), Vector3.ZERO, 9)
			b.add("sphere", Vector3(0.12, 0.06, 0.05), Vector3(0.2, 0.12, 0.2), WHITE_F, Vector3.ZERO, 6)
		"pond_stone":
			b.add_grad("sphere", Vector3(0, 0.12, 0), Vector3(1.3, 0.55, 1.0), STONE.lightened(0.05), STONE_D, Vector3(0, 0, 4), 7)
		"rock_garden":  # kuru bahçe: tırmıklı çakıl + üç kaya
			b.add("box", Vector3(0, 0.03, 0), Vector3(4.0, 0.06, 2.6), Color(0.86, 0.84, 0.78))
			for i in 7:
				b.add("box", Vector3(0, 0.065, -1.05 + i * 0.35), Vector3(3.8, 0.012, 0.05), Color(0.76, 0.74, 0.68))
			b.add_grad("sphere", Vector3(-0.9, 0.3, 0.2), Vector3(1.0, 0.8, 0.8), STONE, STONE_D, Vector3(0, 20, 5), 7)
			b.add_grad("sphere", Vector3(0.4, 0.2, -0.4), Vector3(0.7, 0.5, 0.6), STONE, STONE_D, Vector3(0, 60, 0), 6)
			b.add_grad("sphere", Vector3(1.2, 0.15, 0.5), Vector3(0.5, 0.35, 0.45), STONE, STONE_D, Vector3(0, 10, 0), 6)
			b.add("sphere", Vector3(-0.9, 0.62, 0.2), Vector3(0.7, 0.2, 0.55), Color(0.36, 0.58, 0.28), Vector3.ZERO, 6)
		"sakura":  # kiraz ağacı (yalnız park ortasında, seyrek)
			var bark = Color(0.36, 0.24, 0.2)
			b.add("cyl", Vector3(0, 2.4, 0), Vector3(0.6, 4.8, 0.6), bark, Vector3(4, 0, 0), 8)
			b.add("cyl", Vector3(0.8, 4.2, 0.1), Vector3(0.26, 2.6, 0.26), bark, Vector3(0, 0, -48), 6)
			b.add("cyl", Vector3(-0.7, 4.5, -0.3), Vector3(0.24, 2.4, 0.24), bark, Vector3(-18, 0, 44), 6)
			var pk = [[Color(1.0, 0.86, 0.9), Color(0.86, 0.56, 0.66)], [Color(1.0, 0.9, 0.93), Color(0.9, 0.62, 0.7)]]
			for c in [[Vector3(0, 6.2, 0), 5.6, 0], [Vector3(2.0, 5.5, 0.6), 3.6, 1], [Vector3(-1.9, 5.8, -0.8), 3.8, 0], [Vector3(0.3, 7.4, -0.4), 3.2, 1]]:
				var s: float = c[1]
				var col: Array = pk[c[2]]
				b.add_grad("sphere", c[0], Vector3(1.0, 0.62, 1.0) * s, col[0], col[1], Vector3.ZERO, 10)
				b.add_grad("sphere", c[0] + Vector3(s * 0.3, s * 0.14, s * 0.1), Vector3(0.6, 0.42, 0.6) * s, col[0], col[1], Vector3.ZERO, 8)
			leafy = true
		_:
			if name.begins_with("ring_"):  # ağaç bordürü: 10 taş + koyu toprak
				var rc = Color.html(name.substr(5))
				b.add("cyl", Vector3(0, 0.03, 0), Vector3(1.9, 0.06, 1.9), Color(0.34, 0.25, 0.17), Vector3.ZERO, 10)
				for i in 10:
					var a = TAU * i / 10.0
					b.add_grad("box", Vector3(cos(a) * 1.05, 0.12, sin(a) * 1.05), Vector3(0.62, 0.24, 0.26), rc.lightened(0.1), rc.darkened(0.25), Vector3(0, -rad_to_deg(a) + 90.0, 0))
	var m: Mesh = b.build(Props.foliage() if leafy else Props.toon())
	_meshes[name] = m
	return m


## İklim rengine boyanmış çit: hedge mesh'i renk çarpanıyla yeniden kurulur (önbellekli)
static func hedge_mesh(col: Color) -> Mesh:
	var k = "hedge_" + col.to_html(false)
	if _meshes.has(k):
		return _meshes[k]
	var b = MB.new()
	b.add_grad("box", Vector3(0, 0.42, 0), Vector3(1.6, 0.84, 0.75), col, col.darkened(0.5))
	for i in 2:
		b.add_grad("sphere", Vector3(-0.4 + i * 0.8, 0.86, 0), Vector3(0.95, 0.36, 0.78), col.lightened(0.1), col.darkened(0.15), Vector3.ZERO, 8)
	var m = b.build(Props.foliage())
	_meshes[k] = m
	return m


# ------------------------------------------------------------------ yerleştirme bağlamı
class Ctx:
	var b: Builder
	var rng := RandomNumberGenerator.new()
	var acc := {}       # "hücre|mesh" -> [mesh, [Transform3D], uzaklık, gölge]
	var keep := {}       # 32 m ızgara (dünya xz) -> [[Vector2, yarıçap]] işlev alanları
	var roads := {}      # 16 m ızgara -> [[a, b, yarı genişlik]] (dünya xz) yakın yol parçaları
	var lanes := {}      # 8 m ızgara -> [[a, b]] döşenen patikalar (eşyalar üstüne konmasın)
	var nodes := {}      # 12 m ızgara -> [Vector2] bağlı patika/ara sokak noktaları (kapılar buraya bağlanır)
	var lane_mb := {}    # 256 m hücre -> MB (patika/ara sokak zemini: gölgesiz, birleşik)
	var kit: Dictionary
	var climate := "green"
	var count := 0
	var vid := ""
	const KC := 32.0
	const RC := 16.0
	const RM := 36.0   # yol ızgarası payı: bundan uzak yollar "yok" sayılır
	const LC := 8.0

	var async := false
	var slice_t := 0
	var dead := false

	## Oyun sırasında (akışla kurulan köyler) iş karelere bölünür: karede ~4 ms
	func busy() -> bool:
		return async and Time.get_ticks_usec() - slice_t > 6000

	func rest() -> void:
		await Engine.get_main_loop().process_frame
		slice_t = Time.get_ticks_usec()
		dead = not is_instance_valid(b.root)

	## yatay disk (göl suyu, çakıl meydan) patika meshine
	func flat_disc(x: float, n: float, y: float, d: float, h: float, col: Color, seg: int) -> void:
		var wp = b.w(Vector3(x, y, n))
		var k = Vector2i(floori(wp.x / PCELL), floori(wp.z / PCELL))
		if not lane_mb.has(k):
			lane_mb[k] = MB.new()
		lane_mb[k].add("cyl", wp, Vector3(d, h, d), col, Vector3.ZERO, seg)

	func ground(x: float, n: float) -> float:
		var wp = b.w(Vector3(x, 0, n))
		return Game.terrain_height(wp.x, wp.z) - b.origin.y - b.yoff

	func wxz(x: float, n: float) -> Vector2:
		return Vector2(b.origin.x + x, b.origin.z - n)

	func loc(p: Vector2) -> Vector2:
		return Vector2(p.x - b.origin.x, b.origin.z - p.y)

	func add_keep(p: Vector2, r: float) -> void:
		for cx in range(floori((p.x - r) / KC), floori((p.x + r) / KC) + 1):
			for cz in range(floori((p.y - r) / KC), floori((p.y + r) / KC) + 1):
				var k = Vector2i(cx, cz)
				if not keep.has(k):
					keep[k] = []
				keep[k].append([p, r])

	func add_road(a: Vector2, e: Vector2, half: float) -> void:
		var lo = Vector2(minf(a.x, e.x), minf(a.y, e.y)) - Vector2.ONE * RM
		var hi = Vector2(maxf(a.x, e.x), maxf(a.y, e.y)) + Vector2.ONE * RM
		var rec = [a, e, half]
		for cx in range(floori(lo.x / RC), floori(hi.x / RC) + 1):
			for cz in range(floori(lo.y / RC), floori(hi.y / RC) + 1):
				var k = Vector2i(cx, cz)
				# hücre merkezi parçaya RM+hücre köşegeninden uzaksa atla
				var cc = Vector2((cx + 0.5) * RC, (cz + 0.5) * RC)
				if Geometry2D.get_closest_point_to_segment(cc, a, e).distance_to(cc) > RM + RC * 0.75:
					continue
				if not roads.has(k):
					roads[k] = []
				roads[k].append(rec)

	## dünya xz noktasına en yakın yol kenarı bilgisi: [orta çizgiye uzaklık, en yakın nokta, yarı genişlik]
	func road_near(p: Vector2) -> Array:
		var lst = roads.get(Vector2i(floori(p.x / RC), floori(p.y / RC)))
		var best = [1e9, Vector2.ZERO, 0.0]
		if lst == null:
			return best
		for r in lst:
			var q = Geometry2D.get_closest_point_to_segment(p, r[0], r[1])
			var d = q.distance_to(p)
			if d < best[0]:
				best = [d, q, r[2]]
		return best

	func add_lane(a: Vector2, e: Vector2) -> void:
		var lo = Vector2(minf(a.x, e.x), minf(a.y, e.y)) - Vector2.ONE
		var hi = Vector2(maxf(a.x, e.x), maxf(a.y, e.y)) + Vector2.ONE
		for cx in range(floori(lo.x / LC), floori(hi.x / LC) + 1):
			for cz in range(floori(lo.y / LC), floori(hi.y / LC) + 1):
				var k = Vector2i(cx, cz)
				if not lanes.has(k):
					lanes[k] = []
				lanes[k].append([a, e])

	func on_lane(p: Vector2, r: float) -> bool:
		for cx in range(floori((p.x - r) / LC), floori((p.x + r) / LC) + 1):
			for cz in range(floori((p.y - r) / LC), floori((p.y + r) / LC) + 1):
				var lst = lanes.get(Vector2i(cx, cz))
				if lst == null:
					continue
				for l in lst:
					if Geometry2D.get_closest_point_to_segment(p, l[0], l[1]).distance_to(p) < r + 0.9:
						return true
		return false

	## nokta (yerel) çevresinde r yarıçapında engel yok mu (binalar, çarpışmalar, yol, patika, işlev alanları)
	func open(x: float, n: float, r: float, road_clear := 0.0) -> bool:
		var p = wxz(x, n)
		var kl = keep.get(Vector2i(floori(p.x / KC), floori(p.y / KC)))
		if kl != null:
			for k in kl:
				if p.distance_to(k[0]) < float(k[1]) + r:
					return false
		if road_clear > 0.0 and road_near(p)[0] < road_clear:
			return false
		if on_lane(p, r):
			return false
		return b.area_free(p, r)

	## mesh örneği ekle. yaw derece (Builder yerel), scl: ölçek, dist: görünürlük (m), shadow
	func put(m: Mesh, x: float, n: float, yaw: float, scl: Vector3, dist: float, shadow := false, dy := 0.0) -> void:
		var wp = b.w(Vector3(x, ground(x, n) + dy, n))
		var k = "%d|%d|%d" % [floori(wp.x / PCELL), floori(wp.z / PCELL), m.get_instance_id()]
		if not acc.has(k):
			acc[k] = [m, [], dist, shadow]
		acc[k][1].append(Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)).scaled(scl), wp))
		count += 1

	## Çarpışmalar ayrı gövdeye: gövde sahneye en sonda eklenir (sahnedeki binlerce şekilli gövdeye
	## tek tek eklemek Jolt'ta her seferinde bileşik şekli yeniden kurar: dakikalar sürüyordu)
	var body: StaticBody3D

	func _shape(sh: Shape3D, xf: Transform3D) -> void:
		if body == null:
			body = StaticBody3D.new()
			body.name = "PeyzajCarpisma"
			body.collision_layer = 1
		var cs = CollisionShape3D.new()
		cs.shape = sh
		cs.transform = xf
		body.add_child(cs)

	func solid_cyl(x: float, n: float, r: float, h: float) -> void:
		var p = b.w(Vector3(x, ground(x, n) + h * 0.5, n))
		var sh = CylinderShape3D.new()
		sh.radius = r
		sh.height = h
		_shape(sh, Transform3D(Basis.IDENTITY, p))
		b.add_solid(p, r, r, 0.0)

	func solid_box(x: float, n: float, size: Vector3, yaw: float) -> void:
		var p = b.w(Vector3(x, ground(x, n) + size.y * 0.5, n))
		var sh = BoxShape3D.new()
		sh.size = size
		_shape(sh, Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)), p))
		b.add_solid(p, size.x * 0.5, size.z * 0.5, deg_to_rad(-yaw))

	func flush() -> void:
		for k in acc:
			var e: Array = acc[k]
			var xfs: Array = e[1]
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = e[0]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				mm.set_instance_transform(i, xfs[i])
			var mmi = MultiMeshInstance3D.new()
			mmi.name = "Peyzaj"
			mmi.layers = 2
			mmi.multimesh = mm
			mmi.visibility_range_end = float(e[2]) * float(Game.settings.get("view", 1.0))
			mmi.visibility_range_end_margin = 30.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if e[3] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			b.root.add_child(mmi)
		acc.clear()
		for k in lane_mb:
			var mi = MeshInstance3D.new()
			mi.name = "Patika"
			mi.layers = 2
			mi.mesh = lane_mb[k].build(Props.toon())
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = 700.0 * float(Game.settings.get("view", 1.0))
			mi.visibility_range_end_margin = 40.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			b.root.add_child(mi)
		lane_mb.clear()
		if body != null:
			b.root.add_child(body)
			body = null


# ------------------------------------------------------------------ giriş
static func climate_of(b: Builder) -> String:
	var counts := {}
	for h in b.houses:
		counts[h[6]] = int(counts.get(h[6], 0)) + 1
	var best = "konoha"
	var bc = -1
	for s in counts:
		if counts[s] > bc:
			bc = counts[s]; best = s
	return {"konoha": "green", "wood": "green", "suna": "desert", "kiri": "mist", "iwa": "rock", "rock": "rock",
		"kumo": "rock", "ame": "rain", "snow": "snow"}.get(best, "green")


static func dress(b: Builder) -> void:
	var t0 = Time.get_ticks_usec()
	var c = Ctx.new()
	c.b = b
	c.vid = b.key
	c.rng.seed = hash(b.key) + 77
	c.climate = climate_of(b)
	c.async = b.key != "konoha" and Game.player != null and is_instance_valid(Game.player) and Game.player.is_inside_tree()
	c.slice_t = Time.get_ticks_usec()
	c.kit = KITS[c.climate]
	# işlev alanları: köye özel liste + etkileşim noktaları + canlı şehir mekânları
	var rad := 0.0
	for h in b.houses:
		rad = maxf(rad, Vector2(h[0], h[1]).length())
	rad += 25.0
	for k in KEEP.get(b.key, [[0.0, 0.0, 85.0]]):
		c.add_keep(c.wxz(k[0], k[1]), k[2])
	var cen = Vector2(b.origin.x, b.origin.z)
	for it in Interact.items:
		var p: Vector3 = it["pos"]
		var q = Vector2(p.x, p.z)
		if q.distance_to(cen) < rad + 20.0:
			c.add_keep(q, 3.0 if it["kind"] == "enter" else 14.0)
	for s in VL.sites.get(b.key, []):
		var p2: Vector3 = s["pos"]
		c.add_keep(Vector2(p2.x, p2.z), 6.0)
	# köydeki yol parçaları (harita koordinatı -> dünya xz)
	var mcen = Vector2(b.origin.x, -b.origin.z)
	for e in Game.road_segments_near(mcen, rad + 40.0):
		var rd: Dictionary = Game.roads[e.x]
		if rd["kind"] != "street" and rd["kind"] != "road":
			continue
		var pa: Vector2 = rd["pts"][e.y]
		var pb: Vector2 = rd["pts"][e.y + 1]
		if Geometry2D.get_closest_point_to_segment(mcen, pa, pb).distance_to(mcen) > rad + 40.0:
			continue
		c.add_road(Vector2(pa.x, -pa.y), Vector2(pb.x, -pb.y), 9.0 if rd["kind"] == "street" else 8.0)
	var houses: Array = b.houses
	await _house_infill(c, houses)
	if c.dead:
		return
	for h in houses:
		rad = maxf(rad, Vector2(h[0], h[1]).length() + 25.0)
	var tp = Time.get_ticks_usec()
	if c.climate in ["green", "desert", "snow"]:  # taş döşeli köylerde (Kiri, Kumo, Iwa, Ame) zemin zaten yol
		await _trunks(c, rad, houses)
		await _lanes(c, houses)
		if c.dead:
			return
	var tl = Time.get_ticks_usec()
	for h in houses:
		_yard(c, h)
		if c.busy():
			await c.rest()
			if c.dead:
				return
	var t1 = Time.get_ticks_usec()
	await _street_trees(c, rad)
	var t2 = Time.get_ticks_usec()
	await _parks(c, rad)
	if c.dead:
		return
	await CityInfill.fill(c, rad)
	if c.dead:
		return
	c.flush()
	print("Peyzaj %s (%s): %d ev, %d öğe, %.0f ms (hazırlık %.0f, patika %.0f, bahçe %.0f, sokak %.0f)" % [b.key, c.climate, houses.size(), c.count,
		(Time.get_ticks_usec() - t0) / 1000.0, (tp - t0) / 1000.0, (tl - tp) / 1000.0, (t1 - tl) / 1000.0, (t2 - t1) / 1000.0])


## Sokaklardan uzak kalan boş alanlar (köyü boş gösteriyordu): sur içinde 26 m ızgarada, 24 m içinde ev olmayan,
## yol/işlev alanı/patika dışı, düz her noktaya en yakın yola bakan bir ev. Yeni evler bahçe/patika aşamalarına girer.
static func _house_infill(c, houses: Array) -> void:
	var b: Builder = c.b
	var v: Dictionary = Game.village(b.key)
	if v.is_empty() or houses.is_empty():
		return
	var wall_r = (float(v["r"]) - 40.0) if b.key == "konoha" else float(v["r"]) * 0.95
	var lim = wall_r - 45.0
	var hg := {}
	var styles := {}
	for h in houses:
		var k = Vector2i(floori(float(h[0]) / 24.0), floori(float(h[1]) / 24.0))
		if not hg.has(k):
			hg[k] = []
		hg[k].append(Vector2(float(h[0]), float(h[1])))
		styles[h[6]] = int(styles.get(h[6], 0)) + 1
	var style = ""
	var best = -1
	for st in styles:
		if int(styles[st]) > best:
			best = styles[st]
			style = st
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(b.key) + 4242
	# akademi/hastane/dükkân yerleşkesi (büyük köylerde sur içinde) boş kalmalı
	var site = BuildSites._site_clear(v) if BuildVillageStory.STYLE.has(b.key) else []
	var g0 = c.ground(0.0, 0.0)
	var step = 26.0
	var added = 0
	var x = -lim
	while x <= lim:
		var n = -lim
		while n <= lim:
			var px = x + rng.randf_range(-5.0, 5.0)
			var pn = n + rng.randf_range(-5.0, 5.0)
			var fw = rng.randf_range(9.0, 14.0)
			var fd = rng.randf_range(8.0, 12.0)
			var fl = [1, 2, 2, 2, 3, 3][rng.randi() % 6]
			n += step
			if Vector2(px, pn).length() > lim:
				continue
			if not site.is_empty() and Vector2(px - float(site[0]), pn - float(site[1])).length() < float(site[2]) + 12.0:
				continue
			var near = false
			var kc = Vector2i(floori(px / 24.0), floori(pn / 24.0))
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					for hp in hg.get(kc + Vector2i(dx, dz), []):
						if hp.distance_to(Vector2(px, pn)) < 24.0:
							near = true
			if near:
				continue
			var gy = c.ground(px, pn)
			if absf(gy - g0) > 14.0:
				continue   # uçurum / tepe (Konoha kuzeyi, Kumo/Iwa kayalıkları)
			var slope = maxf(absf(c.ground(px + 7.0, pn) - c.ground(px - 7.0, pn)), absf(c.ground(px, pn + 7.0) - c.ground(px, pn - 7.0)))
			if slope > 3.0:
				continue
			if not c.open(px, pn, 9.0, 11.0):
				continue
			var wp: Vector2 = c.wxz(px, pn)
			var rn: Array = c.road_near(wp)
			var tgt: Vector2 = c.loc(rn[1]) if rn[0] < 80.0 else Vector2.ZERO
			var d = tgt - Vector2(px, pn)
			var yaw = rad_to_deg(atan2(d.x, d.y))
			b.house(px, pn, fw, fd, fl, yaw, style, rng)
			var k2 = Vector2i(floori(px / 24.0), floori(pn / 24.0))
			if not hg.has(k2):
				hg[k2] = []
			hg[k2].append(Vector2(px, pn))
			added += 1
			if c.busy():
				await c.rest()
				if c.dead:
					return
		x += step
	print("Boşluk doldurma %s: +%d ev" % [b.key, added])


const LANE_COL := {"green": Color(0.76, 0.66, 0.48), "mist": Color(0.64, 0.66, 0.66), "rock": Color(0.56, 0.5, 0.44),
	"desert": Color(0.72, 0.58, 0.4), "rain": Color(0.42, 0.44, 0.47), "snow": Color(0.72, 0.72, 0.75)}
const NC := 12.0


## Her evin kapısından en yakın caddeye (yoksa daha önce döşenmiş patikaya) kenarlı patika.
## Caddeye yakın evlerden başlanır; patikalar dışa doğru ağ gibi büyür. Birleşik geometri (çizim çağrısı yok).
static func _lanes(c: Ctx, houses: Array) -> void:
	var nodes: Dictionary = c.nodes
	var doors: Array = []
	for h in houses:
		var o = Builder.rot(0, -float(h[3]) * 0.5 - 0.9, h[4])
		var o2 = Builder.rot(0, -float(h[3]) * 0.5 - 4.0, h[4])
		var dw = c.wxz(h[0] + o.x, h[1] + o.y)
		var rn = c.road_near(dw)
		doors.append([rn[0], dw, rn, c.wxz(h[0] + o2.x, h[1] + o2.y)])
	doors.sort_custom(func(a, e): return a[0] < e[0])
	var made = 0
	var pending: Array = doors
	for attempt in 3:
		var left: Array = []
		for d in pending:
			if c.busy():
				await c.rest()
				if c.dead:
					return
			var dw: Vector2 = d[1]
			var rn: Array = d[2]
			if rn[0] <= float(rn[2]) + 0.4:
				_add_node(nodes, dw)  # kapı zaten caddede
				continue
			var target = null
			var best = 1e9
			if rn[0] < 70.0:
				var q: Vector2 = rn[1]
				var edge = q + (dw - q).normalized() * (float(rn[2]) - 0.5)
				if _clear(c, dw, edge):
					target = edge
					best = dw.distance_to(edge)
			# daha yakın bir patika noktası varsa ona bağlan
			var nq = _nearest_clear(c, nodes, dw, minf(best * 0.75, 44.0))
			if nq != null:
				target = nq
			if target == null and attempt == 2:
				# önce kapıdan 3 m dışarı çık, oradan bağlan (yan ek/merdiven önünü kesiyorsa)
				var wpt: Vector2 = d[3]
				if c.b.area_free(wpt, 0.6):
					var rn2 = c.road_near(wpt)
					if rn2[0] < 70.0:
						var q3: Vector2 = rn2[1]
						var edge3 = q3 + (wpt - q3).normalized() * (float(rn2[2]) - 0.5)
						if _clear(c, wpt, edge3):
							target = edge3
					if target == null:
						target = _nearest_clear(c, nodes, wpt, 44.0)
					if target != null:
						_draw_lane(c, dw, wpt)
						dw = wpt
			if target == null:
				left.append(d)
				continue
			_draw_lane(c, dw, target)
			var L = dw.distance_to(target)
			var steps = maxi(1, int(L / 4.0))
			for i in steps + 1:
				_add_node(nodes, dw.lerp(target, float(i) / steps))
			made += 1
		pending = left
		if pending.is_empty():
			break
	print("  patika: %d bağlandı, %d bağlanamadı" % [made, pending.size()])


## p'ye maxd içindeki en yakın (en çok 5 aday) bağlı noktalardan düz hattı açık olan
static func _nearest_clear(c: Ctx, nodes: Dictionary, p: Vector2, maxd: float):
	var best: Array = []  # [[d, q]] artan, en çok 5
	var cr = ceili(maxd / NC)
	var ci = Vector2i(floori(p.x / NC), floori(p.y / NC))
	for dx in range(-cr, cr + 1):
		for dz in range(-cr, cr + 1):
			var lst = nodes.get(ci + Vector2i(dx, dz))
			if lst == null:
				continue
			for q in lst:
				var dd = p.distance_to(q)
				if dd < 1.0 or dd > maxd:
					continue
				if best.size() == 5 and dd >= best[4][0]:
					continue
				var k = best.size()
				while k > 0 and best[k - 1][0] > dd:
					k -= 1
				best.insert(k, [dd, q])
				if best.size() > 5:
					best.pop_back()
	for e in best:
		if _clear(c, p, e[1]):
			return e[1]
	return null


static func _add_node(nodes: Dictionary, p: Vector2) -> void:
	var k = Vector2i(floori(p.x / NC), floori(p.y / NC))
	if not nodes.has(k):
		nodes[k] = []
	nodes[k].append(p)


## Kapıdan hedefe giden düz hat binalara/duvarlara değmiyor mu (dünya xz)
static func _clear(c: Ctx, a: Vector2, e: Vector2) -> bool:
	var L = a.distance_to(e)
	var n = int(L / 2.0)
	for i in range(1, n):
		if not c.b.area_free(a.lerp(e, float(i) / n), 0.55):
			return false
	return true


## Patika: kapıdan hedefe (dünya xz) 1.5 m genişlikte kenarlı şerit
static func _draw_lane(c: Ctx, a: Vector2, e: Vector2) -> void:
	_strip(c, c.loc(a), c.loc(e), 1.5, LANE_COL[c.climate])
	c.add_lane(a, e)


## Zemini izleyen kenarlı şerit (yerel a -> e). Eğim azsa parçalar 9 m'ye kadar uzar (az köşe).
static func _strip(c: Ctx, la: Vector2, le: Vector2, wd: float, col: Color) -> void:
	var d = le - la
	var L = d.length()
	if L < 0.3:
		return
	var dir = d / L
	var side = Vector2(dir.y, -dir.x)
	var rotd = Vector3(0, rad_to_deg(atan2(dir.x, -dir.y)), 0)  # Godot: kutunun z ekseni şerit boyunca
	var t = 0.0
	var ya = c.ground(la.x, la.y)
	var idx = 0
	# uçlarda yuvarlak kavşak pulu: birleşen şeritlerin köşe çıkıntıları / basamakları görünmesin
	for e in [la, le]:
		var ew = c.b.w(Vector3(e.x, c.ground(e.x, e.y) + 0.025, e.y))
		var ek = Vector2i(floori(ew.x / PCELL), floori(ew.z / PCELL))
		if not c.lane_mb.has(ek):
			c.lane_mb[ek] = MB.new()
		(c.lane_mb[ek] as MB).add("cyl", ew, Vector3(wd * 1.15, 0.1, wd * 1.15), col, Vector3.ZERO, 14)
	while t < L - 0.05:
		var seg = minf(9.0, L - t)
		var yb = c.ground(la.x + dir.x * (t + seg), la.y + dir.y * (t + seg))
		while seg > 3.0 and absf(yb - ya) > 0.18:
			seg *= 0.5
			yb = c.ground(la.x + dir.x * (t + seg), la.y + dir.y * (t + seg))
		var m = la + dir * (t + seg * 0.5)
		var ym = c.ground(m.x, m.y)
		var y = maxf(ym, (ya + yb) * 0.5)
		var pitch = -rad_to_deg(atan2(yb - ya, seg))
		var wp = c.b.w(Vector3(m.x, y + 0.03, m.y))
		var k = Vector2i(floori(wp.x / PCELL), floori(wp.z / PCELL))
		if not c.lane_mb.has(k):
			c.lane_mb[k] = MB.new()
		var mb: MB = c.lane_mb[k]
		var r = Vector3(pitch, rotd.y, 0)
		# tek renk, bordürsüz, alçak şerit: kesişen ara sokaklar dikişsiz birleşir (bordürler kavşakta çizgi çiziyordu)
		mb.add("box", wp - Vector3(0, 0.03, 0), Vector3(wd, 0.1, seg + 0.4), col, r)
		t += seg
		ya = yb
		idx += 1


## Ara sokaklar: Konoha'da ev bloklarının arasında bırakılan boş sıralar (ızgara), diğer köylerde
## merkezden dışa ışınsal yollar + ev halkaları arasında halka yollar. Yalnız boş kalan yerlere çizilir.
static func _trunks(c: Ctx, rad: float, houses: Array) -> void:
	var tt0 = Time.get_ticks_usec()
	# yalnız evlerin arasından geçsin (boş çayırları çizgi çizgi bölmesin)
	var near := {}
	for h in houses:
		var hp = c.wxz(h[0], h[1])
		near[Vector2i(floori(hp.x / 24.0), floori(hp.y / 24.0))] = true
	c.set_meta("near", near)
	var lines: Array = []  # [[yerel a, yerel e]]
	var r0 = 90.0
	if c.vid == "konoha":
		var R = 1460.0
		var k = -R + 51.0
		while k < R:
			lines.append([Vector2(k, -R), Vector2(k, R)])
			lines.append([Vector2(-R, k), Vector2(R, k)])
			k += 68.0
	else:
		var spokes = 16 if rad > 400.0 else 10
		for i in spokes:
			var a = TAU * (i + 0.5) / spokes
			lines.append([Vector2(sin(a), cos(a)) * r0, Vector2(sin(a), cos(a)) * rad])
		var rr = r0 + 20.0
		while rr < rad:
			var ring: Array = []
			var n = maxi(12, int(TAU * rr / 6.0))
			for i in n + 1:
				var a0 = TAU * i / n
				ring.append(Vector2(sin(a0), cos(a0)) * rr)
			lines.append(ring)
			rr += 38.0
	var col: Color = LANE_COL[c.climate].darkened(0.06)
	var wd = 3.2
	var total = 0
	for ln in lines:
		if c.busy():
			await c.rest()
			if c.dead:
				return
		# düz hat: 3 m'de bir örnek; halka: verilen köşeler
		var pts: Array = ln
		if ln.size() == 2:
			pts = []
			var L = ln[0].distance_to(ln[1])
			var n = maxi(1, int(L / 3.0))
			for i in n + 1:
				pts.append(ln[0].lerp(ln[1], float(i) / n))
		var run: Array = []
		for i in pts.size() + 1:
			var ok = false
			if i < pts.size():
				var p: Vector2 = pts[i]
				ok = p.length() < rad and _trunk_ok(c, p, wd)
				if ok:
					run.append(p)
			if not ok and run.size() >= 2:
				total += 1
				if ln.size() == 2:
					_trunk_piece(c, run[0], run[run.size() - 1], wd, col)
				else:
					for k in run.size() - 1:
						_trunk_piece(c, run[k], run[k + 1], wd, col)
			if not ok:
				run = []
	print("  ara sokak: %d parça (%.0f ms)" % [total, (Time.get_ticks_usec() - tt0) / 1000.0])


static func _trunk_piece(c: Ctx, pa: Vector2, pb: Vector2, wd: float, col: Color) -> void:
	_strip(c, pa, pb, wd, col)
	var wa = c.wxz(pa.x, pa.y); var wb = c.wxz(pb.x, pb.y)
	c.add_lane(wa, wb)
	var steps = maxi(1, int(pa.distance_to(pb) / 4.0))
	for s in steps + 1:
		_add_node(c.nodes, wa.lerp(wb, float(s) / steps))


static func _trunk_ok(c: Ctx, p: Vector2, wd: float) -> bool:
	var w = c.wxz(p.x, p.y)
	var near: Dictionary = c.get_meta("near")
	var ci = Vector2i(floori(w.x / 24.0), floori(w.y / 24.0))
	var has = false
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if near.has(ci + Vector2i(dx, dz)):
				has = true
	if not has:
		return false
	var kl = c.keep.get(Vector2i(floori(w.x / Ctx.KC), floori(w.y / Ctx.KC)))
	if kl != null:
		for k in kl:
			if w.distance_to(k[0]) < float(k[1]) - 2.0:
				return false
	var rn = c.road_near(w)
	if rn[0] < float(rn[2]) - 0.5:
		return false  # caddenin içi (cadde zaten döşeli)
	return c.b.area_free(w, wd * 0.5 + 0.3)


## Evin bahçesi. h: [x, n, gen, der, yaw, taban_y, stil]
static func _yard(c: Ctx, h: Array) -> void:
	var rng = c.rng
	var x: float = h[0]; var n: float = h[1]; var hw: float = float(h[2]) * 0.5; var hd: float = float(h[3]) * 0.5; var yaw: float = h[4]
	var kit = c.kit
	var at = func(lx: float, ln: float) -> Vector2:
		var o = Builder.rot(lx, ln, yaw)
		return Vector2(x + o.x, n + o.y)
	var door_side_free = true
	# ön cephe: pencere altı çiçek kutuları (kapı ortada; iki yanda)
	if kit["planter"] and rng.randf() < 0.55:
		var kind = ["planter_g", "planter_w", "planter_y", "planter_g"][rng.randi() % 4]
		for sx in [-1.0, 1.0]:
			var q = at.call(sx * hw * 0.55, -hd - 0.35)
			if c.open(q.x, q.y, 0.4, 9.2):
				c.put(mesh(kind), q.x, q.y, yaw, Vector3.ONE, 160.0)
	# kapı yanı saksılar / bonsai / küpler
	if rng.randf() < 0.45:
		var pk = "pot"
		if kit.get("jars", false):
			pk = "jar"
		elif c.climate in ["rock", "mist"] and rng.randf() < 0.6:
			pk = "bonsai"
		elif not kit["pots"]:
			pk = ""
		if pk != "":
			for sx in [-1.0, 1.0]:
				var q = at.call(sx * 1.45, -hd - 0.55)
				if c.open(q.x, q.y, 0.35, 9.2):
					c.put(mesh(pk), q.x, q.y, yaw + rng.randf() * 360.0, Vector3.ONE * rng.randf_range(0.85, 1.1), 140.0)
	# kapıdan sokağa basamak taşları
	if c.climate != "desert" and rng.randf() < 0.35:
		for i in 3:
			var q = at.call(rng.randf_range(-0.15, 0.15), -hd - 1.3 - i * 1.05)
			if not c.open(q.x, q.y, 0.3, 9.4):
				break
			c.put(mesh("step"), q.x, q.y, rng.randf() * 360.0, Vector3.ONE * rng.randf_range(0.85, 1.1), 120.0)
	# yan bahçe: ağaç / çalı / bambu / kuyu / çamaşır ipi (sağ veya sol)
	var side = 1.0 if rng.randf() < 0.5 else -1.0
	var r_tree = rng.randf()
	if r_tree < 0.5:
		var q = at.call(side * (hw + 2.4), rng.randf_range(-hd * 0.3, hd * 0.5))
		if c.open(q.x, q.y, 1.8, 10.5):
			var tt: int = kit["tree"][rng.randi() % kit["tree"].size()]
			var s = rng.randf_range(0.85, 1.25) if tt != 7 else rng.randf_range(0.8, 1.05)   # bahçe ağacı evin çatısını geçsin (çok kısaydı)
			c.put(veg(tt), q.x, q.y, rng.randf() * 360.0, Vector3.ONE * s, 420.0, false, -0.1)
			c.solid_cyl(q.x, q.y, 0.3 * s + 0.1, 4.5 * s)
		elif kit["bamboo"] and rng.randf() < 0.5:
			var q2 = at.call(side * (hw + 1.4), hd * 0.6)
			if c.open(q2.x, q2.y, 1.2, 10.5):
				c.put(veg(6), q2.x, q2.y, rng.randf() * 360.0, Vector3(0.55, rng.randf_range(0.5, 0.7), 0.55), 300.0)
	elif r_tree < 0.62 and kit["well"]:
		var q = at.call(side * (hw + 2.3), rng.randf_range(-hd * 0.2, hd * 0.3))
		if c.open(q.x, q.y, 1.4, 10.5):
			c.put(mesh("well"), q.x, q.y, yaw + rng.randf_range(-20, 20), Vector3.ONE, 240.0)
			c.solid_cyl(q.x, q.y, 1.0, 1.0)
	elif r_tree < 0.74 and kit["laundry"]:
		var q = at.call(side * (hw + 1.6), rng.randf_range(-hd * 0.2, hd * 0.4))
		if c.open(q.x, q.y, 1.7, 10.5):
			c.put(mesh("laundry"), q.x, q.y, yaw + 90.0, Vector3.ONE, 220.0)
	elif r_tree < 0.86 and kit.get("rocks", false):
		var q = at.call(side * (hw + 2.4), 0.0)
		if c.open(q.x, q.y, 2.0, 10.5):
			c.put(mesh("rock_garden"), q.x, q.y, yaw + 90.0, Vector3.ONE, 200.0)
	# çalılar: arka köşeler
	if rng.randf() < 0.55:
		for sx in [-1.0, 1.0]:
			if rng.randf() < 0.6:
				var q = at.call(sx * (hw + 0.9), hd + 0.9)
				if c.open(q.x, q.y, 0.8, 10.0):
					c.put(veg(kit["bush"]), q.x, q.y, rng.randf() * 360.0, Vector3.ONE * rng.randf_range(0.55, 0.8), 260.0)
	# arka çit (budanmış çalı) ya da ahşap çit
	if rng.randf() < 0.3 and c.climate != "desert":
		var use_hedge = rng.randf() < 0.6
		var segs = int((hw * 2.0) / 1.6)
		for i in segs:
			var lx = -hw + 0.8 + i * 1.6
			var q = at.call(lx, hd + 1.6)
			if not c.open(q.x, q.y, 0.7, 10.0):
				continue
			if use_hedge:
				c.put(hedge_mesh(kit["hedge"]), q.x, q.y, yaw, Vector3.ONE, 260.0)
				c.solid_box(q.x, q.y, Vector3(1.6, 0.9, 0.7), yaw)
			else:
				c.put(mesh("fence"), q.x, q.y, yaw, Vector3(0.8, 1, 1), 220.0)
				c.solid_box(q.x, q.y, Vector3(1.6, 1.0, 0.2), yaw)


## Cadde/yol kenarı ağaçları: evlerin arasındaki boşluklarda, taş bordürlü; uygun yerlerde bank ve fener
static func _street_trees(c: Ctx, rad: float) -> void:
	var b = c.b
	var cen = Vector2(b.origin.x, -b.origin.z)  # harita koordinatı
	var ring_m = mesh("ring_" + Color(c.kit["ring"]).to_html(false))
	var types: Array = c.kit["street_tree"]
	var segs: Array = Game.road_segments_near(cen, rad)
	var spacing = 21.0
	for e in segs:
		if c.busy():
			await c.rest()
			if c.dead:
				return
		var rd: Dictionary = Game.roads[e.x]
		if rd["kind"] != "street" and rd["kind"] != "road":
			continue
		var half = 9.0 if rd["kind"] == "street" else 8.0
		var pa: Vector2 = rd["pts"][e.y]
		var pb: Vector2 = rd["pts"][e.y + 1]
		var L = pa.distance_to(pb)
		if L < 4.0:
			continue
		var dir = (pb - pa) / L
		var nrm = Vector2(-dir.y, dir.x)
		var t = fposmod(pa.x * 0.37 + pa.y * 0.61, spacing)
		while t < L:
			var mp = pa + dir * t
			t += spacing * c.rng.randf_range(0.8, 1.2)
			if mp.distance_to(cen) > rad:
				continue
			for sd in [-1.0, 1.0]:
				var q = mp + nrm * sd * (half + 1.6)
				# harita -> yerel (x doğu, n kuzey)
				var lx = q.x - cen.x
				var ln = q.y - cen.y
				if c.open(lx, ln, 1.6, half + 0.4):
					var tt: int = types[c.rng.randi() % types.size()]
					var s = c.rng.randf_range(1.05, 1.45) if tt != 7 else c.rng.randf_range(0.9, 1.1)
					c.put(veg(tt), lx, ln, c.rng.randf() * 360.0, Vector3.ONE * s, 700.0, true, -0.1)
					c.put(ring_m, lx, ln, 0.0, Vector3.ONE, 220.0, false, 0.02)
					c.solid_cyl(lx, ln, 0.35 * s + 0.1, 5.0 * s)
				elif c.rng.randf() < 0.18:
					# ağaç sığmıyorsa küçük bir saksı/tarh
					var q2 = mp + nrm * sd * (half + 0.9)
					var lx2 = q2.x - cen.x
					var ln2 = q2.y - cen.y
					if c.open(lx2, ln2, 0.5, half + 0.2):
						var pk = "jar" if c.kit.get("jars", false) else ("bonsai" if c.climate in ["rock", "mist", "snow"] else "pot")
						c.put(mesh(pk), lx2, ln2, c.rng.randf() * 360.0, Vector3.ONE, 140.0)


## Büyük boş alanlara küçük parklar
static func _parks(c: Ctx, rad: float) -> void:
	var step = 22.0
	var cands: Array = []
	var gx = -rad
	while gx <= rad:
		if c.busy():
			await c.rest()
			if c.dead:
				return
		var gn = -rad
		while gn <= rad:
			var x = gx + c.rng.randf_range(-4.0, 4.0)
			var n = gn + c.rng.randf_range(-4.0, 4.0)
			gn += step
			if Vector2(x, n).length() > rad * 0.95:
				continue
			if c.open(x, n, 13.0, 15.0):
				cands.append(Vector2(x, n))
		gx += step
	cands.shuffle()
	var parks: Array = []
	var max_parks = clampi(int(rad / 25.0), 3, 60)
	for p in cands:
		if parks.size() >= max_parks:
			break
		var ok = true
		for q in parks:
			if p.distance_to(q) < 110.0:
				ok = false
				break
		if not ok:
			continue
		# en büyük serbest yarıçap
		var r = 13.0
		for rr in [17.0, 21.0, 26.0]:
			if c.open(p.x, p.y, rr, rr + 2.0):
				r = rr
		parks.append(p)
		_park(c, p.x, p.y, r)
		if c.busy():
			await c.rest()
			if c.dead:
				return
	parks_by[c.vid] = parks
	print("  park: %d (aday %d)" % [parks.size(), cands.size()])


static func _park(c: Ctx, px: float, pn: float, r: float) -> void:
	var b = c.b
	var rng = c.rng
	var kit = c.kit
	var pond = kit["pond"] and r >= 20.0 and rng.randf() < 0.7
	var gy = c.ground(px, pn)
	# orta: göl ya da çakıl meydan (kuyu / fener / kuru bahçe)
	var inner = r * 0.36
	if pond:
		var pr = inner
		c.flat_disc(px, pn, gy + 0.02, pr * 2.0, 0.2, Color(0.3, 0.55, 0.8), 28)
		c.flat_disc(px, pn, gy - 0.02, pr * 2.0 + 1.4, 0.2, Color(0.5, 0.42, 0.32), 28)
		var ns = int(TAU * pr / 1.1)
		for i in ns:
			var a = TAU * i / ns + rng.randf_range(-0.05, 0.05)
			c.put(mesh("pond_stone"), px + cos(a) * (pr + 0.3), pn + sin(a) * (pr + 0.3), rad_to_deg(a) + rng.randf_range(-20, 20), Vector3.ONE * rng.randf_range(0.8, 1.2), 200.0)
		for i in 6:
			var a = rng.randf() * TAU
			var rr = rng.randf_range(0.2, 0.75) * pr
			c.put(mesh("lily"), px + cos(a) * rr, pn + sin(a) * rr, rng.randf() * 360.0, Vector3.ONE * rng.randf_range(0.7, 1.2), 150.0, false, 0.14)
		for i in 4:
			var a = rng.randf() * TAU
			c.put(veg(16), px + cos(a) * (pr + 0.9), pn + sin(a) * (pr + 0.9), rng.randf() * 360.0, Vector3.ONE * 0.8, 160.0)
		c.solid_cyl(px, pn, pr * 0.9, 0.6)  # gölün içine yürünmesin (NPC'ler de dolaşır)
	else:
		var gc = Color(0.82, 0.76, 0.64) if c.climate != "snow" else Color(0.85, 0.86, 0.88)
		c.flat_disc(px, pn, gy, inner * 2.0, 0.16, gc, 22)
		var mid = "well" if kit["well"] and rng.randf() < 0.5 else ("rock_garden" if c.climate != "desert" else "jar")
		c.put(mesh(mid), px, pn, rng.randf() * 360.0, Vector3.ONE, 260.0, true)
		if mid == "well":
			c.solid_cyl(px, pn, 1.0, 1.0)
	# basamak taşı yol halkası
	var path_r = inner + 2.4
	var nsteps = int(TAU * path_r / 1.25)
	for i in nsteps:
		var a = TAU * i / nsteps
		c.put(mesh("step"), px + cos(a) * path_r, pn + sin(a) * path_r, rng.randf() * 360.0, Vector3.ONE * rng.randf_range(0.9, 1.15), 160.0)
	# taş fenerler + banklar (göle bakar)
	var nl = 4
	for i in nl:
		var a = TAU * (i + 0.5) / nl + 0.3
		var lx = px + cos(a) * (path_r + 1.5)
		var ln = pn + sin(a) * (path_r + 1.5)
		c.put(mesh("stone_lantern"), lx, ln, rng.randf() * 90.0, Vector3.ONE, 260.0, true)
		c.solid_cyl(lx, ln, 0.35, 2.2)
		if i == 0:
			Lights.add(b.w(Vector3(lx, c.ground(lx, ln) + 1.6, ln)))
	var benches: Array = []
	for i in 3:
		var a = TAU * i / 3.0 + 0.9
		var bx = px + cos(a) * (path_r + 1.6)
		var bn = pn + sin(a) * (path_r + 1.6)
		# bank merkeze baksın: yerel ön -n; yaw ile (merkez - bank) yönüne çevrilir
		var fd = Vector2(px - bx, pn - bn)
		var yaw = rad_to_deg(atan2(-fd.x, -fd.y))
		c.put(mesh("bench"), bx, bn, yaw, Vector3.ONE, 200.0)
		benches.append([bx, bn, fd])
	# çiçek tarhları (yalnız yeşil iklimlerde)
	if c.climate in ["green", "mist", "rain"]:
		for i in 2:
			var a = TAU * i / 2.0 + 0.2
			var fx = px + cos(a) * (path_r + 4.5)
			var fn = pn + sin(a) * (path_r + 4.5)
			c.put(mesh("flowerbed"), fx, fn, rad_to_deg(-a) + 90.0, Vector3.ONE, 200.0)
			c.solid_box(fx, fn, Vector3(3.0, 0.4, 1.4), rad_to_deg(-a) + 90.0)
	# dış halka: ağaçlar (yeşilde ara sıra kiraz), çalılar
	var nt = int(r * 0.45)
	for i in nt:
		var a = TAU * i / nt + rng.randf_range(-0.12, 0.12)
		var rr = r * rng.randf_range(0.78, 0.95)
		var tx = px + cos(a) * rr
		var tn = pn + sin(a) * rr
		if not c.open(tx, tn, 1.5, 10.0):
			continue
		if kit["sakura"] and i % 4 == 1:
			var s = rng.randf_range(0.85, 1.05)
			c.put(mesh("sakura"), tx, tn, rng.randf() * 360.0, Vector3.ONE * s, 900.0, true, -0.1)
			c.solid_cyl(tx, tn, 0.35 * s, 4.5 * s)
		else:
			var tt: int = kit["tree"][rng.randi() % kit["tree"].size()]
			var s = rng.randf_range(1.2, 1.8)
			c.put(veg(tt), tx, tn, rng.randf() * 360.0, Vector3.ONE * s, 900.0, true, -0.1)
			c.solid_cyl(tx, tn, 0.35 * s + 0.1, 5.0 * s)
		if rng.randf() < 0.6:
			var ba = a + rng.randf_range(0.12, 0.25)
			c.put(veg(kit["bush"]), px + cos(ba) * rr, pn + sin(ba) * rr, rng.randf() * 360.0, Vector3.ONE * rng.randf_range(0.6, 0.9), 260.0)
	if kit["bamboo"] and rng.randf() < 0.5:
		var a = rng.randf() * TAU
		c.put(veg(6), px + cos(a) * r * 0.65, pn + sin(a) * r * 0.65, rng.randf() * 360.0, Vector3(0.7, 0.75, 0.7), 400.0, true)
	# canlı şehir: banklara oturan yaşlılar
	if VL.sites.has(c.vid):
		for bb in benches:
			var wp = b.w(Vector3(bb[0], 0, bb[1]))
			wp.y = Game.terrain_height(wp.x, wp.z)
			var fd: Vector2 = bb[2]
			VL.sites[c.vid].append({"type": "bench", "pos": wp, "face": atan2(-fd.x, fd.y)})
