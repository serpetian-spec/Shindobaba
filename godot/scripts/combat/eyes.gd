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
var susanoo_node: Node3D
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


## Göz dokusunu güncelle (model yeniden kurulunca da çağrılır)
func refresh_visual() -> void:
	if p == null or p.model == null:
		return
	var r = _kind("sag"); var l = _kind("sol")
	var vr = r if (active or r in ALWAYS_VISIBLE) else 0
	var vl = l if (active or l in ALWAYS_VISIBLE) else 0
	p.model.set_dojutsu_eyes(vr, _lvl("sag"), vl, _lvl("sol"), active and (r == 2 or l == 2))


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
		Hud.msg("Bir göz tekniğin yok. (Göz ekipmanı: Tab > Ekipman > Sağ/Sol Göz)", Color(0.8, 0.8, 0.8))
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
	var cost: float = sk[1] * _transplant_mult()
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok.", Color(0.6, 0.7, 1))
		return
	p.chakra -= cost
	cd[side] = sk[2]
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
	t.apply_status("stun", stun)
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
	FX.aura(t, Color(0.06, 0.02, 0.08), 1.4, Vector3(0, 0.9, 0), 8.0)
	FX.burst(t.global_position + Vector3.UP, {"amount": 30, "life": 0.8, "tex": FX.tex_smoke, "add": false, "size": 1.2, "vmin": 1, "vmax": 4, "gravity": Vector3(0, 3, 0),
		"colors": [Color(0.05, 0.0, 0.08, 1), Color(0.2, 0.0, 0.25, 0)]})


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
	FX.burst(p.global_position + Vector3.UP, {"amount": 60, "life": 0.6, "tex": FX.tex_smoke, "add": true, "size": 1.0, "vmin": 6, "vmax": 10,
		"colors": [Color(0.8, 0.9, 1, 0.8), Color(0.6, 0.7, 1, 0)]})


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
	return _kind("sag") in [4, 5] and _kind("sol") in [4, 5]


func _start_susanoo() -> void:
	if not _can_susanoo() or susanoo:
		return
	if not active:
		toggle()
	susanoo = true
	Buffs.add("susanoo", 9999.0, {"armor": 0.3, "melee": 1.6, "reach": 1.8})
	susanoo_node = Node3D.new()
	p.add_child(susanoo_node)
	var mb = MB.new()
	var col = Color(0.55, 0.35, 0.95)
	for i in 6:  # kaburga kemikleri
		mb.add("torus", Vector3(0, 0.8 + i * 0.28, 0), Vector3(1.6 - i * 0.12, 1.0, 1.3 - i * 0.1), col, Vector3.ZERO, 14)
	mb.add("sphere", Vector3(0, 2.7, 0), Vector3(1.0, 1.1, 1.0), col, Vector3.ZERO, 10)
	for sx in [-1.0, 1.0]:
		mb.add("cyl", Vector3(1.3 * sx, 1.9, 0.3), Vector3(0.35, 1.6, 0.35), col, Vector3(60, 0, 30 * sx), 8)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(null)
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.35, 1.0, 0.35)
	m.emission_enabled = true
	m.emission = Color(0.5, 0.3, 1.0)
	m.emission_energy_multiplier = 0.8
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	susanoo_node.add_child(mi)
	susanoo_node.scale = Vector3.ONE * 0.2
	susanoo_node.create_tween().tween_property(susanoo_node, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK)
	Hud.msg("SUSANOO", Color(0.75, 0.55, 1.0))
	Sfx.play("roar", p.global_position, 1.6, 0.5)


func _end_susanoo() -> void:
	susanoo = false
	Buffs.remove("susanoo")
	if is_instance_valid(susanoo_node):
		susanoo_node.queue_free()


# ------------------------------------------------------------------ göz çalma / nakil
## Düşman göz sahibi yapar (Bingo Book hedefleri, kaçak klan ninjaları)
static func give_enemy_eyes(f: Node, kind: int, lvl := 3) -> void:
	f.set_meta("eyes", {"kind": kind, "lvl": lvl})
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
	Hud.banner("GÖZLER ALINDI", "%s x2 — Tab > Ekipman > Sağ/Sol Göz ile nakledebilirsin" % KINDS.get(int(e["kind"]), "Göz"), Color(0.9, 0.3, 0.3))
	Sfx.play("seal", p.global_position, 0.7)


# ------------------------------------------------------------------ Sharingan kopyalama
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
	if randf() < 0.2 * tl:
		Progress.learn(id)
		Hud.msg("SHARINGAN KOPYALADI: %s" % Data.jutsu[id].get("name", id), Color(1, 0.35, 0.35))


# ------------------------------------------------------------------ güncelleme
func _process(dt: float) -> void:
	if Game.paused or p == null:
		return
	for s in cd:
		cd[s] = maxf(0.0, cd[s] - dt)
	strain = maxf(0.0, strain - dt * 0.01)
	# V basılı tutma: Susanoo
	if v_held >= 0.0:
		v_held += dt
		if v_held > 0.45 and _can_susanoo() and not susanoo:
			_start_susanoo()
			v_held = -1.0
	if active:
		var drain = 2.0 * _transplant_mult() + (6.0 if susanoo else 0.0)
		if _kind("sag") == 5 or _kind("sol") == 5:
			drain *= 0.6
		p.chakra -= drain * dt
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
	for f in get_tree().get_nodes_in_group("fighters"):
		if f != p and f.has_meta("eyes") and not f.has_meta("eyes_taken") and f.is_dead() and f.global_position.distance_to(p.global_position) < 3.0:
			steal_target = f
			if not f.has_meta("eye_prompt"):
				f.set_meta("eye_prompt", true)
				Combat.popup_text(f.global_position + Vector3.UP * 1.5, "[F] Gözleri al", Color(1, 0.4, 0.4))
			break


## Kaçma şansı (Sharingan öngörüsü): PlayerModes.on_player_hit çağırır
func dodge_chance() -> float:
	if not active:
		return 0.0
	var best = 0.0
	for s in ["sag", "sol"]:
		var k = _kind(s)
		if k in [1, 4, 5]:
			best = maxf(best, 0.1 * _lvl(s) + (0.15 if k >= 4 else 0.0))
	return best


## Byakugan yakın dövüş (Jūken) bonusu
func melee_bonus() -> float:
	if active and (_kind("sag") == 2 or _kind("sol") == 2):
		return 1.25
	return 1.0
