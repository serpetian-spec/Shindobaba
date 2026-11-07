extends Node
## Gama Mise jutsusu: dükkân belirir, rakip içeri çekilir, kurbağaya döner, mide, tükürür
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.9, 0.9, 0.9), "top": Color(0.3, 0.5, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + fw * 8.0
	e.max_hp = 1e9; e.hp = 1e9
	e.set_physics_process(false)
	await _w(0.3)
	var hp0 = e.hp
	Jutsu.execute(pl, "kuchiyose_gama_mise_no_jutsu", e)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var rt = fw.cross(Vector3.UP)
	var t0 = 0.0
	for v in [[0.7, "gmj_shop"], [1.4, "gmj_toad"]]:
		await _w(v[0] - t0)
		t0 = v[0]
		cc.global_position = pl.global_position + rt * 10.0 + fw * 3.0 + Vector3.UP * 4.0
		cc.look_at(pl.global_position + fw * 9.0 + Vector3.UP * 2.0)
		cc.current = true
		await _w(0.05)
		await main.shot(v[1])
		print("GMJ %s enemy_visible=%s bind=%s" % [v[1], str(e.model.visible), str(e.has_status("bind"))])
	await _w(5.0)
	print("GMJ end dmg=%.1f visible=%s" % [hp0 - e.hp, str(e.model.visible)])
	get_tree().quit()
