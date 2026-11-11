extends Node
## Ev hayatı: evli + 1 çocuklu kayıtla eve girilir; karşılama, sarılma, sofra, uyku, sitem/özür sahneleri sırayla çekilir.
## HL="arrive,meal,sleep,upset" (hangi bölümler), HV=köy (varsayılan konoha), HG=f (kadın oyuncu)
var main: Node
var cam: Camera3D


func _cam(x: float, y: float, d: float, tx: float, ty: float, td: float) -> void:
	var I = Interiors.inst
	if cam == null or not is_instance_valid(cam):
		cam = Camera3D.new()
		main.add_child(cam)
		cam.fov = 60.0
	cam.global_position = I.L(x, y, d)
	cam.look_at(I.L(tx, ty, td))
	cam.current = true


func _shot(nm: String) -> void:
	await get_tree().create_timer(0.12).timeout
	await main.shot("hl_" + nm)


func _enter(pl) -> bool:
	var door = HomeLife.door_pos()
	print("HOME door=", door, " home=", Progress.home())
	if door == Vector3.INF:
		return false
	pl.respawn(door + Vector3(0, 0.3, 0))
	await get_tree().create_timer(0.8).timeout
	var it = Interact.nearest(pl.global_position)
	print("HOME nearest=", it.get("room", "?"), " label=", it.get("label", ""))
	Interiors.inst.enter(it)
	await get_tree().create_timer(1.3).timeout
	return true


func _ready() -> void:
	await get_tree().process_frame
	var vid = OS.get_environment("HV") if OS.get_environment("HV") != "" else "konoha"
	var parts = (OS.get_environment("HL") if OS.get_environment("HL") != "" else "arrive,meal,sleep").split(",")
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f" if OS.get_environment("HG") == "f" else "m", "clan": "none", "village": vid, "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	var pr = Game.profile
	pr["age"] = "adult"
	pl.model.apply_age("adult")
	pr["ryo"] = 5000
	# eş + çocuk
	var fem = String(pr.get("gender", "m")) != "f"
	var lk = ClanWorld.clan_look("", "genin", Progress.home(), fem, "adult")
	var id = Friends._make_friend("Hana" if fem else "Kenta", "", lk, 90, "Eşin")
	var f: Dictionary = Friends.all()[id]
	f["romance"] = "eş"
	f["love"] = 90
	f["job"] = "evde"
	f["job_until"] = Time.get_unix_time_from_system() + 99999.0
	pr["spouse"] = id
	pr["children"] = [{"name": "Mio", "gender": "f", "clans": [], "born": Time.get_unix_time_from_system()}]
	if "upset" in parts:
		pr["home_stage"] = 2
	main.world.env.time_of_day = 0.8
	print("HOME spouse_home=", HomeLife.spouse_home(), " where=", Friends.where(id))
	if not await _enter(pl):
		print("HOME FAIL: kapı yok")
		get_tree().quit()
		return
	var hl = HomeLife.cur
	print("HOME cur=", hl, " sp=", hl.sp if hl else null, " W=", hl.W if hl else 0, " D=", hl.D if hl else 0)
	var W = hl.W
	var D = hl.D
	var tb = D * 0.5 + 0.5
	if "arrive" in parts or "upset" in parts:
		_cam(2.6, 1.9, 0.6, -0.6, 1.0, 3.0)
		await _shot("room0")
		await get_tree().create_timer(1.6).timeout
		await _shot("greet1")
		await get_tree().create_timer(2.6).timeout
		_cam(pl.global_position.x - Interiors.inst.origin.x + 1.6, 1.5, -(pl.global_position.z - Interiors.inst.origin.z) - 0.9, pl.global_position.x - Interiors.inst.origin.x, 1.2, -(pl.global_position.z - Interiors.inst.origin.z) + 0.3)
		await _shot("hug_a")
		await get_tree().create_timer(0.9).timeout
		_cam(pl.global_position.x - Interiors.inst.origin.x - 1.5, 1.6, -(pl.global_position.z - Interiors.inst.origin.z) + 0.4, pl.global_position.x - Interiors.inst.origin.x, 1.2, -(pl.global_position.z - Interiors.inst.origin.z) + 0.3)
		await _shot("hug_b")
		await get_tree().create_timer(4.5).timeout
		print("HOME after greet busy=", hl.busy, " routine=", hl.routine, " upset=", hl.upset)
	if "upset" in parts:
		_cam(1.5, 1.6, 0.8, -W * 0.5 + 1.6, 1.1, 2.6)
		await _shot("sulk")
		print("HOME opts=", HomeLife.spouse_opts(id).map(func(o): return o["label"]))
		hl._apologize()
		await get_tree().create_timer(1.0).timeout
		await _shot("bow")
		await get_tree().create_timer(2.2).timeout
		await _shot("forgive")
		await get_tree().create_timer(2.5).timeout
		print("HOME upset after=", hl.upset, " stage=", pr.get("home_stage"))
	if "routine" in parts:
		for k in ["cook", "tea", "sweep"]:
			hl.routine = k
			hl._resume()
			await get_tree().create_timer(5.5).timeout
			if k == "cook":
				_cam(-W * 0.5 + 2.6, 1.6, 1.6, -W * 0.5 + 0.8, 1.1, 2.9)
			elif k == "tea":
				_cam(-0.6, 1.2, tb - 1.9, 0.7, 0.6, tb)
			else:
				_cam(2.4, 1.8, 0.5, 0.0, 0.9, 2.4)
			await _shot("rt_" + k)
			await get_tree().create_timer(1.2).timeout
			await _shot("rt_" + k + "2")
	if "meal" in parts:
		print("HOME opts=", HomeLife.spouse_opts(id).map(func(o): return o["label"]))
		hl._meal()
		await get_tree().create_timer(5.0).timeout
		_cam(-W * 0.5 + 2.7, 1.7, 1.5, -W * 0.5 + 0.7, 1.1, 2.9)
		await _shot("cook")
		_cam(-2.6, 1.3, tb - 1.6, -0.8, 0.5, tb)
		await _shot("pl_sit")
		await get_tree().create_timer(4.2).timeout
		_cam(-W * 0.5 + 2.7, 1.7, 2.6, -W * 0.5 + 0.7, 1.1, 3.75)
		await _shot("chop")
		await get_tree().create_timer(3.4).timeout
		_cam(2.6, 1.8, 1.2, 0.0, 1.0, 3.6)
		await _shot("carry")
		await get_tree().create_timer(6.5).timeout
		_cam(0.0, 1.5, tb - 2.6, 0.0, 0.5, tb)
		await _shot("table_clap")
		await get_tree().create_timer(2.6).timeout
		await _shot("eat1")
		_cam(-0.3, 0.9, tb - 1.5, 0.9, 0.6, tb)
		await _shot("eat_sp")
		_cam(0.3, 0.9, tb - 1.5, -0.9, 0.6, tb)
		await get_tree().create_timer(0.9).timeout
		await _shot("eat_pl")
		_cam(0.0, 2.6, tb + 0.01, 0.0, 0.3, tb)
		await _shot("eat_top")
		await get_tree().create_timer(12.0).timeout
		_cam(2.4, 1.8, 0.8, 0.0, 0.8, tb)
		await _shot("after_meal")
		print("HOME meal done busy=", hl.busy, " hp=", pl.hp, "/", pl.max_hp, " bond=", f["bond"], " love=", f["love"], " locked=", pl.input_locked, " hold=", pl.scene_hold)
	if "sleep" in parts:
		var w0 := 0.0
		while hl.busy and w0 < 20.0:
			w0 += 0.5
			await get_tree().create_timer(0.5).timeout
		print("HOME on_bed=", HomeLife.on_bed())
		await get_tree().create_timer(3.0).timeout
		_cam(W * 0.5 - 3.6, 2.2, 0.5, W * 0.5 - 2.0, 0.3, 3.0)
		await _shot("lie_walk")
		await get_tree().create_timer(4.5).timeout
		await _shot("lie")
		_cam(W * 0.5 - 1.8, 2.9, 2.2, W * 0.5 - 1.8, 0.2, 3.0)
		await _shot("lie_top")
		for k in hl.kids:
			for bn in ["Hips", "Head", "LeftFoot"]:
				print("HOME kid bone ", bn, " ", hl._bone(k, bn) - Interiors.inst.origin, " sp ", hl._bone(hl.sp, bn) - Interiors.inst.origin)
			for mi in k.find_children("*", "MeshInstance3D", true, false):
				print("HOME kid mesh ", mi.name, " vis=", mi.is_visible_in_tree(), " aabb=", (mi.global_transform * mi.get_aabb()).position - Interiors.inst.origin, " size=", (mi.global_transform * mi.get_aabb()).size, " tr=", mi.transparency, " range=", mi.visibility_range_end, " layers=", mi.layers)
			print("HOME kid model pos=", k.model.position, " scale=", k.model.scale, " rot=", k.model.rotation, " vis=", k.model.visible, " body=", k.model.body_mesh.visible if k.model.body_mesh else null, " kids=", k.model.get_child_count())
			print("HOME kid pos=", k.global_position - Interiors.inst.origin, " vis=", k.visible, " anim=", k.model.current, " phys=", k.is_physics_processing())
		_cam(W * 0.5 - 3.4, 1.4, 0.9, W * 0.5 - 3.35, 0.2, 2.6)
		await _shot("kid")
		for k in hl.kids:
			print("HOME kid model gpos=", k.model.global_position - Interiors.inst.origin, " skel=", k.model.skel.global_position - Interiors.inst.origin, " animpos=", k.model.anim.current_animation_position, " playing=", k.model.anim.is_playing(), " cur=", k.model.anim.current_animation)
			print("HOME sp animpos=", hl.sp.model.anim.current_animation_position, " playing=", hl.sp.model.anim.is_playing(), " cur=", hl.sp.model.anim.current_animation)
			_cam(W * 0.5 - 3.4, 2.4, 0.2, W * 0.5 - 3.35, 0.2, 2.6)
			await _shot("kid_hi")
			k.global_position.y = Interiors.inst.origin.y + 0.9
			await _shot("kid_y09")
			k.global_position.y = Interiors.inst.origin.y + 0.42
		for q in 5:
			await get_tree().create_timer(0.7).timeout
			if not hl.blankets.is_empty():
				break
		await get_tree().create_timer(1.0).timeout
		_cam(W * 0.5 - 4.2, 1.6, 1.0, W * 0.5 - 2.0, 0.3, 3.0)
		await _shot("dark")
		await get_tree().create_timer(4.6).timeout
		await _shot("getup")
		await get_tree().create_timer(2.6).timeout
		await _shot("stretch")
		await get_tree().create_timer(3.5).timeout
		print("HOME sleep done busy=", hl.busy, " tod=", main.world.env.time_of_day, " locked=", pl.input_locked, " hold=", pl.scene_hold)
	get_tree().quit()
