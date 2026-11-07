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
	Jutsu.execute(pl, "banbutsu_sozo_no_jutsu", e)
	var cc = Camera3D.new()
	cc.far = 6000.0
	get_tree().current_scene.add_child(cc)
	var rt = fw.cross(Vector3.UP)
	for k in 3:
		await _w([1.0, 0.5, 2.0][k])
		cc.global_position = pl.global_position + rt * 9.0 + fw * 2.0 + Vector3.UP * 3.0
		cc.look_at(pl.global_position + fw * 3.0 + Vector3.UP * 1.3)
		cc.current = true
		await _w(0.05)
		await main.shot("banbutsu_j%d" % k)
	await _w(4.0)
	var sms = get_tree().get_nodes_in_group("summons")
	print("BBJ summons=%d first=%s owner_is_player=%s dmg=%.1f" % [sms.size(), str(sms[0].def.get("name")) if sms.size() > 0 else "-", str(sms.size() > 0 and sms[0].owner_f == pl), hp0 - e.hp])
	get_tree().quit()
