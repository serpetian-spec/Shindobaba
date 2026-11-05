extends Node
## Her jutsu yere devirmesin: yalnız havaya kaldıran/çok sert iten teknikler
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "aburame", "element": "katon", "hair_style": "diken", "hair": Color(0.15, 0.12, 0.1), "top": Color(0.35, 0.45, 0.38), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl = main.player
	pl.max_hp = 1e9
	pl.hp = 1e9
	await get_tree().create_timer(1.5).timeout
	for jid in ["katon_goukakyuu", "suiton_suikoudan", "raikyu", "kidaichu_mushikui", "fuuton_daitoppa", "kurosuki_ikazuchi_kiba", "sabaku_soso"]:
		var a = Enemy.archetype("rogue", 1)
		a["respawn"] = false
		a["sub"] = 0.0
		var e = Enemy.new()
		e.setup(a)
		main.actors.add_child(e)
		e.global_position = pl.global_position + pl.face_dir() * (2.0 if jid == "kidaichu_mushikui" else 7.0)
		e.max_hp = 1e6
		e.hp = 1e6
		e.skill = 0.0
		e.lose_target(999)
		await get_tree().create_timer(0.3).timeout
		var down = false
		var hit = false
		Jutsu.execute(pl, jid, e)
		for k in 40:
			await get_tree().create_timer(0.1).timeout
			if not is_instance_valid(e):
				break
			if e.hp < 1e6:
				hit = true
			if e.state == "knockdown":
				down = true
		print("KD %s vurdu=%s devirdi=%s" % [jid, hit, down])
		if is_instance_valid(e):
			e.queue_free()
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
