extends Node
## Köy suları: Ame gölü, Kiri gölü/kanalları, Taki, Yu — oyuncu su yüzeyinde mi
var main: Node

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _wait(2.0)
	Hud.close_dialog()
	var pl = main.player
	for vid in ["ame", "kiri", "taki", "yu"]:
		var v = Game.village(vid)
		var c = Game.from_map(Vector2(v["x"], v["y"]))
		pl.global_position = c + Vector3(0, 3, 0)
		await _wait(8.0)
		# köyün en yakın kayıtlı suyu (arazinin üstünde)
		var best = null
		var bd = 1e9
		for e in Game.water_list:
			if not is_instance_valid(e[0]):
				continue
			var d = (e[1] as Vector2).distance_to(Vector2(c.x, c.z))
			var tt = Game.terrain_height(e[1].x, e[1].y)
			if d < bd and d < float(v["r"]) * 1.5 and e[4] > tt + 0.1:
				bd = d; best = e
		if best == null:
			print("WTV %s: arazi üstünde kayıtlı su yok" % vid)
			continue
		var at = Vector3(best[1].x, best[4], best[1].y)
		pl.global_position = at + Vector3(0, 1.0, 0)
		pl.velocity = Vector3.ZERO
		await _wait(1.5)
		var p = pl.global_position
		print("WTV %s terr=%.2f water=%.2f y=%.2f on_water=%s swim=%s" % [vid, Game.terrain_height(p.x, p.z), Game.water_level(p.x, p.z), p.y, pl.on_water, pl.swimming])
		pl.set_process(false)
		pl.cam.global_position = p + Vector3(0, 2.5, 6)
		pl.cam.look_at(p + Vector3(0, 0.8, 0))
		await _wait(0.3)
		await main.shot("wv_" + vid)
		pl.set_process(true)
	get_tree().quit()
