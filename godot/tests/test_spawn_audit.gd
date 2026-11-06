extends Node
## Doğan düşman/hayvanlar ağaç/bina/kaya içinde mi
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var space = get_viewport().world_3d.direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sh = SphereShape3D.new(); sh.radius = 0.3
	q.shape = sh; q.collision_mask = 1
	var fd = Game.world_info["landmarks"].filter(func(l): return l["id"] == "forest_death")[0]
	for place in [["orman", Vector2(fd["x"] + 300, fd["y"])], ["kır", Vector2(Game.village("konoha")["x"] + 700, Game.village("konoha")["y"])]]:
		pl.respawn(Game.from_map(place[1]) + Vector3(0, 2, 0))
		await get_tree().create_timer(20.0).timeout
		var n = 0; var bad = 0
		var all := []
		var st = [get_tree().current_scene]
		while not st.is_empty():
			var nd = st.pop_back()
			if nd is Enemy or (nd.get_parent() and nd.get_parent().get_script() and String(nd.get_parent().get_script().resource_path).ends_with("wildlife.gd") and "kind" in nd):
				all.append(nd)
			for ch in nd.get_children():
				st.append(ch)
		for f in all:
			if f == pl or not is_instance_valid(f) or (f as Node3D).global_position.distance_to(pl.global_position) > 400.0:
				continue
			n += 1
			var p: Vector3 = f.global_position
			var tr = Game.world.vegetation.trunk_near(p.x, p.z, 0.0)
			q.transform = Transform3D(Basis(), p + Vector3.UP * 1.0)
			var hits = space.intersect_shape(q, 4).filter(func(h): return not (h["collider"] is CharacterBody3D) and h["collider"] != f)
			if tr or not hits.is_empty():
				bad += 1
				print("  SPAWN içeride: %s ağaç=%s çakışma=%d" % [f.get("display_name") if f.get("display_name") else f.name, tr, hits.size()])
		print("SPAWN %s varlık=%d içeride=%d" % [place[0], n, bad])
	get_tree().quit()
