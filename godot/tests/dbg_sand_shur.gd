extends Node
## Kum Shurikeni: kum kollar gerçek kollara bağlı mı, açılış → savuruş → bıçaklar
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "fuuton", "hair_style": "diken", "hair": Color(0.6, 0.15, 0.1), "top": Color(0.35, 0.3, 0.3), "pants": Color(0.2, 0.18, 0.18), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.3, 0.6, 0.4)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var v = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(v["x"], v["y"] + float(v["r"]) + 500)))
	await get_tree().create_timer(2.0).timeout
	Hud.show_game_hud(false)
	pl.max_chakra = 999.0
	pl.chakra = 999.0
	pl.facing = 0.0
	var cam = Camera3D.new()
	main.add_child(cam)
	cam.fov = 50
	var fw = pl.face_dir()
	var c0 = pl.global_position + Vector3.UP * 1.3
	cam.global_position = c0 - fw * 6.0 + fw.cross(Vector3.UP) * 2.5 + Vector3(0, 0.5, 0)
	cam.look_at(c0)
	cam.current = true
	pl.combat.cooldowns.clear()
	pl.combat.jutsu_gcd = 0.0
	pl.combat.begin_cast("suna_shuriken")
	while pl.combat.action == "cast":
		await get_tree().process_frame
	var gt = 0.0
	var marks = [[0.1, "a_grow"], [0.38, "b_arms"], [0.52, "c_swing"], [0.7, "d_blades"], [1.4, "e_crumble"]]
	for mk in marks:
		while gt < mk[0]:
			pl.set_process(false)
			await get_tree().process_frame
			gt += get_process_delta_time()
		var ca = pl.get_node_or_null("CastAnim")
		var sk = pl.model.skel
		var ua = sk.get_bone_global_pose(sk.find_bone("LeftUpperArm")).origin
		var la = sk.get_bone_global_pose(sk.find_bone("LeftLowerArm")).origin
		print("SANDARM %s dir=%s time_scale=%.2f" % [mk[1], (la - ua).normalized(), Engine.time_scale])
		print("SAND %s castanim=%s style=%s t=%s w=%s arms=%s" % [mk[1], ca != null, ca.style if ca else "", ca.t if ca else 0.0, pl.model.overlay.weights.get("cast"), (pl.model.overlay.cast_pose.get("arms", []) as Array).size()])
		await main.shot("sand_%s" % mk[1])
	# yan görünüş: kollar kemiğe bağlı mı (savuruşta kolla beraber)
	get_tree().quit()
