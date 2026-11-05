extends Node
## Silah izi bıçağa oturuyor mu (wakizashi, katana, tantō): savuruş ortasında yakın kare
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	await get_tree().create_timer(2.0).timeout
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await get_tree().create_timer(1.5).timeout
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for wid in ["wakizashi", "katana", "tanto"]:
		Gear.grant(Game.profile, wid, "sag")
		Gear.apply_look(Game.profile)
		pl.rebuild_model()
		await get_tree().create_timer(1.0).timeout
		Game.profile["weapon_drawn"] = true
		pl.model.set_drawn(true, false)
		await get_tree().create_timer(0.5).timeout
		for w in pl.model.weapons:
			if w.has("trail") and is_instance_valid(w["trail"]):
				print("TRAIL %s z0=%.2f z1=%.2f blade_end=%.2f" % [w["id"], w["trail"].z0, w["trail"].z1, CharacterModel.weapon_mesh(String(w["id"])).get_aabb().end.z])
		for k in 2:
			pl.combat.attack()
			await get_tree().create_timer(0.14 + k * 0.05).timeout
			for w in pl.model.weapons:
				if k == 0 and w.has("trail") and is_instance_valid(w["trail"]):
					print("TRAIL %s z0=%.2f z1=%.2f blade_end=%.2f" % [w["id"], w["trail"].z0, w["trail"].z1, CharacterModel.weapon_mesh(String(w["id"])).get_aabb().end.z])
			var c = pl.global_position + Vector3.UP * 1.1
			cc.global_position = c + pl.face_dir() * 2.6 + pl.face_dir().cross(Vector3.UP) * 1.2 + Vector3.UP * 0.5
			cc.look_at(c + pl.face_dir() * 0.6)
			cc.current = true
			await get_tree().process_frame
			await main.shot("trail_%s_%d" % [wid, k])
			pl.cam.current = true
			await get_tree().create_timer(0.6).timeout
	# Akimichi kol büyütme + elde silah: silah gizlenmeli, sonra geri gelmeli
	Game.profile["clan"] = "akimichi"
	var wn = null
	for w in pl.model.weapons:
		if String(w.get("side", "")) == "Right":
			wn = w["node"]
	Jutsu.execute(pl, "choharite", null)
	await get_tree().create_timer(0.5).timeout
	var lay_during = (wn.find_children("*", "GeometryInstance3D", true, false) + ([wn] if wn is GeometryInstance3D else [])).map(func(g): return g.layers) if wn else []
	await get_tree().create_timer(1.6).timeout
	var lay_after = (wn.find_children("*", "GeometryInstance3D", true, false) + ([wn] if wn is GeometryInstance3D else [])).map(func(g): return g.layers) if wn else []
	print("AKIWEAPON during=", lay_during, " after=", lay_after)
	get_tree().quit()
