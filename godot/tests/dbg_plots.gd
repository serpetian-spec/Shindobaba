extends Node
## Dost planları, flört, hediye bıkkınlığı, işler, pusu, ihanet, Kage emri
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["rank"] = 3
	Game.profile["level"] = 30
	Game.profile["ryo"] = 50000
	var v = ClanResident.new()
	v.clan = "nara"
	v.vid = "konoha"
	v.given = "Nara Emi"
	v.display_override = v.given
	v.role = "nurse"
	v.look_extra = ClanWorld.clan_look("nara", "chunin", "konoha", true, "adult")
	main.actors.add_child(v)
	v.global_position = pl.global_position + Vector3(2, 0, 0)
	await get_tree().create_timer(0.3).timeout
	Friends._meet(v)
	Menus.clear()
	var id = String(v.get_meta("friend_id"))
	var f: Dictionary = Friends.all()[id]
	print("PLOT persona loyalty=", f.get("loyalty"), " amb=", f.get("ambition"), " love=", f.get("love"))
	var lab = func(o): return o.map(func(x): return x["label"])
	f["bond"] = 100
	print("PLOT romance@100 love0: ", lab.call(Friends._romance_opts(id)))
	# hediye bıkkınlığı
	f["gift_times"] = []
	for k in 5:
		f["last_gift"] = 0.0
		var b0 = int(f["bond"])
		f["bond"] = 50
		var opts = Friends._friend_opts(id, v)
		for o in opts:
			if String(o["label"]).begins_with("Hediye"):
				o["cb"].call()
		var gd = Hud.get("_dlg_opts") if false else null
		print("PLOT gift round ", k, " times=", (f.get("gift_times", []) as Array).size())
		Menus.clear()
	f["bond"] = 100
	for k in 6:
		f["last_flirt"] = 0.0
		for o in Friends._romance_opts(id):
			if String(o["label"]).begins_with("İltifat"):
				o["cb"].call()
	print("PLOT dbg g=", f["look"].get("gender"), " pg=", Friends.player_gender(), " av=", Friends.available(f), " b=", f["bond"], " away=", f.get("away"), " st=", f.get("status"))
	print("PLOT after flirts love=", f["love"], " rm=", Friends.romance_of(id), " opts=", lab.call(Friends._romance_opts(id)))
	f["love"] = 70
	print("PLOT love70 opts=", lab.call(Friends._romance_opts(id)))
	f["romance"] = "sevgili"
	f["since"] = Time.get_unix_time_from_system()
	f["love"] = 90
	print("PLOT dating fresh opts=", lab.call(Friends._romance_opts(id)))
	f["since"] = Time.get_unix_time_from_system() - 2000
	print("PLOT dating 33min opts=", lab.call(Friends._romance_opts(id)))
	Menus.clear()
	# planlar
	var ff = Friends.inst()
	print("PLOT inst=", ff)
	f["ambition"] = "kage"
	f["loyalty"] = 10
	FriendPlots.start(id)
	print("PLOT plot=", f.get("plot"), " opt=", lab.call(FriendPlots.option(id)))
	Menus.clear()
	f["plot"]["t"] = 0.0
	ff._kage_order(id, FriendPlots.scenario(String(f["plot"]["id"])), true)
	await get_tree().create_timer(0.5).timeout
	await main.shot("plot_kage_order")
	Menus.clear()
	# işler
	for k in Friends.all():
		Friends.all()[k]["job_until"] = 0.0
	ff._wt = 0.0
	await get_tree().create_timer(1.5).timeout
	print("PLOT job=", f.get("job"), " where=", Friends.where(id))
	# pusu (yolda dost)
	f["status"] = ""
	ff.ambush(id, "bandit", 3, "Yol pususu", true)
	await get_tree().create_timer(1.0).timeout
	await main.shot("plot_ambush")
	for fg in ff.fights:
		for e in fg["foes"]:
			e.take_hit({"dmg": 99999.0, "attacker": pl, "kind": "heavy", "dir": Vector3.FORWARD})
	await get_tree().create_timer(2.0).timeout
	print("PLOT after ambush bond=", f["bond"], " fights=", ff.fights.size())
	# ihanet
	f["party"] = true
	ff.betray_attack(id)
	await get_tree().create_timer(1.0).timeout
	await main.shot("plot_betray")
	print("PLOT betrayed status=", f["status"], " bond=", f["bond"])
	Friends.on_mission_done("A")
	Friends.on_kill()
	ff._plot_tick()
	# İlişkiler kartı (iş + gönül)
	f["status"] = ""
	f["bond"] = 70
	f["romance"] = "flört"
	f["job"] = "nöbet"
	Menus.clear()
	Menus._friend_i = 0
	Menus.ninja_menu(main, "relations")
	await get_tree().create_timer(1.0).timeout
	await main.shot("plot_card")
	Menus.clear()
	main.resume()
	# Kiri chūnin kıyafetleri: hiçbiri Kage cübbesi giymemeli
	for e in get_tree().get_nodes_in_group("fighters"):
		if e is Enemy and e.team == "enemy":
			e.queue_free()
	var row = []
	var white_flame = 0
	for k in 40:
		var a = Enemy.archetype("kiri", k)
		if a["look"].get("outer_pattern", 0) == 2 and a["look"].get("outer") is Color and (a["look"]["outer"] as Color).v > 0.8:
			white_flame += 1
	print("PLOT kiri white+flame robes=", white_flame)
	var fw = pl.face_dir()
	var side = fw.cross(Vector3.UP)
	for k in 6:
		var a = Enemy.archetype("kiri", k)
		a["respawn"] = false
		a["aggr"] = 0.0
		var e = Enemy.new()
		e.setup(a)
		e.team = "player"
		get_tree().current_scene.add_child(e)
		var q = pl.global_position + fw * 6.0 + side * (k - 2.5) * 1.6
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.home = q
	await get_tree().create_timer(1.0).timeout
	await main.shot("kiri_chunin")
	print("PLOT done")
	get_tree().quit()
