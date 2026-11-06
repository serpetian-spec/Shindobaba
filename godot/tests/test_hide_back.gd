extends Node
## Sırt/bel görünüşünü gizle: model çizmez, statlar kalır
var main: Node

func _shot(tag: String) -> void:
	var pl = main.player
	pl.set_process(false)
	pl.cam.global_position = pl.global_position + pl.model.global_transform.basis.z * -2.6 + Vector3(0, 1.4, 0)   # arkadan (modelin sırtı)
	pl.cam.look_at(pl.global_position + Vector3(0, 1.0, 0))
	await get_tree().create_timer(0.3).timeout
	await main.shot(tag)
	pl.set_process(true)

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(1.5).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	var pr = Game.profile
	var pl = main.player
	Gear.grant(pr, "sirt_sepeti", "sirt")
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.apply_profile_stats()
	pl.facing = PI
	await get_tree().create_timer(2.5).timeout
	print("HIDE göster: back_item=%s maxhp=%.0f stat_hp=%s" % [pr["look"].get("back_item"), pl.max_hp, Gear.stat(pr, "hp")])
	await _shot("hide_goster")
	pr["hide_look"] = {"sirt": true}
	Gear.apply_look(pr)
	pl.rebuild_model()
	pl.apply_profile_stats()
	pl.facing = PI
	await get_tree().create_timer(2.5).timeout
	print("HIDE gizle: back_item=%s maxhp=%.0f stat_hp=%s" % [pr["look"].get("back_item"), pl.max_hp, Gear.stat(pr, "hp")])
	await _shot("hide_gizle")
	Hud.show_game_hud(true)
	main._pause()
	Menus._eq_slot = "sirt"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(0.6, true).timeout
	await main.shot("hide_menu")
	get_tree().quit()
