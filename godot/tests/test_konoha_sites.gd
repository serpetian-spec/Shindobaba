extends Node
## Konoha'nın önemli yerleri: her mekân türünden bir tane, 2 açıdan (KS=tür,tür ile süz)
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "village": "konoha", "element": "katon", "hair_style": "diken", "hair": Color(0.85, 0.3, 0.12), "top": Color(0.9, 0.45, 0.12), "eye": Color(0.2, 0.4, 0.9), "skin": Color(0.96, 0.8, 0.66)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	Hud.show_game_hud(false)
	main.world.env.time_of_day = 0.42
	var only = OS.get_environment("KS").split(",", false)
	var seen = {}
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.fov = 55.0
	var lst = []
	for s in WorldDay.vl.sites.get("konoha", []):
		lst.append([String(s["type"]), s["pos"]])
	for it in Interact.items:
		if it.has("room") and not it.get("interior", false) and it["pos"].distance_to(Vector3(-500, 8, 750)) < 1600.0:
			lst.append(["door_" + String(it["room"]), it["pos"]])
	for e in lst:
		var ty: String = e[0]
		if seen.has(ty) or (not only.is_empty() and not ty in only):
			continue
		seen[ty] = true
		var at: Vector3 = e[1]
		main.player.respawn(at + Vector3(0, 1.0, 6.0))
		await get_tree().create_timer(2.2).timeout
		for k in 2:
			var a = [0.6, 3.6][k]
			cc.global_position = at + Vector3(sin(a) * 34.0, 20.0, cos(a) * 34.0)
			cc.look_at(at + Vector3(0, 3, 0))
			cc.current = true
			await get_tree().create_timer(0.35).timeout
			await main.shot("ks_%s_%d" % [ty, k])
	print("KS types ", seen.keys())
	get_tree().quit()
