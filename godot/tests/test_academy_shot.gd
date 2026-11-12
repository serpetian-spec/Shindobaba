extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var site = OS.get_environment("SITE") if OS.get_environment("SITE") != "" else "academy"
	var at = Vector3.ZERO
	for it in Interact.items:
		if (String(it.get("room", "")) == site or String(it.get("kind", "")) == site) and not it.get("interior", false) and it["pos"].distance_to(Vector3(-500, 8, 750)) < 1600.0:
			at = it["pos"]
	print("AS door=", at)
	main.player.respawn(at + Vector3(0, 1, 8))
	await get_tree().create_timer(3.0).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 55.0
	var k = 0
	var far = float(OS.get_environment("FAR")) if OS.get_environment("FAR") != "" else 1.0
	for v in [[Vector3(0, 14, 75), Vector3(0, 14, -17)], [Vector3(-70, 30, 60), Vector3(0, 12, -17)], [Vector3(75, 45, 50), Vector3(0, 12, -17)], [Vector3(10, 4, 22), Vector3(10, 16, -17)], [Vector3(0, 90, 30), Vector3(0, 0, -15)], [Vector3(-30, 28, -85), Vector3(0, 12, -17)]]:
		cc.global_position = at + v[0] * far
		cc.look_at(at + v[1] * Vector3(1, far, far))
		cc.current = true
		await get_tree().create_timer(0.4).timeout
		await main.shot("%s_%d" % [site, k])
		k += 1
	get_tree().quit()
