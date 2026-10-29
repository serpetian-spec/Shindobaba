extends Node
## Düşmanın dev yılanı (hükümdar) gövdesine vurulunca hasar alıp ölüyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	var a = Enemy.archetype("rogue", 0)
	a["level"] = 58
	var e = Enemy.new()
	e.setup(a)
	e.set_meta("contract", "yılan")
	e.set_meta("contract_tier", 2)
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -30)
	Contracts.summon(e, {"id": "kuchiyose"})
	await get_tree().create_timer(1.5).timeout
	var sn = null
	for s in get_tree().get_nodes_in_group("summons"):
		if s.owner_f == e:
			sn = s
	print("SNAKE found=%s hp=%.0f radius=%.1f len=%s" % [sn != null, sn.hp if sn else 0.0, sn.radius if sn else 0.0, sn.def.get("len") if sn else 0])
	var hits = 0
	for off in [Vector3(0, 2, 0), Vector3(18, 2, 0), Vector3(-15, 3, 10), Vector3(0, 8, 20)]:
		var got = Combat.hit_sphere(pl, sn.global_position + off, 1.2, {"dmg": 10.0})
		hits += got.size()
	print("SNAKE body_hits=%d/4 hp=%.0f" % [hits, sn.hp])
	for i in 400:
		if not is_instance_valid(sn) or sn.dead:
			break
		Combat.hit_sphere(pl, sn.global_position + Vector3(14, 2, 6), 1.2, {"dmg": 300.0})
	print("SNAKE dead=%s" % [not is_instance_valid(sn) or sn.dead])
	get_tree().quit()
