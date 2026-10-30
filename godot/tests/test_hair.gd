extends Node
## Saç stilleri vitrini
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 300))
	base.y = Game.terrain_height(base.x, base.z)
	var styles = CharacterModel.HAIR_STYLES.keys()
	var cols = [Color(0.95, 0.8, 0.25), Color(0.08, 0.08, 0.1), Color(0.9, 0.55, 0.7), Color(0.3, 0.2, 0.12), Color(0.75, 0.25, 0.15), Color(0.85, 0.85, 0.9), Color(0.2, 0.3, 0.6)]
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	for page in range(int(OS.get_environment("HAIR_P0")) if OS.get_environment("HAIR_P0") != "" else 0, int(ceil(styles.size() / 6.0))):
		var models = []
		for i in 6:
			var k = page * 6 + i
			if k >= styles.size():
				break
			var m = CharacterModel.new()
			main.add_child(m)
			m.setup({"gender": "f" if k % 3 == 2 else "m", "hair_style": styles[k], "hair": cols[k % cols.size()], "top_style": "uzun", "band": null})
			var p = base + Vector3((i - 2.5) * 0.75, 0, 0)
			p.y = Game.terrain_height(p.x, p.z)
			m.global_position = p
			m.rotation.y = PI * 0.15 * (1 if i % 2 == 0 else -1)
			m.play("idle")
			models.append(m)
		cam.global_position = base + Vector3(0, 1.55, -2.6)
		cam.look_at(base + Vector3(0, 1.45, 0))
		await get_tree().create_timer(1.5).timeout
		await main.shot("hs_%d" % page)
		cam.global_position = base + Vector3(0, 1.75, 2.6)
		cam.look_at(base + Vector3(0, 1.45, 0))
		await get_tree().create_timer(0.3).timeout
		await main.shot("hs_%d_arka" % page)
		var m0 = models[0]
		cam.global_position = m0.global_position + Vector3(0.0, 1.62, 0.9)
		cam.look_at(m0.global_position + Vector3(0, 1.5, 0))
		await get_tree().create_timer(0.2).timeout
		await main.shot("hs_%d_yakin" % page)
		for m in models:
			m.queue_free()
	get_tree().quit()
