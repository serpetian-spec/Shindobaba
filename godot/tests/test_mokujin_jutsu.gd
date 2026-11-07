extends Node
## Mateki: Genbu Sōkyoku: üç gerçek Doki belirir, rakibe yürür, sırayla gürz/tırmık/ruh solucanı
var main: Node

func _w(t: float) -> void:
	await get_tree().create_timer(t).timeout

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "f", "clan": "senju", "element": "doton", "hair_style": "uzun", "hair": Color(0.85, 0.4, 0.35), "top": Color(0.85, 0.82, 0.75), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await _w(2.0)
	Hud.close_dialog()
	var pl = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _w(1.0)
	var fw: Vector3 = pl.cam_forward()
	fw.y = 0
	fw = fw.normalized()
	var e := Enemy.new()
	e.setup(Enemy.archetype("rogue", 1))
	main.actors.add_child(e)
	e.global_position = pl.global_position + fw * 20.0
	e.max_hp = 1e9; e.hp = 1e9
	e.set_physics_process(false)
	await _w(0.3)
	var hp0 = e.hp
	Jutsu.execute(pl, "mokuton_mokujin_no_jutsu", e)
	var cc = Camera3D.new()
	cc.far = 4000.0
	get_tree().current_scene.add_child(cc)
	var rt = fw.cross(Vector3.UP)
	for k in 3:
		await _w([1.6, 0.9, 1.0][k])
		cc.global_position = pl.global_position + rt * 120.0 + fw * 10.0 + Vector3.UP * 50.0
		cc.look_at(pl.global_position + Vector3.UP * 40.0)
		cc.current = true
		await _w(0.05)
		await main.shot("mokujin_j%d" % k)
	await _w(4.0)
	print("MJJ dmg=%.1f dokis_left=%d" % [hp0 - e.hp, get_tree().current_scene.find_children("*", "Doki", true, false).size()])
	get_tree().quit()
