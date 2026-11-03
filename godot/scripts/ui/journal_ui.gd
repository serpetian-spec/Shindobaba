class_name JournalUI
extends RefCounted
## Tab > Görevler: "Yolun" bölümü (seçilen kişisel hedefler, yaşam yolu, rakip) ve kronik (yaşadıklarının günlüğü).

static var picker_open := false


## Hikâye kartının içine (serbest oyunda): hedefler + yeni hedef seçme + yaşam yolu
static func build_story(main: Node, sv: VBoxContainer) -> void:
	if not Journal.is_free():
		return
	var pr = Game.profile
	var redraw = func(): Menus.ninja_menu(main, "missions")
	# seçili hedefler
	var gs = Journal.goals()
	if not gs.is_empty():
		# üstteki tek satırlık özet ile aynı bilgi: kart uzamasın diye gizle
		for c in sv.get_children():
			if c is Label:
				c.visible = false
				break
		sv.add_child(UI.label("HEDEFLERİN", 14, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
		for g in gs:
			var gid: String = g
			var row = UI.hbox(10)
			sv.add_child(row)
			var info = UI.vbox(2)
			info.custom_minimum_size = Vector2(420, 0)
			row.add_child(info)
			info.add_child(UI.label(String(Journal.GOALS[gid]["name"]), 17, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
			var pg = Journal.goal_progress(gid)
			info.add_child(UI.label(pg if pg != "" else String(Journal.GOALS[gid]["desc"]), 13, UI.MUTED))
			var tracked = String(pr.get("track", "")) == "goal:" + gid
			row.add_child(UI.chip("Takipte" if tracked else "Takip et", tracked, func():
				pr["track"] = "" if tracked else "goal:" + gid
				redraw.call()))
			row.add_child(UI.chip("Bırak", false, func():
				Journal.drop(gid)
				redraw.call()))
	# yeni hedef seç
	var avail = []
	for id in Journal.GOALS:
		if not id in gs and not id in Journal.done_goals() and not Journal.goal_done(id):
			if id == "rogue" and int(pr.get("rank", 0)) < 1:
				continue
			avail.append(id)
	if not avail.is_empty() and not picker_open:
		sv.add_child(UI.chip("+ Kendine bir hedef koy…", false, func():
			picker_open = true
			redraw.call()))
	elif not avail.is_empty():
		sv.add_child(UI.label("Kendine bir hedef koy (isteğe bağlı, istediğin kadar):", 13, UI.MUTED))
		var flow = HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		flow.custom_minimum_size = Vector2(700, 0)
		sv.add_child(flow)
		for id in avail:
			var gid2: String = id
			var b = UI.chip("+ " + String(Journal.GOALS[gid2]["name"]), false, func():
				Journal.pick(gid2)
				picker_open = false
				redraw.call())
			b.tooltip_text = String(Journal.GOALS[gid2]["desc"])
			flow.add_child(b)
	# yaşam yolu
	var life = UI.hbox(12)
	sv.add_child(life)
	if Orgs.is_rogue():
		life.add_child(UI.label("Yaşam yolun: KAÇAK NİNJA • Başının ödülü %d Ryō" % int(Orgs.state().get("bounty", 0)), 15, Color(1, 0.5, 0.45)))
		life.add_child(UI.chip("Af dile", false, func(): Orgs.pardon_prompt()))
	else:
		var vn = String(Game.village(Progress.home()).get("name", "Köy"))
		life.add_child(UI.label("Yaşam yolun: %s'ye bağlı shinobi • %s" % [vn, Data.RANKS[clampi(int(pr.get("rank", 0)), 0, Data.RANKS.size() - 1)]], 15, UI.MUTED))
		if int(pr.get("rank", 0)) >= 1 and int(pr.get("rank", 0)) < 6:
			life.add_child(UI.chip("Köyünü terk et…", false, func(): Orgs.defect_prompt()))
	var r = pr.get("rival", {})
	if r is Dictionary and not r.is_empty():
		sv.add_child(UI.label("Rakibin: %s — seni %d kez yendi. Bir gün yine karşına çıkacak." % [String(r.get("name", "?")), int(r.get("wins", 1))], 14, Color(1, 0.6, 0.45)))


## Sağ sütuna: kronik (son olaylar, en yenisi üstte)
static func build_chronicle(rv: VBoxContainer) -> void:
	var es = Journal.entries()
	if es.is_empty():
		return
	rv.add_child(UI.spacer(0, 8, false))
	rv.add_child(UI.icon_label("book", "KRONİK", 15, UI.GOLD))
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(350, 360)
	rv.add_child(sc)
	var box = UI.vbox(6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box)
	for i in range(es.size() - 1, maxi(-1, es.size() - 41), -1):
		var e: Dictionary = es[i]
		var col = {"milestone": UI.GOLD, "goal_done": UI.GOOD, "rival": Color(1, 0.6, 0.45), "exam": Color(0.7, 0.85, 1)}.get(String(e.get("kind", "")), UI.TEXT)
		box.add_child(UI.label("Güç %d • %s" % [int(e.get("lv", 1)), String(e.get("rank", ""))], 11, UI.MUTED))
		var l = UI.label(String(e.get("text", "")), 14, col)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(330, 0)
		box.add_child(l)
