extends Node
## Hakkō Chakura Tō: kendi modeli (elde + simge), efsane sürümü de aynı model; tutuş/kombo tantō
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "hatake", "element": "raiton", "hair_style": "diken", "hair": Color(0.85, 0.85, 0.88), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	var uid = Gear.make_unique("hakko_chakura_to", "w", 12345)
	print("HK1 u=%s name=%s visual=%s skin=%s base=%s" % [uid, Gear.item(uid).get("name"), Gear.visual_id(uid), Gear.skin_id(uid), Gear.base_id(uid)])
	print("HK2 plain visual=%s skin=%s tanto_skin=%s" % [Gear.visual_id("hakko_chakura_to"), Gear.skin_id("hakko_chakura_to"), Gear.skin_id("tanto")])
	Game.profile["level"] = 30
	Game.profile["rank"] = 3
	Gear.grant(Game.profile, uid, "sag", null, null, {})
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	await _w(1.5)
	print("HK3 look weapon_r=%s skin=%s" % [str(pl.model.look.get("weapon_r")), str(pl.model.look.get("weapon_skin_r"))])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 35
	cc.near = 0.02
	var fd: Vector3 = pl.face_dir()
	var rt = fd.cross(Vector3.UP)
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	await _w(0.6)
	pl.combat.attack()
	await _w(0.12)
	for w in pl.model.weapons:
		var nd = w["node"]
		var mis = [nd] if nd is MeshInstance3D else nd.find_children("*", "MeshInstance3D", true, false)
		for mi in mis:
			print("HK5 side=%s mesh_aabb=%s same_as_hakko=%s" % [w["side"], str((mi as MeshInstance3D).mesh.get_aabb().size), str((mi as MeshInstance3D).mesh == CharacterModel.weapon_mesh("hakko_chakura_to"))])
	for v in [[rt * 1.6 + fd * 1.2 + Vector3.UP * 1.3, "hakko_hand_a"], [-rt * 1.4 + fd * 1.5 + Vector3.UP * 1.4, "hakko_hand_b"]]:
		cc.global_position = pl.global_position + v[0]
		cc.look_at(pl.global_position + Vector3.UP * 1.1 + fd * 0.3)
		cc.current = true
		await _w(0.05)
		await main.shot(v[1])
		pl.combat.attack()
		await _w(0.1)
	var tex = Thumbs.weapon(uid)
	await _w(0.5)
	if tex:
		tex.get_image().save_png("C:/Users/serpe/AppData/Local/Temp/claude/4d5ab968db883820/cabfca97-efdd-4efc-b158-8fe1363a82d8/scratchpad/hakko_thumb.png")
	print("HK4 thumb=%s" % str(tex != null))
	get_tree().quit()
