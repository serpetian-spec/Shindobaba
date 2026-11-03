extends Node
## Dedektörün bulduğu noktalara bakış: PTS="x,z;x,z" (köy yerel), VID
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.2, 0.15, 0.1), "top": Color(0.2, 0.3, 0.5), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village(OS.get_environment("VID") if OS.get_environment("VID") != "" else "konoha")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	Hud.show_game_hud(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	var i = 0
	for s in OS.get_environment("PTS").split(";", false):
		var xy = s.split(",")
		var p = c + Vector3(float(xy[0]), 0, float(xy[1]))
		p.y = Game.terrain_height(p.x, p.z) + 1.0
		pl.respawn(p + Vector3(6, 0, 6))
		await get_tree().create_timer(2.5).timeout
		cam.current = true
		cam.global_position = p + Vector3(5, 2.5, 5)
		cam.look_at(p)
		# çarpışma kutularını görünür yap (yarı saydam kırmızı) — kıyas için ikinci kare
		await get_tree().create_timer(0.3).timeout
		await main.shot("iv_%d_a" % i)
		var dbg = []
		for sb in get_tree().root.find_children("*", "CollisionShape3D", true, false):
			if sb.shape is BoxShape3D and sb.global_position.distance_to(p) < 6.0:
				var m = MeshInstance3D.new()
				var bm = BoxMesh.new(); bm.size = sb.shape.size
				m.mesh = bm
				var mt = StandardMaterial3D.new(); mt.albedo_color = Color(1, 0, 0, 0.45); mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.material_override = mt
				add_child(m)
				m.global_transform = sb.global_transform
				dbg.append(m)
		await get_tree().process_frame
		await main.shot("iv_%d_b" % i)
		for m in dbg:
			m.queue_free()
		i += 1
	get_tree().quit()
