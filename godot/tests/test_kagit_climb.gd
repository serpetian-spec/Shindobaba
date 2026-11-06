extends Node
## Kâğıt kulesi: zıpla + çift zıpla ile kat kat tepeye çıkılabiliyor mu (gerçek oyuncu fiziği)
var main: Node
func _w(t): await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(1.5)
	Hud.close_dialog()
	var L: Array = LegendPaths.lairs["kagit"]
	var c = Vector3(L[0], 0, -L[1]); c.y = Game.terrain_height(c.x, c.z)
	var pl = main.player
	pl.respawn(c + Vector3(0, 1, 30))
	await _w(6.0)
	var top: Vector3 = LegendPaths.drill_spots["kagit"]["top"][0]
	# kule merkezi: tepe noktasının içeri tarafı (tepe noktası platform kenarında)
	var tower = top
	var face = Vector3(top.x, 0, top.z) - Vector3(c.x, 0, c.z)
	# kulenin dibine, tepe noktasının altına git (kenar yönünde 2 m dışarı)
	var tw: Vector3 = LegendPaths.drill_spots["kagit"]["tower"]
	var out = (top - tw); out.y = 0; out = out.normalized()
	var st = tw + out * 7.0
	pl.global_position = Vector3(st.x, Game.ground_height(st.x, st.z) + 0.5, st.z)
	await _w(1.0)
	var start_y = pl.global_position.y
	var log := []
	for tier in 6:
		var toward = (Vector3(top.x, 0, top.z) - Vector3(pl.global_position.x, 0, pl.global_position.z))
		var into = -out   # kuleye doğru
		var g0 = pl.grounded; var il = pl.input_locked; var ui = Game.ui_open
		pl._jump()
		if tier == 0:
			print("CLIMB dbg grounded=%s input_locked=%.2f ui_open=%s paused=%s vy=%.1f" % [g0, il, ui, Game.paused, pl.velocity.y])
		for f in 18:
			pl.velocity.x = into.x * 4.0; pl.velocity.z = into.z * 4.0
			await get_tree().physics_frame
		pl._jump()
		for f in 60:
			pl.velocity.x = into.x * 4.0; pl.velocity.z = into.z * 4.0
			await get_tree().physics_frame
		await _w(0.4)
		log.append("%.1f" % (pl.global_position.y - start_y))
	print("CLIMB zemin=%.1f tepe=%.1f (+%.1f) kat sonrası yükseklikler: %s  tepeye vardı=%s" % [start_y, top.y, top.y - start_y, ", ".join(log), pl.global_position.y > top.y - 1.0])
	get_tree().quit()
