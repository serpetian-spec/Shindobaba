extends Node
## Kara alev teknikleri: Kagutsuchi, Alevli Magatama, Entenka, Tensha Fūin — her biri atılır, uçuş anı çekilir
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
	pl.chakra = 99999.0
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	a["respawn"] = false; a["hp"] = 99999.0
	e.setup(a)
	main.add_child(e)
	var p = pl.global_position + pl.face_dir() * 14.0
	p.y = Game.ground_height(p.x, p.z)
	e.global_position = p
	e.home = p
	e.set_physics_process(false)
	pl.set_process(false)
	for s in [["enton_kagutsuchi", 0.75], ["enton_yasaka_no_magatama", 1.1], ["amaterasu_entenka", 0.6], ["tensha_fuin_amaterasu", 1.2]]:
		var h0 = e.hp
		if s[0] == "tensha_fuin_amaterasu":
			e.global_position = pl.global_position + pl.face_dir() * 30.0
		Jutsu.execute(pl, s[0], e)
		if s[0] == "tensha_fuin_amaterasu":
			await get_tree().create_timer(0.6).timeout
			e.global_position = pl.global_position + pl.face_dir() * 8.0
		await get_tree().create_timer(s[1]).timeout
		pl.cam.global_position = pl.global_position - pl.face_dir() * 6.0 + Vector3.UP * 3.5 + pl.face_dir().cross(Vector3.UP) * 5.0
		pl.cam.look_at((pl.global_position + e.global_position) * 0.5 + Vector3.UP * 1.5)
		await main.shot("enton_" + s[0])
		await get_tree().create_timer(2.5).timeout
		print("ENTON %s dmg=%d black=%s" % [s[0], int(h0 - e.hp), e.has_meta("black_flame")])
		if e.has_meta("black_flame"):
			e.remove_meta("black_flame")
		e.global_position = p
	get_tree().quit()
