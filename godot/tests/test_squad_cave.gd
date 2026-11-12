extends Node
## Genin takımı dövüş geçen iç mekâna (mağara) seninle girer
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["rank"] = 1
	GeninSquad.ensure_formed()
	pr["squad"]["state"] = "active"
	pr["squad"]["on_mission"] = true
	Game.profile["active_mission"] = {"title": "Test", "desc": "t", "type": "story", "rank": "D", "count": 1, "progress": 0}
	var pl = main.player
	var out = pl.global_position + Vector3(900, 0, -2600)
	out.y = Game.terrain_height(out.x, out.z) + 1.0
	pl.respawn(out)
	await get_tree().create_timer(4.0).timeout
	var sq = get_tree().current_scene.find_children("*", "GeninSquad", true, false)[0] if not get_tree().current_scene.find_children("*", "GeninSquad", true, false).is_empty() else null
	var ns = sq.members.map(func(m): return m["node"]).filter(func(n): return n != null and is_instance_valid(n))
	print("SC outside members=", ns.size(), " d=", ns.map(func(n): return int(n.global_position.distance_to(pl.global_position))))
	await Interiors.inst.enter({"pos": out, "out": out, "room": "lair_cave", "kind": "enter"})
	await get_tree().create_timer(4.0).timeout
	ns = sq.members.map(func(m): return m["node"]).filter(func(n): return n != null and is_instance_valid(n))
	print("SC inside=", Interiors.inst.inside, " members=", ns.size(), " d=", ns.map(func(n): return snappedf(n.global_position.distance_to(pl.global_position), 0.1)), " dy=", ns.map(func(n): return snappedf(n.global_position.y - pl.global_position.y, 0.1)))
	await main.shot("sc_cave")
	await Interiors.inst.exit()
	await get_tree().create_timer(4.0).timeout
	ns = sq.members.map(func(m): return m["node"]).filter(func(n): return n != null and is_instance_valid(n))
	print("SC after exit members=", ns.size(), " d=", ns.map(func(n): return int(n.global_position.distance_to(pl.global_position))), " dy=", ns.map(func(n): return snappedf(n.global_position.y - pl.global_position.y, 0.1)))
	get_tree().quit()
