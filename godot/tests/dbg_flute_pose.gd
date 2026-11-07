extends Node
## Mateki çalma duruşu ölçümü: eller ve flüt ağza ne kadar yakın
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "none", "element": "katon", "hair_style": "uzun", "hair": Color(0.85, 0.4, 0.35), "top": Color(0.85, 0.82, 0.75), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	Gear.grant(Game.profile, "mateki", "sag")
	Gear.apply_look(Game.profile)
	pl.rebuild_model()
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.2)
	Game.profile["weapon_drawn"] = true
	pl.model.set_drawn(true, false)
	await _w(0.5)
	pl.combat.attack(); await _w(0.5)
	pl.combat.attack(); await _w(0.5)
	pl.combat.attack()   # adım 3: Onpa (çalma)
	await _w(0.3)
	var sk: Skeleton3D = pl.model.skel
	var g = func(b): return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(b)).origin
	var head: Vector3 = g.call("Head")
	var inv = pl.model.global_transform.affine_inverse()
	var mouth = head + Vector3(0, 0.0, 0) 
	print("FP head=%s R=%s L=%s" % [str(inv * head), str(inv * g.call("RightHand")), str(inv * g.call("LeftHand"))])
	var n = preload("res://scripts/combat/keyed_combos.gd")._weapon_node(pl)
	if n:
		print("FP grip=%s end=%s blowhole=%s" % [str(inv * n.to_global(Vector3.ZERO)), str(inv * n.to_global(Vector3(0, 0, 0.28))), str(inv * n.to_global(Vector3(0, 0, -0.15)))])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 35
	var fd: Vector3 = pl.model.global_transform.basis.z * -1.0
	cc.global_position = head + fd * 1.6 + Vector3.UP * 0.1
	cc.look_at(head + Vector3.DOWN * 0.15)
	cc.current = true
	await _w(0.05)
	await main.shot("flute_pose")
	get_tree().quit()
