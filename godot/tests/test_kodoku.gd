extends Node
## Kodoku: iki ceset yakındayken bariyer kurulur, patlar, çevredekiler zehirlenir; cesetsiz reddedilir
var main: Node
func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "aburame", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.1), "top": Color(0.2, 0.3, 0.25), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl: Player = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.5)
	PathJutsu.cast_path(pl, "kodoku_no_jutsu", null)
	print("KODOKU no corpse: (mesaj çıkmalı)")
	var es = []
	for k in 3:
		var e := Enemy.new()
		e.setup(Enemy.archetype("rogue", 1))
		main.actors.add_child(e)
		e.global_position = pl.global_position + Vector3(k * 2.0 - 2.0, 0, -6)
		es.append(e)
	await _w(0.3)
	for k in 2:
		es[k].take_hit({"dmg": 1e9, "knock": 0.0, "kind": "heavy", "attacker": pl})
	await _w(0.6)
	var live_e = es[2]
	live_e.max_hp = 1e6; live_e.hp = 1e6
	live_e.set_physics_process(false)
	var hp0 = live_e.hp
	PathJutsu.cast_path(pl, "kodoku_no_jutsu", null)
	await _w(1.4)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	cc.global_position = pl.global_position + Vector3(9, 6, 4)
	cc.look_at(pl.global_position + Vector3(0, 1, -6))
	cc.current = true
	await main.shot("kodoku_a")
	await _w(2.0)
	await main.shot("kodoku_b")
	await _w(2.0)
	print("KODOKU survivor dmg=%.0f" % [hp0 - live_e.hp])
	get_tree().quit()
