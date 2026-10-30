extends Node
## Ense: arkadan yakın plan (birkaç saç stili), deliksiz mi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("suna")
	var base = Game.from_map(Vector2(v["x"] + 2600, v["y"] + 2600))
	base.y = Game.terrain_height(base.x, base.z)
	var cam = Camera3D.new()
	cam.fov = 40.0
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var styles = ["kısa", "atkuyruğu", "topuz", "yuksek_kuyruk", "kazinmis", "diken", "kase", "bagli_uzun"]
	var i = 0
	for st in styles:
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup({"gender": "m" if i % 2 == 0 else "f", "hair_style": st, "hair": Color(0.15, 0.1, 0.08), "top_style": "tisort", "band": null, "age": "teen"})
		m.global_position = base + Vector3((i - 3.5) * 0.9, 0, 0)
		m.play("idle")
		i += 1
	await get_tree().create_timer(1.0).timeout
	for half in [0, 1]:
		var cx = base + Vector3((half * 4 - 1.5 - 0.5) * 0.9 + (0 if half == 0 else 0), 0, 0)
		var center = base + Vector3(((half * 4 + 1.5) - 3.5) * 0.9, 1.45, 0)
		cam.global_position = center + Vector3(0, 0.25, 2.2)
		cam.look_at(center)
		await get_tree().create_timer(0.4).timeout
		await main.shot("nape_%d" % half)
	get_tree().quit()
