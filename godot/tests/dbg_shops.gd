extends Node
## Büyük köylerin yerleşkesindeki dükkân binaları (eczane, silahçı, terzi, çay evi) + kapı etkileşimleri
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var cam = Camera3D.new()
	cam.far = 3000.0
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	for vid in ["suna", "kumo"]:
		var v = Game.village(vid)
		var s = BuildVillageStory._site(v)
		var c = Game.from_map(s + Vector2(0, 66))
		c.y = Game.terrain_height(c.x, c.z)
		cam.global_position = Game.from_map(s + Vector2(0, 20))
		cam.global_position.y = c.y + 26.0
		cam.look_at(c + Vector3(0, 4, 0))
		await get_tree().create_timer(2.0).timeout
		await main.shot("shops_" + vid)
		var doors = Interact.items.filter(func(it): return it.get("kind", "") == "enter" and String(it.get("vid", "")) == vid).map(func(it): return it["label"])
		print("SHOPS ", vid, " doors=", doors)
	get_tree().quit()
