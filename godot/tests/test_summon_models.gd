extends Node
## Çağırma jutsuları gerçek modellerle: Katsuyu Daibunretsu, Doton Tsuiga, Yatai Kuzushi, Enma Kongōnyoi
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "sarutobi", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var n = 0
	for v in [["katsuyu_daibunretsu", 1.0], ["kuchiyose_doton_tsuiga_no_jutsu", 0.55], ["kuchiyose_yatai_kuzushi_no_jutsu", 0.62], ["sarutobi_enma_kongonyoi", 0.2]]:
		var b0 = base + Vector3(60.0 * n, 0, 0)
		n += 1
		pl.respawn(b0)
		await _w(0.8)
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
		Jutsu.execute(pl, v[0], e)
		await _w(v[1])
		var rt = fw.cross(Vector3.UP)
		cc.global_position = pl.global_position + rt * 9.0 - fw * 2.0 + Vector3.UP * 4.0
		cc.look_at(pl.global_position + fw * 5.0 + Vector3.UP * 1.0)
		cc.current = true
		await _w(0.05)
		await main.shot("sm_%s" % v[0])
		print("SM %s ok" % v[0])
		pl.cam.current = true
		await _w(2.5)
		e.queue_free()
	get_tree().quit()
