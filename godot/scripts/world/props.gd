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
		_toon.set_shader_parameter("detail_noise", 0.18)
	return _toon


static func foliage() -> ShaderMaterial:
	if _foliage == null:
		_foliage = ShaderMaterial.new()
		_foliage.shader = load("res://shaders/toon.gdshader")
		_foliage.set_shader_parameter("rim_amount", 0.3)
		_foliage.set_shader_parameter("sway", 1.0)
		_foliage.set_shader_parameter("detail_noise", 0.25)
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


static func vegetation_mesh(t: int) -> ArrayMesh:
	var b = MB.new()
	var bark = Color(0.4, 0.27, 0.17)
	match t:
		0:  # geniş yapraklı anime ağacı
			b.add("cyl", Vector3(0, 3.0, 0), Vector3(0.75, 6.0, 0.75), bark, Vector3.ZERO, 8)
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
				b.add("cone", Vector3(sin(i * 0.9) * 3.2, 1.8, cos(i * 0.9) * 3.2), Vector3(2.2, 7.0, 2.2), bk, Vector3(-60 * cos(i * 0.9), 0, 60 * sin(i * 0.9)), 6)
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
			for i in 6:
				var a = i * 60.0 + 15.0
				var d = Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a)))
				b.add("cone", d * 1.3 + Vector3(0, 1.2, 0), Vector3(0.9, 3.2, 0.9), tk.darkened(0.1), Vector3(-55 * d.z, 0, 55 * d.x), 6)
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
		12:  # çiçek öbeği
			var fc = [Color(0.95, 0.85, 0.3), Color(0.95, 0.5, 0.6), Color(0.8, 0.85, 1.0), Color(0.95, 0.95, 0.95)][randi() % 4]
			for i in 9:
				var p = Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
				b.add("cyl", p + Vector3(0, 0.25, 0), Vector3(0.03, 0.5, 0.03), Color(0.3, 0.55, 0.22), Vector3.ZERO, 4)
				b.add("sphere", p + Vector3(0, 0.52, 0), Vector3(0.16, 0.08, 0.16), fc, Vector3.ZERO, 6)
		13:  # devrik, yosunlu kütük
			b.add_grad("cyl", Vector3(0, 0.45, 0), Vector3(0.9, 5.2, 0.9), bark.lightened(0.05), bark.darkened(0.3), Vector3(0, 0, 90), 8)
			b.add("box", Vector3(0, 0.88, 0), Vector3(4.2, 0.12, 0.55), Color(0.35, 0.56, 0.26), Vector3.ZERO)
			b.add("cyl", Vector3(1.4, 0.95, 0.2), Vector3(0.18, 1.2, 0.18), bark, Vector3(30, 0, -20), 5)
			b.add("cyl", Vector3(-2.6, 0.45, 0), Vector3(1.0, 0.1, 1.0), Color(0.75, 0.62, 0.45), Vector3(0, 0, 90), 8)
		14:  # mantar öbeği
			var caps = [Color(0.85, 0.25, 0.2), Color(0.75, 0.55, 0.35), Color(0.95, 0.85, 0.7)]
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
		18:  # meyveli / çiçekli çalı
			_leaf_cluster(b, Vector3(0, 0.55, 0), 1.6, 0)
			var bc = [Color(0.85, 0.15, 0.2), Color(0.35, 0.3, 0.75), Color(0.98, 0.95, 0.95)][randi() % 3]
			for i in 10:
				var a = randf() * TAU
				b.add("sphere", Vector3(cos(a) * 0.7, 0.5 + randf() * 0.5, sin(a) * 0.7), Vector3(0.12, 0.12, 0.12), bc, Vector3.ZERO, 5)
		19:  # yosunlu küçük kaya
			b.add_grad("sphere", Vector3(0, 0.3, 0), Vector3(1.4, 0.9, 1.2), Color(0.6, 0.58, 0.54), Color(0.38, 0.36, 0.33), Vector3(5, 30, 0), 6)
			b.add("sphere", Vector3(0.1, 0.62, 0), Vector3(1.0, 0.25, 0.9), Color(0.36, 0.58, 0.28), Vector3.ZERO, 6)
		20:  # karlı kaya
			b.add_grad("sphere", Vector3(0, 0.5, 0), Vector3(2.6, 1.6, 2.2), Color(0.55, 0.56, 0.6), Color(0.35, 0.36, 0.4), Vector3(8, 20, 5), 7)
			b.add("sphere", Vector3(0, 1.15, 0), Vector3(2.2, 0.5, 1.9), Color(0.96, 0.97, 1.0), Vector3.ZERO, 7)
	return b.build(foliage() if t in [0, 1, 5, 6, 7, 8, 9, 10, 12, 15, 16, 18] else toon())


## Uzak mesafe (LOD) modeli: aynı silüet, çok az poligon
static func vegetation_lod(t: int) -> ArrayMesh:
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
	8: [["Bush_Common", "Bush_Common_Flowers"], 1.7, {"sway_amt": 0.04, "sway_h": 1.6}],
	10: [["Fern_1", "Plant_1_Big", "Plant_7_Big", "Plant_1"], 1.0, {"sway_amt": 0.05, "sway_h": 1.0}],
	11: [["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"], 5.0, {}],
	12: [["Flower_3_Group", "Flower_4_Group", "Flower_3_Single", "Flower_4_Single"], 0.75, {"sway_amt": 0.05, "sway_h": 0.7}],
	14: [["Mushroom_Common", "Mushroom_Laetiporus"], 0.45, {"sway": false}],
	15: [["Grass_Common_Tall", "Grass_Wispy_Tall", "Grass_Common_Short", "Grass_Wispy_Short"], 1.0, {"sway_amt": 0.08, "sway_h": 1.0}],
	18: [["Bush_Common_Flowers"], 1.5, {"sway_amt": 0.04, "sway_h": 1.5}],
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
