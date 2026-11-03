extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500))
	base.y = Game.terrain_height(base.x, base.z)
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup({"gender": "m", "hair_style": "diken", "hair": Color(0.12, 0.08, 0.07), "top_style": "uzun", "band": null, "face": [0, 0, 0]})
	m.global_position = base
	m.play("idle")
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 25
	var fwd = m.global_transform.basis.z
	var c = base + Vector3(0, 1.65, 0)
	cam.global_position = c + fwd * 1.2 + Vector3(0, 0.35, 0)
	cam.look_at(c)
	await get_tree().create_timer(0.8).timeout
	await main.shot("pa_all")
	var i = 0
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var ab: AABB = mi.global_transform * mi.get_aabb()
		if ab.end.y < base.y + 1.4:
			continue
		mi.visible = false
		await get_tree().create_timer(0.1).timeout
		await main.shot("pa_hide_%02d_%s" % [i, mi.name])
		mi.visible = true
		i += 1
	get_tree().quit()
