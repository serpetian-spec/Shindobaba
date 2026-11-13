extends Node
## Bölge fenerleri: her köyün hemen dışında Builder.lantern() ile bir fener kurar ve çeker (gündüz + gece). Çıktı: bolge_<köy>_<g|n>.png
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	pl.set_process(false)
	pl.visible = false
	var cc = Camera3D.new()
	main.add_child(cc)
	cc.fov = 34.0
	cc.current = true
	for vid in ["konoha", "suna", "iwa", "ame", "kusa", "shimo", "kiri", "kumo"]:
		var vs = Game.village(vid)
		var mp = Vector2(float(vs["x"]) + float(vs["r"]) + 90.0, float(vs["y"]))
		var base = Game.from_map(mp)
		pl.global_position = base + Vector3(0, 2, 14)
		await get_tree().create_timer(2.5).timeout
		var h0 = Game.terrain_height(base.x, base.z)
		var b = Builder.new(main.world, mp.x, mp.y, h0, "FenerBolge_" + vid)
		b.lantern(0.0, 0.0, 3.2)
		b.finish()
		print("FENER ", vid, " -> ", Builder.lantern_region(base.x, base.z))
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(CharacterModel.default_look())
		m.global_position = Vector3(base.x - 1.6, Game.terrain_height(base.x - 1.6, base.z), base.z)
		m.play("idle", 0.0)
		for tod in [["g", 0.45], ["n", 0.92]]:
			main.world.env.time_of_day = tod[1]
			await get_tree().create_timer(1.0).timeout
			cc.global_position = Vector3(base.x, h0, base.z) + Vector3(1.5, 2.4, 8.5)
			cc.look_at(Vector3(base.x - 0.5, h0 + 1.7, base.z))
			await get_tree().create_timer(0.3).timeout
			await main.shot("bolge_%s_%s" % [vid, tod[0]])
		m.queue_free()
	get_tree().quit()
