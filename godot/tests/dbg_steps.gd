extends Node
## Adım sesi zamanlaması: her döngüde 2 temas (sol+sağ), animasyonla eş
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var m = main.player.model
	main.player.set_physics_process(false)
	for an in ["walk", "jog", "run"]:
		m.play(an, 0.0)
		await get_tree().process_frame
		var prev = m.anim_progress()
		var n = 0
		var hits = []
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 3000:
			await get_tree().process_frame
			if m.footstep_cross(prev):
				n += 1
				hits.append(snappedf(m.anim_progress(), 0.01))
			prev = m.anim_progress()
		var cycles = 3.0 / m.anim.current_animation_length
		print("STEPS ", an, " 3sn: ", n, " adım, ", snappedf(cycles, 0.1), " döngü (beklenen ~", int(cycles * 2), ") fazlar=", hits.slice(0, 6))
	get_tree().quit()
