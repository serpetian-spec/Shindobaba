class_name Menus
extends RefCounted
## Tam ekran menüler (modern): bulanık oyun arka planı, sol simge rayı, cam paneller, simgeli kartlar.
## Hepsi Hud.dialog_layer'a eklenir.

## Yetenek ağacı verisi: data/skills.json (tools/build_skills.py), ekran: SkillTree
const SKILL_ICONS := {"Taijutsu": "hand", "Ninjutsu": "chakra", "Destek": "heart"}

static var _fresh := false


static func clear() -> void:
	# Ninja menüsü kapanırken/yenilenirken açık sekmenin kaydırma konumunu hatırla (yeniden açınca kaldığın yerden)
	if _menu_open and _last_tab != "":
		_scroll_mem[_last_tab] = _scroll_positions()
	_menu_open = false
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


## Gözler sekmesi: sağ göz / sol göz durumu, uyanış, kavanozdaki gözler, Susanoo; tuşlar
## Taşınan kuyruklu canavarlar (biri aktif) + mühür kabındakiler (içine aktarılabilir)
static func _tab_beasts(main: Node, body: Control) -> void:
	var sc = ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var v = UI.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var held: Array = TailedBeasts.held()
	var jar: Array = TailedBeasts.jarred()
	if held.is_empty() and jar.is_empty():
		v.add_child(UI.label("Hiç kuyruklu canavarın yok. Bir canavarı yenip [F] ile mühürle: içine (Jinchūriki) ya da mühür kabına.", 17, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		return
	var act = TailedBeasts.player_jinchuriki()
	v.add_child(UI.label("İÇİNDEKİLER  (aktif olan: X pelerin / dönüşüm / zihin dünyası)", 18, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	for id in held:
		v.add_child(_beast_row(main, id, "held", id == act))
	if not jar.is_empty():
		v.add_child(HSeparator.new())
		v.add_child(UI.label("MÜHÜR KABINDAKİLER", 18, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
		for id in jar:
			v.add_child(_beast_row(main, id, "jar", false))


static func _beast_row(main: Node, id: String, where: String, active: bool) -> Control:
	var inf: Dictionary = BeastModels.INFO.get(id, {})
	var col: Color = inf.get("chakra", UI.GOLD)
	var card = UI.card(col if active else Color(0, 0, 0, 0))
	var h = UI.hbox(16)
	card.add_child(h)
	var tv = UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	tv.add_child(UI.label(String(inf.get("name", id)) + ("   — AKTİF" if active else ""), 20, col, HORIZONTAL_ALIGNMENT_LEFT, true))
	var tr = TailedBeasts.trust(id)
	tv.add_child(UI.label(("Güven %d / 100" % int(tr)) if where == "held" else "Mühür kabında uyuyor. İçine aktarırsan chakrasını kullanabilirsin (güven sıfırdan başlar).", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	if where == "held" and not active:
		h.add_child(UI.button("Aktif yap", func():
			TailedBeasts.set_active(id)
			ninja_menu(main, "beasts"), 200, "check"))
	elif where == "jar":
		h.add_child(UI.button("İçime aktar", func():
			TailedBeasts.transfer_from_jar(id)
			ninja_menu(main, "beasts"), 200, "seal"))
	return card


## İmzalı sözleşmeler: aktif sözleşme ve çağrılacak kademe seçimi
static func _tab_summons(main: Node, body: Control) -> void:
	Contracts.ensure()
	var pr = Game.profile
	var sc = ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var v = UI.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var cs: Dictionary = pr.get("contracts", {})
	if cs.is_empty():
		v.add_child(UI.label("Hiçbir hayvanla sözleşmen yok. Gizli bilgelerin diyarlarını bul ya da köy sözleşme ustalarına danış.", 17, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		return
	var act = Contracts.active()
	for id in cs:
		if not Contracts.DEFS.has(id):
			continue
		var d: Dictionary = Contracts.DEFS[id]
		var card = UI.card(d["color"] if id == act else Color(0, 0, 0, 0))
		v.add_child(card)
		var cv = UI.vbox(8)
		card.add_child(cv)
		var top = UI.hbox(16)
		cv.add_child(top)
		var t = UI.label("%s%s" % [d["name"], "   — AKTİF" if id == act else ""], 20, d["color"], HORIZONTAL_ALIGNMENT_LEFT, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(t)
		top.add_child(UI.label("Ustalık %d" % int(Contracts.mastery(id)), 15, UI.MUTED))
		if id != act:
			top.add_child(UI.button("Aktif yap", func():
				pr["summon"] = id
				Game.save_game()
				ninja_menu(main, "summons"), 180, "check"))
		var pref = int(cs[id].get("tier_pref", -1))
		var row = UI.hbox(10)
		cv.add_child(row)
		row.add_child(UI.button(("● " if pref < 0 else "") + "Otomatik (en büyüğü)", func():
			cs[id]["tier_pref"] = -1
			ninja_menu(main, "summons"), 220))
		var tiers: Dictionary = d["tiers"]
		for tk in [0, 1, 2]:
			if not tiers.has(tk):
				continue
			var td: Dictionary = tiers[tk]
			var ok = int(pr["level"]) >= Contracts.TIER_LEVEL[tk] and Contracts.mastery(id) >= Contracts.TIER_MASTERY[tk]
			var lbl = ("● " if pref == tk else "") + String(td["name"]) + ("" if ok else "  (Güç %d, ustalık %d)" % [Contracts.TIER_LEVEL[tk], int(Contracts.TIER_MASTERY[tk])])
			var b = UI.button(lbl, func():
				cs[id]["tier_pref"] = tk
				ninja_menu(main, "summons"), 260)
			b.disabled = not ok
			row.add_child(b)


static func _tab_eyes(main: Node, body: Control) -> void:
	var pr = Game.profile
	# 1600 px tasarım genişliğinde iki kart + yan sütun ekrandan taşıyordu: tuşlar artık kartların üstünde yatay şerit
	var outer = UI.vbox(12)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(outer)
	var strip = HFlowContainer.new()
	strip.add_theme_constant_override("h_separation", 22)
	strip.add_theme_constant_override("v_separation", 6)
	outer.add_child(strip)
	for k in [["V", "Gözleri aç / kapat"], ["K", "Göz teknikleri jutsu yuvalarına"], ["V (basılı)", "Susanoo (iki göz Mangekyō)"], ["F", "Düşmüş dōjutsu sahibinin gözlerini al"]]:
		var r = UI.hbox(8)
		r.add_child(UI.key_badge(k[0], 13))
		r.add_child(UI.label(k[1], 14, UI.TEXT))
		strip.add_child(r)
	if Susanoo.max_tier(pr) > 0:
		var sr = UI.hbox(10)
		sr.add_child(UI.label("Susanoo: Kademe %d" % Susanoo.cur_tier(pr), 15, Color(0.75, 0.6, 1.0)))
		sr.add_child(UI.button("Susanoo'yu Özelleştir", func():
			_eq_slot = "susanoo"
			ninja_menu(main, "wardrobe"), 240))
		strip.add_child(sr)
	var h = UI.hbox(22)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(h)
	for sl in ["sag_goz", "sol_goz"]:
		var card = UI.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(card)
		var sc = ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.custom_minimum_size = Vector2(420, 480)
		card.add_child(sc)
		var v = UI.vbox(10)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		v.add_child(UI.label("SAĞ GÖZ" if sl == "sag_goz" else "SOL GÖZ", 20, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
		_eq_slot = sl
		_eye_panel(main, v, pr)
	_eq_slot = "set"


## Gözler eşya değil, bedenin parçası: durum, uyanış ilerlemesi, saklanan gözler (nakil hastanede)
static func _eye_panel(main: Node, dv: VBoxContainer, pr: Dictionary) -> void:
	var cur = Gear.equipped(pr, _eq_slot)
	var side = "Sağ" if _eq_slot == "sag_goz" else "Sol"
	if cur.is_empty():
		dv.add_child(UI.label("%s gözün normal bir göz." % side, 16, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		var cl = Data.clans.get(String(pr.get("clan", "")), {})
		if cl.has("dojutsu"):
			dv.add_child(UI.label("Soyunda bir göz tekniği var ama henüz uyanmadı. Ölümcül bir dövüşte, hayatın tehlikedeyken uyanabilir.", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	else:
		var it = Gear.item(cur["id"])
		var e: Dictionary = it.get("eye", {})
		var lvl = int(cur.get("lvl", 3))
		var title = String(e.get("name", it["name"]))
		if int(e.get("kind", 0)) == 1:
			title += "  (%d tomoe)" % lvl
		dv.add_child(UI.label(title, 22, Color(1, 0.45, 0.45), HORIZONTAL_ALIGNMENT_LEFT, true))
		dv.add_child(UI.label("%s göz  •  %s" % [side, "doğuştan" if cur.get("origin", "dogustan") == "dogustan" else "nakil (daha çok chakra harcar)"], 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		var d = UI.label(String(it.get("desc", "")), 14, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dv.add_child(d)
		var k = int(e.get("kind", 0))
		if k == 1 and lvl < 3:
			var xp = float(cur.get("xp", 0.0))
			var need = 600.0 * lvl   # Eyes.gd ile aynı: gözler açık + 25 m içinde düşman varken geçen saniye
			dv.add_child(UI.label("Sonraki tomoe: Sharingan açıkken düşmanla dövüşerek  %d:%02d / %d dk" % [int(xp) / 60, int(xp) % 60, int(need) / 60], 14, Color(1, 0.7, 0.6), HORIZONTAL_ALIGNMENT_LEFT, true))
		elif k == 1 and lvl >= 3:
			dv.add_child(UI.label("Mangekyō, en yakınını kendi ellerinle öldürmenin ya da yanında savaşan bir dostun gözlerinin önünde ölmesinin acısıyla uyanır...", 14, Color(1, 0.7, 0.6), HORIZONTAL_ALIGNMENT_LEFT, true))
		var sk = Eyes.SKILLS.get(k, [])
		if not sk.is_empty():
			var si = sk[0 if _eq_slot == "sag_goz" else 1]
			dv.add_child(UI.label("Göz tekniği: %s  (Jutsular sekmesinden yuvaya koy)" % Eyes.eye_skill_label(pr, "sag" if _eq_slot == "sag_goz" else "sol", k), 15, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
		if k in [4, 5]:
			_ms_editor(main, dv, Eyes.design_for(pr, _eq_slot))
		# gözü çıkar: kavanoza konur, yerine normal göz kalır (geri takmak için aşağıdaki listeden)
		var slot_now = _eq_slot
		dv.add_child(UI.button("Gözü çıkar (kavanoza koy)", func():
			Hud.dialog("Gözü Çıkar", "%s %s gözünden çıkarılıp kavanoza konacak. Göz teknikleri bu gözle kullanılamaz. Emin misin?" % [title, side.to_lower()], [
				{"label": "Evet, çıkar", "cb": func():
					_eye_remove(pr, slot_now)
					ninja_menu(main, "eyes")},
				{"label": "Vazgeç", "cb": func(): ninja_menu(main, "eyes")}]), 380, "close"))
		dv.add_child(UI.button("Gözü yok et", func():
			Hud.dialog("Gözü Yok Et", "%s %s gözünden çıkarılıp tamamen yok edilecek. Geri dönüşü yok. Emin misin?" % [title, side.to_lower()], [
				{"label": "Evet, yok et", "cb": func():
					_eye_destroy(pr, int(Gear.equipped(pr, slot_now).get("uid", -1)))
					ninja_menu(main, "eyes")},
				{"label": "Vazgeç", "cb": func(): ninja_menu(main, "eyes")}]), 380, "close"))
	# saklanan gözler (kavanozda)
	var jars = []
	for g in pr.get("gear", []):
		if Gear.item(g["id"]).get("slot", "") == "goz" and not Gear.is_equipped(pr, g):
			jars.append(g)
	dv.add_child(HSeparator.new())
	dv.add_child(UI.label("SAKLANAN GÖZLER (%d)" % jars.size(), 16, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	if jars.is_empty():
		dv.add_child(UI.label("Kavanozunda göz yok. Yendiğin dōjutsu sahiplerinin gözlerini alabilirsin.", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var slot_here = _eq_slot
	for g in jars:
		var gname = "%s%s" % [Gear.item(g["id"])["name"], ("  (%d tomoe)" % int(g.get("lvl", 3))) if g["id"] == "goz_sharingan" else ""]
		var own = String(g.get("origin", "dogustan")) == "dogustan" and bool(g.get("own", false))
		var row = UI.hbox(8)
		row.add_child(UI.label("• " + gname, 14, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		dv.add_child(row)
		if own:
			# kendi çıkardığın gözü geri takmak nakil gerektirmez
			var uid = int(g["uid"])
			dv.add_child(UI.button("Bu göze geri tak", func():
				_eye_insert(pr, uid, slot_here)
				ninja_menu(main, "eyes"), 300, "eye"))
		var juid = int(g["uid"])
		dv.add_child(UI.button("Yok et", func():
			Hud.dialog("Gözü Yok Et", "%s kavanozdan atılıp yok edilecek. Emin misin?" % gname, [
				{"label": "Evet, yok et", "cb": func():
					_eye_destroy(pr, juid)
					ninja_menu(main, "eyes")},
				{"label": "Vazgeç", "cb": func(): ninja_menu(main, "eyes")}]), 200, "close"))
	if not EyeSurgery.options("self").is_empty():
		if EyeSurgery.can_self(pr):
			dv.add_child(UI.button("Kendi tıbbi ninjutsunla nakil yap (tutma %%%d)" % int(round(EyeSurgery.self_chance(pr) * 100.0)), func():
				Hud.dialog("Kendi Ameliyatın", "Düşman yokken oturup gözünü kendin değiştireceksin. Beden ağır yıpranır; tutmazsa göz bozulur.", EyeSurgery.options("self")), 420, "eye"))
		else:
			dv.add_child(UI.label("Kendi naklini yapmak için Shōsen (tıbbi ninjutsu) ve en az 50 chakra kontrolü ustalığı gerekir.", 13, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	dv.add_child(UI.label("Başkasından alınan gözü köy hastanesi takmaz (kanon: klan gözü klanın malıdır). Nakli takımındaki tıbbi ninja sahada yapar (Rin–Kakashi), kendi tıbbi ninjutsunla yaparsın ya da yeraltındaki Kara Cerrah gizlice takar.", 13, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	# uzun açıklamalar tek satır kalınca paneli genişletip sol göz kutusunu ekranın dışına itiyordu (her çözünürlükte): satırları kaydır
	for l in dv.get_children():
		if l is Label:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = 0.0


## Takılı gözü kavanoza koyar (yuvası boşalır = normal göz); açık gözler kapanır
static func _eye_remove(pr: Dictionary, slot: String) -> void:
	var g = Gear.equipped(pr, slot)
	if g.is_empty():
		return
	g["own"] = String(g.get("origin", "dogustan")) == "dogustan"
	pr["equip"].erase(slot)
	_eye_refresh(pr)
	Hud.msg("Göz çıkarıldı ve kavanoza kondu.", Color(1, 0.8, 0.6))


## Gözü tamamen yok eder (takılıysa önce yuvası boşalır = normal göz)
static func _eye_destroy(pr: Dictionary, uid: int) -> void:
	var g = Gear.find(pr, uid)
	if g.is_empty():
		return
	for s in pr["equip"].keys():
		if int(pr["equip"][s]) == uid:
			pr["equip"].erase(s)
	pr["gear"].erase(g)
	_eye_refresh(pr)
	Hud.msg("Göz yok edildi.", Color(1, 0.7, 0.6))


static func _eye_insert(pr: Dictionary, uid: int, slot: String) -> void:
	var cur = Gear.equipped(pr, slot)
	if not cur.is_empty():
		cur["own"] = String(cur.get("origin", "dogustan")) == "dogustan"
	pr["equip"][slot] = uid
	_eye_refresh(pr)
	Hud.msg("Göz yerine takıldı.", Color(0.7, 1, 0.7))


static func _eye_refresh(pr: Dictionary) -> void:
	var eyes = null
	if Game.player and Game.player.get("combat") and Game.player.combat.get("modes") and Game.player.combat.modes.get("eyes"):
		eyes = Game.player.combat.modes.eyes
	if eyes and eyes.active:
		eyes._close()
	Gear.apply_look(pr)
	if Game.player:
		Game.player.rebuild_model()
		Game.player.apply_profile_stats()
	if eyes:
		eyes.refresh_visual()


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
	var keep_scroll = _scroll_positions() if Hud.dialog_layer.get_child_count() > 0 and Hud.dialog_layer.get_child(0).has_meta("creator") else []
	clear()
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_meta("creator", true)
	Hud.dialog_layer.add_child(root)
	var redraw = func(): creator(main, state, on_change, on_start)
	# sol panel: başlık, sekmeler, seçenek kartları
	var pnl = PanelContainer.new()
	pnl.add_theme_stylebox_override("panel", UI.glass(18, 22, 0.86))
	pnl.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	pnl.offset_left = 28; pnl.offset_top = 28; pnl.offset_bottom = -28; pnl.offset_right = 608
	root.add_child(pnl)
	var outer = UI.vbox(14)
	pnl.add_child(outer)
	var head = UI.vbox(2)
	head.add_child(UI.header("KARAKTERİNİ YARAT", 28))
	head.add_child(UI.label("Shinobi yolun burada başlıyor. Oklarla seçenekler arasında gezin.", 13, UI.MUTED))
	outer.add_child(head)
	var tabs = UI.hbox(8)
	for t in [["kimlik", "person", "Kimlik"], ["gorunum", "hair", "Görünüm"], ["kiyafet", "shirt", "Kıyafet"]]:
		var tb = UI.chip(t[2], _ctab == t[0], func():
			_ctab = t[0]
			if main.has_method("_frame_creator_cam"):
				main._frame_creator_cam()
			redraw.call(), 170)
		tb.icon = Icons.tex(t[1], 40, UI.INK if _ctab == t[0] else UI.TEXT)
		tb.expand_icon = false
		tb.add_theme_constant_override("icon_max_width", 20)
		tb.custom_minimum_size = Vector2(170, 44)
		tabs.add_child(tb)
	outer.add_child(tabs)
	var sep = ColorRect.new()
	sep.color = Color(UI.GOLD, 0.25)
	sep.custom_minimum_size = Vector2(0, 1)
	outer.add_child(sep)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sc)
	var v = UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var card = func() -> VBoxContainer:
		var pc = PanelContainer.new()
		pc.add_theme_stylebox_override("panel", UI._box(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.08), 1, 12, 12))
		v.add_child(pc)
		var cv = UI.vbox(8)
		pc.add_child(cv)
		return cv
	# seçim yan etkileri (köy -> önerilen doğa, klan -> klan doğası)
	var pick = func(key: String, val) -> void:
		state[key] = val
		if key == "village" and Progress.HOME_VILLAGES.has(val):
			state["element"] = Progress.HOME_VILLAGES[val]["element"]
		if key == "clan" and String(ClanWorld.MAIN_EL.get(val, "")) in ["katon", "suiton", "fuuton", "doton", "raiton"]:
			state["element"] = ClanWorld.MAIN_EL[val]   # klan teknikleri bu doğayı ister
		on_change.call()
		redraw.call()
	# ◀ Ad ▶ oklu seçici (Mangekyō desen seçicisi gibi)
	var carousel = func(title: String, key: String, options: Array, labels: Array, col := UI.CREAM) -> VBoxContainer:
		var cv: VBoxContainer = card.call()
		var n = options.size()
		var idx = maxi(0, options.find(state.get(key)))
		var row = UI.hbox(10)
		var tl = UI.label(title.to_upper(), 13, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
		tl.custom_minimum_size = Vector2(120, 0)
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tl)
		row.add_child(_arrow_btn("◀", func(): pick.call(key, options[posmod(idx - 1, n)])))
		var mid = UI.vbox(2)
		mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid.add_child(UI.label(String(labels[idx]), 19, col, HORIZONTAL_ALIGNMENT_CENTER, true))
		# konum noktaları (az seçenekte) ya da sayaç
		if n <= 12:
			var dots = UI.hbox(4)
			dots.alignment = BoxContainer.ALIGNMENT_CENTER
			for i in n:
				var d = ColorRect.new()
				d.custom_minimum_size = Vector2(14 if i == idx else 6, 4)
				d.color = UI.GOLD if i == idx else Color(1, 1, 1, 0.2)
				d.mouse_filter = Control.MOUSE_FILTER_IGNORE
				dots.add_child(d)
			mid.add_child(dots)
		else:
			mid.add_child(UI.label("%d / %d" % [idx + 1, n], 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		row.add_child(mid)
		row.add_child(_arrow_btn("▶", func(): pick.call(key, options[posmod(idx + 1, n)])))
		cv.add_child(row)
		return cv
	var swatches = func(title: String, key: String, cols: Array) -> void:
		var cv: VBoxContainer = card.call()
		cv.add_child(UI.label(title.to_upper(), 13, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
		var fl = HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 8)
		fl.add_theme_constant_override("v_separation", 8)
		for c in cols:
			fl.add_child(_swatch(c, Color(state.get(key, Color.BLACK)).is_equal_approx(c), func():
				state[key] = c
				on_change.call()
				redraw.call()))
		cv.add_child(fl)
	var note = func(cv: VBoxContainer, text: String, col := UI.MUTED) -> void:
		var l = UI.label(text, 13, col)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(480, 0)
		cv.add_child(l)
	var el_names = {"katon": "Ateş", "suiton": "Su", "fuuton": "Rüzgâr", "doton": "Toprak", "raiton": "Yıldırım"}
	match _ctab:
		"kimlik":
			var nc: VBoxContainer = card.call()
			nc.add_child(UI.label("İSİM", 13, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
			var name_edit = LineEdit.new()
			name_edit.text = state["name"]
			name_edit.placeholder_text = "Ninja adın (boş kalırsa rastgele)"
			name_edit.max_length = 18
			name_edit.custom_minimum_size = Vector2(0, 46)
			name_edit.add_theme_font_size_override("font_size", 20)
			name_edit.text_changed.connect(func(t): state["name"] = t)
			nc.add_child(name_edit)
			carousel.call("Cinsiyet", "gender", ["m", "f"], ["Erkek", "Kadın"])
			var vids = Progress.HOME_VILLAGES.keys()
			var vc: VBoxContainer = carousel.call("Köy", "village", vids, vids.map(func(x): return Game.village(x).get("name", x)))
			var vinfo = Progress.HOME_VILLAGES.get(state.get("village", "konoha"), {})
			note.call(vc, "%s  •  Önerilen doğa: %s" % [vinfo.get("kage", ""), el_names.get(String(vinfo.get("element", "katon")), "")])
			# yalnızca seçilen köyün klanları (Suna'da Konoha klanı olmaz); oynanamaz klanlar (Ōtsutsuki) listelenmez
			var hvil = String(state.get("village", "konoha"))
			var clan_ids: Array = Data.clans.keys().filter(func(c): return hvil in Data.clans[c].get("villages", ["konoha"]) and not Progress.UNPLAYABLE_CLANS.has(c))
			if not state["clan"] in clan_ids:
				state["clan"] = "none"
			var cc: VBoxContainer = carousel.call("Klan", "clan", clan_ids, clan_ids.map(func(c): return Data.clans[c]["name"]))
			var cl_d: Dictionary = Data.clans.get(state["clan"], {})
			if cl_d.has("kg"):
				note.call(cc, "Kekkei Genkai: " + String(cl_d["kg"]), UI.ACCENT)
			note.call(cc, String(cl_d.get("desc", "")))
			# klanın hiden teknikleri: seviye geldikçe kendiliğinden öğrenilir
			var cj = []
			for k in Data.jutsu.keys():
				if not k.begins_with("_") and String(Data.jutsu[k].get("clan", "")) == state["clan"]:
					cj.append(Data.jutsu[k])
			cj.sort_custom(func(a, b): return int(a.get("level", 1)) < int(b.get("level", 1)))
			if not cj.is_empty():
				var names = cj.map(func(x): return "%s (Güç %d)" % [String(x["name"]).split(" (")[0], int(x.get("level", 1))])
				note.call(cc, "Klan teknikleri: " + ", ".join(names), UI.GOLD)
			# klansız: klan adı olmayan nadir kan soyu (Darui'nin Ranton'u, Pakura'nın Shakuton'u gibi) — yalnız o köyde doğar
			var soy_ids: Array = [""]
			if state["clan"] == "none":
				soy_ids.append_array(KgPaths.SOY.keys().filter(func(k): return hvil in KgPaths.SOY[k]["villages"]))
			if not String(state.get("soy", "")) in soy_ids:
				state["soy"] = ""
			if soy_ids.size() > 1:
				var soy_c: VBoxContainer = carousel.call("Kan Soyu", "soy", soy_ids, soy_ids.map(func(k): return "Yok" if k == "" else String(KgPaths.SOY[k]["name"])))
				var sd: Dictionary = KgPaths.SOY.get(String(state.get("soy", "")), {})
				if sd.is_empty():
					note.call(soy_c, "Sıradan kan: kekkei genkai yok.")
				else:
					note.call(soy_c, "Kekkei Genkai: %s (Güç %d'de uyanır)" % [Elements.NAMES.get(String(sd["nature"]), String(sd["nature"])), int(sd["level"])], UI.ACCENT)
					note.call(soy_c, String(sd["desc"]))
			var els = ["katon", "suiton", "fuuton", "doton", "raiton"]
			var ec: VBoxContainer = carousel.call("Chakra Doğası", "element", els, els.map(func(e): return el_names[e]), UI.ELEMENT_COLORS.get(state["element"], UI.CREAM))
			# klan teknikleri hangi doğaları istiyor: seçilen doğada olmayanlar ikinci doğa alınana kadar kilitli
			var need := {}
			for k in Data.jutsu.keys():
				var jj = Data.jutsu[k]
				if jj is Dictionary and String(jj.get("clan", "")) == state["clan"] and String(jj.get("element", "")) in els:
					need[jj["element"]] = int(need.get(jj["element"], 0)) + 1
			need.erase(state["element"])
			if not need.is_empty():
				var parts = []
				for e in need:
					parts.append("%s (%d teknik)" % [el_names[e], need[e]])
				note.call(ec, "⚠ Bu doğayla bazı klan teknikleri kilitli kalır: " + ", ".join(parts) + ". O doğayı ikinci doğa olarak alınca açılır.", Color(1, 0.7, 0.4))
		"gorunum":
			var hks = CharacterModel.hair_styles_for(String(state["gender"]))
			if not hks.has(state["hair_style"]):
				state["hair_style"] = hks[0]
			carousel.call("Saç Stili", "hair_style", hks, hks.map(func(h): return CharacterModel.HAIR_STYLES[h]))
			swatches.call("Saç Rengi", "hair", [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.18, 0.12, 0.1), Color(0.95, 0.8, 0.25), Color(0.98, 0.92, 0.6), Color(0.75, 0.25, 0.15),
				Color(0.95, 0.4, 0.15), Color(0.9, 0.9, 0.92), Color(0.6, 0.6, 0.65), Color(0.2, 0.3, 0.6), Color(0.15, 0.18, 0.35), Color(0.9, 0.55, 0.7), Color(0.55, 0.3, 0.6), Color(0.25, 0.45, 0.25)])
			if state["clan"] == "hoshigaki":
				# Hoshigaki: mavi / soluk gri ten (normal ten seçenekleri yok)
				if not ClanWorld.HOSHIGAKI_SKINS.has(state["skin"]):
					state["skin"] = ClanWorld.HOSHIGAKI_SKINS[0]
				swatches.call("Ten", "skin", ClanWorld.HOSHIGAKI_SKINS)
			else:
				swatches.call("Ten", "skin", [Color(0.98, 0.88, 0.8), Color(0.96, 0.8, 0.66), Color(0.86, 0.68, 0.52), Color(0.68, 0.5, 0.36), Color(0.5, 0.36, 0.26)])
			if not state["clan"] in ["uchiha", "hyuga", "aburame"]:
				swatches.call("Göz Rengi", "eye", [Color(0.25, 0.45, 0.8), Color(0.3, 0.2, 0.12), Color(0.25, 0.55, 0.3), Color(0.1, 0.1, 0.1), Color(0.6, 0.4, 0.15), Color(0.55, 0.55, 0.6), Color(0.6, 0.25, 0.55)])
		"kiyafet":
			# kıyafet artık set olarak giyilir (parçalar iç içe geçmesin)
			var sl = Gear.START_SETS.map(func(x): return String(Gear.item(x).get("name", x)))
			carousel.call("Kıyafet Seti", "start_set", Gear.START_SETS, sl)
			var outfit_cols = [Color(0.15, 0.2, 0.33), Color(0.15, 0.15, 0.17), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22), Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45)]
			swatches.call("Üst Rengi", "top", outfit_cols)
			swatches.call("Alt Rengi", "pants", outfit_cols)
	if not keep_scroll.is_empty():
		_restore_scroll.call_deferred(keep_scroll)
	# sağ üst: özet kartı
	var sum = PanelContainer.new()
	sum.add_theme_stylebox_override("panel", UI.glass(14, 16, 0.7))
	sum.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sum.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sum.offset_left = -440; sum.offset_right = -28; sum.offset_top = 28
	root.add_child(sum)
	var sv = UI.vbox(4)
	sum.add_child(sv)
	var nm = String(state.get("name", "")).strip_edges()
	sv.add_child(UI.label(nm if nm != "" else "İsimsiz Ninja", 24, UI.CREAM, HORIZONTAL_ALIGNMENT_RIGHT, true))
	var cname = String(Data.clans.get(state["clan"], {}).get("name", "Klansız"))
	sv.add_child(UI.label("%s  •  %s  •  %s" % [Game.village(String(state.get("village", "konoha"))).get("name", ""), cname, el_names.get(String(state["element"]), "")], 14, UI.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	# sağ alt: eylemler
	var bar = UI.hbox(12)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_left = -28; bar.offset_top = -28; bar.offset_right = -28; bar.offset_bottom = -28
	root.add_child(bar)
	bar.add_child(UI.button("Rastgele", func():
		_creator_random(state)
		on_change.call()
		redraw.call(), 170, "star"))
	bar.add_child(UI.button("Geri", func(): main.back_to_menu(), 140, "arrow"))
	bar.add_child(UI.primary("Maceraya Başla!", on_start, 300, "play"))
	var hint = UI.icon_label("person", "Sürükleyerek karakteri döndür", 14, UI.MUTED)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = -36; hint.offset_top = -92; hint.offset_right = -36; hint.offset_bottom = -92
	root.add_child(hint)


## İlişkiler sekmesi: solda seçili kişinin kartı + tanıdığın herkes (bağa göre renkli), sağda köylerle itibar ve diplomasi
static func _tab_relations(main: Node, body: Control) -> void:
	var h = UI.hbox(26)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	var left = _scroll(h, 780, 900)
	left.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.get_parent().custom_minimum_size.y = 0.0   # sabit 900 px ekrandan taşıyordu: listenin altına inilemiyordu
	_friends_card(main, left)
	var fs: Dictionary = Friends.listed()   # defnedilenler listeden düşer (mezarlıkta adları yazar)
	if not fs.is_empty():
		var lc = UI.card()
		left.add_child(lc)
		var lv = UI.vbox(4)
		lc.add_child(lv)
		lv.add_child(UI.icon_label("person", "TANIDIĞIN HERKES", 15, UI.GOLD))
		var ids = fs.keys()
		var order = ids.duplicate()
		order.sort_custom(func(a, b): return int(fs[a]["bond"]) > int(fs[b]["bond"]))
		for id in order:
			var f: Dictionary = fs[id]
			var b = int(f["bond"])
			var stt = String(f.get("status", ""))
			var txt = "%s  —  %s, %s  •  %s (%d)%s" % [f["name"], String(f.get("title", "")), Friends.rank_label(f), Friends.bond_label(f), b,
				"  •  ÖLDÜ" if stt == "öldü" else ("  •  KAÇAK" if stt == "kaçak" else ("  ★ takımda" if f.get("party", false) else ""))]
			var row = UI.chip(txt, ids.find(id) == _friend_i, func():
				_friend_i = ids.find(id)
				ninja_menu(main, "relations"))
			if ids.find(id) != _friend_i:
				row.add_theme_color_override("font_color", Friends.level_color(b) if stt == "" else UI.MUTED)
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			lv.add_child(row)
	# köyler
	var right = UI.vbox(14)
	right.custom_minimum_size = Vector2(560, 0)
	h.add_child(right)
	# senin ailen: eş + çocuklar
	var pr = Game.profile
	var kids: Array = pr.get("children", [])
	if Friends.spouse_id() != "" or not kids.is_empty():
		var ac = UI.card(Color(1, 0.6, 0.75))
		right.add_child(ac)
		var av = UI.vbox(6)
		ac.add_child(av)
		av.add_child(UI.icon_label("heart", "AİLEN", 15, Color(1, 0.65, 0.78)))
		# her aile üyesi tıklanır: dost kaydı olanlar (eş, mezun çocuk) arkadaş kartında açılır + haritada işaretlenir;
		# küçük çocuklar evinde yaşar, evin işaretlenir
		var fids = fs.keys()
		var sid = Friends.spouse_id()
		if sid != "" and fs.has(sid):
			av.add_child(_family_row("Eşin: %s  —  %s" % [fs[sid]["name"], Friends.where_text(sid)], func():
				_friend_i = fids.find(sid)
				Friends.show_on_map(sid)
				ninja_menu(main, "relations")))
		for k in kids:
			var cl: Array = k.get("clans", [])
			var mix = ("  [%s melezi]" % " × ".join(cl.map(func(c): return ClanWorld.clan_name(c)))) if cl.size() >= 2 and cl[0] != cl[1] else ""
			var rel = "Kızın" if k["gender"] == "f" else "Oğlun"
			var kname = String(k["name"])
			var kfid = ""
			if k.get("grad", false):
				for id in fids:
					if String(fs[id]["name"]) == kname:
						kfid = String(id)
			if kfid != "":
				av.add_child(_family_row("%s: %s%s  —  %s" % [rel, kname, mix, Friends.where_text(kfid)], func():
					_friend_i = fids.find(kfid)
					Friends.show_on_map(kfid)
					ninja_menu(main, "relations")))
			else:
				av.add_child(_family_row("%s: %s%s  —  evinde (akademi yaşına gelmedi)" % [rel, kname, mix], func():
					_mark_home()
					main.resume()))
		if float(pr.get("baby_due", 0.0)) > 0.0:
			av.add_child(UI.label("Bir bebek yolda ♥", 13, Color(1, 0.75, 0.8)))
	var vc = UI.card(UI.GOLD)
	right.add_child(vc)
	var vv = UI.vbox(8)
	vc.add_child(vv)
	vv.add_child(UI.icon_label("village", "KÖYLER — İTİBAR VE DİPLOMASİ", 15, UI.GOLD))
	var rep: Dictionary = Game.profile.get("rep", {})
	for vid in Kage.GREAT:
		var r = int(rep.get(vid, 0))
		var rel = Kage.relation(vid) if vid != Progress.home() else 100
		var rt = "Kahraman" if r >= 150 else ("Saygın" if r >= 50 else ("Tanınmıyor" if r >= 0 else ("Kötü şöhretli" if r > -50 else "Aranıyor")))
		var dt = "Kendi köyün" if vid == Progress.home() else ("Müttefik" if rel >= 40 else ("Barışçıl" if rel >= 0 else ("Gergin" if rel > -40 else "SAVAŞ")))
		vv.add_child(UI.label("%s  •  %s" % [Game.village(vid).get("name", vid), Kage.kage_name(vid)], 15, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		vv.add_child(UI.label("İtibarın: %d (%s)   •   Köyünle ilişkisi: %s" % [r, rt, dt], 13, Color(1, 0.45, 0.4) if rel <= -40 or r < 0 else UI.MUTED))
		var bar = UI.bar(Color(1, 0.4, 0.35) if rel < 0 else Color(0.55, 1.0, 0.7), 500, 6)
		bar.min_value = -100
		bar.max_value = 100
		bar.value = rel
		vv.add_child(bar)
	var note = UI.label("İtibarın tanıştığın ninjaların sana ilk bakışını belirler; köylerin arası açılırsa sınırlarda ve köyünde baskınlar başlar.", 12, UI.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(520, 0)
	vv.add_child(note)


## AİLEN kartı satırı: sola yaslı, tıklanır
static func _family_row(text: String, cb: Callable) -> Button:
	var b = UI.chip(text, false, cb)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", Color(1, 0.82, 0.88))
	return b


## Oyuncunun evinin kapısını haritada işaretle (küçük çocuklar orada yaşar)
static func _mark_home() -> void:
	for it in Interact.items:
		if String(it.get("room", "")) == "home_player":
			var p: Vector3 = it["pos"]
			Game.profile["waypoint"] = [p.x, p.y, p.z, "Evin"]
			Game.profile["track"] = "waypoint"
			Hud.msg("Evin haritada işaretlendi: çocukların orada.", Color(1, 0.8, 0.88))
			return
	Hud.msg("Evin kendi köyünde; çocukların orada seni bekliyor.", Color(1, 0.8, 0.88))


static var _friend_i := 0
## Arkadaşlar: ◀ ▶ ile gez; bağ çubuğu, takıma al / köyde beklet
static func _friends_card(main: Node, left: Control) -> void:
	var fs: Dictionary = Friends.listed()
	var fc = UI.card(Color(0.6, 1.0, 0.75))
	left.add_child(fc)
	var fv = UI.vbox(8)
	fc.add_child(fv)
	var party = Friends.party_ids()
	fv.add_child(UI.icon_label("person", "ARKADAŞLAR (%d)  •  Takımda: %d / %d" % [fs.size(), party.size(), Friends.party_max()], 15, Color(0.6, 1.0, 0.75)))
	if fs.is_empty():
		var hl = UI.label("Köydeki ninjalarla (klan üyeleri, devriye ve antrenman ninjaları) konuş ([F]) ve kendini tanıt. Sohbet, hediye ve dostça düello bağı güçlendirir; bağ %d olunca takımına katılırlar." % Friends.JOIN_BOND, 13, UI.MUTED)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.custom_minimum_size = Vector2(700, 0)
		fv.add_child(hl)
		return
	var ids = fs.keys()
	_friend_i = posmod(_friend_i, ids.size())
	var labels = ids.map(func(k): return "%s%s" % [fs[k]["name"], "  ★" if fs[k].get("party", false) else ""])
	fv.add_child(_arrow_row("Arkadaş", labels, _friend_i, func(i):
		_friend_i = i
		ninja_menu(main, "relations")))
	var id = String(ids[_friend_i])
	var f: Dictionary = fs[id]
	var b = int(f.get("bond", 0))
	var stt = String(f.get("status", ""))
	var st_txt = ""
	if stt == "öldü":
		st_txt = "  •  ÖLDÜ"
	elif stt == "kaçak":
		st_txt = "  •  Kaçak — sana borçlu" if Friends.bingo_status(id) == "spared" else ("  •  KAÇAK (Bingo Kitabı)" if Friends.bingo_status(id) != "dead" else "  •  Kaçak — yakalandı/öldü")
	elif String(f.get("kage", "")) != "":
		st_txt = "  •  %s!" % Progress.kage_title(String(f["kage"]))
	elif stt == "hapiste":
		st_txt = "  •  HAPİSTE"
	elif stt == "" and Orgs.is_rogue() and not f.get("rogue", false):
		st_txt = "  •  Köyde — seni artık kaçak biliyor (dost değil)"
	elif not Friends.available(f):
		var mins = ceili((float(f.get("away", 0.0)) - Time.get_unix_time_from_system()) / 60.0)
		st_txt = ("  •  Hastanede: %s (~%d dk)" % [f["injury"], mins]) if f.has("injury") and float(f.get("inj_away", -1.0)) == float(f.get("away", 0.0)) else "  •  Köyde değil (görev)"
	elif not f.get("party", false):
		st_txt = "  •  " + String(Friends.JOB_NAMES.get(Friends.job_of(f), "Evde"))
	var rm = Friends.romance_of(id)
	if rm != "":
		st_txt += "  •  %s ♥" % {"eş": "Eşin", "sevgili": "Sevgilin", "flört": "Flört"}.get(rm, rm)
	fv.add_child(UI.label("%s  •  %s  •  %s: %d (%s)%s" % [String(f.get("title", "")), Friends.rank_label(f), "Güven" if f.get("rogue", false) else "Bağ", b, Friends.bond_label(f), st_txt], 13, Friends.level_color(b)))
	if f.get("rogue", false) and int(f.get("motive_known", 0)) > 0:
		fv.add_child(UI.label("Neden kaçtı: " + String(RogueBonds.motive_of(f)[int(f["motive_known"])]), 12, Color(0.85, 0.8, 0.7), HORIZONTAL_ALIGNMENT_LEFT, true))
	var bar = UI.bar(Friends.level_color(b), 700, 8)
	bar.min_value = -100
	bar.max_value = 100
	bar.value = b
	fv.add_child(bar)
	if Friends.TRAITS.has(String(f.get("trait", ""))) and Friends.trait_known(f):
		fv.add_child(UI.label("Kişilik: " + String(Friends.TRAITS[f["trait"]]["desc"]), 12, Color(0.85, 0.85, 1.0)))
	elif f.has("trait"):
		fv.add_child(UI.label("Kişilik: ? (onunla birkaç kez sohbet et)", 12, UI.MUTED))
	if rm != "" and rm != "eş":
		fv.add_child(UI.label("Gönül: %d/100  (iltifat, gece yürüyüşü, randevu, sevdiği hediye; evlilik için sevgili olarak zaman + gönül/bağ 85)" % int(f.get("love", 0)), 12, Color(1, 0.65, 0.8)))
	if int(f.get("gift_known", -1)) >= 0:
		fv.add_child(UI.label("Sevdiği hediye: " + String(Friends.GIFTS[int(f["gift_known"])][0]), 12, Color(1, 0.75, 0.8)))
	var fam: Array = f.get("family", [])
	if not fam.is_empty():
		var fl = UI.label("Ailesi: " + ", ".join(fam.map(func(m): return "%s %s%s%s" % [m["rel"], String(m["name"]), (" [%s]" % m["mix"]) if m.has("mix") else "", "" if m.get("alive", true) else " (öldü)"])), 12, UI.MUTED)
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl.custom_minimum_size = Vector2(700, 0)
		fv.add_child(fl)
	var lg: Array = f.get("log", [])
	if not lg.is_empty():
		var ll = UI.label("Son olaylar: " + "  •  ".join(lg.slice(maxi(0, lg.size() - 3))), 12, Color(0.85, 0.85, 0.7))
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size = Vector2(700, 0)
		fv.add_child(ll)
	if stt != "öldü":
		fv.add_child(UI.button("Haritada göster", func():
			Friends.show_on_map(id)
			main.resume(), 260, "map"))
	if stt == "" and not (Orgs.is_rogue() and not f.get("rogue", false)):
		if f.get("party", false):
			fv.add_child(UI.button("Köyde beklet", func():
				Friends.set_party(id, false)
				ninja_menu(main, "relations"), 260, "person"))
		elif b >= Friends.JOIN_BOND:
			fv.add_child(UI.button("Takıma al", func():
				Friends.set_party(id, true)
				ninja_menu(main, "relations"), 260, "person"))
		else:
			fv.add_child(UI.label("Takıma katılması için bağ %d olmalı: köyde rastlayınca sohbet et, hediye ver, dostça düello yap." % Friends.JOIN_BOND, 13, UI.MUTED))
	# Unut: ilişkiler listesinden kaldır (onay ister; eş, öğrenci ve takım hocası unutulmaz)
	fv.add_child(UI.button("Unut", func():
		var why = Friends.forget_block(id)
		if why != "":
			Hud.msg(why, Color(1, 0.7, 0.45))
			return
		Hud.dialog("Unut", "%s ilişkiler listenden silinsin mi? Geri alınamaz." % String(f["name"]), [
			{"label": "Evet, unut", "cb": func():
				Friends.forget(id)
				ninja_menu(main, "relations")},
			{"label": "Vazgeç", "cb": func(): pass}]), 260, "person"))


## Başlık + ◀ Ad (n/N) ▶ satırı; on_pick(yeni_indeks). Seçenekler hep böyle oklarla gezilir, tek tek dizilmez
static func _arrow_row(title: String, labels: Array, idx: int, on_pick: Callable) -> Control:
	var n = labels.size()
	idx = clampi(idx, 0, maxi(n - 1, 0))
	var row = UI.hbox(10)
	var tl = UI.label(title.to_upper(), 13, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	tl.custom_minimum_size = Vector2(110, 0)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tl)
	# satır kendi yazısını günceller (sekme yeniden çizilmese de seçim görünür)
	var cur = [idx]
	var name_l = UI.label(String(labels[idx]) if n > 0 else "-", 17, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, true)
	var cnt_l = UI.label("%d / %d" % [idx + 1, n], 12, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var go = func(d: int) -> void:
		if n <= 0:
			return
		cur[0] = posmod(cur[0] + d, n)
		if is_instance_valid(name_l):
			name_l.text = String(labels[cur[0]])
		if is_instance_valid(cnt_l):
			cnt_l.text = "%d / %d" % [cur[0] + 1, n]
		on_pick.call(cur[0])
	row.add_child(_arrow_btn("◀", func(): go.call(-1)))
	var mid = UI.vbox(2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size = Vector2(200, 0)
	mid.add_child(name_l)
	mid.add_child(cnt_l)
	row.add_child(mid)
	row.add_child(_arrow_btn("▶", func(): go.call(1)))
	return row


## Yuvarlak ok düğmesi (◀ ▶)
static func _arrow_btn(text: String, cb: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(46, 46)
	b.add_theme_font_override("font", UI.font(true))
	b.add_theme_font_size_override("font_size", 18)
	var n = UI._box(Color(0.07, 0.08, 0.1, 0.85), Color(UI.GOLD, 0.45), 1, 23, 6)
	var h = UI._box(Color(UI.GOLD, 0.9), Color(1, 1, 1, 0.4), 1, 23, 6)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", n)
	b.add_theme_color_override("font_color", UI.GOLD)
	for k in ["font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, UI.INK)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.8, 0.15))
	return b


## Rastgele görünüm (köy/klan/doğa korunur)
static func _creator_random(state: Dictionary) -> void:
	state["gender"] = ["m", "f"].pick_random()
	state["hair_style"] = CharacterModel.hair_styles_for(state["gender"]).filter(func(h): return h != "kel").pick_random()
	state["hair"] = [Color(0.3, 0.2, 0.12), Color(0.08, 0.08, 0.1), Color(0.95, 0.8, 0.25), Color(0.75, 0.25, 0.15), Color(0.9, 0.9, 0.92), Color(0.2, 0.3, 0.6), Color(0.9, 0.55, 0.7), Color(0.95, 0.4, 0.15)].pick_random()
	state["skin"] = [Color(0.98, 0.88, 0.8), Color(0.96, 0.8, 0.66), Color(0.86, 0.68, 0.52), Color(0.68, 0.5, 0.36)].pick_random()
	state["eye"] = [Color(0.25, 0.45, 0.8), Color(0.3, 0.2, 0.12), Color(0.25, 0.55, 0.3), Color(0.1, 0.1, 0.1)].pick_random()
	state["top_style"] = CharacterModel.TOP_STYLES.keys().pick_random()
	state["pants_style"] = CharacterModel.PANTS_STYLES.keys().pick_random()
	var oc = [Color(0.15, 0.2, 0.33), Color(0.15, 0.15, 0.17), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22), Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45)]
	state["top"] = oc.pick_random()
	state["top2"] = oc.pick_random()
	state["pants"] = oc.pick_random()


# ================================================================== duraklatma
static func pause(main: Node) -> void:
	var bg = _full(0.6)
	var root = UI.vbox(6)
	root.position = Vector2(110, 110)
	bg.add_child(root)
	root.add_child(UI.label("DURAKLATILDI", 15, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(UI.label(String(Game.profile.get("name", "")), 54, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(UI.label("%s  •  %s" % [Orgs.rogue_rank_name() if Orgs.is_rogue() else Data.RANKS[int(Game.profile.get("rank", 0))], Game.region_name(Game.player.global_position) if Game.player else ""], 17, UI.MUTED))
	root.add_child(UI.spacer(0, 26, false))
	var items = [["Devam", "play", func(): main.resume()], ["Ninja Menüsü", "bag", func(): ninja_menu(main, last_tab())],
		["Ekipman ve Kıyafetler", "armor", func(): ninja_menu(main, "wardrobe")], ["Jutsular", "scroll", func(): ninja_menu(main, "jutsu")],
		["Harita", "map", func(): region_map(main)], ["Ayarlar", "settings", func(): settings(func(): pause(main))],
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
		["Shift", "Ninja koşusu (5 sn: tam hız), havada dash"], ["Duvara koş", "Duvarda koşu"], ["Duvarda Ctrl", "Duvar atılımı (chakra)"], ["Havada Q", "İpli kunai: nişangâha tutun"], ["Sol tık", "Kombo / dalış tekmesi"], ["Sağ tık", "Blok (tam zamanında: mükemmel blok)"],
		["Q", "Kawarimi (genjutsu'dayken: Kai)"], ["C (basılı)", "Chakra şarjı"], ["R / T", "Alet fırlat / değiştir"], ["N", "Silahı çek / kınına sok"], ["E / orta tık", "Hedefe kilitlen"],
		["1-6", "Jutsu slotları"], ["F", "Etkileşim"], ["Caps Lock", "Yürüyüş (aç/kapa)"], ["H / Y", "Merhem / Asker hapı"], ["G + 1-9,0,-,=", "Mühür ör"],
		["V", "Dōjutsu: gözleri aç / kapat (basılı: Susanoo)"], ["Z / X", "Sağ / sol göz tekniği (gözler açıkken)"], ["B", "Sekiz Kapı"], ["Tab", "Ninja menüsü"],
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
	var g0 = group.call("monitor", "Arayüz")
	var scales = [0.75, 0.85, 1.0, 1.15, 1.3, 1.5]
	var cur = float(s.get("ui_scale", 1.0))
	var si = 2
	for i in scales.size():
		if absf(scales[i] - cur) < 0.01:
			si = i
	var ur = UI.hbox(12)
	var ul = UI.label("Arayüz ölçeği", 15)
	ul.custom_minimum_size = Vector2(200, 0)
	ur.add_child(ul)
	var set_scale = func(k: int) -> void:
		s["ui_scale"] = scales[posmod(k, scales.size())]
		Game.apply_settings()
		settings(back)
	ur.add_child(_arrow_btn("◀", func(): set_scale.call(si - 1)))
	var uv = UI.label("%d%%" % int(round(scales[si] * 100.0)), 16, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	uv.custom_minimum_size = Vector2(90, 0)
	ur.add_child(uv)
	ur.add_child(_arrow_btn("▶", func(): set_scale.call(si + 1)))
	g0.add_child(ur)
	# ekran: ◀ Tam ekran / Pencere 1280×720 ... ▶ (küçük ekranlı bilgisayarlarda pencere ekrana sığsın)
	var disp = Game.DISPLAYS
	var cur_d = Game.display_key()
	var di = maxi(0, disp.find(cur_d))
	var dr = UI.hbox(12)
	var dl = UI.label("Ekran", 15)
	dl.custom_minimum_size = Vector2(200, 0)
	dr.add_child(dl)
	var set_disp = func(k: int) -> void:
		s["display"] = disp[posmod(k, disp.size())]
		s["fullscreen"] = s["display"] == "full"
		Game.apply_settings()
		settings(back)
	dr.add_child(_arrow_btn("◀", func(): set_disp.call(di - 1)))
	var dvl = UI.label(Game.display_label(disp[di]), 16, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	dvl.custom_minimum_size = Vector2(220, 0)
	dr.add_child(dvl)
	dr.add_child(_arrow_btn("▶", func(): set_disp.call(di + 1)))
	g0.add_child(dr)
	# kan efekti ◀ Açık / Kapalı ▶
	var br = UI.hbox(12)
	var bl = UI.label("Kan efekti", 15)
	bl.custom_minimum_size = Vector2(200, 0)
	br.add_child(bl)
	var flip_blood = func() -> void:
		s["blood"] = not bool(s.get("blood", true))
		settings(back)
	br.add_child(_arrow_btn("◀", flip_blood))
	var bv = UI.label("Açık" if bool(s.get("blood", true)) else "Kapalı", 16, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	bv.custom_minimum_size = Vector2(90, 0)
	br.add_child(bv)
	br.add_child(_arrow_btn("▶", flip_blood))
	g0.add_child(br)
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
	for opt in [["Gölgeler", "shadows"], ["Anime çizgileri", "outline"], ["Yumuşak filtre", "dreamy"], ["FPS göster", "show_fps"]]:
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
const TABS := [["inv", "bag", "Envanter"], ["wardrobe", "armor", "Ekipman"], ["eyes", "eye", "Gözler"], ["jutsu", "scroll", "Jutsular"], ["skills", "star", "Ustalık"],
	["beasts", "flame", "Canavarlar"], ["summons", "seal", "Kuchiyose"], ["relations", "heart", "İlişkiler"], ["missions", "mission", "Görevler"], ["paths", "book", "Yollar"], ["map", "map", "Harita"]]
const TAB_TITLES := {"beasts": "KUYRUKLU CANAVARLAR", "summons": "KUCHİYOSE SÖZLEŞMELERİ", "inv": "ENVANTER", "wardrobe": "EKİPMAN", "jutsu": "JUTSULAR", "skills": "USTALIK (YAPTIKÇA GELİŞME)", "missions": "GÖREVLER", "relations": "İLİŞKİLER", "eyes": "GÖZLER (DŌJUTSU)", "paths": "EFSANE YOLLARI"}
const SWATCHES := [Color(0.15, 0.2, 0.33), Color(0.12, 0.12, 0.14), Color(0.45, 0.15, 0.15), Color(0.95, 0.5, 0.12), Color(0.2, 0.38, 0.22),
	Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45), Color(0.55, 0.42, 0.3), Color(0.75, 0.2, 0.25)]


static var _last_tab := ""
static var _last_shop := ""
static var _scroll_mem := {}     # sekme -> kaydırma konumları
static var _menu_open := false


## Menü kısayolu: en son açık bırakılan sekme (ilk açılışta envanter)
static func last_tab(fallback := "inv") -> String:
	return _last_tab if _last_tab != "" else fallback


static func _scroll_positions() -> Array:
	var out = []
	for sc in Hud.dialog_layer.find_children("*", "ScrollContainer", true, false):
		out.append(sc.scroll_vertical)
	return out


static func _restore_scroll(vals: Array) -> void:
	var scs = Hud.dialog_layer.find_children("*", "ScrollContainer", true, false)
	for i in mini(scs.size(), vals.size()):
		if is_instance_valid(scs[i]):
			scs[i].scroll_vertical = int(vals[i])


static func ninja_menu(main: Node, tab := "inv", picked := "") -> void:
	if tab == "map":
		region_map(main)
		return
	# aynı sekme yeniden kurulurken (eşya seçince) kaydırma yerinde kalsın; eskiden en üste dönüyordu
	var bg = _full(0.5)   # (önceki sekmenin kaydırması clear() içinde kaydedilir)
	var keep = _scroll_mem.get(tab, [])
	_last_tab = tab
	_menu_open = true
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
	var rail = UI.vbox(2)
	rail.position = Vector2(20, 92)
	rail_bg.add_child(rail)
	var emb = Icons.view("leaf", 44, UI.GOLD)
	emb.position = Vector2(34, 30)
	rail_bg.add_child(emb)
	for t in TABS:
		rail.add_child(UI.icon_button(t[1], t[2], func(): ninja_menu(main, t[0]), 72, t[0] == tab))
	# üst çubuk: başlık + oyuncu bilgisi
	var title = UI.label(TAB_TITLES.get(tab, ""), 34, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	title.position = Vector2(150, 30)
	bg.add_child(title)
	var info = UI.hbox(18)
	info.anchor_left = 1.0; info.anchor_right = 1.0
	info.offset_left = -720; info.offset_right = -110; info.offset_top = 36
	info.alignment = BoxContainer.ALIGNMENT_END
	bg.add_child(info)
	info.add_child(UI.icon_label("person", "%s  •  %s  •  Güç %d" % [pr["name"], Data.RANKS[int(pr["rank"])], int(pr["level"])], 16, UI.TEXT))
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
		"relations":
			_tab_relations(main, body)
		"eyes":
			_tab_eyes(main, body)
		"paths":
			PathsTab.build(main, body)
		"beasts":
			_tab_beasts(main, body)
		"summons":
			_tab_summons(main, body)
	if not keep.is_empty():
		_restore_scroll.call_deferred(keep)
		Engine.get_main_loop().process_frame.connect(_restore_scroll.bind(keep), CONNECT_ONE_SHOT)
	elif _fresh:
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
			if Gear.is_eye(g["id"]):
				continue   # gözler eşya değil: Gözler (dōjutsu) sekmesinde
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
			var rs = Gear.req_summary(sel["id"])
			if rs != "":
				var why = Gear.req_text(sel["id"], pr)
				tv.add_child(UI.icon_label("lock" if why != "" else "check", rs + ("  —  henüz takamazsın" if why != "" else ""), 14, UI.BAD if why != "" else UI.GOOD))
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
			dv.add_child(UI.button("Ekipmanda göster", func():
				var gs = String(Gear.item(sel["id"]).get("slot", "govde"))
				_eq_slot = "sag" if gs == "el" else gs
				ninja_menu(main, "wardrobe"), 380, "armor"))
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
	stat_row.call("star", "Toplam Ustalık", "%d" % int(Mastery.total(pr)))
	stat_row.call("leaf", "Klan", Data.clans.get(pr["clan"], {}).get("name", "Klansız"))
	if KgPaths.SOY.has(String(pr.get("soy", ""))):
		stat_row.call("leaf", "Kan Soyu", KgPaths.SOY[String(pr["soy"])]["name"])
	stat_row.call(UI.ELEMENT_ICONS.get(String(pr["elements"][0]) if not pr["elements"].is_empty() else "", "chakra"), "Chakra doğası", ", ".join(pr["elements"]).capitalize())
	var md: Dictionary = pr["missions_done"]
	stat_row.call("mission", "Görevler", "D%d  C%d  B%d  A%d  S%d" % [md.get("D", 0), md.get("C", 0), md.get("B", 0), md.get("A", 0), md.get("S", 0)])


# ------------------------------------------------------------------ ekipman (karakter etrafında yuvalar)
static var _eq_slot := "set"
# gözler ekipman değil (Gözler sekmesinde)
const DOLL_LEFT := ["kafa", "set"]
const DOLL_RIGHT := ["sirt", "sag"]


static func _slot_name(sl: String) -> String:
	for s in Gear.SLOTS:
		if s[0] == sl:
			return s[1]
	return {"sac": "Saç", "susanoo": "Susanoo"}.get(sl, sl)


static func _tab_wardrobe(main: Node, body: Control) -> void:
	var pr = Game.profile
	Gear.ensure(pr)
	if _eq_slot in ["sag_goz", "sol_goz"] or _eq_slot in Gear.OLD_CLOTH_SLOTS:
		_eq_slot = "set"
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
	tot.append("Silah %.1f hasar" % float(Gear.weapon(pr).get("hit", 4.2)))
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
	if _eq_slot in ["sag_goz", "sol_goz"]:
		_eye_panel(main, dv, pr)
		return
	if _eq_slot in Gear.HIDE_SLOTS:
		# görünüşü gizle: eşya takılı kalır, statları sayılır, yalnız karakterde görünmez
		var hid = Gear.look_hidden(pr, _eq_slot)
		dv.add_child(_arrow_row("Görünüş", ["Göster", "Gizle (statlar sayılır)"], 1 if hid else 0, func(i):
			if not pr.has("hide_look"):
				pr["hide_look"] = {}
			pr["hide_look"][_eq_slot] = i == 1
			refresh.call()))
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
			detail_v.add_child(UI.label("Vuruş hasarı %.1f   •   Menzil +%.1f m   •   %s" % [float(it["weapon"].get("hit", 4.2)), it["weapon"]["reach"], String(it["weapon"].get("style", "")).capitalize()], 14, UI.GOLD))
		var d = UI.label(it.get("desc", ""), 14, UI.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(460, 0)
		detail_v.add_child(d)
		var rs = Gear.req_summary(g["id"])
		var why = Gear.req_text(g["id"], pr)
		if rs != "":
			detail_v.add_child(UI.icon_label("lock" if why != "" else "check", rs, 14, UI.BAD if why != "" else UI.GOOD))
		var on = not cur.is_empty() and int(cur["uid"]) == int(g["uid"])
		if why != "" and not on:
			detail_v.add_child(UI.label("Takamazsın: %s." % why, 15, UI.BAD, HORIZONTAL_ALIGNMENT_LEFT, true))
		elif on:
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
		var why = Gear.req_text(g["id"], pr)
		var t = _tile(Thumbs.gear_view(g["id"], 60, Color.html(g["c1"])), it["name"], UI.RARITY[UI.rarity_of_gear(g["id"])] if why == "" else Color(1, 1, 1, 0.12), on, func():
			if why != "" and not on:
				Hud.msg("Takamazsın: %s" % why, Color(1, 0.5, 0.4))
				show_detail.call(g)
				return
			if used_other:
				Hud.msg("Bu eşya diğer elde takılı.", Color(1, 0.8, 0.5))
				return
			pr["equip"][_eq_slot] = int(g["uid"])
			refresh.call(), 92, "✓" if on else ("◐" if used_other else ("Kilitli" if why != "" else "")))
		if why != "" and not on:
			t.modulate = Color(1, 1, 1, 0.5)
		t.tooltip_text = "%s\n%s%s" % [it["name"], Gear.stats_text(g["id"]), ("\n" + why) if why != "" else ""]
		t.mouse_entered.connect(func(): show_detail.call(g))
		grid.add_child(t)
	dv.add_child(detail)
	show_detail.call(cur if not cur.is_empty() else (list[0] if not list.is_empty() else {}))
	# Mangekyō deseni
	if _eq_slot in ["sag_goz", "sol_goz"] and not Eyes.design_for(pr, _eq_slot).is_empty():
		_ms_editor(main, dv, Eyes.design_for(pr, _eq_slot))
	# boya
	if not cur.is_empty() and not Gear.item(cur["id"]).has("weapon") and not Gear.item(cur["id"]).has("eye"):
		var names = {"set": ["Üst Rengi", "Alt Rengi (pantolon)"]}.get(_eq_slot, ["Renk"])
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


## Özel Mangekyō deseni: canlı önizleme + stil (oklu seçici)/kanat/kıvrım/kalınlık/halka/renk
## Değişiklikler yerinde uygulanır: menü baştan kurulmaz (eskiden stil seçince başka sekmeye atlıyordu)
const MS_STYLES := ["Çark", "Yıldız", "Taç Yaprak", "Shuriken", "Sarmal", "Haç", "Tomoe Halkası", "Orak", "Pervane", "Çiçek",
	"Elmas", "Halkalar", "Kanca", "Dört Bıçak", "Altı Köşeli Yıldız", "Kelebek", "Kar Tanesi", "Kalkan",
	"Madara", "Sasuke", "Shisui", "Kakashi", "Izuna", "Indra", "Ebedi Sasuke", "Ebedi Madara", "Nokta Halkası", "Haç Yaprak",
	"Gül", "Kum Saati", "Güneş", "Dişli", "Triskel", "Hilaller", "Göz İçinde Göz", "Nilüfer", "Dalga", "Diken Halkası",
	"Pusula", "Dişler", "Girdap", "Kare", "Altıgen", "Alev", "Tüy", "Taç", "Çift Nokta", "Gül Düğümü", "Rinne Sharingan Halkası", "Sharingan Kılıcı"]
const MS_COLORS := [[0.9, 0.05, 0.06], [0.6, 0.0, 0.05], [0.55, 0.2, 0.85], [0.15, 0.4, 0.95], [0.95, 0.7, 0.1], [0.1, 0.7, 0.4], [0.95, 0.95, 0.98], [0.05, 0.05, 0.08], [1.0, 0.4, 0.7], [0.2, 0.85, 0.95]]
static func _ms_editor(main: Node, v: VBoxContainer, d: Dictionary) -> void:
	v.add_child(UI.spacer(0, 6, false))
	v.add_child(UI.header("MANGEKYŌ DESENİ", 18))
	var box = UI.vbox(6)
	v.add_child(box)
	_ms_editor_fill(box, d)


static func _ms_editor_fill(box: VBoxContainer, d: Dictionary) -> void:
	for ch in box.get_children():
		ch.queue_free()
	var row = UI.hbox(18)
	box.add_child(row)
	var pv = ColorRect.new()
	pv.custom_minimum_size = Vector2(160, 160)
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
	# stil: < Ad (n/N) > oklu seçici
	var sr = UI.hbox(8)
	var sl0 = UI.label("Desen", 13, UI.MUTED)
	sl0.custom_minimum_size = Vector2(92, 0)
	sr.add_child(sl0)
	var name_l = UI.label("", 15, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	name_l.custom_minimum_size = Vector2(150, 0)
	var upd_name = func() -> void:
		var st = int(d.get("style", 0)) % MS_STYLES.size()
		name_l.text = "%s  (%d/%d)" % [MS_STYLES[st], st + 1, MS_STYLES.size()]
	var step = func(dir: int) -> void:
		d["style"] = posmod(int(d.get("style", 0)) + dir, MS_STYLES.size())
		upd_name.call()
		apply_pv.call()
	sr.add_child(UI.button("◀", func(): step.call(-1), 44))
	sr.add_child(name_l)
	sr.add_child(UI.button("▶", func(): step.call(1), 44))
	upd_name.call()
	ctl.add_child(sr)
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
		sl.focus_mode = Control.FOCUS_NONE   # ok tuşları kaydırıcıyı değil menüyü gezsin
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
	var cr = HFlowContainer.new()
	cr.add_theme_constant_override("h_separation", 6)
	cr.add_theme_constant_override("v_separation", 6)
	for c in MS_COLORS:
		cr.add_child(_swatch(Color(c[0], c[1], c[2]), false, func():
			d["col"] = c
			apply_pv.call()))
	cr.add_child(UI.button("Rastgele", func():
		var nd = Eyes.random_design()
		for k in nd:
			d[k] = nd[k]
		_ms_editor_fill.call_deferred(box, d), 140, "star"))
	box.add_child(cr)


static var _sus_prev: Susanoo   # gardıroptaki önizleme (kaydırıcılar anında günceller)
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
	_sus_prev = sn
	sn.scale = Vector3.ONE * (2.1 / 1.8)
	# yere gömülü kademeler (iskelet/İnsansı) önizlemede de belden görünsün (eskiden kadraj dışına kayıyordu)
	sn.position.y = -0.95 * sn.scale.y * 0.55 if sn.tier in [2, 3] else 0.0
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
		var n = mini(labels.size(), limit)   # kilitli kademeler oklarla seçilemez
		v.add_child(_arrow_row(title, labels.slice(0, n), maxi(0, values.find(cur)), func(i):
			cfg[key] = values[i]
			redraw.call()))
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
	v.add_child(UI.label("Kenar rengi", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var rr = HFlowContainer.new()
	rr.add_theme_constant_override("h_separation", 8)
	for c in Susanoo.COLORS + [[1.0, 1.0, 1.0], [0.05, 0.05, 0.1]]:
		var rc: Array = cfg.get("rim_color", cfg.get("color", Susanoo.COLORS[0]))
		rr.add_child(_swatch(Color(c[0], c[1], c[2]), Color(rc[0], rc[1], rc[2]).is_equal_approx(Color(c[0], c[1], c[2])), func():
			cfg["rim_color"] = c
			redraw.call()))
	v.add_child(rr)
	# kaydırıcılar: menüyü baştan kurmadan önizlemeye ve açıksa oyundaki Susanoo'ya uygulanır
	var live = func() -> void:
		if is_instance_valid(_sus_prev):
			_sus_prev.apply_look()
		var ey = Game.player.combat.modes.eyes if Game.player and Game.player.combat and Game.player.combat.modes else null
		if ey and ey.susanoo and is_instance_valid(ey.susanoo_node):
			ey.susanoo_node.apply_look()
	for sd in [["Yoğunluk", "density", 0.3, 2.0], ["Kenar parlaklığı", "glow", 0.3, 2.0], ["Alev akışı", "flow", 0.0, 3.0]]:
		var hh = UI.hbox(8)
		var l = UI.label(sd[0], 13, UI.MUTED)
		l.custom_minimum_size = Vector2(130, 0)
		hh.add_child(l)
		var sl = HSlider.new()
		sl.min_value = sd[2]
		sl.max_value = sd[3]
		sl.step = 0.05
		sl.value = float(cfg.get(sd[1], 1.0))
		sl.custom_minimum_size = Vector2(240, 22)
		sl.focus_mode = Control.FOCUS_NONE
		sl.value_changed.connect(func(x):
			cfg[sd[1]] = x
			live.call())
		hh.add_child(sl)
		v.add_child(hh)
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
	var keys = CharacterModel.hair_styles_for(String(look.get("gender", "m")))
	v.add_child(_arrow_row("Saç Stili", keys.map(func(h): return CharacterModel.HAIR_STYLES[h]), maxi(0, keys.find(look.get("hair_style", ""))), func(i):
		look["hair_style"] = keys[i]
		refresh.call()))
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
	var lk2 = look.duplicate()
	lk2["own_hair"] = true   # berber/görünüm önizlemesi: seçilen saç aynen
	m.setup(lk2)
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
	["dojutsu", "Dōjutsu"], ["bijuu", "Kuyruklu Canavar"], ["hiden", "Hiden"], ["senjutsu", "Senjutsu"], ["kinjutsu", "Kinjutsu"], ["medical", "Tıbbi"], ["space_time", "Uzay-Zaman"], ["summoning", "Çağırma"]]
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
	# göz ve kuyruklu canavar teknikleri de slota konabilir (sanal jutsu)
	var learned: Array = (pr["learned"] as Array) + SpecialSlots.refresh(pr)
	if picked == "" and not learned.is_empty():
		picked = learned[0]
	# filtreler: öğrendiklerim / jutsu kitabı (tümü), kategori, element, arama
	var fbar = UI.hbox(8)
	left.add_child(fbar)
	var my_clan = String(pr.get("clan", "none"))
	var clan_ids: Array = Data.jutsu.keys().filter(func(k): return not k.begins_with("_") and String(Data.jutsu[k].get("clan", "")) == my_clan and my_clan != "none")
	var modes = [["learned", "Öğrendiklerim (%d)" % learned.size()], ["all", "Jutsu Kitabı (%d)" % Data.jutsu.size()]]
	if not clan_ids.is_empty():
		modes.append(["clan", "%s Teknikleri (%d)" % [Data.clans.get(my_clan, {}).get("name", my_clan), clan_ids.size()]])
	for m in modes:
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
	for jid in (learned if _jf_mode == "learned" else (clan_ids if _jf_mode == "clan" else Data.jutsu.keys())):
		if String(jid).begins_with("_"):
			continue
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
		else:
			# sürükle: öğrenilmiş jutsu kartı slot çubuğuna bırakılabilir
			var cref = card
			var drag_card = func(_at):
				cref.set_drag_preview(_jutsu_drag_preview(jid))
				return {"jutsu": jid, "from_slot": -1}
			card.set_drag_forwarding(drag_card, Callable(), Callable())
		grid.add_child(card)
	if shown.size() >= 120:
		left.add_child(UI.label("İlk 120 sonuç gösteriliyor — filtreyi daralt.", 13, UI.MUTED))
	# slot çubuğu
	var bar = UI.card()
	left.add_child(bar)
	var bv = UI.vbox(8)
	bar.add_child(bv)
	bv.add_child(UI.label("Jutsu kartını bir slota sürükle-bırak (ya da seç ve slota tıkla). Slotlar arasında sürükleyerek yer değiştir, slottan çıkarmak için çöpe sürükle ya da sağ tıkla.", 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var sh = UI.hbox(10)
	bv.add_child(sh)
	var refresh_j = func() -> void:
		(func(): ninja_menu(main, "jutsu", picked)).call_deferred()
	# i: hedef slot, jid: bırakılan jutsu, from: kaynak slot (-1 = kitaptan)
	var assign = func(i: int, jid: String, from: int) -> void:
		while pr["slots"].size() < 6:
			pr["slots"].append("")
		if from >= 0 and from != i:
			var other = pr["slots"][i]
			pr["slots"][i] = jid
			pr["slots"][from] = other if other != null else ""
		elif from < 0:
			for k in 6:
				if pr["slots"][k] == jid:
					pr["slots"][k] = ""
			pr["slots"][i] = jid
		Sfx.play("click")
		refresh_j.call()
	var accepts = func(_at, data) -> bool:
		return data is Dictionary and data.has("jutsu") and String(data["jutsu"]) in learned
	for i in 6:
		var cur = pr["slots"][i] if i < pr["slots"].size() else ""
		var j: Dictionary = Data.jutsu.get(cur, {}) if cur != null and cur != "" else {}
		var el = String(j.get("element", ""))
		var view = Icons.view(UI.ELEMENT_ICONS.get(el, "chakra") if not j.is_empty() else "plus", 40, UI.ELEMENT_COLORS.get(el, UI.TEXT) if not j.is_empty() else Color(1, 1, 1, 0.15))
		var nm = String(j.get("name", "Boş")).split(":")[-1].split("(")[0].strip_edges()
		var t = _tile(view, "[%d] %s" % [i + 1, nm], UI.ELEMENT_COLORS.get(el, Color(1, 1, 1, 0.2)) if not j.is_empty() else Color(1, 1, 1, 0.15), false, func():
			if picked != "" and picked in learned:
				assign.call(i, picked, -1)
			elif picked != "":
				Hud.msg("Önce bu jutsuyu öğrenmelisin.", Color(1, 0.6, 0.4)), 112)
		t.tooltip_text = nm
		if not j.is_empty():
			var sfx_t = _jutsu_effects(String(cur), j)
			t.tooltip_text = String(j.get("name", nm)) + ("
" + sfx_t.replace("  •  ", "
") if sfx_t != "" else "")
		var tref = t
		var cur_id = String(cur) if cur != null else ""
		var drag_slot = func(_at):
			if cur_id == "":
				return null
			tref.set_drag_preview(_jutsu_drag_preview(cur_id))
			return {"jutsu": cur_id, "from_slot": i}
		var drop_slot = func(_at, data) -> void:
			assign.call(i, String(data["jutsu"]), int(data.get("from_slot", -1)))
		t.set_drag_forwarding(drag_slot, accepts, drop_slot)
		t.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT and cur_id != "":
				pr["slots"][i] = ""
				Sfx.play("click")
				refresh_j.call())
		sh.add_child(t)
	# çöp: slottan sürüklenen jutsu buraya bırakılınca slot boşalır
	var trash = _tile(Icons.view("close", 36, Color(1, 0.5, 0.45)), "Çıkar", Color(1, 0.4, 0.35, 0.5), false, func(): pass, 112)
	trash.tooltip_text = "Slottan çıkarmak için buraya sürükle"
	var trash_ok = func(_at, data) -> bool:
		return data is Dictionary and int(data.get("from_slot", -1)) >= 0
	var trash_drop = func(_at, data) -> void:
		pr["slots"][int(data["from_slot"])] = ""
		Sfx.play("click")
		refresh_j.call()
	trash.set_drag_forwarding(Callable(), trash_ok, trash_drop)
	sh.add_child(trash)
	# sağ: ayrıntı
	var right = UI.card()
	right.custom_minimum_size = Vector2(420, 0)
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
		elif lp.begins_with("clan:"):
			txt = "%s klan tekniği — klan üyeleri Güç %d'de kendiliğinden öğrenir" % [Data.clans.get(lp.substr(5), {}).get("name", lp.substr(5)), int(j.get("level", 1))]
		elif lp == "element":
			txt = "İlk element tekniği: mezuniyetten sonra Antrenman Alanı'nda hocanın chakra kâğıdı testiyle öğrenilir (o doğa sende olmalı)"
		elif lp.begins_with("kg"):
			txt = "Kekkei genkai gerekir (%s)" % lp.trim_prefix("kg:")
		elif lp.begins_with("eye"):
			txt = "Göz tekniği gerekir"
		elif lp.begins_with("sage"):
			txt = "Sennin eğitimi gerekir (%s)" % lp.trim_prefix("sage:")
		elif lp.begins_with("weapon:"):
			txt = "%s ele geçirilince öğrenilir" % String(Gear.item(lp.substr(7)).get("name", lp.substr(7)))
		elif lp.begins_with("beast:"):
			txt = "%s jinchūriki'si olunca canavar öğretir (Güç %d)" % [String(BeastModels.INFO.get(lp.substr(6), {}).get("name", lp.substr(6))).split(" —")[0], int(j.get("level", 1))]
		elif lp.begins_with("contract:"):
			txt = "%s imzalanınca bilge öğretir (Güç %d)" % [String(Contracts.DEFS.get(lp.substr(9), {}).get("name", "Çağırma sözleşmesi")), int(j.get("level", 1))]
		elif lp.begins_with("special") or lp == "signature":
			txt = "Özel görev ile açılır"
		if picked in Data.clans.get(String(Game.profile.get("clan", "")), {}).get("family_arts", []):
			txt = "Aile öğretisi: Güç %d olunca ailen öğretir (rütbe gerekmez)" % int(j.get("level", 1))
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
	stats.add_child(UI.icon_label("chakra", "%d chakra" % int(PlayerCombat.jutsu_cost(j)), 15, Color(0.55, 0.78, 1.0)))
	stats.add_child(UI.icon_label("hourglass", "%.1f sn" % Combat.jutsu_cd(j), 15, UI.MUTED))
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
	var mean = String(j.get("meaning", ""))
	var d = UI.label(("“%s” — " % mean if mean != "" else "") + String(j.get("desc", "")), 15, UI.MUTED)   # ad Japonca; Türkçe anlamı açıklamada
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(380, 0)
	rv.add_child(d)
	var fx = _jutsu_effects(picked, j)
	if fx != "":
		var fl2 = UI.label(fx, 15, Color(1, 0.82, 0.55))
		fl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fl2.custom_minimum_size = Vector2(380, 0)
		rv.add_child(fl2)


## Jutsunun sayısal etkisi: tahmini hasar (oyuncunun gücüyle), element etkileri
static func _jutsu_effects(jid: String, j: Dictionary) -> String:
	var parts = []
	var shp = String(j.get("shape", ""))
	var t = int(j.get("tier", 2))
	var dmg = _jutsu_dmg(j)
	if dmg > 0:
		parts.append("Hasar ≈ %d" % dmg)
	var el = String(j.get("element", ""))
	if el in ["katon", "yoton"]:
		parts.append("Yakar (%.1f sn)" % (1.5 + t * 0.4))
	if el == "shakuton":
		parts.append("Beden suyunu buharlaştırır: yavaşlatır (%.1f sn)" % (1.0 + t * 0.3))
	if el in ["raiton", "ranton"] and t >= 2:
		parts.append("Sersemletir (%.1f sn)" % (0.3 + t * 0.12))
	if el in ["suiton", "hyoton"]:
		parts.append("Ateşi söndürür, Raiton'a karşı zayıf")
	if t >= 3:
		parts.append("Ağır vuruş: geri savurur")
	match shp:
		"buff", "transform":
			parts.append("Güçlendirme — etkisi kullanınca sol üstte yazar")
		"heal":
			parts.append("İyileştirir")
		"bind", "genjutsu_stun":
			parts.append("Hareketsiz bırakır")
	return "  •  ".join(parts)


## Sürüklenirken imlecin yanında görünen küçük jutsu rozeti
static func _jutsu_drag_preview(jid: String) -> Control:
	var j: Dictionary = Data.jutsu.get(jid, {})
	var el = String(j.get("element", ""))
	var ec: Color = UI.ELEMENT_COLORS.get(el, UI.GOLD)
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._box(Color(0.05, 0.06, 0.09, 0.92), ec, 2, 14, 8))
	var hb = UI.hbox(8)
	p.add_child(hb)
	hb.add_child(Icons.view(UI.ELEMENT_ICONS.get(el, "chakra"), 32, ec))
	hb.add_child(UI.label(String(j.get("name", jid)).split("(")[0].strip_edges(), 15, UI.TEXT))
	p.position = Vector2(-20, -20)
	return p


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
	var sub = UI.label("%s-rank  •  %d chakra  •  %d mühür" % [j.get("canon_rank", "?"), int(PlayerCombat.jutsu_cost(j)), (j.get("seals", []) as Array).size()], 12, UI.MUTED)
	sub.position = Vector2(66, 46)
	sub.size = Vector2(222, 18)
	b.add_child(sub)
	# hasar kartın sağ üstünde, ayrıntılar üstüne gelince (ipucu)
	var dmg = _jutsu_dmg(j)
	if dmg > 0:
		var dl = UI.label("%d hasar" % dmg, 12, Color(1, 0.6, 0.45), HORIZONTAL_ALIGNMENT_RIGHT, true)
		dl.position = Vector2(196, 66)
		dl.size = Vector2(96, 18)
		b.add_child(dl)
	var fx = _jutsu_effects(jid, j)
	b.tooltip_text = ("“%s”
" % j["meaning"] if String(j.get("meaning", "")) != "" else "") + String(j.get("desc", "")) + ("

" + fx.replace("  •  ", "
") if fx != "" else "") + "
Chakra: %d   •   Bekleme: %.1f sn" % [int(PlayerCombat.jutsu_cost(j)), Combat.jutsu_cd(j)]
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	UI.hover_anim(b, 1.02)
	return b


## Jutsunun yaklaşık hasarı (hasarsız teknikler: 0)
static func _jutsu_dmg(j: Dictionary) -> int:
	if Game.player == null or String(j.get("category", "")) == "dojutsu":
		return 0
	if String(j.get("shape", "")) in ["buff", "transform", "heal", "teleport", "clone", "summon", "genjutsu_stun", "bind", "mode", "utility", "sensor", "stealth"]:
		return 0
	return int(JutsuEngine.base_dmg(Game.player, j))


# ------------------------------------------------------------------ yetenek ağacı (düğüm grafiği)
static var _skill_sel := ""


## Yetenek ağacı kaldırıldı: bu sekme ustalıkları gösterir (nasıl geliştiği + açtığı şeyler)
static func _tab_skills(_main: Node, body: Control) -> void:
	var pr = Game.profile
	var v = UI.vbox(12)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(v)
	v.add_child(UI.label("Güç %d  —  seviye yok: yaptıkça gelişirsin" % int(pr.get("level", 1)), 24, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true))
	# dövüş tarzı: silahsız düz vuruş kombosu (klan/yol/bijū ile açılır); silah kuşanınca silahın kombosu geçerli
	var styles: Array = FightingStyles.available(pr)
	var cur = String(pr.get("fight_style", ""))
	var ci = maxi(0, styles.find(cur))
	var sdesc = func(id: String) -> String:
		return ("Silahsız temel yumruk-tekme kombosu. Klanın, yolun ya da bijūn yeni tarzlar açar." if id == "" or not FightingStyles.STYLES.has(id) else "Menzil: %s.  %s" % [String(FightingStyles.STYLES[id].get("range", "yakın")), String(FightingStyles.STYLES[id]["desc"])]) + "  (Silah kuşanınca silahın kendi kombosu geçerli.)"
	var sdl = UI.label(sdesc.call(cur), 14, UI.MUTED)
	sdl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sdl.custom_minimum_size = Vector2(1200, 0)
	v.add_child(_arrow_row("Dövüş Tarzı", styles.map(func(x): return FightingStyles.name_of(String(x))), ci, func(i):
		pr["fight_style"] = String(styles[i])
		sdl.text = sdesc.call(String(styles[i]))
		Hud.msg("Dövüş tarzı: %s" % FightingStyles.name_of(String(styles[i])), Color(0.95, 0.85, 0.55))))
	v.add_child(sdl)
	var how = {"ninjutsu": "Jutsu attıkça (mühür bozulsa da biraz). Yüksek rütbe teknikler için gerekli; mühür hızı.",
		"taijutsu": "Yumrukla vurdukça; antrenman kuklası 2 kat.", "kenjutsu": "Silahla vurdukça; antrenman kuklası 2 kat.",
		"chakra": "Jutsu attıkça, [C] meditasyon, duvar/ağaç tırmanma, su üstünde yürüme.", "dayaniklilik": "Hasar aldıkça.", "hiz": "Koştukça.",
		"genjutsu": "Genjutsu yaptıkça. Genjutsu gücü + sana atılan genjutsunun etkisi azalır.", "fuinjutsu": "Mühürleme teknikleri yaptıkça. Fūinjutsu gücü.", "iryo": "Tıbbi teknikler yaptıkça (Shōsen...). İyileştirme gücü.",
		"senjutsu": "Senjutsu teknikleri yaptıkça. Senjutsu gücü + Sage Modu güçlenir.", "kuchiyose": "Çağırma teknikleri yaptıkça. Çağrının canı ve hasarı artar.", "shurikenjutsu": "Kunai, shuriken, senbon attıkça. Atış hasarı + alet bekleme süresi kısalır."}
	# 12 dal: iki sütun + kaydırma (tek sütunda alttakiler ekranın dışına taşıyordu)
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var inner = UI.vbox(14)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(inner)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 14)
	inner.add_child(grid)
	for k in Mastery.KEYS:
		var val = Mastery.get_v(pr, k)
		var cell = UI.vbox(4)
		cell.custom_minimum_size = Vector2(620, 0)
		grid.add_child(cell)
		var row = UI.hbox(12)
		cell.add_child(row)
		var nl = UI.label(Mastery.NAMES[k], 19, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
		nl.custom_minimum_size = Vector2(220, 0)
		row.add_child(nl)
		var bar = ProgressBar.new()
		bar.max_value = maxf(100.0, ceilf((val + 0.01) / 100.0) * 100.0)   # sınır yok: çubuk sonraki yüzlüğe kadar
		bar.value = val
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(300, 20)
		row.add_child(bar)
		row.add_child(UI.label("%.2f" % val, 19, UI.CREAM))   # ondalıklı: yavaş artış da görünsün
		var hl = UI.label(how[k], 14, UI.MUTED)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.custom_minimum_size = Vector2(600, 0)
		cell.add_child(hl)
	var opened = []
	for f in Stats.UNLOCK_AT:
		var u = Stats.UNLOCK_AT[f]
		opened.append("%s %s (%s %d)" % ["✓" if Stats.has_unlock(pr, f) else "·", f, Mastery.NAMES[u[0]], int(u[1])])
	var ol = UI.label("Ustalıkla açılanlar:  " + "   ".join(opened), 13, UI.MUTED)
	ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ol.custom_minimum_size = Vector2(1240, 0)
	inner.add_child(ol)


# ------------------------------------------------------------------ görevler sekmesi
static func _tab_missions(main: Node, body: Control) -> void:
	var pr = Game.profile
	var h = UI.hbox(26)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(h)
	var left = UI.vbox(16)
	left.custom_minimum_size = Vector2(760, 0)
	h.add_child(left)
	# Genin takımı: köyde bekletildiyse geri çağır
	var sqd: Dictionary = pr.get("squad", {})
	if int(pr.get("rank", 0)) == 1 and String(sqd.get("state", "")) == "active":
		var tc = UI.card(Color(0.55, 1.0, 0.6))
		left.add_child(tc)
		var tv = UI.vbox(6)
		tc.add_child(tv)
		tv.add_child(UI.label("Takımın: %s, %s  •  Hoca: %s" % [sqd["mates"][0]["name"], sqd["mates"][1]["name"], sqd["sensei"]["name"]], 16, UI.TEXT))
		if sqd.get("on_mission", false):
			tv.add_child(UI.label("Takım görevde, yanında. Görev bitince dağılırsınız.", 13, UI.MUTED))
		elif sqd.has("meet"):
			tv.add_child(UI.label("Buluşma: antrenman alanı — oraya gidince görev başlar.", 13, UI.GOLD))
		else:
			tv.add_child(UI.button("Hocana haber gönder (görev iste)", func():
				main.resume()
				GeninSquad.recall(), 300, "person"))
			tv.add_child(UI.label("Arkadaşların ve hocan köyde kendi hayatlarını yaşıyor; Tab > İlişkiler'de görünürler. Görevleri hocan alır: önce 2 D-rank, sonra C-rank. %d görev yapıldı." % int(sqd.get("missions", 0)), 13, UI.MUTED))
	# hikâye
	var sc = UI.card(UI.GOLD)
	left.add_child(sc)
	var sv = UI.vbox(8)
	sc.add_child(sv)
	sv.add_child(UI.icon_label("book", "YOLUN" if Journal.is_free() else "AKADEMİ", 15, UI.GOLD))
	var st = UI.label(String(Progress.objective_text()), 18)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size = Vector2(700, 0)
	sv.add_child(st)
	JournalUI.build_story(main, sv)   # kişisel hedefler, yaşam yolu, rakip (sabit hikâye yok)
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
	# takip: ok neyi göstersin (her an aynı yeri göstermesin)
	var tc = UI.card()
	left.add_child(tc)
	var tv2 = UI.vbox(8)
	tc.add_child(tv2)
	tv2.add_child(UI.icon_label("target", "TAKİP — ok ve ışık sütunu neyi göstersin?", 15, UI.GOLD))
	var topts = Missions.track_options()
	var tlabels = topts.map(func(o): return o[1])
	tv2.add_child(_arrow_row("Göster", tlabels, Missions.track_index(topts), func(i):
		Missions.set_track(String(topts[i][0]))
		Sfx.play("click")
		ninja_menu(main, "missions")))
	var wp = pr.get("waypoint")
	if wp is Array and wp.size() >= 4:
		tv2.add_child(UI.button("Seçilen yeri sil", func():
			pr.erase("waypoint")
			if String(pr.get("track", "")) == "waypoint":
				pr["track"] = ""
			ninja_menu(main, "missions"), 240, "close"))
		tv2.get_child(tv2.get_child_count() - 1).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tv2.add_child(UI.label("Oyun içinde L tuşu: aktif hedefler arasında geç. Yeni yer seçmek için: Harita > Yakındaki Yerler.", 13, UI.MUTED))
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
	JournalUI.build_chronicle(rv)   # yaşadıklarının günlüğü


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


static func _pick_element(_main) -> void:
	var pr = Game.profile
	var opts = []
	for e in ["katon", "suiton", "fuuton", "doton", "raiton"]:
		if e in pr["elements"]:
			continue
		opts.append({"label": e.capitalize(), "cb": func():
			pr["elements"].append(e)

			var starter = {"katon": "katon_goukakyuu", "suiton": "suiton_suikoudan", "fuuton": "fuuton_shinkuu", "doton": "doton_doryuusou", "raiton": "raiton_nagashi"}[e]
			Progress.learn(starter)
			Progress.clan_unlocks(true)})
	Hud.dialog("Yeni Chakra Doğası", "Ninjutsu ustalığın bir doğa daha açtı. Hangisini geliştireceksin?", opts)


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
	var r2 = UI.label("✦ ekipman şansı" if rw[2] >= 0.5 else "", 13, Color(0.35, 0.25, 0.15), HORIZONTAL_ALIGNMENT_CENTER)   # XP kalktı (ustalık sistemi)
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
	# XP satırı kaldırıldı: seviye sistemi yok, gelişim yaptıkça (ustalık)
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
	var stampw = mk.call(("BAĞIŞLANDI" if e.get("status", "") == "spared" else "YAKALANDI") if dead else "ARANIYOR", 40, Color(red, 0.85), true, HORIZONTAL_ALIGNMENT_CENTER)
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
	var info = [["Köy", "%s (kaçak)" % e.get("village_name", "?")], ["Tehlike", "%s-rank  •  %s" % [e.get("rank", "?"), _threat_word(int(e.get("level", 1)))]],
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
	# aynı dükkân yeniden kurulurken (eşya seçince/alınca) liste en üste dönmesin
	var keep = _scroll_positions() if title == _last_shop else []
	_last_shop = title
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
	if not keep.is_empty():
		Engine.get_main_loop().process_frame.connect(_restore_scroll.bind(keep), CONNECT_ONE_SHOT)
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
## Bölgesel harita: oyuncunun çevresi (1.6 km) yakın plan; yollar, nehirler, binalar ve dükkân / önemli yer ikonları.
## Sağ panelden yere tıklayınca ok oraya yönlendirir. [Dünya Haritası] düğmesiyle dünya haritasına geçilir.
static func region_map(main: Node) -> void:
	var rm = Game.world.get("road_map") if Game.world else null
	if rm == null or rm.local_map == null or rm.local_rect.z <= 0.0 or Game.player == null:
		world_map(main)
		return
	var bg = _full(0.7)
	var vp = bg.get_viewport_rect().size
	var side_w = 330.0
	var r: Vector4 = rm.local_rect
	vp = vp / maxf(0.01, float(Game.settings.get("ui_scale", 1.0))) if bg.get_viewport_rect().size.x > 3000.0 else vp
	var sz = Vector2.ONE * minf(vp.x - side_w - 180, vp.y - 140)
	var ox = maxf(40.0, (vp.x - (sz.x + 40.0 + side_w)) * 0.5)   # harita + yer listesi ortada yan yana (liste sağ köşeye yapışıyordu)
	var frame = Panel.new()
	frame.add_theme_stylebox_override("panel", UI.glass(16, 0, 0.6))
	frame.position = Vector2(ox, (vp.y - sz.y) * 0.5 + 10) - Vector2(10, 10)
	frame.size = sz + Vector2(20, 20)
	bg.add_child(frame)
	var tr = TextureRect.new()
	tr.texture = rm.local_map
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = sz
	tr.position = Vector2(ox, (vp.y - sz.y) * 0.5 + 10)
	tr.clip_contents = true
	bg.add_child(tr)
	var pm = Game.to_map(Game.player.global_position)
	var region = ""
	for v in Game.world_info["villages"]:
		if pm.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 1.3:
			region = String(v["name"])
	var title = UI.label("BÖLGE HARİTASI" + ("  —  " + region.to_upper() if region != "" else ""), 30, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	title.position = Vector2(tr.position.x, tr.position.y - 50)
	bg.add_child(title)
	var to_px = func(wp: Vector3) -> Vector2:
		return Vector2((wp.x - r.x) / r.z, (wp.z - r.y) / r.z) * sz
	var lms = Interact.landmarks(Game.player.global_position, r.z * 0.7)
	for lm in lms:
		var q: Vector2 = to_px.call(lm["pos"])
		if q.x < 0 or q.y < 0 or q.x > sz.x or q.y > sz.y:
			continue
		var dot = Control.new()
		dot.position = q
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var col: Color = lm["col"]
		var gl: String = lm["glyph"]
		dot.draw.connect(func():
			dot.draw_circle(Vector2.ZERO, 11, Color(0, 0, 0, 0.6))
			dot.draw_circle(Vector2.ZERO, 9, col.darkened(0.45))
			dot.draw_string(ThemeDB.fallback_font, Vector2(-5, 5), gl, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE))
		tr.add_child(dot)
	var me = Control.new()
	me.position = to_px.call(Game.player.global_position)
	me.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var yaw = deg_to_rad(Game.player.yaw)
	me.draw.connect(func():
		var f = Vector2(sin(yaw), -cos(yaw)) * -1.0
		var s = Vector2(-f.y, f.x)
		me.draw_colored_polygon(PackedVector2Array([f * 14.0, -f * 7.0 + s * 8.0, -f * 4.0, -f * 7.0 - s * 8.0]), Color(0.25, 0.6, 1.0))
		me.draw_polyline(PackedVector2Array([f * 14.0, -f * 7.0 + s * 8.0, -f * 4.0, -f * 7.0 - s * 8.0, f * 14.0]), Color.WHITE, 2.0, true))
	tr.add_child(me)
	if Missions.has_marker:
		var mq: Vector2 = to_px.call(Missions.target_marker)
		if mq.x >= 0 and mq.y >= 0 and mq.x <= sz.x and mq.y <= sz.y:
			var mk = Icons.view("target", 30, UI.GOLD)
			mk.position = mq - Vector2(15, 15)
			tr.add_child(mk)
	var scl = UI.label("%d m" % int(r.z * 0.25), 13, UI.CREAM)
	scl.position = Vector2(14, sz.y - 30)
	tr.add_child(scl)
	var bar = ColorRect.new()
	bar.color = UI.CREAM
	bar.position = Vector2(14, sz.y - 10)
	bar.size = Vector2(sz.x * 0.25, 3)
	tr.add_child(bar)
	# yan panel: yerler listesi (tıkla -> yol göster) + dünya haritası
	var side = PanelContainer.new()
	side.add_theme_stylebox_override("panel", UI.glass(16, 20, 0.8))
	side.position = Vector2(ox + sz.x + 40.0, (vp.y - sz.y) * 0.5 + 10)
	side.size = Vector2(side_w, sz.y)
	side.custom_minimum_size = Vector2(side_w, 0)
	bg.add_child(side)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var sv = UI.vbox(8)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	sv.add_child(UI.button("Dünya Haritası  ▶", func():
		bg.queue_free()
		world_map(main), side_w - 40, "map"))
	sv.add_child(UI.header("BU BÖLGEDE", 18))
	lms.sort_custom(func(a, b): return a["pos"].distance_to(Game.player.global_position) < b["pos"].distance_to(Game.player.global_position))
	for lm in lms.slice(0, 18):
		var lp: Vector3 = lm["pos"]
		var nm: String = lm["name"]
		var b = UI.button("%s  %s  (%d m)" % [lm["glyph"], nm, int(lp.distance_to(Game.player.global_position))], func():
			Game.profile["waypoint"] = [lp.x, lp.y, lp.z, nm]
			Game.profile["track"] = "waypoint"
			Hud.msg("Yol gösteriliyor: %s" % nm, Color(1, 0.85, 0.4))
			main.resume(), side_w - 40)
		b.add_theme_color_override("font_color", lm["col"])
		sv.add_child(b)
	_close_button(bg, func(): main.resume())


static func world_map(main: Node) -> void:
	var bg = _full(0.7)
	var tex: Texture2D = Game.world_map_tex()
	var vp = bg.get_viewport_rect().size
	var side_w = 330.0
	var scale = minf((vp.x - side_w - 180) / tex.get_width(), (vp.y - 140) / tex.get_height())
	var sz = Vector2(tex.get_width(), tex.get_height()) * scale
	var ox = maxf(40.0, (vp.x - (sz.x + 40.0 + side_w)) * 0.5)   # harita + yer listesi ortada yan yana (liste sağ köşeye yapışıyordu)
	var frame = Panel.new()
	frame.add_theme_stylebox_override("panel", UI.glass(16, 0, 0.6))
	frame.position = Vector2(ox, (vp.y - sz.y) * 0.5 + 10) - Vector2(10, 10)
	frame.size = sz + Vector2(20, 20)
	bg.add_child(frame)
	var tr = TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = sz
	tr.position = Vector2(ox, (vp.y - sz.y) * 0.5 + 10)
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
	var rb = UI.button("◀  Bölge Haritası", func():
		bg.queue_free()
		region_map(main), 240, "map")
	rb.position = Vector2(tr.position.x + sz.x - 240, tr.position.y - 56)
	bg.add_child(rb)
	if Missions.has_marker:
		var mm = Game.to_map(Missions.target_marker)
		var mk = Icons.view("target", 30, UI.GOLD)
		mk.position = to_px.call(mm.x, mm.y) - Vector2(15, 15)
		tr.add_child(mk)
	# yan panel: hızlı seyahat
	var side = PanelContainer.new()
	side.add_theme_stylebox_override("panel", UI.glass(16, 20, 0.8))
	side.position = Vector2(ox + sz.x + 40.0, (vp.y - sz.y) * 0.5 + 10)
	side.size = Vector2(side_w, sz.y)
	side.custom_minimum_size = Vector2(side_w, 0)
	bg.add_child(side)
	# liste uzun olunca tekerlekle aşağı kaydırılabilsin
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	var sv = UI.vbox(8)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(sv)
	sv.add_child(UI.header("HIZLI SEYAHAT", 18))
	sv.add_child(UI.label("Keşfettiğin köylere, haritadaki bölgelere ve yerlere ışınlan.", 13, UI.MUTED))
	for v in Game.world_info["villages"]:
		var visited: bool = v["id"] in Game.profile.get("visited", [])
		if not visited:
			continue
		var vid: String = v["id"]
		if Orgs.is_rogue() and vid in Orgs.ROGUE_BANNED:
			continue   # kaçak gizli köylere ışınlanamaz
		sv.add_child(UI.button(v["name"], func(): main.fast_travel(vid), side_w - 40, "village"))
	# köylerinde yaşayan jinchūriki'ler: kim nerede (gidip bulmak için)
	if not TailedBeasts.host_list().is_empty():
		sv.add_child(UI.header("JİNCHŪRİKİ", 16))
		for row in TailedBeasts.host_list():
			var hv = String(row[3]); var hn = String(row[0])
			sv.add_child(UI.button("%s — %s (%s)" % [hn, row[1], row[2]], func():
				var at = Exams.find_point(["training"], hv)
				Game.profile["waypoint"] = [at.x, at.y, at.z, "%s (%s)" % [hn, row[2]]]
				Game.profile["track"] = "waypoint"
				Hud.msg("Yol gösteriliyor: %s, %s antrenman alanında." % [hn, row[2]], Color(1, 0.8, 0.5))
				main.resume(), side_w - 40, "person"))
	# haritadaki her bölge ve önemli yer (aşırı hızlı koşmaya gerek kalmasın)
	sv.add_child(UI.header("BÖLGELER", 16))
	for c in Game.world_info.get("countries", []):
		var cx = float(c["x"]); var cy = float(c["y"]); var cn = String(c["name"])
		sv.add_child(UI.button(cn, func(): main.travel_to_map(cx, cy, cn), side_w - 40, "map"))
	sv.add_child(UI.header("YERLER", 16))
	for l in Game.world_info.get("landmarks", []):
		var lx = float(l["x"]); var ly = float(l["y"]); var ln = String(l["name"])
		sv.add_child(UI.button(ln, func(): main.travel_to_map(lx, ly, ln), side_w - 40, "map"))
	if Orgs.is_rogue():
		sv.add_child(UI.button("Kaçak Sığınağı", func():
			main.resume()
			Game.player.respawn(Missions.open_ground(Orgs.hideout_spawn(), 6.0)), side_w - 40, "village"))
	# yakındaki önemli yerler: tıkla -> ok ve ışık sütunu oraya yönlendirir
	if Game.player:
		var near = Interact.landmarks(Game.player.global_position, 2500.0)
		near.sort_custom(func(a, b): return a["pos"].distance_to(Game.player.global_position) < b["pos"].distance_to(Game.player.global_position))
		if not near.is_empty():
			sv.add_child(UI.spacer(0, 8, false))
			sv.add_child(UI.header("YAKINDAKİ YERLER", 18))
			sv.add_child(UI.label("Tıkla: ok seni oraya götürsün.", 13, UI.MUTED))
			var seen = {}
			for lm in near:
				if seen.has(lm["name"]) or seen.size() >= 12:
					continue
				seen[lm["name"]] = true
				var d = int(lm["pos"].distance_to(Game.player.global_position))
				var lp: Vector3 = lm["pos"]
				var nm: String = lm["name"]
				var b = UI.button("%s  %s  (%d m)" % [lm["glyph"], nm, d], func():
					Game.profile["waypoint"] = [lp.x, lp.y, lp.z, nm]
					Game.profile["track"] = "waypoint"
					Hud.msg("Yol gösteriliyor: %s" % nm, Color(1, 0.85, 0.4))
					main.resume(), side_w - 40)
				b.add_theme_color_override("font_color", lm["col"])
				sv.add_child(b)
	sv.add_child(UI.spacer(0, 10, false))
	sv.add_child(UI.icon_label("person", "Sen", 14, Color(0.4, 0.7, 1.0)))
	sv.add_child(UI.icon_label("target", "Görev hedefi", 14, UI.GOLD))
	_close_button(bg, func(): main.resume())


## Seviye sayısı göstermeden düşmanın oyuncuya göre tehlikesi (güç değeri iç hesap)
static func _threat_word(lv: int) -> String:
	var me = maxf(1.0, float(Game.profile.get("level", 1)))
	var r = float(lv) / me
	if r < 0.7:
		return "Senden zayıf"
	if r < 1.2:
		return "Dengin"
	if r < 2.0:
		return "Senden güçlü"
	if r < 3.5:
		return "Çok tehlikeli"
	return "Ölümcül — kaç"

