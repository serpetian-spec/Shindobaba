extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "funato", "element": "suiton", "hair_style": "diken", "hair": Color(0.9, 0.75, 0.5), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.8, 0.6, 0.45), "eye": Color(0.5, 0.6, 0.7)}
	main._start_new_game()
	var pl = main.player
	Hud.show_game_hud(false)
	await get_tree().create_timer(1.5).timeout
	Jutsu.execute(pl, "funato_shiomaneki", null)
	await get_tree().create_timer(1.0).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var f = pl.face_dir()
	var sd = f.cross(Vector3.UP)
	for k in 2:
		var hp = pl.model.skel.global_transform * pl.model.skel.get_bone_global_pose(pl.model.skel.find_bone("RightHand"))
		var hpos = hp.origin
		cc.global_position = hpos + (f * 1.0 - sd * 0.6 + Vector3.UP * 0.2 if k == 0 else -sd * 1.1 + Vector3.UP * 0.3)
		cc.look_at(hpos + Vector3.DOWN * 0.2)
		cc.current = true
		await get_tree().create_timer(0.2).timeout
		await main.shot("claw_%d" % k)
	get_tree().quit()
