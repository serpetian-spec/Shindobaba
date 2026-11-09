class_name GeninSquad
extends Node
## Genin takımı: takım sınavındaki iki arkadaş + jōnin hoca kalıcı takımın olur (profil "squad").
## Üçü de Friends kaydıdır (sq_m0 / sq_m1 / sq_sensei): bağ, sohbet, hediye, antrenman; rütbe atlar, evlenir, ölebilirler.
## Görevleri hoca alır: önce 2 D-rank, sonra C-rank (isteğe bağlı — "Bu sefer yokum" denebilir). Hoca bir buluşma yeri söyler;
## oraya gidince takım toplanır ve görev başlar, görev bitince dağılırlar (köyde kendi hayatlarına döner, Friends ziyaretleriyle görünürler).
## Chūnin Sınavı'na da bu iki arkadaşla girersin (Exams.spawn_teammates squad'dan okur). Chūnin olunca takım dağılır.
## Hocanın yanında [F]: "Bizimle gelin" / "Köyde bekleyin".

const RETURN_T := 45.0
const ELS := ["katon", "suiton", "fuuton", "doton", "raiton"]

var members: Array = []    # [{"node": Enemy, "key": "m0"|"m1"|"sensei", "down": float}]
var t := 0.0


static func pr() -> Dictionary:
	return Game.profile


static func data() -> Dictionary:
	var p = pr()
	if p.is_empty():
		return {}
	var sq: Dictionary = p.get("squad", {})
	if not sq.is_empty() and not Friends.all().has("sq_sensei"):
		register_friends()   # eski kayıt: takım kalıcı dost olarak kaydolur
	return sq


static func _c(a) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2])) if a is Array and a.size() >= 3 else Color(0.3, 0.3, 0.3)


static func _a(c: Color) -> Array:
	return [snappedf(c.r, 0.01), snappedf(c.g, 0.01), snappedf(c.b, 0.01)]


## Takımı bir kez kur (Zil Testi başlarken ya da eski kayıtta Genin iken)
static func ensure_formed() -> Dictionary:
	var p = pr()
	if p.is_empty():
		return {}
	if p.has("squad"):
		return p["squad"]
	# her oyunda farklı takım: isimler üretilir (Chūnin sınavı adaylarıyla aynı üretici), cinsiyet ve saç rastgele
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var hs_m = ["diken", "kısa", "kase", "dağınık", "geriye"]
	var hs_f = ["uzun", "atkuyruğu", "topuz", "kısa", "kase"]
	var names = []
	for i in 2:
		var fem = rng.randf() < 0.5
		names.append([ChuninExam.gen_name(fem, rng).split(" ")[-1], "f" if fem else "m", (hs_f if fem else hs_m)[rng.randi() % 5]])
	var hairs = [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.55, 0.7), Color(0.2, 0.3, 0.6), Color(0.85, 0.85, 0.88)]
	hairs.shuffle()
	var tops = [Color(0.3, 0.45, 0.35), Color(0.6, 0.25, 0.2), Color(0.2, 0.3, 0.55), Color(0.85, 0.55, 0.2), Color(0.45, 0.3, 0.55), Color(0.2, 0.2, 0.22)]
	tops.shuffle()
	# takım dengesi: arkadaşlar oyuncudan farklı doğalar taşır
	var mine: Array = p.get("elements", ["katon"])
	var others = ELS.filter(func(e): return not e in mine)
	others.shuffle()
	var mates = []
	for i in 2:
		var nm: Array = names[i]
		mates.append({"name": nm[0], "gender": nm[1], "hair_style": nm[2], "hair": _a(hairs[i]), "top": _a(tops[i]), "element": others[i % others.size()], "medic": i == 1})
	var hi = Progress.home_info()
	var s_fem = rng.randf() < 0.35   # kanon: Kurenai gibi kadın jōnin hocalar da var
	var sensei = {"name": "%s-sensei" % ChuninExam.gen_name(s_fem, rng).split(" ")[-1], "gender": "f" if s_fem else "m", "hair": _a(hairs[2]),
		"hair_style": (hs_f if s_fem else ["diken", "kısa", "geriye", "dağınık"])[rng.randi() % 4], "element": ELS.pick_random()}
	p["squad"] = {"mates": mates, "sensei": sensei, "state": "active", "follow": true}
	register_friends()
	return p["squad"]


## Takımın jōnin hocasının adı (her oyunda üretilir; çan sınavı ve diyaloglar bunu kullanır)
static func sensei_name() -> String:
	var sq = ensure_formed()
	return String(sq.get("sensei", {}).get("name", Progress.home_info().get("s2", "Sensei")))


## Hocanın görünüşü (çan sınavındaki hoca da aynı kişi)
static func dress_sensei(L: Dictionary) -> void:
	var s: Dictionary = ensure_formed().get("sensei", {})
	if s.is_empty():
		return
	L["gender"] = String(s.get("gender", "m"))
	L["hair"] = _c(s["hair"])
	L["hair_style"] = s["hair_style"]


## Takım üyesinin Friends kimliği
static func fid(key: String) -> String:
	return "sq_sensei" if key == "sensei" else "sq_" + key


## Takımı Friends'e kalıcı karakter olarak kaydet (eski kayıtlar da ilk erişimde kaydolur)
static func register_friends() -> void:
	var p = pr()
	var sq: Dictionary = p.get("squad", {})
	if sq.is_empty():
		return
	var fs = Friends.all()
	for key in ["m0", "m1", "sensei"]:
		var id = fid(key)
		if fs.has(id):
			continue
		var a: Dictionary = sensei_arch(45) if key == "sensei" else mate_arch(int(key.substr(1)), 6)
		var lk: Dictionary = (a["look"] as Dictionary).duplicate()
		lk.erase("age")
		var female = String(lk.get("gender", "m")) == "f"
		var nm = _name_of_static(key)
		var rank = 2 if key == "sensei" else 0
		fs[id] = {"name": nm, "role": "teacher" if key == "sensei" else "spar", "ninja": true, "look": Friends._ser(lk), "bond": 10 if key == "sensei" else 20,
			"village": Progress.home(), "party": false, "last_talk": 0.0, "element": String((sq["sensei"] if key == "sensei" else sq["mates"][int(key.substr(1))]).get("element", ELS[absi(hash(key)) % ELS.size()])),
			"clan": "", "eye": [0, 0], "rank": rank, "family": Friends._family("", female, rank), "status": "", "log": [], "news": "",
			"title": "Jōnin hocan" if key == "sensei" else "Takım arkadaşın", "squad_key": key}


static func _name_of_static(key: String) -> String:
	var sq = pr().get("squad", {})
	if key == "sensei":
		return String(sq["sensei"]["name"])
	return String(sq["mates"][int(key.substr(1))]["name"])


## Üye yaşıyor ve köyde mi (ölü / uzun görevde / kaçak değil)
static func alive_here(key: String) -> bool:
	var f: Dictionary = Friends.all().get(fid(key), {})
	return f.is_empty() or String(f.get("status", "")) == ""


# ------------------------------------------------------------------ hocanın görevleri + buluşma
## Hoca görev önerir: ilk iki D-rank (tek adımlık işler), sonra C-rank. Kabul edersen buluşma yeri söyler.
static func request_mission() -> void:
	var sq = data()
	if sq.is_empty() or not alive_here("sensei"):
		Hud.msg("Hocan şu an köyde değil.", Color(1, 0.7, 0.4))
		return
	var who = String(sq["sensei"]["name"])
	if not Missions.active().is_empty() or sq.has("pending"):
		Hud.dialog(who, "Önce elimizdeki işi bitirelim.", [])
		return
	var done = int(sq.get("missions", 0))
	var rank = "D" if done < 2 else "C"
	var specs = MissionGen.specs(Progress.home(), [rank], 1)
	if specs.is_empty():
		Hud.dialog(who, "Bugün masada bize uygun bir iş yok. Yarın tekrar sor.", [])
		return
	var m: Dictionary = Missions._from_spec(Progress.home(), specs[0])
	if m.is_empty():
		Hud.dialog(who, "Bugün masada bize uygun bir iş yok. Yarın tekrar sor.", [])
		return
	m["squad"] = true
	var meet = Exams.find_point(["training"])
	var intro = "Görev masasından bir %s-rank aldım: \"%s\". %s" % [rank, String(m.get("title", "")), String(m.get("brief", ""))]
	if rank == "D" and done == 0:
		intro += "\n\nİlk işlerimiz basit olacak; takım olmayı önce bunlarla öğreneceğiz."
	intro += "\n\nAntrenman alanında buluşalım. Hazır olunca gel — gelmezsen başkasına veririz."
	Hud.dialog(who, intro, [
		{"label": "Geliyorum (buluşma: antrenman alanı)", "cb": func():
			sq["pending"] = m
			sq["meet"] = [meet.x, meet.y, meet.z]
			# haritanın takip sistemi (ok + ışık sütunu + harita işareti); görev işaretçisi takip tarafından eziliyordu
			Game.profile["waypoint"] = [meet.x, meet.y, meet.z, "Takım buluşması (antrenman alanı)"]
			Game.profile["track"] = "waypoint"
			Hud.msg("Buluşma yeri işaretlendi: antrenman alanı.", Color(0.6, 1.0, 0.7))},
		{"label": "Bu sefer yokum", "cb": func(): Hud.msg("%s başını salladı: \"Peki. Ama takım seni bekler, unutma.\"" % who, Color(0.85, 0.85, 0.9))}])


## Buluşma yerine gelince: takım toplanır, görev başlar
func _meet_tick() -> void:
	var sq = data()
	if not sq.has("meet") or Game.player == null:
		return
	var at = Vector3(float(sq["meet"][0]), float(sq["meet"][1]), float(sq["meet"][2]))
	if Game.player.global_position.distance_to(at) > 14.0:
		return
	var m: Dictionary = sq["pending"]
	sq.erase("meet")
	sq.erase("pending")
	sq["on_mission"] = true
	if Game.profile.get("waypoint") is Array and "Takım buluşması" in String(Game.profile["waypoint"][3]):
		Game.profile.erase("waypoint")
	Game.profile["track"] = "mission"   # görev başladı: ok artık görevi gösterir
	Hud.dialog(String(sq["sensei"]["name"]), "Hepimiz buradayız. Görev: \"%s\". Yola çıkıyoruz — birbirinizi kollayın!" % String(m.get("title", "")), [])
	Missions.accept(m)


## Görev bitti (ya da bırakıldı): takım dağılır, herkes kendi hayatına döner
func _mission_tick() -> void:
	var sq = data()
	if not sq.get("on_mission", false):
		return
	if not Missions.active().is_empty():
		return
	sq["on_mission"] = false
	sq["missions"] = int(sq.get("missions", 0)) + 1
	for key in ["m0", "m1", "sensei"]:
		if Friends.all().has(fid(key)):
			Friends.add_bond(fid(key), 4, true)   # birlikte görev: bağ güçlenir
	Hud.msg("Görev bitti, takım dağıldı. %s: \"İyi iş çıkardınız. Yeni bir iş olunca size haber veririm.\"" % String(sq["sensei"]["name"]), Color(0.6, 1.0, 0.7), 5.0)
	if int(sq["missions"]) == 2:
		Hud.msg("Hocan artık C-rank görevler alacak.", Color(1, 0.85, 0.5), 5.0)


## Sınav/Zil Testi için takım arkadaşı arketipi (i: 0 / 1)
static func mate_arch(i: int, level: int) -> Dictionary:
	var sq = ensure_formed()
	var m: Dictionary = sq["mates"][i % 2]
	var a = Enemy.archetype("genin_rival", i)
	a["no_clan"] = true
	var hi = Progress.home_info()
	a["name"] = "%s (takım)" % m["name"]
	a["respawn"] = false
	a["hp"] = 220.0 + level * 14.0
	a["level"] = level
	a["power"] = 0.9 + level * 0.01
	a["xp"] = 0
	a["ryo"] = 0
	a["element"] = m["element"]
	var auto = Enemy.auto_jutsu("genin_rival", String(m["element"]), level)
	if not auto.is_empty():
		a["jutsu"] = auto
		a["auto_jutsu"] = auto.duplicate()
		a["auto_lv"] = level
	var L: Dictionary = a["look"]
	L["keep_hair"] = true   # takım arkadaşı: her çağrıda aynı saç
	L["gender"] = m["gender"]
	L["hair_style"] = m["hair_style"]
	L["hair"] = _c(m["hair"])
	L["top"] = _c(m["top"])
	L["band"] = hi["band"]
	L["village"] = Progress.home()
	L["age"] = Player.age_for_rank(int(pr().get("rank", 1)))   # takım arkadaşları seninle aynı yaşta (Genin = genç)
	return a


static func sensei_arch(level: int) -> Dictionary:
	var sq = ensure_formed()
	var s: Dictionary = sq["sensei"]
	var hi = Progress.home_info()
	var a = Enemy.archetype("rogue", 0)
	a["no_clan"] = true
	a["name"] = "%s (hoca)" % s["name"]
	a["respawn"] = false
	a["hp"] = 900.0 + level * 30.0
	a["level"] = level
	a["power"] = 0.75   # jōnin hoca öğrencilerinin işini elinden almaz: destekler
	a["xp"] = 0
	a["ryo"] = 0
	a["guard"] = 0.55
	a["sub"] = 0.45
	a["aggr"] = 0.45
	a["element"] = s["element"]
	var arts = sensei_arts()
	var own = arts.filter(func(j): return String(Data.jutsu.get(j, {}).get("category", "")) == "ninjutsu")
	if not own.is_empty():
		a["jutsu"] = own.slice(maxi(0, own.size() - 4))   # savaşta kendi tekniklerini kullanır (öğrettikleri gözünün önünde)
	var L: Dictionary = a["look"]
	L["keep_hair"] = true   # takım arkadaşı: her çağrıda aynı saç
	L["gender"] = String(s.get("gender", "m"))
	L["hair"] = _c(s["hair"])
	L["hair_style"] = s["hair_style"]
	L["band_style"] = "head"
	L["band"] = hi["band"]
	L["village"] = Progress.home()
	Outfits.village_set(L, Progress.home())
	return a


## Chūnin olunca: hoca vedalaşır, takım dağılır
static func disband() -> void:
	var sq = data()
	if sq.is_empty() or sq.get("state", "") == "disbanded":
		return
	sq["state"] = "disbanded"
	var s = String(sq["sensei"]["name"])
	var a = String(sq["mates"][0]["name"])
	var b = String(sq["mates"][1]["name"])
	Hud.dialog(s, "Chūnin yeleğin yakışmış. Artık kendi takımını yönetecek, kendi kararlarını vereceksin. %s ve %s de kendi yollarına gidecek; ama takım bir kez kurulunca hiç bozulmaz. Bir gün yine aynı görevde buluşuruz." % [a, b], [])


## Köyden kaçınca takım bozulur: kaçağın peşinden gelmezler
static func on_defect() -> void:
	var sq = data()
	if sq.is_empty() or sq.get("state", "") != "active":
		return
	sq["state"] = "broken"
	Hud.msg("%s ve %s seni durdurmaya çalıştı ama yolunu seçtin. Artık bir takımın yok." % [sq["mates"][0]["name"], sq["mates"][1]["name"]], Color(1, 0.55, 0.5), 6.0)


## Affedilince hâlâ Genin'sen takımın geri döner
static func on_pardon() -> void:
	var sq = data()
	if sq.is_empty() or sq.get("state", "") != "broken":
		return
	if int(pr().get("rank", 0)) != 1:
		sq["state"] = "disbanded"
		return
	sq["state"] = "active"
	sq["follow"] = true
	Hud.dialog(String(sq["sensei"]["name"]), "Köyün kapısında %s ve %s bekliyordu; senden hiç vazgeçmediler. Takımın hâlâ burada. Hadi, bir görev bizi bekliyor." % [sq["mates"][0]["name"], sq["mates"][1]["name"]], [])


# ------------------------------------------------------------------ dünyada eşlik
func _active() -> bool:
	var p = pr()
	if p.is_empty() or Game.player == null or not is_instance_valid(Game.player):
		return false
	var sq: Dictionary = p.get("squad", {})
	if int(p.get("rank", 0)) != 1:
		return false
	if sq.is_empty():
		ensure_formed()   # eski kayıt: Genin ama takımı yok
		sq = p["squad"]
	if sq.get("state", "") != "active" or not sq.get("on_mission", false):
		return false   # takım yalnız hocanın görevlerinde birlikte (buluşmadan görev bitene kadar)
	if Exams.cur != "" or int(ChuninExam.stage) != 0:
		return false   # sınavlar kendi takımını kurar
	var life = get_parent().get_node_or_null("VillageLife")
	if life and life.interiors and life.interiors.inside != "":
		return false
	return true


func _spawn(key: String) -> Node:
	var lv = int(pr().get("level", 1))
	var a: Dictionary
	if key == "sensei":
		var srk = int(Friends.all().get(fid("sensei"), {}).get("rank", 2))
		a = sensei_arch(clampi(lv + 25 + (srk - 2) * 10, 40, 95))   # jōnin hoca: en az Sv.40; Elit Jōnin olunca güçlenir
	else:
		a = mate_arch(int(key.substr(1)), maxi(5, lv - 1 + randi_range(0, 2)))
	var e = Enemy.new()
	e.setup(a)
	e.team = "player"
	e.set_meta("teammate", true)
	e.set_meta("respawn", false)
	e.set_meta("friend_id", fid(key))
	get_tree().current_scene.add_child(e)
	if e.nameplate:
		e.nameplate.modulate = Color(0.55, 1.0, 0.6) if key != "sensei" else Color(0.6, 0.85, 1.0)
	var pp = Game.player.global_position
	var back = -Game.player.face_dir() if Game.player.has_method("face_dir") else Vector3.BACK
	var q = pp + back * 4.0 + back.cross(Vector3.UP) * (randf_range(-3.0, 3.0))
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
	if Game.paused:
		return
	t -= dt
	if t > 0.0:
		return
	t = 0.4
	if not pr().is_empty() and pr().has("squad"):
		_meet_tick()
		_mission_tick()
	if not _active():
		if not members.is_empty():
			_despawn_all()
		return
	if members.is_empty():
		for k in ["m0", "m1", "sensei"]:
			if alive_here(k):
				members.append({"key": k, "node": null, "down": 0.0})
	var pp = Game.player.global_position
	var i = 0
	for m in members:
		var n = m["node"]
		if n != null and is_instance_valid(n) and not n.is_dead():
			# takip: oyuncunun arkasında yay; çok uzaksa (hızlı yolculuk, ışınlanma) yanına gelir
			var off = Vector3(cos(i * 2.1 + 2.4), 0, sin(i * 2.1 + 2.4)) * (3.5 if m["key"] != "sensei" else 6.0)
			n.home = pp + off
			if n.global_position.distance_to(pp) > 60.0:
				var q = pp + off
				q.y = Game.ground_height(q.x, q.z)
				FX.smoke_puff(n.global_position + Vector3.UP, 0.6, 8)
				n.global_position = q
				n.target = null
				FX.smoke_puff(q + Vector3.UP, 0.6, 8)
			elif n.target == null:
				n.wander_to = pp + off
		elif n != null and (not is_instance_valid(n) or n.is_dead()):
			# düştü: geri çekilir, sonra döner
			var nm = _name_of(m["key"])
			var f: Dictionary = Friends.all().get(fid(m["key"]), {})
			if not f.is_empty() and randf() < (0.03 if m["key"] == "sensei" else 0.05):
				# kalıcı ölüm (nadir): Friends kaydı ölür; yakın ölüm Mangekyō uyanışını tetikleyebilir
				if n is Node3D and Game.player and Game.player.combat and Game.player.combat.modes and Game.player.combat.modes.get("eyes"):
					Game.player.combat.modes.eyes.on_ally_died(n)
				f["status"] = "öldü"
				Friends.log_event(f, "Takım görevinde senin yanında öldü")
				Hud.banner("%s ÖLDÜ" % nm.to_upper(), "Takımın artık eksik. Onu asla unutmayacaksın.", Color(0.85, 0.85, 0.95))
				m["node"] = null
				m["down"] = 1e9
			else:
				m["node"] = null
				m["down"] = RETURN_T
				Hud.msg("%s yaralandı ve geri çekildi. Biraz sonra yanına döner." % nm, Color(1, 0.75, 0.5))
		elif float(m["down"]) > 0.0:
			m["down"] = float(m["down"]) - 0.4
		else:
			m["node"] = _spawn(m["key"])
		i += 1


func _name_of(key: String) -> String:
	var sq = data()
	if key == "sensei":
		return String(sq["sensei"]["name"])
	return String(sq["mates"][int(key.substr(1))]["name"])


## Hocanın / arkadaşın yanında [F]: takımı yanına al ya da köyde beklet
func _unhandled_input(ev: InputEvent) -> void:
	if not ev.is_action_pressed("interact") or Game.player == null or Game.paused:
		return
	var p = pr()
	var sq: Dictionary = p.get("squad", {})
	if sq.is_empty() or sq.get("state", "") != "active" or int(p.get("rank", 0)) != 1:
		return
	for m in members:
		var n = m.get("node")
		if n != null and is_instance_valid(n) and not n.is_dead() and n.global_position.distance_to(Game.player.global_position) < 3.0:
			get_viewport().set_input_as_handled()
			_talk(m["key"])
			return


func _talk(key: String) -> void:
	var sq: Dictionary = data()
	var who = _name_of(key)
	var lines = ["Bugün hangi göreve gidiyoruz?", "Seninle aynı takımda olmak iyi. Arkanı ben kollarım.", "Chūnin Sınavı'na birlikte gireceğiz, unutma!",
		"Dün gece yeni bir mühür dizisi çalıştım; görmelisin."]
	var txt = lines.pick_random() if key != "sensei" else "Takımın hocası olarak yanınızdayım; ama işi siz bitirin. Ben yalnız işler kötüye giderse araya girerim."
	var extra: Array = []
	# takımın tıbbi ninjası (eski kayıtlarda ikinci arkadaş): sahada göz nakli yapabilir (kanon: Rin -> Kakashi)
	var mates: Array = sq.get("mates", [])
	if mates.size() > 1 and not mates.any(func(m): return bool(m.get("medic", false))):
		mates[1]["medic"] = true
	if key != "sensei" and bool(mates[int(key.substr(1))].get("medic", false)):
		var eo = EyeSurgery.options("medic")
		if not eo.is_empty():
			extra.append({"label": "Kavanozdaki gözü bana tak (sahada nakil)", "cb": func():
				Hud.dialog(who, "Tıbbi ninjutsum yeter... ama düşman yokken yapalım. Hangi göz, hangi yuva?", eo)})
	if key == "sensei":
		extra.append({"label": "Bana bir teknik öğretir misin?", "cb": func(): _lesson_menu()})
		extra.append({"label": "Görev var mı, hocam?", "cb": func(): request_mission()})
	var fd = fid(key)
	if Friends.all().has(fd):
		var nd = null
		for mm in members:
			if mm["key"] == key:
				nd = mm.get("node")
		extra.append_array(Friends._friend_opts(fd, nd))
	Hud.dialog(who, txt, extra + [
		{"label": "Takım: köyde bekleyin (tek başıma gideceğim)", "cb": func():
			sq["follow"] = false
			_despawn_all()
			Hud.msg("Takımın köyde bekliyor. Tekrar çağırmak için: Tab > Görevler > Takımı çağır.", Color(0.7, 0.9, 1.0))},
		{"label": "Devam edelim", "cb": func(): pass}])


## Görevler sekmesinden takımı yeniden çağır
static func recall() -> void:
	var sq = data()
	if sq.is_empty():
		return
	request_mission()   # takım artık hep peşinde değil: hocaya haber gönder, görev varsa buluşma yeri söyler


# ------------------------------------------------------------------ hocadan teknik öğrenme
## Hocanın kendi teknikleri (klan / kekkei genkai / göz / yasak / yol / imza DEĞİL): kendi doğasından ninjutsu (C..S) +
## bir genel teknik (taijutsu / genjutsu / akademi eğitmen dalı). Takım kurulunca bir kez seçilir, kayıtta sabit kalır.
const NOT_TEACH := ["clan", "kg", "eye", "kinjutsu", "quest", "sage", "path", "beast", "weapon", "contract", "locked"]


static func _teachable(jid: String) -> bool:
	var j = Data.jutsu.get(jid)
	if not j is Dictionary or jid.begins_with("_") or jid in Enemy.SIGNATURE or jid.begins_with("bashosen"):
		return false
	var lp = String(j.get("learn", "")).split(":")[0]
	if lp in NOT_TEACH or String(j.get("blood", "")) != "" or String(j.get("need", "")) != "" or String(j.get("virtual", "")) != "":
		return false
	return true


static func sensei_arts() -> Array:
	var sq = ensure_formed()
	if sq.is_empty():
		return []
	var s: Dictionary = sq["sensei"]
	if s.has("arts"):
		return s["arts"]
	var el = String(s["element"])
	# jōnin iki doğa taşır: kendi doğası + öğrencisinin doğası (yoksa öğretebileceği hiçbir şey öğrenciye uymazdı)
	var mine: Array = pr().get("elements", [])
	var el2 = String(mine[0]) if not mine.is_empty() and String(mine[0]) != el else ""
	var by_rank = {}
	var by2 = {}
	var general = []
	for jid in Data.jutsu:
		if not _teachable(jid):
			continue
		var j: Dictionary = Data.jutsu[jid]
		var lp = String(j.get("learn", ""))
		var r = int(Enemy.RANK_I.get(String(j.get("canon_rank", "")), -1))
		var jel = String(j.get("element", ""))
		if jel != "" and jel in [el, el2] and String(j.get("category", "")) == "ninjutsu" and (j.get("elements", []) as Array).size() <= 1 and r >= 2 and r <= 5:
			var bucket: Dictionary = by_rank if jel == el else by2
			if not bucket.has(r):
				bucket[r] = []
			bucket[r].append(jid)
		elif String(j.get("element", "")) == "" and lp in ["trainer:taijutsu", "trainer:genjutsu", "trainer:jonin"] and r >= 2 and r <= 4:
			general.append(jid)
	var out = []
	for r in [2, 3, 3, 4, 5]:   # C, iki B, A, S: yolun başından jōnin sırrına
		var pool: Array = (by_rank.get(r, []) as Array).filter(func(x): return not x in out)
		if not pool.is_empty():
			out.append(pool.pick_random())
	for r in [2, 3, 4]:   # öğrencinin doğasından C, B, A
		var pool2: Array = (by2.get(r, []) as Array).filter(func(x): return not x in out)
		if not pool2.is_empty():
			out.append(pool2.pick_random())
	if not general.is_empty():
		out.append(general.pick_random())
	out.sort_custom(func(a, b): return int(Data.jutsu[a].get("level", 1)) < int(Data.jutsu[b].get("level", 1)))
	s["arts"] = out
	return out


## Ders hakkı: takım kurulurken 1 + bitirilen her görev 1 (hoca emeği görür)
static func lessons_left() -> int:
	var sq = data()
	return 1 + Progress.genin_missions() - int(sq.get("lessons", 0))


func _sensei_node() -> Node:
	for m in members:
		if m["key"] == "sensei" and m["node"] != null and is_instance_valid(m["node"]) and not m["node"].is_dead():
			return m["node"]
	return null


func _lesson_menu() -> void:
	var sq: Dictionary = data()
	var who = String(sq["sensei"]["name"])
	var learned: Array = pr().get("learned", [])
	var opts = []
	var locked = []
	for jid in sensei_arts():
		if jid in learned:
			continue
		var j: Dictionary = Data.jutsu[jid]
		if Progress.element_block(jid) != "":
			continue   # doğana uymayan teknik hiç önerilmez (hoca senin doğana göre öğretir)
		var why = Progress.can_learn(jid)
		if why == "":
			opts.append({"label": "%s [%s]" % [String(j["name"]), String(j.get("canon_rank", "?"))], "tip": String(j.get("desc", "")), "cb": func(): _teach(jid)})
		else:
			locked.append("%s — %s" % [String(j["name"]).split(" (")[0], why])
	if opts.is_empty() and locked.is_empty():
		Hud.dialog(who, "Bildiğim her şeyi sana öğrettim. Gerisi senin yolun; kendi tekniğini kendin bul.", [])
		return
	var txt = "Klanımın ya da kanımın sırları değil, kendi emeğimle edindiğim teknikler bunlar. Hangisini göstermemi istersin?"
	if lessons_left() <= 0:
		txt = "Önce bir görev daha bitirelim. Sahada ne öğrendiğini görmeden yeni teknik vermem."
		opts.clear()
	if not locked.is_empty():
		txt += "

Henüz hazır değilsin:
" + "
".join(locked.slice(0, 5)) + ("
... ve %d teknik daha" % (locked.size() - 5) if locked.size() > 5 else "")
	opts.append({"label": "Sonra", "cb": func(): pass})
	Hud.dialog(who, txt, opts)


## Ders: hoca açık alana döner, mühürleri yavaşça yapıp tekniği gösterir; sonra öğrenci dener ve öğrenir
func _teach(jid: String) -> void:
	var sq: Dictionary = data()
	var who = String(sq["sensei"]["name"])
	var j: Dictionary = Data.jutsu[jid]
	var e = _sensei_node()
	sq["lessons"] = int(sq.get("lessons", 0)) + 1
	var jn = String(j["name"]).split(" (")[0]
	var seals: Array = j.get("seals", [])
	Hud.dialog(who, "İyi izle. %s%s" % [jn, (" — mühürler: " + " - ".join(seals)) if not seals.is_empty() else ""], [])
	if e != null and Game.player:
		# gösteri: oyuncudan uzağa, boş tarafa doğru (kimseye zarar vermeden)
		var away = (e.global_position - Game.player.global_position)
		away.y = 0
		if away.length() < 0.5:
			away = -Game.player.face_dir()
		away = away.normalized()
		var mark = TrainingDummy.new()   # hoca bir kukla diker ve tekniği ona gösterir
		mark.position = e.global_position + away * 10.0
		get_tree().current_scene.add_child(mark)
		FX.smoke_puff(mark.global_position + Vector3.UP, 0.7, 8)
		e.set_physics_process(false)
		e.facing = atan2(-away.x, -away.z)
		e.model.rotation = Vector3(0, e.facing, 0)
		CastAnim.play(e, jid, 1.2)   # yavaş, gösterir gibi mühür
		e.model.overlay.set_pose("seal", 1.0)
		await get_tree().create_timer(1.25).timeout
		if is_instance_valid(e):
			e.model.overlay.set_pose("seal", 0.0)
			Jutsu.execute(e, jid, mark)
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(e):
			e.set_physics_process(true)
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(mark):
			FX.smoke_puff(mark.global_position + Vector3.UP, 0.7, 8)
			mark.queue_free()
	else:
		await get_tree().create_timer(0.8).timeout
	if Progress.learn(jid):
		Journal.add("%s bana %s tekniğini öğretti." % [who, jn], "milestone")
		Hud.dialog(who, "Şimdi sen dene. İlk denemede olmazsa üzülme; ben de yüz kere yaktım ellerimi. Çalıştıkça ustalaşırsın.", [])
