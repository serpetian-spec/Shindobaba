class_name GedoMazo
extends Node3D
## Gedō Mazō (kanon): On Kuyruk'un kabuğu, Rinnegan ile çağrılan dev heykel. Referans (Narutopedia kareleri):
## zayıf ama iri omuzlu insansı beden, ağaç damarlı gri-mor deri ve sarmal izler; sırttan yukarı-dışa yelpaze gibi açılan,
## uçları düz kesik kalın kütük çıkıntılar; dikey oluklu kubbe kafa; DOKUZ göz delikli bağlı göz bandı (gözler kapalı,
## her mühürlenen kuyruklu canavarla biri açılır); uzun çene ve iri dişler; bandın altından iki yana sarkan düğümlü ipler
## (savaşta ağızdaki parşömen sol ipe küpe gibi asılı kalır); bileklerde ve ayak bileklerinde kırık prangalar.
## Boy: ayakta ~100 m (kanon: "dokuz gözünün her biri yetişkin bir insan boyunda").
## Tasarım birimi: ayakta boy 10 birim (BeastRig.D), ön -Z.

const H := 100.0
const SKIN := Color(0.7, 0.6, 0.64)
const GRAIN := Color(0.4, 0.32, 0.38)
const IRON := Color(0.2, 0.2, 0.23)
const CLOTH := Color(0.8, 0.79, 0.77)
const TEETH := Color(0.93, 0.9, 0.8)
const ROPE := Color(0.32, 0.27, 0.3)

var rig: BeastRig
var root: Node3D
var hips: Node3D
var torso: Node3D
var head: Node3D
var jaw: Node3D
var arms: Array = []   # [{"sh", "el", "side"}]
var legs: Array = []   # [{"hip", "kn", "side"}]
var eyes_open := 0
var t := 0.0
var pose_from := {}
var pose_to := {}
var pose_k := 1.0
var pose_dur := 0.5
var jaw_open := 0.0
var jaw_want := 0.0
var head_pitch := 0.0
var shake := 0.0


static func spawn(parent: Node, at: Vector3, yaw: float, open_eyes := 0) -> GedoMazo:
	var g = GedoMazo.new()
	g.eyes_open = open_eyes
	parent.add_child(g)
	g.global_position = at
	g.rotation.y = yaw
	return g


func _ready() -> void:
	_build()
	set_pose("crouch", 0.0)


# ------------------------------------------------------------------ kurulum
func _mi(parent: Node3D, mb: MB) -> MeshInstance3D:
	return rig._mesh(parent, mb)


func _build() -> void:
	rig = BeastRig.new()
	rig.id = "gedo_mazo"
	rig.height_m = H
	add_child(rig)
	root = Node3D.new()
	root.name = "Design"
	rig.add_child(root)
	hips = rig._pivot(root, Vector3(0, 4.7, 0), "kalca")
	# leğen
	var pb = MB.new()
	var psp = [Vector3(0, -0.45, 0.05), Vector3(0, -0.1, 0.0), Vector3(0, 0.35, 0.0)]
	var prd = [Vector2(0.62, 0.48), Vector2(0.78, 0.55), Vector2(0.66, 0.48)]
	Loft.tube(pb, psp, prd, SKIN, 18, 3)
	_mi(hips, pb)
	BeastModels._grain(rig, hips, psp, prd, 18, 701, GRAIN, 0.026)
	BeastModels._swirls(rig, hips, psp, prd, 2, 702, GRAIN, 0.03, 1.2)
	torso = rig._pivot(hips, Vector3(0, 0.3, 0), "govde")
	_build_torso()
	_build_back()
	head = rig._pivot(torso, Vector3(0, 3.45, -0.25), "bas")
	head.scale = Vector3.ONE * 1.25
	_build_head()
	for s in [-1.0, 1.0]:
		_build_arm(s)
		_build_leg(s)
	root.scale = Vector3.ONE * rig.design_scale()
	var bm = BeastModels.beast_material(1, Color(0.36, 0.27, 0.4))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == null and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == Props.toon():
			mi.material_override = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if mi.get_aabb().size.length() > 1.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_torso() -> void:
	# karın içe çökük (açlık), göğüs-omuz kütlesi iri; sırt kambur
	var spine = [Vector3(0, -0.1, 0.02), Vector3(0, 0.8, 0.08), Vector3(0, 1.7, 0.16), Vector3(0, 2.55, 0.18), Vector3(0, 3.1, 0.05)]
	var rad = [Vector2(0.82, 0.56), Vector2(0.88, 0.6), Vector2(1.22, 0.82), Vector2(1.42, 0.85), Vector2(0.62, 0.46)]
	var mb = MB.new()
	Loft.tube(mb, spine, rad, SKIN, 22, 4)
	for s in [-1.0, 1.0]:
		# omuz/deltoid: iri yuvarlak kütle (protrüzyonların kökü)
		Loft.blob(mb, Vector3(s * 1.4, 2.55, 0.1), Vector3(s * 0.45, -1, 0.1), 1.5, [Vector2(0.25, 0.25), Vector2(0.66, 0.62), Vector2(0.6, 0.56), Vector2(0.25, 0.25)], SKIN, 14)
		Loft.blob(mb, Vector3(s * 0.55, 2.1, -0.62), Vector3(s * 1, -0.35, 0), 1.0, [Vector2(0.12, 0.1), Vector2(0.42, 0.24), Vector2(0.36, 0.2), Vector2(0.1, 0.08)], SKIN, 12)
		for k in 4:   # kaburga çıkıntıları (aç, kemikli karın)
			var y = 1.0 + k * 0.22
			Loft.tube(mb, [Vector3(s * 0.12, y, -0.52), Vector3(s * 0.48, y + 0.05, -0.47), Vector3(s * 0.8, y + 0.1, -0.26)], [0.035, 0.05, 0.03], SKIN.darkened(0.05), 6, 3)
	_mi(torso, mb)
	var nb = MB.new()
	Loft.tube(nb, [Vector3(0, 2.85, 0.05), Vector3(0, 3.15, -0.1), Vector3(0, 3.45, -0.25)], [Vector2(0.5, 0.42), Vector2(0.42, 0.38), Vector2(0.36, 0.34)], SKIN, 14, 3)
	_mi(torso, nb)
	BeastModels._grain(rig, torso, spine, rad, 70, 711, GRAIN, 0.028)
	BeastModels._swirls(rig, torso, spine, rad, 6, 712, GRAIN, 0.03, 1.3)


## Sırt çıkıntıları: kürek kemikleri ve omuz tepelerinden yukarı-dışa açılan dokuz kütük; ortadaki başın arkasında en uzun.
## Referans: kalınlıkları farklı, hafif eğri ve kıvrık, yer yer düğüm/dal kökü; uçlar eğik kesik (koyu kesit), yüzey damarlı.
func _build_back() -> void:
	var mb = MB.new()
	var tips = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 4711
	var n = 12
	for i in n:
		# başın çevresinde ışınsal taç: kesit açısı phi (0 = tam arka, ±PI/2 = yanlar), omurga yönüne (+Y, başa doğru) eğik
		var u = (i - (n - 1) * 0.5) / ((n - 1) * 0.5)   # -1..1
		var au = absf(u)
		var phi = u * 2.35 + rng.randf_range(-0.08, 0.08)   # uçtakiler omuzdan öne-yana (yüzü çevreler)
		var radial = Vector3(sin(phi), 0, cos(phi))
		var base = Vector3(sin(phi) * 1.0, 2.35 + rng.randf_range(-0.15, 0.2) - au * 0.25, cos(phi) * 0.55 + 0.15)
		var dir = (radial * (0.8 + au * 0.35) + Vector3.UP * (1.15 - au * 0.35)).normalized()
		var L = 2.35 + rng.randf_range(-0.35, 0.35) - au * 0.3 + (0.3 if au < 0.15 else 0.0)
		var r0 = 0.38 + rng.randf_range(-0.06, 0.06) - au * 0.05
		var side = dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
		var p1 = base + dir * L * 0.33 + side * rng.randf_range(-0.22, 0.22)
		var p2 = base + dir * L * 0.66 + side * rng.randf_range(-0.3, 0.3) + Vector3(0, rng.randf_range(-0.15, 0.2), 0.1)
		var p3 = base + dir * L + radial * 0.15
		var pts = [base - dir * 0.35, p1, p2, p3]
		var rr = [Vector2(r0 * 1.45, r0 * 1.3), Vector2(r0 * 1.05, r0 * 0.95), Vector2(r0 * 0.9, r0 * 0.85), Vector2(r0 * 0.8, r0 * 0.78)]
		Loft.tube(mb, pts, rr, SKIN, 12, 3, true, false)
		if rng.randf() < 0.5:   # dal kökü: kısa, küt yan çıkıntı
			var q = base + dir * L * rng.randf_range(0.35, 0.6)
			var sd = (side * (1.0 if rng.randf() < 0.5 else -1.0) + dir * 0.6).normalized()
			Loft.tube(mb, [q, q + sd * 0.35, q + sd * 0.55], [r0 * 0.5, r0 * 0.38, r0 * 0.32], SKIN, 8, 2, true, false)
			tips.add("cyl", q + sd * 0.55, Vector3(r0 * 0.64, 0.03, r0 * 0.64), Color(0.16, 0.13, 0.16), Basis(Quaternion(Vector3.UP, sd)).get_euler() * (180.0 / PI), 10)
		# eğik kesik uç: kesit diski uç yönünden biraz sapık
		var td: Vector3 = ((p3 - p2).normalized() + side * rng.randf_range(-0.35, 0.35)).normalized()
		var cap = r0 * 0.8
		tips.add("cyl", p3, Vector3(cap * 2.0, 0.04, cap * 2.0), Color(0.16, 0.13, 0.16), Basis(Quaternion(Vector3.UP, td)).get_euler() * (180.0 / PI), 12)
		BeastModels._grain(rig, torso, pts, rr, 10, 720 + i, GRAIN, 0.026)
	_mi(torso, mb)
	_mi(torso, tips)


func _build_head() -> void:
	var mb = MB.new()
	# kubbe kafatası: uzun, arkaya doğru; dikey oluklar
	Loft.blob(mb, Vector3(0, 0.62, 0.02), Vector3(0, 1, 0.12), 1.05, [Vector2(0.3, 0.28), Vector2(0.5, 0.46), Vector2(0.52, 0.5), Vector2(0.44, 0.42), Vector2(0.18, 0.16)], SKIN, 18)
	for k in 7:
		var a = lerpf(-1.25, 1.25, k / 6.0)
		var pts = []
		for q in 6:
			var v = lerpf(-0.2, 1.35, q / 5.0)
			pts.append(Vector3(sin(a) * cos(v) * 0.5, 0.62 + sin(v) * 0.5, -cos(a) * cos(v) * 0.47 + 0.02))
		Loft.tube(mb, pts, [0.02, 0.03, 0.03, 0.03, 0.025, 0.015], GRAIN.lightened(0.1), 5, 2)
	# üst çene: bandın altında daralan, öne çıkık kemik (dudak yok: dişler açıkta, sırıtış); yanlarda çökük yanak
	Loft.blob(mb, Vector3(0, 0.33, -0.08), Vector3(0, 1, 0.15), 0.42, [Vector2(0.34, 0.3), Vector2(0.44, 0.4), Vector2(0.48, 0.44)], SKIN, 16)
	for sx in [-1.0, 1.0]:
		Loft.tube(mb, [Vector3(sx * 0.42, 0.42, -0.2), Vector3(sx * 0.4, 0.28, -0.3), Vector3(sx * 0.3, 0.2, -0.38)], [0.05, 0.06, 0.04], SKIN.darkened(0.08), 6, 2)
	_mi(head, mb)
	# göz bandı: başı saran yassı bez şerit
	var bb = MB.new()
	var ring = []
	var rr = []
	for k in 25:
		var a = TAU * k / 24.0
		ring.append(Vector3(sin(a) * 0.53, 0.56, -cos(a) * 0.5 + 0.02))
		rr.append(Vector2(0.03, 0.17))
	Loft.tube(bb, ring, rr, CLOTH, 6, 2, false, false)
	_mi(head, bb)
	# dokuz göz: bandın önünde yay boyunca, ortadaki ortada; sağa-sola iki sıra (V biçimli)
	var eb = MB.new()
	var slots = [[0.0, 0.0]]
	for s in [-1.0, 1.0]:
		slots.append([s * 0.42, 0.07])
		slots.append([s * 0.62, -0.05])
		slots.append([s * 0.95, 0.06])
		slots.append([s * 1.15, -0.06])
	for i in slots.size():
		var a = float(slots[i][0])
		var y = 0.56 + float(slots[i][1])
		var p = Vector3(sin(a) * 0.555, y, -cos(a) * 0.525 + 0.02)
		var rot = Vector3(0, -rad_to_deg(a), 0)
		var open = i < eyes_open
		eb.add("sphere", p, Vector3(0.15, 0.085, 0.05), Color(0.18, 0.15, 0.18), rot, 10)   # delik (koyu kenar)
		if open:
			eb.add("sphere", p + Vector3(sin(a), 0, -cos(a)) * 0.012, Vector3(0.125, 0.07, 0.04), Color(0.96, 0.96, 0.98), rot, 10)
			eb.add("sphere", p + Vector3(sin(a), 0, -cos(a)) * 0.022, Vector3(0.05, 0.05, 0.03), Color(0.55, 0.78, 0.95), rot, 8)
		else:
			eb.add("sphere", p + Vector3(sin(a), 0, -cos(a)) * 0.01, Vector3(0.125, 0.068, 0.042), SKIN.darkened(0.08), rot, 10)   # kapalı göz kapağı
			eb.add("box", p + Vector3(sin(a), 0, -cos(a)) * 0.032, Vector3(0.11, 0.008, 0.008), Color(0.15, 0.12, 0.15), rot)
	_mi(head, eb)
	# düğümlü ipler: bandın altından iki yana sarkar (halka düğümler, uçta püskül)
	var rb = MB.new()
	for s in [-1.0, 1.0]:
		var top = Vector3(s * 0.5, 0.42, -0.1)
		var bot = Vector3(s * 0.52, -0.55, -0.16)
		Loft.tube(rb, [top, top.lerp(bot, 0.5) + Vector3(s * 0.02, 0, 0), bot], [0.028, 0.026, 0.024], ROPE, 6, 3)
		for k in 3:
			rb.add("cyl", top.lerp(bot, 0.3 + k * 0.22), Vector3(0.07, 0.05, 0.07), ROPE.darkened(0.2), Vector3.ZERO, 8)
		rb.add("cone", bot + Vector3(0, -0.06, 0), Vector3(0.08, 0.14, 0.08), ROPE, Vector3(180, 0, 0), 8)
	# parşömen: savaşta sol ipe küpe gibi asılı
	rb.add("cyl", Vector3(-0.56, -0.68, -0.16), Vector3(0.09, 0.32, 0.09), Color(0.85, 0.78, 0.6), Vector3(0, 0, 8), 10)
	rb.add("cyl", Vector3(-0.56, -0.68, -0.16), Vector3(0.1, 0.06, 0.1), Color(0.5, 0.2, 0.15), Vector3(0, 0, 8), 10)
	_mi(head, rb)
	# üst diş sırası: iri, kare uçlu, yan yana dizili (sırıtış), diş eti koyu çizgi
	var tb = MB.new()
	for k in 11:
		var a = lerpf(-1.05, 1.05, k / 10.0)
		var p = Vector3(sin(a) * 0.4, 0.2, -cos(a) * 0.4 - 0.06)
		var hh = 0.15 - absf(a) * 0.04
		tb.add("box", p, Vector3(0.068, hh, 0.05), TEETH, Vector3(0, -rad_to_deg(a), 0))
		tb.add("box", p + Vector3(0, hh * 0.5 + 0.01, 0.005), Vector3(0.075, 0.022, 0.055), Color(0.2, 0.12, 0.14), Vector3(0, -rad_to_deg(a), 0))
	tb.add("sphere", Vector3(0, 0.02, -0.3), Vector3(0.66, 0.42, 0.42), Color(0.06, 0.03, 0.05), Vector3.ZERO, 12)   # ağız içi (gırtlak boşluğu)
	_mi(head, tb)
	# alt çene: uzun, dikey oluklu, aşağı sivrilen (Kuchiyose karesi); alt diş sırası üsttekine kapanır
	jaw = rig._pivot(head, Vector3(0, 0.2, 0.15), "cene")
	var jb = MB.new()
	Loft.tube(jb, [Vector3(0, -0.12, -0.12), Vector3(0, -0.34, -0.42), Vector3(0, -0.62, -0.5), Vector3(0, -0.9, -0.46)], [Vector2(0.42, 0.13), Vector2(0.36, 0.14), Vector2(0.22, 0.12), Vector2(0.08, 0.07)], SKIN, 14, 3)
	for k in 7:
		var x = lerpf(-0.24, 0.24, k / 6.0)
		Loft.tube(jb, [Vector3(x, -0.18, -0.53), Vector3(x * 0.75, -0.5, -0.62), Vector3(x * 0.4, -0.84, -0.55)], [0.01, 0.014, 0.008], GRAIN, 4, 2)
	for k in 11:
		var a = lerpf(-1.0, 1.0, k / 10.0)
		var p = Vector3(sin(a) * 0.37, -0.08, -cos(a) * 0.37 - 0.2)
		jb.add("box", p, Vector3(0.064, 0.13 - absf(a) * 0.03, 0.05), TEETH, Vector3(0, -rad_to_deg(a), 0))
	_mi(jaw, jb)


func _build_arm(s: float) -> void:
	var sh = rig._pivot(torso, Vector3(s * 1.55, 2.6, 0.1), "omuz")
	var mb = MB.new()
	var up = [Vector3(0, 0.15, 0), Vector3(s * 0.05, -0.85, 0), Vector3(0, -1.8, 0)]
	var ur = [Vector2(0.55, 0.55), Vector2(0.48, 0.44), Vector2(0.34, 0.32)]
	Loft.tube(mb, up, ur, SKIN, 14, 3)
	_mi(sh, mb)
	BeastModels._grain(rig, sh, up, ur, 16, 730 + int(s), GRAIN, 0.022)
	var el = rig._pivot(sh, Vector3(0, -1.8, 0), "dirsek")
	var fb = MB.new()
	var fp = [Vector3(0, 0.08, 0), Vector3(0, -0.8, -0.03), Vector3(0, -1.65, 0)]
	var fr = [Vector2(0.36, 0.34), Vector2(0.33, 0.29), Vector2(0.23, 0.2)]
	Loft.tube(fb, fp, fr, SKIN, 12, 3)
	# kırık pranga: kalın demir bilezik (dikey çizgili), kopuk zincir halkaları
	fb.add("cyl", Vector3(0, -1.42, 0), Vector3(0.62, 0.4, 0.58), IRON, Vector3.ZERO, 16)
	for k in 10:
		var a = TAU * k / 10.0
		fb.add("box", Vector3(cos(a) * 0.31, -1.42, sin(a) * 0.295), Vector3(0.02, 0.36, 0.02), IRON.darkened(0.4), Vector3(0, -rad_to_deg(a), 0))
	fb.add("torus", Vector3(0, -1.66, 0.3), Vector3(0.11, 0.11, 0.11), IRON, Vector3(90, 0, 0), 8)
	fb.add("torus", Vector3(0, -1.8, 0.36), Vector3(0.11, 0.11, 0.11), IRON, Vector3(0, 0, 90), 8)
	_mi(el, fb)
	BeastModels._grain(rig, el, fp, fr, 12, 740 + int(s), GRAIN, 0.02)
	# el (bilek pivotu): geniş avuç, uzun kemikli parmaklar; -Y yönünde kurulur, pozda avuç yere yatar
	var wr = rig._pivot(el, Vector3(0, -1.65, 0), "bilek")
	var hb = MB.new()
	Loft.blob(hb, Vector3(0, -0.3, 0), Vector3(0, -1, 0), 0.62, [Vector2(0.2, 0.1), Vector2(0.3, 0.12), Vector2(0.3, 0.11)], SKIN, 10)
	for f in 5:
		var thumb = f == (0 if s > 0 else 4)
		var fx = lerpf(-0.24, 0.24, f / 4.0) * s
		var b0 = Vector3(fx, -0.58, 0.0)
		var d = Vector3(fx * 0.9, -1, 0.0).normalized()
		var L = 0.62
		if thumb:
			b0 = Vector3(-0.3 * s, -0.25, -0.05)
			d = Vector3(-0.8 * s, -0.6, -0.2).normalized()
			L = 0.45
		var p1 = b0 + d * L * 0.5
		var p2 = b0 + d * L + Vector3(0, 0, -0.08)
		Loft.tube(hb, [b0, p1, p2], [0.075, 0.06, 0.045], SKIN, 6, 2)
		hb.add("sphere", p1, Vector3(0.16, 0.12, 0.16), SKIN, Vector3.ZERO, 6)   # boğum
	_mi(wr, hb)
	arms.append({"sh": sh, "el": el, "wr": wr, "side": s})


func _build_leg(s: float) -> void:
	var hp = rig._pivot(hips, Vector3(s * 0.55, -0.15, 0), "kalca_b")
	var mb = MB.new()
	var tp = [Vector3(0, 0.15, 0), Vector3(s * 0.05, -1.1, -0.05), Vector3(0, -2.3, 0)]
	var tr = [Vector2(0.52, 0.5), Vector2(0.48, 0.45), Vector2(0.32, 0.32)]
	Loft.tube(mb, tp, tr, SKIN, 14, 3)
	_mi(hp, mb)
	BeastModels._grain(rig, hp, tp, tr, 18, 750 + int(s), GRAIN, 0.035)
	BeastModels._swirls(rig, hp, tp, tr, 2, 752 + int(s), GRAIN, 0.035, 1.5)
	var kn = rig._pivot(hp, Vector3(0, -2.3, 0), "diz")
	var sb = MB.new()
	var sp = [Vector3(0, 0.05, 0), Vector3(0, -1.1, 0.04), Vector3(0, -2.2, 0)]
	var sr = [Vector2(0.33, 0.33), Vector2(0.3, 0.28), Vector2(0.2, 0.19)]
	Loft.tube(sb, sp, sr, SKIN, 12, 3)
	sb.add("cyl", Vector3(0, -1.92, 0), Vector3(0.56, 0.36, 0.54), IRON, Vector3.ZERO, 16)
	for k in 8:
		var a = TAU * k / 8.0
		sb.add("box", Vector3(cos(a) * 0.28, -1.92, sin(a) * 0.275), Vector3(0.02, 0.32, 0.02), IRON.darkened(0.4), Vector3(0, -rad_to_deg(a), 0))
	# ayak: uzun parmaklı çıplak ayak
	Loft.blob(sb, Vector3(0, -2.32, -0.35), Vector3(0, -0.12, -1), 0.95, [Vector2(0.2, 0.14), Vector2(0.26, 0.14), Vector2(0.28, 0.1), Vector2(0.24, 0.07)], SKIN, 10)
	for f in 5:
		var fx = lerpf(-0.2, 0.2, f / 4.0)
		sb.add("sphere", Vector3(fx, -2.36, -0.86 + absf(fx) * 0.3), Vector3(0.1, 0.07, 0.16), SKIN, Vector3.ZERO, 6)
	_mi(kn, sb)
	BeastModels._grain(rig, kn, sp, sr, 14, 760 + int(s), GRAIN, 0.028)
	legs.append({"hip": hp, "kn": kn, "side": s})


# ------------------------------------------------------------------ pozlar
## Pozlar: pivot dönüşleri (radyan) + kalça yüksekliği (tasarım birimi)
func _pose(nm: String) -> Dictionary:
	match nm:
		"stand":
			return {"hy": 4.7, "tx": 0.0, "hx": 0.0, "ax": 0.0, "az": 0.12, "ex": 0.0, "wx": 0.0, "lx": 0.0, "lz": 0.05, "kx": 0.0}
		"rise":   # yerden çıkarken: dimdik, kollar yanlarda, baş hafif öne
			return {"hy": 4.7, "tx": -0.15, "hx": 0.2, "ax": 0.2, "az": 0.2, "ex": -0.3, "wx": 0.0, "lx": 0.0, "lz": 0.05, "kx": 0.0}
		_:   # crouch: Hanzō savaşındaki dört ayak üstü çömelme — gövde öne eğik, eller yerde, baş kalkık
			return {"hy": 1.7, "tx": -1.2, "hx": 1.35, "ax": 1.4, "az": 0.75, "ex": -0.3, "ez": 1.2, "wx": 1.6, "lx": 0.9, "lz": 0.42, "kx": -2.5}


func _apply(p: Dictionary) -> void:
	hips.position.y = p["hy"]
	torso.rotation.x = p["tx"]
	head.rotation.x = p["hx"] + head_pitch
	for a in arms:
		a["sh"].rotation = Vector3(p["ax"], 0, -a["side"] * -p["az"])
		a["el"].rotation = Vector3(p["ex"], 0, -a["side"] * float(p.get("ez", 0.0)))
		a["wr"].rotation.x = p["wx"]
	for l in legs:
		l["hip"].rotation = Vector3(p["lx"], 0, l["side"] * p["lz"])
		l["kn"].rotation.x = p["kx"]


func set_pose(nm: String, dur := 0.5) -> void:
	pose_from = pose_to.duplicate() if not pose_to.is_empty() else _pose(nm)
	if pose_k < 1.0 and not pose_from.is_empty():
		pose_from = _blend(pose_from, pose_to, pose_k)
	pose_to = _pose(nm)
	pose_dur = maxf(0.01, dur)
	pose_k = 0.0 if dur > 0.0 else 1.0
	if dur <= 0.0:
		_apply(pose_to)


func _blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var o = {}
	var s = k * k * (3.0 - 2.0 * k)
	for key in b:
		o[key] = lerpf(float(a.get(key, b[key])), float(b[key]), s)
	return o


func open_mouth(v: float) -> void:
	jaw_want = v


func _process(dt: float) -> void:
	t += dt
	if pose_k < 1.0:
		pose_k = minf(1.0, pose_k + dt / pose_dur)
	var p = _blend(pose_from, pose_to, pose_k) if pose_k < 1.0 else pose_to
	if p.is_empty():
		return
	_apply(p)
	# nefes: gövde ağır ağır şişer; baş hafif salınır
	torso.scale = Vector3.ONE * (1.0 + sin(t * 0.9) * 0.012)
	head.rotation.z = sin(t * 0.6) * 0.04
	jaw_open = lerpf(jaw_open, jaw_want, minf(1.0, dt * 6.0))
	jaw.rotation.x = -jaw_open * 0.75
	if shake > 0.0:
		shake = maxf(0.0, shake - dt)
		root.position = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * shake * 0.03 * rig.design_scale()
	else:
		root.position = Vector3.ZERO


## Ağız (dünya): hayalet ejderhalar ve zincirler buradan çıkar
func mouth_pos() -> Vector3:
	return jaw.global_position + jaw.global_transform.basis * Vector3(0, -0.2, -0.45)


## Göğüs (dünya): kara alıcılar (göbek bağı gibi) buradan çağırana uzanır
func chest_pos() -> Vector3:
	return torso.global_transform * Vector3(0, 1.4, -0.5)


func height_top() -> float:
	return H
