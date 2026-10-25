extends Node
## Kum Shurikeni: kare kare (kollar açılır → savuruş → bıçak yelpazesi → isabet)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "sabaku", "element": "fuuton", "hair_style": "diken", "hair": Color(0.7, 0.15, 0.1), "top": Color(0.5, 0.35, 0.25), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.3, 0.6, 0.5)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.chakra = 9999.0
	for k in 3:
		var e = Enemy.new()
		var a = Enemy.archetype("rogue", k)
		a["respawn"] = false; a["hp"] = 99999.0
		e.setup(a)
		main.add_child(e)
		var p = pl.global_position + pl.face_dir() * 14.0 + pl.face_dir().cross(Vector3.UP) * (k - 1) * 4.0
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		e.set_physics_process(false)
		if k == 1:
			pl.combat.lock_target = e
			pl.facing = atan2(-(p - pl.global_position).x, -(p - pl.global_position).z)
	pl.set_process(false)
	var f = pl.face_dir()
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.global_position = pl.global_position + f * 5.0 + f.cross(Vector3.UP) * 9.0 + Vector3.UP * 3.5
	cam.look_at(pl.global_position + f * 5.0 + Vector3.UP * 1.8)
	cam.current = true
	var ver = OS.get_environment("VER")
	Jutsu.execute(pl, "suna_shuriken", pl.combat.lock_target)
	var last = 0.0
	for i in [0.25, 0.45, 0.6, 0.8, 1.05]:
		await get_tree().create_timer(i - last).timeout
		last = i
		await main.shot("ssh_%s_%d" % [ver, int(i * 100)])
	get_tree().quit()
