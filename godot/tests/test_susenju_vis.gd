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
	var at: Vector3 = pl.global_position + Vector3(0, 0, -200.0)
	at.y = Game.ground_height(at.x, at.z)
	var m = ShinSusenju.spawn(get_tree().current_scene, at, PI)
	var pose = OS.get_environment("MPOSE") if OS.get_environment("MPOSE") != "" else "stand"
	await _w(0.3)

	await _w(0.3)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.far = 6000.0
	for v in [[Vector3(-60, 260, 1150), Vector3(0, 330, 0), "ss_front"], [Vector3(-700, 250, 700), Vector3(0, 330, 0), "ss_side"], [Vector3(-80, 260, 330), Vector3(0, 250, 0), "ss_face"]]:
		cc.global_position = at + v[0]
		cc.look_at(at + v[1])
		cc.current = true
		await _w(0.1)
		await main.shot(v[2])
	print("SS arms=%d" % m.fan_xf.size())
	get_tree().quit()
