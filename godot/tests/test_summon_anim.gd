extends Node
## Çağırma animasyonu: mühürler → avuç yere → mühür çemberi → duman → hayvan (kare kare çekim)
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
	var tag = "v1"
	var cid = "kurbağa"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		if a.begins_with("--c="):
			cid = a.substr(4)
	Game.profile["level"] = 30
	Game.profile["rank"] = 2
	Contracts.sign(cid)
	Game.profile["summon"] = cid
	Progress.learn("kuchiyose", false)
	pl.chakra = 9999.0
	pl.max_chakra = 9999.0
	pl.set_process(false)
	var f = pl.face_dir()
	var side = f.cross(Vector3.UP)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.global_position = pl.global_position + f * 4.5 + side * 3.2 + Vector3.UP * 2.0
	cam.look_at(pl.global_position + f * 1.6 + Vector3.UP * 0.6)
	cam.current = true
	pl.combat.begin_cast("kuchiyose")
	var times = [0.4, 0.75, 0.9, 1.05, 1.35, 2.0]
	var last = 0.0
	for i in times.size():
		await get_tree().create_timer(times[i] - last).timeout
		last = times[i]
		await main.shot("summon_%s_%d" % [tag, i])
	get_tree().quit()
