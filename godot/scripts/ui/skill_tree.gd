class_name SkillTree
extends RefCounted
## Yetenek ağacı ekranı (Tab > Yetenekler): üstte dal sekmeleri, ortada sürüklenip yakınlaştırılabilen düğüm grafiği
## (kademe satırları, ön şart çizgileri, kilitli/açık/öğrenilmiş durumları), sağda ayrıntı kartı + onaylı öğrenme.
## Veri: data/skills.json (tools/build_skills.py), etkiler: Stats.skill().

static var branch := "taijutsu"
static var sel := ""
static var zoom := 1.0
static var pan := Vector2.ZERO
static var confirm := ""
static var fitted := ""


## Dalın tüm kademeleri görünecek şekilde yakınlaştırma
static func _fit(br: String) -> void:
	var maxt = 1
	for n in _nodes_of(br):
		maxt = maxi(maxt, int(n["tier"]))
	zoom = clampf(560.0 / (maxt * 140.0 + 30.0), 0.55, 1.0)
	pan = Vector2.ZERO
	fitted = br

const FX_TEXT := {
	"hp": "Maks can %+d", "chakra": "Maks chakra %+d", "melee": "Yakın dövüş %+d%%", "jutsu": "Jutsu hasarı %+d%%", "speed": "Koşu hızı %+d%%",
	"regen_chakra": "Chakra yenilenmesi %+d%%", "regen_hp": "Can yenilenmesi %+d%%", "jutsu_cost": "Jutsu maliyeti %+d%%", "seal_speed": "Mühür hızı %+d%%",
	"wall_run": "Duvar koşusu hızı %+d%%", "leap": "Ctrl sıçrayış mesafesi %+d%%", "air_dash": "Havada atılma %+d", "jumps": "Havada zıplama %+d",
	"water_cost": "Su üstü chakra tüketimi %+d%%", "guard": "Blokta hasar azaltma %+d%%", "def": "Alınan hasar azaltma %+d%%", "throw_dmg": "Atış hasarı %+d%%",
	"tag_dmg": "Patlayıcı/tuzak hasarı %+d%%", "kg": "Kekkei genkai jutsuları %+d%%", "gen_power": "Genjutsu gücü %+d%%", "gen_resist": "Genjutsu direnci %+d%%",
	"heal": "İyileştirme %+d%%", "poison_resist": "Zehir/yanık direnci %+d%%", "sage_time": "Sennin süresi %+d%%", "sage_power": "Sennin gücü %+d%%",
	"summon_cost": "Çağırma maliyeti %+d%%", "summon_power": "Çağrı gücü %+d%%", "eye_cost": "Göz chakra maliyeti %+d%%", "eye_power": "Göz teknikleri %+d%%",
	"eye_dodge": "Göz öngörüsü kaçış %+d%%", "eye_cd": "Göz bekleme süresi %+d%%", "shop": "Dükkân fiyatları %+d%%", "xp": "XP %+d%%", "ryo": "Kazanılan Ryō %+d%%",
	"stealth": "Gizlilik %+d%%", "sense": "Algılama mesafesi %+d%%", "squad": "Müttefik gücü %+d%%", "combo": "Kombo hızı %+d%%", "el_main": "Ana doğa jutsuları %+d%%",
	"el_all": "Tüm element jutsuları %+d%%", "gates": "Sekiz Kapı dayanımı %+d%%", "carry": "Taşıma %+d%%", "fuin": "Mühür jutsuları %+d%%", "backstab": "Arkadan saldırı %+d%%",
	"rep": "İtibar kazancı %+d%%", "w_all": "Tüm silahlar %+d%%", "w_blade": "Bıçaklar %+d%%", "w_dual": "Çift silah %+d%%", "w_sword": "Kılıçlar %+d%%",
	"w_heavy": "Ağır silahlar %+d%%", "w_staff": "Sopa/mızrak %+d%%", "w_chain": "Zincir %+d%%", "w_sickle": "Orak %+d%%", "w_fan": "Yelpaze %+d%%", "w_claw": "Pençe %+d%%",
}
const FLAT := ["hp", "chakra", "air_dash", "jumps"]


static func fx_lines(n: Dictionary) -> Array:
	var out = []
	for k in n.get("fx", {}):
		var v = float(n["fx"][k])
		var fmt: String = FX_TEXT.get(k, k + " %+d")
		out.append(fmt % (int(v) if k in FLAT else int(round(v * 100.0))))
	for u in n.get("unlock", []):
		out.append("Açar: " + {"genjutsu": "genjutsu teknikleri", "kai": "Kai (genjutsu çözme)", "gentle_fist": "Yumuşak Yumruk", "strong_fist": "Güçlü Yumruk",
			"gates": "Sekiz Kapı ustalığı", "elem2": "ikinci chakra doğası", "elem3": "üçüncü chakra doğası", "barrier": "bariyer mühürü", "scroll_store": "parşömen deposu",
			"scalpel": "chakra neşteri", "wire": "tel tuzakları", "multi_throw": "çoklu atış", "mark_teleport": "ışınlanma işareti", "sensor": "algılayıcı ninja",
			"lotus": "Ön Lotus", "shape": "şekil dönüşümü", "gen_reflect": "genjutsu yansıtma", "byakugou": "yüz mühürü"}.get(u, u))
	return out


static func _nodes_of(br: String) -> Array:
	var out = []
	var nodes: Dictionary = Data.skills.get("nodes", {})
	for sid in nodes:
		if nodes[sid]["branch"] == br:
			out.append(nodes[sid])
	return out


## Düğümlerin grafik konumları (kademe satırları, satır içinde ortalı)
static func _layout(br: String) -> Dictionary:
	var rows = {}
	for n in _nodes_of(br):
		var t = int(n["tier"])
		if not rows.has(t):
			rows[t] = []
		rows[t].append(n["id"])
	var pos = {}
	for t in rows:
		var ids: Array = rows[t]
		for i in ids.size():
			pos[ids[i]] = Vector2((i - (ids.size() - 1) * 0.5) * 178.0, 70.0 + (t - 1) * 140.0)
	return pos


static func build(main: Node, body: Control) -> void:
	var pr = Game.profile
	var nodes: Dictionary = Data.skills.get("nodes", {})
	var root = UI.vbox(14)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(root)
	var redraw = func() -> void:
		Menus.ninja_menu(main, "skills")
	# --- üst: dal sekmeleri + puan
	var top = UI.hbox(10)
	root.add_child(top)
	top.add_child(UI.icon_label("star", "Yetenek puanı: %d" % int(pr.get("sp", 0)), 20, UI.GOLD))
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	top.add_child(spacer)
	var tabs = HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tabs)
	for b in Data.skills.get("branches", []):
		var own = 0
		var tot = 0
		for n in _nodes_of(b["id"]):
			tot += 1
			if n["id"] in pr["skills"]:
				own += 1
		var bid: String = b["id"]
		tabs.add_child(UI.chip("%s  %d/%d" % [b["name"], own, tot], branch == bid, func():
			branch = bid
			sel = ""
			confirm = ""
			pan = Vector2.ZERO
			redraw.call()))
	var h = UI.hbox(18)
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(h)
	# --- orta: kaydırılabilir / yakınlaştırılabilir grafik
	var view = Panel.new()
	view.custom_minimum_size = Vector2(880, 600)
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.clip_contents = true
	view.add_theme_stylebox_override("panel", UI._box(Color(0.03, 0.035, 0.05, 0.55), Color(1, 1, 1, 0.08), 1, 14, 0))
	h.add_child(view)
	var canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(canvas)
	if fitted != branch:
		_fit(branch)
	var pos = _layout(branch)
	var place = func() -> void:
		canvas.scale = Vector2.ONE * zoom
		canvas.position = Vector2(view.size.x * 0.5, 10.0) + pan
	view.resized.connect(place)
	place.call_deferred()
	var drag = {"on": false}
	view.gui_input.connect(func(e):
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_LEFT:
				drag["on"] = e.pressed
			elif e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				var old = zoom
				zoom = clampf(zoom * (1.1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 0.9), 0.5, 1.6)
				# imleç altındaki nokta yerinde kalsın
				var anchor = Vector2(view.size.x * 0.5, 10.0)
				var local = (e.position - anchor - pan) / old
				pan = e.position - anchor - local * zoom
				place.call()
		elif e is InputEventMouseMotion and drag["on"]:
			pan += e.relative
			place.call())
	# ön şart çizgileri
	var lines = Control.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(lines)
	lines.draw.connect(func():
		for sid in pos:
			for r in nodes[sid]["req"]:
				if not pos.has(r):
					continue
				var owned = sid in pr["skills"] and r in pr["skills"]
				var ready = r in pr["skills"]
				var col = Color(UI.GOLD, 0.9) if owned else (Color(1, 1, 1, 0.45) if ready else Color(1, 1, 1, 0.12))
				var a: Vector2 = pos[r] + Vector2(0, 76)   # etiketlerin altından çık
				var b: Vector2 = pos[sid] - Vector2(0, 38)
				var mid = b.y - 14.0
				lines.draw_polyline(PackedVector2Array([a, Vector2(a.x, mid), Vector2(b.x, mid), b]), col, 3.0 if owned else 2.0, true))
	# kademe etiketleri
	var tiers = {}
	for sid in pos:
		tiers[int(nodes[sid]["tier"])] = true
	for t in tiers:
		var tl = UI.label("Kademe %d" % t, 12, Color(1, 1, 1, 0.25))
		tl.position = Vector2(-560, 60.0 + (t - 1) * 140.0)
		canvas.add_child(tl)
	# --- sağ: ayrıntı kartı
	var right = UI.card()
	right.custom_minimum_size = Vector2(400, 0)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(right)
	var rv = UI.vbox(10)
	right.add_child(rv)
	var detail = func(sid: String) -> void:
		_detail(main, rv, sid)
		# kart genişliği içeriğe göre değişmesin: değişirse grafik sağa sola kayar
		for c in rv.get_children():
			if c is Label:
				c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				c.custom_minimum_size.x = 360.0
	# düğümler
	var bicon = "star"
	for b in Data.skills.get("branches", []):
		if b["id"] == branch:
			bicon = b["icon"]
	for sid in pos:
		var n: Dictionary = nodes[sid]
		var owned: bool = sid in pr["skills"]
		var block = Stats.skill_block(pr, sid)
		var can: bool = block == ""
		var col = UI.GOLD if owned else (UI.GOOD if can else Color(1, 1, 1, 0.28))
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(76, 76)
		btn.size = Vector2(76, 76)
		btn.position = pos[sid] - Vector2(38, 38)
		var nb = UI._box(Color(UI.GOLD, 0.24) if owned else Color(0.07, 0.08, 0.11, 0.96), col, 3 if (owned or can) else 1, 38, 0)
		var hb = nb.duplicate()
		hb.border_color = UI.GOLD
		hb.set_border_width_all(3)
		var sb = hb.duplicate()
		sb.shadow_color = Color(UI.GOLD, 0.55)
		sb.shadow_size = 14
		btn.add_theme_stylebox_override("normal", sb if sel == sid else nb)
		btn.add_theme_stylebox_override("hover", sb if sel == sid else hb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb if sel == sid else hb)
		var ic = Icons.view(n.get("icon", "") if n.get("icon", "") != "" else bicon, 36, col)
		ic.position = Vector2(20, 20)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ic)
		if not owned:
			var cost = UI.label(str(int(n["cost"])), 12, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
			cost.position = Vector2(54, 54)
			cost.size = Vector2(18, 16)
			btn.add_child(cost)
		btn.mouse_entered.connect(func(): detail.call(sid))
		btn.mouse_exited.connect(func(): detail.call(sel))
		btn.pressed.connect(func():
			Sfx.play("click")
			sel = sid
			confirm = ""
			redraw.call())
		canvas.add_child(btn)
		var nl = UI.label(n["name"], 13, col if not owned else UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
		nl.position = pos[sid] + Vector2(-85, 42)
		nl.size = Vector2(170, 18)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(nl)
		var ll = UI.label("Sv.%d" % int(n["level"]), 11, Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
		ll.position = pos[sid] + Vector2(-40, 60)
		ll.size = Vector2(80, 14)
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(ll)
	root.add_child(UI.label("Sürükle: kaydır   •   Tekerlek: yakınlaştır   •   Tıkla: seç, sonra Öğren", 12, UI.MUTED))
	detail.call(sel)


static func _detail(main: Node, rv: VBoxContainer, sid: String) -> void:
	for c in rv.get_children():
		c.queue_free()
	var pr = Game.profile
	var nodes: Dictionary = Data.skills.get("nodes", {})
	if sid == "" or not nodes.has(sid):
		rv.add_child(UI.label("Bir düğüm seç.", 16, UI.MUTED))
		rv.add_child(UI.label("Her seviyede 1 puan, her 10 seviyede +2 bonus kazanırsın. Tüm ağacı açamazsın: yolunu seç.", 13, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		return
	var n: Dictionary = nodes[sid]
	var owned: bool = sid in pr["skills"]
	var block = Stats.skill_block(pr, sid)
	var nm = UI.label(n["name"], 24, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	rv.add_child(nm)
	var bname = n["branch"]
	for b in Data.skills.get("branches", []):
		if b["id"] == n["branch"]:
			bname = b["name"]
	rv.add_child(UI.label("%s   •   Kademe %d   •   %d puan" % [bname, int(n["tier"]), int(n["cost"])], 14, UI.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var d = UI.label(n["desc"], 16, UI.TEXT)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(360, 0)
	rv.add_child(d)
	for line in fx_lines(n):
		rv.add_child(UI.label("• " + line, 15, UI.GOOD))
	# şartlar
	rv.add_child(UI.label("Şartlar", 14, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, true))
	var ok_lv = int(pr["level"]) >= int(n["level"])
	rv.add_child(UI.label(("✓ " if ok_lv else "✗ ") + "Seviye %d" % int(n["level"]), 14, UI.GOOD if ok_lv else UI.BAD))
	for r in n["req"]:
		var have = r in pr["skills"]
		rv.add_child(UI.label(("✓ " if have else "✗ ") + nodes.get(r, {}).get("name", r), 14, UI.GOOD if have else UI.BAD))
	var need: Dictionary = n.get("need", {})
	if need.get("clanless", false):
		rv.add_child(UI.label("• Yalnızca klansız ninjalar", 14, UI.MUTED))
	if need.has("rank"):
		rv.add_child(UI.label("• Rütbe: %s" % Data.RANKS[mini(int(need["rank"]), Data.RANKS.size() - 1)], 14, UI.MUTED))
	if need.get("eye", false):
		rv.add_child(UI.label("• Bir dōjutsu gözü", 14, UI.MUTED))
	if need.get("kg", false):
		rv.add_child(UI.label("• Bir kekkei genkai", 14, UI.MUTED))
	if owned:
		rv.add_child(UI.icon_label("check", "Öğrenildi", 18, UI.GOLD))
		return
	if block != "":
		rv.add_child(UI.label(block, 15, UI.BAD, HORIZONTAL_ALIGNMENT_LEFT, true))
		return
	if sid != sel:
		rv.add_child(UI.label("Öğrenmek için düğüme tıkla.", 14, UI.MUTED))
		return
	if confirm != sid:
		rv.add_child(UI.primary("Öğren (%d puan)" % int(n["cost"]), func():
			confirm = sid
			Menus.ninja_menu(main, "skills"), 360, "plus"))
	else:
		rv.add_child(UI.label("Emin misin? %d puan harcanacak." % int(n["cost"]), 15, UI.GOLD))
		var row = UI.hbox(8)
		rv.add_child(row)
		row.add_child(UI.primary("Onayla", func(): learn(main, sid), 180, "check"))
		row.add_child(UI.button("Vazgeç", func():
			confirm = ""
			Menus.ninja_menu(main, "skills"), 160))


## Öğren (elem2/elem3: önce doğa seçimi)
static func learn(main: Node, sid: String) -> void:
	var pr = Game.profile
	var n: Dictionary = Data.skills["nodes"][sid]
	confirm = ""
	if "elem2" in n.get("unlock", []) or "elem3" in n.get("unlock", []):
		var opts = []
		for e in ["katon", "suiton", "fuuton", "doton", "raiton"]:
			if e in pr["elements"]:
				continue
			opts.append({"label": e.capitalize(), "cb": func():
				if not Stats.learn_skill(pr, sid):
					return
				pr["elements"].append(e)
				var starter = {"katon": "katon_goukakyuu", "suiton": "suiton_suikoudan", "fuuton": "fuuton_shinkuu", "doton": "doton_doryuusou", "raiton": "raiton_nagashi"}[e]
				Progress.learn(starter)
				if Game.player:
					Game.player.apply_profile_stats()})
		Hud.dialog("Yeni Chakra Doğası", "Hangi doğayı geliştireceksin?", opts)
		return
	if Stats.learn_skill(pr, sid):
		Sfx.play("levelup", null, 1.4, 0.6)
		Hud.msg("Yeni yetenek: %s" % n["name"], Color(0.95, 0.8, 0.45))
		if Game.player:
			Game.player.apply_profile_stats()
	Menus.ninja_menu(main, "skills")
