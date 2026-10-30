extends Node
## Ağaç gövdesi kontrolü: gerçek ağaçların yanında true, açıkta false; open_ground gövdeden kaçar
var main: Node


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "village": "konoha", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.2, 0.2, 0.3), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	await get_tree().create_timer(4.0).timeout
	var veg = Game.world.vegetation
	var far = Game.player.global_position + Vector3(1500, 0, 900)
	var n_in = 0
	var n_moved = 0
	var cnt = 0
	var key = Vector2i(floori(far.x / veg.CH), floori(far.z / veg.CH))
	var h := {}
	veg._generate(key, true, h)
	for tr in h.get("trees", []).slice(0, 20):
		cnt += 1
		if veg.trunk_near(tr[0], tr[2], 0.5):
			n_in += 1
		var q = Missions.open_ground(Vector3(tr[0], 0, tr[2]), 60.0)
		if Vector2(q.x - tr[0], q.z - tr[2]).length() > 0.5:
			n_moved += 1
	print("TRUNK trees=", cnt, " detected=", n_in, " moved_out=", n_moved, " open=", veg.trunk_near(Game.player.global_position.x, Game.player.global_position.z, 0.5))
	get_tree().quit()
