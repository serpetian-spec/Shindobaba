class_name PlayerCombat
extends Node
## Oyuncunun Storm tarzı dövüşü.
## Sol tık: kombo | Sağ tık (basılı): blok | Q: Kawarimi | C (basılı): chakra şarjı | R: kunai
## E/orta tık: hedefe kilitlen | Kilitliyken Shift: chakra dash | 1-6: jutsu slotları

const KEYED = preload("res://scripts/combat/keyed_combos.gd")   # elle yapılmış silah komboları (yapay zekâ da kullanır)
const COMBO := [
	{"anim": "jab", "speed": 1.5, "hit": 0.10, "dur": 0.32, "dmg": 3.6, "reach": 1.3, "lunge": 4.0, "knock": 2.0},
	{"anim": "cross", "speed": 1.5, "hit": 0.12, "dur": 0.34, "dmg": 4.2, "reach": 1.3, "lunge": 4.0, "knock": 2.0},
	{"anim": "hook", "speed": 1.6, "hit": 0.16, "dur": 0.4, "dmg": 4.8, "reach": 1.4, "lunge": 4.5, "knock": 3.0},
	{"anim": "idle", "kick": true, "speed": 1.0, "hit": 0.14, "dur": 0.38, "dmg": 5.4, "reach": 1.7, "lunge": 5.0, "knock": 4.0},
	{"anim": "hook", "speed": 1.75, "hit": 0.15, "dur": 0.38, "dmg": 5.0, "reach": 1.4, "lunge": 4.5, "knock": 3.0},
	{"anim": "slash_c", "speed": 1.4, "hit": 0.22, "dur": 0.6, "dmg": 9.0, "reach": 1.8, "lunge": 6.0, "knock": 16.0, "launch": 5.0, "heavy": true},
]
## 6 vuruşluk kombo, 5 elemanlı eski listeler (silah stili animasyonları, Samehada/Gunbai anahtarları) için indeks:
## 5. vuruş 2. vuruşun tekrarı, 6. vuruş (bitiriş) listenin sonu
static func _ci(i: int) -> int:
	return [0, 1, 2, 3, 1, 4][clampi(i, 0, 5)]

var p: Player
var step = -1
var t = 0.0          # mevcut hareketin geçen süresi
var action = ""      # "", attack, cast, throw, sub, hitstun, knockdown, guard, charge, chakra_dash
var did_hit = false
var buffered = false
var extra_done := 0
var _seal_fail := false
var cd_max := {}     # jutsu -> bu kullanımdaki toplam bekleme (hasara göre uzayabilir; HUD dolum çubuğu)
var _jdmg := {}      # jutsu -> bu kullanımda verdiği toplam hasar
var _jcast_t := {}


## Hasara göre bekleme: jutsunun bu kullanımda verdiği gerçek hasar arttıkça beklemesi uzar
## (seviye güç çarpanına bölünür: ilerledikçe tüm beklemeler şişmesin). ~800 hasar (temel güçte) -> ~60 sn.
func note_jutsu_dmg(jid: String, dmg: float) -> void:
	if not _jcast_t.has(jid):
		return
	var since = Time.get_ticks_msec() / 1000.0 - float(_jcast_t[jid])
	if since > 8.0:
		return
	_jdmg[jid] = float(_jdmg.get(jid, 0.0)) + dmg
	var want = Combat.dmg_cd(float(_jdmg[jid]), Jutsu._mult(p))
	var total = maxf(float(cd_max.get(jid, 0.0)), want)
	if total > float(cd_max.get(jid, 0.0)):
		cd_max[jid] = total
		cooldowns[jid] = maxf(float(cooldowns.get(jid, 0.0)), total - since)   # adım içindeki ek darbelerden (dönüş vb.) kaç tanesi vuruldu
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
	elif e.is_action_pressed("summon_cmd"):   # Kuchiyose komutu: Saldır -> Koru -> Bekle -> Takip
		Summon.issue_next(p)
	elif e.is_action_pressed("summon_special"):   # çağrılar imza tekniğini hemen kullanır
		Summon.order_special(p)
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
		var cc = _combo(step)
		if t > float(cc["dur"]) * (0.0 if cc.has("keys") else 0.4):   # anahtar animasyonlu kombo: her an tamponlar
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
	extra_done = 0
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
	_set_two_hand(c.get("two_hand", false), float(c.get("dur", 0.6)), float(c.get("two_off", 0.32)))
	if c.has("keys"):
		p.model.overlay.key_mass = KEYED.mass(String(c.get("keyed_id", Gear.equipped(Game.profile, "sag").get("id", ""))))
		p.model.overlay.play_keys(c["keys"], float(c.get("key_spd", 1.0)))
		if c.has("keyed_id"):
			KEYED.on_start(c["keyed_id"], int(c["keyed_i"]), p)   # sıçrama, Samehada açılıp büyüme vb.
		if int(c.get("rai", -1)) == COMBO.size() - 1:
			get_tree().create_timer(0.16).timeout.connect(func():
				if is_instance_valid(p) and action == "attack":
					var hand = p.global_position + Vector3.UP * 2.6
					VFX.bolt(hand + Vector3.UP * 12.0, hand, Color(1.0, 0.88, 0.25), 0.4, 0.3, 4)
					Sfx.play("thunder", hand, 1.3, 0.6))
	else:
		p.model.overlay.stop_keys()
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
	var c = float(j.get("cost", 0)) * (1.0 + (lv - 1) * 0.045) * clampf(1.0 + Stats.skill(Game.profile, "jutsu_cost"), 0.7, 1.0)
	# nakil Senju hücresi: beden yabancı hücreyle savaşır, Mokuton daha çok chakra yer (Senju kanında yok)
	if "mokuton" in j.get("elements", []) and Game.profile.get("flags", {}).get("senju_cells", false) and String(Game.profile.get("clan", "")) != "senju":
		c *= KgPaths.LAB_COST_MULT
	return c


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
	for k in tool_cd.keys():   # alet bekleme süreleri
		tool_cd[k] = maxf(0.0, float(tool_cd[k]) - dt)
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
			elif dist > c["reach"] * 0.8 and float(c["lunge"]) > 0.0:   # lunge 0: yerinde (Samehada dönüşü kaymasın)
				lunge = minf(9.0, dist / maxf(0.05, c["hit"] - t) * 0.9)
			else:
				lunge = 0.0
		var rv0: Vector3 = p.model.overlay.root_vel if (tgt == null or tgt.global_position.distance_to(p.global_position) - tgt.radius - p.radius > 0.9) else Vector3.ZERO   # hedefe değince adım durur (içinden geçmesin)
		var v = p.face_dir() * lunge + rv0   # adımla ilerleme: basan ayak yerinde kalır
		p.velocity.x = v.x; p.velocity.z = v.z
	else:
		var rv: Vector3 = p.model.overlay.root_vel
		if tgt and tgt.global_position.distance_to(p.global_position) - tgt.radius - p.radius < 0.9:
			rv = Vector3.ZERO
		if rv.length() > 0.05:
			p.velocity.x = rv.x; p.velocity.z = rv.z
		else:
			p.velocity.x = move_toward(p.velocity.x, 0, dt * 60); p.velocity.z = move_toward(p.velocity.z, 0, dt * 60)
	p.velocity.y -= Player.GRAV * dt
	if not did_hit and t >= c["hit"] and c.has("chain_kind"):
		did_hit = true
		_chain_strike(c, tgt)
	# ek darbeler (Samehada dönüşü): karakterin çevresinde, savrulmasız hafif vuruş
	var xh: Array = c.get("extra_hits", [])
	while extra_done < xh.size() and t >= float(xh[extra_done]):
		extra_done += 1
		var xi = _hit_info(c)
		xi["dmg"] = float(xi["dmg"]) * 0.35
		xi["launch"] = 0.0
		xi["knock"] = 1.0
		xi["hitstop"] = 0.03
		xi["kind"] = "light"   # dönüş darbeleri yere sermez (sermek son fırlatmayı boşa çıkarıyordu)
		var xc = p.global_position + Vector3.UP * 0.9
		var xhits = Combat.hit_sphere(p, xc, float(c.get("extra_radius", 2.5)), xi)
		for h in xhits:
			_on_hit_fx(h.global_position + Vector3.UP, c)
			Progress.on_hit_landed(h)
			_special_hit(h, h.global_position + Vector3.UP, c)
	if not did_hit and t >= c["hit"]:
		did_hit = true
		var pt = p.global_position + Vector3.UP * 1.1 + p.face_dir() * (p.radius + c["reach"] * 0.6)
		if c.get("gust", false):
			_gunbai_gust(_ci(step))
		if c.has("rai"):
			_raijin_fx(int(c["rai"]), pt)
		if c.has("keyed_id"):
			KEYED.on_strike(c["keyed_id"], int(c["keyed_i"]), p, float(c["dmg"]) * Stats.melee_mult(Game.profile))   # zemin/patlama/uçan kâğıt
		var hits = Combat.hit_sphere(p, pt, c["reach"] * 0.65 * Buffs.mod("reach"), _hit_info(c))
		if not hits.is_empty() and c.has("keyed_id") and step == COMBO.size() - 1:
			VFX.slowmo(0.3, 0.22)   # bitiriş isabeti: kısa ağır çekim + sert sarsıntı
			if Game.world:
				Game.world.env.add_shake(0.7)
		if not hits.is_empty():
			_on_hit_fx(pt, c)
			var armed_m = String(Gear.weapon(Game.profile).get("style", "fist")) != "fist" and bool(Game.profile.get("weapon_drawn", false))
			Mastery.gain(Game.profile, "kenjutsu" if armed_m else "taijutsu", 0.02 * hits.size())
			for h in hits:
				Progress.on_hit_landed(h)
				_special_hit(h, pt, c)
				if c.has("keyed_id"):
					KEYED.on_target(c["keyed_id"], int(c["keyed_i"]), p, h)   # kanca çekişi vb.
	if t >= c["dur"]:
		p.model.overlay.set_pose("kick", 0.0)
		combo_reset = 0.5
		if buffered and step < COMBO.size() - 1:
			step += 1
			_start_step()
		else:
			action = ""
			p.model.overlay.stop_keys()
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


## Silaha özel kombolar (kaynak: Kisame Storm moveset videosu) — stil kombosunun yerine geçer
## Samehada (Kisame Storm videosu 0:00-0:04, saniyede 10 kare): 1 öne atılıp yatay tutup iterek delme (chakra emme girdabı),
## 2 başın arkasına kaldırıp aşağı-öne savurma, 3 sola alıp sağa alçak yatay savurma, 4 tepeye kaldırıp baş hizasında sert vuruş,
## 5 dönerek alçaktan savurup yukarı fırlatma
const ID_COMBOS := {
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
	# her silahın kendi vuruş hasarı (hit); kombo adımları yumruk kombosunun oranlarıyla (4.2 = yumruğun ortalama vuruşu)
	var per_hit = float(w.get("hit", 4.2))
	c["dmg"] = per_hit * float(c["dmg"]) / 4.2 * (1.0 + Stats.weapon_bonus(Game.profile, String(w.get("style", "fist"))) * 0.6)
	c["reach"] = float(c["reach"]) + float(w["reach"])
	var st: Dictionary = STYLE_COMBOS.get(w["style"], {})
	var wid = ""
	var gq = Gear.equipped(Game.profile, "sag")
	if not gq.is_empty():
		wid = String(gq.get("id", ""))
	if ID_COMBOS.has(wid):
		st = ID_COMBOS[wid]
		c["water"] = st["water"][_ci(i)]
		c["water_big"] = false
		c["two_hand"] = st.get("two_hand", [false, false, false, false, false])[_ci(i)]
		c["grind"] = st.get("grind", [false, false, false, false, false])[_ci(i)]
		c["flash"] = st.get("flash", [false, false, false, false, false])[_ci(i)]
		if st.has("lunge"):
			c["lunge"] = float(c.get("lunge", 1.0)) * float(st["lunge"][_ci(i)])
	if st.is_empty():
		return c
	var an: String = st["anims"][_ci(i)]
	if an != "":
		c["anim"] = an
		c["kick"] = false
		c["speed"] = float(st["speed"]) * (0.85 if i == COMBO.size() - 1 else 1.0)
	c["dur"] = float(c["dur"]) * float(st["dur"])
	c["hit"] = float(c["hit"]) * float(st["dur"])
	c["knock"] = float(c["knock"]) * float(st["knock"])
	c["fx"] = st["fx"]
	c["snd"] = st["snd"]
	if w["style"] == "heavy" and i == COMBO.size() - 1:
		c["launch"] = 8.0
	if w["style"] == "chain" and not KEYED.has(wid):
		# kusarigama: orta menzil — orak zincirle fırlar, savrulur, çeker, döner; oyuncu hedefe atılmaz
		c["chain_kind"] = ["throw", "sweep", "reel", "throw", "spin"][_ci(i)]
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
		"drain":
			c["drain"] = true
	if KEYED.has(wid):
		# el yapımı anahtar animasyon (Samehada: videodan; Gunbai/Kunai: kendine anlatılmış tarif): süre/vuruş anı anahtarlardan
		var kst: Array = KEYED.steps(wid)
		var ks: Dictionary = kst[clampi(i, 0, 5)] if kst.size() >= 6 else kst[_ci(i)]
		c["keys"] = ks
		c["anim"] = "idle"
		c["speed"] = 1.0
		var ksp = KEYED.speed(wid)
		c["key_spd"] = ksp
		c["dur"] = float(ks["len"]) / ksp
		c["hit"] = float(ks["hit"]) / ksp
		if ks.has("extra_hits"):
			c["extra_hits"] = (ks["extra_hits"] as Array).map(func(x): return float(x) / ksp)
			c["extra_radius"] = ks.get("extra_radius", 2.5)
		if wid == "gunbai":
			c["gust"] = true
			if _ci(i) == 3:
				c["dmg"] = float(c["dmg"]) * 0.5   # kalkan: hafif itiş
				c["knock"] = 4.0
			elif i == COMBO.size() - 1:
				c["knock"] = 22.0   # Uchiha Gaeshi: düz geri savrulur (havaya değil)
		if wid == "raijin":
			c["rai"] = i
			c["fx"] = Color(1.0, 0.85, 0.2)   # sarı şimşek
			if i == COMBO.size() - 1:
				c["knock"] = 12.0
				c["heavy"] = true
		# adım değiştiricileri + vuruş anı etkileri ORTAK (KeyedCombos.mods/on_strike/on_target): düşman da aynısını kullanır
		var km: Dictionary = KEYED.mods(wid, i)
		if not km.is_empty() or ks.has("two"):
			c["two_hand"] = bool(ks.get("two", false))
			c["two_off"] = KEYED.two_off(wid)
			c["keyed_id"] = wid
			c["keyed_i"] = i
			c["lunge"] = float(c["lunge"]) * float(km.get("lunge_mul", 1.0))
			for mk in ["heavy", "knock", "launch", "stun", "special", "element"]:
				if km.has(mk):
					c[mk] = km[mk]
			c["reach"] = float(c["reach"]) + float(km.get("reach_add", 0.0))
		if wid == "kunai" and i == COMBO.size() - 1:
			c["knock"] = 9.0   # bitiriş biçmesi rakibi geri savurur
	return c


## Efsanevi silah yetenekleri: vuruş bilgisine eklenenler
func _special_info(info: Dictionary, c: Dictionary) -> Dictionary:
	if float(c.get("stun", 0.0)) > 0.0:
		info["stun"] = float(c["stun"])   # tırpan yere saplama: sersemletir
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
			# Samehada: düşmanın chakrasını emer — düşmandan eksilir, sana geçer
			var took = 6.0
			if "chakra" in h:
				took = minf(6.0, maxf(0.0, float(h.chakra)))
				h.chakra = maxf(0.0, float(h.chakra) - 6.0)
			p.chakra = minf(p.max_chakra, p.chakra + maxf(took, 3.0))
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
			FX.hit_spark(pt, Color(1.0, 0.85, 0.2), 1.4)
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
	if c.get("water", false):   # Samehada bitiriş: yere çakma — etrafa su kubbesi + sprey (videodaki gibi)
		var gp = Vector3(pt.x, Game.jutsu_floor(pt.x, pt.z), pt.z)
		WaterArt.splash(gp, 2.6 if c.get("water_big", false) else 1.6)
		if c.get("water_big", false):
			WaterArt.dome(gp, 4.5)
	if c.get("grind", false):   # Samehada itip delme: dönen mavi chakra girdabı (videodaki gibi)
		for k in 3:
			var ang = k * TAU / 3.0
			WindFX.streak(func(q: float) -> Vector3: return pt + Vector3(cos(ang + q * 6.0), sin(ang + q * 6.0), 0).rotated(Vector3.UP, p.facing) * (0.4 + q * 0.7), 0.3, 0.06, Color(0.55, 0.9, 1.0), k * 0.03, 10)
	if c.get("flash", false):   # baş hizasında sert vuruş: büyük beyaz çarpma flaşı
		VFX.star(pt, Color(1, 1, 1), 3.2, 0.2)
		if Game.world:
			Game.world.env.add_shake(0.6)
	if c.get("drain", false):   # Samehada chakra emer: hedeften kullanıcıya mavi chakra (miktar _special_hit'te)
		FX.burst(pt, {"amount": 10, "life": 0.4, "tex": FX.tex_spark, "size": 0.5, "vmin": 2, "vmax": 5, "colors": [Color(0.8, 0.95, 1.0, 1), Color(0.35, 0.65, 1.0, 0.8), Color(0.3, 0.6, 1.0, 0)]})
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
	if want and action == "charge":
		Mastery.gain(Game.profile, "chakra", dt * 0.01)   # meditasyon / chakra toplama antrenmanı
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


## Raijin Kılıcı: her vuruşta ağızdan şimşek çatırtısı; saplamada ağız şimşek olarak ileri uzar; bitirişte gökten yıldırım çakar
func _raijin_fx(i: int, pt: Vector3) -> void:
	var col = Color(1.0, 0.88, 0.25)
	var dir = p.face_dir()
	var tip = p.global_position + Vector3.UP * 1.1 + dir * 1.2
	match i:
		3:
			VFX.bolt(tip, tip + dir * 3.2 + Vector3.UP * 0.1, col, 0.22, 0.25, 4)   # chakra ağzı uzar
			Combat.hit_zone(p, p.global_position, dir, 4.5, 12.0, 2.0, {"dmg": 3.0 * Stats.melee_mult(Game.profile), "knock": 3.0, "kind": "light", "element": "raiton", "melee": true})
		5:
			VFX.bolt(pt + Vector3.UP * 14.0, pt + Vector3.DOWN * 1.0, col, 0.55, 0.35, 5)
			VFX.cracks(Vector3(pt.x, p.global_position.y, pt.z), 3.0)
			if Game.world:
				Game.world.env.add_shake(0.5)
				Game.world.env.screen_flash(0.06)
			Sfx.play("thunder", pt, 1.1)
		_:
			for k in 2:
				VFX.bolt(pt, pt + Vector3(randf_range(-0.8, 0.8), randf_range(-0.4, 0.8), randf_range(-0.8, 0.8)), col, 0.08, 0.15, 1)
	Sfx.play("chidori", pt, 1.6, 0.35)


## Gunbai vuruş efektleri (rüzgâr savurma yok — ağır başlı sopa/kalkan): kenar yarması, yüz tokadı, saplama, emme, Uchiha Gaeshi
func _gunbai_gust(i: int) -> void:
	var dir = p.face_dir()
	var o = p.global_position + Vector3.UP * 1.1
	match i:
		0:
			VFX.debris(p.global_position + dir * 1.8, Color(0.55, 0.47, 0.36), 6, 5.0, 0.2)   # kenar yere sürtüp toprak sıçratır
			if Game.world:
				Game.world.env.add_shake(0.25)
		1:
			FX.ring(o + dir * 1.6, Color(0.95, 0.95, 1.0), 2.2, 0.18)   # yassı yüz çarpması: kısa basınç halkası
		2:
			FX.speed_lines(o, dir)
		3:
			# emme: yüzde kırmızı-turuncu chakra toplanır
			VFX.gather(o + dir * 1.4 + Vector3.UP * 0.6, Color(1.0, 0.45, 0.2), 1.1)
			Sfx.play("charge", o, 0.8, 0.6)
		4:
			# Uchiha Gaeshi: emilen enerji yüzden ateşli dalga olarak düz ileri patlar
			var f = o + dir * 1.8 + Vector3.UP * 0.3
			var side = dir.cross(Vector3.UP).normalized()
			for k in 5:
				var a = (k - 2) * 0.32
				var d2 = (dir * cos(a) + side * sin(a)).normalized()
				var fb = VFX.fireball(1.1 + 0.25 * (2 - absi(k - 2)))
				VFX.scene().add_child(fb)
				fb.global_position = f + d2 * 0.4
				fb.scale = Vector3.ONE * 0.25
				var tw = fb.create_tween().set_parallel(true)
				tw.tween_property(fb, "global_position", f + d2 * (7.0 + 2.0 * (2 - absi(k - 2))) + Vector3.UP * 0.6, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(k % 2 * 0.04)
				tw.tween_property(fb, "scale", Vector3.ONE * 1.25, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tw.chain().tween_property(fb, "scale", Vector3.ONE * 0.05, 0.25).set_ease(Tween.EASE_IN)
				tw.chain().tween_callback(fb.queue_free)
			VFX.embers(f, Color(1.0, 0.55, 0.12), 22, 12.0)
			Sfx.play("fire", f, 1.0, 1.2)
			# alev hattındakilere yanık (düz geri savrulma vuruşun kendisinde)
			Combat.hit_zone(p, p.global_position, dir, 9.0, 40.0, 3.0, {"dmg": 4.0 * Stats.melee_mult(Game.profile), "knock": 2.0, "kind": "light", "element": "katon", "burn": 2.0})
			if Game.world:
				Game.world.env.add_shake(0.5)
				Game.world.env.screen_flash(0.05)


## İki elle tutuş (videoda Kisame'nin iki elle savurduğu adımlar): sol el sağdaki silahın sapına IK ile uzanır
func _set_two_hand(on: bool, dur: float, off := 0.32) -> void:
	var m = p.model
	if m == null or m.get("rig") == null:
		return
	var rig: WeaponRig = m.rig
	rig.two_hand_off = off   # sol elin sağ yumruktan sap boyunca uzaklığı (tırpan 0.42)
	var wn: Node3D = null
	for w in m.weapons:
		if w["side"] == "Right" and is_instance_valid(w["node"]) and w["node"].get_parent() == w["hand"]:
			wn = w["node"]
	rig.two_hand_node = wn
	var tw = m.create_tween()
	tw.tween_property(rig, "two_hand_w", 1.0 if (on and wn) else 0.0, 0.08)
	if on and wn:
		tw.tween_interval(maxf(0.1, dur - 0.15))
		tw.tween_property(rig, "two_hand_w", 0.0, 0.12)


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
	dest = safe_dest(p, from, dest)
	p.global_position = dest
	p.velocity = Vector3.ZERO
	action = ""
	invuln = 0.5
	FX.smoke_puff(dest + Vector3.UP * 0.9, 0.7, 10)
	Progress.on_technique_used("kawarimi")


## Işınlanma/kaçış varışı: duvarın içinden geçmez (önünde durur), zemin iç mekânda oda zemini (Chūnin kulesi, mağara inleri
## dünyanın üstünde kurulu: arazi yüksekliği oyuncuyu odanın altına, dışarı düşürüyordu). Düşmanlar da aynı yardımcıyı kullanır.
static func safe_dest(body: Node3D, from: Vector3, dest: Vector3) -> Vector3:
	var space = body.get_world_3d().direct_space_state
	var ex = [body.get_rid()] if body is CollisionObject3D else []
	var a = from + Vector3.UP * 1.0
	var b = Vector3(dest.x, from.y + 1.0, dest.z)
	var hw = space.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1, ex))
	if not hw.is_empty():
		var dirv = (b - a)
		dirv.y = 0
		var back = hw["position"] - dirv.normalized() * 0.6
		dest = Vector3(back.x, dest.y, back.z)
	var top = Vector3(dest.x, from.y + 2.5, dest.z)
	var hf = space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 12.0, 1, ex))
	if not hf.is_empty():
		dest.y = float(hf["position"].y) + 0.05
	elif Interiors.inst and Interiors.inst.inside != "":
		return Vector3(from.x, from.y, from.z)   # odada zemin bulunamadı (duvar dışı/boşluk): yerinde kal, asla araziye düşme
	else:
		dest.y = Game.jutsu_floor(dest.x, dest.z) + 0.1
	return dest


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


# ------------------------------------------------------------------ kunai/shuriken/tuzaklar
## Fırlatılan aletler (kunai, shuriken, senbon, etiketli kunai, makibishi, duman): pazardan BİR KEZ alınır, sonra sınırsız;
## her aletin kendi bekleme süresi var (TOOL_CD sn). Düşmanlar da aynı kurala tabi (Enemy.tool_cd).
const TOOL_CD := 30.0
var tool_cd := {}   # alet -> kalan bekleme (sn)


static func tool_owned(id: String) -> bool:
	return int(Game.profile.get("inventory", {}).get(id, 0)) > 0


func throw_tool() -> void:
	_break_henge()
	if action != "" and action != "guard":
		return
	var tool: String = Game.profile.get("throw_sel", "kunai")
	if not tool_owned(tool):
		Hud.msg("%s sende yok — pazardan bir kez al, sonra sınırsız." % Data.items.get(tool, {"name": tool})["name"], Color(1, 0.6, 0.5))
		return
	if float(tool_cd.get(tool, 0.0)) > 0.0:
		Hud.msg("%s hazır değil: %d sn" % [Data.items.get(tool, {"name": tool})["name"], ceili(float(tool_cd[tool]))], Color(1, 0.75, 0.5))
		return
	tool_cd[tool] = TOOL_CD / (1.0 + Mastery.get_v(Game.profile, "shurikenjutsu") / 50.0)   # shurikenjutsu ustalığı: alet daha çabuk hazır
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
		Mastery.gain(Game.profile, "shurikenjutsu", 0.01)   # atış: shurikenjutsu
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
	# Jūken ile tenketsu kapatıldıysa chakra yoğrulamaz: yalnız taijutsu (düşmanla aynı kural)
	if p.has_status("sealed") and String(j.get("category", "")) != "taijutsu":
		Hud.msg("Chakra noktaların kapalı: şimdilik yalnız taijutsu yapabilirsin.", Color(0.6, 0.8, 1.0))
		return
	# dōjutsu teknikleri: göz açık olmadan yapılamaz (V)
	if String(j.get("learn", "")).begins_with("eye:") and not String(j.get("learn", "")).ends_with("susanoo"):
		var ey = modes.eyes if modes else null
		if ey == null or not ey.active:
			Hud.msg("%s için önce gözlerini aç (V)." % String(j["name"]).split(" (")[0], Color(1, 0.55, 0.5))
			return
		# tekniğin gözü takılı olmalı (en az bir göz): Rinnegan tekniği Eternal Mangekyō ile atılmaz
		var ek = String(j.get("learn", "")).substr(4)
		if Progress.EYE_KINDS.has(ek) and not Progress.has_eye(ek):
			Hud.msg("%s için en az bir gözün %s olmalı." % [String(j["name"]).split(" (")[0], {"rinnegan": "Rinnegan", "ems": "Eternal Mangekyō", "mangekyo": "Mangekyō", "sharingan": "Sharingan", "byakugan": "Byakugan", "tenseigan": "Tenseigan", "jogan": "Jōgan", "ketsuryugan": "Ketsuryūgan"}.get(ek, ek)], Color(1, 0.55, 0.5))
			return
	# Susanoo teknikleri gerçek Susanoo ile yapılır: Susanoo (yeterli kademede) açılabilmeli
	if Susanoo.need_tier(jid) > 0:
		var sg = Susanoo.gate_msg(jid, String(j["name"]))
		var ey2 = modes.eyes if modes else null
		if sg == "" and ey2 and not ey2.susanoo and ey2.blind() >= 1.0 and not (ey2._kind("sag") == 5 or ey2._kind("sol") == 5):
			sg = "Gözlerin kör: Susanoo'yu çağıramıyorsun."
		if sg != "":
			Hud.msg(sg, Color(1, 0.55, 0.5))
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
	if need.begins_with("contract:") and not Contracts.signed(need.substr(9)):   # kanon: çağrı hayvanının tekniği (Enma -> Kongōnyoi)
		Hud.msg("%s için %s gerekir." % [String(j["name"]), String(Contracts.DEFS.get(need.substr(9), {}).get("name", need.substr(9)))], Color(1, 0.75, 0.45))
		return
	if need.begins_with("weapon:") and not need.substr(7) in Gear.held_ids(Game.profile):   # kılıca özgü teknik
		Hud.msg("%s için %s kuşanmalısın." % [String(j["name"]), String(Gear.item(need.substr(7)).get("name", need.substr(7)))], Color(1, 0.75, 0.45))
		return
	if need == "islak_zemin":
		var tgj = _cast_target()
		var gpos: Vector3 = tgj.global_position if tgj else p.aim_point(40.0)
		if not ClanMech.prepared_ground(gpos):
			Hud.msg("%s için zemini hazırla: toprağı kır (Doton) ve su ekle (Suiton) — ya da çamur/su başında kullan." % String(j["name"]), Color(0.7, 0.85, 0.5))
			return
	if need == "sototoro" and not (Buffs.has("sototoro") or Buffs.has("santoro")):   # kanon: ninkenle birleşik kurt biçiminde
		Hud.msg("%s yalnız Sōtōrō (ya da Santōrō) biçimindeyken yapılır." % String(j["name"]), Color(0.9, 0.9, 0.95))
		return
	if need == "santoro" and not Buffs.has("santoro"):
		Hud.msg("%s yalnız Santōrō (üç başlı kurt) biçimindeyken yapılır." % String(j["name"]), Color(0.9, 0.9, 0.95))
		return
	if need == "senninka" and not (Buffs.has("jugo_senninka") or Buffs.has("jugo_senninka2")):   # kanon: Jūgo bu biçimleri Senninka ile alır
		Hud.msg("%s için önce Senninka ile bedenini dönüştürmelisin." % String(j["name"]), Color(0.75, 0.9, 0.6))
		return
	if need == "senninka2" and not Buffs.has("jugo_senninka2"):
		Hud.msg("%s Senninka'nın ikinci aşamasında yapılır (dönüşümdeyken Senninka'yı yeniden kullan)." % String(j["name"]), Color(0.75, 0.9, 0.6))
		return
	if need == "raiton_modo" and not Buffs.has("raiton_chakura_modo"):   # kanon: Raikage nintaijutsusu yalnız Raiton Chakra Modu'ndayken
		Hud.msg("%s yalnız Raiton Chakra Modu'ndayken yapılır." % String(j["name"]), Color(0.75, 0.88, 1.0))
		return
	if need == "juin2" and not Buffs.has("juin2"):   # kanon: Kimimaro yalnız lanet mührünün ikinci aşamasında
		Hud.msg("%s için Lanetli Mühür'ün ikinci aşamasında olmalısın." % String(j["name"]), Color(0.85, 0.55, 1.0))
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
	# klan kuralı: Akimichi kalorisi, Aburame kikaichū kolonisi, Inuzuka ortak teknikleri köpekle
	var cm_block = ClanMech.cast_block(jid, j)
	if cm_block != "" and not Game.has_meta("sandbox"):
		Hud.msg(cm_block, Color(1, 0.75, 0.45))
		return
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok! [C] ile chakra topla", Color(0.5, 0.8, 1))
		return
	# ninjutsu ustalığı: yetersizse teknik yapılamaz; sınırdaysa mühür bozulabilir (yaptıkça gelişme)
	var mc = "" if Game.has_meta("sandbox") else Mastery.cast_check(Game.profile, j)
	if mc != "" and not mc.begins_with("fail:"):
		Hud.msg(mc, Color(1, 0.55, 0.45))
		return
	_seal_fail = mc.begins_with("fail:") and randf() < float(mc.substr(5))
	p.chakra -= cost
	ClanMech.pay(jid, j)
	cooldowns[jid] = Combat.jutsu_cd(j)
	cd_max[jid] = cooldowns[jid]
	_jdmg[jid] = 0.0
	_jcast_t[jid] = Time.get_ticks_msec() / 1000.0
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
		var jd: Dictionary = Data.jutsu.get(cast_jutsu, {})
		if _seal_fail:
			# mühür bozuldu: chakra boşa gider, teknik çıkmaz (yine de biraz öğrenilir)
			_seal_fail = false
			FX.smoke_puff(p.global_position + Vector3.UP * 1.3 + p.face_dir() * 0.4, 0.35, 5)
			Combat.popup_text(p.global_position + Vector3.UP * 2.3, "Mühür bozuldu!", Color(1, 0.6, 0.4))
			cooldowns[cast_jutsu] = minf(float(cooldowns.get(cast_jutsu, 0.0)), 2.0)
			Mastery.gain(Game.profile, Mastery.branch_of(jd), 0.1 * (1.0 + int(jd.get("tier", 2)) * 0.3))
			return true
		var br = Mastery.branch_of(jd)   # teknik kendi dalını geliştirir (genjutsu, fūinjutsu, tıbbi...)
		Mastery.gain(Game.profile, br, 0.3 * (1.0 + int(jd.get("tier", 2)) * 0.35))   # temel teknikler (Henge) de hissedilir ilerletir: ~20 Henge -> Bunshin
		if br != "ninjutsu" and br != "taijutsu" and br != "kenjutsu":
			Mastery.gain(Game.profile, "ninjutsu", 0.06)   # chakra şekillendirme ortak temel
		Mastery.gain(Game.profile, "chakra", jutsu_cost(jd) / 360.0)
		Jutsu.execute(p, cast_jutsu, tg)
		Progress.on_technique_used(cast_jutsu)
	return true


# ------------------------------------------------------------------ hasar alma
func take_hit(info: Dictionary) -> void:
	if invuln > 0.0 or p.hp <= 0.0:
		return
	if modes and modes.on_player_hit(info):
		return
	ClanMech.on_player_hit(info)
	Jutsu.kurama_ido_check(p)   # Kurama: can düşünce Ido uyanabilir
	if p.has_meta("shintenshin_t"):   # boş bedene darbe: Yamanaka'nın ruhu bedene geri çekilir
		Combat.popup_text(p.global_position + Vector3.UP * 2.4, "Ruh bedene döndü!", Color(0.8, 0.65, 1))
		Jutsu.shintenshin_release(p, p.get_meta("shintenshin_t"))
	var atk: Node3D = info.get("attacker")
	var dmg: float = info.get("dmg", 5.0) * Combat.jutsu_factor(info)
	dmg *= Combat.element_mult(info.get("element", ""), Game.profile.get("elements", [""])[0])
	dmg *= 1.0 - Gear.elem_resist(p, String(info.get("element", "")))   # kıyafet seti element direnci
	dmg *= Elements.on_hit(p, info)  # ıslak/yanık/donma etkileşimleri oyuncuya da işler
	if action == "guard" and atk and is_instance_valid(atk):
		var to_atk = (atk.global_position - p.global_position)
		to_atk.y = 0
		# yalnız önden (yandan/arkadan gelen darbe bloğu geçer); açık Byakugan neredeyse 360° görür — tek kör nokta ensenin arkası
		var byaku = modes and modes.eyes and modes.eyes.active and Progress.has_eye("byakugan")
		var fdot = to_atk.normalized().dot(p.face_dir()) if to_atk.length() >= 0.3 else 1.0
		if fdot > 0.1 or (byaku and fdot > -0.9):
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
					if not ClanMech.try_extra_life():
						Progress.on_player_died()
				return
	p.hp -= dmg
	Combat.note_jutsu_dmg(atk, info, dmg)
	if p.hp <= 0.0:
		# ölüm kontrolü hemen burada: aşağıdaki düz vuruş / hafif darbe dalları erken dönüyordu, ölümcül darbede
		# ölüm işlenmiyor, Kakuzu kalpleri / İzanagi de devreye girmiyordu
		p.hp = 0.0
		Combat.damage_number(p.global_position + Vector3.UP * 2.0, dmg, Color(1, 0.4, 0.35))
		if not ClanMech.try_extra_life():
			Progress.on_player_died()
		return
	Mastery.gain(Game.profile, "dayaniklilik", clampf(dmg / maxf(1.0, p.max_hp), 0.0, 0.5) * 0.4)   # dayak yedikçe dayanıklılık
	last_hit_t = 0.0
	# Jashin laneti: çemberdeyken sana gelen acı bağlı hedefe de gelir
	if p.has_meta("jashin_link"):
		var lk: Array = p.get_meta("jashin_link")
		if Time.get_ticks_msec() > int(lk[1]) or not is_instance_valid(lk[0]) or lk[0].get("dead") == true:
			p.remove_meta("jashin_link")
		else:
			lk[0].take_hit({"dmg": dmg, "kind": "light", "knock": 0.0, "attacker": p, "no_link": true})
			VFX.debris(lk[0].global_position + Vector3.UP * 1.2, Color(0.7, 0.05, 0.05), 6, 4.0, 0.2)
	p.model.flash(0.8)
	var hdir: Vector3 = info.get("dir", Vector3.ZERO)
	var hheavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	p.model.react(hdir, clampf(dmg / maxf(1.0, p.max_hp) * 7.0, 0.55, 1.0) * (1.3 if hheavy else 1.0), randf() < 0.35, clampf(float(info.get("launch", 0.0)) / 10.0, 0.0, 1.0), 1.0 if hheavy else 0.0)
	if dmg >= 1.0 and not info.get("no_blood", false) and String(info.get("element", "")) not in ["katon", "raiton"]:
		FX.blood(p.global_position + Vector3.UP * 1.1, hdir, clampf(dmg / maxf(1.0, p.max_hp) * 5.0, 0.3, 1.0))
	Combat.damage_number(p.global_position + Vector3.UP * 2.0, dmg, Color(1, 0.4, 0.35))
	Sfx.play("hurt", p.global_position)
	if Game.world:
		Game.world.env.add_shake(0.35)
	var dir: Vector3 = info.get("dir", Vector3.ZERO)
	# yere serilme yalnız gerçekten ağır darbede / havaya fırlatmada (her jutsu isabeti yere sermesin)
	var heavy: bool = info.get("kind", "light") == "heavy" or info.get("launch", 0.0) > 0.0
	# düz vuruş = jutsu olmayan her darbe (yakın dövüş, canavar/klon/bekçi vuruşu, boss taijutsusu): ağır olsa bile yere düşürmez,
	# sersemletmez; yalnız silahın havaya fırlatan bitişi (launch >= 8) düşürür
	var basic: bool = info.get("melee", false) or (not info.has("tier") and String(info.get("element", "")) == "" and float(info.get("stun", 0.0)) <= 0.0)
	if basic and float(info.get("launch", 0.0)) < 8.0:
		heavy = false
		info = info.duplicate()
		info["melee"] = true
	if not heavy and float(info.get("knock", 2.0)) <= 0.5 and float(info.get("stun", 0.0)) <= 0.0:
		return
	if info.get("melee", false) and not heavy:
		# düz vuruşla stun yok (kullanıcı kuralı): hasar + küçük itme, saldırı/hareket kesilmez
		p.velocity += dir * float(info.get("knock", 2.0)) * 0.25
		return
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
	if heavy and Combat.knocks_down(info):
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
		if not ClanMech.try_extra_life():
			Progress.on_player_died()
