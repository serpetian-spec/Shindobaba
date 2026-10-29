extends Node
## Lanetli mühür II: dört form (kanat, boynuz, kaya, örümcek) — kemiğe bağlı parçalar + ten rengi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.3, 0.3, 0.35), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(true)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 45
	cam.current = true
	for f in ["kanat", "boynuz", "kaya", "orumcek"]:
		Game.profile["juin_form"] = f
		pl.max_hp = 9999.0
		pl.hp = 9999.0
		PathJutsu.get_pinst().p_juin_ni_no_dankai(pl, null)
		await get_tree().create_timer(1.2).timeout
		pl.set_process(false)
		var fw = pl.face_dir()
		var c0 = pl.global_position + Vector3.UP * 1.3
		cam.global_position = c0 - fw * 3.2 + fw.cross(Vector3.UP) * 1.6 + Vector3(0, 0.4, 0)
		cam.look_at(c0)
		await get_tree().create_timer(0.2).timeout
		await main.shot("juin_%s_a" % f)
		cam.global_position = c0 + fw * 3.2 + fw.cross(Vector3.UP) * 1.2 + Vector3(0, 0.6, 0)
		cam.look_at(c0)
		await get_tree().create_timer(0.2).timeout
		await main.shot("juin_%s_b" % f)
		pl.set_process(true)
		if pl.has_method("stop_flight"):
			pl.stop_flight()
		get_tree().call_group("juin_dbg", "queue_free")
		await get_tree().create_timer(19.0).timeout
	get_tree().quit()
