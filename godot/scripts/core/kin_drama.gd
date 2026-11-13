class_name KinDrama
extends ScenePoser
## Aile dramı: yakınların (baban, annen, kardeşin, eşin, mezun çocuğun) başına gelenler — hepsi sahne olarak oynanır.
## · Kaçırılma: bir ulak koşarak gelir, haber verir. Kaçıran gerçek bir Bingo Kitabı kaçağıdır (saklandığı yer haritada).
##   - zamanında yetişirsen (T_SAFE): direğe bağlı bulursun; kaçağı yen / kaçır → ipleri çözersin, sarılırsınız
##   - gecikirsen (T_HURT): yaralı bulursun → koluna girip hastaneye götürürsün (hastanede yatar)
##   - çok gecikirsen: son nefesine yetişirsin (son sözler; Uchiha'da Mangekyō) — katil kaçar, Bingo Kitabı'nda izini sürersin
##   - hiç gitmezsen (T_LOST): ulak kötü haberi getirir
## · Hastane: yaralı yakının köy hastanesinde yatar; başucunda oturursun (daha çabuk toparlanır)
## · Mezar: mezarlıkta başında oturursun; katili öldürdüysen bandını mezarına bırakırsın

const GAP := [1800.0, 3000.0]   # iki olay arası (oyun süresi, sn)
const T_SAFE := 720.0
const T_HURT := 1200.0
const T_LOST := 2400.0

static var cur: KinDrama

var kind := ""
var id := ""
var v: Node3D          # ulak / tutsak / hasta
var foe: Node3D
var extra: Array = []  # sahne eşyaları (direk, ip, bant)
var ward_busy := false


static func pr() -> Dictionary:
	return Game.profile


static func d() -> Dictionary:
	return pr().get("kin_drama", {})


static func is_family(fid: String) -> bool:
	var f: Dictionary = Friends.all().get(fid, {})
	return not f.is_empty() and (f.has("kin") or f.get("child", false) or fid == Friends.spouse_id())


static func _fem(fid: String) -> bool:
	return String(Friends.all().get(fid, {}).get("look", {}).get("gender", "m")) == "f"


## "Kardeşin", "Eşin"... (ulak / haber cümleleri)
static func rel_word(fid: String) -> String:
	var f: Dictionary = Friends.all().get(fid, {})
	match String(f.get("kin", "")):
		"baba": return "Baban"
		"anne": return "Annen"
		"kardeş": return "Kardeşin"
	if fid == Friends.spouse_id():
		return "Eşin"
	if f.get("child", false):
		return "Kızın" if _fem(fid) else "Oğlun"
	return String(f.get("name", ""))


## Yakının sana nasıl seslendiği
static func me_word(fid: String) -> String:
	var f: Dictionary = Friends.all().get(fid, {})
	var me_f = Friends.player_gender() == "f"
	match String(f.get("kin", "")):
		"baba", "anne": return "evladım"
		"kardeş": return "kardeşim" if f.get("elder", false) else ("abla" if me_f else "ağabey")
	if f.get("child", false):
		return "anne" if me_f else "baba"
	return "canım"


static func short(fid: String) -> String:
	return String(Friends.all().get(fid, {}).get("name", "")).split(" ")[-1]


static func victims() -> Array:
	var o = []
	var soft = []
	for fid in Friends.all():
		var f: Dictionary = Friends.all()[fid]
		if is_family(fid) and String(f.get("status", "")) == "" and Friends.available(f) and not f.get("party", false):
			o.append(fid)
			if int(f.get("rank", 0)) < 2:
				soft.append(fid)
	return soft if not soft.is_empty() else o   # jōnin baban ancak başka kimse yoksa


static func can_start() -> bool:
	var pl = Game.player
	if pl == null or Orgs.is_rogue() or Missions.quiet() or is_instance_valid(cur) or is_instance_valid(KinScene.cur):
		return false
	if Interiors.inst == null or Interiors.inst.inside != "" or pl.get("scene_hold") or pl.input_locked > 0.0 or pl.hp <= 0.0:
		return false
	return not victims().is_empty()


static func tick(dt: float) -> void:
	if pr().is_empty() or Game.player == null:
		return
	var dd: Dictionary = d()
	if dd.is_empty():
		if not pr().has("kd_wait"):
			pr()["kd_wait"] = randf_range(GAP[0], GAP[1]) * 1.4
		pr()["kd_wait"] = float(pr()["kd_wait"]) - dt
		if float(pr()["kd_wait"]) <= 0.0 and can_start():
			begin("")
		return
	dd["el"] = float(dd.get("el", 0.0)) + dt
	if is_instance_valid(cur):
		return
	var fid = String(dd["id"])
	if not Friends.all().has(fid) or String(Friends.all()[fid].get("status", "")) != "":
		_close(fid)
		return
	var e = entry()
	if e.is_empty() or String(e.get("status", "")) != "alive":
		# kaçak başka yerde öldü / silindi: yakının kendi başına döner
		Friends.all()[fid]["news"] = "Beni tutan adam bir gün ortadan kayboldu... ipleri taşa sürte sürte kopardım."
		_close(fid)
		return
	if Interiors.inst == null or Interiors.inst.inside != "":
		return
	var nodes = Missions._bb_spawned.get(int(dd["eid"]))
	if nodes != null and is_instance_valid(nodes[0]) and not nodes[0].dead and Game.player.global_position.distance_to(nodes[0].global_position) < 110.0:
		_spawn("camp", fid)
	elif float(dd["el"]) > T_LOST and nodes == null and can_start_lost():
		_spawn("lost", fid)


static func can_start_lost() -> bool:
	var pl = Game.player
	return not Missions.quiet() and not pl.get("scene_hold") and pl.input_locked <= 0.0 and pl.hp > 0.0


static func entry() -> Dictionary:
	var dd = d()
	if dd.is_empty():
		return {}
	for e in Missions._bingo()["list"]:
		if int(e["id"]) == int(dd["eid"]):
			return e
	return {}


static func _spawn(k: String, fid: String) -> KinDrama:
	var s = KinDrama.new()
	s.kind = k
	s.id = fid
	if k != "ward":
		cur = s
		Friends.inst().get_parent().add_child(s)
	return s


## Kaçırılma başlar (fid boşsa yakınlardan biri)
static func begin(fid: String) -> bool:
	if fid == "":
		var vs = victims()
		if vs.is_empty():
			return false
		fid = String(vs.pick_random())
	var f: Dictionary = Friends.all()[fid]
	var rank = int(f.get("rank", 0))
	var e: Dictionary = Missions._bb_new(["C", "B", "A", "A"][clampi(rank, 0, 3)])
	var hide = Missions._spot(Progress.home(), 220, 520)
	e["hide"] = hide
	e["area"] = [hide[0], hide[1]]
	e["known"] = 20.0
	e["kin_victim"] = fid
	var clan = String(f.get("clan", ""))
	var info: Dictionary = Data.clans.get(clan, {})
	var motive = "öç"
	if String(info.get("dojutsu", "")) != "":
		motive = "göz"
	elif not (info.get("kg_natures", []) as Array).is_empty():
		motive = "kan"
	(e["crimes"] as Array).insert(0, "Kaçırdığı kişi: %s" % String(f["name"]))
	for x in Missions._bingo()["list"]:
		x["tracked"] = false
	e["tracked"] = true
	Missions._bingo()["list"].append(e)
	f["away"] = Time.get_unix_time_from_system() + 86400.0 * 7.0
	f["abducted"] = true
	f["party"] = false
	pr()["kin_drama"] = {"id": fid, "eid": int(e["id"]), "el": 0.0, "motive": motive}
	Friends.log_event(f, "«%s» %s tarafından kaçırıldı" % [e["alias"], e["name"]])
	_spawn("news", fid)
	return true


static func _mark() -> void:
	var e = entry()
	if e.is_empty():
		return
	var p = Game.from_map(Vector2(e["hide"][0], e["hide"][1]))
	pr()["waypoint"] = [p.x, p.y, p.z, "Kaçırıldı: %s" % String(Friends.all()[String(d()["id"])]["name"])]
	pr()["track"] = "waypoint"


static func _close(fid: String) -> void:
	pr().erase("kin_drama")
	pr()["kd_wait"] = randf_range(GAP[0], GAP[1])
	if pr().has("waypoint") and String(pr()["waypoint"][3]).begins_with("Kaçırıldı:"):
		pr().erase("waypoint")
	if Friends.all().has(fid):
		var f: Dictionary = Friends.all()[fid]
		if f.get("abducted", false):
			f.erase("abducted")
			if not f.has("injury"):
				f["away"] = 0.0


## Ölüm: kayıt, katil Bingo Kitabı'nda, (gözünün önündeyse) Mangekyō bağı
static func _kill(fid: String, node: Node, seen: bool) -> void:
	var f: Dictionary = Friends.all()[fid]
	var e = entry()
	if seen and node is Node3D and Game.player.combat and Game.player.combat.modes and Game.player.combat.modes.get("eyes"):
		Game.player.combat.modes.eyes.on_ally_died(node)
	f["status"] = "öldü"
	f["party"] = false
	f.erase("injury")
	if not e.is_empty():
		f["killer"] = int(e["id"])
		f["killer_name"] = "«%s» %s" % [e["alias"], e["name"]]
		(e["crimes"] as Array).insert(0, "Öldürdüğü kişi: %s" % String(f["name"]))
		e["bounty"] = int(e["bounty"]) + 2000
		Friends.log_event(f, "%s tarafından öldürüldü" % f["killer_name"])
		Journal.add("%s öldü. Katili: %s. Bingo Kitabı'nda adı var — bulacağım." % [String(f["name"]), f["killer_name"]], "milestone")
	else:
		Friends.log_event(f, "Kaçıranların elinde öldü")
	_close(fid)
	Game.save_game()


## Tanıdık dövüşte öldü: katili bellidir. Katil sağsa adıyla Bingo Kitabı'na yazılır (o an karşındaki kişi odur: orada öldürürsen
## intikam orada alınır, kaçarsa kitaptan izini sürersin); dövüşte çoktan düştüyse intikam alınmış sayılır.
## body: ölen kişinin düğümü (yoksa null), foes: o dövüşteki düşmanlar, at: dövüş yeri, what: kayda geçecek söz
static func slain(fid: String, body, foes: Array, at: Vector3, what: String) -> void:
	if not Friends.all().has(fid):
		return
	var f: Dictionary = Friends.all()[fid]
	var pl = Game.player
	var has_body = body != null and is_instance_valid(body) and body is Node3D
	var bp: Vector3 = body.global_position if has_body else at
	if has_body and pl.global_position.distance_to(bp) < 60.0 and pl.combat and pl.combat.modes and pl.combat.modes.get("eyes"):
		pl.combat.modes.eyes.on_ally_died(body)
	f["status"] = "öldü"
	f["party"] = false
	f.erase("injury")
	var cand: Array = foes.filter(func(e): return is_instance_valid(e) and e is Enemy and not e.is_dead())
	if cand.is_empty():
		for e in pl.get_tree().get_nodes_in_group("fighters"):
			if e is Enemy and not e.is_dead() and e.team != "player" and e.global_position.distance_to(bp) < 40.0 and (e.target == body or e.target == pl):
				cand.append(e)
	var killer: Enemy = null
	var bd = 1e18
	for e in cand:
		var dd: float = e.global_position.distance_to(bp) * (0.3 if has_body and e.target == body else 1.0)
		if dd < bd:
			bd = dd
			killer = e
	var up = String(f["name"]).to_upper()
	if killer == null:
		var dead_foes = foes.filter(func(e): return is_instance_valid(e) and e is Enemy)
		if not dead_foes.is_empty():
			f["killer"] = -1
			f["killer_name"] = String(dead_foes[0].display_name)
			f["avenged"] = true
			Friends.log_event(f, "%s — %s tarafından öldürüldü; katili orada senin elinle öldü" % [what, f["killer_name"]])
			Hud.banner("%s ÖLDÜ" % up, "Katili %s de orada can verdi. Mezarına gidip söyleyebilirsin." % f["killer_name"], Color(0.85, 0.85, 0.95))
		else:
			Friends.log_event(f, what)
			Hud.banner("%s ÖLDÜ" % up, what, Color(0.85, 0.85, 0.95))
		Game.save_game()
		return
	var e2: Dictionary = {}
	if killer.has_meta("bingo_id"):
		for x in Missions._bingo()["list"]:
			if int(x["id"]) == int(killer.get_meta("bingo_id")):
				e2 = x
	if e2.is_empty():
		var lv = int(killer.level)
		e2 = Missions._bb_new("C" if lv < 65 else ("B" if lv < 115 else ("A" if lv < 170 else "S")))
		e2["name"] = String(killer.display_name)
		e2["level"] = lv
		e2["hp"] = float(killer.max_hp)
		e2["power"] = float(killer.arch.get("power", e2["power"]))
		if String(killer.element) != "":
			e2["element"] = String(killer.element)
		e2["escorts"] = 0
		var mp = Game.to_map(bp)
		e2["hide"] = [mp.x, mp.y]
		e2["area"] = [mp.x, mp.y]
		e2["known"] = 30.0
		Missions._bingo()["list"].append(e2)
		killer.set_meta("bingo_id", int(e2["id"]))
		Missions._bb_spawned[int(e2["id"])] = [killer]
	e2["kin_victim"] = fid
	(e2["crimes"] as Array).insert(0, "Öldürdüğü kişi: %s" % String(f["name"]))
	e2["bounty"] = int(e2["bounty"]) + 2000
	f["killer"] = int(e2["id"])
	f["killer_name"] = "«%s» %s" % [e2["alias"], e2["name"]]
	Friends.log_event(f, "%s — %s tarafından öldürüldü" % [what, f["killer_name"]])
	if is_family(fid) or Friends.closeness(fid) >= 40:
		for x in Missions._bingo()["list"]:
			x["tracked"] = false
		e2["tracked"] = true
		Journal.add("%s öldü. Katili: %s. Bingo Kitabı'nda adı var — bulacağım." % [String(f["name"]), f["killer_name"]], "milestone")
	Hud.banner("%s ÖLDÜ" % up, "Katili: %s. Adı Bingo Kitabı'na yazıldı — intikamını alabilirsin." % f["killer_name"], Color(1, 0.5, 0.45))
	Game.save_game()


## Tanıdık uzakta, görevde öldü: onu öldüren de dünyada biridir — adı Bingo Kitabı'na yazılır
static func slain_far(fid: String, what: String) -> void:
	if not Friends.all().has(fid):
		return
	var f: Dictionary = Friends.all()[fid]
	f["status"] = "öldü"
	f["party"] = false
	f.erase("injury")
	var e2: Dictionary = Missions._bb_new(["C", "B", "A", "A"][clampi(int(f.get("rank", 0)), 0, 3)])
	e2["kin_victim"] = fid
	(e2["crimes"] as Array).insert(0, "Öldürdüğü kişi: %s" % String(f["name"]))
	Missions._bingo()["list"].append(e2)
	f["killer"] = int(e2["id"])
	f["killer_name"] = "«%s» %s" % [e2["alias"], e2["name"]]
	Friends.log_event(f, "%s — %s tarafından öldürüldü" % [what, f["killer_name"]])
	if is_family(fid) or Friends.closeness(fid) >= 40:
		for x in Missions._bingo()["list"]:
			x["tracked"] = false
		e2["tracked"] = true
		Journal.add("%s öldü. Katili: %s. Bingo Kitabı'nda adı var — bulacağım." % [String(f["name"]), f["killer_name"]], "milestone")
	Hud.banner("%s ÖLDÜ" % String(f["name"]).to_upper(), "%s. Katili: %s — adı Bingo Kitabı'nda." % [what, f["killer_name"]], Color(1, 0.5, 0.45))
	Game.save_game()


## Bingo kaçağı öldürüldü (Missions._bingo_killed çağırır)
static func on_bingo_killed(e: Dictionary) -> void:
	var fid = String(e.get("kin_victim", ""))
	if fid == "" or not Friends.all().has(fid):
		return
	var f: Dictionary = Friends.all()[fid]
	if String(f.get("status", "")) == "öldü" and int(f.get("killer", -1)) == int(e["id"]):
		f["avenged"] = true
		Friends.log_event(f, "Katili senin elinle öldü")
		Journal.add("Katil öldü; %s artık rahat uyuyabilir. Mezarına gidip söylemeliyim." % String(f["name"]), "milestone")
		Hud.msg("İntikam alındı (%s). Mezarlığa git: ona haber ver." % String(f["name"]), Color(0.85, 0.85, 0.95), 7.0)


## Konuşma seçenekleri (hastanede yatan yakın)
static func opts(fid: String, node: Node) -> Array:
	if node == null or not node.get_meta("bedside", false) or not is_instance_valid(node.get_meta("ward", null)):
		return []
	var f: Dictionary = Friends.all().get(fid, {})
	if float(f.get("visited_inj", 0.0)) == float(f.get("inj_away", -1.0)):
		return []
	var w: KinDrama = node.get_meta("ward")
	return [{"label": "Başucunda otur", "cb": func(): w.bedside()}]


## Mezarlık seçenekleri
static func grave_opts(v_id: String) -> Array:
	var o = []
	for fid in Graveyard.dead_of(v_id):
		var f: Dictionary = Friends.all()[fid]
		if not (f.has("kin") or f.get("child", false) or f.has("killer") or String(f.get("romance", "")) == "eş"):
			continue
		var told = f.get("avenged", false) and not f.get("avenged_told", false)
		var fid2 = String(fid)
		o.append({"label": ("%s — katilinin öldüğünü söyle" if told else "%s — mezarı başında otur") % short(fid2), "cb": func(): start_grave(fid2)})
	return o


static func start_grave(fid: String) -> void:
	if is_instance_valid(cur):
		return
	_spawn("grave", fid)


## Hastane kurulurken: yatan yakının varsa yatağına yerleştir
static func ward(inter: Node) -> void:
	var hv: Dictionary = Game.village(Progress.home())
	if inter.door.has("pos") and Game.to_map(inter.door["pos"]).distance_to(Vector2(float(hv.get("x", 0)), float(hv.get("y", 0)))) > float(hv.get("r", 300)) * 1.6:
		return   # başka köyün hastanesi
	var now = Time.get_unix_time_from_system()
	for fid in Friends.all():
		var f: Dictionary = Friends.all()[fid]
		if is_family(fid) and f.has("injury") and String(f.get("status", "")) == "" and now < float(f.get("away", 0.0)) and not f.get("abducted", false):
			var s = _spawn("ward", String(fid))
			inter.room.add_child(s)
			return


# ====================================================================== sahneler
func _ready() -> void:
	match kind:
		"news": await _news(false)
		"lost": await _news(true)
		"camp": await _camp()
		"grave": await _grave()
		"ward":
			await _ward()
			return   # oda kapanana kadar yaşar
	_end()


func _end() -> void:
	var pl = Game.player
	if kind != "ward" and is_instance_valid(pl):
		_clear_pose(pl)
		_release_player()
	for m in extra:
		if is_instance_valid(m):
			m.queue_free()
	if cur == self:
		cur = null
	queue_free()


func _exit_tree() -> void:
	if cur == self:
		cur = null
		_release_player()
	elif kind == "ward" and ward_busy:
		_release_player()


func _process(dt: float) -> void:
	_apply_poses(dt)


func _floor_y(p: Vector3) -> float:
	if kind == "ward":
		return Interiors.inst.L(0, 0.05, 0).y
	return Game.ground_height(p.x, p.z)


func _tell(text: String, dur := 2.4) -> void:
	Combat.popup_text(_bone(Game.player, "Head") + Vector3.UP * 0.35, text, Color(1.0, 0.92, 0.72))
	await _wait(dur)


func _foe_say(text: String) -> void:
	if is_instance_valid(foe):
		Combat.popup_text(foe.global_position + Vector3.UP * 2.25, text, Color(1.0, 0.55, 0.45))


func _lie(n: Node3D, feet: Vector3, head_dir: Vector3, lift := 0.04) -> void:
	n.global_position = feet + Vector3.UP * lift
	_face(n, atan2(head_dir.x, head_dir.z))
	var full: String = CharacterModel.ANIM["getup"]
	n.model.current = "getup"
	n.model.anim.play(full, 0.0, -8.0, true)
	n.model.overlay.foot_ik = false


func _make(n: Node3D, s: Dictionary) -> Dictionary:
	var t: float = s["t"]
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	match String(s["k"]):
		"bound":   # eller arkada bağlı
			var sl = float(s.get("slump", 8.0))
			return {"arms": [["LeftUpperArm", Vector3(0.22, -0.75, -0.5)], ["RightUpperArm", Vector3(-0.22, -0.75, -0.5)],
				["LeftLowerArm", Vector3(-0.55, -0.3, -0.75)], ["RightLowerArm", Vector3(0.55, -0.3, -0.75)]],
				"fL": GRIP, "fR": GRIP, "spine": sl + sin(t * 1.3) * 1.5, "neck": sl * 1.3}
		"untie":   # iki elle düğümü çözer
			var c: Vector3 = s["c"]
			var j = sin(t * 11.0) * 0.03
			var a1 = _ik(n, "Left", c - right * 0.07 + Vector3.UP * j, 24.0)
			a1.append_array(_ik(n, "Right", c + right * 0.07 - Vector3.UP * j, 24.0))
			return {"arms": a1, "fL": GRIP, "fR": GRIP, "spine": 24.0, "neck": 16.0}
		"hold":    # yerde yatanın başını ve göğsünü tutar
			var o: Node3D = s["with"]
			var a2 = []
			if is_instance_valid(o):
				a2 = _ik(n, "Left", _bone(o, "Head") + Vector3.UP * 0.02, 38.0)
				a2.append_array(_ik(n, "Right", _bone(o, "Chest") + Vector3.UP * 0.1, 38.0))
			return {"arms": a2, "fL": HALF, "fR": HALF, "spine": 38.0, "neck": 22.0}
		"last":    # yatarken eli uzanır, sonra düşer
			var k = float(s.get("kk", 0.0))
			var sh = _bone(n, "RightUpperArm")
			var to: Vector3 = s["to"]
			var low = sh + (to - sh).normalized() * 0.3 * Vector3(1, 0, 1) + Vector3.DOWN * 0.1
			return {"arms": _ik(n, "Right", low.lerp(to, k)), "fL": HALF, "fR": OPEN, "spine": 0.0, "neck": 0.0}
		"grief":   # yumruklar yerde, baş önde
			var sob = sin(t * 7.0) * 2.0
			return {"arms": [["LeftUpperArm", Vector3(0.22, -0.8, 0.5)], ["RightUpperArm", Vector3(-0.22, -0.8, 0.5)],
				["LeftLowerArm", Vector3(0.05, -0.92, 0.35)], ["RightLowerArm", Vector3(-0.05, -0.92, 0.35)]],
				"fL": GRIP, "fR": GRIP, "spine": 44.0 + sob, "neck": 30.0}
		"point":
			var dv: Vector3 = s["dir"]
			var tg = _bone(n, "RightUpperArm") + dv * 0.55 + Vector3.UP * 0.04
			return {"arms": _ik(n, "Right", tg), "fL": HALF, "fR": [0.05, 0.95, 1.1, 1.2, 0.6], "spine": 0.0, "neck": 0.0}
		"support": # yanındakinin sırtına kol atar
			var o2: Node3D = s["with"]
			var a3 = []
			if is_instance_valid(o2):
				a3 = _ik(n, String(s.get("side", "Right")), _bone(o2, "Chest") - _fd(o2) * 0.14 + Vector3.UP * 0.05)
			return {"arms": a3, "fL": HALF, "fR": HALF, "spine": 4.0, "neck": 6.0}
		"clasp":   # yatağın yanında, elini iki eliyle tutar
			var c2: Vector3 = s["c"]
			var a4 = _ik(n, "Left", c2 - right * 0.03, 16.0)
			a4.append_array(_ik(n, "Right", c2 + right * 0.03, 16.0))
			return {"arms": a4, "fL": HALF, "fR": HALF, "spine": 14.0, "neck": 12.0}
		"place":   # önüne, yere bir şey bırakır
			var c3: Vector3 = s["c"]
			return {"arms": _ik(n, "Right", c3 + Vector3.UP * 0.05, 40.0), "fL": HALF, "fR": HALF, "spine": 40.0, "neck": 20.0}
	return super._make(n, s)


# ------------------------------------------------------------------ ulak: haber
func _ulak(at: Vector3) -> Villager:
	var m = Villager.new()
	m.role = "nurse"
	var lk = ClanWorld.clan_look("", "chunin", Progress.home(), false, "adult")
	Outfits.village_set(lk, Progress.home(), false)
	m.look_extra = lk
	m.display_override = "Ulak"
	Friends.inst().get_parent().add_child(m)
	at.y = Game.ground_height(at.x, at.z)
	m.global_position = at
	m.home = at
	m.goal = at
	m.set_physics_process(false)
	return m


func _news(lost: bool) -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	var e = entry()
	var from = Missions.open_ground(pl.global_position + pl.face_dir() * 20.0, 12.0)
	v = _ulak(from)
	await _wait(0.2)
	# koşarak gelir; yaklaşınca dönersin
	var t0 := 0.0
	while is_instance_valid(v) and t0 < 14.0:
		var to = pl.global_position - v.global_position
		to.y = 0
		if to.length() < 1.9:
			break
		var dt = get_process_delta_time()
		t0 += dt
		_turn(v, atan2(-to.x, -to.z), dt * 9.0)
		v.global_position += to.normalized() * 6.5 * dt
		v.global_position.y = Game.ground_height(v.global_position.x, v.global_position.z)
		v.model.play("run", 0.15, 0.85)
		if to.length() < 7.0 and not pl.get("scene_hold"):
			_lock(60.0)
			pl.model.play("idle", 0.2)
		if pl.get("scene_hold"):
			_look_at(pl, v.global_position, 0.15)
		await get_tree().process_frame
	if not is_instance_valid(v):
		return
	_lock(60.0)
	_look_at(pl, v.global_position)
	_look_at(v, pl.global_position)
	_pose(v, "tired", {"anim": "idle"})
	var me = String(pr().get("name", ""))
	if lost:
		_say(v, "%s... (soluk soluğa) Seni arıyordum." % me, 3.0)
		await _wait(2.6)
		_clear_pose(v)
		_pose(v, "bow", {"anim": "idle", "len": 5.0})
		_say(v, "%s %s... bulduk. Yetişemedik. Başın sağ olsun." % [rel_word(id), short(id)], 4.5)
		await _wait(2.0)
		_pose(pl, "grief", {"anim": "idle", "sit": "seiza"})
		Sfx.play("heartbeat", pl.global_position, 0.6)
		await _wait(3.2)
		if not e.is_empty():
			_say(v, "Yapan belli: «%s». Bingo Kitabı'na işlendi." % String(e["alias"]), 4.0)
		_kill(id, null, false)
		await _wait(3.6)
		_clear_pose(pl)
		pl.model.play("idle", 0.4)
	else:
		_say(v, "%s! (soluk soluğa) Sonunda... buldum seni!" % me, 3.0)
		await _wait(2.6)
		_clear_pose(v)
		v.model.play("talk", 0.2)
		var why = {"göz": "Gözlerinin peşindeler!", "kan": "Kanındaki gücün peşindeler!", "öç": "Seninle bir hesabı varmış!"}[String(d().get("motive", "öç"))]
		_say(v, "%s %s kaçırıldı! Yapan «%s» — Bingo Kitabı'ndaki kaçak. %s" % [rel_word(id), short(id), String(e.get("alias", "?")), why], 5.5)
		await _wait(1.2)
		pl.model.play("hit", 0.1, 0.8, true)
		await _wait(0.9)
		pl.model.play("idle", 0.3)
		await _tell("Ne?! Hangi yöne gittiler?", 2.6)
		var hp = Game.from_map(Vector2(e["hide"][0], e["hide"][1]))
		var dv = hp - v.global_position
		dv.y = 0
		dv = dv.normalized()
		_face(v, atan2(-dv.x, -dv.z))
		_pose(v, "point", {"anim": "idle", "dir": dv})
		_look_at(pl, pl.global_position + dv * 5.0)
		_say(v, "İzler şu yöne gidiyor. Uzaklaşmadan yetiş — geciktikçe sağ bulma şansın azalır!", 4.5)
		_mark()
		d()["stage"] = "hunt"
		await _wait(3.6)
		_clear_pose(v)
		Hud.msg("%s kaçırıldı. Saklandıkları yer haritada işaretli — çabuk ol." % short(id), Color(1.0, 0.7, 0.5), 7.0)
		Journal.add("%s kaçırıldı. Yapan: «%s». Peşlerine düştüm." % [String(f["name"]), String(e.get("alias", "?"))], "milestone")
	_release_player()
	# ulak köye koşar
	var away = v.global_position + (v.global_position - pl.global_position).normalized() * 30.0
	_say(v, "Ben Kage'ye haber veriyorum!" if not lost else "...Yalnız kalmak istersin.", 2.5)
	var t1 := 0.0
	while is_instance_valid(v) and t1 < (4.0 if not lost else 7.0):
		var to2 = away - v.global_position
		to2.y = 0
		var dt2 = get_process_delta_time()
		t1 += dt2
		_turn(v, atan2(-to2.x, -to2.z), dt2 * 9.0)
		v.global_position += to2.normalized() * (6.5 if not lost else 1.5) * dt2
		v.global_position.y = Game.ground_height(v.global_position.x, v.global_position.z)
		v.model.play("run" if not lost else "walk", 0.15, 0.85 if not lost else 1.0)
		await get_tree().process_frame
	if is_instance_valid(v):
		v.queue_free()
	Game.save_game()


# ------------------------------------------------------------------ kamp: tutsak + kaçak
func _camp() -> void:
	var pl = Game.player
	var dd = d()
	var f: Dictionary = Friends.all()[id]
	var eid = int(dd["eid"])
	foe = Missions._bb_spawned[eid][0]
	var late = float(dd["el"]) > T_HURT
	var hurt = float(dd["el"]) > T_SAFE
	var fp = foe.global_position
	var away = fp - pl.global_position
	away.y = 0
	away = away.normalized()
	var cp = fp + away * 3.2
	cp.y = Game.ground_height(cp.x, cp.z)
	v = Friends.inst()._spawn_npc(id, cp, false)
	v.set_physics_process(false)
	v.set_meta("captive", true)
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(v):
		return
	var sc: float = v.model.age_scale
	if late:
		await _late(cp, away)
		return
	_face(v, atan2(away.x, away.z))   # yüzü gelen yöne
	var b = MB.new()
	b.add("cyl", Vector3(0, 0.8, 0), Vector3(0.2, 1.6, 0.2), Color(0.36, 0.25, 0.15), Vector3.ZERO, 8)
	b.add("cyl", Vector3(0, 1.62, 0), Vector3(0.24, 0.05, 0.24), Color(0.3, 0.2, 0.12), Vector3.ZERO, 8)
	var post = _mesh(b)
	post.global_position = cp + away * 0.3
	extra.append(post)
	var rb = MB.new()
	for k in 3:
		rb.add("cyl", Vector3(0, (0.52 + k * 0.09) * sc, 0.12), Vector3(0.5, 0.035, 0.62), Color(0.72, 0.6, 0.38), Vector3(0, 0, 4.0 * (k - 1)), 12)
	var rope = _mesh(rb)
	rope.global_position = cp
	rope.global_basis = Basis(Vector3.UP, atan2(away.x, away.z))
	extra.append(rope)
	_pose(v, "bound", {"anim": "idle", "sit": "seiza", "slump": 30.0 if hurt else 8.0})
	var spoke = false
	while true:
		await _wait(0.25)
		if not is_instance_valid(v) or d().is_empty():
			return
		var gone = not is_instance_valid(foe) or foe.dead or foe.global_position.distance_to(cp) > 28.0
		var pd = pl.global_position.distance_to(cp)
		if not spoke and pd < 24.0 and not gone:
			spoke = true
			_foe_say({"göz": "O gözler artık benim. Sen de sıranı bekle.", "kan": "Bu kanın alıcısı çok. Çekil yolumdan.", "öç": "Geldin demek. Önce onu, sonra seni."}[String(dd.get("motive", "öç"))])
			_say(v, ("...%s..." if hurt else "%s! Dikkat et, çok güçlü!") % me_word(id).capitalize(), 3.0)
		if gone and pd < 30.0 and pl.hp > 0.0 and not pl.get("scene_hold"):
			break
		if pd > 170.0 or (not Missions._bb_spawned.has(eid) and not gone):
			v.queue_free()   # uzaklaştın: olay sürüyor, dönünce yine burada
			return
	await _wait(1.2)
	await _rescue(cp, away, hurt, rope)


func _rescue(cp: Vector3, away: Vector3, hurt: bool, rope: Node3D) -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	var sc: float = v.model.age_scale
	_lock(60.0)
	_say(v, "...Geldin. Biliyordum..." if hurt else "%s! Buradayım!" % me_word(id).capitalize(), 3.0)
	var front = cp - away * 0.72
	front.y = Game.ground_height(front.x, front.z)
	await _go_w(pl, front, 4.8)
	_look_at(pl, cp)
	_pose(pl, "untie", {"anim": "idle", "sit": "seiza", "c": cp - away * 0.2 + Vector3.UP * 0.6 * sc})
	await _tell("Tamam. Geçti. Buradayım.", 1.4)
	Sfx.play("slash", cp, 0.4)
	await _wait(1.2)
	if is_instance_valid(rope):
		rope.queue_free()
	Sfx.play("slash", cp, 0.5)
	await _wait(0.4)
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	_clear_pose(v)
	v.model.play("idle", 0.4)
	await _wait(0.8)
	if hurt:
		# ayakta duramaz: koluna girersin, birlikte yürürsünüz
		_pose(v, "tired", {"anim": "idle"})
		_say(v, "Ayakta... duramıyorum...", 2.6)
		await _wait(1.8)
		var side = away.cross(Vector3.UP).normalized()
		var by = v.global_position + side * 0.42
		by.y = Game.ground_height(by.x, by.z)
		await _go_w(pl, by, 1.6)
		var home_dir = (Game.from_map(Vector2(Game.village(Progress.home())["x"], Game.village(Progress.home())["y"])) - v.global_position)
		home_dir.y = 0
		home_dir = home_dir.normalized()
		_face(pl, atan2(-home_dir.x, -home_dir.z))
		_face(v, atan2(-home_dir.x, -home_dir.z))
		v.global_position = pl.global_position + home_dir.cross(Vector3.UP).normalized() * 0.4
		_pose(pl, "support", {"with": v, "side": "Right"})
		_pose(v, "support", {"with": pl, "side": "Left"})
		await _tell("Dayan. Seni hastaneye götürüyorum.", 1.6)
		var t0 := 0.0
		while t0 < 3.6 and is_instance_valid(v):
			var dt = get_process_delta_time()
			t0 += dt
			for n in [pl, v]:
				n.global_position += home_dir * 0.95 * dt
				n.global_position.y = Game.ground_height(n.global_position.x, n.global_position.z)
				n.model.play("walk", 0.25, 0.7)
			pl.velocity = Vector3.ZERO
			await get_tree().process_frame
		await Interiors.inst._fade(1.0, 0.6)
		_clear_pose(pl)
		pl.model.play("idle", 0.1)
		var hosp = Exams.find_point(["hospital"])
		if hosp != Vector3.INF and hosp != Vector3.ZERO:
			var hq = Missions.open_ground(hosp + Vector3(0, 0, 9.0), 14.0)
			pl.respawn(hq + Vector3(0, 0.3, 0))
		if is_instance_valid(v):
			v.queue_free()
		_close(id)
		Friends.injure(id, "Kaçıranların elinden yaralı kurtarıldı")
		Friends.add_bond(id, 10, true)
		f["news"] = "Beni sırtlayıp getirdiğin o yolu hiç unutmayacağım."
		Journal.add("%s yaralı ama hayatta: kurtardım, hastanede yatıyor." % String(f["name"]), "milestone")
		await _wait(0.6)
		await Interiors.inst._fade(0.0, 0.8)
		Hud.msg("%s hastaneye yetiştirildi. Yanına uğrayabilirsin." % short(id), Color(0.7, 0.95, 0.8), 6.0)
	else:
		# ayağa kalkar, sarılırsınız
		var near = v.global_position - away * 0.33
		near.y = Game.ground_height(near.x, near.z)
		_look_at(v, pl.global_position)
		await _go_w(pl, near, 1.4)
		_look_at(pl, v.global_position)
		_look_at(v, pl.global_position)
		_pose(v, "hug", {"with": pl, "anim": "idle", "hi": 0.08})
		_pose(pl, "hug", {"with": v, "anim": "idle", "hi": -0.08})
		_say(v, ["Geleceğini biliyordum. Bir an bile şüphe etmedim.", "Korktum... çok korktum. Ama gelirsin dedim.", "Bir daha göremeyeceğim sandım seni."].pick_random(), 3.6)
		await _wait(1.4)
		Combat.popup_text((_bone(pl, "Head") + _bone(v, "Head")) * 0.5 + Vector3.UP * 0.35, "♥", Color(1, 0.5, 0.65))
		await _wait(2.4)
		_clear_pose(pl)
		_clear_pose(v)
		pl.model.play("idle", 0.3)
		v.model.play("idle", 0.3)
		_say(v, "Eve dönelim. Herkes merak etmiştir.", 3.0)
		_close(id)
		Friends.add_bond(id, 12, true)
		f["news"] = "O gün gelmeseydin... neyse. Geldin. Yeter."
		Journal.add("Kaçırılan %s artık güvende: kurtardım." % String(f["name"]), "milestone")
		Progress.add_xp(120)
		await _wait(1.6)
		_release_player()
		# köye doğru koşar
		var hd = (Game.from_map(Vector2(Game.village(Progress.home())["x"], Game.village(Progress.home())["y"])) - v.global_position)
		hd.y = 0
		await _go_w(v, v.global_position + hd.normalized() * 34.0, 6.0)
		if is_instance_valid(v):
			v.queue_free()
	Game.save_game()


## Geç kaldın: son nefes
func _late(cp: Vector3, away: Vector3) -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	var e = entry()
	var eid = int(d()["eid"])
	var side = away.cross(Vector3.UP).normalized()
	_lie(v, cp, away)
	foe.set_physics_process(false)
	foe.global_position = cp + away * 1.3 + side * 1.1
	foe.global_position.y = Game.ground_height(foe.global_position.x, foe.global_position.z)
	while true:
		await _wait(0.2)
		if not is_instance_valid(v) or not is_instance_valid(foe):
			if is_instance_valid(v):
				v.queue_free()
			return
		var pd = pl.global_position.distance_to(cp)
		if pd < 17.0 and pl.hp > 0.0 and not pl.get("scene_hold"):
			break
		if pd > 170.0 or not Missions._bb_spawned.has(eid):
			if is_instance_valid(foe):
				foe.set_physics_process(true)
			v.queue_free()
			return
	_lock(90.0)
	_look_at(pl, cp)
	if foe.get("facing") != null:
		var tf = pl.global_position - foe.global_position
		foe.set("facing", atan2(-tf.x, -tf.z))
	_foe_say({"göz": "Geç kaldın. Gözler bende. Bir gün seninkiler için de gelirim.", "kan": "Geç kaldın. İstediğimi aldım.", "öç": "Şimdi ödeştik. Bu acıyla yaşa."}[String(d().get("motive", "öç"))])
	await _wait(3.0)
	# kaçak sıçrayıp kaybolur; Bingo Kitabı'nda yeni saklanma yeri
	var p0 = foe.global_position
	var t0 := 0.0
	while t0 < 0.7 and is_instance_valid(foe):
		t0 += get_process_delta_time()
		var k = t0 / 0.7
		foe.global_position = p0 + away * 26.0 * k + Vector3.UP * (9.0 * k - 5.0 * k * k)
		await get_tree().process_frame
	for n in Missions._bb_spawned.get(eid, []):
		if is_instance_valid(n):
			n.queue_free()
	Missions._bb_spawned.erase(eid)
	if not e.is_empty():
		var hide = Missions._spot(Progress.home(), 500, 1100)
		e["hide"] = hide
		e["area"] = [hide[0] + randf_range(-200, 200), hide[1] + randf_range(-200, 200)]
		e["known"] = 300.0
		e["tracked"] = true
	# yanına koşar, diz çöker
	var knee = cp + away * 0.95 + side * 0.5
	knee.y = Game.ground_height(knee.x, knee.z)
	await _go_w(pl, knee, 5.2)
	_look_at(pl, cp + away * 1.0)
	_pose(pl, "hold", {"anim": "idle", "sit": "seiza", "with": v})
	await _tell("%s! Hayır, hayır... bana bak!" % short(id), 2.4)
	var me = me_word(id)
	var rel = String(f.get("kin", ""))
	var lines = ["...%s... geldin..." % me.capitalize()]
	if rel in ["baba", "anne"]:
		lines.append("Ağlama. Seni büyürken görmek... bana yetti.")
		lines.append("Kendine iyi bak... kardeşine de...")
	elif rel == "kardeş":
		lines.append("Skoru... eşitleyemedim, ha...")
		lines.append("Benim yerime de... güçlü ol...")
	elif f.get("child", false):
		lines.append("Korkmadım... sen gelirsin dedim...")
		lines.append("Seninle... gurur duyuyor muydun?")
	else:
		lines.append("Evimiz... ışığı açık bırakmıştım...")
		lines.append("Seni sevmek... en güzel görevimdi.")
	for i in lines.size():
		_say(v, lines[i], 3.6)
		if i == 1:
			# eli yüzüne uzanır
			_pose(v, "last", {"to": _bone(pl, "Head") + Vector3.DOWN * 0.08, "kk": 0.0})
			v.model.overlay.foot_ik = false
			var tk := 0.0
			while tk < 1.0:
				tk += get_process_delta_time() / 1.1
				st[v]["kk"] = smoothstep(0.0, 1.0, tk)
				await get_tree().process_frame
			await _wait(2.4)
		else:
			await _wait(3.4)
	# el düşer
	if st.has(v):
		var tk2 := 1.0
		while tk2 > 0.0:
			tk2 -= get_process_delta_time() / 0.45
			st[v]["kk"] = maxf(tk2, 0.0)
			await get_tree().process_frame
	Sfx.play("heartbeat", cp, 0.6)
	await _wait(1.0)
	st.erase(v)
	v.model.overlay.set_pose("cast", 0.0)
	_kill(id, v, true)
	await _tell("...%s?" % short(id), 2.2)
	_pose(pl, "grief", {"anim": "idle", "sit": "seiza"})
	await _wait(4.2)
	Hud.msg("Katil: %s. Bingo Kitabı'nda izi sürülüyor." % String(f.get("killer_name", "?")), Color(1.0, 0.6, 0.5), 7.0)
	_clear_pose(pl)
	pl.model.play("idle", 0.4)
	# beden bir süre kalır (cenaze sistemi devralır)
	var body = v
	v = null
	Friends.inst().get_tree().create_timer(40.0, false).timeout.connect(func():
		if is_instance_valid(body):
			body.queue_free())


# ------------------------------------------------------------------ hastane: yatan yakın, başucu
func _ward() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var I = Interiors.inst
	if not is_inside_tree() or not Friends.all().has(id):
		return
	v = Friends.inst()._spawn_npc(id, Game.player.global_position, false)
	if v == null:
		return
	v.reparent(I.room)
	v.set_physics_process(false)
	v.interior = true
	I.npcs.append(v)
	await get_tree().process_frame
	_lie(v, I.L(3.42, 0.73, 6.6), Vector3(1, 0, 0), 0.0)
	v.set_meta("bedside", true)
	v.set_meta("ward", self)
	var b = MB.new()
	b.add("sphere", Vector3.ZERO, Vector3(1.45, 0.34, 0.92), Color(0.8, 0.9, 0.88), Vector3.ZERO, 14)
	var m = _mesh(b)
	m.global_position = I.L(3.3, 0.76, 6.6)


func bedside() -> void:
	if ward_busy or not is_instance_valid(v):
		return
	ward_busy = true
	Hud.close_dialog()
	var I = Interiors.inst
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	_lock(40.0)
	await _go_w(pl, I.L(3.75, 0.05, 5.7), 1.6)
	_face(pl, PI)   # yatağa dön (odanın derinine)
	_look_at(pl, I.L(3.75, 0.05, 6.6))
	var hand = I.L(3.7, 0.8, 6.2)
	_pose(pl, "clasp", {"anim": "idle", "sit": "seiza", "c": hand, "lift": 0.05})
	await _wait(1.2)
	var me = me_word(id)
	_say(v, ["Geldin mi, %s... Gözümü açınca seni görmek güzel." % me, "Merak etme, %s. Doktorlar iyi olacağımı söyledi." % me].pick_random(), 4.0)
	await _wait(3.4)
	await _tell("Dinlen. Ben buradayım.", 2.4)
	_say(v, ["Biraz daha kal... ne olur.", "Sen yanımdayken acımıyor, biliyor musun."].pick_random(), 3.6)
	await _wait(3.6)
	var now = Time.get_unix_time_from_system()
	var left = maxf(float(f.get("away", now)) - now, 0.0)
	f["away"] = now + left * 0.6
	f["inj_away"] = f["away"]
	f["visited_inj"] = f["away"]
	Friends.add_bond(id, 3, true)
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	_release_player()
	Hud.msg("Yanında olman iyi geldi: %s daha çabuk toparlanacak." % short(id), Color(0.7, 0.95, 0.8), 5.0)
	ward_busy = false


# ------------------------------------------------------------------ mezar başı
func _grave() -> void:
	var pl = Game.player
	var f: Dictionary = Friends.all()[id]
	var told = f.get("avenged", false) and not f.get("avenged_told", false)
	Hud.close_dialog()
	_lock(40.0)
	var fd = pl.face_dir()
	_pose(pl, "clap", {"anim": "idle", "sit": "seiza"})
	await _wait(2.2)
	var rel = String(f.get("kin", ""))
	var hi = {"baba": "Baba.", "anne": "Anne.", "kardeş": "%s." % short(id)}.get(rel, "%s." % short(id))
	await _tell(hi, 2.0)
	if told:
		await _tell("Bitti. Sana bunu yapan artık nefes almıyor.", 3.2)
		var spot = pl.global_position + fd * 0.55
		spot.y = Game.ground_height(spot.x, spot.z) + 0.02
		_pose(pl, "place", {"anim": "idle", "sit": "seiza", "c": spot})
		await _wait(1.0)
		var b = MB.new()
		b.add("box", Vector3.ZERO, Vector3(0.5, 0.012, 0.07), Color(0.14, 0.14, 0.18))
		b.add("box", Vector3(0, 0.012, 0), Vector3(0.15, 0.014, 0.065), Color(0.72, 0.74, 0.78))
		b.add("box", Vector3(0, 0.02, 0), Vector3(0.16, 0.004, 0.008), Color(0.12, 0.1, 0.1))   # çizik
		# bant mezarda kalır (sahne bitince silinmez)
		var band = MeshInstance3D.new()
		band.mesh = b.build(mat)
		Friends.inst().get_parent().add_child(band)
		band.global_position = spot
		band.global_basis = Basis(Vector3.UP, pl.facing + 0.3)
		Friends.inst().get_tree().create_timer(600.0, false).timeout.connect(func():
			if is_instance_valid(band):
				band.queue_free())
		await _wait(0.8)
		await _tell("Bandını getirdim. Artık rahat uyu.", 3.0)
		f["avenged_told"] = true
		f["grief_done"] = true
		Journal.add("Katilin bandını mezarına bıraktım: %s." % String(f["name"]), "milestone")
	else:
		var say = ["Bugün de geldim. Anlatacak çok şey var.", "Seni özledim. Hepsi bu.", "Daha güçlü oldum. Görsen tanımazdın."]
		if f.has("killer") and not f.get("avenged", false):
			say = ["Onu bulacağım. Söz veriyorum.", "Henüz bitmedi. Ama bitecek."]
		await _tell(say.pick_random(), 3.2)
	_pose(pl, "bow", {"anim": "idle", "sit": "seiza", "len": 3.0})
	await _wait(3.2)
	_clear_pose(pl)
	pl.model.play("idle", 0.4)
	Game.save_game()
