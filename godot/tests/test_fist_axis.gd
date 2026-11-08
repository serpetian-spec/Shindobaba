extends Node
## Yumruk ekseni: fist açık/kapalıyken parmak kemiği yönleri + yakın çekim (idle duruşta)
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
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	var m = pl.model
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for mode in [0.0, 1.0]:
		m.overlay.fist = {"Right": mode, "Left": mode}
		await _w(0.3)
		var sk: Skeleton3D = m.skel
		var hb = sk.find_bone("RightHand")
		var hp = (sk.global_transform * sk.get_bone_global_pose(hb)).origin
		var tip = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("RightIndexDistal"))).origin
		var mid = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("RightIndexProximal"))).origin
		print("FA mode=%d hand=%s prox=%s tip=%s tipdist=%.3f" % [int(mode), str(hp), str(mid), str(tip), tip.distance_to(hp)])
		cc.global_position = hp + pl.face_dir().cross(Vector3.UP) * 0.6 + Vector3.UP * 0.1 + pl.face_dir() * 0.25
		cc.look_at(hp)
		cc.fov = 35.0
		cc.current = true
		await main.shot("fa_%d" % int(mode * 100))
	get_tree().quit()
