extends Node
## Hokage Kayası kabartmaları: köyden uzak + yakın görüntü
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.45
	var v = Game.village("konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	var rock: Dictionary = Game.world_info.get("hokage_rock", {})
	var cn = float(rock.get("y", float(v["y"]) + 1170.0)) - float(v["y"])
	var face_z = c.z - cn
	var gy = Game.terrain_height(c.x, face_z + 200)
	main.player.respawn(Vector3(c.x, gy + 2, face_z + 260))
	await get_tree().create_timer(4.0).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var top = Game.terrain_height(c.x, face_z - 40)
	var views = [[Vector3(c.x, gy + 70, face_z + 420), Vector3(c.x, top - 60, face_z)], [Vector3(c.x + 20, gy + 90, face_z + 170), Vector3(c.x, top - 70, face_z)],
		[Vector3(c.x - 140, gy + 80, face_z + 150), Vector3(c.x - 92, top - 70, face_z)], [Vector3(c.x + 230, gy + 70, face_z + 120), Vector3(c.x + 92, top - 70, face_z)]]
	for k in views.size():
		cc.global_position = views[k][0]
		cc.look_at(views[k][1])
		cc.current = true
		await get_tree().create_timer(0.4).timeout
		await main.shot("rock_%d" % k)
	get_tree().quit()
