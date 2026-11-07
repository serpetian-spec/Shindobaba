extends Node
## Shiki Fūjin kanon: Shinigami belirir, ruh yakalanır; chakra yeterse ölüm, yetmezse kollar mühürlenir; çağıran 12 sn sonra ölür
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "sarutobi", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.3, 0.3), "top": Color(0.2, 0.2, 0.25), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
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
	for strong in [false, true]:
		var e := Enemy.new()
		e.setup(Enemy.archetype("rogue", 1))
		main.actors.add_child(e)
		e.global_position = pl.global_position + fw * 5.0
		e.set_physics_process(false)
		await _w(0.3)
		e.max_chakra = 9999.0 if strong else 50.0
		e.chakra = e.max_chakra
		e.max_hp = 1e5 if strong else e.max_hp
		e.hp = e.max_hp
		pl.max_chakra = 300.0
		pl.chakra = 300.0
		pl.hp = pl.max_hp
		Jutsu.execute(pl, "shiki_fujin", e)
		await _w(1.5)
		if not strong:
			var cc = Camera3D.new()
			get_tree().current_scene.add_child(cc)
			var rt = fw.cross(Vector3.UP)
			cc.global_position = pl.global_position + rt * 9.0 + fw * 6.0 + Vector3.UP * 3.5
			cc.look_at(pl.global_position + fw * 2.0 + Vector3.UP * 3.0)
			cc.current = true
			await _w(0.05)
			await main.shot("shiki_cast")
			pl.cam.current = true
		await _w(1.2)
		print("SF strong_target=%s dead=%s sealed=%s caster_hp=%.0f" % [str(strong), str(not is_instance_valid(e) or e.dead), str(is_instance_valid(e) and e.has_status("sealed")), pl.hp])
		if is_instance_valid(e) and not e.dead:
			e.queue_free()
	await _w(12.0)
	print("SF after 12s caster_hp=%.0f" % pl.hp)
	get_tree().quit()
