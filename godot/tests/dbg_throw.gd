extends Node
## Yeni aletler: senbon, makibishi alanı, düşman cephanesi; yelpaze dalgası
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var e = Enemy.new()
	e.setup(Enemy.archetype("bandit", 0))
	get_tree().current_scene.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 10.0
	e.set_physics_process(false)
	var hp0 = e.hp
	Game.profile["inventory"]["senbon"] = 10
	Game.profile["inventory"]["makibishi"] = 3
	Game.profile["throw_sel"] = OS.get_environment("TK") if OS.get_environment("TK") != "" else "senbon"
	Game.profile["inventory"]["kunai"] = 10
	pl.combat.throw_tool()
	await get_tree().create_timer(0.6).timeout
	print("TH senbon dmg=%.1f left=%d" % [hp0 - e.hp, Game.profile["inventory"]["senbon"]])
	var hp1 = e.hp
	Projectile.caltrops(pl, e.global_position, 3.0)
	await get_tree().create_timer(1.2).timeout
	print("TH caltrops dmg=%.1f slow=%s" % [hp1 - e.hp, e.has_status("slow")])
	var r = Enemy.new()
	r.setup(Enemy.archetype("kiri", 0))
	print("TH enemy ammo=%d maki=%d" % [r.ammo, r.maki])
	get_tree().quit()
