class_name GeninSquad
extends Node
## Genin takımı: Zil Testi'ndeki iki takım arkadaşı + jōnin hoca kalıcı takımın olur (profil "squad").
## Genin olduğun sürece dünyada yanında yürür ve seninle savaşırlar; düşen geri çekilir, bir süre sonra döner.
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
	return p.get("squad", {})


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
	var names = [["Hayato", "m", "diken"], ["Sayuri", "f", "uzun"], ["Kenta", "m", "kase"], ["Mio", "f", "atkuyruğu"], ["Daichi", "m", "kısa"], ["Aoi", "f", "uzun"],
		["Ren", "m", "dağınık"], ["Hana", "f", "topuz"], ["Sora", "m", "diken"], ["Yui", "f", "atkuyruğu"]]
	names.shuffle()
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
		mates.append({"name": nm[0], "gender": nm[1], "hair_style": nm[2], "hair": _a(hairs[i]), "top": _a(tops[i]), "element": others[i % others.size()]})
	var hi = Progress.home_info()
	var sensei = {"name": String(hi.get("s2", "Kurogane-sensei")), "hair": _a(hairs[2]), "hair_style": ["diken", "kısa", "geriye", "dağınık"].pick_random(),
		"element": ELS.pick_random()}
	p["squad"] = {"mates": mates, "sensei": sensei, "state": "active", "follow": true}
	return p["squad"]


## Sınav/Zil Testi için takım arkadaşı arketipi (i: 0 / 1)
static func mate_arch(i: int, level: int) -> Dictionary:
	var sq = ensure_formed()
	var m: Dictionary = sq["mates"][i % 2]
	var a = Enemy.archetype("genin_rival", i)
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
	var auto = Enemy.auto_jutsu("rogue", String(s["element"]), level)
	if not auto.is_empty():
		a["jutsu"] = auto
		a["auto_jutsu"] = auto.duplicate()
		a["auto_lv"] = level
	var L: Dictionary = a["look"]
	L["hair"] = _c(s["hair"])
	L["hair_style"] = s["hair_style"]
	L["band_style"] = "head"
	L["band"] = hi["band"]
	L["vest"] = hi["vest"]
	L["village"] = Progress.home()
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
	if sq.get("state", "") != "active" or not sq.get("follow", true):
		return false
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
		a = sensei_arch(clampi(lv + 25, 40, 85))   # jōnin hoca: en az Sv.40
	else:
		a = mate_arch(int(key.substr(1)), maxi(5, lv - 1 + randi_range(0, 2)))
	var e = Enemy.new()
	e.setup(a)
	e.team = "player"
	e.set_meta("teammate", true)
	e.set_meta("respawn", false)
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
	if not _active():
		if not members.is_empty():
			_despawn_all()
		return
	if members.is_empty():
		for k in ["m0", "m1", "sensei"]:
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
			m["node"] = null
			m["down"] = RETURN_T
			var nm = _name_of(m["key"])
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
	Hud.dialog(who, txt, [
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
	sq["follow"] = true
	Hud.msg("Takımın yola çıktı, birazdan yanında.", Color(0.6, 1.0, 0.7))
