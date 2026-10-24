class_name BeastModels
extends RefCounted
## Dokuz kuyruklu canavarın prosedürel modelleri (BeastRig parçalarına bağlı, animasyonlu).
## Boylar anime ölçeğinde (metre, ayakta/çömelik tepe yüksekliği).

const INFO := {
	"shukaku": {"name": "Shukaku — Bir Kuyruk", "tails": 1, "height": 52.0, "element": "fuuton", "color": Color(0.82, 0.66, 0.42), "chakra": Color(0.85, 0.7, 0.45), "num": 1},
	"matatabi": {"name": "Matatabi — İki Kuyruk", "tails": 2, "height": 46.0, "element": "katon", "color": Color(0.12, 0.28, 0.85), "chakra": Color(0.3, 0.45, 1.0), "num": 2},
	"isobu": {"name": "Isobu — Üç Kuyruk", "tails": 3, "height": 42.0, "element": "suiton", "color": Color(0.45, 0.55, 0.5), "chakra": Color(0.35, 0.8, 0.75), "num": 3},
	"son_goku": {"name": "Son Gokū — Dört Kuyruk", "tails": 4, "height": 62.0, "element": "yoton", "color": Color(0.8, 0.18, 0.12), "chakra": Color(1.0, 0.35, 0.1), "num": 4},
	"kokuo": {"name": "Kokuō — Beş Kuyruk", "tails": 5, "height": 56.0, "element": "futton", "color": Color(0.94, 0.94, 0.92), "chakra": Color(0.95, 0.9, 0.8), "num": 5},
	"saiken": {"name": "Saiken — Altı Kuyruk", "tails": 6, "height": 50.0, "element": "suiton", "color": Color(0.85, 0.92, 1.0), "chakra": Color(0.75, 0.9, 1.0), "num": 6},
	"chomei": {"name": "Chōmei — Yedi Kuyruk", "tails": 7, "height": 48.0, "element": "fuuton", "color": Color(0.2, 0.45, 0.85), "chakra": Color(0.6, 1.0, 0.4), "num": 7},
	"gyuki": {"name": "Gyūki — Sekiz Kuyruk", "tails": 8, "height": 72.0, "element": "raiton", "color": Color(0.45, 0.3, 0.33), "chakra": Color(0.75, 0.35, 0.9), "num": 8},
	"kurama": {"name": "Kurama — Dokuz Kuyruk", "tails": 9, "height": 115.0, "element": "katon", "color": Color(0.95, 0.42, 0.12), "chakra": Color(1.0, 0.45, 0.1), "num": 9},
	"raiju": {"name": "Raijū", "tails": 3, "height": 8.0, "element": "raiton", "color": Color(0.3, 0.4, 0.6), "chakra": Color(0.45, 0.75, 1.0), "num": 0},
}


## yüzey: 0 kürk, 1 deri/pul, 2 kabuk/zırh, 3 sümük
const SURFACE := {"kurama": 0, "matatabi": 0, "son_goku": 0, "kokuo": 0, "shukaku": 1, "gyuki": 1, "isobu": 2, "chomei": 2, "saiken": 3, "raiju": 0}
const SHADOW := {"kurama": Color(0.45, 0.16, 0.2), "matatabi": Color(0.12, 0.1, 0.35), "son_goku": Color(0.35, 0.1, 0.22), "shukaku": Color(0.4, 0.3, 0.38),
	"isobu": Color(0.22, 0.28, 0.35), "kokuo": Color(0.62, 0.68, 0.78), "saiken": Color(0.52, 0.5, 0.58), "chomei": Color(0.32, 0.33, 0.42), "gyuki": Color(0.44, 0.33, 0.4)}
static var _bmats := {}
static func beast_material(surface: int, shadow: Color) -> ShaderMaterial:
	var k = "%d|%s" % [surface, shadow]
	if not _bmats.has(k):
		var m = ShaderMaterial.new()
		m.shader = load("res://shaders/beast.gdshader")
		m.set_shader_parameter("surface", surface)
		m.set_shader_parameter("shadow_tint", shadow)
		m.set_shader_parameter("stroke", 0.45 if surface == 0 else 0.35)
		_bmats[k] = m
	return _bmats[k]


## Tehditkar kas cikintisi: gozun ustune ice-asagi egik koyu kemer (ofkeli bakis)
static func _brow(mb: MB, eye_pos: Vector3, sx: float, w: float, col: Color) -> void:
	var a = eye_pos + Vector3(-sx * w * 0.55, w * 0.22, -w * 0.05)
	var b = eye_pos + Vector3(sx * w * 0.6, w * 0.62, w * 0.2)
	Loft.tube(mb, [a, a.lerp(b, 0.5) + Vector3(0, w * 0.12, -w * 0.12), b], [Vector2(w * 0.22, w * 0.14), Vector2(w * 0.26, w * 0.18), Vector2(w * 0.1, w * 0.08)], col, 10, 3)


static func build(id: String, height_m := -1.0) -> BeastRig:
	var r = BeastRig.new()
	r.id = id
	r.height_m = height_m if height_m > 0.0 else float(INFO.get(id, INFO["kurama"])["height"])
	var root = Node3D.new()
	root.name = "Design"
	r.add_child(root)
	match id:
		"shukaku": _shukaku(r, root)
		"matatabi": _matatabi(r, root)
		"isobu": _isobu(r, root)
		"son_goku": _son_goku(r, root)
		"kokuo": _kokuo(r, root)
		"saiken": _saiken(r, root)
		"chomei": _chomei(r, root)
		"gyuki": _gyuki(r, root)
		_: _kurama(r, root)
	root.scale = Vector3.ONE * r.design_scale()
	# sert cel gölgeli canavar malzemesi (peluş yumuşaklığı yerine): yüzey türü canavara göre
	var bm = beast_material(SURFACE.get(id, 0), SHADOW.get(id, Color(0.32, 0.26, 0.42)))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == null and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == Props.toon():
			mi.material_override = bm
	r.finalize_colliders()
	# hayran modeli varsa (assets/sketchfab) görünüm onunla değişir; prosedürel iskelet çarpışma/zayıf nokta/animasyon için kalır
	var sf = SFModels.build(id, r.height_m)
	if not sf.is_empty():
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			if not String(mi.get_parent().name).begins_with("weak"):
				mi.visible = false
		var node: Node3D = sf["node"]
		# iskeletsiz modeli kalçaya değil kök düğüme bağla: kalça animasyonu onu havaya kaldırmasın;
		# canlandırma (kuyruk, nefes, baş, adım, pençe) ve zemine oturtma SFBeastAnim'de
		r.add_child(node)
		node.transform = Transform3D.IDENTITY
		r.set_meta("sf_model", node)
		if sf.get("player") == null or (sf.get("anims", []) as Array).is_empty():
			var an = SFBeastAnim.new()
			an.name = "SFAnim"
			r.add_child(an)
			an.setup(r, node, sf["size"], SFModels.regions(id))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if mi.get_aabb().size.length() > 1.5 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return r


# ------------------------------------------------------------------ ortak parçalar
static func _arm(r: BeastRig, parent: Node3D, side: float, sh_pos: Vector3, elbow: Vector3, wrist: Vector3, r0: float, r1: float, r2: float, col: Color, hand_col: Color, claw_col: Color, fingers := 5, hand_size := 1.0, finger_len := 1.0, claw_len := 1.0) -> void:
	var sh = r._pivot(parent, sh_pos, "omuz")
	var mb = MB.new()
	BeastRig.limb(mb, Vector3.ZERO, elbow, r0, r1, col)
	r._mesh(sh, mb)
	var el = r._pivot(sh, elbow, "dirsek")
	var mb2 = MB.new()
	BeastRig.limb(mb2, Vector3.ZERO, wrist, r1, r2, col)
	mb2.add("sphere", wrist + Vector3(0, -0.15, -0.25) * hand_size, Vector3(1.1, 0.6, 1.3) * hand_size, hand_col, Vector3.ZERO, 10)
	for f in fingers:
		var a = lerpf(-0.6, 0.6, float(f) / max(1, fingers - 1))
		var base = wrist + Vector3(sin(a) * (0.45 + 0.3 * (finger_len - 1.0)) * hand_size, -0.25 * hand_size, (-0.7 * finger_len - cos(a) * 0.15) * hand_size)
		BeastRig.limb(mb2, wrist + Vector3(sin(a) * 0.3, -0.15, -0.4) * hand_size, base, 0.17 * hand_size, 0.13 * hand_size, hand_col, 6)
		BeastRig.claw(mb2, base, Vector3(sin(a) * 0.2, -0.75, -1.0), 1.0 * hand_size * claw_len, 0.13 * hand_size, claw_col)
	r._mesh(el, mb2)
	r.arms.append({"sh": sh, "el": el, "side": side})


static func _leg(r: BeastRig, parent: Node3D, side: float, hip_pos: Vector3, knee: Vector3, ankle: Vector3, r0: float, r1: float, r2: float, col: Color, foot_col: Color, claw_col: Color, front := false, hoof := false, foot_size := 1.0) -> void:
	var hp = r._pivot(parent, hip_pos, "kalca")
	var mb = MB.new()
	BeastRig.limb(mb, Vector3.ZERO, knee, r0, r1, col)
	r._mesh(hp, mb)
	var kn = r._pivot(hp, knee, "diz")
	var mb2 = MB.new()
	BeastRig.limb(mb2, Vector3.ZERO, ankle, r1, r2, col)
	if hoof:   # at bacağı ucu: bilek eklemi, ince bilek kemiği, bilek tüyü, alttan genişleyen bej toynak
		var pst = ankle + Vector3(0, -0.55, -0.2)
		mb2.add("sphere", ankle, Vector3.ONE * r2 * 2.3, col, Vector3.ZERO, 10)
		BeastRig.limb(mb2, ankle, pst, r2 * 0.95, r2 * 0.85, col, 10)
		for k in 5:
			var a = TAU * k / 5.0
			BeastRig.claw(mb2, ankle + Vector3(cos(a) * r2 * 0.8, -0.1, sin(a) * r2 * 0.8), Vector3(cos(a) * 0.4, -1, sin(a) * 0.4 + 0.3).normalized(), r2 * 1.6, r2 * 0.45, col)
		mb2.add("frustum", pst + Vector3(0, -0.32, -0.05), Vector3(r2 * 2.9, 0.65, r2 * 3.2), foot_col, Vector3.ZERO, 12)
		mb2.add("cyl", pst + Vector3(0, -0.62, -0.05), Vector3(r2 * 3.0, 0.08, r2 * 3.3), foot_col.darkened(0.35), Vector3.ZERO, 12)
	else:
		mb2.add("sphere", ankle + Vector3(0, -0.2, -0.45) * foot_size, Vector3(1.1, 0.55, 1.6) * foot_size, foot_col, Vector3.ZERO, 10)
		for f in 4:
			var a = lerpf(-0.5, 0.5, f / 3.0)
			BeastRig.claw(mb2, ankle + Vector3(sin(a) * 0.4, -0.3, -1.1) * foot_size, Vector3(sin(a) * 0.2, -0.55, -1.0), 0.9 * foot_size, 0.12 * foot_size, claw_col)
	r._mesh(kn, mb2)
	r.legs.append({"hip": hp, "kn": kn, "side": side, "front": front})


## Kuyruk yelpazesi: kökten yukarı-geriye açılı
static func _tail_fan(r: BeastRig, parent: Node3D, base: Vector3, count: int, spread: float, pitch: float, length: float, r0: float, rmid: float, col: Color, tip: Color, style: String, segs := 7) -> void:
	var b = r._pivot(parent, base, "kuyruk_koku")
	for i in count:
		var yaw = 0.0 if count == 1 else lerpf(-spread, spread, float(i) / (count - 1))
		var p = pitch + (absf(yaw) / maxf(1.0, spread)) * 12.0
		r._tail(b, yaw, p, segs, length, r0, rmid, col, tip, style)


static func _particles(parent: Node3D, box: Vector3, cols: Array, amount: int, size: float, vel: Vector3, life: float, add := false) -> void:
	var p = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = vel.normalized()
	pm.spread = 25.0
	pm.initial_velocity_min = vel.length() * 0.5
	pm.initial_velocity_max = vel.length()
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var g = Gradient.new()
	g.set_color(0, cols[0])
	g.set_color(1, cols[1])
	var gt = GradientTexture1D.new()
	gt.gradient = g
	pm.color_ramp = gt
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(size, size)
	var m = StandardMaterial3D.new()
	m.albedo_texture = FX.tex_smoke
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = m
	p.draw_pass_1 = q
	p.local_coords = false
	p.visibility_aabb = AABB(-box * 3.0 - Vector3.ONE * 4, box * 6.0 + Vector3.ONE * 8)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)


# ------------------------------------------------------------------ yardımcılar (pürüzsüz gövde + desen)
## Gövde tüpü + mesh
static func _tube(r: BeastRig, parent: Node3D, pts: Array, rad: Array, col, fn := Callable(), seg := 20, sub := 4) -> void:
	var mb = MB.new()
	Loft.tube(mb, pts, rad, col, seg, sub, true, true, fn)
	r._mesh(parent, mb)


## Sırt rengi -> karın rengi (alt yüzey açık), sırt boyunca koyu şerit
static func _belly(top: Color, belly: Color, stripe := Color(0, 0, 0, 0)) -> Callable:
	return func(_t: float, a: float, _d: Vector3) -> Color:
		var low = smoothstep(-0.15, -0.95, sin(a))
		var c = top.lerp(belly, low)
		if stripe.a > 0.0 and sin(a) > 0.82:
			c = c.lerp(stripe, 0.6)
		return c


## Badem göz: sklera + iris + bebek (yassı, yüzeye yapışık)
static func _anime_eye(r: BeastRig, parent: Node3D, pos: Vector3, size: Vector3, sclera: Color, iris: Color, pupil: Color, rot := Vector3.ZERO, pupil_kind := "slit") -> void:
	var mb = MB.new()
	mb.add("sphere", pos, size, sclera, rot, 14)
	var fwd = Basis.from_euler(rot * PI / 180.0) * Vector3(0, 0, -1)
	mb.add("sphere", pos + fwd * size.z * 0.32, size * Vector3(0.62, 0.86, 0.55), iris, rot, 12)
	match pupil_kind:
		"slit":
			mb.add("sphere", pos + fwd * size.z * 0.48, size * Vector3(0.12, 0.8, 0.3), pupil, rot, 8)
		"star":  # Shukaku: dört köşeli yıldız + çevresinde dört nokta
			for k in 4:
				var ang = k * 90.0
				mb.add("sphere", pos + fwd * size.z * 0.48, size * Vector3(0.13, 0.62, 0.25), pupil, rot + Vector3(0, 0, ang), 6)
				var o = Vector3(cos(deg_to_rad(ang + 45.0)), sin(deg_to_rad(ang + 45.0)), 0) * size.x * 0.32
				mb.add("sphere", pos + Basis.from_euler(rot * PI / 180.0) * o + fwd * size.z * 0.45, size * 0.1, pupil, rot, 6)
		"dot":
			mb.add("sphere", pos + fwd * size.z * 0.48, size * Vector3(0.28, 0.32, 0.25), pupil, rot, 8)
		"none":
			pass
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	parent.add_child(mi)


## Gövde tüpü boyunca uzanan ince, hafif dalgalı kas/ağaç damarı çizgileri (Gyūki)
static func _grain(r: BeastRig, parent: Node3D, spine: Array, rad: Array, n: int, seed_v: int, col: Color, w: float) -> void:
	var mb = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	for v in n:
		var a = rng.randf_range(-PI, PI)
		var t0 = rng.randf_range(0.05, 0.7)
		var t1 = minf(0.97, t0 + rng.randf_range(0.15, 0.4))
		var pts: Array = []
		var rr: Array = []
		for k in 8:
			var u = k / 7.0
			var d = _tube_pt(spine, rad, lerpf(t0, t1, u), a + sin(u * PI * 1.5 + v) * 0.08, 0.0)
			pts.append((d[0] as Vector3) + (d[1] as Vector3) * 0.02)
			rr.append(w * sin(maxf(0.15, u) * PI) + 0.005)
		Loft.tube(mb, pts, rr, col, 5, 2, true, true)
	r._mesh(parent, mb)


## Gövde tüpünün yüzeyinde nokta + normal (Loft ile aynı Catmull-Rom); t: 0..1 omurga boyunca, a: kesit açısı (90° = üst)
static func _tube_pt(spine: Array, rad: Array, t: float, a: float, lift := 0.0) -> Array:
	var x = clampf(t, 0.0, 0.999) * (spine.size() - 1)
	var k = int(x)
	var f = x - k
	var nn = spine.size()
	var s0: Vector3 = Loft._cr(spine[maxi(0, k - 1)], spine[k], spine[k + 1], spine[mini(nn - 1, k + 2)], f)
	var r0: Vector2 = Loft._cr(rad[maxi(0, k - 1)], rad[k], rad[k + 1], rad[mini(nn - 1, k + 2)], f)
	var tg: Vector3 = ((spine[k + 1] as Vector3) - (spine[k] as Vector3)).normalized()
	var ax = Vector3.RIGHT
	var nz = ax.cross(tg).normalized()
	var n = (ax * cos(a) / r0.x + nz * sin(a) / r0.y).normalized()
	return [s0 + ax * cos(a) * r0.x + nz * sin(a) * r0.y + n * lift, n]


## Gövde tüpünün yüzeyine yapışık, kıvrılarak biten ince damar çizgileri (Shukaku lanet mührü vb.); köşe rengiyle çizilemeyecek kadar ince desenler için gerçek geometri
static func _veins(r: BeastRig, parent: Node3D, spine: Array, rad: Array, n: int, seed_v: int, col: Color, w: float, lift := 1.0) -> void:
	var mb = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	var at = func(t: float, a: float) -> Vector3:
		var x = clampf(t, 0.0, 0.999) * (spine.size() - 1)
		var k = int(x)
		var f = x - k
		var nn = spine.size()
		var s0: Vector3 = Loft._cr(spine[maxi(0, k - 1)], spine[k], spine[k + 1], spine[mini(nn - 1, k + 2)], f)   # gövdeyle aynı Catmull-Rom eğrisi
		var r0: Vector2 = Loft._cr(rad[maxi(0, k - 1)], rad[k], rad[k + 1], rad[mini(nn - 1, k + 2)], f)
		var tg: Vector3 = ((spine[k + 1] as Vector3) - (spine[k] as Vector3)).normalized()
		var ax = Vector3.RIGHT
		var nz = ax.cross(tg).normalized()
		return s0 + ax * cos(a) * r0.x * lift + nz * sin(a) * r0.y * lift
	for v in n:
		var t = rng.randf_range(0.08, 0.92)
		var a = rng.randf_range(-PI, PI)
		var th = rng.randf_range(0.0, TAU)   # damarın akış yönü (dikey/çapraz/yatay karışık)
		var curl = rng.randf_range(0.5, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
		var pts: Array = []
		var rr: Array = []
		var steps = rng.randi_range(12, 22)
		for k in steps:
			pts.append(at.call(t, a))
			var u = float(k) / (steps - 1)
			rr.append(w * (0.35 + 0.65 * sin(minf(1.0, u * 1.3) * PI * 0.5)) * (1.0 - u * 0.55))
			# kıvrım: uca doğru dönüş hızlanır (alev / sarmal uç)
			# kıvrım: yön hafifçe dalgalanır, uca doğru sarmal gibi döner (alev / kanca uç)
			var dir = th + sin(k * 0.9 + v) * 0.5 + curl * 5.0 * u * u * u
			t += cos(dir) * 0.028
			a += sin(dir) * 0.11
		Loft.tube(mb, pts, rr, col, 6, 3, true, true)
		if rng.randf() < 0.5:   # damla biçimli "göz" kıvrımı
			var e = at.call(t, a)
			mb.add("sphere", e, Vector3.ONE * w * 1.6, col, Vector3.ZERO, 8)
	r._mesh(parent, mb)


## Cel tüy öbeği: uçları sivri birkaç pençe-tüp
static func _tuft(mb: MB, at: Vector3, dir: Vector3, n: int, ln: float, rad: float, col: Color, spread := 0.5) -> void:
	var d = dir.normalized()
	var side = d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	for i in n:
		var k = (float(i) / maxf(1.0, n - 1.0) - 0.5) * 2.0
		BeastRig.claw(mb, at + side * k * rad * 1.4, (d + side * k * spread).normalized(), ln * (1.0 - absf(k) * 0.25), rad, col)


# ------------------------------------------------------------------ 9 Kuyruk: Kurama (çömelik tilki, insansı kollar)
static func _kurama(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): altın-turuncu, YALIN ve örümcek gibi uzun uzuvlu; yere çömelmiş, dirsekler yana açık,
	# uzun parmaklı eller yerde; dar, aşağı bakan sivri tilki yüzü, yüzü boydan boya yaran dişli sırıtış;
	# kafadan uzun, tabanı geniş, içi koyu lacivert kulaklar; gözden kulağa uzanan siyah çizgi; çok uzun, kalın, pürüzsüz kuyruklar
	r.quadruped = true
	r.upright = false
	var c = Color(0.86, 0.48, 0.13)
	var sh = Color(0.58, 0.27, 0.07)        # cel gölge turuncusu (kahveye yakın)
	var belly = Color(0.94, 0.62, 0.26)
	var dark = Color(0.05, 0.04, 0.08)
	var ear_in = Color(0.12, 0.14, 0.32)
	var cl = Color(0.98, 0.95, 0.88)
	var fur = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.15 else sh
	# kalça (arkada, yüksek) -> ince bel -> geniş göğüs/omuz (önde, alçak)
	r.hips = r._pivot(root, Vector3(0, 4.6, 2.6), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, 0.4, 1.6), Vector3(0, 0.3, 0.2), Vector3(0, 0.0, -2.0), Vector3(0, -0.2, -4.0), Vector3(0, -0.4, -5.4)],
		[Vector2(2.0, 1.9), Vector2(2.2, 2.1), Vector2(1.6, 1.6), Vector2(1.6, 1.6), Vector2(2.0, 1.9)], c, fur)
	r._collider(r.hips, Vector3(0, 0, -1.8), Vector3(3.2, 2.8, 7.2))
	r.chest = r._pivot(r.hips, Vector3(0, -0.5, -5.4), "gogus")
	_tube(r, r.chest, [Vector3(0, 0.1, 1.0), Vector3(0, 0.4, -0.4), Vector3(0, 0.3, -1.7), Vector3(0, -0.3, -2.7)],
		[Vector2(2.0, 1.9), Vector2(3.0, 2.5), Vector2(2.7, 2.3), Vector2(1.5, 1.4)], c, fur)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:   # omuz kemiği çıkıntısı (yalın, kaslı)
		mc.add("sphere", Vector3(2.2 * sx, 0.9, -1.3), Vector3(2.0, 1.5, 2.1), c, Vector3(0, 0, -20 * sx), 12)
		for k in 2:   # omuzda birkaç sivri tüy
			BeastRig.claw(mc, Vector3(2.4 * sx, 1.2 - k * 0.5, -0.7 + k * 0.4), Vector3(sx, 0.4, 0.6), 1.2, 0.3, c)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0, -1.2), Vector3(4.2, 3.0, 3.6))
	# uzun, kaslı boyun: göğüsten öne-yukarı uzanır
	_tube(r, r.chest, [Vector3(0, 0.3, -2.0), Vector3(0, 0.1, -3.3), Vector3(0, -0.3, -4.6)], [Vector2(1.3, 1.25), Vector2(1.0, 1.05), Vector2(0.95, 1.0)], c, fur)
	# boyun öne ve aşağı uzanır; baş göğsün önünde, alçakta, yere doğru bakar
	r.head = r._pivot(r.chest, Vector3(0, -0.4, -5.0), "bas")
	r.head.rotation.x = deg_to_rad(-22.0)   # aşağı, avına tepeden bakar
	var hb = MB.new()
	# kafatası: önden V — kulaklar arası geniş alın, aşağı/öne doğru daralan UZUN sivri burun
	var ksp = [Vector3(0, 0.55, 1.2), Vector3(0, 0.6, 0.2), Vector3(0, 0.3, -0.55), Vector3(0, 0.05, -1.45), Vector3(0, -0.15, -2.35)]
	var krd = [Vector2(1.6, 1.3), Vector2(1.8, 1.35), Vector2(1.0, 0.85), Vector2(0.7, 0.58), Vector2(0.36, 0.3)]
	Loft.tube(hb, ksp, krd, c, 20, 5, true, true,
		func(_t: float, _a: float, d: Vector3) -> Color:
			return c if d.y > -0.35 else belly)
	# burun sırtı: alından burun ucuna yassı, keskin kenarlı sırt (huni gibi yuvarlak değil)
	Loft.tube(hb, [Vector3(0, 1.0, -0.3), Vector3(0, 0.6, -1.4), Vector3(0, 0.15, -2.3)], [Vector2(0.4, 0.1), Vector2(0.3, 0.08), Vector2(0.14, 0.05)], c, 8, 3)
	# geniş, kemikli yanak elmacıkları + aşağı-geriye savrulan yanak yelesi (yüzü elmas/V yapar)
	for sx in [-1.0, 1.0]:
		hb.add_xf("sphere", Transform3D(Basis(Vector3.UP, deg_to_rad(-25 * sx)) * Basis.from_scale(Vector3(0.9, 0.75, 1.3)), Vector3(1.45 * sx, 0.05, -0.55)), c, 12)
		for k in 6:
			var cy = 0.35 - k * 0.2
			BeastRig.claw(hb, Vector3((1.75 + 0.05 * k) * sx, cy, -0.4 + k * 0.12), Vector3(sx * 0.9, -0.45 - k * 0.08, 0.35).normalized(), 1.7 - k * 0.12, 0.32, c if k % 2 == 0 else sh)
	var nose = _tube_pt(ksp, krd, 0.99, deg_to_rad(80.0), 0.0)
	hb.add_xf("cone", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-100)) * Basis.from_scale(Vector3(0.32, 0.22, 0.16)), nose[0] + Vector3(0, 0.04, -0.06)), dark, 10)   # küçük üçgen tilki burnu
	for k in 4:   # alında çatık kırışıklar (V biçimli)
		for sx in [-1.0, 1.0]:
			var w = _tube_pt(ksp, krd, 0.3 + k * 0.05, deg_to_rad(90.0 - (8.0 + k * 4.0) * sx), 0.02)
			hb.add_xf("box", Transform3D(Basis.looking_at(w[1], Vector3(0, 0, -1)) * Basis(Vector3.BACK, deg_to_rad(28 * sx)) * Basis.from_scale(Vector3(0.45, 0.035, 0.05)), w[0]), sh, 1)
	# SIRITIŞ: yanaktan burun ucuna uzanan koyu çizgi (tüpün alt-yan yüzeyinde), üst ve alt sık sivri dişler, önde köpek dişleri
	for sx in [-1.0, 1.0]:
		var gl: Array = []
		var gr: Array = []
		for k in 9:
			var u = k / 8.0
			var gp = _tube_pt(ksp, krd, lerpf(0.3, 0.97, u), deg_to_rad(-90.0 + (lerpf(90.0, 72.0, u)) * sx) + (PI if sx < 0 else 0.0) * 0.0, 0.0)
			gl.append(gp[0])
			gr.append(Vector2(0.08, lerpf(0.3, 0.16, u)))
		Loft.tube(hb, gl, gr, dark, 8, 2)
		for k in 16:
			var u = (k + 0.5) / 16.0
			var gp = _tube_pt(ksp, krd, lerpf(0.32, 0.95, u), deg_to_rad(-90.0 + lerpf(90.0, 72.0, u) * sx), 0.0)
			var n: Vector3 = gp[1]
			var big = k == 12
			var tl = (0.26 if not big else 0.56) * lerpf(1.1, 0.85, u)
			BeastRig.claw(hb, (gp[0] as Vector3) + Vector3(0, 0.2, 0) + n * 0.03, (Vector3(0, -1, 0) + n * 0.25).normalized(), tl, 0.065 if not big else 0.1, cl)
			if k < 15:
				var lp = _tube_pt(ksp, krd, lerpf(0.33, 0.95, u + 0.03), deg_to_rad(-90.0 + lerpf(90.0, 72.0, u + 0.03) * sx), 0.0)
				BeastRig.claw(hb, (lp[0] as Vector3) - Vector3(0, 0.2, 0) + (lp[1] as Vector3) * 0.03, (Vector3(0, 1, 0) + (lp[1] as Vector3) * 0.25).normalized(), tl * 0.8, 0.06, cl)
	# AĞIZ UCU: iki yandaki sırıtış çizgisi burnun altında birleşir + ön kesici dişler ve köpek dişleri
	var gL = _tube_pt(ksp, krd, 0.97, deg_to_rad(-90.0 - 72.0), 0.0)
	var gR = _tube_pt(ksp, krd, 0.97, deg_to_rad(-90.0 + 72.0), 0.0)
	var tip = _tube_pt(ksp, krd, 0.995, deg_to_rad(-90.0), 0.0)
	var gfront: Vector3 = (tip[0] as Vector3) + Vector3(0, 0.05, -0.12)
	Loft.tube(hb, [gL[0], gfront, gR[0]], [Vector2(0.08, 0.16), Vector2(0.08, 0.14), Vector2(0.08, 0.16)], dark, 8, 3)
	for k in 5:
		var u = (k - 2.0) / 2.0
		var ip = gfront.lerp(gR[0] if u > 0 else gL[0], absf(u) * 0.85)
		BeastRig.claw(hb, ip + Vector3(0, 0.16, -0.04), Vector3(0, -1, -0.15).normalized(), 0.22 if absf(u) < 0.9 else 0.42, 0.05 if absf(u) < 0.9 else 0.07, cl)
		BeastRig.claw(hb, ip + Vector3(0, -0.16, -0.02), Vector3(0, 1, -0.15).normalized(), 0.18 if absf(u) < 0.9 else 0.34, 0.045, cl)
	for sx in [-1.0, 1.0]:
		# çok uzun kulaklar: tabanı geniş yaprak, yukarı-dışa-geriye, içi koyu lacivert
		var e0 = Vector3(0.85 * sx, 1.05, 0.55)
		var ed = Vector3(3.0 * sx, 7.4, 1.8)
		var eax = ed.normalized()
		var ebn = Vector3(0, 0, -1).cross(eax).normalized() * sx
		Loft.tube(hb, [e0, e0 + ed * 0.3 + ebn * 0.15, e0 + ed * 0.65 + ebn * 0.1, e0 + ed], [Vector2(0.72, 0.17), Vector2(0.66, 0.15), Vector2(0.38, 0.11), Vector2(0.03, 0.03)], c, 14, 3, true, false, Callable(), Vector3(0, 0, -1))
		var efr = Vector3(0, 0, -0.27)
		Loft.tube(hb, [e0 + ed * 0.04 - ebn * 0.22 + efr * 0.65, e0 + ed * 0.35 - ebn * 0.2 + efr * 0.6, e0 + ed * 0.7 - ebn * 0.08 + efr * 0.5, e0 + ed * 0.93 + efr * 0.4],
			[Vector2(0.3, 0.05), Vector2(0.3, 0.05), Vector2(0.16, 0.04), Vector2(0.02, 0.02)], ear_in, 8, 3, true, true, Callable(), Vector3(0, 0, -1))
		# ÇEKİK KIRMIZI GÖZ: kafa yüzeyinde; koyu çerçeve kulağın lacivert içine doğru uzar
		# AVCI BAKIŞI: göz yüzeyi öne (avına) bakar — kafa aşağı eğik olduğu için hafif yukarı telafi; bebekler buruna doğru kayık
		var eg = _tube_pt(ksp, krd, 0.36, deg_to_rad(90.0 - 62.0 * sx), 0.0)
		var nrm: Vector3 = Vector3(0.42 * sx, 0.3, -1.0).normalized()
		var ep: Vector3 = (eg[0] as Vector3) + nrm * 0.1
		var eb = Basis.looking_at(-nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-24 * sx))
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.95, 0.3, 0.2)), ep), dark, 12)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.74, 0.19, 0.26)), ep + nrm * 0.02), Color(0.7, 0.05, 0.04), 12)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.42, 0.18, 0.3)), ep + nrm * 0.03 - eb.x * 0.14 * sx - eb.y * 0.02), Color(1.0, 0.2, 0.12), 10)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.055, 0.18, 0.34)), ep + nrm * 0.035 - eb.x * 0.14 * sx - eb.y * 0.02), dark, 6)
		hb.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.07, 0.05, 0.36)), ep + nrm * 0.04 - eb.x * 0.2 * sx + eb.y * 0.04), Color(1, 0.95, 0.9), 6)   # parıltı
		# göz çerçevesinden kulağa uzanan koyu şerit
		Loft.tube(hb, [ep - eb.x * 0.35 * sx, ep + Vector3(0.25 * sx, 0.35, 0.45), e0 + Vector3(0.0, 0.25, -0.3)], [Vector2(0.09, 0.05), Vector2(0.1, 0.05), Vector2(0.14, 0.05)], dark, 6, 3)
		# çatık kaş kemiği
		hb.add_xf("sphere", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(8 * sx)) * Basis.from_scale(Vector3(1.15, 0.22, 0.42)), ep + eb.y * 0.15 + nrm * 0.08), sh, 10)
		hb.add_xf("box", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(8 * sx)) * Basis.from_scale(Vector3(1.0, 0.05, 0.2)), ep + eb.y * 0.08 + nrm * 0.12), dark, 1)   # üst göz kapağı çizgisi
		# yanaklarda yana-geriye savrulan sivri tüy tutamları
		for k in 5:
			var cp = _tube_pt(ksp, krd, 0.18 + k * 0.06, deg_to_rad(-15.0 * sx + (180.0 if sx < 0 else 0.0)), -0.05)
			BeastRig.claw(hb, cp[0], ((cp[1] as Vector3) + Vector3(0, -0.35, 0.6)).normalized(), 1.5 - k * 0.15, 0.3, c if k % 2 == 0 else sh)
	r._mesh(r.head, hb)
	r._collider(r.head, Vector3(0, 0, -0.6), Vector3(2.8, 2.2, 3.4))
	r.jaw = r._pivot(r.head, Vector3(0, -0.55, -0.6), "cene")
	var jb = MB.new()
	Loft.tube(jb, [Vector3(0, -0.05, 0.3), Vector3(0, -0.1, -0.85), Vector3(0, 0.02, -1.7)], [Vector2(0.95, 0.3), Vector2(0.62, 0.24), Vector2(0.3, 0.18)], belly, 14, 3)
	r._mesh(r.jaw, jb)
	r.mouth = r._pivot(r.head, Vector3(0, -0.4, -2.3), "agiz")
	# uzun, örümcek gibi açılmış ön kollar: dirsekler yana-yukarı, uzun parmaklı eller yerde
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.1 * sx, 0.6, -1.4), Vector3(3.4 * sx, 0.6, -1.2), Vector3(0.8 * sx, -4.9, -1.4), 0.85, 0.68, 0.5, c, c, cl, 5, 1.5, 1.9, 0.45)
		# arka bacaklar: çömelik, dizler öne-yana, ayak bilekleri geride (parmak ucunda)
		_leg(r, r.hips, sx, Vector3(1.5 * sx, 0.0, 0.4), Vector3(2.8 * sx, -0.9, -1.6), Vector3(0.6 * sx, -3.5, 1.4), 1.05, 0.75, 0.5, c, c, cl, false, false, 1.45)
	# çok uzun, kalın, pürüzsüz kuyruklar: yelpaze gibi geniş açılır
	# kuyruklar: gövde kadar kalın, çok uzun; vücudun iki yanına yelpaze gibi yayılıp yukarı kalkar, uçta aşağı kıvrılır
	r.tail_curl = 0.11
	_tail_fan(r, r.hips, Vector3(0, 0.9, 1.6), 9, 88.0, -62.0, 28.0, 1.7, 2.3, c, Color(0.95, 0.64, 0.3), "sleek", 12)
	r._weak(r.head, Vector3(0, 1.4, -0.3))
	r._weak(r.chest, Vector3(0, 1.8, 0.4))
	r._weak(r.hips, Vector3(0, 1.4, 1.4))


# ------------------------------------------------------------------ 1 Kuyruk: Shukaku (dik duran göbekli rakun, lanetli mühür desenleri)
static func _shukaku(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): gri-bej sıkıştırılmış kum; tüm vücutta lacivert, alev gibi kıvrılan lanet damarları ve damla biçimli "göz" kıvrımları;
	# devasa yuvarlak göbekli tombul gövde, gövdeye gömülü küçük yuvarlak baş, sivri üçgen kulaklar (içi lacivert);
	# gözlerin çevresinde siyah maske bandı, sarı gözler, dört köşeli yıldız bebek; küçük siyah burun; yüzün altında zikzak dişli ağız;
	# kalın, pul pul plakalı tek kuyruk
	var c = Color(0.74, 0.66, 0.53); var sh = Color(0.6, 0.52, 0.42); var mk = Color(0.14, 0.18, 0.46); var dark = Color(0.04, 0.04, 0.06)
	# lanetli mühür: alev gibi kıvrılan ince lacivert damarlar + damla kıvrımları (yüksek çözünürlüklü tüplerde)
	var curse = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.4 else sh
	r.hips = r._pivot(root, Vector3(0, 3.2, 0), "kalca_kok")
	# devasa yuvarlak göbek: alt ve öne doğru şişkin
	_tube(r, r.hips, [Vector3(0, -2.9, 0.2), Vector3(0, -1.6, -0.5), Vector3(0, 0.2, -0.7), Vector3(0, 1.9, -0.3), Vector3(0, 3.2, 0.0)],
		[Vector2(3.0, 2.8), Vector2(3.9, 3.7), Vector2(4.1, 3.9), Vector2(3.5, 3.2), Vector2(2.6, 2.3)], c, curse, 40, 10)
	_veins(r, r.hips, [Vector3(0, -2.9, 0.2), Vector3(0, -1.6, -0.5), Vector3(0, 0.2, -0.7), Vector3(0, 1.9, -0.3), Vector3(0, 3.2, 0.0)],
		[Vector2(3.0, 2.8), Vector2(3.9, 3.7), Vector2(4.1, 3.9), Vector2(3.5, 3.2), Vector2(2.6, 2.3)], 120, 11, mk, 0.08)
	r._collider(r.hips, Vector3(0, 0.2, -0.3), Vector3(7.6, 6.4, 7.0))
	r.chest = r._pivot(r.hips, Vector3(0, 3.0, -0.1), "gogus")
	_tube(r, r.chest, [Vector3(0, -0.6, 0.1), Vector3(0, 0.5, -0.1), Vector3(0, 1.3, -0.1)], [Vector2(2.9, 2.6), Vector2(2.6, 2.3), Vector2(2.0, 1.8)], c, curse, 36, 8)
	_veins(r, r.chest, [Vector3(0, -0.6, 0.1), Vector3(0, 0.5, -0.1), Vector3(0, 1.3, -0.1)], [Vector2(2.9, 2.6), Vector2(2.6, 2.3), Vector2(2.0, 1.8)], 55, 23, mk, 0.08)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:   # yuvarlak, kambur omuzlar
		mc.add("sphere", Vector3(2.4 * sx, 0.5, 0.0), Vector3(2.0, 1.8, 2.0), c, Vector3.ZERO, 14)
	r._mesh(r.chest, mc)
	# baş: gövdeye gömülü (boyunsuz), yuvarlak ve kısa burunlu
	r.head = r._pivot(r.chest, Vector3(0, 1.9, -0.6), "bas")
	_tube(r, r.head, [Vector3(0, 0.1, 1.2), Vector3(0, 0.3, 0.2), Vector3(0, -0.05, -0.9), Vector3(0, -0.1, -1.45)],
		[Vector2(1.9, 1.7), Vector2(2.15, 1.95), Vector2(1.95, 1.75), Vector2(1.45, 1.2)], c, curse, 36, 8)
	_veins(r, r.head, [Vector3(0, 0.1, 1.2), Vector3(0, 0.3, 0.2), Vector3(0, -0.05, -0.9)], [Vector2(1.9, 1.7), Vector2(2.15, 1.95), Vector2(1.95, 1.75)], 22, 37, mk, 0.07)
	# yüz = tüpün ön kubbesi (elipsoid): yüz parçaları bu yüzeye oturtulur (içine gömülmez)
	var dc = Vector3(0, -0.1, -1.45); var dr = Vector3(1.45, 1.2, 0.94)
	var dome = func(a: float, e: float, lift := 0.0) -> Array:
		var p = Vector3(dr.x * cos(e) * sin(a), dr.y * sin(e), -dr.z * cos(e) * cos(a))
		var n = Vector3(p.x / (dr.x * dr.x), p.y / (dr.y * dr.y), p.z / (dr.z * dr.z)).normalized()
		return [dc + p + n * lift, n]
	var mh = MB.new()
	# siyah göz maskesi: kubbeyi saran, dış uçları yukarı kalkan bant (üst üste yassı diskler)
	for i in 13:
		var a = lerpf(-1.25, 1.25, i / 12.0)
		var d = dome.call(a, 0.28 + 0.2 * absf(a), 0.02)
		mh.add_xf("sphere", Transform3D(Basis.looking_at(d[1], Vector3.UP) * Basis.from_scale(Vector3(0.6, 0.78 - 0.22 * absf(a), 0.12)), d[0]), dark, 10)
	var nd = dome.call(0.0, -0.12, 0.05)
	mh.add_xf("sphere", Transform3D(Basis.looking_at(nd[1], Vector3.UP) * Basis.from_scale(Vector3(0.5, 0.34, 0.3)), nd[0]), dark, 10)   # küçük siyah burun
	for k in 3:   # alında lanet kıvrımları
		mh.add("box", Vector3((k - 1) * 0.5, 1.5 - absf(k - 1) * 0.15, -0.8), Vector3(0.1, 0.5, 0.1), mk, Vector3(-30, 0, (k - 1) * -25))
	for sx in [-1.0, 1.0]:
		# sivri üçgen kulaklar, içi lacivert
		var e0 = Vector3(1.3 * sx, 1.5, 0.3)
		Loft.tube(mh, [e0, e0 + Vector3(0.35 * sx, 0.9, 0.0), e0 + Vector3(0.75 * sx, 1.9, 0.15)], [Vector2(0.85, 0.32), Vector2(0.6, 0.25), Vector2(0.04, 0.04)], c, 12, 3)
		mh.add_xf("sphere", Transform3D(Basis(Vector3.BACK, deg_to_rad(-20 * sx)) * Basis.from_scale(Vector3(0.75, 1.5, 0.1)), e0 + Vector3(0.35 * sx, 0.75, -0.24)), mk, 10)
		# maskenin dış uçları sivri kanat gibi yukarı-dışa uzanır
		var wt = dome.call(1.3 * sx, 0.55, 0.0)
		BeastRig.claw(mh, wt[0], (wt[1] + Vector3(0, 0.8, 0)).normalized(), 0.7, 0.25, dark)
		# sarı göz, dört köşeli yıldız bebek: maskenin üstünde, yüzey normaline bakar
		var ed = dome.call(0.5 * sx, 0.33, 0.06)
		var eb = Basis.looking_at(ed[1], Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-16 * sx))
		_anime_eye(r, r.head, ed[0], Vector3(0.66, 0.34, 0.16), Color(0.02, 0.02, 0.04), Color(1.0, 0.85, 0.15), Color(0.02, 0.02, 0.02), eb.get_euler() * 180.0 / PI, "star")
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(4.0, 3.4, 3.4))
	# ağız: kubbenin altında boydan boya koyu yarık, üst ve alt kenarda açık kum rengi zikzak dişler
	var jp = Vector3(0, -0.75, -1.3)
	r.jaw = r._pivot(r.head, jp, "cene")
	var mj = MB.new()
	var gl: Array = []
	for i in 9:
		var a = lerpf(-1.15, 1.15, i / 8.0)
		gl.append((dome.call(a, -0.36 + 0.2 * absf(a), 0.0)[0] as Vector3) - jp)
	Loft.tube(mj, gl, [Vector2(0.08, 0.1), Vector2(0.12, 0.14), Vector2(0.14, 0.17), Vector2(0.14, 0.18), Vector2(0.14, 0.18), Vector2(0.14, 0.18), Vector2(0.14, 0.17), Vector2(0.12, 0.14), Vector2(0.08, 0.1)], dark, 10, 3)
	for i in 15:
		var a = lerpf(-1.1, 1.1, i / 14.0)
		var e = -0.36 + 0.2 * absf(a)
		var up_d = dome.call(a, e + 0.08, 0.05)
		var lo_d = dome.call(a + 0.07, e - 0.09, 0.05)
		var big = i % 2 == 0
		BeastRig.claw(mj, (up_d[0] as Vector3) - jp, (Vector3(0, -1, 0) + up_d[1] * 0.25).normalized(), 0.3 if big else 0.2, 0.085, Color(0.92, 0.87, 0.74))   # üst zikzak
		BeastRig.claw(mj, (lo_d[0] as Vector3) - jp, (Vector3(0, 1, 0) + lo_d[1] * 0.25).normalized(), 0.24 if not big else 0.16, 0.08, Color(0.92, 0.87, 0.74))   # alt zikzak
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -2.1), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.9 * sx, 0.4, 0), Vector3(1.0 * sx, -2.2, -0.9), Vector3(0.4 * sx, -1.9, -1.0), 1.25, 1.0, 0.8, c, c, Color(0.9, 0.85, 0.72), 4, 1.25)
		_leg(r, r.hips, sx, Vector3(2.0 * sx, -2.2, 0.2), Vector3(0.4 * sx, -1.0, -0.4), Vector3(0, -0.7, -0.1), 1.5, 1.25, 1.0, c, c, Color(0.9, 0.85, 0.72), false, false, 1.4)
	# kalın, pul pul plakalı kuyruk: yere değip yana kıvrılır
	_tail_fan(r, r.hips, Vector3(0, -1.6, 3.2), 1, 0.0, -14.0, 15.0, 1.7, 2.6, c, c.lightened(0.08), "sand", 9)
	_particles(r.hips, Vector3(3.5, 4.0, 3.0), [Color(0.78, 0.7, 0.56, 0.8), Color(0.78, 0.7, 0.56, 0.0)], 60, 1.2, Vector3(0, -3, 0), 2.0)
	r._weak(r.head, Vector3(0, 2.0, -0.2))
	r._weak(r.hips, Vector3(0, 0.6, -4.0))
	r._weak(r.hips, Vector3(0, -0.6, 3.6))


# ------------------------------------------------------------------ 2 Kuyruk: Matatabi (kobalt mavi ve siyah alevden kedi)
static func _matatabi(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): mavi alevden YALIN, kaslı, yere sinmiş saldırgan kedi; omuzlar yüksek, baş alçakta öne uzanmış,
	# ön bacaklar geniş açık, büyük pençeler; ağız ardına kadar açık: pembe ağız içi, iki sıra sivri diş, köpek dişleri;
	# çekik, kızgın gözler (biri sarı biri yeşil), çatık kaş; vücutta kıvrılan siyah alev desenleri, sırtta yukarı savrulan alev dilleri
	r.quadruped = true
	r.upright = false
	var c = Color(0.22, 0.45, 0.95); var hi = Color(0.55, 0.78, 1.0); var dk = Color(0.02, 0.02, 0.06)
	var cl = Color(0.97, 0.97, 1.0); var pink = Color(0.92, 0.45, 0.5); var gum = Color(0.55, 0.12, 0.2)
	# bulut gibi dalgalanan mavi alev tonu (açık-koyu lekeler animedeki gibi yumuşak)
	var flame = func(t: float, a: float, d: Vector3) -> Color:
		var m = sin(t * 11.0 + a * 2.3) * sin(a * 3.1 - t * 5.0)
		var col = c.lerp(hi, clampf(m * 0.8 + 0.25, 0.0, 1.0))
		return col if d.y > -0.5 else col.darkened(0.25)
	# kalça -> ince bel -> yüksek, kaslı omuzlar
	r.hips = r._pivot(root, Vector3(0, 4.2, 2.4), "kalca_kok")
	var hsp = [Vector3(0, 0.3, 1.8), Vector3(0, 0.2, 0.2), Vector3(0, 0.0, -1.8), Vector3(0, 0.2, -3.6)]
	var hrd = [Vector2(1.6, 1.6), Vector2(1.7, 1.7), Vector2(1.3, 1.35), Vector2(1.7, 1.8)]
	_tube(r, r.hips, hsp, hrd, c, flame, 28, 6)
	_veins(r, r.hips, hsp, hrd, 34, 51, dk, 0.2)
	r._collider(r.hips, Vector3(0, 0, -0.8), Vector3(3.2, 3.2, 5.6))
	r.chest = r._pivot(r.hips, Vector3(0, 0.2, -3.6), "gogus")
	var csp = [Vector3(0, 0.2, 0.8), Vector3(0, 0.6, -0.6), Vector3(0, 0.3, -1.8), Vector3(0, -0.4, -2.8)]
	var crd = [Vector2(1.7, 1.7), Vector2(2.3, 2.2), Vector2(2.0, 2.0), Vector2(1.2, 1.2)]
	_tube(r, r.chest, csp, crd, c, flame, 28, 6)
	_veins(r, r.chest, csp, crd, 22, 52, dk, 0.18)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:   # yukarı çıkık kürek kemikleri (sinsi sokulma duruşu)
		mc.add("sphere", Vector3(1.75 * sx, 1.4, -0.9), Vector3(1.5, 1.3, 2.0), c, Vector3(0, 0, -18 * sx), 12)
	# sırtta yukarı-geriye savrulan alev dilleri (siyah ve açık mavi karışık)
	for i in 9:
		var z = lerpf(1.0, -2.0, i / 8.0)
		var sx2 = 1.0 if i % 2 == 0 else -1.0
		BeastRig.claw(mc, Vector3(0.6 * sx2, 2.3 - absf(z + 0.6) * 0.15, z), Vector3(0.45 * sx2, 0.55, 1.0), 1.4 + 0.5 * (i % 3), 0.2, dk if i % 2 == 0 else hi)
	r._mesh(r.chest, mc)
	var hm = MB.new()
	for i in 10:
		var z = lerpf(1.6, -3.2, i / 9.0)
		var sx2 = 1.0 if i % 2 == 0 else -1.0
		BeastRig.claw(hm, Vector3(0.5 * sx2, 1.5, z), Vector3(0.45 * sx2, 0.5, 1.0), 1.2 + 0.5 * (i % 3), 0.2, dk if i % 2 == 0 else hi)
	r._mesh(r.hips, hm)
	r._collider(r.chest, Vector3(0, 0.2, -1.2), Vector3(4.0, 3.6, 3.6))
	# baş: alçakta, öne uzanmış, hafif yukarı (avına) bakar; yuvarlak geniş kedi kafası, kısa burun
	r.head = r._pivot(r.chest, Vector3(0, -0.5, -3.3), "bas")
	r.head.rotation.x = deg_to_rad(8.0)
	var hsp2 = [Vector3(0, 0.3, 0.8), Vector3(0, 0.35, 0.0), Vector3(0, 0.15, -0.6), Vector3(0, -0.05, -1.0)]
	var hrd2 = [Vector2(1.5, 1.3), Vector2(1.8, 1.45), Vector2(1.5, 1.15), Vector2(0.95, 0.7)]
	_tube(r, r.head, hsp2, hrd2, c, flame, 24, 6)
	var mh = MB.new()
	# bıyık yastıkları + morumsu burun (kedi ağzı)
	for sx in [-1.0, 1.0]:
		mh.add("sphere", Vector3(0.34 * sx, -0.22, -1.36), Vector3(0.68, 0.52, 0.55), c.lerp(hi, 0.3), Vector3.ZERO, 12)
		for k in 3:  # bıyık
			mh.add("box", Vector3(0.95 * sx, -0.2 + k * 0.1, -1.3), Vector3(1.4, 0.035, 0.035), cl, Vector3(0, -18 * sx, (k - 1) * 9 * sx))
	mh.add("sphere", Vector3(0, 0.06, -1.6), Vector3(0.46, 0.3, 0.3), Color(0.45, 0.35, 0.5), Vector3.ZERO, 10)
	# alında V biçimli siyah alev çizgileri
	for sx in [-1.0, 1.0]:
		for k in 3:
			var p0 = Vector3((0.25 + k * 0.28) * sx, 1.42 - k * 0.1, -0.5 + k * 0.15)
			Loft.tube(mh, [p0, p0 + Vector3(0.15 * sx, 0.14, 0.6), p0 + Vector3(0.45 * sx, 0.1, 1.1)], [0.07, 0.09, 0.02], dk, 6, 3)
	for sx in [-1.0, 1.0]:
		# geriye yatık sivri kulaklar (saldırı duruşu), içi siyah
		var e0 = Vector3(1.0 * sx, 1.3, 0.3)
		Loft.tube(mh, [e0, e0 + Vector3(0.55 * sx, 0.8, 0.7), e0 + Vector3(1.0 * sx, 1.4, 1.5)], [Vector2(0.75, 0.3), Vector2(0.5, 0.22), Vector2(0.04, 0.04)], c, 12, 3, true, false)
		mh.add_xf("sphere", Transform3D(Basis.looking_at(Vector3(0.3 * sx, 0.5, 1.0).normalized(), Vector3.UP) * Basis.from_scale(Vector3(0.45, 0.9, 0.08)), e0 + Vector3(0.5 * sx, 0.72, 0.55)), dk, 8)
		# çekik, kızgın göz: tüp yüzeyine oturtulur (içine gömülmez), öne ve yana bakar
		var sp = _tube_pt(hsp2, hrd2, 0.8, deg_to_rad(90.0 - 34.0 * sx), 0.0)
		var nrm = ((sp[1] as Vector3) + Vector3(0, 0, -1.3)).normalized()
		var ep: Vector3 = sp[0] + nrm * 0.04
		var eb = Basis(nrm, deg_to_rad(-22 * sx)) * Basis.looking_at(-nrm, Vector3.UP)
		var iris = Color(1.0, 0.85, 0.15) if sx < 0 else Color(0.2, 0.95, 0.55)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.9, 0.26, 0.26)), ep), dk, 12)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.5, 0.17, 0.34)), ep + nrm * 0.02 - eb.x * 0.08 * sx), iris, 10)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.06, 0.17, 0.38)), ep + nrm * 0.03 - eb.x * 0.08 * sx), dk, 6)
		mh.add_xf("sphere", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(-10 * sx)) * Basis.from_scale(Vector3(1.1, 0.18, 0.26)), ep + nrm * 0.05 + eb.y * 0.2), dk, 10)   # çatık kaş
		# yanaklarda geriye savrulan alev tutamları (geniş kedi yanak tüyü)
		for k in 4:
			BeastRig.claw(mh, Vector3(1.45 * sx, 0.1 - k * 0.25, -0.2 + k * 0.25), Vector3(sx, 0.15, 0.6), 1.3, 0.28, dk if k % 2 == 1 else c)
		# ÜST DİŞ SIRASI: açık ağzın üst kenarı boyunca, önde uzun köpek dişi
		for i in 8:
			var u = i / 7.0
			var tp = Vector3(lerpf(1.08, 0.28, u) * sx, lerpf(-0.86, -0.62, u), lerpf(-0.25, -1.5, u))
			var big = i == 6
			BeastRig.claw(mh, tp, Vector3(0.05 * sx, -1, -0.15), 0.95 if big else 0.5, 0.13 if big else 0.1, cl)
		Loft.tube(mh, [Vector3(1.1 * sx, -0.8, -0.15), Vector3(0.8 * sx, -0.72, -0.85), Vector3(0.3 * sx, -0.6, -1.4), Vector3(0.02 * sx, -0.58, -1.5)], [0.1, 0.11, 0.1, 0.07], gum, 8, 3)   # dudak
	# ağız içi (pembe) + gırtlak (koyu)
	mh.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(1.95, 0.5, 1.6)), Vector3(0, -0.98, -0.6)), pink, 14)
	mh.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(0.9, 0.45, 0.8)), Vector3(0, -0.9, -0.05)), gum, 10)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -0.4), Vector3(3.4, 2.8, 3.0))
	# alt çene: ARDINA KADAR AÇIK (aşağı eğik), üstü pembe, kenarında alt diş sırası
	r.jaw = r._pivot(r.head, Vector3(0, -0.92, -0.05), "cene")
	var jb = MB.new()
	Loft.tube(jb, [Vector3(0, 0.0, 0.2), Vector3(0, -0.4, -0.6), Vector3(0, -0.85, -1.2)], [Vector2(1.1, 0.38), Vector2(0.85, 0.32), Vector2(0.42, 0.2)], c, 16, 4, true, true,
		func(_t: float, _a: float, d: Vector3) -> Color:
			return pink if d.y > 0.3 else c.darkened(0.1))
	jb.add_xf("sphere", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-34)) * Basis.from_scale(Vector3(0.6, 0.18, 1.2)), Vector3(0, -0.25, -0.6)), Color(0.85, 0.35, 0.45), 10)   # dil
	for sx in [-1.0, 1.0]:
		for i in 7:
			var u = i / 6.0
			var bp = Vector3(lerpf(0.92, 0.3, u) * sx, lerpf(0.12, -0.7, u), lerpf(0.0, -1.15, u))
			var big = i == 5
			BeastRig.claw(jb, bp, Vector3(0.05 * sx, 1, -0.55), 0.75 if big else 0.42, 0.11 if big else 0.09, cl)
		for k in 2:   # çene altında sarkan alev tutamı
			BeastRig.claw(jb, Vector3(0.4 * sx, -0.5 - k * 0.3, -0.6 + k * 0.3), Vector3(0.3 * sx, -1, 0.5), 0.9, 0.22, dk if k == 0 else c)
	r._mesh(r.jaw, jb)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -1.6), "agiz")
	# bacaklar: ön bacaklar geniş açık (sinmiş, saldırıya hazır), arka bacaklar çömelik
	for sx in [-1.0, 1.0]:
		_leg(r, r.chest, sx, Vector3(1.7 * sx, -0.3, -1.3), Vector3(1.5 * sx, -1.7, -0.6), Vector3(0.2 * sx, -2.3, -0.6), 0.78, 0.55, 0.42, c, c, cl, true, false, 1.2)
		_leg(r, r.hips, sx, Vector3(1.3 * sx, -0.2, 0.8), Vector3(0.6 * sx, -1.6, -1.4), Vector3(0, -2.0, 1.3), 0.95, 0.62, 0.45, c, c, cl, false, false, 1.1)
	# iki uzun alev kuyruk
	_tail_fan(r, r.hips, Vector3(0, 0.9, 2.0), 2, 34.0, -42.0, 16.0, 0.7, 1.15, c, hi, "flame", 9)
	_particles(r.hips, Vector3(2.0, 1.8, 3.4), [Color(0.4, 0.65, 1.0, 0.95), Color(0.02, 0.02, 0.15, 0.0)], 160, 2.0, Vector3(0, 7, 0), 1.0, true)
	_particles(r.chest, Vector3(2.0, 2.2, 2.0), [Color(0.4, 0.65, 1.0, 0.95), Color(0.02, 0.02, 0.15, 0.0)], 90, 1.8, Vector3(0, 7, 0), 0.9, true)
	_particles(r.head, Vector3(1.2, 1.0, 1.2), [Color(0.5, 0.75, 1.0, 0.9), Color(0.02, 0.02, 0.15, 0.0)], 40, 1.2, Vector3(0, 5, 0), 0.7, true)
	r._weak(r.head, Vector3(0, 1.5, 0.0))
	r._weak(r.hips, Vector3(0, 2.0, 0.0))


# ------------------------------------------------------------------ 3 Kuyruk: Isobu (dikenli gri-yeşil kabuk, kırmızı et, tek açık göz)
static func _isobu(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): soluk gri, taş gibi zırh; dev kubbe kabuk, öne doğru başın üstüne kıvrılan kalın kenar sırtı,
	# kabuğun her yerine dağılmış sivri dikenler; kabuk altında lifli/çizgili koyu kırmızı et;
	# dikenli taç gibi yelpazelenen baş, tek açık kırmızı (halkalı) göz, diğeri kapalı; gri plakalı kalın kollar, iri pençeli eller; karides gibi boğumlu kuyruklar
	r.quadruped = true
	r.upright = false
	var sh = Color(0.5, 0.51, 0.55); var shd = Color(0.32, 0.33, 0.37); var sp = Color(0.62, 0.63, 0.67)
	var flesh = Color(0.55, 0.13, 0.15); var fl2 = Color(0.32, 0.05, 0.08)
	var shade = func(_t: float, a: float, _d: Vector3) -> Color:
		return sh.lerp(shd, smoothstep(0.3, -0.6, sin(a)))
	r.hips = r._pivot(root, Vector3(0, 3.0, 0.8), "kalca_kok")
	# kabuk altı et: lifli kırmızı (koyu çizgiler)
	var fsp = [Vector3(0, -0.7, 4.4), Vector3(0, -0.4, 0.4), Vector3(0, -0.6, -3.8)]
	var frd = [Vector2(3.2, 1.5), Vector2(3.8, 1.9), Vector2(3.2, 1.6)]
	_tube(r, r.hips, fsp, frd, flesh, Callable(), 24, 5)
	_veins(r, r.hips, fsp, frd, 50, 71, fl2, 0.06)
	# kabuk: dev kubbe
	var ssp = [Vector3(0, -0.2, 4.8), Vector3(0, 1.2, 2.2), Vector3(0, 1.6, -0.8), Vector3(0, 1.0, -3.8)]
	var srd = [Vector2(2.6, 1.4), Vector2(4.6, 3.0), Vector2(4.8, 3.2), Vector2(3.8, 2.2)]
	_tube(r, r.hips, ssp, srd, sh, shade, 30, 6)
	_veins(r, r.hips, ssp, srd, 26, 72, shd, 0.07)   # taş çatlakları
	var mb = MB.new()
	# kabuğun kalın kenar sırtı: yanlardan öne dolanıp başın üstüne kıvrılır
	for sx in [-1.0, 1.0]:
		var rim: Array = []
		for k in 8:
			var u = k / 7.0
			rim.append(Vector3(lerpf(2.6, 4.9, sin(u * PI * 0.85)) * sx, lerpf(-0.1, -0.5, sin(u * PI)), lerpf(4.8, -3.8, u)))
		Loft.tube(mb, rim, [0.5, 0.8, 0.95, 1.0, 1.0, 0.95, 0.9, 0.9], sh, 10, 3)
		for k in range(1, 8):   # kenar dikenleri: dışa-yukarı
			var rp: Vector3 = rim[k]
			BeastRig.claw(mb, rp + Vector3(0.6 * sx, 0.5, 0), Vector3(sx, 0.7, 0.2).normalized(), 1.1 + 0.3 * (k % 2), 0.3, sp)
	Loft.tube(mb, [Vector3(-3.8, 0.0, -3.8), Vector3(-2.2, 0.9, -5.9), Vector3(0, 1.2, -6.6), Vector3(2.2, 0.9, -5.9), Vector3(3.8, 0.0, -3.8)], [0.9, 1.15, 1.25, 1.15, 0.9], sh, 12, 3)   # başın üstündeki ön kenar
	# kabuğa dağılmış sivri dikenler (yüzey normali boyunca)
	var rng = RandomNumberGenerator.new()
	rng.seed = 333
	for i in 72:
		var d = _tube_pt(ssp, srd, rng.randf_range(0.08, 0.95), rng.randf_range(deg_to_rad(15), deg_to_rad(165)), -0.1)
		var ln = rng.randf_range(0.8, 2.2)
		BeastRig.claw(mb, d[0], ((d[1] as Vector3) + Vector3(0, 0, 0.35)).normalized(), ln, ln * 0.24, sp)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 1.2, 0), Vector3(8.6, 3.8, 9.6))
	r.chest = r._pivot(r.hips, Vector3(0, -0.4, -4.0), "gogus")
	_tube(r, r.chest, [Vector3(0, 0, 1.2), Vector3(0, 0.2, -0.6)], [Vector2(2.4, 1.6), Vector2(2.0, 1.5)], flesh)
	# baş: gri zırhlı, kabuğun kenarının altından çıkar
	r.head = r._pivot(r.chest, Vector3(0, 0.5, -1.8), "bas")
	var hsp = [Vector3(0, 0.1, 1.0), Vector3(0, 0.2, 0.0), Vector3(0, 0.0, -1.0), Vector3(0, -0.3, -1.7)]
	var hrd = [Vector2(1.8, 1.4), Vector2(2.0, 1.5), Vector2(1.6, 1.2), Vector2(0.9, 0.7)]
	_tube(r, r.head, hsp, hrd, sh, shade, 24, 5)
	var mh = MB.new()
	# taç gibi geriye-yukarı yelpazelenen yassı dikenler
	for i in 13:
		var a = lerpf(-1.4, 1.4, i / 12.0)
		var base = Vector3(sin(a) * 1.3, 1.2 + cos(a) * 0.2, 0.1 - absf(a) * 0.2)
		var ln = 1.3 + (1.0 - absf(a) / 1.4) * 1.2
		BeastRig.claw(mh, base, Vector3(sin(a) * 0.9, 0.8, 0.9).normalized(), ln, 0.34, sp if i % 2 == 0 else sh)
	for sx in [-1.0, 1.0]:
		for k in 3:   # yanak dikenleri
			BeastRig.claw(mh, Vector3(1.5 * sx, -0.2 - k * 0.3, -0.5 + k * 0.4), Vector3(sx, -0.3, 0.3), 0.9, 0.24, sp)
	# sol göz: açık, kırmızı halkalı (Sharingan benzeri); sağ göz kapalı zırh kapağı altında
	for sx in [-1.0, 1.0]:
		var d = _tube_pt(hsp, hrd, 0.72, deg_to_rad(90.0 - 40.0 * sx), 0.0)
		var nrm = ((d[1] as Vector3) + Vector3(0, 0, -1.1)).normalized()
		var ep: Vector3 = d[0] + nrm * 0.04
		var eb = Basis.looking_at(-nrm, Vector3.UP)
		if sx < 0:
			mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.75, 0.6, 0.26)), ep), Color(0.05, 0.03, 0.04), 12)
			mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.6, 0.48, 0.32)), ep + nrm * 0.02), Color(0.95, 0.12, 0.08), 12)
			mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.4, 0.32, 0.34)), ep + nrm * 0.03), Color(0.3, 0.02, 0.02), 12)
			mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.32, 0.25, 0.36)), ep + nrm * 0.035), Color(0.95, 0.12, 0.08), 12)
			mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.12, 0.12, 0.4)), ep + nrm * 0.04), Color(0.05, 0.02, 0.02), 8)
		else:
			mh.add_xf("sphere", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(-12)) * Basis.from_scale(Vector3(0.75, 0.08, 0.3)), ep), Color(0.1, 0.06, 0.06), 10)   # kapalı göz çizgisi
		mh.add_xf("sphere", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(10 * sx)) * Basis.from_scale(Vector3(1.05, 0.3, 0.4)), ep + eb.y * 0.36 + nrm * 0.05), sh, 10)   # zırh kaş
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -0.4), Vector3(4.0, 3.0, 3.4))
	r.jaw = r._pivot(r.head, Vector3(0, -0.7, -0.4), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.2, 0.6), Vector3(0, -0.4, -0.6), Vector3(0, -0.2, -1.4)], [Vector2(1.6, 0.55), Vector2(1.4, 0.6), Vector2(0.8, 0.35)], sh, 16, 3, true, true, shade)
	for i in 7:
		BeastRig.claw(mj, Vector3(-0.9 + i * 0.3, 0.1, -1.1 + absf(i - 3) * 0.12), Vector3(0, 1, -0.3), 0.45, 0.13, sp)   # tırtıklı diş
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.5, -1.7), "agiz")
	# gri plakalı kalın kollar, dört iri pençe
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.8 * sx, 0.2, 0.3), Vector3(2.8 * sx, -0.5, -1.0), Vector3(-0.4 * sx, -2.0, -1.5), 1.05, 0.9, 0.72, sh, sh, sp, 4, 1.6)
	var am = MB.new()
	for sx in [-1.0, 1.0]:   # omuz zırh plakası ve yuvarlak taş kabarcıklar
		am.add("sphere", Vector3(2.8 * sx, 0.6, 0.2), Vector3(2.2, 1.6, 2.2), sh, Vector3(0, 0, -15 * sx), 12)
		for k in 4:
			am.add("sphere", Vector3((2.4 + k * 0.25) * sx, 0.9 - k * 0.35, -0.4 + k * 0.3), Vector3(0.45, 0.4, 0.45), sp, Vector3.ZERO, 8)
		BeastRig.claw(am, Vector3(3.2 * sx, 1.1, 0.4), Vector3(sx, 0.8, 0.3), 1.4, 0.35, sp)
	r._mesh(r.chest, am)
	_tail_fan(r, r.hips, Vector3(0, -0.2, 4.6), 3, 30.0, -12.0, 12.0, 0.8, 1.1, sh, sp, "shrimp", 11)
	r._weak(r.hips, Vector3(0, 4.8, 0.0))
	r._weak(r.head, Vector3(0, 1.8, -0.1))


# ------------------------------------------------------------------ 4 Kuyruk: Son Gokū (kırmızı kürklü, yeşil tenli goril, boynuz taç)
static func _son_goku(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): koyu kırmızı, püskül püskül kürklü kambur dev maymun; dev kaslı omuzlar, uzun kollar;
	# soluk gri-yeşil çıplak göğüs/karın; kırmızı yeleyle çevrili soluk yeşil yüz, ARDINA KADAR AÇIK dikey ağız (mor-pembe gırtlak, çevresinde diş halkası),
	# alt köşelerden sarkan iki koyu kıvrık diş; küçük sarı-turuncu gözler, kalın kaş; öne-yukarı kıvrılan bej boynuz tacı; bej kemik plakalı kalın kuyruklar
	var c = Color(0.48, 0.07, 0.05); var cd = Color(0.3, 0.04, 0.04); var g = Color(0.62, 0.7, 0.6); var gd = Color(0.45, 0.53, 0.46)
	var bone = Color(0.86, 0.76, 0.58); var dk = Color(0.1, 0.05, 0.05); var gum = Color(0.45, 0.08, 0.12)
	var fur = func(t: float, a: float, d: Vector3) -> Color:
		if d.z < -0.5 and absf(d.x) < 0.7 and t > 0.15 and t < 0.8:
			return g   # çıplak göğüs/karın
		return c.lerp(cd, 0.25 + 0.12 * sin(t * 17.0 + a * 5.0)) if d.y < 0.6 else c
	var rng = RandomNumberGenerator.new()
	rng.seed = 404
	# püskül kürk: yüzeyden aşağı sarkan sivri tutamlar
	var tufts = func(mb: MB, sp: Array, rd: Array, n: int, t0: float, t1: float) -> void:
		for i in n:
			var d = _tube_pt(sp, rd, rng.randf_range(t0, t1), rng.randf_range(-0.3, PI + 0.3) + (PI if rng.randf() < 0.35 else 0.0), -0.15)
			var nr: Vector3 = d[1]
			if nr.z < -0.55 and absf(nr.x) < 0.6:
				continue   # göğüs çıplak
			var ln = rng.randf_range(0.9, 1.8)
			BeastRig.claw(mb, d[0], (nr * 0.55 + Vector3(0, -0.75, 0.25)).normalized(), ln, ln * 0.26, c if rng.randf() < 0.6 else cd)
	r.hips = r._pivot(root, Vector3(0, 3.4, 0.8), "kalca_kok")
	var hsp = [Vector3(0, -1.0, 0.4), Vector3(0, 0.4, 0), Vector3(0, 1.8, -0.4)]
	var hrd = [Vector2(2.3, 2.0), Vector2(2.6, 2.2), Vector2(2.7, 2.3)]
	_tube(r, r.hips, hsp, hrd, c, fur, 24, 5)
	var hm = MB.new()
	tufts.call(hm, hsp, hrd, 26, 0.1, 0.9)
	r._mesh(r.hips, hm)
	r.chest = r._pivot(r.hips, Vector3(0, 2.7, -0.6), "gogus")
	var csp = [Vector3(0, -1.6, 0.3), Vector3(0, 0.0, 0.0), Vector3(0, 1.4, -0.6), Vector3(0, 2.0, -1.6)]
	var crd = [Vector2(2.7, 2.1), Vector2(3.5, 2.6), Vector2(3.4, 2.5), Vector2(1.9, 1.7)]
	_tube(r, r.chest, csp, crd, c, fur, 28, 6)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:   # dev kambur omuz kasları
		mc.add("sphere", Vector3(2.9 * sx, 1.5, -0.2), Vector3(2.9, 2.5, 2.9), c, Vector3(0, 0, -15 * sx), 14)
		for k in 7:
			var a = k * 0.55
			BeastRig.claw(mc, Vector3((2.9 + cos(a) * 1.2) * sx, 1.5 + sin(a) * 1.1, 0.4 + k * 0.05), Vector3(sx * 0.6, -0.5, 0.5).normalized(), 1.6, 0.42, c if k % 2 == 0 else cd)
	tufts.call(mc, csp, crd, 44, 0.05, 0.95)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.4, -0.4), Vector3(6.4, 4.6, 4.2))
	# baş: kambur göğsün önünde, alçakta
	r.head = r._pivot(r.chest, Vector3(0, 2.3, -2.6), "bas")
	var bsp = [Vector3(0, 0.2, 0.9), Vector3(0, 0.3, 0.0), Vector3(0, 0.1, -0.8)]
	var brd = [Vector2(1.7, 1.6), Vector2(1.9, 1.8), Vector2(1.6, 1.5)]
	_tube(r, r.head, bsp, brd, c, func(t: float, _a: float, d: Vector3) -> Color:
		return g if (t > 0.6 and d.z < -0.2 and absf(d.x) < 0.8) else c, 24, 6)
	# yüz = ön kubbe (soluk yeşil); yüz parçaları kubbe yüzeyine oturtulur
	var dc = Vector3(0, 0.1, -0.8); var dr = Vector3(1.6, 1.5, brd[2].length() * 0.5)
	var dome = func(a: float, e: float, lift := 0.0) -> Array:
		var p = Vector3(dr.x * cos(e) * sin(a), dr.y * sin(e), -dr.z * cos(e) * cos(a))
		var n = Vector3(p.x / (dr.x * dr.x), p.y / (dr.y * dr.y), p.z / (dr.z * dr.z)).normalized()
		return [dc + p + n * lift, n]
	var mh = MB.new()
		# kırmızı yele: yüzün çevresinden dışa-geriye savrulan tutamlar
	for i in 18:
		var ang = TAU * i / 18.0
		var d = dome.call(sin(ang) * 1.5, cos(ang) * 1.3, -0.1)
		BeastRig.claw(mh, d[0], ((d[1] as Vector3) * 0.2 + Vector3(sin(ang), cos(ang), 0.9)).normalized(), 1.1, 0.3, c if i % 2 == 0 else cd)
	# ARDINA KADAR AÇIK DİKEY AĞIZ
	var md = dome.call(0.0, -0.28, 0.0)
	var mb_basis = Basis.looking_at(md[1], Vector3.UP)
	mh.add_xf("sphere", Transform3D(mb_basis * Basis.from_scale(Vector3(1.25, 1.65, 0.3)), md[0] + (md[1] as Vector3) * 0.05), gum, 14)    # dudak/diş eti halkası
	mh.add_xf("sphere", Transform3D(mb_basis * Basis.from_scale(Vector3(1.0, 1.38, 0.34)), md[0] + (md[1] as Vector3) * 0.06), Color(0.72, 0.45, 0.62), 14)   # mor-pembe ağız içi
	mh.add_xf("sphere", Transform3D(mb_basis * Basis.from_scale(Vector3(0.42, 0.6, 0.36)), md[0] + (md[1] as Vector3) * 0.07 + mb_basis.y * 0.05), Color(0.2, 0.05, 0.1), 10)   # koyu gırtlak
	for i in 16:   # diş halkası: ağız kenarından içe bakan sivri dişler
		var ang = TAU * i / 16.0
		var rim = mb_basis.x * cos(ang) * 0.6 + mb_basis.y * sin(ang) * 0.8
		BeastRig.claw(mh, md[0] + (md[1] as Vector3) * 0.16 + rim, (-rim.normalized() + (md[1] as Vector3) * 0.3).normalized(), 0.34 + 0.12 * (i % 2), 0.09, bone)
	for sx in [-1.0, 1.0]:
		# alt köşelerden aşağı sarkan iki koyu kıvrık diş
		var fp: Vector3 = md[0] + (md[1] as Vector3) * 0.2 + mb_basis.x * 0.62 * sx - mb_basis.y * 0.55
		Loft.tube(mh, [fp, fp + Vector3(0.12 * sx, -0.5, -0.25), fp + Vector3(0.05 * sx, -1.0, -0.15), fp + Vector3(-0.08 * sx, -1.3, 0.05)], [0.16, 0.13, 0.08, 0.02], [bone, bone.lerp(dk, 0.5), dk, dk], 8, 3, true, false)
		# küçük sarı-turuncu göz, koyu göz çukuru, kalın soluk kaş
		var ed = dome.call(0.52 * sx, 0.42, 0.02)
		var eb = Basis.looking_at(ed[1], Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-18 * sx))
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.62, 0.38, 0.18)), ed[0]), Color(0.2, 0.25, 0.2), 10)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.34, 0.24, 0.24)), ed[0] + (ed[1] as Vector3) * 0.02), Color(1.0, 0.62, 0.12), 10)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.1, 0.13, 0.28)), ed[0] + (ed[1] as Vector3) * 0.03), dk, 6)
		var bd = dome.call(0.5 * sx, 0.62, 0.05)
		mh.add_xf("sphere", Transform3D(Basis.looking_at(bd[1], Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-16 * sx)) * Basis.from_scale(Vector3(0.95, 0.3, 0.4)), bd[0]), gd, 10)
		# sivri soluk yeşil kulaklar
		Loft.tube(mh, [Vector3(1.6 * sx, 0.4, -0.2), Vector3(2.2 * sx, 0.75, 0.0), Vector3(2.6 * sx, 1.1, 0.25)], [Vector2(0.5, 0.2), Vector2(0.35, 0.15), Vector2(0.03, 0.03)], g, 10, 3)
		# bej boynuz tacı: alından öne, sonra yukarı kıvrılır; uçları koyu
		var hp = dome.call(0.32 * sx, 0.8, -0.1)
		var h0: Vector3 = hp[0]
		Loft.tube(mh, [h0, h0 + Vector3(0.2 * sx, 0.4, -0.55), h0 + Vector3(0.35 * sx, 1.05, -0.85), h0 + Vector3(0.3 * sx, 1.75, -0.7), h0 + Vector3(0.18 * sx, 2.15, -0.35)], [0.32, 0.28, 0.21, 0.12, 0.03], [bone, bone, bone, bone.lerp(dk, 0.5), dk], 10, 3, true, false)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -0.4), Vector3(3.6, 3.4, 3.4))
	r.jaw = r._pivot(r.head, (md[0] as Vector3) - mb_basis.y * 0.9, "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.15, 0.1), Vector3(1.5, 0.6, 1.0), g, Vector3.ZERO, 12)   # alt dudak / çene
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, (md[0] as Vector3) + (md[1] as Vector3) * 0.4, "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(3.4 * sx, 1.1, -0.2), Vector3(1.1 * sx, -3.3, -0.6), Vector3(0.2 * sx, -3.0, -1.2), 1.45, 1.15, 0.95, c, g, dk, 5, 1.6)
		_leg(r, r.hips, sx, Vector3(1.6 * sx, -1.2, 0.2), Vector3(0.6 * sx, -1.3, -0.5), Vector3(0, -1.1, 0.1), 1.35, 1.1, 0.85, c, g, dk, false, false, 1.3)
	_tail_fan(r, r.hips, Vector3(0, 0.4, 2.0), 4, 62.0, -22.0, 13.0, 0.7, 1.05, c, cd, "spike", 9)
	_particles(r.mouth, Vector3(0.4, 0.4, 0.3), [Color(1.0, 0.5, 0.1, 0.9), Color(0.3, 0.05, 0.0, 0.0)], 30, 0.7, Vector3(0, 1, -2), 0.8, true)
	r._weak(r.head, Vector3(0, 1.6, 0.0))
	r._weak(r.chest, Vector3(0, 1.8, 1.8))


# ------------------------------------------------------------------ 5 Kuyruk: Kokuō (yunus başlı beyaz at, kırmızı göz altı, buhar)
static func _kokuo(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): beyaz, açık mavi-gri gölgeli yalın at gövdesi; çok uzun ince bacaklar, bej toynaklar;
	# öne-aşağı kavisli uzun boyun; yunus gibi uzun pürüzsüz baş, geniş açılan ağızda sık testere dişler;
	# kırmızı çerçeveli açık mavi göz; başın arkasından geriye uzanan dört bej uçlu boynuz (benekli);
	# göğüs/boyunda kabarık sivri tüy, beş uzun akan bej uçlu kuyruk
	r.quadruped = true
	r.upright = false
	var c = Color(0.95, 0.96, 0.97); var sh = Color(0.76, 0.8, 0.86); var tan = Color(0.86, 0.7, 0.48)
	var dk = Color(0.16, 0.18, 0.24); var red = Color(0.85, 0.12, 0.14); var cl = Color(1, 1, 1)
	var body = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.2 else sh
	# yalın at gövdesi: yüksek kalça, derin göğüs, ince bel
	r.hips = r._pivot(root, Vector3(0, 6.8, 2.6), "kalca_kok")
	var hsp = [Vector3(0, 0.3, 2.0), Vector3(0, 0.4, 0.4), Vector3(0, 0.0, -1.8), Vector3(0, -0.2, -3.8)]
	var hrd = [Vector2(1.7, 1.7), Vector2(1.9, 1.9), Vector2(1.5, 1.6), Vector2(1.9, 2.2)]
	_tube(r, r.hips, hsp, hrd, c, body, 24, 5)
	r._collider(r.hips, Vector3(0, 0, -0.8), Vector3(3.6, 3.6, 6.2))
	r.chest = r._pivot(r.hips, Vector3(0, -0.2, -4.0), "gogus")
	var csp = [Vector3(0, 0.0, 0.8), Vector3(0, -0.2, -0.6), Vector3(0, 0.6, -1.9)]
	var crd = [Vector2(2.0, 2.3), Vector2(2.1, 2.5), Vector2(1.5, 1.8)]
	_tube(r, r.chest, csp, crd, c, body, 22, 5)
	var mc = MB.new()
	for i in 9:   # göğüs ve boyun tabanında kabarık sivri tüy
		var a = lerpf(-1.3, 1.3, i / 8.0)
		BeastRig.claw(mc, Vector3(sin(a) * 1.6, -0.6 + cos(a) * 0.6, -1.8), Vector3(sin(a) * 0.5, -0.6, -0.6).normalized(), 1.5, 0.4, c if i % 2 == 0 else sh)
	for i in 6:   # sırtta yele
		BeastRig.claw(mc, Vector3(0, 2.3 - i * 0.05, -1.4 + i * 0.5), Vector3(0, 0.6, 1.0).normalized(), 1.2, 0.3, c)
	r._mesh(r.chest, mc)
	# uzun kavisli boyun: önce yukarı, sonra öne-aşağı
	_tube(r, r.chest, [Vector3(0, 0.6, -1.9), Vector3(0, 1.9, -3.1), Vector3(0, 1.8, -4.6), Vector3(0, 0.6, -5.8)], [Vector2(1.4, 1.6), Vector2(1.1, 1.25), Vector2(0.95, 1.05), Vector2(0.9, 1.0)], c, body, 20, 5)
	r.head = r._pivot(r.chest, Vector3(0, 0.3, -6.0), "bas")
	r.head.rotation.x = deg_to_rad(-38.0)   # baş aşağıda, öne uzanmış
	# yunus başı: yuvarlak alın, uzun pürüzsüz gaga
	var ksp = [Vector3(0, 0.3, 0.9), Vector3(0, 0.55, 0.0), Vector3(0, 0.3, -1.0), Vector3(0, -0.05, -1.9), Vector3(0, -0.2, -2.5)]
	var krd = [Vector2(1.1, 1.05), Vector2(1.2, 1.2), Vector2(0.95, 0.88), Vector2(0.62, 0.52), Vector2(0.34, 0.28)]
	_tube(r, r.head, ksp, krd, c, body, 20, 5)
	var mh = MB.new()
	# ağız: gaganın iki yanında yanaktan uca uzanan çizgi + sık testere dişler (üst ve alt)
	for sx in [-1.0, 1.0]:
		var gl: Array = []
		for k in 8:
			var u = k / 7.0
			gl.append((_tube_pt(ksp, krd, lerpf(0.35, 0.97, u), deg_to_rad(-90.0 + 70.0 * sx), 0.0)[0] as Vector3))
		var gr: Array = []
		gr.resize(gl.size())
		gr.fill(Vector2(0.03, 0.04))
		Loft.tube(mh, gl, gr, dk, 6, 2)
		for k in 18:
			var u = (k + 0.5) / 18.0
			var gp = _tube_pt(ksp, krd, lerpf(0.37, 0.95, u), deg_to_rad(-90.0 + 70.0 * sx), 0.0)
			var n: Vector3 = gp[1]
			BeastRig.claw(mh, (gp[0] as Vector3) + Vector3(0, 0.04, 0) + n * 0.02, (Vector3(0, -1, 0) + n * 0.2).normalized(), 0.13, 0.035, cl)
			BeastRig.claw(mh, (gp[0] as Vector3) - Vector3(0, 0.04, 0) + n * 0.02, (Vector3(0, 1, 0) + n * 0.2).normalized(), 0.11, 0.03, cl)
		# göz: kırmızı çerçeve, açık mavi iris, koyu bebek; üstünde kaş çıkıntısı
		var eg = _tube_pt(ksp, krd, 0.3, deg_to_rad(90.0 - 62.0 * sx), 0.0)
		var nrm: Vector3 = ((eg[1] as Vector3) + Vector3(0, 0, -0.3)).normalized()
		var ep: Vector3 = (eg[0] as Vector3) + nrm * 0.04
		var eb = Basis.looking_at(-nrm, Vector3.UP) * Basis(Vector3.BACK, deg_to_rad(-10 * sx))
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.5, 0.32, 0.14)), ep), red, 12)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.4, 0.25, 0.18)), ep + nrm * 0.02), cl, 12)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.22, 0.22, 0.2)), ep + nrm * 0.03), Color(0.6, 0.75, 0.9), 10)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.12, 0.13, 0.22)), ep + nrm * 0.035), dk, 8)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.75, 0.18, 0.3)), ep + eb.y * 0.24 + nrm * 0.04), sh, 10)
		# dört boynuz: başın arkasından geriye-yukarı, uçları bej, üstünde benekler
		for h in 2:
			var h0 = Vector3((0.55 + h * 0.3) * sx, 0.95 - h * 0.25, 0.35 + h * 0.35)
			var hd = Vector3((0.45 + h * 0.5) * sx, 3.0 - h * 0.5, 2.2 + h * 0.3)
			Loft.tube(mh, [h0, h0 + hd * 0.5 + Vector3(0, 0.15, -0.1), h0 + hd], [0.34 - h * 0.05, 0.25 - h * 0.04, 0.04], [c, c.lerp(tan, 0.3), tan], 10, 3, true, false)
			for k in 3:
				mh.add("sphere", h0 + hd * (0.35 + k * 0.15) + Vector3(0.12 * sx, 0.12, 0), Vector3(0.07, 0.07, 0.07), tan, Vector3.ZERO, 6)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -1.0), Vector3(2.4, 2.2, 4.4))
	r.jaw = r._pivot(r.head, Vector3(0, -0.5, -0.6), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, 0.0, 0.3), Vector3(0, -0.05, -0.8), Vector3(0, 0.08, -1.75)], [Vector2(0.75, 0.28), Vector2(0.5, 0.22), Vector2(0.24, 0.13)], sh, 14, 3)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.3, -2.4), "agiz")
	# çok uzun ince at bacakları, bej toynaklar
	for sx in [-1.0, 1.0]:
		# ön: dirsek geride, diz öne; arka: diz öne, topuk (hock) geride — taban toynakla birlikte yere oturur
		_leg(r, r.chest, sx, Vector3(1.2 * sx, -1.2, -0.4), Vector3(0.1 * sx, -2.3, 0.4), Vector3(0, -2.4, -0.3), 0.85, 0.45, 0.32, c, tan, tan, true, true)
		_leg(r, r.hips, sx, Vector3(1.3 * sx, -0.8, 0.8), Vector3(0.1 * sx, -2.2, -1.1), Vector3(0, -2.9, 1.2), 1.15, 0.5, 0.33, c, tan, tan, false, true)
	# beş uzun akan kuyruk: kabarık, uçları bej
	r.tail_curl = 0.11   # arkaya akıp aşağı sarkar
	_tail_fan(r, r.hips, Vector3(0, 0.9, 2.2), 5, 34.0, -50.0, 19.0, 1.0, 1.6, c, c.lerp(tan, 0.55), "sleek", 11)
	_particles(r.hips, Vector3(2.0, 2.0, 3.5), [Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)], 60, 2.5, Vector3(0, 4, 0), 2.0)
	r._weak(r.head, Vector3(0, 1.3, 0.0))
	r._weak(r.hips, Vector3(0, 2.0, -1.0))


# ------------------------------------------------------------------ 6 Kuyruk: Saiken (açık mavimsi beyaz dev sümüklü böcek)
static func _saiken(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): soluk lila-gri, ıslak parlak sümüklü gövde; alt kısmı dev göbek, yukarı daralan armut gövde;
	# boyunsuz kubbe baş, başın yanında bir sıra koyu nokta (delikler), tepede kısa düğümlü göz sapları, sümük damlayan küçük ağız;
	# minik güdük kollar; arkadan yukarı-yana kalkan altı kalın pürüzsüz kuyruk, uçları yassı kaşık gibi, her yerden sarkan sümük; sabun köpüğü baloncukları
	r.quadruped = false
	r.upright = true
	var c = Color(0.8, 0.78, 0.84); var cd = Color(0.66, 0.63, 0.72); var hi = Color(0.97, 0.96, 1.0); var dk = Color(0.3, 0.27, 0.36)
	var slime = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.35 else cd
	# dev göbek (yere oturan alt gövde)
	r.hips = r._pivot(root, Vector3(0, 3.6, 0.4), "kalca_kok")
	var hsp = [Vector3(0, -3.2, 0.2), Vector3(0, -1.6, -0.5), Vector3(0, 0.6, -0.4), Vector3(0, 2.4, 0.0)]
	var hrd = [Vector2(3.6, 3.2), Vector2(4.4, 4.1), Vector2(4.0, 3.7), Vector2(2.9, 2.7)]
	_tube(r, r.hips, hsp, hrd, c, slime, 30, 6)
	r._collider(r.hips, Vector3(0, -0.8, -0.2), Vector3(8.0, 6.0, 7.4))
	var hm = MB.new()
	_slime_dress(hm, hsp, hrd, 26, 61, hi, c)
	r._mesh(r.hips, hm)
	# üst gövde: yukarı daralır
	r.chest = r._pivot(r.hips, Vector3(0, 2.2, -0.2), "gogus")
	var csp = [Vector3(0, -0.4, 0.1), Vector3(0, 1.0, -0.3), Vector3(0, 2.4, -0.4)]
	var crd = [Vector2(2.9, 2.7), Vector2(2.5, 2.3), Vector2(2.3, 2.1)]
	_tube(r, r.chest, csp, crd, c, slime, 26, 5)
	var mc = MB.new()
	_slime_dress(mc, csp, crd, 12, 62, hi, c)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 1.0, -0.2), Vector3(5.0, 3.4, 4.4))
	# kubbe baş: gövdeyle birleşik, hafif öne eğik
	r.head = r._pivot(r.chest, Vector3(0, 2.7, -0.6), "bas")
	r.head.rotation.x = deg_to_rad(12.0)
	var ksp = [Vector3(0, -0.6, 0.6), Vector3(0, 0.5, 0.2), Vector3(0, 1.0, -0.6), Vector3(0, 0.6, -1.6)]
	var krd = [Vector2(2.3, 2.0), Vector2(2.5, 2.1), Vector2(2.2, 1.8), Vector2(1.4, 1.0)]
	_tube(r, r.head, ksp, krd, c, slime, 24, 6)
	var mh = MB.new()
	_slime_dress(mh, ksp, krd, 8, 63, hi, c)
	for sx in [-1.0, 1.0]:
		# başın yanında bir sıra koyu nokta (göz/delik sırası)
		for k in 6:
			var d = _tube_pt(ksp, krd, lerpf(0.55, 0.9, k / 5.0), deg_to_rad(90.0 - lerpf(78.0, 50.0, k / 5.0) * sx), 0.0)
			mh.add_xf("sphere", Transform3D(Basis.looking_at(-(d[1] as Vector3), Vector3.UP) * Basis.from_scale(Vector3(0.24, 0.3, 0.1)), d[0]), dk, 8)
		# kısa düğümlü göz sapı (anten), ucunda yassı çatal düğme
		var a0: Vector3 = _tube_pt(ksp, krd, 0.45, deg_to_rad(90.0 - 28.0 * sx), 0.0)[0]
		var a1 = a0 + Vector3(0.35 * sx, 1.3, 0.1)
		Loft.tube(mh, [a0, a0 + Vector3(0.12 * sx, 0.7, 0.1), a1], [0.26, 0.2, 0.16], c, 10, 3, true, false)
		mh.add_xf("sphere", Transform3D(Basis(Vector3.BACK, deg_to_rad(-25 * sx)) * Basis.from_scale(Vector3(0.55, 0.25, 0.35)), a1 + Vector3(0, 0.08, 0)), c, 10)
		# yanlardaki boru gibi sifon çıkıntıları
		var sp: Vector3 = _tube_pt(ksp, krd, 0.7, deg_to_rad(-20.0 * sx + (180.0 if sx < 0 else 0.0)), 0.0)[0]
		Loft.tube(mh, [sp, sp + Vector3(0.7 * sx, -0.2, -0.3), sp + Vector3(1.3 * sx, -0.1, -0.5)], [0.32, 0.26, 0.24], c, 10, 3, true, true)
		mh.add("sphere", sp + Vector3(1.38 * sx, -0.1, -0.52), Vector3(0.28, 0.28, 0.28), dk, Vector3.ZERO, 8)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.4, -0.4), Vector3(4.6, 3.8, 4.0))
	# küçük ağız: burun ucunun altında yatay yarık, sarkan sümük ipleri
	r.jaw = r._pivot(r.head, Vector3(0, 0.1, -1.95), "cene")
	var mj = MB.new()
	mj.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(1.4, 0.24, 0.3)), Vector3.ZERO), dk, 12)
	for k in 3:
		var x = (k - 1) * 0.35
		Loft.tube(mj, [Vector3(x, -0.05, -0.05), Vector3(x * 1.1, -0.6, -0.1), Vector3(x * 1.1, -0.9 - k * 0.1, -0.08)], [0.08, 0.06, 0.12], hi, 6, 3)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, 0.1, -2.2), "agiz")
	# minik güdük kollar (göbeğin üstünde), üç kısa parmak
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.1 * sx, 0.6, -1.0), Vector3(0.6 * sx, -1.0, -0.8), Vector3(0.0, -0.8, -0.3), 0.45, 0.38, 0.32, c, c, cd, 3, 0.6, 0.7, 0.2)
	# altı kalın sümüklü kuyruk: arkadan yukarı-yana kalkar, uçları yassı ve aşağı sarkar
	r.tail_curl = 0.06   # yukarı kalkar, uçları hafifçe dışa-aşağı sarkar
	_tail_fan(r, r.hips, Vector3(0, 0.6, 2.6), 6, 70.0, -80.0, 15.0, 1.5, 1.8, c, cd, "slug", 9)
	# sabun köpüğü baloncukları
	_bubbles(r.hips, Vector3(6.0, 5.0, 5.0), 26)
	_particles(r.hips, Vector3(3.4, 0.5, 3.4), [Color(0.9, 0.9, 1.0, 0.6), Color(0.9, 0.9, 1.0, 0.0)], 30, 1.0, Vector3(0, -2, 0), 1.5)
	r._weak(r.head, Vector3(0, 2.0, -0.2))
	r._weak(r.hips, Vector3(0, 0.5, 4.2))


## Sümük kaplaması: yüzeyden aşağı sarkan damlalar + parlak beyaz ıslaklık çizgileri (tüp yüzeyine oturur)
static func _slime_dress(mb: MB, spine: Array, rad: Array, n: int, seed_v: int, hi: Color, col: Color) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var t = rng.randf_range(0.1, 0.92)
		var a = rng.randf_range(-0.4, PI + 0.4)
		var d = _tube_pt(spine, rad, t, a, 0.0)
		var p: Vector3 = d[0]
		var nr: Vector3 = d[1]
		if rng.randf() < 0.55:   # parlak ıslaklık çizgisi: yüzeye yapışık kısa dikey yassı şerit
			var ln = rng.randf_range(0.4, 0.9)
			Loft.tube(mb, [p + nr * 0.03, p + nr * 0.03 + Vector3(0, -ln * 0.5, 0), p + nr * 0.02 + Vector3(0, -ln, 0)], [Vector2(0.08, 0.025), Vector2(0.06, 0.02), Vector2(0.02, 0.01)], hi, 5, 2, true, true, Callable(), nr)
		else:   # sarkan sümük damlası: dışa çıkıp aşağı uzayan, ucu şişkin
			var ln2 = rng.randf_range(0.5, 1.4)
			var e = p + nr * 0.25 + Vector3(0, -ln2, 0)
			Loft.tube(mb, [p, p + nr * 0.2 + Vector3(0, -ln2 * 0.4, 0), e], [0.18, 0.09, 0.07], col, 6, 3, false, false)
			mb.add("sphere", e, Vector3.ONE * 0.2, col, Vector3.ZERO, 6)


## Yüzen sabun köpüğü baloncukları: yarı saydam, gökkuşağı kenarlı, yavaşça yükselir
static func _bubbles(parent: Node3D, box: Vector3, amount: int) -> void:
	var p = GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 6.0
	var pm = ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = Vector3.UP
	pm.spread = 40.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 1.0
	pm.gravity = Vector3(0, 0.15, 0)
	pm.scale_min = 0.5
	pm.scale_max = 2.0
	p.process_material = pm
	var sm = SphereMesh.new()
	sm.radius = 0.9
	sm.height = 1.8
	var m = StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.85, 0.9, 1.0, 0.12)
	m.rim_enabled = true
	m.rim = 1.0
	m.rim_tint = 0.2
	m.metallic_specular = 1.0
	m.roughness = 0.05
	m.emission_enabled = true
	m.emission = Color(0.5, 0.35, 0.6) * 0.15
	sm.material = m
	p.draw_pass_1 = sm
	p.visibility_aabb = AABB(-box * 2.0 - Vector3.ONE * 8, box * 4.0 + Vector3.ONE * 16)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)


# ------------------------------------------------------------------ 7 Kuyruk: Chōmei (mavi zırhlı gergedan böceği, turuncu kanatlar)
static func _chomei(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): arduvaz gri-mavi zırhlı böcek; yarı dik duruş, zırhlı göğüs ve yarık sıralı dev omuz plakaları;
	# çatal boynuzlu kask, önde turuncu dikey çizgili vizör; dört ince çok eklemli kol, pençe parmaklar;
	# göğüsten aşağı uzanan uzun boğumlu karın (altı yeşilimsi); arkadan yelpaze gibi açılan altı dev turuncu-kahve yaprak kanat, açık yeşil damarlar
	r.quadruped = false
	r.upright = true
	var c = Color(0.56, 0.58, 0.66); var cd = Color(0.4, 0.41, 0.49); var cl = Color(0.68, 0.7, 0.78)
	var slit = Color(0.12, 0.12, 0.18); var orn = Color(1.0, 0.55, 0.15); var gr = Color(0.82, 0.88, 0.5)
	var armor = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.3 else cd
	# uzun boğumlu karın: kalçadan geriye-aşağı iner (zemine değen uç)
	r.hips = r._pivot(root, Vector3(0, 6.0, 0.5), "kalca_kok")
	var ab = MB.new()
	for k in 9:
		var u = k / 8.0
		var p = Vector3(0, -u * 3.6 - u * u * 1.4, 0.6 + u * 4.0)
		var w = lerpf(0.85, 0.35, u)
		ab.add("sphere", p, Vector3(w * 2.0, w * 1.5, 1.3), c.lerp(Color(0.78, 0.8, 0.45), smoothstep(0.1, 0.9, u)), Vector3(-30 - u * 20, 0, 0), 14)   # aşağı doğru sarımsı yeşil
		ab.add_xf("torus", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(60 - u * 20)) * Basis.from_scale(Vector3(w * 1.05, 0.25, w * 0.8)), p + Vector3(0, 0, -0.2)), cd.lerp(Color(0.55, 0.58, 0.3), u), 12)
	r._mesh(r.hips, ab)
	r._collider(r.hips, Vector3(0, -2.4, 2.5), Vector3(2.6, 4.0, 5.0))
	# zırhlı göğüs (dik)
	r.chest = r._pivot(r.hips, Vector3(0, 0.6, -0.3), "gogus")
	var csp = [Vector3(0, -0.6, 0.2), Vector3(0, 0.8, 0.0), Vector3(0, 2.2, -0.2), Vector3(0, 3.0, -0.4)]
	var crd = [Vector2(0.9, 0.8), Vector2(1.1, 0.95), Vector2(1.05, 0.9), Vector2(0.7, 0.65)]
	_tube(r, r.chest, csp, crd, c, armor, 20, 5)
	var mc = MB.new()
	for k in 4:   # göğüs plaka dikişleri
		mc.add_xf("torus", Transform3D(Basis.from_scale(Vector3(lerpf(1.08, 0.95, k / 3.0), 0.16, 0.95)), Vector3(0, -0.2 + k * 0.7, -0.1)), cd, 14)
	for sx in [-1.0, 1.0]:
		# dev omuz plakası: kubbe + dışa-yukarı sivri uç + dikey yarık sıraları
		var sp = Vector3(1.85 * sx, 2.4, 0.0)
		mc.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(1.6, 1.4, 1.5)), Vector3(0.9 * sx, 2.1, 0.0)), cd, 12)   # omuzu gövdeye bağlayan eklem
		mc.add_xf("sphere", Transform3D(Basis(Vector3.BACK, deg_to_rad(-18 * sx)) * Basis.from_scale(Vector3(2.4, 3.0, 2.5)), sp), c, 16)
		mc.add_xf("sphere", Transform3D(Basis(Vector3.BACK, deg_to_rad(-18 * sx)) * Basis.from_scale(Vector3(2.42, 0.45, 2.52)), sp + Vector3(0, -1.1, 0)), cd, 14)
		BeastRig.claw(mc, sp + Vector3(0.9 * sx, 1.6, 0.1), Vector3(0.55 * sx, 1, 0.1).normalized(), 2.4, 0.5, c)   # omuz boynuzu
		for k in 5:
			var a = deg_to_rad(lerpf(-75.0, 15.0, k / 4.0))   # öne bakan yüzde dikey yarıklar
			var n = Vector3(sin(a) * sx, 0.05, -cos(a)).normalized()
			mc.add_xf("box", Transform3D(Basis.looking_at(-n, Vector3.UP) * Basis.from_scale(Vector3(0.16, 1.2, 0.08)), sp + Vector3(n.x * 1.18, 0.3, n.z * 1.24)), slit, 1)
	# sırtta, kanatların arasında yükselen çatallı böcek boynuzu
	var hb = Vector3(0, 2.4, 0.9)
	var hm = hb + Vector3(0, 5.6, 1.0)
	Loft.tube(mc, [hb, hb + Vector3(0, 2.8, 0.7), hm], [Vector2(1.1, 0.8), Vector2(0.8, 0.62), Vector2(0.55, 0.42)], c, 12, 3, true, false)
	for sx in [-1.0, 1.0]:
		Loft.tube(mc, [hm, hm + Vector3(1.1 * sx, 1.5, 0.2), hm + Vector3(2.4 * sx, 2.3, 0.4)], [0.5, 0.3, 0.04], c, 10, 3, false, false)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 1.4, 0), Vector3(5.0, 4.0, 3.0))
	# kask: önde vizör, tepede çatallı boynuz
	r.head = r._pivot(r.chest, Vector3(0, 3.4, -0.6), "bas")
	var ksp = [Vector3(0, -0.2, 0.6), Vector3(0, 0.3, 0.0), Vector3(0, 0.2, -0.7), Vector3(0, -0.2, -1.05)]
	var krd = [Vector2(0.95, 0.9), Vector2(1.05, 1.1), Vector2(0.9, 0.9), Vector2(0.55, 0.5)]
	_tube(r, r.head, ksp, krd, c, armor, 18, 5)
	var mh = MB.new()
	# vizör: koyu yüz plakası, turuncu parlayan dikey çizgiler
	mh.add_xf("box", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-8)) * Basis.from_scale(Vector3(1.5, 0.85, 0.14)), Vector3(0, 0.12, -1.3)), slit, 1)   # vizör plakası
	for k in 6:
		var x = lerpf(-0.58, 0.58, k / 5.0)
		mh.add("box", Vector3(x, 0.12, -1.4), Vector3(0.13, 0.66, 0.06), Color(1.0, 0.85, 0.15), Vector3(-8, 0, 0))   # sarı çizgi göz
	mh.add_xf("box", Transform3D(Basis.from_scale(Vector3(1.35, 0.14, 0.35)), Vector3(0, 0.5, -1.25)), cl, 1)   # vizör üst kenarı
	# çatal boynuz: tepeden yukarı-öne, ucu Y gibi ikiye ayrılır
	Loft.tube(mh, [Vector3(0, 0.95, -0.3), Vector3(0, 1.8, -0.55), Vector3(0, 2.7, -0.55), Vector3(0, 3.3, -0.3)], [Vector2(0.38, 0.3), Vector2(0.26, 0.22), Vector2(0.14, 0.12), Vector2(0.02, 0.02)], c, 10, 3, true, false)   # tek sivri kafa boynuzu
	for sx in [-1.0, 1.0]:
		BeastRig.claw(mh, Vector3(0.75 * sx, 0.6, 0.1), Vector3(0.5 * sx, 1, 0.3).normalized(), 0.9, 0.2, c)   # yan kask dikenleri
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0.3, -0.3), Vector3(2.2, 2.2, 2.2))
	r.jaw = r._pivot(r.head, Vector3(0, -0.55, -0.7), "cene")
	var mj = MB.new()
	for sx in [-1.0, 1.0]:   # çene kıskaçları
		BeastRig.claw(mj, Vector3(0.3 * sx, 0, -0.2), Vector3(-0.35 * sx, -0.4, -1.0).normalized(), 0.8, 0.14, cd)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.3, -1.2), "agiz")
	# dört ince, çok eklemli böcek kolu: omuz plakalarının altından öne-aşağı uzanır; uçta üç pençe parmak
	for row in 3:   # altı küçük böcek bacağı: göğsün altından iki yana, ince ve eklemli
		for sx in [-1.0, 1.0]:
			var sh = Vector3(0.75 * sx, 0.9 - row * 0.75, -0.5)
			_insect_arm(r, r.chest, sx, sh, Vector3(1.0 * sx, 0.35, -0.55), Vector3(0.35 * sx, -1.0, -0.6), 0.1, cl, cd, 0.35)
	# altı dev yaprak kanat: göğsün arkasından yelpaze gibi açılır
	# kanatlar en altta, karnın ucunda birleşir; oradan çiçek yaprağı gibi yukarı-yana açılır
	var wb = r._pivot(r.hips, Vector3(0, -5.0, 4.6), "kanat_koku")   # karnın/kuyruğun en uç noktası
	for i in 6:
		var sx2 = -1.0 if i < 3 else 1.0
		var k = i % 3
		r._tail(wb, (178.0 - (12.0 + k * 32.0)) * sx2, -(80.0 - k * 25.0), 1, 21.0 - k * 2.0, 0.2, 4.6, Color(0.78, 0.42, 0.16), gr, "wing")
	_particles(wb, Vector3(6.0, 4.0, 3.0), [Color(0.9, 1.0, 0.6, 0.7), Color(0.9, 1.0, 0.6, 0.0)], 40, 0.5, Vector3(0, -1, 0), 2.0, true)
	r._weak(r.head, Vector3(0, 1.4, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.4))


## İnce çok eklemli böcek kolu: üç parça + üç kıvrık pençe parmak (BeastRig kol listesine girer, animasyonlu)
static func _insect_arm(r: BeastRig, parent: Node3D, side: float, sh_pos: Vector3, elbow: Vector3, wrist: Vector3, rad: float, col: Color, joint: Color, claw_len := 0.75) -> void:
	var sh = r._pivot(parent, sh_pos, "omuz")
	var mb = MB.new()
	BeastRig.limb(mb, Vector3.ZERO, elbow, rad * 1.3, rad, col, 8)
	mb.add("sphere", elbow, Vector3.ONE * rad * 2.4, joint, Vector3.ZERO, 8)
	r._mesh(sh, mb)
	var el = r._pivot(sh, elbow, "dirsek")
	var mb2 = MB.new()
	var mid = wrist * 0.5 + Vector3(0, 0.25, 0)
	BeastRig.limb(mb2, Vector3.ZERO, mid, rad, rad * 0.85, col, 8)
	mb2.add("sphere", mid, Vector3.ONE * rad * 2.0, joint, Vector3.ZERO, 8)
	BeastRig.limb(mb2, mid, wrist, rad * 0.85, rad * 0.7, col, 8)
	for f in 3:
		var a = (f - 1) * 0.5
		var d = (wrist - mid).normalized()
		var sd = d.cross(Vector3.UP).normalized()
		var f1 = wrist + (d * 0.55 + sd * sin(a) * 0.35 + Vector3(0, -0.1, 0)) * claw_len / 0.75
		BeastRig.limb(mb2, wrist, f1, rad * 0.6, rad * 0.45, col, 6)
		BeastRig.claw(mb2, f1, (d + Vector3(0, -0.9, 0) + sd * sin(a) * 0.5).normalized(), claw_len, rad * 0.4, joint)
	r._mesh(el, mb2)
	r.arms.append({"sh": sh, "el": el, "side": side})


# ------------------------------------------------------------------ 8 Kuyruk: Gyūki (kambur öküz gövdesi, kıvrık boynuzlar, sekiz dokunaç)
static func _gyuki(r: BeastRig, root: Node3D) -> void:
	# REFERANS (anime): pembemsi mor-kahve; dik duran iri kaslı insansı üst gövde, çok geniş omuzlar, yumruklu kalın kollar;
	# tüm vücutta ağaç damarı gibi dikey kas çizgileri; uzun öküz yüzü, burun ucunda bej bant, kare insan dişleriyle açık ağız,
	# halkalı gözler; kafanın yanından çıkıp yukarı-öne kıvrılan kalın öküz boynuzları; alt gövdede 8 kalın ahtapot kolu, altlarında beyaz halka vantuzlar
	var c = Color(0.68, 0.53, 0.54); var cd = Color(0.55, 0.41, 0.43); var ln = Color(0.4, 0.28, 0.3)
	var band = Color(0.84, 0.72, 0.58); var dk = Color(0.12, 0.06, 0.08); var tooth = Color(0.97, 0.96, 0.92)
	var skin = func(_t: float, _a: float, d: Vector3) -> Color:
		return c if d.y > -0.3 else cd
	r.hips = r._pivot(root, Vector3(0, 3.6, 0), "kalca_kok")
	var hsp = [Vector3(0, -1.2, 0.3), Vector3(0, 0.2, 0.0), Vector3(0, 1.6, -0.2)]
	var hrd = [Vector2(3.0, 2.6), Vector2(3.1, 2.6), Vector2(3.0, 2.4)]
	_tube(r, r.hips, hsp, hrd, c, skin, 28, 6)
	_grain(r, r.hips, hsp, hrd, 30, 81, ln, 0.04)
	r.chest = r._pivot(r.hips, Vector3(0, 2.4, -0.3), "gogus")
	var csp = [Vector3(0, -1.2, 0.4), Vector3(0, 0.2, 0.2), Vector3(0, 1.8, 0.3), Vector3(0, 2.7, -0.6)]
	var crd = [Vector2(3.0, 2.4), Vector2(3.7, 2.7), Vector2(3.5, 2.6), Vector2(1.7, 1.6)]
	_tube(r, r.chest, csp, crd, c, skin, 30, 6)
	_grain(r, r.chest, csp, crd, 46, 82, ln, 0.04)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:   # iri göğüs ve omuz kasları, trapez
		mc.add("sphere", Vector3(1.4 * sx, 0.9, -2.0), Vector3(2.4, 2.0, 1.1), c, Vector3(0, 0, -8 * sx), 14)
		mc.add("sphere", Vector3(3.2 * sx, 1.8, 0.0), Vector3(2.9, 2.6, 2.9), c, Vector3.ZERO, 14)
		mc.add("sphere", Vector3(1.6 * sx, 2.6, 0.5), Vector3(1.8, 1.4, 2.0), c, Vector3(0, 0, 20 * sx), 12)
		for k in 3:   # karın kası sıraları
			mc.add("sphere", Vector3(0.75 * sx, -0.6 - k * 0.85, -2.25), Vector3(1.2, 0.72, 0.5), c, Vector3.ZERO, 10)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3(0, 0.5, 0), Vector3(6.4, 4.6, 4.2))
	# baş: göğsün önünde öne eğik uzun öküz yüzü
	r.head = r._pivot(r.chest, Vector3(0, 3.0, -1.2), "bas")
	r.head.rotation.x = deg_to_rad(-10.0)
	var ksp = [Vector3(0, 0.4, 0.8), Vector3(0, 0.5, 0.0), Vector3(0, 0.1, -0.9), Vector3(0, -0.5, -1.6), Vector3(0, -0.95, -1.95)]
	var krd = [Vector2(1.25, 1.15), Vector2(1.3, 1.2), Vector2(1.05, 0.95), Vector2(0.9, 0.78), Vector2(0.75, 0.55)]
	_tube(r, r.head, ksp, krd, c, skin, 24, 6)
	_grain(r, r.head, ksp, krd, 14, 83, ln, 0.04)
	var mh = MB.new()
	# burun ucundaki bej bant (burun halkası/plaka) + burun delikleri
	var nb = _tube_pt(ksp, krd, 0.93, deg_to_rad(80.0), 0.0)
	var nbc = Loft._cr(ksp[2], ksp[3], ksp[4], ksp[4], 0.75)
	mh.add_xf("torus", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(90.0 - 40.0)) * Basis.from_scale(Vector3(1.9, 2.2, 1.6)), nbc), band, 16)   # burnu saran kalın bej bant
	for sx in [-1.0, 1.0]:
		mh.add("sphere", (nb[0] as Vector3) + Vector3(0.3 * sx, -0.18, -0.5), Vector3(0.22, 0.14, 0.16), dk, Vector3.ZERO, 8)
	# AÇIK AĞIZ: bandın altında geniş koyu boşluk, üstte kare dişler
	var mp = _tube_pt(ksp, krd, 0.86, deg_to_rad(-90.0), 0.0)
	var mo: Vector3 = (mp[0] as Vector3) + Vector3(0, 0.05, -0.5)
	mh.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(1.7, 1.25, 0.8)), mo + Vector3(0, -0.1, -0.1)), Color(0.3, 0.08, 0.12), 14)   # ağız içi
	for i in 8:
		var x = lerpf(-0.62, 0.62, i / 7.0)
		mh.add("box", mo + Vector3(x, 0.3 - absf(x) * 0.12, -0.42 + absf(x) * 0.25), Vector3(0.17, 0.3, 0.12), tooth, Vector3(0, -x * 40.0, 0))
	for sx in [-1.0, 1.0]:
		# halkalı gözler: beyaz, koyu halka, içte pembe/koyu nokta
		var eg = _tube_pt(ksp, krd, 0.45, deg_to_rad(90.0 - 52.0 * sx), 0.0)
		var nrm: Vector3 = Vector3(0.45 * sx, 0.25, -1.0).normalized()
		var ep: Vector3 = (eg[0] as Vector3) + nrm * 0.08
		var eb = Basis.looking_at(-nrm, Vector3.UP)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.46, 0.4, 0.16)), ep), dk, 12)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.38, 0.33, 0.2)), ep + nrm * 0.02), Color(0.98, 0.95, 0.95), 12)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.24, 0.21, 0.22)), ep + nrm * 0.03), Color(0.85, 0.45, 0.55), 12)
		mh.add_xf("sphere", Transform3D(eb * Basis.from_scale(Vector3(0.12, 0.1, 0.24)), ep + nrm * 0.035), dk, 8)
		mh.add_xf("sphere", Transform3D(eb * Basis(Vector3.BACK, deg_to_rad(-14 * sx)) * Basis.from_scale(Vector3(0.65, 0.16, 0.35)), ep + eb.y * 0.32 + nrm * 0.03), cd, 10)   # çatık kaş
		# kalın öküz boynuzu: kafanın yanından dışa, sonra yukarı-öne kıvrılır; boğum halkaları
		var h0 = Vector3(1.0 * sx, 0.75, 0.25)
		var hp = [h0, h0 + Vector3(1.3 * sx, 0.35, 0.15), h0 + Vector3(2.3 * sx, 1.3, -0.15), h0 + Vector3(2.65 * sx, 2.6, -0.8), h0 + Vector3(2.35 * sx, 3.6, -1.5)]
		Loft.tube(mh, hp, [0.62, 0.55, 0.42, 0.25, 0.04], [c, c, c.lightened(0.05), c.lightened(0.1), c.lightened(0.15)], 12, 4, true, false)
		for k in 3:   # boğum halkaları (boynuzun ilk üç parçasında)
			var a0: Vector3 = (hp[k] as Vector3).lerp(hp[k + 1], 0.5)
			var dir = ((hp[k + 1] as Vector3) - (hp[k] as Vector3)).normalized()
			var rr = [0.6, 0.5, 0.36][k]
			mh.add_xf("torus", Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(rr * 2.1, rr * 0.6, rr * 2.1)), a0), cd, 12)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -0.6), Vector3(2.8, 2.6, 3.2))
	r.jaw = r._pivot(r.head, mo + Vector3(0, -0.35, 0.3), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.1, 0.4), Vector3(0, -0.3, -0.35), Vector3(0, -0.25, -0.75)], [Vector2(1.0, 0.4), Vector2(0.85, 0.36), Vector2(0.62, 0.28)], c, 14, 3)
	for i in 7:
		var x = lerpf(-0.55, 0.55, i / 6.0)
		mj.add("box", Vector3(x, 0.08, -0.62 + absf(x) * 0.28), Vector3(0.15, 0.22, 0.1), tooth, Vector3(0, -x * 40.0, 0))
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, mo + Vector3(0, 0, -0.4), "agiz")
	# iri kaslı kollar, büyük yumruklar
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(3.6 * sx, 1.6, 0.0), Vector3(1.3 * sx, -2.6, -0.8), Vector3(-0.2 * sx, -2.6, -1.3), 1.55, 1.25, 1.0, c, c, cd, 4, 1.7, 0.8, 0.2)
	# 8 kalın ahtapot kolu: belden yayılır, yukarı kalkıp kıvrılır; altlarında beyaz halka vantuzlar
	var tb = r._pivot(r.hips, Vector3(0, -1.0, 0.4), "dokunac_koku")
	r.tail_curl = -0.12   # uçlar yukarı-geriye sarmal gibi kıvrılır
	for i in 8:
		var yaw = 360.0 * i / 8.0 + 22.5
		var fa = absf(wrapf(yaw, -180.0, 180.0))   # kuyruklar +Z'ye uzar: 0 = arka, 180 = ön
		r._tail(tb, yaw, 28.0 if fa > 110.0 else lerpf(-30.0, -8.0, fa / 110.0), 11, 25.0 if fa <= 110.0 else 17.0, 1.8, 2.15, c, c.lightened(0.08), "tentacle")   # öndekiler yere yayılır, arkadakiler yukarı kalkar
	r._weak(r.head, Vector3(0, 1.5, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.8))
	r._weak(r.hips, Vector3(0, -1.0, 0))
