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
var tail_curl := -0.05     # segment başına sabit eğim (radyan): negatif yukarı kıvırır, pozitif aşağı sarkıtır
var tail_cfg: Array = []  # her kuyruk: {"yaw","pitch","len","amp"}
var weak_points: Array = []   # mühür noktaları (Node3D)
var colliders: Array = []
var glow_mat: StandardMaterial3D
var t = 0.0
var move_speed = 0.0      # 0..1 yürüyüş
var action = ""           # roar, swipe_l, swipe_r, stomp, tail, ball, kneel, charge, leap, bite, slam
var action_t = 0.0
var action_dur = 1.0
var quadruped = false
var upright = true
var hips_base = -1e9
# hareket durumu (TailedBeast / BeastCloak ayarlar): koşu, savaş duruşu, hedefe bakış, havada
var run := 0.0            # 0..1 koşu/dörtnal (yumuşatılmış)
var run_target := 0.0
var aggro := false        # savaş duruşu: alçak, kamburlaşmış, kuyruk kamçılar, baş hedefe döner
var stance := 0.0
var look_yaw := 0.0       # başın hedefe dönüşü (radyan, gövdeye göre)
var airborne := false     # oyuncu tam dönüşümde zıplarken
var gp := 0.0             # adım fazı
var _last_step := 0
# bekleme ara hareketleri (etrafa bakınma, silkinme, hırlama, pençe, esneme)
var fid := ""
var fid_t := 0.0
var fid_dur := 1.0
var fid_wait := 3.0
var fid_side := 1.0


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
				var ink = Color(0.14, 0.18, 0.46)
				var fn = func(tt: float, a: float, _d: Vector3) -> Color:
					var w = sin((tt + i) * PI * 2.0 + sin(a * 3.0) * 0.6)
					return c if w > -2.0 else ink   # köşe rengi desen lekeli görünüyordu: düz renk, desen pullarda
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.98, r * 0.92], c, 14, 3, true, true, fn)
				# üst üste binen sivri kum pulları (yaprak gibi geriye bakan plakalar, lacivert kenarlı)
				for pk in 9:
					var ang = lerpf(-2.7, 2.7, pk / 8.0) + (0.3 if i % 2 == 1 else 0.0)
					var nrm = Vector3(sin(ang), cos(ang), 0)
					var pb = Basis(Vector3.FORWARD, -ang) * Basis(Vector3.RIGHT, deg_to_rad(-12))
					var lb = pb * Basis(Vector3.RIGHT, deg_to_rad(80))
					mb.add_xf("cone", Transform3D(lb * Basis.from_scale(Vector3(r * 0.85, seg_len * 1.25, r * 0.22)), nrm * r * 0.92 + Vector3(0, 0, seg_len * 0.55)), c.lightened(0.05), 8)   # büyük örtüşen yaprak pul
					mb.add_xf("cone", Transform3D(lb * Basis.from_scale(Vector3(r * 0.32, seg_len * 0.55, r * 0.1)), nrm * r * 1.06 + Vector3(0, 0, seg_len * 0.55)), ink, 5)   # pulun lacivert fırça izi
			"shrimp":  # karides kuyruğu: üstte gri zırh plakası + iki yanda diken, altta kırmızı boğumlu et
				var fr = Color(0.55, 0.13, 0.15)
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.05), Vector3(0, 0, seg_len * 0.55), Vector3(0, 0, seg_len * 1.05)], [r * 0.95, r * 1.04, r * 0.9], c, 12, 2, true, true,
					func(_t: float, aa: float, _d: Vector3) -> Color: return fr.darkened(0.15 * _t) if sin(aa) < -0.25 else c)
				mb.add_xf("sphere", Transform3D(Basis.from_scale(Vector3(r * 1.25, r * 0.55, seg_len * 0.62)), Vector3(0, r * 0.62, seg_len * 0.55)), c.lightened(0.06), 10)   # sırt plakası
				for sv in [-1.0, 1.0]:
					claw(mb, Vector3(sv * r * 1.05, r * 0.3, seg_len * 0.7), Vector3(sv, 0.35, 0.6).normalized(), r * 1.1, r * 0.3, c.lightened(0.1))
				claw(mb, Vector3(0, r * 1.05, seg_len * 0.75), Vector3(0, 0.8, 0.6).normalized(), r * 0.9, r * 0.25, c.lightened(0.1))
			"spike":  # dikenli maymun kuyruğu
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
				# bej kemik plaka + koyu uç (Son Gokū kuyruk dikenleri)
				var pdir = Vector3(0, 1, 0.75).normalized()
				var pb = Vector3(0, r * 0.75, seg_len * 0.35)
				claw(mb, pb, pdir, r * 1.25, r * 0.45, Color(0.86, 0.76, 0.58))
				claw(mb, pb + pdir * r * 0.95, pdir, r * 0.5, r * 0.17, Color(0.12, 0.08, 0.06))
			"tentacle":  # ahtapot kolu + vantuz
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
				for v in 2:   # iki sıra beyaz halka vantuz (alt yüz): dış halka açık, içi koyu çukur
					var vx = r * 0.42 * (1.0 if v == 0 else -1.0)
					var vp = Vector3(vx, -r * 0.82, seg_len * (0.25 + v * 0.5))
					var vs = r * 0.62
					mb.add("sphere", vp, Vector3(vs, vs * 0.32, vs), Color(0.93, 0.9, 0.88), Vector3(0, 0, -25 if v == 0 else 25), 10)
					mb.add("sphere", vp + Vector3(0, -vs * 0.12, 0), Vector3(vs * 0.55, vs * 0.3, vs * 0.55), c.darkened(0.25), Vector3(0, 0, -25 if v == 0 else 25), 8)
			"slug":  # kalın pürüzsüz sümüklü kuyruk: uca doğru yassılaşıp kaşık gibi genişler, sarkan damlalar
				var fl = smoothstep(0.55, 1.0, k)   # uçta yassılaşma
				var rr = maxf(r, r0 * 0.55) * (1.0 + fl * 0.5)
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [Vector2(rr, rr * (1.0 - fl * 0.65)), Vector2(rr, rr * (1.0 - fl * 0.65)), Vector2(rr * (0.9 if i < n - 1 else 0.5), rr * (1.0 - fl * 0.7))], c, 14, 2, true, true)
				if i % 2 == 1:
					var dl = r0 * 0.9
					Loft.tube(mb, [Vector3(rr * 0.3, -rr * 0.8, seg_len * 0.4), Vector3(rr * 0.32, -rr * 0.8 - dl * 0.6, seg_len * 0.45), Vector3(rr * 0.3, -rr * 0.8 - dl, seg_len * 0.45)], [r0 * 0.14, r0 * 0.07, r0 * 0.11], c, 6, 2)
			"wing":  # böcek kanadı: ince yarı saydam yaprak (tek parça, ilk segmentte)
				if i == 0:   # yaprak kanat: uzun sivri yaprak, kalın açık yeşil orta damar + yanlara çatallanan ince damarlar (tip = damar rengi)
					var lp: Array = []
					var lr: Array = []
					for q in 7:
						var u = q / 6.0
						lp.append(Vector3(0, 0, length * u))
						lr.append(Vector2(maxf(0.05, r_mid * sin(pow(u, 0.75) * PI) * (1.0 - u * 0.25)), 0.05))
					Loft.tube(mb, lp, lr, [c.darkened(0.25), c, c, c.lightened(0.08), c, c.darkened(0.1), c.darkened(0.3)], 10, 3, true, true)
					Loft.tube(mb, [Vector3(0, 0.07, 0), Vector3(0, 0.07, length * 0.5), Vector3(0, 0.06, length * 0.98)], [Vector2(0.16, 0.06), Vector2(0.11, 0.05), Vector2(0.03, 0.03)], tip, 6, 3)
					for q in 6:
						var u = 0.15 + q * 0.13
						var wd = r_mid * sin(pow(u, 0.75) * PI) * (1.0 - u * 0.25)
						for sv in [-1.0, 1.0]:
							Loft.tube(mb, [Vector3(0, 0.07, length * u), Vector3(sv * wd * 0.5, 0.07, length * (u + 0.06)), Vector3(sv * wd * 0.92, 0.07, length * (u + 0.1))], [0.05, 0.035, 0.015], tip.darkened(0.15), 5, 2)
			"flame":  # alev kuyruğu: gövde + her segmentte dışa savrulan alev dilleri, açık mavi/koyu
				Loft.tube(mb, [Vector3(0, 0, -seg_len * 0.2), Vector3(0, 0, seg_len * 0.5), Vector3(0, 0, seg_len * 1.2)], [r, r * 0.97, r * 0.9], c, 12, 2, true, true)
				for f in 4:
					var fa = TAU * f / 4.0 + i * 0.9
					var fd = Vector3(cos(fa), sin(fa), 0.9).normalized()
					var fl2 = r * 1.1
					Loft.tube(mb, [Vector3(cos(fa), sin(fa), 0) * r * 0.8 + Vector3(0, 0, seg_len * 0.4), Vector3(cos(fa), sin(fa), 0) * r * 0.8 + fd * fl2 * 0.5 + Vector3(0, 0, seg_len * 0.4), Vector3(cos(fa), sin(fa), 0) * r * 0.8 + fd * fl2 + Vector3(0, 0, seg_len * 0.8)], [r * 0.3, r * 0.18, 0.02], c.lerp(tip, 0.4) if f % 2 == 0 else Color(0.02, 0.02, 0.06), 6, 2, false, false)
		if not mb.is_empty():
			if style == "wing":
				var wm = StandardMaterial3D.new()
				wm.vertex_color_use_as_albedo = true
				wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				wm.albedo_color = Color(1, 1, 1, 0.92)
				wm.cull_mode = BaseMaterial3D.CULL_DISABLED
				wm.emission_enabled = true
				wm.emission = Color(1.0, 0.5, 0.1) * 0.25
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
	var walk: float = move_speed
	run = move_toward(run, run_target, dt * 2.5)
	stance = move_toward(stance, 1.0 if aggro else 0.0, dt * 1.5)
	var air = 0.0
	if action == "leap":
		air = clampf(sin(clampf((k - 0.22) / 0.62, 0.0, 1.0) * PI), 0.0, 1.0)
	if airborne:
		air = maxf(air, 1.0)
	# adım fazı: yürüyüşte yavaş, koşuda hızlı (canavara göre ağırlık)
	var heavy = 0.8 if id in ["isobu", "son_goku", "gyuki", "shukaku"] else 1.0
	var freq = (1.7 + 1.6 * run) * heavy * (1.25 if quadruped else 1.0)
	if walk > 0.02 and air < 0.5:
		gp += dt * freq * (0.6 + 0.4 * walk) * TAU * 0.5
	var wt = gp
	var gallop = run if quadruped else 0.0
	# --- bekleme: ağırlık aktarma + nefes + ara hareketler (kazık gibi durmasın)
	var idle = clampf(1.0 - walk * 3.0, 0.0, 1.0) * (1.0 if action == "" else 0.0) * (1.0 - air)
	var fk = 0.0
	var fs = 0.0
	if fid != "":
		fid_t += dt
		if fid_t >= fid_dur or idle < 0.5:
			fid = ""
		else:
			fk = fid_t / fid_dur
			fs = sin(fk * PI)
	elif idle > 0.9:
		fid_wait -= dt
		if fid_wait <= 0.0:
			fid_wait = randf_range(3.0, 6.5)
			fid = (["look", "growl"] if aggro else ["look", "look", "shake", "growl", "paw", "stretch"]).pick_random()
			fid_dur = {"look": 2.8, "shake": 1.2, "growl": 1.8, "paw": 1.8, "stretch": 2.6}[fid]
			fid_t = 0.0
			fid_side = 1.0 if randf() < 0.5 else -1.0
	var sway = sin(t * 0.55)                       # ağırlık bir yandan öbürüne
	var breath = sin(t * (1.3 + stance * 0.8))
	var spine = sin(wt + 1.2) * gallop            # dörtnalda omurga toplanır / açılır
	# --- adım tozu + yer sarsıntısı (her adım)
	if walk > 0.15 and air < 0.3:
		var stp = int(floor(wt / PI))
		if stp != _last_step:
			_last_step = stp
			_footfall(stp % 2 == 0, 0.6 + 0.8 * run)
	# nefes: savaşta daha derin
	if chest:
		var br = 1.0 + sin(t * (1.3 + stance * 0.8)) * (0.025 + stance * 0.015)
		chest.scale = Vector3(br, br, br)
	# --- gövde
	if hips:
		var y = abs(sin(wt)) * (0.15 * walk + 0.35 * run) * heavy
		var pitch = 0.0
		var roll = idle * sway * (0.02 if quadruped else 0.035)
		y += idle * breath * 0.05
		if fid == "stretch":
			y += fs * (-0.25 if quadruped else 0.12)
			pitch += fs * (0.1 if quadruped else -0.08)
		elif fid == "growl":
			y -= fs * 0.12
			pitch += fs * 0.05
		# savaş duruşu: gövde alçalır, öne eğilir (dört ayaklı pusuya yatar, dik canavar kamburlaşır)
		y -= stance * (0.45 if quadruped else 0.3)
		pitch += stance * (0.08 if quadruped else 0.12)
		# koşu: öne yatma; dörtnalda omurga dalgası
		pitch += run * (0.1 if quadruped else 0.2) + spine * 0.1
		if upright and not quadruped:
			roll = sin(wt) * (0.05 + (0.1 if id == "shukaku" else 0.0)) * walk   # dik canavar ağırlığını yandan yana verir (Shukaku paytak)
		if id == "chomei" and (walk > 0.05 or air > 0.0):
			y += (1.2 + sin(t * 9.0) * 0.12) * maxf(minf(1.0, walk * 2.0), air)   # kanatlanıp süzülür
		if id == "saiken":
			var u = sin(t * 2.4 + wt) * (0.04 + 0.06 * walk)
			hips.scale = Vector3(1.0 - u * 0.4, 1.0 + u, 1.0 - u * 0.6)   # sümük gövde dalgalanır
		# sıçrama: çömel → havalan → kon (iniş darbesi)
		if action == "leap":
			if k < 0.22:
				y -= sin(k / 0.22 * PI * 0.5) * 1.0
				pitch += 0.18 * (k / 0.22)
			elif k < 0.84:
				y += air * 2.4
				pitch += lerpf(-0.2, 0.25, (k - 0.22) / 0.62)
			else:
				y -= sin((k - 0.84) / 0.16 * PI) * 0.9
				pitch += 0.15
		elif airborne:
			y += 0.6
			pitch -= 0.1
		if action == "stomp":
			y += (sin(k * PI * 1.0) * 1.4) if k < 0.6 else -0.3 * (1.0 - k)
			pitch = -0.12 * s
		elif action == "kneel":
			y -= minf(1.0, action_t * 1.2) * (2.2 if upright else 1.2)
			pitch = 0.25 * minf(1.0, action_t)
		elif action == "charge":
			pitch += 0.22 * s
		elif action == "ball":
			pitch = (-0.15 if k < 0.7 else 0.2) * minf(1.0, action_t * 2.0)
		elif action == "bite":
			pitch += (-0.1 if k < 0.35 else 0.3) * s
		elif action == "slam":
			y += (0.9 * sin(k / 0.5 * PI * 0.5)) if k < 0.5 else 0.9 * (1.0 - (k - 0.5) / 0.15) if k < 0.65 else -0.3
			pitch += -0.25 * s if k < 0.5 else 0.35 * s
		elif action in ["swipe_l", "swipe_r"]:
			roll += (0.12 if action == "swipe_l" else -0.12) * s
		if action == "tail":
			hips.rotation.y = sin(k * TAU) * 1.2
		if action != "tail":
			var yaw_t = idle * sin(t * 0.37) * 0.04 + sin(wt) * 0.07 * walk * (1.0 - gallop)   # adımda kalça döner
			hips.rotation.y = lerp_angle(hips.rotation.y, yaw_t, minf(1.0, dt * 4.0))
		hips.position.x = lerpf(hips.position.x, idle * sway * 0.14, minf(1.0, dt * 4.0))
		if hips_base < -1e8:
			hips_base = hips.position.y
		hips.position.y = lerpf(hips.position.y, hips_base + y, minf(1.0, dt * 14.0))
		hips.rotation.x = lerp_angle(hips.rotation.x, pitch, minf(1.0, dt * 6.0))
		hips.rotation.z = lerp_angle(hips.rotation.z, roll, minf(1.0, dt * 6.0))
	# --- göğüs: kalçaya karşı döner (yürüyüş), nefesle kabarır, dörtnalda omurga esner
	if chest:
		var cx = idle * breath * 0.02 - spine * 0.16
		var cy = -sin(wt) * 0.1 * walk * (1.0 - gallop) - idle * sin(t * 0.37) * 0.06
		var cz = -idle * sway * 0.03
		if fid == "stretch":
			cx += fs * (0.16 if quadruped else -0.14)
		elif fid == "growl":
			cx += fs * 0.06
		elif fid == "look":
			cy += fid_side * 0.12 * fs
		chest.rotation.x = lerp_angle(chest.rotation.x, cx, minf(1.0, dt * 6.0))
		chest.rotation.y = lerp_angle(chest.rotation.y, cy, minf(1.0, dt * 5.0))
		chest.rotation.z = lerp_angle(chest.rotation.z, cz, minf(1.0, dt * 5.0))
	# --- baş: hedefe bakar, kükreme, top şarjı, ısırık
	if head:
		var hx = sin(t * 0.4) * 0.05 - stance * 0.1
		var hy = sin(t * 0.27) * 0.15 * (1.0 - stance)
		if look_yaw != 0.0 or stance > 0.0:
			hy = lerpf(hy, clampf(look_yaw, -0.7, 0.7), stance)
		if walk > 0.1:
			hx += sin(wt * 2.0) * 0.04 * walk * (1.0 - gallop) + spine * 0.12   # adımda baş sallanır; dörtnalda baş dengede kalır
		var hz = idle * sin(t * 0.31) * 0.05
		if fid == "look":
			hy += fid_side * 0.65 * pow(fs, 0.35)
			hx += 0.06 * fs
			hz += fid_side * 0.1 * fs
		elif fid == "shake":
			hz += sin(fid_t * 24.0) * 0.28 * fs
			hy += sin(fid_t * 24.0 + 1.0) * 0.12 * fs
		elif fid == "growl":
			hx += 0.14 * fs
		elif fid == "stretch":
			hx -= 0.32 * fs
		head.rotation.z = lerp_angle(head.rotation.z, hz, minf(1.0, dt * 10.0))
		if action == "roar":
			hx = -0.55 * s
		elif action == "ball":
			hx = -0.2 if k < 0.75 else 0.15
		elif action == "kneel":
			hx = 0.35
		elif action == "bite":
			hx = (-0.35 * sin(k / 0.35 * PI * 0.5)) if k < 0.35 else 0.4 * s
		elif action == "leap":
			hx = -0.2 * air
		head.rotation.x = lerp_angle(head.rotation.x, hx, minf(1.0, dt * 6.0))
		head.rotation.y = lerp_angle(head.rotation.y, hy, minf(1.0, dt * 3.0))
		if action == "bite" and head.has_meta("rest_z") == false:
			head.set_meta("rest_z", head.position.z)
		if head.has_meta("rest_z"):
			var rz0: float = head.get_meta("rest_z")
			var lunge = (-1.2 * sin(clampf((k - 0.3) / 0.4, 0.0, 1.0) * PI)) if action == "bite" else 0.0
			head.position.z = lerpf(head.position.z, rz0 + lunge, minf(1.0, dt * 14.0))
	if jaw:
		var open = 0.06 + sin(t * 1.3) * 0.03 + stance * 0.06
		if fid == "growl":
			open = 0.28 * fs + sin(fid_t * 30.0) * 0.03
		elif fid == "stretch":
			open = 0.55 * fs   # esneme
		if action == "roar":
			open = 0.6 * s
		elif action == "ball":
			open = 0.5 * minf(1.0, action_t * 2.0)
		elif action in ["swipe_l", "swipe_r", "charge", "slam"]:
			open = 0.25 * s
		elif action == "bite":
			open = 0.7 if k < 0.45 else 0.05
		jaw.rotation.x = lerp_angle(jaw.rotation.x, open, minf(1.0, dt * 12.0))
	# --- kollar (dört ayaklılarda ön bacak): yürüyüş/dörtnal + pençe + yere çakma
	for a in arms:
		var sh: Node3D = a["sh"]
		var side: float = a["side"]
		var ph = (0.0 if side > 0 else PI) * (1.0 - gallop)   # dörtnalda iki ön ayak birlikte
		var amp = (0.35 + 0.45 * run) * (1.3 if quadruped else 1.0)
		var rx = sin(wt + ph) * amp * walk
		var rz = 0.0
		rx -= stance * (0.25 if not quadruped else 0.0)   # dik canavar savaşta kollarını kaldırır
		rz += stance * 0.25 * side * (0.0 if quadruped else 1.0)
		rx += idle * (sin(t * 0.6 + side * 1.3) * 0.06 + breath * 0.03)   # beklerken kollar hafif salınır
		rz += idle * breath * 0.035 * side
		var fex = 0.0
		if fid == "paw" and side == fid_side and not quadruped:
			rx -= 0.75 * fs + sin(fid_t * 12.0) * 0.1 * fs   # pençesini kaldırıp tartar
			fex = -0.7 * fs
		elif fid == "stretch" and not quadruped:
			rx -= 0.45 * fs
			rz += 0.55 * side * fs
		elif fid == "growl" and not quadruped:
			rz += 0.18 * side * fs
			fex = -0.25 * fs
		if (action == "swipe_l" and side > 0) or (action == "swipe_r" and side < 0):
			rx = -1.6 * sin(minf(1.0, k * 1.6) * PI * 0.5) + (2.2 * maxf(0.0, k - 0.45))
			rz = -0.6 * side * s
		elif action == "slam":
			rx = (-2.4 * sin(minf(1.0, k / 0.5) * PI * 0.5)) if k < 0.5 else lerpf(-2.4, 0.6, minf(1.0, (k - 0.5) / 0.15))
			rz = 0.2 * side * s
		elif action == "roar":
			rx = -0.5 * s
			rz = 0.5 * side * s
		elif action == "ball":
			rx = -0.7 * minf(1.0, action_t * 2.0)
			rz = -0.25 * side
		elif action == "kneel":
			rx = -0.4
		elif action == "leap" or airborne:
			rx = lerpf(rx, -0.9 if k < 0.84 else 0.3, maxf(air, 0.6 if k >= 0.84 else 0.0))   # havada öne uzanır, inişte yere çakar
		sh.rotation.x = lerp_angle(sh.rotation.x, rx, minf(1.0, dt * 10.0))
		sh.rotation.z = lerp_angle(sh.rotation.z, rz, minf(1.0, dt * 10.0))
		if a.has("el"):
			var el: Node3D = a["el"]
			var ex = -0.25 * walk - (0.6 if action == "kneel" else 0.0) - stance * 0.35 - maxf(0.0, -sin(wt + ph)) * 0.5 * run + fex - idle * (0.5 + 0.5 * breath) * 0.05
			el.rotation.x = lerp_angle(el.rotation.x, ex, minf(1.0, dt * 8.0))
	# --- bacaklar: yürüyüş / dörtnal (ön ve arka çift birlikte) / sıçrayış toplama
	for l in legs:
		var hp: Node3D = l["hip"]
		var front = l.get("front", false)
		var phase = lerpf((0.0 if l["side"] > 0 else PI) + (PI if front else 0.0), (0.0 if front else PI * 0.85), gallop)
		var lamp = 0.45 + 0.5 * run
		var rx2 = sin(wt + phase) * lamp * walk
		rx2 -= stance * (0.15 if not front else -0.1)   # savaş duruşu: dizler kırık, ağırlık önde
		var fkn = idle * maxf(0.0, sway * float(l["side"])) * 0.07   # yük binen bacak hafif kırılır
		if quadruped and front:
			if fid == "paw" and float(l["side"]) == fid_side:
				rx2 += 0.55 * fs + sin(fid_t * 13.0) * 0.14 * fs   # ön pençeyle yeri eşeler
				fkn += 0.8 * fs
			elif fid == "stretch":
				rx2 += 0.4 * fs    # ön ayaklar ileri, göğüs yere (kedi esnemesi)
		elif quadruped and fid == "stretch":
			rx2 -= 0.12 * fs
		# gövde yana yatınca ayaklar yerde kalsın: bacak ters yöne açılır
		if not l.has("rz0"):
			l["rz0"] = hp.rotation.z
		var par_roll = hips.rotation.z + (chest.rotation.z if (front and chest and quadruped) else 0.0) if hips else 0.0
		hp.rotation.z = lerp_angle(hp.rotation.z, float(l["rz0"]) - par_roll * idle, minf(1.0, dt * 8.0))
		if action == "stomp" and l["side"] > 0 and not front:
			rx2 = -1.0 * sin(minf(1.0, k * 1.7) * PI)
		elif action == "kneel":
			rx2 = 0.5
		elif action == "leap" or airborne:
			rx2 = lerpf(rx2, (0.6 if not front else -0.7), air)   # havada arka bacak geriye, ön bacak öne
		hp.rotation.x = lerp_angle(hp.rotation.x, rx2, minf(1.0, dt * 10.0))
		if l.has("kn"):
			var kn: Node3D = l["kn"]
			var kx = maxf(0.0, -sin(wt + phase)) * (0.6 + 0.5 * run) * walk + (0.9 if action == "kneel" else 0.0) + stance * 0.3 + air * 0.6 + fkn
			if action == "leap" and k < 0.22:
				kx += 0.7 * (k / 0.22)
			kn.rotation.x = lerp_angle(kn.rotation.x, kx, minf(1.0, dt * 10.0))
	# --- kuyruklar: dalga; savaşta kamçılar, koşuda arkaya akar, sıçrayışta havada savrulur
	for i in tails.size():
		var cfg: Dictionary = tail_cfg[i]
		var segs: Array = tails[i]
		var amp: float = cfg["amp"] * (1.0 + stance * 0.6 + run * 0.3 + (0.8 * fs if fid in ["shake", "growl"] else 0.0))
		var sweep = 0.0
		if action == "tail":
			sweep = sin(k * TAU) * 0.5
		var spd = 1.0 + stance * 0.8 + run * 0.6
		var root: Node3D = cfg["root"]
		root.rotation.y = cfg["yaw"] + sin(t * 0.7 * spd + cfg["phase"]) * (0.12 + stance * 0.08) + sweep + idle * sin(t * 0.33 + cfg["phase"] * 0.7) * 0.1 - sin(wt) * 0.1 * walk
		root.rotation.x = cfg["pitch"] + sin(t * 0.9 * spd + cfg["phase"]) * 0.06 - (0.4 if action == "roar" else 0.0) * s - stance * 0.15 + run * 0.25 + air * 0.3
		for j in range(1, segs.size()):
			var sg: Node3D = segs[j]
			sg.rotation.y = sin(t * 1.4 * spd - j * 0.55 + cfg["phase"]) * amp + sweep * 0.25
			sg.rotation.x = sin(t * 1.1 * spd - j * 0.45 + cfg["phase"] * 1.3) * amp * 0.7 + tail_curl + sin(wt * 2.0 - j * 0.6) * 0.05 * walk * (1.0 + run)
		if cfg["style"] == "wing" and segs.size() > 0:
			var buzz = 14.0 if (action == "charge" or walk > 0.05 or air > 0.0) else 3.0
			segs[0].rotation.z = sin(t * buzz + cfg["phase"]) * amp


## Adım: ayağın altında toz bulutu + yakındaki oyuncuda yer sarsıntısı (canavar ağırlığı hissedilsin)
func _footfall(right: bool, k: float) -> void:
	if not is_inside_tree() or Game.player == null:
		return
	var lst = legs if not legs.is_empty() else arms
	if lst.is_empty():
		return
	var cand = []
	for l in lst:
		if (float(l["side"]) > 0) == right:
			cand.append(l)
	if cand.is_empty():
		cand = lst
	var lg = cand[_last_step % cand.size()]
	var node: Node3D = lg.get("kn", lg.get("el", lg.get("hip", lg.get("sh"))))
	var w = node.global_position
	w.y = Game.ground_height(w.x, w.z)
	var dp = w.distance_to(Game.player.global_position)
	if dp > 500.0:
		return
	var H = height_m
	VFX.puffs(w + Vector3.UP * H * 0.02, {"amount": int(8 * k), "life": 1.1, "size": H * 0.045 * k, "radius": H * 0.035, "vmin": 2, "vmax": 5 * k, "dir": Vector3.UP, "spread": 80.0,
		"gravity": Vector3(0, -2, 0), "colors": [Color(0.8, 0.72, 0.6, 0.85), Color(0.7, 0.62, 0.5, 0)]})
	if Game.world and dp < H * 2.5 and get_parent() != Game.player:
		Game.world.env.add_shake(0.12 * k * clampf(H / 40.0, 0.4, 1.5))


## İniş darbesi (sıçrayış sonu, uçuştan konma): halka toz + sarsıntı
func land_fx() -> void:
	if Game.player == null:
		return
	var w = global_position
	var H = height_m
	VFX.puffs(w + Vector3.UP * H * 0.03, {"amount": 40, "life": 1.4, "size": H * 0.08, "radius": H * 0.25, "vmin": 4, "vmax": 12, "dir": Vector3.UP, "spread": 85.0,
		"gravity": Vector3(0, -3, 0), "colors": [Color(0.8, 0.72, 0.6, 0.9), Color(0.7, 0.62, 0.5, 0)]})
	VFX.shockwave(w + Vector3.UP * 0.3, Color(0.85, 0.78, 0.65), H * 0.9, 0.5)
	if Game.world:
		Game.world.env.add_shake(1.2)
