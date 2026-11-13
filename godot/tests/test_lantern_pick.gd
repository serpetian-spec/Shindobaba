extends Node
## Fener adayları: 5 tasarım yan yana, gündüz + gece. Çıktı: fener_gunduz / fener_gece / fener_<n>.png
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var a0 = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base = Game.from_map(Vector2(a0["x"], a0["y"])) + Vector3(300, 0, 235)
	var mp = Vector2(base.x, -base.z)
	pl.respawn(base + Vector3(0, 0, 12))
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	pl.set_process(false)
	pl.visible = false
	var h0 = Game.terrain_height(base.x, base.z)
	var b = Builder.new(main.world, mp.x, mp.y, h0, "FenerAday")
	for k in 5:
		var x = (k - 2) * 2.6
		var wp = b.w(Vector3(x, 0, 0))
		b.lantern_design(x, 0.0, k + 1, Game.terrain_height(wp.x, wp.z) - h0)
	b.finish()
	# boy ölçüsü: yanlarında bir insan
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup(CharacterModel.default_look())
	var mw = b.w(Vector3(-7.6, 0, 0))
	m.global_position = Vector3(mw.x, Game.terrain_height(mw.x, mw.z), mw.z)
	m.play("idle", 0.0)
	var cc = Camera3D.new()
	main.add_child(cc)
	cc.fov = 38.0
	cc.current = true
	var c0 = b.w(Vector3(0, 0, 0))
	c0.y = Game.terrain_height(c0.x, c0.z)
	for tod in [["gunduz", 0.45], ["gece", 0.92]]:
		main.world.env.time_of_day = tod[1]
		await get_tree().create_timer(1.5).timeout
		cc.global_position = c0 + Vector3(-1.2, 2.2, 13.5)
		cc.look_at(c0 + Vector3(-1.2, 1.5, 0))
		await get_tree().create_timer(0.4).timeout
		await main.shot("fener_%s" % tod[0])
		for k in 5:
			var q = b.w(Vector3((k - 2) * 2.6, 0, 0))
			q.y = Game.terrain_height(q.x, q.z)
			cc.global_position = q + Vector3(1.6, 2.3, 4.6)
			cc.look_at(q + Vector3(0.2, 1.5, 0))
			await get_tree().create_timer(0.3).timeout
			await main.shot("fener_%s_%d" % [tod[0], k + 1])
	get_tree().quit()
