extends Node
## Görev sistemi (autoload "Missions"). Rank: D C B A S. Hedef türleri: kill, collect, deliver, cat, dummies, boss.

const REWARD := {"D": [60, 50], "C": [220, 140], "B": [600, 380], "A": [1600, 900], "S": [6000, 2500]}
const RANK_FOR := {0: ["D"], 1: ["D", "C"], 2: ["C", "B"], 3: ["B", "A", "S"], 4: ["A", "S"]}

var board: Array = []
var board_village = ""
var pickups: Array = []
var target_marker = Vector3.ZERO
var has_marker = false


func active() -> Dictionary:
	return Game.profile.get("active_mission", {})


func _vpos(id: String, dx := 0.0, dy := 0.0) -> Vector3:
	var v = Game.village(id)
	return Game.from_map(Vector2(float(v["x"]) + dx, float(v["y"]) + dy))


func _templates(rank: String, here: String) -> Array:
	var t: Array = []
	var other = ["suna", "kiri", "kumo", "iwa", "ame", "kusa", "taki", "yu", "tani", "nami"].filter(func(x): return x != here)
	match rank:
		"D":
			t.append({"title": "Kayıp Kedi Mikan", "desc": "Daimyo'nun eşinin kedisi Mikan yine kaçtı! Köyde bul ve yakala.", "type": "cat", "count": 1})
			t.append({"title": "Şifalı Ot Toplama", "desc": "Hastane için Nara Ormanı'ndan 6 şifalı ot topla.", "type": "collect", "count": 6, "area": "nara_forest"})
			t.append({"title": "Antrenman Alanı Bakımı", "desc": "Antrenman Alanı 3'teki eski kuklaları devirerek test et (5 adet).", "type": "dummies", "count": 5})
			t.append({"title": "Paket Teslimi", "desc": "Bu paketi köyün güney kapısındaki nöbetçiye ulaştır.", "type": "deliver", "count": 1, "to": "gate"})
		"C":
			t.append({"title": "Haydut Temizliği", "desc": "Haydut Kampı tüccarları soyuyor. 6 haydut etkisiz hale getir.", "type": "kill", "count": 6, "enemy": "bandit", "where": "bandit_camp"})
			t.append({"title": "Kaçak Ninja Avı", "desc": "Ateş Ülkesi ormanlarında 2 kaçak ninja görüldü. Bul ve durdur.", "type": "kill", "count": 2, "enemy": "rogue", "spawn": true})
			var o: String = other.pick_random()
			t.append({"title": "Tüccar Mektubu", "desc": "Bu mektubu %s köy meclisine teslim et." % Game.village(o)["name"], "type": "deliver_village", "count": 1, "to": o})
		"B":
			t.append({"title": "Ses Ninjası Devriyesi", "desc": "Ses Ülkesi sınırında Oto ninjaları kamp kurmuş. 4 tanesini yen.", "type": "kill", "count": 4, "enemy": "oto", "spawn": true, "near": "valley_end"})
			var o2: String = other.pick_random()
			t.append({"title": "Gizli Belge", "desc": "Gizli belgeyi %s köyüne ulaştır. Yolda pusu olabilir!" % Game.village(o2)["name"], "type": "deliver_village", "count": 1, "to": o2, "ambush": "rogue"})
			t.append({"title": "Samuray Sınır Çatışması", "desc": "Demir Ülkesi sınırında başıboş samuraylar köylüleri tehdit ediyor. 3 tanesini yen.", "type": "kill", "count": 3, "enemy": "samurai", "spawn": true, "near": "tetsu"})
		"A":
			var k: String = ["kumo", "kiri", "iwa", "suna"].pick_random()
			t.append({"title": "Hain Chunin'ler", "desc": "%s'dan kaçan 4 chunin tehlikeli. Durdur." % Game.village(k)["name"], "type": "kill", "count": 4, "enemy": k, "spawn": true, "near": k})
			t.append({"title": "Kızıl Bulut İzleri", "desc": "Yağmur Ülkesi'ndeki gizli sığınağın çevresinde şüpheli ninjalar var. 5 tanesini yen.", "type": "kill", "count": 5, "enemy": "rogue", "spawn": true, "near": "hideout"})
		"S":
			t.append({"title": "Fırtınanın Kalbi: Raijū", "desc": "Yıldırım Ülkesi'ndeki Fırtına Kanyonu'nda dev bir canavar uyandı. Yen ve mühürle!", "type": "boss", "count": 1, "boss": "raiju", "near": "storm_canyon"})
			t.append({"title": "Kuklacı Mukuro", "desc": "Rüzgar Ülkesi'nde köyleri yağmalayan efsanevi kuklacı. Onu durdur.", "type": "boss", "count": 1, "boss": "puppeteer", "near": "suna"})
	for x in t:
		x["rank"] = rank
	return t


func open_board(it: Dictionary) -> void:
	var here = "konoha"
	var best = 1e9
	for v in Game.world_info["villages"]:
		var d: float = Game.to_map(it["pos"]).distance_to(Vector2(v["x"], v["y"]))
		if d < best:
			best = d; here = v["id"]
	board_village = here
	var cur = active()
	if not cur.is_empty():
		Hud.dialog("Görev Masası", "Aktif görevin: %s (%s)\n%s\nİlerleme: %d/%d" % [cur["title"], cur["rank"], cur["desc"], cur.get("progress", 0), cur["count"]],
			[{"label": "Görevi bırak", "cb": func(): abandon()}])
		return
	var ranks: Array = RANK_FOR[int(Game.profile["rank"])]
	board = []
	for r in ranks:
		var ts = _templates(r, here)
		ts.shuffle()
		board.append_array(ts.slice(0, 2))
	var opts = []
	for m in board:
		var rw: Array = REWARD[m["rank"]]
		opts.append({"label": "[%s] %s — %d Ryō" % [m["rank"], m["title"], rw[0]], "cb": accept.bind(m), "tip": m["desc"]})
	Hud.dialog("Görev Masası — %s" % Game.village(here)["name"], "Rütbene uygun görevler (%s):" % Data.RANKS[int(Game.profile["rank"])], opts)


func accept(m: Dictionary) -> void:
	m = m.duplicate(true)
	m["progress"] = 0
	Game.profile["active_mission"] = m
	_setup(m)
	Hud.banner("GÖREV: %s" % m["title"], "%s-rank" % m["rank"], Color(1, 0.75, 0.35))
	Hud.objective_changed()


func abandon() -> void:
	_cleanup()
	Game.profile["active_mission"] = {}
	Hud.objective_changed()


func _setup(m: Dictionary) -> void:
	var root = get_tree().current_scene
	has_marker = true
	match m["type"]:
		"cat":
			var c = CatNPC.new()
			root.add_child(c)
			c.global_position = _vpos("konoha", randf_range(-250, 250), randf_range(-250, 150))
			pickups.append(c)
			target_marker = c.global_position
		"collect":
			var a = Game.village(m["area"])
			for i in m["count"] + 2:
				var pk = Pickup.new()
				pk.item = "herb"
				root.add_child(pk)
				pk.global_position = Game.from_map(Vector2(a["x"] + randf_range(-150, 150), a["y"] + randf_range(-150, 150)))
				pickups.append(pk)
			target_marker = Game.from_map(Vector2(a["x"], a["y"]))
		"dummies":
			target_marker = _vpos("konoha", 300, 170)
		"deliver":
			Game.profile["inventory"]["package"] = 1
			target_marker = _vpos("konoha", 30, -415)
		"deliver_village":
			Game.profile["inventory"]["package"] = 1
			target_marker = _vpos(m["to"])
			if m.has("ambush"):
				var mid = Game.player.global_position.lerp(target_marker, 0.5)
				_spawn_group(m["ambush"], mid, 3)
		"kill":
			if m.get("spawn", false):
				var c: Vector3
				if m.has("near"):
					var v = Game.village(m["near"])
					c = Game.from_map(Vector2(v["x"] + randf_range(-120, 120), v["y"] + randf_range(-120, 120)))
				else:
					var pm = Game.to_map(Game.player.global_position)
					c = Game.from_map(pm + Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(250, 450))
				_spawn_group(m["enemy"], c, m["count"])
				target_marker = c
			else:
				target_marker = _vpos(m["where"])
		"boss":
			var v = Game.village(m["near"])
			var c = Game.from_map(Vector2(v["x"], v["y"]))
			var b = Boss.new()
			b.setup(Boss.make(m["boss"]))
			root.add_child(b)
			b.global_position = c
			b.home = c
			pickups.append(b)
			target_marker = c


func _spawn_group(kind: String, at: Vector3, n: int) -> void:
	for i in n:
		var e = Enemy.new()
		var a = Enemy.archetype(kind, i)
		a["respawn"] = false
		e.setup(a)
		e.set_meta("mission", true)
		get_tree().current_scene.add_child(e)
		var p = at + Vector3(randf_range(-12, 12), 0, randf_range(-12, 12))
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		pickups.append(e)


func _cleanup() -> void:
	for x in pickups:
		if is_instance_valid(x):
			x.queue_free()
	pickups.clear()
	has_marker = false
	Game.profile["inventory"].erase("package")


func _advance(n := 1) -> void:
	var m = active()
	if m.is_empty():
		return
	m["progress"] = int(m["progress"]) + n
	Hud.objective_progress("%s: %d/%d" % [m["title"], m["progress"], m["count"]])
	if int(m["progress"]) >= int(m["count"]):
		complete()


func complete() -> void:
	var m = active()
	var rw: Array = REWARD[m["rank"]]
	_cleanup()
	Game.profile["active_mission"] = {}
	Game.profile["missions_done"][m["rank"]] = int(Game.profile["missions_done"].get(m["rank"], 0)) + 1
	Hud.banner("GÖREV TAMAMLANDI", "%s  (+%d Ryō)" % [m["title"], rw[0]], Color(0.5, 1, 0.6))
	Progress.add_ryo(rw[0])
	Progress.add_xp(rw[1])
	if Progress.story() == 6 and int(Game.profile["missions_done"]["D"]) >= 3:
		Progress.set_story(7)
	Hud.objective_changed()
	Game.save_game()


# ------------------------------------------------------------------ olaylar
func on_kill(e: Node) -> void:
	var m = active()
	if m.is_empty():
		return
	if m["type"] == "kill" and e.get("arch") != null and e.arch.get("kind", "") == m["enemy"]:
		_advance()
	elif m["type"] == "boss" and e is Boss:
		_advance()


func on_dummy_broken() -> void:
	var m = active()
	if not m.is_empty() and m["type"] == "dummies":
		_advance()


func on_pickup(item: String) -> void:
	var m = active()
	if not m.is_empty() and m["type"] == "collect" and item == "herb":
		_advance()


func on_cat_caught() -> void:
	var m = active()
	if not m.is_empty() and m["type"] == "cat":
		_advance()


func on_interact(it: Dictionary) -> void:
	var m = active()
	if m.is_empty():
		return
	if m["type"] == "deliver" and it["kind"] == "gate":
		_advance()
	elif m["type"] == "deliver_village" and it["kind"] == "mission_board":
		var v = Game.village(m["to"])
		if Game.to_map(it["pos"]).distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			_advance()


func _process(_dt: float) -> void:
	var m = active()
	if m.is_empty():
		has_marker = false
		return
	has_marker = true
	if m["type"] == "cat" and not pickups.is_empty() and is_instance_valid(pickups[0]):
		target_marker = pickups[0].global_position
	if m["type"] == "collect":
		var best = 1e9
		for pk in pickups:
			if is_instance_valid(pk) and Game.player:
				var d: float = pk.global_position.distance_to(Game.player.global_position)
				if d < best:
					best = d; target_marker = pk.global_position


func spawn_scroll_thief() -> void:
	var c = _vpos("bandit_camp")
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["name"] = "Haydut Lideri Gouzan"
	a["hp"] = 220.0
	a["level"] = 7
	a["respawn"] = false
	a["xp"] = 250
	a["ryo"] = 300
	e.setup(a)
	e.set_meta("scroll_thief", true)
	get_tree().current_scene.add_child(e)
	e.global_position = c
	e.home = c
	target_marker = c
	has_marker = true
	Game.profile["active_mission"] = {"title": "Yasak Parşömen", "desc": "Haydut liderini yen.", "type": "story", "rank": "B", "count": 1, "progress": 0}
