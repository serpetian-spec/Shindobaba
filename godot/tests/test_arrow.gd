extends Node
## Hedef oku testi: ilk hikâye adımı (Akademi), kamerayı döndürünce ok yönü, dünya ışık sütunu.
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	await get_tree().create_timer(2.0).timeout
	Hud.close_dialog()
	var tp: Vector3 = Missions.target_marker
	print("hedef: ", Missions.has_marker, " ", Missions.target_name, " ", tp, " oyuncu ", pl.global_position)
	# kamerayı hedefe çevir: ok yukarı bakmalı
	var to = tp - pl.global_position
	var face_yaw = rad_to_deg(atan2(-to.x, -to.z))
	for i in 4:
		pl.yaw = face_yaw + i * 90.0
		pl.pitch = -8.0
		await get_tree().create_timer(0.8).timeout
		pl.yaw = face_yaw + i * 90.0
		await get_tree().process_frame
		await get_tree().process_frame
		print("yaw+%d (yaw=%.1f, face=%.1f) ok yönü: %s  hesap: %s  pos %s" % [i * 90, pl.yaw, face_yaw, str(Hud.compass_dir.normalized()), str(Hud._target_screen_dir(pl, tp).normalized()), str(pl.global_position)])
		await main.shot("a%d_ok_%d" % [i + 1, i * 90])
	for st in 15:
		var t = Missions.story_target_for(st)
		print("adım %d -> %s" % [st, (t["name"] + " " + str(t["pos"])) if not t.is_empty() else "YOK"])
	get_tree().quit()
