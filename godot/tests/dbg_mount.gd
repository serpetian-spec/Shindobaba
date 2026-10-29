extends Node
## Binek: oyuncu hayvanın kafasına/sırtına oturuyor mu (gövdenin içinde kaybolmasın)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	for spec in [["kurbağa", 2], ["yılan", 2], ["örümcek", 1], ["kaplumbağa", 2]]:
		var s = Summon.new()
		s.contract = spec[0]
		s.tier = spec[1]
		s.def = Contracts.DEFS[spec[0]]["tiers"][spec[1]]
		s.owner_f = pl
		s.team = pl.team
		get_tree().current_scene.add_child(s)
		s.global_position = pl.global_position + Vector3(0, 0, -6)
		await get_tree().create_timer(0.8).timeout
		s.mounted = true
		s._seat = Vector3.INF
		pl.set_meta("riding", s)
		await get_tree().create_timer(2.5).timeout
		var h = s.height
		print("MOUNT %s h=%.1f seat=%s pl_above=%.2f" % [spec[0], h, s._seat, pl.global_position.y - s.global_position.y])
		pl.set_process(false)
		var cam = Camera3D.new()
		main.add_child(cam)
		cam.current = true
		cam.global_position = pl.global_position + Vector3(6, 4, 7)
		cam.look_at(pl.global_position + Vector3.UP)
		await get_tree().create_timer(0.3).timeout
		await main.shot("mount_%s" % spec[0])
		cam.queue_free()
		pl.set_process(true)
		s._dismount()
		s.dismiss()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
