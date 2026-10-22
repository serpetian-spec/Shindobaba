extends Node
## Menü testi: gerçek fare tıklamasıyla Yeni Oyun -> yuva -> yaratıcı, sonra Tab menüsü sekmeleri ve Esc menüsü.
var main: Node


func _find_button(text: String) -> Button:
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(text) and b.is_visible_in_tree():
			return b
	return null


func _click(text: String) -> bool:
	var b = _find_button(text)
	if b == null:
		print("BUTON YOK: ", text)
		return false
	var c = b.get_global_rect().get_center()
	var vp = get_viewport().get_visible_rect()
	if not vp.has_point(c):
		print("BUTON EKRAN DIŞI: ", text, " ", c)
		return false
	for pressed in [true, false]:
		var e = InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = c
		e.global_position = c
		Input.parse_input_event(e)
		await get_tree().process_frame
	print("TIKLANDI: ", text)
	return true


func _key(k: Key) -> void:
	for pressed in [true, false]:
		var e = InputEventKey.new()
		e.physical_keycode = k
		e.keycode = k
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame


func _ready() -> void:
	await get_tree().process_frame
	main.to_main_menu()
	await get_tree().create_timer(1.5).timeout
	await main.shot("m1_ana_menu")
	await _click("Yeni Oyun")
	await get_tree().create_timer(0.5).timeout
	await main.shot("m1b_yuva")
	await _click("Yuva 3")
	await get_tree().create_timer(1.5).timeout
	await main.shot("m2_karakter_yarat")
	await _click("Maceraya")
	await get_tree().create_timer(2.0).timeout
	await _key(KEY_TAB)
	await get_tree().create_timer(0.6).timeout
	await main.shot("m5_tab_envanter")
	Gear.grant(Game.profile, "katana")
	Gear.grant(Game.profile, "tanto")
	Game.profile["rank"] = 2
	await _click("Ekipman")
	await get_tree().create_timer(0.6).timeout
	await _click("Sağ El")
	await get_tree().create_timer(0.4).timeout
	await _click("Giy / Kuşan")
	await get_tree().create_timer(0.4).timeout
	await _click("Sol El")
	await get_tree().create_timer(0.4).timeout
	await _click("Giy / Kuşan")
	await get_tree().create_timer(1.2).timeout
	await main.shot("m6_tab_ekipman")
	await _click("Üst Kıyafet")
	await get_tree().create_timer(1.2).timeout
	await main.shot("m6b_ekipman_ust")
	await _click("Jutsular")
	await get_tree().create_timer(0.4).timeout
	await main.shot("m7_tab_jutsu")
	await _click("Yetenekler")
	await get_tree().create_timer(0.4).timeout
	await main.shot("m8_tab_yetenek")
	await _key(KEY_TAB)
	await get_tree().create_timer(0.4).timeout
	print("tab kapandı mı: ", not Game.paused)
	await _key(KEY_ESCAPE)
	await get_tree().create_timer(0.5).timeout
	await main.shot("m3_duraklat")
	await _click("Ayarlar")
	await get_tree().create_timer(0.4).timeout
	await main.shot("m3b_ayarlar")
	await _click("Kaydet ve Geri")
	await get_tree().create_timer(0.3).timeout
	var names = []
	for b in Hud.dialog_layer.find_children("*", "Button", true, false):
		names.append(b.text)
	print("BUTONLAR: ", names)
	await _click("Devam")
	await get_tree().create_timer(0.3).timeout
	print("esc devam: ", not Game.paused)
	get_tree().quit()
