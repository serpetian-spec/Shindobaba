extends Node
## Konoha'daki tüm girilebilir kapılara gir-çık: çıkış noktası kapıya yakın ve yerde mi?
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var seen = {}
	var doors = []
	for it in Interact.items:
		if it.get("kind", "") == "enter" and not seen.has(String(it.get("room", "")) + str(int(it["pos"].x / 50))):
			seen[String(it.get("room", "")) + str(int(it["pos"].x / 50))] = true
			doors.append(it)
	print("DOORS ", doors.size())
	var n = 0
	for it in doors:
		if n >= 40:
			break
		n += 1
		var pl = main.player
		pl.respawn(it["pos"] + Vector3(0, 0.3, 0))
		await get_tree().create_timer(0.6).timeout
		Interiors.inst.enter(it)
		await get_tree().create_timer(1.2).timeout
		Interiors.inst.exit()
		await get_tree().create_timer(1.4).timeout
		var d = Vector2(pl.global_position.x - it["pos"].x, pl.global_position.z - it["pos"].z).length()
		var gy = Game.ground_height(pl.global_position.x, pl.global_position.z)
		var bad = d > 15.0 or pl.global_position.y - gy > 3.0
		print("DOOR %s %s room=%s out=%s dist=%.1f above_ground=%.1f %s" % ["BAD" if bad else "ok", it.get("label", ""), it.get("room", ""), it.get("out", "-"), d, pl.global_position.y - gy, pl.global_position])
	get_tree().quit()
