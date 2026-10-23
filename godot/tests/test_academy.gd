extends Node
## Akademi avlusu: Konoha ve diğer köylerin akademi çevresinden ekran görüntüleri
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var tag = "after" if OS.get_cmdline_user_args().has("--after") else "before"
	var kv = Game.village("konoha")
	var spots = [
		[Vector2(kv["x"] - 540, kv["y"] + 610 - 104), 0.0, -22.0, 34.0, "ak_konoha_on"],
		[Vector2(kv["x"] - 560, kv["y"] + 610 - 60), -60.0, -18.0, 16.0, "ak_konoha_avlu"],
		[Vector2(kv["x"] - 520, kv["y"] + 610 - 60), 70.0, -18.0, 16.0, "ak_konoha_bahce"],
	]
	for vid in ["suna", "kiri"]:
		var s = BuildVillageStory._site(Game.village(vid))
		spots.append([s + Vector2(0, -60), 0.0, -20.0, 24.0, "ak_" + vid])
	var pl = main.player
	for sp in spots:
		var p = Game.from_map(sp[0])
		p.y = Game.terrain_height(p.x, p.z) + 0.2
		pl.respawn(p)
		pl.yaw = sp[1]; pl.pitch = sp[2]; pl.cam_dist = sp[3]
		main.world.env.time_of_day = 0.42
		await get_tree().create_timer(5.0).timeout
		await main.shot(sp[4] + "_" + tag)
	# alacakaranlık: fenerler
	var p2 = Game.from_map(Vector2(kv["x"] - 540, kv["y"] + 610 - 100))
	p2.y = Game.terrain_height(p2.x, p2.z) + 0.2
	pl.respawn(p2)
	pl.yaw = 0.0; pl.pitch = -20.0; pl.cam_dist = 26.0
	main.world.env.time_of_day = 0.8
	await get_tree().create_timer(4.0).timeout
	await main.shot("ak_konoha_aksam_" + tag)
	get_tree().quit()
