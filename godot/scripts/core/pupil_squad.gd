class_name PupilSquad
extends Node
## Jōnin hoca olarak kendi genin takımın (kanon: Kakashi - Takım 7, Asuma - Takım 10). Jōnin olunca köy sana üç genin verir.
## Öğrencilerin kalıcı Friends kaydıdır (pu_0..pu_2): köyde görünürler, sohbet/hediye/idman (Friends sistemi) — rolleri "pupil".
## - Göreve götür: D/C/B görevlerinde peşinden gelir, yanında savaşırlar (GeninSquad'ın eşlik mantığı).
## - Gelişim: kendi seviyeleri (pupil_lv) birikir — görev (D+0.6, C+1.2, B+2), idman maçı (+0.8), öğrettiğin teknikler.
## - Teknik öğret: bildiğin, öğretilebilir (klan/göz/yasak/yol değil) ve onların seviyesine uygun bir tekniği verirsin; savaşta kullanırlar.
## - Seviye 22'yi geçen öğrenci Chūnin olur (rütbesi değişir, yelek giyer).

const MISSION_GAIN := {"D": 0.6, "C": 1.2, "B": 2.0}
const SPAR_GAIN := 0.8
const CHUNIN_LV := 22.0
const RETURN_T := 40.0

var members: Array = []    # [{"id": "pu_0", "node": Enemy, "down": float}]
var t := 0.0
var _mkey := ""
var _mdone := 0


static func pr() -> Dictionary:
	return Game.profile


static func data() -> Dictionary:
	return pr().get("pupils", {}) if not pr().is_empty() else {}


static func ids() -> Array:
	return ["pu_0", "pu_1", "pu_2"]


## Takımı kur (Jōnin olunca; eski kayıtta Jōnin ama takımı yoksa yüklemede sessizce)
static func form(announce: bool) -> void:
	var p = pr()
	if p.is_empty() or int(p.get("rank", 0)) < 3 or p.has("pupils") or Orgs.is_rogue():
		return
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var hairs = [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.55, 0.7), Color(0.2, 0.3, 0.6), Color(0.85, 0.85, 0.88)]
	var tops = [Color(0.3, 0.45, 0.35), Color(0.6, 0.25, 0.2), Color(0.2, 0.3, 0.55), Color(0.85, 0.55, 0.2), Color(0.45, 0.3, 0.55), Color(0.2, 0.2, 0.22)]
	var styles = ["kısa", "uzun", "kase", "dağınık", "topuz", "diken", "atkuyruğu"]
	var els = ["katon", "suiton", "fuuton", "doton", "raiton"]
	els.shuffle()
	var vid = Progress.home()
	var clans = []
	for cc in Data.clans:
		if cc != "none" and not cc in Progress.UNPLAYABLE_CLANS and vid in Data.clans[cc].get("villages", []):
			clans.append(cc)
	var fs = Friends.all()
	var names = []
	for i in 3:
		var female = rng.randf() < 0.45
		var nm = ChuninExam.gen_name(female, rng)
		var clan = String(clans[rng.randi() % clans.size()]) if not clans.is_empty() and rng.randf() < 0.5 else ""
		var look = {"gender": "f" if female else "m", "hair_style": styles[rng.randi() % styles.size()], "hair": hairs[rng.randi() % hairs.size()], "top": tops[rng.randi() % tops.size()], "age": "teen"}
		fs[ids()[i]] = {"name": nm.split(" ")[-1], "role": "spar", "ninja": true, "look": Friends._ser(look), "bond": 15, "village": vid, "party": false,
			"last_talk": 0.0, "element": els[i], "clan": clan, "eye": [0, 0], "rank": 0, "family": Friends._family(clan, female, 0), "status": "", "log": [],
			"news": "", "title": "Öğrencin", "pupil": true, "pupil_lv": 6.0 + rng.randf_range(0.0, 2.0), "taught": []}
		names.append(nm.split(" ")[-1])
	p["pupils"] = {"state": "active", "follow": true, "missions": 0}
	if announce:
		Hud.dialog(String(Progress.home_info()["kage"]), "Artık bir Jōnin'sin. Akademiden yeni mezun üç genini sana veriyorum: %s, %s ve %s. Onları D ve C görevlerinde yanına al, idman yaptır, bildiklerini öğret. Bir gün Chūnin yeleğini giyecekler — senin sayende." % names, [])
	else:
		Hud.msg("Genin takımın: %s, %s, %s. Onları görevlere götürebilir, idman yaptırabilir, teknik öğretebilirsin." % names, Color(0.7, 0.95, 0.7), 7.0)


# ------------------------------------------------------------------ dost menüsü seçenekleri (Friends._friend_opts çağırır)
static func options(id: String) -> Array:
	var f: Dictionary = Friends.all().get(id, {})
	if not f.get("pupil", false) or String(f.get("status", "")) != "":
		return []
	var d = data()
	var opts = []
	var fol = bool(d.get("follow", true))
	opts.append({"label": "Takım: bundan sonra görevlere benimle gelin" if not fol else "Takım: görevlere tek başıma gideceğim, köyde kalın", "cb": func():
		d["follow"] = not fol
		Hud.msg("Öğrencilerin %s." % ("D/C/B görevlerinde seninle gelecek" if not fol else "köyde kalacak"), Color(0.7, 0.95, 0.7))})
	opts.append({"label": "Sana bir teknik öğreteyim...", "cb": func(): _teach_menu(id)})
	opts.append({"label": "Gelişimin nasıl? (Güç %d, %d teknik)" % [int(f.get("pupil_lv", 6)), (f.get("taught", []) as Array).size()], "cb": func():
		Hud.dialog(String(f["name"]), "Gücüm %d. %s Sizin sayenizde her görevde biraz daha güçleniyorum, hocam!" % [int(f.get("pupil_lv", 6)),
			("Chūnin oldum!" if int(f.get("rank", 0)) >= 1 else "Chūnin olmama %d Güç var." % maxi(0, int(CHUNIN_LV) - int(f.get("pupil_lv", 6))))], [])})
	return opts


static func _teach_menu(id: String) -> void:
	var f: Dictionary = Friends.all()[id]
	var taught: Array = f.get("taught", [])
	var lv = float(f.get("pupil_lv", 6.0))
	var opts = []
	for jid in pr().get("learned", []):
		if jid in taught or not GeninSquad._teachable(String(jid)):
			continue
		var j: Dictionary = Data.jutsu.get(jid, {})
		if j.is_empty() or int(j.get("level", 1)) > int(lv) + 6:
			continue   # öğrencinin seviyesinin çok üstü: henüz kaldıramaz
		var jel = String(j.get("element", ""))
		if jel != "" and jel != String(f.get("element", "")):
			continue   # kendi doğası olmayan ninjutsu öğrenemez
		opts.append({"label": "%s [%s]" % [String(j["name"]), String(j.get("canon_rank", "?"))], "tip": String(j.get("desc", "")), "cb": func():
			taught.append(jid)
			f["taught"] = taught
			f["pupil_lv"] = lv + 0.3
			Friends.add_bond(id, 3, true)
			Journal.add("%s'e %s tekniğini öğrettin." % [f["name"], String(j["name"]).split(" (")[0]], "milestone")
			Hud.dialog(String(f["name"]), "İzledim hocam... bir kez daha! — Tamam, oldu! Bundan sonra savaşta kullanırım.", [])})
		if opts.size() >= 8:
			break
	if opts.is_empty():
		Hud.dialog(String(f["name"]), "Şu an öğretebileceğiniz bir şey yok hocam (benim doğam: %s, seviyem %d). Önce biraz daha gelişeyim." % [Elements.NAMES.get(String(f.get("element", "")), "—"), int(lv)], [])
		return
	opts.append({"label": "Sonra", "cb": func(): pass})
	Hud.dialog(String(f["name"]), "Hangi tekniği göstereceksiniz hocam?", opts)


## İdman maçı bitti (Friends._spar_end): öğrenci gelişir
static func on_spar(id: String, player_won: bool) -> void:
	var f: Dictionary = Friends.all().get(id, {})
	if not f.get("pupil", false) and not f.get("child", false):
		return
	_grow(f, SPAR_GAIN + (0.2 if not player_won else 0.0))


static func _grow(f: Dictionary, amt: float) -> void:
	var before = float(f.get("pupil_lv", 6.0))
	var nv = before + amt
	f["pupil_lv"] = nv
	if int(nv) > int(before):
		Hud.msg("%s gelişti — Güç %d" % [f["name"], int(nv)], Color(0.7, 0.95, 0.7))
	if before < CHUNIN_LV and nv >= CHUNIN_LV and int(f.get("rank", 0)) < 1:
		f["rank"] = 1
		f["title"] = "Öğrencin (Chūnin)" if not f.get("child", false) else String(f.get("title", "")) + " (Chūnin)"
		Hud.banner("%s CHŪNİN OLDU" % String(f["name"]).to_upper(), "Senin öğrencin Chūnin yeleğini giydi." if not f.get("child", false) else "Çocuğun Chūnin yeleğini giydi.", Color(0.7, 0.95, 0.7))
		Journal.add("Öğrencim %s Chūnin oldu." % f["name"], "milestone")


## Savaşçı arketipi: Friends.arch öğrencinin kendi seviyesini (pupil_lv) ve öğrendiği teknikleri kullanır (idman maçıyla aynı)
static func arch_of(f: Dictionary) -> Dictionary:
	return Friends.arch(f)


# ------------------------------------------------------------------ dünyada eşlik
func _active() -> bool:
	var d = data()
	if d.is_empty() or d.get("state", "") != "active" or not bool(d.get("follow", true)):
		return false
	if Game.player == null or not is_instance_valid(Game.player) or int(pr().get("rank", 0)) < 3 or Orgs.is_rogue():
		return false
	var m = Missions.active()
	if m.is_empty() or not String(m.get("rank", "")) in MISSION_GAIN:
		return false   # yalnız D/C/B görevlerinde (öğrencileri A/S'ye götürmezsin)
	if Exams.cur != "" or int(ChuninExam.stage) != 0:
		return false
	if Interiors.inst and Interiors.inst.inside != "":
		return false
	return true


func _spawn(id: String) -> Node:
	var f: Dictionary = Friends.all()[id]
	var e = Enemy.new()
	e.setup(arch_of(f))
	e.team = "player"
	e.set_meta("teammate", true)
	e.set_meta("respawn", false)
	e.set_meta("friend_id", id)
	get_tree().current_scene.add_child(e)
	if e.nameplate:
		e.nameplate.modulate = Color(0.55, 1.0, 0.6)
	var pp = Game.player.global_position
	var back = -Game.player.face_dir() if Game.player.has_method("face_dir") else Vector3.BACK
	var q = pp + back * 4.0 + back.cross(Vector3.UP) * randf_range(-3.0, 3.0)
	q.y = Game.ground_height(q.x, q.z)
	e.global_position = q
	e.home = q
	FX.smoke_puff(q + Vector3.UP, 0.8, 10)
	return e


func _despawn_all() -> void:
	for m in members:
		var n = m.get("node")
		if n != null and is_instance_valid(n):
			n.queue_free()
	members.clear()


func _process(dt: float) -> void:
	if Game.paused or pr().is_empty():
		return
	t -= dt
	if t > 0.0:
		return
	t = 0.4
	if int(pr().get("rank", 0)) >= 3 and not pr().has("pupils"):
		form(false)
	_mission_end_tick()
	if not _active():
		if not members.is_empty():
			_despawn_all()
		return
	if members.is_empty():
		for id in ids():
			if Friends.all().has(id) and String(Friends.all()[id].get("status", "")) == "":
				members.append({"id": id, "node": null, "down": 0.0})
	var pp = Game.player.global_position
	var i = 0
	for m in members:
		var n = m["node"]
		if n != null and is_instance_valid(n) and not n.is_dead():
			var off = Vector3(cos(i * 2.1 + 2.4), 0, sin(i * 2.1 + 2.4)) * 3.5
			n.home = pp + off
			if n.global_position.distance_to(pp) > 60.0:
				var q = pp + off
				q.y = Game.ground_height(q.x, q.z)
				n.global_position = q
				n.target = null
			elif n.target == null:
				n.wander_to = pp + off
		elif n != null and (not is_instance_valid(n) or n.is_dead()):
			m["node"] = null
			m["down"] = RETURN_T
			Hud.msg("%s yaralandı ve geri çekildi. Biraz sonra yanına döner." % String(Friends.all()[m["id"]]["name"]), Color(1, 0.75, 0.5))
		elif float(m["down"]) > 0.0:
			m["down"] = float(m["down"]) - 0.4
		else:
			m["node"] = _spawn(m["id"])
		i += 1


## Öğrencilerle gidilen görev başarıyla bitince gelişirler (görev sayacı artmışsa başarı)
func _mission_end_tick() -> void:
	var m = Missions.active()
	var tot = 0
	for k in pr().get("missions_done", {}):
		tot += int(pr()["missions_done"][k])
	if not m.is_empty() and not members.is_empty():
		_mkey = String(m.get("rank", ""))
		if _mdone == 0:
			_mdone = tot + 1
		return
	if _mkey != "" and m.is_empty():
		if tot >= _mdone:
			var g = float(MISSION_GAIN.get(_mkey, 0.6))
			for id in ids():
				var f: Dictionary = Friends.all().get(id, {})
				if not f.is_empty() and String(f.get("status", "")) == "":
					_grow(f, g)
					Friends.add_bond(id, 3, true)
			data()["missions"] = int(data().get("missions", 0)) + 1
			Hud.msg("Öğrencilerin görevden tecrübeyle döndü.", Color(0.7, 0.95, 0.7), 4.0)
		_mkey = ""
		_mdone = 0
