extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 120))
	base.y = Game.terrain_height(base.x, base.z)
	var looks = [{"gender": "m", "hair_style": "diken", "hair": Color(0.95, 0.8, 0.25), "band": Color(0.15, 0.22, 0.55), "age": "adult"},
		{"gender": "f", "hair_style": "uzun", "hair": Color(0.9, 0.55, 0.7), "band": Color(0.15, 0.22, 0.55), "age": "teen"},
		{"gender": "m", "hair_style": "kase", "hair": Color(0.08, 0.08, 0.1), "band": Color(0.15, 0.22, 0.55), "age": "child"}]
	var ms = []
	for i in looks.size():
		var m = CharacterModel.new()
		main.add_child(m)
		m.setup(looks[i])
		var p = base + Vector3((i - 1) * 0.55, 0, 0)
		p.y = Game.terrain_height(p.x, p.z)
		m.global_position = p
		m.play("idle")
		ms.append(m)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 32
	main.world.env.attach_post(cam)
	var hp = base + Vector3(0, 1.6, 0)
	cam.global_position = hp + Vector3(0, 0.05, -2.0)
	cam.look_at(hp)
	await get_tree().create_timer(1.2).timeout
	await main.shot("b1_bant")
	cam.global_position = hp + Vector3(0.9, 0.15, -1.6)
	cam.look_at(hp)
	await get_tree().create_timer(0.2).timeout
	await main.shot("b2_bant_yan")
	var a = ms[0].global_position
	cam.global_position = a + Vector3(0, 0.25, -1.2)
	cam.look_at(a + Vector3(0, 0.1, 0))
	await get_tree().create_timer(0.2).timeout
	await main.shot("b3_ayak")
	cam.fov = 50
	cam.global_position = base + Vector3(0, 1.0, -3.6)
	cam.look_at(base + Vector3(0, 0.85, 0))
	await get_tree().create_timer(0.2).timeout
	await main.shot("b4_boy")
	get_tree().quit()
