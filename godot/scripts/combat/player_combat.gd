class_name PlayerCombat
extends Node
## Oyuncunun Storm tarzı dövüşü.
## Sol tık: kombo | Sağ tık (basılı): blok | Q: Kawarimi | C (basılı): chakra şarjı | R: kunai
## E/orta tık: hedefe kilitlen | Kilitliyken Shift: chakra dash | 1-6: jutsu slotları

const COMBO := [
	{"anim": "jab", "speed": 1.5, "hit": 0.10, "dur": 0.32, "dmg": 3.6, "reach": 1.3, "lunge": 4.0, "knock": 2.0},
	{"anim": "cross", "speed": 1.5, "hit": 0.12, "dur": 0.34, "dmg": 4.2, "reach": 1.3, "lunge": 4.0, "knock": 2.0},
	{"anim": "hook", "speed": 1.6, "hit": 0.16, "dur": 0.4, "dmg": 4.8, "reach": 1.4, "lunge": 4.5, "knock": 3.0},
	{"anim": "idle", "kick": true, "speed": 1.0, "hit": 0.14, "dur": 0.38, "dmg": 5.4, "reach": 1.7, "lunge": 5.0, "knock": 4.0},
	{"anim": "slash_c", "speed": 1.4, "hit": 0.22, "dur": 0.6, "dmg": 9.0, "reach": 1.8, "lunge": 6.0, "knock": 16.0, "launch": 5.0, "heavy": true},
]

var p: Player
var step = -1
var t = 0.0          # mevcut hareketin geçen süresi
var action = ""      # "", attack, cast, throw, sub, hitstun, knockdown, guard, charge, chakra_dash
var did_hit = false
var buffered = false
var combo_reset = 0.0
var lock_target: Node3D = null
var guard_t = 0.0
var sub_bars = 4.0
var invuln = 0.0
var stun_meter := 0.0
var stun_last_ms := 0
var last_hit_t = 99.0
var aura: GPUParticles3D
var cast_jutsu = ""
var cast_time = 0.0
var cooldowns = {}
var jutsu_gcd = 0.0
var fan_cd = 0.0         # yelpaze rüzgâr dalgası      # her jutsudan sonra ortak bekleme (rütbeye göre): üst üste jutsu yağdırılmasın
var strain = 0           # chakra yorgunluğu: art arda jutsularda maliyet artar
var strain_t = 0.0
var _gcd_msg_t = 0.0
var dash_target: Node3D = null
var air_attack = false
var modes: PlayerModes
var cast_anim: CastAnim


func _ready() -> void:
	p = get_parent()
	p.combat = self
	modes = PlayerModes.new()
	add_child(modes)
	modes.setup(self)


func busy() -> bool:
	return action != "" and action != "guard"


func _unhandled_input(e: InputEvent) -> void:
	if Game.paused or Game.ui_open:
		return
	if modes and modes.handle_input(e):
		return
	if e.is_action_pressed("attack"):
		attack()
	elif e.is_action_pressed("substitute"):
		# havada Q: ipli kunai (tutunacak yer yoksa normal kawarimi)
		if not p.rope_kunai():
			substitute()
	elif e.is_action_pressed("throw"):
		throw_tool()
	elif e.is_action_pressed("weapon_draw"):
		toggle_weapon()
	elif e.is_action_pressed("lock"):
		toggle_lock()
	elif e.is_action_pressed("dash") and lock_target and p.grounded and action == "":
		chakra_dash()
	for i in 6:
		if e.is_action_pressed("slot%d" % (i + 1)):
			var slots: Array = Game.profile.get("slots", [])
			if i < slots.size() and slots[i] != null and slots[i] != "":
				begin_cast(slots[i])


# ------------------------------------------------------------------ kilitlenme
func toggle_lock() -> void:
	if lock_target:
		lock_target = null
		return
	lock_target = Combat.nearest_enemy(p, 35.0, p.cam_forward(), 0.3)
	if lock_target == null:
		lock_target = Combat.nearest_enemy(p, 20.0)


func _auto_target(range_ := 7.0) -> Node3D:
	if lock_target and is_instance_valid(lock_target) and not lock_target.is_dead():
		if lock_target.global_position.distance_to(p.global_position) < range_ * 2.0:
			return lock_target
	var d = p.wish_dir()
	if d.length() < 0.1:
		d = p.cam_forward()
	return Combat.nearest_enemy(p, range_, d, 0.2)


func _cast_target() -> Node3D:
	if lock_target and is_instance_valid(lock_target) and not lock_target.is_dead():
		return lock_target
	return Jutsu.soft_target(p)


func face_to(target: Node3D) -> void:
	var v = target.global_position - p.global_position
	p.facing = atan2(-v.x, -v.z)


# ------------------------------------------------------------------ silah kını
## Silahı çek / kınına sok [N]; durum kayıtta tutulur (model yeniden kurulsa da korunur)
func toggle_weapon() -> void:
	if p.model == null or not p.model.has_weapon() or busy():
		return
	var on = not bool(Game.profile.get("weapon_drawn", false))
	Game.profile["weapon_drawn"] = on
	p.model.set_drawn(on, true)


## Kınındaki silahla saldırınca silah anında çekilir (iai çekişi)
func _quick_draw() -> void:
	if p.model and p.model.has_weapon() and not Game.profile.get("weapon_drawn", false):
		Game.profile["weapon_drawn"] = true
		p.model.set_drawn(true, false)


func _process(_dt: float) -> void:
	# ekipman değişip model yeniden kurulunca kın durumu geri gelsin
	if p and p.model and p.model.has_weapon() and p.model.drawn != bool(Game.profile.get("weapon_drawn", false)) and p.model._sheath_t < 0.0:
		p.model.set_drawn(bool(Game.profile.get("weapon_drawn", false)), false)


# ------------------------------------------------------------------ saldırı
func _break_henge() -> void:
	if Buffs.has("henge"):
		Jutsu.end_henge(p)


func attack() -> void:
	_break_henge()
	_quick_draw()
	if action == "attack":
		if t > _combo(step)["dur"] * 0.4:
			buffered = true
		return
	if action != "" and action != "guard":
		return
	var ca = p.get_node_or_null("CastAnim")
	if ca:
		ca.finish()   # jutsunun bitiş pozu sürerken vurulursa iki poz üst üste binip kollar takılıyordu
	if not p.grounded and p.wall_n == Vector3.ZERO:
		_air_attack()
		return
	step = step + 1 if combo_reset > 0.0 else 0
	if step >= COMBO.size():
		step = 0
	_start_step()


const SWING_SND := {"blade": "swing_blade", "dual": "swing_blade", "sword": "swing_sword", "heavy": "swing_heavy", "staff": "swing_staff",
	"chain": "swing_chain", "sickle": "swing_chain", "claw": "swing_blade", "fan": "swing_fan"}


func _start_step() -> void:
	var c: Dictionary = _combo(step)
	action = "attack"
	t = 0.0
	did_hit = false
	buffered = false
	var tgt = _auto_target()
	if tgt:
		face_to(tgt)
	else:
		var f = p.wish_dir() if p.wish_dir().length() > 0.1 else p.cam_forward()
		p.facing = atan2(-f.x, -f.z)
	# bloktan vuruşa geçiş: blok pozu kollarda kalıp vuruş animasyonuyla karışıyordu (kollar kilitli, takılma) -> hemen bırak
	p.model.overlay.snap("guard", 0.0)
	p.model.play(c["anim"], 0.05, c["speed"], true)
	p.model.overlay.set_pose("kick", 1.0 if c.get("kick", false) else 0.0)
	# yelpaze: kombonun 4. vuruşu uzak rüzgâr dalgası (3 sn bekleme, spam yok)
	if String(Gear.weapon(Game.profile).get("style", "")) == "fan" and step == 3 and fan_cd <= 0.0 and p.chakra >= 6.0:
		fan_cd = 3.0
		p.chakra -= 6.0
		var dir = p.face_dir()
		get_tree().create_timer(0.15).timeout.connect(func():
			if not is_instance_valid(p):
				return
			var o = p.global_position + Vector3.UP * 0.3
			FX.speed_lines(o + Vector3.UP, dir)
			VFX.puffs(o + dir * 4.0 + Vector3.UP, {"amount": 40, "life": 0.6, "size": 0.7, "radius": 1.2, "vmin": 10, "vmax": 18, "dir": dir, "spread": 18.0,
				"colors": [Color(0.85, 1.0, 0.92, 0.7), Color(0.7, 0.95, 0.85, 0)]})
			Sfx.play("wind", o, 1.1)
			Combat.hit_zone(p, o, dir, 16.0, 18.0, 3.0, {"dmg": 12.0 * Stats.melee_mult(Game.profile), "knock": 14.0, "launch": 3.0, "kind": "heavy", "element": "fuuton", "hitstop": 0.04, "melee": true}))
	# silaha özgü savuruş (kılıç "vuuşş", ağır silah "vuuum", asa "vuff"...), silahsız: yumruk savuruşu
	var wst = String(Gear.weapon(Game.profile).get("style", "fist")) if Game.profile.get("weapon_drawn", false) else "fist"
	Sfx.play(String(SWING_SND.get(wst, "whoosh")), p.global_position, randf_range(0.92, 1.1), 0.75 if SWING_SND.has(wst) else 0.6)


## Jutsu chakra maliyeti: gücü gibi seviyeyle büyür (sabit kalınca yüksek seviyede chakra hiç bitmiyordu);
## yetenek indirimi en fazla %30
static func jutsu_cost(j: Dictionary) -> float:
	var lv = int(Game.profile.get("level", 1))
	return float(j.get("cost", 0)) * (1.0 + (lv - 1) * 0.045) * clampf(1.0 + Stats.skill(Game.profile, "jutsu_cost"), 0.7, 1.0)


func _air_attack() -> void:
	action = "attack"
	air_attack = true
	t = 0.0
	did_hit = false
	step = 4
	var tgt = _auto_target(10.0)
	if tgt:
		face_to(tgt)
	p.velocity = p.face_dir() * 14.0 + Vector3.DOWN * 18.0
	p.model.play("slash_b", 0.05, 1.5, true)
	p.model.overlay.set_pose("kick", 1.0)


## Player'ın hareket fizik koduna çağrılır; true dönerse normal hareket atlanır
func move_override(dt: float) -> bool:
	t += dt
	combo_reset -= dt
	guard_t += dt
	last_hit_t += dt
	invuln -= dt
	sub_bars = minf(4.0, sub_bars + dt / 6.0)
	for k in cooldowns.keys():
		cooldowns[k] -= dt
	jutsu_gcd -= dt
	fan_cd -= dt
	_gcd_msg_t -= dt
	strain_t -= dt
	if strain_t <= 0.0:
		strain = 0
	_update_charge(dt)
	_update_guard()
	match action:
		"attack":
			return _do_attack(dt)
		"cast":
			return _do_cast(dt)
		"throw":
			p.velocity.x *= 0.8; p.velocity.z *= 0.8
			p.velocity.y -= Player.GRAV * dt
			if t > 0.35:
				action = ""
			return true
		"hitstun":
			p.velocity.x = move_toward(p.velocity.x, 0, dt * 30); p.velocity.z = move_toward(p.velocity.z, 0, dt * 30)
			p.velocity.y -= Player.GRAV * dt
			if t > 0.4:
				action = ""
			return true
		"knockdown":
			p.velocity.x = move_toward(p.velocity.x, 0, dt * 8); p.velocity.z = move_toward(p.velocity.z, 0, dt * 8)
			p.velocity.y -= Player.GRAV * dt
			if t > 1.0 and p.grounded and p.model.current != "getup":
				p.model.play("getup", 0.1, 1.6, true)
			if t > 1.9:
				action = ""
				invuln = 0.6
			return true
		"chakra_dash":
			return _do_chakra_dash(dt)
		"guard", "charge":
			p.velocity.x = move_toward(p.velocity.x, 0, dt * 60); p.velocity.z = move_toward(p.velocity.z, 0, dt * 60)
			p.velocity.y -= Player.GRAV * dt
			return true
	return false


func _do_attack(dt: float) -> bool:
	var c: Dictionary = _combo(step)
	var tgt = _auto_target()
	if air_attack:
		p.velocity.y -= Player.GRAV * dt * 0.5
		if not did_hit:
			var pt = p.global_position + Vector3.UP * 0.6 + p.face_dir() * 0.8
			if not Combat.hit_sphere(p, pt, 0.9, _hit_info(c)).is_empty():
				did_hit = true
				_on_hit_fx(pt, c)
		if p.grounded or t > 0.8:
			air_attack = false
			action = ""
			p.model.overlay.set_pose("kick", 0.0)
			FX.impact(p.global_position, Color(0.9, 0.8, 0.6), 0.6)
			Combat.hit_sphere(p, p.global_position + Vector3.UP * 0.5, 2.2, {"dmg": 8.0 * Stats.melee_mult(Game.profile), "knock": 10.0, "launch": 4.0, "kind": "heavy", "melee": true})
		return true
	# hedefe atıl (homing)
	if t < c["hit"]:
		var lunge: float = c["lunge"]
		if tgt:
			var dist = tgt.global_position.distance_to(p.global_position) - tgt.radius - p.radius
			if dist > 5.0:
				pass   # uzaktaki hedefe kayarak yaklaşmak yok (savaşta Shift'siz koşu gibi görünüyordu): normal adım
			elif dist > c["reach"] * 0.8:
				lunge = minf(9.0, dist / maxf(0.05, c["hit"] - t) * 0.9)
			else:
				lunge = 0.0
		var v = p.face_dir() * lunge
		p.velocity.x = v.x; p.velocity.z = v.z
	else:
		p.velocity.x = move_toward(p.velocity.x, 0, dt * 60); p.velocity.z = move_toward(p.velocity.z, 0, dt * 60)
	p.velocity.y -= Player.GRAV * dt
	if not did_hit and t >= c["hit"] and c.has("chain_kind"):
		did_hit = true
		_chain_strike(c, tgt)
	if not did_hit and t >= c["hit"]:
		did_hit = true
		var pt = p.global_position + Vector3.UP * 1.1 + p.face_dir() * (p.radius + c["reach"] * 0.6)
		var hits = Combat.hit_sphere(p, pt, c["reach"] * 0.65 * Buffs.mod("reach"), _hit_info(c))
		if not hits.is_empty():
			_on_hit_fx(pt, c)
			for h in hits:
				Progress.on_hit_landed(h)
				_special_hit(h, pt, c)
	if t >= c["dur"]:
		p.model.overlay.set_pose("kick", 0.0)
		combo_reset = 0.5
		if buffered and step < COMBO.size() - 1:
			step += 1
			_start_step()
		else:
			action = ""
			if step >= COMBO.size() - 1:
				step = -1
	return true


## Silah stillerine özel kombolar: 5 adımın animasyonları ("" = temel adım/tekme), hız, süre ve savurma çarpanı, vuruş rengi/sesi
const STYLE_COMBOS := {
	"blade": {"anims": ["a/Punch_Jab", "b/Melee_Hook", "b/Sword_Regular_A", "", "b/Sword_Regular_C"], "speed": 1.75, "dur": 0.9, "knock": 1.0, "fx": Color(0.85, 0.92, 1.0), "snd": "hit_blade"},
	"dual": {"anims": ["b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_Combo"], "speed": 2.0, "dur": 0.78, "knock": 0.8, "fx": Color(0.7, 0.9, 1.0), "snd": "hit_blade"},
	"sword": {"anims": ["b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_C", "a/Sword_Attack", "b/Sword_Dash_RM"], "speed": 1.5, "dur": 1.05, "knock": 1.25, "fx": Color(0.8, 0.9, 1.0), "snd": "hit_sword"},
	"heavy": {"anims": ["b/TreeChopping", "b/Sword_Regular_C", "a/Sword_Attack", "b/Shield_OneShot", "b/TreeChopping"], "speed": 1.12, "dur": 1.45, "knock": 2.2, "fx": Color(1.0, 0.6, 0.3), "snd": "hit_heavy_weapon"},
	"staff": {"anims": ["a/Punch_Jab", "b/Sword_Regular_B", "b/Farm_Harvest", "a/Sword_Attack", "b/Sword_Regular_Combo"], "speed": 1.45, "dur": 1.1, "knock": 1.6, "fx": Color(1.0, 0.85, 0.5), "snd": "hit_staff"},
	"chain": {"anims": ["b/OverhandThrow", "b/Sword_Regular_B", "b/OverhandThrow", "b/OverhandThrow", "b/Sword_Regular_Combo"], "speed": 1.7, "dur": 1.15, "knock": 1.1, "fx": Color(0.9, 0.95, 1.0), "snd": "hit_chain"},
	"sickle": {"anims": ["b/Farm_Harvest", "b/Sword_Regular_A", "b/Farm_Harvest", "", "b/Sword_Regular_C"], "speed": 2.0, "dur": 0.85, "knock": 1.0, "fx": Color(0.9, 0.95, 1.0), "snd": "hit_chain"},
	"claw": {"anims": ["b/Zombie_Scratch", "b/Zombie_Scratch", "b/Melee_Hook", "", "b/Zombie_Scratch"], "speed": 2.1, "dur": 0.8, "knock": 0.9, "fx": Color(1.0, 0.4, 0.35), "snd": "hit_claw"},
	"fan": {"anims": ["b/Sword_Regular_B", "b/Sword_Regular_A", "b/Sword_Regular_Combo", "a/Spell_Simple_Shoot", "b/Sword_Regular_C"], "speed": 1.5, "dur": 1.0, "knock": 1.8, "fx": Color(0.7, 1.0, 0.85), "snd": "hit_fan"},
}


## Kombo adımı, eldeki silaha göre (hasar, menzil, stile özel animasyon/süre/vuruş efekti)
func _combo(i: int) -> Dictionary:
	var c = _combo_base(i)
	var cm = Stats.skill(Game.profile, "combo")
	if cm > 0.0:
		c["dur"] = float(c["dur"]) / (1.0 + cm)
		c["hit"] = float(c["hit"]) / (1.0 + cm)
		c["speed"] = float(c.get("speed", 1.0)) * (1.0 + cm)
		c["dmg"] = float(c["dmg"]) * (1.0 + cm * 0.5)
	return c


func _combo_base(i: int) -> Dictionary:
	var c: Dictionary = COMBO[clampi(i, 0, COMBO.size() - 1)].duplicate()
	var w = Gear.weapon(Game.profile)
	# silah hasarı sıkıştırılmış: en ağır silah bile yumruğun ~1.5 katı (jutsu anlamını korusun)
	c["dmg"] = float(c["dmg"]) * (1.0 + (float(w["dmg"]) - 1.0) * 0.45) * (1.0 + Stats.weapon_bonus(Game.profile, String(w.get("style", "fist"))) * 0.6)
	c["reach"] = float(c["reach"]) + float(w["reach"])
	var st: Dictionary = STYLE_COMBOS.get(w["style"], {})
	if st.is_empty():
		return c
	var an: String = st["anims"][clampi(i, 0, 4)]
	if an != "":
		c["anim"] = an
		c["kick"] = false
		c["speed"] = float(st["speed"]) * (0.85 if i == 4 else 1.0)
	c["dur"] = float(c["dur"]) * float(st["dur"])
	c["hit"] = float(c["hit"]) * float(st["dur"])
	c["knock"] = float(c["knock"]) * float(st["knock"])
	c["fx"] = st["fx"]
	c["snd"] = st["snd"]
	if w["style"] == "heavy" and i == 4:
		c["launch"] = 8.0
	if w["style"] == "chain":
		# kusarigama: orta menzil — orak zincirle fırlar, savrulur, çeker, döner; oyuncu hedefe atılmaz
		c["chain_kind"] = ["throw", "sweep", "reel", "throw", "spin"][clampi(i, 0, 4)]
		c["reach"] = 6.5
		c["lunge"] = 0.0
	c["special"] = w.get("special", "")
	match c["special"]:
		"extend":
			c["reach"] = float(c["reach"]) + 0.4
		"gust", "wind":
			c["knock"] = float(c["knock"]) * 1.8
		"armor_break":
			c["heavy"] = true
	return c


## Efsanevi silah yetenekleri: vuruş bilgisine eklenenler
func _special_info(info: Dictionary, c: Dictionary) -> Dictionary:
	match c.get("special", ""):
		"raiton":
			info["element"] = "raiton"
			info["stun"] = 0.5
		"wind", "gust":
			info["element"] = "fuuton"
		"flow":
			info["stun"] = 0.25
		"armor_break":
			info["kind"] = "heavy"
			info["dmg"] = float(info["dmg"]) * 1.2
	return info


## Efsanevi silah yetenekleri: isabetten sonra (can çalma, chakra emme, patlama, çekme)
## Kusarigama vuruşu: orak elden zincirle fırlar (throw/reel), yay çizer (sweep) ya da etrafta döner (spin); zincir elden orağa uzanır
func _chain_strike(c: Dictionary, tgt: Node3D) -> void:
	var pj = PathJutsu.get_pinst()
	var kind: String = c["chain_kind"]
	var dir = p.face_dir()
	var reach: float = float(c["reach"]) * Buffs.mod("reach")
	var dist = reach
	if tgt and is_instance_valid(tgt):
		var d = tgt.global_position - p.global_position
		d.y = 0.0
		if d.length() < reach + 1.0 and d.length() > 0.3:
			dir = d.normalized()
			dist = clampf(d.length(), 2.0, reach)
	var hand = func(): return pj.hand_pos(p, true) if is_instance_valid(p) else Vector3.ZERO
	# elde zincirli orak gizlenir, havada uçan orak görünür
	var wn: Node3D = null
	if p.model and not p.model.weapons.is_empty():
		wn = p.model.weapons[0]["node"]
		wn.visible = false
	var b = MB.new()
	b.add("cyl", Vector3(0, 0, -0.15), Vector3(0.03, 0.3, 0.03), Color(0.45, 0.32, 0.2), Vector3(90, 0, 0), 8)
	b.add("box", Vector3(0, 0.09, 0.0), Vector3(0.01, 0.22, 0.04), Color(0.75, 0.78, 0.82), Vector3(-25, 0, 0))
	var tip = MeshInstance3D.new()
	tip.mesh = b.build(Props.toon())
	get_tree().current_scene.add_child(tip)
	tip.global_position = hand.call()
	var chain_mat = StandardMaterial3D.new()
	chain_mat.albedo_color = Color(0.3, 0.3, 0.34)
	var life = 0.5 if kind != "spin" else 0.75
	pj.tether(hand, func(): return tip.global_position if is_instance_valid(tip) else hand.call(), 0.035, chain_mat, life)
	var center = p.global_position + Vector3.UP * 1.1
	var pos_at := func(u: float) -> Vector3:   # u: 0→1 vuruş yolu
		match kind:
			"sweep":
				var a = deg_to_rad(lerpf(-75.0, 75.0, u))
				return center + dir.rotated(Vector3.UP, a) * (reach * 0.8)
			"spin":
				return center + dir.rotated(Vector3.UP, u * TAU) * (reach * 0.65) + Vector3.UP * (sin(u * TAU) * 0.3)
			_:
				var out = 1.0 - absf(u * 2.0 - 1.0)   # git-gel
				return center.lerp(center + dir * dist, out)
	var tw = tip.create_tween()
	tw.tween_method(func(u):
		if is_instance_valid(tip):
			var q: Vector3 = pos_at.call(u)
			tip.look_at_from_position(q, q + (q - center).normalized() + Vector3.UP * 0.01, Vector3.UP)
			tip.rotate_object_local(Vector3.RIGHT, u * 30.0), 0.0, 1.0, life)
	tw.tween_callback(func():
		tip.queue_free()
		if is_instance_valid(wn):
			wn.visible = true)
	Sfx.play("whoosh", center, 1.5, 0.5)
	var info = _hit_info(c)
	var hit_once := {}
	var strike := func(q: Vector3, r: float):
		for h in Combat.hit_sphere(p, q, r, info):
			if hit_once.has(h):
				continue
			hit_once[h] = true
			_on_hit_fx(q, c)
			Progress.on_hit_landed(h)
			_special_hit(h, q, c)
			if kind == "reel" and is_instance_valid(h) and h.get("velocity") != null:
				var back = p.global_position - h.global_position
				h.velocity = back.normalized() * minf(22.0, back.length() * 3.0) + Vector3.UP * 3.0
				if h.has_method("apply_status"):
					h.apply_status("stun", 0.6)
	match kind:
		"sweep", "spin":
			for k in 6:
				var u = (k + 0.5) / 6.0
				get_tree().create_timer(life * u).timeout.connect(func(): strike.call(pos_at.call(u), 1.3))
		_:
			get_tree().create_timer(life * 0.5).timeout.connect(func(): strike.call(pos_at.call(0.5), 1.2))


func _special_hit(h: Node3D, pt: Vector3, c: Dictionary) -> void:
	var dmg = float(c["dmg"]) * Stats.melee_mult(Game.profile)
	match c.get("special", ""):
		"lifesteal":
			p.hp = minf(p.max_hp, p.hp + dmg * 0.25)
			FX.hit_spark(pt, Color(0.9, 0.1, 0.15), 1.2)
		"drain":
			p.chakra = minf(p.max_chakra, p.chakra + 6.0)
			if h.has_method("apply_status"):
				h.apply_status("slow", 1.5)
			FX.hit_spark(pt, Color(0.35, 0.5, 1.0), 1.2)
		"explode":
			FX.explosion(pt, 0.55)
			Combat.hit_sphere(p, pt, 1.8, {"dmg": dmg * 0.5, "knock": 8.0, "launch": 2.0, "kind": "heavy", "burn": 2.0}, [h])
		"pull":
			if h is CharacterBody3D:
				h.velocity = (p.global_position - h.global_position).normalized() * 9.0 + Vector3.UP * 2.0
		"raiton":
			FX.hit_spark(pt, Color(1.0, 0.95, 0.4), 1.4)
			Sfx.play("chidori", pt, 1.4, 0.5)
		"wind", "gust":
			FX.hit_spark(pt, Color(0.6, 1.0, 0.8), 1.3)


func _hit_info(c: Dictionary) -> Dictionary:
	return _special_info(_hit_info_base(c), c)


func _hit_info_base(c: Dictionary) -> Dictionary:
	return {
		"dmg": c["dmg"] * Stats.melee_mult(Game.profile), "knock": c.get("knock", 2.0), "launch": c.get("launch", 0.0), "melee": true,
		"kind": "heavy" if c.get("heavy", false) else "light", "hitstop": 0.09 if c.get("heavy", false) else 0.04,
		"dir": p.face_dir(),
		"blade": String(c.get("snd", "")) in ["hit_blade", "hit_sword", "hit_claw", "hit_chain", "hit_heavy_weapon"],   # kesici silah: daha çok kan
	}


func _on_hit_fx(pt: Vector3, c: Dictionary) -> void:
	var heavy: bool = c.get("heavy", false)
	FX.hit_spark(pt, c.get("fx", Color(1.0, 0.85, 0.45) if not heavy else Color(1.0, 0.55, 0.25)), 1.4 if heavy else 0.9)
	Sfx.play(c.get("snd", "hit_heavy" if heavy else "punch"), pt, randf_range(0.9, 1.15))
	if heavy and c.has("snd") and not String(c["snd"]).begins_with("hit_"):
		Sfx.play("hit_heavy", pt, 0.9, 0.6)
	if Game.world:
		Game.world.env.add_shake(0.5 if heavy else 0.18)
		if heavy:
			Game.world.env.screen_flash(0.12)


# ------------------------------------------------------------------ blok
func _update_guard() -> void:
	var want = Input.is_action_pressed("guard") and p.grounded and (action == "" or action == "guard")
	if want and action == "":
		action = "guard"
		guard_t = 0.0
		p.model.play("block", 0.08)
		p.model.overlay.set_pose("guard", 1.0)
	elif not want and action == "guard":
		action = ""
		p.model.overlay.set_pose("guard", 0.0)
		p.model.play("idle", 0.15)   # blok klibinde donup kalmasın


# ------------------------------------------------------------------ chakra şarjı
func _update_charge(dt: float) -> void:
	var want = Input.is_action_pressed("charge") and p.grounded and (action == "" or action == "charge") and not Game.ui_open
	if want:
		if action != "charge":
			action = "charge"
			p.model.play("idle", 0.15)
			# animedeki chakra toplama: eller göğüs önünde Kaplan mühründe, dirsekler dışa, dizler bükük, gövde hafif öne, baş eğik
			p.model.overlay.cast_pose = {"arms": [["LeftUpperArm", Vector3(0.35, -0.7, 0.45)], ["LeftLowerArm", Vector3(-0.85, 0.35, 0.4)], ["LeftHand", Vector3(-0.15, 0.95, 0.25)],
				["RightUpperArm", Vector3(-0.35, -0.7, 0.45)], ["RightLowerArm", Vector3(0.85, 0.35, 0.4)], ["RightHand", Vector3(0.15, 0.95, 0.25)]],
				"fL": [0.0, 0.0, 1.5, 1.5, 0.1], "fR": [0.0, 0.0, 1.5, 1.5, 0.1], "spine": 12.0, "neck": 10.0, "crouch": 0.45}
			p.model.overlay.set_pose("cast", 1.0)
			p.model.overlay.set_pose("plant", 1.0)
			if aura == null:
				aura = FX.aura(p, Color(0.35, 0.7, 1.0), 1.2, Vector3(0, 0.9, 0), 0.0)
			Sfx.play("wind", p.global_position, 0.8, 0.6)
		p.chakra = minf(p.max_chakra, p.chakra + 32.0 * dt)
	elif action == "charge":
		action = ""
	if action != "charge" and float(p.model.overlay.targets.get("plant", 0.0)) > 0.0:
		p.model.overlay.set_pose("cast", 0.0)
		p.model.overlay.set_pose("plant", 0.0)
	if aura and action != "charge":
		aura.emitting = false
		var a = aura
		aura = null
		get_tree().create_timer(1.0).timeout.connect(a.queue_free)


# ------------------------------------------------------------------ Kawarimi (yer değiştirme)
func substitute() -> void:
	if sub_bars < 1.0 or action in ["cast"]:
		return
	sub_bars -= 1.0
	var from = p.global_position
	FX.smoke_puff(from + Vector3.UP * 0.9, 1.0, 16)
	_spawn_log(from)
	var tgt = _auto_target(12.0)
	var dest: Vector3
	if tgt:
		var back = -(tgt.global_transform.basis.z) if not tgt is Player else Vector3.ZERO
		var v = (p.global_position - tgt.global_position)
		v.y = 0
		dest = tgt.global_position - v.normalized() * (tgt.radius + 1.6)
		face_to(tgt)
	else:
		dest = from - p.face_dir() * 7.0
	dest.y = Game.ground_height(dest.x, dest.z) + 0.1
	p.global_position = dest
	p.velocity = Vector3.ZERO
	action = ""
	invuln = 0.5
	FX.smoke_puff(dest + Vector3.UP * 0.9, 0.7, 10)
	Progress.on_technique_used("kawarimi")


func _spawn_log(at: Vector3) -> void:
	var log = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = 0.22; c.bottom_radius = 0.24; c.height = 1.5; c.radial_segments = 10
	c.material = Props.toon_color(Color(0.55, 0.38, 0.22))
	log.mesh = c
	get_tree().current_scene.add_child(log)
	log.global_position = at + Vector3.UP * 0.75
	log.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
	var tw = log.create_tween()
	tw.tween_property(log, "rotation:x", PI * 0.5, 0.5).set_delay(0.3)
	tw.tween_property(log, "scale", Vector3.ONE * 0.01, 0.3).set_delay(1.5)
	tw.tween_callback(log.queue_free)


# ------------------------------------------------------------------ kunai/shuriken
func throw_tool() -> void:
	_break_henge()
	if action != "" and action != "guard":
		return
	var inv: Dictionary = Game.profile.get("inventory", {})
	var tool: String = Game.profile.get("throw_sel", "kunai")
	if int(inv.get(tool, 0)) <= 0:
		Hud.msg("Hiç %s kalmadı!" % tool, Color(1, 0.6, 0.5))
		return
	inv[tool] = int(inv[tool]) - 1
	action = "throw"
	t = 0.0
	var tgt = _auto_target(40.0)
	var aim: Vector3
	var start = p.global_position + Vector3.UP * 1.4 + p.face_dir() * 0.4
	if tgt:
		face_to(tgt)
		aim = (tgt.global_position + Vector3.UP * tgt.height * 0.55 - start).normalized()
	else:
		aim = -p.cam.global_transform.basis.z
		p.facing = atan2(-aim.x, -aim.z)
	p.model.play("throw", 0.05, 1.8, true)
	Sfx.play("kunai", start)
	var n = 3 if tool in ["shuriken", "senbon"] else 1
	if Stats.has_unlock(Game.profile, "multi_throw") and tool in ["kunai", "shuriken"]:
		n += 2  # Silah Yağmuru
	for i in n:
		var dir = aim.rotated(Vector3.UP, deg_to_rad((i - (n - 1) * 0.5) * 8.0))
		Projectile.tool(p, start, dir, tool, tgt)


# ------------------------------------------------------------------ chakra dash (Storm)
func chakra_dash() -> void:
	if p.chakra < 8.0:
		return
	p.chakra -= 8.0
	action = "chakra_dash"
	t = 0.0
	dash_target = lock_target
	p.model.play("run", 0.05, 1.6)
	p.model.overlay.set_pose("ninja_run", 1.0)
	aura = FX.aura(p, Color(0.4, 0.75, 1.0), 0.8, Vector3(0, 0.9, 0), 0.0)
	Sfx.play("whoosh", p.global_position, 0.8)


func _do_chakra_dash(dt: float) -> bool:
	if dash_target == null or not is_instance_valid(dash_target) or dash_target.is_dead() or t > 1.2:
		action = ""
		return false
	face_to(dash_target)
	var v = dash_target.global_position - p.global_position
	var d = v.length() - dash_target.radius - p.radius
	var dir = v.normalized()
	p.velocity = Vector3(dir.x, maxf(dir.y, -0.5), dir.z) * 30.0
	if d < 1.4:
		action = ""
		p.velocity = Vector3.ZERO
		step = -1
		combo_reset = 0.0
		attack()
	return true


# ------------------------------------------------------------------ jutsu
func begin_cast(jid: String) -> void:
	if SpecialSlots.cast(p, jid):   # göz / kuyruklu canavar tekniği (slotta)
		return
	if jid != "henge":
		_break_henge()
	if action != "" and action != "guard" and action != "charge":
		return
	var j: Dictionary = Data.jutsu.get(jid, {})
	if j.is_empty():
		return
	# dōjutsu teknikleri: göz açık olmadan yapılamaz (V)
	if String(j.get("learn", "")).begins_with("eye:") and not String(j.get("learn", "")).ends_with("susanoo"):
		var ey = modes.eyes if modes else null
		if ey == null or not ey.active:
			Hud.msg("%s için önce gözlerini aç (V)." % String(j["name"]).split(" (")[0], Color(1, 0.55, 0.5))
			return
	# moda bağlı teknikler: animedeki gibi yalnız sennin modunda / kuyruklu canavar modunda atılır
	var need = String(j.get("need", ""))
	if need == "sage" and not (modes and modes.sage):
		Hud.msg("%s sadece sennin modunda atılabilir." % String(j["name"]), Color(1, 0.7, 0.4))
		return
	var in_beast = modes and (modes.beast or (modes.cloak != null and modes.cloak.level > 0))
	if need == "beast" and not in_beast:
		Hud.msg("%s sadece kuyruklu canavar modunda atılabilir." % String(j["name"]), Color(1, 0.55, 0.3))
		return
	if need.begins_with("contract:") and not Contracts.signed(need.substr(9)):   # kurbağa yağı vb.: sözleşme gerekir
		Hud.msg("%s için %s gerekli." % [String(j["name"]), String(Contracts.DEFS.get(need.substr(9), {}).get("name", "çağırma sözleşmesi"))], Color(1, 0.7, 0.4))
		return
	if need.begins_with("beast:"):   # belirli canavarın tekniği (Shukaku'nun fūtonu, Kurama'nın Rasenshurikeni...)
		var bid = need.substr(6)
		if not in_beast or modes.cloak == null or modes.cloak.beast_id() != bid:
			var bn = String(BeastModels.INFO.get(bid, {}).get("name", bid)).split(" —")[0]
			Hud.msg("%s sadece %s jinchūriki'si olarak, canavar modundayken atılabilir." % [String(j["name"]), bn], Color(1, 0.55, 0.3))
			return
	if cooldowns.get(jid, 0.0) > 0.0:
		Hud.msg("%s hazır değil (%.1fsn)" % [j["name"], cooldowns[jid]], Color(0.8, 0.8, 1))
		return
	# art arda atış engeli (ortak bekleme + chakra yorgunluğu) kaldırıldı: sınır chakranın kendisi (seviyeyle büyüyen maliyet)
	var cost = jutsu_cost(j)
	if Game.has_meta("sandbox"):
		cost = 0.0
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok! [C] ile chakra topla", Color(0.5, 0.8, 1))
		return
	p.chakra -= cost
	cooldowns[jid] = Combat.jutsu_cd(j)
	var tier = int(j.get("tier", 2))
	cast_jutsu = jid
	action = "cast"
	t = 0.0
	var seals: Array = j.get("seals", [])
	var tgt = _auto_target(30.0)
	if tgt:
		face_to(tgt)
	else:
		var f = p.cam_forward()
		p.facing = atan2(-f.x, -f.z)
	# mühürler + jutsuya özel hazırlık/salınım koreografisi (CastAnim)
	cast_anim = CastAnim.play(p, jid)
	cast_time = cast_anim.release_t
	if seals.size() > 0:
		Hud.show_seals(seals)


func _do_cast(dt: float) -> bool:
	p.velocity.x = move_toward(p.velocity.x, 0, dt * 60); p.velocity.z = move_toward(p.velocity.z, 0, dt * 60)
	if not p.grounded:
		p.velocity.y -= Player.GRAV * dt * 0.3
	# hedef: kilitli hedef, yoksa nişangâhın üstündeki (kırmızı) düşman, yoksa yok (jutsu nişangâhın noktasına gider)
	var tg = _cast_target()
	if tg and t < cast_time:
		face_to(tg)
	if t >= cast_time:
		# salınım anı: koreografi ile eş zamanlı; takip pozu CastAnim'de sürer
		action = ""
		Jutsu.execute(p, cast_jutsu, tg)
		Progress.on_technique_used(cast_jutsu)
	return true


# ------------------------------------------------------------------ hasar alma
func take_hit(info: Dictionary) -> void:
	if invuln > 0.0 or p.hp <= 0.0:
		return
	if modes and modes.on_player_hit(info):
		return
	var atk: Node3D = info.get("attacker")
	var dmg: float = info.get("dmg", 5.0) * Combat.jutsu_factor(info)
	dmg *= Combat.element_mult(info.get("element", ""), Game.profile.get("elements", [""])[0])
	dmg *= Elements.on_hit(p, info)  # ıslak/yanık/donma etkileşimleri oyuncuya da işler
	if action == "guard" and atk and is_instance_valid(atk):
		var to_atk = (atk.global_position - p.global_position)
		to_atk.y = 0
		# yalnız önden (yandan/arkadan gelen darbe bloğu geçer)
		if to_atk.length() < 0.3 or to_atk.normalized().dot(p.face_dir()) > 0.1:
			var tier = int(info.get("tier", -1))
			var gskill = clampf(Stats.skill(Game.profile, "guard"), 0.0, 0.8)
			if guard_t < 0.18 and tier < 3:
				# mükemmel blok (yakın dövüş ve küçük jutsu): saldıran sendeler
				Combat.popup_text(p.global_position + Vector3.UP * 2.2, "MÜKEMMEL!", Color(0.6, 0.9, 1))
				FX.ring(p.global_position + Vector3.UP, Color(0.6, 0.9, 1), 4.0, 0.3, false)
				Sfx.play("block", p.global_position, 1.3)
				if tier < 0 and atk.has_method("stagger"):
					atk.stagger(1.0)
				return
			# jutsu bloğu deler: büyük jutsuda hasarın çoğu geçer, bloğu tutmak chakra yer
			var pass_f = Combat.block_pass(info, 0.2) * (1.0 - gskill * (1.0 if tier < 0 else 0.4))
			if guard_t < 0.18:
				pass_f *= 0.6   # büyük jutsuya mükemmel zamanlama: biraz daha az
			var blocked = dmg * (1.0 - pass_f)
			dmg *= pass_f
			var cost = blocked * (0.35 if tier >= 0 else 0.1)
			if tier >= 4 or p.chakra < cost:
				# blok kırıldı: kalan hasarla birlikte devrilir
				p.chakra = maxf(0.0, p.chakra - cost)
				action = ""
				Combat.popup_text(p.global_position + Vector3.UP * 2.2, "BLOK KIRILDI!", Color(1.0, 0.6, 0.35))
				Sfx.play("block", p.global_position, 0.7)
				info = info.duplicate()
				info["kind"] = "heavy"
			else:
				p.chakra -= cost
				FX.hit_spark(p.global_position + Vector3.UP * 1.2 + p.face_dir() * 0.5, Color(0.6, 0.85, 1.0), 0.6)
				Sfx.play("block", p.global_position)
				p.velocity += info.get("dir", Vector3.ZERO) * (3.0 + maxi(0, tier) * 1.5)
				p.hp -= dmg
				if dmg >= 1.0:
					Combat.damage_number(p.global_position + Vector3.UP * 2.0, dmg, Color(0.75, 0.8, 1.0))
				if p.hp <= 0.0:
					p.hp = 0.0
					Progress.on_player_died()
				return
	p.hp -= dmg
	last_hit_t = 0.0
	p.model.flash(0.8)
	var hdir: Vector3 = info.get("dir", Vector3.ZERO)
	var hheavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	p.model.react(hdir, clampf(dmg / maxf(1.0, p.max_hp) * 7.0, 0.55, 1.0) * (1.3 if hheavy else 1.0), randf() < 0.35)
	if dmg >= 1.0 and not info.get("no_blood", false) and String(info.get("element", "")) not in ["katon", "raiton"]:
		FX.blood(p.global_position + Vector3.UP * 1.1, hdir, clampf(dmg / maxf(1.0, p.max_hp) * 5.0, 0.3, 1.0))
	Combat.damage_number(p.global_position + Vector3.UP * 2.0, dmg, Color(1, 0.4, 0.35))
	Sfx.play("hurt", p.global_position)
	if Game.world:
		Game.world.env.add_shake(0.35)
	var dir: Vector3 = info.get("dir", Vector3.ZERO)
	# yere serilme yalnız gerçekten ağır darbede / havaya fırlatmada (her jutsu isabeti yere sermesin)
	var heavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	# kombo kilidi kırıcı: üst üste sersemletilince kısa dokunulmazlık + itme patlaması (düşman kombosunda sonsuz kilit yok)
	var now = Time.get_ticks_msec()
	stun_meter = maxf(0.0, stun_meter - (now - stun_last_ms) / 1000.0 * 1.2) + (2.0 if heavy else 1.0)
	stun_last_ms = now
	if stun_meter >= 4.0 and p.hp > 0.0:
		stun_meter = 0.0
		invuln = 1.0
		action = ""
		Combat.popup_text(p.global_position + Vector3.UP * 2.3, "Kombo kırıldı!", Color(0.7, 0.9, 1.0))
		FX.ring(p.global_position + Vector3.UP * 0.9, Color(0.7, 0.9, 1.0), 4.5, 0.35)
		Combat.hit_sphere(p, p.global_position + Vector3.UP, 3.2, {"dmg": 6.0, "knock": 14.0, "kind": "light"})
		return
	t = 0.0
	if aura:
		_update_charge(0)
	if heavy:
		action = "knockdown"
		p.velocity = dir * info.get("knock", 8.0) * 0.4 + Vector3.UP * (info.get("launch", 0.0) * 0.6 + 2.5)
		p.model.play("knock", 0.05, 1.2, true)
	else:
		action = "hitstun"
		p.velocity = dir * info.get("knock", 2.0) * 0.35
		p.model.play("hit" if randf() < 0.5 else "hit_head", 0.04, 1.4, true)
	p.model.overlay.set_pose("seal", 0.0)
	p.model.overlay.set_pose("guard", 0.0)
	if p.hp <= 0.0:
		p.hp = 0.0
		Progress.on_player_died()
