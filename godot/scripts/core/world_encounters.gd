extends Node
## Yol karşılaşmaları (autoload "Encounters"): köy dışında gezerken arada bir, bölgeye uygun küçük olaylar.
## Abartmasın diye: karşılaşmalar arası en az birkaç dakika + en az ~400 m yol, aynı anda tek karşılaşma, art arda aynı tür yok.
## Türler: pusuya düşmüş tüccar, iki ninjanın düellosu (taraf seç), yaralı ninja, kaçak avlayan klan izcisi, kaçak devriyesi,
## gezgin falcı ve ateş gösterisi, yol kenarı tapınağı, kuyruklu canavar söylentisi, rakip takım, köprü haracı, kayıp çocuk,
## kaçak klan ninjası; bölgeye özel: kum fırtınası akıncıları (Rüzgar), sis pususu (Su), şimşek fırtınası (Yıldırım).

const GENERIC := ["merchant", "duel", "wounded", "hunter", "patrol", "performers", "shrine", "rumor", "rivals", "toll", "lost_child", "clan_rogue"]
const REGION := {
	"wind": ["sandstorm", "sandstorm", "sandstorm", "merchant", "toll", "wounded", "patrol", "clan_rogue", "performers"],
	"water": ["mist", "mist", "mist", "patrol", "wounded", "clan_rogue", "duel", "shrine"],
	"waves": ["mist", "mist", "merchant", "toll", "wounded", "patrol"],
	"whirlpool": ["mist", "mist", "shrine", "wounded", "clan_rogue"],
	"lightning": ["storm", "storm", "storm", "patrol", "wounded", "duel", "clan_rogue", "hunter"],
	"north": ["storm", "storm", "patrol", "wounded", "shrine"],
	"rain": ["patrol", "patrol", "wounded", "duel", "clan_rogue", "rumor"],
}
## Bölgenin kaçak klanları
const REGION_CLANS := {"fire": ["uchiha", "hyuga", "nara", "akimichi", "aburame", "inuzuka", "iburi", "shimura", "tsuchigumo", "namikaze", "yuhi", "gekko", "mitarashi", "shiranui"], "lightning": ["chinoike", "yotsuki"],
	"water": ["kaguya", "yuki", "hozuki", "hoshigaki", "funato", "momochi", "kurosuki", "hagoromo"], "wind": ["sabaku", "shirogane"], "earth": ["kamizuru", "jugo"],
	"rain": ["uchiha", "chinoike", "hozuki"]}
## Savaş karşılaşmaları (eski dost yardıma gelebilir)
const COMBAT := ["patrol", "mist", "sandstorm", "storm", "clan_rogue", "toll_revenge", "nemesis"]
const DIRS := ["kuzeyde", "kuzeydoğuda", "doğuda", "güneydoğuda", "güneyde", "güneybatıda", "batıda", "kuzeybatıda"]

var gap_t := 150.0
var dist_acc := 0.0
var check_t := 3.0
var last_pos := Vector3.INF
var last_kind := ""
var cur := {}        # etkin karşılaşma: kind, nodes, center, t, ...


func _process(dt: float) -> void:
	if Game.paused or Game.profile.is_empty() or Game.player == null:
		return
	var p := Game.player.global_position
	if last_pos != Vector3.INF:
		var step := Vector2(p.x - last_pos.x, p.z - last_pos.z).length()
		if step < 40.0:   # ışınlanma/hızlı seyahat sayılmaz
			dist_acc += step
	last_pos = p
	if not cur.is_empty():
		_tick(dt)
		return
	gap_t -= dt
	if gap_t > 0.0 or dist_acc < 400.0:
		return
	check_t -= dt
	if check_t > 0.0:
		return
	check_t = 4.0
	if not _can_start(p) or randf() > 0.3:
		return
	start(_pick_kind(p))


func _can_start(p: Vector3) -> bool:
	if int(ChuninExam.stage) != 0 or Exams.cur != "":
		return false   # sınav sürerken yol karşılaşması (haydut, haraççı...) yok
	if not ClanWorld._village_here(p).is_empty():
		return false
	if p.y > Game.terrain_height(p.x, p.z) + 300.0:   # iç mekân / gizli diyar
		return false
	if Game.terrain_height(p.x, p.z) < -1.0:
		return false
	if Hud.boss != null and is_instance_valid(Hud.boss):
		return false
	return true


func country_at(p: Vector3) -> String:
	var m := Game.to_map(p)
	var best := ""
	var bd := 1e9
	for c in Game.world_info["countries"]:
		var d := m.distance_to(Vector2(c["x"], c["y"])) / float(c["r"])
		if d < bd:
			bd = d
			best = c["id"]
	return best if bd < 1.0 else ""


func _pick_kind(p: Vector3) -> String:
	var fu := _followup()
	if fu != "" and randf() < 0.5:
		return fu
	var pool: Array = REGION.get(country_at(p), GENERIC).duplicate()
	if randf() < 0.35:
		pool.append_array(GENERIC)
	pool = pool.filter(func(k): return k != last_kind)
	return pool.pick_random()


# ------------------------------------------------------------------ yardımcılar
func _ahead(p: Vector3, dmin := 55.0, dmax := 85.0) -> Vector3:
	var fwd := -Game.player.global_transform.basis.z
	if Game.player.has_method("face_dir"):
		fwd = Game.player.face_dir()
	fwd.y = 0
	for i in 12:
		var dir := fwd.normalized().rotated(Vector3.UP, randf_range(-0.8, 0.8))
		# hızlıysan (tam hız, uçuş) olay daha ileride çıkar, yanından geçip gitmeyesin
		var spd := Vector2(Game.player.velocity.x, Game.player.velocity.z).length()
		var q := p + dir * (randf_range(dmin, dmax) + minf(spd * 4.0, 260.0))
		q.y = Game.ground_height(q.x, q.z)
		if Game.terrain_height(q.x, q.z) > -0.5 and absf(q.y - p.y) < 40.0:
			return q
	var q2 := p + Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))
	q2.y = Game.ground_height(q2.x, q2.z)
	return q2


func _dir_text(at: Vector3) -> String:
	var v := at - Game.player.global_position
	var a := fposmod(atan2(v.x, -v.z), TAU)    # 0 = kuzey (-z)
	return DIRS[int(round(a / (TAU / 8.0))) % 8]


func _lv() -> int:
	return int(Game.profile.get("level", 1))


func _npc(name: String, at: Vector3, look := {}, mode := "idle") -> EncounterNPC:
	var n := EncounterNPC.new()
	n.team = "neutral"   # varsayılan "enemy"di: takımdaki dostlar olay veren NPC'ye saldırıp öldürüyordu
	at = Missions.open_ground(at, 20.0)   # kayaya/duvara gömülmesin (tüccar kayboluyordu)
	n.display = name
	n.mode = mode
	if not look.is_empty():
		var lk := CharacterModel.default_look()
		lk.merge({"gender": ["m", "m", "f"].pick_random(), "hair_style": ["kısa", "uzun", "kase", "dağınık", "topuz"].pick_random(), "age": "adult"}, true)
		lk.merge(look, true)
		n.look = lk
	get_tree().current_scene.add_child(n)
	at.y = Game.ground_height(at.x, at.z)
	n.global_position = at
	n.home = at
	cur["nodes"].append(n)
	return n


func _enemy(kind: String, at: Vector3, i := 0, mods := {}) -> Enemy:
	var a := Enemy.archetype(kind, i)
	a["respawn"] = false
	var lv := Enemy.world_level(at)   # oyuncuya göre değil, bölgeye göre
	a["level"] = maxi(int(a["level"]), lv) if kind != "bandit" else clampi(lv, 2, 20)
	a["hp"] = float(a["hp"]) * (1.0 + a["level"] * 0.04)
	a["power"] = float(a["power"]) * (1.0 + a["level"] * 0.015)
	a.merge(mods, true)
	var e := Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	at = Missions.open_ground(at, 20.0)
	e.global_position = at
	e.home = at
	cur["nodes"].append(e)
	return e


func _around(c: Vector3, r: float, i: int, n: int) -> Vector3:
	var a := TAU * i / maxf(1.0, n) + randf_range(-0.3, 0.3)
	return c + Vector3(cos(a), 0, sin(a)) * r


func _alive(list: Array) -> Array:
	return list.filter(func(e): return is_instance_valid(e) and not e.dead)


func _marker(at: Vector3, txt: String, col := Color(1, 0.85, 0.4)) -> void:
	var l := Label3D.new()
	l.text = txt
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64
	l.outline_size = 12
	l.pixel_size = 0.02
	l.modulate = col
	l.no_depth_test = true
	l.fixed_size = false
	get_tree().current_scene.add_child(l)
	l.global_position = at + Vector3.UP * 6.0
	cur["nodes"].append(l)
	cur["label"] = l


func _reward(ryo: int, xp: int, txt: String) -> void:
	if ryo > 0:
		Progress.add_ryo(ryo)
	if xp > 0:
		Progress.add_xp(xp)
	Hud.banner("KARŞILAŞMA", "%s  (+%d Ryō, +%d XP)" % [txt, ryo, xp], Color(0.95, 0.85, 0.5))


func finish(delay := 25.0) -> void:
	if cur.is_empty() or cur.get("done", false):
		return
	_clear_wp()
	cur["done"] = true
	if cur.has("label") and is_instance_valid(cur["label"]):
		cur["label"].queue_free()
	var nodes: Array = cur["nodes"]
	get_tree().create_timer(delay).timeout.connect(func():
		for n in nodes:
			if is_instance_valid(n) and not (n is Enemy and n.dead):
				if n is Node3D:
					FX.smoke_puff(n.global_position + Vector3.UP, 0.8, 10)
				n.queue_free())
	cur = {}
	gap_t = randf_range(240.0, 480.0)
	dist_acc = 0.0


func _clear_wp() -> void:
	if cur.get("wp", false) and Game.profile.has("waypoint") and String(Game.profile["waypoint"][3]).begins_with("Olay:"):
		Game.profile.erase("waypoint")
		if String(Game.profile.get("track", "")) == "waypoint":
			Game.profile["track"] = ""


func _abort() -> void:
	_clear_wp()
	for n in cur.get("nodes", []):
		if is_instance_valid(n):
			n.queue_free()
	cur = {}
	gap_t = randf_range(120.0, 240.0)
	dist_acc = 0.0


# ------------------------------------------------------------------ başlatma
func start(kind: String) -> void:
	var p := Game.player.global_position
	last_kind = kind
	cur = {"kind": kind, "nodes": [], "t": 0.0, "center": _ahead(p)}
	var c: Vector3 = cur["center"]
	call("_start_" + kind, c)
	if cur.is_empty():
		return
	cur["center"] = c
	if kind in COMBAT and _has("ally") and randf() < 0.6:
		_ally_join()


func _start_merchant(c: Vector3) -> void:
	var m := _npc("Pusuya Düşmüş Tüccar", c, Outfits.roll("merchant", Outfits.village_near(c)), "cower")
	var bandits := []
	for i in 3:
		bandits.append(_enemy("bandit", _around(c, 4.5, i, 3), i, {"name": "Yol Kesen Haydut"}))
	cur["foes"] = bandits
	cur["npc"] = m
	_marker(c, "!")
	Hud.msg("%s bir çığlık duydun: \"İmdat! Haydutlar!\"" % _dir_text(c).capitalize(), Color(1, 0.75, 0.5))
	m.on_talk = func(n):
		if _alive(cur.get("foes", [])).is_empty():
			var ryo := 120 + _lv() * 12
			_reward(ryo, 30 + _lv() * 6, "Tüccarı kurtardın")
			remember({"k": "merchant", "name": "Tüccar " + ["Daikoku", "Hanbei", "Gonza", "Mameshiba", "Tōkichi", "Okuni"].pick_random(), "vid": Outfits.village_near(n.global_position)})
			Missions._rep(Progress.home(), 2)
			Hud.dialog(n.display, "Hayatımı kurtardın! Al, bu kesemin yarısı. Köye vardığımda adını herkese anlatacağım.", [])
			n.mode = "idle"
			finish()
		else:
			Hud.dialog(n.display, "Daha bitmedi! Arkanda!", [])


func _start_duel(c: Vector3) -> void:
	var vids := ["suna", "kiri", "kumo", "iwa", "oto"]
	vids.shuffle()
	var a := _enemy(vids[0], c + Vector3(-3, 0, 0), 0)
	var b := _enemy(vids[1], c + Vector3(3, 0, 0), 1)
	a.team = "duel_a"
	b.team = "duel_b"
	a.target = b
	b.target = a
	cur["a"] = a
	cur["b"] = b
	cur["asked"] = false
	_marker(c, "⚔")
	Hud.msg("%s çelik sesleri: iki ninja düello ediyor (%s ve %s)." % [_dir_text(c).capitalize(), Game.village(vids[0]).get("name", vids[0]), Game.village(vids[1]).get("name", vids[1])], Color(1, 0.8, 0.5))


func _start_wounded(c: Vector3) -> void:
	var w := _npc("Yaralı Ninja", c, Outfits.roll("chunin", Outfits.village_near(c)), "cower")
	_marker(c, "+", Color(0.6, 1.0, 0.6))
	FX.burst(c + Vector3.UP * 0.3, {"amount": 10, "life": 2.0, "add": false, "size": 0.4, "vmin": 0.1, "vmax": 0.4, "colors": [Color(0.55, 0.05, 0.05, 0.9), Color(0.4, 0, 0, 0)]})
	Hud.msg("%s inleyen birini görüyorsun." % _dir_text(c).capitalize(), Color(0.7, 1, 0.7))
	w.on_talk = func(n):
		Hud.dialog(n.display, "Pusu... kaçak ninjalar... takımımı dağıttılar. Lütfen... biraz chakra...", [
			{"label": "İlk yardım yap (25 chakra)", "cb": func():
				if Game.player.chakra < 25.0:
					Hud.msg("Yeterli chakran yok.", Color(1, 0.5, 0.4))
					return
				Game.player.chakra -= 25.0
				FX.burst(n.global_position + Vector3.UP, {"amount": 30, "life": 1.0, "size": 0.5, "vmin": 0.5, "vmax": 2.0, "gravity": Vector3(0, 2, 0),
					"colors": [Color(0.5, 1.0, 0.6, 1), Color(0.3, 0.9, 0.5, 0)]})
				n.mode = "idle"
				_reward(60 + _lv() * 6, 50 + _lv() * 8, "Yaralı ninjayı iyileştirdin")
				remember({"k": "contact", "name": "Chūnin " + ["Ibuki", "Sōsuke", "Kagari", "Tōya", "Nagisa", "Yoshino"].pick_random()})
				_hint_bounty(n)
				if randf() < 0.45:
					_ambushers(n.global_position)
				else:
					finish()},
			{"label": "Kendi başının çaresine bak", "cb": func(): finish(5.0)}])


func _hint_bounty(n: Node) -> void:
	for e in Missions._bingo()["list"]:
		if e["status"] == "alive":
			e["known"] = maxf(60.0, float(e["known"]) * 0.5)
			e["area"] = [lerpf(e["area"][0], e["hide"][0], 0.6), lerpf(e["area"][1], e["hide"][1], 0.6)]
			Hud.dialog(n.display, "Teşekkürler... Bir şey söyleyeyim: «%s» denen kaçağı %s civarında gördüm. Bingo Kitabı'na bak." % [e["alias"], Game.region_name(Game.from_map(Vector2(e["area"][0], e["area"][1])))], [])
			return


func _ambushers(at: Vector3) -> void:
	Hud.msg("Saldırganlar geri döndü!", Color(1, 0.4, 0.3))
	var foes := []
	for i in 2:
		foes.append(_enemy("rogue", _around(at, 14.0, i, 2), i))
	cur["foes"] = foes
	cur["after"] = "ambush"


func _start_hunter(c: Vector3) -> void:
	var tracker_clan: String = ["hyuga", "inuzuka", "aburame"].pick_random()
	var h := _npc(ClanWorld.person_name(tracker_clan, randf() < 0.4), c, ClanWorld.clan_look(tracker_clan, "chunin", "konoha"), "idle")
	if tracker_clan == "hyuga":
		h.model.set_dojutsu_eyes(2, 1, 2, 1, true)
	var reg := country_at(c)
	var rogue_clan: String = (REGION_CLANS.get(reg, ["uchiha", "hyuga", "kaguya", "chinoike", "yuki"]) as Array).pick_random()
	cur["npc"] = h
	cur["rogue_clan"] = rogue_clan
	_marker(c, "?")
	Hud.msg("%s bir izci ninja seni işaret ediyor." % _dir_text(c).capitalize(), Color(0.8, 0.9, 1))
	h.on_talk = func(n):
		if cur.has("foes"):
			if _alive(cur["foes"]).is_empty():
				_reward(200 + _lv() * 20, 80 + _lv() * 10, "Kaçak %s etkisiz" % ClanWorld.clan_name(rogue_clan))
				Game.profile["flags"]["klan_dostu_" + tracker_clan] = true
				Hud.msg("%s klanı artık seni dost biliyor." % ClanWorld.clan_name(tracker_clan), Color(0.8, 0.9, 1))
				Hud.dialog(n.display, "Köyüm sana borçlu. Gözleri... onlarla ne yapacağın senin vicdanına kalmış.", [])
				finish()
			else:
				Hud.dialog(n.display, "Odaklan! Klan teknikleri öldürücüdür!", [])
			return
		Hud.dialog(n.display, "%s klanından bir kaçağın izini sürüyorum. Tek başıma yetmem. Yardım eder misin? Ödül köyden." % ClanWorld.clan_name(rogue_clan), [
			{"label": "Yardım et", "cb": func():
				var at := _ahead(n.global_position, 35.0, 50.0)
				var e: Enemy = ClanWorld.spawn_enemy(rogue_clan, maxi(4, Enemy.world_level(at)), at)
				e.set_meta("eye_share", n.display)   # gözleri paylaşılır: biri oyuncuya, biri izciye
				cur["nodes"].append(e)
				cur["foes"] = [e]
				n.mode = "follow"
				n.team = "player"
				Hud.msg("Kaçak %s ileride! (%s)" % [ClanWorld.clan_name(rogue_clan), _dir_text(at)], Color(1, 0.6, 0.4))},
			{"label": "Başka işim var", "cb": func(): finish(5.0)}])


func _start_patrol(c: Vector3) -> void:
	var foes := []
	for i in randi_range(2, 3):
		foes.append(_enemy("rogue", _around(c, 3.0, i, 3), i, {"name": "Kaçak Devriyesi"}))
	cur["foes"] = foes
	cur["after"] = "loot"
	Hud.msg("%s kaçak ninjaların devriyesi var. Dikkat." % _dir_text(c).capitalize(), Color(1, 0.6, 0.45))


func _start_performers(c: Vector3) -> void:
	var f := _npc("Gezgin Falcı", c, Outfits.roll("traveler", Outfits.village_near(c)), "idle")
	var fire := _npc("Ateş Yutan Gösterici", c + Vector3(3.5, 0, 1), Outfits.roll("civ", Outfits.village_near(c)), "idle")
	for i in 4:
		var lp := c + Vector3(cos(i * 1.6) * 4.5, 2.2, sin(i * 1.6) * 4.5)
		var lan := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.3
		sm.height = 0.7
		lan.mesh = sm
		var mt := StandardMaterial3D.new()
		mt.albedo_color = Color(0.95, 0.25, 0.15)
		mt.emission_enabled = true
		mt.emission = Color(1.0, 0.45, 0.2)
		mt.emission_energy_multiplier = 1.6
		lan.material_override = mt
		get_tree().current_scene.add_child(lan)
		var gy := Game.ground_height(lp.x, lp.z)
		lan.global_position = Vector3(lp.x, gy + 2.2, lp.z)
		cur["nodes"].append(lan)
		var pole := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.05
		pm.bottom_radius = 0.07
		pm.height = 2.9
		pole.mesh = pm
		pole.material_override = Props.toon_color(Color(0.42, 0.3, 0.2))
		get_tree().current_scene.add_child(pole)
		pole.global_position = Vector3(lp.x + 0.4, gy + 1.45, lp.z)
		cur["nodes"].append(pole)
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.5, 0.05, 0.05)
		arm.mesh = am
		arm.material_override = pole.material_override
		get_tree().current_scene.add_child(arm)
		arm.global_position = Vector3(lp.x + 0.2, gy + 2.85, lp.z)
		cur["nodes"].append(arm)
		var ol := OmniLight3D.new()
		ol.light_color = Color(1.0, 0.5, 0.3)
		ol.light_energy = 1.0
		ol.omni_range = 5.0
		lan.add_child(ol)
	cur["show_t"] = 2.0
	cur["fire_npc"] = fire
	_marker(c, "♪", Color(1, 0.7, 0.9))
	Hud.msg("%s fenerler ve davul sesi: gezgin göstericiler." % _dir_text(c).capitalize(), Color(1, 0.8, 0.9))
	f.on_talk = func(n):
		var cost := 40 + _lv() * 3
		Hud.dialog(n.display, "Ellerini göster ninja... Yıldızların sana bir şey söylüyor. %d Ryō karşılığında falına bakarım." % cost, [
			{"label": "Fal baktır (%d Ryō)" % cost, "cb": func():
				if int(Game.profile.get("ryo", 0)) < cost:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-cost)
				var fate: Array = [["Rüzgar arkandan esiyor: adımların hafif olacak.", "fal_hiz", {"speed": 1.1}],
					["Ateşin iraden güçlü: jutsuların daha sert vuracak.", "fal_jutsu", {"jutsu": 1.12}],
					["Bir kalkan görüyorum: darbeler seni zor yaralar.", "fal_zirh", {"armor": 0.88}],
					["Yumrukların taş gibi: yakın dövüşte rakipsizsin.", "fal_yumruk", {"melee": 1.12}]].pick_random()
				Buffs.add(fate[1], 600.0, fate[2])
				Hud.dialog(n.display, "%s (10 dakika)" % fate[0], [])
				finish(40.0)},
			{"label": "Gösteriyi izle", "cb": func(): cur["show_t"] = 0.0}])


func _start_shrine(c: Vector3) -> void:
	var root := Node3D.new()
	get_tree().current_scene.add_child(root)
	root.global_position = Vector3(c.x, Game.ground_height(c.x, c.z), c.z)
	cur["nodes"].append(root)
	var red := Props.toon_color(Color(0.86, 0.16, 0.1))
	var black := Props.toon_color(Color(0.12, 0.1, 0.1))
	var wood := Props.toon_color(Color(0.5, 0.35, 0.22))
	var roofm := Props.toon_color(Color(0.22, 0.24, 0.3))
	var stone := Props.toon_color(Color(0.64, 0.63, 0.6))
	var paper := Props.toon_color(Color(0.97, 0.96, 0.9))
	# taş zemin (iki basamak) ve yol taşları
	_box(root, Vector3(0, 0.12, -1.6), Vector3(4.4, 0.24, 3.6), stone)
	_box(root, Vector3(0, 0.3, -2.3), Vector3(3.0, 0.2, 2.0), stone)
	for z in [1.2, 2.3, 3.4]:
		_box(root, Vector3(randf_range(-0.2, 0.2), 0.05, z), Vector3(0.9, 0.1, 0.7), stone, randf_range(-20, 20))
	# torii: kırmızı direkler, kavisli siyah kasagi, nuki, levha
	for sx in [-1.45, 1.45]:
		_cyl(root, Vector3(sx, 1.6, 0), 0.15, 0.17, 3.2, red)
		_cyl(root, Vector3(sx, 0.15, 0), 0.24, 0.24, 0.3, black)
	_box(root, Vector3(0, 3.25, 0), Vector3(3.4, 0.24, 0.42), red)
	for sx in [-1, 1]:
		_box(root, Vector3(sx * 1.95, 3.33, 0), Vector3(0.7, 0.24, 0.44), red, 0.0, sx * -12.0)
	_box(root, Vector3(0, 3.45, 0), Vector3(4.5, 0.12, 0.5), black)
	_box(root, Vector3(0, 2.65, 0), Vector3(3.3, 0.16, 0.26), red)
	_box(root, Vector3(0, 2.95, 0.05), Vector3(0.5, 0.45, 0.06), black)
	# hokora: taş kaide, ahşap gövde, beşik çatı, şimenava ipi + kâğıt şeritler, sunak
	_box(root, Vector3(0, 0.75, -2.6), Vector3(1.3, 0.7, 1.1), stone)
	_box(root, Vector3(0, 1.5, -2.6), Vector3(1.0, 0.8, 0.9), wood)
	for sx in [-1, 1]:
		_box(root, Vector3(sx * 0.38, 2.12, -2.6), Vector3(0.9, 0.08, 1.3), roofm, 0.0, sx * -32.0)
	_box(root, Vector3(0, 2.35, -2.6), Vector3(0.1, 0.1, 1.35), black)
	var rope := _cyl(root, Vector3(0, 1.82, -2.12), 0.06, 0.06, 1.2, Props.toon_color(Color(0.85, 0.75, 0.5)))
	rope.rotation_degrees = Vector3(0, 0, 90)
	for sx in [-0.35, 0.0, 0.35]:
		_box(root, Vector3(sx, 1.62, -2.1), Vector3(0.08, 0.3, 0.02), paper, 0.0, 12.0)
	_box(root, Vector3(0, 0.75, -1.65), Vector3(0.9, 0.5, 0.5), wood)
	for sx in [-0.25, 0.25]:
		_cyl(root, Vector3(sx, 1.12, -1.65), 0.07, 0.07, 0.25, paper)
	# taş fenerler (tōrō): ayak, sütun, ışık odası (yanar), sivri başlık
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.85, 0.55)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.7, 0.35)
	glow.emission_energy_multiplier = 1.4
	for sx in [-2.6, 2.6]:
		_box(root, Vector3(sx, 0.2, -0.6), Vector3(0.7, 0.4, 0.7), stone)
		_cyl(root, Vector3(sx, 0.85, -0.6), 0.14, 0.17, 0.9, stone)
		_box(root, Vector3(sx, 1.38, -0.6), Vector3(0.62, 0.16, 0.62), stone)
		_box(root, Vector3(sx, 1.68, -0.6), Vector3(0.42, 0.44, 0.42), glow)
		var cap := _cyl(root, Vector3(sx, 2.12, -0.6), 0.0, 0.55, 0.42, stone)
		cap.mesh.radial_segments = 4
		cap.rotation_degrees.y = 45.0
		var om := OmniLight3D.new()
		om.light_color = Color(1.0, 0.7, 0.35)
		om.light_energy = 1.2
		om.omni_range = 6.0
		root.add_child(om)
		om.position = Vector3(sx, 1.7, -0.6)
	var k := _npc("Tapınak Bekçisi", c + Vector3(1.5, 0, -2.6), Outfits.roll("monk", Outfits.village_near(c)), "idle")
	_marker(c, "⛩", Color(1, 0.6, 0.5))
	Hud.msg("%s yol kenarında küçük bir tapınak var." % _dir_text(c).capitalize(), Color(1, 0.8, 0.7))
	k.on_talk = func(n):
		Hud.dialog(n.display, "Yolcu, dua et ve yükünü bırak. Tanrılar yorgun ninjaları kutsar.", [
			{"label": "Dua et", "cb": func():
				Game.player.hp = Game.player.max_hp
				Game.player.chakra = Game.player.max_chakra
				Buffs.add("tapinak", 480.0, {"armor": 0.9, "jutsu": 1.05})
				FX.burst(Game.player.global_position + Vector3.UP, {"amount": 40, "life": 1.4, "size": 0.5, "vmin": 0.5, "vmax": 2.5, "gravity": Vector3(0, 2.5, 0),
					"colors": [Color(1, 0.95, 0.7, 1), Color(1, 0.8, 0.4, 0)]})
				Hud.banner("TAPINAK KUTSAMASI", "Can ve chakra doldu • 8 dakika koruma", Color(1, 0.9, 0.6))
				finish(30.0)}])


func _box(root: Node3D, pos: Vector3, size: Vector3, mat: Material, yaw := 0.0, roll := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	root.add_child(mi)
	mi.position = pos
	mi.rotation_degrees = Vector3(0, yaw, roll)
	return mi


func _cyl(root: Node3D, pos: Vector3, top: float, bottom: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = mat
	root.add_child(mi)
	mi.position = pos
	return mi


func _start_rumor(c: Vector3) -> void:
	var t := _npc("Telaşlı Yolcu", c, Outfits.roll("traveler", Outfits.village_near(c)), "idle")
	_marker(c, "?")
	Hud.msg("%s bir yolcu sana el sallıyor." % _dir_text(c).capitalize(), Color(0.9, 0.9, 1))
	t.on_talk = func(n):
		var lairs: Array = TailedBeasts.lair_markers() if TailedBeasts.has_method("lair_markers") else []
		if lairs.is_empty():
			Hud.dialog(n.display, "Bu yollarda canavar falan kalmadı artık... sen mi yaptın yoksa?", [])
			finish(10.0)
			return
		var pm := Game.to_map(n.global_position)
		lairs.sort_custom(func(a, b): return pm.distance_to(Vector2(a["x"], a["y"])) < pm.distance_to(Vector2(b["x"], b["y"])))
		var L: Dictionary = lairs[0]
		var at := Game.from_map(Vector2(L["x"], L["y"]))
		var news: Array = Game.profile.get("beast_news", [])
		var extra = ("

Bir de şunu duydum: %s" % news.back()) if not news.is_empty() else ""
		Hud.dialog(n.display, "Gördüm! Dev bir yaratık... kuyrukları vardı! %s tarafında, gökyüzü bile karardı. Oraya gitme, delilik bu!%s" % [Game.region_name(at), extra], [
			{"label": "Yerini haritada işaretle", "cb": func():
				Game.profile["waypoint"] = [at.x, at.y, at.z, String(L["name"]).split(" — ")[0]]
				Game.profile["track"] = "waypoint"
				Hud.msg("İşaretlendi: %s" % String(L["name"]).split(" — ")[0], Color(1, 0.7, 0.4))
				finish(10.0)},
			{"label": "Teşekkürler", "cb": func(): finish(10.0)}])


func _start_rivals(c: Vector3) -> void:
	var vids := ["konoha", "suna", "kiri", "kumo", "iwa"]
	var vid: String = vids.pick_random()
	var team := []
	for i in 3:
		var e := _enemy("genin_rival", _around(c, 2.5, i, 3), i, {"name": "Rakip Takım — %s" % Game.village(vid).get("name", vid)})
		e.team = "neutral"
		var tr := ClanTrait.new()
		tr.name = "ClanTrait"
		tr.duel = true
		e.add_child(tr)
		team.append(e)
	cur["foes"] = team
	cur["neutral"] = true
	cur["rvid"] = vid
	var lead := team[0] as Enemy
	_marker(c, "!")
	Hud.msg("%s başka köyden bir takım yolunu kesiyor." % _dir_text(c).capitalize(), Color(1, 0.8, 0.5))
	cur["ask_at"] = lead


func _start_toll(c: Vector3) -> void:
	var foes := []
	for i in 3:
		var e := _enemy("bandit", _around(c, 3.0, i, 3), i, {"name": "Haraççı Haydut"})
		e.team = "neutral"
		foes.append(e)
	cur["foes"] = foes
	cur["neutral"] = true
	cur["ask_at"] = foes[0]
	_marker(c, "¥")
	Hud.msg("%s haydutlar yolu tutmuş, haraç istiyorlar." % _dir_text(c).capitalize(), Color(1, 0.7, 0.4))


func _start_lost_child(c: Vector3) -> void:
	var best := {}
	var bd := 1e9
	var m := Game.to_map(c)
	for v in Game.world_info["villages"]:
		var d := m.distance_to(Vector2(v["x"], v["y"])) - float(v["r"])
		if d < bd:
			bd = d
			best = v
	if best.is_empty() or bd > 1500.0:
		cur = {"kind": "patrol", "nodes": [], "t": 0.0, "center": c}
		_start_patrol(c)
		return
	var lk := Outfits.roll("kid", best["id"])
	lk["age"] = "child"
	var k := _npc("Kayıp Çocuk", c, lk, "cower")
	k.look["age"] = "child"
	cur["village"] = best
	_marker(c, "?", Color(0.7, 0.9, 1))
	Hud.msg("%s bir çocuk ağlıyor." % _dir_text(c).capitalize(), Color(0.8, 0.9, 1))
	k.on_talk = func(n):
		if n.mode == "follow":
			Hud.dialog(n.display, "%s'ye çok kaldı mı? Ayaklarım ağrıyor..." % best["name"], [])
			return
		Hud.dialog(n.display, "Kelebek kovalarken kayboldum... %s'ye nasıl dönerim? Beni götürür müsün?" % best["name"], [
			{"label": "Elini tut, köye götür", "cb": func():
				n.mode = "follow"
				Hud.msg("Çocuğu %s'ye götür (seni takip ediyor)." % best["name"], Color(0.8, 0.9, 1))},
			{"label": "Şimdi olmaz", "cb": func(): pass}])
	cur["child"] = k


func _start_clan_rogue(c: Vector3) -> void:
	var reg := country_at(c)
	var cl: String = (REGION_CLANS.get(reg, ["uchiha", "hyuga", "kaguya", "yuki", "hozuki", "chinoike"]) as Array).pick_random()
	var e: Enemy = ClanWorld.spawn_enemy(cl, maxi(4, Enemy.world_level(c)), c)
	cur["nodes"].append(e)
	cur["foes"] = [e]
	cur["after"] = "loot"
	Hud.msg("%s tuhaf bir chakra: kaçak bir %s ninjası!" % [_dir_text(c).capitalize(), ClanWorld.clan_name(cl)], Color(1, 0.55, 0.4))


func _start_sandstorm(c: Vector3) -> void:
	if Game.world:
		Game.world.env.region_weather = "kum fırtınası"
		Game.world.env.weather_t = 70.0
	var foes := []
	for i in 3:
		var e := _enemy("rogue", _around(Game.player.global_position, 16.0, i, 3), i, {"name": "Kum Akıncısı", "element": "fuuton", "jutsu": Enemy.auto_jutsu("rogue", "fuuton", Enemy.region_level(Game.player.global_position))})
		e.look["mask"] = "cloth"
		foes.append(e)
	cur["foes"] = foes
	cur["after"] = "loot"
	Hud.banner("KUM FIRTINASI", "Fırtınanın içinden akıncılar çıkıyor!", Color(0.95, 0.8, 0.5))


func _start_mist(c: Vector3) -> void:
	if Game.world:
		Game.world.env.region_weather = "sis"
		Game.world.env.weather_t = 70.0
	var foes := []
	var n := randi_range(3, 4)
	for i in n:
		var js: Array = ["kirigakure_no_jutsu"] + Enemy.auto_jutsu("rogue", "suiton", Enemy.region_level(Game.player.global_position)).slice(0, 2)
		var e := _enemy("rogue", _around(Game.player.global_position, 13.0, i, n), i, {"name": "Sis Suikastçısı", "element": "suiton", "jutsu": js, "sub": 0.35})
		foes.append(e)
		FX.smoke_puff(e.global_position + Vector3.UP, 1.2, 12)
	cur["foes"] = foes
	cur["after"] = "loot"
	Hud.banner("SİS PUSUSU", "Sessiz Öldürme... sis çöktü, etrafın sarıldı!", Color(0.7, 0.85, 1.0))


func _start_storm(c: Vector3) -> void:
	if Game.world:
		Game.world.env.region_weather = "yağmur"
		Game.world.env.weather_t = 60.0
	cur["storm_t"] = 40.0
	cur["bolt_t"] = 2.0
	var foes := []
	for i in 2:
		foes.append(_enemy("rogue", _around(Game.player.global_position, 18.0, i, 2), i, {"name": "Fırtına Avcısı", "element": "raiton",
			"jutsu": Enemy.auto_jutsu("rogue", "raiton", Enemy.region_level(Game.player.global_position))}))
	cur["foes"] = foes
	cur["after"] = "loot"
	Hud.banner("ŞİMŞEK FIRTINASI", "Gök gürlüyor — yıldırımlar yere iniyor, açıkta durma!", Color(0.7, 0.8, 1.0))


# ------------------------------------------------------------------ güncelleme
func _tick(dt: float) -> void:
	cur["t"] = float(cur["t"]) + dt
	var p := Game.player.global_position
	var c: Vector3 = cur["center"]
	# hızlı koşarken/uçarken hemen kaybolmasın: 900 m dışında 40 sn kalınca biter, olay yeri haritada/okta gösterilir
	var dist := Vector2(p.x - c.x, p.z - c.z).length()
	var far := dist > 700.0
	cur["far_t"] = (float(cur.get("far_t", 0.0)) + dt) if far else 0.0
	# uzaklaşınca olay biter (kayıp çocuk yanındaysa merkez onunla gider); 2 km'yi geçince hemen biter
	if (float(cur["far_t"]) > 25.0 and cur["kind"] != "lost_child") or dist > 2000.0:
		_abort()
		return
	# olaylar pusulayı/oku ELE GEÇİRMEZ: oyuncu neyi takip edeceğini kendisi seçer (yalnız haritada işaret)
	if float(cur["t"]) > 600.0:
		finish(5.0)
		return
	match cur["kind"]:
		"duel":
			_tick_duel(p)
		"rivals", "toll":
			_tick_neutral(p)
		"lost_child":
			_tick_child()
		"performers":
			_tick_show(dt)
		"storm":
			_tick_storm(dt, p)
	if cur.is_empty():
		return
	# tüccar: haydutlar bitti ama tüccar bulunamıyor (kaçtı/ezildi) → ödül yine verilir, olay biter
	if cur.get("kind", "") == "merchant" and cur.has("foes") and _alive(cur["foes"]).is_empty():
		var mn = cur.get("npc")
		if mn == null or not is_instance_valid(mn):
			_reward(120 + _lv() * 12, 30 + _lv() * 6, "Haydutları temizledin; tüccar kaçarken kesesini bıraktı")
			finish()
			return
		if not cur.get("merchant_called", false):
			cur["merchant_called"] = true
			mn.mode = "idle"
			_marker(mn.global_position, "Konuş", Color(0.6, 1, 0.6))
			Hud.msg("Tüccar güvende: yanına gidip konuş [F].", Color(0.6, 1, 0.6))
	if cur.has("foes") and cur.get("after", "") == "loot" and not cur.get("escaped", false):
		var al := _alive(cur["foes"])
		if al.size() == 1 and al[0].hp < al[0].max_hp * 0.3 and al[0].hp > 0.0 and al[0].arch.get("kind", "") == "rogue" and randf() < 0.5:
			_escape(al[0])
	if cur.has("foes") and cur.get("after", "") != "" and _alive(cur["foes"]).is_empty() and not cur.get("neutral", false):
		match cur["after"]:
			"loot":
				_reward(80 + _lv() * 14, 0, "Saldırganlar etkisiz")
				finish()
			"ambush":
				_reward(50 + _lv() * 8, 40 + _lv() * 6, "Pusucuları püskürttün")
				finish()
			"nemesis":
				Hud.banner("KAN DAVASI BİTTİ", "Peşindeki kaçak artık yok.", Color(1, 0.8, 0.5))
				finish(5.0)


func _tick_duel(p: Vector3) -> void:
	var a = cur["a"]
	var b = cur["b"]
	var av: bool = is_instance_valid(a) and not a.dead
	var bv: bool = is_instance_valid(b) and not b.dead
	if not cur["asked"] and av and bv and p.distance_to(a.global_position) < 28.0:
		cur["asked"] = true
		var na := String(a.display_name)
		var nb := String(b.display_name)
		Hud.dialog("Düello", "İki ninja kıyasıya dövüşüyor: %s ve %s. Biri seni gördü: \"Yardım et!\"" % [na, nb], [
			{"label": "%s'nin yanında savaş" % na, "cb": func(): _side(a, b)},
			{"label": "%s'nin yanında savaş" % nb, "cb": func(): _side(b, a)},
			{"label": "Karışma", "cb": func(): pass}])
	if cur.has("ally"):
		var foe = cur["foe"]
		if not is_instance_valid(foe) or foe.dead:
			var ally = cur["ally"]
			if is_instance_valid(ally) and not ally.dead:
				Combat.popup_text(ally.global_position + Vector3.UP * 2.4, "Sağ ol dostum!", Color(0.8, 1, 0.7))
				ally.team = "neutral"
				ally.target = null
			_reward(100 + _lv() * 12, 60 + _lv() * 8, "Düelloyu kazandırdın")
			if is_instance_valid(cur.get("ally")):
				remember({"k": "ally", "name": String(cur["ally"].display_name), "kind": String(cur["ally"].arch.get("kind", "kumo"))})
			finish(8.0)
	elif not av or not bv:
		finish(10.0)


func _side(ally: Enemy, foe: Enemy) -> void:
	ally.team = "player"
	ally.target = foe
	foe.target = Game.player
	ally.nameplate.modulate = Color(0.6, 1.0, 0.6)
	cur["ally"] = ally
	cur["foe"] = foe


func _tick_neutral(p: Vector3) -> void:
	var foes: Array = cur["foes"]
	var lead = cur.get("ask_at")
	if cur.get("neutral", false) and is_instance_valid(lead) and p.distance_to(lead.global_position) < 12.0 and not cur.get("asked", false):
		cur["asked"] = true
		if cur["kind"] == "rivals":
			Hud.dialog(lead.display_name, "Hey, sen! Bakalım köyünün ninjaları ne kadar güçlü. Takım takıma, dostça bir maç?", [
				{"label": "Kabul et (yenilen pes eder)", "cb": func():
					cur["neutral"] = false
					cur["after"] = "rivals"
					for e in _alive(foes):
						e.team = "enemy"},
				{"label": "Reddet", "cb": func():
					remember({"k": "rivals", "won": false, "vid": cur.get("rvid", "suna")})
					for e in _alive(foes):
						FX.smoke_puff(e.global_position + Vector3.UP, 0.8, 10)
						e.queue_free()
					finish(1.0)}])
		else:
			var toll := mini(int(Game.profile.get("ryo", 0)), 80 + _lv() * 6)
			Hud.dialog(lead.display_name, "Bu yol bizim. Geçmek istiyorsan %d Ryō. Yoksa..." % toll, [
				{"label": "Öde (%d Ryō)" % toll, "cb": func():
					Progress.add_ryo(-toll)
					remember({"k": "toll_paid"})
					Hud.msg("Haraç ödendi. Haydutlar sırıtarak çekildi.", Color(0.9, 0.8, 0.6))
					finish(6.0)},
				{"label": "Ödemem — savaş!", "cb": func():
					remember({"k": "toll_fought"})
					cur["neutral"] = false
					cur["after"] = "loot"
					for e in _alive(foes):
						e.team = "enemy"
						e.target = Game.player}])
	# rakipler: hepsi pes edince (ClanTrait düello) ödül
	if cur.get("after", "") == "rivals":
		var standing := foes.filter(func(e): return is_instance_valid(e) and not e.dead)
		if standing.is_empty():
			_reward(60 + _lv() * 10, 90 + _lv() * 12, "Rakip takımı yendin")
			remember({"k": "rivals", "won": true, "vid": cur.get("rvid", "suna")})
			finish(3.0)


func _tick_child() -> void:
	var k = cur.get("child")
	if not is_instance_valid(k):
		_abort()
		return
	var v: Dictionary = cur["village"]
	if k.mode == "follow" and Game.to_map(k.global_position).distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 0.95:
		Hud.dialog("Çocuğun Annesi", "Oğlum! Neredeydin?! ...Sana nasıl teşekkür etsem bilmiyorum ninja. Al, az da olsa.", [])
		_reward(90 + _lv() * 8, 60 + _lv() * 6, "Kayıp çocuğu ailesine kavuşturdun")
		remember({"k": "child", "vid": String(v["id"])})
		Missions._rep(String(v["id"]), 3)
		k.mode = "idle"
		finish(6.0)
	elif k.mode != "follow" and Game.player.global_position.distance_to(k.global_position) > 320.0:
		_abort()


func _tick_show(dt: float) -> void:
	cur["show_t"] = float(cur["show_t"]) - dt
	var fp = cur.get("fire_npc")
	if float(cur["show_t"]) <= 0.0 and is_instance_valid(fp) and Game.player.global_position.distance_to(fp.global_position) < 40.0:
		cur["show_t"] = randf_range(2.5, 4.0)
		fp.model.play("cast_out", 0.05, 1.2, true)
		var from: Vector3 = fp.global_position + Vector3.UP * 1.6 + fp.face_dir() * 0.4
		FX.burst(from, {"amount": 50, "life": 0.9, "size": 0.9, "vmin": 4, "vmax": 9, "gravity": Vector3(0, 4, 0),
			"colors": [Color(1, 0.85, 0.35, 1), Color(1, 0.35, 0.05, 0)]})
		FX.light(from, Color(1, 0.6, 0.2), 5.0, 12.0, 0.6)


func _tick_storm(dt: float, p: Vector3) -> void:
	cur["storm_t"] = float(cur["storm_t"]) - dt
	if float(cur["storm_t"]) <= 0.0:
		if _alive(cur["foes"]).is_empty():
			finish(3.0)
		return
	cur["bolt_t"] = float(cur["bolt_t"]) - dt
	if float(cur["bolt_t"]) > 0.0:
		return
	cur["bolt_t"] = randf_range(1.2, 2.6)
	var a := randf() * TAU
	var hit := p + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 22.0)
	hit.y = Game.ground_height(hit.x, hit.z)
	VFX.bolt(hit + Vector3(randf_range(-6, 6), 60, randf_range(-6, 6)), hit, Color(0.75, 0.85, 1.0), 0.6, 0.3, 5)
	VFX.shockwave(hit + Vector3.UP * 0.2, Color(0.7, 0.85, 1.0, 0.8), 4.0, 0.3)
	VFX.cracks(hit, 2.5)
	FX.light(hit + Vector3.UP * 3, Color(0.7, 0.8, 1.0), 10.0, 30.0, 0.25)
	if Game.world:
		Game.world.env.screen_flash(0.35)
		Game.world.env.add_shake(0.3)
	Sfx.play("chidori", hit, 0.6)
	if Vector2(p.x - hit.x, p.z - hit.z).length() < 2.6:
		Game.player.take_hit({"dmg": 14.0 + _lv() * 0.6, "knock": 6.0, "kind": "heavy", "attacker": null})
		Game.player.apply_status("shock", 1.5)
	for e in _alive(cur["foes"]):
		if Vector2(e.global_position.x - hit.x, e.global_position.z - hit.z).length() < 2.6:
			e.hp -= 20.0


# ------------------------------------------------------------------ dünya hafızası: senin hikâyen (takip olayları)
## Kurtardığın tüccar kervanıyla döner, düellosunu kazandırdığın ninja bir gün savaşında yanında belirir, kaçan kaçak
## intikam için seni avlar, haraç ödersen haydutlar azar, rakip takım rövanş ister. Hepsi profile["enc_mem"] içinde kalıcı.
func _mem() -> Array:
	if not Game.profile.has("enc_mem"):
		Game.profile["enc_mem"] = []
	return Game.profile["enc_mem"]


func remember(d: Dictionary) -> void:
	d["t"] = Time.get_unix_time_from_system()
	var m := _mem()
	m.append(d)
	if m.size() > 30:
		m.remove_at(0)


func _has(k: String) -> bool:
	return _mem().any(func(x): return x.get("k", "") == k)


func _take(k: String) -> Dictionary:
	var m := _mem()
	for i in m.size():
		if m[i].get("k", "") == k:
			var d: Dictionary = m[i]
			m.remove_at(i)
			return d
	return {}


func _count(k: String) -> int:
	return _mem().filter(func(x): return x.get("k", "") == k).size()


## Hafızadan doğan karşılaşma (yoksa "")
func _followup() -> String:
	var opts := []
	if _has("merchant"):
		opts.append("merchant_return")
	if _has("rivals"):
		opts.append("rival_rematch")
	if _has("toll_fought") or _count("toll_paid") >= 2:
		opts.append("toll_revenge")
	if _has("contact"):
		opts.append("contact")
	if _has("nemesis"):
		opts.append("nemesis")
		opts.append("nemesis")
	if _has("child"):
		opts.append("child_gift")
	opts = opts.filter(func(k): return k != last_kind)
	return opts.pick_random() if not opts.is_empty() else ""


func _ally_join() -> void:
	var d := _take("ally")
	var kind: String = d.get("kind", "kumo")
	var at: Vector3 = Game.player.global_position - Game.player.face_dir() * 6.0
	var a := _enemy(kind if kind in ["kumo", "kiri", "iwa", "suna", "oto"] else "kumo", at, 0, {"name": d.get("name", "Eski Dost")})
	a.team = "player"
	a.nameplate.modulate = Color(0.6, 1.0, 0.6)
	FX.smoke_puff(a.global_position + Vector3.UP, 1.0, 14)
	Combat.popup_text(a.global_position + Vector3.UP * 2.4, "Borcumu ödeme vakti!", Color(0.7, 1, 0.7))
	Hud.msg("%s yardımına yetişti — o düelloyu unutmamış." % d.get("name", "Eski bir dost"), Color(0.7, 1, 0.7))


## Son kalan kaçak yaralıyken kaçar ve Bingo Kitabı'na intikam peşindeki biri olarak girer
func _escape(e: Enemy) -> void:
	cur["escaped"] = true
	FX.smoke_puff(e.global_position + Vector3.UP, 1.2, 16)
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Bunu unutmayacağım!", Color(1, 0.5, 0.4))
	var bb: Dictionary = Missions._bingo()
	var en: Dictionary = Missions._bb_new()
	en["rank"] = "B" if _lv() < 30 else "A"
	en["level"] = _lv() + 3
	en["hp"] = 300.0 + en["level"] * 26.0
	en["power"] = 1.4 + en["level"] * 0.035
	en["bounty"] = 2500 + _lv() * 120
	en["alias"] = ["Kaçan Gölge", "Yaralı Kurt", "Kinci", "Yarım Kalan", "İz Süren"].pick_random()
	en["crimes"] = ["Seninle savaştı ve kaçtı — intikam yemini etti", "Yol pusularının elebaşı"]
	if String(e.element) != "":
		en["element"] = String(e.element)
	en["nemesis"] = true
	var m := Game.to_map(e.global_position)
	en["hide"] = [m.x + randf_range(-500, 500), m.y + randf_range(-500, 500)]
	en["area"] = en["hide"].duplicate()
	en["known"] = 500.0
	bb["list"].append(en)
	remember({"k": "nemesis", "id": int(en["id"])})
	Hud.msg("«%s» kaçtı... Bingo Kitabı'na eklendi. Seni arayacak." % en["alias"], Color(1, 0.55, 0.4))
	e.queue_free()


func _start_merchant_return(c: Vector3) -> void:
	var d := _take("merchant")
	var m := _npc(d.get("name", "Tüccar"), c, Outfits.roll("merchant", d.get("vid", "konoha")), "idle")
	for i in 2:
		var g := _npc("Kervan Muhafızı", c + Vector3(2.5 * (1 if i else -1), 0, 2.0), Outfits.roll("guard", d.get("vid", "konoha")), "idle")
		g.line = "Patron senden çok bahsetti."
	_marker(c, "★")
	Hud.msg("%s tanıdık bir kervan: %s!" % [_dir_text(c).capitalize(), d.get("name", "Tüccar")], Color(1, 0.85, 0.5))
	m.on_talk = func(n):
		var gid: String = Gear.random_reward(2)
		var txt := "Ah, kurtarıcım! O günden beri işlerim açıldı. Bunu sana sakladım."
		if gid != "" and not Gear.item(gid).is_empty():
			Gear.grant(Game.profile, gid)
			txt += "\n\n[%s aldın]" % Gear.item(gid)["name"]
		Hud.dialog(n.display, txt, [])
		_reward(0, 40 + _lv() * 5, "Eski dost tüccar")
		finish(20.0)


func _start_rival_rematch(c: Vector3) -> void:
	var d := _take("rivals")
	_start_rivals(c)
	cur["kind"] = "rivals"
	cur["rvid"] = d.get("vid", cur.get("rvid", "suna"))
	for e in cur["foes"]:
		e.level += 3
		e.max_hp *= 1.35
		e.hp = e.max_hp
		e.power *= 1.2
	var lead: Enemy = cur["foes"][0]
	lead.display_name = "Rakip Lider " + ["Kotetsu", "Hayabusa", "Sumire", "Onikiri", "Raiga"].pick_random()
	lead.nameplate.text = "%s  Sv.%d" % [lead.display_name, lead.level]
	var line := "\"Rövanş! Bu sefer hazırız!\"" if d.get("won", true) else "\"Geçen sefer kaçtın, bu sefer kaçamazsın!\""
	Hud.msg("Rakip takım geri döndü: %s" % line, Color(1, 0.75, 0.45))


func _start_toll_revenge(c: Vector3) -> void:
	var fought := _take("toll_fought")
	if fought.is_empty():
		_take("toll_paid")
		_take("toll_paid")
	var foes := []
	var boss := _enemy("bandit", c, 0, {"name": "Haraç Kralı Gōzaemon", "hp": 260.0 + _lv() * 30.0, "power": 1.6 + _lv() * 0.03, "guard": 0.4, "size": 1.25})
	foes.append(boss)
	for i in 4:
		foes.append(_enemy("bandit", _around(c, 5.0, i, 4), i, {"name": "Haraççı Haydut"}))
	cur["foes"] = foes
	cur["after"] = "loot"
	_marker(c, "☠", Color(1, 0.4, 0.3))
	Hud.banner("HARAÇ KRALI", "Adamlarını dağıttın; şimdi elebaşı geldi!" if not fought.is_empty() else "Haraç verdikçe büyüdüler — artık bütün yolu istiyorlar!", Color(1, 0.5, 0.35))


func _start_contact(c: Vector3) -> void:
	var d := _take("contact")
	var k := _npc(d.get("name", "Eski Dost"), c, Outfits.roll("chunin", Outfits.village_near(c)), "idle")
	_marker(c, "★", Color(0.7, 1, 0.7))
	Hud.msg("%s bir ninja el sallıyor — kurtardığın yaralı!" % _dir_text(c).capitalize(), Color(0.7, 1, 0.7))
	k.on_talk = func(n):
		Hud.dialog(n.display, "Seni bulmak kolay olmadı! Hayatımı sana borçluyum. Kulağıma gelenleri anlatayım; bir de şu askerî hapları al.", [])
		Game.player.hp = Game.player.max_hp
		Game.player.chakra = Game.player.max_chakra
		Buffs.add("asker_hapi", 300.0, {"melee": 1.1, "jutsu": 1.08})
		_hint_bounty(n)
		_reward(100 + _lv() * 10, 30, "Eski bir dostluk")
		finish(20.0)


func _start_child_gift(c: Vector3) -> void:
	var d := _take("child")
	var v := Game.village(d.get("vid", "konoha"))
	var lk := Outfits.roll("kid", d.get("vid", "konoha"))
	lk["age"] = "child"
	var k := _npc("Tanıdık Çocuk", c, lk, "kid")
	_marker(c, "♥", Color(1, 0.7, 0.8))
	Hud.msg("%s bir çocuk sana koşuyor: kaybolduğunda %s'ye götürdüğün çocuk!" % [_dir_text(c).capitalize(), v.get("name", "köy")], Color(1, 0.8, 0.85))
	k.on_talk = func(n):
		Hud.dialog(n.display, "Ninja abi! Sana resim yaptım, bak, sensin bu! Annem de bu kurabiyeleri yolladı.", [])
		Game.player.hp = Game.player.max_hp
		Missions._rep(String(d.get("vid", "konoha")), 2)
		_reward(0, 50 + _lv() * 4, "Küçük bir hayranın var")
		finish(15.0)


## Kaçan düşman seni buluyor: Bingo girdisi yolda pusu kurar
func _start_nemesis(c: Vector3) -> void:
	var d := _take("nemesis")
	var en := {}
	for e in Missions._bingo()["list"]:
		if int(e["id"]) == int(d.get("id", -1)) and e["status"] == "alive":
			en = e
	if en.is_empty() or Missions._bb_spawned.has(int(en["id"])):
		cur = {"kind": "patrol", "nodes": [], "t": 0.0, "center": c}
		_start_patrol(c)
		return
	var m := Game.to_map(c)
	en["hide"] = [m.x, m.y]
	en["area"] = [m.x, m.y]
	en["known"] = 30.0
	Missions._bb_spawn(en, c)
	var nodes: Array = Missions._bb_spawned.get(int(en["id"]), [])
	cur["foes"] = nodes.filter(func(x): return x is Enemy)
	cur["after"] = "nemesis"
	cur["escaped"] = true
	Hud.banner("İNTİKAM", "«%s» seni buldu: \"Sana bunu unutmayacağımı söylemiştim!\"" % en["alias"], Color(1, 0.45, 0.35))
