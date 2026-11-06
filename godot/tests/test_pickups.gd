extends Node
## Toplama eşyaları: sık ormanda ve köyde ağaç/bina içine düşüyor mu (gövde verisi + fizik çakışma)
var main: Node

func _check(tag: String) -> void:
	var space = get_viewport().world_3d.direct_space_state
	var q = PhysicsShapeQueryParameters3D.new()
	var sh = SphereShape3D.new()
	sh.radius = 0.3
	q.shape = sh
	q.collision_mask = 1
	var n = 0; var tree = 0; var phys = 0
	for pk in Missions.step_nodes:
		if not (is_instance_valid(pk) and pk is Pickup):
			continue
		n += 1
		var p: Vector3 = pk.global_position
		if Game.world.vegetation.trunk_near(p.x, p.z, 0.3):
			tree += 1
		q.transform = Transform3D(Basis(), p + Vector3.UP * 0.6)
		var hits = space.intersect_shape(q, 4).filter(func(h): return not (h["collider"] is CharacterBody3D))
		if not hits.is_empty():
			phys += 1
			var c = hits[0]["collider"]
			var so = c.shape_find_owner(int(hits[0]["shape"])) if c.has_method("shape_find_owner") else -1
			var shp = c.shape_owner_get_shape(so, 0) if so >= 0 else null
			var own = c.shape_owner_get_owner(so) if so >= 0 else null
			print("    şekil=%s sahip=%s konum=%s" % [shp.get_class() if shp else "?", own.name if own else "?", str((own as Node3D).global_position.snapped(Vector3.ONE * 0.1)) if own is Node3D else "?"])
			print("  içinde: %s (%s) @%s oyuncuya %.0f m" % [c.name, c.get_class(), str(p.snapped(Vector3.ONE * 0.1)), p.distance_to(Game.player.global_position)])
	var og = Missions.step_nodes.filter(func(x): return is_instance_valid(x) and x.has_meta("og")).size()
	print("PICK %s ikinci_kontrol=%d" % [tag, og])
	print("PICK %s eşya=%d ağaç_içinde=%d bir_şeyin_içinde=%d" % [tag, n, tree, phys])

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	var pl = main.player
	var fd = Game.world_info["landmarks"].filter(func(l): return l["id"] == "forest_death")[0]
	var konoha = Game.village("konoha")
	for place in [["orman", Vector2(fd["x"], fd["y"])], ["köy", Vector2(konoha["x"], konoha["y"] + 60.0)]]:
		var at: Vector2 = place[1]
		pl.respawn(Game.from_map(at) + Vector3(0, 2, 0))
		await get_tree().create_timer(4.0).timeout
		Missions.abandon() if Missions.has_method("abandon") else null
		Missions.accept({"title": "Test Toplama", "rank": "D", "village": "konoha", "type": "quest",
			"steps": [{"kind": "collect", "at": [at.x, at.y], "item": "herb", "n": 20, "spread": 35, "text": "Topla"}]})
		await get_tree().create_timer(2.0).timeout
		_check(place[0])
	get_tree().quit()
