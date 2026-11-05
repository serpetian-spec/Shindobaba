extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "tsuchigumo", "element": "doton", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.5, 0.4, 0.3)}
	main._start_new_game()
	var pl = main.player
	pl.max_hp = 5000.0
	pl.hp = 5000.0
	await get_tree().create_timer(1.5).timeout
	var a = Enemy.archetype("rogue", 1)
	a["respawn"] = false
	var e = Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 14.0
	e.max_hp = 1e6
	e.hp = 1e6
	e.lose_target(999)
	await get_tree().create_timer(0.5).timeout
	Jutsu.execute(pl, "tsuchigumo_kinjutsu", e)
	await get_tree().create_timer(2.0).timeout
	print("DOH yüksüz: düşman hasar=%d oyuncu can=%d (değişmemeli)" % [1e6 - e.hp, pl.hp])
	Jutsu.execute(pl, "tsuchigumo_tenchi_kaibyaku", null)
	await get_tree().create_timer(4.5).timeout
	print("DOH yük=%s" % pl.has_meta("dohatsuten_until"))
	var hp_b = e.hp
	e.global_position = pl.global_position + pl.face_dir() * 12.0
	Jutsu.execute(pl, "tsuchigumo_kinjutsu", e)
	for k in 12:
		await get_tree().create_timer(0.2).timeout
		print("DOH t=%.1f e.hp=%.0f d=%.1f inv=%s" % [k * 0.2, e.hp, e.global_position.distance_to(pl.global_position), e.get("invuln")])
	print("DOH yüklü: düşman hasar=%d oyuncu can=%d (canın %%30'u bedel)" % [1e6 - e.hp, pl.hp])
	get_tree().quit()
