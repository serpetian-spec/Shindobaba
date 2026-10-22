class_name BeastModels
extends RefCounted
## Dokuz kuyruklu canavarın prosedürel modelleri (BeastRig parçalarına bağlı, animasyonlu).
## Boylar anime ölçeğinde (metre, ayakta/çömelik tepe yüksekliği).

const INFO := {
	"shukaku": {"name": "Shukaku — Bir Kuyruk", "tails": 1, "height": 52.0, "element": "fuuton", "color": Color(0.82, 0.66, 0.42), "chakra": Color(0.85, 0.7, 0.45), "num": 1},
	"matatabi": {"name": "Matatabi — İki Kuyruk", "tails": 2, "height": 46.0, "element": "katon", "color": Color(0.25, 0.4, 1.0), "chakra": Color(0.3, 0.45, 1.0), "num": 2},
	"isobu": {"name": "Isobu — Üç Kuyruk", "tails": 3, "height": 42.0, "element": "suiton", "color": Color(0.45, 0.55, 0.5), "chakra": Color(0.35, 0.8, 0.75), "num": 3},
	"son_goku": {"name": "Son Gokū — Dört Kuyruk", "tails": 4, "height": 62.0, "element": "yoton", "color": Color(0.8, 0.18, 0.12), "chakra": Color(1.0, 0.35, 0.1), "num": 4},
	"kokuo": {"name": "Kokuō — Beş Kuyruk", "tails": 5, "height": 56.0, "element": "futton", "color": Color(0.94, 0.94, 0.92), "chakra": Color(0.95, 0.9, 0.8), "num": 5},
	"saiken": {"name": "Saiken — Altı Kuyruk", "tails": 6, "height": 50.0, "element": "suiton", "color": Color(0.85, 0.92, 1.0), "chakra": Color(0.75, 0.9, 1.0), "num": 6},
	"chomei": {"name": "Chōmei — Yedi Kuyruk", "tails": 7, "height": 48.0, "element": "fuuton", "color": Color(0.2, 0.45, 0.85), "chakra": Color(0.6, 1.0, 0.4), "num": 7},
	"gyuki": {"name": "Gyūki — Sekiz Kuyruk", "tails": 8, "height": 72.0, "element": "raiton", "color": Color(0.45, 0.3, 0.33), "chakra": Color(0.75, 0.35, 0.9), "num": 8},
	"kurama": {"name": "Kurama — Dokuz Kuyruk", "tails": 9, "height": 115.0, "element": "katon", "color": Color(0.95, 0.42, 0.12), "chakra": Color(1.0, 0.45, 0.1), "num": 9},
	"raiju": {"name": "Raijū", "tails": 3, "height": 8.0, "element": "raiton", "color": Color(0.3, 0.4, 0.6), "chakra": Color(0.45, 0.75, 1.0), "num": 0},
}


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
	r.finalize_colliders()
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
		BeastRig.claw(mb2, base, Vector3(sin(a) * 0.2, -0.6, -1.0), 0.55 * hand_size, 0.11 * hand_size, claw_col)
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
			BeastRig.claw(mb2, ankle + Vector3(sin(a) * 0.4, -0.3, -1.1) * foot_size, Vector3(sin(a) * 0.2, -0.4, -1.0), 0.5 * foot_size, 0.1 * foot_size, claw_col)
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


# ------------------------------------------------------------------ 9 Kuyruk: Kurama (çömelik tilki, insansı kollar)
static func _kurama(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.95, 0.42, 0.12); var belly = Color(0.98, 0.62, 0.3); var dark = Color(0.14, 0.05, 0.04); var cl = Color(0.95, 0.9, 0.8)
	r.hips = r._pivot(root, Vector3(0, 4.2, 2.0), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(4.2, 3.8, 4.6), c, Vector3.ZERO, 16)
	mb.add("sphere", Vector3(0, -0.4, -2.2), Vector3(4.0, 3.4, 4.4), belly.lerp(c, 0.5), Vector3.ZERO, 16)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0, -1.0), Vector3(4.0, 3.4, 6.0))
	r.chest = r._pivot(r.hips, Vector3(0, 1.0, -4.0), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(5.0, 4.6, 4.4), c, Vector3.ZERO, 16)
	mc.add("sphere", Vector3(0, -0.6, -1.4), Vector3(3.6, 3.2, 2.2), belly, Vector3.ZERO, 14)
	BeastRig.limb(mc, Vector3(0, 1.0, -1.0), Vector3(0, 2.4, -2.6), 1.6, 1.2, c)
	for i in 8:  # boyun yelesi
		var a = TAU * i / 8.0
		BeastRig.claw(mc, Vector3(sin(a) * 1.6, 1.6 + cos(a) * 0.6, -1.6), Vector3(sin(a) * 0.6, 0.3, 0.8), 1.4, 0.45, c.darkened(0.08))
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(4.6, 4.2, 4.0))
	r.head = r._pivot(r.chest, Vector3(0, 2.9, -3.2), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(3.4, 2.8, 3.2), c, Vector3.ZERO, 16)
	mh.add("sphere", Vector3(0, -0.4, -2.0), Vector3(1.8, 1.35, 2.8), c, Vector3.ZERO, 14)
	mh.add("sphere", Vector3(0, -0.25, -3.35), Vector3(0.6, 0.45, 0.45), dark, Vector3.ZERO, 8)
	for sx in [-1.0, 1.0]:
		mh.add("sphere", Vector3(0.78 * sx, 0.32, -1.15), Vector3(1.25, 0.7, 1.0), dark, Vector3(0, 0, -18 * sx), 10)  # göz çevresi siyah kürk
		mh.add("cone", Vector3(1.0 * sx, 1.9, 0.2), Vector3(1.15, 2.7, 0.65), c, Vector3(-8, 0, -22 * sx), 8)  # kulak
		mh.add("cone", Vector3(1.02 * sx, 1.75, 0.0), Vector3(0.75, 2.1, 0.3), dark, Vector3(-8, 0, -22 * sx), 6)
		for k in 3:  # yanak tüyü
			BeastRig.claw(mh, Vector3(1.55 * sx, -0.35 - k * 0.3, -0.4 + k * 0.2), Vector3(sx, -0.2, 0.5), 1.0, 0.3, c)
		r._eye(r.head, Vector3(0.82 * sx, 0.38, -1.5), Vector3(0.75, 0.3, 0.22), Color(1.0, 0.12, 0.05), Color(0.02, 0.0, 0.0), Vector3(0, 20 * sx, -16 * sx))
	for i in 5:  # üst dişler
		for sx in [-1.0, 1.0]:
			BeastRig.claw(mh, Vector3(0.6 * sx - sx * i * 0.08, -0.95, -1.2 - i * 0.38), Vector3(0, -1, 0), 0.45, 0.12, cl)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3(0, 0, -0.8), Vector3(3.2, 2.6, 4.4) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.85, -0.5), "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.15, -1.6), Vector3(1.5, 0.6, 2.6), c, Vector3.ZERO, 12)
	mj.add("box", Vector3(0, 0.12, -1.6), Vector3(1.1, 0.12, 2.2), Color(0.55, 0.08, 0.08))
	for i in 4:
		for sx in [-1.0, 1.0]:
			BeastRig.claw(mj, Vector3(0.5 * sx, 0.1, -0.9 - i * 0.4), Vector3(0, 1, 0), 0.35, 0.1, cl)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.7, -3.0), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.3 * sx, 0.3, -0.8), Vector3(0.5 * sx, -2.6, -1.2), Vector3(-0.1 * sx, -2.5, -0.7), 1.05, 0.8, 0.6, c, c.darkened(0.05), dark, 5, 1.2)
		_leg(r, r.hips, sx, Vector3(1.9 * sx, -0.5, 1.0), Vector3(0.3 * sx, -1.6, 1.6), Vector3(0, -1.9, -0.6), 1.25, 0.85, 0.55, c, c.darkened(0.05), dark, false, false, 1.2)
	_tail_fan(r, r.hips, Vector3(0, 0.9, 2.2), 9, 70.0, -40.0, 9.5, 0.6, 1.3, c, Color(1.0, 0.78, 0.45), "fur", 8)
	r._weak(r.head, Vector3(0, 1.45, -0.3))
	r._weak(r.chest, Vector3(0, 2.4, 0.6))
	r._weak(r.hips, Vector3(0, 1.6, 2.0))


# ------------------------------------------------------------------ 1 Kuyruk: Shukaku (dik duran göbekli rakun, kum)
static func _shukaku(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.82, 0.66, 0.42); var mk = Color(0.12, 0.14, 0.32); var cl = Color(0.9, 0.85, 0.7)
	r.hips = r._pivot(root, Vector3(0, 3.0, 0), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3(0, 0.6, 0), Vector3(5.4, 5.6, 4.8), c, Vector3.ZERO, 18)
	for i in 4:  # göbekte lanetli mühür desenleri
		mb.add("torus", Vector3(0, -0.6 + i * 0.9, 0), Vector3(5.5 - absf(i - 1.5) * 0.6, 0.35, 4.9 - absf(i - 1.5) * 0.5), mk, Vector3.ZERO, 18)
	for i in 10:
		var a = TAU * i / 10.0
		mb.add("sphere", Vector3(sin(a) * 2.2, 1.6 + cos(a * 2.0) * 0.6, -cos(a) * 1.9 - 0.3), Vector3(0.35, 0.35, 0.2), mk, Vector3.ZERO, 6)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0.6, 0), Vector3(5.0, 5.2, 4.4))
	r.chest = r._pivot(r.hips, Vector3(0, 3.1, -0.1), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(4.3, 3.2, 3.8), c, Vector3.ZERO, 16)
	mc.add("torus", Vector3(0, 0.2, 0), Vector3(4.4, 0.3, 3.9), mk, Vector3.ZERO, 16)
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 2.5, -0.3), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(3.8, 3.3, 3.5), c, Vector3.ZERO, 16)
	mh.add("sphere", Vector3(0, -0.6, -1.5), Vector3(2.0, 1.2, 1.4), c.lightened(0.08), Vector3.ZERO, 12)
	for sx in [-1.0, 1.0]:
		mh.add("sphere", Vector3(1.35 * sx, 1.55, 0.2), Vector3(1.1, 1.1, 0.55), c, Vector3.ZERO, 10)
		mh.add("sphere", Vector3(1.35 * sx, 1.55, 0.05), Vector3(0.65, 0.65, 0.3), mk, Vector3.ZERO, 8)
		mh.add("torus", Vector3(0.95 * sx, 0.45, -1.4), Vector3(1.5, 0.3, 1.2), mk, Vector3(80, 0, 0), 14)
		mh.add("sphere", Vector3(0.95 * sx, 0.45, -1.48), Vector3(1.05, 1.0, 0.5), Color(0.02, 0.02, 0.04), Vector3.ZERO, 10)
		r._eye(r.head, Vector3(0.95 * sx, 0.45, -1.62), Vector3(0.7, 0.7, 0.25), Color(1.0, 0.85, 0.2), Color(0.02, 0.02, 0.02), Vector3.ZERO, false)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(3.4, 3.0, 3.2) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.9, -1.2), "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.2, -0.5), Vector3(2.0, 0.7, 1.2), c, Vector3.ZERO, 10)
	mj.add("box", Vector3(0, 0.1, -0.7), Vector3(1.6, 0.2, 0.6), Color(0.1, 0.05, 0.05))
	for i in 7:
		BeastRig.claw(mj, Vector3(-0.75 + i * 0.25, 0.25, -0.95), Vector3(0, 1, -0.2), 0.4, 0.12, cl)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -1.9), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.4 * sx, 0.3, 0), Vector3(0.9 * sx, -1.9, -0.5), Vector3(0.2 * sx, -1.6, -0.8), 0.85, 0.72, 0.6, c, c, cl, 4, 1.0)
		_leg(r, r.hips, sx, Vector3(1.5 * sx, -1.6, 0), Vector3(0.25 * sx, -0.9, -0.2), Vector3(0, -0.6, -0.1), 1.1, 0.95, 0.75, c, c, cl, false, false, 1.0)
	_tail_fan(r, r.hips, Vector3(0, -0.6, 2.2), 1, 0.0, -18.0, 10.0, 1.1, 1.6, c, c.lightened(0.1), "sand", 8)
	_particles(r.hips, Vector3(3.0, 4.0, 2.5), [Color(0.85, 0.7, 0.45, 0.8), Color(0.85, 0.7, 0.45, 0.0)], 60, 1.2, Vector3(0, -3, 0), 2.0)
	r._weak(r.head, Vector3(0, 1.7, -0.2))
	r._weak(r.hips, Vector3(0, 1.0, -2.4))
	r._weak(r.hips, Vector3(0, 0.0, 2.4))


# ------------------------------------------------------------------ 2 Kuyruk: Matatabi (mavi alevden kedi)
static func _matatabi(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.22, 0.35, 0.95); var dk = Color(0.06, 0.06, 0.18); var cl = Color(0.9, 0.9, 1.0)
	r.hips = r._pivot(root, Vector3(0, 4.4, 2.4), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(3.2, 3.0, 4.2), c, Vector3.ZERO, 16)
	mb.add("sphere", Vector3(0, -0.2, -2.6), Vector3(2.9, 2.7, 4.0), c.darkened(0.1), Vector3.ZERO, 14)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0, -1.2), Vector3(2.8, 2.6, 6.0))
	r.chest = r._pivot(r.hips, Vector3(0, 0.4, -4.4), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(3.4, 3.4, 3.6), c, Vector3.ZERO, 16)
	BeastRig.limb(mc, Vector3(0, 0.8, -0.8), Vector3(0, 2.0, -1.8), 1.2, 0.95, c)
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 2.4, -2.2), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.8, 2.4, 2.6), c, Vector3.ZERO, 16)
	mh.add("sphere", Vector3(0, -0.45, -1.2), Vector3(1.4, 1.0, 1.2), c.lightened(0.1), Vector3.ZERO, 12)
	mh.add("sphere", Vector3(0, -0.2, -1.8), Vector3(0.4, 0.3, 0.3), dk, Vector3.ZERO, 8)
	for sx in [-1.0, 1.0]:
		mh.add("cone", Vector3(0.95 * sx, 1.55, 0.1), Vector3(1.0, 2.0, 0.55), c, Vector3(-5, 0, -18 * sx), 6)
		mh.add("cone", Vector3(0.97 * sx, 1.45, -0.05), Vector3(0.6, 1.5, 0.25), dk, Vector3(-5, 0, -18 * sx), 6)
		for k in 3:  # bıyık
			mh.add("box", Vector3(0.95 * sx, -0.5 + k * 0.12, -1.3), Vector3(1.6, 0.04, 0.04), cl, Vector3(0, -15 * sx, (k - 1) * 8 * sx))
	r._eye(r.head, Vector3(-0.7, 0.3, -1.1), Vector3(0.6, 0.38, 0.25), Color(1.0, 0.9, 0.2), Color(1.0, 0.9, 0.2), Vector3(0, -15, 10), false)
	r._eye(r.head, Vector3(0.7, 0.3, -1.1), Vector3(0.6, 0.38, 0.25), Color(0.3, 1.0, 0.4), Color(0.3, 1.0, 0.4), Vector3(0, 15, -10), false)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(2.6, 2.2, 2.6) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.8, -0.6), "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.1, -0.7), Vector3(1.1, 0.5, 1.2), c, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		BeastRig.claw(mj, Vector3(0.35 * sx, 0.3, -1.1), Vector3(0, -1, 0), 0.5, 0.1, cl)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.6, -1.7), "agiz")
	for sx in [-1.0, 1.0]:
		_leg(r, r.chest, sx, Vector3(1.3 * sx, -0.6, -0.3), Vector3(0.2 * sx, -2.0, -0.2), Vector3(0, -2.2, -0.1), 0.85, 0.6, 0.45, c, c, cl, true, false, 0.9)
		_leg(r, r.hips, sx, Vector3(1.3 * sx, -0.5, 0.8), Vector3(0.2 * sx, -1.8, 1.2), Vector3(0, -2.1, -0.5), 1.0, 0.65, 0.45, c, c, cl, false, false, 0.9)
	_tail_fan(r, r.hips, Vector3(0, 0.8, 2.0), 2, 22.0, -35.0, 11.0, 0.45, 0.9, c, dk, "flame", 8)
	_particles(r.hips, Vector3(2.0, 2.0, 4.0), [Color(0.35, 0.55, 1.0, 0.9), Color(0.05, 0.05, 0.3, 0.0)], 120, 1.6, Vector3(0, 6, 0), 1.0, true)
	_particles(r.chest, Vector3(2.0, 2.5, 2.0), [Color(0.35, 0.55, 1.0, 0.9), Color(0.05, 0.05, 0.3, 0.0)], 70, 1.4, Vector3(0, 6, 0), 0.9, true)
	r._weak(r.head, Vector3(0, 1.25, -0.1))
	r._weak(r.hips, Vector3(0, 1.6, 0.0))


# ------------------------------------------------------------------ 3 Kuyruk: Isobu (dikenli kabuklu kaplumbağa)
static func _isobu(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var sh = Color(0.45, 0.55, 0.5); var flesh = Color(0.75, 0.2, 0.18); var sp = Color(0.6, 0.65, 0.58)
	r.hips = r._pivot(root, Vector3(0, 3.0, 0.8), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3(0, -0.3, 0), Vector3(7.0, 3.2, 8.0), flesh, Vector3.ZERO, 16)
	mb.add("hemi", Vector3(0, 0.0, 0), Vector3(8.4, 6.0, 9.4), sh, Vector3.ZERO, 20)
	mb.add("torus", Vector3(0, 0.1, 0), Vector3(8.6, 0.8, 9.6), sh.darkened(0.2), Vector3.ZERO, 22)
	for ring in [[1.0, 10, 3.6], [2.0, 8, 2.6], [2.8, 5, 1.4]]:  # kabuk dikenleri
		for i in ring[1]:
			var a = TAU * i / ring[1] + ring[0]
			var p = Vector3(sin(a) * ring[2], ring[0] + 0.4, cos(a) * ring[2] * 1.1)
			BeastRig.claw(mb, p, (p - Vector3(0, -1, 0)).normalized(), 1.6, 0.4, sp)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 1.2, 0), Vector3(7.6, 3.6, 8.6))
	r.chest = r._pivot(r.hips, Vector3(0, -0.2, -4.0), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(3.6, 2.6, 2.6), flesh, Vector3.ZERO, 14)
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 0.5, -1.6), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.6, 2.0, 2.6), flesh, Vector3.ZERO, 14)
	mh.add("hemi", Vector3(0, 0.6, -0.2), Vector3(3.6, 1.6, 3.2), sh, Vector3.ZERO, 16)  # alın plakası
	for i in 5:
		BeastRig.claw(mh, Vector3(-1.2 + i * 0.6, 1.2, -0.6), Vector3(0, 1, -0.5), 1.0, 0.25, sp)
	r._eye(r.head, Vector3(-0.6, 0.15, -1.2), Vector3(0.45, 0.4, 0.2), Color(1.0, 0.85, 0.1), Color(0.6, 0.0, 0.0), Vector3.ZERO, false)
	mh.add("box", Vector3(0.6, 0.15, -1.25), Vector3(0.5, 0.06, 0.1), Color(0.1, 0.0, 0.0))  # kapalı sağ göz
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.6, -0.4), "cene")
	var mj = MB.new()
	mj.add("hemi", Vector3(0, -0.2, -0.6), Vector3(2.8, 1.2, 2.4), sh, Vector3(180, 0, 0), 14)
	for i in 4:
		BeastRig.claw(mj, Vector3(-0.9 + i * 0.6, -0.6, -1.2), Vector3(0, -1, -0.6), 0.9, 0.22, sp)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.3, -1.6), "agiz")
	for sx in [-1.0, 1.0]:  # insan benzeri iki kol
		_arm(r, r.chest, sx, Vector3(2.6 * sx, 0.2, 0.3), Vector3(1.2 * sx, -1.1, -1.2), Vector3(0, -1.2, -1.0), 0.85, 0.75, 0.6, flesh, flesh.darkened(0.1), sp, 5, 1.1)
	_tail_fan(r, r.hips, Vector3(0, 0.0, 4.4), 3, 30.0, -12.0, 10.0, 0.7, 1.0, sh, sh.lightened(0.15), "shrimp", 9)
	r._weak(r.hips, Vector3(0, 3.2, 0.0))
	r._weak(r.head, Vector3(0, 1.4, -0.1))


# ------------------------------------------------------------------ 4 Kuyruk: Son Gokū (boynuzlu goril, lav)
static func _son_goku(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.82, 0.18, 0.12); var g = Color(0.35, 0.6, 0.35); var dk = Color(0.15, 0.08, 0.06); var cl = Color(0.95, 0.9, 0.75)
	r.hips = r._pivot(root, Vector3(0, 3.0, 0.6), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(3.9, 3.4, 3.4), c, Vector3.ZERO, 16)
	r._mesh(r.hips, mb)
	r.chest = r._pivot(r.hips, Vector3(0, 2.7, -0.6), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(5.6, 4.3, 4.0), c, Vector3.ZERO, 18)
	mc.add("sphere", Vector3(0, -0.2, -1.4), Vector3(3.4, 3.2, 1.6), g, Vector3.ZERO, 14)
	for sx in [-1.0, 1.0]:
		mc.add("sphere", Vector3(2.4 * sx, 1.1, 0), Vector3(2.4, 2.0, 2.4), c, Vector3.ZERO, 12)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(5.2, 4.0, 3.6))
	r.head = r._pivot(r.chest, Vector3(0, 2.5, -1.5), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.8, 2.7, 2.6), c, Vector3.ZERO, 14)
	mh.add("sphere", Vector3(0, -0.2, -0.9), Vector3(2.2, 2.0, 1.2), g, Vector3.ZERO, 12)
	for sx in [-1.0, 1.0]:  # kavisli boynuzlar
		var base = Vector3(0.6 * sx, 1.1, -0.4)
		var p = base
		for k in 5:
			var d = Vector3(0.35 * sx, 0.9, 0.25 - k * 0.12)
			var col = cl.lerp(dk, k / 4.0)
			BeastRig.limb(mh, p, p + d, 0.32 - k * 0.05, 0.27 - k * 0.05, col, 8)
			p += d
		r._eye(r.head, Vector3(0.6 * sx, 0.35, -1.4), Vector3(0.5, 0.32, 0.2), Color(1.0, 0.9, 0.2), Color(1, 1, 1), Vector3.ZERO, false)
		BeastRig.claw(mh, Vector3(0.45 * sx, -0.9, -1.3), Vector3(0, -1, -0.2), 0.7, 0.16, cl)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(2.6, 2.6, 2.6) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -0.8, -0.8), "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.2, -0.5), Vector3(1.8, 0.8, 1.2), g, Vector3.ZERO, 10)
	mj.add("torus", Vector3(0, 0.0, -0.85), Vector3(1.0, 0.6, 1.0), dk, Vector3(80, 0, 0), 12)  # volkan ağız
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.8, -1.8), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(3.0 * sx, 0.9, 0.1), Vector3(1.0 * sx, -2.8, -0.6), Vector3(0, -2.6, -1.0), 1.25, 1.05, 0.85, c, g, dk, 5, 1.4)
		_leg(r, r.hips, sx, Vector3(1.4 * sx, -1.2, 0.2), Vector3(0.6 * sx, -1.2, -0.4), Vector3(0, -1.0, 0.1), 1.2, 1.0, 0.8, c, g, dk, false, false, 1.2)
	_tail_fan(r, r.hips, Vector3(0, 0.4, 1.8), 4, 45.0, -30.0, 10.0, 0.55, 0.9, c, c.darkened(0.2), "spike", 8)
	_particles(r.jaw, Vector3(0.4, 0.3, 0.4), [Color(1.0, 0.5, 0.1, 0.9), Color(0.3, 0.05, 0.0, 0.0)], 30, 0.7, Vector3(0, 2, -2), 0.8, true)
	r._weak(r.head, Vector3(0, 1.35, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.4))


# ------------------------------------------------------------------ 5 Kuyruk: Kokuō (yunus başlı beyaz at, buhar)
static func _kokuo(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.94, 0.94, 0.92); var tan = Color(0.82, 0.68, 0.45); var dk = Color(0.15, 0.3, 0.32)
	r.hips = r._pivot(root, Vector3(0, 5.0, 2.6), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(3.0, 3.0, 3.6), c, Vector3.ZERO, 16)
	mb.add("sphere", Vector3(0, -0.1, -2.3), Vector3(2.8, 2.8, 4.0), c, Vector3.ZERO, 16)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3(0, 0, -1.0), Vector3(2.8, 2.8, 6.0))
	r.chest = r._pivot(r.hips, Vector3(0, 0.3, -4.4), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(3.2, 3.4, 3.6), c, Vector3.ZERO, 16)
	BeastRig.limb(mc, Vector3(0, 1.0, -1.0), Vector3(0, 3.0, -2.2), 1.2, 0.9, c)
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 3.4, -2.6), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.2, 2.0, 3.0), c, Vector3.ZERO, 16)
	mh.add("sphere", Vector3(0, -0.45, -2.2), Vector3(0.95, 0.75, 2.6), c, Vector3.ZERO, 12)  # yunus burnu
	for sx in [-1.0, 1.0]:
		var b = Vector3(0.5 * sx, 0.9, -0.2)
		BeastRig.limb(mh, b, b + Vector3(0.6 * sx, 1.6, -1.8), 0.3, 0.2, tan, 8)
		BeastRig.claw(mh, b + Vector3(0.6 * sx, 1.6, -1.8), Vector3(0.2 * sx, 0.4, -1.0), 1.4, 0.2, tan)
		r._eye(r.head, Vector3(0.9 * sx, 0.25, -0.9), Vector3(0.45, 0.32, 0.2), dk, Color(0.02, 0.05, 0.05), Vector3(0, 30 * sx, 0), false)
		mh.add("box", Vector3(0.95 * sx, -0.08, -0.85), Vector3(0.4, 0.06, 0.1), Color(0.85, 0.15, 0.15), Vector3(0, 30 * sx, 0))
	for i in 3:
		BeastRig.claw(mh, Vector3((i - 1) * 0.35, 0.95, -0.9), Vector3((i - 1) * 0.2, 1.0, -0.8), 0.7, 0.14, tan)
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.75, -1.0), "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.05, -1.2), Vector3(0.8, 0.4, 2.2), c.darkened(0.05), Vector3.ZERO, 10)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.5, -3.4), "agiz")
	for sx in [-1.0, 1.0]:
		_leg(r, r.chest, sx, Vector3(1.2 * sx, -0.8, -0.2), Vector3(0, -2.4, 0.2), Vector3(0, -2.4, -0.2), 0.75, 0.5, 0.42, c, tan, tan, true, true)
		_leg(r, r.hips, sx, Vector3(1.2 * sx, -0.7, 0.6), Vector3(0, -2.2, 1.0), Vector3(0, -2.6, -0.6), 0.9, 0.55, 0.42, c, tan, tan, false, true)
	_tail_fan(r, r.hips, Vector3(0, 0.8, 1.8), 5, 50.0, -40.0, 9.0, 0.5, 1.0, c, tan, "fur", 7)
	_particles(r.hips, Vector3(2.0, 2.0, 3.5), [Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)], 60, 2.5, Vector3(0, 4, 0), 2.0)
	r._weak(r.head, Vector3(0, 1.05, 0.0))
	r._weak(r.hips, Vector3(0, 1.6, -1.0))


# ------------------------------------------------------------------ 6 Kuyruk: Saiken (dev beyaz sümüklü böcek)
static func _saiken(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.85, 0.92, 1.0); var dk = Color(0.3, 0.35, 0.5)
	r.hips = r._pivot(root, Vector3(0, 1.4, 0.5), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(5.6, 3.0, 7.0), c, Vector3.ZERO, 18)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3.ZERO, Vector3(5.0, 2.6, 6.4))
	r.chest = r._pivot(r.hips, Vector3(0, 3.2, -1.0), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(4.2, 6.4, 3.8), c, Vector3.ZERO, 18)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(3.8, 6.0, 3.4))
	r.head = r._pivot(r.chest, Vector3(0, 3.4, -0.4), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(3.2, 2.6, 3.0), c, Vector3.ZERO, 16)
	for sx in [-1.0, 1.0]:  # göz sapları
		BeastRig.limb(mh, Vector3(0.7 * sx, 0.9, -0.5), Vector3(1.3 * sx, 3.0, -1.0), 0.38, 0.26, c, 8)
		mh.add("sphere", Vector3(1.35 * sx, 3.2, -1.05), Vector3(0.75, 0.75, 0.75), c, Vector3.ZERO, 10)
		r._eye(r.head, Vector3(1.35 * sx, 3.2, -1.38), Vector3(0.38, 0.38, 0.2), Color(0.1, 0.1, 0.15), Color(0.9, 0.9, 1.0), Vector3.ZERO, false)
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.4, -1.3), "cene")
	var mj = MB.new()
	mj.add("torus", Vector3(0, 0, -0.1), Vector3(1.3, 0.8, 1.3), dk, Vector3(90, 0, 0), 14)
	mj.add("sphere", Vector3(0, 0, -0.05), Vector3(0.9, 0.9, 0.3), Color(0.05, 0.05, 0.08), Vector3.ZERO, 10)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.4, -1.6), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(1.9 * sx, 0.6, -0.4), Vector3(0.8 * sx, -1.0, -0.6), Vector3(0.1 * sx, -0.9, -0.5), 0.6, 0.5, 0.42, c, c, c, 3, 0.8)
	_tail_fan(r, r.hips, Vector3(0, 0.6, 3.0), 6, 60.0, -25.0, 9.0, 0.6, 1.0, c, c.darkened(0.08), "slug", 7)
	_particles(r.hips, Vector3(2.6, 0.5, 3.4), [Color(0.85, 0.95, 1.0, 0.6), Color(0.85, 0.95, 1.0, 0.0)], 30, 1.0, Vector3(0, -2, 0), 1.5)
	r._weak(r.head, Vector3(0, 1.25, -0.1))
	r._weak(r.chest, Vector3(0, 0.0, 1.8))


# ------------------------------------------------------------------ 7 Kuyruk: Chōmei (zırhlı gergedan böceği, kanatlı)
static func _chomei(r: BeastRig, root: Node3D) -> void:
	r.quadruped = true
	r.upright = false
	var c = Color(0.2, 0.45, 0.85); var gr = Color(0.35, 0.75, 0.3); var orn = Color(1.0, 0.55, 0.15)
	r.hips = r._pivot(root, Vector3(0, 3.6, 2.0), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(4.0, 3.0, 6.0), c, Vector3.ZERO, 16)
	for i in 4:
		mb.add("torus", Vector3(0, 0, -1.8 + i * 1.2), Vector3(4.1 - absf(i - 1.5) * 0.4, 0.4, 3.1), c.darkened(0.25), Vector3(90, 0, 0), 16)
	r._mesh(r.hips, mb)
	r._collider(r.hips, Vector3.ZERO, Vector3(3.6, 2.6, 5.6))
	r.chest = r._pivot(r.hips, Vector3(0, 0.4, -4.0), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(3.6, 2.8, 3.2), c, Vector3.ZERO, 16)
	for sx in [-1.0, 1.0]:
		for k in 3:
			BeastRig.claw(mc, Vector3(1.6 * sx, 0.8 - k * 0.3, -0.4 + k * 0.4), Vector3(sx, 0.4, 0), 1.0, 0.25, c.lightened(0.15))
	BeastRig.claw(mc, Vector3(0, 1.4, 0.2), Vector3(0, 1.0, -0.6), 3.2, 0.7, c.darkened(0.1))  # sırt boynuzu
	BeastRig.claw(mc, Vector3(0, 3.4, -1.2), Vector3(0, 0.4, -1.0), 1.6, 0.35, c.darkened(0.1))
	r._mesh(r.chest, mc)
	r.head = r._pivot(r.chest, Vector3(0, 0.3, -2.0), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.4, 2.0, 2.4), c, Vector3.ZERO, 14)
	mh.add("box", Vector3(0, 0.2, -1.12), Vector3(1.6, 0.25, 0.1), orn)  # kask içinden parlayan göz
	for sx in [-1.0, 1.0]:
		BeastRig.claw(mh, Vector3(0.55 * sx, -0.5, -1.0), Vector3(-0.4 * sx, -0.3, -1.0), 1.0, 0.18, gr)
	r._mesh(r.head, mh)
	r.jaw = r._pivot(r.head, Vector3(0, -0.6, -0.8), "cene")
	var mj = MB.new()
	BeastRig.claw(mj, Vector3(0, 0, -0.3), Vector3(0, -0.2, -1.0), 0.9, 0.22, gr)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.3, -1.4), "agiz")
	for sx in [-1.0, 1.0]:  # altı bacak
		_leg(r, r.chest, sx, Vector3(1.5 * sx, -0.6, -0.4), Vector3(1.6 * sx, -0.6, -0.6), Vector3(0.2 * sx, -2.6, -0.4), 0.4, 0.3, 0.22, c, gr, gr, true, true)
		_leg(r, r.hips, sx, Vector3(1.6 * sx, -0.8, -2.0), Vector3(1.8 * sx, -0.4, 0.0), Vector3(0.2 * sx, -2.6, 0.2), 0.42, 0.3, 0.22, c, gr, gr, false, true)
		_leg(r, r.hips, sx, Vector3(1.6 * sx, -0.8, 0.6), Vector3(1.8 * sx, -0.4, 0.6), Vector3(0.2 * sx, -2.6, 0.6), 0.42, 0.3, 0.22, c, gr, gr, true, true)
	var wb = r._pivot(r.hips, Vector3(0, 1.2, 0.5), "kanat_koku")
	for i in 6:
		var sx = -1.0 if i < 3 else 1.0
		var k = i % 3
		r._tail(wb, (60.0 + k * 22.0) * sx, -20.0 - k * 10.0, 1, 7.5 - k * 0.8, 0.2, 1.5, orn, orn, "wing")
	r._tail(r.hips, 0.0, -5.0, 6, 6.0, 0.5, 0.6, c, gr, "shrimp")
	_particles(wb, Vector3(5.0, 1.5, 3.0), [Color(0.9, 1.0, 0.6, 0.7), Color(0.9, 1.0, 0.6, 0.0)], 40, 0.5, Vector3(0, -1, 0), 2.0, true)
	r._weak(r.head, Vector3(0, 1.05, 0.0))
	r._weak(r.hips, Vector3(0, 1.6, 1.0))


# ------------------------------------------------------------------ 8 Kuyruk: Gyūki (öküz gövdeli, ahtapot kollu)
static func _gyuki(r: BeastRig, root: Node3D) -> void:
	var c = Color(0.48, 0.32, 0.34); var hn = Color(0.85, 0.8, 0.7); var dk = Color(0.12, 0.08, 0.1)
	r.hips = r._pivot(root, Vector3(0, 3.4, 0), "kalca_kok")
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(3.8, 2.6, 3.6), c, Vector3.ZERO, 16)
	r._mesh(r.hips, mb)
	r.chest = r._pivot(r.hips, Vector3(0, 2.6, -0.3), "gogus")
	var mc = MB.new()
	mc.add("sphere", Vector3.ZERO, Vector3(5.4, 4.2, 3.9), c, Vector3.ZERO, 18)
	for sx in [-1.0, 1.0]:
		mc.add("sphere", Vector3(1.2 * sx, 0.2, -1.6), Vector3(2.0, 1.8, 1.0), c.lightened(0.05), Vector3.ZERO, 12)
		mc.add("sphere", Vector3(2.4 * sx, 1.2, 0), Vector3(2.4, 2.2, 2.4), c, Vector3.ZERO, 12)
	r._mesh(r.chest, mc)
	r._collider(r.chest, Vector3.ZERO, Vector3(5.0, 4.0, 3.6))
	r.head = r._pivot(r.chest, Vector3(0, 2.6, -1.2), "bas")
	var mh = MB.new()
	mh.add("sphere", Vector3.ZERO, Vector3(2.4, 2.3, 2.6), c, Vector3.ZERO, 14)
	mh.add("sphere", Vector3(0, -0.5, -1.2), Vector3(1.8, 1.3, 1.4), c.lightened(0.08), Vector3.ZERO, 12)
	for sx in [-1.0, 1.0]:
		for h in 2:  # dört kıvrık koç boynuzu
			var p = Vector3(0.8 * sx, 0.8 + h * 0.3, -0.2 + h * 0.4)
			for k in 10:
				var a = k * 0.55 + h * 0.4
				var d = Vector3(sx * (0.35 * cos(a) + 0.25), 0.35 * sin(a), 0.3 * cos(a * 0.7) * (1 if h == 0 else -1))
				BeastRig.limb(mh, p, p + d, 0.32 - k * 0.022, 0.3 - k * 0.022, hn.lerp(hn.darkened(0.3), k / 9.0), 7)
				p += d
		r._eye(r.head, Vector3(0.6 * sx, 0.3, -1.15), Vector3(0.45, 0.25, 0.2), Color(0.95, 0.8, 0.3), Color(0.05, 0.02, 0.02), Vector3(0, 15 * sx, -10 * sx), true)
	r._mesh(r.head, mh)
	r._collider(r.head, Vector3.ZERO, Vector3(2.4, 2.4, 2.6) * 1.15)
	r.jaw = r._pivot(r.head, Vector3(0, -1.0, -1.0), "cene")
	var mj = MB.new()
	mj.add("sphere", Vector3(0, -0.15, -0.4), Vector3(1.6, 0.6, 1.0), c, Vector3.ZERO, 10)
	for i in 6:
		mj.add("box", Vector3(-0.6 + i * 0.24, 0.15, -0.85), Vector3(0.2, 0.28, 0.12), hn)
	r._mesh(r.jaw, mj)
	r.mouth = r._pivot(r.head, Vector3(0, -0.9, -1.9), "agiz")
	for sx in [-1.0, 1.0]:
		_arm(r, r.chest, sx, Vector3(2.9 * sx, 0.9, 0.1), Vector3(0.9 * sx, -2.4, -0.4), Vector3(0, -2.2, -1.0), 1.15, 0.95, 0.8, c, c, dk, 5, 1.3)
	# dirsek dikenleri
	for a in r.arms:
		var sp = MB.new()
		BeastRig.claw(sp, Vector3(0, 0, 0.6), Vector3(0, 0.2, 1.0), 1.0, 0.25, hn)
		r._mesh(a["el"], sp)
	# sekiz dokunaç: aşağı-dışa kıvrılır, gövdeyi taşır
	var tb = r._pivot(r.hips, Vector3(0, -0.8, 0), "dokunac_koku")
	for i in 8:
		var yaw = 360.0 * i / 8.0 + 22.5
		r._tail(tb, yaw, 25.0, 9, 9.0, 0.75, 0.85, c, c.lightened(0.15), "tentacle")
	r._weak(r.head, Vector3(0, 1.35, 0.0))
	r._weak(r.chest, Vector3(0, 1.6, 1.4))
	r._weak(r.hips, Vector3(0, -1.0, 0))
