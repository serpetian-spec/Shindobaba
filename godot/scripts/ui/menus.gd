class_name Menus
extends RefCounted
## Tam ekran menüler. Hepsi Hud.dialog_layer'a eklenir.

const SKILLS := {
	"tai1": ["Demir Yumruk", "Yakın dövüş +%20", "Taijutsu", "", 1],
	"tai2": ["Rüzgar Adım", "Koşu hızı +%12", "Taijutsu", "tai1", 4],
	"tai4": ["Usta Savaşçı", "Yakın dövüş +%30", "Taijutsu", "tai2", 14],
	"nin1": ["Chakra Kontrolü", "Jutsu maliyeti -%10", "Ninjutsu", "", 1],
	"nin2": ["Geniş Chakra", "Maks chakra +50", "Ninjutsu", "nin1", 4],
	"nin3": ["Hızlı Mühür", "Mühür süresi -%40", "Ninjutsu", "nin2", 8],
	"nin4": ["Jutsu Ustası", "Jutsu hasarı +%30", "Ninjutsu", "nin3", 16],
	"elem2": ["İkinci Element", "Yeni bir chakra doğası (Chunin)", "Ninjutsu", "nin2", 12],
	"vit1": ["Dayanıklılık", "Maks can +40", "Destek", "", 1],
	"vit2": ["Yenilenme", "Chakra yenilenmesi x2", "Destek", "vit1", 10],
	"genjutsu": ["Genjutsu Eğitimi", "Genjutsu teknikleri", "Destek", "", 5],
}


static func clear() -> void:
	for c in Hud.dialog_layer.get_children():
		c.queue_free()


static var _fresh := false


static func _full() -> Control:
	_fresh = Hud.dialog_layer.get_child_count() == 0
	clear()
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.015, 0.025, 0.62)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.dialog_layer.add_child(bg)
	# kenarlarda koyulaşma + alt köşede eğik turuncu fırça izi
	var deco = Control.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		var r = deco.get_rect().size
		deco.draw_colored_polygon(PackedVector2Array([Vector2(0, r.y), Vector2(r.x * 0.42, r.y), Vector2(r.x * 0.36, r.y - 26), Vector2(0, r.y - 26)]), Color(UI.ACCENT, 0.55))
		deco.draw_colored_polygon(PackedVector2Array([Vector2(r.x, 0), Vector2(r.x * 0.62, 0), Vector2(r.x * 0.66, 18), Vector2(r.x, 18)]), Color(UI.ACCENT, 0.4)))
	bg.add_child(deco)
	if _fresh:
		bg.modulate.a = 0.0
		var tw = bg.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(bg, "modulate:a", 1.0, 0.15)
	return bg


static func _center_panel(parent: Control, w := 560.0) -> VBoxContainer:
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var p = UI.panel()
	p.custom_minimum_size = Vector2(w, 0)
	cc.add_child(p)
	var v = UI.vbox(10)
	p.add_child(v)
	if _fresh:
		UI.pop_in(p)
	return v


# ------------------------------------------------------------------ ana menü
static func main_menu(main: Node) -> void:
	clear()
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.dialog_layer.add_child(root)
	var col = Panel.new()
	var csb = UI._box(Color(0.03, 0.02, 0.03, 0.78), UI.ACCENT, 0, 0, 0, -0.08)
	csb.border_width_right = 6
	col.add_theme_stylebox_override("panel", csb)
	col.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	col.offset_left = -40
	col.offset_right = 640
	root.add_child(col)
	var logo = UI.label("SHINOBI", 104, UI.ACCENT)
	logo.position = Vector2(70, 50)
	root.add_child(logo)
	var logo2 = UI.label("YOLU", 72, UI.CREAM)
	logo2.position = Vector2(300, 160)
	root.add_child(logo2)
	var kanji = UI.label("忍の道", 30, Color(UI.ACCENT, 0.85))
	kanji.position = Vector2(84, 186)
	root.add_child(kanji)
	var sub = UI.label("Beş Büyük Ülke'nin dünyasında kendi efsaneni yaz", 20, UI.MUTED)
	sub.position = Vector2(78, 262)
	root.add_child(sub)
	var v = UI.vbox(14)
	v.position = Vector2(90, 330)
	root.add_child(v)
	var items = [["Yeni Oyun", func(): slot_select(main, true)], ["Devam Et", func(): slot_select(main, false)],
		["Ayarlar", func(): settings(func(): main_menu(main))], ["Çıkış", func(): main.get_tree().quit()]]
	for i in items.size():
		var b = UI.button(items[i][0], items[i][1], 380)
		b.custom_minimum_size = Vector2(380, 52)
		b.add_theme_font_size_override("font_size", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
		b.modulate.a = 0.0
		var tw = b.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_property(b, "modulate:a", 1.0, 0.25)
	var ver = UI.label("v%s %s   •   Kanon karakter içermez; Naruto evreninde geçen özgün bir hikâye." % [Game.version, "(TEST)" if Game.build_tag == "test" else ""], 13, UI.MUTED)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(24, -34)
	root.add_child(ver)


static func slot_select(main: Node, new_game: bool) -> void:
	var bg = _full()
	var v = _center_panel(bg)
	v.add_child(UI.header("YENİ OYUN — KAYIT YUVASI SEÇ" if new_game else "KAYIT YÜKLE", 28))
	for s in [1, 2, 3]:
		var info = Game.slot_summary(s)
		var txt = "Yuva %d:  %s" % [s, info if info != "" else "(boş)"]
		var b = UI.button(txt, func():
			if new_game:
				main.start_creator(s)
			elif info != "":
				main.load_slot(s), 520)
		if not new_game and info == "":
			b.disabled = true
		v.add_child(b)
	v.add_child(UI.button("Geri", func(): main_menu(main), 520))


# ------------------------------------------------------------------ karakter yaratma
static func creator(main: Node, state: Dictionary, on_change: Callable, on_start: Callable) -> void:
	clear()
	var sc = ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sc.offset_left = 30
	sc.offset_top = 24
	sc.offset_bottom = -98
	sc.offset_right = 600
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Hud.dialog_layer.add_child(sc)
	var p = UI.panel()
	p.custom_minimum_size = Vector2(540, 0)
	sc.add_child(p)
	var v = UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.header("KARAKTERİNİ YARAT", 30))
	var name_edit = LineEdit.new()
	name_edit.text = state["name"]
	name_edit.placeholder_text = "Ninja adın"
	name_edit.max_length = 18
	name_edit.text_changed.connect(func(t): state["name"] = t)
	v.add_child(UI.label("İsim", 16))
	v.add_child(name_edit)
	var row = func(title: String, key: String, options: Array, labels: Array) -> void:
		var h = UI.hbox(6)
		var l = UI.label(title, 16)
		l.custom_minimum_size = Vector2(120, 0)
		h.add_child(l)
		var ob = OptionButton.new()
		ob.custom_minimum_size = Vector2(360, 34)
		for i in options.size():
			ob.add_item(labels[i])
			if options[i] == state[key]:
				ob.select(i)
		ob.item_selected.connect(func(i):
			state[key] = options[i]
			on_change.call()
			if key == "clan":
				creator(main, state, on_change, on_start))
		h.add_child(ob)
		v.add_child(h)
	row.call("Cinsiyet", "gender", ["m", "f"], ["Erkek", "Kadın"])
	var clan_ids: Array = Data.clans.keys()
	var clan_names: Array = clan_ids.map(func(c): return Data.clans[c]["name"])
	row.call("Klan", "clan", clan_ids, clan_names)
	var cd = UI.label(Data.clans.get(state["clan"], {}).get("desc", ""), 13, Color(0.85, 0.85, 0.8))
	cd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cd.custom_minimum_size = Vector2(480, 0)
	v.add_child(cd)
	row.call("Chakra Doğası", "element", ["katon", "suiton", "fuuton", "doton", "raiton"], ["Katon (Ateş)", "Suiton (Su)", "Fuuton (Rüzgar)", "Doton (Toprak)", "Raiton (Yıldırım)"])
	row.call("Saç Stili", "hair_style", ["diken", "kısa", "uzun", "atkuyruğu", "kase", "dağınık"], ["Dikenli", "Kısa", "Uzun", "At kuyruğu", "Kâse", "Dağınık"])
	var hair_cols = [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.9, 0.92), Color(0.2, 0.3, 0.6), Color(0.9, 0.55, 0.7), Color(0.25, 0.45, 0.25)]
	row.call("Saç Rengi", "hair", hair_cols, ["Kahve", "Siyah", "Sarı", "Kızıl", "Beyaz", "Lacivert", "Pembe", "Yeşil"])
	var outfit_cols = [Color(0.15, 0.2, 0.33), Color(0.15, 0.15, 0.17), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22), Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45)]
	row.call("Üst Kıyafet", "top_style", CharacterModel.TOP_STYLES.keys(), CharacterModel.TOP_STYLES.values())
	row.call("Alt Kıyafet", "pants_style", CharacterModel.PANTS_STYLES.keys(), CharacterModel.PANTS_STYLES.values())
	row.call("Üst Rengi", "top", outfit_cols, ["Lacivert", "Siyah", "Bordo", "Turuncu", "Yeşil", "Mor", "Krem", "Petrol"])
	row.call("Vurgu Rengi", "top2", outfit_cols, ["Lacivert", "Siyah", "Bordo", "Turuncu", "Yeşil", "Mor", "Krem", "Petrol"])
	row.call("Alt Rengi", "pants", outfit_cols, ["Lacivert", "Siyah", "Bordo", "Turuncu", "Yeşil", "Mor", "Krem", "Petrol"])
	var skin = [Color(0.96, 0.8, 0.66), Color(0.86, 0.68, 0.52), Color(0.68, 0.5, 0.36), Color(0.98, 0.88, 0.8)]
	row.call("Ten", "skin", skin, ["Açık", "Buğday", "Esmer", "Çok açık"])
	if not state["clan"] in ["uchiha", "hyuga", "aburame"]:
		var eye_cols = [Color(0.25, 0.45, 0.8), Color(0.3, 0.2, 0.12), Color(0.25, 0.55, 0.3), Color(0.1, 0.1, 0.1), Color(0.6, 0.4, 0.15)]
		row.call("Göz Rengi", "eye", eye_cols, ["Mavi", "Kahve", "Yeşil", "Siyah", "Kehribar"])
	v.add_child(UI.label("İpucu: fareyle önizlemeyi döndür", 13, Color(0.7, 0.7, 0.7)))
	# alt çubuk: her zaman görünür (kaydırma alanının dışında)
	var bar = PanelContainer.new()
	var bsb = UI._box(Color(0.04, 0.03, 0.04, 0.9), UI.ACCENT, 0, 4, 10)
	bsb.border_width_top = 3
	bar.add_theme_stylebox_override("panel", bsb)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bar.position = Vector2(30, -88)
	bar.custom_minimum_size = Vector2(570, 0)
	var h = UI.hbox(12)
	bar.add_child(h)
	h.add_child(UI.button("Geri", func(): main.back_to_menu(), 190))
	var go = UI.button("Maceraya Başla!", on_start, 340)
	var gsb = UI._box(UI.ACCENT_DARK, UI.ACCENT, 1, 3, 9, 0.12)
	gsb.border_width_bottom = 3
	go.add_theme_stylebox_override("normal", gsb)
	h.add_child(go)
	Hud.dialog_layer.add_child(bar)


# ------------------------------------------------------------------ duraklatma
static func pause(main: Node) -> void:
	var bg = _full()
	var v = _center_panel(bg, 420)
	v.add_child(UI.header("DURAKLATILDI", 32))
	v.add_child(UI.label("%s  •  %s" % [Game.profile.get("name", ""), Game.region_name(Game.player.global_position) if Game.player else ""], 15, UI.MUTED))
	v.add_child(UI.button("Devam", func(): main.resume(), 380))
	v.add_child(UI.button("Ninja Menüsü — Envanter [Tab]", func(): ninja_menu(main, "inv"), 380))
	v.add_child(UI.button("Ekipman ve Kıyafetler", func(): ninja_menu(main, "wardrobe"), 380))
	v.add_child(UI.button("Jutsu ve Yetenekler [K]", func(): ninja_menu(main, "jutsu"), 380))
	v.add_child(UI.button("Dünya Haritası [M]", func(): world_map(main), 380))
	v.add_child(UI.button("Ayarlar", func(): settings(func(): pause(main)), 380))
	v.add_child(UI.button("Kaydet", func():
		Game.save_game()
		Hud.msg("Oyun kaydedildi.", Color(0.6, 1, 0.6)), 380))
	v.add_child(UI.button("Kontroller", func(): controls(main), 380))
	v.add_child(UI.button("Ana Menüye Dön (kaydeder)", func(): main.to_main_menu(), 380))
	v.add_child(UI.button("Oyundan Çık (kaydeder)", func():
		Game.save_game()
		main.get_tree().quit(), 380))


static func controls(main: Node) -> void:
	var bg = _full()
	var v = _center_panel(bg, 760)
	v.add_child(UI.header("KONTROLLER", 28))
	var t = """WASD: hareket   •   Fare: kamera   •   Tekerlek: yakınlaştır
Space: zıpla (havada tekrar = çift zıplama)   •   Ctrl: uzun ninja sıçrayışı (Shinobi Striker)   •   Shift: ninja koşusu, havada dash
Duvara doğru koş: DUVARDA KOŞ (W yukarı, A/D yana)   •   Duvardayken Ctrl: duvardan sek
Sol tık: kombo (havada: dalış tekmesi)   •   Sağ tık (basılı): blok (tam zamanında = mükemmel blok)
Q: Kawarimi (yer değiştirme)   •   C (basılı): chakra şarjı   •   R: kunai/alet   •   T: alet değiştir
E / orta tık: hedefe kilitlen   •   Kilitliyken Shift: chakra dash
1-6: jutsu slotları   •   F: etkileşim   •   H: merhem   •   Y: asker hapı
G (basılı) + 1-9,0,-,=: mühür ör (bırakınca jutsu / yeni jutsu keşfi)   •   V: Sharingan/Byakugan
B: Sekiz Kapı (klansız)   •   Z: Sennin Modu   •   X: Kuyruklu Canavar modu / bombası
Tab: ninja menüsü (envanter, kıyafetler, jutsu, yetenekler)   •   K: jutsular   •   M: harita   •   Esc: menü"""
	var l = UI.label(t, 17)
	v.add_child(l)
	v.add_child(UI.button("Geri", func(): pause(main), 720))


# ------------------------------------------------------------------ ayarlar
static func settings(back: Callable) -> void:
	var bg = _full()
	var v = _center_panel(bg, 560)
	v.add_child(UI.header("AYARLAR", 28))
	var s = Game.settings
	var slider = func(title: String, key: String, mn: float, mx: float, step: float) -> void:
		var h = UI.hbox(8)
		var l = UI.label("%s: %.2f" % [title, s[key]], 16)
		l.custom_minimum_size = Vector2(220, 0)
		var sl = HSlider.new()
		sl.min_value = mn; sl.max_value = mx; sl.step = step; sl.value = s[key]
		sl.custom_minimum_size = Vector2(280, 24)
		sl.value_changed.connect(func(x):
			s[key] = x
			l.text = "%s: %.2f" % [title, x])
		h.add_child(l); h.add_child(sl)
		v.add_child(h)
	var check = func(title: String, key: String) -> void:
		var c = CheckBox.new()
		c.text = title
		c.button_pressed = s[key]
		c.toggled.connect(func(x): s[key] = x)
		v.add_child(c)
	slider.call("Fare hassasiyeti", "sens", 0.2, 3.0, 0.05)
	slider.call("Görüş alanı (FOV)", "fov", 55.0, 100.0, 1.0)
	slider.call("Müzik", "music", 0.0, 1.0, 0.05)
	slider.call("Efektler", "sfx", 0.0, 1.0, 0.05)
	slider.call("Görüş mesafesi", "view", 0.5, 1.6, 0.05)
	check.call("Tam ekran", "fullscreen")
	check.call("Gölgeler", "shadows")
	check.call("Anime çizgileri", "outline")
	check.call("Fareyi ters çevir (Y)", "invert_y")
	check.call("FPS göster", "show_fps")
	v.add_child(UI.button("Kaydet ve Geri", func():
		Game.save_settings()
		if Game.player:
			Game.player.cam.fov = s["fov"]
		if Game.world:
			Game.world.env.sun.shadow_enabled = s["shadows"]
			Game.world.env.post.visible = s["outline"]
		Sfx.music_a.volume_db = linear_to_db(maxf(0.001, float(s["music"]) * 0.6))
		back.call(), 520))


# ------------------------------------------------------------------ ninja menüsü [Tab]: envanter / kıyafetler / jutsu / yetenekler
const TABS := [["inv", "Envanter"], ["wardrobe", "Ekipman"], ["jutsu", "Jutsular"], ["skills", "Yetenekler"]]
const SWATCHES := [Color(0.15, 0.2, 0.33), Color(0.12, 0.12, 0.14), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22),
	Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45), Color(0.55, 0.42, 0.3), Color(0.75, 0.2, 0.25)]


static func ninja_menu(main: Node, tab := "inv", picked := "") -> void:
	var bg = _full()
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(cc)
	var p = UI.panel()
	p.custom_minimum_size = Vector2(1240, 740)
	cc.add_child(p)
	if _fresh:
		UI.pop_in(p)
	var v = UI.vbox(10)
	p.add_child(v)
	# başlık + sekmeler
	var head = UI.hbox(8)
	var pr = Game.profile
	var wv = UI.vbox(0)
	wv.custom_minimum_size = Vector2(380, 0)
	wv.add_child(UI.label(String(pr["name"]), 26, UI.CREAM))
	wv.add_child(UI.label("%s  •  Seviye %d  •  両 %d" % [Data.RANKS[int(pr["rank"])].to_upper(), int(pr["level"]), int(pr["ryo"])], 14, UI.ACCENT))
	head.add_child(wv)
	var icons = {"inv": "🎒 ", "wardrobe": "🥋 ", "jutsu": "🌀 ", "skills": "✦ "}
	for t in TABS:
		var b = UI.button(t[1], func(): ninja_menu(main, t[0]), 170)
		b.icon = null
		b.text = t[1]
		b.tooltip_text = icons.get(t[0], "") + t[1]
		if t[0] == tab:
			var sel = UI._box(UI.ACCENT_DARK, UI.ACCENT, 1, 3, 9, 0.12)
			sel.border_width_bottom = 4
			for k in ["normal", "hover", "pressed", "focus", "disabled"]:
				b.add_theme_stylebox_override(k, sel)
			b.add_theme_color_override("font_disabled_color", Color(1, 0.95, 0.85))
			b.disabled = true
		head.add_child(b)
	v.add_child(head)
	v.add_child(HSeparator.new())
	var body = Control.new()
	body.custom_minimum_size = Vector2(1200, 600)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	match tab:
		"inv":
			_tab_inventory(main, body)
		"wardrobe":
			_tab_wardrobe(main, body)
		"jutsu":
			_tab_jutsu(main, body, picked)
		"skills":
			_tab_skills(main, body)
	var foot = UI.hbox(10)
	foot.add_child(UI.key_badge("Tab", 13))
	foot.add_child(UI.label("/", 14, UI.MUTED))
	foot.add_child(UI.key_badge("Esc", 13))
	foot.add_child(UI.label("kapat     ", 14, UI.MUTED))
	foot.add_child(UI.key_badge("I", 13))
	foot.add_child(UI.label("envanter     ", 14, UI.MUTED))
	foot.add_child(UI.key_badge("K", 13))
	foot.add_child(UI.label("jutsular", 14, UI.MUTED))
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	foot.add_child(UI.button("Kapat", func(): main.resume(), 200))
	v.add_child(foot)


static func _scroll(parent: Control, w: float) -> VBoxContainer:
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w, 600)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var v = UI.vbox(6)
	v.custom_minimum_size = Vector2(w - 20, 0)
	sc.add_child(v)
	return v


static func _tab_inventory(main: Node, body: Control) -> void:
	var pr = Game.profile
	var h = UI.hbox(24)
	body.add_child(h)
	var v = _scroll(h, 760)
	v.add_child(UI.header("ÇANTA   —   %d Ryō" % int(pr["ryo"]), 22))
	var inv: Dictionary = pr["inventory"]
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	var any = false
	for id in inv.keys():
		if int(inv[id]) <= 0:
			continue
		any = true
		var it: Dictionary = Data.items.get(id, {"name": id, "desc": "", "kind": "misc"})
		var card = UI.panel()
		card.custom_minimum_size = Vector2(360, 96)
		var cv = UI.vbox(4)
		card.add_child(cv)
		cv.add_child(UI.label("%s   x%d" % [it["name"], int(inv[id])], 18, Color(1, 0.9, 0.7)))
		var d = UI.label(it.get("desc", ""), 13, Color(0.85, 0.85, 0.8))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(320, 0)
		cv.add_child(d)
		if it.get("kind", "") == "throw":
			var sel: bool = pr["throw_sel"] == id
			var b = UI.button("Kuşanıldı" if sel else "Kuşan [R]", func():
				pr["throw_sel"] = id
				ninja_menu(main, "inv"), 150)
			b.disabled = sel
			cv.add_child(b)
		elif it.get("kind", "") == "use":
			cv.add_child(UI.button("Kullan", func():
				main.use_item(id)
				ninja_menu(main, "inv"), 150))
		grid.add_child(card)
	if not any:
		v.add_child(UI.label("Çantan boş.", 16))
	# sağ: durum
	var s = UI.vbox(8)
	s.custom_minimum_size = Vector2(380, 0)
	h.add_child(s)
	s.add_child(UI.header("DURUM", 22))
	var pl = Game.player
	if pl:
		s.add_child(UI.label("Can: %d / %d" % [int(pl.hp), int(pl.max_hp)], 17))
		s.add_child(UI.label("Chakra: %d / %d" % [int(pl.chakra), int(pl.max_chakra)], 17))
	s.add_child(UI.label("Rütbe: %s" % Data.RANKS[int(pr["rank"])], 17))
	s.add_child(UI.label("Seviye %d  (XP %d)" % [int(pr["level"]), int(pr["xp"])], 17))
	s.add_child(UI.label("Klan: %s" % Data.clans.get(pr["clan"], {}).get("name", "Klansız"), 17))
	s.add_child(UI.label("Chakra doğası: %s" % ", ".join(pr["elements"]), 17))
	s.add_child(UI.label("Yetenek puanı: %d" % int(pr["sp"]), 17))
	var md: Dictionary = pr["missions_done"]
	s.add_child(UI.label("Görevler  D:%d  C:%d  B:%d  A:%d  S:%d" % [md["D"], md["C"], md["B"], md["A"], md["S"]], 17))


static var _eq_slot := "govde"


## Ekipman: solda yuvalar (kafa, üst, alt, ayak, yelek, sağ el, sol el, saç), ortada sahip olunanlar + boya, sağda önizleme
static func _tab_wardrobe(main: Node, body: Control) -> void:
	var pr = Game.profile
	Gear.ensure(pr)
	var h = UI.hbox(16)
	body.add_child(h)
	var refresh = func() -> void:
		Gear.apply_look(pr)
		if Game.player:
			Game.player.rebuild_model()
			Game.player.apply_profile_stats()
		ninja_menu(main, "wardrobe")
	# --- sol: yuvalar
	var left = UI.vbox(6)
	left.custom_minimum_size = Vector2(330, 0)
	h.add_child(left)
	left.add_child(UI.header("EKİPMAN", 22))
	for sl in Gear.SLOTS + [["sac", "Saç"]]:
		var nm = "—"
		if sl[0] == "sac":
			nm = String(pr["look"].get("hair_style", "diken")).capitalize()
		else:
			var g = Gear.equipped(pr, sl[0])
			if not g.is_empty():
				nm = Gear.item(g["id"])["name"]
		var b = UI.button("%s:  %s" % [sl[1], nm], func():
			_eq_slot = sl[0]
			ninja_menu(main, "wardrobe"), 330)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		if sl[0] == _eq_slot:
			b.modulate = Color(1, 0.75, 0.4)
		left.add_child(b)
	left.add_child(HSeparator.new())
	var tot = []
	for k in [["def", "Savunma", false], ["hp", "Can", false], ["chakra", "Chakra", false], ["speed", "Hız", true], ["melee", "Yakın dövüş", true]]:
		var v = Gear.stat(pr, k[0])
		if v != 0.0:
			tot.append(("%s %+d%%" % [k[1], int(round(v * 100))]) if k[2] else ("%s %+d" % [k[1], int(v)]))
	var w = Gear.weapon(pr)
	tot.append("Silah hasarı x%.2f" % w["dmg"])
	var tl = UI.label("Toplam: " + ", ".join(tot), 15, Color(0.85, 0.95, 0.85))
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(320, 0)
	left.add_child(tl)
	# --- orta: bu yuvaya giyilebilenler
	var mid = _scroll(h, 470)
	if _eq_slot == "sac":
		_hair_panel(mid, pr["look"], refresh)
	else:
		var cur = Gear.equipped(pr, _eq_slot)
		var title = ""
		for sl in Gear.SLOTS:
			if sl[0] == _eq_slot:
				title = sl[1]
		mid.add_child(UI.header(title.to_upper(), 20))
		var list = Gear.owned_for(pr, _eq_slot)
		if list.is_empty():
			mid.add_child(UI.label("Bu yuvaya uygun eşyan yok. Dükkânlardan alabilir, görevlerden kazanabilirsin.", 15, Color(0.75, 0.75, 0.75)))
		for g in list:
			var it = Gear.item(g["id"])
			var card = UI.panel()
			var cv = UI.vbox(3)
			card.add_child(cv)
			var on: bool = not cur.is_empty() and int(cur["uid"]) == int(g["uid"])
			var used_other = false
			for sl in Gear.SLOTS:
				if sl[0] != _eq_slot and int(pr["equip"].get(sl[0], -1)) == int(g["uid"]):
					used_other = true
			var head = UI.hbox(6)
			var sw = ColorRect.new()
			sw.color = Color.html(g["c1"])
			sw.custom_minimum_size = Vector2(18, 18)
			head.add_child(sw)
			head.add_child(UI.label(it["name"] + ("   (takılı)" if on else ("   (diğer elde)" if used_other else "")), 17, Color(1, 0.9, 0.6) if on else UI.TEXT))
			cv.add_child(head)
			cv.add_child(UI.label(Gear.stats_text(g["id"]), 14, Color(0.7, 0.95, 0.7)))
			var d = UI.label(it["desc"], 13, Color(0.8, 0.8, 0.78))
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size = Vector2(420, 0)
			cv.add_child(d)
			if on:
				if not _eq_slot in Gear.REQUIRED:
					cv.add_child(UI.button("Çıkar", func():
						pr["equip"].erase(_eq_slot)
						refresh.call(), 140))
			elif not used_other:
				cv.add_child(UI.button("Giy / Kuşan", func():
					pr["equip"][_eq_slot] = int(g["uid"])
					refresh.call(), 140))
			mid.add_child(card)
		# boya (silah hariç)
		if not cur.is_empty() and not Gear.item(cur["id"]).has("weapon"):
			mid.add_child(HSeparator.new())
			var names = {"govde": ["Ana renk", "Vurgu (omuz/yaka)"], "ayak": ["Sandalet", "Sargılar"]}.get(_eq_slot, ["Renk"])
			for ci in names.size():
				var key = "c%d" % (ci + 1)
				var r = UI.hbox(4)
				var l = UI.label(names[ci], 15)
				l.custom_minimum_size = Vector2(150, 0)
				r.add_child(l)
				var sc = GridContainer.new()
				sc.columns = 5
				for c in SWATCHES:
					sc.add_child(_swatch(c, Color.html(cur[key]).is_equal_approx(c), func():
						cur[key] = c.to_html(false)
						refresh.call()))
				r.add_child(sc)
				mid.add_child(r)
	# --- sağ: önizleme
	h.add_child(_model_preview(Game.player._look_with_age() if Game.player else pr["look"]))


static func _swatch(c: Color, on: bool, cb: Callable) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(40, 30)
	var sb = StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(4)
	sb.border_color = UI.ACCENT if on else Color(0, 0, 0, 0.6)
	sb.set_border_width_all(3 if on else 1)
	for st in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


static func _hair_panel(v: VBoxContainer, look: Dictionary, refresh: Callable) -> void:
	v.add_child(UI.header("SAÇ (berber ücretsiz)", 20))
	var styles = {"diken": "Dikenli", "dağınık": "Dağınık", "kase": "Kâse", "kısa": "Kısa", "uzun": "Uzun", "atkuyruğu": "At kuyruğu"}
	var g = GridContainer.new()
	g.columns = 3
	for k in styles:
		var b = UI.button(styles[k], func():
			look["hair_style"] = k
			refresh.call(), 140)
		if look.get("hair_style", "") == k:
			b.modulate = Color(1, 0.75, 0.4)
		g.add_child(b)
	v.add_child(g)
	v.add_child(UI.label("Renk", 16))
	var cg = GridContainer.new()
	cg.columns = 8
	for c in [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.9, 0.92), Color(0.2, 0.3, 0.6), Color(0.9, 0.55, 0.7), Color(0.25, 0.45, 0.25)]:
		cg.add_child(_swatch(c, Color(look.get("hair", Color.BLACK)).is_equal_approx(c), func():
			look["hair"] = c
			refresh.call()))
	v.add_child(cg)


## Ayrı dünyada dönen karakter önizlemesi (oyun duraklatılmışken de çalışır)
static func _model_preview(look: Dictionary) -> Control:
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(400, 600)
	svc.stretch = true
	svc.process_mode = Node.PROCESS_MODE_ALWAYS
	var sv = SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	sv.msaa_3d = Viewport.MSAA_4X
	svc.add_child(sv)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.78, 0.9)
	env.environment.ambient_light_energy = 0.5
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	sv.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_energy = 1.3
	sv.add_child(sun)
	var m = CharacterModel.new()
	sv.add_child(m)
	m.setup(look)
	m.play("idle")
	m.scale = Vector3.ONE  # önizlemede tam boy
	var cam = Camera3D.new()
	cam.fov = 32
	sv.add_child(cam)
	var cp = Vector3(0, 1.0, -4.2)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.92, 0) - cp), cp)
	var tw = m.create_tween().set_loops()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(m, "rotation:y", TAU, 9.0).from(0.0)
	return svc


static func _tab_jutsu(main: Node, body: Control, picked: String) -> void:
	var pr = Game.profile
	var v = _scroll(body, 1200)
	v.add_child(UI.header("JUTSULAR  — bir jutsu seç, sonra aşağıdan slota ata", 22))
	var learned: Array = pr["learned"]
	if learned.is_empty():
		v.add_child(UI.label("Henüz bir jutsu bilmiyorsun. Akademi hocanla konuş!", 16))
	var grid = GridContainer.new()
	grid.columns = 2
	v.add_child(grid)
	for jid in learned:
		var j: Dictionary = Data.jutsu.get(jid, {})
		var seals: Array = j.get("seals", [])
		var b = UI.button("%s  [%s] — %d ck%s" % [j.get("name", jid), j.get("canon_rank", "?"), int(j.get("cost", 0)), ("  •  " + "-".join(seals)) if not seals.is_empty() else ""],
			func(): ninja_menu(main, "jutsu", jid), 585)
		b.tooltip_text = j.get("desc", "")
		b.clip_text = true
		if jid == picked:
			b.modulate = Color(1, 0.8, 0.5)
		grid.add_child(b)
	if picked != "":
		var d = UI.label(Data.jutsu.get(picked, {}).get("desc", ""), 15, Color(0.9, 0.9, 0.85))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(1150, 0)
		v.add_child(d)
	v.add_child(HSeparator.new())
	v.add_child(UI.header("SLOTLAR (1-6)", 18))
	var sh = UI.hbox(8)
	for i in 6:
		var cur = pr["slots"][i]
		var nm: String = Data.jutsu.get(cur, {}).get("name", "—") if cur != null and cur != "" else "—"
		var b = UI.button("[%d] %s" % [i + 1, nm.split(":")[-1].split("(")[0].strip_edges()], func():
			if picked != "":
				for k in 6:
					if pr["slots"][k] == picked:
						pr["slots"][k] = ""
				pr["slots"][i] = picked
			ninja_menu(main, "jutsu"), 186)
		b.clip_text = true
		b.tooltip_text = nm
		sh.add_child(b)
	v.add_child(sh)


static func _tab_skills(main: Node, body: Control) -> void:
	var pr = Game.profile
	var v = _scroll(body, 1200)
	v.add_child(UI.header("YETENEK AĞACI  — Puan: %d" % int(pr["sp"]), 22))
	var cat = ""
	for sid in SKILLS:
		var s: Array = SKILLS[sid]
		if s[2] != cat:
			cat = s[2]
			v.add_child(UI.label(cat, 18, Color(1, 0.85, 0.6)))
		var owned: bool = sid in pr["skills"]
		var can: bool = not owned and int(pr["sp"]) > 0 and int(pr["level"]) >= int(s[4]) and (s[3] == "" or s[3] in pr["skills"])
		if sid == "elem2" and int(pr["rank"]) < 2:
			can = false
		var b = UI.button("%s %s — %s  (Sv.%d)" % ["✔" if owned else "•", s[0], s[1], s[4]], func():
			if sid == "elem2":
				_pick_element(main)
				return
			pr["skills"].append(sid)
			pr["sp"] = int(pr["sp"]) - 1
			Game.player.apply_profile_stats()
			ninja_menu(main, "skills"), 760)
		b.disabled = not can
		if owned:
			b.modulate = Color(0.6, 1, 0.6)
		v.add_child(b)


static func inventory(main: Node) -> void:
	ninja_menu(main, "inv")


static func jutsu_skills(main: Node, picked := "") -> void:
	ninja_menu(main, "jutsu", picked)


static func _pick_element(main: Node) -> void:
	var pr = Game.profile
	var opts = []
	for e in ["katon", "suiton", "fuuton", "doton", "raiton"]:
		if e in pr["elements"]:
			continue
		opts.append({"label": e, "cb": func():
			pr["elements"].append(e)
			pr["skills"].append("elem2")
			pr["sp"] = int(pr["sp"]) - 1
			var starter = {"katon": "katon_goukakyuu", "suiton": "suiton_suikoudan", "fuuton": "fuuton_shinkuu", "doton": "doton_doryuusou", "raiton": "raiton_nagashi"}[e]
			Progress.learn(starter)})
	Hud.dialog("İkinci Chakra Doğası", "Hangi doğayı geliştireceksin?", opts)


# ------------------------------------------------------------------ dünya haritası + hızlı seyahat
static func world_map(main: Node) -> void:
	var bg = _full()
	var tex: Texture2D = load("res://data/world/map.png")
	var vp = bg.get_viewport_rect().size
	var scale = minf((vp.x - 80) / tex.get_width(), (vp.y - 120) / tex.get_height())
	var sz = Vector2(tex.get_width(), tex.get_height()) * scale
	var tr = TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = sz
	tr.position = (vp - sz) * 0.5 + Vector2(0, 20)
	bg.add_child(tr)
	var title = UI.label("◆ SHINOBİ DÜNYASI — keşfettiğin köylere tıkla: hızlı seyahat", 22, UI.ACCENT)
	title.position = Vector2(tr.position.x, tr.position.y - 36)
	bg.add_child(title)
	var W = Game.hw * Game.res
	var H = Game.hh * Game.res
	var to_px = func(mx: float, my: float) -> Vector2:
		return Vector2((mx - Game.x0) / W * sz.x, (Game.y1 - my) / H * sz.y)
	for c in Game.world_info["countries"]:
		var l = UI.label(c["name"], 15, Color(0.25, 0.18, 0.1))
		l.add_theme_color_override("font_outline_color", Color(1, 0.97, 0.9, 0.8))
		l.position = to_px.call(c["x"], c["y"]) + Vector2(-50, 24)
		tr.add_child(l)
	for v in Game.world_info["villages"]:
		var visited: bool = v["id"] in Game.profile.get("visited", [])
		var b = Button.new()
		b.text = ("◆ " if visited else "◇ ") + v["name"]
		b.flat = true
		b.add_theme_color_override("font_color", Color(0.75, 0.1, 0.05) if visited else Color(0.35, 0.3, 0.25))
		b.add_theme_font_size_override("font_size", 15)
		b.position = to_px.call(v["x"], v["y"]) - Vector2(8, 12)
		b.disabled = not visited
		var vid: String = v["id"]
		b.pressed.connect(func(): main.fast_travel(vid))
		tr.add_child(b)
	for l in Game.world_info["landmarks"]:
		var lb = UI.label("• " + l["name"], 12, Color(0.3, 0.25, 0.4))
		lb.position = to_px.call(l["x"], l["y"]) - Vector2(4, 8)
		tr.add_child(lb)
	var pm = Game.to_map(Game.player.global_position)
	var me = UI.label("▲ SEN", 18, Color(0.1, 0.4, 1.0))
	me.position = to_px.call(pm.x, pm.y) - Vector2(10, 10)
	tr.add_child(me)
	if Missions.has_marker:
		var mm = Game.to_map(Missions.target_marker)
		var mk = UI.label("★ HEDEF", 18, Color(0.95, 0.65, 0.0))
		mk.position = to_px.call(mm.x, mm.y) - Vector2(10, 10)
		tr.add_child(mk)
	var back = UI.button("Kapat [M]", func(): main.resume(), 200)
	back.position = Vector2(tr.position.x + sz.x - 200, tr.position.y + sz.y + 8)
	bg.add_child(back)
