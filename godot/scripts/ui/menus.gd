class_name Menus
extends RefCounted
## Tam ekran menüler (modern): bulanık oyun arka planı, sol simge rayı, cam paneller, simgeli kartlar.
## Hepsi Hud.dialog_layer'a eklenir.

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
const SKILL_ICONS := {"Taijutsu": "hand", "Ninjutsu": "chakra", "Destek": "heart"}

static var _fresh := false


static func clear() -> void:
	for c in Hud.dialog_layer.get_children():
		c.queue_free()


## Tam ekran arka plan: bulanıklaştırılmış oyun görüntüsü + koyulaştırma + vinyet
static func _full(dim := 0.55) -> Control:
	_fresh = Hud.dialog_layer.get_child_count() == 0
	clear()
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sm = ShaderMaterial.new()
	sm.shader = load("res://shaders/ui_backdrop.gdshader")
	sm.set_shader_parameter("dim", maxf(dim, 0.6))
	bg.material = sm
	Hud.dialog_layer.add_child(bg)
	if _fresh:
		bg.modulate.a = 0.0
		var tw = bg.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(bg, "modulate:a", 1.0, 0.18)
	return bg


static func _center_panel(parent: Control, w := 560.0) -> VBoxContainer:
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var p = UI.panel()
	p.custom_minimum_size = Vector2(w, 0)
	p.add_theme_stylebox_override("panel", UI.glass(18, 28))
	cc.add_child(p)
	var v = UI.vbox(12)
	p.add_child(v)
	if _fresh:
		UI.pop_in(p)
	return v


## Ekran üst köşesinde kapatma düğmesi
static func _close_button(parent: Control, cb: Callable) -> Button:
	var b = UI.button("", cb, 52, "close")
	b.custom_minimum_size = Vector2(52, 52)
	b.tooltip_text = "Kapat [Esc]"
	b.anchor_left = 1.0; b.anchor_right = 1.0
	b.offset_left = -76; b.offset_right = -24; b.offset_top = 22; b.offset_bottom = 74
	parent.add_child(b)
	return b


static func _scroll(parent: Control, w: float, h := 600.0) -> VBoxContainer:
	var sc = ScrollContainer.new()
	sc.custom_minimum_size = Vector2(w, h)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var v = UI.vbox(8)
	v.custom_minimum_size = Vector2(w - 16, 0)
	sc.add_child(v)
	return v


## Kare karo düğme: içerik (simge/3B görsel), alt yazı, nadirlik kenarı, seçili parlama
static func _tile(content: Control, text: String, accent: Color, selected: bool, cb: Callable, size := 96, badge := "") -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(size, size + (18 if text != "" else 0))
	b.add_theme_font_override("font", UI.font(true))
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_color_override("font_color", UI.MUTED)
	b.add_theme_color_override("font_hover_color", UI.TEXT)
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.clip_text = true
	var n = UI._box(Color(1, 1, 1, 0.045), Color(accent, 0.45), 1, 12, 6)
	n.content_margin_top = size - 4
	var h = n.duplicate()
	h.bg_color = Color(1, 1, 1, 0.1)
	h.border_color = Color(accent, 0.9)
	var s = n.duplicate()
	s.bg_color = Color(UI.GOLD, 0.16)
	s.border_color = UI.GOLD
	s.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", s if selected else n)
	b.add_theme_stylebox_override("hover", s if selected else h)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_stylebox_override("focus", s if selected else h)
	# nadirlik şeridi (alt)
	var strip = ColorRect.new()
	strip.color = Color(accent, 0.85)
	strip.anchor_left = 0.0; strip.anchor_right = 1.0
	strip.offset_left = 12; strip.offset_right = -12; strip.offset_top = size - 6; strip.offset_bottom = size - 4
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(strip)
	var cc = CenterContainer.new()
	cc.position = Vector2(0, 4)
	cc.size = Vector2(size, size - 10)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cc)
	content.custom_minimum_size = Vector2(size - 24, size - 24)
	cc.add_child(content)
	if badge != "":
		var bl = UI.label(badge, 13, UI.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, true)
		bl.position = Vector2(4, 4)
		bl.size = Vector2(size - 10, 18)
		b.add_child(bl)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.8, 0.15))
	return b


static func _swatch(c: Color, on: bool, cb: Callable) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(34, 34)
	var sb = UI._box(c, Color(1, 1, 1, 0.95) if on else Color(1, 1, 1, 0.15), 3 if on else 1, 17, 0)
	var sh = sb.duplicate()
	sh.border_color = UI.GOLD
	sh.set_border_width_all(2)
	for st in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("hover", sh)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


# ================================================================== ana menü
static func main_menu(main: Node) -> void:
	clear()
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.dialog_layer.add_child(root)
	# soldan sağa koyulaşan degrade
	var grad = TextureRect.new()
	var gt = GradientTexture2D.new()
	var g = Gradient.new()
	g.set_color(0, Color(0.02, 0.025, 0.04, 0.92))
	g.set_color(1, Color(0.02, 0.025, 0.04, 0.0))
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	grad.texture = gt
	grad.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	grad.offset_right = 900
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grad)
	var col = UI.vbox(0)
	col.position = Vector2(110, 120)
	root.add_child(col)
	var kanji = UI.label("忍 の 道", 22, Color(UI.GOLD, 0.9), HORIZONTAL_ALIGNMENT_LEFT, true)
	col.add_child(kanji)
	var logo = UI.label("SHINOBI", 112, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	logo.add_theme_constant_override("line_spacing", -20)
	col.add_child(logo)
	var logo2 = UI.label("Y O L U", 40, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	col.add_child(logo2)
	col.add_child(UI.spacer(0, 14, false))
	col.add_child(UI.label("Beş Büyük Ülke'nin dünyasında kendi efsaneni yaz.", 19, UI.MUTED))
	col.add_child(UI.spacer(0, 54, false))
	var items = [["Yeni Oyun", "play", func(): slot_select(main, true)], ["Devam Et", "save", func(): slot_select(main, false)],
		["Ayarlar", "settings", func(): settings(func(): main_menu(main))], ["Çıkış", "exit", func(): main.get_tree().quit()]]
	for i in items.size():
		var b = _menu_entry(items[i][0], items[i][1], items[i][2])
		col.add_child(b)
		UI.slide_in(b, -30.0, 0.05 * i)
	var ver = UI.label("v%s %s   •   Kanon karakter içermez; Naruto evreninde geçen özgün bir hikâye." % [Game.version, "(TEST)" if Game.build_tag == "test" else ""], 13, Color(UI.MUTED, 0.8))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(110, -44)
	root.add_child(ver)


## Ana menü satırı: sade yazı, üzerine gelince altın çizgi kayar
static func _menu_entry(text: String, icon: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.icon = Icons.tex(icon)
	b.add_theme_constant_override("icon_max_width", 26)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(420, 62)
	b.add_theme_font_override("font", UI.font(true))
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", Color(UI.TEXT, 0.82))
	b.add_theme_color_override("font_hover_color", UI.GOLD)
	b.add_theme_color_override("font_focus_color", UI.GOLD)
	b.add_theme_color_override("icon_normal_color", Color(UI.TEXT, 0.6))
	b.add_theme_color_override("icon_hover_color", UI.GOLD)
	b.add_theme_color_override("icon_focus_color", UI.GOLD)
	b.add_theme_constant_override("h_separation", 18)
	var n = StyleBoxEmpty.new()
	n.content_margin_left = 6
	var h = UI._box(Color(1, 1, 1, 0.0), Color(0, 0, 0, 0), 0, 0, 0)
	h.content_margin_left = 22
	h.border_width_left = 3
	h.border_color = UI.GOLD
	h.bg_color = Color(1, 1, 1, 0.04)
	for k in [["normal", n], ["hover", h], ["pressed", h], ["focus", h]]:
		b.add_theme_stylebox_override(k[0], k[1])
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.8, 0.2))
	return b


static func slot_select(main: Node, new_game: bool) -> void:
	var bg = _full(0.65)
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(cc)
	var root = UI.vbox(28)
	cc.add_child(root)
	root.add_child(UI.header("YENİ OYUN — BİR KAYIT YUVASI SEÇ" if new_game else "KAYITLI OYUNU YÜKLE", 28))
	var row = UI.hbox(22)
	root.add_child(row)
	for s in [1, 2, 3]:
		var info = Game.slot_summary(s)
		var card = Button.new()
		card.text = "Yuva %d" % s
		card.custom_minimum_size = Vector2(320, 360)
		# düğme yazısı test/erişilebilirlik için durur ama görünmez; içerik elle yerleştirilir
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
			card.add_theme_color_override(k, Color(0, 0, 0, 0))
		var n = UI.glass(16, 26, 0.75)
		var h = n.duplicate()
		h.border_color = UI.GOLD
		h.bg_color = Color(0.1, 0.11, 0.14, 0.9)
		for k in [["normal", n], ["hover", h], ["focus", h], ["pressed", h], ["disabled", n]]:
			card.add_theme_stylebox_override(k[0], k[1])
		var ic = Icons.view("person" if info != "" else "plus", 96, UI.GOLD if info != "" else Color(UI.TEXT, 0.3))
		ic.position = Vector2(112, 56)
		card.add_child(ic)
		var tl = UI.label("YUVA %d" % s, 26, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
		tl.position = Vector2(0, 182)
		tl.size = Vector2(320, 34)
		card.add_child(tl)
		var parts = info.split("(") if info != "" else []
		var dl = UI.label(parts[0].strip_edges() if info != "" else "Boş yuva", 16, UI.GOLD if info != "" else UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.position = Vector2(20, 226)
		dl.size = Vector2(280, 50)
		card.add_child(dl)
		var dd = UI.label(("(" + parts[1]) if parts.size() > 1 else ("Yeni bir hikâye başlat" if new_game else ""), 13, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		dd.position = Vector2(20, 290)
		dd.size = Vector2(280, 20)
		card.add_child(dd)
		card.pressed.connect(func():
			Sfx.play("click")
			if new_game:
				main.start_creator(s)
			elif info != "":
				main.load_slot(s))
		if not new_game and info == "":
			card.disabled = true
		UI.hover_anim(card, 1.025)
		row.add_child(card)
	var back = UI.button("Geri", func(): main_menu(main), 200, "arrow")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(back)


# ================================================================== karakter yaratma
static var _ctab := "kimlik"


static func creator(main: Node, state: Dictionary, on_change: Callable, on_start: Callable) -> void:
	clear()
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Hud.dialog_layer.add_child(root)
	var redraw = func(): creator(main, state, on_change, on_start)
	# sol panel: kategori rayı + seçenekler
	var pnl = PanelContainer.new()
	pnl.add_theme_stylebox_override("panel", UI.glass(18, 22, 0.86))
	pnl.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	pnl.offset_left = 28; pnl.offset_top = 28; pnl.offset_bottom = -28; pnl.offset_right = 668
	root.add_child(pnl)
	var hv = UI.hbox(16)
	pnl.add_child(hv)
	var rail = UI.vbox(8)
	hv.add_child(rail)
	for t in [["kimlik", "person", "Kimlik"], ["gorunum", "hair", "Görünüm"], ["kiyafet", "shirt", "Kıyafet"]]:
		rail.add_child(UI.icon_button(t[1], t[2], func():
			_ctab = t[0]
			redraw.call(), 84, _ctab == t[0]))
	var v = _scroll(hv, 520, 0)
	v.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(UI.header("KARAKTERİNİ YARAT", 26))
	var chips = func(title: String, key: String, options: Array, labels: Array, rebuild := false) -> void:
		v.add_child(UI.label(title, 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		var fl = HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 8)
		fl.add_theme_constant_override("v_separation", 8)
		for i in options.size():
			fl.add_child(UI.chip(labels[i], options[i] == state.get(key), func():
				state[key] = options[i]
				if key == "village" and Progress.HOME_VILLAGES.has(options[i]):
					state["element"] = Progress.HOME_VILLAGES[options[i]]["element"]
				on_change.call()
				redraw.call()))
		v.add_child(fl)
	var swatches = func(title: String, key: String, cols: Array) -> void:
		v.add_child(UI.label(title, 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		var fl = HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 8)
		for c in cols:
			fl.add_child(_swatch(c, Color(state.get(key, Color.BLACK)).is_equal_approx(c), func():
				state[key] = c
				on_change.call()
				redraw.call()))
		v.add_child(fl)
	match _ctab:
		"kimlik":
			v.add_child(UI.label("İsim", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
			var name_edit = LineEdit.new()
			name_edit.text = state["name"]
			name_edit.placeholder_text = "Ninja adın"
			name_edit.max_length = 18
			name_edit.custom_minimum_size = Vector2(0, 46)
			name_edit.add_theme_font_size_override("font_size", 20)
			name_edit.text_changed.connect(func(t): state["name"] = t)
			v.add_child(name_edit)
			chips.call("Cinsiyet", "gender", ["m", "f"], ["Erkek", "Kadın"])
			if true:
				var vids = Progress.HOME_VILLAGES.keys()
				chips.call("Köy", "village", vids, vids.map(func(x): return Game.village(x).get("name", x)))
				var vinfo = Progress.HOME_VILLAGES.get(state.get("village", "konoha"), {})
				v.add_child(UI.label("%s  •  Önerilen doğa: %s" % [vinfo.get("kage", ""), String(vinfo.get("element", "katon")).capitalize()], 13, UI.MUTED))
			var clan_ids: Array = Data.clans.keys()
			chips.call("Klan", "clan", clan_ids, clan_ids.map(func(c): return Data.clans[c]["name"]))
			var cd = UI.label(Data.clans.get(state["clan"], {}).get("desc", ""), 14, UI.MUTED)
			cd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cd.custom_minimum_size = Vector2(480, 0)
			v.add_child(cd)
			chips.call("Chakra Doğası", "element", ["katon", "suiton", "fuuton", "doton", "raiton"], ["Ateş", "Su", "Rüzgar", "Toprak", "Yıldırım"])
		"gorunum":
			swatches.call("Ten", "skin", [Color(0.98, 0.88, 0.8), Color(0.96, 0.8, 0.66), Color(0.86, 0.68, 0.52), Color(0.68, 0.5, 0.36), Color(0.5, 0.36, 0.26)])
			chips.call("Saç Stili", "hair_style", ["diken", "kısa", "uzun", "atkuyruğu", "kase", "dağınık"], ["Dikenli", "Kısa", "Uzun", "At kuyruğu", "Kâse", "Dağınık"])
			swatches.call("Saç Rengi", "hair", [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.9, 0.92), Color(0.2, 0.3, 0.6), Color(0.9, 0.55, 0.7), Color(0.25, 0.45, 0.25)])
			if not state["clan"] in ["uchiha", "hyuga", "aburame"]:
				swatches.call("Göz Rengi", "eye", [Color(0.25, 0.45, 0.8), Color(0.3, 0.2, 0.12), Color(0.25, 0.55, 0.3), Color(0.1, 0.1, 0.1), Color(0.6, 0.4, 0.15)])
		"kiyafet":
			chips.call("Üst", "top_style", CharacterModel.TOP_STYLES.keys(), CharacterModel.TOP_STYLES.values())
			chips.call("Alt", "pants_style", CharacterModel.PANTS_STYLES.keys(), CharacterModel.PANTS_STYLES.values())
			var outfit_cols = [Color(0.15, 0.2, 0.33), Color(0.15, 0.15, 0.17), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22), Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45)]
			swatches.call("Üst Rengi", "top", outfit_cols)
			swatches.call("Vurgu Rengi", "top2", outfit_cols)
			swatches.call("Alt Rengi", "pants", outfit_cols)
	# sağ alt: eylemler
	var bar = UI.hbox(12)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.position = Vector2(-560, -96)
	root.add_child(bar)
	bar.add_child(UI.button("Geri", func(): main.back_to_menu(), 160, "arrow"))
	bar.add_child(UI.primary("Maceraya Başla!", on_start, 340, "play"))
	var hint = UI.icon_label("person", "Fareyle sürükleyerek karakteri döndür", 14, UI.MUTED)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position = Vector2(-460, -136)
	root.add_child(hint)


# ================================================================== duraklatma
static func pause(main: Node) -> void:
	var bg = _full(0.6)
	var root = UI.vbox(6)
	root.position = Vector2(110, 110)
	bg.add_child(root)
	root.add_child(UI.label("DURAKLATILDI", 15, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(UI.label(String(Game.profile.get("name", "")), 54, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(UI.label("%s  •  %s" % [Data.RANKS[int(Game.profile.get("rank", 0))], Game.region_name(Game.player.global_position) if Game.player else ""], 17, UI.MUTED))
	root.add_child(UI.spacer(0, 26, false))
	var items = [["Devam", "play", func(): main.resume()], ["Ninja Menüsü", "bag", func(): ninja_menu(main, "inv")],
		["Ekipman ve Kıyafetler", "armor", func(): ninja_menu(main, "wardrobe")], ["Jutsu ve Yetenekler", "scroll", func(): ninja_menu(main, "jutsu")],
		["Dünya Haritası", "map", func(): world_map(main)], ["Ayarlar", "settings", func(): settings(func(): pause(main))],
		["Kaydet", "save", func():
			Game.save_game()
			Hud.msg("Oyun kaydedildi.", Color(0.6, 1, 0.6))], ["Kontroller", "controls", func(): controls(main)],
		["Ana Menüye Dön (kaydeder)", "home", func(): main.to_main_menu()], ["Oyundan Çık (kaydeder)", "exit", func():
			Game.save_game()
			main.get_tree().quit()]]
	for i in items.size():
		var b = _menu_entry(items[i][0], items[i][1], items[i][2])
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(440, 50)
		root.add_child(b)
		if _fresh:
			UI.slide_in(b, -24.0, 0.025 * i)


static func controls(main: Node) -> void:
	var bg = _full()
	var v = _center_panel(bg, 980)
	v.add_child(UI.header("KONTROLLER", 26))
	var rows = [["WASD", "Hareket"], ["Fare", "Kamera"], ["Space", "Zıpla / çift zıplama"], ["Ctrl (basılı)", "Süper zıplama (Shinobi Striker)"],
		["Shift", "Ninja koşusu, havada dash"], ["Duvara koş", "Duvarda koşu"], ["Sol tık", "Kombo / dalış tekmesi"], ["Sağ tık", "Blok (tam zamanında: mükemmel blok)"],
		["Q", "Kawarimi"], ["C (basılı)", "Chakra şarjı"], ["R / T", "Alet fırlat / değiştir"], ["E / orta tık", "Hedefe kilitlen"],
		["1-6", "Jutsu slotları"], ["F", "Etkileşim"], ["H / Y", "Merhem / Asker hapı"], ["G + 1-9,0,-,=", "Mühür ör"],
		["V", "Göz tekniği (basılı: Susanoo)"], ["Z / X", "Sağ / sol göz tekniği (gözler açıkken)"], ["B", "Sekiz Kapı"], ["Tab", "Ninja menüsü"],
		["K", "Jutsular"], ["M", "Harita"], ["Esc", "Menü"]]
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	for r in rows:
		var h = UI.hbox(12)
		var kb = UI.key_badge(r[0], 13)
		kb.custom_minimum_size = Vector2(130, 0)
		h.add_child(kb)
		h.add_child(UI.label(r[1], 15))
		grid.add_child(h)
	v.add_child(grid)
	v.add_child(UI.button("Geri", func(): pause(main), 200, "arrow"))


# ================================================================== ayarlar
static func settings(back: Callable) -> void:
	var bg = _full()
	var v = _center_panel(bg, 640)
	v.add_child(UI.header("AYARLAR", 26))
	var s = Game.settings
	var group = func(icon: String, title: String) -> VBoxContainer:
		var c = UI.card()
		var gv = UI.vbox(8)
		c.add_child(gv)
		gv.add_child(UI.icon_label(icon, title, 16, UI.GOLD))
		v.add_child(c)
		return gv
	var slider = func(gv: VBoxContainer, title: String, key: String, mn: float, mx: float, step: float) -> void:
		var h = UI.hbox(12)
		var l = UI.label(title, 15)
		l.custom_minimum_size = Vector2(200, 0)
		var val = UI.label("%.2f" % s[key], 15, UI.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, true)
		val.custom_minimum_size = Vector2(60, 0)
		var sl = HSlider.new()
		sl.min_value = mn; sl.max_value = mx; sl.step = step; sl.value = s[key]
		sl.custom_minimum_size = Vector2(300, 24)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.value_changed.connect(func(x):
			s[key] = x
			val.text = "%.2f" % x)
		h.add_child(l); h.add_child(sl); h.add_child(val)
		gv.add_child(h)
	var check = func(gv: Container, title: String, key: String) -> void:
		var c = CheckBox.new()
		c.text = title
		c.button_pressed = s[key]
		c.toggled.connect(func(x): s[key] = x)
		gv.add_child(c)
	var g1 = group.call("controls", "Kontrol")
	slider.call(g1, "Fare hassasiyeti", "sens", 0.2, 3.0, 0.05)
	check.call(g1, "Fareyi ters çevir (Y)", "invert_y")
	var g2 = group.call("monitor", "Görüntü")
	var qr = UI.hbox(8)
	var ql = UI.label("Grafik kalitesi", 15)
	ql.custom_minimum_size = Vector2(150, 0)
	qr.add_child(ql)
	for qi in 3:
		qr.add_child(UI.chip(Game.QUALITY_NAMES[qi], int(s.get("quality", 2)) == qi, func():
			Game.set_quality(qi)
			settings(back)))
	g2.add_child(qr)
	slider.call(g2, "Görüş alanı (FOV)", "fov", 55.0, 100.0, 1.0)
	slider.call(g2, "Görüş mesafesi", "view", 0.5, 1.6, 0.05)
	var gr = HFlowContainer.new()
	gr.add_theme_constant_override("h_separation", 18)
	g2.add_child(gr)
	for opt in [["Tam ekran", "fullscreen"], ["Gölgeler", "shadows"], ["Anime çizgileri", "outline"], ["FPS göster", "show_fps"]]:
		check.call(gr, opt[0], opt[1])
	var g3 = group.call("sound", "Ses")
	slider.call(g3, "Müzik", "music", 0.0, 1.0, 0.05)
	slider.call(g3, "Efektler", "sfx", 0.0, 1.0, 0.05)
	v.add_child(UI.primary("Kaydet ve Geri", func():
		Game.save_settings()
		if Game.player:
			Game.player.cam.fov = s["fov"]
		if Game.world:
			Game.apply_graphics()
		Sfx.music_a.volume_db = linear_to_db(maxf(0.001, float(s["music"]) * 0.6))
		back.call(), 584, "check"))


# ================================================================== ninja menüsü [Tab]
const TABS := [["inv", "bag", "Envanter"], ["wardrobe", "armor", "Ekipman"], ["jutsu", "scroll", "Jutsular"], ["skills", "star", "Yetenekler"],
	["missions", "mission", "Görevler"], ["map", "map", "Harita"]]
const TAB_TITLES := {"inv": "ENVANTER", "wardrobe": "EKİPMAN", "jutsu": "JUTSULAR", "skills": "YETENEK AĞACI", "missions": "GÖREVLER"}
const SWATCHES := [Color(0.15, 0.2, 0.33), Color(0.12, 0.12, 0.14), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22),
	Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45), Color(0.55, 0.42, 0.3), Color(0.75, 0.2, 0.25)]


static func ninja_menu(main: Node, tab := "inv", picked := "") -> void:
	if tab == "map":
		world_map(main)
		return
	var bg = _full(0.5)
	var pr = Game.profile
	# sol ray
	var rail_bg = Panel.new()
	var rsb = UI._box(Color(0.03, 0.035, 0.05, 0.7), Color(0, 0, 0, 0), 0, 0, 0)
	rsb.border_width_right = 1
	rsb.border_color = UI.LINE
	rail_bg.add_theme_stylebox_override("panel", rsb)
	rail_bg.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	rail_bg.offset_right = 112
	bg.add_child(rail_bg)
	var rail = UI.vbox(10)
	rail.position = Vector2(14, 104)
	rail_bg.add_child(rail)
	var emb = Icons.view("leaf", 44, UI.GOLD)
	emb.position = Vector2(34, 30)
	rail_bg.add_child(emb)
	for t in TABS:
		rail.add_child(UI.icon_button(t[1], t[2], func(): ninja_menu(main, t[0]), 84, t[0] == tab))
	# üst çubuk: başlık + oyuncu bilgisi
	var title = UI.label(TAB_TITLES.get(tab, ""), 34, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	title.position = Vector2(150, 30)
	bg.add_child(title)
	var info = UI.hbox(18)
	info.anchor_left = 1.0; info.anchor_right = 1.0
	info.offset_left = -720; info.offset_right = -110; info.offset_top = 36
	info.alignment = BoxContainer.ALIGNMENT_END
	bg.add_child(info)
	info.add_child(UI.icon_label("person", "%s  •  %s  •  Sv.%d" % [pr["name"], Data.RANKS[int(pr["rank"])], int(pr["level"])], 16, UI.TEXT))
	info.add_child(UI.icon_label("coin", "%d Ryō" % int(pr["ryo"]), 16, UI.GOLD))
	_close_button(bg, func(): main.resume())
	# içerik
	var body = Control.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 150; body.offset_top = 100; body.offset_right = -40; body.offset_bottom = -54
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(body)
	match tab:
		"inv":
			_tab_inventory(main, body)
		"wardrobe":
			_tab_wardrobe(main, body)
		"jutsu":
			_tab_jutsu(main, body, picked)
		"skills":
			_tab_skills(main, body)
		"missions":
			_tab_missions(main, body)
	if _fresh:
		UI.pop_in(body, 0.985)
	# alt ipucu satırı
	var foot = UI.hbox(8)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.position = Vector2(150, -42)
	bg.add_child(foot)
	for k in [["Tab", "kapat"], ["I", "envanter"], ["K", "jutsular"], ["M", "harita"]]:
		foot.add_child(UI.key_badge(k[0], 12))
		foot.add_child(UI.label(k[1] + "    ", 13, UI.MUTED))


# ------------------------------------------------------------------ envanter
static var _inv_filter := "all"
static var _inv_sel := ""


static func _tab_inventory(main: Node, body: Control) -> void:
	var pr = Game.profile
	var h = UI.hbox(28)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	var left = UI.vbox(14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	var chips = UI.hbox(8)
	left.add_child(chips)
	for f in [["all", "Tümü"], ["throw", "Aletler"], ["use", "Tüketilebilir"], ["scroll", "Parşömenler"], ["gear", "Ekipman"]]:
		chips.add_child(UI.chip(f[1], _inv_filter == f[0], func():
			_inv_filter = f[0]
			ninja_menu(main, "inv")))
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	var entries = []
	var inv: Dictionary = pr["inventory"]
	for id in inv.keys():
		if int(inv[id]) <= 0:
			continue
		var it: Dictionary = Data.items.get(id, {"name": id, "desc": "", "kind": "misc"})
		var kind = String(it.get("kind", "misc"))
		if _inv_filter in ["all", kind]:
			entries.append({"type": "item", "id": id, "name": it["name"], "count": int(inv[id]), "kind": kind, "desc": it.get("desc", "")})
	if _inv_filter in ["all", "gear"]:
		Gear.ensure(pr)
		var counts = {}
		for g in pr.get("gear", []):
			counts[g["id"]] = int(counts.get(g["id"], 0)) + 1
		for gid in counts:
			var gi = Gear.item(gid)
			if gi.is_empty():
				continue
			entries.append({"type": "gear", "id": gid, "name": gi["name"], "count": counts[gid], "kind": "gear", "desc": gi.get("desc", "")})
	if _inv_sel == "" and not entries.is_empty():
		_inv_sel = entries[0]["id"]
	var sel = {}
	for e in entries:
		var view = Thumbs.gear_view(e["id"], 72) if e["type"] == "gear" else Thumbs.item_view(e["id"], 72)
		var acc = UI.RARITY[UI.rarity_of_gear(e["id"])] if e["type"] == "gear" else UI.RARITY[0]
		grid.add_child(_tile(view, e["name"], acc, e["id"] == _inv_sel, func():
			_inv_sel = e["id"]
			ninja_menu(main, "inv"), 104, "x%d" % e["count"] if e["count"] > 1 else ""))
		if e["id"] == _inv_sel:
			sel = e
	if entries.is_empty():
		left.add_child(UI.label("Bu kategoride eşya yok.", 16, UI.MUTED))
	# sağ: ayrıntı + durum
	var right = UI.vbox(16)
	right.custom_minimum_size = Vector2(420, 0)
	h.add_child(right)
	var dc = UI.card()
	dc.custom_minimum_size = Vector2(420, 300)
	right.add_child(dc)
	var dv = UI.vbox(10)
	dc.add_child(dv)
	if sel.is_empty():
		dv.add_child(UI.label("Bir eşya seç.", 16, UI.MUTED))
	else:
		var top = UI.hbox(16)
		var big = Thumbs.gear_view(sel["id"], 96) if sel["type"] == "gear" else Thumbs.item_view(sel["id"], 96)
		top.add_child(big)
		var tv = UI.vbox(4)
		tv.add_child(UI.label(sel["name"], 24, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		if sel["type"] == "gear":
			var r = UI.rarity_of_gear(sel["id"])
			tv.add_child(UI.label(UI.RARITY_NAMES[r], 14, UI.RARITY[r], HORIZONTAL_ALIGNMENT_LEFT, true))
			tv.add_child(UI.label(Gear.stats_text(sel["id"]), 14, UI.GOOD))
		tv.add_child(UI.label("Adet: %d" % sel["count"], 14, UI.MUTED))
		top.add_child(tv)
		dv.add_child(top)
		var d = UI.label(sel["desc"], 15, UI.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(380, 0)
		dv.add_child(d)
		if sel["kind"] == "throw":
			var on: bool = pr["throw_sel"] == sel["id"]
			var b = UI.primary("Kuşanıldı" if on else "Kuşan [R]", func():
				pr["throw_sel"] = sel["id"]
				ninja_menu(main, "inv"), 380, "check" if on else "kunai")
			b.disabled = on
			dv.add_child(b)
		elif sel["kind"] == "use":
			dv.add_child(UI.primary("Kullan", func():
				main.use_item(sel["id"])
				ninja_menu(main, "inv"), 380, "potion"))
		elif sel["type"] == "gear":
			dv.add_child(UI.button("Ekipmanda göster", func(): ninja_menu(main, "wardrobe"), 380, "armor"))
	# durum kartı
	var st = UI.card()
	right.add_child(st)
	var sv = UI.vbox(8)
	st.add_child(sv)
	var pl = Game.player
	var stat_row = func(icon: String, name: String, val: String, col := UI.TEXT) -> void:
		var r = UI.hbox(10)
		r.add_child(Icons.view(icon, 20, UI.GOLD))
		var l = UI.label(name, 15, UI.MUTED)
		l.custom_minimum_size = Vector2(150, 0)
		r.add_child(l)
		r.add_child(UI.label(val, 15, col, HORIZONTAL_ALIGNMENT_LEFT, true))
		sv.add_child(r)
	if pl:
		stat_row.call("heart", "Can", "%d / %d" % [int(pl.hp), int(pl.max_hp)], UI.GOOD)
		stat_row.call("chakra", "Chakra", "%d / %d" % [int(pl.chakra), int(pl.max_chakra)], Color(0.5, 0.75, 1.0))
	stat_row.call("star", "Seviye", "%d  (XP %d)" % [int(pr["level"]), int(pr["xp"])])
	stat_row.call("leaf", "Klan", Data.clans.get(pr["clan"], {}).get("name", "Klansız"))
	stat_row.call(UI.ELEMENT_ICONS.get(String(pr["elements"][0]) if not pr["elements"].is_empty() else "", "chakra"), "Chakra doğası", ", ".join(pr["elements"]).capitalize())
	stat_row.call("plus", "Yetenek puanı", str(int(pr["sp"])))
	var md: Dictionary = pr["missions_done"]
	stat_row.call("mission", "Görevler", "D%d  C%d  B%d  A%d  S%d" % [md.get("D", 0), md.get("C", 0), md.get("B", 0), md.get("A", 0), md.get("S", 0)])


# ------------------------------------------------------------------ ekipman (karakter etrafında yuvalar)
static var _eq_slot := "govde"
const DOLL_LEFT := ["kafa", "sag_goz", "sol_goz", "yuz", "govde", "bacak", "ayak"]
const DOLL_RIGHT := ["zirh", "dis", "kol", "sirt", "sag", "sol"]


static func _slot_name(sl: String) -> String:
	for s in Gear.SLOTS:
		if s[0] == sl:
			return s[1]
	return {"sac": "Saç", "susanoo": "Susanoo"}.get(sl, sl)


static func _tab_wardrobe(main: Node, body: Control) -> void:
	var pr = Game.profile
	Gear.ensure(pr)
	var refresh = func() -> void:
		Gear.apply_look(pr)
		if Game.player:
			Game.player.rebuild_model()
			Game.player.apply_profile_stats()
		ninja_menu(main, "wardrobe")
	var h = UI.hbox(26)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	# --- sol: karakter + çevresindeki yuvalar
	var doll = Control.new()
	doll.custom_minimum_size = Vector2(860, 740)
	doll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(doll)
	var preview: Control
	if _eq_slot == "susanoo":
		preview = _susanoo_preview(pr)
	else:
		preview = _model_preview(Game.player._look_with_age() if Game.player else pr["look"])
	preview.position = Vector2(250, 0)
	preview.size = Vector2(360, 700)
	preview.custom_minimum_size = Vector2(360, 700)
	doll.add_child(preview)
	# zemin halkası
	var ring = Control.new()
	ring.position = Vector2(250, 600)
	ring.size = Vector2(360, 100)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(func():
		ring.draw_arc(Vector2(180, 60), 150, 0, TAU, 64, Color(UI.GOLD, 0.25), 2.0, true)
		ring.draw_arc(Vector2(180, 60), 110, 0, TAU, 64, Color(UI.GOLD, 0.12), 1.0, true))
	doll.add_child(ring)
	ring.scale = Vector2(1, 0.35)
	ring.position.y = 660
	var make_slot = func(sl: String, pos: Vector2, name_left: bool) -> void:
		var g = Gear.equipped(pr, sl) if not sl in ["sac", "susanoo"] else {}
		var view: Control
		var acc = Color(1, 1, 1, 0.2)
		var item_name = ""
		if sl == "sac":
			view = Icons.view("hair", 44, Color(pr["look"].get("hair", UI.TEXT)).lightened(0.2))
			item_name = String(pr["look"].get("hair_style", "")).capitalize()
		elif sl == "susanoo":
			view = Icons.view("susanoo", 44, Color(0.7, 0.55, 1.0))
			item_name = "Kademe %d" % Susanoo.cur_tier(pr)
		elif g.is_empty():
			view = Icons.view(Thumbs.SLOT_ICONS.get(sl, "info"), 40, Color(1, 1, 1, 0.18))
		else:
			view = Thumbs.gear_view(g["id"], 56, Color.html(g["c1"]))
			acc = UI.RARITY[UI.rarity_of_gear(g["id"])]
			item_name = Gear.item(g["id"])["name"]
		var t = _tile(view, _slot_name(sl), acc, sl == _eq_slot, func():
			_eq_slot = sl
			ninja_menu(main, "wardrobe"), 76)
		t.position = pos
		t.tooltip_text = item_name if item_name != "" else "Boş"
		doll.add_child(t)
		if item_name != "":
			var nl = UI.label(item_name, 13, Color(acc, 1.0) if acc.a > 0.5 else UI.MUTED, HORIZONTAL_ALIGNMENT_RIGHT if name_left else HORIZONTAL_ALIGNMENT_LEFT)
			nl.size = Vector2(150, 20)
			nl.position = pos + (Vector2(-158, 30) if name_left else Vector2(84, 30))
			nl.clip_text = true
			doll.add_child(nl)
	for i in DOLL_LEFT.size():
		make_slot.call(DOLL_LEFT[i], Vector2(160, 4 + i * 100), true)
	for i in DOLL_RIGHT.size():
		make_slot.call(DOLL_RIGHT[i], Vector2(624, 4 + i * 100), false)
	make_slot.call("sac", Vector2(624, 4 + 6 * 100), false)
	if Susanoo.max_tier(pr) > 0:
		make_slot.call("susanoo", Vector2(392, 620), false)
	# toplam istatistikler (karakterin üstünde)
	var tot = []
	for k in [["def", "Savunma", false], ["hp", "Can", false], ["chakra", "Chakra", false], ["speed", "Hız", true], ["melee", "Yakın dövüş", true]]:
		var v = Gear.stat(pr, k[0])
		if v != 0.0:
			tot.append(("%s %+d%%" % [k[1], int(round(v * 100))]) if k[2] else ("%s %+d" % [k[1], int(v)]))
	tot.append("Silah x%.2f" % Gear.weapon(pr)["dmg"])
	var tl = UI.label("  •  ".join(tot), 13, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	tl.position = Vector2(220, -26)
	tl.size = Vector2(420, 20)
	doll.add_child(tl)
	# --- sağ: seçili yuvanın çekmecesi
	var drawer = PanelContainer.new()
	drawer.add_theme_stylebox_override("panel", UI.glass(16, 20, 0.7))
	drawer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(drawer)
	var dv = _scroll(drawer, 520, 680)
	dv.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(UI.header(_slot_name(_eq_slot).to_upper(), 22))
	if _eq_slot == "sac":
		_hair_panel(dv, pr["look"], refresh)
		return
	if _eq_slot == "susanoo":
		_susanoo_panel(main, dv, null)
		return
	var cur = Gear.equipped(pr, _eq_slot)
	var list = Gear.owned_for(pr, _eq_slot)
	if list.is_empty():
		dv.add_child(UI.label("Bu yuvaya uygun eşyan yok. Dükkânlardan alabilir, görevlerden kazanabilirsin.", 15, UI.MUTED))
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	dv.add_child(grid)
	var detail = UI.card()
	var detail_v = UI.vbox(8)
	detail.add_child(detail_v)
	var show_detail = func(g: Dictionary) -> void:
		for c in detail_v.get_children():
			c.queue_free()
		if g.is_empty():
			detail_v.add_child(UI.label("Boş yuva", 15, UI.MUTED))
			return
		var it = Gear.item(g["id"])
		var r = UI.rarity_of_gear(g["id"])
		var row = UI.hbox(14)
		row.add_child(Thumbs.gear_view(g["id"], 72, Color.html(g["c1"])))
		var tv = UI.vbox(2)
		tv.add_child(UI.label(it["name"], 21, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		tv.add_child(UI.label(UI.RARITY_NAMES[r] + ("   •   takılı" if not cur.is_empty() and int(cur["uid"]) == int(g["uid"]) else ""), 13, UI.RARITY[r], HORIZONTAL_ALIGNMENT_LEFT, true))
		row.add_child(tv)
		detail_v.add_child(row)
		# istatistik karşılaştırması
		var mine = it.get("stats", {})
		var theirs = Gear.item(cur["id"]).get("stats", {}) if not cur.is_empty() else {}
		var names = {"def": "Savunma", "hp": "Can", "chakra": "Chakra", "speed": "Hız", "melee": "Yakın dövüş"}
		for k in names:
			var a = float(mine.get(k, 0.0)); var b = float(theirs.get(k, 0.0))
			if a == 0.0 and b == 0.0:
				continue
			var pct = k in ["speed", "melee"]
			var txt = ("%+d%%" % int(round(a * 100))) if pct else ("%+d" % int(a))
			var diff = a - b
			var dtxt = ""
			if not cur.is_empty() and int(cur["uid"]) != int(g["uid"]) and absf(diff) > 0.0001:
				dtxt = ("  (%+d%%)" % int(round(diff * 100))) if pct else ("  (%+d)" % int(diff))
			var sr = UI.hbox(6)
			var nl = UI.label(names[k], 14, UI.MUTED)
			nl.custom_minimum_size = Vector2(130, 0)
			sr.add_child(nl)
			sr.add_child(UI.label(txt, 14, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
			if dtxt != "":
				sr.add_child(UI.label(dtxt, 14, UI.GOOD if diff > 0 else UI.BAD, HORIZONTAL_ALIGNMENT_LEFT, true))
			detail_v.add_child(sr)
		if it.has("weapon"):
			detail_v.add_child(UI.label("Hasar x%.2f   •   Menzil +%.1f m   •   %s" % [it["weapon"]["dmg"], it["weapon"]["reach"], String(it["weapon"].get("style", "")).capitalize()], 14, UI.GOLD))
		var d = UI.label(it.get("desc", ""), 14, UI.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(460, 0)
		detail_v.add_child(d)
		var on = not cur.is_empty() and int(cur["uid"]) == int(g["uid"])
		if on:
			if not _eq_slot in Gear.REQUIRED:
				detail_v.add_child(UI.button("Çıkar", func():
					pr["equip"].erase(_eq_slot)
					refresh.call(), 460, "close"))
		else:
			detail_v.add_child(UI.primary("Giy / Kuşan", func():
				pr["equip"][_eq_slot] = int(g["uid"])
				refresh.call(), 460, "check"))
	for g in list:
		var it = Gear.item(g["id"])
		var used_other = false
		for sl in Gear.SLOTS:
			if sl[0] != _eq_slot and int(pr["equip"].get(sl[0], -1)) == int(g["uid"]):
				used_other = true
		var on = not cur.is_empty() and int(cur["uid"]) == int(g["uid"])
		var t = _tile(Thumbs.gear_view(g["id"], 60, Color.html(g["c1"])), it["name"], UI.RARITY[UI.rarity_of_gear(g["id"])], on, func():
			if used_other:
				Hud.msg("Bu eşya diğer elde takılı.", Color(1, 0.8, 0.5))
				return
			pr["equip"][_eq_slot] = int(g["uid"])
			refresh.call(), 92, "✓" if on else ("◐" if used_other else ""))
		t.tooltip_text = "%s\n%s" % [it["name"], Gear.stats_text(g["id"])]
		t.mouse_entered.connect(func(): show_detail.call(g))
		grid.add_child(t)
	dv.add_child(detail)
	show_detail.call(cur if not cur.is_empty() else (list[0] if not list.is_empty() else {}))
	# Mangekyō deseni
	if _eq_slot in ["sag_goz", "sol_goz"] and not Eyes.design_for(pr, _eq_slot).is_empty():
		_ms_editor(main, dv, Eyes.design_for(pr, _eq_slot))
	# boya
	if not cur.is_empty() and not Gear.item(cur["id"]).has("weapon") and not Gear.item(cur["id"]).has("eye"):
		var names = {"govde": ["Ana renk", "Vurgu (omuz/yaka)"], "ayak": ["Sandalet", "Sargılar"]}.get(_eq_slot, ["Renk"])
		for ci in names.size():
			var key = "c%d" % (ci + 1)
			dv.add_child(UI.label(names[ci], 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
			var fl = HFlowContainer.new()
			fl.add_theme_constant_override("h_separation", 8)
			for c in SWATCHES:
				fl.add_child(_swatch(c, Color.html(cur[key]).is_equal_approx(c), func():
					cur[key] = c.to_html(false)
					refresh.call()))
			dv.add_child(fl)


## Özel Mangekyō deseni: canlı önizleme + stil/kanat/kıvrım/kalınlık/halka/renk
const MS_STYLES := ["Çark", "Yıldız", "Taç Yaprak", "Shuriken", "Sarmal", "Haç", "Tomoe Halkası"]
const MS_COLORS := [[0.9, 0.05, 0.06], [0.6, 0.0, 0.05], [0.55, 0.2, 0.85], [0.15, 0.4, 0.95], [0.95, 0.7, 0.1], [0.1, 0.7, 0.4]]
static func _ms_editor(main: Node, v: VBoxContainer, d: Dictionary) -> void:
	v.add_child(UI.spacer(0, 6, false))
	v.add_child(UI.header("MANGEKYŌ DESENİ", 18))
	var row = UI.hbox(18)
	v.add_child(row)
	var pv = ColorRect.new()
	pv.custom_minimum_size = Vector2(180, 180)
	var sm = ShaderMaterial.new()
	sm.shader = load("res://shaders/ms_preview.gdshader")
	pv.material = sm
	row.add_child(pv)
	var apply_pv = func() -> void:
		var vv = Eyes.design_vecs(d)
		sm.set_shader_parameter("ms_a", vv[0])
		sm.set_shader_parameter("ms_b", vv[1])
		sm.set_shader_parameter("col", vv[2])
		if Game.player and Game.player.combat and Game.player.combat.modes and Game.player.combat.modes.eyes:
			Game.player.combat.modes.eyes.refresh_visual()
	apply_pv.call()
	var ctl = UI.vbox(6)
	row.add_child(ctl)
	var slider = func(title: String, key: String, mn: float, mx: float, stp: float) -> void:
		var hh = UI.hbox(8)
		var l = UI.label(title, 13, UI.MUTED)
		l.custom_minimum_size = Vector2(92, 0)
		hh.add_child(l)
		var sl = HSlider.new()
		sl.min_value = mn
		sl.max_value = mx
		sl.step = stp
		sl.value = float(d.get(key, mn))
		sl.custom_minimum_size = Vector2(180, 22)
		sl.value_changed.connect(func(x):
			d[key] = x
			apply_pv.call())
		hh.add_child(sl)
		ctl.add_child(hh)
	slider.call("Kanat sayısı", "blades", 2, 8, 1)
	slider.call("Kıvrım", "curve", -3.0, 3.0, 0.05)
	slider.call("Kalınlık", "thick", 0.2, 0.9, 0.01)
	slider.call("Göz bebeği", "inner", 0.08, 0.4, 0.01)
	slider.call("Dönüş hızı", "spin", 0.0, 2.0, 0.05)
	var tg = UI.hbox(6)
	for opt in [["ring", "Dış halka"], ["invert", "Ters renk"]]:
		var cb = CheckBox.new()
		cb.text = opt[1]
		cb.button_pressed = bool(d.get(opt[0], false))
		cb.toggled.connect(func(x):
			d[opt[0]] = x
			apply_pv.call())
		tg.add_child(cb)
	ctl.add_child(tg)
	var fl = HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 6)
	for i in MS_STYLES.size():
		fl.add_child(UI.chip(MS_STYLES[i], int(d.get("style", 0)) == i, func():
			d["style"] = i
			ninja_menu(main, "wardrobe")))
	v.add_child(fl)
	var cr = UI.hbox(8)
	for c in MS_COLORS:
		cr.add_child(_swatch(Color(c[0], c[1], c[2]), false, func():
			d["col"] = c
			apply_pv.call()))
	cr.add_child(UI.button("Rastgele", func():
		var nd = Eyes.random_design()
		for k in nd:
			d[k] = nd[k]
		ninja_menu(main, "wardrobe"), 140, "star"))
	v.add_child(cr)


## Susanoo önizlemesi (karakter yerine)
static func _susanoo_preview(pr: Dictionary) -> Control:
	var svc = SubViewportContainer.new()
	svc.stretch = true
	svc.process_mode = Node.PROCESS_MODE_ALWAYS
	var sv = SubViewport.new()
	sv.own_world_3d = true
	sv.transparent_bg = true
	svc.add_child(sv)
	var sn = Susanoo.new()
	sv.add_child(sn)
	sn.build(pr, maxi(1, Susanoo.cur_tier(pr)))
	sn.scale = Vector3.ONE * (2.1 / 1.8)
	var cam = Camera3D.new()
	cam.fov = 36
	sv.add_child(cam)
	var cp = Vector3(0, 1.25, -5.2)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 1.1, 0) - cp), cp)
	var tw = sn.create_tween().set_loops()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(sn, "rotation:y", TAU, 10.0).from(0.0)
	return svc


## Susanoo özelleştirme: kademe, renk, zırh, yüz, silah, kanat
static func _susanoo_panel(main: Node, v: VBoxContainer, _h) -> void:
	var pr = Game.profile
	var cfg = Susanoo.config(pr)
	var mt = Susanoo.max_tier(pr)
	var redraw = func() -> void:
		ninja_menu(main, "wardrobe")
	var m = float(cfg.get("mastery", 0.0))
	var nxt = mt + 1
	var info = "Ustalık: %d sn" % int(m)
	if nxt <= 5:
		info += "   •   Kademe %d için %d sn%s" % [nxt, int(Susanoo.MASTERY_STEPS[nxt]), " (Ebedi Mangekyō)" if nxt >= 4 else ""]
	v.add_child(UI.label(info, 14, Color(0.78, 0.7, 1.0)))
	if nxt <= 5:
		var pb = UI.bar(Color(0.65, 0.5, 1.0), 460, 8)
		pb.max_value = Susanoo.MASTERY_STEPS[nxt]
		pb.value = m
		v.add_child(pb)
	var opt_row = func(title: String, labels: Array, cur, key: String, values: Array, limit := 99) -> void:
		v.add_child(UI.label(title, 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		var fl = HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 8)
		fl.add_theme_constant_override("v_separation", 8)
		for i in labels.size():
			var b = UI.chip(labels[i], cur == values[i], func():
				cfg[key] = values[i]
				redraw.call())
			b.disabled = i + 1 > limit
			fl.add_child(b)
		v.add_child(fl)
	var tp = int(cfg.get("tier_pref", 5))
	opt_row.call("Kademe", ["1 Kaburga", "2 İskelet", "3 İnsansı", "4 Zırhlı", "5 Mükemmel"], tp, "tier_pref", [1, 2, 3, 4, 5], mt)
	opt_row.call("Zırh", Susanoo.ARMORS, int(cfg.get("armor", 0)), "armor", [0, 1, 2])
	opt_row.call("Yüz", Susanoo.FACES, int(cfg.get("face", 0)), "face", [0, 1, 2])
	opt_row.call("Silah", Susanoo.WEAPONS.values(), cfg.get("weapon", "kilic"), "weapon", Susanoo.WEAPONS.keys())
	v.add_child(UI.label("Renk", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var cr = HFlowContainer.new()
	cr.add_theme_constant_override("h_separation", 8)
	for c in Susanoo.COLORS:
		var cc: Array = cfg.get("color", Susanoo.COLORS[0])
		cr.add_child(_swatch(Color(c[0], c[1], c[2]), Color(cc[0], cc[1], cc[2]).is_equal_approx(Color(c[0], c[1], c[2])), func():
			cfg["color"] = c
			redraw.call()))
	v.add_child(cr)
	var wb = CheckBox.new()
	wb.text = "Kanatlar (Mükemmel Susanoo)"
	wb.button_pressed = bool(cfg.get("wings", true))
	wb.toggled.connect(func(x):
		cfg["wings"] = x
		redraw.call())
	v.add_child(wb)
	v.add_child(UI.icon_label("info", "Gözler açıkken V basılı tut. Sol tık dev savuruş, sağ tık silah saldırısı.", 13, UI.MUTED))


static func _hair_panel(v: VBoxContainer, look: Dictionary, refresh: Callable) -> void:
	v.add_child(UI.label("Berber ücretsiz", 14, UI.MUTED))
	var styles = {"diken": "Dikenli", "dağınık": "Dağınık", "kase": "Kâse", "kısa": "Kısa", "uzun": "Uzun", "atkuyruğu": "At kuyruğu"}
	var fl = HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 8)
	fl.add_theme_constant_override("v_separation", 8)
	for k in styles:
		fl.add_child(UI.chip(styles[k], look.get("hair_style", "") == k, func():
			look["hair_style"] = k
			refresh.call()))
	v.add_child(fl)
	v.add_child(UI.label("Renk", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var cg = HFlowContainer.new()
	cg.add_theme_constant_override("h_separation", 8)
	for c in [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.9, 0.92), Color(0.2, 0.3, 0.6), Color(0.9, 0.55, 0.7), Color(0.25, 0.45, 0.25)]:
		cg.add_child(_swatch(c, Color(look.get("hair", Color.BLACK)).is_equal_approx(c), func():
			look["hair"] = c
			refresh.call()))
	v.add_child(cg)


## Ayrı dünyada dönen karakter önizlemesi (oyun duraklatılmışken de çalışır)
static func _model_preview(look: Dictionary, cam_pos := Vector3(0, 1.0, -4.4), target := Vector3(0, 0.92, 0), fov := 32.0, spin := true, size := Vector2(400, 600)) -> Control:
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = size
	svc.size = size
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
	env.environment.ambient_light_energy = 0.55
	sv.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.3
	sv.add_child(sun)
	var rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, 200, 0)
	rim.light_energy = 0.6
	rim.light_color = Color(1.0, 0.8, 0.55)
	sv.add_child(rim)
	var m = CharacterModel.new()
	sv.add_child(m)
	m.setup(look)
	m.play("idle")
	m.scale = Vector3.ONE
	var cam = Camera3D.new()
	cam.fov = fov
	sv.add_child(cam)
	cam.transform = Transform3D(Basis.looking_at(target - cam_pos), cam_pos)
	if spin:
		var tw = m.create_tween().set_loops()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(m, "rotation:y", TAU, 12.0).from(0.0)
	svc.set_meta("model", m)
	return svc


# ------------------------------------------------------------------ jutsular
static var _jf_mode := "learned"
static var _jf_cat := ""
static var _jf_el := ""
static var _jf_text := ""
const JUTSU_CATS := [["", "Tümü"], ["ninjutsu", "Ninjutsu"], ["taijutsu", "Taijutsu"], ["genjutsu", "Genjutsu"], ["fuinjutsu", "Fūinjutsu"], ["kekkei_genkai", "Kekkei Genkai"],
	["dojutsu", "Dōjutsu"], ["hiden", "Hiden"], ["senjutsu", "Senjutsu"], ["kinjutsu", "Kinjutsu"], ["medical", "Tıbbi"], ["space_time", "Uzay-Zaman"], ["summoning", "Çağırma"]]
const JUTSU_ELEMS := [["", "Tüm elementler"], ["katon", "Katon"], ["suiton", "Suiton"], ["fuuton", "Fūton"], ["raiton", "Raiton"], ["doton", "Doton"],
	["mokuton", "Mokuton"], ["hyoton", "Hyōton"], ["yoton", "Yōton"], ["futton", "Futton"], ["ranton", "Ranton"], ["bakuton", "Bakuton"], ["jinton", "Jinton"]]


static func _tab_jutsu(main: Node, body: Control, picked: String) -> void:
	var pr = Game.profile
	var h = UI.hbox(26)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	var left = UI.vbox(16)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	var learned: Array = pr["learned"]
	if picked == "" and not learned.is_empty():
		picked = learned[0]
	# filtreler: öğrendiklerim / jutsu kitabı (tümü), kategori, element, arama
	var fbar = UI.hbox(8)
	left.add_child(fbar)
	for m in [["learned", "Öğrendiklerim (%d)" % learned.size()], ["all", "Jutsu Kitabı (%d)" % Data.jutsu.size()]]:
		fbar.add_child(UI.chip(m[1], _jf_mode == m[0], func():
			_jf_mode = m[0]
			ninja_menu(main, "jutsu", picked)))
	var search = LineEdit.new()
	search.placeholder_text = "Ara..."
	search.text = _jf_text
	search.custom_minimum_size = Vector2(200, 36)
	search.text_submitted.connect(func(t):
		_jf_text = t
		ninja_menu(main, "jutsu", picked))
	fbar.add_child(search)
	var cbar = HFlowContainer.new()
	cbar.add_theme_constant_override("h_separation", 6)
	left.add_child(cbar)
	for c in JUTSU_CATS:
		cbar.add_child(UI.chip(c[1], _jf_cat == c[0], func():
			_jf_cat = c[0]
			ninja_menu(main, "jutsu", picked)))
	var ebar = HFlowContainer.new()
	ebar.add_theme_constant_override("h_separation", 6)
	left.add_child(ebar)
	for e in JUTSU_ELEMS:
		ebar.add_child(UI.chip(e[1], _jf_el == e[0], func():
			_jf_el = e[0]
			ninja_menu(main, "jutsu", picked)))
	var shown: Array = []
	for jid in (learned if _jf_mode == "learned" else Data.jutsu.keys()):
		var jj: Dictionary = Data.jutsu.get(jid, {})
		if _jf_cat != "" and String(jj.get("category", "")) != _jf_cat:
			continue
		if _jf_el != "" and String(jj.get("element", "")) != _jf_el and not _jf_el in jj.get("elements", []):
			continue
		if _jf_text != "" and not String(jj.get("name", jid)).to_lower().contains(_jf_text.to_lower()):
			continue
		shown.append(jid)
		if shown.size() >= 120:
			break
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	if learned.is_empty() and _jf_mode == "learned":
		left.add_child(UI.label("Henüz bir jutsu bilmiyorsun. Akademi hocanla konuş!", 16, UI.MUTED))
	for jid in shown:
		var card = _jutsu_card(jid, jid == picked, func(): ninja_menu(main, "jutsu", jid))
		if not jid in learned:
			card.modulate = Color(1, 1, 1, 0.45)
		grid.add_child(card)
	if shown.size() >= 120:
		left.add_child(UI.label("İlk 120 sonuç gösteriliyor — filtreyi daralt.", 13, UI.MUTED))
	# slot çubuğu
	var bar = UI.card()
	left.add_child(bar)
	var bv = UI.vbox(8)
	bar.add_child(bv)
	bv.add_child(UI.label("Seçili jutsuyu bir slota ata", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var sh = UI.hbox(10)
	bv.add_child(sh)
	for i in 6:
		var cur = pr["slots"][i] if i < pr["slots"].size() else ""
		var j: Dictionary = Data.jutsu.get(cur, {}) if cur != null and cur != "" else {}
		var el = String(j.get("element", ""))
		var view = Icons.view(UI.ELEMENT_ICONS.get(el, "chakra") if not j.is_empty() else "plus", 40, UI.ELEMENT_COLORS.get(el, UI.TEXT) if not j.is_empty() else Color(1, 1, 1, 0.15))
		var nm = String(j.get("name", "Boş")).split(":")[-1].split("(")[0].strip_edges()
		var t = _tile(view, "[%d] %s" % [i + 1, nm], UI.ELEMENT_COLORS.get(el, Color(1, 1, 1, 0.2)) if not j.is_empty() else Color(1, 1, 1, 0.15), false, func():
			if picked != "":
				while pr["slots"].size() < 6:
					pr["slots"].append("")
				for k in 6:
					if pr["slots"][k] == picked:
						pr["slots"][k] = ""
				pr["slots"][i] = picked
			ninja_menu(main, "jutsu", picked), 112)
		t.tooltip_text = nm
		sh.add_child(t)
	# sağ: ayrıntı
	var right = UI.card()
	right.custom_minimum_size = Vector2(440, 0)
	h.add_child(right)
	var rv = UI.vbox(10)
	right.add_child(rv)
	if picked == "":
		rv.add_child(UI.label("Bir jutsu seç.", 16, UI.MUTED))
		return
	var j: Dictionary = Data.jutsu.get(picked, {})
	var el = String(j.get("element", ""))
	var ec: Color = UI.ELEMENT_COLORS.get(el, UI.GOLD)
	if not picked in learned:
		var why = Progress.can_learn(picked) if Progress.has_method("can_learn") else ""
		var how = {"academy": "Akademide öğrenilir", "scroll": "Silah dükkânında parşömeni satılır", "clan": "Klan tekniği", "kinjutsu": "Yasak teknik — hikâye ile",
			"element": "Element başlangıç tekniği"}
		var lp = String(j.get("learn", ""))
		var txt = how.get(lp, "")
		if lp.begins_with("trainer"):
			txt = "Hocadan öğrenilir (%s)" % lp.trim_prefix("trainer").trim_prefix(":")
		elif lp.begins_with("kg"):
			txt = "Kekkei genkai gerekir (%s)" % lp.trim_prefix("kg:")
		elif lp.begins_with("eye"):
			txt = "Göz tekniği gerekir"
		elif lp.begins_with("sage"):
			txt = "Sennin eğitimi gerekir (%s)" % lp.trim_prefix("sage:")
		elif lp.begins_with("special") or lp == "signature":
			txt = "Özel görev ile açılır"
		rv.add_child(UI.label("🔒 Öğrenilmedi — " + (txt if txt != "" else lp) + ((".  " + why) if why != "" else ""), 14, Color(1, 0.75, 0.45), HORIZONTAL_ALIGNMENT_LEFT, true))
	var top = UI.hbox(14)
	var badge = Panel.new()
	badge.custom_minimum_size = Vector2(76, 76)
	badge.add_theme_stylebox_override("panel", UI._box(Color(ec, 0.18), Color(ec, 0.8), 2, 38, 0))
	var bi = Icons.view(UI.ELEMENT_ICONS.get(el, "chakra"), 44, ec)
	bi.position = Vector2(16, 16)
	badge.add_child(bi)
	top.add_child(badge)
	var tv = UI.vbox(2)
	var nm = UI.label(String(j.get("name", picked)), 22, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(300, 0)
	tv.add_child(nm)
	tv.add_child(UI.label("%s-rank   •   %s" % [j.get("canon_rank", "?"), el.capitalize() if el != "" else "Doğasız"], 14, ec, HORIZONTAL_ALIGNMENT_LEFT, true))
	top.add_child(tv)
	rv.add_child(top)
	var stats = UI.hbox(22)
	stats.add_child(UI.icon_label("chakra", "%d chakra" % int(j.get("cost", 0)), 15, Color(0.55, 0.78, 1.0)))
	stats.add_child(UI.icon_label("hourglass", "%.1f sn" % float(j.get("cd", 5)), 15, UI.MUTED))
	rv.add_child(stats)
	var seals: Array = j.get("seals", [])
	if not seals.is_empty():
		rv.add_child(UI.label("Mühürler", 13, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		var fl = HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 6)
		for s in seals:
			var p = PanelContainer.new()
			var psb = UI._box(Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.12), 1, 14, 4)
			psb.content_margin_left = 12; psb.content_margin_right = 12
			p.add_theme_stylebox_override("panel", psb)
			p.add_child(UI.label(String(s), 13, UI.CREAM))
			fl.add_child(p)
		rv.add_child(fl)
	var d = UI.label(String(j.get("desc", "")), 15, UI.MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(400, 0)
	rv.add_child(d)


static func _jutsu_card(jid: String, selected: bool, cb: Callable) -> Button:
	var j: Dictionary = Data.jutsu.get(jid, {})
	var el = String(j.get("element", ""))
	var ec: Color = UI.ELEMENT_COLORS.get(el, UI.GOLD)
	var b = Button.new()
	b.custom_minimum_size = Vector2(300, 92)
	var n = UI._box(Color(1, 1, 1, 0.045), Color(1, 1, 1, 0.08), 1, 12, 10)
	n.border_width_left = 4
	n.border_color = Color(ec, 0.8)
	var hh = n.duplicate()
	hh.bg_color = Color(1, 1, 1, 0.1)
	var s = n.duplicate()
	s.bg_color = Color(ec, 0.16)
	s.set_border_width_all(2)
	s.border_width_left = 4
	s.border_color = ec
	b.add_theme_stylebox_override("normal", s if selected else n)
	b.add_theme_stylebox_override("hover", s if selected else hh)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_stylebox_override("focus", s if selected else hh)
	var ic = Icons.view(UI.ELEMENT_ICONS.get(el, "chakra"), 38, ec)
	ic.position = Vector2(16, 26)
	b.add_child(ic)
	var nm = UI.label(String(j.get("name", jid)).split("(")[0].strip_edges(), 16, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	nm.position = Vector2(66, 16)
	nm.size = Vector2(222, 22)
	nm.clip_text = true
	b.add_child(nm)
	var sub = UI.label("%s-rank  •  %d chakra  •  %d mühür" % [j.get("canon_rank", "?"), int(j.get("cost", 0)), (j.get("seals", []) as Array).size()], 12, UI.MUTED)
	sub.position = Vector2(66, 46)
	sub.size = Vector2(222, 18)
	b.add_child(sub)
	b.tooltip_text = String(j.get("desc", ""))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	UI.hover_anim(b, 1.02)
	return b


# ------------------------------------------------------------------ yetenek ağacı (düğüm grafiği)
static var _skill_sel := ""


static func _tab_skills(main: Node, body: Control) -> void:
	var pr = Game.profile
	var h = UI.hbox(26)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	var graph = Control.new()
	graph.custom_minimum_size = Vector2(900, 680)
	graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(graph)
	var cats = ["Taijutsu", "Ninjutsu", "Destek"]
	var pos = {}
	var col_x = {"Taijutsu": 120.0, "Ninjutsu": 400.0, "Destek": 700.0}
	var depth = {}
	for sid in SKILLS:
		var s: Array = SKILLS[sid]
		var d = 0 if s[3] == "" else int(depth.get(s[3], 0)) + 1
		depth[sid] = d
	var col_count = {}
	for sid in SKILLS:
		var s: Array = SKILLS[sid]
		var cat: String = s[2]
		var d = int(depth[sid])
		var key = "%s|%d" % [cat, d]
		var k = int(col_count.get(key, 0))
		col_count[key] = k + 1
		pos[sid] = Vector2(col_x[cat] + k * 130.0, 110.0 + d * 150.0)
	# bağlantı çizgileri
	var lines = Control.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.draw.connect(func():
		for sid in SKILLS:
			var s: Array = SKILLS[sid]
			if s[3] != "":
				var owned = sid in pr["skills"]
				lines.draw_line(pos[s[3]], pos[sid], Color(UI.GOLD, 0.8) if owned else Color(1, 1, 1, 0.15), 3.0 if owned else 2.0, true))
	graph.add_child(lines)
	for c in cats:
		var cl = UI.icon_label(SKILL_ICONS[c], c.to_upper(), 16, UI.GOLD)
		cl.position = Vector2(col_x[c] - 60, 20)
		graph.add_child(cl)
	for sid in SKILLS:
		var s: Array = SKILLS[sid]
		var owned: bool = sid in pr["skills"]
		var can: bool = not owned and int(pr["sp"]) > 0 and int(pr["level"]) >= int(s[4]) and (s[3] == "" or s[3] in pr["skills"])
		if sid == "elem2" and int(pr["rank"]) < 2:
			can = false
		var b = Button.new()
		b.custom_minimum_size = Vector2(72, 72)
		b.size = Vector2(72, 72)
		b.position = pos[sid] - Vector2(36, 36)
		var col = UI.GOLD if owned else (UI.TEXT if can else Color(1, 1, 1, 0.25))
		var n = UI._box(Color(UI.GOLD, 0.22) if owned else Color(0.08, 0.09, 0.12, 0.95), col, 3 if (owned or can) else 1, 36, 0)
		var hv = n.duplicate()
		hv.border_color = UI.GOLD
		hv.set_border_width_all(3)
		var selb = hv.duplicate()
		selb.shadow_color = Color(UI.GOLD, 0.5)
		selb.shadow_size = 12
		b.add_theme_stylebox_override("normal", selb if _skill_sel == sid else n)
		b.add_theme_stylebox_override("hover", selb if _skill_sel == sid else hv)
		b.add_theme_stylebox_override("pressed", selb)
		b.add_theme_stylebox_override("focus", selb if _skill_sel == sid else hv)
		var ic = Icons.view(SKILL_ICONS[s[2]] if sid != "elem2" else "chakra", 34, col)
		ic.position = Vector2(19, 19)
		b.add_child(ic)
		b.pressed.connect(func():
			Sfx.play("click")
			_skill_sel = sid
			ninja_menu(main, "skills"))
		graph.add_child(b)
		var nl = UI.label(s[0], 13, col, HORIZONTAL_ALIGNMENT_CENTER, true)
		nl.position = pos[sid] + Vector2(-70, 42)
		nl.size = Vector2(140, 18)
		graph.add_child(nl)
	# sağ: ayrıntı
	var right = UI.card()
	right.custom_minimum_size = Vector2(420, 0)
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(right)
	var rv = UI.vbox(10)
	right.add_child(rv)
	rv.add_child(UI.icon_label("star", "Yetenek puanı: %d" % int(pr["sp"]), 18, UI.GOLD))
	if _skill_sel == "" or not SKILLS.has(_skill_sel):
		rv.add_child(UI.label("Bir düğüm seç.", 15, UI.MUTED))
		return
	var s: Array = SKILLS[_skill_sel]
	var owned: bool = _skill_sel in pr["skills"]
	var can: bool = not owned and int(pr["sp"]) > 0 and int(pr["level"]) >= int(s[4]) and (s[3] == "" or s[3] in pr["skills"])
	if _skill_sel == "elem2" and int(pr["rank"]) < 2:
		can = false
	rv.add_child(UI.label(s[0], 24, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	rv.add_child(UI.label("%s   •   Seviye %d" % [s[2], int(s[4])], 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	rv.add_child(UI.label(s[1], 17, UI.GOOD))
	if s[3] != "":
		rv.add_child(UI.label("Gerekli: %s" % SKILLS[s[3]][0], 14, UI.MUTED))
	var sid = _skill_sel
	if owned:
		rv.add_child(UI.icon_label("check", "Öğrenildi", 16, UI.GOLD))
	else:
		var b = UI.primary("Öğren (1 puan)", func():
			if sid == "elem2":
				_pick_element(main)
				return
			pr["skills"].append(sid)
			pr["sp"] = int(pr["sp"]) - 1
			Game.player.apply_profile_stats()
			ninja_menu(main, "skills"), 380, "plus")
		b.disabled = not can
		rv.add_child(b)


# ------------------------------------------------------------------ görevler sekmesi
static func _tab_missions(main: Node, body: Control) -> void:
	var pr = Game.profile
	var h = UI.hbox(26)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	var left = UI.vbox(16)
	left.custom_minimum_size = Vector2(760, 0)
	h.add_child(left)
	# hikâye
	var sc = UI.card(UI.GOLD)
	left.add_child(sc)
	var sv = UI.vbox(8)
	sc.add_child(sv)
	sv.add_child(UI.icon_label("book", "HİKÂYE", 15, UI.GOLD))
	var s = Progress.story()
	var st = UI.label(String(Progress.STORY[mini(s, Progress.STORY.size() - 1)]), 18)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size = Vector2(700, 0)
	sv.add_child(st)
	# aktif görev
	var m: Dictionary = pr.get("active_mission", {})
	var mc = UI.card()
	left.add_child(mc)
	var mv = UI.vbox(8)
	mc.add_child(mv)
	mv.add_child(UI.icon_label("mission", "AKTİF GÖREV", 15, UI.GOLD))
	if m.is_empty():
		mv.add_child(UI.label("Aktif görev yok. Köydeki görev masasından görev alabilirsin.", 16, UI.MUTED))
	else:
		var row = UI.hbox(16)
		row.add_child(_rank_stamp(String(m.get("rank", "D")), 64))
		var tv = UI.vbox(4)
		tv.add_child(UI.label(String(m.get("title", "")), 22, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		var dl = UI.label(String(m.get("desc", "")), 15, UI.MUTED)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(600, 0)
		tv.add_child(dl)
		row.add_child(tv)
		mv.add_child(row)
		var steps: Array = m.get("steps", [])
		var cur_step = int(m.get("step", m.get("progress", 0)))
		for i in steps.size():
			var done = i < cur_step
			mv.add_child(UI.icon_label("check" if done else ("play" if i == cur_step else "target"), String(steps[i].get("text", "")), 15, UI.GOOD if done else (UI.TEXT if i == cur_step else UI.MUTED)))
	var acts = UI.hbox(12)
	left.add_child(acts)
	acts.add_child(UI.button("Haritada göster", func(): world_map(main), 240, "map"))
	if Missions.has_method("bingo_entries"):
		acts.add_child(UI.button("Bingo Kitabı", func(): bingo_book(main), 240, "book"))
	# sağ: tamamlananlar
	var right = UI.card()
	right.custom_minimum_size = Vector2(380, 0)
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(right)
	var rv = UI.vbox(12)
	right.add_child(rv)
	rv.add_child(UI.icon_label("check", "TAMAMLANANLAR", 15, UI.GOLD))
	var md: Dictionary = pr["missions_done"]
	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	for r in ["D", "C", "B", "A", "S"]:
		var cv = UI.vbox(4)
		cv.add_child(_rank_stamp(r, 52))
		cv.add_child(UI.label(str(int(md.get(r, 0))), 18, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true))
		grid.add_child(cv)
	rv.add_child(grid)


## Kırmızı mürekkep rütbe damgası
static func _rank_stamp(r: String, size := 64) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col = {"D": Color(0.55, 0.62, 0.5), "C": Color(0.3, 0.55, 0.85), "B": Color(0.62, 0.38, 0.85), "A": Color(0.9, 0.45, 0.15), "S": Color(0.85, 0.12, 0.12)}.get(r, Color(0.8, 0.15, 0.15))
	c.draw.connect(func():
		var cen = Vector2(size, size) * 0.5
		c.draw_circle(cen, size * 0.47, Color(col, 0.16))
		c.draw_arc(cen, size * 0.44, 0, TAU, 40, col, maxf(2.0, size * 0.06), true)
		c.draw_arc(cen, size * 0.34, 0.3, TAU - 0.4, 40, Color(col, 0.55), 1.5, true)
		var f = UI.font(true)
		var fs = int(size * 0.5)
		var w = f.get_string_size(r, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		c.draw_string(f, cen + Vector2(-w * 0.5, fs * 0.36), r, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col))
	return c


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
		opts.append({"label": e.capitalize(), "cb": func():
			pr["elements"].append(e)
			pr["skills"].append("elem2")
			pr["sp"] = int(pr["sp"]) - 1
			var starter = {"katon": "katon_goukakyuu", "suiton": "suiton_suikoudan", "fuuton": "fuuton_shinkuu", "doton": "doton_doryuusou", "raiton": "raiton_nagashi"}[e]
			Progress.learn(starter)})
	Hud.dialog("İkinci Chakra Doğası", "Hangi doğayı geliştireceksin?", opts)


# ================================================================== görev masası (ahşap pano + parşömenler)
static var _board_open := {}


static func mission_board(village_id: String) -> void:
	var main = Hud.get_tree().current_scene
	var list: Array = []
	if Missions.has_method("board_missions"):
		list = Missions.board_missions(village_id)
	else:
		list = Missions.board
	Missions.board = list
	Missions.board_village = village_id
	Game.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg = _full(0.45)
	# ahşap pano
	var board = ColorRect.new()
	var wm = ShaderMaterial.new()
	wm.shader = load("res://shaders/ui_wood.gdshader")
	board.material = wm
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.offset_left = 90; board.offset_right = -90; board.offset_top = 70; board.offset_bottom = -70
	bg.add_child(board)
	if _fresh:
		UI.pop_in(board, 0.97)
	# başlık plakası
	var vname = String(Game.village(village_id).get("name", village_id))
	var plate = PanelContainer.new()
	var psb = UI._box(Color(0.12, 0.07, 0.04, 0.95), Color(UI.GOLD, 0.7), 2, 8, 12)
	psb.content_margin_left = 40; psb.content_margin_right = 40
	plate.add_theme_stylebox_override("panel", psb)
	plate.add_child(UI.label("任務   GÖREV MASASI — %s" % vname.to_upper(), 24, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, true))
	plate.set_anchors_preset(Control.PRESET_CENTER_TOP)
	plate.position = Vector2(-330, -18)
	plate.custom_minimum_size = Vector2(660, 0)
	board.add_child(plate)
	var rep_txt = ""
	if Missions.has_method("rep"):
		rep_txt = "%s itibarın: %d" % [vname, int(Missions.rep(village_id))]
	if Missions.has_method("board_limits"):
		var lim = Missions.board_limits(village_id)
		if String(lim.get("note", "")) != "":
			rep_txt += "   •   " + String(lim["note"])
	var sub = UI.label("Rütben: %s   •   %s" % [Data.RANKS[int(Game.profile["rank"])], rep_txt], 15, Color(1, 0.92, 0.8))
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-500, 52)
	sub.size = Vector2(1000, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.add_child(sub)
	# asılı parşömenler
	var flow = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 26)
	flow.add_theme_constant_override("v_separation", 30)
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.set_anchors_preset(Control.PRESET_FULL_RECT)
	flow.offset_left = 50; flow.offset_right = -50; flow.offset_top = 110; flow.offset_bottom = -30
	board.add_child(flow)
	if list.is_empty():
		var l = UI.label("Şu an rütbene uygun görev yok. Daha sonra tekrar bak.", 20, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		flow.add_child(l)
	for i in list.size():
		var m: Dictionary = list[i]
		var sc = _hanging_scroll(m, func(): _unroll(m, village_id))
		flow.add_child(sc)
		if _fresh:
			sc.modulate.a = 0.0
			var tw = sc.create_tween()
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_interval(0.05 * i)
			tw.tween_property(sc, "modulate:a", 1.0, 0.2)
	_close_button(bg, func(): Hud.close_dialog())


## Panoya iğnelenmiş görev parşömeni
static func _hanging_scroll(m: Dictionary, cb: Callable) -> Button:
	var b = Button.new()
	b.custom_minimum_size = Vector2(200, 300)
	var empty = StyleBoxEmpty.new()
	for k in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(k, empty)
	var paper = ColorRect.new()
	var pm = ShaderMaterial.new()
	pm.shader = load("res://shaders/ui_parchment.gdshader")
	pm.set_shader_parameter("seed", float(hash(String(m.get("title", "")))) * 0.0001)
	paper.material = pm
	paper.position = Vector2(8, 14)
	paper.size = Vector2(184, 280)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(paper)
	# iğne
	var pin = Control.new()
	pin.position = Vector2(100, 14)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.draw.connect(func():
		pin.draw_circle(Vector2(2, 3), 8, Color(0, 0, 0, 0.35))
		pin.draw_circle(Vector2.ZERO, 8, Color(0.75, 0.12, 0.1))
		pin.draw_circle(Vector2(-2, -2), 3, Color(1, 0.6, 0.55)))
	b.add_child(pin)
	var stamp = _rank_stamp(String(m.get("rank", "D")), 58)
	stamp.position = Vector2(71, 34)
	b.add_child(stamp)
	var ink = Color(0.16, 0.1, 0.06)
	var t = UI.label(String(m.get("title", "")), 18, ink, HORIZONTAL_ALIGNMENT_CENTER, true)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.position = Vector2(20, 104)
	t.size = Vector2(160, 80)
	b.add_child(t)
	if m.get("local", false):
		var loc = UI.label("★ köye özgü", 12, Color(0.6, 0.15, 0.1), HORIZONTAL_ALIGNMENT_CENTER, true)
		loc.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		loc.position = Vector2(20, 186)
		loc.size = Vector2(160, 16)
		b.add_child(loc)
	var rw = _rewards(m)
	var r1 = UI.label("%d Ryō" % rw[0], 15, ink, HORIZONTAL_ALIGNMENT_CENTER, true)
	r1.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	r1.position = Vector2(20, 222)
	r1.size = Vector2(160, 20)
	b.add_child(r1)
	var r2 = UI.label("%d XP%s" % [rw[1], "   ✦ ekipman" if rw[2] >= 0.5 else ""], 13, Color(0.35, 0.25, 0.15), HORIZONTAL_ALIGNMENT_CENTER)
	r2.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	r2.position = Vector2(20, 246)
	r2.size = Vector2(160, 18)
	b.add_child(r2)
	b.resized.connect(func(): b.pivot_offset = Vector2(100, 14))
	b.mouse_entered.connect(func():
		Sfx.play("click", null, 1.6, 0.2)
		var tw = b.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(b, "rotation", deg_to_rad(-2.5), 0.12))
	b.mouse_exited.connect(func():
		var tw = b.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(b, "rotation", 0.0, 0.15))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


static func _rewards(m: Dictionary) -> Array:
	if m.has("rewards") and m["rewards"] is Dictionary:
		var rw: Dictionary = m["rewards"]
		return [int(rw.get("ryo", 0)), int(rw.get("xp", 0)), float(rw.get("gear_chance", 0.0))]
	var r = String(m.get("rank", "D"))
	var base: Array = Missions.REWARD.get(r, [0, 0])
	return [int(base[0]), int(base[1]), float(Missions.GEAR_CHANCE.get(r, 0.0))]


## Parşömen açılır: brifing, hedefler, ödüller, hanko damgalı kabul
static func _unroll(m: Dictionary, village_id: String) -> void:
	var layer = Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.dialog_layer.add_child(layer)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var holder = Control.new()
	holder.set_anchors_preset(Control.PRESET_CENTER)
	holder.size = Vector2(900, 620)
	holder.position = Vector2(-450, -310)
	layer.add_child(holder)
	# rulolar
	for y in [0.0, 600.0]:
		var rod = Panel.new()
		rod.add_theme_stylebox_override("panel", UI._box(Color(0.32, 0.18, 0.1), Color(0.15, 0.08, 0.04), 2, 10, 0))
		rod.position = Vector2(-20, y)
		rod.size = Vector2(940, 22)
		holder.add_child(rod)
	var paper = ColorRect.new()
	var pm = ShaderMaterial.new()
	pm.shader = load("res://shaders/ui_parchment.gdshader")
	pm.set_shader_parameter("edge", 0.05)
	paper.material = pm
	paper.position = Vector2(0, 16)
	paper.size = Vector2(900, 588)
	holder.add_child(paper)
	paper.clip_contents = true
	var ink = Color(0.16, 0.1, 0.06)
	var mk = func(text: String, size: int, col: Color, bold := false) -> Label:
		var l = UI.label(text, size, col, HORIZONTAL_ALIGNMENT_LEFT, bold)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		return l
	var v = UI.vbox(10)
	v.position = Vector2(56, 34)
	v.custom_minimum_size = Vector2(620, 0)
	paper.add_child(v)
	v.add_child(mk.call("%s-RANK GÖREV%s" % [m.get("rank", "D"), "   •   KÖYE ÖZGÜ" if m.get("local", false) else ""], 14, Color(0.6, 0.15, 0.1), true))
	var tl = mk.call(String(m.get("title", "")), 30, ink, true)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(620, 0)
	v.add_child(tl)
	v.add_child(mk.call("Görevi veren: %s" % m.get("giver", "Görev masası"), 15, Color(0.35, 0.25, 0.15)))
	var br = mk.call(String(m.get("brief", m.get("desc", ""))), 17, ink)
	br.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	br.custom_minimum_size = Vector2(620, 0)
	v.add_child(br)
	v.add_child(mk.call("HEDEFLER", 14, Color(0.6, 0.15, 0.1), true))
	var steps: Array = m.get("steps", [])
	for i in steps.size():
		var row = UI.hbox(10)
		var num = PanelContainer.new()
		num.add_theme_stylebox_override("panel", UI._box(Color(0.6, 0.15, 0.1, 0.9), Color(0, 0, 0, 0), 0, 12, 2))
		num.custom_minimum_size = Vector2(24, 24)
		num.add_child(UI.label(str(i + 1), 13, Color(1, 0.95, 0.9), HORIZONTAL_ALIGNMENT_CENTER, true))
		row.add_child(num)
		var sl = mk.call(String(steps[i].get("text", "")), 15, ink)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size = Vector2(560, 0)
		row.add_child(sl)
		v.add_child(row)
	# ödüller + damga (sağ sütun)
	var rw = _rewards(m)
	var rv = UI.vbox(12)
	rv.position = Vector2(700, 60)
	paper.add_child(rv)
	rv.add_child(_rank_stamp(String(m.get("rank", "D")), 110))
	rv.add_child(mk.call("ÖDÜL", 14, Color(0.6, 0.15, 0.1), true))
	var r1 = UI.hbox(8)
	r1.add_child(Icons.view("coin", 22, Color(0.6, 0.42, 0.1)))
	r1.add_child(mk.call("%d Ryō" % rw[0], 18, ink, true))
	rv.add_child(r1)
	var r2 = UI.hbox(8)
	r2.add_child(Icons.view("star", 22, Color(0.6, 0.42, 0.1)))
	r2.add_child(mk.call("%d XP" % rw[1], 18, ink, true))
	rv.add_child(r2)
	if rw[2] > 0.0:
		var r3 = UI.hbox(8)
		r3.add_child(Icons.view("chest", 22, Color(0.6, 0.42, 0.1)))
		r3.add_child(mk.call("Ekipman %%%d" % int(rw[2] * 100), 15, ink))
		rv.add_child(r3)
	# hanko: kabul et
	var hanko = Button.new()
	hanko.text = "受\nKABUL ET"
	hanko.custom_minimum_size = Vector2(130, 130)
	hanko.add_theme_font_override("font", UI.font(true))
	hanko.add_theme_font_size_override("font_size", 17)
	var hn = UI._box(Color(0.72, 0.1, 0.08, 0.92), Color(0.45, 0.04, 0.03), 4, 65, 6)
	var hh = hn.duplicate()
	hh.bg_color = Color(0.85, 0.15, 0.1, 0.97)
	hh.shadow_color = Color(0.9, 0.2, 0.1, 0.5)
	hh.shadow_size = 14
	for k in [["normal", hn], ["hover", hh], ["pressed", hh], ["focus", hh]]:
		hanko.add_theme_stylebox_override(k[0], k[1])
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		hanko.add_theme_color_override(k, Color(1, 0.95, 0.9))
	hanko.position = Vector2(724, 420)
	hanko.rotation = deg_to_rad(-8)
	hanko.pressed.connect(func():
		Sfx.play("seal", null, 0.9)
		Hud.close_dialog()
		Missions.accept(m))
	UI.hover_anim(hanko, 1.06)
	paper.add_child(hanko)
	var back = UI.ink_button("‹  Diğer görevler", func(): mission_board(village_id), 220)
	back.position = Vector2(56, 524)
	paper.add_child(back)
	# açılma animasyonu: kâğıt yukarıdan aşağıya iner
	paper.scale = Vector2(1, 0.04)
	var tw = paper.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(paper, "scale:y", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var rods = [holder.get_child(1)]
	for rd in rods:
		rd.position.y = 0
		var t2 = rd.create_tween()
		t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t2.tween_property(rd, "position:y", 600.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh", null, 1.4, 0.4)


# ================================================================== Bingo Kitabı (açık kitap)
static var _bb_index := 0


static func bingo_book(main: Node = null) -> void:
	if not Missions.has_method("bingo_entries"):
		return
	var entries: Array = Missions.bingo_entries()
	Game.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg = _full(0.6)
	_close_button(bg, func():
		if Game.paused and main and main.has_method("resume"):
			main.resume()
		else:
			Hud.close_dialog())
	var book = Control.new()
	book.set_anchors_preset(Control.PRESET_CENTER)
	book.size = Vector2(1240, 720)
	book.position = Vector2(-620, -360)
	bg.add_child(book)
	if _fresh:
		UI.pop_in(book, 0.95)
	# kapak (koyu kırmızı deri)
	var cover = Panel.new()
	var csb = UI._box(Color(0.32, 0.06, 0.06), Color(0.15, 0.02, 0.02), 3, 18, 0)
	csb.shadow_color = Color(0, 0, 0, 0.6)
	csb.shadow_size = 30
	cover.add_theme_stylebox_override("panel", csb)
	cover.size = book.size
	book.add_child(cover)
	var pages = []
	for i in 2:
		var pg = ColorRect.new()
		var pm = ShaderMaterial.new()
		pm.shader = load("res://shaders/ui_parchment.gdshader")
		pm.set_shader_parameter("edge", 0.06)
		pm.set_shader_parameter("seed", 3.0 + i)
		pm.set_shader_parameter("paper", Color(0.95, 0.9, 0.78))
		pg.material = pm
		pg.position = Vector2(24 + i * 600, 22)
		pg.size = Vector2(592, 676)
		book.add_child(pg)
		pages.append(pg)
	var spine = ColorRect.new()
	spine.color = Color(0, 0, 0, 0.25)
	spine.position = Vector2(612, 22)
	spine.size = Vector2(16, 676)
	book.add_child(spine)
	var ink = Color(0.16, 0.1, 0.06)
	var red = Color(0.62, 0.1, 0.08)
	var mk = func(text: String, size: int, col: Color, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
		var l = UI.label(text, size, col, align, bold)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		return l
	var lp: Control = pages[0]
	var rp: Control = pages[1]
	if entries.is_empty():
		var l = mk.call("Bingo Kitabı boş.", 24, ink, true, HORIZONTAL_ALIGNMENT_CENTER)
		l.position = Vector2(0, 300)
		l.size = Vector2(592, 40)
		lp.add_child(l)
		return
	_bb_index = clampi(_bb_index, 0, entries.size() - 1)
	var e: Dictionary = entries[_bb_index]
	var dead = e.get("status", "alive") != "alive"
	# sol sayfa: portre + isim + ödül
	var head = mk.call("ビンゴブック   •   BINGO KİTABI", 14, red, true, HORIZONTAL_ALIGNMENT_CENTER)
	head.position = Vector2(0, 22)
	head.size = Vector2(592, 20)
	lp.add_child(head)
	var frame = Panel.new()
	frame.add_theme_stylebox_override("panel", UI._box(Color(0.2, 0.17, 0.14), Color(0.3, 0.2, 0.12), 6, 6, 0))
	frame.position = Vector2(146, 60)
	frame.size = Vector2(300, 340)
	lp.add_child(frame)
	if e.has("look") and e["look"] is Dictionary:
		var pv = _model_preview(e["look"], Vector3(0, 1.48, -1.75), Vector3(0, 1.4, 0), 30.0, false, Vector2(288, 328))
		pv.position = Vector2(6, 6)
		frame.clip_contents = true
		frame.add_child(pv)
		var mdl = pv.get_meta("model")
		if mdl:
			mdl.rotation.y = 0.0
	if dead:
		var x = Control.new()
		x.size = Vector2(300, 340)
		x.mouse_filter = Control.MOUSE_FILTER_IGNORE
		x.draw.connect(func():
			x.draw_line(Vector2(20, 20), Vector2(280, 320), Color(red, 0.85), 10.0, true)
			x.draw_line(Vector2(280, 20), Vector2(20, 320), Color(red, 0.85), 10.0, true))
		frame.add_child(x)
	var nm = mk.call(String(e.get("name", "?")), 30, ink, true, HORIZONTAL_ALIGNMENT_CENTER)
	nm.position = Vector2(0, 414)
	nm.size = Vector2(592, 40)
	lp.add_child(nm)
	var al = mk.call("«%s»" % e.get("alias", ""), 18, Color(0.4, 0.28, 0.18), false, HORIZONTAL_ALIGNMENT_CENTER)
	al.position = Vector2(0, 456)
	al.size = Vector2(592, 24)
	lp.add_child(al)
	var stampw = mk.call("YAKALANDI" if dead else "ARANIYOR", 40, Color(red, 0.85), true, HORIZONTAL_ALIGNMENT_CENTER)
	stampw.position = Vector2(150, 500)
	stampw.size = Vector2(292, 50)
	stampw.rotation = deg_to_rad(-6)
	lp.add_child(stampw)
	var bounty = mk.call("ÖDÜL: %d Ryō" % int(e.get("bounty", 0)), 26, ink, true, HORIZONTAL_ALIGNMENT_CENTER)
	bounty.position = Vector2(0, 570)
	bounty.size = Vector2(592, 34)
	lp.add_child(bounty)
	# sağ sayfa: ayrıntılar
	var v = UI.vbox(12)
	v.position = Vector2(50, 50)
	v.custom_minimum_size = Vector2(492, 0)
	rp.add_child(v)
	v.add_child(_rank_stamp(String(e.get("rank", "C")), 84))
	var info = [["Köy", "%s (kaçak)" % e.get("village_name", "?")], ["Tehlike", "%s-rank  •  Seviye ~%d" % [e.get("rank", "?"), int(e.get("level", 1))]],
		["Element", String(e.get("element", "?")).capitalize()], ["Son görüldüğü yer", "%s (~%d m alan)" % [e.get("region", "?"), int(e.get("known", 0))]]]
	for row in info:
		var r = UI.hbox(10)
		var k = mk.call(row[0], 15, Color(0.45, 0.32, 0.2), true)
		k.custom_minimum_size = Vector2(170, 0)
		r.add_child(k)
		var vl = mk.call(row[1], 16, ink)
		vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vl.custom_minimum_size = Vector2(310, 0)
		r.add_child(vl)
		v.add_child(r)
	v.add_child(mk.call("SUÇLARI", 14, red, true))
	var cr = mk.call("• " + "\n• ".join(e.get("crimes", [])), 16, ink)
	cr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cr.custom_minimum_size = Vector2(490, 0)
	v.add_child(cr)
	if String(e.get("rank", "")) in ["B", "A", "S"]:
		v.add_child(mk.call("Dikkat: yenilmek üzereyken kaçmaya çalışır.", 14, red))
	var id = int(e.get("id", 0))
	if not dead:
		var acts = UI.hbox(10)
		acts.position = Vector2(50, 560)
		rp.add_child(acts)
		var tracked = bool(e.get("tracked", false))
		acts.add_child(UI.primary("Takipte" if tracked else "Takip Et", func():
			Missions.track_bounty(id)
			bingo_book(main), 220, "target"))
		var cost = maxi(50, int(int(e.get("bounty", 0)) * 0.05))
		acts.add_child(UI.ink_button("Muhbire sor (%d Ryō)" % cost, func():
			Missions.ask_informant(id), 250))
	# sayfa çevirme
	var nav = UI.hbox(14)
	nav.position = Vector2(960, 640)
	book.add_child(nav)
	nav.add_child(UI.ink_button("◀", func():
		_bb_index = (_bb_index - 1 + entries.size()) % entries.size()
		bingo_book(main), 56))
	var pl = UI.label("%d / %d" % [_bb_index + 1, entries.size()], 18, Color(0.16, 0.1, 0.06), HORIZONTAL_ALIGNMENT_CENTER, true)
	pl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	pl.custom_minimum_size = Vector2(80, 42)
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nav.add_child(pl)
	nav.add_child(UI.ink_button("▶", func():
		_bb_index = (_bb_index + 1) % entries.size()
		bingo_book(main), 56))


# ================================================================== dükkân (ızgara + ayrıntı)
static var _shop_sel := ""


## entries: [{id, name, price, desc, stats, locked, lock_text, owned, view: Callable->Control, rarity}], buy: Callable(id)
static func shop_screen(title: String, entries: Array, buy: Callable) -> void:
	Game.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg = _full(0.55)
	var head = UI.label(title.to_upper(), 34, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	head.position = Vector2(110, 40)
	bg.add_child(head)
	var ryo = UI.icon_label("coin", "%d Ryō" % int(Game.profile.get("ryo", 0)), 20, UI.GOLD)
	ryo.anchor_left = 1.0; ryo.anchor_right = 1.0
	ryo.offset_left = -300; ryo.offset_top = 52
	bg.add_child(ryo)
	_close_button(bg, func(): Hud.close_dialog())
	var h = UI.hbox(28)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 110; h.offset_top = 110; h.offset_right = -60; h.offset_bottom = -60
	bg.add_child(h)
	var sc = ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h.add_child(sc)
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	var ids = entries.map(func(x): return x["id"])
	if not _shop_sel in ids and not entries.is_empty():
		_shop_sel = entries[0]["id"]
	var sel = {}
	for e in entries:
		var acc: Color = UI.RARITY[int(e.get("rarity", 0))]
		var t = _tile(e["view"].call(), "%s — %d" % [e["name"], int(e["price"])], acc if not e.get("locked", false) else Color(1, 1, 1, 0.12), e["id"] == _shop_sel, func():
			_shop_sel = e["id"]
			shop_screen(title, entries, buy), 132, "x%d" % int(e["owned"]) if int(e.get("owned", 0)) > 0 else "")
		if e.get("locked", false):
			t.modulate = Color(1, 1, 1, 0.55)
		grid.add_child(t)
		if e["id"] == _shop_sel:
			sel = e
	var right = UI.card()
	right.custom_minimum_size = Vector2(440, 0)
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(right)
	var rv = UI.vbox(12)
	right.add_child(rv)
	if sel.is_empty():
		rv.add_child(UI.label("Satılık bir şey yok.", 16, UI.MUTED))
		return
	var top = UI.hbox(16)
	var big = sel["view"].call()
	big.custom_minimum_size = Vector2(110, 110)
	top.add_child(big)
	var tv = UI.vbox(4)
	var nm = UI.label(sel["name"], 22, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size = Vector2(280, 0)
	tv.add_child(nm)
	var r = int(sel.get("rarity", 0))
	tv.add_child(UI.label(UI.RARITY_NAMES[r], 13, UI.RARITY[r], HORIZONTAL_ALIGNMENT_LEFT, true))
	if String(sel.get("stats", "")) != "":
		var st = UI.label(sel["stats"], 14, UI.GOOD)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		st.custom_minimum_size = Vector2(280, 0)
		tv.add_child(st)
	top.add_child(tv)
	rv.add_child(top)
	var d = UI.label(String(sel.get("desc", "")), 15, UI.MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(400, 0)
	rv.add_child(d)
	if int(sel.get("owned", 0)) > 0:
		rv.add_child(UI.label("Sende: %d" % int(sel["owned"]), 14, UI.MUTED))
	if sel.get("locked", false):
		rv.add_child(UI.icon_label("lock", String(sel.get("lock_text", "Kilitli")), 16, UI.BAD))
	else:
		var afford = int(Game.profile.get("ryo", 0)) >= int(sel["price"])
		var b = UI.primary("Satın al — %d Ryō" % int(sel["price"]), func():
			buy.call(sel["id"]), 400, "coin")
		b.disabled = not afford
		rv.add_child(b)
		if not afford:
			rv.add_child(UI.label("Yeterli Ryō yok.", 14, UI.BAD))


# ================================================================== dünya haritası + hızlı seyahat
static func world_map(main: Node) -> void:
	var bg = _full(0.7)
	var tex: Texture2D = load("res://data/world/map.png")
	var vp = bg.get_viewport_rect().size
	var side_w = 330.0
	var scale = minf((vp.x - side_w - 180) / tex.get_width(), (vp.y - 140) / tex.get_height())
	var sz = Vector2(tex.get_width(), tex.get_height()) * scale
	var frame = Panel.new()
	frame.add_theme_stylebox_override("panel", UI.glass(16, 0, 0.6))
	frame.position = Vector2(60, (vp.y - sz.y) * 0.5 + 10) - Vector2(10, 10)
	frame.size = sz + Vector2(20, 20)
	bg.add_child(frame)
	var tr = TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = sz
	tr.position = Vector2(60, (vp.y - sz.y) * 0.5 + 10)
	bg.add_child(tr)
	var title = UI.label("SHINOBİ DÜNYASI", 30, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	title.position = Vector2(tr.position.x, tr.position.y - 50)
	bg.add_child(title)
	var W = Game.hw * Game.res
	var H = Game.hh * Game.res
	var to_px = func(mx: float, my: float) -> Vector2:
		return Vector2((mx - Game.x0) / W * sz.x, (Game.y1 - my) / H * sz.y)
	for c in Game.world_info["countries"]:
		var l = UI.label(String(c["name"]).to_upper(), 13, Color(0.22, 0.16, 0.1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, true)
		l.add_theme_color_override("font_shadow_color", Color(1, 0.97, 0.9, 0.5))
		l.position = to_px.call(c["x"], c["y"]) + Vector2(-50, 24)
		tr.add_child(l)
	for v in Game.world_info["villages"]:
		var visited: bool = v["id"] in Game.profile.get("visited", [])
		var dot = Control.new()
		dot.position = to_px.call(v["x"], v["y"])
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.draw.connect(func():
			dot.draw_circle(Vector2.ZERO, 7, Color(0, 0, 0, 0.5))
			dot.draw_circle(Vector2.ZERO, 5, Color(0.85, 0.15, 0.1) if visited else Color(0.4, 0.35, 0.3)))
		tr.add_child(dot)
		var l = UI.label(v["name"], 13, Color(0.15, 0.08, 0.05) if visited else Color(0.35, 0.3, 0.25), HORIZONTAL_ALIGNMENT_LEFT, true)
		l.add_theme_color_override("font_shadow_color", Color(1, 0.97, 0.9, 0.6))
		l.position = to_px.call(v["x"], v["y"]) + Vector2(9, -10)
		tr.add_child(l)
	for l in Game.world_info["landmarks"]:
		var lb = UI.label("· " + l["name"], 11, Color(0.3, 0.25, 0.4))
		lb.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.3))
		lb.position = to_px.call(l["x"], l["y"]) - Vector2(4, 8)
		tr.add_child(lb)
	if Game.player:
		var pm = Game.to_map(Game.player.global_position)
		var me = Control.new()
		me.position = to_px.call(pm.x, pm.y)
		me.mouse_filter = Control.MOUSE_FILTER_IGNORE
		me.draw.connect(func():
			me.draw_circle(Vector2.ZERO, 11, Color(0.2, 0.55, 1.0, 0.35))
			me.draw_circle(Vector2.ZERO, 6, Color(0.25, 0.6, 1.0))
			me.draw_arc(Vector2.ZERO, 6, 0, TAU, 20, Color.WHITE, 2.0, true))
		tr.add_child(me)
	if Missions.has_marker:
		var mm = Game.to_map(Missions.target_marker)
		var mk = Icons.view("target", 30, UI.GOLD)
		mk.position = to_px.call(mm.x, mm.y) - Vector2(15, 15)
		tr.add_child(mk)
	# yan panel: hızlı seyahat
	var side = PanelContainer.new()
	side.add_theme_stylebox_override("panel", UI.glass(16, 20, 0.8))
	side.anchor_left = 1.0; side.anchor_right = 1.0
	side.offset_left = -side_w - 40; side.offset_right = -40; side.offset_top = 100
	side.custom_minimum_size = Vector2(side_w, 0)
	bg.add_child(side)
	var sv = UI.vbox(8)
	side.add_child(sv)
	sv.add_child(UI.header("HIZLI SEYAHAT", 18))
	sv.add_child(UI.label("Keşfettiğin köylere ışınlan.", 13, UI.MUTED))
	for v in Game.world_info["villages"]:
		var visited: bool = v["id"] in Game.profile.get("visited", [])
		if not visited:
			continue
		var vid: String = v["id"]
		sv.add_child(UI.button(v["name"], func(): main.fast_travel(vid), side_w - 40, "village"))
	sv.add_child(UI.spacer(0, 10, false))
	sv.add_child(UI.icon_label("person", "Sen", 14, Color(0.4, 0.7, 1.0)))
	sv.add_child(UI.icon_label("target", "Görev hedefi", 14, UI.GOLD))
	_close_button(bg, func(): main.resume())
