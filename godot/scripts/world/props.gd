class_name Props
extends RefCounted
## Paylaşılan materyaller + bitki örtüsü meshleri.

static var _toon: ShaderMaterial
static var _foliage: ShaderMaterial
static var _stone: ShaderMaterial


static func toon() -> ShaderMaterial:
	if _toon == null:
		_toon = ShaderMaterial.new()
		_toon.shader = load("res://shaders/toon.gdshader")
		_toon.set_shader_parameter("rim_amount", 0.15)
		_toon.set_shader_parameter("detail_noise", 0.1)
		_toon.set_shader_parameter("detail_tex", load("res://assets/tex/plaster.png"))   # duvar/taş/ahşap: boyalı sıva dokusu
		_toon.set_shader_parameter("detail_tex_amt", 0.32)
		_toon.set_shader_parameter("detail_tex_scale", 0.35)
	return _toon


static var _roof: ShaderMaterial
## Çatılar: toon + kiremit deseni (sıra sıra tırtıklı kiremit çizgileri)
static func roof_toon() -> ShaderMaterial:
	if _roof == null:
		_roof = toon().duplicate()
		_roof.set_shader_parameter("roof_tiles", true)
		_roof.set_shader_parameter("detail_tex", load("res://assets/tex/roof.png"))   # gerçek kil kiremit dokusu
		_roof.set_shader_parameter("detail_tex_amt", 0.55)
		_roof.set_shader_parameter("detail_tex_scale", 0.5)
	return _roof


static var _rock_m: ShaderMaterial
static var _bark_m: ShaderMaterial
## Kaya / toprak (Doton kayaları, kaya parçaları): gerçek kaya yüzeyi dokusu
static func rock_toon() -> ShaderMaterial:
	if _rock_m == null:
		_rock_m = toon().duplicate()
		_rock_m.set_shader_parameter("detail_tex", load("res://assets/tex/rock.png"))
		_rock_m.set_shader_parameter("detail_tex_amt", 0.55)
		_rock_m.set_shader_parameter("detail_tex_scale", 0.6)
	return _rock_m


static var _earth := {}
## Doton toprağı/kayası (ref doton*.png): düz renk yerine çatlaklı, lekeli kaya dokusu (dünya uzayı, üç yönlü)
static func earth_color(c: Color) -> ShaderMaterial:
	var k = c.to_html()
	if not _earth.has(k):
		var m = toon_color(c, 0.2)
		m.set_shader_parameter("detail_tex", load("res://assets/tex/rock.png"))
		m.set_shader_parameter("detail_tex_amt", 0.75)
		m.set_shader_parameter("detail_tex_scale", 0.45)
		m.set_shader_parameter("detail_noise", 0.35)
		_earth[k] = m
	return _earth[k]


## Ahşap (Mokuton, kütükler): ağaç kabuğu dokusu
static func bark_toon() -> ShaderMaterial:
	if _bark_m == null:
		_bark_m = toon().duplicate()
		_bark_m.set_shader_parameter("detail_tex", load("res://assets/tex/bark.png"))
		_bark_m.set_shader_parameter("detail_tex_amt", 0.5)
		_bark_m.set_shader_parameter("detail_tex_scale", 0.9)
	return _bark_m


static func foliage() -> ShaderMaterial:
	if _foliage == null:
		_foliage = ShaderMaterial.new()
		_foliage.shader = load("res://shaders/toon.gdshader")
		_foliage.set_shader_parameter("rim_amount", 0.3)
		_foliage.set_shader_parameter("sway", 1.0)
		_foliage.set_shader_parameter("detail_noise", 0.25)
		_foliage.set_shader_parameter("detail_tex", load("res://assets/tex/bark.png"))   # gövde: ağaç kabuğu (yalnız kahverengi köşeler)
		_foliage.set_shader_parameter("detail_tex_amt", 0.55)
		_foliage.set_shader_parameter("detail_tex_scale", 0.7)
		_foliage.set_shader_parameter("detail_brown_only", true)
		_foliage.set_shader_parameter("leaf_tex", load("res://assets/tex/grass.png"))   # yaprak / çam iğnesi dokusu
		_foliage.set_shader_parameter("leaf_tex_amt", 0.55)
	return _foliage


static func toon_color(c: Color, rim := 0.3) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/toon.gdshader")
	m.set_shader_parameter("tint", c)
	m.set_shader_parameter("use_vertex_color", false)
	m.set_shader_parameter("rim_amount", rim)
	return m


## Konoha orman ağacının dalları: [yükseklik, yön(derece), uzunluk] (ölçek 1). Çarpışmalar da bunu kullanır.
const FOREST_BRANCHES := [[8.5, 25.0, 8.5], [11.5, 145.0, 9.5], [14.5, 265.0, 8.5], [17.0, 70.0, 7.5], [19.5, 200.0, 7.0], [22.0, 320.0, 6.5]]
const FOREST_TRUNK_H := 27.0
const FOREST_TRUNK_R := 1.05

static var _leaf_cols := [
	[Color(0.38, 0.7, 0.26), Color(0.12, 0.3, 0.12)],
	[Color(0.45, 0.75, 0.3), Color(0.15, 0.35, 0.13)],
	[Color(0.33, 0.62, 0.22), Color(0.1, 0.26, 0.1)],
]


static func _leaf_cluster(b: MB, p: Vector3, s: float, ci := 0) -> void:
	var c: Array = _leaf_cols[ci % _leaf_cols.size()]
	b.add_grad("sphere", p, Vector3(1.0, 0.62, 1.0) * s, c[0], c[1], Vector3(0, 0, 0), 10)
	b.add_grad("sphere", p + Vector3(s * 0.32, s * 0.16, s * 0.1), Vector3(0.62, 0.45, 0.62) * s, c[0].lightened(0.06), c[1], Vector3.ZERO, 8)
	b.add_grad("sphere", p + Vector3(-s * 0.28, s * 0.12, -s * 0.22), Vector3(0.6, 0.42, 0.6) * s, c[0], c[1], Vector3.ZERO, 8)
	b.add_grad("sphere", p + Vector3(s * 0.05, s * 0.3, -s * 0.05), Vector3(0.5, 0.35, 0.5) * s, c[0].lightened(0.1), c[1], Vector3.ZERO, 8)


static func _leaf_cluster_c(b: MB, p: Vector3, s: float, hi: Color, lo: Color) -> void:
	b.add_grad("sphere", p, Vector3(1.0, 0.62, 1.0) * s, hi, lo, Vector3.ZERO, 10)
	b.add_grad("sphere", p + Vector3(s * 0.32, s * 0.16, s * 0.1), Vector3(0.62, 0.45, 0.62) * s, hi.lightened(0.06), lo, Vector3.ZERO, 8)
	b.add_grad("sphere", p + Vector3(-s * 0.28, s * 0.12, -s * 0.22), Vector3(0.6, 0.42, 0.6) * s, hi, lo, Vector3.ZERO, 8)
	b.add_grad("sphere", p + Vector3(s * 0.05, s * 0.3, -s * 0.05), Vector3(0.5, 0.35, 0.5) * s, hi.lightened(0.1), lo, Vector3.ZERO, 8)


## Köy / şehir ağacı türleri (her biri ayrı silüet + renk). Yaprak dökümü de bu renkleri kullanır (VILLAGE_TREE_LEAF).
## 0 geniş yapraklı, 1 sakura, 2 momiji (kızıl akçaağaç), 3 yaşlı meşe (geniş, katlı taç), 4 servi (sütun), 5 ginkgo (sarı), 6 söğüt (sarkık)
const VILLAGE_TREE_W := [30, 12, 8, 16, 0, 6, 0]   # 4 servi + 6 söğüt (eski küre/şerit stil) kaldırıldı: anime ağaçları
const VILLAGE_TREE_LEAF := [Color(0.42, 0.68, 0.26), Color(1.0, 0.75, 0.84), Color(0.92, 0.33, 0.16), Color(0.36, 0.58, 0.22), Color(0.2, 0.42, 0.24), Color(0.98, 0.82, 0.25), Color(0.55, 0.75, 0.32)]
const VILLAGE_TREE_TOP := [7.4, 6.2, 6.0, 8.6, 9.0, 7.6, 6.0]   # yaprak dökümü için taç yüksekliği (ölçek 1)


static func village_tree_mesh(v: int) -> ArrayMesh:
	match v:
		0: return AnimeTree.mesh("broad", "green", 1)
		1: return AnimeTree.mesh("broad", "sakura", 2)
		2: return AnimeTree.mesh("slender", "momiji", 3)
		3: return AnimeTree.mesh("oak", "green", 4)
		5: return AnimeTree.mesh("slender", "ginkgo", 5)
	var b = MB.new()
	var bark = Color(0.4, 0.27, 0.17)
	match v:
		1:   # sakura: koyu, kıvrık gövde; yayvan pembe taç
			var bk = Color(0.3, 0.2, 0.18)
			b.add("cyl", Vector3(0, 1.8, 0), Vector3(0.6, 3.6, 0.6), bk, Vector3(0, 0, 6), 8)
			b.add("cyl", Vector3(0.6, 4.0, 0.1), Vector3(0.36, 2.6, 0.36), bk, Vector3(0, 0, -35), 6)
			b.add("cyl", Vector3(-0.7, 4.2, -0.2), Vector3(0.32, 2.8, 0.32), bk, Vector3(-10, 0, 40), 6)
			b.add("cyl", Vector3(0.1, 4.4, 0.6), Vector3(0.28, 2.2, 0.28), bk, Vector3(35, 0, 0), 6)
			for i in 4:
				var ra = deg_to_rad(i * 90.0 + 40.0)
				b.add_root(Vector3.ZERO, Vector3(sin(ra), 0, cos(ra)), 0.3, 0.45, 0.12, bk, 0.3, 0.45)
			var pk = Color(1.0, 0.78, 0.86)
			var pd = Color(0.86, 0.5, 0.64)
			_leaf_cluster_c(b, Vector3(0, 6.0, 0), 5.0, pk, pd)
			_leaf_cluster_c(b, Vector3(2.4, 5.4, 0.4), 3.6, pk.lightened(0.05), pd)
			_leaf_cluster_c(b, Vector3(-2.3, 5.5, -0.6), 3.6, pk, pd)
			_leaf_cluster_c(b, Vector3(0.3, 5.3, 2.2), 3.0, pk, pd)
		2:   # momiji: ince gövde, katlı kızıl-turuncu taç
			b.add("cyl", Vector3(0, 2.6, 0), Vector3(0.5, 5.2, 0.5), bark.darkened(0.1), Vector3.ZERO, 8)
			b.add("cyl", Vector3(0.5, 4.4, 0), Vector3(0.22, 2.0, 0.22), bark, Vector3(0, 0, -40), 6)
			b.add("cyl", Vector3(-0.5, 4.7, 0.2), Vector3(0.2, 1.8, 0.2), bark, Vector3(20, 0, 36), 6)
			_leaf_cluster_c(b, Vector3(0, 5.4, 0), 4.4, Color(0.95, 0.38, 0.16), Color(0.6, 0.12, 0.08))
			_leaf_cluster_c(b, Vector3(1.3, 6.3, 0.5), 3.0, Color(0.98, 0.55, 0.2), Color(0.7, 0.2, 0.08))
			_leaf_cluster_c(b, Vector3(-1.1, 6.6, -0.6), 2.8, Color(0.9, 0.25, 0.14), Color(0.55, 0.1, 0.07))
		3:   # yaşlı meşe: kalın gövde, kök yayılımı, geniş ve katlı koyu taç
			b.add_grad("cyl", Vector3(0, 2.8, 0), Vector3(1.2, 5.6, 1.2), bark.lightened(0.05), bark.darkened(0.2), Vector3.ZERO, 10)
			for i in 6:
				var ra = deg_to_rad(i * 60.0 + 15.0)
				b.add_root(Vector3.ZERO, Vector3(sin(ra), 0, cos(ra)), 0.6, 0.8, 0.22, bark.darkened(0.08), 0.35 * (1 if i % 2 == 0 else -1), 0.8)
			for i in 4:
				var a = deg_to_rad(i * 90.0 + 20.0)
				b.add("cyl", Vector3(sin(a) * 1.3, 5.6, cos(a) * 1.3), Vector3(0.36, 3.2, 0.36), bark, Vector3(cos(a) * 45, 0, -sin(a) * 45), 6)
			var g0 = Color(0.32, 0.56, 0.2)
			var g1 = Color(0.08, 0.22, 0.08)
			_leaf_cluster_c(b, Vector3(0, 8.8, 0), 6.8, g0, g1)
			_leaf_cluster_c(b, Vector3(3.0, 7.4, 1.0), 4.6, g0.lightened(0.05), g1)
			_leaf_cluster_c(b, Vector3(-2.8, 7.6, -1.2), 4.8, g0, g1)
			_leaf_cluster_c(b, Vector3(0.6, 7.2, -3.0), 4.2, g0.darkened(0.05), g1)
			_leaf_cluster_c(b, Vector3(-0.8, 7.0, 3.0), 4.0, g0, g1)
		4:   # servi: ince uzun sütun taç
			b.add("cyl", Vector3(0, 1.2, 0), Vector3(0.45, 2.4, 0.45), bark, Vector3.ZERO, 7)
			var c0 = Color(0.22, 0.45, 0.26)
			var c1 = Color(0.06, 0.18, 0.1)
			for i in 5:
				var r = 2.6 - absf(i - 1.5) * 0.45
				b.add_grad("sphere", Vector3(0, 3.0 + i * 1.6, 0), Vector3(r, 2.8, r), c0.lightened(i * 0.02), c1, Vector3.ZERO, 9)
			b.add_grad("cone", Vector3(0, 11.2, 0), Vector3(1.4, 2.6, 1.4), c0, c1, Vector3.ZERO, 8)
		5:   # ginkgo: dik gövde, yelpaze gibi altın sarısı taç
			b.add("cyl", Vector3(0, 3.2, 0), Vector3(0.55, 6.4, 0.55), bark.lightened(0.05), Vector3.ZERO, 8)
			for i in 3:
				b.add("cyl", Vector3(0, 4.2 + i * 1.2, 0), Vector3(0.2, 2.6, 0.2), bark, Vector3(0, i * 120, 50), 5)
			_leaf_cluster_c(b, Vector3(0, 7.6, 0), 4.6, Color(1.0, 0.86, 0.3), Color(0.72, 0.52, 0.08))
			_leaf_cluster_c(b, Vector3(0.4, 5.8, 0.3), 4.0, Color(0.98, 0.8, 0.26), Color(0.68, 0.48, 0.06))
		6:   # söğüt: yuvarlak taç + yere sarkan yaprak perdeleri
			b.add("cyl", Vector3(0, 2.4, 0), Vector3(0.7, 4.8, 0.7), bark.darkened(0.05), Vector3(0, 0, 5), 8)
			var w0 = Color(0.55, 0.76, 0.3)
			var w1 = Color(0.2, 0.4, 0.12)
			_leaf_cluster_c(b, Vector3(0, 5.6, 0), 4.6, w0, w1)
			for i in 14:
				var a = i * TAU / 14.0
				var r = 2.1 + (i % 3) * 0.25
				var L = 2.6 + (i % 4) * 0.5
				b.add_grad("cyl", Vector3(sin(a) * r, 5.0 - L * 0.5, cos(a) * r), Vector3(0.55, L, 0.3), w0.lightened(0.05), w1, Vector3(cos(a) * 8, rad_to_deg(a), -sin(a) * 8), 5)
	return b.build(foliage())


## Çiçek öbekleri (6 tür, ~2 m): 0 lale, 1 papatya, 2 ortanca, 3 lavanta, 4 higanbana (kızıl örümcek zambağı), 5 karışık kır çiçeği
const FLOWER_KINDS := 6
static func flower_mesh(v: int) -> ArrayMesh:
	var b = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 700 + v
	var stem = Color(0.3, 0.55, 0.22)
	var leaf = Color(0.36, 0.62, 0.26)
	match v:
		0:   # lale: dik sap, iki uzun yaprak, kupa çiçek
			var cols = [Color(0.92, 0.18, 0.2), Color(1.0, 0.82, 0.2), Color(0.98, 0.5, 0.65), Color(0.95, 0.95, 0.9)]
			for i in 14:
				var p = Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-0.9, 0.9))
				var h = rng.randf_range(0.35, 0.5)
				b.add("cyl", p + Vector3(0, h * 0.5, 0), Vector3(0.025, h, 0.025), stem, Vector3.ZERO, 4)
				b.add("box", p + Vector3(0.04, h * 0.3, 0), Vector3(0.05, h * 0.55, 0.012), leaf, Vector3(0, rng.randf() * 180, 12))
				var c: Color = cols[i % cols.size()] if rng.randf() < 0.7 else cols[0]
				b.add_grad("cone", p + Vector3(0, h + 0.08, 0), Vector3(0.2, 0.24, 0.2), c, c.darkened(0.25), Vector3(180, 0, 0), 6)
		1:   # papatya: alçak yeşil yastık üstünde beyaz taç yapraklı sarı göbekli çiçekler
			b.add_grad("sphere", Vector3(0, 0.08, 0), Vector3(1.8, 0.18, 1.6), leaf, stem.darkened(0.2), Vector3.ZERO, 8)
			for i in 22:
				var p = Vector3(rng.randf_range(-0.8, 0.8), 0.2, rng.randf_range(-0.7, 0.7))
				b.add("cyl", p, Vector3(0.24, 0.03, 0.24), Color(0.97, 0.97, 0.95), Vector3.ZERO, 8)
				b.add("cyl", p + Vector3(0, 0.015, 0), Vector3(0.06, 0.025, 0.06), Color(1.0, 0.82, 0.2), Vector3.ZERO, 6)
		2:   # ortanca: yuvarlak çalı + mavi / mor / pembe top çiçek kümeleri
			var hc = [Color(0.45, 0.55, 0.95), Color(0.65, 0.45, 0.85), Color(0.95, 0.6, 0.78)][rng.randi() % 3]
			b.add_grad("sphere", Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 1.5), leaf, stem.darkened(0.25), Vector3.ZERO, 9)
			for i in 9:
				var a = rng.randf() * TAU
				var r = rng.randf_range(0.3, 0.7)
				b.add_grad("sphere", Vector3(cos(a) * r, 0.75 + rng.randf_range(-0.1, 0.15), sin(a) * r), Vector3(0.38, 0.32, 0.38), hc.lightened(0.15), hc.darkened(0.12), Vector3.ZERO, 7)
		3:   # lavanta: ince uzun mor başaklar, sıra halinde
			for i in 26:
				var p = Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-0.6, 0.6))
				var h = rng.randf_range(0.45, 0.65)
				b.add("cyl", p + Vector3(0, h * 0.5, 0), Vector3(0.02, h, 0.02), Color(0.45, 0.58, 0.4), Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)), 4)
				b.add_grad("cyl", p + Vector3(0, h + 0.09, 0), Vector3(0.11, 0.22, 0.11), Color(0.62, 0.36, 0.95), Color(0.38, 0.18, 0.7), Vector3.ZERO, 5)
		4:   # higanbana: yapraksız ince sap, tepede ışınsal kıvrık kızıl taç yaprakları
			for i in 10:
				var p = Vector3(rng.randf_range(-0.85, 0.85), 0, rng.randf_range(-0.85, 0.85))
				var h = rng.randf_range(0.4, 0.55)
				b.add("cyl", p + Vector3(0, h * 0.5, 0), Vector3(0.02, h, 0.02), Color(0.32, 0.5, 0.25), Vector3.ZERO, 4)
				for k in 6:
					var a = k * 60.0 + rng.randf_range(-10, 10)
					var d = Vector3(cos(deg_to_rad(a)), 0.35, sin(deg_to_rad(a))).normalized()
					b.add("box", p + Vector3(0, h, 0) + d * 0.09, Vector3(0.04, 0.02, 0.18), Color(0.9, 0.06, 0.08), Vector3(-20, -a + 90.0, 0))
				b.add("sphere", p + Vector3(0, h + 0.02, 0), Vector3(0.05, 0.04, 0.05), Color(0.75, 0.06, 0.08), Vector3.ZERO, 5)
		_:   # karışık kır çiçekleri: alçak yeşillik üstünde renk renk küçük çiçekler
			b.add_grad("sphere", Vector3(0, 0.06, 0), Vector3(2.0, 0.14, 1.8), leaf, stem.darkened(0.2), Vector3.ZERO, 8)
			var wc = [Color(1.0, 0.85, 0.25), Color(0.95, 0.95, 0.95), Color(0.95, 0.45, 0.6), Color(0.55, 0.6, 0.98), Color(1.0, 0.55, 0.2)]
			for i in 30:
				var p = Vector3(rng.randf_range(-0.9, 0.9), 0.16 + rng.randf_range(0.0, 0.1), rng.randf_range(-0.8, 0.8))
				b.add("sphere", p, Vector3(0.17, 0.09, 0.17), wc[rng.randi() % wc.size()], Vector3.ZERO, 5)
	return b.build(foliage())


## Anime ağaçları (AnimeTree, ref tree1..10): orman/geniş yapraklı/Ölüm Ormanı/çalı
const ANIME_T := {0: ["broad", "green"], 1: ["fir", "fir"], 2: ["dead", "dead"], 5: ["giant", "death"], 6: ["bamboo", "bamboo"], 7: ["palm", "palm"],
	8: ["bush", "bush"], 9: ["forest", "forest"], 18: ["bush", "bush"]}


static func vegetation_mesh(t: int, variant := 0) -> ArrayMesh:
	if ANIME_T.has(t):
		var k: Array = ANIME_T[t]
		var kind: String = k[0]
		var pl: String = k[1]
		if t == 0:
			kind = ["broad", "slender", "oak"][variant % 3]
		elif t == 1 and variant % 2 == 1:
			kind = "pine"   # Japon kara çamı (eğri gövde, yassı pedler)
			pl = "pine"
		return AnimeTree.mesh(kind, pl, variant)
	var b = MB.new()
	var bark = Color(0.4, 0.27, 0.17)
	match t:
		0:  # geniş yapraklı anime ağacı
			b.add("cyl", Vector3(0, 3.0, 0), Vector3(0.75, 6.0, 0.75), bark, Vector3.ZERO, 8)
			for i in 5:
				var ra = deg_to_rad(i * 72.0 + 25.0)
				b.add_root(Vector3.ZERO, Vector3(sin(ra), 0, cos(ra)), 0.375, 0.5 + 0.15 * (i % 2), 0.15, bark.darkened(0.05), 0.35 * (1 if i % 2 == 0 else -1), 0.55)
			b.add("cyl", Vector3(0.7, 5.0, 0), Vector3(0.3, 2.4, 0.3), bark, Vector3(0, 0, -42), 6)
			b.add("cyl", Vector3(-0.6, 5.4, 0.3), Vector3(0.28, 2.2, 0.28), bark, Vector3(20, 0, 38), 6)
			_leaf_cluster(b, Vector3(0, 7.4, 0), 6.2, 0)
			_leaf_cluster(b, Vector3(1.9, 6.6, 0.8), 4.0, 1)
			_leaf_cluster(b, Vector3(-1.7, 6.9, -0.9), 4.2, 2)
		1:  # çam
			b.add("cyl", Vector3(0, 4, 0), Vector3(0.7, 8, 0.7), bark, Vector3.ZERO, 7)
			for i in 5:
				var s = 5.4 - i * 1.05
				b.add_grad("cone", Vector3(0, 3.4 + i * 1.9, 0), Vector3(s, 3.4, s), Color(0.22, 0.48, 0.32), Color(0.07, 0.2, 0.14), Vector3.ZERO, 9)
		2:  # kuru ağaç
			var dc = Color(0.36, 0.31, 0.27)
			b.add("cyl", Vector3(0, 3.5, 0), Vector3(0.6, 7, 0.6), dc, Vector3.ZERO, 6)
			for i in 5:
				b.add("cyl", Vector3(0, 4.2 + i * 0.7, 0), Vector3(0.18, 2.8, 0.18), dc, Vector3(0, i * 75, 48), 5)
		3:  # kaktüs
			var c = Color(0.36, 0.58, 0.3)
			b.add_grad("cyl", Vector3(0, 1.8, 0), Vector3(0.7, 3.6, 0.7), c.lightened(0.1), c.darkened(0.2), Vector3.ZERO, 10)
			b.add("sphere", Vector3(0, 3.6, 0), Vector3(0.7, 0.55, 0.7), c, Vector3.ZERO, 8)
			b.add("cyl", Vector3(0.6, 2.0, 0), Vector3(0.4, 1.3, 0.4), c, Vector3(0, 0, 90), 6)
			b.add("cyl", Vector3(0.9, 2.6, 0), Vector3(0.4, 1.3, 0.4), c, Vector3.ZERO, 6)
		4:  # kaya
			b.add_grad("sphere", Vector3(0, 0.5, 0), Vector3(3.2, 2.2, 2.6), Color(0.62, 0.59, 0.54), Color(0.38, 0.36, 0.33), Vector3(8, 20, 5), 7)
			b.add_grad("sphere", Vector3(1.0, 0.3, 0.7), Vector3(1.7, 1.3, 1.5), Color(0.58, 0.55, 0.5), Color(0.36, 0.34, 0.31), Vector3(0, 50, 0), 6)
		5:  # Ölüm Ormanı dev ağacı
			var bk = Color(0.3, 0.2, 0.14)
			b.add_grad("cyl", Vector3(0, 28, 0), Vector3(6.4, 56, 6.4), bk.lightened(0.08), bk.darkened(0.25), Vector3.ZERO, 12)
			for i in 7:
				var ra = i * 0.9
				b.add_root(Vector3.ZERO, Vector3(sin(ra), 0, cos(ra)), 3.2, 4.2, 1.3, bk.darkened(0.05), 0.45 * (1 if i % 2 == 0 else -1), 4.2, 11, 9)
			for i in 6:
				var a = i * 60.0 + 20.0
				var y = 14.0 + i * 6.0
				var d = Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
				b.add("box", d * 8.0 + Vector3(0, y, 0), Vector3(2.4, 1.6, 14.0), bk, Vector3(0, a, 0))
				_leaf_cluster(b, d * 15.0 + Vector3(0, y + 2.0, 0), 7.0, i)
			b.add_grad("sphere", Vector3(0, 58, 0), Vector3(32, 15, 32), Color(0.2, 0.42, 0.18), Color(0.05, 0.15, 0.06), Vector3.ZERO, 12)
			b.add_grad("sphere", Vector3(9, 53, 6), Vector3(18, 10, 18), Color(0.22, 0.45, 0.2), Color(0.05, 0.15, 0.06), Vector3.ZERO, 9)
		6:  # bambu
			for i in 7:
				var p = Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
				var h = randf_range(8, 12)
				b.add("cyl", p + Vector3(0, h / 2, 0), Vector3(0.2, h, 0.2), Color(0.5, 0.68, 0.32), Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)), 6)
				for k in 3:
					b.add("box", p + Vector3(0, h * (0.6 + k * 0.15), 0), Vector3(1.6, 0.04, 0.35), Color(0.38, 0.62, 0.25), Vector3(0, randf() * 180, -20))
		7:  # palmiye
			for i in 5:
				b.add("cyl", Vector3(i * 0.25, 0.9 + i * 1.6, 0), Vector3(0.5, 1.8, 0.5), Color(0.55, 0.42, 0.3), Vector3(0, 0, -6), 6)
			for i in 7:
				b.add("box", Vector3(1.25, 8.3, 0), Vector3(0.6, 0.08, 3.6), Color(0.3, 0.58, 0.24), Vector3(-25, i * 51, 0))
		8:  # çalı
			_leaf_cluster(b, Vector3(0, 0.6, 0), 2.0, 1)
			_leaf_cluster(b, Vector3(0.8, 0.45, 0.5), 1.3, 2)
		9:  # Konoha orman ağacı: düz uzun gövde, kök çıkıntıları, kalın dallar, katmanlı yaprak kümeleri
			var tk = Color(0.43, 0.29, 0.18)
			b.add_grad("cyl", Vector3(0, FOREST_TRUNK_H * 0.5, 0), Vector3(FOREST_TRUNK_R * 2.0, FOREST_TRUNK_H, FOREST_TRUNK_R * 2.0), tk.lightened(0.06), tk.darkened(0.3), Vector3.ZERO, 10)
			# kökler: gövdeden kıvrılarak yere yatar, toprağa gömülür
			for i in 8:
				var big = i % 2 == 0
				var a = i * 45.0 + 15.0 + (9.0 if i % 3 == 1 else -6.0)
				var d = Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
				b.add_root(Vector3.ZERO, d, FOREST_TRUNK_R, (1.4 if big else 0.85) + 0.2 * (i % 3), 0.38 if big else 0.25, tk.darkened(0.08), 0.3 * (1 if i % 4 < 2 else -1), 1.45 if big else 0.85)
			var ci = 0
			for br in FOREST_BRANCHES:
				var a: float = br[1]
				var L: float = br[2]
				var d = Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
				b.add("box", d * (FOREST_TRUNK_R + L * 0.5) + Vector3(0, br[0], 0), Vector3(1.1, 0.75, L), tk, Vector3(-4, a, 0))
				_leaf_cluster(b, d * (FOREST_TRUNK_R + L + 1.0) + Vector3(0, br[0] + 1.6, 0), 6.5, ci)
				ci += 1
			_leaf_cluster(b, Vector3(0, FOREST_TRUNK_H + 1.5, 0), 10.0, 0)
			_leaf_cluster(b, Vector3(3.0, FOREST_TRUNK_H - 1.0, 2.0), 7.0, 1)
			_leaf_cluster(b, Vector3(-3.2, FOREST_TRUNK_H - 0.5, -1.6), 7.0, 2)
		10:  # eğrelti otu
			for i in 7:
				b.add_grad("box", Vector3(sin(i * 0.9) * 0.45, 0.45, cos(i * 0.9) * 0.45), Vector3(0.32, 0.03, 1.5), Color(0.42, 0.72, 0.3), Color(0.16, 0.36, 0.14), Vector3(-38, rad_to_deg(i * 0.9), 0))
		11:  # büyük kaya kümesi
			var rc = Color(0.6, 0.56, 0.5)
			b.add_grad("sphere", Vector3(0, 1.4, 0), Vector3(6.5, 4.5, 5.5), rc, rc.darkened(0.4), Vector3(6, 30, 4), 7)
			b.add_grad("sphere", Vector3(2.6, 0.9, 1.6), Vector3(3.6, 2.8, 3.2), rc.lightened(0.05), rc.darkened(0.4), Vector3(0, 70, 8), 6)
			b.add_grad("sphere", Vector3(-2.4, 0.7, -1.2), Vector3(3.0, 2.2, 2.6), rc, rc.darkened(0.45), Vector3(10, 10, 0), 6)
		12:  # yonca / küçük yeşil bitki öbeği (renkli çiçek yok)
			for i in 9:
				var p = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				b.add("cyl", p + Vector3(0, 0.12, 0), Vector3(0.025, 0.24, 0.025), Color(0.3, 0.55, 0.22), Vector3.ZERO, 4)
				b.add_grad("sphere", p + Vector3(0, 0.26, 0), Vector3(0.26, 0.07, 0.26), Color(0.42, 0.7, 0.3), Color(0.22, 0.45, 0.16), Vector3.ZERO, 6)
		13:  # devrik, yosunlu kütük
			b.add_grad("cyl", Vector3(0, 0.45, 0), Vector3(0.9, 5.2, 0.9), bark.lightened(0.05), bark.darkened(0.3), Vector3(0, 0, 90), 8)
			b.add("box", Vector3(0, 0.88, 0), Vector3(4.2, 0.12, 0.55), Color(0.35, 0.56, 0.26), Vector3.ZERO)
			b.add("cyl", Vector3(1.4, 0.95, 0.2), Vector3(0.18, 1.2, 0.18), bark, Vector3(30, 0, -20), 5)
			b.add("cyl", Vector3(-2.6, 0.45, 0), Vector3(1.0, 0.1, 1.0), Color(0.75, 0.62, 0.45), Vector3(0, 0, 90), 8)
		14:  # mantar öbeği
			var caps = [Color(0.62, 0.45, 0.3), Color(0.75, 0.58, 0.4), Color(0.9, 0.82, 0.68)]
			for i in 5:
				var p = Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
				var h = randf_range(0.15, 0.4)
				b.add("cyl", p + Vector3(0, h * 0.5, 0), Vector3(0.07, h, 0.07), Color(0.95, 0.92, 0.85), Vector3.ZERO, 5)
				b.add("hemi", p + Vector3(0, h, 0), Vector3(0.28, 0.14, 0.28) * randf_range(0.8, 1.5), caps[i % 3], Vector3.ZERO, 7)
		15:  # uzun çimen öbeği
			for i in 14:
				var a = randf() * TAU
				var r = randf_range(0.0, 0.5)
				var h = randf_range(0.7, 1.3)
				b.add_grad("box", Vector3(cos(a) * r, h * 0.45, sin(a) * r), Vector3(0.08, h, 0.02), Color(0.62, 0.78, 0.32), Color(0.28, 0.48, 0.16), Vector3(randf_range(-15, 15), rad_to_deg(a), randf_range(-12, 12)))
		16:  # saz / kamış (su kenarı)
			for i in 11:
				var p = Vector3(randf_range(-0.9, 0.9), 0, randf_range(-0.9, 0.9))
				var h = randf_range(1.4, 2.2)
				b.add("cyl", p + Vector3(0, h * 0.5, 0), Vector3(0.05, h, 0.05), Color(0.45, 0.62, 0.3), Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)), 4)
				if i % 2 == 0:
					b.add("cyl", p + Vector3(0, h - 0.15, 0), Vector3(0.12, 0.35, 0.12), Color(0.45, 0.3, 0.18), Vector3.ZERO, 5)
		17:  # kuru çalı (çöl)
			var dc2 = Color(0.55, 0.45, 0.32)
			for i in 9:
				b.add("cyl", Vector3(0, 0.45, 0), Vector3(0.05, 1.1, 0.05), dc2, Vector3(randf_range(-55, 55), randf() * 360.0, randf_range(-55, 55)), 4)
			b.add("sphere", Vector3(0, 0.4, 0), Vector3(1.1, 0.7, 1.1), Color(0.62, 0.55, 0.38), Vector3.ZERO, 6)
		18:  # sade yeşil çalı (meyve/çiçek yok)
			_leaf_cluster(b, Vector3(0, 0.55, 0), 1.6, 0)
			_leaf_cluster(b, Vector3(0.5, 0.4, -0.3), 1.1, 2)
		19:  # yosunlu küçük kaya
			b.add_grad("sphere", Vector3(0, 0.3, 0), Vector3(1.4, 0.9, 1.2), Color(0.6, 0.58, 0.54), Color(0.38, 0.36, 0.33), Vector3(5, 30, 0), 6)
			b.add("sphere", Vector3(0.1, 0.62, 0), Vector3(1.0, 0.25, 0.9), Color(0.36, 0.58, 0.28), Vector3.ZERO, 6)
		20:  # karlı kaya
			b.add_grad("sphere", Vector3(0, 0.5, 0), Vector3(2.6, 1.6, 2.2), Color(0.55, 0.56, 0.6), Color(0.35, 0.36, 0.4), Vector3(8, 20, 5), 7)
			b.add("sphere", Vector3(0, 1.15, 0), Vector3(2.2, 0.5, 1.9), Color(0.96, 0.97, 1.0), Vector3.ZERO, 7)
	return b.build(foliage() if t in [0, 1, 5, 6, 7, 8, 9, 10, 12, 15, 16, 18] else toon())


## Uzak mesafe (LOD) modeli: aynı silüet, çok az poligon
## Anime ağacının gölge modeli: aynı çeşidin az kartlı kopyası (silüet birebir, maliyet düşük)
static func vegetation_shadow(t: int, variant := 0) -> ArrayMesh:
	var k: Array = ANIME_T[t]
	var kind: String = k[0]
	var pl: String = k[1]
	if t == 0:
		kind = ["broad", "slender", "oak"][variant % 3]
	elif t == 1 and variant % 2 == 1:
		kind = "pine"
		pl = "pine"
	elif t == 9 and variant == 2:
		pl = "death"
	return AnimeTree.mesh(kind, pl, variant, true)


## Çok uzak kademe (700 m+): ağaç başına birkaç düzine üçgen
static func vegetation_far(t: int) -> ArrayMesh:
	if not t in [0, 1, 2, 5, 6, 7, 9]:
		return null
	var k: Array = ANIME_T[t]
	return AnimeTree.mesh(k[0], k[1], 0, true, true)


static func vegetation_lod(t: int) -> ArrayMesh:
	if t in [0, 1, 2, 5, 6, 7, 9]:
		var k: Array = ANIME_T[t]
		return AnimeTree.mesh(k[0], k[1], 0, true)
	var b = MB.new()
	var bark = Color(0.4, 0.27, 0.17)
	match t:
		0:
			b.add("cyl", Vector3(0, 3.0, 0), Vector3(0.75, 6.0, 0.75), bark, Vector3.ZERO, 4)
			b.add_grad("sphere", Vector3(0, 7.4, 0), Vector3(8.5, 6.0, 8.5), Color(0.38, 0.68, 0.26), Color(0.12, 0.3, 0.12), Vector3.ZERO, 6)
		1:
			b.add_grad("cone", Vector3(0, 7.5, 0), Vector3(5.4, 13, 5.4), Color(0.22, 0.48, 0.32), Color(0.07, 0.2, 0.14), Vector3.ZERO, 5)
		5:
			b.add("cyl", Vector3(0, 28, 0), Vector3(6.4, 56, 6.4), Color(0.3, 0.2, 0.14), Vector3.ZERO, 6)
			b.add_grad("sphere", Vector3(0, 56, 0), Vector3(34, 18, 34), Color(0.2, 0.42, 0.18), Color(0.05, 0.15, 0.06), Vector3.ZERO, 7)
		9:
			b.add("cyl", Vector3(0, FOREST_TRUNK_H * 0.5, 0), Vector3(FOREST_TRUNK_R * 2.0, FOREST_TRUNK_H, FOREST_TRUNK_R * 2.0), bark, Vector3.ZERO, 5)
			b.add_grad("sphere", Vector3(0, FOREST_TRUNK_H - 2.0, 0), Vector3(19, 13, 19), Color(0.38, 0.7, 0.26), Color(0.12, 0.3, 0.12), Vector3.ZERO, 7)
			b.add_grad("sphere", Vector3(0, 15.0, 0), Vector3(21, 9, 21), Color(0.33, 0.62, 0.22), Color(0.1, 0.26, 0.1), Vector3.ZERO, 6)
		_:
			return null
	return b.build(foliage())


# ------------------------------------------------------------------ hazır model paketleri (Quaternius Stylized Nature MegaKit vb.)
## tip -> [dosyalar, hedef yükseklik (m), seçenekler]
const PACK := {
	0: [["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"], 10.5, {}],
	1: [["Pine_1", "Pine_2", "Pine_3", "Pine_4", "Pine_5"], 14.0, {}],
	2: [["DeadTree_1", "DeadTree_2", "DeadTree_3", "DeadTree_4", "DeadTree_5"], 9.0, {}],
	4: [["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"], 2.4, {}],
	5: [["TwistedTree_1", "TwistedTree_2", "TwistedTree_3", "TwistedTree_4"], 58.0, {"sway_amt": 0.0}],
	8: [["Bush_Common"], 1.7, {"sway_amt": 0.04, "sway_h": 1.6}],
	10: [["Fern_1", "Plant_1_Big", "Plant_7_Big", "Plant_1"], 1.0, {"sway_amt": 0.05, "sway_h": 1.0}],
	11: [["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"], 5.0, {}],
	# kırmızı/mor çiçekler kötü görünüyordu: yerine yonca ve küçük yeşil bitkiler
	12: [["Clover_1", "Clover_2", "Plant_1"], 0.5, {"sway_amt": 0.05, "sway_h": 0.5}],
	14: [["Mushroom_Common", "Mushroom_Laetiporus"], 0.45, {"sway": false}],
	15: [["Grass_Common_Tall", "Grass_Wispy_Tall", "Grass_Common_Short", "Grass_Wispy_Short"], 1.0, {"sway_amt": 0.08, "sway_h": 1.0}],
	18: [["Bush_Common"], 1.5, {"sway_amt": 0.04, "sway_h": 1.5}],
	19: [["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"], 0.9, {"tint": Color(0.85, 0.95, 0.8)}],
	20: [["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"], 2.0, {"tint": Color(0.92, 0.95, 1.05)}],
}
const PACK_BAMBOO := "res://assets/packs/japan/bamboo_auVD.glb"


## Tip için hazır model varyantları: [[yakın mesh, orta mesafe mesh], ...] (paket yoksa boş)
static func pack_variants(t: int) -> Array:
	var out = []
	if t == 6 and ResourceLoader.exists(PACK_BAMBOO):
		var m = AssetLib.mesh(PACK_BAMBOO, 11.0, 1.0, {"sway_amt": 0.12, "sway_h": 10.0})
		if m:
			out.append([m, AssetLib.lod(m, 0.3), AssetLib.lod(m, 0.1)])
		return out
	if not PACK.has(t):
		return out
	var spec: Array = PACK[t]
	for f in spec[0]:
		var path = AssetLib.NATURE + f + ".gltf"
		var m = AssetLib.mesh(path, float(spec[1]), 1.0, spec[2])
		if m == null:
			continue
		out.append([m, AssetLib.lod(m, 0.1 if t in [0, 1, 2, 5] else 0.3), AssetLib.lod(m, 0.03 if t in [0, 1, 2, 5] else 0.12)])
	return out


## Konoha orman ağacı (9): dallı gövde (yürünebilir çarpışmalarla birebir) + hazır modelden yaprak kümeleri
static func forest_tree_pack() -> ArrayMesh:
	var leaves: Array = []
	for f in ["CommonTree_1", "CommonTree_3", "CommonTree_5"]:
		var lm = AssetLib.mesh(AssetLib.NATURE + f + ".gltf", 0.0, 1.0, {"only": "leaves", "sway_amt": 0.05, "sway_h": 8.0})
		if lm and lm.get_surface_count() > 0:
			leaves.append(AssetLib.lod(lm, 0.25))  # dev ağaçta 9 küme var: hafif yaprak modeli yeter
	if leaves.is_empty():
		return null
	# kabuk dokulu gövde, kökler ve dallar (UV'li silindirler)
	var bark = ShaderMaterial.new()
	bark.shader = load("res://shaders/asset_toon.gdshader")
	bark.set_shader_parameter("tex", load(AssetLib.NATURE + "Bark_NormalTree.png"))
	bark.set_shader_parameter("uv_scale", Vector2(3.0, 6.0))
	bark.set_shader_parameter("tint", Color(0.82, 0.74, 0.7))
	bark.set_shader_parameter("saturation", 0.95)
	var st_b = SurfaceTool.new()
	st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk = CylinderMesh.new()
	trunk.top_radius = FOREST_TRUNK_R * 0.8
	trunk.bottom_radius = FOREST_TRUNK_R * 1.15
	trunk.height = FOREST_TRUNK_H
	trunk.radial_segments = 14
	trunk.rings = 4
	st_b.append_from(trunk, 0, Transform3D(Basis.IDENTITY, Vector3(0, FOREST_TRUNK_H * 0.5, 0)))
	for i in 5:
		var ra = i * 72.0 + 10.0
		var rd = Vector3(sin(deg_to_rad(ra)), 0, cos(deg_to_rad(ra)))
		var root_m = CylinderMesh.new()
		root_m.top_radius = 0.08
		root_m.bottom_radius = 0.42
		root_m.height = 2.0
		root_m.radial_segments = 8
		root_m.rings = 1
		# kök: geniş ucu gövdede, ince ucu dışarıda ve yerin içinde
		var axis_r = (rd * 0.8 - Vector3.UP * 0.6).normalized()
		var rb = Basis(Quaternion(Vector3.UP, axis_r))
		st_b.append_from(root_m, 0, Transform3D(rb, rd * (FOREST_TRUNK_R * 0.9 + 0.7) + Vector3(0, 0.35, 0)))
	for br in FOREST_BRANCHES:
		var a2: float = br[1]
		var L: float = br[2]
		var d2 = Vector3(sin(deg_to_rad(a2)), 0, cos(deg_to_rad(a2)))
		var bm = CylinderMesh.new()
		bm.top_radius = 0.22
		bm.bottom_radius = 0.48
		bm.height = L
		bm.radial_segments = 8
		bm.rings = 1
		var axis = d2.cross(Vector3.UP).normalized()
		var bb = Basis(axis, deg_to_rad(-80.0))
		st_b.append_from(bm, 0, Transform3D(bb, d2 * (FOREST_TRUNK_R + L * 0.5) + Vector3(0, br[0], 0)))
	st_b.generate_normals()
	var base := ArrayMesh.new()
	var ba = st_b.commit_to_arrays()
	var nv = (ba[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var wc = PackedColorArray()
	wc.resize(nv)
	wc.fill(Color.WHITE)
	ba[Mesh.ARRAY_COLOR] = wc
	base.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ba)
	base.surface_set_material(0, bark)

	# yaprak kümeleri: dal uçlarında + tepede (hazır yaprak modelleri, büyütülmüş)
	var st_leaf = {}
	var k = 0
	var places = []
	for br in FOREST_BRANCHES:
		var a3: float = br[1]
		var L3: float = br[2]
		var d3 = Vector3(sin(deg_to_rad(a3)), 0, cos(deg_to_rad(a3)))
		places.append([d3 * (FOREST_TRUNK_R + L3 * 0.75) + Vector3(0, br[0] - 2.0, 0), 1.45, a3])
	places.append([Vector3(0, FOREST_TRUNK_H - 7.0, 0), 2.2, 0.0])
	places.append([Vector3(3.0, FOREST_TRUNK_H - 9.0, 2.0), 1.6, 120.0])
	places.append([Vector3(-3.2, FOREST_TRUNK_H - 8.0, -1.6), 1.6, 240.0])
	for pl in places:
		var lm: ArrayMesh = leaves[k % leaves.size()]
		k += 1
		var xf = Transform3D(Basis(Vector3.UP, deg_to_rad(pl[2])).scaled(Vector3.ONE * pl[1]), pl[0])
		for si in lm.get_surface_count():
			var mat = lm.surface_get_material(si)
			if not st_leaf.has(mat):
				var stn = SurfaceTool.new()
				stn.begin(Mesh.PRIMITIVE_TRIANGLES)
				st_leaf[mat] = stn
			st_leaf[mat].append_from(lm, si, xf)
	for mat in st_leaf:
		var arr = st_leaf[mat].commit_to_arrays()
		base.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		base.surface_set_material(base.get_surface_count() - 1, mat)
	return base
