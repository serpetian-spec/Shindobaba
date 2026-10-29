class_name UI
extends RefCounted
## Modern arayüz teması ve widget fabrikaları: cam efektli koyu paneller, yuvarlak köşeler, ince altın vurgular,
## sade tipografi (sistem fontu: Bahnschrift/Segoe UI), simge tabanlı düğmeler, yumuşak geçişler.

const ACCENT := Color(0.98, 0.62, 0.2)
const ACCENT_DARK := Color(0.55, 0.3, 0.08)
const GOLD := Color(0.95, 0.78, 0.42)
const INK := Color(0.045, 0.05, 0.065)
const PANEL := Color(0.05, 0.058, 0.078, 0.92)
const GLASS := Color(0.09, 0.1, 0.13, 0.72)
const LINE := Color(1, 1, 1, 0.09)
const TEXT := Color(0.95, 0.95, 0.97)
const CREAM := Color(1.0, 0.95, 0.85)
const MUTED := Color(0.62, 0.65, 0.72)
const GOOD := Color(0.45, 0.9, 0.55)
const BAD := Color(1.0, 0.42, 0.38)
const ELEMENT_COLORS := {"katon": Color(1.0, 0.42, 0.12), "suiton": Color(0.25, 0.6, 1.0), "fuuton": Color(0.5, 0.92, 0.7),
	"doton": Color(0.78, 0.58, 0.32), "raiton": Color(0.75, 0.8, 1.0), "": Color(0.85, 0.78, 0.6)}
const ELEMENT_ICONS := {"katon": "flame", "suiton": "drop", "fuuton": "wind", "doton": "rock", "raiton": "bolt", "": "chakra"}
## Nadirlik: sıradan, nadir, ender, destansı, efsanevi
const RARITY := [Color(0.62, 0.65, 0.7), Color(0.4, 0.85, 0.45), Color(0.35, 0.6, 1.0), Color(0.72, 0.42, 1.0), Color(1.0, 0.72, 0.25)]
const RARITY_NAMES := ["Sıradan", "Nadir", "Ender", "Destansı", "Efsanevi"]

static var _theme: Theme
static var _font: Font
static var _font_bold: Font


static func font(bold := false) -> Font:
	if _font == null:
		var f = SystemFont.new()
		f.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Noto Sans", "Arial"])
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_font = f
		var fb = SystemFont.new()
		fb.font_names = PackedStringArray(["Bahnschrift SemiBold", "Bahnschrift", "Segoe UI Semibold", "Segoe UI", "Arial"])
		fb.font_weight = 650
		_font_bold = fb
	return _font_bold if bold else _font


static func _box(bg: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 10, margin := 10.0, skew := 0.0) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.skew = Vector2(skew, 0)
	sb.anti_aliasing = true
	sb.corner_detail = 6
	return sb


static func glass(radius := 14, margin := 18.0, alpha := 0.82) -> StyleBoxFlat:
	var sb = _box(Color(PANEL, alpha), LINE, 1, radius, margin)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 18
	return sb


static func theme() -> Theme:
	if _theme:
		return _theme
	var t = Theme.new()
	t.default_font = font()
	t.default_font_size = 17
	t.set_stylebox("panel", "PanelContainer", glass())
	t.set_stylebox("panel", "Panel", glass())
	# düğme: sade, yuvarlak, üzerine gelince aydınlanan
	var bn = _box(Color(0.07, 0.08, 0.1, 0.86), Color(1, 1, 1, 0.1), 1, 10, 10)
	bn.content_margin_left = 18; bn.content_margin_right = 18
	var bh = bn.duplicate()
	bh.bg_color = Color(0.16, 0.17, 0.2, 0.94)
	bh.border_color = Color(GOLD, 0.6)
	var bp = bh.duplicate()
	bp.bg_color = Color(ACCENT, 0.35)
	var bd = bn.duplicate()
	bd.bg_color = Color(0.06, 0.065, 0.08, 0.6)
	bd.border_color = Color(1, 1, 1, 0.04)
	var bf = bh.duplicate()
	bf.border_color = GOLD
	bf.set_border_width_all(2)
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("focus", "Button", bf)
	t.set_stylebox("disabled", "Button", bd)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_focus_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.52, 0.56))
	t.set_constant("outline_size", "Button", 0)
	t.set_constant("h_separation", "Button", 10)
	t.set_color("font_color", "Label", TEXT)
	for k in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(k, "OptionButton", t.get_stylebox(k, "Button"))
	t.set_color("font_color", "OptionButton", TEXT)
	var le = _box(Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.12), 1, 10, 10)
	t.set_stylebox("normal", "LineEdit", le)
	var lef = le.duplicate()
	lef.border_color = GOLD
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_color("caret_color", "LineEdit", GOLD)
	# kaydırma çubuğu: ince, yuvarlak
	t.set_stylebox("grabber", "VScrollBar", _box(Color(1, 1, 1, 0.18), Color(0, 0, 0, 0), 0, 6, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", _box(Color(GOLD, 0.7), Color(0, 0, 0, 0), 0, 6, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", _box(GOLD, Color(0, 0, 0, 0), 0, 6, 0))
	var sbg = _box(Color(1, 1, 1, 0.03), Color(0, 0, 0, 0), 0, 6, 3)
	t.set_stylebox("scroll", "VScrollBar", sbg)
	var sep = StyleBoxLine.new()
	sep.color = LINE
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 14)
	# kaydırıcı
	t.set_stylebox("slider", "HSlider", _box(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 0, 4, 2))
	t.set_stylebox("grabber_area", "HSlider", _box(Color(GOLD, 0.85), Color(0, 0, 0, 0), 0, 4, 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(GOLD, Color(0, 0, 0, 0), 0, 4, 2))
	var cb_n = StyleBoxEmpty.new()
	cb_n.content_margin_left = 6; cb_n.content_margin_top = 4; cb_n.content_margin_bottom = 4
	for k in ["normal", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(k, "CheckBox", cb_n)
	t.set_stylebox("hover", "CheckBox", _box(Color(1, 1, 1, 0.06), Color(0, 0, 0, 0), 0, 8, 4))
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_pressed_color", "CheckBox", Color(1, 1, 1))
	t.set_color("font_hover_color", "CheckBox", Color(1, 1, 1))
	var tt = _box(Color(0.05, 0.055, 0.07, 0.97), Color(GOLD, 0.4), 1, 10, 10)
	t.set_stylebox("panel", "TooltipPanel", tt)
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font("font", "TooltipLabel", font())
	_theme = t
	return t


static func label(text: String, size := 17, col := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT, bold := false) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", font(bold or size >= 22))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1 if size < 24 else 2)
	l.add_theme_constant_override("shadow_outline_size", 1 if size < 24 else 3)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Küçük, sade başlık: üstte ince altın çizgi, büyük harf, geniş harf aralığı hissi
static func header(text: String, size := 22) -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var line = ColorRect.new()
	line.color = GOLD
	line.custom_minimum_size = Vector2(28, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(line)
	v.add_child(label(text, size, CREAM, HORIZONTAL_ALIGNMENT_LEFT, true))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


## Üzerine gelince hafifçe büyüyen kontrol
static func hover_anim(c: Control, amount := 1.03) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	c.mouse_entered.connect(func():
		var tw = c.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(c, "scale", Vector2.ONE * amount, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	c.mouse_exited.connect(func():
		var tw = c.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(c, "scale", Vector2.ONE, 0.12))


static func button(text: String, cb: Callable, minw := 260, icon_kind := "") -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minw, 46)
	b.add_theme_font_override("font", font(true))
	b.add_theme_font_size_override("font_size", 17)
	b.focus_mode = Control.FOCUS_ALL
	if icon_kind != "":
		b.icon = Icons.tex(icon_kind, 40, TEXT)
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 22)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.8, 0.18))
	hover_anim(b, 1.02)
	return b


## Vurgulu ana eylem düğmesi (altın dolgu)
static func primary(text: String, cb: Callable, minw := 260, icon_kind := "") -> Button:
	var b = button(text, cb, minw, icon_kind)
	var n = _box(Color(GOLD, 0.92), Color(1, 1, 1, 0.25), 1, 10, 10)
	n.content_margin_left = 22; n.content_margin_right = 22
	var h = n.duplicate()
	h.bg_color = Color(1.0, 0.86, 0.55)
	var p = n.duplicate()
	p.bg_color = ACCENT
	for k in [["normal", n], ["hover", h], ["pressed", p], ["focus", h]]:
		b.add_theme_stylebox_override(k[0], k[1])
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, INK)
	if icon_kind != "":
		b.icon = Icons.tex(icon_kind, 40, INK)
	return b


## Parşömen/kâğıt üzerinde mürekkep düğme (koyu yazı, ince mürekkep çerçeve)
static func ink_button(text: String, cb: Callable, minw := 220) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minw, 42)
	b.add_theme_font_override("font", font(true))
	b.add_theme_font_size_override("font_size", 16)
	var ink = Color(0.16, 0.1, 0.06)
	var n = _box(Color(ink, 0.06), Color(ink, 0.6), 2, 8, 8)
	var h = _box(Color(ink, 0.85), Color(ink, 0.9), 2, 8, 8)
	for k in [["normal", n], ["hover", h], ["pressed", h], ["focus", h]]:
		b.add_theme_stylebox_override(k[0], k[1])
	b.add_theme_color_override("font_color", ink)
	for k in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, Color(1, 0.94, 0.85))
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


## Yalnız simge + altında küçük yazı (sekme rayı, eylem kutuları)
static func icon_button(kind: String, text: String, cb: Callable, size := 72, selected := false) -> Button:
	var b = Button.new()
	b.text = text
	b.icon = Icons.tex(kind, 64, GOLD if selected else TEXT)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", int(size * 0.42))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.custom_minimum_size = Vector2(size, size)
	b.add_theme_font_override("font", font(true))
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", GOLD if selected else MUTED)
	b.add_theme_color_override("font_hover_color", TEXT)
	var n = StyleBoxEmpty.new()
	n.content_margin_top = 10
	var h = _box(Color(1, 1, 1, 0.07), Color(0, 0, 0, 0), 0, 12, 6)
	h.content_margin_top = 10
	var s = _box(Color(GOLD, 0.14), Color(GOLD, 0.55), 1, 12, 6)
	s.content_margin_top = 10
	b.add_theme_stylebox_override("normal", s if selected else n)
	b.add_theme_stylebox_override("hover", s if selected else h)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_stylebox_override("focus", s if selected else h)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.8, 0.18))
	return b


## Hap şeklinde seçim çipi (filtreler, seçenekler)
static func chip(text: String, on: bool, cb: Callable, minw := 0) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minw, 36)
	b.add_theme_font_override("font", font(true))
	b.add_theme_font_size_override("font_size", 14)
	var n = _box(Color(0.07, 0.08, 0.1, 0.8), Color(1, 1, 1, 0.12), 1, 18, 8)
	n.content_margin_left = 16; n.content_margin_right = 16
	var h = n.duplicate()
	h.bg_color = Color(0.16, 0.17, 0.2, 0.92)
	var s = n.duplicate()
	s.bg_color = Color(GOLD, 0.9)
	s.border_color = Color(1, 1, 1, 0.3)
	b.add_theme_stylebox_override("normal", s if on else n)
	b.add_theme_stylebox_override("hover", s if on else h)
	b.add_theme_stylebox_override("pressed", s)
	b.add_theme_stylebox_override("focus", s if on else h)
	var fc = INK if on else TEXT
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fc)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


## İnce, yuvarlak dolum çubuğu
static func bar(col: Color, w := 340.0, h := 10.0, _skew := 0.0) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.custom_minimum_size = Vector2(w, h)
	pb.show_percentage = false
	var r = int(h * 0.5)
	var bg = _box(Color(0, 0, 0, 0.45), Color(1, 1, 1, 0.08), 1, r, 0)
	var fg = _box(col, Color(0, 0, 0, 0), 0, r, 0)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


static func panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.theme = theme()
	return p


## Kart: cam panel, isteğe bağlı vurgu rengiyle ince kenar
static func card(accent := Color(0, 0, 0, 0), radius := 12, margin := 14.0) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = _box(Color(1, 1, 1, 0.045), Color(1, 1, 1, 0.08) if accent.a == 0.0 else Color(accent, 0.7), 1, radius, margin)
	p.add_theme_stylebox_override("panel", sb)
	return p


## Tuş rozeti
static func key_badge(k: String, size := 14) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = _box(Color(1, 1, 1, 0.92), Color(0, 0, 0, 0), 0, 6, 2)
	sb.content_margin_left = 7; sb.content_margin_right = 7
	p.add_theme_stylebox_override("panel", sb)
	var l = label(k, size, INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	l.add_theme_constant_override("shadow_outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Simge + metin satırı
static func icon_label(kind: String, text: String, size := 16, col := TEXT) -> HBoxContainer:
	var h = hbox(8)
	h.add_child(Icons.view(kind, size + 4, col))
	var l = label(text, size, col)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


## Açılış animasyonu (duraklatılmışken de çalışır)
static func pop_in(c: Control, from_scale := 0.97, dur := 0.18) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2.ONE * from_scale
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	var tw = c.create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "modulate:a", 1.0, dur)
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Soldan kayarak gelme
static func slide_in(c: Control, dx := -24.0, delay := 0.0, dur := 0.22) -> void:
	c.modulate.a = 0.0
	var tw = c.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(delay)
	tw.tween_callback(func():
		var x = c.position.x
		c.position.x = x + dx
		var t2 = c.create_tween().set_parallel(true)
		t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t2.tween_property(c, "modulate:a", 1.0, dur)
		t2.tween_property(c, "position:x", x, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))


static func vbox(sep := 8) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(w := 0.0, h := 0.0, expand := true) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(w, h)
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Eşya nadirliği: rütbe / fiyat / efsanevi listesinden
static func rarity_of_gear(id: String) -> int:
	var it = Gear.item(id)
	if id in Gear.LEGENDARY:
		return 4
	if it.has("unique"):
		return int(it["unique"])
	var r = int(it.get("rank", 0))
	var p = int(it.get("price", 0))
	if r >= 4 or p >= 2000:
		return 3
	if r >= 2 or p >= 600:
		return 2
	if r >= 1 or p >= 200:
		return 1
	return 0
