extends Node
## Ketsuryūgan: Chinoike doğuştan göz alıyor mu, V ile açılıyor mu, yüzde görünüyor mu
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "chinoike", "element": "katon", "village": "kumo", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.5).timeout
	var pl = main.player
	var ey: Eyes = pl.combat.modes.eyes
	var pr = Game.profile
	print("KETSU gear=", pr["gear"].filter(func(g): return String(g["id"]).begins_with("goz")).map(func(g): return g["id"]), " equip=", pr["equip"])
	print("KETSU kinds=", ey._kind("sag"), ey._kind("sol"), " has_eyes=", ey.has_eyes())
	print("KETSU learned eye jutsu=", pr["learned"].filter(func(j): return "ketsu" in String(j) or "eye" in String(j)))
	pl.set_process(false)
	pl.set_physics_process(false)
	pl.cam.current = false
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	main.world.env.attach_post(cam)
	var head = pl.global_position + Vector3(0, 1.45, 0)
	var fwd = Vector3(sin(pl.model.global_rotation.y), 0, cos(pl.model.global_rotation.y))
	cam.global_position = head - fwd * 0.75
	cam.look_at(head)
	await get_tree().create_timer(0.4).timeout
	await main.shot("ketsu_0_kapali")
	ey.toggle()
	print("KETSU active=", ey.active)
	await get_tree().create_timer(1.6).timeout
	pl.cam.current = false
	cam.current = true
	cam.global_position = head - fwd * 0.75
	cam.look_at(head)
	await get_tree().create_timer(0.3).timeout
	await main.shot("ketsu_1_acik")
	get_tree().quit()
