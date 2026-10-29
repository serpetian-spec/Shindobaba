extends Node
## Parşömenci: yalnız temel element jutsuları; her büyük köyde tezgâh var mı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(2.0).timeout
	Game.profile["level"] = 40
	var n = 0
	var bad = []
	for iid in Data.items:
		if Data.items[iid].get("kind", "") == "scroll" and Progress.scroll_sellable(String(Data.items[iid].get("jutsu", ""))):
			n += 1
	print("SCROLL sellable=%d shop=%s" % [n, Progress.scroll_shop_items(14).map(func(i): return Data.items[i]["jutsu"])])
	var shops = Interact.items.filter(func(it): return it["kind"] == "shop_scrolls").map(func(it): return it.get("village", ""))
	print("SCROLL stalls=%s" % [shops])
	get_tree().quit()
