extends Node
## C2 ejderini referans açılarından çeker (VER: sürüm etiketi). Çıktı: c2_<VER>_<açı>.png
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pl = main.player
	var a = Game.world_info["landmarks"].filter(func(l): return l.get("id", "") == "arena_earth")[0]
	var base = Game.from_map(Vector2(a["x"], a["y"])) + Vector3(300, 0, 235)
	pl.respawn(base)
	await get_tree().create_timer(3.0).timeout
	Hud.close_dialog()
	main.world.env.time_of_day = 0.45
	pl.set_process(false)
	var ver = OS.get_environment("VER")
	var S = 3.0
	var r = ClayArt.c2_dragon(S)
	main.add_child(r)
	var p = base + Vector3(0, 0, -30.0)
	p.y = Game.terrain_height(p.x, p.z) + 2.6 * S
	r.global_position = p
	pl.global_position = Vector3(p.x + 2.0, Game.terrain_height(p.x + 2.0, p.z - 4.2 * S), p.z - 4.2 * S)   # boy ölçüsü: burnun önünde bir insan
	await get_tree().create_timer(0.6).timeout
	var cc = Camera3D.new()
	main.add_child(cc)
	cc.fov = 50.0
	cc.current = true
	var fwd = Vector3(0, 0, -1)
	var right = Vector3(1, 0, 0)
	var ctr = p - fwd * 1.5 * S
	var hp = p + fwd * 3.5 * S
	var shots = [
		["ref", hp + fwd * 5.0 * S - right * 6.5 * S + Vector3.UP * 5.5 * S, ctr - right * 1.0 * S],          # C2_Dragon: baş tarafından yüksekten
		["front", hp + fwd * 6.0 * S - right * 1.5 * S + Vector3.UP * 0.4 * S, ctr + Vector3.UP * 0.3 * S],   # C2_Guided_Missile: önden alçak
		["side", ctr + right * 13.0 * S + Vector3.UP * 0.5 * S, ctr],
		["top", ctr + Vector3.UP * 14.0 * S + fwd * 0.1, ctr],
		["face", hp + fwd * 2.2 * S - right * 2.2 * S + Vector3.UP * 0.6 * S, hp],
		["back", ctr - fwd * 9.0 * S + right * 5.0 * S + Vector3.UP * 4.0 * S, ctr],
	]
	for s in shots:
		cc.global_position = s[1]
		cc.look_at(s[2])
		await get_tree().create_timer(0.3).timeout
		await main.shot("c2_%s_%s" % [ver, s[0]])
	get_tree().quit()
