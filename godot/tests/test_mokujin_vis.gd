extends Node
## Mokujin modeli: 110 m tahta dev (ölçek: dibinde oyuncu)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "senju", "element": "doton", "hair_style": "uzun", "hair": Color(0.1, 0.08, 0.07), "top": Color(0.6, 0.2, 0.2), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 600, vs["y"])))
	await _w(1.0)
	pl.set_physics_process(false)
	var at: Vector3 = pl.global_position + Vector3(0, 0, -40.0)
	at.y = Game.ground_height(at.x, at.z)
	var m = Mokujin.spawn(get_tree().current_scene, at, PI)
	var pose = OS.get_environment("MPOSE") if OS.get_environment("MPOSE") != "" else "stand"
	await _w(0.3)
	m.set_pose(pose, 0.0)
	await _w(0.3)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.far = 4000.0
	for v in [[Vector3(-25, 60, 170), Vector3(0, 58, 0), "mj_front"], [Vector3(150, 60, 40), Vector3(0, 55, 0), "mj_side"], [Vector3(18, 96, 52), Vector3(0, 92, 0), "mj_face"]]:
		cc.global_position = at + v[0]
		cc.look_at(at + v[1])
		cc.current = true
		await _w(0.1)
		await main.shot(v[2])
	var hp: Vector3 = m.head.global_position
	var fwd: Vector3 = -m.global_transform.basis.z
	cc.global_position = hp + fwd * 55.0 + Vector3(12, 4, 0)
	cc.look_at(hp + Vector3.UP * 2.0)
	await _w(0.1)
	await main.shot("mj_face2")
	print("MJ head_y=%.1f fist_y=%.1f" % [m.head.global_position.y - at.y, m.fist_pos(true).y - at.y])
	get_tree().quit()
