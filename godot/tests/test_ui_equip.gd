extends Node
## Gözler sekmesi (çıkar / geri tak), envanterde göz yok, ekipmanda rütbe kilitli eşya + şart yazısı, jutsu sürükle-bırak
var main: Node
func _ready() -> void:
	await get_tree().process_frame
	main.creator_state = {"slot": 3, "name": "Test", "gender": "m", "clan": "uchiha", "element": "katon", "hair_style": "diken", "hair": Color(0.1, 0.1, 0.12), "top": Color(0.15, 0.2, 0.33), "pants": Color(0.15, 0.15, 0.17), "skin": Color(0.96, 0.8, 0.66), "eye": Color(0.25, 0.45, 0.8)}
	main._start_new_game()
	await get_tree().create_timer(3.0).timeout
	var pr = Game.profile
	Gear.ensure(pr)
	print("UI eyes equipped: ", not Gear.equipped(pr, "sag_goz").is_empty(), " ", not Gear.equipped(pr, "sol_goz").is_empty())
	# rütbe kilitli eşya ver (chunin yeleği rank>0 ise)
	var locked_id = ""
	for id in Gear.ITEMS:
		var it = Gear.ITEMS[id]
		if int(it.get("rank", 0)) >= 2 and it.get("slot", "") == "zirh":
			locked_id = id
			break
	Gear.grant(pr, locked_id)
	print("UI locked item: ", locked_id, " req=", Gear.req_text(locked_id, pr), " in owned_for: ", Gear.owned_for(pr, "zirh").map(func(g): return g["id"]).has(locked_id))
	pr["learned"] = ["katon_goukakyuu", "katon_housenka", "shunshin"]
	main._pause()
	Menus._inv_filter = "gear"
	Menus.ninja_menu(main, "inv")
	await get_tree().create_timer(0.6).timeout
	await main.shot("ui_inv")
	Menus.ninja_menu(main, "eyes")
	await get_tree().create_timer(0.6).timeout
	await main.shot("ui_eyes")
	Menus._eye_remove(pr, "sag_goz")
	Menus.ninja_menu(main, "eyes")
	await get_tree().create_timer(0.6).timeout
	print("UI after remove: sag empty=", Gear.equipped(pr, "sag_goz").is_empty(), " look eye_r=", pr["look"].get("eye_r"))
	await main.shot("ui_eyes_removed")
	var jar = -1
	for g in pr["gear"]:
		if Gear.is_eye(g["id"]) and not int(g["uid"]) in pr["equip"].values():
			jar = int(g["uid"])
	Menus._eye_insert(pr, jar, "sag_goz")
	print("UI after insert: sag ok=", not Gear.equipped(pr, "sag_goz").is_empty())
	Menus._eq_slot = "zirh"
	Menus.ninja_menu(main, "wardrobe")
	await get_tree().create_timer(0.8).timeout
	await main.shot("ui_wardrobe")
	Menus.ninja_menu(main, "jutsu", "katon_goukakyuu")
	await get_tree().create_timer(0.6).timeout
	# sürükle-bırak: ilk kartı 3. slota mouse olaylarıyla sürükle
	var card: Control = null
	var slots: Array = []
	for c in get_tree().root.find_children("*", "Button", true, false):
		if c.is_visible_in_tree() and c.has_method("get_drag_data"):
			pass
	for c in get_tree().root.find_children("*", "Button", true, false):
		if not c.is_visible_in_tree():
			continue
		if card == null and c.custom_minimum_size == Vector2(300, 92):
			card = c
		if c.custom_minimum_size == Vector2(112, 130) and c.text.begins_with("["):
			slots.append(c)
	print("UI found card=", card != null, " slots=", slots.size())
	if card and slots.size() >= 3:
		var a = card.get_global_rect().position + Vector2(card.size.x - 20, card.size.y - 12)
		var b = slots[2].get_global_rect().get_center()
		_mouse(a, true)
		await get_tree().process_frame
		for k in 12:
			_motion(a.lerp(b, (k + 1) / 12.0))
			await get_tree().process_frame
		print("UI dragging=", get_viewport().gui_is_dragging(), " data=", get_viewport().gui_get_drag_data())
		_mouse(b, false)
		await get_tree().create_timer(0.3).timeout
		print("UI slots after drag: ", pr["slots"], " hovered=", get_viewport().gui_get_hovered_control())
	await main.shot("ui_jutsu_drag")
	get_tree().quit()


func _mouse(pos: Vector2, down: bool) -> void:
	pos = get_viewport().get_final_transform() * pos
	var e = InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = pos
	e.global_position = pos
	if down:
		e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)


func _motion(pos: Vector2) -> void:
	pos = get_viewport().get_final_transform() * pos
	var e = InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)
