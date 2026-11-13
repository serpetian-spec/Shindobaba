extends Node
## Klan mahallesi sakinleri aşamalı kurulumla geliyor mu: ilk Konoha klan mahallesine gider, sakin sayısı / modeli tam mı / takılan kare.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().create_timer(12.0).timeout
	Hud.close_dialog()
	var cw = ClanWorld
	var gs: Array = cw._groups.get("konoha", [])
	print("CS mahalle sayisi ", gs.size())
	for gi in mini(2, gs.size()):
		var g = gs[gi]
		var sp: Vector3 = g["spots"][0]
		main.player.global_position = Vector3(sp.x + 12.0, Game.ground_height(sp.x + 12.0, sp.z) + 1.0, sp.z)
		var worst = 0.0
		var cnt = 0
		var last = Time.get_ticks_usec()
		var t0 = last
		while Time.get_ticks_usec() - t0 < 9000000:
			await get_tree().process_frame
			var nw = Time.get_ticks_usec()
			var ms = (nw - last) / 1000.0
			last = nw
			if Time.get_ticks_usec() - t0 > 2500000:
				worst = maxf(worst, ms)
				if ms > 40.0:
					cnt += 1
		var ok = 0
		for r in g["nodes"]:
			if is_instance_valid(r) and r.model != null and r.model.anim != null and r.model.get_parent() == r:
				ok += 1
		print("CS mahalle %s: yuva %d | sakin %d | modeli tam %d | bekleyen %d | en dusuk an %.0f FPS | 40 ms ustu kare %d" % [g["clan"], g["spots"].size(), g["nodes"].size(), ok, int(g.get("pending", 0)), 1000.0 / maxf(worst, 1.0), cnt])
	get_tree().quit()
