extends Node
## Kelebek Modu kanatları: önden/arkadan/yandan + karakter dönünce kanatlar da dönüyor mu

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "shimura", "element": "fuuton", "hair_style": "diken",
		"hair": Color(0.45, 0.25, 0.15), "top": Color(0.55, 0.15, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.45
	Game.world.env.weather = "açık"
	var pl: Player = main.player
	var vs = Game.village("suna")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"]))
	pl.respawn(base)
	await _wait(2.0)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var e = Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 5.0
	e.max_hp = 1e9
	e.hp = 1e9
	await _wait(0.5)
	for ti in [0.08, 0.18]:
		Jutsu.execute(pl, "futon_shinkujin", e)
		await _wait(ti)
		var hp = pl.combat.modes.p.global_position
		var fd = pl.face_dir()
		var sd = fd.cross(Vector3.UP).normalized()
		var hand = Jutsu.get_node("/root/PathJutsu").hand_pos(pl, true) if false else pl.global_position + Vector3.UP * 1.1 + sd * 0.3
		cc.global_position = hand + fd * 1.3 + sd * 1.0 + Vector3.UP * 0.4
		cc.look_at(hand)
		cc.current = true
		await main.shot("jin_%s" % str(ti))
		await _wait(1.5)
	get_tree().quit()
