extends Node
## Oyuncu yeni kıyafet parçalarını giyer (Gear.apply_look yolu) + Terzi dükkânı ekranı
var main: Node
const SETS := [
	{"kafa": "kabuto", "yuz": "mempo", "govde": "gi_siyah", "bacak": "kizil_hakama", "ayak": "zirhli_cizme", "zirh": "lake_zirh", "dis": "jinbaori", "kol": "agir_zirh", "sirt": "sashimono"},
	{"kafa": "golge_kapuson", "yuz": "anbu_tilki", "govde": "golge_ust", "bacak": "siyah_pant", "ayak": "siyah_tabi", "zirh": "kok_yelek", "dis": "gece_pelerini", "kol": "uzun_sargi_eldiven", "sirt": "bel_parsomenleri"},
	{"kafa": "col_sarigi", "yuz": "col_pecesi", "govde": "panel_ceket", "bacak": "col_salvari", "ayak": "yuksek_sandal", "zirh": "kayis_kosum", "dis": "panco", "kol": "omuz_zirhi", "sirt": "bel_cantasi"},
	{"kafa": "tengai", "govde": "kesis_ustu", "bacak": "bol_pantolon", "ayak": "zori", "dis": "kesa", "sirt": "tespih"},
]


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(1.0).timeout
	Menus.clear()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var pr = Game.profile
	Gear.ensure(pr)
	var pl = main.player
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 45
	main.world.env.attach_post(cam)
	for k in SETS.size():
		pr["equip"] = {}
		for slot in SETS[k]:
			Gear.grant(pr, SETS[k][slot], slot)
		Gear.apply_look(pr)
		pl.rebuild_model()
		pl.input_locked = 99.0
		await get_tree().create_timer(0.8).timeout
		var p = pl.global_position
		for side in [0, 1]:
			var f = Vector3(sin(pl.model.global_rotation.y), 0, cos(pl.model.global_rotation.y))
			cam.global_position = p + Vector3.UP * 1.1 + f * (3.2 if side == 0 else -3.2)
			cam.look_at(p + Vector3.UP * 0.95)
			await get_tree().create_timer(0.5).timeout
			await main.shot("og_%d_%d" % [k, side])
	pr["rank"] = 6
	pr["ryo"] = 999999
	Hud.gear_shop("Terzi", Gear.SHOP_CLOTHES)
	await get_tree().create_timer(1.0).timeout
	await main.shot("og_dukkan")
	get_tree().quit()
