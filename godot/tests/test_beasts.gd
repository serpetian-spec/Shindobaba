extends Node
## Kuyruklu canavar modelleri: her birini oyuncu yanında, boy karşılaştırmalı çeker
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var a = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base = Game.from_map(Vector2(a["x"], a["y"]))
	pl.respawn(base)
	await get_tree().create_timer(3.0).timeout
	pl.set_process(false)
	var ids = ["shukaku", "matatabi", "isobu", "son_goku", "kokuo", "saiken", "chomei", "gyuki", "kurama"]
	for id in ids:
		var r = BeastModels.build(id)
		main.add_child(r)
		var p = base + Vector3(0, 0, -r.height_m * 0.9 - 20.0)
		p.y = Game.terrain_height(p.x, p.z)
		r.global_position = p
		r.rotation.y = PI * 0.85
		await get_tree().create_timer(0.6).timeout
		var h = r.height_m
		pl.cam.global_position = base + Vector3(h * 0.7, h * 0.35, h * 0.3)
		pl.cam.look_at(p + Vector3.UP * h * 0.45)
		await get_tree().create_timer(0.2).timeout
		await main.shot("b_%s" % id)
		r.play_action("roar", 1.2)
		await get_tree().create_timer(0.6).timeout
		pl.cam.global_position = p + Vector3(h * 0.25, h * 0.75, -h * 1.1)
		pl.cam.look_at(p + Vector3.UP * h * 0.6)
		await get_tree().create_timer(0.1).timeout
		await main.shot("b_%s_on" % id)
		r.queue_free()
	get_tree().quit()
