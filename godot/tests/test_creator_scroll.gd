extends Node
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	Menus._ctab = "gorunum"
	main.start_creator(3)
	await get_tree().create_timer(1.0).timeout
	var scs = Menus._live_scrolls()
	print("CS scrolls=", scs.size(), " max=", scs.map(func(s): return [s.get_v_scroll_bar().max_value, s.get_v_scroll_bar().page, s.size.y]))
	var k = 0
	for i in scs.size():
		var mx = int(scs[i].get_v_scroll_bar().max_value - scs[i].get_v_scroll_bar().page)
		if mx > k:
			k = mx
		scs[i].scroll_vertical = mx
	await get_tree().process_frame
	var before = Menus._scroll_positions()
	main.creator_state["hair_style"] = "uzun"
	Menus.creator(main, main.creator_state, main._update_preview, main._start_new_game)
	await get_tree().create_timer(0.4).timeout
	print("CS before=", before, " after=", Menus._scroll_positions())
	get_tree().quit()
