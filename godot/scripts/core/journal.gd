class_name Journal
extends RefCounted
## "Yolun": oyuncunun kendi hikâyesi. Sabit bir ana hikâye yok; Akademi'den mezun olduktan sonra (Progress.story() >= FREE)
## oyuncu kendi hedeflerini seçer, dünyada yaşadıkları günlüğe (kronik) yazılır, yenildiği bir rakip yıllar sonra geri dönebilir.
## Profil: profile["journal"] = [{"lv", "rank", "text", "kind"}], profile["goals"] = [id...], profile["rival"] = {...}, profile["seed"]

const FREE := 4          # 0..3 Akademi başlangıcı; 4 ve üstü serbest oyun
const MAX_LOG := 200

## Seçilebilir kişisel hedefler (hepsi isteğe bağlı; birden fazla seçilebilir)
const GOALS := {
	"chunin": {"name": "Chūnin ol", "desc": "Güç 30, 8 D-rank ve 4 C-rank görevle Chūnin Seçme Sınavı'na başvur ve jüriyi etkile.", "icon": "star"},
	"jonin": {"name": "Jōnin ol", "desc": "Chūnin'ken Güç 90, 6 B-rank + 4 A-rank görev ve ikinci doğa ile Kage Kulesi'nde terfi değerlendirmesi.", "icon": "star"},
	"anbu": {"name": "ANBU'ya katıl", "desc": "Jōnin + Güç 130 + 8 A-rank ve 2 S-rank görevle ANBU seçmelerine çağrılırsın.", "icon": "mask"},
	"kage": {"name": "Köyün Kage'si ol", "desc": "Güç 180, 5 S-rank görev ve köyde itibarla adaylık, Güç 200'de seçim. Köyün kaderi senin elinde olur.", "icon": "crown"},
	"legend": {"name": "Bir Efsane Yolu'na katıl", "desc": "Söylentileri takip et; gizli bir ustayı bul ve sınavını geç.", "icon": "scroll"},
	"beast": {"name": "Bir Kuyruklu Canavarla bağ kur", "desc": "Bir canavarı mühürle ya da onunla anlaş. Bedeli ağır olabilir.", "icon": "flame"},
	"summon": {"name": "Bir çağırma sözleşmesi imzala", "desc": "Sözleşme ustalarını ve gizli diyarları bul.", "icon": "scroll"},
	"explore": {"name": "Beş Büyük Köyü gör", "desc": "Konoha, Suna, Kiri, Kumo ve Iwa'ya ayak bas.", "icon": "map"},
	"dojutsu": {"name": "Bir dōjutsu uyandır", "desc": "Klanının gözü ya da başka bir yol... gözlerin açılsın.", "icon": "eye"},
	"master": {"name": "40 jutsu ustası ol", "desc": "Parşömenler, hocalar, klanın ve yollar: 40 farklı teknik öğren.", "icon": "book"},
	"bingo": {"name": "Ödül avcısı: 5 Bingo kaydı", "desc": "Bingo Kitabı'ndaki 5 kaçağı yakala ya da yen.", "icon": "target"},
	"rep": {"name": "Köyünün kahramanı ol", "desc": "Köyündeki itibarını 150'ye çıkar.", "icon": "heart"},
	"sage": {"name": "Sennin ol", "desc": "Doğa enerjisini kontrol etmeyi öğren.", "icon": "leaf"},
	"rich": {"name": "100.000 Ryō biriktir", "desc": "Görevler, ödüller, ticaret... ya da başka yollar.", "icon": "coin"},
	"rogue": {"name": "Köyünden kaç", "desc": "Alın bandını çiz, kendi yolunda yürü. Av-ninjaları peşine düşer.", "icon": "skull"},
}

static var _t := 0.0
static var _rival_t := 0.0


static func pr() -> Dictionary:
	return Game.profile


static func is_free() -> bool:
	return not pr().is_empty() and int(pr().get("story", 0)) >= FREE


# ------------------------------------------------------------------ kronik
## Günlüğe bir satır: "Güç 12 • Genin — Kumo'da bir tüccarı haydutlardan kurtardın."
static func add(text: String, kind := "") -> void:
	if pr().is_empty():
		return
	if not pr().has("journal") or not pr()["journal"] is Array:
		pr()["journal"] = []
	var j: Array = pr()["journal"]
	j.append({"lv": int(pr().get("level", 1)), "rank": Data.RANKS[clampi(int(pr().get("rank", 0)), 0, Data.RANKS.size() - 1)], "text": text, "kind": kind})
	if j.size() > MAX_LOG:
		j.remove_at(0)


static func entries() -> Array:
	return pr().get("journal", []) if pr().get("journal") is Array else []


# ------------------------------------------------------------------ hedefler
static func goals() -> Array:
	if not pr().get("goals") is Array:
		pr()["goals"] = []
	return pr()["goals"]


static func done_goals() -> Array:
	if not pr().get("goals_done") is Array:
		pr()["goals_done"] = []
	return pr()["goals_done"]


static func pick(id: String) -> void:
	if id in goals() or id in done_goals() or not GOALS.has(id):
		return
	goals().append(id)
	add("Kendine bir hedef koydun: %s." % GOALS[id]["name"], "goal")
	Hud.objective_changed()


static func drop(id: String) -> void:
	goals().erase(id)
	if String(pr().get("track", "")) == "goal:" + id:
		pr()["track"] = ""
	Hud.objective_changed()


static func goal_done(id: String) -> bool:
	var p = pr()
	var rk = int(p.get("rank", 0))
	match id:
		"chunin": return rk >= 2
		"jonin": return rk >= 3
		"anbu": return rk >= 4
		"kage": return rk >= 6
		"legend":
			for k in (p.get("paths", {}) as Dictionary):
				if int(p["paths"][k].get("s", 0)) >= 4:
					return true
			return false
		"beast": return TailedBeasts.player_jinchuriki() != ""
		"summon": return "kuchiyose" in p.get("learned", [])
		"explore":
			for v in ["konoha", "suna", "kiri", "kumo", "iwa"]:
				if not v in p.get("visited", []):
					return false
			return true
		"dojutsu": return (p.get("look", {}) as Dictionary).get("eye_r") != null or (p.get("look", {}) as Dictionary).get("eye_l") != null
		"master": return (p.get("learned", []) as Array).size() >= 40
		"bingo": return int(p.get("stats", {}).get("bingo_caught", 0)) >= 5
		"rep": return int(p.get("rep", {}).get(Progress.home(), 0)) >= 150
		"sage": return "sage" in p.get("skills", [])
		"rich": return int(p.get("ryo", 0)) >= 100000
		"rogue": return Orgs.is_rogue()
	return false


## Hedefin ilerleme notu (UI)
static func goal_progress(id: String) -> String:
	var p = pr()
	match id:
		"chunin": return "Güç %d/30 • D-rank %d/8 • C-rank %d/4" % [int(p["level"]), int(p["missions_done"].get("D", 0)), int(p["missions_done"].get("C", 0))]
		"jonin": return "Güç %d/90 • B-rank %d/6 • A-rank %d/4" % [int(p["level"]), int(p["missions_done"].get("B", 0)), int(p["missions_done"].get("A", 0))]
		"anbu": return "Güç %d/130 • A-rank %d/8 • S-rank %d/2" % [int(p["level"]), int(p["missions_done"].get("A", 0)), int(p["missions_done"].get("S", 0))]
		"kage": return "Güç %d/180 • S-rank %d/5 (adaylık)" % [int(p["level"]), int(p["missions_done"].get("S", 0))]
		"explore":
			var n = 0
			for v in ["konoha", "suna", "kiri", "kumo", "iwa"]:
				if v in p.get("visited", []):
					n += 1
			return "%d/5 köy" % n
		"master": return "%d/40 jutsu" % (p.get("learned", []) as Array).size()
		"bingo": return "%d/5 kaçak" % int(p.get("stats", {}).get("bingo_caught", 0))
		"rep": return "İtibar %d/150" % int(p.get("rep", {}).get(Progress.home(), 0))
		"rich": return "%d / 100.000 Ryō" % int(p.get("ryo", 0))
	return ""


## Hedefin dünyadaki yönü (takip oku için): {pos, name} ya da boş
static func goal_target(id: String) -> Dictionary:
	var kind = {"chunin": "chunin_exam", "jonin": "mission_board", "anbu": "anbu", "kage": "mission_board", "summon": "contract_keeper",
		"sage": "sage", "bingo": "bounty_board", "rep": "mission_board", "legend": "path_mentor"}.get(id, "")
	if id == "explore":
		var best = {}
		var bd = 1e12
		var pm = Game.to_map(Game.player.global_position) if Game.player else Vector2.ZERO
		for v in ["konoha", "suna", "kiri", "kumo", "iwa"]:
			if v in pr().get("visited", []) or Game.village(v).is_empty():
				continue
			var vv = Game.village(v)
			var d = pm.distance_to(Vector2(vv["x"], vv["y"]))
			if d < bd:
				bd = d
				best = {"pos": Game.from_map(Vector2(vv["x"], vv["y"])), "name": String(vv.get("name", v))}
		return best
	if kind == "":
		return {}
	var hv = Game.village(Progress.home())
	var hc = Vector2(float(hv.get("x", 0)), float(hv.get("y", 0)))
	var res = {}
	var bd2 = 1e12
	for it in Interact.items:
		if it.get("interior", false) or (it["kind"] != kind and it.get("alias", "") != kind):
			continue
		var d = Game.to_map(it["pos"]).distance_to(hc)
		if d < bd2:
			bd2 = d
			res = {"pos": it["pos"], "name": GOALS[id]["name"]}
	return res


## Takip edilmiyorsa oku gösterilecek ilk hedef
static func primary_target() -> Dictionary:
	for g in goals():
		var t = goal_target(String(g))
		if not t.is_empty():
			return t
	return {}


## HUD hedef satırı (serbest oyunda)
static func objective_text() -> String:
	var gs = goals()
	if gs.is_empty():
		if Orgs.is_rogue():
			return "Kaçak ninjasın. Av-ninjalarından uzak dur, kendi yolunu çiz. (Tab > Görevler > Yolun)"
		return "Yolun açık. Görev panosundan iş al, dünyayı dolaş ya da Tab > Görevler > Yolun'dan kendine bir hedef seç."
	var parts = []
	for g in gs:
		var pg = goal_progress(String(g))
		parts.append(GOALS[g]["name"] + (" (%s)" % pg if pg != "" else ""))
	return "Hedeflerin: " + ", ".join(parts)


# ------------------------------------------------------------------ zaman içinde kontroller (Progress._process'ten)
static func tick(dt: float) -> void:
	if not is_free():
		return
	_t += dt
	if _t < 2.0:
		return
	_t = 0.0
	for g in goals().duplicate():
		if goal_done(String(g)):
			goals().erase(g)
			done_goals().append(g)
			add("Hedefine ulaştın: %s." % GOALS[g]["name"], "goal_done")
			Hud.banner("HEDEF TAMAM", GOALS[g]["name"], Color(1, 0.85, 0.4))
			Progress.add_xp(300 + 25 * int(pr().get("level", 1)))
			Sfx.play("levelup", null, 1.2, 0.6)
			Hud.objective_changed()
	_rival_tick(2.0)


# ------------------------------------------------------------------ rakip: seni yenen biri geri döner
static func on_player_defeated() -> void:
	if not is_free() or Game.player == null:
		return
	var e = Combat.nearest_enemy(Game.player, 35.0)
	if e == null or not e is Enemy or e.get("arch") == null:
		return
	var a: Dictionary = e.arch
	if a.has("beast") or e.has_meta("bingo_id") or e.has_meta("hunter_nin") or not String(a.get("kind", "")) in ["rogue", "oto", "kumo", "kiri", "iwa", "suna", "samurai", "genin_rival", "bandit"]:
		return
	var nm = String(e.display_name)
	pr()["rival"] = {"name": nm, "kind": String(a["kind"]), "element": String(a.get("element", "")), "level": int(e.level), "wins": int(pr().get("rival", {}).get("wins", 0)) + 1 if String(pr().get("rival", {}).get("name", "")) == nm else 1, "t": 0.0}
	add("%s seni yere serdi. Bu yüzü unutmayacaksın." % nm, "rival")


static func _rival_tick(dt: float) -> void:
	var r = pr().get("rival")
	if not r is Dictionary or r.is_empty() or Game.player == null or Game.ui_open:
		return
	r["t"] = float(r.get("t", 0.0)) + dt
	if float(r["t"]) < 1500.0 or r.get("active", false):   # en erken 25 dk'da bir (8 dk idi)
		return
	if not Missions.active().is_empty() or int(ChuninExam.stage) != 0 or Exams.cur != "":
		return   # görevdeyken / sınavdayken rakip araya girmez
	# köy dışında, savaş yokken ara sıra karşına çıkar
	var m = Game.to_map(Game.player.global_position)
	for v in Game.world_info.get("villages", []):
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) + 60.0:
			return
	if randf() > 0.03:
		return
	r["active"] = true
	var e = Enemy.new()
	var a = Enemy.archetype(String(r["kind"]), 0)
	a["respawn"] = false
	a["name"] = "«Rakip» " + String(r["name"]).replace("«Rakip» ", "")
	var rlv = int(r.get("lv", randi_range(6, 12)))   # rakip kendi hızıyla güçlenir: her karşılaşmada biraz daha güçlü
	r["lv"] = rlv + randi_range(2, 5)
	a["level"] = rlv
	a["hp"] = float(a["hp"]) * 1.8 + rlv * 18.0
	a["power"] = float(a["power"]) * 1.25 + int(pr()["level"]) * 0.015
	if String(r.get("element", "")) != "":
		a["element"] = r["element"]
	e.setup(a)
	e.set_meta("rival", true)
	Game.player.get_tree().current_scene.add_child(e)
	var q = Game.player.global_position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 22.0
	q.y = Game.ground_height(q.x, q.z)
	e.global_position = q
	e.home = q
	Hud.banner("ESKİ BİR YÜZ", "%s: \"Seni yine buldum. Bu sefer de kazanacağımı mı sanıyorsun?\"" % String(r["name"]), Color(1, 0.5, 0.35))
	Hud.boss_bar(e)


static func on_enemy_killed(e: Node) -> void:
	if e.has_meta("rival"):
		var r: Dictionary = pr().get("rival", {})
		add("Seni bir zamanlar yenen %s'i bu kez sen yendin." % String(r.get("name", "rakibin")), "rival")
		Hud.banner("RÖVANŞ", "Eski rakibini yendin!", Color(1, 0.85, 0.4))
		Progress.add_xp(200 + 30 * int(pr().get("level", 1)))
		pr()["rival"] = {}
	elif e.has_meta("bingo_id"):
		pr()["stats"]["bingo_caught"] = int(pr()["stats"].get("bingo_caught", 0)) + 1
		add("Bingo Kitabı'ndaki %s artık bir tehdit değil." % String(e.display_name), "bingo")


## Eski kayıtlar: Naruto hikâye adımları (4..14) serbest oyuna çevrilir
static func migrate(p: Dictionary) -> void:
	if not p.has("seed"):
		p["seed"] = randi()
	var s = int(p.get("story", 0))
	if s >= FREE and not p.get("flags", {}).get("story_migrated", false):
		p["story"] = FREE
		if not p.has("flags"):
			p["flags"] = {}
		p["flags"]["story_migrated"] = true
		# eski hikâyenin yarım kalmış "Yasak Parşömen" görevi
		if String((p.get("active_mission", {}) as Dictionary).get("title", "")) == "Yasak Parşömen":
			p["active_mission"] = {}
		if not p.get("journal") is Array:
			p["journal"] = []
		(p["journal"] as Array).append({"lv": int(p.get("level", 1)), "rank": Data.RANKS[clampi(int(p.get("rank", 0)), 0, Data.RANKS.size() - 1)],
			"text": "Bundan sonrası tamamen senin hikâyen. Hedeflerini kendin seç.", "kind": "goal"})
