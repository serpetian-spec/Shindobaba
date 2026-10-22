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


static func _full() -> Control:
	clear()
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.dialog_layer.add_child(bg)
	return bg


static func _center_panel(parent: Control, w := 560.0) -> VBoxContainer:
	var p = UI.panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(w, 0)
	parent.add_child(p)
	var v = UI.vbox(10)
	p.add_child(v)
	p.resized.connect(func(): p.position = -p.size * 0.5, CONNECT_DEFERRED)
	return v


# ------------------------------------------------------------------ ana menü
static func main_menu(main: Node) -> void:
	clear()
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	Hud.dialog_layer.add_child(root)
	var logo = UI.label("SHINOBI YOLU", 96, UI.ACCENT)
	logo.position = Vector2(80, 70)
	root.add_child(logo)
	var sub = UI.label("Beş Büyük Ülke'nin dünyasında kendi efsaneni yaz", 22, Color(1, 0.95, 0.85))
	sub.position = Vector2(86, 190)
	root.add_child(sub)
	var v = UI.vbox(12)
	v.position = Vector2(90, 280)
	root.add_child(v)
	v.add_child(UI.button("Yeni Oyun", func(): slot_select(main, true), 340))
	v.add_child(UI.button("Devam Et", func(): slot_select(main, false), 340))
	v.add_child(UI.button("Ayarlar", func(): settings(func(): main_menu(main)), 340))
	v.add_child(UI.button("Çıkış", func(): main.get_tree().quit(), 340))
	var ver = UI.label("v%s %s   •   Kanon karakter içermez; Naruto evreninde geçen özgün bir hikâye." % [Game.version, "(TEST)" if Game.build_tag == "test" else ""], 14, Color(0.85, 0.85, 0.85))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(20, -34)
	root.add_child(ver)


static func slot_select(main: Node, new_game: bool) -> void:
	var bg = _full()
	var v = _center_panel(bg)
	v.add_child(UI.label("Yeni Oyun — Kayıt Yuvası Seç" if new_game else "Kayıt Yükle", 28, UI.ACCENT))
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
	var p = UI.panel()
	p.position = Vector2(30, 30)
	p.custom_minimum_size = Vector2(520, 0)
	Hud.dialog_layer.add_child(p)
	var v = UI.vbox(8)
	p.add_child(v)
	v.add_child(UI.label("KARAKTERİNİ YARAT", 30, UI.ACCENT))
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
	row.call("Üst Rengi", "top", outfit_cols, ["Lacivert", "Siyah", "Bordo", "Turuncu", "Yeşil", "Mor", "Krem", "Petrol"])
	row.call("Alt Rengi", "pants", outfit_cols, ["Lacivert", "Siyah", "Bordo", "Turuncu", "Yeşil", "Mor", "Krem", "Petrol"])
	var skin = [Color(0.96, 0.8, 0.66), Color(0.86, 0.68, 0.52), Color(0.68, 0.5, 0.36), Color(0.98, 0.88, 0.8)]
	row.call("Ten", "skin", skin, ["Açık", "Buğday", "Esmer", "Çok açık"])
	if not state["clan"] in ["uchiha", "hyuga", "aburame"]:
		var eye_cols = [Color(0.25, 0.45, 0.8), Color(0.3, 0.2, 0.12), Color(0.25, 0.55, 0.3), Color(0.1, 0.1, 0.1), Color(0.6, 0.4, 0.15)]
		row.call("Göz Rengi", "eye", eye_cols, ["Mavi", "Kahve", "Yeşil", "Siyah", "Kehribar"])
	v.add_child(UI.label("İpucu: fareyle önizlemeyi döndür", 13, Color(0.7, 0.7, 0.7)))
	var h = UI.hbox(10)
	h.add_child(UI.button("Geri", func(): main.back_to_menu(), 200))
	h.add_child(UI.button("Maceraya Başla!", on_start, 280))
	v.add_child(h)


# ------------------------------------------------------------------ duraklatma
static func pause(main: Node) -> void:
	var bg = _full()
	var v = _center_panel(bg, 420)
	v.add_child(UI.label("DURAKLATILDI", 32, UI.ACCENT, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.button("Devam", func(): main.resume(), 380))
	v.add_child(UI.button("Envanter [I]", func(): inventory(main), 380))
	v.add_child(UI.button("Jutsu ve Yetenekler [K]", func(): jutsu_skills(main), 380))
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
	v.add_child(UI.label("KONTROLLER", 28, UI.ACCENT))
	var t = """WASD: hareket   •   Fare: kamera   •   Tekerlek: yakınlaştır
Ctrl / Space: zıpla (havada tekrar = çift zıplama)   •   Shift: ninja koşusu, havada dash
Duvara doğru koş: DUVARDA KOŞ (W yukarı, A/D yana)   •   Duvardayken Ctrl: duvardan sek
Sol tık: kombo (havada: dalış tekmesi)   •   Sağ tık (basılı): blok (tam zamanında = mükemmel blok)
Q: Kawarimi (yer değiştirme)   •   C (basılı): chakra şarjı   •   R: kunai/alet   •   T: alet değiştir
Tab / orta tık: hedefe kilitlen   •   Kilitliyken Shift: chakra dash
1-4: jutsu slotları   •   F: etkileşim   •   H: merhem   •   Y: asker hapı
G (basılı) + 1-9,0,-,=: mühür ör (bırakınca jutsu / yeni jutsu keşfi)   •   V: Sharingan/Byakugan
B: Sekiz Kapı (klansız)   •   Z: Sennin Modu   •   X: Kuyruklu Canavar modu / bombası
I: envanter   •   K: jutsu/yetenekler   •   M: dünya haritası   •   Esc: menü"""
	var l = UI.label(t, 17)
	v.add_child(l)
	v.add_child(UI.button("Geri", func(): pause(main), 720))


# ------------------------------------------------------------------ ayarlar
static func settings(back: Callable) -> void:
	var bg = _full()
	var v = _center_panel(bg, 560)
	v.add_child(UI.label("AYARLAR", 28, UI.ACCENT))
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


# ------------------------------------------------------------------ envanter
static func inventory(main: Node) -> void:
	var bg = _full()
	var v = _center_panel(bg, 620)
	var pr = Game.profile
	v.add_child(UI.label("ENVANTER   (%d Ryō)" % int(pr["ryo"]), 28, UI.ACCENT))
	var inv: Dictionary = pr["inventory"]
	if inv.is_empty():
		v.add_child(UI.label("Çantan boş.", 16))
	for id in inv.keys():
		if int(inv[id]) <= 0:
			continue
		var it: Dictionary = Data.items.get(id, {"name": id, "desc": "", "kind": "misc"})
		var h = UI.hbox(8)
		var l = UI.label("%s  x%d — %s" % [it["name"], int(inv[id]), it.get("desc", "")], 16)
		l.custom_minimum_size = Vector2(440, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(l)
		if it.get("kind", "") == "throw":
			h.add_child(UI.button("Seç" if pr["throw_sel"] != id else "Seçili", func():
				pr["throw_sel"] = id
				inventory(main), 110))
		elif it.get("kind", "") == "use":
			h.add_child(UI.button("Kullan", func():
				main.use_item(id)
				inventory(main), 110))
		v.add_child(h)
	v.add_child(UI.button("Geri", func(): pause(main), 580))


# ------------------------------------------------------------------ jutsu + yetenek ağacı
static func jutsu_skills(main: Node, picked := "") -> void:
	var bg = _full()
	var p = UI.panel()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-640, -380)
	p.custom_minimum_size = Vector2(1280, 760)
	bg.add_child(p)
	var cols = UI.hbox(24)
	p.add_child(cols)
	var pr = Game.profile
	# sol: öğrenilen jutsular
	var left = UI.vbox(6)
	left.custom_minimum_size = Vector2(600, 0)
	cols.add_child(left)
	left.add_child(UI.label("JUTSULAR  — bir jutsu seç, sonra slota ata", 22, UI.ACCENT))
	var learned: Array = pr["learned"]
	if learned.is_empty():
		left.add_child(UI.label("Henüz bir jutsu bilmiyorsun. Akademi hocanla konuş!", 16))
	for jid in learned:
		var j: Dictionary = Data.jutsu.get(jid, {})
		var seals: Array = j.get("seals", [])
		var b = UI.button("%s  [%s] — %d ck%s" % [j.get("name", jid), j.get("canon_rank", "?"), int(j.get("cost", 0)), ("  •  " + "-".join(seals)) if not seals.is_empty() else ""],
			func(): jutsu_skills(main, jid), 590)
		b.tooltip_text = j.get("desc", "")
		if jid == picked:
			b.modulate = Color(1, 0.8, 0.5)
		left.add_child(b)
	var sh = UI.hbox(6)
	for i in 4:
		var cur = pr["slots"][i]
		var nm: String = Data.jutsu.get(cur, {}).get("name", "—") if cur != null and cur != "" else "—"
		sh.add_child(UI.button("[%d] %s" % [i + 1, nm.split(":")[-1].strip_edges()], func():
			if picked != "":
				for k in 4:
					if pr["slots"][k] == picked:
						pr["slots"][k] = ""
				pr["slots"][i] = picked
			jutsu_skills(main), 142))
	left.add_child(UI.label("Slotlar:", 16))
	left.add_child(sh)
	# sağ: yetenek ağacı
	var right = UI.vbox(6)
	right.custom_minimum_size = Vector2(600, 0)
	cols.add_child(right)
	right.add_child(UI.label("YETENEK AĞACI  — Puan: %d" % int(pr["sp"]), 22, UI.ACCENT))
	var cat = ""
	for sid in SKILLS:
		var s: Array = SKILLS[sid]
		if s[2] != cat:
			cat = s[2]
			right.add_child(UI.label(cat, 18, Color(1, 0.85, 0.6)))
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
			jutsu_skills(main), 590)
		b.disabled = not can
		if owned:
			b.modulate = Color(0.6, 1, 0.6)
		right.add_child(b)
	right.add_child(UI.button("Geri", func(): pause(main), 590))


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
	var title = UI.label("SHINOBİ DÜNYASI — keşfettiğin köylere tıkla: hızlı seyahat", 22, UI.ACCENT)
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
