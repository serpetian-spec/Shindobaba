class_name Swordsmen
extends RefCounted
## Sis'in Yedi Kılıç Ustası (dinamik): her kılıcın bir sahibi var — Kiri'ye sadık ("kiri"), kaçak ("rogue") ya da oyuncuda ("player").
## Kaçak sahipler Bingo Kitabı'na girer, kılıcı elinde ve kılıca özgü teknikleriyle dövüşür; yenilince kılıç oyuncuya geçer.
## Zamanla sadık sahipler kaçar, kaçaklar avcı ninjalarca öldürülüp kılıç Kiri'ye döner (Game.profile["mist_swords"]).
## Kanon kişiler yok: sahipler kendi ninjalarımız; kılıçlar ve teknik tarzları kanondaki gibi.

const INFO := {
	"kubikiribocho": {"alias": ["Sisteki Kasap", "Sessiz Cellat", "Kafa Kesen"], "el": "suiton",
		"tech": "Kirigakure no Jutsu: sise gömülüp arkadan iner; kesilenin kanıyla kılıç onarılır."},
	"samehada": {"alias": ["Köpekbalığı Dişi", "Chakra Yiyen", "Derin Deniz Canavarı"], "el": "suiton",
		"tech": "Değdiği chakrayı yer; zorlanınca kılıçla birleşip köpekbalığına döner."},
	"kiba": {"alias": ["Çifte Yıldırım", "Gök Gürültüsü Dişi", "Şimşek Dansçısı"], "el": "raiton",
		"tech": "İkiz yıldırım kılıçlarıyla şimşek hızında atılır, değdiğini sersemletir."},
	"hiramekarei": {"alias": ["Yüzgeç Kılıç", "Mavi Dalga", "Chakra Deposu"], "el": "suiton",
		"tech": "Biriktirdiği chakrayı salıp ağzını devasa bir bıçağa çevirir (Kaihō)."},
	"shibuki": {"alias": ["Patlayan Parşömen", "Ateş Yağmuru", "Gök Gürleten"], "el": "katon",
		"tech": "Her darbesi patlayıcı etiket zinciriyle patlar; sıçrayıp yeri havaya uçurur."},
	"nuibari": {"alias": ["Dikiş İğnesi", "Tel Örücü", "Ölüm Dikişi"], "el": "fuuton",
		"tech": "İğneyi fırlatıp telle diker: kurbanını çeker ve bağlar."},
	"kabutowari": {"alias": ["Miğfer Kıran", "Demir Çekiç", "Kalkan Delen"], "el": "doton",
		"tech": "Balta ve çekiçle her savunmayı, her zırhı parçalar."},
}
const GIVEN := ["Kaigen", "Sazanami", "Mizuchi", "Uzume", "Nagare", "Kaname", "Shiomi", "Tsurara", "Kirisaki", "Seiran", "Umihiko", "Aogiri", "Namito", "Kurose", "Hisui", "Tōgo"]
const FAMILY := ["Kaizuka", "Mizushima", "Kirikawa", "Shiozawa", "Uragami", "Isonade", "Fukami", "Kurashio", "Ōnami", "Kiritani"]
const EVENT_T := 3600.0   # kılıç ustaları da güçlü: nadiren kaçar ya da yakalanır


static func _p() -> Dictionary:
	return Game.profile


static func _name() -> String:
	return "%s %s" % [FAMILY.pick_random(), GIVEN.pick_random()]


static func sword_name(id: String) -> String:
	return String(Gear.item(id).get("name", id)).split(" (")[0]


static func player_has(id: String) -> bool:
	for g in _p().get("gear", []):
		if String(g.get("id", "")) == id:
			return true
	return false


## Dünya durumu (ilk kez: oyuncuda olanlar "player", kalanların yarısı Kiri'de yarısı kaçak)
static func state() -> Dictionary:
	var pr = _p()
	if pr.is_empty():
		return {}
	if not pr.has("mist_swords"):
		var s = {}
		for id in MistSwords.IDS:
			if player_has(id):
				s[id] = {"state": "player"}
			else:
				s[id] = {"state": "rogue" if randf() < 0.5 else "kiri", "name": _name(), "level": randi_range(34, 58)}
		pr["mist_swords"] = s
		for id in s:
			if s[id]["state"] == "rogue":
				Missions.add_swordsman(id, s[id])
	return pr["mist_swords"]


static func _news(title: String, text: String, col := Color(0.55, 0.8, 1.0)) -> void:
	Hud.msg("Haber: " + text, col.lerp(Color.WHITE, 0.3), 4.0)   # büyük başlık yok
	var pr = _p()
	if not pr.has("beast_news"):
		pr["beast_news"] = []
	pr["beast_news"].append(text)


static var _t := 300.0


## Missions._bingo_tick'ten: dünya olayları
static func world_tick(dt: float) -> void:
	var s = state()
	if s.is_empty():
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = EVENT_T * randf_range(0.7, 1.3)
	if randf() > 0.35:
		return   # çoğu zaman bir şey olmaz
	var kiri = []
	var rogue = []
	for id in s:
		if s[id]["state"] == "kiri":
			kiri.append(id)
		elif s[id]["state"] == "rogue" and not Missions.swordsman_spawned(id):
			rogue.append(id)
	if not kiri.is_empty() and (rogue.is_empty() or randf() < 0.6):
		var id: String = kiri.pick_random()
		s[id]["state"] = "rogue"
		Missions.add_swordsman(id, s[id])
		_news("SİS'İN KILIÇ USTASI KAÇTI", "%s, %s ile Kirigakure'den kaçtı. Bingo Kitabı'na girdi." % [s[id]["name"], sword_name(id)])
	elif not rogue.is_empty():
		var id: String = rogue.pick_random()
		Missions.remove_swordsman(id)
		var old = String(s[id]["name"])
		s[id] = {"state": "kiri", "name": _name(), "level": randi_range(34, 58)}
		_news("SÖYLENTİ", "Kaçak kılıç ustası %s avcı ninjalarca yakalandı; %s Kirigakure'ye döndü, yeni sahibi %s." % [old, sword_name(id), s[id]["name"]])


## Bingo'daki kaçak kılıç ustası yenildi: kılıç oyuncuya geçer
static func claim(id: String) -> void:
	var s = state()
	if s.is_empty() or not s.has(id):
		return
	s[id] = {"state": "player"}
	if not player_has(id):
		Gear.grant(_p(), id)
	Hud.banner("KILIÇ SANA GEÇTİ", "%s artık senin. Sis'in Yedi Kılıcı'ndan biri! [Tab > Ekipman]" % sword_name(id), Color(0.55, 0.85, 1.0))
	Sfx.play("levelup", null, 0.8)


## Bingo düşmanını kılıç ustası olarak giydir
static func dress(a: Dictionary, id: String) -> void:
	a["mist_sword"] = id
	a["kind_anim"] = "sword"
	a["element"] = INFO[id]["el"]
	if not a.has("look"):
		a["look"] = CharacterModel.default_look()
	a["look"]["weapon_r"] = id
	if id == "kiba":
		a["look"]["weapon_l"] = "kiba"
	a["guard"] = 0.5
	a["sub"] = 0.3


# ================================================================== dövüş: kılıca özgü teknikler (Enemy._physics_process)
static func tick(e: Enemy, dt: float) -> void:
	var id = String(e.arch.get("mist_sword", ""))
	if id == "" or e.dead:
		return
	var cd = float(e.get_meta("ms_cd", 3.0)) - dt
	e.set_meta("ms_cd", cd)
	if id == "samehada" and not e.get_meta("ms_fused", false) and e.hp < e.max_hp * 0.5:
		_samehada_fuse(e)
	if e.get_meta("ms_fused", false):
		e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.006 * dt)
	var t = e.target
	if cd > 0.0 or t == null or not is_instance_valid(t) or t.is_dead() or e.state in ["hitstun", "knockdown", "cast"] or e.has_status("stun") or e.has_status("bind"):
		return
	var d = e.global_position.distance_to(t.global_position)
	var fast = 0.65 if e.hp < e.max_hp * 0.5 else 1.0
	match id:
		"kubikiribocho":
			if d < 30.0:
				_mist_strike(e, t)
				e.set_meta("ms_cd", randf_range(9.0, 12.0) * fast)
		"samehada":
			if d < 5.0:
				_bite(e, t)
				e.set_meta("ms_cd", randf_range(4.0, 6.0) * fast)
		"kiba":
			if d < 18.0:
				_lightning_dash(e, t)
				e.set_meta("ms_cd", randf_range(5.0, 7.0) * fast)
		"hiramekarei":
			if d < 16.0:
				_kaiho(e, t)
				e.set_meta("ms_cd", randf_range(7.0, 9.0) * fast)
		"shibuki":
			if d < 20.0:
				_blast_leap(e, t)
				e.set_meta("ms_cd", randf_range(7.0, 9.0) * fast)
		"nuibari":
			if d < 22.0:
				_stitch(e, t)
				e.set_meta("ms_cd", randf_range(8.0, 11.0) * fast)
		"kabutowari":
			if d < 5.5:
				_smash(e, t)
				e.set_meta("ms_cd", randf_range(5.0, 7.0) * fast)


static func _say(e: Enemy, txt: String, col: Color) -> void:
	Combat.popup_text(e.global_position + Vector3.UP * 2.5, txt, col)


static func _flat_dir(a: Vector3, b: Vector3) -> Vector3:
	var d = b - a
	d.y = 0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


## Kubikiribōchō — Kirigakure no Jutsu: sis basar, usta görünmez olur, hedefin arkasında belirip iner; vurursa kılıç onarılır (can)
static func _mist_strike(e: Enemy, t: Node3D) -> void:
	_say(e, "Kirigakure no Jutsu...", Color(0.8, 0.88, 0.95))
	if t == Game.player and Game.world:
		Game.world.env.flash_tint(Color(0.85, 0.9, 0.95, 0.55), 3.0)
	for k in 8:
		FX.smoke_puff(e.global_position + Vector3(randf_range(-6, 6), 0.8, randf_range(-6, 6)), 2.2, 10)
	e.model.visible = false
	e.nameplate.visible = false
	e.get_tree().create_timer(1.4).timeout.connect(func():
		if not is_instance_valid(e) or e.dead or not is_instance_valid(t):
			if is_instance_valid(e):
				e.model.visible = true
				e.nameplate.visible = true
			return
		var behind = t.global_position - (t.face_dir() if t.has_method("face_dir") else Vector3.FORWARD) * 1.8
		behind.y = Game.ground_height(behind.x, behind.z)
		e.global_position = behind
		e.facing = atan2(-(t.global_position.x - behind.x), -(t.global_position.z - behind.z))
		e.model.visible = true
		e.nameplate.visible = true
		e.model.play("slash_c", 0.05, 1.2, true)
		_say(e, "Sessiz Öldürüş!", Color(1, 0.4, 0.35))
		var hits = Combat.hit_sphere(e, t.global_position + Vector3.UP, 1.6, {"dmg": 34.0 * e.power, "knock": 14.0, "launch": 3.0, "kind": "heavy", "dir": _flat_dir(behind, t.global_position)})
		if not hits.is_empty():
			e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.05)
			Combat.popup_text(e.global_position + Vector3.UP * 2.2, "Kılıç onarıldı", Color(0.85, 0.3, 0.3))
		FX.hit_spark(t.global_position + Vector3.UP, Color(0.9, 0.9, 1.0), 1.4))


## Samehada — chakra yiyen ısırık
static func _bite(e: Enemy, t: Node3D) -> void:
	e.model.play("slash_b", 0.05, 1.1, true)
	var hits = Combat.hit_sphere(e, e.global_position + e.face_dir() * 1.8 + Vector3.UP, 1.6, {"dmg": 22.0 * e.power, "knock": 8.0, "kind": "heavy", "dir": e.face_dir()})
	for h in hits:
		if h == Game.player:
			var eat = minf(Game.player.chakra, 30.0)
			Game.player.chakra -= eat
			e.hp = minf(e.max_hp, e.hp + eat * 3.0)
			_say(e, "Samehada chakranı yedi! (-%d)" % int(eat), Color(0.5, 0.6, 1.0))
	FX.ring(e.global_position + e.face_dir() * 1.8 + Vector3.UP, Color(0.35, 0.4, 0.75), 2.0, 0.3)


## Samehada ile birleşme: köpekbalığı derisi, mavi aura, can yenilenir, daha hızlı ve dayanıklı
static func _samehada_fuse(e: Enemy) -> void:
	e.set_meta("ms_fused", true)
	_say(e, "Samehada ile Birleşme!", Color(0.45, 0.6, 1.0))
	Hud.banner(e.display_name, "Samehada ile birleşti!", Color(0.45, 0.6, 1.0))
	FX.aura(e, Color(0.3, 0.45, 0.9), 1.4, Vector3(0, 0.9, 0), 0.0)
	e.arch["speed"] = float(e.arch.get("speed", 8.5)) * 1.25
	e.arch["guard"] = 0.65
	if e.model:
		var tw = e.model.create_tween()
		tw.tween_property(e.model, "scale", e.model.scale * 1.15, 0.6).set_trans(Tween.TRANS_BACK)


## Kiba — yıldırım atılışı: hedefe şimşek gibi atılır, ikiz kılıçla keser, sersemletir
static func _lightning_dash(e: Enemy, t: Node3D) -> void:
	var from = e.global_position
	var dir = _flat_dir(from, t.global_position)
	var to = t.global_position - dir * 1.2
	to.y = Game.ground_height(to.x, to.z)
	VFX.bolt(from + Vector3.UP, to + Vector3.UP, Color(0.6, 0.85, 1.0), 0.25)
	FX.speed_lines(from + Vector3.UP, dir)
	e.global_position = to
	e.facing = atan2(-dir.x, -dir.z)
	e.model.play("slash_a", 0.02, 1.5, true)
	_say(e, "Kiba: Raiton Kesiği!", Color(0.7, 0.9, 1.0))
	for h in Combat.hit_sphere(e, to + dir * 1.0 + Vector3.UP, 1.7, {"dmg": 26.0 * e.power, "knock": 6.0, "kind": "heavy", "element": "raiton", "dir": dir}):
		h.apply_status("stun", 0.9)
	FX.hit_spark(to + dir + Vector3.UP, Color(0.7, 0.9, 1.0), 1.5)
	Sfx.play("chidori", to, 1.3, 0.6)


## Hiramekarei — Kaihō: biriken chakra devasa bir bıçak olur, önündeki geniş yelpazeye iner
static func _kaiho(e: Enemy, t: Node3D) -> void:
	var dir = _flat_dir(e.global_position, t.global_position)
	e.facing = atan2(-dir.x, -dir.z)
	_say(e, "Hiramekarei: Kaihō!", Color(0.5, 0.75, 1.0))
	FX.aura(e, Color(0.4, 0.65, 1.0), 1.2, Vector3(0, 0.9, 0), 1.0)
	e.get_tree().create_timer(0.7).timeout.connect(func():
		if not is_instance_valid(e) or e.dead:
			return
		e.model.play("slash_c", 0.05, 1.0, true)
		var o = e.global_position
		Combat.hit_zone(e, o, dir, 15.0, 32.0, 6.0, {"dmg": 40.0 * e.power, "knock": 18.0, "launch": 4.0, "kind": "heavy", "dir": dir})
		for k in 6:
			var q = o + dir * (2.5 + k * 2.2)
			q.y = Game.ground_height(q.x, q.z)
			FX.impact(q + Vector3.UP * 0.6, Color(0.45, 0.7, 1.0), 1.4)
		FX.ring(o + Vector3.UP + dir * 7.0, Color(0.45, 0.7, 1.0), 9.0, 0.4, false, dir))


## Shibuki — patlayıcı sıçrayış: havaya fırlayıp hedefin üstüne iner, etiket zinciri patlar
static func _blast_leap(e: Enemy, t: Node3D) -> void:
	var land = t.global_position
	land.y = Game.ground_height(land.x, land.z)
	_say(e, "Shibuki!", Color(1.0, 0.6, 0.3))
	var tw = e.create_tween()
	var from = e.global_position
	tw.tween_method(func(x: float):
		if is_instance_valid(e):
			e.global_position = from.lerp(land, x) + Vector3.UP * sin(x * PI) * 7.0, 0.0, 1.0, 0.75)
	tw.tween_callback(func():
		if not is_instance_valid(e) or e.dead:
			return
		e.model.play("slash_c", 0.02, 1.2, true)
		for k in 5:
			var q = land + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
			e.get_tree().create_timer(k * 0.08).timeout.connect(func(): FX.explosion(q + Vector3.UP * 0.5, 1.3))
		Combat.hit_sphere(e, land + Vector3.UP, 4.5, {"dmg": 38.0 * e.power, "knock": 22.0, "launch": 8.0, "kind": "heavy", "element": "katon"})
		VFX.cracks(land, 5.0)
		if Game.world:
			Game.world.env.add_shake(0.6))


## Nuibari — dikiş: iğne telle fırlar, hedefi deler, çekip bağlar
static func _stitch(e: Enemy, t: Node3D) -> void:
	var from = e.global_position + Vector3.UP * 1.3
	var to = t.global_position + Vector3.UP * 1.1
	e.model.play("throw", 0.05, 1.3, true)
	_say(e, "Nuibari: Dikiş!", Color(0.85, 0.88, 0.95))
	VFX.bolt(from, to, Color(0.9, 0.92, 1.0), 0.05)
	var hits = Combat.hit_sphere(e, to, 1.2, {"dmg": 18.0 * e.power, "knock": 0.0, "kind": "light", "dir": _flat_dir(from, to)})
	for h in hits:
		h.apply_status("bind", 1.6)
		var pull = e.global_position + _flat_dir(e.global_position, h.global_position) * 2.2
		pull.y = Game.ground_height(pull.x, pull.z)
		h.create_tween().tween_property(h, "global_position", pull, 0.35).set_trans(Tween.TRANS_QUAD)
		Combat.popup_text(h.global_position + Vector3.UP * 2.2, "Dikildin!", Color(0.85, 0.88, 0.95))


## Kabutowari — miğfer kıran: balta ve çekiç birlikte iner, savunma/zırh dağılır, yer çatlar
static func _smash(e: Enemy, t: Node3D) -> void:
	var dir = _flat_dir(e.global_position, t.global_position)
	e.model.play("slash_c", 0.05, 0.9, true)
	_say(e, "Kabutowari!", Color(0.85, 0.8, 0.7))
	e.get_tree().create_timer(0.35).timeout.connect(func():
		if not is_instance_valid(e) or e.dead:
			return
		var o = e.global_position
		for h in Combat.hit_zone(e, o, dir, 5.5, 50.0, 3.5, {"dmg": 36.0 * e.power, "knock": 16.0, "launch": 5.0, "kind": "heavy", "dir": dir}):
			h.apply_status("stun", 0.7)
			if h == Game.player:
				Buffs.add("kabutowari", 6.0, {"armor": 1.35})   # zırh kırıldı: 6 sn fazla hasar alır
				Combat.popup_text(h.global_position + Vector3.UP * 2.2, "Zırh kırıldı!", Color(1, 0.6, 0.3))
		var q = o + dir * 2.5
		q.y = Game.ground_height(q.x, q.z)
		VFX.cracks(q, 4.0)
		VFX.debris(q + Vector3.UP * 0.3, Color(0.5, 0.45, 0.4), 14, 9.0)
		if Game.world:
			Game.world.env.add_shake(0.5))
