extends Node
## Dinamik jinchūriki: başlangıç taşıyıcıları, dünya olayları, kaçak taşıyıcı Bingo'da, yenilince canavar fışkırıp diz çöker
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.max_hp = 999999.0
	pl.hp = pl.max_hp
	var bs = TailedBeasts.beasts()
	for id in bs:
		print("INIT %s %s %s" % [id, bs[id]["state"], bs[id].get("host", {}).get("name", "")])
	for i in 12:
		TailedBeasts._host_events()
	for n in Game.profile.get("beast_news", []):
		print("NEWS ", n)
	# bir köy taşıyıcısını kaçır
	var hid = ""
	for id in bs:
		if bs[id]["state"] == "host" and not bs[id]["host"].get("rogue", false):
			hid = id
			break
	if hid == "":
		bs["gyuki"]["state"] = "host"
		bs["gyuki"]["host"] = TailedBeasts._new_host("gyuki", "kumo")
		hid = "gyuki"
	Missions.add_rogue_jinchuriki(hid, bs[hid]["host"])
	var entry = {}
	for x in Missions._bingo()["list"]:
		if x["status"] == "alive" and String(x.get("beast", "")) == hid:
			entry = x
	print("BINGO %s name=%s rank=%s crimes=%s" % [hid, entry.get("name", "-"), entry.get("rank", "-"), entry.get("crimes", [])])
	var at = pl.global_position + pl.face_dir() * 10.0
	var am = Game.to_map(at)
	entry["hide"] = [am.x, am.y]
	Missions._bb_spawn(entry, at)
	await get_tree().create_timer(0.5).timeout
	var boss = Missions._bb_spawned[int(entry["id"])][0]
	print("BOSS ", boss.display_name, " beast=", boss.arch.get("beast", ""))
	boss.hp = 1.0
	boss.sub_cd = 99.0
	boss.take_hit({"dmg": 50.0, "kind": "heavy", "attacker": pl, "dir": Vector3.FORWARD})
	await get_tree().create_timer(3.5).timeout
	var tb = TailedBeasts.spawned.get(hid)
	print("RELEASE state=%s spawned=%s subdued=%s" % [TailedBeasts.beast_state(hid), tb != null and is_instance_valid(tb), tb.subdued if tb else false])
	if tb:
		pl.set_process(false)
		pl.cam.global_position = tb.global_position + Vector3(tb.height * 1.2, tb.height * 0.6, tb.height * 1.6)
		pl.cam.look_at(tb.global_position + Vector3.UP * tb.height * 0.4)
		await get_tree().create_timer(0.3).timeout
		await main.shot("jin_release")
	get_tree().quit()
