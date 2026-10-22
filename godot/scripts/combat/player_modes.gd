class_name PlayerModes
extends Node
## Oyuncunun özel modları: Dōjutsu (V), Sekiz Kapı (B), Sennin Modu (Z), Kuyruklu Canavar (X),
## Baika boyutu, Suika (su beden) ve mühür örme modu (G basılı + 1..9,0,-,=).

const SEAL_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]

var c: PlayerCombat
var p: Player
var dojutsu = false   # eski alan (Eyes.active ile senkron)
var eyes: Eyes
var gates = 0
var sage = false
var sage_t = 0.0
var beast = false
var beast_t = 0.0
var beast_cd = 0.0
var size = 1.0
var size_t = 0.0
var seal_mode = false
var seal_seq: Array = []
var auras := {}
var markers := {}
var marker_t = 0.0
var training = false
var training_t = 0.0
var base_radius = 0.38
var base_height = 1.8


func setup(combat: PlayerCombat) -> void:
	c = combat
	p = combat.p
	base_radius = p.radius
	base_height = p.height
	Progress.clan_unlocks.call_deferred(false)
	eyes = Eyes.new()
	eyes.name = "Eyes"
	add_child(eyes)
	eyes.setup.call_deferred(combat)


func clan() -> String:
	return Game.profile.get("clan", "none")


# ------------------------------------------------------------------ girdi (PlayerCombat'tan çağrılır)
## true dönerse girdi tüketilmiştir
func handle_input(e: InputEvent) -> bool:
	if e.is_action_pressed("seal_mode"):
		seal_mode = true
		seal_seq.clear()
		Hud.msg("MÜHÜR MODU: 1-9, 0, -, = ile mühür yap, G'yi bırakınca jutsu", Color(1, 0.9, 0.6), 2.0)
		return true
	if e.is_action_released("seal_mode") and seal_mode:
		seal_mode = false
		_finish_seals()
		return true
	if seal_mode:
		if e is InputEventKey and e.pressed and not e.echo:
			var i = SEAL_KEYS.find(e.physical_keycode)
			if i >= 0 and i < Data.seals.size():
				seal_seq.append(Data.seals[i])
				Sfx.play("seal", p.global_position, 1.0 + seal_seq.size() * 0.04)
				p.model.overlay.set_pose("seal", 1.0)
				Hud.msg("Mühürler: " + " - ".join(seal_seq), Color(1, 0.9, 0.7), 2.0)
				return true
		return e is InputEventKey
	if eyes and eyes.handle_input(e):
		dojutsu = eyes.active
		return true
	if e.is_action_pressed("gates"):
		next_gate()
		return true
	if e.is_action_pressed("sage"):
		toggle_sage()
		return true
	if e.is_action_pressed("beast"):
		beast_key()
		return true
	return false


# ------------------------------------------------------------------ mühür örme
func _finish_seals() -> void:
	p.model.overlay.set_pose("seal", 0.0)
	if seal_seq.is_empty():
		return
	var pr = Game.profile
	var found = ""
	var learnable = ""
	for jid in Data.jutsu.keys():
		if jid.begins_with("_"):
			continue
		var j: Dictionary = Data.jutsu[jid]
		if j.get("seals", []) == seal_seq:
			if jid in pr["learned"]:
				found = jid
				break
			elif learnable == "" and _can_discover(j):
				learnable = jid
	if found != "":
		var cost = float(Data.jutsu[found].get("cost", 0)) * 0.7
		if p.chakra < cost:
			Hud.msg("Yeterli chakra yok!", Color(0.5, 0.8, 1))
			return
		p.chakra -= cost
		Hud.msg("Kusursuz mühürler! %s (-%%30 chakra)" % Data.jutsu[found]["name"], Color(1, 0.85, 0.5))
		c.cast_jutsu = found
		Jutsu.execute(p, found, c._auto_target(35.0))
		p.model.play("cast_out", 0.05, 1.4, true)
		Progress.on_technique_used(found)
	elif learnable != "":
		Hud.banner("YENİ JUTSU KEŞFETTİN!", Data.jutsu[learnable]["name"], Color(0.6, 1, 0.7))
		Progress.learn(learnable, false)
	else:
		Hud.msg("Mühürler bir şey oluşturmadı... (%s)" % " - ".join(seal_seq), Color(0.8, 0.8, 0.8))
	seal_seq.clear()


func _can_discover(j: Dictionary) -> bool:
	var pr = Game.profile
	if int(pr["level"]) < int(j.get("level", 1)) or int(pr["rank"]) < int(j.get("rank", 0)):
		return false
	if j.get("clan", "") != "" and j["clan"] != pr.get("clan", ""):
		return false
	var el = j.get("element", "")
	if el != "" and not el in pr.get("elements", []):
		return false
	# görev/hoca ile öğrenilenler mühürle keşfedilemez
	var learn = String(j.get("learn", ""))
	return learn in ["element", "scroll", "academy", "clan"] or learn.begins_with("trainer")


# ------------------------------------------------------------------ Dōjutsu (V)
func toggle_dojutsu() -> void:
	var cl = clan()
	if not cl in ["uchiha", "hyuga"]:
		Hud.msg("Klanının bir göz tekniği (dōjutsu) yok.", Color(0.8, 0.8, 0.8))
		return
	if int(Game.profile["level"]) < 2:
		Hud.msg("Gözlerin henüz uyanmadı (Seviye 2).", Color(0.8, 0.8, 0.8))
		return
	dojutsu = not dojutsu
	var base_eye: Array = Data.clans.get(cl, {}).get("eye", [0.2, 0.2, 0.2])
	if dojutsu:
		Sfx.play("genjutsu", p.global_position, 1.6, 0.6)
		if cl == "uchiha":
			p.model.set_eye_color(Color(0.9, 0.05, 0.08))
			Combat.base_time_scale = 0.8
			Hud.msg("SHARINGAN: hareketleri yavaş görüyorsun, darbelerden kaçabilirsin", Color(1, 0.4, 0.4))
			if Game.world:
				Game.world.env.set_tint(Color(0.9, 0.1, 0.1, 0.08))
		else:
			p.model.set_eye_color(Color(0.97, 0.97, 1.0))
			Hud.msg("BYAKUGAN: duvarların ardını görüyorsun", Color(0.85, 0.9, 1))
			if Game.world:
				Game.world.env.set_tint(Color(0.6, 0.7, 1.0, 0.1))
	else:
		_end_dojutsu()


func _end_dojutsu() -> void:
	dojutsu = false
	var base_eye: Array = Data.clans.get(clan(), {}).get("eye", [0.2, 0.2, 0.2])
	p.model.set_eye_color(Color(base_eye[0], base_eye[1], base_eye[2]))
	Combat.base_time_scale = 1.0
	if Game.world:
		Game.world.env.set_tint(Color(0, 0, 0, 0))
	for k in markers.keys():
		if is_instance_valid(markers[k]):
			markers[k].queue_free()
	markers.clear()


func _update_byakugan() -> void:
	# duvar arkasından görünen işaretler
	for f in get_tree().get_nodes_in_group("fighters"):
		if not Combat.hostile(p, f) or f.is_dead() or f.get("team") == "dummy":
			continue
		if f.global_position.distance_to(p.global_position) > 90.0:
			continue
		if not markers.has(f.get_instance_id()):
			var l = Label3D.new()
			l.text = "◆"
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.no_depth_test = true
			l.fixed_size = true
			l.pixel_size = 0.002
			l.font_size = 48
			l.modulate = Color(0.75, 0.85, 1.0, 0.9)
			l.outline_size = 8
			f.add_child(l)
			l.position = Vector3(0, f.height * 0.6, 0)
			markers[f.get_instance_id()] = l


# ------------------------------------------------------------------ Sekiz Kapı (B)
func next_gate() -> void:
	if clan() != "none":
		Hud.msg("Sekiz Kapı yalnızca klansız, saf taijutsu ustalarına açık.", Color(0.8, 0.8, 0.8))
		return
	if int(Game.profile["level"]) < 6:
		Hud.msg("Kapıları açacak kadar güçlü değilsin (Seviye 6).", Color(0.8, 0.8, 0.8))
		return
	gates += 1
	if gates > 3:
		gates = 0
		Buffs.remove("gates")
		_set_aura("gates", null)
		Hud.msg("Kapılar kapandı.", Color(0.8, 0.9, 0.8))
		return
	var names = ["", "1. Kapı: Açılış Kapısı!", "2. Kapı: Dinlenme Kapısı!", "3. Kapı: Yaşam Kapısı!"]
	Buffs.add("gates", 9999.0, {"speed": 1.0 + gates * 0.15, "melee": 1.0 + gates * 0.35})
	_set_aura("gates", [Color(0.3, 1.0, 0.5), Color(0.4, 0.9, 1.0), Color(0.2, 0.6, 1.0)][gates - 1], 0.9 + gates * 0.3)
	Hud.banner("HACHIMON", names[gates], Color(0.4, 1.0, 0.6))
	FX.ring(p.global_position + Vector3.UP * 0.2, Color(0.4, 1.0, 0.6), 6.0 + gates * 2.0, 0.4)
	if Game.world:
		Game.world.env.add_shake(0.3 * gates)
	Sfx.play("roar", p.global_position, 1.6, 0.5)


# ------------------------------------------------------------------ Sennin Modu (Z)
func toggle_sage() -> void:
	if not "sage" in Game.profile.get("skills", []):
		Hud.msg("Sennin Modu için Gizli Şelale'de doğa enerjisi eğitimi gerekli (Sv.20, Chunin).", Color(0.9, 0.8, 0.5))
		return
	if sage:
		_end_sage()
		return
	if c.action != "":
		return
	# doğa enerjisini topla: kısa meditasyon
	c.action = "cast"
	c.t = -10.0
	p.model.play("crouch", 0.15)
	Hud.msg("Doğa enerjisini topluyorsun...", Color(1, 0.8, 0.4), 1.5)
	get_tree().create_timer(1.4).timeout.connect(func():
		c.action = ""
		sage = true
		sage_t = 45.0
		Buffs.add("sage", 45.0, {"melee": 1.5, "jutsu": 1.5, "speed": 1.15, "armor": 0.8})
		p.model.set_eye_color(Color(1.0, 0.65, 0.1))
		_set_aura("sage", Color(1.0, 0.7, 0.2), 1.2)
		Hud.banner("SENNIN MODU", "Doğa enerjisiyle bir oldun (45 sn)", Color(1, 0.75, 0.3))
		Sfx.play("levelup", p.global_position, 0.7))


func _end_sage() -> void:
	sage = false
	Buffs.remove("sage")
	_set_aura("sage", null)
	var base_eye: Array = Data.clans.get(clan(), {}).get("eye", [0.25, 0.45, 0.8])
	if not dojutsu:
		p.model.set_eye_color(Color(base_eye[0], base_eye[1], base_eye[2]))
	Hud.msg("Sennin Modu sona erdi.", Color(0.9, 0.8, 0.6))


func start_sage_training() -> void:
	training = true
	training_t = 0.0
	Hud.banner("SENNİN EĞİTİMİ", "[C] basılı tut ve kıpırdama: doğa enerjisini hisset (12 sn)", Color(1, 0.75, 0.3))


# ------------------------------------------------------------------ Kuyruklu Canavar (X)
func beast_key() -> void:
	if not "jinchuriki" in Game.profile.get("skills", []):
		Hud.msg("İçinde mühürlü bir canavar yok... (Raijū'yu yen)", Color(0.7, 0.8, 1))
		return
	if not beast:
		beast = true
		beast_t = 25.0
		Buffs.add("beast", 25.0, {"melee": 2.0, "speed": 1.4, "armor": 0.5, "jutsu": 1.3})
		_set_aura("beast", Color(0.45, 0.75, 1.0), 1.8)
		p.model.set_eye_color(Color(0.6, 0.9, 1.0))
		Hud.banner("KUYRUKLU CANAVAR MODU", "Raijū'nun chakra pelerini! [X] = Canavar Bombası", Color(0.5, 0.8, 1))
		Sfx.play("roar", p.global_position)
		FX.ring(p.global_position + Vector3.UP * 0.3, Color(0.5, 0.8, 1.0), 14.0, 0.5)
		if Game.world:
			Game.world.env.add_shake(1.0)
		return
	if beast_cd > 0.0:
		Hud.msg("Canavar bombası hazırlanıyor (%.1f)" % beast_cd, Color(0.6, 0.8, 1))
		return
	if p.chakra < 40.0:
		Hud.msg("Yeterli chakra yok!", Color(0.5, 0.8, 1))
		return
	p.chakra -= 40.0
	beast_cd = 6.0
	Jutsu.beast_bomb(p, c._auto_target(40.0))


func _end_beast() -> void:
	beast = false
	Buffs.remove("beast")
	_set_aura("beast", null)
	var base_eye: Array = Data.clans.get(clan(), {}).get("eye", [0.25, 0.45, 0.8])
	if not dojutsu:
		p.model.set_eye_color(Color(base_eye[0], base_eye[1], base_eye[2]))
	Hud.msg("Chakra pelerini söndü.", Color(0.7, 0.8, 1))


# ------------------------------------------------------------------ boyut (Baika): model + kapsül hitbox birlikte
func set_size(s: float, dur: float) -> void:
	size = s
	size_t = dur
	p.model.scale = Vector3.ONE * s
	p.radius = base_radius * s
	p.height = base_height * s
	var cs: CollisionShape3D = null
	for ch in p.get_children():
		if ch is CollisionShape3D:
			cs = ch
			break
	if cs:
		var cap: CapsuleShape3D = cs.shape
		cap.radius = p.radius
		cap.height = p.height
		cs.position.y = p.height * 0.5
	p.cam_dist = 5.5 * maxf(1.0, s * 0.8)


# ------------------------------------------------------------------ hasar kancası: true = darbe tamamen önlendi
func on_player_hit(info: Dictionary) -> bool:
	if Buffs.has("suika") and p.chakra >= 5.0:
		p.chakra -= 5.0
		FX.burst(p.global_position + Vector3.UP, {"amount": 20, "life": 0.6, "tex": FX.tex_smoke, "add": false, "size": 0.8, "vmin": 2, "vmax": 6, "gravity": Vector3(0, -10, 0),
			"colors": [Color(0.85, 0.95, 1, 1), Color(0.3, 0.6, 1, 0)]})
		Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Su beden!", Color(0.5, 0.8, 1))
		Sfx.play("water", p.global_position, 1.5, 0.6)
		c.invuln = 0.25
		return true
	if eyes and info.get("kind", "light") != "heavy" and randf() < eyes.dodge_chance():
		var side = p.global_transform.basis.x * (1.0 if randf() < 0.5 else -1.0)
		p.global_position += side * 1.6
		Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Okundu!", Color(1, 0.4, 0.4))
		FX.burst(p.global_position + Vector3.UP, {"amount": 10, "life": 0.3, "tex": FX.tex_spark, "size": 0.8, "vmin": 4, "vmax": 8, "colors": [Color(1, 0.4, 0.4, 0.9), Color(1, 0.2, 0.2, 0)]})
		c.invuln = 0.3
		return true
	return false


# ------------------------------------------------------------------ aura yardımcı
func _set_aura(key: String, col, s := 1.0) -> void:
	if auras.has(key) and is_instance_valid(auras[key]):
		var a: GPUParticles3D = auras[key]
		a.emitting = false
		get_tree().create_timer(1.0).timeout.connect(a.queue_free)
	auras.erase(key)
	if col != null:
		auras[key] = FX.aura(p, col, s, Vector3(0, 0.9, 0), 0.0)


# ------------------------------------------------------------------ güncelleme
func _process(dt: float) -> void:
	if Game.paused or p == null:
		return
	beast_cd -= dt
	if dojutsu:
		p.chakra -= (3.0 if clan() == "uchiha" else 2.0) * dt
		if p.chakra <= 0.0:
			p.chakra = 0.0
			Hud.msg("Chakra bitti, gözlerin kapandı.", Color(0.8, 0.8, 1))
			_end_dojutsu()
		elif clan() == "hyuga":
			marker_t -= dt
			if marker_t <= 0.0:
				marker_t = 0.5
				_update_byakugan()
	if gates > 0:
		p.hp -= [0.0, 1.5, 3.0, 5.5][gates] * dt
		if p.hp <= p.max_hp * 0.1:
			gates = 0
			Buffs.remove("gates")
			_set_aura("gates", null)
			Hud.msg("Bedenin dayanamıyor! Kapılar kapandı.", Color(1, 0.5, 0.4))
	if sage:
		sage_t -= dt
		p.chakra = minf(p.max_chakra, p.chakra + 6.0 * dt)
		if sage_t <= 0.0:
			_end_sage()
	if beast:
		beast_t -= dt
		if beast_t <= 0.0:
			_end_beast()
	if size_t > 0.0:
		size_t -= dt
		if size_t <= 0.0:
			FX.smoke_puff(p.global_position + Vector3.UP * 2.0, 2.0, 20)
			set_size(1.0, 0.0)
	if training:
		if Input.is_action_pressed("charge") and p.velocity.length() < 0.5:
			training_t += dt
			p.model.play("crouch", 0.2)
			Hud.objective_progress("Doğa enerjisi: %d%%" % int(training_t / 12.0 * 100.0))
			if training_t >= 12.0:
				training = false
				if not "sage" in Game.profile["skills"]:
					Game.profile["skills"].append("sage")
				Hud.banner("SENNİN MODU AÇILDI", "[Z] ile doğa enerjisini kullan", Color(1, 0.75, 0.3))
				Sfx.play("levelup")
				Game.save_game()
		else:
			training_t = maxf(0.0, training_t - dt * 3.0)
