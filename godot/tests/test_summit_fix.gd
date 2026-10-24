extends Node
## Eski kayıttaki Kage Zirvesi görevi (adımlar kale merkezinde): yükleyince salona taşınıyor mu, pusula nereyi gösteriyor (+ çekim)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	var pl = main.player
	await get_tree().create_timer(2.0).timeout
	var t = Game.village("tetsu")
	var cx = float(t["x"]); var cy = float(t["y"])
	Kage.start_summit()
	var m = Missions.active()
	# eski kayıt taklidi
	m.erase("summit_v2")
	var i = 0
	for st in m["steps"]:
		if st.has("at"):
			st["at"] = [cx - 12 + i * 8, cy + 10] if st["kind"] == "talk" else [cx, cy]
			i += 1
	m["step"] = 0
	Missions._begin_step()
	var c = Game.from_map(Vector2(cx, cy))
	print("FIX marker rel=%s" % [Missions.target_marker - c])
	for st in m["steps"]:
		if st.has("at"):
			print("FIX step %s rel=(%.0f, %.0f)" % [st["kind"], float(st["at"][0]) - cx, float(st["at"][1]) - cy])
	# genel adımına geç: general nerede doğuyor
	m["step"] = 1
	Missions._begin_step()
	await get_tree().create_timer(4.0).timeout
	for id in Missions.npcs:
		var n = Missions.npcs[id]
		if is_instance_valid(n):
			print("FIX npc %s rel=%s" % [id, n.global_position - c])
	pl.respawn(Missions._w([cx, cy - 125.0]))
	await get_tree().create_timer(3.0).timeout
	pl.set_process(false)
	var cam = Camera3D.new()
	main.add_child(cam)
	var hc = Missions._w([cx, cy - 101.0])
	hc.y = Game.ground_height(hc.x, hc.z)
	cam.global_position = hc + Vector3(14, 9, 26)
	cam.look_at(hc + Vector3(0, 2, 0))
	cam.current = true
	Hud.show_game_hud(true)
	await get_tree().create_timer(0.5).timeout
	await main.shot("summit_fix")
	get_tree().quit()
