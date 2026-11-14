extends Node
## Tuş ezme denemesi: Güç PLV oyuncu yalnız düz vuruşa basarak Güç ELV kaçağa karşı ne yapıyor (düşmanın durumu saniye saniye)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12),
		"bottom": Color(0.9, 0.45, 0.12), "skin": Color(1.0, 0.86, 0.72), "eye": Color(0.2, 0.4, 0.9)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	WorldDay.auto = false
	var plv = float(OS.get_environment("PLV")) if OS.get_environment("PLV") != "" else 30.0
	var elv = int(OS.get_environment("ELV")) if OS.get_environment("ELV") != "" else 90
	var avg = 100.0 * pow(plv / 100.0, 1.0 / 0.7)
	if not Game.profile.has("mastery"):
		Game.profile["mastery"] = {}
	for k in Mastery.KEYS:
		Game.profile["mastery"][k] = avg
	var save_slots: Array = []
	if OS.get_environment("KAYIT") != "":   # oyuncunun gerçek kaydı (yalnız okunur): ustalıklar + yuvalardaki jutsular
		var sv = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("KAYIT")))
		Game.profile["mastery"] = (sv["mastery"] as Dictionary).duplicate(true)
		for sl in sv.get("slots", []):
			if String(sl) != "" and Data.jutsu.has(String(sl)) and not String(sl) in save_slots and String(sl) != "kuchiyose":
				save_slots.append(String(sl))
	Mastery.refresh_level(Game.profile)
	pl.max_hp = Stats.max_hp(Game.profile)
	pl.max_chakra = Stats.max_chakra(Game.profile)
	pl.chakra = pl.max_chakra
	pl.hp = pl.max_hp
	var at = Missions.open_ground(pl.global_position + Vector3(0, 0, 700.0), 60.0)
	at.y = Game.ground_height(at.x, at.z) + 0.3
	pl.global_position = at
	pl.velocity = Vector3.ZERO
	pl.reset_physics_interpolation()
	await get_tree().create_timer(1.5).timeout
	# dünyadan gerçek biri: Güç'ü istenen değere en yakın kişi (jutsu listesi o Güç'e göre yeniden öğrenilir)
	var cands = WorldPeople.all().values().filter(func(q): return WorldPeople.alive(q) and int(q["rank"]) >= 1)
	cands.sort_custom(func(x, y): return absi(int(x["level"]) - elv) < absi(int(y["level"]) - elv))
	var wp: Dictionary = cands[int(OS.get_environment("KISI")) if OS.get_environment("KISI") != "" else 0]
	print("MASH kisi: %s gercek Guc %d rutbe %s goz %s el %s" % [String(wp["name"]), int(wp["level"]), str(wp["rank"]), str(wp["eye"]), str(wp["els"])])
	wp["level"] = elv
	WorldPeople._learn(wp)
	var a = WorldPeople.arch_of(wp)
	a["respawn"] = false
	var e = Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = Missions.open_ground(pl.global_position + pl.face_dir() * 6.0, 10.0)
	e.home = e.global_position
	print("MASH oyuncu Guc %d can %.0f vurus carpani %.2f | dusman Guc %d can %.0f guc %.2f" % [Mastery.power(Game.profile), pl.hp, Stats.melee_mult(Game.profile), elv, e.max_hp, e.power])
	print("MASH dusman: %s jutsulari=%s" % [e.display_name, str(e.arch.get("jutsu", []))])
	var states = {}
	var t := 0.0
	var last := 0.0
	var mode = OS.get_environment("MODE")
	var pre = OS.get_environment("PRE") if OS.get_environment("PRE") != "" else "shoton"
	var ids = []
	for k in Data.jutsu:
		var jd = Data.jutsu[k]
		if jd is Dictionary and (String(k).begins_with(pre) or String(jd.get("learn", "")) == "kg:" + pre) and float(jd.get("level", 1)) * 0.55 <= avg:
			ids.append(String(k))
	if not save_slots.is_empty():
		if OS.get_environment("PRE") != "":   # kayıttaki ustalıklarla başka element: o elementin atabildiği en güçlü 9 tekniği (9 yuva)
			ids.sort_custom(func(x, y): return float(Data.jutsu[x].get("level", 1)) > float(Data.jutsu[y].get("level", 1)))
			ids = ids.slice(0, 9)
		else:
			ids = save_slots
	for k in ids:
		if not k in Game.profile.get("learned", []):
			Game.profile["learned"] = Game.profile.get("learned", []) + [k]
	var real = OS.get_environment("GERCEK") == "1" or not save_slots.is_empty()
	var hit_t := -9.0
	var cd = {}
	var busy := 0.0
	var casts := 0
	var fails := 0
	var dealt = {}
	var hp0 = e.hp
	var pend := ""
	var php: float = pl.hp
	var shots := 0
	var ehp: float = e.hp
	print("MASH kullanilabilir jutsu: %d  %s" % [ids.size(), str(ids)])
	while t < 60.0 and is_instance_valid(e) and not e.dead and not pl.is_dead():
		await get_tree().create_timer(0.1).timeout
		t += 0.1
		var dir = e.global_position - pl.global_position
		dir.y = 0
		pl.facing = atan2(-dir.x, -dir.z)
		if mode == "jutsu":
			# oyunun gerçek atış yolu: mühür / hazırlık / toparlanma süresi, bekleme süresi, chakra bedeli, ustalık şartı hepsi oyundaki gibi
			var pc = pl.combat
			if String(pc.action) == "":
				var rdy = ids.filter(func(k): return float(pc.cooldowns.get(k, 0.0)) <= 0.0)
				var can = rdy.filter(func(k): return Stats.is_taijutsu(Data.jutsu[k]) or pl.chakra >= PlayerCombat.cast_cost(Data.jutsu[k]))
				if not can.is_empty():
					var jid: String = can.pick_random()
					pc.begin_cast(jid)
					if String(pc.action) == "cast":
						casts += 1
						print("MASH   t=%.1f at: %s | dusman takim=%s hedef=%s can=%.0f durumlar=%s" % [t, jid, str(e.team), (str(e.target.name) if e.target != null and is_instance_valid(e.target) else "yok"), e.hp, str(e.statuses)])
					else:
						fails += 1
						pc.cooldowns[jid] = 3.0   # atılamadı (şart / ustalık): bir süre deneme
				elif not rdy.is_empty() and t - hit_t > 0.6:   # chakra yok: C ile toplar (darbe yiyince 0.6 sn kesilir)
					pl.chakra = minf(pl.max_chakra, pl.chakra + Stats.charge_rate(Game.profile) * 0.1)
		else:
			if dir.length() > 2.2:
				pl.global_position += dir.normalized() * minf(dir.length() - 1.8, 0.9)
			pl.combat.attack()
		if is_instance_valid(e) and e.hp < ehp - 0.5:
			print("MASH     dusman -%.0f (son teknik=%s) durumlar=%s" % [ehp - e.hp, str(pl.get_meta("jid", "")), str(e.statuses.keys())])
		ehp = e.hp if is_instance_valid(e) else 0.0
		if pl.hp < php - 0.5:
			hit_t = t
			print("MASH     oyuncu -%.0f (dusman durum=%s teknik=%s uzaklik=%.0f) oyuncu durum=%s" % [php - pl.hp, e.state, str(e.get_meta("cast_id", "")), dir.length(), str(pl.statuses.keys())])
		php = pl.hp
		if OS.get_environment("CHG") == "1" and t > 2.0 and t < 2.15 and is_instance_valid(e):
			e.chakra = 0.0   # görüntü denemesi: chakrası bitmiş düşman
		if is_instance_valid(e) and e.state == "charge" and shots < 2 and e.state_t > 0.5:
			shots += 1
			var c3 = Camera3D.new()
			main.add_child(c3)
			var off = Vector3(3.5, 1.6, 3.5) if shots == 1 else Vector3(-1.5, 1.2, -5.0)
			c3.global_position = e.global_position + off
			c3.look_at(e.global_position + Vector3.UP * 1.0)
			c3.current = true
			await get_tree().create_timer(0.15).timeout
			await main.shot("npc_chakra_%d" % shots)
			pl.cam.make_current()
			c3.queue_free()
			print("MASH     dusman chakra topluyor (chakra %.0f / %.0f)" % [e.chakra, e.max_chakra])
		states[e.state] = float(states.get(e.state, 0.0)) + 0.1
		for st in ["stun", "bind", "freeze", "slow"]:
			if e.has_status(st):
				states["*" + st] = float(states.get("*" + st, 0.0)) + 0.1
		if t - last >= 3.0:
			last = t
			print("MASH t=%.0f dusman can %.0f%% durum=%s uzaklik=%.0f hedef=%s chakra=%.0f durumlar=%s | oyuncu can %.0f%% | atis %d bozulan %d" % [t, 100.0 * e.hp / e.max_hp, e.state, dir.length(), e.target != null and is_instance_valid(e.target), e.chakra, str(e.statuses.keys() if e.get("statuses") != null else []), 100.0 * pl.hp / Stats.max_hp(Game.profile), casts, fails])
	print("MASH bitis t=%.1f dusman_oldu=%s oyuncu_oldu=%s dusman can %.0f%% oyuncu can %.0f%%" % [t, not is_instance_valid(e) or e.dead, pl.is_dead(), (100.0 * e.hp / e.max_hp if is_instance_valid(e) else 0.0), 100.0 * pl.hp / Stats.max_hp(Game.profile)])
	print("MASH dusmanin gecirdigi sure (sn): %s" % str(states))
	get_tree().quit()
