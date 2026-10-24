class_name Eyes
extends Node
## Göz teknikleri (dōjutsu): sağ göz / sol göz ayrı ekipman.
## V: gözleri aç/kapa  •  Gözler açıkken Z: sağ göz tekniği, X: sol göz tekniği
## V basılı (iki göz de Mangekyō/Ebedi): Susanoo  •  Düşmüş göz sahibinin yanında F: gözü al

const KINDS := {1: "Sharingan", 2: "Byakugan", 3: "Ketsuryūgan", 4: "Mangekyō Sharingan", 5: "Ebedi Mangekyō", 6: "Rinnegan", 7: "Tenseigan", 8: "Jōgan"}
## Gözler kapalıyken de görünen gözler (doğuştan desen)
const ALWAYS_VISIBLE := [2, 6, 7]
## [ad, chakra, bekleme] — sağ / sol göz
const SKILLS := {
	1: [["Genjutsu: Sharingan", 15.0, 12.0], ["Genjutsu: Sharingan", 15.0, 12.0]],
	2: [["Hakke Kūshō", 14.0, 6.0], ["Hakkeshō Kaiten", 22.0, 10.0]],
	3: [["Kan Genjutsu", 18.0, 12.0], ["Kanashibari", 20.0, 14.0]],
	4: [["Amaterasu", 40.0, 20.0], ["Tsukuyomi", 45.0, 24.0]],
	5: [["Amaterasu", 30.0, 14.0], ["Tsukuyomi", 32.0, 16.0]],
	6: [["Shinra Tensei", 35.0, 14.0], ["Banshō Ten'in", 25.0, 10.0]],
	7: [["Gudōdama", 30.0, 10.0], ["Çekim Darbesi", 25.0, 12.0]],
	8: [["Jōgan Nüfuzu", 20.0, 12.0], ["Boyut Görüşü", 10.0, 8.0]],
}

var p: Player
var c: PlayerCombat
var active = false
var cd := {"sag": 0.0, "sol": 0.0}
var strain = 0.0          # Mangekyō yorgunluğu (görüş bulanır)
var susanoo = false
var susanoo_node: Susanoo
var v_held = -1.0
var markers := {}
var marker_t = 0.0
var steal_target: Node3D = null


func setup(combat: PlayerCombat) -> void:
	c = combat
	p = combat.p
	var j = get_node_or_null("/root/Jutsu")
	if j and j.has_signal("jutsu_cast"):
		j.jutsu_cast.connect(_on_jutsu_cast)
	refresh_visual()


func eye(side: String):
	return Game.profile.get("look", {}).get("eye_r" if side == "sag" else "eye_l")


func has_eyes() -> bool:
	return eye("sag") != null or eye("sol") != null


func _kind(side: String) -> int:
	var e = eye(side)
	return int(e["kind"]) if e != null else 0


func _lvl(side: String) -> int:
	var g = Gear.equipped(Game.profile, "sag_goz" if side == "sag" else "sol_goz")
	if not g.is_empty():
		return int(g.get("lvl", 3))
	var e = eye(side)
	return int(e.get("lvl", 3)) if e != null else 0


func _transplant_mult() -> float:
	# nakil göz (soydan değil) çok daha fazla chakra yer
	var m = 1.0
	for s in ["sag", "sol"]:
		var e = eye(s)
		if e != null and e.get("origin", "dogustan") == "nakil":
			m += 0.75
	return m


## Mangekyō deseni: her göz için benzersiz (oyuncu düzenleyebilir)
## style 0 çark, 1 yıldız, 2 taç yaprak, 3 shuriken, 4 sarmal, 5 haç, 6 tomoe halkası, 7..17 (bkz. Menus.MS_STYLES)
static func random_design() -> Dictionary:
	return {"style": randi() % 18, "blades": randi_range(3, 6), "curve": randf_range(-2.5, 2.5), "thick": randf_range(0.35, 0.75),
		"inner": randf_range(0.14, 0.3), "ring": randf() < 0.4, "invert": randf() < 0.12, "spin": randf_range(0.2, 1.0),
		"col": [0.9, 0.05, 0.06]}


static func design_vecs(d: Dictionary) -> Array:
	var c: Array = d.get("col", [0.9, 0.05, 0.06])
	return [Vector4(d.get("style", 0), d.get("blades", 3), d.get("curve", 1.5), d.get("thick", 0.5)),
		Vector4(d.get("inner", 0.22), 1.0 if d.get("ring", false) else 0.0, 1.0 if d.get("invert", false) else 0.0, d.get("spin", 0.6)),
		Color(c[0], c[1], c[2])]


## Takılı Mangekyō/EMS gözünün desen sözlüğü (yoksa üretip kaydeder)
static func design_for(pr: Dictionary, slot: String) -> Dictionary:
	var g = Gear.equipped(pr, slot)
	if g.is_empty():
		return {}
	var kind = int(Gear.item(g["id"]).get("eye", {}).get("kind", 0))
	if not kind in [4, 5]:
		return {}
	if not g.has("design"):
		g["design"] = random_design()
		if kind == 5:  # ebedi: iki deseni birleştiren daha karmaşık stil
			g["design"]["ring"] = true
			g["design"]["blades"] = int(g["design"]["blades"]) + 1
	return g["design"]


## Göz dokusunu güncelle (model yeniden kurulunca da çağrılır)
func refresh_visual() -> void:
	if p == null or p.model == null:
		return
	var r = _kind("sag"); var l = _kind("sol")
	var vr = r if (active or r in ALWAYS_VISIBLE) else 0
	var vl = l if (active or l in ALWAYS_VISIBLE) else 0
	p.model.set_dojutsu_eyes(vr, _lvl("sag"), vl, _lvl("sol"), active and (r == 2 or l == 2))
	p.model.set_ms_designs(design_for(Game.profile, "sag_goz"), design_for(Game.profile, "sol_goz"))


# ------------------------------------------------------------------ girdi (PlayerModes'tan)
func handle_input(e: InputEvent) -> bool:
	if e.is_action_pressed("dojutsu"):
		v_held = 0.0
		return true
	if e.is_action_released("dojutsu") and v_held >= 0.0:
		var held = v_held
		v_held = -1.0
		if held < 0.45:
			toggle()
		return true
	if susanoo and is_instance_valid(susanoo_node):
		if e.is_action_pressed("attack"):
			susanoo_node.swipe(p, p.cam_forward() if p.wish_dir().length() < 0.1 else p.wish_dir().normalized())
			return true
		if e.is_action_pressed("guard"):
			susanoo_node.special(p, p.cam_forward())
			return true
	if active:
		if e.is_action_pressed("sage"):
			use_skill("sag")
			return true
		if e.is_action_pressed("beast"):
			use_skill("sol")
			return true
	if e.is_action_pressed("interact") and steal_target != null:
		_steal(steal_target)
		return true
	return false


func toggle() -> void:
	if not has_eyes():
		Hud.msg("Bir göz tekniğin yok. (Gözler: Tab > Gözler)", Color(0.8, 0.8, 0.8))
		return
	if susanoo:
		_end_susanoo()
	active = not active
	if active:
		Sfx.play("genjutsu", p.global_position, 1.5, 0.6)
		var r = _kind("sag"); var l = _kind("sol")
		var main_kind = maxi(r, l)
		var names = []
		for k in [r, l]:
			if k > 0 and not KINDS[k] in names:
				names.append(KINDS[k])
		Hud.msg("%s AÇILDI  —  Z: %s   X: %s   %s" % [" / ".join(names).to_upper(), _skill_name("sag"), _skill_name("sol"), "(V basılı: Susanoo)" if _can_susanoo() else ""], Color(1, 0.45, 0.45) if main_kind != 2 else Color(0.85, 0.9, 1))
		FX.ring(p.global_position + Vector3.UP * 1.5, Color(1, 0.2, 0.2) if main_kind != 2 else Color(0.8, 0.85, 1), 2.5, 0.35, false, -p.face_dir())
		if Game.world:
			Game.world.env.set_tint(Color(0.9, 0.1, 0.1, 0.07) if main_kind != 2 else Color(0.6, 0.7, 1.0, 0.08))
		if r in [1, 4, 5] or l in [1, 4, 5]:
			var tl = maxi(_lvl("sag"), _lvl("sol"))
			Combat.base_time_scale = 0.9 - 0.04 * tl
	else:
		_close()
	refresh_visual()


func _close() -> void:
	active = false
	Combat.base_time_scale = 1.0
	if Game.world:
		Game.world.env.set_tint(Color(0, 0, 0, 0))
	for k in markers.keys():
		if is_instance_valid(markers[k]):
			markers[k].queue_free()
	markers.clear()
	if susanoo:
		_end_susanoo()


func _skill_name(side: String) -> String:
	var k = _kind(side)
	return SKILLS[k][0 if side == "sag" else 1][0] if k > 0 else "—"


# ------------------------------------------------------------------ teknikler
func use_skill(side: String) -> void:
	var k = _kind(side)
	if k == 0:
		Hud.msg("%s gözünde dōjutsu yok." % ("Sağ" if side == "sag" else "Sol"), Color(0.8, 0.8, 0.8))
		return
	if cd[side] > 0.0:
		Hud.msg("%s hazır değil (%.0f sn)" % [_skill_name(side), cd[side]], Color(0.9, 0.8, 0.6))
		return
	var sk: Array = SKILLS[k][0 if side == "sag" else 1]
	var cost: float = sk[1] * _transplant_mult() * maxf(0.3, 1.0 + Stats.skill(Game.profile, "eye_cost"))
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok.", Color(0.6, 0.7, 1))
		return
	p.chakra -= cost
	cd[side] = sk[2] * maxf(0.3, 1.0 + Stats.skill(Game.profile, "eye_cd"))
	Combat.popup_text(p.global_position + Vector3.UP * 2.4, sk[0], Color(1, 0.5, 0.5) if k != 2 else Color(0.85, 0.9, 1))
	var t = Combat.nearest_enemy(p, 30.0, p.face_dir(), 0.3)
	if t == null:
		t = Combat.nearest_enemy(p, 30.0)
	var right = side == "sag"
	match k:
		1:
			_genjutsu_gaze(t, 1.5 + 0.5 * _lvl(side), 0.0)
		2:
			if right:
				_air_palm()
			else:
				_kaiten()
		3:
			if right:
				for f in _enemies_in(12.0):
					f.apply_status("slow", 4.0)
					f.apply_status("stun", 1.5)
				FX.ring(p.global_position + Vector3.UP * 0.2, Color(0.8, 0.05, 0.1), 12.0, 0.6)
			else:
				if t:
					t.apply_status("bind", 3.0)
					FX.ring(t.global_position + Vector3.UP, Color(0.8, 0.05, 0.1), 2.0, 0.5, false)
		4, 5:
			if right:
				_amaterasu(t, k == 5)
			else:
				_genjutsu_gaze(t, 4.0, 40.0 if k == 4 else 55.0)
			if k == 4:
				strain = minf(1.0, strain + 0.18)
				if strain > 0.6:
					Hud.msg("Gözlerin kanıyor, görüşün bulanıklaşıyor...", Color(1, 0.4, 0.4))
		6:
			if right:
				_push(15.0, 22.0)
			elif t:
				var d = (p.global_position - t.global_position)
				t.velocity = d.normalized() * minf(30.0, d.length() * 2.2) + Vector3.UP * 4.0
				t.apply_status("stun", 1.2)
				FX.ring(t.global_position + Vector3.UP, Color(0.7, 0.6, 1), 2.5, 0.4, false)
		7:
			if right:
				_truth_orb(t)
			else:
				_push(10.0, -18.0)
		8:
			if right:
				_genjutsu_gaze(t, 2.5, 15.0)
			else:
				_dimension_sight()
	Sfx.play("genjutsu", p.global_position, 0.8, 0.7)


func _enemies_in(r: float) -> Array:
	var out = []
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(p, f) and not f.is_dead() and f.global_position.distance_to(p.global_position) < r:
			out.append(f)
	return out


func _genjutsu_gaze(t: Node3D, stun: float, dmg: float) -> void:
	if t == null:
		Hud.msg("Göz göze gelecek hedef yok.", Color(0.8, 0.8, 0.8))
		return
	var gm = 1.0 + Stats.skill(Game.profile, "gen_power")
	t.apply_status("stun", stun * gm)
	dmg *= gm
	if dmg > 0.0:
		t.take_hit({"dmg": dmg, "knock": 0.0, "kind": "light", "dir": p.face_dir(), "element": ""})
	FX.ring(t.global_position + Vector3.UP * 1.6, Color(0.9, 0.05, 0.05), 1.6, 0.6, false, (p.global_position - t.global_position).normalized())
	Combat.popup_text(t.global_position + Vector3.UP * 2.2, "Genjutsu!", Color(1, 0.3, 0.3))


func _amaterasu(t: Node3D, eternal: bool) -> void:
	if t == null:
		return
	# söndürülemeyen kara alev: uzun yanma
	t.apply_status("burn", 10.0 if eternal else 8.0)
	t.set_meta("black_flame", true)
	t.take_hit({"dmg": 25.0, "knock": 0.0, "kind": "light", "dir": p.face_dir(), "element": "katon"})
	# hedefi saran kara cel alev (mor konturlu), süre bitince söner
	var flame = VFX.black_flames(maxf(1.2, t.height * 0.75) if "height" in t else 1.3)
	t.add_child(flame)
	flame.position = Vector3(0, 0.1, 0)
	VFX.black_smolder(t.global_position, 1.8, 8.0)
	t.get_tree().create_timer(10.0 if eternal else 8.0).timeout.connect(func(): if is_instance_valid(flame): flame.queue_free())
	VFX.puffs(t.global_position + Vector3.UP, {"amount": 30, "life": 0.8, "size": 1.4, "vmin": 1, "vmax": 4, "gravity": Vector3(0, 3, 0), "glow": 1.0,
		"outline_col": Color(0.4, 0.05, 0.45), "colors": [Color(0.12, 0.02, 0.15, 1), Color(0.05, 0.0, 0.08, 1), Color(0.02, 0.0, 0.03, 0)]})
	if Game.world:
		Game.world.env.set_tint(Color(0.6, 0.0, 0.05, 0.25))
		t.get_tree().create_timer(0.35).timeout.connect(func(): Game.world.env.set_tint(Color(0, 0, 0, 0)))


func _air_palm() -> void:
	var dir = p.face_dir()
	for i in 6:
		var pt = p.global_position + Vector3.UP * 1.1 + dir * (1.5 + i * 1.6)
		Combat.hit_sphere(p, pt, 1.3, {"dmg": 18.0 * Stats.melee_mult(Game.profile), "knock": 14.0, "kind": "heavy", "dir": dir})
	FX.ring(p.global_position + Vector3.UP * 1.1 + dir * 2.0, Color(0.85, 0.9, 1), 2.5, 0.3, false, dir)
	FX.speed_lines(p.global_position + Vector3.UP, dir)
	Sfx.play("wind", p.global_position, 1.3)


func _kaiten() -> void:
	c.invuln = 1.4
	_push(5.0, 16.0)
	p.model.play("roll", 0.05, 0.6, true)
	# dönen chakra kubbesi (Kaiten): spiral kabuk + yer şok dalgası + toz
	var dome = VFX._mi(VFX._sphere(0.5, 28, 14), VFX.mat_spiral(Color(1, 1, 1), Color(0.55, 0.75, 1.0), 6.0, 3.0, 14.0, 1.6, Vector3.UP))
	p.add_child(dome)
	dome.position = Vector3(0, 0.6, 0)
	dome.scale = Vector3.ONE * 0.5
	var tw = dome.create_tween()
	tw.tween_property(dome, "scale", Vector3(7.0, 5.5, 7.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dome, "rotation:y", TAU * 3.0, 1.2)
	tw.tween_property(dome, "scale", Vector3.ONE * 0.1, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(dome.queue_free)
	VFX.shockwave(p.global_position + Vector3.UP * 0.1, Color(0.7, 0.85, 1.0), 12.0, 0.5)
	FX.dust(p.global_position, 1.4)


func _push(r: float, force: float) -> void:
	for f in _enemies_in(r):
		var d = (f.global_position - p.global_position)
		d.y = 0
		f.take_hit({"dmg": 20.0, "knock": force, "launch": absf(force) * 0.3, "kind": "heavy", "dir": d.normalized() * signf(force), "element": ""})
	FX.ring(p.global_position + Vector3.UP * 0.5, Color(0.75, 0.65, 1.0), r, 0.5)
	Sfx.play("boom", p.global_position, 0.7)


func _truth_orb(t: Node3D) -> void:
	var dir = p.face_dir() if t == null else (t.global_position - p.global_position).normalized()
	var at = p.global_position + Vector3.UP * 1.2 + dir * 3.0
	Combat.hit_sphere(p, at + dir * 4.0, 3.5, {"dmg": 35.0, "knock": 18.0, "kind": "heavy", "dir": dir, "element": ""})
	FX.impact(at + dir * 4.0, Color(0.1, 0.1, 0.12), 1.4)


func _dimension_sight() -> void:
	# yakındaki tüm düşmanları ve etkileşim noktalarını 10 sn işaretle
	for f in _enemies_in(120.0):
		_mark(f, Color(0.95, 0.9, 0.5))
	get_tree().create_timer(10.0).timeout.connect(func():
		if not active:
			return
		for k in markers.keys():
			if is_instance_valid(markers[k]):
				markers[k].queue_free()
		markers.clear())


func _mark(f: Node3D, col: Color) -> void:
	if markers.has(f.get_instance_id()):
		return
	var l = Label3D.new()
	l.text = "◆"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.002
	l.font_size = 48
	l.modulate = col
	l.outline_size = 8
	f.add_child(l)
	l.position = Vector3(0, f.height * 0.6, 0)
	markers[f.get_instance_id()] = l


# ------------------------------------------------------------------ Susanoo
func _can_susanoo() -> bool:
	return Susanoo.max_tier(Game.profile) > 0


func _start_susanoo() -> void:
	if not _can_susanoo() or susanoo:
		return
	if not active:
		toggle()
	susanoo = true
	var sn = Susanoo.new()
	sn.name = "Susanoo"
	p.add_child(sn)
	sn.build(Game.profile, -1, p.model)
	susanoo_node = sn
	var armor = [1.0, 0.4, 0.3, 0.22, 0.15, 0.08][sn.tier]
	Buffs.add("susanoo", 9999.0, {"armor": armor})
	var final_scale = sn.scale
	sn.scale = final_scale * 0.1
	sn.create_tween().tween_property(sn, "scale", final_scale, 0.6).set_trans(Tween.TRANS_BACK)
	Hud.banner("SUSANOO", "Kademe %d — %s   (sol tık: dev savuruş, sağ tık: silah)" % [sn.tier, Susanoo.TIER_NAMES[sn.tier]], Color(sn.mat.get_shader_parameter("col")))
	Sfx.play("roar", p.global_position, 1.6, 0.6)
	var h = Susanoo.TIER_HEIGHT[sn.tier]
	if sn.tier >= 2:
		# kamera Susanoo boyuna göre; kullanıcı Susanoo'nun içinde (göğüs / alın) süzülür
		p.set_meta("susanoo_cam", [p.cam_dist, p.cam_lift])
		p.cam_range = Vector2(maxf(3.0, h * 0.7), maxf(14.0, h * 3.0))
		p.cam_dist = h * 1.5 + 3.0
		p.cam_lift = h * (0.55 if sn.tier >= 3 else 0.3)
		p.cam_giant = sn.tier >= 3
		p.model_lift = h * Susanoo.USER_SEAT[sn.tier] if sn.tier >= 4 else 0.0   # İnsansı: kullanıcı yerde durur (uçmaz)
	# kanatlı tam Susanoo: havadayken Space ile uçuşa geç
	if sn.tier >= 5 and Susanoo.config(Game.profile).get("wings", true) and p.has_method("start_flight"):
		p.set_meta("wing_flight", {"speed": 24.0, "lift": 13.0, "drain": 1.2, "name": "Susanoo kanatları", "land_stop": true})
		Hud.msg("Kanatlar: havadayken Space ile uç", Color(0.8, 0.9, 1.0))


func _end_susanoo() -> void:
	susanoo = false
	p.model_lift = 0.0
	if p.has_meta("susanoo_cam"):
		var sc: Array = p.get_meta("susanoo_cam")
		p.cam_dist = float(sc[0])
		p.cam_lift = float(sc[1])
		p.remove_meta("susanoo_cam")
		p.cam_range = Vector2(2.2, 14.0)
		p.cam_giant = false
	if p.has_meta("wing_flight"):
		p.remove_meta("wing_flight")
	if p.has_method("flight_source") and p.flight_source() == "susanoo":
		p.stop_flight()
	Buffs.remove("susanoo")
	if is_instance_valid(susanoo_node):
		var sn = susanoo_node
		var tw = sn.create_tween()
		tw.tween_property(sn, "scale", sn.scale * 0.05, 0.35)
		tw.tween_callback(sn.queue_free)


# ------------------------------------------------------------------ göz çalma / nakil
## Düşman göz sahibi yapar (Bingo Book hedefleri, kaçak klan ninjaları)
static func give_enemy_eyes(f: Node, kind: int, lvl := 3) -> void:
	f.set_meta("eyes", {"kind": kind, "lvl": lvl})
	f.add_to_group("dojutsu_bearers")   # öldükten sonra "fighters"tan çıkar; göz çalma bu grubu tarar
	if f.get("model") and f.model and f.model.has_method("set_dojutsu_eyes"):
		f.model.set_dojutsu_eyes(kind, lvl, kind, lvl, kind == 2)


func _steal(f: Node3D) -> void:
	var e: Dictionary = f.get_meta("eyes")
	f.set_meta("eyes_taken", true)
	steal_target = null
	var id = {1: "goz_sharingan", 2: "goz_byakugan", 3: "goz_ketsuryugan", 4: "goz_mangekyo", 5: "goz_ems", 6: "goz_rinnegan", 7: "goz_tenseigan", 8: "goz_jogan"}.get(int(e["kind"]), "goz_sharingan")
	for i in 2:
		Gear.grant(Game.profile, id, "", null, null, {"lvl": int(e.get("lvl", 3)), "origin": "nakil"})
	Game.profile["flags"]["goz_hirsizi"] = int(Game.profile["flags"].get("goz_hirsizi", 0)) + 1
	Hud.banner("GÖZLER ALINDI", "%s x2 kavanoza kondu — Tab > Gözler > Saklanan Gözler; nakil hastanede" % KINDS.get(int(e["kind"]), "Göz"), Color(0.9, 0.3, 0.3))
	Sfx.play("seal", p.global_position, 0.7)


# ------------------------------------------------------------------ Sharingan kopyalama
var _copy_warned := {}   # kopyalanamayan teknik uyarısı jutsu başına bir kez
func _on_jutsu_cast(caster: Node, id: String) -> void:
	if not active or caster == p or not is_instance_valid(caster):
		return
	var tl = 0
	for s in ["sag", "sol"]:
		if _kind(s) in [1, 4, 5]:
			tl = maxi(tl, _lvl(s) + (2 if _kind(s) >= 4 else 0))
	if tl == 0 or caster.global_position.distance_to(p.global_position) > 35.0:
		return
	if id in Game.profile.get("learned", []) or not Data.jutsu.has(id):
		return
	# Sharingan yalnızca senin de yapabileceğin teknikleri kopyalar: seviye/rütbe sınırını aşar ama
	# sahip olmadığın element, başka klanın hiden tekniği, kekkei genkai, göz/sennin gerektiren ve yasak/özel teknikler kopyalanamaz
	var why = Progress.can_learn(id)
	if why != "" and not why.begins_with("Seviye") and not why.ends_with("rütbesi gerekli"):
		if not _copy_warned.has(id):
			_copy_warned[id] = true
			Hud.msg("Sharingan gördü ama kopyalayamaz: %s (%s)" % [Data.jutsu[id].get("name", id), why], Color(0.75, 0.55, 0.55))
		return
	if randf() < 0.2 * tl:
		Progress.learn(id)
		Hud.msg("SHARINGAN KOPYALADI: %s" % Data.jutsu[id].get("name", id), Color(1, 0.35, 0.35))


# ------------------------------------------------------------------ güncelleme
func _process(dt: float) -> void:
	if Game.paused or p == null:
		return
	check_awaken(dt)
	for s in cd:
		cd[s] = maxf(0.0, cd[s] - dt)
	strain = maxf(0.0, strain - dt * 0.01)
	# V basılı tutma: Susanoo
	if v_held >= 0.0:
		v_held += dt
		if v_held > 0.45 and _can_susanoo() and not susanoo:
			_start_susanoo()
			v_held = -1.0
	if susanoo and is_instance_valid(susanoo_node):
		susanoo_node.rotation.y = p.facing
		susanoo_node.follow = p.model
		var cfg = Susanoo.config(Game.profile)
		var before = Susanoo.max_tier(Game.profile)
		cfg["mastery"] = float(cfg.get("mastery", 0.0)) + dt
		if Susanoo.max_tier(Game.profile) > before:
			Hud.banner("SUSANOO USTALIĞI", "Yeni kademe açıldı: %s" % Susanoo.TIER_NAMES[Susanoo.max_tier(Game.profile)], Color(0.8, 0.6, 1.0))
	if active:
		var drain = 2.0 * _transplant_mult() + ((4.0 + 2.0 * susanoo_node.tier) if susanoo and is_instance_valid(susanoo_node) else 0.0)
		if _kind("sag") == 5 or _kind("sol") == 5:
			drain *= 0.6
		p.chakra -= drain * maxf(0.3, 1.0 + Stats.skill(Game.profile, "eye_cost")) * dt
		if p.chakra <= 0.0:
			p.chakra = 0.0
			Hud.msg("Chakra bitti, gözlerin kapandı.", Color(0.8, 0.8, 1))
			_close()
			refresh_visual()
		if _kind("sag") == 2 or _kind("sol") == 2:
			marker_t -= dt
			if marker_t <= 0.0:
				marker_t = 0.5
				for f in _enemies_in(90.0):
					_mark(f, Color(0.75, 0.85, 1.0, 0.9))
	# göz çalma: yakında gözleri alınmamış düşmüş dōjutsu sahibi
	steal_target = null
	for f in get_tree().get_nodes_in_group("dojutsu_bearers"):
		if f != p and f.has_meta("eyes") and not f.has_meta("eyes_taken") and f.is_dead() and f.global_position.distance_to(p.global_position) < 4.5:
			steal_target = f
			if not f.has_meta("eye_prompt"):
				f.set_meta("eye_prompt", true)
				Combat.popup_text(f.global_position + Vector3.UP * 1.5, "[F] Gözleri al", Color(1, 0.4, 0.4))
			break


# ------------------------------------------------------------------ uyanış ve gelişim (gözler eşya değil)
var _awaken_cd = 0.0
## Uyuyan klan gözü: hayatın tehlikedeyken (can < %20) yakında düşman varken uyanır
func check_awaken(dt: float) -> void:
	_awaken_cd -= dt
	var pr = Game.profile
	var dormant = String(pr.get("flags", {}).get("dormant_eye", ""))
	if dormant != "" and _awaken_cd <= 0.0 and p.hp < p.max_hp * 0.2 and not _enemies_in(20.0).is_empty():
		_awaken_cd = 5.0
		if randf() < 0.5:
			pr["flags"].erase("dormant_eye")
			Gear.grant(pr, dormant, "sag_goz", null, null, {"lvl": 1, "origin": "dogustan", "xp": 0.0})
			Gear.grant(pr, dormant, "sol_goz", null, null, {"lvl": 1, "origin": "dogustan", "xp": 0.0})
			Gear.apply_look(pr)
			p.rebuild_model()
			Hud.banner("SHARINGAN UYANDI", "Ölümün eşiğinde gözlerin açıldı", Color(1, 0.2, 0.2))
			Sfx.play("genjutsu", p.global_position, 1.3)
			if not active:
				toggle.call_deferred()
	# tomoe ilerlemesi: gözler açıkken dövüş
	if active and not _enemies_in(25.0).is_empty():
		for slot in ["sag_goz", "sol_goz"]:
			var g = Gear.equipped(pr, slot)
			if g.is_empty() or g["id"] != "goz_sharingan" or int(g.get("lvl", 1)) >= 3:
				continue
			g["xp"] = float(g.get("xp", 0.0)) + dt
			if g["xp"] >= 120.0 * int(g.get("lvl", 1)):
				g["xp"] = 0.0
				g["lvl"] = int(g.get("lvl", 1)) + 1
				Hud.banner("SHARINGAN GELİŞTİ", "%d tomoe" % int(g["lvl"]), Color(1, 0.3, 0.3))
				Gear.apply_look(pr)  # görünüm sözlüğü (eye_r/eye_l lvl) güncellensin, yoksa göz eski tomoe'da kalır
				refresh_visual()


## Mangekyō uyanışı: 3 tomoe iken yakın bir müttefik (eskort, rehine, takım arkadaşı) gözlerinin önünde ölürse
func on_ally_died(ally: Node3D) -> void:
	if not is_instance_valid(ally) or ally.global_position.distance_to(p.global_position) > 40.0:
		return
	var pr = Game.profile
	var ok = false
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(pr, slot)
		if not g.is_empty() and g["id"] == "goz_sharingan" and int(g.get("lvl", 1)) >= 3:
			g["id"] = "goz_mangekyo"
			g.erase("design")
			ok = true
	if ok:
		Gear.apply_look(pr)
		p.rebuild_model()
		Hud.banner("MANGEKYŌ SHARINGAN", "Acı, gözlerini sonsuza dek değiştirdi", Color(0.8, 0.05, 0.1))
		Sfx.play("roar", p.global_position, 0.7, 0.5)


## Hastanede nakil: saklanan bir gözü seçilen yuvaya takar (eski göz kavanoza)
static func transplant(pr: Dictionary, uid: int, slot: String) -> void:
	var g = Gear.find(pr, uid)
	if g.is_empty():
		return
	# Mangekyō sahibine başka bir Mangekyō nakli = Ebedi Mangekyō
	var cur = Gear.equipped(pr, slot)
	if not cur.is_empty() and cur["id"] == "goz_mangekyo" and g["id"] == "goz_mangekyo":
		g["id"] = "goz_ems"
		g["origin"] = "dogustan"
		g.erase("design")
		Hud.banner("EBEDİ MANGEKYŌ", "Gözlerin artık hiç kararmayacak", Color(0.9, 0.2, 0.3))
	pr["equip"][slot] = uid
	Buffs.add("nakil", 120.0, {"speed": 0.85, "melee": 0.85})
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()


## Kaçma şansı (Sharingan öngörüsü): PlayerModes.on_player_hit çağırır
func dodge_chance() -> float:
	if not active:
		return 0.0
	var best = 0.0
	for s in ["sag", "sol"]:
		var k = _kind(s)
		if k in [1, 4, 5]:
			best = maxf(best, 0.1 * _lvl(s) + (0.15 if k >= 4 else 0.0) + Stats.skill(Game.profile, "eye_dodge"))
	return best


## Byakugan yakın dövüş (Jūken) bonusu
func melee_bonus() -> float:
	if active and (_kind("sag") == 2 or _kind("sol") == 2):
		return 1.25
	return 1.0
