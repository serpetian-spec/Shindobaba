extends Node
## Naka Tapınağı: giriş, ana salon, yedinci tatami (Uchiha/Sharingan şartı), gizli salon, taş tablet okuma katmanları
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(cc: Camera3D, at: Vector3, look: Vector3, name: String) -> void:
	cc.global_position = at
	cc.look_at(look)
	cc.current = true
	await _wait(0.05)
	await main.shot(name)


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken",
		"hair": Color(0.1, 0.1, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pr = Game.profile
	var pl: Player = main.player
	await _wait(1.0)
	Hud.close_dialog()
	var it = {}
	for x in Interact.items:
		if String(x.get("room", "")) == "naka_shrine":
			it = x
	print("NAKA kapı bulundu: ", not it.is_empty(), " toplam=", Interact.items.size(), " naka-ish=", Interact.items.filter(func(x): return "Naka" in String(x.get("label", ""))).map(func(x): return [x.get("kind"), x.get("room")]))
	pl.respawn(it["pos"] + Vector3(0, 0.5, 2))
	await _wait(1.0)
	Interiors.inst.enter(it)
	await _wait(2.5)
	print("NAKA inside=", Interiors.inst.inside)
	var o: Vector3 = Interiors.inst.origin
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	Hud.close_dialog()
	await _shot(cc, o + Vector3(0, 1.7, -1.0), o + Vector3(0, 2.2, -14), "naka_hall")
	await _shot(cc, o + Vector3(5.5, 3.5, -3), o + Vector3(-2, 0.5, -10), "naka_hall2")
	# tatami: Uchiha ama Sharingan yok -> klan kanıyla açılır
	pr["look"]["eye_r"] = null
	pr["look"]["eye_l"] = null
	print("NAKA uchiha seal=", UchihaLife.can_open_seal(pr), " tier=", UchihaLife.tablet_tier(pr))
	var pc = pr["clan"]
	pr["clan"] = "nara"
	print("NAKA nara seal=", UchihaLife.can_open_seal(pr))
	pr["clan"] = pc
	pl.cam.current = true
	Interiors.inst.goto_local(Interiors.NAKA_X, 4.0, 0.0, "Naka Tapınağı — Gizli Toplantı Yeri")
	await _wait(2.0)
	print("NAKA alt salon konum dx=%.1f dy=%.2f inside=%s" % [pl.global_position.x - o.x, pl.global_position.y - o.y, Interiors.inst.inside])
	await _wait(1.0)
	print("NAKA 1sn sonra dx=%.1f dy=%.2f" % [pl.global_position.x - o.x, pl.global_position.y - o.y])
	await _shot(cc, o + Vector3(Interiors.NAKA_X, 1.8, -3.0), o + Vector3(Interiors.NAKA_X, 2.3, -14), "naka_secret")
	await _shot(cc, o + Vector3(Interiors.NAKA_X + 1.5, 2.2, -10.5), o + Vector3(Interiors.NAKA_X, 2.6, -13.4), "naka_tablet")
	pl.cam.current = true
	await main.shot("naka_secret_game")
	for kind in [0, 1, 4, 6]:
		pr["look"]["eye_r"] = null if kind == 0 else {"kind": kind, "lvl": 3}
		print("NAKA göz %d -> katman %d" % [kind, UchihaLife.tablet_tier(pr)])
		UchihaLife.read_tablet(pr)
		await _wait(0.3)
		Hud.close_dialog()
	print("NAKA naka_read=", pr["flags"].get("naka_read"))
	Interiors.inst.goto_local(-2.85, 7.2, 180.0, "Naka Tapınağı")
	await _wait(2.0)
	print("NAKA yukarı dx=%.1f dy=%.2f" % [pl.global_position.x - o.x, pl.global_position.y - o.y])
	get_tree().quit()
