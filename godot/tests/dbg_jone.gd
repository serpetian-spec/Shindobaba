extends Node
## Tek jutsu görsel kontrol: JO_ID jutsusu atılır, JO_T="0.5,1.5,3" anlarında kare; JO_DIST kamera uzaklığı, JO_H yükseklik
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 60
	Hud.show_game_hud(false)
	Combat.quiet = true
	pl.set_process(false)
	var id = OS.get_environment("JO_ID")
	var times = Array(OS.get_environment("JO_T").split(",")).map(func(x): return float(x))
	var dist = float(OS.get_environment("JO_DIST")) if OS.get_environment("JO_DIST") != "" else 18.0
	var h = float(OS.get_environment("JO_H")) if OS.get_environment("JO_H") != "" else 6.0
	var tz = float(OS.get_environment("JO_TZ")) if OS.get_environment("JO_TZ") != "" else 12.0
	var spot = Missions._spot("suna", 600, 900)
	var base = Missions.open_ground(Game.from_map(Vector2(spot[0], spot[1])), 60.0)
	pl.global_position = base + Vector3(0, 0.5, 0)
	pl.facing = 0.0
	pl.model.rotation.y = 0.0
	await get_tree().create_timer(4.0).timeout
	var a = Enemy.archetype("rogue", 0)
	a["hp"] = 1e9
	a["respawn"] = false
	a["jutsu"] = []
	var tgt = Enemy.new()
	tgt.setup(a)
	get_tree().current_scene.add_child(tgt)
	var tp = base + Vector3(0, 0, -tz)
	tp.y = Game.ground_height(tp.x, tp.z)
	tgt.global_position = tp
	tgt.home = tp
	tgt.set_physics_process(false)
	var cam = Camera3D.new()
	cam.fov = 60
	main.add_child(cam)
	cam.current = true
	var mid = (base + tp) * 0.5 + Vector3.UP * (float(OS.get_environment("JO_LOOK")) if OS.get_environment("JO_LOOK") != "" else h * 0.4)
	cam.global_position = mid + Vector3(dist, h, dist * 0.25)
	cam.look_at(mid, Vector3.UP)
	await get_tree().create_timer(0.5).timeout
	pl.chakra = 99999.0
	Jutsu.execute(pl, id, tgt)
	var t0 = 0.0
	for t in times:
		await get_tree().create_timer(maxf(0.01, t - t0)).timeout
		t0 = t
		await main.shot("%s_%s" % [id, str(t)])
	get_tree().quit()
