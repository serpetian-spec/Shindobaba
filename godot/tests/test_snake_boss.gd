extends Node
## S-rank: yılan çağıran kaçak — dev yılan çağırıyor mu, oyuncuya düşman mı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.5).timeout
	pl.max_hp = 999999.0
	pl.hp = pl.max_hp
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false
	a["hp"] = 5200.0
	a["level"] = 58
	a["power"] = 3.2
	a["name"] = "Kaçak Sannin Adayı Jakotsu"
	BossStyles.dress(a, "S", 0, "kuchiyose")
	var e = Enemy.new()
	e.setup(a)
	e.set_meta("contract", "yılan")
	e.set_meta("contract_tier", 2)
	main.add_child(e)
	var p = pl.global_position + pl.face_dir() * 20.0
	p.y = Game.ground_height(p.x, p.z)
	e.global_position = p
	e.home = p
	e.target = pl
	e.state = "chase"
	await get_tree().create_timer(6.0).timeout
	var sums = get_tree().get_nodes_in_group("summons")
	for s in sums:
		print("SUMMON %s h=%.1f team=%s hostile_to_player=%s" % [s.def.get("name", "?"), s.height, s.team, Combat.hostile(s, pl)])
	print("SUMMONS %d plhp_lost=%d" % [sums.size(), int(pl.max_hp - pl.hp)])
	pl.set_process(false)
	pl.cam.global_position = pl.global_position + Vector3(40, 30, 50)
	pl.cam.look_at(p + Vector3.UP * 8)
	await main.shot("snake_boss")
	get_tree().quit()
