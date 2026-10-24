extends Node
## Menü yeniden kurulunca (eşya seçince) kaydırma yerinde kalmalı
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "none", "element": "katon", "hair_style": "diken", "hair": Color(0.3, 0.2, 0.12), "top": Color(0.9, 0.45, 0.12), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	for id in Gear.SHOP_CLOTHES:
		Gear.grant(Game.profile, id)
	main._pause()
	for tab in ["wardrobe", "jutsu", "inv"]:
		Menus.ninja_menu(main, tab)
		await get_tree().create_timer(0.4).timeout
		var scs = Hud.dialog_layer.find_children("*", "ScrollContainer", true, false)
		var best = null
		for sc in scs:
			if sc.get_v_scroll_bar().max_value > sc.size.y + 50 and (best == null or sc.get_v_scroll_bar().max_value > best.get_v_scroll_bar().max_value):
				best = sc
		if best == null:
			print("SCROLL ", tab, " no scrollable")
			continue
		best.scroll_vertical = 400
		await get_tree().process_frame
		var idx = scs.find(best)
		Menus.ninja_menu(main, tab)
		await get_tree().create_timer(0.3).timeout
		var after = Hud.dialog_layer.find_children("*", "ScrollContainer", true, false)
		print("SCROLL ", tab, " before=400 after=", after[idx].scroll_vertical if idx < after.size() else -1)
	get_tree().quit()
