extends Node
## Oda içinde 16 yöne koş: odadan dışarı düşülebiliyor mu?
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var rooms = {}
	for it in Interact.items:
		if it.get("kind", "") == "enter" and not rooms.has(it.get("room", "")):
			rooms[it.get("room", "")] = it
	var pl = main.player
	for rk in rooms:
		var it = rooms[rk]
		pl.respawn(it["pos"] + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.4).timeout
		Interiors.inst.enter(it)
		await get_tree().create_timer(1.3).timeout
		var start = pl.global_position
		var fell = []
		for k in 16:
			pl.global_position = start
			pl.velocity = Vector3.ZERO
			pl.reset_physics_interpolation()
			var a = TAU * k / 16.0
			var d = Vector3(cos(a), 0, sin(a))
			for f in 90:
				pl.velocity.x = d.x * 14.0; pl.velocity.z = d.z * 14.0
				await get_tree().physics_frame
			if pl.global_position.y < start.y - 3.0:
				fell.append(k)
		print("ROOM %s fell_dirs=%s" % [rk, fell])
		Interiors.inst.exit()
		await get_tree().create_timer(1.3).timeout
	get_tree().quit()
