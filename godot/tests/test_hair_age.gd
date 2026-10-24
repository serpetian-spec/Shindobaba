extends Node
## Saç x yaş: her stilin çocuk/genç/yetişkin halinde kafada durup durmadığı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 300))
	base.y = Game.terrain_height(base.x, base.z)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var styles = CharacterModel.HAIR_STYLES.keys()
	var ages = ["child", "adult"]
	for gi in ["m", "f"]:
		for page in range(0, styles.size(), 6):
			var models = []
			for i in 6:
				if page + i >= styles.size():
					break
				for ai in 2:
					var m = CharacterModel.new()
					main.add_child(m)
					m.setup({"gender": gi, "hair_style": styles[page + i], "hair": Color(0.95, 0.8, 0.25), "age": ages[ai], "band": Color(0.15, 0.22, 0.55)})
					var p = base + Vector3((i - 2.5) * 0.7, 0, ai * 2.2)
					p.y = Game.terrain_height(p.x, p.z)
					m.global_position = p
					m.play("idle")
					models.append(m)
			cam.global_position = base + Vector3(0, 1.9, 4.2)
			cam.look_at(base + Vector3(0, 1.2, 0.0))
			await get_tree().create_timer(1.2).timeout
			await main.shot("ha_%s_%d" % [gi, page])
			for m in models:
				m.queue_free()
			await get_tree().process_frame
	get_tree().quit()
