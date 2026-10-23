extends Node
## Bir klasördeki GLB/GLTF modelleri ızgarada gösterip ekran görüntüsü alır (varlık değerlendirme).
## Kullanım: --test=res://tests/dbg_contact.gd --shots=<dir> -- (ortam değişkeni CONTACT_DIR, CONTACT_FILTER)
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	Menus.clear()
	var dir = OS.get_environment("CONTACT_DIR")
	var filt = OS.get_environment("CONTACT_FILTER").to_lower()
	var per_page = 20
	var files: Array = []
	for f in DirAccess.get_files_at(dir):
		var lf = f.to_lower()
		if (lf.ends_with(".glb") or lf.ends_with(".gltf")) and (filt == "" or lf.contains(filt)):
			files.append(f)
	files.sort()
	var root = Node3D.new()
	add_child(root)
	var cam = Camera3D.new()
	root.add_child(cam)
	cam.current = true
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.85)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.environment.ambient_light_energy = 0.6
	root.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	root.add_child(sun)
	main.world.visible = false
	var page = 0
	while page * per_page < files.size():
		var holder = Node3D.new()
		root.add_child(holder)
		var labels = []
		for i in per_page:
			var k = page * per_page + i
			if k >= files.size():
				break
			var doc = GLTFDocument.new()
			var st = GLTFState.new()
			if doc.append_from_file(dir.path_join(files[k]), st) != OK:
				continue
			var n: Node3D = doc.generate_scene(st)
			var ab = AABB()
			var first = true
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				var b: AABB = (mi as MeshInstance3D).get_aabb()
				b = mi.transform * b
				var t = mi.get_parent()
				while t != n and t is Node3D:
					b = t.transform * b
					t = t.get_parent()
				ab = b if first else ab.merge(b)
				first = false
			var s = 3.0 / maxf(0.01, maxf(ab.size.x, maxf(ab.size.y, ab.size.z)))
			var cell = Node3D.new()
			holder.add_child(cell)
			cell.add_child(n)
			n.scale = Vector3.ONE * s
			n.position = -ab.get_center() * s + Vector3(0, ab.size.y * s * 0.5, 0)
			cell.position = Vector3((i % 5) * 4.2 - 8.4, -float(i / 5) * 4.6 + 6.0, 0)
			var l = Label3D.new()
			l.text = "%d %s" % [k, files[k].get_basename().left(26)]
			l.font_size = 40
			l.pixel_size = 0.006
			l.position = cell.position + Vector3(0, -0.5, 1.5)
			l.modulate = Color(0, 0, 0)
			holder.add_child(l)
		cam.position = Vector3(0, 1.0, 20.0)
		cam.look_at(Vector3(0, 1.0, 0))
		if files.size() == 1:
			cam.position = Vector3(-8.4 + 3.2, 6.0 + 2.6, 4.2)
			cam.look_at(Vector3(-8.4, 6.0 + 1.3, 0))
		cam.fov = 60
		await get_tree().create_timer(0.6).timeout
		await main.shot("contact_%s_%d" % [filt if filt != "" else "all", page])
		holder.queue_free()
		page += 1
	get_tree().quit()
