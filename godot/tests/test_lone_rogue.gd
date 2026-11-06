extends Node
## Yoldaki kaçak: ateş başında gerçekten oturan biri var mı (görünür, yerinde, birkaç saniye sonra hâlâ orada)
var main: Node

func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.3, 0.2, 0.15), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.3, 0.3), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	Hud.show_game_hud(false)
	Orgs.flags()["rogue"] = true
	var vs = Game.village("konoha")
	var base = Game.from_map(Vector2(vs["x"] + float(vs["r"]) + 500, vs["y"]))
	pl.respawn(base)
	await get_tree().create_timer(1.5).timeout
	Encounters.start("lone_rogue")
	var vg = Encounters.cur.get("rogue")
	for k in 6:
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(vg):
			print("LR t=%d FREED cur=%s" % [k, str(Encounters.cur.keys())])
			break
		print("LR t=%d pos=%s vis=%s in_tree=%s dist=%.1f model=%s" % [k, str(vg.global_position), str(vg.is_visible_in_tree()), str(vg.is_inside_tree()), vg.global_position.distance_to(pl.global_position), str(vg.get("model") != null)])
	if is_instance_valid(vg):
		pl.global_position = vg.global_position + Vector3(-3, 0.5, 3)
		await get_tree().create_timer(3.0).timeout
		print("LR near valid=%s vis=%s pos=%s" % [str(is_instance_valid(vg)), str(is_instance_valid(vg) and vg.is_visible_in_tree()), str(vg.global_position) if is_instance_valid(vg) else "-"])
	if is_instance_valid(vg):
		var cc = Camera3D.new()
		get_tree().current_scene.add_child(cc)
		cc.global_position = vg.global_position + Vector3(1.0, 1.8, 4.5)
		cc.look_at(vg.global_position + Vector3.UP)
		cc.current = true
		await main.shot("lone_rogue")
	get_tree().quit()
