class_name KageDesk
extends RefCounted
## Kage masası: takımlara görev dağıt, köye yatırım yap, diğer köylerle diplomasi, köy olaylarına karar ver, kayıt defteri.

static var tab := "gorev"
static var picked_squad := -1


static func open(t := "") -> void:
	if t != "":
		tab = t
	ExamUI._pause()
	var k = Kage.st()
	var bg = Menus._full(0.55)
	var root = HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 30; root.offset_right = -30; root.offset_top = 24; root.offset_bottom = -24
	root.add_theme_constant_override("separation", 18)
	bg.add_child(root)
	# sol: sekme rayı
	var rail = UI.vbox(10)
	rail.custom_minimum_size = Vector2(96, 0)
	root.add_child(rail)
	for tt in [["gorev", "mission", "Görevler"], ["koy", "village", "Köy"], ["diplomasi", "scroll", "Diplomasi"], ["olay", "info", "Olaylar"], ["kayit", "book", "Kayıt"]]:
		var b = UI.icon_button(tt[1], tt[2], func():
			tab = tt[0]
			open(), 88, tab == tt[0])
		rail.add_child(b)
	# ana panel
	var panel = UI.panel()
	panel.add_theme_stylebox_override("panel", UI.glass(18, 24))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(panel)
	var v = UI.vbox(12)
	panel.add_child(v)
	var head = UI.hbox(18)
	var kt = Progress.home_info()["kage"]
	head.add_child(UI.label("影   %s MASASI" % kt.to_upper(), 26, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	head.add_child(UI.spacer())
	head.add_child(UI.icon_label("coin", "%s Ryō" % _num(int(k["funds"])), 18, UI.CREAM))
	head.add_child(UI.icon_label("hourglass", "Gün %d" % int(k["day"]), 18, UI.CREAM))
	head.add_child(UI.icon_label("star", "İtibar %d" % Missions.rep(Progress.home()), 18, UI.CREAM))
	head.add_child(UI.icon_label("chakra", "Gelir %s/gün" % _num(Kage.daily_income()), 16, UI.MUTED))
	head.add_child(UI.spacer(70, 0, false))
	v.add_child(head)
	match tab:
		"gorev":
			_tab_jobs(v)
		"koy":
			_tab_village(v)
		"diplomasi":
			_tab_diplo(v)
		"olay":
			_tab_events(v)
		"kayit":
			_tab_log(v)
	Menus._close_button(bg, func(): ExamUI._resume())


static func _num(n: int) -> String:
	var s = str(absi(n))
	var out = ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func _rank_col(r: String) -> Color:
	return {"D": Color(0.55, 0.62, 0.5), "C": Color(0.3, 0.55, 0.85), "B": Color(0.62, 0.38, 0.85), "A": Color(0.9, 0.45, 0.15), "S": Color(0.85, 0.12, 0.12)}.get(r, UI.TEXT)


static func _tab_jobs(v: VBoxContainer) -> void:
	var k = Kage.st()
	var cols = UI.hbox(18)
	v.add_child(cols)
	var left = Menus._scroll(cols, 560, 620)
	left.add_child(UI.header("NİNJA TAKIMLARI", 18))
	var sqs: Array = k["squads"]
	for i in sqs.size():
		var sq: Dictionary = sqs[i]
		var on = picked_squad == i
		var card = UI.card(UI.GOLD if on else (UI.GOOD if sq["status"] == "hazır" else UI.LINE))
		var cv = UI.vbox(4)
		card.add_child(cv)
		var h = UI.hbox(8)
		h.add_child(UI.label(String(sq["name"]), 18, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true))
		h.add_child(UI.spacer())
		var stc = {"hazır": UI.GOOD, "görevde": UI.ACCENT, "yaralı": UI.BAD}.get(sq["status"], UI.MUTED)
		var stt = String(sq["status"]).capitalize()
		if sq["status"] != "hazır":
			stt += " (%d sn)" % int(float(sq["busy"]))
		h.add_child(UI.label(stt, 15, stc, HORIZONTAL_ALIGNMENT_RIGHT, true))
		cv.add_child(h)
		var mem = []
		for m in sq["members"]:
			mem.append("%s (%s)" % [m["name"], m["rank"]])
		var ml = UI.label(", ".join(mem), 13, UI.MUTED)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml.custom_minimum_size = Vector2(500, 0)
		cv.add_child(ml)
		var sh = UI.hbox(14)
		sh.add_child(UI.icon_label("sword", "Güç %d" % int(sq["power"]), 14, UI.TEXT))
		sh.add_child(UI.icon_label("heart", "Moral %d" % int(sq["morale"]), 14, UI.TEXT))
		sh.add_child(UI.icon_label("check", "%d görev" % int(sq["missions"]), 14, UI.TEXT))
		if not (sq["job"] as Dictionary).is_empty():
			sh.add_child(UI.label("→ %s" % sq["job"].get("title", ""), 14, UI.ACCENT))
		cv.add_child(sh)
		if sq["status"] == "hazır":
			var idx = i
			cv.add_child(UI.button("Seçildi" if on else "Bu takımı seç", func():
				picked_squad = idx
				open(), 200))
		left.add_child(card)
	var right = Menus._scroll(cols, 560, 620)
	right.add_child(UI.header("GÖREV TALEPLERİ", 18))
	right.add_child(UI.label("Önce soldan hazır bir takım seç, sonra talebi ata. Başarı şansı takım gücüne, moraline ve istihbarat yatırımına bağlıdır.", 13, UI.MUTED))
	for rq in k["requests"]:
		var card = UI.card(_rank_col(rq["rank"]))
		var cv = UI.vbox(4)
		card.add_child(cv)
		var h = UI.hbox(10)
		h.add_child(Menus._rank_stamp(String(rq["rank"]), 44))
		var tv = UI.vbox(2)
		tv.add_child(UI.label(String(rq["title"]), 17, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true))
		tv.add_child(UI.label("%s  •  %d gün  •  Zorluk %d" % [rq["client"], int(rq["days"]), int(rq["diff"])], 13, UI.MUTED))
		h.add_child(tv)
		h.add_child(UI.spacer())
		h.add_child(UI.icon_label("coin", _num(int(rq["pay"])), 16, UI.GOLD))
		cv.add_child(h)
		if picked_squad >= 0 and picked_squad < (k["squads"] as Array).size() and k["squads"][picked_squad]["status"] == "hazır":
			var sq = k["squads"][picked_squad]
			var ch = Kage.success_chance(sq, rq)
			var rid = int(rq["id"])
			var row = UI.hbox(10)
			row.add_child(UI.label("%s: başarı %%%d" % [sq["name"], int(ch * 100)], 14, UI.GOOD if ch >= 0.6 else (UI.ACCENT if ch >= 0.35 else UI.BAD)))
			row.add_child(UI.spacer())
			row.add_child(UI.primary("Görevlendir", func():
				Kage.assign(picked_squad, rid)
				picked_squad = -1
				open(), 160))
			cv.add_child(row)
		right.add_child(card)


static func _tab_village(v: VBoxContainer) -> void:
	var k = Kage.st()
	v.add_child(UI.header("KÖY YATIRIMLARI", 18))
	v.add_child(UI.label("Her yatırım köyde görünür bir değişiklik yapar (gözcü kuleleri, sancaklar, hastane kanadı, pazar tezgâhları, gözlem direği).", 14, UI.MUTED))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	for id in Kage.UPGRADES:
		var u: Array = Kage.UPGRADES[id]
		var lv = int(k["upg"].get(id, 0))
		var card = UI.card(UI.GOLD if lv > 0 else UI.LINE)
		card.custom_minimum_size = Vector2(560, 120)
		var cv = UI.vbox(6)
		card.add_child(cv)
		var h = UI.hbox(8)
		h.add_child(UI.icon_label(u[2], String(u[0]), 19, UI.CREAM))
		h.add_child(UI.spacer())
		h.add_child(UI.label("●".repeat(lv) + "○".repeat(3 - lv), 18, UI.GOLD))
		cv.add_child(h)
		cv.add_child(UI.label(String(u[1]), 14, UI.MUTED))
		if lv < 3:
			var cost = Kage.upgrade_cost(id)
			var b = UI.primary("Yatırım yap — %s Ryō" % _num(cost), func():
				if not Kage.buy_upgrade(id):
					Hud.msg("Hazine yetersiz.", UI.BAD)
				open(), 280)
			b.disabled = int(k["funds"]) < cost
			cv.add_child(b)
		else:
			cv.add_child(UI.label("En üst seviye", 14, UI.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
		grid.add_child(card)


static func _tab_diplo(v: VBoxContainer) -> void:
	var k = Kage.st()
	v.add_child(UI.header("DİPLOMASİ", 18))
	v.add_child(UI.label("İlişki −40'ın altına düşerse o köyün sınır muhafızları düşmanlaşır ve istila riski doğar. 30+ ticaret, 70+ (ve Zirve sonrası) ittifak.", 14, UI.MUTED))
	for vid in k["rel"]:
		var rel = Kage.relation(vid)
		var vn = String(Game.village(vid).get("name", vid))
		var card = UI.card(UI.GOOD if rel >= 30 else (UI.BAD if rel <= -40 else UI.LINE))
		var cv = UI.vbox(6)
		card.add_child(cv)
		var h = UI.hbox(10)
		h.add_child(UI.label("%s  —  %s" % [vn, Progress.kage_title(vid)], 18, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true))
		h.add_child(UI.spacer())
		var tags = []
		if k["trade"].get(vid, false):
			tags.append("Ticaret")
		if k["alliance"].get(vid, false):
			tags.append("İttifak")
		if rel <= -40:
			tags.append("GERGİN")
		h.add_child(UI.label(" • ".join(tags), 14, UI.ACCENT))
		cv.add_child(h)
		var bar = UI.bar(UI.GOOD if rel >= 0 else UI.BAD, 700, 12)
		bar.min_value = -100
		bar.max_value = 100
		bar.value = rel
		var bh = UI.hbox(10)
		bh.add_child(bar)
		bh.add_child(UI.label("%+d" % rel, 16, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
		cv.add_child(bh)
		var row = UI.hbox(8)
		for a in [["hediye", "Hediye gönder (8.000)"], ["ticaret", "Ticaret anlaşması"], ["ittifak", "İttifak teklif et"], ["tatbikat", "Sınır tatbikatı"]]:
			var act = a[0]
			var target = vid
			row.add_child(UI.button(a[1], func():
				var r = Kage.diplomacy(target, act)
				if r != "":
					Hud.msg(r, Color(1, 0.85, 0.5))
				open(), 200))
		cv.add_child(row)
		v.add_child(card)


static func _tab_events(v: VBoxContainer) -> void:
	var k = Kage.st()
	v.add_child(UI.header("KÖY OLAYLARI", 18))
	if Kage.summit_ready():
		var c = UI.card(UI.GOLD)
		var cv = UI.vbox(6)
		c.add_child(cv)
		cv.add_child(UI.icon_label("village", "Demir Ülkesi'nden davet: BEŞ KAGE ZİRVESİ", 19, UI.CREAM))
		cv.add_child(UI.label("Akatsuki'ye karşı birleşik bir ordu kurulup kurulmayacağı konuşulacak. Bizzat katılmalısın.", 14, UI.MUTED))
		cv.add_child(UI.primary("Zirveye git", func():
			ExamUI._resume()
			Kage.start_summit(), 220))
		v.add_child(c)
	if (k["events"] as Array).is_empty() and not Kage.summit_ready():
		v.add_child(UI.label("Şu an karar bekleyen bir olay yok. Günler geçtikçe mektuplar, afetler ve baskınlar gelecek.", 15, UI.MUTED))
	for ev in k["events"]:
		var card = UI.card(UI.ACCENT)
		var cv = UI.vbox(6)
		card.add_child(cv)
		cv.add_child(UI.label(String(ev["title"]), 19, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, true))
		cv.add_child(UI.label(String(ev["text"]), 15, UI.MUTED))
		var row = UI.hbox(8)
		var eid = int(ev["id"])
		var opts = []
		match String(ev["type"]):
			"mektup":
				opts = [["kabul", "Kabul et (−5.000)"], ["ret", "Reddet"]]
			"festival":
				opts = [["kabul", "Festival düzenle (−12.000)"], ["ret", "İptal et"]]
			"afet":
				opts = [["kabul", "Yardım gönder (−15.000)"], ["ret", "Gönderme"]]
			_:
				opts = [["kabul", "Bizzat savun"], ["takim", "En güçlü takımı gönder"]]
		for o in opts:
			var ch = o[0]
			row.add_child(UI.button(o[1], func():
				var r = Kage.resolve_event(eid, ch)
				if ch == "kabul" and String(ev["type"]) in ["baskin", "istila"]:
					ExamUI._resume()
					return
				Hud.msg(r, Color(1, 0.85, 0.5))
				open(), 260))
		cv.add_child(row)
		v.add_child(card)


static func _tab_log(v: VBoxContainer) -> void:
	v.add_child(UI.header("KAYIT DEFTERİ", 18))
	var sc = Menus._scroll(v, 1100, 600)
	for line in Kage.st()["log"]:
		sc.add_child(UI.label(String(line), 15, UI.TEXT))
