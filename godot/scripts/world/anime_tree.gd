class_name AnimeTree
extends RefCounted
## Anime ağaçları (ref tree1..tree10.png): dallı gövde + taç, tırtıklı yaprak öbeği kartlarından (assets/tex/anime_leaf.png,
## 2x2 atlas: "yaprak -> öbek -> ağaç" tekniği, tree9). Kartların normali taç merkezinden dışa (kütle gölgesi: güneşli üst
## canlı sarı-yeşil, öbek altları derin yeşil), köşe rengi tacın yüksekliğine göre açılır. Gövde ve yapraklar rüzgârda
## aynı formülle salınır (toon "sway" = anime_leaf "sway"). Üçgen bütçesi: geniş yapraklı ~400, orman devi ~900, LOD ~100.
## Orman ağacı (9) gövde/dal ölçüleri Props.FOREST_* ile birebir (dal çarpışmaları üstünde koşulur).

const PAL := {
	"green": [Color(0.66, 0.9, 0.3), Color(0.34, 0.68, 0.22), Color(0.1, 0.36, 0.15)],
	"forest": [Color(0.58, 0.86, 0.3), Color(0.28, 0.6, 0.2), Color(0.08, 0.3, 0.14)],
	"death": [Color(0.44, 0.7, 0.26), Color(0.2, 0.46, 0.18), Color(0.04, 0.17, 0.1)],
	"sakura": [Color(1.0, 0.88, 0.92), Color(0.98, 0.72, 0.82), Color(0.8, 0.46, 0.6)],
	"momiji": [Color(1.0, 0.66, 0.24), Color(0.94, 0.34, 0.14), Color(0.56, 0.1, 0.07)],
	"ginkgo": [Color(1.0, 0.94, 0.42), Color(0.98, 0.8, 0.24), Color(0.72, 0.52, 0.08)],
	"bush": [Color(0.6, 0.86, 0.3), Color(0.3, 0.62, 0.2), Color(0.1, 0.32, 0.14)],
}
const BARK := {"green": Color(0.43, 0.35, 0.28), "forest": Color(0.45, 0.39, 0.32), "death": Color(0.31, 0.26, 0.21),
	"sakura": Color(0.32, 0.24, 0.22), "momiji": Color(0.38, 0.28, 0.2), "ginkgo": Color(0.46, 0.38, 0.28), "bush": Color(0.4, 0.32, 0.24)}

static var _leaf_m: ShaderMaterial
static var _bark_m: ShaderMaterial
static var _cache := {}


static func leaf_mat() -> ShaderMaterial:
	if _leaf_m == null:
		_leaf_m = ShaderMaterial.new()
		_leaf_m.shader = load("res://shaders/anime_leaf.gdshader")
		_leaf_m.set_shader_parameter("leaf_tex", load("res://assets/tex/anime_leaf.png"))
	return _leaf_m


static func bark_mat() -> ShaderMaterial:
	if _bark_m == null:
		_bark_m = Props.bark_toon().duplicate()
		_bark_m.set_shader_parameter("sway", 1.0)   # yapraklarla aynı salınım (dal uçları öbeklerden kopmasın)
		_bark_m.set_shader_parameter("rim_amount", 0.15)
	return _bark_m


## kind: broad / oak / slender / forest / giant / bush; pal: PAL anahtarı; lod: uzak kopya (öbek başına tek kart, ince gövde)
static func mesh(kind: String, pal := "green", seed := 0, lod := false) -> ArrayMesh:
	var key = "%s|%s|%d|%s" % [kind, pal, seed, lod]
	if _cache.has(key):
		return _cache[key]
	var t = AnimeTree.new()
	t.rng.seed = hash(key)
	t.pal = PAL.get(pal, PAL["green"])
	t.bark = BARK.get(pal, BARK["green"])
	t.lod = lod
	t.call("_" + kind)
	var m = t._commit()
	_cache[key] = m
	return m


var rng := RandomNumberGenerator.new()
var pal: Array
var bark: Color
var lod := false
var sb := SurfaceTool.new()   # gövde
var sl := SurfaceTool.new()   # yaprak kartları
var nb := 0
var nl := 0


func _init() -> void:
	sb.begin(Mesh.PRIMITIVE_TRIANGLES)
	sl.begin(Mesh.PRIMITIVE_TRIANGLES)


func _commit() -> ArrayMesh:
	var m := ArrayMesh.new()
	if nb > 0:
		sb.commit(m)
		m.surface_set_material(m.get_surface_count() - 1, bark_mat())
	if nl > 0:
		sl.commit(m)
		m.surface_set_material(m.get_surface_count() - 1, leaf_mat())
	return m


# ------------------------------------------------------------------ gövde parçaları
## a -> b sivrilen dal/gövde (kesit seg kenar); renk dibe doğru koyulaşır
func limb(a: Vector3, b: Vector3, r0: float, r1: float, seg := 7) -> void:
	if lod:
		seg = 4
	var ax := b - a
	var L := ax.length()
	if L < 0.01:
		return
	var d := ax / L
	var u := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
	var v := d.cross(u)
	var c0 := bark.darkened(0.18)
	var c1 := bark.lightened(0.04)
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var n0 := u * cos(a0) + v * sin(a0)
		var n1 := u * cos(a1) + v * sin(a1)
		var p00 := a + n0 * r0
		var p01 := a + n1 * r0
		var p10 := b + n0 * r1
		var p11 := b + n1 * r1
		for q in [[p00, n0, c0], [p10, n0, c1], [p11, n1, c1], [p00, n0, c0], [p11, n1, c1], [p01, n1, c0]]:
			sb.set_color(q[2])
			sb.set_normal(q[1])
			sb.set_uv(Vector2.ZERO)
			sb.add_vertex(q[0])
		nb += 2


## Gövde dibinden toprağa kıvrılan kök çıkıntıları
func roots(r: float, n: int, spread: float) -> void:
	if lod:
		return
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.25, 0.25)
		var d := Vector3(sin(a), 0, cos(a))
		var L := spread * rng.randf_range(0.75, 1.15)
		# gövdeye kaynaşan kök: gövde içinden çıkar, yay çizip toprağa dalar (yuvarlak kesit)
		var p0 := Vector3(0, r * 1.6, 0) + d * r * 0.35
		var p1 := d * (r * 0.9 + L * 0.3) + Vector3(0, r * 0.45, 0)
		var p2 := d * (r * 0.9 + L * 0.75) + Vector3(0, r * 0.12, 0)
		var p3 := d * (r * 0.9 + L * 1.1) + Vector3(0, -0.2, 0)
		limb(p0, p1, r * 0.55, r * 0.36, 6)
		limb(p1, p2, r * 0.36, r * 0.2, 6)
		limb(p2, p3, r * 0.2, r * 0.05, 5)


# ------------------------------------------------------------------ yaprak öbekleri
## c merkezli, r yarıçaplı öbek; cc taç merkezi (normal yönü), y0..y1 taç boyu (renk açılması)
func clump(c: Vector3, r: float, cc: Vector3, y0: float, y1: float, cards := 6, tone := 0.0) -> void:
	if lod:
		cards = 2   # uzak kopya: öbek başına iki çapraz büyük kart (seyrek "çubuk" görünmesin)
	var jit = rng.randf_range(-0.05, 0.05) + tone
	for i in cards:
		var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.7, 0.8), rng.randf_range(-1, 1)) * r * (0.45 if not lod else 0.1)
		var p := c + off
		var size := r * (rng.randf_range(1.15, 1.55) if not lod else 2.7)
		var out := (p - cc)
		out = out.normalized() if out.length() > 0.01 else Vector3.UP
		var rnd := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var nrm := out.lerp(rnd, 0.55).normalized()
		if lod:
			nrm = (out + Vector3(0, 0.3, 0)).normalized().rotated(Vector3.UP, PI * 0.5 * i)
		var u := nrm.cross(Vector3.UP if absf(nrm.y) < 0.9 else Vector3.RIGHT).normalized()
		var v := nrm.cross(u)
		var rot := rng.randf() * TAU
		var uu := u * cos(rot) + v * sin(rot)
		var vv := nrm.cross(uu)
		var q := rng.randi() % 4
		var uv0 := Vector2(float(q % 2) * 0.5, float(q >> 1) * 0.5)
		var corners = [[p - uu * size * 0.5 - vv * size * 0.5, uv0 + Vector2(0.0, 0.5)], [p + uu * size * 0.5 - vv * size * 0.5, uv0 + Vector2(0.5, 0.5)],
			[p + uu * size * 0.5 + vv * size * 0.5, uv0 + Vector2(0.5, 0.0)], [p - uu * size * 0.5 + vv * size * 0.5, uv0]]
		var vs = []
		for cr in corners:
			var pp: Vector3 = cr[0]
			var h := clampf((pp.y - y0) / maxf(0.5, y1 - y0) + jit, 0.0, 1.0)
			var col: Color = (pal[2] as Color).lerp(pal[1], smoothstep(0.0, 0.55, h)).lerp(pal[0], smoothstep(0.55, 1.0, h) * 0.75)
			var on := (pp - cc)
			var vn := (on.normalized() * 0.75 + (pp - c).normalized() * 0.25 + Vector3(0, 0.12, 0)).normalized()
			vs.append([pp, cr[1], col, vn])
		for k in [0, 1, 2, 0, 2, 3]:
			var w = vs[k]
			sl.set_color(w[2])
			sl.set_normal(w[3])
			sl.set_uv(w[1])
			sl.add_vertex(w[0])
		nl += 2


## Elipsoit taç: üst kubbede düzgün dağılmış öbekler + içte koyu dolgu (taçtan gök görünmesin)
func crown(cc: Vector3, rad: Vector3, n: int, cr: float, bottom := -0.35) -> Array:
	var tips: Array = []
	var y0 := cc.y - rad.y
	var y1 := cc.y + rad.y
	var ga := PI * (3.0 - sqrt(5.0))
	for i in n:
		var yy := 1.0 - (float(i) + 0.5) / n * (1.0 - bottom)   # 1 .. bottom
		var rr := sqrt(maxf(0.0, 1.0 - yy * yy))
		var a := ga * i + rng.randf_range(-0.3, 0.3)
		var dir := Vector3(cos(a) * rr, yy, sin(a) * rr)
		var p := cc + Vector3(dir.x * rad.x, dir.y * rad.y, dir.z * rad.z) * rng.randf_range(0.82, 1.0)
		clump(p, cr * rng.randf_range(0.85, 1.15), cc, y0, y1)
		tips.append(p)
	if not lod:
		for i in maxi(2, n / 6):   # iç dolgu
			var p := cc + Vector3(rng.randf_range(-0.4, 0.4) * rad.x, rng.randf_range(-0.5, 0.1) * rad.y, rng.randf_range(-0.4, 0.4) * rad.z)
			clump(p, cr * 1.3, cc, y0, y1, 4, -0.25)
	return tips


## Gövde ucundan taçtaki öbeklere uzanan dallar (taçın içinde dallanma görünür)
func branches_to(from: Vector3, tips: Array, k: int, r0: float) -> void:
	var picks = tips.duplicate()
	picks.shuffle()
	for i in mini(k, picks.size()):
		var tip: Vector3 = picks[i]
		var mid := from.lerp(tip, 0.55) + Vector3(rng.randf_range(-0.4, 0.4), 0.4, rng.randf_range(-0.4, 0.4))
		limb(from, mid, r0, r0 * 0.6, 6)
		if not lod:
			limb(mid, from.lerp(tip, 0.85), r0 * 0.6, r0 * 0.25, 5)


# ------------------------------------------------------------------ türler
## Geniş yapraklı (tree6/7/10): kısa gövde, 4-5 ana dala çatallanır, kubbe taç
func _broad() -> void:
	var th = 4.2
	limb(Vector3.ZERO, Vector3(0, th, 0), 0.46, 0.32, 8)
	roots(0.45, 5, 0.9)
	var cc = Vector3(rng.randf_range(-0.3, 0.3), 8.2, rng.randf_range(-0.3, 0.3))
	var tips = crown(cc, Vector3(4.6, 3.4, 4.6), 24, 2.2)
	branches_to(Vector3(0, th - 0.3, 0), tips, 6, 0.3)


## Yaşlı meşe (tree10): kalın gövde, geniş yayvan taç
func _oak() -> void:
	var th = 4.6
	limb(Vector3.ZERO, Vector3(0, th, 0), 0.75, 0.55, 9)
	roots(0.75, 6, 1.4)
	var cc = Vector3(0, 9.2, 0)
	var tips = crown(cc, Vector3(6.4, 4.0, 6.4), 32, 2.6, -0.45)
	branches_to(Vector3(0, th - 0.4, 0), tips, 8, 0.42)


## İnce genç ağaç (tree8): ince uzun gövde, yuvarlak taç
func _slender() -> void:
	var th = 5.0
	limb(Vector3.ZERO, Vector3(0.15, th, 0.05), 0.24, 0.15, 6)
	roots(0.22, 3, 0.4)
	var cc = Vector3(0.15, 7.6, 0.05)
	var tips = crown(cc, Vector3(2.9, 3.2, 2.9), 16, 1.6, -0.5)
	branches_to(Vector3(0.15, th - 0.6, 0.05), tips, 4, 0.14)


## Konoha orman devi (tree2/3/5; Kakashi'nin zil testi ağaçları): düz uzun gövde, dallarda öbek kümeleri, yüksek taç.
## Dallar FOREST_BRANCHES ile birebir (yatay: çarpışma kutusunun üstü yürünür)
func _forest() -> void:
	var H: float = Props.FOREST_TRUNK_H
	var R: float = Props.FOREST_TRUNK_R
	limb(Vector3.ZERO, Vector3(0, H * 0.55, 0), R * 1.15, R * 0.95, 10)
	limb(Vector3(0, H * 0.55, 0), Vector3(0, H + 1.0, 0), R * 0.95, R * 0.55, 10)
	roots(R, 7, 2.2)
	var cc_top = Vector3(0, H + 2.5, 0)
	for br in Props.FOREST_BRANCHES:
		var a = deg_to_rad(br[1])
		var L: float = br[2]
		var d = Vector3(sin(a), 0, cos(a))
		var y: float = br[0]
		var tip = d * (R + L) + Vector3(0, y + 0.15, 0)
		limb(Vector3(0, y, 0), tip, 0.48, 0.24, 7)
		# dal ucu ve üstünde öbek kümesi (dalın üstü yürünebilir kalsın: öbekler dal hizasının üstünde/ucunda)
		var cc = tip + d * 1.2 + Vector3(0, 2.0, 0)
		for k in 4:
			var o = Vector3(rng.randf_range(-1, 1) * 2.0, rng.randf_range(-0.3, 1.0) * 1.2, rng.randf_range(-1, 1) * 2.0) + d * rng.randf_range(0.0, 1.8)
			clump(cc + o, 2.7, cc - Vector3(0, 1.2, 0), cc.y - 2.5, cc.y + 3.0)
	var tips = crown(cc_top, Vector3(7.5, 5.0, 7.5), 22, 3.0, -0.3)
	branches_to(Vector3(0, H - 2.0, 0), tips, 5, 0.5)


## Ölüm Ormanı devi (anime 44. Alan): dev gövde, yayılan dev kökler, gövde boyunca kalın dallar, koyu yoğun tavan
func _giant() -> void:
	var H = 56.0
	limb(Vector3.ZERO, Vector3(0, H * 0.5, 0), 3.4, 3.0, 12)
	limb(Vector3(0, H * 0.5, 0), Vector3(0, H, 0), 3.0, 2.0, 12)
	roots(3.2, 9, 7.5)
	for i in 6:
		var a = deg_to_rad(i * 60.0 + 20.0)
		var y = 14.0 + i * 6.0
		var d = Vector3(sin(a), 0, cos(a))
		var tip = d * 15.0 + Vector3(0, y + 1.0, 0)
		limb(Vector3(0, y, 0) + d * 2.4, tip, 1.15, 0.55, 8)
		var cc = tip + Vector3(0, 2.5, 0)
		for k in 5:
			var o = Vector3(rng.randf_range(-1, 1) * 3.5, rng.randf_range(-0.4, 1.0) * 2.0, rng.randf_range(-1, 1) * 3.5) + d * rng.randf_range(0.0, 3.0)
			clump(cc + o, 4.6, cc - Vector3(0, 2.0, 0), cc.y - 4.0, cc.y + 5.0)
	var tips = crown(Vector3(0, H + 2.0, 0), Vector3(22.0, 9.0, 22.0), 34, 6.2, -0.4)
	branches_to(Vector3(0, H - 4.0, 0), tips, 7, 1.0)


## Çalı: yerden öbekler
func _bush() -> void:
	var cc = Vector3(0, 0.55, 0)
	for i in 6:
		var a = TAU * i / 6.0 + rng.randf_range(-0.3, 0.3)
		var p = cc + Vector3(cos(a) * 0.7, rng.randf_range(-0.1, 0.35), sin(a) * 0.7)
		clump(p, 0.85, cc - Vector3(0, 0.4, 0), 0.0, 1.5, 4)
	clump(cc + Vector3(0, 0.45, 0), 0.95, cc - Vector3(0, 0.4, 0), 0.0, 1.5, 4)
