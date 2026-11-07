extends Node
## Konoha binaları: yakına yürüyünce kaybolmamalı — evin 60 / 25 / 10 m uzağından kare + görünür mesh sayımı
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(3.0)
	Hud.close_dialog()
	var pl = main.player
	var rp: Array = Builder.roof_points.get("konoha", [])
	var c = rp[rp.size() / 2]
	var cpos: Vector3 = c if c is Vector3 else Vector3(c[0], c[1], c[2])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for d in [80.0, 40.0, 20.0, 8.0]:
		var p = cpos + Vector3(d, 0, d * 0.3)
		p.y = Game.ground_height(p.x, p.z) + 0.2
		pl.global_position = p
		pl.velocity = Vector3.ZERO
		await _w(1.5)
		cc.global_position = p + Vector3(0, 6, 0)
		cc.look_at(cpos + Vector3.UP * 3.0)
		cc.current = true
		# görünür ve mesafesi içinde olan multimesh/mesh sayısı (cpos'a 30 m)
		var vis = 0
		var hid = 0
		for n in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
			var g: GeometryInstance3D = n
			if not g.is_visible_in_tree():
				continue
			var aabb = g.get_aabb()
			var gc = g.global_transform * aabb.get_center()
			if Vector2(gc.x - cpos.x, gc.z - cpos.z).length() > 30.0 and aabb.size.length() < 200.0:
				continue
			var dist = gc.distance_to(cc.global_position)
			if g.visibility_range_end > 0.0 and (dist > g.visibility_range_end or dist < g.visibility_range_begin):
				hid += 1
			else:
				vis += 1
		if d == 80.0:
			var nm = 0
			var nul = 0
			for n in get_tree().current_scene.find_children("*", "MultiMeshInstance3D", true, false):
				if n.visibility_range_begin == 0.0 and n.multimesh:
					nm += 1
					if n.multimesh.mesh == null or n.multimesh.mesh.get_surface_count() == 0:
						nul += 1
			print("KVIS near_mm=%d empty_mesh=%d" % [nm, nul])
		if d == 20.0:
			var k2 = 0
			for n in get_tree().current_scene.find_children("*", "MultiMeshInstance3D", true, false):
				if n.multimesh == null or n.multimesh.instance_count == 0:
					continue
				var ab: AABB = n.global_transform * n.get_aabb()
				var cd = ab.get_center().distance_to(pl.global_position)
				var pp = pl.global_position
				if ab.grow(20.0).has_point(Vector3(pp.x, ab.get_center().y, pp.z)) and k2 < 14:
					k2 += 1
					print("KMM %s cd=%.0f beg=%.0f end=%.0f vis=%s layers=%d aabb=%s mesh=%s par=%s" % [n.name, cd, n.visibility_range_begin, n.visibility_range_end, n.is_visible_in_tree(), n.layers, str(ab.size), str(n.multimesh.mesh.resource_name if n.multimesh.mesh else "null"), n.get_parent().name])
			var k3 = 0
			for n in get_tree().current_scene.find_children("*", "MultiMeshInstance3D", true, false):
				if n.material_override == Props.roof_toon() and k3 < 6 and String(n.get_path()).to_lower().contains("konoha") and (n.global_transform * n.get_aabb()).get_center().distance_to(pl.global_position) < 250.0:
					k3 += 1
					var ab2: AABB = n.global_transform * n.get_aabb()
					var t0 = n.global_transform * n.multimesh.get_instance_transform(0).origin
					print("KROOF aabbc=%s size=%s inst0=%s pl=%s end=%.0f cnt=%d par=%s" % [str(ab2.get_center()), str(ab2.size), str(t0), str(pl.global_position), n.visibility_range_end, n.multimesh.instance_count, n.get_parent().get_path()])
			var tot = 0
			var paths = {}
			for n in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
				if String(n.get_path()).to_lower().contains("konoha"):
					tot += 1
					var pp2 = String(n.get_parent().get_path())
					paths[pp2] = int(paths.get(pp2, 0)) + 1
			print("KVIS konoha_geo=", tot, " parents=", paths.size())
			var ks = paths.keys()
			for q in ks:
				if int(paths[q]) > 20:
					print("  KPAR ", q, " ", paths[q])
			var mmn = 0
			var near_any = []
			for n in get_tree().current_scene.find_children("*", "MultiMeshInstance3D", true, false):
				if String(n.get_path()).to_lower().contains("konoha") and n.multimesh and n.multimesh.instance_count > 0:
					mmn += 1
					var ab3: AABB = n.global_transform * n.get_aabb()
					if ab3.grow(10.0).has_point(Vector3(pl.global_position.x, ab3.get_center().y, pl.global_position.z)):
						near_any.append("%s end=%.0f beg=%.0f vis=%s" % [n.name, n.visibility_range_end, n.visibility_range_begin, n.visible])
			var best = []
			for n in get_tree().current_scene.find_children("*", "GeometryInstance3D", true, false):
				if n.get_parent().name == "Konoha":
					var ab4: AABB = n.global_transform * n.get_aabb()
					best.append([ab4.get_center().distance_to(cpos), n])
			best.sort_custom(func(a, b): return a[0] < b[0])
			for q in best.slice(0, 10):
				var nn = q[1]
				print("  KCL d=%.0f %s %s beg=%.0f end=%.0f size=%s cnt=%s" % [q[0], nn.get_class(), nn.name, nn.visibility_range_begin, nn.visibility_range_end, str(nn.get_aabb().size), str(nn.multimesh.instance_count) if nn is MultiMeshInstance3D else "-"])
			var zc = 0
			var cnt0 = 0
			var ends = {}
			for n in get_tree().current_scene.find_children("*", "MultiMeshInstance3D", false, false) + get_tree().current_scene.find_child("Konoha", true, false).get_children():
				if n is MultiMeshInstance3D and n.get_parent().name == "Konoha":
					if n.multimesh == null or n.multimesh.instance_count == 0:
						cnt0 += 1
					elif n.get_aabb().size.length() < 0.01:
						zc += 1
					ends[int(n.visibility_range_end)] = int(ends.get(int(n.visibility_range_end), 0)) + 1
			print("KVIS zero_aabb=", zc, " empty=", cnt0, " ends=", ends)
			print("KVIS konoha_mm=", mmn, " covering_player=", near_any.size())
			for q in near_any.slice(0, 15):
				print("  KNEAR ", q)
			print("KVIS view=", Game.settings["view"], " SHELL_NEAR=", HouseKit.SHELL_NEAR)
		print("KVIS d=%d vis=%d range_hidden=%d" % [int(d), vis, hid])
		await main.shot("kvis_%d" % int(d))
	get_tree().quit()
