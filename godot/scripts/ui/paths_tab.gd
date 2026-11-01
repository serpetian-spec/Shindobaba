class_name PathsTab
extends RefCounted
## Tab > Yollar: keşfedilen Efsane Yolları, ustası, ini, durumu, sıradaki adım ve teknik listesi.
## "İzi takip et" ok ve ışık sütununu ustanın inine yönlendirir.


static func build(main: Node, body: Control) -> void:
	var pr = Game.profile
	var sc = ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var col = UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	var intro = UI.label("Kanon ninjaların imza teknikleri dünyada saklı ustalardan öğrenilir. Söylentileri izle, ini bul, ustanın sınavını geç ve yola katıl. Yollar hikâyeye bağlı değildir; istediğin zaman, istediğin kadarına katılabilirsin.", 14, UI.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(1100, 0)
	col.add_child(intro)
	for pid in LegendPaths.PATHS:
		col.add_child(_card(main, pid))
	var more = UI.label("Daha fazla yol keşfedilmeyi bekliyor: kurbağa bilgesi, kil sanatçısı, kukla ustası, ışınlanma mührü...", 13, UI.MUTED)
	col.add_child(more)


static func _card(main: Node, pid: String) -> Control:
	var P: Dictionary = LegendPaths.PATHS[pid]
	var s = LegendPaths.state(pid)
	var pcol: Color = P["color"]
	var card = UI.card(pcol if s >= LegendPaths.JOINED else Color(1, 1, 1, 0.12))
	var v = UI.vbox(8)
	card.add_child(v)
	if s == LegendPaths.UNKNOWN:
		v.add_child(UI.icon_label("seal", "Gizli Yol", 20, UI.MUTED))
		v.add_child(UI.label("Henüz bir söylenti duymadın. (Güç %d civarında kulağına bir şeyler çalınabilir)" % LegendPaths.lv_need(pid, "rumor_level"), 14, UI.MUTED))
		return card
	var head = UI.hbox(14)
	v.add_child(head)
	head.add_child(UI.icon_label(P["icon"], P["name"], 22, pcol))
	var stxt = ["", "Söylenti", "İn bulundu", "Sınavda", "Yoldasın"][s]
	head.add_child(UI.label("•  " + stxt, 16, pcol.lightened(0.3) if s >= LegendPaths.JOINED else UI.TEXT))
	v.add_child(UI.label(P["style"], 14, UI.MUTED))
	var M: Dictionary = P["mentor"]
	v.add_child(UI.label("Usta: %s (%s)   •   Yer: %s" % [M["name"] if s >= LegendPaths.FOUND else "???", M["title"], P["site"]["place"]], 15, UI.TEXT))
	if s >= LegendPaths.JOINED:
		v.add_child(UI.label("Yol bonusu: " + P["passive_desc"], 14, UI.GOOD))
	var nx = UI.label("Sıradaki adım: " + LegendPaths.next_step(pid), 15, UI.GOLD)
	nx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nx.custom_minimum_size = Vector2(1000, 0)
	v.add_child(nx)
	if LegendPaths.lairs.has(pid):
		var at: Array = LegendPaths.lairs[pid]
		var place: String = P["site"]["place"]
		v.add_child(UI.button("İzi takip et", func():
			var wp = Game.from_map(Vector2(float(at[0]), float(at[1])))
			Game.profile["waypoint"] = [wp.x, wp.y, wp.z, place]
			Game.profile["track"] = "waypoint"
			Hud.msg("Yol gösteriliyor: %s" % place, pcol.lightened(0.3))
			main.resume(), 260, "map"))
		v.get_child(v.get_child_count() - 1).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# teknikler
	var grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	var learned: Array = Game.profile.get("learned", [])
	for jid in P["order"]:
		var j: Dictionary = Data.jutsu.get(jid, {})
		var nm = String(j.get("name", jid)).split(" (")[0]
		var have = jid in learned
		var dark = int(P["dark"].get(jid, 0)) > 0
		var tx = "%s  Güç %d%s%s" % [nm, int(j.get("level", 1)), "  ⚠" if dark else "", "  ✦" if P["quest"].has(jid) else ""]
		var l = UI.label(("✓ " if have else "· ") + tx, 13, UI.GOOD if have else (Color(0.85, 0.6, 0.95) if dark else UI.MUTED))
		l.tooltip_text = String(j.get("desc", ""))
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		l.custom_minimum_size = Vector2(340, 0)
		grid.add_child(l)
	v.add_child(UI.label("✦ ustanın özel sınavıyla öğrenilir   ⚠ yasak sanat: köy itibarı düşer", 12, UI.MUTED))
	return card
