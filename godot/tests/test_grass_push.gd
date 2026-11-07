extends Node
## Çimen eğilmesi: oyuncunun çevresindeki çimen dışa yatar (karşılaştırma: itme kapalı)
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var v = Game.village("konoha")
	# köy dışında çimenli bir yer (biome 7)
	var base = Game.from_map(Vector2(v["x"] + float(v["r"]) + 250, v["y"]))
	for r in range(0, 2000, 60):
		var q = base + Vector3(r, 0, 0)
		if Game.biome_at(q.x, q.z) in [7, 2] and Game.road_at(q.x, q.z) < 0.1:
			base = q
			break
	pl.respawn(base)
	await _w(2.0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = pl.global_position + Vector3(1.8, 0.7, 1.8)
	cc.look_at(pl.global_position + Vector3(0, 0.25, 0))
	cc.current = true
	await _w(0.3)
	await main.shot("grass_push")
	var g = get_tree().current_scene.find_child("Grass", true, false)
	g.set_process(false)
	RenderingServer.global_shader_parameter_set("push0", Vector4(0, -10000, 0, 0))
	await _w(0.3)
	await main.shot("grass_nopush")
	print("GRASS biome=%d" % Game.biome_at(pl.global_position.x, pl.global_position.z))
	get_tree().quit()
