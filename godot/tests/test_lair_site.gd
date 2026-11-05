extends Node
## İn yeri dev ağaçlı özel ormanlara (Ölüm Ormanı) düşmüyor mu

var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	for l in Game.world_info["landmarks"]:
		if String(l["id"]) in ["forest_death", "nara_forest"]:
			var bad = 0
			for k in 20:
				var c = Game.from_map(Vector2(float(l["x"]) + randf_range(-0.6, 0.6) * float(l["r"]), float(l["y"]) + randf_range(-0.6, 0.6) * float(l["r"])))
				var q = Missions._lair_site(c)
				var m = Game.to_map(q)
				if Vector2(m.x - float(l["x"]), m.y - float(l["y"])).length() < float(l["r"]):
					bad += 1
			print("FOREST %s r=%d inside=%d/20" % [l["id"], int(l["r"]), bad])
	get_tree().quit()
