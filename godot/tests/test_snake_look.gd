extends Node
## Dev yılan: çöreklenmiş (duruyor) ve sürünürken, yakın çekim
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.set_process(false)
	var d = SummonModels.build("snake_boss", 11.0, 70.0)
	var root: Node3D = d["root"]
	main.add_child(root)
	var p = pl.global_position + Vector3(0, 0, -60)
	p.y = Game.ground_height(p.x, p.z)
	root.global_position = p
	await get_tree().create_timer(1.5).timeout
	for s in [["on", Vector3(-25, 6, -45)], ["yan", Vector3(110, 40, 30)], ["ust", Vector3(20, 140, 60)], ["oyuncu", Vector3(8, 3, 25)]]:
		pl.cam.global_position = p + s[1]
		pl.cam.look_at(p + Vector3(0, 8, 0))
		await get_tree().create_timer(0.2).timeout
		await main.shot("snake_%s" % s[0])
	get_tree().quit()
