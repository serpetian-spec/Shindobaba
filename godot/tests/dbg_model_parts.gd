extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var a = Enemy.archetype("rogue", 0)
	var e = Enemy.new()
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = main.player.global_position + Vector3(0, 0, 5)
	await get_tree().create_timer(1.0).timeout
	for who in [main.player, e]:
		var n_mi = 0
		var n_sh = 0
		var n_surf = 0
		var n_vis = 0
		var mats = {}
		var big = []
		for mi in who.find_children("*", "MeshInstance3D", true, false):
			if not mi.is_visible_in_tree() or mi.mesh == null:
				continue
			n_mi += 1
			n_surf += mi.mesh.get_surface_count()
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				n_sh += mi.mesh.get_surface_count()
			if mi.visibility_range_end > 0:
				n_vis += 1
			var m = mi.material_override if mi.material_override else mi.get_active_material(0)
			mats[m] = true
			big.append("%s(%d)" % [mi.name, mi.mesh.get_surface_count()])
		var others = who.find_children("*", "GeometryInstance3D", true, false).filter(func(g): return not g is MeshInstance3D and g.is_visible_in_tree())
		print("PARTS %s: meshinst=%d surfaces=%d shadow_surfaces=%d vis_range=%d unique_mats=%d other_geom=%d" % [who.name, n_mi, n_surf, n_sh, n_vis, mats.size(), others.size()])
		print("  ", " ".join(big.slice(0, 80)))
	var types = {}
	var tn = 0
	for n in e.find_children("*", "", true, false):
		tn += 1
		var k = n.get_class()
		if n.get_script():
			k += ":" + String(n.get_script().resource_path.get_file())
		types[k] = int(types.get(k, 0)) + 1
	var arr = []
	for k in types:
		arr.append([types[k], k])
	arr.sort()
	arr.reverse()
	print("NODES total=%d %s" % [tn, str(arr.slice(0, 14))])
	var dl = get_tree().current_scene.find_children("*", "DirectionalLight3D", true, false)
	for l in dl:
		print("LIGHT shadow=%s mode=%d max_dist=%.0f" % [l.shadow_enabled, l.directional_shadow_mode, l.directional_shadow_max_distance])
	get_tree().quit()
