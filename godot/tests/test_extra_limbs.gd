extends Node
## Tarenken / Tarenkyaku / Kisei Kikai: ek uzuvlar ve omuz yüzü yakın çekim
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
	pl.facing = 0.0
	var b0 = pl.global_position
	var fw = Vector3(0, 0, -1)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	Buffs.add("juin2", 60.0, {})
	Mastery.gain(Game.profile, "ninjutsu", 50.0)
	for spec in [["tarenken", 0.2], ["tarenkyaku", 0.22], ["kisei_kikai_no_jutsu", 0.9]]:
		var id: String = spec[0]
		var e := Enemy.new()
		e.setup(Enemy.archetype("rogue", 1))
		main.actors.add_child(e)
		e.global_position = b0 + fw * 1.7
		e.max_hp = 1e9; e.hp = 1e9
		e.set_physics_process(false)
		pl.global_position = b0
		pl.facing = 0.0
		Game.profile["learned"].append(id)
		pl.combat.cooldowns.erase(id)
		await _w(0.3)
		pl.combat.begin_cast(id)
		await _w(pl.combat.cast_time + float(spec[1]))
		cc.global_position = b0 + Vector3(2.6, 1.5, -0.9)
		cc.look_at(b0 + fw * 0.9 + Vector3.UP * 1.1)
		cc.fov = 45.0
		cc.current = true
		await main.shot("limb_%s" % id)
		pl.cam.current = true
		await _w(1.5)
		e.queue_free()
		await _w(0.5)
	get_tree().quit()
