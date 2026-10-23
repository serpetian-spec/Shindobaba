extends Node
## Kök testi: üç ağaç tipini (anime, Konoha orman, Ölüm Ormanı) oyuncunun önüne koyup yakından çeker.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	Game.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	main.player.respawn(Game.from_map(Vector2(v["x"] + 300, v["y"] - float(v["r"]) - 250)))
	await get_tree().create_timer(4.0).timeout
	Game.world.vegetation.visible = false
	if Game.world.get("grass"):
		Game.world.grass.visible = false
	main.player.visible = false
	var p = main.player.global_position
	var fwd = -main.player.global_transform.basis.z
	var cams = [[0, Vector3(0, 0, 0), 5.0], [9, Vector3(0, 0, 0), 10.0], [5, Vector3(0, 0, 0), 30.0]]
	for c in cams:
		var mi = MeshInstance3D.new()
		mi.mesh = Props.vegetation_mesh(c[0])
		get_tree().current_scene.add_child(mi)
		var at = p + fwd * c[2]
		at.y = Game.ground_height(at.x, at.z, false)
		mi.global_position = at
		var cam = Camera3D.new()
		get_tree().current_scene.add_child(cam)
		var side = fwd.cross(Vector3.UP).normalized()
		cam.global_position = at - fwd * c[2] * 0.9 + side * c[2] * 0.5 + Vector3.UP * c[2] * 0.3
		cam.look_at(at + Vector3.UP * c[2] * 0.04)
		cam.current = true
		await get_tree().create_timer(0.8).timeout
		await main.shot("root_%d" % c[0])
		mi.queue_free()
		cam.queue_free()
	get_tree().quit()
