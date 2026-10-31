class_name MsArts
extends RefCounted
## Mangekyō tarzlarının kendi teknikleri (Eyes.MS_STYLES): her biri ayrı hazırlık + bırakış + çarpma efekti.
## Susanoo teknikleri tarzın renginde geçici bir Susanoo çağırır (Itachi kırmızı, Sasuke mor, Madara mavi, Shisui yeşil,
## Kakashi turkuaz); Kamui teknikleri boyut girdabı; Shisui / Itachi yanılsamaları karga ve hayal. Jutsu.execute çağırır.

const COL := {"itachi": Color(1.0, 0.3, 0.25), "sasuke": Color(0.6, 0.35, 1.0), "madara": Color(0.25, 0.5, 1.0),
	"shisui": Color(0.3, 0.95, 0.5), "kakashi": Color(0.25, 0.95, 0.95)}

const IDS := ["totsuka_no_tsurugi", "yata_no_kagami", "magen_karasu_bunshin",
	"susanoo_kagutsuchi_no_yumiya", "enton_kagutsuchi_no_tsurugi", "susanoo_chidori", "enton_kokuen_no_tate", "enton_kokuryu",
	"kamui_surinuke", "kamui_kyuin", "kamui_ikukan_toji", "kamui_hanten", "kamui_kusari_shibari", "kamui_ikukan_tobi", "kamui_ranbu",
	"susanoo_kamui_ya", "raikiri_soryu", "kamui_kakushi", "kopi_ninja_no_me",
	"kyubi_shihai", "susanoo_kenjutsu", "kanzen_tai_itto", "susanoo_tate", "susanoo_shuha",
	"shunshin_genso", "susanoo_shisui_no_ya", "karasu_kuyo", "utakata_no_genso", "kotodama_no_shibari", "kyokei_shunshin"]


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


## Tarzın renginde geçici Susanoo (kademe, süre); oyuncuda kendi Susanoo ayarı (zırh/yüz), renk tarzdan
static func _sus(c: Node3D, tier: int, col: Color, dur: float) -> Susanoo:
	var sn = Susanoo.new()
	c.add_child(sn)
	# oyuncu: kendi özelleştirdiği Susanoo (renk, zırh, yüz, silah, kanat); başkaları tarzın renginde
	# NPC: kendine özgü rastgele Susanoo (EnemyArts ile aynı; bir kez zar atılır, saklanır)
	var mine = c == Game.player
	var pr = Game.profile if mine else EnemyArts.random_susanoo(c)
	sn.build(pr, tier, c.get("model"))
	# Susanoo kullanıcının baktığı yöne döner ve teknikler o yöne atılır (sırtı dönük kalıyordu)
	sn.face_owner = c
	if "facing" in c:
		sn.rotation.y = c.facing
	var fs = sn.scale
	sn.scale = fs * 0.1
	var tw = sn.create_tween()
	tw.tween_property(sn, "scale", fs, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(maxf(0.1, dur - 0.7))
	tw.tween_property(sn, "scale", fs * 0.05, 0.35)
	tw.tween_callback(sn.queue_free)
	Sfx.play("roar", c.global_position, 1.7, 0.45)
	VFX.shockwave(c.global_position + Vector3.UP * 0.2, col, 3.0 + tier * 1.5, 0.4)
	return sn


static func _spiral(pos: Vector3, size: float, dur: float, normal := Vector3(0, 0, 1)) -> MeshInstance3D:
	var sw = VFX._mi(VFX._sphere(0.5, 32, 16), VFX.mat_spiral(Color(0.05, 0.02, 0.08), Color(0.3, 0.15, 0.45), 3.0, 8.0, 10.0, 1.0, normal))
	_scene().add_child(sw)
	sw.global_position = pos
	if Game.player and Game.player.cam:
		sw.look_at(Game.player.cam.global_position, Vector3.UP)
	sw.scale = Vector3(0.1, 0.1, 0.02)
	var tw = sw.create_tween()
	tw.tween_property(sw, "scale", Vector3(size, size, size * 0.12), 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sw, "rotation:z", TAU * 2.0, dur)
	tw.tween_interval(maxf(0.0, dur - 0.6))
	tw.tween_property(sw, "scale", Vector3.ONE * 0.02, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(sw.queue_free)
	return sw


## Karga: iki kanatlı siyah gövde (kanat çırpar)
static func _crow() -> Node3D:
	var root = Node3D.new()
	var mb = MB.new()
	mb.add("sphere", Vector3.ZERO, Vector3(0.18, 0.16, 0.36), Color(0.05, 0.05, 0.07), Vector3.ZERO, 6)
	mb.add("sphere", Vector3(0, 0.06, -0.2), Vector3(0.12, 0.12, 0.12), Color(0.04, 0.04, 0.06), Vector3.ZERO, 6)
	mb.add("cone", Vector3(0, 0.05, -0.3), Vector3(0.03, 0.09, 0.03), Color(0.2, 0.2, 0.22), Vector3(-90, 0, 0), 4)
	mb.add("sphere", Vector3(0.05, 0.09, -0.25), Vector3(0.025, 0.025, 0.025), Color(0.9, 0.05, 0.05), Vector3.ZERO, 4)   # kırmızı göz (Sharingan kargası)
	var body = MeshInstance3D.new()
	body.mesh = mb.build(Props.toon())
	root.add_child(body)
	for sx in [-1.0, 1.0]:
		var wm = MB.new()
		wm.add("box", Vector3(sx * 0.3, 0, 0.02), Vector3(0.55, 0.02, 0.24), Color(0.06, 0.06, 0.08))
		var w = MeshInstance3D.new()
		w.mesh = wm.build(Props.toon())
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


## Susanoo oku / Kamui oku: yaydan çıkan parlak chakra oku, hedefe uçar
static func _sus_arrow(c: Node3D, from: Vector3, to: Vector3, col: Color, size: float, speed: float, on_hit: Callable) -> void:
	var mb = MB.new()
	mb.add("cyl", Vector3(0, 0, 0.9), Vector3(0.12, 2.8, 0.12), Color.WHITE, Vector3(90, 0, 0), 8)
	mb.add("cone", Vector3(0, 0, -0.75), Vector3(0.38, 0.9, 0.38), Color.WHITE, Vector3(-90, 0, 0), 8)
	for sx in [-1.0, 1.0]:
		mb.add("box", Vector3(0.18 * sx, 0, 2.1), Vector3(0.3, 0.02, 0.55), Color.WHITE)
	var ar = MeshInstance3D.new()
	ar.mesh = mb.build(null)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col.lightened(0.35)
	m.emission_enabled = true
	m.emission = col * 2.2
	ar.material_override = m
	ar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scene().add_child(ar)
	ar.global_position = from
	ar.scale = Vector3.ONE * size
	ar.look_at(to, Vector3.UP)
	var tr = VFX.trail(ar, 0.5 * size, col.lightened(0.5), col, Color(col.r, col.g, col.b, 0.0), 20, 1.0)
	var dur = clampf(from.distance_to(to) / speed, 0.08, 1.2)
	var tw = ar.create_tween()
	tw.tween_property(ar, "global_position", to, dur)
	tw.tween_callback(func():
		on_hit.call(to)
		ar.queue_free())


# ================================================================== ITACHI
## Totsuka no Tsurugi: kırmızı Susanoo'nun elinde sıvı ateşten ruh kılıcı; saplar, hedef girdaba çekilip mühürlenir gibi sersemler
static func m_totsuka_no_tsurugi(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["itachi"]
	var sn = _sus(c, 3, col, 2.6)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var tg = Jutsu._tg(c, t, 18.0)
	var aim = _chest(tg) if tg else c.global_position + c.face_dir() * 10.0 + Vector3.UP
	var blade = VFX._mi(VFX._sphere(0.5, 16, 8), VFX.mat_fire("spirit", 3.0, 2.0, 0.35, 1.6, 0.18, Vector3(0, 0, 1)))
	_scene().add_child(blade)
	var base = c.global_position + Vector3.UP * 5.2 + c.face_dir() * 1.5
	blade.global_position = base
	blade.look_at(aim, Vector3.UP)
	blade.scale = Vector3(0.6, 0.6, 0.2)
	VFX.gather(base, col, 1.2)
	var tw = blade.create_tween()
	tw.tween_property(blade, "scale", Vector3(0.9, 0.9, 9.0), 0.45).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func(): if is_instance_valid(sn) and sn.body: sn.body.play("jab", 0.05, 1.0, true))
	tw.tween_property(blade, "global_position", base.lerp(aim, 0.55), 0.18)
	tw.tween_callback(func():
		var inf = Jutsu._inf(c, "totsuka_no_tsurugi", 2.4, {"knock": 4.0, "kind": "heavy", "hitstop": 0.12, "dir": c.face_dir()})
		for h in Combat.hit_sphere(c, aim, 2.4, inf):
			h.apply_status("stun", 4.0)
			_spiral(_chest(h), 3.5, 1.6)   # sake testisine çekilir gibi
		VFX.star(aim, col.lightened(0.4), 5.0, 0.2)
		VFX.shockwave(aim, col, 6.0, 0.4, false, c.face_dir())
		VFX.embers(aim, col, 20, 6.0, 0.8)
		_shake(0.6))
	tw.tween_interval(0.5)
	tw.tween_property(blade, "scale", Vector3(0.1, 0.1, 0.1), 0.25)
	tw.tween_callback(blade.queue_free)


## Yata no Kagami: Susanoo'nun kolunda yansıtan ayna-kalkan; 6 sn ağır hasar azaltma, yakına gelen savrulur
static func m_yata_no_kagami(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["itachi"]
	var sn = _sus(c, 3, col, 6.2)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var disc = VFX._mi(VFX._sphere(0.5, 32, 4), VFX.mat_water(Color(0.6, 0.1, 0.1), col, Color(1.0, 0.85, 0.8), Vector3(0, 0, 1), 0.7, 0.3, 0.05))
	c.add_child(disc)
	disc.position = Vector3(0, 3.2, -2.2)
	disc.scale = Vector3(0.1, 0.1, 0.02)
	var tw = disc.create_tween()
	tw.tween_property(disc, "scale", Vector3(4.6, 4.6, 0.35), 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(5.4)
	tw.tween_property(disc, "scale", Vector3(0.1, 0.1, 0.02), 0.3)
	tw.tween_callback(disc.queue_free)
	if c is Player:
		Buffs.add("yata", 6.0, {"armor": 0.12})
	var inf = Jutsu._inf(c, "yata_no_kagami", 0.25, {"knock": 18.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.04})
	Jutsu._ticks(12, 0.5, func(_i):
		if not is_instance_valid(c):
			return
		var hs = Combat.hit_sphere(c, c.global_position + Vector3.UP, 3.6, inf)
		if not hs.is_empty():
			VFX.shockwave(c.global_position + Vector3.UP * 1.5, col, 5.0, 0.3, false, c.face_dir()))


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
## Susanoo: Kagutsuchi no Yumiya — mor Susanoo yay gerer, kara alevli ok; değdiği yerde kara alev sütunu
static func m_susanoo_kagutsuchi_no_yumiya(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["sasuke"]
	var sn = _sus(c, 3, col, 2.2)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var aim = _point(c, t, 60.0, 30.0)
	_later(0.45, func():
		if not is_instance_valid(c):
			return
		if is_instance_valid(sn) and sn.body:
			sn.body.play("throw", 0.05, 1.0, true)
		var from = c.global_position + Vector3.UP * 4.5 + c.face_dir() * 2.0
		VFX.gather(from, Color(0.3, 0.0, 0.4), 1.0)
		_sus_arrow(c, from, aim, col, 1.4, 70.0, func(p: Vector3):
			var inf = Jutsu._inf(c, "susanoo_kagutsuchi_no_yumiya", 1.8, {"knock": 14.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.08, "element": "katon"})
			for h in Combat.hit_sphere(c, p, 3.2, inf):
				Jutsu._ignite(h, 8.0)
			var fl = VFX.black_flames(2.0)
			_scene().add_child(fl)
			fl.global_position = Jutsu._ground(p)
			fl.scale = Vector3(1.0, 2.0, 1.0)
			_later(3.0, func(): if is_instance_valid(fl): fl.queue_free())
			VFX.shockwave(p, Color(0.25, 0.0, 0.3), 6.0, 0.5)
			VFX.black_smolder(Jutsu._ground(p), 3.0, 6.0)
			VFX.embers(p, Color(0.6, 0.15, 0.7), 24, 7.0, 1.0)
			_shake(0.7)))


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


## Susanoo: Chidori — mor Susanoo'nun dev eli şimşek kürene dolar, yumrukla ileri
static func m_susanoo_chidori(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["sasuke"]
	var sn = _sus(c, 3, col, 2.0)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var ball = VFX.lightning_ball(3.2, Color(0.55, 0.6, 1.0))
	c.add_child(ball)
	ball.position = Vector3(1.8, 3.6, -2.0)
	Sfx.play("chidori", c.global_position, 0.7)
	var aim = _point(c, t, 16.0, 10.0)
	_later(0.6, func():
		if not is_instance_valid(c):
			return
		if is_instance_valid(sn) and sn.body:
			sn.body.play("jab", 0.05, 1.2, true)
		var from = ball.global_position if is_instance_valid(ball) else c.global_position + Vector3.UP * 3.0
		if is_instance_valid(ball):
			var tw = ball.create_tween()
			tw.tween_property(ball, "global_position", aim, 0.16)
			tw.tween_callback(ball.queue_free)
		_later(0.16, func():
			var inf = Jutsu._inf(c, "susanoo_chidori", 2.0, {"knock": 18.0, "launch": 5.0, "kind": "heavy", "hitstop": 0.1, "element": "raiton", "stun": 1.2})
			Combat.hit_sphere(c, aim, 3.4, inf)
			for k in 6:
				VFX.bolt(aim, aim + Vector3(randf_range(-6, 6), randf_range(-1, 4), randf_range(-6, 6)), Color(0.6, 0.65, 1.0), 0.35, 0.3, 3)
			VFX.bolt(from, aim, Color(0.7, 0.8, 1.0), 0.5, 0.2, 4)
			VFX.star(aim, Color(0.8, 0.85, 1.0), 6.0, 0.2)
			VFX.shockwave(aim, Color(0.5, 0.55, 1.0), 7.0, 0.4, false, c.face_dir())
			VFX.cracks(Jutsu._ground(aim), 4.0)
			_shake(0.8)))


## Enton: Kokuen no Tate — önünde yay biçiminde kara alev duvarı; içinden geçen tutuşur, arkasındaki sen korunursun
static func m_enton_kokuen_no_tate(c: Node3D, t: Node3D) -> void:
	var fd: Vector3 = c.face_dir()
	var right = fd.cross(Vector3.UP).normalized()
	var fls = []
	Sfx.play("genjutsu", c.global_position, 0.6)
	for k in 7:
		var a = (k - 3) / 3.0
		var p = Jutsu._ground(c.global_position + fd * (3.2 - absf(a) * 0.8) + right * a * 4.2)
		var fl = VFX.black_flames(1.6)
		_scene().add_child(fl)
		fl.global_position = p
		fl.scale = Vector3(1.0, 0.05, 1.0)
		fl.create_tween().tween_property(fl, "scale", Vector3(1.0, 2.2, 1.0), 0.3 + absf(a) * 0.15).set_trans(Tween.TRANS_BACK)
		VFX.black_smolder(p, 1.0, 6.5)
		fls.append(fl)
	if c is Player:
		Buffs.add("kokuen", 6.0, {"armor": 0.55})
	var center = c.global_position + fd * 3.0
	var inf = Jutsu._inf(c, "enton_kokuen_no_tate", 0.15, {"knock": 10.0, "kind": "light", "element": "katon"})
	Jutsu._ticks(12, 0.5, func(_i):
		for h in Combat.hit_zone(c, c.global_position, fd, 4.5, 70.0, 3.5, inf):
			Jutsu._ignite(h, 4.0)
		VFX.embers(center + Vector3.UP, Color(0.6, 0.15, 0.7), 4, 2.0, 0.8), func():
		for fl in fls:
			if is_instance_valid(fl):
				var tw = fl.create_tween()
				tw.tween_property(fl, "scale", Vector3(1.0, 0.05, 1.0), 0.3)
				tw.tween_callback(fl.queue_free))


## Enton: Kokuryū — kara alevler ejderha biçiminde yükselip kıvrılır, hedefe dalar; çarpınca kara alev patlaması
static func m_enton_kokuryu(c: Node3D, t: Node3D) -> void:
	var fd = Jutsu._aim_flat(c, t)
	var tg = Jutsu._tg(c, t, 50.0)
	var start = c.global_position + Vector3.UP * 2.0 + fd * 1.5
	Sfx.play("genjutsu", c.global_position, 0.45)
	VFX.black_smolder(Jutsu._ground(start), 2.0, 3.0)
	var pr = Projectile.new()
	pr.shooter = c
	pr.vel = Vector3.UP * 12.0 + fd * 6.0
	pr.radius = 1.6
	pr.life = 3.5
	pr.homing = tg
	pr.homing_turn = 3.0
	pr.info = Jutsu._inf(c, "enton_kokuryu", 1.6, {"knock": 16.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.08, "element": "katon"})
	var bm = Jutsu._black_mat()
	var head = VfxSerpent.dragon_head(bm, 3.2, Color(0.85, 0.3, 1.0))
	pr.add_child(head)
	var body = VfxSerpent.new()
	body.style = "dark"
	body.seed_id = "enton_kokuryu"
	body.head = pr
	body.count = 18
	body.spacing = 1.6
	body.radius = 1.9
	body.mat = bm
	body.fin_mat = bm
	_scene().add_child(body)
	var age = {"t": 0.0}
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		age["t"] += dt
		if age["t"] < 0.7:
			p.vel = Vector3.UP * 20.0 + fd.cross(Vector3.UP) * cos(age["t"] * 8.0) * 10.0 + fd * 4.0
			return
		p.homing_turn = 6.0
		if tg == null and p.life < 2.9:
			p.vel = p.vel.lerp(Jutsu._aim(c, null) * 26.0, 0.06)
		p.vel = p.vel.normalized() * minf(32.0, p.vel.length() + 0.7)
	pr.on_hit = func(pos: Vector3, h: Node3D) -> void:
		if h:
			Jutsu._ignite(h, 8.0)
		for x in Combat.hit_sphere(c, pos, 4.0, Jutsu._inf(c, "enton_kokuryu", 0.6, {"knock": 12.0, "element": "katon"}), pr.hit_list):
			Jutsu._ignite(x, 6.0)
		VFX.shockwave(pos, Color(0.25, 0.0, 0.3), 7.0, 0.5)
		VFX.black_smolder(Jutsu._ground(pos), 3.5, 7.0)
		VFX.embers(pos, Color(0.6, 0.15, 0.7), 30, 8.0, 1.0)
		_shake(0.8)
	_scene().add_child(pr)
	pr.global_position = start


# ================================================================== OBITO
## Kamui: Surinuke — beden boyuta kayar: 3 sn saldırılar içinden geçer (yarı saydam, yüzünde girdap)
static func m_kamui_surinuke(c: Node3D, t: Node3D) -> void:
	Sfx.play("genjutsu", c.global_position, 1.1)
	var sw = _spiral(c.global_position + Vector3.UP * 1.5, 1.2, 3.0)
	if c is Player and c.combat:
		c.combat.invuln = maxf(c.combat.invuln, 3.0)
	if c.get("model") and c.model:
		c.model.flash(0.6)
	var ring = FX.aura(c, Color(0.35, 0.2, 0.55), 3.0, Vector3(0, 0.9, 0), 0.0)
	Jutsu._ticks(10, 0.3, func(_i):
		if is_instance_valid(sw) and is_instance_valid(c):
			sw.global_position = c.global_position + Vector3.UP * 1.5
		if is_instance_valid(c):
			VFX.puffs(c.global_position + Vector3.UP, {"amount": 4, "life": 0.5, "size": 0.5, "radius": 0.6, "vmin": 0.5, "vmax": 1.5,
				"colors": [Color(0.3, 0.15, 0.45, 0.6), Color(0.1, 0.05, 0.15, 0)]}), func():
		if is_instance_valid(ring):
			ring.emitting = false
			_later(1.0, ring.queue_free))


## Kamui: Kyūin — bakılan alanda dev sarmal açılır, çevredekileri içine çeker, sonunda kapanıp ezer
static func m_kamui_kyuin(c: Node3D, t: Node3D) -> void:
	var pos = _point(c, t, 30.0, 14.0)
	var sw = _spiral(pos, 12.0, 2.2)
	Sfx.play("genjutsu", pos, 0.6)
	var inf = Jutsu._inf(c, "kamui_kyuin", 0.3, {"knock": 0.0, "kind": "light"})
	Jutsu._ticks(10, 0.2, func(_i):
		for f in Jutsu.get_tree().get_nodes_in_group("fighters"):
			if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(pos) < 9.0:
				var d = pos - f.global_position
				f.velocity = d.normalized() * minf(14.0, d.length() * 3.0)
				f.apply_status("stun", 0.4)
				f.take_hit(inf.merged({"attacker": c, "dir": d.normalized()}))
		VFX.puffs(pos, {"amount": 10, "life": 0.5, "size": 0.6, "radius": 5.0, "vmin": -6, "vmax": -3, "colors": [Color(0.3, 0.15, 0.45, 0.7), Color(0.05, 0.02, 0.08, 0)]}), func():
		Combat.hit_sphere(c, pos, 4.0, Jutsu._inf(c, "kamui_kyuin", 1.2, {"knock": 12.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.08}))
		VFX.star(pos, Color(0.6, 0.4, 0.9), 6.0, 0.2)
		VFX.shockwave(pos, Color(0.3, 0.15, 0.45), 8.0, 0.4, false)
		_shake(0.6))


## Kamui: Ikūkan Tōji — hedef küçük bir girdaba çekilip kaybolur (2 sn boyutta hasar), sonra fırlatılarak geri düşer
static func m_kamui_ikukan_toji(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 30.0)
	if tg == null:
		if c is Player: Hud.msg("Hapsedecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var p0 = _chest(tg)
	_spiral(p0, 4.0, 1.0)
	Sfx.play("genjutsu", p0, 0.8)
	tg.apply_status("stun", 3.0)
	if tg.get("model"):
		var tw = tg.model.create_tween()
		tw.tween_property(tg.model, "scale", Vector3.ONE * 0.05, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	Jutsu._ticks(5, 0.4, func(_i):
		if is_instance_valid(tg) and not tg.is_dead():
			tg.take_hit(Jutsu._inf(c, "kamui_ikukan_toji", 0.3, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO})), func():
		if not is_instance_valid(tg):
			return
		_spiral(p0 + Vector3.UP * 3.0, 4.0, 0.8)
		if tg.get("model"):
			tg.model.create_tween().tween_property(tg.model, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
		if not tg.is_dead():
			tg.take_hit(Jutsu._inf(c, "kamui_ikukan_toji", 0.8, {"knock": 10.0, "launch": 8.0, "kind": "heavy", "attacker": c, "dir": Vector3.UP})))


## Kamui: Hanten — 2.5 sn boyutu açık tutar (hasar emilir), sonra emilen güç çevrene ters girdap patlaması olarak döner
static func m_kamui_hanten(c: Node3D, t: Node3D) -> void:
	var sw = _spiral(c.global_position + Vector3.UP * 1.3, 2.4, 2.6)
	Sfx.play("genjutsu", c.global_position, 0.95)
	if c is Player:
		Buffs.add("hanten", 2.5, {"armor": 0.1})
	Jutsu._ticks(8, 0.3, func(_i):
		if is_instance_valid(sw) and is_instance_valid(c):
			sw.global_position = c.global_position + Vector3.UP * 1.3, func():
		if not is_instance_valid(c):
			return
		var p = c.global_position + Vector3.UP
		Combat.hit_sphere(c, p, 7.0, Jutsu._inf(c, "kamui_hanten", 1.6, {"knock": 20.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.1}))
		_spiral(p, 10.0, 0.8)
		VFX.shockwave(p, Color(0.35, 0.2, 0.55), 10.0, 0.45, false)
		VFX.debris(Jutsu._ground(p), Color(0.4, 0.35, 0.4), 16, 10.0, 0.5)
		_shake(0.8))


## Kamui: Kusari Shibari — hedefin arkasında girdap açılır, içinden zincirler fırlayıp hedefi sarar (4 sn bağlı)
static func m_kamui_kusari_shibari(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 30.0)
	if tg == null:
		if c is Player: Hud.msg("Bağlanacak hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var back = tg.global_position + (tg.global_position - c.global_position).normalized() * 3.0 + Vector3.UP * 2.5
	_spiral(back, 3.0, 4.2)
	Sfx.play("seal", back, 0.7)
	var links = Node3D.new()
	_scene().add_child(links)
	var dst = _chest(tg)
	var n = 14
	for i in n:
		var l = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 0.08; tm.outer_radius = 0.16; tm.rings = 8; tm.ring_segments = 6
		l.mesh = tm
		l.material_override = Props.toon_color(Color(0.3, 0.3, 0.34))
		links.add_child(l)
		l.global_position = back
		l.rotation = Vector3(0, 0, PI * 0.5 * (i % 2))
		var tw = l.create_tween()
		tw.tween_interval(i * 0.02)
		tw.tween_property(l, "global_position", back.lerp(dst, float(i) / (n - 1)), 0.2)
	tg.apply_status("bind", 4.0)
	tg.take_hit(Jutsu._inf(c, "kamui_kusari_shibari", 0.6, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	_later(4.0, links.queue_free)


## Kamui: Ikūkan Tobi — girdaba girer, hedefin arkasındaki girdaptan çıkıp vurursun
static func m_kamui_ikukan_tobi(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 40.0)
	var from = c.global_position
	_spiral(from + Vector3.UP * 1.2, 2.6, 0.7)
	Sfx.play("genjutsu", from, 1.2)
	var dest = Jutsu._ground((tg.global_position - (tg.global_position - from).normalized() * -1.8) if tg else from + Jutsu._aim_flat(c, t) * 16.0)
	if c.get("model"):
		c.model.visible = false
	_later(0.35, func():
		if not is_instance_valid(c):
			return
		_spiral(dest + Vector3.UP * 1.2, 2.6, 0.7)
		c.global_position = dest
		if c.has_method("reset_physics_interpolation"):
			c.reset_physics_interpolation()
		if c.get("model"):
			c.model.visible = true
		if tg and is_instance_valid(tg) and not tg.is_dead():
			var d = tg.global_position - dest
			d.y = 0
			if c is Player:
				c.facing = atan2(-d.x, -d.z)
			_anim(c, "slash_c", 1.4)
			tg.take_hit(Jutsu._inf(c, "kamui_ikukan_tobi", 1.4, {"knock": 9.0, "attacker": c, "dir": d.normalized(), "hitstop": 0.08}))
			VFX.star(_chest(tg), Color(0.6, 0.4, 0.9), 3.0, 0.15))


## Kamui: Ranbu — hedefin üstünde üç girdap açılır, içlerinden kunai ve shuriken yağar
static func m_kamui_ranbu(c: Node3D, t: Node3D) -> void:
	var pos = Jutsu._ground(_point(c, t, 35.0, 16.0))
	var portals = []
	for k in 3:
		var a = TAU * k / 3.0
		var pp = pos + Vector3(cos(a) * 3.0, 9.0, sin(a) * 3.0)
		_spiral(pp, 3.2, 2.6, Vector3.UP)
		portals.append(pp)
	Sfx.play("whoosh", pos, 0.8)
	var kmesh = CharacterModel.weapon_mesh("kunai")
	var inf = Jutsu._inf(c, "kamui_ranbu", 0.22, {"knock": 2.0, "kind": "light"})
	Jutsu._ticks(18, 0.1, func(i):
		var from: Vector3 = portals[int(i) % 3]
		var to = pos + Vector3(randf_range(-3.5, 3.5), 0.1, randf_range(-3.5, 3.5))
		var k = MeshInstance3D.new()
		k.mesh = kmesh
		_scene().add_child(k)
		k.global_position = from
		k.look_at(to, Vector3.UP)
		var tw = k.create_tween()
		tw.tween_property(k, "global_position", to, 0.22)
		tw.tween_callback(func():
			Combat.hit_sphere(c, to + Vector3.UP, 1.4, inf)
			FX.dust(to, 0.4))
		tw.tween_interval(1.5)
		tw.tween_callback(k.queue_free))


# ================================================================== KAKASHI
## Susanoo: Kamui no Ya — turkuaz Susanoo'nun oku; değdiği yerde Kamui girdabı açılıp koparır
static func m_susanoo_kamui_ya(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["kakashi"]
	var sn = _sus(c, 3, col, 2.2)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var aim = _point(c, t, 60.0, 30.0)
	var tg = Jutsu._tg(c, t, 60.0)
	_later(0.45, func():
		if not is_instance_valid(c):
			return
		if is_instance_valid(sn) and sn.body:
			sn.body.play("throw", 0.05, 1.0, true)
		var from = c.global_position + Vector3.UP * 4.5 + c.face_dir() * 2.0
		_sus_arrow(c, from, aim, col, 1.3, 75.0, func(p: Vector3):
			_spiral(p, 8.0, 1.4)
			Combat.hit_sphere(c, p, 3.0, Jutsu._inf(c, "susanoo_kamui_ya", 1.4, {"knock": 6.0, "kind": "heavy", "hitstop": 0.08}))
			if tg and is_instance_valid(tg) and not tg.is_dead():
				tg.apply_status("stun", 1.5)
				Jutsu._ticks(5, 0.2, func(_i):
					if is_instance_valid(tg) and not tg.is_dead():
						tg.take_hit(Jutsu._inf(c, "susanoo_kamui_ya", 0.3, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO})))
			VFX.shockwave(p, col, 6.0, 0.4, false)
			_shake(0.6)))


## Raikiri: Sōryū — iki elde Raikiri, ikiz şimşek ejderhası olarak kıvrılarak hedefe saldırır
static func m_raikiri_soryu(c: Node3D, t: Node3D) -> void:
	var aim = _point(c, t, 40.0, 20.0)
	var right = c.face_dir().cross(Vector3.UP).normalized()
	Sfx.play("chidori", c.global_position, 0.9)
	_anim(c, "cast_out", 1.0)
	for sx in [-1.0, 1.0]:
		var ball = VFX.lightning_ball(0.7, Color(0.55, 0.75, 1.0))
		_scene().add_child(ball)
		var from = c.global_position + Vector3.UP * 1.3 + right * sx * 0.5 + c.face_dir() * 0.4
		ball.global_position = from
		var mid = (from + aim) * 0.5 + right * sx * 6.0 + Vector3.UP * 3.0
		var last = [from]
		var tw = ball.create_tween()
		tw.tween_interval(0.25)
		tw.tween_method(func(x: float):
			if not is_instance_valid(ball):
				return
			var p = from.lerp(mid, x).lerp(mid.lerp(aim, x), x)
			VFX.bolt(last[0], p, Color(0.6, 0.8, 1.0), 0.35, 0.25, 1)
			last[0] = p
			ball.global_position = p, 0.0, 1.0, 0.45)
		tw.tween_callback(func():
			Combat.hit_sphere(c, aim, 2.8, Jutsu._inf(c, "raikiri_soryu", 1.0, {"knock": 10.0, "launch": 3.0, "kind": "heavy", "element": "raiton", "stun": 0.8, "hitstop": 0.06}))
			VFX.star(aim, Color(0.75, 0.85, 1.0), 4.5, 0.18)
			VFX.shockwave(aim, Color(0.5, 0.7, 1.0), 5.0, 0.35, false)
			ball.queue_free())
	_later(0.75, func(): _shake(0.6))


## Kamui: Kakushi — bedenini boyutun eşiğine çekersin: 6 sn görünmezsin, düşmanlar hedefini kaybeder
static func m_kamui_kakushi(c: Node3D, t: Node3D) -> void:
	_spiral(c.global_position + Vector3.UP * 1.2, 2.2, 0.8)
	Sfx.play("genjutsu", c.global_position, 1.3)
	if c.get("model"):
		c.model.visible = false
	for f in Jutsu.get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and f.get("target") == c:
			f.set("target", null)
	if c is Player:
		Buffs.add("kakushi", 6.0, {"speed": 1.2})
	_later(6.0, func():
		if is_instance_valid(c) and c.get("model"):
			c.model.visible = true
			_spiral(c.global_position + Vector3.UP * 1.2, 2.2, 0.6))


## Sharingan: Kopī Ninja no Me — göz rakibin hareketini okur: 10 sn jutsu gücü ve hız artar, kırmızı görüş
static func m_kopi_ninja_no_me(c: Node3D, t: Node3D) -> void:
	Sfx.play("sharingan", null)
	if c is Player:
		Buffs.add("kopi", 10.0, {"jutsu": 1.25, "speed": 1.12, "armor": 0.85})
		_tint(Color(0.9, 0.05, 0.05, 0.12), 0.6)
	var a = FX.aura(c, Color(1.0, 0.2, 0.2), 10.0, Vector3(0, 1.6, 0), 0.0)
	VFX.shockwave(c.global_position + Vector3.UP * 1.6, Color(0.9, 0.05, 0.05), 3.0, 0.4, false, c.face_dir())
	_later(10.0, func():
		if is_instance_valid(a):
			a.emitting = false
			_later(1.0, a.queue_free))


# ================================================================== MADARA
## Sharingan: Kyūbi Shihai — dev tomoe halkası hedefin çevresinde döner: hedef uzun süre, çevresi kısa süre donar
static func m_kyubi_shihai(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 30.0)
	if tg == null:
		if c is Player: Hud.msg("Göz göze gelecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	Sfx.play("genjutsu", c.global_position, 0.4)
	_tint(Color(0.7, 0.0, 0.05, 0.3), 0.8)
	var p = _chest(tg)
	var ring = Node3D.new()
	_scene().add_child(ring)
	ring.global_position = p
	for k in 3:
		var a = TAU * k / 3.0
		var mb = MB.new()
		mb.add("sphere", Vector3.ZERO, Vector3(0.6, 0.6, 0.15), Color(0.05, 0.02, 0.02), Vector3.ZERO, 10)
		mb.add("cone", Vector3(0.3, 0.3, 0), Vector3(0.24, 0.6, 0.1), Color(0.05, 0.02, 0.02), Vector3(0, 0, -45), 6)
		var tm = MeshInstance3D.new()
		tm.mesh = mb.build(Props.toon())
		ring.add_child(tm)
		tm.position = Vector3(cos(a), sin(a), 0) * 2.4
	var disc = VFX._mi(VFX._sphere(0.5, 32, 4), VFX.mat_spiral(Color(0.9, 0.05, 0.05), Color(0.5, 0.0, 0.02), 3.0, 2.0, 4.0, 0.9, Vector3(0, 0, 1)))
	ring.add_child(disc)
	disc.scale = Vector3(6.5, 6.5, 0.05)
	if Game.player and Game.player.cam:
		ring.look_at(Game.player.cam.global_position, Vector3.UP)
	var tw = ring.create_tween()
	tw.tween_property(ring, "rotation:z", TAU, 1.4)
	tw.tween_property(ring, "scale", Vector3.ONE * 0.05, 0.3)
	tw.tween_callback(ring.queue_free)
	tg.apply_status("stun", 5.5)
	tg.take_hit(Jutsu._inf(c, "kyubi_shihai", 1.0, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	for f in Jutsu.get_tree().get_nodes_in_group("fighters"):
		if f != tg and Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(tg.global_position) < 10.0:
			f.apply_status("stun", 2.0)
	VFX.shockwave(p, Color(0.9, 0.05, 0.05), 10.0, 0.6, false)


## Susanoo: Kenjutsu — mavi Susanoo iki kılıçla çevreni yarar (iki geniş kesik)
static func m_susanoo_kenjutsu(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["madara"]
	var sn = _sus(c, 4, col, 2.6)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var fd = c.face_dir()
	for k in 2:
		_later(0.4 + k * 0.5, func():
			if not is_instance_valid(c):
				return
			if is_instance_valid(sn) and sn.body:
				sn.body.play(["slash_a", "slash_b"][k], 0.05, 1.2, true)
			Combat.hit_zone(c, c.global_position, fd, 16.0, 100.0, 12.0, Jutsu._inf(c, "susanoo_kenjutsu", 1.1, {"knock": 16.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.08, "dir": fd}))
			var arc = VFX._mi(VFX.asset("slash_arc"), VFX.mat_trail(col.lightened(0.6), col, Color(col.r, col.g, col.b, 0.0), 1.0))
			_scene().add_child(arc)
			arc.global_position = c.global_position + Vector3.UP * (5.0 - k * 2.0) + fd * 6.0
			arc.look_at(arc.global_position + fd, Vector3.UP)
			arc.rotation.z = deg_to_rad(-25.0 if k == 0 else 25.0)
			arc.scale = Vector3.ONE * 10.0
			var tw = arc.create_tween()
			tw.tween_property(arc, "scale", Vector3.ONE * 14.0, 0.3)
			tw.tween_property(arc, "scale", Vector3.ONE * 0.1, 0.2)
			tw.tween_callback(arc.queue_free)
			VFX.debris(Jutsu._ground(c.global_position + fd * 8.0), Color(0.5, 0.42, 0.32), 14, 10.0, 0.6)
			_shake(0.7))


## Kanzen Tai: Ittō — dev Susanoo tek savuruşla önündeki her şeyi yarar: uzayan kesik dalgası, yerde uzun yarık
static func m_kanzen_tai_itto(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["madara"]
	var sn = _sus(c, 5, col, 3.0)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var fd = Jutsu._aim_flat(c, t)
	Sfx.play("roar", c.global_position, 0.6, 0.8)
	_tint(Color(0.05, 0.1, 0.35, 0.25), 1.2)
	_later(1.0, func():
		if not is_instance_valid(c):
			return
		if is_instance_valid(sn) and sn.body:
			sn.body.play("slash_c", 0.05, 0.9, true)
		var wave = VFX._mi(VFX.asset("slash_arc"), VFX.mat_trail(Color(0.9, 0.95, 1.0), col, Color(col.r, col.g, col.b, 0.0), 1.0))
		_scene().add_child(wave)
		var from = c.global_position + Vector3.UP * 3.0 + fd * 4.0
		wave.global_position = from
		wave.look_at(from + fd, Vector3.UP)
		wave.rotation.z = PI * 0.5
		wave.scale = Vector3.ONE * 9.0
		var tw = wave.create_tween()
		tw.tween_property(wave, "global_position", from + fd * 60.0, 0.6)
		tw.parallel().tween_property(wave, "scale", Vector3.ONE * 16.0, 0.6)
		tw.tween_callback(wave.queue_free)
		Combat.hit_zone(c, c.global_position, fd, 62.0, 9.0, 20.0, Jutsu._inf(c, "kanzen_tai_itto", 3.0, {"knock": 24.0, "launch": 8.0, "kind": "heavy", "hitstop": 0.14, "dir": fd}))
		for k in 10:
			var gp = Jutsu._ground(c.global_position + fd * (6.0 + k * 5.5))
			_later(k * 0.05, func():
				VFX.cracks(gp, 4.0)
				VFX.debris(gp, Color(0.5, 0.42, 0.32), 8, 9.0, 0.6))
		VFX.screen_lines(0.5, 1.0, col.lightened(0.5))
		_shake(1.2))


## Susanoo: Tate — mavi Susanoo kaburgaları ve kolları seni sarar: 7 sn ağır hasar azaltma
static func m_susanoo_tate(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["madara"]
	var sn = _sus(c, 2, col, 7.0)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	if is_instance_valid(sn) and sn.body:
		sn.body.play("block", 0.1, 1.0, false)
	if c is Player:
		Buffs.add("susanoo_tate", 7.0, {"armor": 0.25})
	Jutsu._ticks(7, 1.0, func(_i):
		if is_instance_valid(c):
			VFX.shockwave(c.global_position + Vector3.UP * 0.2, col, 4.0, 0.5))


## Susanoo: Shūha — Susanoo yumruğunu yere indirir: üç halka şok dalgası, yer yarılır, düşmanlar havaya savrulur
static func m_susanoo_shuha(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["madara"]
	var sn = _sus(c, 3, col, 2.2)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	_later(0.5, func():
		if not is_instance_valid(c):
			return
		if is_instance_valid(sn) and sn.body:
			sn.body.play("knock", 0.05, 1.4, true)
		var gp = Jutsu._ground(c.global_position + c.face_dir() * 3.0)
		for k in 3:
			_later(k * 0.18, func():
				VFX.shockwave(gp + Vector3.UP * 0.2, col, 8.0 + k * 6.0, 0.45)
				Combat.hit_sphere(c, gp + Vector3.UP, 5.0 + k * 3.0, Jutsu._inf(c, "susanoo_shuha", 0.55, {"knock": 14.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.05})))
		VFX.cracks(gp, 9.0)
		VFX.debris(gp, Color(0.5, 0.42, 0.32), 24, 14.0, 0.8)
		FX.dust(gp, 3.0)
		_shake(1.0))


# ================================================================== SHISUI
## Shunshin Gensō — göz açıp kapayana kadar hedefin arkasında; geride yeşil yanılsama izleri kalır
static func m_shunshin_genso(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 35.0)
	var from = c.global_position
	var dest = Jutsu._ground((tg.global_position - (tg.global_position - from).normalized() * -1.6) if tg else from + Jutsu._aim_flat(c, t) * 14.0)
	var col: Color = COL["shisui"]
	for k in 5:
		var p = from.lerp(dest, k / 4.0) + Vector3.UP
		VFX.puffs(p, {"amount": 6, "life": 0.5, "size": 0.8, "radius": 0.4, "vmin": 0.2, "vmax": 0.8, "colors": [Color(col.r, col.g, col.b, 0.5), Color(col.r, col.g, col.b, 0)]})
	VFX.bolt(from + Vector3.UP, dest + Vector3.UP, col, 0.25, 0.15, 0)
	c.global_position = dest
	if c.has_method("reset_physics_interpolation"):
		c.reset_physics_interpolation()
	Sfx.play("whoosh", dest, 1.9)
	if tg and is_instance_valid(tg) and not tg.is_dead():
		var d = tg.global_position - dest
		d.y = 0
		if c is Player:
			c.facing = atan2(-d.x, -d.z)
		tg.take_hit(Jutsu._inf(c, "shunshin_genso", 1.1, {"knock": 8.0, "attacker": c, "dir": d.normalized(), "hitstop": 0.06}))
		tg.apply_status("stun", 0.8)
		VFX.star(_chest(tg), col, 3.0, 0.15)
	VFX.screen_lines(0.3, 0.8, col)


## Susanoo: Shisui no Ya — yeşil Susanoo'nun delici oku: yol boyunca herkesi deler geçer
static func m_susanoo_shisui_no_ya(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["shisui"]
	var sn = _sus(c, 3, col, 2.2)
	col = sn.color()   # efektler Susanoo'nun kendi renginde (oyuncu: özelleştirdiği, NPC: rastgele)
	var fd = Jutsu._aim(c, t)
	_later(0.45, func():
		if not is_instance_valid(c):
			return
		if is_instance_valid(sn) and sn.body:
			sn.body.play("throw", 0.05, 1.0, true)
		var from = c.global_position + Vector3.UP * 4.5 + c.face_dir() * 2.0
		var to = from + fd * 55.0
		_sus_arrow(c, from, to, col, 1.2, 90.0, func(_p: Vector3):
			VFX.star(to, col, 4.0, 0.2))
		Combat.hit_zone(c, c.global_position, Vector3(fd.x, 0, fd.z).normalized(), 55.0, 5.0, 10.0, Jutsu._inf(c, "susanoo_shisui_no_ya", 1.6, {"knock": 12.0, "kind": "heavy", "hitstop": 0.06, "dir": fd}))
		VFX.screen_lines(0.35, 0.8, col)
		_shake(0.5))


## Karasu Kuyō — karga sürüsü hedef bölgenin üstüne çullanır: gagalar, gözleri kör eder (yavaşlama + sersemleme)
static func m_karasu_kuyo(c: Node3D, t: Node3D) -> void:
	var pos = Jutsu._ground(_point(c, t, 35.0, 14.0))
	Sfx.play("genjutsu", c.global_position, 1.0)
	_crows(c.global_position + Vector3.UP * 1.5, pos + Vector3.UP * 1.2, 34, 0.8, func():
		var inf = Jutsu._inf(c, "karasu_kuyo", 0.25, {"knock": 1.0, "kind": "light"})
		Jutsu._ticks(8, 0.25, func(_i):
			for h in Combat.hit_sphere(c, pos + Vector3.UP, 5.5, inf):
				h.apply_status("slow", 3.0)
			VFX.puffs(pos + Vector3.UP * 1.5, {"amount": 10, "life": 0.6, "size": 0.35, "radius": 4.0, "vmin": 1.0, "vmax": 3.0,
				"colors": [Color(0.04, 0.04, 0.06, 1), Color(0.04, 0.04, 0.06, 0)]}), func():
			for h in Combat.hit_sphere(c, pos + Vector3.UP, 5.5, inf):
				h.apply_status("stun", 1.6)))


## Utakata no Gensō — yeşil-beyaz köpük halkası yayılır: çevrendeki herkes bir anlığına hayale dalar
static func m_utakata_no_genso(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["shisui"]
	Sfx.play("genjutsu", c.global_position, 0.75)
	for k in 3:
		_later(k * 0.15, func():
			if is_instance_valid(c):
				VFX.shockwave(c.global_position + Vector3.UP * (0.4 + k * 0.6), col.lightened(0.3), 14.0 + k * 3.0, 0.7, true))
	VFX.puffs(c.global_position + Vector3.UP, {"amount": 40, "life": 1.2, "size": 0.5, "radius": 2.0, "vmin": 4.0, "vmax": 9.0, "spread": 180.0,
		"colors": [Color(0.9, 1.0, 0.95, 0.7), Color(col.r, col.g, col.b, 0.0)]})
	for f in Jutsu.get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and not f.is_dead() and f.global_position.distance_to(c.global_position) < 14.0:
			f.apply_status("stun", 2.6)
			f.take_hit(Jutsu._inf(c, "utakata_no_genso", 0.4, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	_tint(Color(0.6, 1.0, 0.8, 0.12), 0.5)


## Kotodama no Shibari — hedefin üstünde parlayan "縛" (bağ) yazısı belirir; tek emirle kıpırdayamaz (4.5 sn)
static func m_kotodama_no_shibari(c: Node3D, t: Node3D) -> void:
	var tg = Jutsu._tg(c, t, 30.0)
	if tg == null:
		if c is Player: Hud.msg("Göz göze gelecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var col: Color = COL["shisui"]
	Sfx.play("seal", tg.global_position, 0.8)
	var l = Label3D.new()
	l.text = "縛"
	l.font_size = 220
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = col.lightened(0.4)
	l.outline_modulate = Color(0.0, 0.15, 0.05)
	l.outline_size = 24
	_scene().add_child(l)
	l.global_position = tg.global_position + Vector3.UP * (float(tg.height) + 1.2)
	l.scale = Vector3.ONE * 0.1
	var tw = l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(4.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
	tg.apply_status("bind", 4.5)
	tg.take_hit(Jutsu._inf(c, "kotodama_no_shibari", 0.5, {"knock": 0.0, "attacker": c, "dir": Vector3.ZERO}))
	VFX.shockwave(tg.global_position + Vector3.UP * 0.2, col, 4.0, 0.5)


## Kyōkei Shunshin — art arda belirip kaybolan üç yanılsama + gerçek gölge klonlar; düşman hangisinin sen olduğunu bilemez
static func m_kyokei_shunshin(c: Node3D, t: Node3D) -> void:
	var col: Color = COL["shisui"]
	Sfx.play("whoosh", c.global_position, 1.6)
	for k in 3:
		var a = TAU * k / 3.0 + randf()
		var p = c.global_position + Vector3(cos(a), 0, sin(a)) * 3.0
		_later(k * 0.1, func():
			VFX.star(p + Vector3.UP, col, 2.5, 0.15)
			VFX.puffs(p + Vector3.UP, {"amount": 8, "life": 0.5, "size": 0.7, "radius": 0.5, "vmin": 0.5, "vmax": 1.5, "colors": [Color(col.r, col.g, col.b, 0.6), Color(col.r, col.g, col.b, 0)]}))
	JutsuEngine._clone(c, Data.jutsu.get("kyokei_shunshin", {}))
	for f in Jutsu.get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(c, f) and f.get("target") == c and randf() < 0.6:
			f.apply_status("stun", 0.8)
