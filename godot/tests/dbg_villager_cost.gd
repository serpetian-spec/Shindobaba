extends Node
## Köylünün sahneye giriş maliyeti: add_child süresi (tümü) ve model kurulum aşamaları (PROF). İlk tur soğuk, sonraki ikisi sıcak.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(14.0).timeout
	Hud.close_dialog()
	CharacterModel.PROF = true
	for rnd in 3:
		var sum = 0.0
		var n = 0
		for role in ["walker", "shopper", "patrol", "kid", "vendor", "worker", "sitter", "spar", "walker", "shopper", "customer", "guard"]:
			var vg = Villager.new()
			vg.role = role
			vg.plan_look()
			var tries = 0
			while not CharacterModel.prepare(vg.look) and tries < 200:
				tries += 1
				await get_tree().process_frame
			var t = Time.get_ticks_usec()
			main.add_child(vg)
			var ms = (Time.get_ticks_usec() - t) / 1000.0
			vg.global_position = main.player.global_position + Vector3(randf() * 6.0 - 3.0, 0, -4.0 - randf() * 4.0)
			print("VC r%d %-9s giris %.1f" % [rnd, role, ms])
			sum += ms
			n += 1
			await get_tree().create_timer(0.25).timeout
			vg.queue_free()
		print("VC tur %d ortalama %.1f" % [rnd, sum / n])
	get_tree().quit()
