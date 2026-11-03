extends Node
## Silah mesh'lerini düz arka planda yan (blade düzlemi YZ) + üst açıdan yakın çeker. IDS=a,b
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var base = Vector3(0, 3000, 0)
	var ids = OS.get_environment("IDS").split(",", false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.6, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment = e
	main.add_child(env)
	var sun = DirectionalLight3D.new()
	main.add_child(sun)
	sun.rotation_degrees = Vector3(-40, 60, 0)
	for i in ids.size():
		var mi = MeshInstance3D.new()
		mi.mesh = CharacterModel.weapon_mesh(ids[i])
		main.add_child(mi)
		mi.global_position = base
		var ab = mi.mesh.get_aabb()
		print("MESH ", ids[i], " aabb=", ab)
		var c = base + ab.get_center()
		for vw in [["x", Vector3(1, 0, 0), Vector3.UP], ["y", Vector3(0, 1, 0.001), Vector3.RIGHT], ["q", Vector3(1, 0.5, 0.6), Vector3.UP]]:
			cam.size = maxf(ab.size.z, maxf(ab.size.y, ab.size.x)) * 0.62
			cam.global_position = c + (vw[1] as Vector3).normalized() * 5.0
			cam.look_at(c, vw[2])
			await get_tree().process_frame
			await get_tree().process_frame
			await main.shot("ws_%s_%s" % [ids[i], vw[0]])
		mi.queue_free()
	get_tree().quit()
