extends Node
## Kage binaları + meydanlar + Kage ofisi iç mekânı + özel binalar: ekran görüntüleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var args = OS.get_cmdline_user_args()
	var tag = "after" if args.has("--after") else "before"
	var only = ""
	var wait = 6.0
	for a in args:
		if a.begins_with("--only="):
			only = a.substr(7)
		if a.begins_with("--wait="):
			wait = float(a.substr(7))
	var env = main.world.env
	env.region_weather = "açık"
	env.weather_t = 1e9
	var kv = Game.village("konoha")
	# [harita noktası, yaw, pitch, cam, ad]
	var spots = [
		[Vector2(kv["x"], kv["y"] + 600 - 105), 0.0, -12.0, 30.0, "kg_konoha_on"],
		[Vector2(kv["x"] - 30, kv["y"] + 600 - 60), 30.0, -24.0, 40.0, "kg_konoha_kule"],
		[Vector2(kv["x"] + 40, kv["y"] + 600 - 70), -35.0, -16.0, 22.0, "kg_konoha_meydan"],
		[Vector2(kv["x"] + 545, kv["y"] + 230 - 75), 0.0, -10.0, 24.0, "kg_hastane"],
		[Vector2(kv["x"] - 480, float(kv.get("hokage_rock", {}).get("y", kv["y"] + 1170.0)) - 110 - 60), 0.0, -12.0, 28.0, "kg_anbu"],
		[Vector2(kv["x"] - 170, kv["y"] - 12), 180.0, -10.0, 16.0, "kg_eczane"],
		[Vector2(kv["x"] + 250, kv["y"] - 12), 180.0, -10.0, 16.0, "kg_cayevi"],
		[Vector2(kv["x"] - 1020, kv["y"] - 640 - 175), 0.0, -12.0, 26.0, "kg_uchiha"],
	]
	for vid in ["suna", "kiri", "kumo", "iwa"]:
		var v = Game.village(vid)
		spots.append([Vector2(v["x"], v["y"] - 120), 0.0, -8.0, 30.0, "kg_" + vid])
	spots.append([Vector2(kv["x"] + 100, kv["y"] + 80), 0.0, -8.0, 9.0, "kg_kapi_konoha"])
	var sv = Game.village("suna")
	spots.append([Vector2(sv["x"] + 200, sv["y"] + 60), 90.0, -8.0, 12.0, "kg_kapi_suna"])
	var pl = main.player
	for sp in spots:
		if only != "" and not String(sp[4]).contains(only):
			continue
		var p = Game.from_map(sp[0])
		p.y = Game.terrain_height(p.x, p.z) + 0.2
		pl.respawn(p)
		pl.yaw = sp[1]; pl.pitch = sp[2]; pl.cam_dist = sp[3]
		env.time_of_day = 0.42
		await get_tree().create_timer(wait).timeout
		await main.shot(sp[4] + "_" + tag)
	# iç mekân: her köyün Kage ofisi
	for vid in ["konoha", "suna", "kumo"]:
		if only != "" and not ("ofis_" + vid).contains(only):
			continue
		var door = {}
		var v = Game.village(vid)
		for it in Interact.items:
			if it.get("kind", "") == "enter" and String(it.get("room", "")).begins_with("kage") or String(it.get("room", "")) == "hokage":
				if Game.to_map(it["pos"]).distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
					door = it
		if door.is_empty():
			print("KAPI YOK ", vid)
			continue
		pl.respawn(door["pos"])
		await get_tree().create_timer(1.0).timeout
		Interiors.inst.enter(door)
		await get_tree().create_timer(4.0).timeout
		pl.yaw = 0.0; pl.pitch = -6.0; pl.cam_dist = 4.0
		await get_tree().create_timer(1.5).timeout
		await main.shot("kg_ofis_%s_%s" % [vid, tag])
		pl.global_position += Vector3(2.5, 0, -6.0)
		pl.yaw = 20.0; pl.pitch = -4.0; pl.cam_dist = 2.5
		await get_tree().create_timer(1.5).timeout
		await main.shot("kg_ofis_%s_kage_%s" % [vid, tag])
		Interiors.inst.exit()
		await get_tree().create_timer(2.0).timeout
	get_tree().quit()
