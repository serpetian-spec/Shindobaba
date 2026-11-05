extends Node
## Kaçak sığınağı mağara: dışarıda ağız + ateş + kuklalar + kaçaklar, içeride simsar ve kara pazar tezgâhları
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _wait(1.5)
	Hud.close_dialog()
	var pl = main.player
	Game.profile["rank"] = 2
	Orgs.defect()
	await _wait(0.5)
	Hud.close_dialog()
	var hp = Orgs.hideout_pos()
	pl.respawn(hp + Vector3(0, 1, 20))
	await _wait(6.0)
	Orgs._ensure_hideout()
	await _wait(1.0)
	var sp = Orgs.hideout_spawn()
	pl.respawn(sp)
	await _wait(1.5)
	Hud.close_dialog()
	var node = Orgs._hideout_node
	var fz: Vector3 = node.global_transform.basis.z
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = node.global_position + fz * 18.0 + Vector3.UP * 6.0 + node.global_transform.basis.x * 6.0
	cc.look_at(node.global_position + fz * 4.0 + Vector3.UP * 1.5)
	cc.current = true
	await _wait(0.2)
	await main.shot("hideout_out")
	var door = {}
	for it in Interact.items:
		if String(it.get("room", "")) == "rogue_hideout":
			door = it
	print("HID kapı=%s  spawn-ağız mesafe=%.1f" % [not door.is_empty(), sp.distance_to(node.global_position)])
	pl.cam.current = true
	Interiors.inst.enter(door)
	await _wait(2.5)
	print("HID içeride=", Interiors.inst.inside, " tezgâh=", Interact.items.filter(func(x): return String(x.get("kind", "")).begins_with("rogue_")).size())
	var o: Vector3 = Interiors.inst.origin
	cc.global_position = o + Vector3(0, 3.0, -2.0)
	cc.look_at(o + Vector3(0, 1.0, -20))
	cc.current = true
	Hud.close_dialog()
	await _wait(0.3)
	await main.shot("hideout_in")
	cc.global_position = o + Vector3(-6, 2.5, -14.0)
	cc.look_at(o + Vector3(6, 1.0, -9))
	await _wait(0.2)
	await main.shot("hideout_in2")
	get_tree().quit()
