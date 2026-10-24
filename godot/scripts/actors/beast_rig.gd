class_name BeastRig
extends Node3D
## Kuyruklu canavar iskeleti: ayrı parçalar (gövde, göğüs, baş, çene, kollar, bacaklar, kuyruk zincirleri)
## prosedürel animasyonla oynar: nefes, yürüyüş, kuyruk dalgası, kükreme, pençe, tepme, kuyruk süpürme, top şarjı, diz çökme.
## Model "tasarım birimi"nde kurulur (D = 10 birim boy) ve gerçek boya ölçeklenir. İleri yön -Z.

const D := 10.0

var id = ""
var height_m = 50.0
var hips: Node3D          # gövde kökü (her şey buna bağlı)
var chest: Node3D
var head: Node3D
var jaw: Node3D
var mouth: Node3D         # top/nefes çıkış noktası (başın içinde)
var arms: Array = []      # [{"sh": omuz, "el": dirsek, "side": ±1}]
var legs: Array = []      # [{"hip": kalça, "kn": diz, "side": ±1, "front": bool}]
var tails: Array = []     # her kuyruk: [segment Node3D...]
var tail_cfg: Array = []  # her kuyruk: {"yaw","pitch","len","amp"}
var weak_points: Array = []   # mühür noktaları (Node3D)
var colliders: Array = []
var glow_mat: StandardMaterial3D
var t = 0.0
var move_speed = 0.0      # 0..1 yürüyüş
var action = ""           # roar, swipe_l, swipe_r, stomp, tail, ball, kneel, charge
var action_t = 0.0
var action_dur = 1.0
var quadruped = false
var upright = true
var hips_base = -1e9


func design_scale() -> float:
	return height_m / D


## Eylem başlat (süre saniye). Animasyon _process'te uygulanır.
func play_action(a: String, dur: float) -> void:
	action = a
	action_t = 0.0
	action_dur = maxf(0.05, dur)


func action_k() -> float:
	return clampf(action_t / action_dur, 0.0, 1.0)


func mouth_pos() -> Vector3:
	return mouth.global_position if mouth else global_position + Vector3.UP * height_m * 0.8


# ------------------------------------------------------------------ kurulum yardımcıları
func _pivot(parent: Node3D, pos: Vector3, nm := "") -> Node3D:
	var n = Node3D.new()
	n.name = nm if nm != "" else "p"
	n.position = pos
	parent.add_child(n)
	return n


func _mesh(parent: Node3D, mb: MB, mat: Material = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(mat if mat else Props.toon())
	parent.add_child(mi)
	return mi


## İki nokta arası incelen uzuv (silindir + eklem küreleri)
static func limb(mb: MB, a: Vector3, b: Vector3, ra: float, rb: float, col: Color, seg := 10) -> void:
	# pürüzsüz, kas şişkinlikli tüp (Loft) — eski silindir yığını yerine
	if (b - a).length() < 0.001:
		return
	Loft.limb(mb, a, b, ra, rb, col, maxi(seg, 12))


## Pençe/tırnak: uca doğru sivri koni
static func claw(mb: MB, base: Vector3, dir: Vector3, length: float, r: float, col: Color) -> void:
	var d = dir.normalized()
	var bend = d.cross(Vector3.RIGHT if absf(d.x) < 0.9 else Vector3.UP).normalized()
	Loft.tube(mb, [base, base + d * length * 0.55 + bend * length * 0.06, base + d * length], [r, r * 0.55, r * 0.06], col, 8, 2, true, false)


## Göz: parlayan (ışıksız) badem göz + bebek
func _eye(parent: Node3D, pos: Vector3, size: Vector3, iris: Color, pupil: Color, rot := Vector3.ZERO, slit := true) -> void:
	var mb = MB.new()
	mb.add("sphere", pos, size, iris, rot, 10)
	if slit:
		mb.add("box", pos + Vector3(0, 0, -size.z * 0.42), Vector3(size.x * 0.12, size.y * 0.9, size.z * 0.2), pupil, rot)
	else:
		mb.add("sphere", pos + Vector3(0, 0, -size.z * 0.4), size * Vector3(0.35, 0.45, 0.3), pupil, rot, 8)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	parent.add_child(mi)


## Kuyruk zinciri: segment başına ayrı pivot (dalga animasyonu için)
func _tail(base: Node3D, yaw_deg: float, pitch_deg: float, n: int, length: float, r0: float, r_mid: float, col: Color, tip: Color, style := "fur") -> void:
	var root = _pivot(base, Vector3.ZERO, "tail")
	root.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0)
	var segs = []
	var parent = root
	var seg_len = length / n
	for i in n:
		var k = float(i) / max(1, n - 1)
		var piv = _pivot(parent, Vector3(0, 0, seg_len) if i > 0 else Vector3.ZERO, "s%d" % i)
		var mb = MB.new()
		var r = lerpf(r0, r_mid, sin(minf(1.0, k * 1.6) * PI * 0.5)) * (1.0 - pow(k, 3.0) * 0.85)
		var c = col.lerp(tip, smoothstep(0.55, 1.0, k))
		match style:
			"fur":  # kabarık kuyruk: pürüzsüz tüp + uca doğru açık renk + tüy uçları
				var kn = minf(1.0, float(i + 1) / max(1, n - 1))   # son segmentte 1'i aşıp negatif yarıçap veriyordu (uçta balon)
				var rn = maxf(r0 * 0.06, lerpf(r0, r_mid, sin(minf(1.0, kn * 1.6) * PI * 0.5)) * (1.0 - pow(kn, 3.0) * 0.85) * (0.15 if i == n - 1 else 1.0))
				var cn = col.lerp(tip, smoothstep(0.55, 1.0, kn))
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.15), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.15)], [r * 1.05, (r + rn) * 0.55 * 1.1, rn * 1.0], [c, c.lerp(cn, 0.5), cn], 14, 2, true, true)
				for f in (3 if i < n - 2 else 0):
					var fa = TAU * f / 3.0 + i
					claw(mb, Vector3(cos(fa) * r * 0.8, sin(fa) * r * 0.8, seg_len * 0.6), Vector3(cos(fa) * 0.6, sin(fa) * 0.6, 1.0), r * 0.9, r * 0.35, c.lerp(cn, 0.5))
			"sleek":  # pürüzsüz, kalın, sivri uçlu kuyruk (tüy dikeni yok)
				var kn2 = minf(1.0, float(i + 1) / max(1, n - 1))
				var rn2 = maxf(r0 * 0.05, lerpf(r0, r_mid, sin(minf(1.0, kn2 * 1.6) * PI * 0.5)) * (1.0 - pow(kn2, 2.2) * 0.9) * (0.12 if i == n - 1 else 1.0))
				var cn2 = col.lerp(tip, smoothstep(0.6, 1.0, kn2))
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.15), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.15)], [r, (r + rn2) * 0.52, rn2], [c, c.lerp(cn2, 0.5), cn2], 14, 2, true, true)
			"sand":
				var ink = Color(0.1, 0.12, 0.3)
				var fn = func(tt: float, a: float, _d: Vector3) -> Color:
					var w = sin((tt + i) * PI * 2.0 + sin(a * 3.0) * 0.6)
					return ink if (absf(w) < 0.16 or (a > 0.6 and a < 2.4 and absf(sin(a * 5.0 + tt * 9.0)) < 0.08)) else c
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.98, r * 0.92], c, 14, 3, true, true, fn)
			"shrimp":  # zırh halkalı
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.05), Vector3(0, 0, seg_len * 0.55), Vector3(0, 0, seg_len * 1.05)], [r * 0.95, r * 1.08, r * 0.9], [c.darkened(0.15), c, c.darkened(0.2)], 12, 2, true, true)
			"spike":  # dikenli maymun kuyruğu
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
				claw(mb, Vector3(0, r * 0.8, seg_len * 0.5), Vector3(0, 1, 0.4), r * 1.4, r * 0.35, Color(0.25, 0.2, 0.15))
			"tentacle":  # ahtapot kolu + vantuz
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
				for v in 2:
					mb.add("sphere", Vector3(0, -r * 0.88, seg_len * (0.25 + v * 0.5)), Vector3(r * 0.6, r * 0.25, r * 0.6), c.lightened(0.4), Vector3.ZERO, 8)
			"slug":
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
			"wing":  # böcek kanadı: ince yarı saydam yaprak (tek parça, ilk segmentte)
				if i == 0:
					mb.add("sphere", Vector3(0, 0, length * 0.5), Vector3(r_mid * 2.2, 0.06, length), c, Vector3.ZERO, 14)
					mb.add("box", Vector3(0, 0.04, length * 0.5), Vector3(0.08, 0.04, length * 0.95), Color(0.25, 0.45, 0.15))
			"flame":
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
		if not mb.is_empty():
			if style == "wing":
				var wm = StandardMaterial3D.new()
				wm.vertex_color_use_as_albedo = true
				wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				wm.albedo_color = Color(1, 1, 1, 0.75)
				wm.cull_mode = BaseMaterial3D.CULL_DISABLED
				wm.emission_enabled = true
				wm.emission = Color(1.0, 0.5, 0.1) * 0.9
				_mesh(piv, mb, wm)
			else:
				_mesh(piv, mb)
		segs.append(piv)
		parent = piv
		if style == "wing":
			break
	tails.append(segs)
	tail_cfg.append({"yaw": deg_to_rad(yaw_deg), "pitch": deg_to_rad(pitch_deg), "amp": 0.16 if style != "wing" else 0.35, "phase": randf() * TAU, "style": style, "root": root})


## Tırmanma çarpıştırıcısı (dünya katmanı 1): oyuncu üstünde koşabilir / duvar koşusu yapabilir.
## Ölçekli düğüm altında fizik güvenilir değil: işaretçi parçaya bağlı, gövde üst düzeyde ve ölçeksiz, her fizik karesinde işaretçiyi izler.
func _collider(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var mk = _pivot(parent, pos, "carpisma")
	mk.set_meta("size", size)
	colliders.append(mk)


## Model ölçeklendikten sonra çağrılır: gerçek boyutlu, ölçeksiz, üst düzey gövdeler kurar.
## (Ölçekli düğüm altında ve her karede ışınlanan gövdelerden karakter geçip düşüyor: gövde yalnızca
## işaretçi belirgin hareket edince yeniden konumlanır.)
func finalize_colliders() -> void:
	var s = design_scale()
	for mk in colliders:
		var b = AnimatableBody3D.new()
		b.collision_layer = 1
		b.collision_mask = 2
		b.top_level = true
		b.sync_to_physics = true
		var cs = CollisionShape3D.new()
		var bx = BoxShape3D.new()
		bx.size = (mk.get_meta("size") as Vector3) * s
		cs.shape = bx
		b.add_child(cs)
		mk.add_child(b)
		mk.set_meta("body", b)
		mk.set_meta("last", Transform3D())


func remove_colliders() -> void:
	for mk in colliders:
		if mk.has_meta("body") and is_instance_valid(mk.get_meta("body")):
			mk.get_meta("body").queue_free()
	colliders.clear()


func _physics_process(_dt: float) -> void:
	for mk in colliders:
		var b = mk.get_meta("body", null)
		if b == null or not is_instance_valid(b) or not mk.is_inside_tree():
			continue
		var want = Transform3D(mk.global_transform.basis.orthonormalized(), mk.global_position)
		var last: Transform3D = mk.get_meta("last")
		if want.origin.distance_to(last.origin) > 0.01 or want.basis.z.dot(last.basis.z) < 0.99999:
			b.global_transform = want
			mk.set_meta("last", want)


func _weak(parent: Node3D, pos: Vector3) -> void:
	var n = _pivot(parent, pos, "weak")
	var mb = MB.new()
	mb.add("torus", Vector3.ZERO, Vector3(0.9, 0.9, 0.9), Color(1.0, 0.95, 0.6), Vector3(90, 0, 0), 16)
	mb.add("sphere", Vector3.ZERO, Vector3(0.35, 0.35, 0.35), Color(1.0, 0.85, 0.3), Vector3.ZERO, 8)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(1.0, 0.8, 0.3)
	m.no_depth_test = false
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	weak_points.append(n)


## Mühür noktalarını göster/gizle (canavar sersemleyince belirginleşir)
func show_weak(on: bool) -> void:
	for w in weak_points:
		if is_instance_valid(w):
			w.visible = on


# ------------------------------------------------------------------ animasyon
func _process(dt: float) -> void:
	t += dt
	if action != "":
		action_t += dt
		if action_t >= action_dur and action != "kneel":
			action = ""
	var k = action_k()
	var s = sin(k * PI)               # 0 → 1 → 0
	var walk = move_speed
	var wt = t * (2.2 if not quadruped else 2.8)
	# nefes
	if chest:
		var br = 1.0 + sin(t * 1.3) * 0.025
		chest.scale = Vector3(br, br, br)
	# gövde: yürüyüş sallanması, tepme zıplaması, diz çökme
	if hips:
		var y = abs(sin(wt)) * 0.15 * walk
		var pitch = 0.0
		if action == "stomp":
			y += (sin(k * PI * 1.0) * 1.4) if k < 0.6 else -0.3 * (1.0 - k)
			pitch = -0.12 * s
		elif action == "kneel":
			y -= minf(1.0, action_t * 1.2) * (2.2 if upright else 1.2)
			pitch = 0.25 * minf(1.0, action_t)
		elif action == "charge":
			pitch = 0.22 * s
		elif action == "ball":
			pitch = (-0.15 if k < 0.7 else 0.2) * minf(1.0, action_t * 2.0)
		elif action == "tail":
			hips.rotation.y = sin(k * TAU) * 1.2
		if action != "tail":
			hips.rotation.y = lerp_angle(hips.rotation.y, 0.0, minf(1.0, dt * 4.0))
		if hips_base < -1e8:
			hips_base = hips.position.y
		hips.position.y = hips_base + y
		hips.rotation.x = lerp_angle(hips.rotation.x, pitch, minf(1.0, dt * 6.0))
	# baş: etrafa bakma, kükreme, top şarjı
	if head:
		var hx = sin(t * 0.4) * 0.05
		var hy = sin(t * 0.27) * 0.15
		if action == "roar":
			hx = -0.55 * s
		elif action == "ball":
			hx = -0.2 if k < 0.75 else 0.15
		elif action == "kneel":
			hx = 0.35
		head.rotation.x = lerp_angle(head.rotation.x, hx, minf(1.0, dt * 6.0))
		head.rotation.y = lerp_angle(head.rotation.y, hy, minf(1.0, dt * 3.0))
	if jaw:
		var open = 0.06 + sin(t * 1.3) * 0.03
		if action == "roar":
			open = 0.6 * s
		elif action == "ball":
			open = 0.5 * minf(1.0, action_t * 2.0)
		elif action in ["swipe_l", "swipe_r", "charge"]:
			open = 0.25 * s
		jaw.rotation.x = lerp_angle(jaw.rotation.x, open, minf(1.0, dt * 10.0))
	# kollar: yürüyüş salınımı + pençe savurma
	for a in arms:
		var sh: Node3D = a["sh"]
		var side: float = a["side"]
		var rx = sin(wt + (0.0 if side > 0 else PI)) * 0.35 * walk
		var rz = 0.0
		if (action == "swipe_l" and side > 0) or (action == "swipe_r" and side < 0):
			rx = -1.6 * sin(minf(1.0, k * 1.6) * PI * 0.5) + (2.2 * maxf(0.0, k - 0.45))
			rz = -0.6 * side * s
		elif action == "roar":
			rx = -0.5 * s
			rz = 0.5 * side * s
		elif action == "ball":
			rx = -0.7 * minf(1.0, action_t * 2.0)
			rz = -0.25 * side
		elif action == "kneel":
			rx = -0.4
		sh.rotation.x = lerp_angle(sh.rotation.x, rx, minf(1.0, dt * 8.0))
		sh.rotation.z = lerp_angle(sh.rotation.z, rz, minf(1.0, dt * 8.0))
		if a.has("el"):
			var el: Node3D = a["el"]
			el.rotation.x = lerp_angle(el.rotation.x, -0.25 * walk - (0.6 if action == "kneel" else 0.0), minf(1.0, dt * 6.0))
	# bacaklar
	for l in legs:
		var hp: Node3D = l["hip"]
		var phase = (0.0 if l["side"] > 0 else PI) + (PI if l.get("front", false) else 0.0)
		var rx2 = sin(wt + phase) * 0.45 * walk
		if action == "stomp" and l["side"] > 0 and not l.get("front", false):
			rx2 = -1.0 * sin(minf(1.0, k * 1.7) * PI)
		elif action == "kneel":
			rx2 = 0.5
		hp.rotation.x = lerp_angle(hp.rotation.x, rx2, minf(1.0, dt * 8.0))
		if l.has("kn"):
			var kn: Node3D = l["kn"]
			kn.rotation.x = lerp_angle(kn.rotation.x, maxf(0.0, -sin(wt + phase)) * 0.6 * walk + (0.9 if action == "kneel" else 0.0), minf(1.0, dt * 8.0))
	# kuyruklar: yayılı dalga + kuyruk süpürmesinde savrulma
	for i in tails.size():
		var cfg: Dictionary = tail_cfg[i]
		var segs: Array = tails[i]
		var amp: float = cfg["amp"]
		var sweep = 0.0
		if action == "tail":
			sweep = sin(k * TAU) * 0.5
		var root: Node3D = cfg["root"]
		root.rotation.y = cfg["yaw"] + sin(t * 0.7 + cfg["phase"]) * 0.12 + sweep
		root.rotation.x = cfg["pitch"] + sin(t * 0.9 + cfg["phase"]) * 0.06 - (0.4 if action == "roar" else 0.0) * s
		for j in range(1, segs.size()):
			var sg: Node3D = segs[j]
			sg.rotation.y = sin(t * 1.4 - j * 0.55 + cfg["phase"]) * amp + sweep * 0.25
			sg.rotation.x = sin(t * 1.1 - j * 0.45 + cfg["phase"] * 1.3) * amp * 0.7 - 0.05
		if cfg["style"] == "wing" and segs.size() > 0:
			segs[0].rotation.z = sin(t * (14.0 if action == "charge" else 3.0) + cfg["phase"]) * amp
