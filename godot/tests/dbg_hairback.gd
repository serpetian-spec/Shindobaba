extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var v = Game.village("konoha")
	var base = Game.from_map(Vector2(v["x"] + 20, v["y"] - 300))
	base.y = Game.terrain_height(base.x, base.z)
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup({"gender": "m", "hair_style": "diken", "hair": Color(0.08, 0.08, 0.1), "top_style": "uzun", "band": null})
	m.global_position = base
	m.play("idle")
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.global_position = base + Vector3(0, 1.62, 0.9)
	cam.look_at(base + Vector3(0, 1.55, 0))
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		print("MI ", mi.name, " ", mi.get_parent().get_parent().get("bone_name") if mi.get_parent().get_parent() is BoneAttachment3D else "-", " surf=", mi.mesh.get_surface_count() if mi.mesh else 0, " aabb=", mi.get_aabb())
	await get_tree().create_timer(1.0).timeout
	await main.shot("hb_all")
	var i = 0
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		mi.visible = false
		await get_tree().create_timer(0.15).timeout
		await main.shot("hb_hide_%02d_%s" % [i, mi.name])
		mi.visible = true
		i += 1
	get_tree().quit()
