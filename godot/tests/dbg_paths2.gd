extends Node
## Yeni efsane yolları: Şifacı ve Sekiz Kapı mekânları kuruldu mu, katılım ve teknik öğrenme
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var pl = main.player
	print("P2 lairs=%s" % [LegendPaths.lairs.keys()])
	Game.profile["level"] = 30
	Game.profile["ryo"] = 999999
	for pid in ["tip", "kapi"]:
		LegendPaths.set_state(pid, LegendPaths.JOINED)
		for jid in LegendPaths.PATHS[pid]["order"]:
			LegendPaths._teach(pid, jid, true)
		print("P2 %s next=%s" % [pid, LegendPaths.next_step(pid)])
	print("P2 gates_skill=%s" % ("gates" in Game.profile["skills"]))
	var lp = LegendPaths.lairs["kapi"]
	var w = Game.from_map(Vector2(lp[0], lp[1]))
	pl.respawn(w + Vector3(0, 0, 10))
	await get_tree().create_timer(4.0).timeout
	Hud.show_game_hud(false)
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = w + Vector3(14, 9, -16)
	cam.look_at(w + Vector3(0, 2, 6))
	await get_tree().create_timer(0.5).timeout
	await main.shot("dojo")
	get_tree().quit()
