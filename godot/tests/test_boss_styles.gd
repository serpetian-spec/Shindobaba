extends Node
## Her boss tarzı: oyuncuya karşı birkaç saniye dövüşür, özel saldırısını kullanır, 2. aşamaya geçer
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
	for st in BossStyles.STYLES.keys():
		var a = Enemy.archetype("rogue", 0)
		a["respawn"] = false
		a["hp"] = 2000.0
		a["level"] = 40
		a["power"] = 2.4
		a["name"] = "Test Boss"
		BossStyles.dress(a, "S", 0, st)
		var e = Enemy.new()
		e.setup(a)
		main.add_child(e)
		var p = pl.global_position + pl.face_dir() * 8.0
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		e.target = pl
		e.state = "chase"
		for q in 4:
			await get_tree().create_timer(1.0).timeout
			print("  t=%d state=%s d=%.1f tgt=%s cd=%.1f hostile=%s plhp=%d" % [q, e.state, e.global_position.distance_to(pl.global_position), e.target == pl, float(e.get_meta("bs_cd", -1)), Combat.hostile(e, pl), int(pl.hp)])
		e.hp = e.max_hp * 0.4
		await get_tree().create_timer(3.0).timeout
		pl.cam.global_position = pl.global_position + Vector3(6, 4, 8)
		pl.cam.look_at(pl.global_position + Vector3.UP)
		await main.shot("boss_%s" % st)
		print("BOSS %s name=%s skill=%.2f phase2=%s plhp_lost=%d" % [st, e.display_name, e.skill, e.get_meta("bs_phase2", false), int(pl.max_hp - pl.hp)])
		pl.hp = pl.max_hp
		for n in get_tree().get_nodes_in_group("fighters"):
			if n != pl and n is Node3D:
				n.queue_free()
		await get_tree().create_timer(0.5).timeout
	get_tree().quit()
