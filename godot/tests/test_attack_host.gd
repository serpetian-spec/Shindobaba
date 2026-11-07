extends Node
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	pl.max_hp = 1e9; pl.hp = 1e9
	var hid = ""
	for id in TailedBeasts.LAIRS:
		if not TailedBeasts.host_of(id).is_empty() and not TailedBeasts.host_of(id).get("rogue", false):
			hid = id
			break
	print("HOST id=%s host=%s" % [hid, str(TailedBeasts.host_of(hid)).left(80)])
	if hid == "":
		get_tree().quit()
		return
	var vg = Villager.new()
	vg.role = "spar"
	vg.look_extra = {"gender": "m", "age": "adult"}
	get_tree().current_scene.add_child(vg)
	vg.global_position = pl.global_position + Vector3(0, 0, 6)
	vg.set_meta("jinchuriki_of", hid)
	await _w(0.5)
	TailedBeasts.attack_host(vg)
	await _w(0.5)
	var e = get_tree().get_nodes_in_group("fighters").filter(func(f): return f is Enemy and f.has_meta("host_beast"))
	print("HOST enemy=%d hp=%.0f beast=%s" % [e.size(), e[0].max_hp if e.size() > 0 else -1.0, e[0].arch.get("beast", "") if e.size() > 0 else ""])
	if e.size() > 0:
		e[0].take_hit({"dmg": 1e9, "attacker": pl, "kind": "heavy"})
		await _w(4.0)
		var b = TailedBeasts.beasts().get(hid, {})
		print("HOST after kill: state=%s spawned=%s" % [b.get("state", "?"), TailedBeasts.spawned.has(hid) and is_instance_valid(TailedBeasts.spawned[hid])])
	get_tree().quit()
