extends Node
## Bina/çatı/sur görünüm testi.

var main: Node

const SPOTS := [
	# isim, harita x, harita y, yaw, pitch, yükseklik ofseti, kamera mesafesi
	["h1_konoha_sokak", -50, -200, 20.0, -10.0, 0.0, 9.0],
	["h2_konoha_yan", 40, -120, 270.0, -14.0, 0.0, 12.0],
	["h3_konoha_ust", -60, -260, 0.0, -28.0, 40.0, 14.0],
	["h4_konoha_kapi", -50, -455, 180.0, -2.0, 0.0, 10.0],
	["h5_konoha_sur_d", 320, -75, 90.0, -2.0, 0.0, 10.0],
	["h5b_konoha_sur_b", 320, -75, 270.0, -2.0, 0.0, 10.0],
	["h5c_kaya", -50, 180, 0.0, 4.0, 0.0, 10.0],
	["h5d_ic_sur", -50, -300, 200.0, 0.0, 0.0, 8.0],
	["h6_suna", -1822, -1450, 0.0, -10.0, 0.0, 10.0],
	["h7_kiri", 3204, -800, 0.0, -10.0, 0.0, 10.0],
	["h8_kumo", 2261, 1700, 0.0, -10.0, 0.0, 10.0],
]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	Game.world.env.time_of_day = 0.42
	for s in SPOTS:
		var p = Game.from_map(Vector2(s[1], s[2]))
		p.y = Game.ground_height(p.x, p.z) + s[5]
		pl.respawn(p)
		pl.yaw = s[3]
		pl.pitch = s[4]
		pl.cam_dist = s[6]
		Game.world.env.weather_t = 999
		await get_tree().create_timer(2.5).timeout
		await main.shot(s[0])
	get_tree().quit()
