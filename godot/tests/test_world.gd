extends Node
## Açık dünya görünüm testi: farklı bölgelerden ekran görüntüsü.

var main: Node

const SPOTS := [
	# isim, harita x, harita y, yaw, pitch, yükseklik ofseti, kamera mesafesi
	["w1_ates_ormani", 400, -700, 30.0, -6.0, 0.0, 6.0],
	["w2_ates_tepe", 300, -400, 200.0, -12.0, 40.0, 10.0],
	["w3_sonun_vadisi", 120, 470, 0.0, 6.0, 3.0, 9.0],
	["w9_konoha_sokak", -50, -195, 0.0, -8.0, 0.0, 6.0],
	["w10_cocuk", -50, -190, 150.0, -4.0, 0.0, 2.8],
	["w11_orman_ici", 600, -900, 60.0, 8.0, 0.0, 7.0],
	["w4_ruzgar_colu", -1900, -1100, 90.0, -6.0, 0.0, 7.0],
	["w5_toprak_ulkesi", -1600, 1800, 60.0, -4.0, 0.0, 8.0],
	["w6_yildirim", 2100, 1700, 30.0, 4.0, 0.0, 8.0],
	["w7_su_ulkesi", 3300, -900, 0.0, -4.0, 0.0, 8.0],
	["w8_yagmur", -1100, -150, 270.0, -4.0, 0.0, 7.0],
]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl: Player = main.player
	Game.world.env.time_of_day = 0.4
	for s in SPOTS:
		var p := Game.from_map(Vector2(s[1], s[2]))
		p.y = Game.ground_height(p.x, p.z) + s[5]
		pl.respawn(p)
		pl.yaw = s[3]
		pl.pitch = s[4]
		pl.cam_dist = s[6]
		Game.world.env.weather_t = 999
		await get_tree().create_timer(2.5).timeout
		await main.shot(s[0])
		print(s[0], " fps=", Engine.get_frames_per_second(), " npcs=", get_tree().get_nodes_in_group("talkers").size())
	get_tree().quit()
