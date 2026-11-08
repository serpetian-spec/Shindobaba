extends Node
## Köy baskını (savaş): ANBU dalgası ANBU kıyafetinde, Kage beyaz cübbe + köy renkli Kage şapkasıyla çıkar — ekran görüntüsü
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.profile["flags"]["rogue"] = true
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for vid in ["konoha", "kumo"]:
		Orgs._raid = {"vid": vid, "wave": 3, "t": 0.0, "out_t": 0.0, "nodes": [], "kage": false}
		Orgs._raid_wave(vid, Orgs.RAID_WAVES[2])
		Orgs._raid_kage(vid)
		var nodes: Array = Orgs._raid["nodes"]
		var base = pl.global_position + Vector3(0, 0, -6)
		for i in nodes.size():
			var e = nodes[i]
			e.set_physics_process(false)
			e.global_position = Game.ground_point(base + Vector3((i - 2) * 1.6, 0, 0)) if Game.has_method("ground_point") else base + Vector3((i - 2) * 1.6, 0, 0)
			e.global_position.y = Game.ground_height(e.global_position.x, e.global_position.z)
			e.facing = 0.0
			e.rotation.y = 0.0
		await _w(1.5)
		cc.global_position = base + Vector3(0, 1.6, -5.0)
		cc.look_at(base + Vector3.UP * 1.1)
		cc.current = true
		await main.shot("raid_%s_front" % vid)
		var k = nodes[-1]
		cc.global_position = k.global_position + Vector3(0.6, 1.9, -2.2)
		cc.look_at(k.global_position + Vector3.UP * 1.5)
		await main.shot("raid_%s_kage" % vid)
		var a0 = nodes[0]
		cc.global_position = a0.global_position + Vector3(0.4, 1.4, -2.0)
		cc.look_at(a0.global_position + Vector3.UP * 1.0)
		await main.shot("raid_%s_zanbu" % vid)
		print("RAID %s kage name=%s head=%s outer=%s anbu face=%s vest_style=%s" % [vid, k.display_name, k.look.get("head_style"), k.look.get("outer_style"), nodes[0].look.get("face_style"), nodes[0].look.get("vest_style")])
		for e in nodes:
			e.queue_free()
		await _w(0.3)
	get_tree().quit()
