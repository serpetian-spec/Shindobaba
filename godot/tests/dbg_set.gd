extends Node
## Set görünümü: SET kıyafeti, önden/arkadan/yandan/çapraz + yakın yaka
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "uzun", "hair": Color(0.1, 0.1, 0.14), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("konoha")
	pl.respawn(Game.from_map(Vector2(v["x"] + 300, v["y"] + float(v["r"]) + 900)))
	await get_tree().create_timer(1.0).timeout
	Gear.grant(Game.profile, OS.get_environment("SET"), "set")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await get_tree().create_timer(2.5).timeout
	Hud.show_game_hud(false)
	pl.set_physics_process(false)
	pl.model.play("idle")
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 38
	var fw = pl.face_dir()
	var sd = fw.cross(Vector3.UP)
	var c = pl.global_position + Vector3.UP * 0.95
	var i = 0
	for o in [fw * 3.2, -fw * 3.2, sd * 3.2, (fw + sd).normalized() * 3.2, fw * 1.2 + Vector3.UP * 0.55]:
		cam.global_position = c + o + Vector3.UP * 0.15
		cam.look_at(c + (Vector3.UP * 0.55 if i == 4 else Vector3.ZERO))
		await get_tree().create_timer(0.2).timeout
		await main.shot("set_%d" % i)
		i += 1
	get_tree().quit()
