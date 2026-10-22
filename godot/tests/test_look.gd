extends Node
## Renk / kapı / gece görünüm testi (açık hava zorunlu).

var main: Node

const SPOTS := [
	# isim, harita x, harita y, yaw, pitch, yükseklik ofseti, kamera mesafesi, saat
	["l1_konoha_gun", -50, -200, 20.0, -10.0, 0.0, 9.0, 0.42],
	["l2_konoha_ust", -60, -260, 0.0, -24.0, 40.0, 14.0, 0.42],
	["l3_kapi_dis", -50, -560, 0.0, -6.0, 0.0, 22.0, 0.42],
	["l3b_dogu_kapi", 430, -205, 270.0, -6.0, 0.0, 22.0, 0.42],
	["l6b_suna_kapi", -1555, -1290, 260.0, -6.0, 0.0, 24.0, 0.42],
	["l4_kapi_ic", -50, -380, 180.0, -4.0, 0.0, 12.0, 0.42],
	["l5_orman", 400, -700, 30.0, -6.0, 0.0, 6.0, 0.42],
	["l6_suna", -1822, -1450, 0.0, -10.0, 0.0, 10.0, 0.42],
	["l7_col", -1900, -1100, 90.0, -6.0, 0.0, 7.0, 0.42],
	["l8_gece_sokak", -50, -200, 20.0, -10.0, 0.0, 9.0, 0.95],
	["l9_gece_ust", -60, -260, 0.0, -24.0, 40.0, 14.0, 0.02],
	["l10_aksam", -50, -200, 20.0, -10.0, 0.0, 9.0, 0.74],
]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var env = Game.world.env
	var only = OS.get_environment("LOOK_ONLY")
	for s in SPOTS:
		if only != "" and not String(s[0]).begins_with(only):
			continue
		env.time_of_day = s[7]
		env.weather_t = 9999
		env.region_weather = "açık"
		env.overcast = 0.0
		var p = Game.from_map(Vector2(s[1], s[2]))
		p.y = Game.ground_height(p.x, p.z) + s[5]
		pl.respawn(p)
		pl.yaw = s[3]
		pl.pitch = s[4]
		pl.cam_dist = s[6]
		await get_tree().create_timer(2.5).timeout
		env.time_of_day = s[7]
		await main.shot(s[0])
	get_tree().quit()
