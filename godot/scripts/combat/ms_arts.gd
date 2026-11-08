class_name MsArts
extends RefCounted
## Mangekyō tarzlarının kendi teknikleri (Eyes.MS_STYLES): her biri ayrı hazırlık + bırakış + çarpma efekti.
## Susanoo teknikleri sahibinin GERÇEK Susanoo'sunu kullanır (Susanoo.of); Kamui girdabı; Itachi yanılsaması karga sürüsü.
## Jutsu.execute çağırır.

const COL := {"itachi": Color(1.0, 0.3, 0.25), "sasuke": Color(0.6, 0.35, 1.0), "madara": Color(0.25, 0.5, 1.0),
	"shisui": Color(0.3, 0.95, 0.5), "kakashi": Color(0.25, 0.95, 0.95)}

const IDS := ["totsuka_no_tsurugi", "yata_no_kagami", "magen_karasu_bunshin", "susanoo_kagutsuchi_no_yumiya",
	"enton_kagutsuchi_no_tsurugi", "susanoo_chidori", "susanoo", "susanoo_kobushi", "susanoo_kai", "yasaka_no_magatama", "enton_yasaka_no_magatama",
	"indora_no_ya", "susanoo_gokakyu", "susanoo_hozan", "susanoo_tsukumo", "kamui_shuriken", "kyoso_enbu"]   # yalnız kanon (uydurma tarz teknikleri silindi; Kamui/Shisui güçleri artık göz yeteneği)


static func handles(id: String) -> bool:
	return id in IDS


static func cast(c: Node3D, id: String, t: Node3D) -> void:
	Callable(MsArts, "m_" + id).call(c, t)


# ------------------------------------------------------------------ ortak yardımcılar
static func _scene() -> Node:
	return Jutsu.get_tree().current_scene


static func _tw() -> Tween:
	return Jutsu.create_tween()


static func _later(t: float, f: Callable) -> void:
	Jutsu.get_tree().create_timer(t).timeout.connect(f)


static func _chest(n: Node3D) -> Vector3:
	return n.global_position + Vector3.UP * float(n.get("height") if n.get("height") != null else 1.8) * 0.55


static func _point(c: Node3D, t: Node3D, rng: float, fall := 14.0) -> Vector3:
	var tg = Jutsu._tg(c, t, rng)
	return _chest(tg) if tg else Jutsu._aim_ground(c, t, fall, rng) + Vector3.UP


static func _anim(c: Node3D, a: String, sp := 1.2) -> void:
	if c.get("model") and c.model:
		c.model.play(a, 0.05, sp, true)


static func _shake(a: float) -> void:
	if Game.world:
		Game.world.env.add_shake(a)


static func _tint(col: Color, dur: float) -> void:
	if Game.world:
		Game.world.env.set_tint(col)
		_later(dur, func(): if Game.world: Game.world.env.set_tint(Color(0, 0, 0, 0)))


static func _spiral(pos: Vector3, size: float, dur: float, normal := Vector3(0, 0, 1)) -> MeshInstance3D:
	return kamui_vortex(pos, size, dur)


## Kamui girdabı (anime): uzay merkeze doğru burkulur, ortası koyu boşluğa açılır; kameraya bakan, ekranı büken dörtgen
static func kamui_vortex(pos: Vector3, size: float, dur: float) -> MeshInstance3D:
	var q = QuadMesh.new()
	q.size = Vector2(1, 1)
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/vfx_kamui.gdshader")
	m.set_shader_parameter("strength", 0.0)
	var mi = MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scene().add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * size * 2.0
	var face = func():
		if is_instance_valid(mi) and Game.player and Game.player.cam:
			mi.look_at(Game.player.cam.global_position, Vector3.UP)
			mi.rotate_object_local(Vector3.UP, PI)
	face.call()
	var tw = mi.create_tween()
	tw.tween_method(func(k: float):
		m.set_shader_parameter("strength", k)
		face.call(), 0.0, 1.0, minf(0.35, dur * 0.4)).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(_k: float): face.call(), 0.0, 1.0, maxf(0.05, dur - 0.65))
	tw.tween_method(func(k: float):
		m.set_shader_parameter("strength", k)
		face.call(), 1.0, 0.0, 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)
	return mi


## Itachi'nin kargası: sivri gagalı başı, kalın gövdesi, yelpaze kuyruğu ve parmak parmak tüylenen kanatları (Sharingan gözlü).
## Örgüler bir kez kurulur (sürüler yüzlerce karga çağırır).
static var _crow_body: ArrayMesh
static var _crow_wing: ArrayMesh
static func _crow() -> Node3D:
	if _crow_body == null:
		var ink = Color(0.04, 0.04, 0.06)
		var mb = MB.new()
		var pts = []
		var rr = []
		for k in 8:   # gövde: göğüs kalın, kuyruğa doğru incelir
			var z = lerpf(-0.16, 0.2, k / 7.0)
			pts.append(Vector3(0, -0.01 * sin(k / 7.0 * PI), z))
			var w = 0.085 * sin(lerpf(0.35, 2.9, k / 7.0)) + 0.012
			rr.append(Vector2(w, w * 0.9))
		Loft.tube(mb, pts, rr, ink, 8, 2)
		mb.add("sphere", Vector3(0, 0.05, -0.2), Vector3(0.11, 0.11, 0.12), ink, Vector3.ZERO, 8)   # baş
		mb.add("cone", Vector3(0, 0.04, -0.3), Vector3(0.035, 0.11, 0.03), Color(0.12, 0.12, 0.14), Vector3(-90, 0, 0), 5)   # gaga
		for sx in [-1.0, 1.0]:
			mb.add("sphere", Vector3(0.045 * sx, 0.075, -0.23), Vector3(0.026, 0.026, 0.02), Color(0.95, 0.05, 0.05), Vector3.ZERO, 5)   # Sharingan gözler
		for k in 5:   # yelpaze kuyruk
			var a = lerpf(-0.45, 0.45, k / 4.0)
			mb.add("box", Vector3(sin(a) * 0.06, -0.005, 0.27 + cos(a) * 0.05), Vector3(0.04, 0.008, 0.16), ink, Vector3(0, rad_to_deg(a), 0))
		_crow_body = mb.build(Props.toon())
		var wm = MB.new()   # sağ kanat (+X); sol kanat aynası
		wm.add("box", Vector3(0.12, 0, 0.0), Vector3(0.2, 0.018, 0.17), ink, Vector3(0, -8, 0))   # iç kanat (örtü tüyleri)
		for k in 5:   # dış kanat: parmak gibi ayrılan uç tüyler
			var a = lerpf(-22.0, 18.0, k / 4.0)
			var L = 0.2 + 0.04 * sin(k / 4.0 * PI)
			var dir = Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
			wm.add("box", Vector3(0.22, 0, 0.02) + dir * L * 0.5, Vector3(L, 0.012, 0.045), ink, Vector3(0, -a, 0))
		_crow_wing = wm.build(Props.toon())
	var root = Node3D.new()
	var body = MeshInstance3D.new()
	body.mesh = _crow_body
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(body)
	for sx in [-1.0, 1.0]:
		var w = MeshInstance3D.new()
		w.mesh = _crow_wing
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.scale = Vector3(sx, 1, 1)
		w.position = Vector3(0.04 * sx, 0.02, -0.04)
		w.name = "W%d" % int(sx)
		root.add_child(w)
	return root


static func _flap(cr: Node3D, t: float) -> void:
	var a = sin(t * 26.0) * 0.8
	var l = cr.get_node_or_null("W-1"); var r = cr.get_node_or_null("W1")
	if l: l.rotation.z = -a
	if r: r.rotation.z = a


## Karga sürüsü: from'dan to'ya kıvrılarak uçar (n karga, süre); varınca on_arrive
static func _crows(from: Vector3, to: Vector3, n: int, dur: float, on_arrive := Callable()) -> void:
	var cs = []
	for i in n:
		var cr = _crow()
		_scene().add_child(cr)
		cr.global_position = from + Vector3(randf_range(-0.6, 0.6), randf_range(0.0, 1.6), randf_range(-0.6, 0.6))
		cr.scale = Vector3.ONE * randf_range(1.0, 1.5)
		cs.append([cr, cr.global_position, Vector3(randf_range(-4, 4), randf_range(1.5, 5.0), randf_range(-4, 4)), randf() * 0.25])
	var tw = _tw()
	tw.tween_method(func(x: float):
		for e in cs:
			var cr: Node3D = e[0]
			if not is_instance_valid(cr):
				continue
			var k = clampf((x - float(e[3])) / (1.0 - float(e[3])), 0.0, 1.0)
			var p0: Vector3 = e[1]
			var mid: Vector3 = (p0 + to) * 0.5 + e[2]
			var p = p0.lerp(mid, k).lerp(mid.lerp(to + e[2] * 0.15, k), k)
			if p.distance_to(cr.global_position) > 0.01:
				cr.look_at(p + (p - cr.global_position), Vector3.UP)
			cr.global_position = p
			_flap(cr, x * dur + float(e[3]) * 10.0), 0.0, 1.0, dur)
	tw.tween_callback(func():
		for e in cs:
			if is_instance_valid(e[0]):
				FX.smoke_puff(e[0].global_position, 0.25, 3)
				e[0].queue_free()
		if on_arrive.is_valid():
			on_arrive.call())


## Kara alev malzemeli geometri
static func _black_mesh(mb: MB) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	mi.material_override = Jutsu._black_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ================================================================== ITACHI
## Magen: Karasu Bunshin — beden karga sürüsüne dağılır, hedefin arkasında yeniden toplanır; hedef yanılsamada kalır
static func m_magen_karasu_bunshin(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 35.0)
	var from = c.global_position
	var dest: Vector3 = (tg.global_position + (tg.global_position - from).normalized() * 2.0) if tg else Jutsu._ground(from + Jutsu._aim_flat(c, t) * 14.0)
	dest = Jutsu._ground(dest)
	Sfx.play("genjutsu", from, 0.9)
	if c.get("model"):
		c.model.visible = false
	FX.smoke_puff(from + Vector3.UP, 0.8, 10)
	_crows(from + Vector3.UP, dest + Vector3.UP, 26, 0.7, func():
		if not is_instance_valid(c):
			return
		c.global_position = dest
		if c.has_method("reset_physics_interpolation"):
			c.reset_physics_interpolation()
		if c.get("model"):
			c.model.visible = true
		FX.smoke_puff(dest + Vector3.UP, 0.8, 10)
		if tg and is_instance_valid(tg) and not tg.is_dead():
			tg.apply_status("stun", 2.2)
			tg.take_hit(Jutsu._inf(c, "magen_karasu_bunshin", 1.0, {"knock": 6.0, "attacker": c, "dir": (tg.global_position - dest).normalized()}))
			VFX.shockwave(_chest(tg), Color(0.9, 0.05, 0.05), 3.0, 0.4, false))


# ================================================================== SASUKE
## Enton: Kagutsuchi no Tsurugi — elde kara alevden kılıç biçimlenir, ileri atılıp yay çizen kesik; kesik yanmaya devam eder
static func m_enton_kagutsuchi_no_tsurugi(c: Node3D, t: Node3D) -> void:
	var mb = MB.new()
	mb.add("box", Vector3(0, 0, -0.8), Vector3(0.12, 0.05, 1.6), Color.WHITE)
	mb.add("cone", Vector3(0, 0, -1.75), Vector3(0.12, 0.35, 0.05), Color.WHITE, Vector3(-90, 0, 0), 4)
	var sw = _black_mesh(mb)
	c.add_child(sw)
	sw.position = Vector3(0.35, 1.1, -0.5)
	sw.scale = Vector3(1, 1, 0.05)
	sw.create_tween().tween_property(sw, "scale", Vector3.ONE * 1.4, 0.25).set_trans(Tween.TRANS_BACK)
	Sfx.play("genjutsu", c.global_position, 0.7)
	var inf = Jutsu._inf(c, "enton_kagutsuchi_no_tsurugi", 0.7, {"knock": 8.0, "kind": "heavy", "hitstop": 0.06, "element": "katon"})
	var hitl = []
	_later(0.25, func():
		if not is_instance_valid(c):
			return
		_anim(c, "slash_c", 1.3)
		Jutsu._dash(c, t, 0.32, 24.0, func(p: Vector3):
			for h in Combat.hit_sphere(c, p, 2.0, inf, hitl):
				hitl.append(h)
				Jutsu._ignite(h, 6.0)
			VFX.embers(p, Color(0.5, 0.1, 0.6), 2, 2.0, 0.5), func():
			if not is_instance_valid(c):
				return
			var arc = VFX._mi(VFX.asset("slash_arc"), Jutsu._black_mat())
			_scene().add_child(arc)
			arc.global_position = c.global_position + Vector3.UP * 1.1 + c.face_dir() * 1.2
			arc.look_at(arc.global_position + c.face_dir(), Vector3.UP)
			arc.scale = Vector3.ONE * 3.5
			var tw = arc.create_tween()
			tw.tween_property(arc, "scale", Vector3.ONE * 4.5, 0.6)
			tw.tween_property(arc, "scale", Vector3.ONE * 0.1, 0.25)
			tw.tween_callback(arc.queue_free)
			VFX.black_smolder(Jutsu._ground(c.global_position + c.face_dir() * 2.0), 1.6, 5.0)
			if is_instance_valid(sw):
				sw.queue_free()))


# ================================================================== SUSANOO TEKNİKLERİ (gerçek Susanoo)
## Hepsi sahibinin GERÇEK Susanoo'sunu kullanır (Susanoo.of): oyuncunun V ile açtığı / özelleştirdiği, düşmanın kendi Susanoo'su.
## Susanoo yoksa teknik atılmaz. Kollar hedefe göre pozlanır (PoseOverlay), efektler Susanoo'nun elinden / ağzından çıkar,
## boyutlar Susanoo boyuyla (TIER_HEIGHT) ölçeklenir.

static func _pj() -> PathJutsu:
	return PathJutsu.get_pinst()


static func _alive(n: Node3D) -> bool:
	return n != null and is_instance_valid(n) and not n.is_dead()


## Sahibi (ve Susanoo'su) hedefe döner; yatay yön döner
static func _turn(c: Node3D, to: Vector3) -> Vector3:
	var d = to - c.global_position
	d.y = 0.0
	d = d.normalized() if d.length() > 0.1 else c.face_dir()
	if "facing" in c:
		c.facing = atan2(-d.x, -d.z)
	return d


## Nişan: hedef varsa göğsü (her kare güncel), yoksa ileride yer
static func _aim_fn(c: Node3D, tg: Node3D, dist: float) -> Callable:
	var fb = Jutsu._ground(c.global_position + c.face_dir() * dist) + Vector3.UP
	var wr = weakref(tg) if tg else null   # serbest kalan hedefi lambda yakalamasın
	var last = {"p": _chest(tg) if tg else fb}
	return func() -> Vector3:
		var n = wr.get_ref() if wr else null
		if n != null and not n.is_dead():
			last["p"] = _chest(n)
		return last["p"]


## +Z ekseni dir'e bakan dönüş (looking_at -Z'yi çevirir); dikeye yakınsa yedek yukarı ekseni
static func _zbasis(dir: Vector3, up := Vector3.UP) -> Basis:
	var d = dir.normalized()
	var u = up if absf(d.dot(up.normalized())) < 0.98 else Vector3.FORWARD
	return Basis.looking_at(-d, u)


## İnce silindir parçasını a->b arasına yerleştir (yay kirişi)
static func _seg(mi: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var v = b - a
	var L = maxf(0.01, v.length())
	var y = v / L
	var x = y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z = x.cross(y)
	mi.global_transform = Transform3D(Basis(x * r, y * L, z * r), (a + b) * 0.5)


static func _rod() -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 6
	cm.rings = 1
	mi.mesh = cm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Susanoo'nun gövdesinden yükselen chakra halkası (teknik başlarken)
static func _sus_flare(sn: Susanoo, at: Vector3, s: float) -> void:
	VFX.gather(at, sn.color().lightened(0.3), s)
	VFX.star(at, sn.color().lightened(0.5), s * 1.6, 0.18)


# ------------------------------------------------------------------ Susanoo (çağırma)
static func m_susanoo(c: Node3D, t: Node3D) -> void:
	var had = c == Game.player and c.combat and c.combat.modes and c.combat.modes.eyes and c.combat.modes.eyes.susanoo
	var sn = Susanoo.of(c, "susanoo")
	if sn == null:
		return
	if had:
		Hud.msg("Susanoo zaten açık.", Color(0.8, 0.85, 1.0), 1.2)
		return
	var H = sn.h()
	VFX.shockwave(c.global_position + Vector3.UP * 0.3, sn.color(), 4.0 + H * 0.5, 0.5)
	VFX.embers(c.global_position + Vector3.UP * H * 0.3, sn.color().lightened(0.3), 30, 4.0 + H * 0.2, 1.2)
	_shake(0.3 + sn.tier * 0.15)


# ------------------------------------------------------------------ Totsuka no Tsurugi (Itachi)
## Kanon: Susanoo'nun sağ elindeki sake testisinden (kabza) akan ruhani sıvı kılıç; deldiği her şeyi testiye çeker,
## sonsuz sarhoş rüya dünyasına mühürler. Oyunda: saplama ağır hasar + sersemletme; zayıflamış (%40 altı, boss olmayan)
## hedef testiye çekilip mühürlenir. Oyuncuyu öldürmez (sersemletir).
static func _gourd(sn: Susanoo) -> MeshInstance3D:
	var mb = MB.new()
	mb.add("sphere", Vector3(0, 0, 0.0), Vector3(0.34, 0.34, 0.36), Color.WHITE, Vector3.ZERO, 16)
	mb.add("sphere", Vector3(0, 0, 0.27), Vector3(0.23, 0.23, 0.25), Color.WHITE, Vector3.ZERO, 14)
	mb.add("cyl", Vector3(0, 0, 0.42), Vector3(0.09, 0.12, 0.09), Color.WHITE, Vector3(90, 0, 0), 10)
	mb.add("torus", Vector3(0, 0, 0.15), Vector3(0.2, 0.2, 0.2), Color.WHITE, Vector3(90, 0, 0), 14)   # bel bağı
	mb.add("torus", Vector3(0, 0, 0.48), Vector3(0.1, 0.12, 0.1), Color.WHITE, Vector3(90, 0, 0), 10)   # ağız halkası
	return sn.chakra_mesh(mb, 1.3)


static var _blade_m: ArrayMesh
static func _blade_mesh() -> ArrayMesh:
	if _blade_m == null:
		var mb = MB.new()
		var pts = []
		var rr = []
		for k in 17:
			var z = k / 16.0
			pts.append(Vector3(sin(z * 11.0) * 0.025 * z, cos(z * 7.0) * 0.012 * z, z))
			var w = (0.06 + 0.06 * sin(z * PI * 0.9)) * (1.0 - pow(z, 4.0)) + 0.004
			rr.append(Vector2(w, w * 0.55))
		Loft.tube(mb, pts, rr, Color.WHITE, 10, 2, true, true, Callable(), Vector3.UP)
		_blade_m = mb.build(null)
	return _blade_m


static func m_totsuka_no_tsurugi(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "totsuka_no_tsurugi")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg = Jutsu._tg(c, t, 10.0 + H * 1.3)
	var aim = _aim_fn(c, tg, H * 0.9)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.2)
	_anim(c, "cast_out", 0.8)
	sn.hide_weapons(2.9)
	var left_idle = Susanoo.arm(false, -side * 0.25 - Vector3.UP * 0.9 + d * 0.25, d * 0.7 - Vector3.UP * 0.5 - side * 0.2)
	# 1) testi omuz üstüne kalkar, kılıç ağzından göğe doğru akarak uzar
	sn.pose({"arms": Susanoo.arm(true, side * 0.55 + Vector3.UP * 0.5 - d * 0.15, Vector3.UP * 0.9 + d * 0.3, Vector3.UP * 0.5 + d * 0.85) + left_idle, "spine": -5.0}, 2.8)
	var gourd = _gourd(sn)
	_scene().add_child(gourd)
	var blade = Node3D.new()
	var outer = VFX._mi(_blade_mesh(), sn.flame_mat())
	var inner = VFX._mi(_blade_mesh(), VFX.mat_bolt(Color(1.0, 0.96, 0.9), 2.4))
	inner.scale = Vector3(0.38, 0.38, 1.0)
	blade.add_child(outer)
	blade.add_child(inner)
	_scene().add_child(blade)
	var st = {"len": 0.0, "mode": 0, "gs": 0.05, "w": S * 0.5}
	var o = {"sn": sn, "g": gourd, "b": blade}   # düğümler sözlükte: serbest kalınca lambda yakalaması hata vermesin
	var upd = func(_x: float):
		if not (is_instance_valid(o["sn"]) and is_instance_valid(o["g"]) and is_instance_valid(o["b"])):
			return
		var sn2: Susanoo = o["sn"]
		var gourd2: Node3D = o["g"]
		var blade2: Node3D = o["b"]
		var hp = sn2.hand(true)
		var dir: Vector3 = (Vector3.UP * 0.8 + d * 0.6).normalized() if st["mode"] == 0 else (aim.call() - hp).normalized()
		gourd2.global_transform = Transform3D(_zbasis(dir) * Basis.from_scale(Vector3.ONE * S * 0.75 * st["gs"]), hp - dir * S * 0.08)
		var mouth = gourd2.to_global(Vector3(0, 0, 0.5))
		blade2.global_transform = Transform3D(_zbasis(dir) * Basis.from_scale(Vector3(st["w"], st["w"], maxf(0.02, st["len"]))), mouth)
	var tw = blade.create_tween()
	tw.set_parallel(true)
	tw.tween_method(upd, 0.0, 1.0, 3.0)
	tw.tween_method(func(x: float): st["gs"] = x, 0.05, 1.0, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_method(func(x: float): st["len"] = x, 0.0, H * 0.55, 0.45).set_delay(0.25).set_trans(Tween.TRANS_SINE)
	_sus_flare(sn, sn.hand(true), 1.4)
	Sfx.play("genjutsu", c.global_position, 0.6)
	_later(0.3, func(): Sfx.play("fire", c.global_position, 0.5, 0.6))
	# 2) saplama: kol hedefe uzanır, sıvı kılıç hedefe kadar akıp deler
	_later(0.8, func():
		if not (is_instance_valid(c) and is_instance_valid(sn)):
			return
		st["mode"] = 1
		var ad = (aim.call() - sn.bone_at("RightUpperArm")).normalized()
		sn.pose({"arms": Susanoo.arm(true, ad, ad, ad) + left_idle, "spine": 12.0}, 2.0, true)
		var reach = sn.hand(true).distance_to(aim.call()) + H * 0.06
		var tw2 = blade.create_tween()
		tw2.tween_method(func(x: float): st["len"] = x, st["len"], reach, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		Sfx.play("whoosh", c.global_position, 0.5, 0.9))
	_later(0.93, func():
		if not is_instance_valid(c):
			return
		var p: Vector3 = aim.call()
		VFX.star(p, col.lightened(0.5), 3.0 + H * 0.1, 0.2)
		VFX.shockwave(p, col, 3.0 + H * 0.15, 0.35, false, d)
		VFX.embers(p, col.lightened(0.3), 26, 7.0, 0.9)
		_shake(0.7)
		var inf = Jutsu._inf(c, "totsuka_no_tsurugi", 2.4, {"knock": 2.0, "kind": "heavy", "hitstop": 0.14, "dir": d})
		if c != Game.player and is_instance_valid(Game.player):
			# oyuncu Totsuka'yla mühürlenip ölmez: hasar mevcut canının yarısıyla sınırlı, sersemletme kalır
			inf["dmg"] = minf(float(inf.get("dmg", 0.0)), maxf(1.0, float(Game.player.hp) * 0.5))
		var hs = Combat.hit_sphere(c, p, 2.4 + H * 0.04, inf)
		for h in hs:
			if not _alive(h):
				continue
			h.apply_status("stun", 3.0)
			var sealable = h.has_method("die") and not (h is Player) and not h.has_meta("boss") and float(h.hp) <= float(h.max_hp) * 0.4
			if sealable:
				_totsuka_seal(c, sn, h, gourd, col)
			else:
				Combat.popup_text(_chest(h) + Vector3.UP, "Mühüre direniyor!", Color(1, 0.65, 0.55))
				# ruh testiye doğru çekiştirilir (iz), ama beden kopmaz
				_soul_wisps(h, gourd, col, 8))
	# 3) kılıç geri akar, testi kaybolur
	_later(2.2, func():
		if not is_instance_valid(blade):
			return
		var tw3 = blade.create_tween()
		tw3.set_parallel(true)
		tw3.tween_method(func(x: float): st["len"] = x, st["len"], 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		tw3.tween_method(func(x: float): st["gs"] = x, 1.0, 0.02, 0.35).set_delay(0.35)
		tw3.chain().tween_callback(func():
			blade.queue_free()
			if is_instance_valid(gourd):
				gourd.queue_free()))


## Ruh izleri: hedeften testinin ağzına akan Susanoo renginde sıvı-alev damlaları
static func _soul_wisps(h: Node3D, gourd: Node3D, col: Color, n: int) -> void:
	for k in n:
		_later(k * 0.07, func():
			if not (is_instance_valid(h) and is_instance_valid(gourd)):
				return
			var w = VFX._mi(VFX._sphere(0.5, 10, 6), VFX.mat_bolt(col.lightened(0.4), 1.8))
			_scene().add_child(w)
			var from = _chest(h) + Vector3(randf_range(-0.5, 0.5), randf_range(-0.6, 0.6), randf_range(-0.5, 0.5))
			w.global_position = from
			w.scale = Vector3.ONE * randf_range(0.3, 0.6)
			var tw = w.create_tween()
			var o = {"g": gourd, "w": w}
			tw.tween_method(func(x: float):
				if is_instance_valid(o["g"]) and is_instance_valid(o["w"]):
					var w2: Node3D = o["w"]
					var to = o["g"].to_global(Vector3(0, 0, 0.5))
					var mid = from.lerp(to, 0.5) + Vector3.UP * 2.0
					w2.global_position = from.lerp(mid, x).lerp(mid.lerp(to, x), x)
					w2.scale = Vector3.ONE * lerpf(0.5, 0.12, x), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_callback(w.queue_free))


static func _totsuka_seal(c: Node3D, sn: Susanoo, h: Node3D, gourd: Node3D, col: Color) -> void:
	Combat.popup_text(_chest(h) + Vector3.UP, "Totsuka: mühürlendi", col.lightened(0.4))
	Sfx.play("genjutsu", h.global_position, 0.5)
	_soul_wisps(h, gourd, col, 18)
	var m = h.get("model")
	if m:
		var tw = m.create_tween()
		tw.set_parallel(true)
		tw.tween_property(m, "scale", m.scale * Vector3(0.05, 1.4, 0.05), 1.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_later(1.15, func():
		if not _alive(h):
			return
		h.die({"execute": true, "attacker": c, "dmg": 9999.0, "sealed": true})
		if is_instance_valid(h) and h.get("model"):
			h.model.visible = false
		if is_instance_valid(gourd):
			VFX.star(gourd.to_global(Vector3(0, 0, 0.5)), col.lightened(0.6), 2.0 + sn.h() * 0.05, 0.25))


# ------------------------------------------------------------------ Yata no Kagami (Itachi)
## Kanon: Susanoo'nun sol kolundaki ayna kalkan; niteliğini saldırıya göre değiştirip her saldırıyı etkisiz kılar.
## Oyunda: 6 sn boyunca gelen hasar %95 azalır (oyuncu ve düşman aynı); her darbe kalkanda dalgalanır ve önündekileri iter.
static func m_yata_no_kagami(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "yata_no_kagami")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var DUR = 6.0
	var d = c.face_dir()
	var side = d.cross(Vector3.UP).normalized()
	_anim(c, "block", 1.0)
	# sol kol kalkanı göğsün önünde tutar
	sn.pose({"arms": Susanoo.arm(false, -side * 0.55 + d * 0.65 - Vector3.UP * 0.35, side * 0.8 + d * 0.45 + Vector3.UP * 0.3), "spine": 6.0}, DUR)
	var shield = Node3D.new()
	var mb = MB.new()
	mb.add("torus", Vector3.ZERO, Vector3(1.0, 0.16, 1.0), Color.WHITE, Vector3(90, 0, 0), 28)
	mb.add("torus", Vector3.ZERO, Vector3(0.62, 0.06, 0.62), Color.WHITE, Vector3(90, 0, 0), 24)
	for k in 12:   # kenar boncukları (aynanın süslü çerçevesi)
		var a = TAU * k / 12.0
		mb.add("sphere", Vector3(cos(a), sin(a), 0) * 0.5, Vector3(0.08, 0.08, 0.08), Color.WHITE, Vector3.ZERO, 8)
	mb.add("sphere", Vector3(0, 0, 0.02), Vector3(0.12, 0.12, 0.06), Color.WHITE, Vector3.ZERO, 10)
	shield.add_child(sn.chakra_mesh(mb, 1.4))
	var face = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.49
	cm.bottom_radius = 0.49
	cm.height = 0.02
	cm.radial_segments = 32
	face.mesh = cm
	face.rotation = Vector3(PI * 0.5, 0, 0)
	var fm = StandardMaterial3D.new()
	fm.albedo_color = Color(col.lightened(0.55).r, col.lightened(0.55).g, col.lightened(0.55).b, 0.55)
	fm.metallic = 1.0
	fm.roughness = 0.06
	fm.emission_enabled = true
	fm.emission = col * 0.35
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	face.material_override = fm
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shield.add_child(face)
	_scene().add_child(shield)
	var st = {"s": 0.05}
	var o = {"sn": sn, "sh": shield, "c": c}
	var upd = func(_x: float):
		if not (is_instance_valid(o["sn"]) and is_instance_valid(o["sh"]) and is_instance_valid(o["c"])):
			return
		var fd = o["c"].face_dir()
		var at = o["sn"].bone_at("LeftLowerArm").lerp(o["sn"].bone_at("LeftHand"), 0.55) + fd * S * 0.12
		o["sh"].global_transform = Transform3D(_zbasis(fd) * Basis.from_scale(Vector3.ONE * S * 1.05 * st["s"]), at)
	var tw = shield.create_tween()
	tw.set_parallel(true)
	tw.tween_method(upd, 0.0, 1.0, DUR + 0.4)
	tw.tween_method(func(x: float): st["s"] = x, 0.05, 1.0, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_method(func(x: float): st["s"] = x, 1.0, 0.02, 0.35).set_delay(DUR)
	tw.chain().tween_callback(shield.queue_free)
	VFX.star(shield.global_position, col.lightened(0.6), 2.0 + H * 0.08, 0.2)
	Sfx.play("chakra", c.global_position, 0.6)
	if c is Player:
		Buffs.add("yata", DUR, {"armor": 0.05, "_name": "Yata no Kagami", "_desc": "ayna kalkan: gelen hasar %95 azalır"})
	else:
		c.set_meta("yata_until", Time.get_ticks_msec() + int(DUR * 1000.0))
	var inf = Jutsu._inf(c, "yata_no_kagami", 0.3, {"knock": 20.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.04})
	var last = {"hp": float(c.hp)}
	Jutsu._ticks(int(DUR / 0.25), 0.25, func(i):
		if not (is_instance_valid(o["c"]) and is_instance_valid(o["sh"])):
			return
		var shield2: Node3D = o["sh"]
		var fd = c.face_dir()
		# darbe aldıysa ayna dalgalanır ve saldırganları geri savurur (niteliğini değiştirip yansıtır)
		if float(c.hp) < last["hp"] - 0.01 or i % 2 == 0:
			var struck = float(c.hp) < last["hp"] - 0.01
			var hs = Combat.hit_sphere(c, c.global_position + fd * H * 0.3 + Vector3.UP * H * 0.2, H * 0.22 + 2.0, inf)
			if struck or not hs.is_empty():
				VFX.shockwave(shield2.global_position + fd * S * 0.1, col.lightened(0.4), S * 1.4, 0.3, false, fd)
				VFX.star(shield2.global_position, Color(1, 1, 1), S * 0.5, 0.12)
		last["hp"] = float(c.hp))


# ------------------------------------------------------------------ Susanoo yayı: Enton: Susanoo Kagutsuchi (Sasuke) / Indora'nın Oku
## Sol el yayı hedefe uzatır, sağ el kirişi yanağa kadar çeker; ok kirişte biçimlenir (kara alev / şimşek), bırakınca kiriş titrer.
static func _bow_mesh(sn: Susanoo) -> MeshInstance3D:
	var mb = MB.new()
	var pts = []
	var rr = []
	for k in 15:
		var a = lerpf(-1.25, 1.25, k / 14.0)
		var tip = maxf(0.0, absf(a) - 1.0) * 4.0   # uçlar öne kıvrılır (recurve)
		pts.append(Vector3(0, sin(a) * 0.82, (1.0 - cos(a)) * 0.38 - tip * 0.1))
		var w = lerpf(0.045, 0.016, absf(a) / 1.25)
		rr.append(Vector2(w, w * 1.4))
	Loft.tube(mb, pts, rr, Color.WHITE, 8, 2, true, true, Callable(), Vector3.FORWARD)
	mb.add("sphere", Vector3(0, 0, 0.0), Vector3(0.09, 0.2, 0.1), Color.WHITE, Vector3.ZERO, 10)   # kabza
	for s in [-1.0, 1.0]:   # kanat süsleri
		mb.add("cone", Vector3(0, 0.45 * s, 0.1), Vector3(0.05, 0.22, 0.04), Color.WHITE, Vector3(90 + 30 * s, 0, 0), 6)
	return sn.chakra_mesh(mb, 1.5)


static func _bow_tips() -> Array:
	var a = 1.25
	var tip = (a - 1.0) * 4.0
	var z = (1.0 - cos(a)) * 0.38 - tip * 0.1
	return [Vector3(0, sin(a) * 0.82, z), Vector3(0, -sin(a) * 0.82, z)]


static func _sus_bow(c: Node3D, t: Node3D, jid: String, mode: String) -> void:
	var sn = Susanoo.of(c, jid)
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var indora = mode == "indora"
	var rng = (70.0 if indora else 45.0) + H * 1.5
	var tg = Jutsu._tg(c, t, rng)
	var aim = _aim_fn(c, tg, minf(rng, 25.0 + H))
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	var charge = 1.9 if indora else 1.0
	_pj().busy(c, charge + 0.3)
	_anim(c, "cast", 0.8)
	sn.hide_weapons(charge + 0.9)
	var ad = (aim.call() - sn.bone_at("LeftUpperArm")).normalized()
	var draw = Susanoo.arm(true, side * 0.55 - d * 0.8 + Vector3.UP * 0.12, -side * 0.85 + d * 0.3 + Vector3.UP * 0.3, -side * 0.6 + d * 0.7)
	sn.pose({"arms": Susanoo.arm(false, ad, ad, ad) + draw, "spine": -4.0}, charge + 0.8)
	var bow = _bow_mesh(sn)
	_scene().add_child(bow)
	var strings = [_rod(), _rod()]
	var smat = VFX.mat_bolt(col.lightened(0.6), 1.6)
	for s in strings:
		s.material_override = smat
		_scene().add_child(s)
	# ok: kara alev (Enton) ya da ak-mavi şimşek (Indora)
	var arrow = Node3D.new()
	var amb = MB.new()
	amb.add("cyl", Vector3(0, 0, 0.0), Vector3(0.05, 1.4, 0.05), Color.WHITE, Vector3(90, 0, 0), 8)
	amb.add("cone", Vector3(0, 0, -0.82), Vector3(0.16, 0.3, 0.06), Color.WHITE, Vector3(-90, 0, 0), 4)
	for s in [-1.0, 1.0]:
		amb.add("box", Vector3(0.06 * s, 0, 0.6), Vector3(0.12, 0.01, 0.22), Color.WHITE)
	var shaft = MeshInstance3D.new()
	shaft.mesh = amb.build(null)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shaft.material_override = VFX.mat_bolt(Color(0.85, 0.92, 1.0), 2.6) if indora else Jutsu._black_mat()
	arrow.add_child(shaft)
	if indora:
		var arcs = Arcs.new()
		arcs.color = Color(0.7, 0.85, 1.0)
		arcs.radius = 0.5
		arcs.count = 8
		arcs.width = 0.04
		arrow.add_child(arcs)
	else:
		var fl = VFX.black_flames(0.35)
		fl.position = Vector3(0, 0, -0.3)
		fl.scale = Vector3(0.22, 0.22, 0.9)
		arrow.add_child(fl)
	_scene().add_child(arrow)
	var st = {"bs": 0.05, "as": 0.02, "drawn": true, "flying": false}
	var o = {"sn": sn, "bow": bow, "ar": arrow}
	var upd = func(_x: float):
		if not (is_instance_valid(o["sn"]) and is_instance_valid(o["bow"])):
			return
		var sn2: Susanoo = o["sn"]
		var bow2: Node3D = o["bow"]
		var arrow2 = o["ar"]
		var lh = sn2.hand(false)
		var a2: Vector3 = (aim.call() - lh).normalized()
		bow2.global_transform = Transform3D(_zbasis(-a2) * Basis.from_scale(Vector3.ONE * S * 1.35 * st["bs"]), lh)
		var tips = _bow_tips()
		var t0 = bow2.to_global(tips[0])
		var t1 = bow2.to_global(tips[1])
		var nock = sn2.hand(true) if st["drawn"] else bow2.to_global(Vector3(0, 0, (1.0 - cos(1.25)) * 0.38 - 0.1))
		var r = S * 0.012 * st["bs"]
		_seg(strings[0], t0, nock, r)
		_seg(strings[1], nock, t1, r)
		if is_instance_valid(arrow2) and not st["flying"]:
			var ad2 = (lh - nock).normalized() if st["drawn"] else a2
			arrow2.global_transform = Transform3D(_zbasis(-ad2) * Basis.from_scale(Vector3.ONE * S * 1.35 * st["as"]), nock + ad2 * S * 1.35 * st["as"] * 0.7)
	var tw = bow.create_tween()
	tw.set_parallel(true)
	tw.tween_method(upd, 0.0, 1.0, charge + 1.2)
	tw.tween_method(func(x: float): st["bs"] = x, 0.05, 1.0, 0.3).set_trans(Tween.TRANS_BACK)
	tw.tween_method(func(x: float): st["as"] = x, 0.02, 1.0, 0.4).set_delay(0.3)
	tw.tween_method(func(x: float): st["bs"] = x, 1.0, 0.02, 0.3).set_delay(charge + 0.85)
	tw.chain().tween_callback(func():
		bow.queue_free()
		for s in strings:
			if is_instance_valid(s):
				s.queue_free())
	_sus_flare(sn, sn.hand(false), 1.2)
	if indora:
		# Indora: gök kararır, her yandan şimşekler okun ucuna toplanır
		Sfx.play("thunder", c.global_position, 0.7)
		_tint(Color(0.06, 0.05, 0.16, 0.35), charge + 0.6)
		for k in 22:
			_later(0.3 + k * 0.07, func():
				if not is_instance_valid(arrow) or st["flying"]:
					return
				var tip = arrow.to_global(Vector3(0, 0, -0.9))
				var q = tip + Vector3(randf_range(-1, 1), randf_range(-0.2, 1.2), randf_range(-1, 1)).normalized() * randf_range(H * 0.3, H * 0.8)
				VFX.bolt(q, tip, Color(0.65, 0.85, 1.0), S * 0.02, 0.18, 2))
	else:
		Sfx.play("genjutsu", c.global_position, 0.6)
		_later(0.3, func(): if is_instance_valid(arrow): VFX.gather(arrow.global_position, Color(0.3, 0.05, 0.4), 1.4))
	# bırakış
	_later(charge, func():
		if not (is_instance_valid(c) and is_instance_valid(sn) and is_instance_valid(arrow)):
			if is_instance_valid(arrow):
				arrow.queue_free()
			return
		st["drawn"] = false
		st["flying"] = true
		sn.pose({"arms": Susanoo.arm(false, ad, ad, ad) + Susanoo.arm(true, side * 0.5 - d * 0.85 + Vector3.UP * 0.1, side * 0.3 - d * 0.9 + Vector3.UP * 0.25), "spine": -8.0}, 0.7, true)
		var from = arrow.global_position
		var to: Vector3 = aim.call()
		var dir = (to - from).normalized()
		var dist = from.distance_to(to)
		if not tg:
			to = from + dir * rng * 0.8
			dist = rng * 0.8
		Sfx.play("thunder" if indora else "whoosh", from, 0.6 if indora else 0.7)
		if indora:
			_fire_indora(c, sn, arrow, from, to, dir, dist)
		else:
			_fire_kagutsuchi(c, sn, arrow, from, to, dir, dist))


static func _fire_kagutsuchi(c: Node3D, sn: Susanoo, arrow: Node3D, from: Vector3, to: Vector3, dir: Vector3, dist: float) -> void:
	var H = sn.h()
	VFX.trail(arrow, H * 0.03, Color(0.45, 0.15, 0.55), Color(0.1, 0.02, 0.12), Color(0, 0, 0, 0), 24, 0.0)
	var dur = clampf(dist / 110.0, 0.1, 0.7)
	var tw = arrow.create_tween()
	tw.tween_property(arrow, "global_position", to, dur)
	tw.tween_callback(func():
		arrow.queue_free()
		if not is_instance_valid(c):
			return
		var inf = Jutsu._inf(c, "susanoo_kagutsuchi_no_yumiya", 1.8, {"knock": 14.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.08, "element": "katon"})
		for h in Combat.hit_sphere(c, to, 3.0 + H * 0.12, inf):
			Jutsu._ignite(h, 8.0)
		var g = Jutsu._ground(to)
		var fl = VFX.black_flames(2.0 + H * 0.05)
		_scene().add_child(fl)
		fl.global_position = g
		fl.scale = Vector3(1.0, 2.2, 1.0)
		_later(4.0, func(): if is_instance_valid(fl): fl.queue_free())
		VFX.shockwave(to, Color(0.22, 0.0, 0.3), 5.0 + H * 0.2, 0.5)
		VFX.black_smolder(g, 3.0 + H * 0.06, 7.0)
		VFX.embers(to, Color(0.6, 0.15, 0.7), 30, 8.0, 1.1)
		_shake(0.8))


static func _fire_indora(c: Node3D, sn: Susanoo, arrow: Node3D, from: Vector3, to: Vector3, dir: Vector3, dist: float) -> void:
	var H = sn.h()
	arrow.queue_free()
	# ışın: tüm yol boyunca kalın şimşek demeti + çatallar, sonda dev patlama
	for k in 3:
		VFX.bolt(from, to, Color(0.8, 0.9, 1.0), H * 0.025 * (1.0 - k * 0.3), 0.45, 4)
	var n = int(dist / 8.0)
	for k in n:
		var q = from + dir * (k * 8.0)
		_later(k * 0.012, func():
			VFX.bolt(q, q + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * H * 0.2, Color(0.6, 0.8, 1.0), H * 0.008, 0.3, 2))
	var inf = Jutsu._inf(c, "indora_no_ya", 4.0, {"knock": 30.0, "launch": 8.0, "kind": "heavy", "element": "raiton", "stun": 1.0, "hitstop": 0.15, "dir": dir})
	var flat = Vector3(dir.x, 0, dir.z).normalized()
	Combat.hit_zone(c, Jutsu._ground(from), flat, dist + 6.0, 10.0, H * 0.6 + 6.0, inf)
	_later(0.1, func():
		if not is_instance_valid(c):
			return
		Combat.hit_sphere(c, to, 6.0 + H * 0.12, inf)
		_pj().impact_fx("raiton", Color(0.65, 0.85, 1.0), to, 2.0 + H * 0.06)
		VFX.cracks(Jutsu._ground(to), 10.0 + H * 0.2)
		VFX.shockwave(to, Color(0.7, 0.85, 1.0), 10.0 + H * 0.3, 0.6)
		VFX.star(to, Color(0.9, 0.95, 1.0), 8.0 + H * 0.2, 0.3)
		if c is Player:
			VFX.screen_lines(0.5, 1.5, Color(0.7, 0.85, 1.0))
		_shake(2.2))


static func m_susanoo_kagutsuchi_no_yumiya(c: Node3D, t: Node3D) -> void:
	_sus_bow(c, t, "susanoo_kagutsuchi_no_yumiya", "enton")


static func m_indora_no_ya(c: Node3D, t: Node3D) -> void:
	_sus_bow(c, t, "indora_no_ya", "indora")


# ------------------------------------------------------------------ Susanoo: Chidori
## Susanoo'nun sağ eli aşağıda dev Chidori'yi doldurur (yere sürten şimşekler, cıvıltı), sonra kol hedefe uzanır ve
## şimşek mızrak gibi elden fırlar.
static func m_susanoo_chidori(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "susanoo_chidori")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color().lerp(Color(0.6, 0.75, 1.0), 0.5)
	var tg = Jutsu._tg(c, t, 16.0 + H * 1.2)
	var aim = _aim_fn(c, tg, 10.0 + H * 0.6)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.1)
	_anim(c, "cast", 0.9)
	sn.hide_weapons(1.6)
	var lguard = Susanoo.arm(false, d * 0.55 - side * 0.35 - Vector3.UP * 0.55, d * 0.8 + side * 0.25 + Vector3.UP * 0.35)
	sn.pose({"arms": Susanoo.arm(true, -d * 0.4 - Vector3.UP * 0.85 + side * 0.3, d * 0.35 - Vector3.UP * 0.9, d * 0.6 - Vector3.UP * 0.7) + lguard, "spine": 16.0}, 1.6)
	var ball = VFX.lightning_ball(S * 0.32, col)
	var arcs = Arcs.new()
	arcs.color = col.lightened(0.3)
	arcs.radius = S * 0.5
	arcs.count = 12
	arcs.width = S * 0.02
	ball.add_child(arcs)
	_scene().add_child(ball)
	var st = {"free": false}
	var tw = ball.create_tween()
	var o = {"sn": sn, "ball": ball}
	tw.tween_method(func(_x: float):
		if is_instance_valid(o["sn"]) and is_instance_valid(o["ball"]) and not st["free"]:
			o["ball"].global_position = o["sn"].hand(true), 0.0, 1.0, 1.0)
	ball.scale = Vector3.ONE * 0.1
	ball.create_tween().tween_property(ball, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	Sfx.play("chidori", c.global_position, 0.6)
	for k in 12:   # yere sürten şimşek dilleri
		_later(0.1 + k * 0.065, func():
			if not is_instance_valid(ball) or st["free"]:
				return
			var hp = ball.global_position
			var g = Jutsu._ground(hp + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * S * 0.6)
			VFX.bolt(hp, g, col.lightened(0.2), S * 0.03, 0.14, 2)
			if k % 4 == 0:
				FX.light(hp, col, 6.0, 8.0 + H * 0.6, 0.3))
	_later(0.9, func():
		if not (is_instance_valid(c) and is_instance_valid(sn)):
			if is_instance_valid(ball):
				ball.queue_free()
			return
		var ad = (aim.call() - sn.bone_at("RightUpperArm")).normalized()
		sn.pose({"arms": Susanoo.arm(true, ad, ad, ad) + lguard, "spine": -6.0}, 0.7, true))
	_later(1.0, func():
		if not (is_instance_valid(c) and is_instance_valid(ball)):
			return
		st["free"] = true
		var from = ball.global_position
		var to: Vector3 = aim.call()
		for k in 3:
			VFX.bolt(from, to, col.lightened(0.4), S * (0.05 - k * 0.012), 0.3, 4)
		var tw2 = ball.create_tween()
		tw2.tween_property(ball, "global_position", to, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw2.tween_callback(func():
			ball.queue_free()
			if not is_instance_valid(c):
				return
			var inf = Jutsu._inf(c, "susanoo_chidori", 2.2, {"knock": 18.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.1, "element": "raiton", "stun": 1.4, "dir": d})
			Combat.hit_sphere(c, to, 3.0 + H * 0.1, inf)
			for k in 8:
				VFX.bolt(to, to + Vector3(randf_range(-1, 1), randf_range(-0.2, 1), randf_range(-1, 1)).normalized() * (4.0 + H * 0.3), col.lightened(0.3), S * 0.02, 0.3, 3)
			VFX.star(to, Color(0.85, 0.9, 1.0), 4.0 + H * 0.15, 0.2)
			VFX.shockwave(to, col, 5.0 + H * 0.25, 0.4, false, d)
			VFX.cracks(Jutsu._ground(to), 4.0 + H * 0.15)
			_shake(0.9)))


# ------------------------------------------------------------------ Yasaka no Magatama (Itachi) / Enton: Yasaka no Magatama (Sasuke)
## Susanoo'nun eli üç magatamayı bir halkada döndürür (Yasaka kolyesi), kolunu savurup fırlatır; magatamalar dönerek
## yay çizip hedefe iner. Enton türü: kara alevli magatamalar, değdiği yer kara alevle yanar.
static func _magatama_mesh() -> MB:
	var mb = MB.new()
	mb.add("sphere", Vector3(0.13, 0, 0), Vector3(0.24, 0.24, 0.16), Color.WHITE, Vector3.ZERO, 12)
	var pts = []
	var rr = []
	for k in 9:
		var a = -k / 8.0 * 2.3
		pts.append(Vector3(cos(a) * 0.13, sin(a) * 0.13, 0))
		var w = lerpf(0.1, 0.01, k / 8.0)
		rr.append(Vector2(w, w * 0.66))
	Loft.tube(mb, pts, rr, Color.WHITE, 8, 2, true, true, Callable(), Vector3.BACK)
	return mb


static func _sus_yasaka(c: Node3D, t: Node3D, jid: String, black: bool) -> void:
	var sn = Susanoo.of(c, jid)
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg = Jutsu._tg(c, t, 36.0 + H * 1.2)
	var aim = _aim_fn(c, tg, 18.0 + H * 0.6)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.0)
	_anim(c, "cast", 0.9)
	sn.hide_weapons(1.5)
	# kurulma: sağ kol yana-geriye açılır, avuç yukarıda, magatamalar avuçta döner
	sn.pose({"arms": Susanoo.arm(true, side * 0.75 + Vector3.UP * 0.35 - d * 0.35, Vector3.UP * 0.75 + d * 0.15 + side * 0.3, Vector3.UP * 0.6 - d * 0.3), "spine": -6.0}, 1.5)
	var holder = Node3D.new()
	_scene().add_child(holder)
	var ring_mb = MB.new()
	ring_mb.add("torus", Vector3.ZERO, Vector3(0.72, 0.04, 0.72), Color.WHITE, Vector3(90, 0, 0), 24)
	var ring = sn.chakra_mesh(ring_mb, 1.2)
	holder.add_child(ring)
	var mags = []
	for k in 3:
		var mi: MeshInstance3D
		if black:
			mi = _black_mesh(_magatama_mesh())
			var fl = VFX.black_flames(0.08)
			mi.add_child(fl)
			fl.position = Vector3(0.13, 0, 0)
		else:
			mi = sn.chakra_mesh(_magatama_mesh(), 1.8)
		var a = TAU * k / 3.0
		mi.position = Vector3(cos(a), sin(a), 0) * 0.36
		mi.rotation.z = a
		holder.add_child(mi)
		mags.append(mi)
	var st = {"s": 0.05, "spin": 0.0, "free": false}
	var tw = holder.create_tween()
	tw.set_parallel(true)
	var o = {"sn": sn, "h": holder}
	tw.tween_method(func(x: float):
		if not (is_instance_valid(o["sn"]) and is_instance_valid(o["h"])) or st["free"]:
			return
		st["spin"] = x * TAU * 6.0
		var hp = o["sn"].hand(true) + Vector3.UP * S * 0.25
		o["h"].global_transform = Transform3D(_zbasis(d) * Basis(Vector3.BACK, st["spin"]) * Basis.from_scale(Vector3.ONE * S * 0.6 * st["s"]), hp), 0.0, 1.0, 0.85)
	tw.tween_method(func(x: float): st["s"] = x, 0.05, 1.0, 0.3).set_trans(Tween.TRANS_BACK)
	_sus_flare(sn, sn.hand(true), 1.2)
	Sfx.play("genjutsu" if black else "chakra", c.global_position, 0.7)
	# savuruş: kol öne-aşağı iner
	_later(0.7, func():
		if is_instance_valid(sn):
			var ad = (aim.call() - sn.bone_at("RightUpperArm")).normalized()
			sn.pose({"arms": Susanoo.arm(true, (ad - side * 0.3).normalized(), (ad - side * 0.4 - Vector3.UP * 0.2).normalized()), "spine": 14.0}, 0.7, true))
	_later(0.82, func():
		st["free"] = true
		if not is_instance_valid(holder):
			return
		if not is_instance_valid(c):
			holder.queue_free()
			return
		ring.create_tween().tween_property(ring, "scale", Vector3.ONE * 1.8, 0.25)
		_later(0.25, func(): if is_instance_valid(holder): holder.queue_free())
		Sfx.play("whoosh", holder.global_position, 0.8)
		for k in 3:
			var mi: MeshInstance3D = mags[k]
			var from = mi.global_position
			mi.reparent(_scene())
			_later(k * 0.09, func(): _fly_magatama(c, sn, mi, from, aim, k, black, jid)))


static func _fly_magatama(c: Node3D, sn: Susanoo, mi: MeshInstance3D, from: Vector3, aim: Callable, k: int, black: bool, jid: String) -> void:
	if not is_instance_valid(mi):
		return
	var H = sn.h() if is_instance_valid(sn) else 16.0
	var col = sn.color() if is_instance_valid(sn) else Color(1, 0.3, 0.25)
	var to0: Vector3 = aim.call()
	var mid = (from + to0) * 0.5 + Vector3.UP * (2.0 + H * 0.12) + (to0 - from).cross(Vector3.UP).normalized() * (k - 1) * (3.0 + H * 0.15)
	var dur = clampf(from.distance_to(to0) / 55.0, 0.25, 1.1)
	if not black:
		VFX.trail(mi, H * 0.02, col.lightened(0.5), col, Color(col.r, col.g, col.b, 0), 18, 1.0)
	var sp = mi.global_basis
	var tw = mi.create_tween()
	var o = {"mi": mi}
	tw.tween_method(func(x: float):
		if is_instance_valid(o["mi"]):
			var to: Vector3 = aim.call()
			o["mi"].global_position = from.lerp(mid, x).lerp(mid.lerp(to, x), x)
			o["mi"].global_basis = sp * Basis(Vector3.BACK, x * TAU * 5.0), 0.0, 1.0, dur)
	tw.tween_callback(func():
		var p = mi.global_position
		mi.queue_free()
		if not is_instance_valid(c):
			return
		var inf = Jutsu._inf(c, jid, 0.55 if black else 0.6, {"knock": 12.0, "launch": 3.0, "kind": "heavy", "hitstop": 0.06, "element": "katon" if black else ""})
		for h in Combat.hit_sphere(c, p, 2.4 + H * 0.06, inf):
			if black:
				Jutsu._ignite(h, 6.0)
		if black:
			var fl = VFX.black_flames(1.2 + H * 0.03)
			_scene().add_child(fl)
			fl.global_position = Jutsu._ground(p)
			_later(2.5, func(): if is_instance_valid(fl): fl.queue_free())
			VFX.black_smolder(Jutsu._ground(p), 1.6 + H * 0.04, 5.0)
			VFX.shockwave(p, Color(0.25, 0.0, 0.3), 3.0 + H * 0.12, 0.35)
		else:
			FX.impact(p, col, 1.0 + H * 0.05)
			VFX.shockwave(p, col.lightened(0.3), 3.0 + H * 0.12, 0.35)
			VFX.cracks(Jutsu._ground(p), 2.0 + H * 0.08)
		_shake(0.35))


static func m_yasaka_no_magatama(c: Node3D, t: Node3D) -> void:
	_sus_yasaka(c, t, "yasaka_no_magatama", false)


static func m_enton_yasaka_no_magatama(c: Node3D, t: Node3D) -> void:
	_sus_yasaka(c, t, "enton_yasaka_no_magatama", true)


# ------------------------------------------------------------------ Susanoo: Kobushi (yumruk)
static func m_susanoo_kobushi(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "susanoo_kobushi")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg = Jutsu._tg(c, t, 6.0 + H * 1.1)
	var aim = _aim_fn(c, tg, 4.0 + H * 0.45)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 0.7)
	_anim(c, "cross", 1.0)
	# geri çekiş: yumruk omuzun arkasında, gövde burulur
	sn.pose({"arms": Susanoo.arm(true, -d * 0.7 + side * 0.55 - Vector3.UP * 0.25, d * 0.25 + Vector3.UP * 0.55 + side * 0.25, d * 0.6 + Vector3.UP * 0.4), "spine": -8.0}, 1.0)
	_later(0.38, func():
		if not (is_instance_valid(c) and is_instance_valid(sn)):
			return
		var ad = (aim.call() - sn.bone_at("RightUpperArm")).normalized()
		sn.pose({"arms": Susanoo.arm(true, ad, ad, ad), "spine": 14.0}, 0.6, true)
		Sfx.play("whoosh", c.global_position, 0.6, 0.7))
	_later(0.5, func():
		if not (is_instance_valid(c) and is_instance_valid(sn)):
			return
		var fist = sn.hand(true)
		var to: Vector3 = aim.call()
		var p = fist.lerp(to, 0.4) if tg and fist.distance_to(to) < S * 0.9 + 3.0 else fist
		var inf = Jutsu._inf(c, "susanoo_kobushi", 2.4, {"knock": 24.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.12, "dir": d})
		Combat.hit_sphere(c, p, S * 0.45 + 2.0, inf)
		# yumruk basıncı: kolun ucundan ileri chakra şoku (kolun yetmediği mesafe)
		Combat.hit_zone(c, c.global_position, d, S * 1.2 + 6.0, 26.0, H * 0.8, inf)
		var front = fist + d * (S * 0.6 + 3.0)
		VFX.shockwave(front, col, S * 0.9 + 2.0, 0.3, false, d)
		VFX.shockwave(fist, col.lightened(0.3), S * 1.2 + 2.0, 0.3, false, d)
		VFX.star(fist, Color(1, 1, 1), S * 0.6 + 1.0, 0.12)
		var g = Jutsu._ground(p)
		if p.y - g.y < S * 0.8 + 2.0:
			VFX.cracks(g, S * 0.7 + 3.0)
			VFX.debris(g + Vector3.UP * 0.5, Color(0.5, 0.42, 0.32), 14, 8.0 + S, 0.4 + S * 0.05)
		Sfx.play("punch", p, 0.6)
		_shake(0.5 + sn.tier * 0.12))


# ------------------------------------------------------------------ Susanoo: Gōkakyū
## Susanoo nefes alıp geriye yaslanır, ağzında alev toplanır; öne eğilip dev ateş topunu üfler.
static func m_susanoo_gokakyu(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "susanoo_gokakyu")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var tg = Jutsu._tg(c, t, 40.0 + H)
	var aim = _aim_fn(c, tg, 22.0 + H * 0.6)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.1)
	_anim(c, "cast", 0.9)
	# mühür eli: iki el göğüs önünde; nefes alırken gövde geriye
	var seal = Susanoo.arm(true, -Vector3.UP * 0.7 + d * 0.45 + side * 0.2, -side * 0.75 + Vector3.UP * 0.55 + d * 0.35) + Susanoo.arm(false, -Vector3.UP * 0.7 + d * 0.45 - side * 0.2, side * 0.75 + Vector3.UP * 0.55 + d * 0.35)
	sn.pose({"arms": seal, "spine": -16.0, "neck": -14.0}, 1.4)
	VFX.gather(sn.mouth(d), Color(1.0, 0.55, 0.15), 1.6)
	Sfx.play("fire", c.global_position, 0.5, 0.6)
	_later(0.65, func():
		if not (is_instance_valid(c) and is_instance_valid(sn)):
			return
		sn.pose({"arms": seal, "spine": 18.0, "neck": 12.0}, 0.8, true)
		var from = sn.mouth(d)
		var to: Vector3 = aim.call()
		var ball = Node3D.new()
		ball.add_child(VFX.fireball(1.6 + S * 0.5))
		var inf = Jutsu._inf(c, "susanoo_gokakyu", 3.0, {"knock": 18.0, "launch": 8.0, "kind": "heavy", "element": "katon", "burn": 5.0})
		var pr = _pj().shot(c, from, (to - from).normalized(), 20.0 + S, ball, inf, tg, false, 3.0, func(p, _h):
			VFX.explosion(p, 2.0 + S * 0.3, Color(1.0, 0.5, 0.12))
			GroundFX.add(p, "burning", 5.0 + S * 0.5, 5.0, c)
			_shake(1.4))
		pr.radius = 1.5 + S * 0.35
		pr.homing_turn = 1.0
		ball.scale = Vector3.ONE * 0.2
		ball.create_tween().tween_property(ball, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		Sfx.play("fire", from, 0.4))


# ------------------------------------------------------------------ Susanoo: Hōzan
## Susanoo'nun sol eli hedefi kavrayıp havaya kaldırır, sağ eldeki kılıç (yoksa chakra kılıcı) yukarıdan biçer.
static func m_susanoo_hozan(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "susanoo_hozan")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg0 = Jutsu._tg(c, t, 8.0 + H * 1.0)
	if not _alive(tg0):
		if c == Game.player:
			Hud.msg("Hōzan: kavranacak hedef yok.", Color(0.85, 0.85, 0.85))
		return
	var d = _turn(c, tg0.global_position)
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.2)
	_anim(c, "cast_out", 0.9)
	var wr = weakref(tg0)
	var reach = func() -> Array:
		var ad = (_chest(wr.get_ref()) - sn.bone_at("LeftUpperArm")).normalized() if _alive(wr.get_ref()) else d
		return Susanoo.arm(false, ad, ad, ad)
	sn.pose({"arms": reach.call()}, 1.5)
	var st = {"held": false}
	var o = {"sn": sn}
	_later(0.35, func():
		if not (_alive(wr.get_ref()) and is_instance_valid(sn)):
			return
		st["held"] = true
		wr.get_ref().apply_status("bind", 1.2)
		Combat.popup_text(_chest(wr.get_ref()) + Vector3.UP, "Kavrandı!", col.lightened(0.4))
		# kavranan hedef ele çekilir, el yukarı kalkar
		var lift = Susanoo.arm(false, d * 0.6 - side * 0.3 + Vector3.UP * 0.3, d * 0.5 + Vector3.UP * 0.75)
		sn.pose({"arms": lift}, 1.2)
		var g0 = wr.get_ref().global_position
		var tw = wr.get_ref().create_tween()
		tw.tween_method(func(x: float):
			if _alive(wr.get_ref()) and is_instance_valid(o["sn"]) and st["held"]:
				var tt = wr.get_ref()
				var to = o["sn"].hand(false) - Vector3.UP * float(tt.get("height") if tt.get("height") != null else 1.8) * 0.5
				tt.global_position = g0.lerp(to, minf(1.0, x * 3.0))
				if "velocity" in tt:
					tt.velocity = Vector3.ZERO, 0.0, 1.0, 0.75))
	_later(0.55, func():
		if is_instance_valid(sn):
			sn.perform("slash_c", 0.9, 1.0))
	_later(1.05, func():
		st["held"] = false
		if not (is_instance_valid(c) and _alive(wr.get_ref())):
			return
		var p = _chest(wr.get_ref())
		_pj()._arc_cut(p, d, -70.0, 70.0, col.lightened(0.3), 2.0 + S * 0.35)
		_pj()._tai_impact(c, p, 1.0 + S * 0.15, false)
		var inf = Jutsu._inf(c, "susanoo_hozan", 3.0, {"knock": 18.0, "launch": 5.0, "kind": "heavy", "bleed": 5.0, "hitstop": 0.12, "dir": d})
		Combat.hit_sphere(c, p, float(wr.get_ref().radius) + 0.8 + S * 0.1, inf)
		_shake(0.9))


# ------------------------------------------------------------------ Susanoo: Tsukumo
## Susanoo iki elini kaldırır, ellerinin çevresinde onlarca chakra oku biçimlenir ve hedefe yağar.
static func m_susanoo_tsukumo(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "susanoo_tsukumo")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg = Jutsu._tg(c, t, 34.0 + H * 1.2)
	var aim = _aim_fn(c, tg, 20.0 + H * 0.6)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.2)
	_anim(c, "cast", 0.9)
	sn.hide_weapons(1.8)
	sn.pose({"arms": Susanoo.arm(true, d * 0.55 + Vector3.UP * 0.55 + side * 0.45, d * 0.75 + Vector3.UP * 0.55) + Susanoo.arm(false, d * 0.55 + Vector3.UP * 0.55 - side * 0.45, d * 0.75 + Vector3.UP * 0.55), "spine": -6.0}, 1.8)
	var spears = []
	var smb = MB.new()
	smb.add("cyl", Vector3(0, 0, 0.0), Vector3(0.04, 1.0, 0.04), Color.WHITE, Vector3(90, 0, 0), 6)
	smb.add("cone", Vector3(0, 0, -0.62), Vector3(0.1, 0.25, 0.1), Color.WHITE, Vector3(-90, 0, 0), 6)
	for k in 16:
		_later(0.15 + k * 0.025, func():
			if not is_instance_valid(sn):
				return
			var u = (k / 15.0) * 2.0 - 1.0
			var base = sn.hand(true).lerp(sn.hand(false), 0.5) + side * u * S * 0.9 + Vector3.UP * (S * 0.25 + (1.0 - u * u) * S * 0.5)
			var sp = sn.chakra_mesh(smb, 1.6)
			_scene().add_child(sp)
			sp.global_transform = Transform3D(_zbasis(-(aim.call() - base).normalized()) * Basis.from_scale(Vector3.ONE * S * 0.45), base)
			sp.scale = Vector3.ONE * 0.05
			sp.create_tween().tween_property(sp, "scale", Vector3.ONE * S * 0.45, 0.2).set_trans(Tween.TRANS_BACK)
			spears.append(sp))
	Sfx.play("chakra", c.global_position, 0.8)
	_later(0.75, func():
		if is_instance_valid(sn):
			sn.pose({"arms": Susanoo.arm(true, d * 0.9 + side * 0.25, d) + Susanoo.arm(false, d * 0.9 - side * 0.25, d), "spine": 10.0}, 0.8, true))
	_later(0.8, func():
		for k in spears.size():
			var sp: MeshInstance3D = spears[k]
			_later(k * 0.035, func():
				if not is_instance_valid(sp):
					return
				if not is_instance_valid(c):
					sp.queue_free()
					return
				var from = sp.global_position
				var to: Vector3 = aim.call() + Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1)) * (1.0 + S * 0.1)
				var dir = (to - from).normalized()
				sp.global_transform = Transform3D(_zbasis(-dir) * Basis.from_scale(Vector3.ONE * S * 0.45), from)
				VFX.trail(sp, S * 0.05, col.lightened(0.5), col, Color(col.r, col.g, col.b, 0), 14, 1.0)
				var dur = clampf(from.distance_to(to) / 80.0, 0.12, 0.8)
				var tw = sp.create_tween()
				tw.tween_property(sp, "global_position", to, dur)
				tw.tween_callback(func():
					sp.queue_free()
					if is_instance_valid(c):
						Combat.hit_sphere(c, to, 1.6 + S * 0.08, Jutsu._inf(c, "susanoo_tsukumo", 0.3, {"knock": 3.0, "kind": "heavy"}))
						FX.impact(to, col, 0.6 + S * 0.05)))
		Sfx.play("whoosh", c.global_position, 1.3))


# ================================================================== KAMUI (Kakashi / Obito) — ortak boyut çekişi
## Kamui geçirgenliği görünümü: modelin tüm parçaları yarı saydam (0 = normal)
static func ghost(model: Node, amount: float) -> void:
	if model == null or not is_instance_valid(model):
		return
	for g in model.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = amount


## Hasar vermeden: konumun çevresindeki düşmanlar
static func _foes(c: Node3D, pos: Vector3, r: float) -> Array:
	var out = []
	for f in c.get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) <= r + float(f.get("radius") if f.get("radius") != null else 0.5):
			out.append(f)
	return out


## Kamui çekişi (kanon: deldiği / odakladığı şey anında Kamui boyutuna gider). Hasar verir; zayıflamış (boss olmayan, canı
## %35 altı) hedef bütünüyle boyuta çekilir, güçlü hedefin yalnız bir parçası kopar (ağır kanama). Oyuncu hedefse öldürmez.
static func kamui_warp(c: Node3D, h: Node3D, info: Dictionary, at: Vector3) -> void:
	if not _alive(h):
		return
	kamui_vortex(at, 1.6, 1.0)
	var inf = info.duplicate()
	if h == Game.player:
		inf["dmg"] = minf(float(inf.get("dmg", 0.0)), maxf(1.0, float(h.hp) * 0.5))
	h.take_hit(inf)
	if not _alive(h):
		return
	var weak = not (h is Player) and not h.has_meta("boss") and float(h.hp) <= float(h.max_hp) * 0.35 and h.has_method("die")
	if weak:
		Combat.popup_text(_chest(h) + Vector3.UP, "Kamui boyutuna çekildi", Color(0.7, 0.55, 0.9))
		h.apply_status("stun", 1.2)
		var m = h.get("model")
		if m:
			var tw = m.create_tween()
			tw.set_parallel(true)
			tw.tween_property(m, "scale", m.scale * 0.05, 0.9).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tw.tween_property(m, "rotation:y", m.rotation.y + TAU * 2.0, 0.9)
		if c == Game.player:
			Game.profile["kamui_store"] = int(Game.profile.get("kamui_store", 0)) + 1
		_later(0.95, func():
			if _alive(h):
				h.die({"execute": true, "attacker": c, "kamui": true, "dmg": 9999.0})
				if is_instance_valid(h) and h.get("model"):
					h.model.visible = false)
	else:
		Combat.popup_text(_chest(h) + Vector3.UP, "Bir parçası koptu", Color(0.8, 0.6, 0.95))
		h.apply_status("bleed", 5.0)


## Kamui Shuriken (kanon, Kakashi): Susanoo, Obito'nun Mangekyō'su biçiminde dev shuriken'ler oluşturur, Kamui ile doldurup
## fırlatır; dönerek gider, değdiğini keser ve anında boyuta çeker. GERÇEK Susanoo'nun elinden atılır.
static func _kamui_shuriken_mesh(sn: Susanoo) -> MeshInstance3D:
	var mb = MB.new()
	mb.add("cyl", Vector3.ZERO, Vector3(0.28, 0.05, 0.28), Color.WHITE, Vector3.ZERO, 16)
	for k in 3:   # Obito'nun Mangekyō deseni: merkezden kıvrılan üç kanat
		var pts = []
		var rr = []
		for j in 9:
			var u = j / 8.0
			var a = TAU * k / 3.0 + u * 1.9
			pts.append(Vector3(cos(a), 0, sin(a)) * lerpf(0.1, 0.62, u))
			var w = lerpf(0.13, 0.015, u)
			rr.append(Vector2(w, 0.025))
		Loft.tube(mb, pts, rr, Color.WHITE, 6, 2, true, true, Callable(), Vector3.UP)
	mb.add("torus", Vector3.ZERO, Vector3(1.0, 0.05, 1.0), Color.WHITE, Vector3.ZERO, 24)
	return sn.chakra_mesh(mb, 1.6)


static func m_kamui_shuriken(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "kamui_shuriken")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var tg = Jutsu._tg(c, t, 40.0 + H)
	var aim = _aim_fn(c, tg, 20.0 + H * 0.6)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.1)
	_anim(c, "throw", 1.0)
	sn.hide_weapons(1.6)
	for k in 3:
		var right = k != 1
		_later(k * 0.28, func():
			if not (is_instance_valid(c) and is_instance_valid(sn)):
				return
			var arm_side = side if right else -side
			sn.pose({"arms": Susanoo.arm(right, arm_side * 0.7 + Vector3.UP * 0.35 - d * 0.3, Vector3.UP * 0.6 + d * 0.5)}, 0.4, true)
			var sh = _kamui_shuriken_mesh(sn)
			_scene().add_child(sh)
			sh.global_position = sn.hand(right)
			sh.scale = Vector3.ONE * S * 0.9
			var vortex = kamui_vortex(sh.global_position, S * 0.5, 2.0)
			_later(0.22, func():
				if not (is_instance_valid(c) and is_instance_valid(sh) and is_instance_valid(sn)):
					if is_instance_valid(sh):
						sh.queue_free()
					return
				var ad = (aim.call() - sn.bone_at("RightUpperArm" if right else "LeftUpperArm")).normalized()
				sn.pose({"arms": Susanoo.arm(right, ad, ad)}, 0.4, true)
				var from = sh.global_position
				var to: Vector3 = aim.call() + side * (k - 1) * 2.0
				var dur = clampf(from.distance_to(to) / 60.0, 0.15, 0.9)
				var o = {"sh": sh, "v": vortex}
				var tw = sh.create_tween()
				tw.tween_method(func(x: float):
					if is_instance_valid(o["sh"]):
						var p = from.lerp(to, x) + side * sin(x * PI) * (k - 1) * S * 0.6
						o["sh"].global_position = p
						o["sh"].rotation.y = x * TAU * 6.0
						if is_instance_valid(o["v"]):
							o["v"].global_position = p, 0.0, 1.0, dur)
				tw.tween_callback(func():
					sh.queue_free()
					if not is_instance_valid(c):
						return
					var inf = Jutsu._inf(c, "kamui_shuriken", 0.7, {"knock": 6.0, "kind": "heavy", "hitstop": 0.1})
					for h in _foes(c, to, 2.0 + S * 0.15):
						kamui_warp(c, h, inf, _chest(h))
					kamui_vortex(to, 1.4 + S * 0.15, 0.9)
					_shake(0.4))
				Sfx.play("blade", from, 0.7)))


## Kyōsō Enbu (kanon, Madara): Susanoo'ya bürünmüş Madara chakra kılıcını shuriken gibi döndürerek fırlatır; yolundakileri biçer,
## hedefte döner durur, sonra Susanoo'nun eline geri gelir. GERÇEK Susanoo'nun kılıcı kullanılır.
static func m_kyoso_enbu(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "kyoso_enbu")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg = Jutsu._tg(c, t, 40.0 + H)
	var aim = _aim_fn(c, tg, 22.0 + H * 0.6)
	var d = _turn(c, aim.call())
	var side = d.cross(Vector3.UP).normalized()
	_pj().busy(c, 1.2)
	_anim(c, "slash_c", 1.0)
	sn.hide_weapons(2.6)
	# kurulma: kılıç omuz arkasına çekilir
	sn.pose({"arms": Susanoo.arm(true, side * 0.6 - d * 0.6 + Vector3.UP * 0.4, -side * 0.5 + Vector3.UP * 0.6 - d * 0.3)}, 0.6)
	var mb = MB.new()
	mb.add("box", Vector3(0, 0, -0.85), Vector3(0.05, 0.14, 1.7), Color.WHITE)
	mb.add("cone", Vector3(0, 0, -1.8), Vector3(0.05, 0.25, 0.14), Color.WHITE, Vector3(-90, 0, 0), 4)
	mb.add("box", Vector3(0, 0, 0.05), Vector3(0.3, 0.06, 0.06), Color.WHITE)
	mb.add("cyl", Vector3(0, 0, 0.3), Vector3(0.05, 0.45, 0.05), Color.WHITE, Vector3(90, 0, 0), 8)
	var sw = sn.chakra_mesh(mb, 1.7)
	_scene().add_child(sw)
	sw.global_position = sn.hand(true)
	sw.scale = Vector3.ONE * S * 1.2
	VFX.trail(sw, S * 0.15, col.lightened(0.5), col, Color(col.r, col.g, col.b, 0.0), 22, 1.0)
	_later(0.45, func():
		if not (is_instance_valid(c) and is_instance_valid(sw) and is_instance_valid(sn)):
			if is_instance_valid(sw):
				sw.queue_free()
			return
		var ad = (aim.call() - sn.bone_at("RightUpperArm")).normalized()
		sn.pose({"arms": Susanoo.arm(true, ad, ad)}, 0.5, true)
		var from = sw.global_position
		var to: Vector3 = aim.call()
		var dist = from.distance_to(to)
		var go = clampf(dist / 55.0, 0.2, 0.9)
		var hits = []
		var inf = Jutsu._inf(c, "kyoso_enbu", 0.6, {"knock": 10.0, "kind": "heavy", "bleed": 3.0, "hitstop": 0.05})
		var o = {"sw": sw}
		var tw = sw.create_tween()
		# git — hedefte dönerek biç — geri dön
		tw.tween_method(func(x: float):
			if is_instance_valid(o["sw"]):
				var p = from.lerp(to, x) + Vector3.UP * sin(x * PI) * S * 0.4
				o["sw"].global_position = p
				o["sw"].global_basis = Basis(Vector3.UP, x * TAU * 5.0) * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3.ONE * S * 1.2)
				if is_instance_valid(c):
					for h in Combat.hit_sphere(c, p, 1.5 + S * 0.35, inf, hits):
						hits.append(h), 0.0, 1.0, go)
		tw.tween_method(func(x: float):
			if is_instance_valid(o["sw"]):
				o["sw"].global_basis = Basis(Vector3.UP, x * TAU * 4.0) * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3.ONE * S * 1.2)
				if is_instance_valid(c) and int(x * 8.0) != int((x - 0.02) * 8.0):
					Combat.hit_sphere(c, to, 1.8 + S * 0.4, Jutsu._inf(c, "kyoso_enbu", 0.25, {"knock": 4.0, "kind": "heavy", "bleed": 2.0}))
					VFX.shockwave(to, col.lightened(0.3), 3.0 + S * 0.4, 0.2)
			, 0.0, 1.0, 0.6)
		tw.tween_method(func(x: float):
			if is_instance_valid(o["sw"]) and is_instance_valid(sn):
				o["sw"].global_position = to.lerp(sn.hand(true), x)
				o["sw"].global_basis = Basis(Vector3.UP, x * TAU * 4.0) * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3.ONE * S * 1.2), 0.0, 1.0, go)
		tw.tween_callback(sw.queue_free)
		Sfx.play("blade", from, 0.6))


# ------------------------------------------------------------------ Susanoo: Kai (ref Narutopedia "Susanoo: Crush")
## Susanoo'nun eli rakibe uzanır, onu kavrar ve yumruğunun içinde ezer; sonra yere fırlatır
static func m_susanoo_kai(c: Node3D, t: Node3D) -> void:
	var sn = Susanoo.of(c, "susanoo_kai")
	if sn == null:
		return
	var H = sn.h()
	var S = H / 1.8
	var col = sn.color()
	var tg = Jutsu._tg(c, t, 6.0 + H * 1.2)
	if tg == null:
		if c is Player:
			Hud.msg("Hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var aim = _aim_fn(c, tg, 4.0 + H * 0.45)
	var d = _turn(c, aim.call())
	_pj().busy(c, 1.4)
	_anim(c, "push", 1.0)
	# uzan: el rakibe açık uzanır
	var ad = (aim.call() - sn.bone_at("RightUpperArm")).normalized()
	sn.pose({"arms": Susanoo.arm(true, ad, ad, ad), "spine": 10.0}, 0.9)
	Sfx.play("whoosh", c.global_position, 0.6, 0.7)
	_later(0.35, func():
		if not (is_instance_valid(c) and is_instance_valid(sn) and is_instance_valid(tg)) or tg.is_dead():
			return
		# kavra: hedef yumruğun içine alınır, havaya kaldırılır
		if tg.has_method("apply_status"):
			tg.apply_status("bind", 1.6)
		var hold = sn.hand(true)
		sn.pose({"arms": Susanoo.arm(true, (d + Vector3.UP * 0.6).normalized(), (d + Vector3.UP * 0.9).normalized(), Vector3.UP), "spine": 4.0}, 1.0)
		for k in 4:
			_later(0.15 + k * 0.25, func():
				if is_instance_valid(sn) and is_instance_valid(tg) and not tg.is_dead():
					tg.global_position = sn.hand(true) - Vector3.UP * 0.9
					if tg is CharacterBody3D:
						tg.velocity = Vector3.ZERO
					tg.take_hit(Jutsu._inf(c, "susanoo_kai", 0.45, {"knock": 0.0, "launch": 0.0, "kind": "crush", "pierce_guard": true}))
					VFX.shockwave(sn.hand(true), col.lightened(0.3), S * 0.5 + 1.2, 0.2, false)
					Sfx.play("hit_heavy", tg.global_position, 0.7, 0.6))
		Combat.popup_text(hold + Vector3.UP * 1.5, "Susanoo: Kai!", col.lightened(0.3)))
	# fırlat: el aşağı savrulur, hedef yere çarpar
	_later(1.4, func():
		if not (is_instance_valid(c) and is_instance_valid(sn) and is_instance_valid(tg)) or tg.is_dead():
			return
		sn.pose({"arms": Susanoo.arm(true, (d - Vector3.UP * 0.5).normalized(), d, d)}, 0.5, true)
		tg.take_hit(Jutsu._inf(c, "susanoo_kai", 1.2, {"knock": 18.0, "launch": -10.0, "kind": "heavy", "dir": d, "hitstop": 0.1}))
		var g = Jutsu._ground(tg.global_position)
		VFX.cracks(g, S * 0.6 + 3.0)
		VFX.debris(g + Vector3.UP * 0.4, Color(0.5, 0.42, 0.32), 12, 7.0, 0.35)
		_shake(0.6))
