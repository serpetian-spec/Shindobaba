extends Node
## Edo Tensei tabutu: yükselir, kapak öne devrilir, diriltilen çıkar (düşman çağırır: DNA/kurban şartı oyuncuda)
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
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	pl.max_hp = 1e6; pl.hp = 1e6
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 3))
	main.actors.add_child(e)
	e.global_position = pl.global_position + Vector3(0, 0, -14)
	e.set_physics_process(false)
	await _w(0.3)
	e.facing = 0.0
	Jutsu.execute(e, "kuchiyose_edo_tensei", pl)
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	for v in [[0.7, "edo_rise"], [1.3, "edo_open"]]:
		await _w(v[0] if v[1] == "edo_rise" else 0.55)
		var mid = (e.global_position + pl.global_position) * 0.5
		var cf = e.global_position + (pl.global_position - e.global_position).normalized() * 4.0
		cc.global_position = cf + (pl.global_position - e.global_position).normalized() * 4.5 + Vector3(1.2, 1.6, 0)
		cc.look_at(cf + Vector3.UP * 1.4)
		cc.current = true
		await _w(0.05)
		await main.shot(v[1])
	print("EC warriors=%d" % get_tree().current_scene.find_children("*", "EdoWarrior", true, false).size())
	get_tree().quit()
