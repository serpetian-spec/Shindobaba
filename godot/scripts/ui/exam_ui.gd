class_name ExamUI
extends RefCounted
## Sınav ekranları: yazılı sınav kâğıdı (parşömen, süre, kopya çekme), sonuç kartı, seçim kartları, eşleşme tablosu.
## Modern arayüz yardımcılarını (UI.gd, Menus._full) kullanır; oyun bu ekranlarda duraklatılır.

const INK := Color(0.16, 0.1, 0.06)
const RED_INK := Color(0.72, 0.1, 0.08)


static func _main() -> Node:
	return Hud.get_tree().current_scene


static func _pause() -> void:
	var m = _main()
	if m and m.has_method("_pause") and not Game.paused:
		m._pause()
	Game.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func _resume() -> void:
	var m = _main()
	if m and m.has_method("resume"):
		m.resume()
	else:
		Menus.clear()
		Game.ui_open = false


static func _paper(parent: Control, size: Vector2, seed := 0.0) -> Control:
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var holder = Control.new()
	holder.custom_minimum_size = size
	cc.add_child(holder)
	var paper = ColorRect.new()
	var pm = ShaderMaterial.new()
	pm.shader = load("res://shaders/ui_parchment.gdshader")
	pm.set_shader_parameter("seed", seed)
	paper.material = pm
	paper.size = size
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(paper)
	UI.pop_in(holder, 0.96)
	return holder


static func _ink_label(text: String, size := 17, col := INK, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = UI.label(text, size, col, align, bold)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.add_theme_constant_override("outline_size", 0)
	return l


## Soruların şıklarını karıştır (doğru cevabın yeri her seferinde rastgele); [soru, şıklar, doğru_idx] biçimi korunur
static func shuffle_options(qs: Array) -> Array:
	var out = []
	for q in qs:
		var opts: Array = (q[1] as Array).duplicate()
		var right = String(opts[int(q[2])])
		opts.shuffle()
		var nq: Array = (q as Array).duplicate()
		nq[1] = opts
		nq[2] = opts.find(right)
		out.append(nq)
	return out


## Yazılı sınav. cfg: title, subtitle, questions [[soru, [şıklar], doğru_idx], ...], time (sn),
## cheat: 0 yok / 1 riskli kopya (yan sıraya bakmak) / 2 dōjutsu-sensör ile güvenli kopya, q10: Chūnin 10. soru ikilemi.
## done(result: {correct, total, caught, cheated, q10})
static func written(cfg: Dictionary, done: Callable) -> void:
	_pause()
	var qs: Array = shuffle_options(cfg["questions"])   # doğru cevap hep ilk şık olmasın
	var st = {"i": 0, "correct": 0, "caught": 0, "cheated": 0, "answers": [], "t": float(cfg.get("time", 120.0)), "over": false}
	var bg = Menus._full(0.62)
	var paper = _paper(bg, Vector2(860, 640), float(hash(cfg.get("title", "")) % 100) * 0.01)
	var v = UI.vbox(10)
	v.position = Vector2(56, 40)
	v.custom_minimum_size = Vector2(750, 0)
	paper.add_child(v)
	v.add_child(_ink_label("試験   " + String(cfg.get("title", "Yazılı Sınav")), 26, INK, true))
	v.add_child(_ink_label(String(cfg.get("subtitle", "")), 15, Color(INK, 0.75)))
	var head = UI.hbox(14)
	var qnum = _ink_label("", 16, RED_INK, true)
	head.add_child(qnum)
	head.add_child(UI.spacer())
	var timer_lbl = _ink_label("", 16, INK, true)
	head.add_child(timer_lbl)
	var strikes = _ink_label("", 15, RED_INK, true)
	head.add_child(strikes)
	v.add_child(head)
	var line = ColorRect.new()
	line.color = Color(INK, 0.35)
	line.custom_minimum_size = Vector2(750, 2)
	v.add_child(line)
	var qlbl = _ink_label("", 21, INK, true)
	qlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qlbl.custom_minimum_size = Vector2(750, 70)
	v.add_child(qlbl)
	var opts = UI.vbox(8)
	v.add_child(opts)
	var hint = _ink_label("", 15, Color(0.25, 0.3, 0.55), true)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(750, 0)
	v.add_child(hint)
	var bottom = UI.hbox(10)
	v.add_child(bottom)
	var finish = func() -> void:
		if st["over"]:
			return
		st["over"] = true
		_resume()
		done.call({"correct": st["correct"], "total": qs.size(), "caught": st["caught"], "cheated": st["cheated"], "q10": st.get("q10", "")})
	st["show"] = func() -> void:
		for c in opts.get_children():
			c.queue_free()
		for c in bottom.get_children():
			c.queue_free()
		hint.text = ""
		strikes.text = ("   Uyarı: %s" % "✗".repeat(int(st["caught"]))) if int(st["caught"]) > 0 else ""
		if int(st["i"]) >= qs.size():
			if cfg.get("q10", false):
				qnum.text = "10. SORU"
				qlbl.text = "Son soruyu almadan önce karar vermelisin. Kabul edip yanlış cevaplarsan, bir daha asla bu sınava giremezsin ve sonsuza dek Genin kalırsın. Reddedersen sen ve takımın şimdi elenirsiniz."
				opts.add_child(UI.ink_button("Soruyu alıyorum. Bir ninja asla geri adım atmaz.", func():
					st["q10"] = "kabul"
					finish.call(), 720))
				opts.add_child(UI.ink_button("Reddediyorum (takımla birlikte çekil)", func():
					st["q10"] = "ret"
					finish.call(), 720))
				return
			finish.call()
			return
		var q: Array = qs[int(st["i"])]
		qnum.text = "Soru %d / %d" % [int(st["i"]) + 1, qs.size() + (1 if cfg.get("q10", false) else 0)]
		qlbl.text = String(q[0])
		var letters = ["A", "B", "C", "D", "E"]
		for k in (q[1] as Array).size():
			var idx = k
			opts.add_child(UI.ink_button("%s)  %s" % [letters[k], q[1][k]], func():
				if idx == int(q[2]):
					st["correct"] = int(st["correct"]) + 1
				st["i"] = int(st["i"]) + 1
				st["show"].call(), 720))
		var cheat = int(cfg.get("cheat", 0))
		if cheat > 0:
			var txt = "👁 Dōjutsu / sensör ile yan sıradakinin kâğıdını oku" if cheat >= 2 else "Yan sıradakinin kâğıdına çaktırmadan bak (riskli)"
			bottom.add_child(UI.ink_button(txt, func():
				var risk = 0.08 if cheat >= 2 else 0.35
				st["cheated"] = int(st["cheated"]) + 1
				if randf() < risk:
					st["caught"] = int(st["caught"]) + 1
					hint.add_theme_color_override("font_color", RED_INK)
					hint.text = "Gözetmen: \"%s, sırandaki numaraya bakıyorum... İkinci uyarıda takımınla dışarıdasın.\" (−2 puan)" % Game.profile.get("name", "Aday")
					Sfx.play("hurt", null, 1.3, 0.4)
					if int(st["caught"]) >= 3:
						st["correct"] = 0
						finish.call()
					strikes.text = "   Uyarı: %s" % "✗".repeat(int(st["caught"]))
				else:
					hint.add_theme_color_override("font_color", Color(0.25, 0.3, 0.55))
					hint.text = "Kâğıtta işaretli cevap: %s) %s" % [letters[int(q[2])], q[1][int(q[2])]], 720))
	st["show"].call()
	# geri sayım
	var tick = bg.create_tween().set_loops(int(st["t"]) + 1)
	tick.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tick.tween_callback(func():
		if st["over"]:
			return
		st["t"] = float(st["t"]) - 1.0
		timer_lbl.text = "⏳ %d:%02d" % [int(st["t"]) / 60, int(st["t"]) % 60]
		if float(st["t"]) <= 0.0:
			finish.call()).set_delay(1.0)
	timer_lbl.text = "⏳ %d:%02d" % [int(st["t"]) / 60, int(st["t"]) % 60]


## Sonuç kartı: rows [[başlık, değer, iyi_mi], ...]
static func scorecard(title: String, rows: Array, verdict: String, passed: bool, on_close: Callable, button_text := "Devam") -> void:
	_pause()
	var bg = Menus._full(0.6)
	var v = Menus._center_panel(bg, 640)
	v.add_child(UI.header(title, 24))
	for r in rows:
		var h = UI.hbox(10)
		h.add_child(UI.icon_label("check" if r[2] else "close", String(r[0]), 17, UI.TEXT if r[2] else UI.MUTED))
		h.add_child(UI.spacer())
		h.add_child(UI.label(String(r[1]), 17, UI.GOOD if r[2] else UI.BAD, HORIZONTAL_ALIGNMENT_RIGHT, true))
		v.add_child(h)
	var sep = ColorRect.new()
	sep.color = UI.LINE
	sep.custom_minimum_size = Vector2(580, 1)
	v.add_child(sep)
	var vl = UI.label(verdict, 19, UI.GOOD if passed else UI.BAD, HORIZONTAL_ALIGNMENT_CENTER, true)
	vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vl.custom_minimum_size = Vector2(580, 0)
	v.add_child(vl)
	var row = UI.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.primary(button_text, func():
		_resume()
		on_close.call(), 260))
	v.add_child(row)


## Seçim kartları (uzmanlık, karar): cards [{id, title, desc, icon}]
static func choose_cards(title: String, subtitle: String, cards: Array, on_pick: Callable, allow_cancel := true) -> void:
	_pause()
	var bg = Menus._full(0.6)
	var v = Menus._center_panel(bg, 1080)
	v.add_child(UI.header(title, 24))
	var sl = UI.label(subtitle, 16, UI.MUTED)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.custom_minimum_size = Vector2(1000, 0)
	v.add_child(sl)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	for c in cards:
		var card = UI.card(UI.GOLD)
		card.custom_minimum_size = Vector2(330, 170)
		var cv = UI.vbox(6)
		card.add_child(cv)
		cv.add_child(UI.icon_label(String(c.get("icon", "star")), String(c["title"]), 18, UI.CREAM))
		var d = UI.label(String(c.get("desc", "")), 14, UI.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(300, 0)
		cv.add_child(d)
		cv.add_child(UI.spacer(0, 0, true))
		var cid = c["id"]
		cv.add_child(UI.primary("Seç", func():
			_resume()
			on_pick.call(cid), 120))
		grid.add_child(card)
	if allow_cancel:
		Menus._close_button(bg, func(): _resume())


## Turnuva tablosu: pairs [[a, b, winner_or_empty], ...]
static func bracket(title: String, pairs: Array, note: String, on_close: Callable) -> void:
	_pause()
	var bg = Menus._full(0.6)
	var v = Menus._center_panel(bg, 760)
	v.add_child(UI.header(title, 24))
	for i in pairs.size():
		var pr: Array = pairs[i]
		var card = UI.card(UI.ACCENT if String(pr[2]) == "" else UI.LINE)
		var h = UI.hbox(12)
		card.add_child(h)
		h.add_child(UI.label("Maç %d" % (i + 1), 15, UI.MUTED))
		for k in 2:
			var nm = String(pr[k])
			var won = String(pr[2]) == nm
			var lost = String(pr[2]) != "" and not won
			h.add_child(UI.label(nm, 18, UI.GOOD if won else (UI.MUTED if lost else UI.TEXT), HORIZONTAL_ALIGNMENT_LEFT, won))
			if k == 0:
				h.add_child(UI.label("  vs  ", 16, UI.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, true))
		v.add_child(card)
	var nl = UI.label(note, 15, UI.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.custom_minimum_size = Vector2(700, 0)
	v.add_child(nl)
	var row = UI.hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.primary("Arenaya çık", func():
		_resume()
		on_close.call(), 260, "sword"))
	v.add_child(row)
