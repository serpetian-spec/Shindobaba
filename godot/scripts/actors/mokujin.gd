class_name Mokujin
extends Node3D
## Mokuton: Mokujin no Jutsu (kanon, Hashirama; ref _tmp/mokujinref): tahtadan dev, heykel gibi insansı — oni yüzü (kalın kaş,
## parlayan sarı gözler, iri burun, aşağı kıvrık geniş ağız, sarkık yanaklar), başta ve omuzlarda yele gibi tahta dikenler,
## iri kambur üst beden, dev kollar; gövdesine sarılı bir tahta ejder omzunun üstünden baş uzatır (Ryūtōki). Kanon: Dokuz
## Kuyruk kadar güçlü, tam beden Susanoo ile çarpışır — boy ~110 m. Tasarım birimi: ayakta boy 10 (BeastRig.D), ön -Z.

const H := 128.0   # tasarım boyu (dik); kambur duruşta ~105-110 m
const WOOD := Color(0.56, 0.55, 0.42)
const GRAIN := Color(0.36, 0.35, 0.26)
const EYE := Color(1.0, 0.82, 0.3)

var rig: BeastRig
var root: Node3D
var hips: Node3D
var torso: Node3D
var head: Node3D
var dragon_head: Node3D
var arms: Array = []
var legs: Array = []
var t := 0.0
var pose_from := {}
var pose_to := {}
var pose_k := 1.0
var pose_dur := 0.5


static func spawn(parent: Node, at: Vector3, yaw: float) -> Mokujin:
	var m = Mokujin.new()
	parent.add_child(m)
	m.global_position = at
	m.rotation.y = yaw
	return m


func _ready() -> void:
	_build()
	set_pose("stand", 0.0)


func _mi(parent: Node3D, mb: MB) -> MeshInstance3D:
	return rig._mesh(parent, mb)


func _build() -> void:
	rig = BeastRig.new()
	rig.id = "mokujin"
	rig.height_m = H
	add_child(rig)
	root = Node3D.new()
	rig.add_child(root)
	hips = rig._pivot(root, Vector3(0, 3.6, 0), "kalca")
	var pb = MB.new()
	Loft.tube(pb, [Vector3(0, -0.5, 0.05), Vector3(0, 0.0, 0.0), Vector3(0, 0.45, 0.0)], [Vector2(1.15, 0.85), Vector2(1.3, 0.95), Vector2(1.2, 0.9)], WOOD, 18, 3)
	_mi(hips, pb)
	torso = rig._pivot(hips, Vector3(0, 0.35, 0), "govde")
	_build_torso()
	head = rig._pivot(torso, Vector3(0, 4.55, -1.15), "bas")
	_build_head()
	for s in [-1.0, 1.0]:
		_build_arm(s)
		_build_leg(s)
	_build_dragon()
	root.scale = Vector3.ONE * rig.design_scale()
	var bm = BeastModels.beast_material(1, Color(0.3, 0.3, 0.22))
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == null and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == Props.toon():
			mi.material_override = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _build_torso() -> void:
	# iri kambur üst beden: geniş göğüs ve omuzlar, sırt kamburu
	var sp = [Vector3(0, -0.1, 0.05), Vector3(0, 1.1, 0.2), Vector3(0, 2.4, 0.45), Vector3(0, 3.5, 0.4), Vector3(0, 4.15, -0.4)]
	var rd = [Vector2(1.25, 0.95), Vector2(1.45, 1.05), Vector2(2.1, 1.35), Vector2(2.35, 1.35), Vector2(1.05, 0.8)]
	var mb = MB.new()
	Loft.tube(mb, sp, rd, WOOD, 22, 4)
	for s in [-1.0, 1.0]:
		Loft.blob(mb, Vector3(s * 0.75, 2.9, -1.05), Vector3(s * 0.3, -0.45, -1), 1.15, [Vector2(0.15, 0.1), Vector2(0.72, 0.38), Vector2(0.6, 0.3), Vector2(0.12, 0.06)], WOOD, 12)   # göğüs
		Loft.blob(mb, Vector3(s * 2.15, 3.55, 0.1), Vector3(s * 0.4, -1, 0), 1.3, [Vector2(0.25, 0.25), Vector2(0.75, 0.72), Vector2(0.68, 0.62), Vector2(0.22, 0.22)], WOOD, 12)   # omuz
		for k in 3:   # karın
			mb.add("sphere", Vector3(s * 0.38, 0.85 + k * 0.52, -1.0), Vector3(0.55, 0.45, 0.24), WOOD.darkened(0.04), Vector3.ZERO, 8)
	_mi(torso, mb)
	BeastModels._grain(rig, torso, sp, rd, 60, 911, GRAIN, 0.03)
	# omuz tepelerinde ve ensede yukarı-dışa savrulan tahta tutamlar (ref: omuzları saran diken yelesi)
	var spk = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 917
	for s in [-1.0, 1.0]:
		for k in 9:
			var base = Vector3(s * (1.2 + k * 0.17), 3.95 - k * 0.06, 0.35 + rng.randf_range(-0.25, 0.25))
			var dir = Vector3(s * rng.randf_range(0.35, 0.7), rng.randf_range(0.6, 0.9), rng.randf_range(0.0, 0.4)).normalized()
			var L = rng.randf_range(0.8, 1.5)
			Loft.tube(spk, [base, base + dir * L * 0.5, base + dir * L + Vector3(0, -0.1, 0.1)], [0.26, 0.15, 0.01], WOOD.darkened(rng.randf_range(0.0, 0.15)), 6, 2)
	_mi(torso, spk)


func _build_head() -> void:
	var mb = MB.new()
	# yuvarlak iri kafa (ref: geniş yüz, alçak alın)
	Loft.blob(mb, Vector3(0, -0.35, 0.05), Vector3(0, 1, 0), 1.75, [Vector2(0.85, 0.8), Vector2(1.05, 0.95), Vector2(0.95, 0.85), Vector2(0.45, 0.42)], WOOD, 18)
	# kalın, çatık kaş kemeri (yüzeye oturan iki yay)
	for s in [-1.0, 1.0]:
		Loft.tube(mb, [Vector3(s * 0.08, 0.38, -0.98), Vector3(s * 0.4, 0.52, -0.95), Vector3(s * 0.72, 0.46, -0.78)], [0.12, 0.15, 0.09], WOOD.darkened(0.05), 8, 3)
	# iri yassı burun (kaş arasından aşağı)
	Loft.blob(mb, Vector3(0, 0.25, -0.98), Vector3(0, -0.75, -0.66), 0.75, [Vector2(0.14, 0.12), Vector2(0.3, 0.22), Vector2(0.34, 0.24), Vector2(0.2, 0.12)], WOOD, 10)
	# sarkık yanak torbaları + aşağı kıvrık kalın dudaklar
	for s in [-1.0, 1.0]:
		mb.add("sphere", Vector3(s * 0.6, -0.42, -0.72), Vector3(0.7, 0.75, 0.55), WOOD, Vector3.ZERO, 12)
	Loft.tube(mb, [Vector3(-0.55, -0.62, -0.92), Vector3(-0.25, -0.42, -1.04), Vector3(0.25, -0.42, -1.04), Vector3(0.55, -0.62, -0.92)], [0.06, 0.09, 0.09, 0.06], GRAIN, 8, 3)   # ağız çizgisi (∩)
	mb.add("sphere", Vector3(0, -0.85, -0.7), Vector3(0.95, 0.5, 0.55), WOOD, Vector3.ZERO, 12)   # çene
	for s in [-1.0, 1.0]:   # alt çeneden yukarı çıkan kısa dişler (ref oni)
		mb.add("cone", Vector3(s * 0.32, -0.42, -1.02), Vector3(0.09, 0.2, 0.09), Color(0.85, 0.82, 0.68), Vector3.ZERO, 5)
	_mi(head, mb)
	# parlayan gözler: kaşın altında, yüze gömülü
	var em = StandardMaterial3D.new()
	em.albedo_color = EYE
	em.emission_enabled = true
	em.emission = EYE
	em.emission_energy_multiplier = 2.0
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var eb = MB.new()
	for s in [-1.0, 1.0]:
		eb.add("sphere", Vector3(s * 0.38, 0.3, -0.98), Vector3(0.32, 0.16, 0.1), EYE, Vector3(0, 0, -s * 12), 10)
	rig._mesh(head, eb, em)
	# taç gibi yele: başın tepesinden ve yanlarından yukarı-geriye savrulan sivri tahta tutamlar (alev gibi)
	var hb = MB.new()
	var rng = RandomNumberGenerator.new()
	rng.seed = 921
	for k in 48:   # üç sıra, düzensiz: alev gibi dağınık
		var row = k % 3
		var a = rng.randf_range(-1.7, 1.7)
		var base = Vector3(sin(a) * (0.75 + row * 0.08), 0.85 + cos(a) * 0.4 - row * 0.12, -0.45 + row * 0.42 + absf(a) * 0.1)
		var dir = Vector3(sin(a) * rng.randf_range(0.3, 0.75), rng.randf_range(0.45, 0.95), rng.randf_range(0.1, 0.6) + row * 0.2).normalized()
		var L = rng.randf_range(0.6, 1.6) * (1.0 - absf(a) * 0.15)
		var bend = Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(0.0, 0.2))
		Loft.tube(hb, [base, base + dir * L * 0.5 + bend, base + dir * L + bend * 2.0], [rng.randf_range(0.16, 0.26), 0.12, 0.01], WOOD.darkened(rng.randf_range(0.0, 0.18)), 6, 2)
	_mi(head, hb)


func _build_arm(s: float) -> void:
	var sh = rig._pivot(torso, Vector3(s * 2.35, 3.4, 0.05), "omuz")
	var ub = MB.new()
	Loft.tube(ub, [Vector3(0, 0.25, 0), Vector3(s * 0.12, -1.1, 0), Vector3(s * 0.08, -2.3, 0)], [0.85, 0.85, 0.65], WOOD, 14, 3)
	_mi(sh, ub)
	BeastModels._grain(rig, sh, [Vector3(0, 0.2, 0), Vector3(0, -1.0, 0), Vector3(0, -2.2, 0)], [Vector2(0.85, 0.85), Vector2(0.8, 0.8), Vector2(0.65, 0.65)], 10, 930 + int(s), GRAIN, 0.03)
	var el = rig._pivot(sh, Vector3(s * 0.08, -2.3, 0), "dirsek")
	var lb = MB.new()
	Loft.tube(lb, [Vector3(0, 0, 0), Vector3(0, -1.15, -0.05), Vector3(0, -2.2, -0.05)], [0.68, 0.75, 0.58], WOOD, 14, 3)
	Loft.blob(lb, Vector3(0, -2.65, -0.1), Vector3(0, -1, -0.1), 1.15, [Vector2(0.55, 0.42), Vector2(0.75, 0.55), Vector2(0.66, 0.48), Vector2(0.32, 0.24)], WOOD, 12)   # dev yumruk
	for f in 4:
		var fx = lerpf(-0.42, 0.42, f / 3.0)
		lb.add("sphere", Vector3(fx, -3.1, -0.45), Vector3(0.3, 0.26, 0.3), WOOD.darkened(0.05), Vector3.ZERO, 8)   # boğumlar
	_mi(el, lb)
	arms.append({"sh": sh, "el": el, "side": s})


func _build_leg(s: float) -> void:
	var hp = rig._pivot(hips, Vector3(s * 1.0, -0.2, 0.0), "kalca_b")
	var ub = MB.new()
	Loft.tube(ub, [Vector3(0, 0.25, 0), Vector3(s * 0.1, -0.8, 0), Vector3(s * 0.06, -1.6, 0)], [1.0, 1.0, 0.78], WOOD, 14, 3)
	_mi(hp, ub)
	var kn = rig._pivot(hp, Vector3(s * 0.06, -1.6, 0), "diz")
	var lb = MB.new()
	Loft.tube(lb, [Vector3(0, 0, 0), Vector3(0, -0.8, 0.02), Vector3(0, -1.45, 0)], [0.8, 0.72, 0.6], WOOD, 14, 3)
	Loft.blob(lb, Vector3(0, -1.6, -0.35), Vector3(0, -0.1, -1), 1.4, [Vector2(0.35, 0.22), Vector2(0.55, 0.28), Vector2(0.5, 0.24), Vector2(0.3, 0.12)], WOOD, 10)
	_mi(kn, lb)
	legs.append({"hip": hp, "kn": kn, "side": s})


## Gövdeye sarmal sarılı tahta ejder: göbekten başlayıp gövdeyi iki kez dolanır, sağ omzun arkasından baş uzatır
func _build_dragon() -> void:
	var pts = []
	var rr = []
	var n = 26
	for k in n:
		var q = k / float(n - 1)
		var a = q * TAU * 1.6 + PI * 0.6
		var y = 0.2 + q * 3.7
		var rx = lerpf(1.55, 2.5, q)
		var rz = lerpf(1.2, 1.55, q)
		pts.append(Vector3(cos(a) * rx, y, sin(a) * rz + 0.2))
		rr.append(lerpf(0.32, 0.55, sin(q * PI * 0.9 + 0.1)))
	var end: Vector3 = pts[n - 1]
	var neck_top = Vector3(2.2, 5.3, 0.3)
	pts.append(end.lerp(neck_top, 0.5) + Vector3(0, 0, 0.4))
	rr.append(0.5)
	pts.append(neck_top)
	rr.append(0.45)
	var mb = MB.new()
	Loft.tube(mb, pts, rr, WOOD.darkened(0.04), 12, 3)
	for k in 30:   # sırt dikenleri
		var i = int(k * (pts.size() - 2) / 30.0)
		var p: Vector3 = pts[i]
		var out = Vector3(p.x, 0, p.z - 0.2).normalized()
		mb.add("cone", p + out * float(rr[i]) * 0.9 + Vector3.UP * 0.1, Vector3(0.18, 0.5, 0.18), WOOD.darkened(0.12), Vector3(0, 0, 0), 6)
	_mi(torso, mb)
	# ejder başı (ref: uzun burun, geriye boynuzlar, küçük gözler, alt çenede diş)
	dragon_head = rig._pivot(torso, neck_top, "ejder_bas")
	var hb = MB.new()
	Loft.blob(hb, Vector3(0, 0.1, -0.2), Vector3(0, -0.15, -1), 2.3, [Vector2(0.45, 0.4), Vector2(0.55, 0.45), Vector2(0.4, 0.3), Vector2(0.2, 0.15)], WOOD, 12)
	Loft.blob(hb, Vector3(0, -0.25, -0.5), Vector3(0, -0.25, -1), 1.8, [Vector2(0.35, 0.18), Vector2(0.42, 0.2), Vector2(0.3, 0.14), Vector2(0.12, 0.06)], WOOD.darkened(0.05), 10)   # alt çene
	for s in [-1.0, 1.0]:
		Loft.tube(hb, [Vector3(s * 0.25, 0.4, 0.2), Vector3(s * 0.35, 0.75, 0.9), Vector3(s * 0.3, 0.9, 1.6)], [0.13, 0.09, 0.01], WOOD.darkened(0.15), 6, 3)   # boynuz
		hb.add("cone", Vector3(s * 0.22, -0.3, -1.6), Vector3(0.07, 0.22, 0.07), Color(0.9, 0.86, 0.72), Vector3(180, 0, 0), 5)   # diş
	_mi(dragon_head, hb)
	var em = StandardMaterial3D.new()
	em.albedo_color = EYE
	em.emission_enabled = true
	em.emission = EYE
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var eb = MB.new()
	for s in [-1.0, 1.0]:
		eb.add("sphere", Vector3(s * 0.33, 0.32, -0.75), Vector3(0.12, 0.08, 0.1), EYE, Vector3.ZERO, 8)
	rig._mesh(dragon_head, eb, em)


# ------------------------------------------------------------------ pozlar (rax/lax: negatif kolu öne-yukarı kaldırır)
func _pose(nm: String) -> Dictionary:
	match nm:
		"rise":   # topraktan çıkarken: kollar yukarı, baş kalkık
			return {"hy": 3.0, "tx": -0.1, "hx": -0.2, "rax": -2.4, "raz": 0.3, "rex": -0.4, "lax": -2.4, "laz": 0.3, "lex": -0.4, "lx": 0.4, "kx": -0.6}
		"pull_r":   # sağ yumruk geride, gövde döner
			return {"hy": 3.4, "tx": -0.3, "hx": 0.2, "rax": -1.6, "raz": -0.2, "rex": -1.6, "lax": -0.8, "laz": 0.2, "lex": -0.6, "lx": 0.5, "kx": -0.7, "ty": 0.35}
		"punch_r":   # sağ yumruk aşağı-ileri indirilir
			return {"hy": 2.9, "tx": -0.75, "hx": 0.45, "rax": -1.15, "raz": 0.05, "rex": -0.05, "lax": -0.3, "laz": 0.3, "lex": -0.7, "lx": 0.8, "kx": -1.1, "ty": -0.25}
		"pull_l":
			return {"hy": 3.4, "tx": -0.3, "hx": 0.2, "rax": -0.8, "raz": 0.2, "rex": -0.6, "lax": -1.6, "laz": -0.2, "lex": -1.6, "lx": 0.5, "kx": -0.7, "ty": -0.35}
		"punch_l":
			return {"hy": 2.9, "tx": -0.75, "hx": 0.45, "rax": -0.3, "raz": 0.3, "rex": -0.7, "lax": -1.15, "laz": 0.05, "lex": -0.05, "lx": 0.8, "kx": -1.1, "ty": 0.25}
		_:   # stand: kambur, dev kollar önde sarkık
			return {"hy": 3.2, "tx": -0.4, "hx": 0.45, "rax": 0.3, "raz": 0.12, "rex": -0.5, "lax": 0.3, "laz": 0.12, "lex": -0.5, "lx": 0.6, "kx": -0.85}


func _apply(p: Dictionary) -> void:
	hips.position.y = p["hy"]
	torso.rotation = Vector3(p["tx"], float(p.get("ty", 0.0)), 0)
	head.rotation.x = p["hx"]
	for a in arms:
		var r = a["side"] > 0
		a["sh"].rotation = Vector3(p["rax"] if r else p["lax"], 0, a["side"] * (p["raz"] if r else p["laz"]))
		a["el"].rotation.x = p["rex"] if r else p["lex"]
	for l in legs:
		l["hip"].rotation = Vector3(-p["lx"] * 0.5, 0, l["side"] * 0.2)
		l["kn"].rotation.x = -p["kx"] * 0.9
	dragon_head.rotation = Vector3(-0.2 + sin(t * 1.3) * 0.08, -0.35 + sin(t * 0.8) * 0.1, 0)


func set_pose(nm: String, dur := 0.5) -> void:
	pose_from = _blend(pose_from, pose_to, pose_k) if not pose_to.is_empty() else _pose(nm)
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


func _process(dt: float) -> void:
	t += dt
	if pose_k < 1.0:
		pose_k = minf(1.0, pose_k + dt / pose_dur)
	var p = _blend(pose_from, pose_to, pose_k) if pose_k < 1.0 else pose_to
	if not p.is_empty():
		_apply(p)


func fist_pos(right := true) -> Vector3:
	var a = arms[1 if right else 0]
	return a["el"].global_transform * Vector3(0, -2.7, -0.2)


func dragon_mouth() -> Vector3:
	return dragon_head.global_transform * Vector3(0, -0.1, -2.2)
