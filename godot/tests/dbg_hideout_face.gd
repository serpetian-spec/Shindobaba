extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	Game.profile["flags"]["rogue"] = true
	Orgs._ensure_hideout()
	await _w(0.5)
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")) == "rogue_hideout":
			door = it
	main.player.global_position = door["out"] + Vector3(0, 0.5, 0)
	await _w(1.0)
	Interiors.inst.enter(door)
	await _w(3.0)
	var pl = main.player
	for n in Interiors.inst.npcs:
		if not is_instance_valid(n):
			continue
		var fd: Vector3 = n.face_dir()
		var near_it = null
		var bd = 99.0
		for it in Interiors.inst.items:
			var d = (it["pos"] as Vector3).distance_to(n.global_position)
			if d < bd and d > 0.3:
				bd = d
				near_it = it
		var to: Vector3 = ((near_it["orig_pos"] if near_it.has("orig_pos") else near_it["pos"]) - n.global_position) if near_it else Vector3.ZERO
		to.y = 0
		print("NPC %-8s %-18s dot_to_item(%s,%.1fm)=%.2f y_above_floor=%.2f pl_dist=%.1f" % [n.role, n.display_override, String(near_it["kind"]) if near_it else "-", bd, fd.dot(to.normalized()) if to.length() > 0.01 else 0.0, n.global_position.y - Interiors.inst.origin.y, n.global_position.distance_to(pl.global_position)])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var k = 0
	for n in Interiors.inst.npcs:
		if not is_instance_valid(n) or not (k in [0, 1, 2, 7]):
			k += 1
			continue
		var fd: Vector3 = n.face_dir()
		cc.global_position = n.global_position + fd * 3.0 + Vector3.UP * 1.6
		cc.look_at(n.global_position + Vector3.UP * 1.0, Vector3.UP)
		cc.current = true
		await _w(0.15)
		await main.shot("hf_%d" % k)
		k += 1
	get_tree().quit()
