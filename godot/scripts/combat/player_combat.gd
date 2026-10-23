class_name PlayerCombat
extends Node
## Oyuncunun Storm tarzı dövüşü.
## Sol tık: kombo | Sağ tık (basılı): blok | Q: Kawarimi | C (basılı): chakra şarjı | R: kunai
## E/orta tık: hedefe kilitlen | Kilitliyken Shift: chakra dash | 1-6: jutsu slotları

const COMBO := [
	{"anim": "jab", "speed": 1.5, "hit": 0.10, "dur": 0.32, "dmg": 6.0, "reach": 1.3, "lunge": 4.0, "knock": 2.0},
	{"anim": "cross", "speed": 1.5, "hit": 0.12, "dur": 0.34, "dmg": 7.0, "reach": 1.3, "lunge": 4.0, "knock": 2.0},
	{"anim": "hook", "speed": 1.6, "hit": 0.16, "dur": 0.4, "dmg": 8.0, "reach": 1.4, "lunge": 4.5, "knock": 3.0},
	{"anim": "idle", "kick": true, "speed": 1.0, "hit": 0.14, "dur": 0.38, "dmg": 9.0, "reach": 1.7, "lunge": 5.0, "knock": 4.0},
	{"anim": "slash_c", "speed": 1.4, "hit": 0.22, "dur": 0.6, "dmg": 15.0, "reach": 1.8, "lunge": 6.0, "knock": 16.0, "launch": 5.0, "heavy": true},
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
var last_hit_t = 99.0
var aura: GPUParticles3D
var cast_jutsu = ""
var cast_time = 0.0
var cooldowns = {}
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
	if not p.grounded and p.wall_n == Vector3.ZERO:
		_air_attack()
		return
	step = step + 1 if combo_reset > 0.0 else 0
	if step >= COMBO.size():
		step = 0
	_start_step()


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
	p.model.play(c["anim"], 0.05, c["speed"], true)
	p.model.overlay.set_pose("kick", 1.0 if c.get("kick", false) else 0.0)
	Sfx.play("whoosh", p.global_position, randf_range(0.9, 1.2), 0.6)


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
			Combat.hit_sphere(p, p.global_position + Vector3.UP * 0.5, 2.2, {"dmg": 8.0 * Stats.melee_mult(Game.profile), "knock": 10.0, "launch": 4.0, "kind": "heavy"})
		return true
	# hedefe atıl (homing)
	if t < c["hit"]:
		var lunge: float = c["lunge"]
		if tgt:
			var dist = tgt.global_position.distance_to(p.global_position) - tgt.radius - p.radius
			if dist > c["reach"] * 0.8:
				lunge = minf(18.0, dist / maxf(0.05, c["hit"] - t) * 0.9)
			else:
				lunge = 0.0
		var v = p.face_dir() * lunge
		p.velocity.x = v.x; p.velocity.z = v.z
	else:
		p.velocity.x = move_toward(p.velocity.x, 0, dt * 60); p.velocity.z = move_toward(p.velocity.z, 0, dt * 60)
	p.velocity.y -= Player.GRAV * dt
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
	"blade": {"anims": ["a/Punch_Jab", "b/Melee_Hook", "b/Sword_Regular_A", "", "b/Sword_Regular_C"], "speed": 1.75, "dur": 0.9, "knock": 1.0, "fx": Color(0.85, 0.92, 1.0), "snd": "clink"},
	"dual": {"anims": ["b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_Combo"], "speed": 2.0, "dur": 0.78, "knock": 0.8, "fx": Color(0.7, 0.9, 1.0), "snd": "clink"},
	"sword": {"anims": ["b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_C", "a/Sword_Attack", "b/Sword_Dash_RM"], "speed": 1.5, "dur": 1.05, "knock": 1.25, "fx": Color(0.8, 0.9, 1.0), "snd": "clink"},
	"heavy": {"anims": ["b/TreeChopping", "b/Sword_Regular_C", "a/Sword_Attack", "b/Shield_OneShot", "b/TreeChopping"], "speed": 1.12, "dur": 1.45, "knock": 2.2, "fx": Color(1.0, 0.6, 0.3), "snd": "hit_heavy"},
	"staff": {"anims": ["a/Punch_Jab", "b/Sword_Regular_B", "b/Farm_Harvest", "a/Sword_Attack", "b/Sword_Regular_Combo"], "speed": 1.45, "dur": 1.1, "knock": 1.6, "fx": Color(1.0, 0.85, 0.5), "snd": "punch"},
	"chain": {"anims": ["b/Farm_Harvest", "b/Sword_Regular_B", "b/OverhandThrow", "b/Farm_Harvest", "b/Sword_Regular_Combo"], "speed": 1.8, "dur": 1.05, "knock": 1.3, "fx": Color(0.9, 0.95, 1.0), "snd": "clink"},
	"sickle": {"anims": ["b/Farm_Harvest", "b/Sword_Regular_A", "b/Farm_Harvest", "", "b/Sword_Regular_C"], "speed": 2.0, "dur": 0.85, "knock": 1.0, "fx": Color(0.9, 0.95, 1.0), "snd": "clink"},
	"claw": {"anims": ["b/Zombie_Scratch", "b/Zombie_Scratch", "b/Melee_Hook", "", "b/Zombie_Scratch"], "speed": 2.1, "dur": 0.8, "knock": 0.9, "fx": Color(1.0, 0.4, 0.35), "snd": "punch"},
	"fan": {"anims": ["b/Sword_Regular_B", "b/Sword_Regular_A", "b/Sword_Regular_Combo", "a/Spell_Simple_Shoot", "b/Sword_Regular_C"], "speed": 1.5, "dur": 1.0, "knock": 1.8, "fx": Color(0.7, 1.0, 0.85), "snd": "wind"},
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
	c["dmg"] = float(c["dmg"]) * float(w["dmg"]) * (1.0 + Stats.weapon_bonus(Game.profile, String(w.get("style", "fist"))))
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
		"dmg": c["dmg"] * Stats.melee_mult(Game.profile), "knock": c.get("knock", 2.0), "launch": c.get("launch", 0.0),
		"kind": "heavy" if c.get("heavy", false) else "light", "hitstop": 0.09 if c.get("heavy", false) else 0.04,
		"dir": p.face_dir(),
	}


func _on_hit_fx(pt: Vector3, c: Dictionary) -> void:
	var heavy: bool = c.get("heavy", false)
	FX.hit_spark(pt, c.get("fx", Color(1.0, 0.85, 0.45) if not heavy else Color(1.0, 0.55, 0.25)), 1.4 if heavy else 0.9)
	Sfx.play(c.get("snd", "hit_heavy" if heavy else "punch"), pt, randf_range(0.9, 1.15))
	if heavy and c.has("snd"):
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


# ------------------------------------------------------------------ chakra şarjı
func _update_charge(dt: float) -> void:
	var want = Input.is_action_pressed("charge") and p.grounded and (action == "" or action == "charge") and not Game.ui_open
	if want:
		if action != "charge":
			action = "charge"
			p.model.play("cast", 0.15)
			if aura == null:
				aura = FX.aura(p, Color(0.35, 0.7, 1.0), 1.2, Vector3(0, 0.9, 0), 0.0)
			Sfx.play("wind", p.global_position, 0.8, 0.6)
		p.chakra = minf(p.max_chakra, p.chakra + 32.0 * dt)
	elif action == "charge":
		action = ""
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
	var n = 3 if tool == "shuriken" else 1
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
	if jid != "henge":
		_break_henge()
	if action != "" and action != "guard" and action != "charge":
		return
	var j: Dictionary = Data.jutsu.get(jid, {})
	if j.is_empty():
		return
	if cooldowns.get(jid, 0.0) > 0.0:
		Hud.msg("%s hazır değil (%.1fsn)" % [j["name"], cooldowns[jid]], Color(0.8, 0.8, 1))
		return
	var cost = float(j.get("cost", 0)) * clampf(1.0 + Stats.skill(Game.profile, "jutsu_cost"), 0.4, 1.0)
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok! [C] ile chakra topla", Color(0.5, 0.8, 1))
		return
	p.chakra -= cost
	cooldowns[jid] = float(j.get("cd", 5))
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
	# hedefe dönük kal (mühür yaparken)
	var tg = _auto_target(35.0)
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
	var dmg: float = info.get("dmg", 5.0)
	dmg *= Combat.element_mult(info.get("element", ""), Game.profile.get("elements", [""])[0])
	dmg *= Elements.on_hit(p, info)  # ıslak/yanık/donma etkileşimleri oyuncuya da işler
	if action == "guard" and atk:
		var to_atk = (atk.global_position - p.global_position)
		to_atk.y = 0
		if to_atk.normalized().dot(p.face_dir()) > -0.2 or true:
			if guard_t < 0.18:
				# mükemmel blok
				Combat.popup_text(p.global_position + Vector3.UP * 2.2, "MÜKEMMEL!", Color(0.6, 0.9, 1))
				FX.ring(p.global_position + Vector3.UP, Color(0.6, 0.9, 1), 4.0, 0.3, false)
				Sfx.play("block", p.global_position, 1.3)
				if atk.has_method("stagger"):
					atk.stagger(1.0)
				return
			dmg *= 0.2 * (1.0 - clampf(Stats.skill(Game.profile, "guard"), 0.0, 0.8))
			FX.hit_spark(p.global_position + Vector3.UP * 1.2 + p.face_dir() * 0.5, Color(0.6, 0.85, 1.0), 0.6)
			Sfx.play("block", p.global_position)
			p.velocity += info.get("dir", Vector3.ZERO) * 3.0
			p.hp -= dmg
			return
	p.hp -= dmg
	last_hit_t = 0.0
	p.model.flash(0.8)
	Combat.damage_number(p.global_position + Vector3.UP * 2.0, dmg, Color(1, 0.4, 0.35))
	Sfx.play("hurt", p.global_position)
	if Game.world:
		Game.world.env.add_shake(0.35)
	var dir: Vector3 = info.get("dir", Vector3.ZERO)
	var heavy: bool = info.get("kind", "light") != "light" or info.get("launch", 0.0) > 0.0
	t = 0.0
	if aura:
		_update_charge(0)
	if heavy:
		action = "knockdown"
		p.velocity = dir * info.get("knock", 8.0) + Vector3.UP * (info.get("launch", 0.0) + 4.0)
		p.model.play("knock", 0.05, 1.2, true)
	else:
		action = "hitstun"
		p.velocity = dir * info.get("knock", 2.0)
		p.model.play("hit" if randf() < 0.5 else "hit_head", 0.04, 1.4, true)
	p.model.overlay.set_pose("seal", 0.0)
	p.model.overlay.set_pose("guard", 0.0)
	if p.hp <= 0.0:
		p.hp = 0.0
		Progress.on_player_died()
