extends Node
## Doki modeli: üç iblis yan yana + ölçek için oyuncu (Tayuya boyu); ön ve yan açı, pozlar
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "katon", "hair_style": "uzun", "hair": Color(0.85, 0.4, 0.35), "top": Color(0.85, 0.82, 0.75), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	pl.set_physics_process(false)
	var b0: Vector3 = pl.global_position
	var fw = Vector3(0, 0, -1)
	pl.facing = 0.0
	var pose = OS.get_environment("DPOSE") if OS.get_environment("DPOSE") != "" else "stand"
	var ds = []
	for k in 3:
		var p = b0 + fw * 5.0 + Vector3((k - 1) * 4.2, 0, 0)
		p.y = Game.ground_height(p.x, p.z)
		var d = Doki.spawn(get_tree().current_scene, p, 0.0, [0, 1, 2][k])
		d.rotation.y = PI   # oyuncuya (kameraya) dönük
		ds.append(d)
	await _w(0.3)
	for d in ds:
		d.set_pose(pose, 0.0)
	await _w(0.3)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for v in [[Vector3(0, 3.6, 8.5), "doki_front"], [Vector3(9.0, 3.0, 1.0), "doki_side"], [Vector3(-3, 3.5, 11.0), "doki_wide"]]:
		cc.global_position = b0 + fw * 5.0 + v[0]
		cc.look_at(b0 + fw * 5.0 + Vector3.UP * 2.4)
		cc.current = true
		await _w(0.1)
		await main.shot(v[1] + ("_" + pose if pose != "stand" else ""))
	for d in ds:
		print("DK kind=%d top=%.2f hand_y=%.2f sh_y=%.2f hand_fwd=%.2f club=%s" % [d.kind, d.head.global_position.y - d.global_position.y, d.hand_pos(true).y - d.global_position.y, d.arms[1]["sh"].global_position.y - d.global_position.y, (d.global_transform.affine_inverse() * d.hand_pos(true)).z, str(d.weapon.global_position - d.global_position) if d.weapon else "-"])
	get_tree().quit()
