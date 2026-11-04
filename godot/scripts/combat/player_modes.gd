class_name PlayerModes
extends Node
## Oyuncunun özel modları: Dōjutsu (V), Sekiz Kapı (B), Sennin Modu (Z), Kuyruklu Canavar (X),
## Baika boyutu, Suika (su beden) ve mühür örme modu (G basılı + 1..9,0,-,=).

const SEAL_KEYS = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]

var c: PlayerCombat
var p: Player
var dojutsu = false   # eski alan (Eyes.active ile senkron)
var eyes: Eyes
var cloak: BeastCloak   # jinchūriki modları (X)
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
var sage_kind = ""          # aktif sennin modunun sözleşmesi (kurbağa/yılan/sümüklü)
var train_contract = ""
var train_energy = 0.0      # 0..1.2 doğa enerjisi (0.85-1.0 arası bırakınca denge)
var stone_t = 0.0           # taşa dönüşme süresi
var sage_marks := {}
var sage_mark_t = 0.0
var gather_t = -1.0
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
	cloak = BeastCloak.new()
	cloak.name = "BeastCloak"
	add_child(cloak)
	cloak.setup(combat)


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
	if cloak and cloak.handle_input(e):
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
		Hud.msg("Gözlerin henüz uyanmadı (Güç 2).", Color(0.8, 0.8, 0.8))
		return
	dojutsu = not dojutsu
	var base_eye: Array = Data.clans.get(cl, {}).get("eye", [0.2, 0.2, 0.2])
	if dojutsu:
		exclusive("eyes")
		dojutsu = true
		Sfx.play("genjutsu", p.global_position, 1.6, 0.6)
		if cl == "uchiha":
			p.model.set_eye_color(Color(0.9, 0.05, 0.08))
			Combat.base_time_scale = 0.8
			Combat.self_slow = true
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
	Combat.self_slow = false
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
var _steam_t := 0.0


func next_gate() -> void:
	if not LegendPaths.joined("kapi"):
		Hud.msg("Sekiz Kapı'yı açmayı bir usta öğretmeli: Sekiz Kapı Yolu'nu bul (Tab > Yollar, Güç 8+ söylenti).", Color(0.8, 0.8, 0.8))
		return
	gates += 1
	if gates > 7:   # 8. kapı (Ölüm Kapısı) yalnızca Gece Gayı tekniğiyle açılır
		gates = 0
		Buffs.remove("gates")
		_set_aura("gates", null)
		_gate_look(0)
		Hud.msg("Kapılar kapandı.", Color(0.8, 0.9, 0.8))
		return
	var names = ["", "1. Kapı: Açılış Kapısı!", "2. Kapı: Dinlenme Kapısı!", "3. Kapı: Yaşam Kapısı!", "4. Kapı: Acı Kapısı!",
		"5. Kapı: Sınır Kapısı!", "6. Kapı: Görüş Kapısı!", "7. Kapı: Şaşkınlık Kapısı!"]
	var gm = Stats.skill(Game.profile, "gates")  # ustalık: daha güçlü kapılar, daha az beden yükü
	if gates == 1:
		exclusive("gates")
	Buffs.add("gates", 9999.0, {"speed": 1.0 + gates * 0.08 * (1.0 + gm), "melee": 1.0 + gates * 0.18 * (1.0 + gm)})
	_gate_look(gates)
	_gate_burst(gates)
	# kapı aurası + açılış şok dalgası/halka/moloz (kullanıcının sevdiği asıl kapı efektleri)
	_set_aura("gates", [Color(0.3, 1.0, 0.5), Color(0.4, 0.9, 1.0), Color(0.2, 0.6, 1.0), Color(0.35, 1.0, 0.45), Color(0.3, 0.95, 0.4),
		Color(0.25, 0.9, 0.35), Color(0.4, 0.85, 1.0)][gates - 1], 0.9 + gates * 0.3)
	if gates >= 4:
		VFX.shockwave(p.global_position + Vector3.UP * 0.2, Color(0.4, 1.0, 0.5), 8.0 + gates * 2.0, 0.5, true)
		VFX.debris(p.global_position, Color(0.55, 0.45, 0.35), 10 + gates * 4, 8.0)
		VFX.cracks(p.global_position, 2.0 + gates * 0.6)
	FX.ring(p.global_position + Vector3.UP * 0.2, Color(0.4, 1.0, 0.6), 6.0 + gates * 2.0, 0.4)
	Hud.banner("HACHIMON", names[gates], Color(0.4, 1.0, 0.6))
	if Game.world:
		Game.world.env.add_shake(0.3 * gates)
	Sfx.play("roar", p.global_position, 1.6, 0.5)


# ------------------------------------------------------------------ Sennin Modu (Z): sözleşmeye özel
const SAGE_FX := {
	"kurbağa": {"mods": {"melee": 1.3, "jutsu": 1.25, "speed": 1.1, "armor": 0.88, "reach": 1.4}, "col": Color(1.0, 0.6, 0.15), "visual": 1,
		"desc": "Kurbağa Kata: görünmez menzil, güçlü vuruşlar, chakra algısı"},
	"yılan": {"mods": {"melee": 1.2, "jutsu": 1.18, "speed": 1.2, "armor": 0.85}, "col": Color(0.7, 0.4, 0.95), "visual": 2,
		"desc": "Yılan hızı ve yenilenme, zehirli vuruşlar"},
	"sümüklü": {"mods": {"melee": 1.15, "jutsu": 1.2, "armor": 0.8}, "col": Color(0.5, 0.95, 0.6), "visual": 3,
		"desc": "Hızlı iyileşme, chakra yenilenmesi, dayanıklılık"},
}


func sage_contracts() -> Array:
	Contracts.ensure()
	var out = []
	for id in Game.profile.get("contracts", {}):
		if Game.profile["contracts"][id].get("sage", false):
			out.append(id)
	if out.is_empty() and "sage" in Game.profile.get("skills", []):
		out.append("kurbağa")
	return out


func toggle_sage() -> void:
	var list = sage_contracts()
	if list.is_empty():
		Hud.msg("Sennin Modu için bir sözleşme diyarında doğa enerjisi eğitimi gerekli (Kurbağa Dağı, Yılan Mağarası, Sümüklüböcek Ormanı).", Color(0.9, 0.8, 0.5))
		return
	if sage:
		_end_sage()
		return
	if c.action != "" or gather_t >= 0.0:
		return
	var a = Contracts.active()
	sage_kind = a if a in list else list[0]
	# doğa enerjisini topla: kıpırdamadan bekle (hareket edersen bozulur)
	gather_t = 0.0
	c.action = "cast"
	c.t = -10.0
	p.model.play("crouch", 0.15)
	Hud.msg("Doğa enerjisini topluyorsun... kıpırdama!", SAGE_FX[sage_kind]["col"], 1.5)


## Güç modları üst üste binmez (kullanıcı kuralı): sennin, göz (Sharingan/Byakugan...), Sekiz Kapı, kuyruklu canavar —
## biri açılınca diğerleri kapanır
func exclusive(keep: String) -> void:
	if keep != "jutsu":
		Buffs.clear_modes()
	if keep != "sage" and sage:
		_end_sage()
	if keep != "eyes":
		if eyes and eyes.active:
			eyes.toggle()
		if dojutsu:
			_end_dojutsu()
	if keep != "gates" and gates > 0:
		gates = 0
		Buffs.remove("gates")
		_set_aura("gates", null)
		_gate_look(0)
	if keep != "beast" and beast:
		_end_beast()
	if keep != "beast" and cloak != null and cloak.level > 0 and cloak.has_method("deactivate"):
		cloak.deactivate()


func _enter_sage() -> void:
	exclusive("sage")
	gather_t = -1.0
	c.action = ""
	var fx: Dictionary = SAGE_FX.get(sage_kind, SAGE_FX["kurbağa"])
	var m = Contracts.mastery(sage_kind)
	sage = true
	sage_t = 999999.0   # süresiz: tuşa tekrar basılana kadar açık (kullanıcı isteği)
	var mods: Dictionary = fx["mods"].duplicate()
	var sp = Stats.skill(Game.profile, "sage_power")
	for k in ["melee", "jutsu"]:
		if mods.has(k):
			mods[k] = float(mods[k]) * (1.0 + sp)
	Buffs.add("sage", sage_t, mods)
	_set_aura("sage", fx["col"], 1.2)
	if p.model.has_method("set_sage"):
		p.model.set_sage(fx["visual"])
	else:
		p.model.set_eye_color(fx["col"])
	Hud.banner(Contracts.DEFS.get(sage_kind, {}).get("sage_name", "SENNIN MODU").to_upper(), "%s (süresiz — kapatmak için tekrar bas)" % fx["desc"], fx["col"])
	Sfx.play("levelup", p.global_position, 0.7)
	FX.ring(p.global_position + Vector3.UP * 0.2, fx["col"], 6.0, 0.6)


func _end_sage() -> void:
	sage = false
	Buffs.remove("sage")
	_set_aura("sage", null)
	if p.model.has_method("set_sage"):
		p.model.set_sage(0)
	var base_eye: Array = Data.clans.get(clan(), {}).get("eye", [0.25, 0.45, 0.8])
	if not dojutsu:
		p.model.set_eye_color(Color(base_eye[0], base_eye[1], base_eye[2]))
	for k in sage_marks.keys():
		if is_instance_valid(sage_marks[k]):
			sage_marks[k].queue_free()
	sage_marks.clear()
	Hud.msg("Sennin Modu sona erdi.", Color(0.9, 0.8, 0.6))


## Sözleşme diyarında eğitim: C basılı + kıpırdama; enerji %85-100 iken C'yi bırak = denge.
## %100'ü aşarsa hayvanlaşıp taşa dönersin (kısa süre). 3 başarılı denge = o sözleşmenin Sennin Modu.
func start_sage_training(contract := "kurbağa") -> void:
	training = true
	training_t = 0.0
	train_contract = contract
	train_energy = 0.0
	Hud.banner("SENNİN EĞİTİMİ", "[C] basılı tut, kıpırdama. Enerji %85-100 arasındayken C'yi bırak! Aşarsan taşa dönersin.", Contracts.DEFS.get(contract, {}).get("color", Color(1, 0.75, 0.3)))


func _train(dt: float) -> void:
	if stone_t > 0.0:
		stone_t -= dt
		if stone_t <= 0.0:
			p.model.visible = true
			_stone_visual(false)
			Hud.msg("Taşlaşma çözüldü... Bilge seni kurtardı. Tekrar dene.", Color(0.85, 0.85, 0.8))
		return
	var still = p.velocity.length() < 0.5
	if Input.is_action_pressed("charge") and still:
		train_energy += dt * 0.11
		p.model.play("crouch", 0.2)
		var bar = ""
		for i in 20:
			bar += "▮" if i < int(train_energy * 20.0 / 1.2) else "▯"
		Hud.objective_progress("Doğa enerjisi: %d%%  %s  (%%85-100 arası bırak)" % [int(train_energy * 100.0), bar])
		if train_energy > 1.0:
			# fazla doğa enerjisi: hayvanlaşma ve taşa dönüşme
			stone_t = 4.0
			train_energy = 0.0
			p.input_locked = maxf(p.input_locked, 4.0)
			_stone_visual(true)
			Hud.banner("TAŞA DÖNÜŞÜYORSUN!", "Fazla doğa enerjisi emdin", Color(0.6, 0.6, 0.58))
			Sfx.play("earth", p.global_position, 0.6)
	elif Input.is_action_just_released("charge") and train_energy > 0.05:
		var cs: Dictionary = Game.profile["contracts"].get(train_contract, {})
		if train_energy >= 0.85:
			cs["sage_trials"] = int(cs.get("sage_trials", 0)) + 1
			Hud.msg("Denge sağlandı! (%d/3)" % cs["sage_trials"], Color(0.6, 1, 0.6))
			FX.ring(p.global_position + Vector3.UP * 0.2, Color(1, 0.8, 0.3), 4.0, 0.5)
			Sfx.play("seal", p.global_position, 1.2)
			if int(cs["sage_trials"]) >= 3:
				training = false
				cs["sage"] = true
				if not "sage" in Game.profile["skills"]:
					Game.profile["skills"].append("sage")
				if Data.jutsu.has("sennin_modo") and not "sennin_modo" in Game.profile["learned"]:
					Progress.learn("sennin_modo", false)
				Hud.banner(Contracts.DEFS[train_contract]["sage_name"].to_upper() + " AÇILDI", "[Z] ile doğa enerjisini kullan. Bilgeden sennin sanatlarını öğren.", Color(1, 0.75, 0.3))
				Sfx.play("levelup")
				Game.save_game()
		else:
			Hud.msg("Yetersiz doğa enerjisi (%d%%). Tekrar dene." % int(train_energy * 100.0), Color(0.9, 0.8, 0.6))
		train_energy = 0.0
	elif not still:
		train_energy = maxf(0.0, train_energy - dt * 0.4)


func _stone_visual(on: bool) -> void:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.55, 0.52)
	m.roughness = 1.0
	for mi in p.model.find_children("*", "MeshInstance3D", true, false):
		if on:
			mi.set_meta("pre_stone", mi.material_override)
			mi.material_override = m
		elif mi.has_meta("pre_stone"):
			mi.material_override = mi.get_meta("pre_stone")
			mi.remove_meta("pre_stone")
	if on:
		p.model.anim.pause()
	else:
		p.model.anim.play()


func _sage_tick(dt: float) -> void:
	if gather_t >= 0.0:
		if p.velocity.length() > 1.0:
			gather_t = -1.0
			c.action = ""
			Hud.msg("Kıpırdadın, doğa enerjisi dağıldı!", Color(1, 0.6, 0.4))
			return
		gather_t += dt
		var need = maxf(0.6, 1.6 - Contracts.mastery(sage_kind) / 400.0)
		if gather_t >= need:
			_enter_sage()
		return
	if not sage:
		return
	p.chakra = minf(p.max_chakra, p.chakra + (14.0 if sage_kind == "sümüklü" else 6.0) * dt)
	if sage_kind == "yılan":
		p.hp = minf(p.max_hp, p.hp + 6.0 * dt)
	elif sage_kind == "sümüklü":
		p.hp = minf(p.max_hp, p.hp + 12.0 * dt)
	elif sage_kind == "kurbağa":
		# chakra algısı: yakındaki düşmanları işaretle
		sage_mark_t -= dt
		if sage_mark_t <= 0.0:
			sage_mark_t = 0.6
			for f in get_tree().get_nodes_in_group("fighters"):
				if Combat.hostile(p, f) and not f.is_dead() and f.global_position.distance_to(p.global_position) < 80.0 and not sage_marks.has(f.get_instance_id()):
					var l = Label3D.new()
					l.text = "◈"
					l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
					l.no_depth_test = true
					l.fixed_size = true
					l.pixel_size = 0.002
					l.font_size = 44
					l.modulate = Color(1.0, 0.6, 0.15, 0.9)
					f.add_child(l)
					l.position = Vector3(0, f.height * 0.6, 0)
					sage_marks[f.get_instance_id()] = l


# ------------------------------------------------------------------ Kuyruklu Canavar (X)
func beast_key() -> void:
	if not "jinchuriki" in Game.profile.get("skills", []):
		Hud.msg("İçinde mühürlü bir canavar yok... (Raijū'yu yen)", Color(0.7, 0.8, 1))
		return
	if not beast:
		beast = true
		beast_t = 25.0
		exclusive("beast")
		Buffs.add("beast", 25.0, {"melee": 1.45, "speed": 1.2, "armor": 0.75, "jutsu": 1.15})
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
	p.cam_range = Vector2(2.2 * maxf(1.0, s * 0.6), 14.0 * maxf(1.0, s * 0.8))
	p.cam_giant = s > 3.0


# ------------------------------------------------------------------ hasar kancası: true = darbe tamamen önlendi
func on_player_hit(info: Dictionary) -> bool:
	Combat.larch_counter(p, info)   # Karamatsu: yakın dövüş saldıranı kendini saplar
	# Shikotsumyaku (kanon yetenek): çelikten sert kemikler — fiziksel darbe azalır (düşman Kaguya da aynı)
	if ClanMech.clan() == "kaguya" and String(info.get("element", "")) == "":
		info["dmg"] = float(info.get("dmg", 0.0)) * 0.8
	# Hōzuki (kanon): beden darbe anında kendiliğinden sıvılaşır — fiziksel darbe içinden geçer (su harcar); raiton suyu iletir
	if ClanMech.clan() == "hozuki" and not Buffs.has("suika"):
		var hel = String(info.get("element", ""))
		if hel in ["raiton", "ranton", "jinton"]:
			info["dmg"] = float(info.get("dmg", 0.0)) * 1.5
			Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Su beden elektriği iletti!", Color(1, 1, 0.4))
			return false
		var pr = Game.profile
		if hel == "" and float(pr.get("su", ClanMech.SU_MAX)) >= ClanMech.SUIKA_HIT_COST and not info.get("sealed", false):
			pr["su"] = float(pr.get("su", ClanMech.SU_MAX)) - ClanMech.SUIKA_HIT_COST
			VFX.splash(p.global_position + Vector3.UP * 1.1, 1.2)
			Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Suika", Color(0.5, 0.8, 1))
			Sfx.play("water", p.global_position, 1.5, 0.5)
			return true
	if Buffs.has("suika"):
		# su beden: Raiton suyu iletir — iki kat hasar, beden dağılır (zayıflık); ağır darbe yarıya iner; her darbe chakra yer
		var sel = String(info.get("element", ""))
		if sel in ["raiton", "ranton", "jinton"]:
			info["dmg"] = float(info.get("dmg", 0.0)) * 2.0
			Buffs.remove("suika")
			Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Su beden elektriklendi!", Color(1, 1, 0.4))
			if p.has_method("apply_status"):
				p.apply_status("stun", 1.2)
			return false
		var cost = 5.0 + float(info.get("dmg", 0.0)) * 0.25
		if p.chakra < cost:
			Buffs.remove("suika")
			Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Chakra bitti — su beden çözüldü", Color(0.6, 0.75, 1))
			return false
		if info.get("kind", "light") == "heavy":
			info["dmg"] = float(info.get("dmg", 0.0)) * 0.5
			p.chakra -= cost
			return false
		p.chakra -= cost
		FX.burst(p.global_position + Vector3.UP, {"amount": 20, "life": 0.6, "tex": FX.tex_smoke, "add": false, "size": 0.8, "vmin": 2, "vmax": 6, "gravity": Vector3(0, -10, 0),
			"colors": [Color(0.85, 0.95, 1, 1), Color(0.3, 0.6, 1, 0)]})
		Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Su beden!", Color(0.5, 0.8, 1))
		Sfx.play("water", p.global_position, 1.5, 0.6)
		c.invuln = 0.25
		return true
	var predict = eyes != null and eyes.predict_t > 0.0
	if eyes and (info.get("kind", "light") != "heavy" or predict) and randf() < (0.6 if predict else eyes.dodge_chance()):
		var side = p.global_transform.basis.x * (1.0 if randf() < 0.5 else -1.0)
		p.global_position += side * 1.6
		Combat.popup_text(p.global_position + Vector3.UP * 2.2, "Okundu!", Color(1, 0.4, 0.4))
		FX.burst(p.global_position + Vector3.UP, {"amount": 10, "life": 0.3, "tex": FX.tex_spark, "size": 0.8, "vmin": 4, "vmax": 8, "colors": [Color(1, 0.4, 0.4, 0.9), Color(1, 0.2, 0.2, 0)]})
		c.invuln = 0.3
		if predict:
			eyes.counter_strike(info)
		return true
	return false


# ------------------------------------------------------------------ aura yardımcı
## Sekiz Kapı görünümü (anime): 1-2 hafif mavi-beyaz aura; 3+ ten kızarır; 4 mavi damarlar; 6-7 yeşil alev aurası
var _gate_fx: Array = []
func _gate_look(g: int) -> void:
	for n in _gate_fx:
		if is_instance_valid(n):
			if n is GPUParticles3D:
				n.emitting = false
				get_tree().create_timer(1.0).timeout.connect(n.queue_free)
			else:
				n.queue_free()
	_gate_fx.clear()
	_set_aura("gates", null)
	var m = p.get("model")
	if m and m.has_method("set_skin_tint"):
		m.set_skin_tint(Color(0.85, 0.25, 0.2), 0.0 if g < 3 else [0, 0, 0, 0.25, 0.4, 0.45, 0.5, 0.55, 0.75][g])
	if g <= 0:
		return
	if g >= 4 and m:   # kabaran mavi damarlar: kol ve gövdede titreyen ince mavi çizgiler
		for bone in ["LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "UpperChest", "Neck"]:
			var arc = Arcs.new()
			arc.color = Color(0.45, 0.65, 1.0)
			arc.glow = 1.5
			arc.radius = 0.18
			arc.count = 3
			arc.segs = 4
			arc.width = 0.012
			var holder = PathJutsu.get_pinst().bone_attach(p, bone)
			if holder:
				holder.add_child(arc)
				_gate_fx.append(holder)


## Kapı açılış patlaması (anime): 5 hava sütunu, 6 yerde dönen kaya krateri, 7 hava kubbesi
func _gate_burst(g: int) -> void:
	var at = p.global_position
	var gp_ = Vector3(at.x, Game.jutsu_floor(at.x, at.z), at.z)
	WindFX.blast(at + Vector3.UP * 1.5, 1.5 + g * 0.5, 6 + g * 2, WindFX.LINE, false)
	if g >= 5:
		WindFX.swirl(gp_, 1.6, 10.0 + g, 0.6, 10, Color(0.85, 0.95, 1.0, 0.9), false)   # yukarı patlayan hava/su sütunu
	if g >= 6:
		WindFX.swirl(gp_, 5.0, 2.0, 1.2, 12, Color(0.75, 0.62, 0.45, 0.9), false)   # yerde dönen kaya krateri
		VFX.debris(gp_, Color(0.55, 0.45, 0.35), 12 + g * 3, 8.0)
		VFX.cracks(gp_, 2.0 + g * 0.7)
	if g >= 7:
		WindFX.blast(at + Vector3.UP * 1.5, 7.0, 24, Color(0.8, 1.0, 0.85, 0.9), false)
		if Game.world:
			Game.world.env.screen_flash(0.15)


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
		p.hp -= [0.0, 1.5, 3.0, 5.5, 9.0, 13.0, 18.0, 25.0][gates] * dt * maxf(0.3, 1.0 - Stats.skill(Game.profile, "gates") * 0.8)
		if p.hp <= p.max_hp * 0.1:
			gates = 0
			Buffs.remove("gates")
			_set_aura("gates", null)
			_gate_look(0)
			Hud.msg("Bedenin dayanamıyor! Kapılar kapandı.", Color(1, 0.5, 0.4))
	_sage_tick(dt)
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
		_train(dt)
