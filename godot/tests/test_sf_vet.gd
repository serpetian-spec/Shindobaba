extends Node
## Sketchfab modellerini oyun içinde inceleme: SF="ad:boy,ad:boy" (boy = metre, en uzun kenar), yanında oyuncu ölçek için.
## Çıktı: --shots dizinine vet_<ad>_0/1.png ve konsola boyut/yükleme süresi.
var main: Node


func _aabb(n: Node3D) -> AABB:
	var ab = AABB(); var first = true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if not mi.is_visible_in_tree():
			continue
		var a = mi.global_transform * mi.get_aabb()
		ab = a if first else ab.merge(a)
		first = false
	return ab


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	main.world.env.region_weather = "açık"
	main.world.env.weather_t = 9999.0
	main.world.env.overcast = 0.0
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	pl.set_process(false)
	pl.set_physics_process(false)
	TailedBeasts.set_process(false)
	var base = pl.global_position + Vector3(1.5, 0, -4)
	var items = OS.get_environment("SF").split(",")
	for it in items:
		var parts = it.split(":")
		var nm = parts[0]
		var target = float(parts[1]) if parts.size() > 1 else 2.0
		var path = "res://assets/sketchfab/%s/%s.glb" % [nm, nm]
		if not ResourceLoader.exists(path):
			print("VET YOK ", nm)
			continue
		var t0 = Time.get_ticks_msec()
		var ps = load(path) as PackedScene
		if ps == null:
			print("VET YÜKLENEMEDİ ", nm)
			continue
		var n: Node3D = ps.instantiate()
		main.add_child(n)
		var p = base + Vector3(target * 0.5, 0, -target * 0.5)
		p.y = Game.terrain_height(p.x, p.z)
		n.global_position = p
		await get_tree().process_frame
		var ab = _aabb(n)
		var longest = maxf(ab.size.x, maxf(ab.size.y, ab.size.z))
		var k = target / maxf(longest, 0.0001)
		n.scale = Vector3.ONE * k
		await get_tree().process_frame
		ab = _aabb(n)
		n.global_position += Vector3(p.x - ab.get_center().x, p.y - ab.position.y, p.z - ab.get_center().z)
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		var anims = []
		if ap:
			anims = Array(ap.get_animation_list())
			if not anims.is_empty():
				ap.play(anims[0])
		var mats = 0
		var tris = 0
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh:
				mats += mi.mesh.get_surface_count()
				for s in mi.mesh.get_surface_count():
					var arr = mi.mesh.surface_get_arrays(s)
					var idx = arr[Mesh.ARRAY_INDEX]
					tris += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
		print("VET ", nm, " orig_size=", ab.size / k, " tris=", tris, " surf=", mats, " anims=", anims.size(), " ", anims.slice(0, 6), " load_ms=", Time.get_ticks_msec() - t0)
		await get_tree().create_timer(0.4).timeout
		var c = p + Vector3(0, target * 0.45, 0)
		var dist = target * float(OS.get_environment("DIST") if OS.get_environment("DIST") != "" else "0.9") + 0.3
		for side in [0, 1]:
			var dir = Vector3(0.35, 0.25, 1).normalized() if side == 0 else Vector3(-0.6, 0.35, -0.8).normalized()
			pl.cam.global_position = c + dir * dist
			pl.cam.look_at(c)
			await get_tree().create_timer(0.25).timeout
			await main.shot("vet_%s_%d" % [nm, side])
		n.queue_free()
		await get_tree().process_frame
	get_tree().quit()
