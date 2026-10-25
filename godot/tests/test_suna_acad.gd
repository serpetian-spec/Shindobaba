extends Node
## Suna akademi yerleşkesi: köye göre konumu ve görünüşü (duvar şeffaflığı)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8), "village": "suna"}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	var vid = "suna"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--village="):
			vid = a.substr(10)
	var v = Game.village(vid)
	var site = BuildVillageStory._site(v)
	var c = Vector2(v["x"], v["y"])
	print("ACAD %s site_d=%.0f r=%.0f" % [vid, site.distance_to(c), float(v["r"])])
	var sp = Game.from_map(site)
	sp.y = Game.terrain_height(sp.x, sp.z)
	pl.respawn(sp + Vector3(20, 0, 30))
	await get_tree().create_timer(5.0).timeout
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.far = 3000
	cam.current = true
	for s in [["near", Vector3(30, 12, 40)], ["far", Vector3(140, 90, 200)]]:
		cam.global_position = sp + s[1]
		cam.look_at(sp + Vector3(0, 5, 0))
		await get_tree().create_timer(0.5).timeout
		await main.shot("acad_%s_%s_%s" % [vid, s[0], OS.get_environment("VER")])
	get_tree().quit()
