extends Node
## Örümcek Kolları: sırttan çıkan 6 kol (önden/arkadan/yandan) + yakındaki düşmana sırayla vuruş
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "tsuchigumo", "element": "doton", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.25, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.visible = false if Hud.has_method("hide") else true
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	Game.profile["level"] = 40
	pl.chakra = 9999.0
	pl.max_chakra = 9999.0
	if not "tsuchigumo_kumo_yoroi" in Game.profile["learned"]:
		Game.profile["learned"].append("tsuchigumo_kumo_yoroi")
	pl.combat.begin_cast("tsuchigumo_kumo_yoroi")
	await get_tree().create_timer(1.6).timeout
	pl.set_process(false)
	pl.set_physics_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	pl.cam.current = false
	main.world.env.attach_post(cam)
	var fwd = pl.face_dir()
	var c = pl.global_position + Vector3(0, 1.2, 0)
	var right = fwd.cross(Vector3.UP)
	for v in [["on", fwd * 1.9], ["arka", -fwd * 1.9], ["yan", right * 1.9 + fwd * 0.4]]:
		cam.global_position = c + v[1] + Vector3(0, 0.25, 0)
		cam.look_at(c)
		await get_tree().create_timer(0.4).timeout
		await main.shot("spider_" + v[0])
	# düşman yaklaştır: kollar sırayla vurmalı
	var e = Enemy.new()
	var a = Enemy.archetype("bandit", 0)
	a["hp"] = 99999.0
	a["respawn"] = false
	e.setup(a)
	main.add_child(e)
	e.global_position = pl.global_position + fwd * 2.4
	e.set_physics_process(false)
	var hp0 = e.hp
	cam.global_position = c + right * 2.6 + fwd * 1.2 + Vector3(0, 0.3, 0)
	cam.look_at(c + fwd * 1.2)
	await get_tree().create_timer(0.45).timeout
	await main.shot("spider_vurus")
	await get_tree().create_timer(1.2).timeout
	print("SPIDER hits dmg=", hp0 - e.hp)
	get_tree().quit()
