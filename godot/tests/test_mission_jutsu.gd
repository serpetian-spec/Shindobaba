extends Node
## Görev düşmanı jutsu atıyor mu: D / C / B rütbede haydut, samuray, kaçak türleriyle doğur, 25 sn izle, atılan teknikleri say
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var at = main.player.global_position + Vector3(0, 0, 900)
	at.y = Game.ground_height(at.x, at.z)
	main.player.respawn(at)
	await get_tree().create_timer(1.5).timeout
	for cs in [["C", "bandit"], ["B", "samurai"]]:
		Game.profile["active_mission"] = {"rank": cs[0], "type": "x"}
		var es = Missions._spawn(cs[1], main.player.global_position + Vector3(14, 0, 0), 3, 6.0, "", false)
		var rk = Missions._mission_rank()
		Game.profile.erase("active_mission")
		var casts = {}
		var sw0 = Enemy.swings
		var far_t = 0.0
		var info = []
		for e in es:
			info.append("%s/%s lv%d j=%s" % [e.display_name, e.arch["kind"], e.level, str(e.arch["jutsu"])])
		var t = 0.0
		while t < 25.0:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			main.player.hp = main.player.max_hp
			if t > 12.0 and t < 12.2:
				main.player.global_position += Vector3(45, 0, 0)   # biraz uzaklaş: takip sürüyor mu
				main.player.global_position.y = Game.ground_height(main.player.global_position.x, main.player.global_position.z) + 1.0
			for e in es:
				if is_instance_valid(e) and e.state == "cast" and e.has_meta("cast_id"):
					casts[String(e.get_meta("cast_id"))] = true
		print("MJ vurus=", Enemy.swings - sw0, " takip=", es.filter(func(e): return is_instance_valid(e) and not e.dead and e.target == main.player).size(), "/", es.size(), " ", cs, " n=", es.size(), " rank=", rk, " atilan=", casts.keys(), " | ", info)
		for e in es:
			if is_instance_valid(e):
				e.queue_free()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
