extends Node
## Katana elde: sakin duruş ve savaş duruşu yakın çekim (önden + yandan)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(1.0).timeout
	var wid = OS.get_environment("WID") if OS.get_environment("WID") != "" else "katana"
	Gear.grant(Game.profile, wid, "sag")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await get_tree().create_timer(4.0).timeout
	Hud.show_game_hud(false)
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.current = true
	cam.fov = 45
	var fw = pl.face_dir()
	var side = fw.cross(Vector3.UP)
	var c0 = pl.global_position + Vector3.UP
	for phase in ["calm", "combat"]:
		if phase == "combat":
			var e = Enemy.new()
			var a = Enemy.archetype("bandit", 0)
			e.setup(a)
			get_tree().current_scene.add_child(e)
			e.global_position = pl.global_position + fw * 6.0
			e.set_physics_process(false)
			pl.combat.lock_target = e
			pl.combat.attack()
			await get_tree().create_timer(2.5).timeout
		await get_tree().create_timer(1.0).timeout
		c0 = pl.global_position + Vector3.UP
		fw = pl.face_dir(); side = fw.cross(Vector3.UP)
		cam.global_position = c0 + fw * 1.4 + side * 1.2 + Vector3.UP * 0.6
		cam.look_at(c0)
		var wn: Node3D = pl.model.weapons[0]["node"]
		var gb = wn.global_transform.basis
		var hb = (wn.get_parent() as Node3D).global_transform.basis.orthonormalized()
		var yawb = Basis(Vector3.UP, atan2(-pl.face_dir().x, -pl.face_dir().z))
		var rel = yawb.inverse() * hb   # el çerçevesi karakterin yönüne göre (karakter -Z'ye bakıyor gibi)
		print("KB %s blade(z)=%s thin(x)=%s face=%s" % [phase, gb.z.normalized(), gb.x.normalized(), pl.face_dir()])
		print("KH %s %s %s %s" % [phase, rel.x, rel.y, rel.z])
		await main.shot("kh_%s_front" % phase)
		cam.global_position = c0 - side * 1.6 + fw * 0.6 + Vector3.UP * 0.1
		cam.look_at(c0)
		await main.shot("kh_%s_side" % phase)
		cam.global_position = c0 - fw * 2.4 + side * 0.5 + Vector3.UP * 0.5
		cam.look_at(c0)
		await main.shot("kh_%s_back" % phase)
	get_tree().quit()
