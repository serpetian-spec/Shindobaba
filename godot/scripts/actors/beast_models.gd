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
	"isobu": Color(0.22, 0.28, 0.35), "kokuo": Color(0.45, 0.5, 0.65), "saiken": Color(0.45, 0.55, 0.75), "chomei": Color(0.1, 0.15, 0.35), "gyuki": Color(0.22, 0.14, 0.25)}
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
		r.hips.add_child(node)
		node.transform = (root.transform * r.hips.transform).affine_inverse()
		r.set_meta("sf_model", node)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if mi.get_aabb().size.length() > 1.5 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return r


# ------------------------------------------------------------------ ortak parçalar
static func _arm(r: BeastRig, parent: Node3D, side: float, sh_pos: Vector3, elbow: Vector3, wrist: Vector3, r0: float, r1: float, r2: float, col: Color, hand_col: Color, claw_col: Color, fingers := 5, hand_size := 1.0) -> void:
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
		var base = wrist + Vector3(sin(a) * 0.45 * hand_size, -0.25 * hand_size, -0.7 * hand_size - cos(a) * 0.15)
		BeastRig.limb(mb2, wrist + Vector3(sin(a) * 0.3, -0.15, -0.4) * hand_size, base, 0.17 * hand_size, 0.13 * hand_size, hand_col, 6)
		BeastRig.claw(mb2, base, Vector3(sin(a) * 0.2, -0.75, -1.0), 1.0 * hand_size, 0.13 * hand_size, claw_col)
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
	if hoof:
		mb2.add("cyl", ankle + Vector3(0, -0.25, 0), Vector3(r2 * 2.6, 0.55, r2 * 2.6), foot_col, Vector3.ZERO, 10)
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
				mb.add("sphere", pos + fwd * size.z * 0.48, size * Vector3(0.08, 0.5, 0.25), pupil, rot + Vector3(0, 0, ang), 6)
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


## Cel tüy öbeği: uçları sivri birkaç pençe-tüp
static func _tuft(mb: MB, at: Vector3, dir: Vector3, n: int, ln: float, rad: float, col: Color, spread := 0.5) -> void:
	var d = dir.normalized()
	var side = d.cross(Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	for i in n:
		var k = (float(i) / maxf(1.0, n - 1.0) - 0.5) * 2.0
		BeastRig.claw(mb, at + side * k * rad * 1.4, (d + side * k * spread).normalized(), ln * (1.0 - absf(k) * 0.25), rad, col)


# ------------------------------------------------------------------ 9 Kuyruk: Kurama (çömelik tilki, insansı kollar)
static func _kurama(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.88, 0.32, 0.07); var belly = Color(0.97, 0.52, 0.2); var dark = Color(0.06, 0.02, 0.02); var cl = Color(0.97, 0.93, 0.85)
	var fn = _belly(c, belly, c.darkened(0.12))
	r.hips = r._pivot(root, Vector3(0, 4.2, 2.0), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, 0.6, 3.0), Vector3(0, 0.7, 1.0), Vector3(0, 0.8, -1.8), Vector3(0, 1.0, -4.2)], [Vector2(2.7, 2.6), Vector2(3.2, 2.8), Vector2(3.3, 3.0), Vector2(3.9, 3.6)], c, fn)
	var hm = MB.new()
	_tuft(hm, Vector3(0, 3.4, 0.0), Vector3(0, 1, 0.3), 5, 1.6, 0.4, c.darkened(0.05))
	r._mesh(r.hips, hm)
	r._collider(r.hips, Vector3(0, 0, -1.0), Vector3(4.0, 3.4, 6.0))
	r.chest = r._pivot(r.hips, Vector3(0, 1.0, -4.0), "gogus")
	_tube(r, r.chest, [Vector3(0, -0.2, 1.4), Vector3(0, 0.2, -0.4), Vector3(0, 1.3, -2.1), Vector3(0, 2.3, -3.3)], [Vector2(4.3, 4.0), Vector2(4.8, 4.4), Vector2(2.6, 2.4), Vector2(1.9, 1.8)], c, fn)
	var mc = MB.new()
	for i in 11:  # boyun yelesi (cel tüyler)
		var a = lerpf(-2.4, 2.4, i / 10.0)
		BeastRig.claw(mc, Vector3(sin(a) * 2.6, 2.0 + cos(a) * 1.2, -1.2), Vector3(sin(a) * 0.7, 0.35 + cos(a) * 0.4, 0.9), 2.2, 0.6, c.lerp(belly, 0.25 if absf(a) > 1.5 else 0.0))
	for i in 5:  # göğüs tüyü
		BeastRig.claw(mc, Vector3((i - 2) * 0.9, -0.6, -2.6), Vector3((i - 2) * 0.2, -0.8, -0.6), 1.6, 0.5, belly)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(4.6, 4.2, 4.0))
	r.head = r._pivot(r.chest, Vector3(0, 2.7, -3.9), "bas")
	# kafatası + uzun burun (tek pürüzsüz profil)
	_tube(r, r.head, [Vector3(0, 0.3, 1.3), Vector3(0, 0.2, -0.2), Vector3(0, -0.2, -1.6), Vector3(0, -0.45, -3.0), Vector3(0, -0.55, -3.7)],
		[Vector2(1.8, 1.6), Vector2(2.0, 1.75), Vector2(1.35, 1.05), Vector2(0.75, 0.55), Vector2(0.45, 0.35)], c, func(t: float, a: float, _d: Vector3) -> Color:
			# gözlerden kulaklara uzanan siyah maske
			if t > 0.22 and t < 0.6 and sin(a) > 0.12 and sin(a) < 0.8 and absf(cos(a)) > 0.45:
				return dark
			return c.lerp(belly, smoothstep(-0.15, -0.95, sin(a))))
	var mh = MB.new()
	mh.add("sphere", Vector3(0, -0.35, -3.75), Vector3(0.75, 0.5, 0.45), dark, Vector3.ZERO, 10)  # burun
	for sx in [-1.0, 1.0]:
		# kulaklar: dışı turuncu, iç ve uç siyah
		Loft.tube(mh, [Vector3(1.15 * sx, 1.2, 0.3), Vector3(1.45 * sx, 2.8, 0.55), Vector3(1.6 * sx, 4.1, 0.75)], [Vector2(0.95, 0.5), Vector2(0.7, 0.36), Vector2(0.05, 0.05)], [c, c.lerp(dark, 0.4), dark], 12, 3, true, false)
		for k in 4:  # yanak tüyü
			BeastRig.claw(mh, Vector3(1.75 * sx, -0.15 - k * 0.32, -0.3 + k * 0.25), Vector3(sx, -0.25, 0.55), 1.3, 0.34, c)
		_anime_eye(r, r.head, Vector3(0.98 * sx, 0.55, -1.75), Vector3(1.0, 0.45, 0.3), Color(0.98, 0.9, 0.35), Color(0.85, 0.04, 0.02), dark, Vector3(0, 30 * sx, -24 * sx), "slit")
		_brow(mh, Vector3(0.98 * sx, 0.6, -1.75), sx, 1.0, dark)
		_tuft(mh, Vector3(0.9 * sx, 1.2, 0.9), Vector3(0.3 * sx, 0.6, 1.0), 3, 1.6, 0.35, c)
	for i in 6:  # üst dişler
		for sx in [-1.0, 1.0]:
			BeastRig.claw(mh, Vector3(0.62 * sx - sx * i * 0.07, -0.85, -1.2 - i * 0.38), Vector3(0, -1, -0.1), 0.85 - (0.3 if i > 0 else 0.0), 0.14, cl)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -0.8), Vector3(3.2, 2.6, 4.4) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.9, -0.5), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.1, 0.2), Vector3(0, -0.15, -1.4), Vector3(0, -0.05, -2.6)], [Vector2(1.15, 0.45), Vector2(0.85, 0.35), Vector2(0.35, 0.2)], c.lerp(belly, 0.4), 14, 3)
	mj.add("sphere", Vector3(0, 0.12, -1.4), Vector3(1.4, 0.18, 2.4), Color(0.55, 0.08, 0.1), Vector3.ZERO, 10)
	for i in 5:
		for sx in [-1.0, 1.0]:
			BeastRig.claw(mj, Vector3(0.5 * sx - sx * i * 0.06, 0.12, -0.6 - i * 0.42), Vector3(0, 1, 0), 0.4, 0.11, cl)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.7, -3.0), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.4 * sx, 0.3, -0.8), Vector3(0.5 * sx, -2.6, -1.2), Vector3(-0.1 * sx, -2.5, -0.7), 1.15, 0.85, 0.62, c, c.darkened(0.05), dark, 5, 1.25)
		_leg(r, r.hips, sx, Vector3(2.0 * sx, -0.5, 1.0), Vector3(0.3 * sx, -1.6, 1.6), Vector3(0, -1.9, -0.6), 1.35, 0.9, 0.58, c, c.darkened(0.05), dark, false, false, 1.25)
	_tail_fan(r, r.hips, Vector3(0, 1.2, 2.6), 9, 75.0, -38.0, 12.0, 0.7, 1.55, c, Color(1.0, 0.72, 0.4), "fur", 8)
	r._weak(r.head, Vector3(0, 1.8, -0.3))
	r._weak(r.chest, Vector3(0, 2.4, 0.6))
	r._weak(r.hips, Vector3(0, 1.6, 2.0))


# ------------------------------------------------------------------ 1 Kuyruk: Shukaku (dik duran göbekli rakun, lanetli mühür desenleri)
static func _shukaku(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.84, 0.68, 0.45); var mk = Color(0.1, 0.12, 0.32); var cl = Color(0.92, 0.88, 0.75)
	# lanetli mühür deseni: dalgalı bantlar + noktalar
	var curse = func(t: float, a: float, _d: Vector3) -> Color:
		# dalgalı bantlar + sarmal kıvrımlar (lanetli mühür)
		var w = sin(t * 14.0 + sin(a * 2.0 + t * 6.0) * 1.8)
		if absf(w) < 0.2:
			return mk
		var sp = sin(a * 4.0 + t * 30.0) * cos(t * 22.0 - a * 2.0)
		if sp > 0.9:
			return mk
		return c.lerp(c.lightened(0.12), smoothstep(-0.2, -0.9, sin(a)))
	r.hips = r._pivot(root, Vector3(0, 3.0, 0), "kalca_kok")
	# göbekli gövde: dikey tüp (alt geniş)
	_tube(r, r.hips, [Vector3(0, -2.4, 0.2), Vector3(0, -0.6, -0.1), Vector3(0, 1.4, -0.2), Vector3(0, 3.4, 0.0)], [Vector2(2.7, 2.4), Vector2(3.2, 3.0), Vector2(2.9, 2.6), Vector2(2.2, 1.9)], c, curse)
	r._collider(r.hips, Vector3(0, 0.6, 0), Vector3(5.0, 5.2, 4.4))
	r.chest = r._pivot(r.hips, Vector3(0, 3.1, -0.1), "gogus")
	_tube(r, r.chest, [Vector3(0, -0.8, 0), Vector3(0, 0.4, 0), Vector3(0, 1.4, 0)], [Vector2(2.3, 2.0), Vector2(2.2, 1.9), Vector2(1.7, 1.5)], c, curse)
	r.head = r._pivot(r.chest, Vector3(0, 2.6, -0.3), "bas")
	_tube(r, r.head, [Vector3(0, 0.0, 1.4), Vector3(0, 0.2, 0.1), Vector3(0, -0.1, -1.2), Vector3(0, -0.5, -1.9)], [Vector2(1.7, 1.5), Vector2(2.0, 1.75), Vector2(1.6, 1.35), Vector2(0.9, 0.6)], c, curse)
	var mh = MB.new()
	for sx in [-1.0, 1.0]:
		# yuvarlak rakun kulakları (içi koyu)
		Loft.tube(mh, [Vector3(1.4 * sx, 1.4, 0.2), Vector3(1.6 * sx, 2.1, 0.2)], [Vector2(0.75, 0.3), Vector2(0.6, 0.25)], c, 12, 2)
		mh.add("sphere", Vector3(1.6 * sx, 2.05, -0.05), Vector3(0.75, 0.75, 0.2), mk, Vector3.ZERO, 10)
		# göz çevresi koyu halka
		mh.add("sphere", Vector3(0.95 * sx, 0.45, -1.42), Vector3(1.25, 1.15, 0.5), mk, Vector3.ZERO, 12)
		_anime_eye(r, r.head, Vector3(0.95 * sx, 0.45, -1.62), Vector3(1.0, 0.85, 0.3), Color(0.02, 0.02, 0.04), Color(1.0, 0.82, 0.15), Color(0.02, 0.02, 0.02), Vector3(0, 0, -12 * sx), "star")
		_brow(mh, Vector3(0.95 * sx, 0.45, -1.62), sx, 1.0, mk)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(3.4, 3.0, 3.2) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.9, -1.2), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(-1.1, -0.1, -0.5), Vector3(0, -0.35, -0.85), Vector3(1.1, -0.1, -0.5)], [Vector2(0.45, 0.35), Vector2(0.55, 0.4), Vector2(0.45, 0.35)], c, 12, 3)
	mj.add("sphere", Vector3(0, 0.15, -0.75), Vector3(2.2, 0.5, 0.7), Color(0.08, 0.04, 0.05), Vector3.ZERO, 12)
	for i in 9:  # tırtıklı dişler
		BeastRig.claw(mj, Vector3(-1.0 + i * 0.25, 0.2, -0.95), Vector3(0, 1, -0.15), 0.6 + 0.25 * (i % 2), 0.13, cl)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -1.9), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.0 * sx, 0.3, 0), Vector3(0.9 * sx, -1.9, -0.5), Vector3(0.2 * sx, -1.6, -0.8), 0.95, 0.78, 0.62, c, c, cl, 4, 1.0)
		_leg(r, r.hips, sx, Vector3(1.6 * sx, -1.8, 0), Vector3(0.25 * sx, -0.9, -0.2), Vector3(0, -0.6, -0.1), 1.2, 1.0, 0.8, c, c, cl, false, false, 1.1)
	_tail_fan(r, r.hips, Vector3(0, -0.8, 2.4), 1, 0.0, -18.0, 11.0, 1.2, 1.8, c, c.lightened(0.1), "sand", 8)
	_particles(r.hips, Vector3(3.0, 4.0, 2.5), [Color(0.85, 0.7, 0.45, 0.8), Color(0.85, 0.7, 0.45, 0.0)], 60, 1.2, Vector3(0, -3, 0), 2.0)
	r._weak(r.head, Vector3(0, 1.9, -0.2))
	r._weak(r.hips, Vector3(0, 1.0, -3.0))
	r._weak(r.hips, Vector3(0, 0.0, 2.8))


# ------------------------------------------------------------------ 2 Kuyruk: Matatabi (kobalt mavi ve siyah alevden kedi)
static func _matatabi(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.08, 0.18, 0.62); var hi = Color(0.35, 0.62, 1.0); var dk = Color(0.03, 0.03, 0.1); var cl = Color(0.9, 0.95, 1.0)
	# alev deseni: üstten açık mavi, dalgalı siyah alev dilleri
	var flame = func(t: float, a: float, _d: Vector3) -> Color:
		var tongue = sin(t * 18.0 + a * 2.0) * 0.5 + sin(t * 7.0 - a * 3.0) * 0.5
		var col = c.lerp(hi, smoothstep(0.2, 1.0, sin(a)))
		if tongue > 0.55 and sin(a) < 0.5:
			col = col.lerp(dk, 0.75)
		return col
	r.hips = r._pivot(root, Vector3(0, 4.6, 2.4), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, 0.2, 2.6), Vector3(0, 0.0, 0.6), Vector3(0, -0.2, -1.8), Vector3(0, 0.3, -4.4)], [Vector2(2.4, 2.3), Vector2(2.9, 2.7), Vector2(2.6, 2.4), Vector2(2.9, 2.8)], c, flame)
	r._collider(r.hips, Vector3(0, 0, -1.2), Vector3(2.8, 2.6, 6.0))
	r.chest = r._pivot(r.hips, Vector3(0, 0.4, -4.4), "gogus")
	_tube(r, r.chest, [Vector3(0, -0.2, 0.8), Vector3(0, 0.1, -0.6), Vector3(0, 1.3, -1.6), Vector3(0, 2.2, -2.2)], [Vector2(2.9, 2.8), Vector2(3.0, 2.9), Vector2(1.6, 1.5), Vector2(1.3, 1.2)], c, flame)
	r.head = r._pivot(r.chest, Vector3(0, 2.5, -2.4), "bas")
	_tube(r, r.head, [Vector3(0, 0.2, 1.1), Vector3(0, 0.1, -0.2), Vector3(0, -0.3, -1.3), Vector3(0, -0.45, -1.75)], [Vector2(1.5, 1.3), Vector2(1.6, 1.35), Vector2(1.0, 0.75), Vector2(0.55, 0.4)], c, flame)
	var mh = MB.new()
	mh.add("sphere", Vector3(0, -0.25, -1.85), Vector3(0.45, 0.32, 0.3), dk, Vector3.ZERO, 8)
	for sx in [-1.0, 1.0]:
		Loft.tube(mh, [Vector3(0.95 * sx, 1.0, 0.2), Vector3(1.15 * sx, 2.2, 0.35), Vector3(1.25 * sx, 3.0, 0.45)], [Vector2(0.75, 0.38), Vector2(0.5, 0.25), Vector2(0.04, 0.04)], [c, hi, hi], 12, 3, true, false)
		mh.add("sphere", Vector3(1.1 * sx, 1.9, 0.1), Vector3(0.6, 1.2, 0.15), dk, Vector3(0, 0, -10 * sx), 8)
		for k in 3:  # bıyık
			mh.add("box", Vector3(1.0 * sx, -0.5 + k * 0.12, -1.35), Vector3(1.8, 0.04, 0.04), cl, Vector3(0, -15 * sx, (k - 1) * 8 * sx))
	# heterokrom gözler: sağ sarı, sol yeşil; bebeksiz
	_anime_eye(r, r.head, Vector3(-0.72, 0.32, -1.15), Vector3(0.62, 0.4, 0.26), Color(1.0, 0.9, 0.3), Color(1.0, 0.9, 0.25), Color(1.0, 0.9, 0.25), Vector3(0, -15, 10), "none")
	_anime_eye(r, r.head, Vector3(0.72, 0.32, -1.15), Vector3(0.62, 0.4, 0.26), Color(0.4, 1.0, 0.45), Color(0.35, 1.0, 0.45), Color(0.35, 1.0, 0.45), Vector3(0, 15, -10), "none")
	for sx in [-1.0, 1.0]:
		_brow(mh, Vector3(0.72 * sx, 0.32, -1.15), sx, 0.75, dk)
	for i in 6:  # basta alev dilleri
		BeastRig.claw(mh, Vector3((i - 2.5) * 0.4, 1.1, 0.2 + absf(i - 2.5) * 0.2), Vector3((i - 2.5) * 0.2, 1, 0.5), 1.4, 0.3, hi)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(2.6, 2.2, 2.6) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.8, -0.6), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.1, 0.1), Vector3(0, -0.15, -0.8)], [Vector2(0.9, 0.35), Vector2(0.5, 0.25)], c, 12, 2)
	for sx in [-1.0, 1.0]:
		BeastRig.claw(mj, Vector3(0.38 * sx, 0.35, -1.0), Vector3(0, -1, 0), 0.85, 0.12, cl)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.6, -1.7), "agiz")
	for sx in [-1.0, 1.0]:
		_leg(r, r.chest, sx, Vector3(1.4 * sx, -0.6, -0.3), Vector3(0.2 * sx, -2.0, -0.2), Vector3(0, -2.2, -0.1), 0.9, 0.62, 0.45, c, c, cl, true, false, 0.95)
		_leg(r, r.hips, sx, Vector3(1.4 * sx, -0.5, 0.8), Vector3(0.2 * sx, -1.8, 1.2), Vector3(0, -2.1, -0.5), 1.05, 0.66, 0.45, c, c, cl, false, false, 0.95)
	_tail_fan(r, r.hips, Vector3(0, 0.9, 2.4), 2, 22.0, -35.0, 12.0, 0.5, 1.0, c, hi, "flame", 8)
	_particles(r.hips, Vector3(2.4, 2.0, 4.0), [Color(0.4, 0.6, 1.0, 0.95), Color(0.02, 0.02, 0.15, 0.0)], 160, 2.0, Vector3(0, 7, 0), 1.0, true)
	_particles(r.chest, Vector3(2.0, 2.5, 2.0), [Color(0.4, 0.6, 1.0, 0.95), Color(0.02, 0.02, 0.15, 0.0)], 90, 1.8, Vector3(0, 7, 0), 0.9, true)
	_particles(r.head, Vector3(1.2, 1.0, 1.2), [Color(0.5, 0.7, 1.0, 0.9), Color(0.02, 0.02, 0.15, 0.0)], 40, 1.2, Vector3(0, 5, 0), 0.7, true)
	r._weak(r.head, Vector3(0, 1.45, -0.1))
	r._weak(r.hips, Vector3(0, 2.0, 0.0))


# ------------------------------------------------------------------ 3 Kuyruk: Isobu (dikenli gri-yeşil kabuk, kırmızı et, tek açık göz)
static func _isobu(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var sh = Color(0.5, 0.58, 0.52); var flesh = Color(0.72, 0.22, 0.2); var sp = Color(0.72, 0.75, 0.66)
	# kabuk: plaka deseni (altıgen benzeri koyu çizgiler)
	var plates = func(t: float, a: float, _d: Vector3) -> Color:
		var u = a * 3.0; var v = t * 9.0
		var lines = minf(absf(sin(u * 1.4 + floor(v) * 0.7)), absf(sin(v * PI)))
		return sh.darkened(0.3) if lines < 0.12 else sh.lerp(sh.lightened(0.1), smoothstep(0.3, 1.0, sin(a)))
	r.hips = r._pivot(root, Vector3(0, 3.0, 0.8), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3(0, -0.4, 0), Vector3(7.2, 3.0, 8.2), flesh, Vector3.ZERO, 18)  # kabuk altı et
	Loft.tube(mb, [Vector3(0, -0.2, 4.6), Vector3(0, 1.1, 2.0), Vector3(0, 1.5, -1.0), Vector3(0, 0.9, -4.0)], [Vector2(2.6, 1.4), Vector2(4.4, 2.9), Vector2(4.6, 3.1), Vector2(3.4, 2.0)], sh, 22, 4, true, true, plates)
	for ring in [[1.0, 12, 3.6], [2.0, 9, 2.6], [2.8, 6, 1.4], [3.4, 1, 0.0]]:  # kabuk dikenleri
		for i in ring[1]:
			var a = TAU * i / ring[1] + ring[0]
			var p = Vector3(sin(a) * ring[2], ring[0] + 1.0, cos(a) * ring[2] * 1.15)
			BeastRig.claw(mb, p, (p - Vector3(0, -2, 0)).normalized(), 2.0, 0.5, sp)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 1.2, 0), Vector3(7.6, 3.6, 8.6))
	r.chest = r._pivot(r.hips, Vector3(0, -0.2, -4.2), "gogus")
	_tube(r, r.chest, [Vector3(0, 0, 1.2), Vector3(0, 0.2, -0.6)], [Vector2(2.4, 1.6), Vector2(2.0, 1.5)], flesh)
	r.head = r._pivot(r.chest, Vector3(0, 0.6, -1.8), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.6, 2.0, 2.6), flesh, Vector3.ZERO, 16)
	# büyük alın plakası ve dikenleri
	Loft.tube(mh, [Vector3(0, 0.9, 1.0), Vector3(0, 1.1, -0.4), Vector3(0, 0.7, -1.5)], [Vector2(1.9, 0.9), Vector2(2.0, 1.0), Vector2(1.6, 0.5)], sh, 18, 3, true, true, plates)
	for i in 6:
		BeastRig.claw(mh, Vector3(-1.4 + i * 0.56, 1.6, -0.5), Vector3((i - 2.5) * 0.15, 1, -0.4), 1.3, 0.32, sp)
	# tek açık kırmızı göz, sağ göz kapalı
	_anime_eye(r, r.head, Vector3(-0.65, 0.2, -1.25), Vector3(0.55, 0.42, 0.22), Color(0.95, 0.1, 0.08), Color(1.0, 0.85, 0.15), Color(0.3, 0.0, 0.0), Vector3.ZERO, "dot")
	mh.add("box", Vector3(0.65, 0.2, -1.28), Vector3(0.6, 0.07, 0.1), Color(0.15, 0.02, 0.02))
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.6, -0.4), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.4, 0.6), Vector3(0, -0.6, -0.6), Vector3(0, -0.4, -1.4)], [Vector2(1.6, 0.6), Vector2(1.5, 0.65), Vector2(1.0, 0.35)], sh, 16, 3, true, true, plates)
	for i in 5:
		BeastRig.claw(mj, Vector3(-1.0 + i * 0.5, -0.9, -1.0), Vector3(0, -1, -0.6), 1.0, 0.24, sp)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.3, -1.6), "agiz")
	for sx in [-1.0, 1.0]:  # insan benzeri iki kol (kırmızı et, gri dirsek plakası)
		_arm(r, r.chest, sx, Vector3(2.8 * sx, 0.2, 0.3), Vector3(1.2 * sx, -1.1, -1.2), Vector3(0, -1.2, -1.0), 0.9, 0.78, 0.62, flesh, flesh.darkened(0.1), sp, 5, 1.15)
	_tail_fan(r, r.hips, Vector3(0, 0.0, 4.6), 3, 30.0, -12.0, 11.0, 0.75, 1.05, sh, sh.lightened(0.15), "shrimp", 10)
	r._weak(r.hips, Vector3(0, 4.6, 0.0))
	r._weak(r.head, Vector3(0, 1.8, -0.1))


# ------------------------------------------------------------------ 4 Kuyruk: Son Gokū (kırmızı kürklü, yeşil tenli goril, boynuz taç)
static func _son_goku(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.66, 0.11, 0.09); var g = Color(0.36, 0.55, 0.38); var dk = Color(0.12, 0.06, 0.05); var cl = Color(0.95, 0.9, 0.72)
	var fur = func(t: float, a: float, d: Vector3) -> Color:
		var front = d.z < -0.35 and sin(a) < 0.7  # göğüs/karın yeşil ten
		return g if front else c.lerp(c.darkened(0.12), 0.5 + 0.5 * sin(t * 20.0 + a * 4.0))
	r.hips = r._pivot(root, Vector3(0, 3.0, 0.6), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, -1.0, 0.4), Vector3(0, 0.4, 0), Vector3(0, 1.8, -0.4)], [Vector2(2.2, 1.9), Vector2(2.4, 2.0), Vector2(2.5, 2.1)], c)
	r.chest = r._pivot(r.hips, Vector3(0, 2.7, -0.6), "gogus")
	_tube(r, r.chest, [Vector3(0, -1.6, 0.3), Vector3(0, 0.0, 0), Vector3(0, 1.4, -0.2), Vector3(0, 2.2, -0.8)], [Vector2(2.6, 2.0), Vector2(3.4, 2.3), Vector2(3.2, 2.2), Vector2(1.6, 1.4)], c, fur)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:  # omuz kası + kürk püskülleri
		mc.add("sphere", Vector3(2.6 * sx, 1.2, 0), Vector3(2.5, 2.1, 2.5), c, Vector3.ZERO, 14)
		_tuft(mc, Vector3(2.9 * sx, 2.0, 0.4), Vector3(sx * 0.4, 1, 0.3), 4, 1.4, 0.4, c.darkened(0.1))
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(5.2, 4.0, 3.6))
	r.head = r._pivot(r.chest, Vector3(0, 2.7, -1.6), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.8, 2.7, 2.6), c, Vector3.ZERO, 16)
	Loft.tube(mh, [Vector3(0, 0.2, -0.6), Vector3(0, -0.2, -1.1)], [Vector2(1.1, 1.0), Vector2(1.0, 0.9)], g, 16, 2)  # yeşil yüz
	mh.add("sphere", Vector3(0, 0.55, -1.15), Vector3(2.0, 0.45, 0.6), g.darkened(0.15), Vector3.ZERO, 10)  # kaş çıkıntısı
	for sx in [-1.0, 1.0]:  # yukarı kıvrılan taç boynuzlar (uçları koyu)
		Loft.tube(mh, [Vector3(0.6 * sx, 1.1, -0.4), Vector3(1.1 * sx, 2.4, -0.2), Vector3(1.3 * sx, 3.6, -0.6), Vector3(1.1 * sx, 4.5, -1.3)], [0.36, 0.3, 0.2, 0.03], [cl, cl, cl.lerp(dk, 0.5), dk], 10, 3, true, false)
		_anime_eye(r, r.head, Vector3(0.55 * sx, 0.3, -1.42), Vector3(0.58, 0.3, 0.2), Color(1.0, 0.88, 0.2), Color(1.0, 0.88, 0.2), Color(1, 1, 1), Vector3(0, 0, -15 * sx), "dot")
		_brow(mh, Vector3(0.55 * sx, 0.3, -1.42), sx, 0.7, dk)
		BeastRig.claw(mh, Vector3(0.48 * sx, -0.95, -1.3), Vector3(0, -1, -0.2), 1.3, 0.22, cl)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(2.6, 2.6, 2.6) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.8, -0.8), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.2, 0.0), Vector3(0, -0.25, -0.8)], [Vector2(1.0, 0.45), Vector2(0.9, 0.45)], g, 14, 2)
	mj.add("torus", Vector3(0, 0.05, -0.95), Vector3(1.1, 0.7, 1.1), dk, Vector3(80, 0, 0), 14)  # volkan ağız
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.8, -1.8), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(3.2 * sx, 0.9, 0.1), Vector3(1.0 * sx, -2.8, -0.6), Vector3(0, -2.6, -1.0), 1.35, 1.1, 0.9, c, g, dk, 5, 1.45)
		_leg(r, r.hips, sx, Vector3(1.5 * sx, -1.2, 0.2), Vector3(0.6 * sx, -1.2, -0.4), Vector3(0, -1.0, 0.1), 1.3, 1.05, 0.8, c, g, dk, false, false, 1.25)
	_tail_fan(r, r.hips, Vector3(0, 0.4, 2.0), 4, 45.0, -30.0, 11.0, 0.6, 0.95, c, c.darkened(0.2), "spike", 8)
	_particles(r.jaw, Vector3(0.4, 0.3, 0.4), [Color(1.0, 0.5, 0.1, 0.9), Color(0.3, 0.05, 0.0, 0.0)], 30, 0.7, Vector3(0, 2, -2), 0.8, true)
	r._weak(r.head, Vector3(0, 1.45, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.6))


# ------------------------------------------------------------------ 5 Kuyruk: Kokuō (yunus başlı beyaz at, kırmızı göz altı, buhar)
static func _kokuo(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.96, 0.95, 0.93); var tan = Color(0.84, 0.68, 0.44); var dk = Color(0.12, 0.3, 0.32); var red = Color(0.85, 0.15, 0.15)
	var body = _belly(c, Color(0.88, 0.88, 0.9))
	r.hips = r._pivot(root, Vector3(0, 5.2, 2.6), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, 0.2, 2.4), Vector3(0, 0.0, 0.4), Vector3(0, -0.1, -2.2), Vector3(0, 0.3, -4.4)], [Vector2(2.4, 2.4), Vector2(2.7, 2.7), Vector2(2.5, 2.5), Vector2(2.7, 2.8)], c, body)
	r._collider(r.hips, Vector3(0, 0, -1.0), Vector3(2.8, 2.8, 6.0))
	r.chest = r._pivot(r.hips, Vector3(0, 0.3, -4.4), "gogus")
	_tube(r, r.chest, [Vector3(0, -0.4, 0.8), Vector3(0, 0.2, -0.6), Vector3(0, 1.8, -1.6), Vector3(0, 3.3, -2.4)], [Vector2(2.6, 2.8), Vector2(2.7, 2.9), Vector2(1.5, 1.6), Vector2(1.1, 1.2)], c, body)
	var mc = MB.new()
	for i in 6:  # ten rengi yele
		_tuft(mc, Vector3(0, 1.6 + i * 0.35, -1.0 - i * 0.28), Vector3(0, 0.6, 1.0), 2, 1.4, 0.3, tan)
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 3.6, -2.7), "bas")
	# yunus başı: yuvarlak alın + uzun gaga
	_tube(r, r.head, [Vector3(0, 0.1, 1.2), Vector3(0, 0.35, -0.2), Vector3(0, -0.2, -1.4), Vector3(0, -0.5, -2.8), Vector3(0, -0.55, -3.5)],
		[Vector2(1.1, 1.0), Vector2(1.25, 1.2), Vector2(1.0, 0.85), Vector2(0.55, 0.42), Vector2(0.38, 0.3)], c, body)
	var mh = MB.new()
	for sx in [-1.0, 1.0]:  # iki uzun boynuz
		Loft.tube(mh, [Vector3(0.5 * sx, 1.1, -0.1), Vector3(0.95 * sx, 2.4, -1.0), Vector3(1.3 * sx, 3.2, -2.6)], [0.3, 0.22, 0.03], [c, tan.lerp(c, 0.3), tan], 10, 3, true, false)
		_anime_eye(r, r.head, Vector3(0.95 * sx, 0.3, -0.85), Vector3(0.55, 0.3, 0.2), Color(0.95, 0.95, 0.95), dk, Color(0.02, 0.05, 0.05), Vector3(0, 30 * sx, -14 * sx), "dot")
		_brow(mh, Vector3(0.95 * sx, 0.3, -0.85), sx, 0.6, c.darkened(0.3))
		Loft.tube(mh, [Vector3(0.85 * sx, -0.05, -0.7), Vector3(1.0 * sx, -0.25, -0.95)], [Vector2(0.18, 0.08), Vector2(0.12, 0.05)], red, 8, 2)  # göz altı kırmızı işaret
	for i in 3:  # önde üç kısa boynuz
		BeastRig.claw(mh, Vector3((i - 1) * 0.38, 1.1, -0.9), Vector3((i - 1) * 0.25, 1.0, -0.7), 0.8, 0.16, tan)
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.75, -1.0), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.05, 0.0), Vector3(0, -0.1, -1.4), Vector3(0, -0.05, -2.3)], [Vector2(0.75, 0.3), Vector2(0.5, 0.25), Vector2(0.3, 0.16)], c.darkened(0.04), 12, 3)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.5, -3.4), "agiz")
	for sx in [-1.0, 1.0]:
		_leg(r, r.chest, sx, Vector3(1.3 * sx, -0.8, -0.2), Vector3(0, -2.4, 0.2), Vector3(0, -2.4, -0.2), 0.85, 0.52, 0.42, c, tan, tan, true, true)
		_leg(r, r.hips, sx, Vector3(1.3 * sx, -0.7, 0.6), Vector3(0, -2.2, 1.0), Vector3(0, -2.6, -0.6), 1.0, 0.58, 0.42, c, tan, tan, false, true)
	_tail_fan(r, r.hips, Vector3(0, 0.9, 2.2), 5, 50.0, -40.0, 9.5, 0.5, 1.05, c, tan, "fur", 7)
	_particles(r.hips, Vector3(2.0, 2.0, 3.5), [Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)], 60, 2.5, Vector3(0, 4, 0), 2.0)
	r._weak(r.head, Vector3(0, 1.3, 0.0))
	r._weak(r.hips, Vector3(0, 2.0, -1.0))


# ------------------------------------------------------------------ 6 Kuyruk: Saiken (açık mavimsi beyaz dev sümüklü böcek)
static func _saiken(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.9, 0.95, 1.0); var tint = Color(0.72, 0.84, 0.98); var dk = Color(0.32, 0.38, 0.55)
	var slime = func(t: float, a: float, _d: Vector3) -> Color:
		var bands = 0.5 + 0.5 * sin(t * 30.0)
		return c.lerp(tint, smoothstep(0.1, -0.9, sin(a)) * 0.7 + bands * 0.12)
	r.hips = r._pivot(root, Vector3(0, 1.4, 0.5), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, -0.4, 3.6), Vector3(0, 0.1, 1.2), Vector3(0, 0.3, -1.8), Vector3(0, 0.6, -3.2)], [Vector2(2.6, 1.1), Vector2(3.4, 1.6), Vector2(3.2, 1.7), Vector2(2.6, 1.7)], c, slime)
	r._collider(r.hips, Vector3.ZERO, Vector3(5.0, 2.6, 6.4))
	r.chest = r._pivot(r.hips, Vector3(0, 0.8, -1.4), "gogus")
	# dik duran gövde: alttan üste incelen pürüzsüz sütun
	_tube(r, r.chest, [Vector3(0, -0.6, 0.4), Vector3(0, 1.8, 0.1), Vector3(0, 4.4, -0.3), Vector3(0, 6.2, -0.4)], [Vector2(3.0, 2.6), Vector2(2.6, 2.3), Vector2(2.2, 2.0), Vector2(1.7, 1.6)], c, slime)
	r._collider(r.chest, Vector3(0, 2.5, 0), Vector3(3.8, 6.0, 3.4))
	r.head = r._pivot(r.chest, Vector3(0, 6.4, -0.4), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(3.2, 2.4, 3.0), c, Vector3.ZERO, 18)
	for sx in [-1.0, 1.0]:  # göz sapları
		Loft.tube(mh, [Vector3(0.7 * sx, 0.7, -0.4), Vector3(1.1 * sx, 1.9, -0.6), Vector3(1.35 * sx, 3.0, -1.0)], [0.4, 0.32, 0.3], c, 12, 3)
		mh.add("sphere", Vector3(1.38 * sx, 3.2, -1.05), Vector3(0.8, 0.8, 0.8), c, Vector3.ZERO, 12)
		_anime_eye(r, r.head, Vector3(1.38 * sx, 3.2, -1.38), Vector3(0.42, 0.42, 0.22), Color(0.12, 0.12, 0.2), Color(0.12, 0.12, 0.2), Color(0.9, 0.9, 1.0), Vector3.ZERO, "dot")
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.4, -1.3), "cene")
	var mj = MB.new()
	mj.add("torus", Vector3(0, 0, -0.1), Vector3(1.3, 0.8, 1.3), dk, Vector3(90, 0, 0), 16)
	mj.add("sphere", Vector3(0, 0, -0.05), Vector3(0.9, 0.9, 0.3), Color(0.05, 0.05, 0.08), Vector3.ZERO, 12)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.4, -1.6), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.0 * sx, 2.6, -0.4), Vector3(0.9 * sx, -1.0, -0.6), Vector3(0.1 * sx, -0.9, -0.5), 0.7, 0.55, 0.45, c, c, tint, 3, 0.85)
	_tail_fan(r, r.hips, Vector3(0, 0.4, 3.6), 6, 60.0, -25.0, 9.5, 0.65, 1.05, c, tint, "slug", 7)
	_particles(r.hips, Vector3(2.6, 0.5, 3.4), [Color(0.85, 0.95, 1.0, 0.6), Color(0.85, 0.95, 1.0, 0.0)], 30, 1.0, Vector3(0, -2, 0), 1.5)
	r._weak(r.head, Vector3(0, 1.3, -0.1))
	r._weak(r.chest, Vector3(0, 3.0, 1.9))


# ------------------------------------------------------------------ 7 Kuyruk: Chōmei (mavi zırhlı gergedan böceği, turuncu kanatlar)
static func _chomei(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.12, 0.32, 0.7); var gr = Color(0.3, 0.68, 0.3); var orn = Color(1.0, 0.55, 0.12)
	var armor = func(t: float, a: float, _d: Vector3) -> Color:
		var seams = absf(sin(t * PI * 6.0))
		var col = c.lerp(c.lightened(0.2), smoothstep(0.3, 1.0, sin(a)))
		return col.darkened(0.35) if seams < 0.12 else col
	r.hips = r._pivot(root, Vector3(0, 3.6, 2.0), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, 0.2, 3.4), Vector3(0, 0.6, 1.0), Vector3(0, 0.6, -1.8), Vector3(0, 0.3, -3.6)], [Vector2(1.8, 1.4), Vector2(2.2, 1.7), Vector2(2.1, 1.6), Vector2(1.9, 1.4)], c, armor)
	r._collider(r.hips, Vector3.ZERO, Vector3(3.6, 2.6, 5.6))
	r.chest = r._pivot(r.hips, Vector3(0, 0.4, -4.0), "gogus")
	_tube(r, r.chest, [Vector3(0, 0, 0.8), Vector3(0, 0.3, -0.6), Vector3(0, 0.1, -1.6)], [Vector2(2.0, 1.5), Vector2(2.1, 1.6), Vector2(1.5, 1.2)], c, armor)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:  # dikenli omuzlar + yarık sıraları
		for k in 3:
			BeastRig.claw(mc, Vector3(1.8 * sx, 0.9 - k * 0.3, -0.5 + k * 0.45), Vector3(sx, 0.5, 0), 1.2, 0.28, c.lightened(0.15))
		for k in 4:
			mc.add("box", Vector3(1.85 * sx, 0.2, -0.9 + k * 0.4), Vector3(0.08, 0.6, 0.12), Color(0.05, 0.1, 0.2))
	# iki bölümlü büyük sırt boynuzu
	Loft.tube(mc, [Vector3(0, 1.3, 0.4), Vector3(0, 3.0, -0.2), Vector3(0, 4.2, -1.4), Vector3(0, 4.6, -2.6)], [Vector2(0.75, 0.5), Vector2(0.55, 0.4), Vector2(0.35, 0.28), Vector2(0.05, 0.05)], c.darkened(0.1), 12, 3, true, false)
	BeastRig.claw(mc, Vector3(0, 3.3, -0.4), Vector3(0, 1.0, 0.4), 1.4, 0.3, c.darkened(0.1))
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 0.3, -2.1), "bas")
	var mh = MB.new()
	# kask: göz kısmını örten kubbe; içinden turuncu parıltı
	Loft.tube(mh, [Vector3(0, 0.3, 0.8), Vector3(0, 0.35, -0.4), Vector3(0, 0.1, -1.2)], [Vector2(1.3, 1.1), Vector2(1.35, 1.1), Vector2(1.0, 0.7)], c, 16, 3, true, true, armor)
	mh.add("box", Vector3(0, 0.1, -1.18), Vector3(1.6, 0.22, 0.12), orn)
	for sx in [-1.0, 1.0]:  # üç parçalı kıskaç
		BeastRig.claw(mh, Vector3(0.6 * sx, -0.5, -1.0), Vector3(-0.45 * sx, -0.3, -1.0), 1.1, 0.2, gr)
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.6, -0.8), "cene")
	var mj = MB.new()
	BeastRig.claw(mj, Vector3(0, 0, -0.3), Vector3(0, -0.2, -1.0), 1.0, 0.24, gr)
	for i in 4:
		BeastRig.claw(mj, Vector3(-0.3 + i * 0.2, 0.1, -0.5), Vector3(0, 1, -0.2), 0.3, 0.08, Color(0.95, 0.95, 0.9))
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.3, -1.4), "agiz")
	for sx in [-1.0, 1.0]:  # altı zırhlı bacak, uçları yeşil
		_leg(r, r.chest, sx, Vector3(1.6 * sx, -0.6, -0.4), Vector3(1.6 * sx, -0.6, -0.6), Vector3(0.2 * sx, -2.6, -0.4), 0.45, 0.32, 0.22, c, gr, gr, true, true)
		_leg(r, r.hips, sx, Vector3(1.7 * sx, -0.8, -2.0), Vector3(1.8 * sx, -0.4, 0.0), Vector3(0.2 * sx, -2.6, 0.2), 0.46, 0.32, 0.22, c, gr, gr, false, true)
		_leg(r, r.hips, sx, Vector3(1.7 * sx, -0.8, 0.6), Vector3(1.8 * sx, -0.4, 0.6), Vector3(0.2 * sx, -2.6, 0.6), 0.46, 0.32, 0.22, c, gr, gr, true, true)
	var wb = r._pivot(r.hips, Vector3(0, 1.6, 0.8), "kanat_koku")
	for i in 6:
		var sx2 = -1.0 if i < 3 else 1.0
		var k = i % 3
		r._tail(wb, (60.0 + k * 22.0) * sx2, -20.0 - k * 10.0, 1, 8.0 - k * 0.8, 0.2, 1.7, orn, orn, "wing")
	r._tail(r.hips, 0.0, -5.0, 6, 6.5, 0.55, 0.65, c, gr, "shrimp")
	_particles(wb, Vector3(5.0, 1.5, 3.0), [Color(0.9, 1.0, 0.6, 0.7), Color(0.9, 1.0, 0.6, 0.0)], 40, 0.5, Vector3(0, -1, 0), 2.0, true)
	r._weak(r.head, Vector3(0, 1.3, 0.0))
	r._weak(r.hips, Vector3(0, 2.0, 1.0))


# ------------------------------------------------------------------ 8 Kuyruk: Gyūki (kambur öküz gövdesi, kıvrık boynuzlar, sekiz dokunaç)
static func _gyuki(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.46, 0.3, 0.33); var hn = Color(0.9, 0.85, 0.74); var dk = Color(0.12, 0.08, 0.1)
	var skin = _belly(c, c.lightened(0.12), c.darkened(0.15))
	r.hips = r._pivot(root, Vector3(0, 3.4, 0), "kalca_kok")
	_tube(r, r.hips, [Vector3(0, -0.8, 0.2), Vector3(0, 0.4, 0), Vector3(0, 1.6, -0.3)], [Vector2(2.2, 1.9), Vector2(2.3, 2.0), Vector2(2.4, 2.1)], c, skin)
	r.chest = r._pivot(r.hips, Vector3(0, 2.6, -0.3), "gogus")
	_tube(r, r.chest, [Vector3(0, -1.4, 0.4), Vector3(0, 0.0, 0.3), Vector3(0, 1.6, 0.6), Vector3(0, 2.2, -0.6)], [Vector2(2.5, 2.0), Vector2(3.2, 2.3), Vector2(3.1, 2.4), Vector2(1.6, 1.5)], c, skin)
	var mc = MB.new()
	for sx in [-1.0, 1.0]:
		mc.add("sphere", Vector3(1.2 * sx, 0.2, -1.6), Vector3(2.0, 1.8, 1.0), c.lightened(0.05), Vector3.ZERO, 12)
		mc.add("sphere", Vector3(2.5 * sx, 1.3, 0), Vector3(2.4, 2.2, 2.4), c, Vector3.ZERO, 14)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(5.0, 4.0, 3.6))
	r.head = r._pivot(r.chest, Vector3(0, 2.6, -1.4), "bas")
	_tube(r, r.head, [Vector3(0, 0.3, 0.9), Vector3(0, 0.2, -0.3), Vector3(0, -0.5, -1.3), Vector3(0, -0.7, -1.8)], [Vector2(1.3, 1.25), Vector2(1.35, 1.25), Vector2(1.0, 0.8), Vector2(0.75, 0.55)], c, skin)
	var mh = MB.new()
	for sx in [-1.0, 1.0]:
		for h in 2:  # dört kıvrık koç boynuzu (pürüzsüz sarmal)
			var pts = []; var rads = []; var cols = []
			for k in 10:
				var a = k * 0.62 + h * 0.5
				var rr = 1.4 + k * 0.2
				pts.append(Vector3(sx * (0.8 + rr * 0.6 * (1.0 - cos(a)) * 0.6 + k * 0.08), 0.8 + h * 0.3 + rr * sin(a) * 0.55, -0.2 + h * 0.4 + rr * 0.25 * cos(a * 0.7) * (1 if h == 0 else -1)))
				rads.append(0.42 - k * 0.035)
				cols.append(hn.lerp(hn.darkened(0.35), k / 9.0))
			Loft.tube(mh, pts, rads, cols, 10, 3, true, true)
		_anime_eye(r, r.head, Vector3(0.6 * sx, 0.3, -1.2), Vector3(0.6, 0.28, 0.2), Color(0.98, 0.95, 0.85), Color(0.95, 0.8, 0.3), Color(0.05, 0.02, 0.02), Vector3(0, 15 * sx, -18 * sx), "slit")
		_brow(mh, Vector3(0.6 * sx, 0.3, -1.2), sx, 0.7, c.darkened(0.4))
	mh.add("sphere", Vector3(0, -0.45, -1.85), Vector3(0.9, 0.5, 0.3), dk, Vector3.ZERO, 10)  # burun
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(2.4, 2.4, 2.6) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -1.0, -1.0), "cene")
	var mj = MB.new()
	Loft.tube(mj, [Vector3(0, -0.15, 0.1), Vector3(0, -0.2, -0.8)], [Vector2(1.0, 0.4), Vector2(0.8, 0.35)], c, 14, 2)
	for i in 6:
		mj.add("box", Vector3(-0.6 + i * 0.24, 0.15, -0.85), Vector3(0.2, 0.28, 0.12), hn)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -1.9), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(3.0 * sx, 0.9, 0.1), Vector3(0.9 * sx, -2.4, -0.4), Vector3(0, -2.2, -1.0), 1.25, 1.0, 0.82, c, c, dk, 5, 1.35)
	for a in r.arms:  # dirsek dikenleri
		var spm = MB.new()
		BeastRig.claw(spm, Vector3(0, 0, 0.6), Vector3(0, 0.2, 1.0), 1.2, 0.3, hn)
		r._mesh(a["el"], spm)
	var tb = r._pivot(r.hips, Vector3(0, -0.8, 0), "dokunac_koku")
	for i in 8:
		var yaw = 360.0 * i / 8.0 + 22.5
		r._tail(tb, yaw, 25.0, 9, 9.5, 0.8, 0.9, c, c.lightened(0.15), "tentacle")
	r._weak(r.head, Vector3(0, 1.5, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.6))
	r._weak(r.hips, Vector3(0, -1.0, 0))
