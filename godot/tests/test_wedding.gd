extends Node
## Düğün töreni: sevgiliyle tören planlanır, alana gidilir, tören baştan sona oynar; aralıklarla iki açıdan çekilir.
## WV=köy, WC=oyuncu klanı (uchiha -> eş senju: itiraz sahnesi)
var main: Node
var cam: Camera3D
var w


func _cam(x: float, y: float, z: float, tx: float, ty: float, tz: float) -> void:
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 55.0
	cam.global_position = w.P(x, z, y)
	cam.look_at(w.P(tx, tz, ty))
	cam.current = true


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.12).timeout
	await main.shot("wd_" + nm)


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("WV") if OS.get_environment("WV") != "" else "konoha"
	var clan = OS.get_environment("WC") if OS.get_environment("WC") != "" else "none"
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": clan, "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	pl.model.apply_age("adult")
	var pr = Game.profile
	var sc = "senju" if clan == "uchiha" else ""
	var lk = ClanWorld.clan_look(sc, "genin", Progress.home(), true, "adult")
	var id = Friends._make_friend("Hana", sc, lk, 90, "Sevgilin")
	var f: Dictionary = Friends.all()[id]
	f["romance"] = "sevgili"
	f["love"] = 95
	f["family"] = [{"rel": "Babası", "name": "Daichi", "alive": true}, {"rel": "Annesi", "name": "Yuki", "alive": true}]
	main.world.env.time_of_day = 0.45
	print("WED plan=", Wedding.plan(id), " site=", Wedding.site(), " pl=", pl.global_position)
	Hud.close_dialog()
	var s = Wedding.site()
	pl.respawn(s + (pl.global_position - s).normalized() * 40.0 + Vector3.UP)
	await get_tree().create_timer(2.5).timeout
	w = Wedding.cur
	print("WED cur=", w, " guests=", w.guests.size() if w else 0, " objector=", w.objector if w else null)
	if w == null:
		get_tree().quit()
		return
	_cam(8.0, 6.0, 19.0, 0.0, 1.0, -3.0)
	await _shot("site")
	_cam(-5.5, 2.4, 0.0, 0.0, 1.6, -7.0)
	await _shot("stage")
	_cam(0.0, 1.7, 15.5, 0.0, 2.0, 0.0)
	await _shot("gate")
	pl.global_position = w.P(0, 14.0, 0.3)
	var marks = [[4.0, "aisle", [3.6, 2.2, 9.5, 0.0, 1.1, 0.0]], [12.0, "altar_pl", [3.4, 2.4, 0.5, 0.0, 1.4, -5.5]], [7.0, "bride_walk", [-2.0, 1.7, 2.5, 0.0, 1.3, 9.0]],
		[2.0, "bride_side", [5.5, 2.0, 6.0, 0.0, 1.3, 6.5]], [12.0, "both", [0.0, 2.0, 1.5, 0.0, 1.5, -6.0]]]
	if w.objector != null:
		marks.append_array([[7.0, "object1", [4.0, 2.2, -0.5, 0.0, 1.4, 1.5]], [6.0, "object2", [-4.0, 2.6, 5.5, 0.0, 1.4, -4.0]], [9.5, "object3", [4.0, 2.2, 4.5, 0.0, 1.4, -4.0]]])
	marks.append_array([[4.3, "sip_pl", [2.2, 1.9, -2.6, 0.4, 1.6, -4.3]], [3.6, "sip_br", [-2.2, 1.9, -2.6, -0.4, 1.6, -4.3]], [6.5, "vow", [0.0, 1.9, -1.6, 0.0, 1.5, -4.3]],
		[5.2, "bow", [2.6, 1.9, -3.0, 0.0, 1.3, -4.3]], [3.4, "cheer", [0.0, 4.0, 10.0, 0.0, 1.4, -3.0]], [1.6, "hug", [1.8, 1.9, -2.6, 0.0, 1.55, -4.3]], [0.6, "hug2", [-5.5, 2.6, 2.5, 0.0, 1.3, -1.0]]])
	for m in marks:
		await get_tree().create_timer(float(m[0])).timeout
		var a: Array = m[2]
		_cam(a[0], a[1], a[2], a[3], a[4], a[5])
		await _shot(String(m[1]))
	var wt := 0.0
	while not w.done and wt < 60.0:
		wt += 0.5
		await get_tree().create_timer(0.5).timeout
	print("WED pl local=", w._local(pl.global_position), " plat=", w.plat_y, " ply=", pl.global_position.y)
	# tören bitti: oyuncu kendi yürüyerek basamaktan çıkabiliyor mu
	pl.global_position = w.P(0, 0.5, 0.2)
	pl.facing = w.yaw
	for q in 90:
		pl.velocity = (w.P(0, -4.0) - pl.global_position).normalized() * 4.0
		pl.velocity.y = -2.0
		pl.move_and_slide()
		await get_tree().physics_frame
	print("WED climb local=", w._local(pl.global_position), " y-plat=", pl.global_position.y - w.plat_y)
	print("WED done=", w.done, " spouse=", Friends.spouse_id(), " romance=", f["romance"], " pending=", Wedding.pending(), " hold=", pl.scene_hold)
	_cam(6.0, 4.0, 14.0, 0.0, 1.0, 0.0)
	await _shot("after")
	get_tree().quit()
