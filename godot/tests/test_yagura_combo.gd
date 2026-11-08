extends Node
## Yagura sopası kombosu: her adımda su çıkıyor mu (görüntü)
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.85, 0.88), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	print("HC1 grant=%s" % [str(Gear.grant(Game.profile, "yagura_sopa", "sag"))])
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await _w(1.0)
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	await _w(1.5)
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	var b0 = pl.global_position
	pl.facing = 0.0
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	e.global_position = b0 + fw * 3.0
	e.max_hp = 1e9; e.hp = 1e9
	e.set_physics_process(false)
	await _w(0.6)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for k in 6:
		if k != 3:
			pl.global_position = b0
		pl.combat.face_to(e)
		var hp0 = e.hp
		pl.combat.attack()
		var c = pl.combat._combo(pl.combat.step)
		var ht = float(c.get("hit", 0.2))
		await _w(maxf(0.02, ht + (0.3 if k >= 4 else 0.02)))
		cc.global_position = b0 + fw.cross(Vector3.UP) * 4.5 + fw * 1.2 + Vector3.UP * 1.8
		cc.look_at(b0 + fw * 1.3 + Vector3.UP * 1.1)
		cc.current = true
		await main.shot("yagura_c%d" % k)
		await _w(maxf(0.05, float(c.get("dur", 0.5)) - ht))
		print("HC2 step=%d key=%s dmg=%.1f" % [k, str(c.get("keyed", "")), hp0 - e.hp])
	get_tree().quit()
