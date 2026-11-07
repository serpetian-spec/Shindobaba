extends Node
## Hōzuki: düşman Suika no Jutsu (oyuncuyla aynı kural) + kendiliğinden sıvılaşmada beden suya döner
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var a = Enemy.archetype("rogue", 3)
	a["clan"] = "hozuki"; a["respawn"] = false
	var e := Enemy.new()
	e.setup(a)
	main.actors.add_child(e)
	e.global_position = pl.global_position + pl.face_dir() * 3.0
	e.set_physics_process(false)
	await _w(0.5)
	e.set_meta("su", 0.0)   # kendiliğinden sulaşma kapalı: yalnız Suika no Jutsu ölçülsün
	Jutsu.j_suika(e, null)
	await _w(0.3)
	for t in [["light", ""], ["heavy", ""], ["light", "raiton"]]:
		var hp0 = e.hp
		e.take_hit({"attacker": pl, "dmg": 20.0, "kind": t[0], "element": t[1], "melee": true})
		await _w(0.2)
		print("SP1 suika %s %s -> dmg=%.1f stun=%s" % [t[0], t[1], hp0 - e.hp, str(e.has_status("stun"))])
	e.remove_meta("suika_until")
	e.set_meta("su", 100.0)
	await _w(15.5)   # Suika görünüşü bitsin
	var hp1 = e.hp
	e.take_hit({"attacker": pl, "dmg": 20.0, "kind": "light", "element": "", "melee": true})
	await _w(0.15)
	var ov = 0
	for mi in e.model.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).material_overlay != null:
			ov += 1
	print("SP2 auto dmg=%.1f su=%.0f overlay_meshes=%d" % [hp1 - e.hp, float(e.get_meta("su")), ov])
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = e.global_position + Vector3(0, 1.4, 0) + (pl.global_position - e.global_position).normalized() * 2.2
	cc.look_at(e.global_position + Vector3.UP * 1.0)
	cc.current = true
	await _w(0.05)
	await main.shot("suika_auto")
	await _w(0.8)
	ov = 0
	for mi in e.model.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).material_overlay != null:
			ov += 1
	print("SP3 after overlay_meshes=%d" % ov)
	get_tree().quit()
