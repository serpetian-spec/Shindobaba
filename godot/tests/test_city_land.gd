extends Node
## Şehir peyzajı: Konoha mahalleleri, cadde, kuşbakışı ve diğer köylerden görüntüler (--after: sonrası etiketi)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var tag = "after" if OS.get_cmdline_user_args().has("--after") else "before"
	var only = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	Game.world.env.weather_t = 999
	var kv = Game.village("konoha")
	# [köy, yerel (x, n), yaw, pitch, cam_dist, ad, ekstra yükseklik]
	var spots = [
		["konoha", Vector2(-60, -320), 0.0, -12.0, 14.0, "kl_mahalle1", 0.0],
		["konoha", Vector2(300, -260), 90.0, -12.0, 14.0, "kl_mahalle2", 0.0],
		["konoha", Vector2(0, -700), 0.0, -10.0, 12.0, "kl_cadde", 0.0],
		["konoha", Vector2(-380, 260), 45.0, -14.0, 14.0, "kl_mahalle3", 0.0],
		["konoha", Vector2(100, -400), 0.0, -35.0, 20.0, "kl_kus", 70.0],
		["konoha", Vector2(-200, 80), 0.0, -10.0, 12.0, "kl_merkez", 0.0],
		["suna", Vector2(0, -330), 0.0, -12.0, 16.0, "kl_suna", 0.0],
		["kiri", Vector2(0, -260), 0.0, -12.0, 16.0, "kl_kiri", 0.0],
		["kumo", Vector2(0, -260), 0.0, -12.0, 16.0, "kl_kumo", 0.0],
		["iwa", Vector2(0, -300), 0.0, -12.0, 16.0, "kl_iwa", 0.0],
	]
	var pk: Array = CityLandscape.parks_by.get("konoha", [])
	for i in mini(3, pk.size()):
		spots.append(["konoha", pk[i] + Vector2(0, -24), 0.0, -16.0, 14.0, "kl_park%d" % i, 0.0])
	var pl = main.player
	for sp in spots:
		if only != "" and not String(sp[5]).contains(only):
			continue
		var v = Game.village(sp[0])
		var p = Game.from_map(Vector2(v["x"], v["y"]) + sp[1])
		p.y = Game.ground_height(p.x, p.z) + 0.2
		pl.respawn(p)
		pl.yaw = sp[2]; pl.pitch = sp[3]; pl.cam_dist = sp[4]
		Game.world.env.time_of_day = 0.42
		await get_tree().create_timer(15.0 if sp[0] != "konoha" else 4.0).timeout
		if sp[6] > 0.0:
			pl.global_position.y += sp[6]
			pl.velocity = Vector3.ZERO
			pl.reset_physics_interpolation()
			await get_tree().create_timer(0.25).timeout
		await main.shot(sp[5] + "_" + tag)
	get_tree().quit()
