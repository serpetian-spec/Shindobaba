extends Node
## Sharingan/Mangekyō ayrımı: V -> 3 tomoe Sharingan (Mangekyō görünmez, körlük birikmez), tekrar V -> Mangekyō (körlük birikir),
## tekrar V -> kapanır. Mangekyō tarz jutsusu Mangekyō kapalıyken atılamaz. Düşman da önce Sharingan, kullanınca Mangekyō.
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _eye_param(m) -> String:
	var fm = m.get("face_skin_mat")
	var out = []
	for mt in [m.get("eye_mat"), fm]:
		if mt is ShaderMaterial:
			out.append("doj=%s tomoe=%s" % [str(mt.get_shader_parameter("dojutsu")), str(mt.get_shader_parameter("tomoe"))])
	return ",".join(out)

func _face_shot(pl, nm: String) -> void:
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var sk: Skeleton3D = pl.model.skel
	var hb = sk.find_bone("Head")
	var head: Vector3 = (sk.global_transform * sk.get_bone_global_pose(hb)).origin
	var f: Vector3 = pl.face_dir()
	var ep = head + Vector3.UP * 0.07 + f * 0.08
	cc.fov = 30.0
	cc.near = 0.01
	cc.global_position = ep + f * 0.55
	cc.look_at(ep)
	cc.current = true
	await _w(0.2)
	await main.shot(nm)
	pl.cam.current = true
	cc.queue_free()

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	var pl = main.player
	Hud.close_dialog()
	Gear.grant(Game.profile, "goz_mangekyo", "sag_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.grant(Game.profile, "goz_mangekyo", "sol_goz", null, null, {"lvl": 3, "origin": "dogustan"})
	Gear.apply_look(Game.profile)
	SpecialSlots.refresh(Game.profile)
	var ey: Eyes = pl.combat.modes.eyes
	Game.profile["ms_blind"] = 0.0
	ey.toggle()
	await _w(1.5)
	print("MS1 active=%s ms_on=%s kind_sag=%d raw=%d eye=%s" % [ey.active, ey.ms_on, ey._kind("sag"), ey._raw_kind("sag"), _eye_param(pl.model)])
	await _w(3.0)
	await _face_shot(pl, "ms_eye_shar")
	print("MS2 blind_after_3s_sharingan=%.5f" % ey.blind())
	# Mangekyō jutsusu kapalıyken
	var mj = ""
	for st in Eyes.MS_STYLES.values():
		for jj in st["jutsu"]:
			if Data.jutsu.has(jj):
				mj = jj
				break
		if mj != "":
			break
	Progress.learn(mj)
	var ch0 = pl.chakra
	pl.chakra = pl.max_chakra
	pl.combat.begin_cast(mj) if pl.combat.has_method("begin_cast") else null
	await _w(0.2)
	print("MS3 jutsu=%s cast_while_closed: chakra_used=%s" % [mj, str(pl.chakra < pl.max_chakra - 1.0)])
	# V tekrar: Mangekyō
	var ev = InputEventAction.new(); ev.action = "dojutsu"; ev.pressed = true
	ey.handle_input(ev)
	var ev2 = InputEventAction.new(); ev2.action = "dojutsu"; ev2.pressed = false
	await _w(0.1)
	ey.handle_input(ev2)
	await _w(1.5)
	print("MS4 active=%s ms_on=%s kind_sag=%d eye=%s" % [ey.active, ey.ms_on, ey._kind("sag"), _eye_param(pl.model)])
	await _face_shot(pl, "ms_eye_ms")
	var b0 = ey.blind()
	await _w(4.0)
	print("MS5 blind_gain_4s_ms=%.5f" % (ey.blind() - b0))
	ey.handle_input(ev)
	await _w(0.1)
	ey.handle_input(ev2)
	await _w(0.5)
	print("MS6 after_third_V active=%s ms_on=%s" % [ey.active, ey.ms_on])
	# düşman
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 3))
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -20)
	Eyes.give_enemy_eyes(e, 4, 3)
	await _w(0.3)
	print("MS7 enemy_eye_before=%s" % _eye_param(e.model))
	EnemyArts.ms_open(e)
	print("MS8 enemy_eye_after=%s ms_open=%s" % [_eye_param(e.model), str(e.get_meta("ms_open", false))])
	get_tree().quit()
