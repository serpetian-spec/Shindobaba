extends Node
## Bağışlanan Bingo kaçağı: dost olur, bir daha düşman olarak doğmaz (uzaklaş -> geri gel), kampında dost kopyası tek
var main: Node


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _count(bid: int) -> int:
	var n = 0
	for f in get_tree().get_nodes_in_group("fighters"):
		if is_instance_valid(f) and not f.is_queued_for_deletion() and f.has_meta("bingo_id") and int(f.get_meta("bingo_id")) == bid:
			n += 1
	return n


func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken",
		"hair": Color(0.2, 0.2, 0.2), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.2, 0.2, 0.2)}
	main._start_new_game()
	var pl: Player = main.player
	await _wait(1.5)
	Hud.close_dialog()
	var lst: Array = Missions._bingo()["list"]
	var e: Dictionary = {}
	for x in lst:
		if x["status"] == "alive" and not x.has("beast"):
			e = x
			break
	if e.is_empty():
		lst.append(Missions._bb_new())
		e = lst[-1]
	var bid = int(e["id"])
	var hp = Game.from_map(Vector2(e["hide"][0], e["hide"][1]))
	pl.global_position = hp + Vector3(0, 2, 8)
	await _wait(1.5)
	print("BBS spawned before spare: %d" % _count(bid))
	var boss = Missions._bb_spawned[bid][0]
	RogueBonds.spare(boss)
	await _wait(0.5)
	print("BBS status=%s friend=%s count=%d" % [e["status"], e.get("friend_id", ""), _count(bid)])
	var fid = String(e["friend_id"])
	pl.global_position = hp + Vector3(600, 2, 0)
	await _wait(1.5)
	pl.global_position = hp + Vector3(0, 2, 8)
	await _wait(1.5)
	print("BBS after return enemy count=%d" % _count(bid))
	# eski kayıt göçü: status alive'a geri çek, yeniden doğsun, düzeltme silmeli
	e["status"] = "alive"
	Missions._bb_spawn(e, hp)
	await _wait(1.2)
	print("BBS old-save migration status=%s enemy count=%d" % [e["status"], _count(bid)])
	# dostun kampına git: dost tek kopya
	var lp = Friends.where(fid)
	Friends.show_on_map(fid)
	pl.global_position = lp + Vector3(0, 2, 5)
	await _wait(2.0)
	var fr = 0
	for n in get_tree().get_nodes_in_group("talkers"):
		if String(n.get_meta("friend_id", "")) == fid:
			fr += 1
	print("BBS at lair friend copies=%d enemy copies=%d" % [fr, _count(bid)])
	get_tree().quit()
