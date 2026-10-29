extends Node
## Kusarigama: elde tutuş + orta menzil kombo (fırlat/savur/çek/dön)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(1.0).timeout
	Gear.grant(Game.profile, "kusarigama", "sag")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await get_tree().create_timer(4.0).timeout
	Hud.show_game_hud(false)
	pl.model.set_drawn(true, false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	var fw = pl.face_dir()
	var side = fw.cross(Vector3.UP)
	var c0 = pl.global_position + Vector3.UP
	cam.global_position = c0 + fw * 2.0 + side * 0.8 + Vector3.UP * 0.2
	cam.look_at(c0 + Vector3.UP * 0.2)
	await get_tree().create_timer(1.0).timeout
	await main.shot("k_idle")
	var e = Enemy.new()
	var a = Enemy.archetype("bandit", 0)
	a["hp"] = 5000.0
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + fw * 5.0
	e.set_physics_process(false)
	pl.combat.lock_target = e
	cam.global_position = pl.global_position - side * 7.0 + fw * 2.5 + Vector3.UP * 2.5
	cam.look_at(pl.global_position + fw * 2.5 + Vector3.UP)
	for i in 5:
		var hp0 = e.hp
		pl.combat.attack()
		await get_tree().create_timer(0.5).timeout
		await main.shot("k_step%d" % i)
		await get_tree().create_timer(0.9).timeout
		print("KS step=%d dmg=%.0f dist=%.1f" % [i, hp0 - e.hp, e.global_position.distance_to(pl.global_position)])
	e.queue_free()
	await get_tree().create_timer(2.0).timeout
	pl.model.set_drawn(false, false)
	cam.global_position = c0 - side * 1.6 + fw * 1.2 + Vector3.UP * 0.1
	cam.look_at(c0 - Vector3.UP * 0.1)
	await get_tree().create_timer(0.5).timeout
	await main.shot("k_stowed")
	get_tree().quit()
