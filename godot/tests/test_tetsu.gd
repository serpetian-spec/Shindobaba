extends Node
## Demir Ülkesi: şato, generalin yeri, zirve görevi adımlarının yerleri erişilebilir mi (+ çekim)
var main: Node
func _blocked(q: Vector3) -> bool:
	var sq = PhysicsShapeQueryParameters3D.new()
	var sph = SphereShape3D.new()
	sph.radius = 0.4
	sq.shape = sph
	sq.collision_mask = 1
	sq.transform = Transform3D(Basis.IDENTITY, q + Vector3.UP * 1.0)
	return not main.player.get_world_3d().direct_space_state.intersect_shape(sq, 1).is_empty()

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("tetsu")
	var c = Game.from_map(Vector2(v["x"], v["y"]))
	pl.respawn(Missions.open_ground(c + Vector3(0, 0, 140), 40.0))
	await get_tree().create_timer(5.0).timeout
	for it in Interact.items:
		var p: Vector3 = it["pos"]
		if Vector2(p.x - c.x, p.z - c.z).length() < 300.0:
			print("TETSU item %s %s rel=%s blocked=%s" % [it.get("kind", ""), it.get("label", ""), p - c, _blocked(Vector3(p.x, Game.ground_height(p.x, p.z), p.z))])
	print("TETSU center ground=%.1f blocked=%s" % [Game.ground_height(c.x, c.z), _blocked(Vector3(c.x, Game.ground_height(c.x, c.z), c.z))])
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.far = 3000.0
	var hc = c + Vector3(0, Game.ground_height(c.x, c.z + 101.0) - c.y, 101.0)
	cam.global_position = hc + Vector3(28, 22, 48)
	cam.look_at(hc + Vector3(0, 4, 0))
	cam.current = true
	await get_tree().create_timer(0.5).timeout
	await main.shot("tetsu_hall_" + OS.get_environment("VER"))
	# kale kapısından iç mekâna
	var door = null
	for it in Interact.items:
		if String(it.get("room", "")) == "summit":
			door = it
	cam.current = false
	pl.set_process(true)
	pl.respawn(door["pos"] + Vector3(0, 0.3, 0))
	await get_tree().create_timer(0.8).timeout
	Interiors.inst.enter(door)
	await get_tree().create_timer(1.6).timeout
	print("TETSU inside=%s" % Interiors.inst.inside)
	pl.set_process(false)
	var icam = Camera3D.new()
	main.add_child(icam)
	icam.global_position = Interiors.inst.L(-6.0, 5.5, 3.0)
	icam.look_at(Interiors.inst.L(0, 0.8, 13.0))
	icam.current = true
	await get_tree().create_timer(0.4).timeout
	await main.shot("tetsu_inside_" + OS.get_environment("VER"))
	icam.current = false
	pl.set_process(true)
	Interiors.inst.exit()
	await get_tree().create_timer(1.5).timeout
	print("TETSU exit pos rel=%s blocked=%s" % [pl.global_position - c, _blocked(pl.global_position)])
	# zirve görevi: NPC'ler açık zeminde mi
	Kage.start_summit()
	await get_tree().create_timer(0.5).timeout
	var m = Missions.active()
	for st in m.get("steps", []):
		if st.has("at"):
			var q = Missions._w(st["at"])
			q.y = Game.ground_height(q.x, q.z)
			print("SUMMIT step %s rel=%s blocked=%s" % [st["kind"], q - c, _blocked(Missions.open_ground(q, 1.0))])
	get_tree().quit()
