extends Node
## Silahsız yumruk: el sıkılı mı (yakın çekim); karşılaştırma için düz vuruş adımları
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	Game.profile["weapon_drawn"] = false
	pl.model.set_drawn(false, false)
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	pl.facing = 0.0
	var b0 = pl.global_position
	var fw: Vector3 = pl.face_dir()
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for k in 3:
		pl.combat.attack()
		var c = pl.combat._combo(pl.combat.step)
		await _w(float(c.get("hit", 0.2)) * 0.9)
		var m = pl.model
		var hp = pl.global_position + Vector3.UP * 1.3
		var hits = {}
		for side in ["RightHand", "LeftHand"]:
			var bi = m.skel.find_bone(side)
			hits[side] = (m.skel.global_transform * m.skel.get_bone_global_pose(bi)).origin
		# öne uzanan el (gövdeden en uzaktaki)
		var fwd_now = pl.face_dir()
		hp = hits["RightHand"] if (hits["RightHand"] - pl.global_position).dot(fwd_now) > (hits["LeftHand"] - pl.global_position).dot(fwd_now) else hits["LeftHand"]
		fw = fwd_now
		cc.global_position = hp + fw.cross(Vector3.UP) * 0.9 + Vector3.UP * 0.25 + fw * 0.3
		cc.look_at(hp)
		cc.fov = 40.0
		cc.current = true
		print("FIST step=%d fist=%s" % [k, str(pl.model.overlay.fist)])
		await main.shot("fist_%d" % k)
		await _w(float(c.get("dur", 0.5)))
	get_tree().quit()
