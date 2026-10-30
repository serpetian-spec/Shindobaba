class_name BossStyles
extends RefCounted
## Boss dövüş tarzları: her boss yalnız can/güçle değil davranışla farklı (kendi saldırıları, aşama değişimi).
## arch["style"] verilen Enemy her karede tick() çağırır; can %50'nin altına inince 2. aşama.
## Tarzlar: kenjutsu (kılıç ustası), kugutsu (kuklacı), genjutsu (yanılsama ustası), taijutsu (kapı açan),
##          fuin (mühür/tuzak ustası), bakuton (patlayıcı), clan (klan tekniği kullanıcısı)

const STYLES := {
	"kenjutsu": {"title": "Kılıç Ustası", "weapon": "katana", "skill": 0.15},
	"kugutsu": {"title": "Kuklacı", "weapon": "", "skill": 0.0},
	"genjutsu": {"title": "Yanılsama Ustası", "weapon": "", "skill": 0.1},
	"taijutsu": {"title": "Taijutsu Canavarı", "weapon": "", "skill": 0.2},
	"fuin": {"title": "Mühür Ustası", "weapon": "", "skill": 0.05},
	"bakuton": {"title": "Patlatıcı", "weapon": "", "skill": 0.05},
	"kuchiyose": {"title": "Çağırıcı", "weapon": "", "skill": 0.1},
}
## Rütbeye göre dövüş ustalığı (stat değil: kaçınma, blok, kombo, kawarimi sıklığı)
const RANK_SKILL := {"D": 0.15, "C": 0.35, "B": 0.55, "A": 0.75, "S": 0.92}


## Görev/Bingo boss tanımına tarz ve ustalık ver. seed: aynı görev hep aynı tarzı seçsin
static func dress(a: Dictionary, rank: String, seed_v: int, style := "") -> void:
	# kalıp tarzlar (çağırıcı/kuklacı/patlatıcı...) kaldırıldı: herkes kendi jutsularıyla dövüşür,
	# rütbe yalnız dövüş ustalığını (blok, kaçınma, kombo, kawarimi) belirler
	a.erase("style")
	a["skill"] = clampf(float(RANK_SKILL.get(rank, 0.5)), 0.1, 0.98)
	return
	var keys = STYLES.keys()
	# element jutsusu atan biri birden kuklacı/çağırıcı/patlatıcı olmasın: kimliğini değiştirmeyen tarzlar
	if String(a.get("element", "")) != "" and not (a.get("jutsu", []) as Array).is_empty():
		keys = ["kenjutsu", "genjutsu", "taijutsu", "fuin"]
	if style == "" or not STYLES.has(style):
		style = keys[absi(seed_v) % keys.size()]
	var st: Dictionary = STYLES[style]
	a["style"] = style
	a["skill"] = clampf(float(RANK_SKILL.get(rank, 0.5)) + float(st["skill"]), 0.1, 0.98)
	a["name"] = "%s — %s" % [String(a.get("name", "Boss")), st["title"]]
	if String(st["weapon"]) != "":
		if not a.has("look"):
			a["look"] = CharacterModel.default_look()
		a["look"]["weapon_r"] = st["weapon"]
	if style == "taijutsu":
		a["speed"] = float(a.get("speed", 8.5)) * 1.15
		a["jutsu"] = (a.get("jutsu", []) as Array).slice(0, 1)
	if style == "kenjutsu":
		a["kind_anim"] = "sword"


## Her fizik karesi (Enemy._physics_process): tarza özel saldırılar + aşama
static func tick(e: Enemy, dt: float) -> void:
	var st = String(e.arch.get("style", ""))
	if st == "" or e.dead:
		return
	var cd = float(e.get_meta("bs_cd", 3.0)) - dt
	e.set_meta("bs_cd", cd)
	if not e.get_meta("bs_phase2", false) and e.hp < e.max_hp * 0.5:
		_phase2(e, st)
	var t = e.target
	if cd > 0.0 or t == null or not is_instance_valid(t) or t.is_dead() or e.state in ["hitstun", "knockdown", "cast"]:
		return
	var d = e.global_position.distance_to(t.global_position)
	var p2 = e.get_meta("bs_phase2", false)
	match st:
		"kenjutsu":
			if d < 14.0:
				_dash_slash(e, t)
				e.set_meta("bs_cd", randf_range(4.0, 6.0) * (0.6 if p2 else 1.0))
		"kugutsu":
			if d < 35.0:
				_puppets(e, 2 if not p2 else 3)
				e.set_meta("bs_cd", 14.0 if not p2 else 10.0)
		"genjutsu":
			if d < 25.0:
				_illusion(e, t, p2)
				e.set_meta("bs_cd", randf_range(8.0, 11.0))
		"taijutsu":
			if d < 10.0:
				_rush(e, t, p2)
				e.set_meta("bs_cd", randf_range(3.5, 5.0) * (0.6 if p2 else 1.0))
		"fuin":
			if d < 22.0:
				_tag_trap(e, t, 4 if not p2 else 7)
				e.set_meta("bs_cd", randf_range(6.0, 8.0))
		"kuchiyose":   # dövüşün başında ve 2. aşamada dev çağrı (sözleşme hayvanı) getirir
			var n_sum = int(e.get_meta("bs_summons", 0))
			if d < 45.0 and n_sum < (1 if not p2 else 2):
				e.set_meta("bs_summons", n_sum + 1)
				Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Kuchiyose no Jutsu!", Color(0.85, 0.6, 1.0))
				e.model.play("cast_out", 0.05, 1.0, true)
				Contracts.summon(e, {"id": "kuchiyose"})
				e.set_meta("bs_cd", 6.0)
			elif d < 30.0:
				_tag_trap(e, t, 3)
				e.set_meta("bs_cd", randf_range(6.0, 9.0))
		"bakuton":
			if d < 30.0:
				_clay_birds(e, t, 3 if not p2 else 5)
				e.set_meta("bs_cd", randf_range(6.0, 8.0))


static func _phase2(e: Enemy, st: String) -> void:
	e.set_meta("bs_phase2", true)
	e.skill = minf(0.98, e.skill + 0.15)
	e.arch["aggr"] = float(e.arch.get("aggr", 0.6)) * 1.35
	var lines = {"kenjutsu": "Kılıcımın gerçek hızını gör!", "kugutsu": "Kuklalarımın hepsi uyandı!", "genjutsu": "Gördüğün hiçbir şey gerçek değil...",
		"taijutsu": "Kapılar... AÇILIN!", "kuchiyose": "Gel bakalım... hükümdarım!", "fuin": "Bu alan artık benim mührüm.", "bakuton": "Sanat bir patlamadır!"}
	Hud.banner(e.display_name, String(lines.get(st, "Ciddileşti!")), Color(1, 0.45, 0.35))
	if st == "taijutsu":
		e.arch["speed"] = float(e.arch["speed"]) * 1.45
		e.power *= 1.3
		FX.aura(e, Color(0.4, 1.0, 0.5), 1.4, Vector3(0, 0.9, 0), 0.0)
	else:
		FX.aura(e, Color(1.0, 0.4, 0.3), 1.0, Vector3(0, 0.9, 0), 3.0)


## Kılıç ustası: hedefe ani atılış + geniş yatay kesik (hilal iz)
static func _dash_slash(e: Enemy, t: Node3D) -> void:
	var v = t.global_position - e.global_position
	v.y = 0
	var dir = v.normalized()
	e.facing = atan2(-dir.x, -dir.z)
	FX.speed_lines(e.global_position + Vector3.UP, dir)
	var end = t.global_position - dir * 1.4
	end.y = Game.ground_height(end.x, end.z)
	e.global_position = end
	e.model.play("slash_c", 0.05, 1.5, true)
	FX.ring(end + Vector3.UP * 1.1 + dir, Color(0.9, 0.95, 1.0), 3.5, 0.25, false, dir)
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Iaigiri!", Color(0.85, 0.9, 1))
	Combat.hit_sphere(e, end + Vector3.UP * 1.1 + dir * 1.2, 2.0, {"dmg": 18.0 * e.power, "knock": 9.0, "launch": 3.0, "kind": "heavy", "dir": dir})
	Sfx.play("whoosh", end, 1.1)


## Kuklacı: savaş kuklaları çağırır (ClanConstruct), kendisi geride kalır
static func _puppets(e: Enemy, n: int) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Kugutsu no Jutsu!", Color(0.85, 0.7, 0.5))
	ClanConstruct.spawn(e, "puppet", n, {"tier": 3})
	e.state = "flee"
	e.state_t = 0.0


## Yanılsama: iki gölge klon (tek vuruşta dağılır) + hedefin kilidi kırılır, ekran kararır
static func _illusion(e: Enemy, t: Node3D, p2: bool) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Magen: Narakumi!", Color(0.8, 0.6, 1))
	if t == Game.player and Game.world:
		Game.world.env.flash_tint(Color(0.35, 0.2, 0.5, 0.45), 1.6)
		if Game.player.combat:
			Game.player.combat.lock_target = null
	for k in (2 if not p2 else 3):
		var c = Enemy.new()
		var a = e.arch.duplicate(true)
		a["hp"] = 1.0
		a["respawn"] = false
		a.erase("style")
		a["jutsu"] = []
		a["xp"] = 0
		a["ryo"] = 0
		c.setup(a)
		c.set_meta("respawn", false)
		e.get_parent().add_child(c)
		var ang = TAU * k / 3.0 + randf()
		var pp = t.global_position + Vector3(cos(ang), 0, sin(ang)) * 5.0
		pp.y = Game.ground_height(pp.x, pp.z)
		c.global_position = pp
		c.target = t
		c.state = "chase"
		FX.smoke_puff(pp + Vector3.UP, 0.9, 12)
		e.get_tree().create_timer(9.0).timeout.connect(func():
			if is_instance_valid(c) and not c.dead:
				FX.smoke_puff(c.global_position + Vector3.UP, 0.9, 12)
				c.queue_free())
	# kendisi yer değiştirir
	var bp = t.global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	bp.y = Game.ground_height(bp.x, bp.z)
	FX.smoke_puff(e.global_position + Vector3.UP, 1.0, 14)
	e.global_position = bp


## Taijutsu: ard arda üç atılış yumruk + yukarı fırlatan tekme
static func _rush(e: Enemy, t: Node3D, p2: bool) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Konoha Senpū!" if not p2 else "Asa Kujaku!", Color(1, 0.75, 0.4))
	for k in (3 if not p2 else 5):
		e.get_tree().create_timer(k * 0.18).timeout.connect(func():
			if not is_instance_valid(e) or e.dead or not is_instance_valid(t):
				return
			var dir = (t.global_position - e.global_position)
			dir.y = 0
			dir = dir.normalized()
			e.facing = atan2(-dir.x, -dir.z)
			e.global_position = t.global_position - dir * 1.3
			e.model.play(["jab", "cross", "hook"][k % 3], 0.03, 1.8, true)
			FX.hit_spark(t.global_position + Vector3.UP * 1.2, Color(1, 0.8, 0.5), 0.9)
			Combat.hit_sphere(e, t.global_position + Vector3.UP * 1.1, 1.3, {"dmg": 9.0 * e.power, "knock": 4.0 if k < 2 else 8.0, "launch": 0.0 if k < 2 else 7.0, "kind": "heavy" if k >= 2 else "light", "dir": dir}))


## Mühür ustası: hedefin etrafına patlayıcı etiketler, 1.2 sn sonra patlar (kaçmak gerek)
static func _tag_trap(e: Enemy, t: Node3D, n: int) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Kibaku Fuda: Kassei!", Color(1, 0.85, 0.5))
	var c0 = t.global_position
	for k in n:
		var ang = TAU * k / n
		var q = c0 + Vector3(cos(ang), 0, sin(ang)) * 3.0
		q.y = Game.ground_height(q.x, q.z)
		FX.ring(q + Vector3.UP * 0.1, Color(1, 0.6, 0.2), 1.6, 1.2)
		e.get_tree().create_timer(1.2).timeout.connect(func():
			if not is_instance_valid(e):
				return
			FX.impact(q + Vector3.UP * 0.5, Color(1, 0.55, 0.2), 1.4)
			Sfx.play("boom", q, 1.1, 0.6)
			Combat.hit_sphere(e, q + Vector3.UP * 0.6, 2.6, {"dmg": 14.0 * e.power, "knock": 10.0, "launch": 5.0, "kind": "heavy"}))


## Patlatıcı: hedefe süzülen kil kuşlar, çarpınca patlar
static func _clay_birds(e: Enemy, t: Node3D, n: int) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Nendo: C1!", Color(0.95, 0.9, 0.75))
	for k in n:
		var mi = MeshInstance3D.new()
		var mb = MB.new()
		mb.add("sphere", Vector3.ZERO, Vector3(0.4, 0.3, 0.6), Color(0.95, 0.93, 0.85), Vector3.ZERO, 8)
		for sx in [-1.0, 1.0]:
			mb.add("box", Vector3(0.35 * sx, 0.05, 0), Vector3(0.6, 0.04, 0.3), Color(0.95, 0.93, 0.85), Vector3(0, 0, 15 * sx))
		mi.mesh = mb.build(Props.toon())
		e.get_parent().add_child(mi)
		var from = e.global_position + Vector3(randf_range(-2, 2), 3.0 + randf() * 2.0, randf_range(-2, 2))
		mi.global_position = from
		var tw = mi.create_tween()
		var dur = 1.0 + k * 0.2
		tw.tween_method(func(u: float):
			if is_instance_valid(t):
				var aim = t.global_position + Vector3.UP
				mi.global_position = from.lerp(aim, u) + Vector3.UP * sin(u * PI) * 3.0
				if mi.global_position.distance_to(aim) > 0.05:
					mi.look_at(aim), 0.0, 1.0, dur)
		tw.tween_callback(func():
			var at = mi.global_position
			mi.queue_free()
			if is_instance_valid(e):
				FX.impact(at, Color(1, 0.7, 0.3), 1.6)
				Sfx.play("boom", at, 1.0, 0.6)
				Combat.hit_sphere(e, at, 3.0, {"dmg": 15.0 * e.power, "knock": 12.0, "launch": 6.0, "kind": "heavy"}))
