extends Node
## Bütün silahlar tek tek: kamera her silahın sınır kutusuna oturur (yan + 3/4 açı)
var main: Node


func _aabb(n: Node3D) -> AABB:
	var ab := AABB()
	var first = true
	for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		var m: MeshInstance3D = mi
		if m.mesh == null:
			continue
		var b = m.global_transform * m.mesh.get_aabb()
		ab = b if first else ab.merge(b)
		first = false
	return ab


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	main.world.env.time_of_day = 0.42
	var only = OS.get_environment("WEAP")
	var ids = []
	for k in Gear.ITEMS:
		if Gear.ITEMS[k].get("slot", "") in ["sag", "sol"] and (only == "" or k in only.split(",")):
			ids.append(k)
	var v = Game.village("suna")
	var base = Game.from_map(Vector2(v["x"] + 2600, v["y"] + 2600))
	base.y = Game.terrain_height(base.x, base.z) + 60.0
	var cam = Camera3D.new()
	cam.fov = 35.0
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	for id in ids:
		var holder = Node3D.new()
		main.add_child(holder)
		holder.global_position = base
		var node: Node3D = SFProps.weapon_node(id)
		var src = "model" if node != null else "prosedürel"
		if node == null:
			var mi = MeshInstance3D.new()
			mi.mesh = CharacterModel.weapon_mesh(id)
			node = mi
		holder.add_child(node)
		await get_tree().process_frame
		var ab = _aabb(holder)
		var c = ab.get_center()
		var size = maxf(ab.size.length(), 0.3)
		print("WEAP ", id, " ", src, " size=", ab.size)
		for view in [["yan", Vector3(1, 0.15, 0)], ["34", Vector3(0.7, 0.45, 0.7)]]:
			cam.global_position = c + (view[1] as Vector3).normalized() * size * 1.5
			cam.look_at(c)
			await get_tree().create_timer(0.25).timeout
			await main.shot("w_%s_%s" % [id, view[0]])
		holder.queue_free()
	get_tree().quit()
