extends Node
## Terfi kıyafeti: Chūnin olunca köyün Chūnin seti kuşanılıyor mu (yeni terfi + eski kayıt telafisi), ekran görüntüsü

var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "akimichi", "element": "katon", "hair_style": "diken",
		"hair": Color(0.45, 0.25, 0.15), "top": Color(0.55, 0.15, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	Hud.show_game_hud(false)
	var pr = Game.profile
	var pl: Player = main.player
	var vs = Game.village("suna")
	pl.respawn(Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 400, vs["y"])))
	await _wait(2.0)
	pr["rank"] = 1
	Progress.promote(2)
	await _wait(1.0)
	var g = Gear.equipped(pr, "set")
	print("PROMOTE set=", g.get("id", "YOK"), " flag=", pr["flags"].get("rank_outfit_2", false))
	var cc = Camera3D.new()
	get_tree().current_scene.add_child(cc)
	var c = pl.global_position + Vector3.UP * 1.0
	cc.global_position = c + pl.face_dir() * 3.2 + Vector3.UP * 0.4
	cc.look_at(c)
	cc.current = true
	await _wait(0.2)
	await main.shot("rank_chunin_front")
	cc.global_position = c - pl.face_dir() * 3.2 + Vector3.UP * 0.4
	cc.look_at(c)
	await _wait(0.1)
	await main.shot("rank_chunin_back")
	# eski kayıt: rütbe 2 ama bayrak yok, set başka
	Gear.grant(pr, "set_shinobi", "set")
	pr["flags"].erase("rank_outfit_2")
	Progress.ensure_rank_outfit()
	print("LEGACY set=", Gear.equipped(pr, "set").get("id", "YOK"))
	Progress.ensure_rank_outfit()   # ikinci kez: tekrar giydirmemeli
	Gear.grant(pr, "set_shinobi", "set")
	Progress.ensure_rank_outfit()
	print("AFTER flag set (should stay shinobi)=", Gear.equipped(pr, "set").get("id", "YOK"))
	get_tree().quit()
