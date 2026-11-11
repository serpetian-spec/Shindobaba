extends Node
## Düğün sahnesi basamağı: (1) tören yürüyüşü (_go_w) damadı sahneye çıkarıyor mu, (2) oyuncu kendi yürüyerek çıkabiliyor mu
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	pl.model.apply_age("adult")
	var lk = ClanWorld.clan_look("", "genin", Progress.home(), true, "adult")
	var id = Friends._make_friend("Hana", "", lk, 90, "Sevgilin")
	Friends.all()[id]["romance"] = "sevgili"
	Wedding.plan(id)
	Hud.close_dialog()
	var s = Wedding.site()
	pl.respawn(s + Vector3(30, 1, 30))
	await get_tree().create_timer(2.0).timeout
	var w = Wedding.cur
	if w == null:
		print("STEP FAIL: tören alanı kurulmadı")
		get_tree().quit()
		return
	pl.global_position = w.P(0.6, 1.0, 0.3)
	await get_tree().create_timer(0.5).timeout
	pl.input_locked = 20.0
	await w._go_w(pl, w.P(0.6, -4.3), 1.3)
	await get_tree().create_timer(0.5).timeout
	var l1 = w._local(pl.global_position)
	print("STEP scripted local=", l1, " y-plat=", snappedf(pl.global_position.y - w.plat_y, 0.01), " OK=", l1.z < -4.0 and absf(pl.global_position.y - w.plat_y) < 0.12)
	pl.input_locked = 0.0
	await get_tree().create_timer(1.5).timeout
	print("STEP stay y-plat=", snappedf(pl.global_position.y - w.plat_y, 0.01))
	var rp = w.P(0.0, -1.0)
	rp.y = w._floor_y(rp) + 0.05
	pl.global_position = rp
	pl.velocity = Vector3.ZERO
	await get_tree().create_timer(1.2).timeout
	print("STEP ramp rest y-plat=", snappedf(pl.global_position.y - w.plat_y, 0.01), " beklenen=", snappedf(w._floor_y(pl.global_position) - w.plat_y, 0.01), " yer=", snappedf(Game.ground_height(rp.x, rp.z) - w.plat_y, 0.01))
	get_tree().quit()
