class_name UI
extends RefCounted
## Ortak arayüz stili ve widget fabrikaları (Storm tarzı: mürekkep siyahı paneller, eğik fırça şeritleri,
## turuncu vurgu, krem yazı, kalın konturlu başlıklar, üzerine gelince büyüyen butonlar).

const ACCENT := Color(0.98, 0.55, 0.12)
const ACCENT_DARK := Color(0.62, 0.27, 0.04)
const INK := Color(0.055, 0.045, 0.06)
const PANEL := Color(0.07, 0.055, 0.07, 0.93)
const TEXT := Color(0.98, 0.95, 0.88)
const CREAM := Color(1.0, 0.93, 0.78)
const MUTED := Color(0.72, 0.68, 0.62)
const GOOD := Color(0.55, 0.95, 0.55)
const BAD := Color(1.0, 0.45, 0.38)
const ELEMENT_COLORS := {"katon": Color(1.0, 0.42, 0.12), "suiton": Color(0.25, 0.6, 1.0), "fuuton": Color(0.55, 0.95, 0.75),
	"doton": Color(0.75, 0.55, 0.3), "raiton": Color(0.85, 0.85, 1.0), "": Color(0.85, 0.75, 0.55)}

static var _theme: Theme


static func _box(bg: Color, border := Color(0, 0, 0, 0), bw := 0, radius := 3, margin := 10.0, skew := 0.0) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.skew = Vector2(skew, 0)
	sb.anti_aliasing = true
	return sb


static func theme() -> Theme:
	if _theme:
		return _theme
	var t = Theme.new()
	t.default_font_size = 18
	# panel: koyu mürekkep, solda kalın turuncu fırça çizgisi, yumuşak gölge
	var sb = _box(PANEL, ACCENT, 0, 4, 16)
	sb.border_width_left = 5
	sb.border_width_top = 1
	sb.border_color = ACCENT
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(4, 5)
	t.set_stylebox("panel", "PanelContainer", sb)
	t.set_stylebox("panel", "Panel", sb)
	# butonlar: eğik şerit
	var bn = _box(Color(0.13, 0.1, 0.11, 0.96), Color(0.36, 0.29, 0.26), 1, 3, 9, 0.12)
	bn.content_margin_left = 16; bn.content_margin_right = 16
	var bh = bn.duplicate()
	bh.bg_color = Color(0.36, 0.18, 0.06, 0.98)
	bh.border_color = ACCENT
	bh.border_width_bottom = 3
	var bp = bh.duplicate()
	bp.bg_color = ACCENT_DARK
	var bd = bn.duplicate()
	bd.bg_color = Color(0.09, 0.08, 0.09, 0.7)
	bd.border_color = Color(0.2, 0.18, 0.18)
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("focus", "Button", bh)
	t.set_stylebox("disabled", "Button", bd)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 0.9, 0.7))
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.52, 0.5))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Button", 3)
	t.set_color("font_color", "Label", TEXT)
	for k in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(k, "OptionButton", t.get_stylebox(k, "Button"))
	t.set_color("font_color", "OptionButton", TEXT)
	var le = _box(Color(0.1, 0.08, 0.09, 0.95), Color(0.36, 0.29, 0.26), 1, 3, 8)
	t.set_stylebox("normal", "LineEdit", le)
	var lef = le.duplicate()
	lef.border_color = ACCENT
	lef.border_width_bottom = 3
	t.set_stylebox("focus", "LineEdit", lef)
	# kaydırma çubuğu, ayırıcı, onay kutusu, kaydırıcı
	var sg = _box(ACCENT_DARK, Color(0, 0, 0, 0), 0, 4, 0)
	var sgh = _box(ACCENT, Color(0, 0, 0, 0), 0, 4, 0)
	var sbg = _box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 4, 2)
	t.set_stylebox("grabber", "VScrollBar", sg)
	t.set_stylebox("grabber_highlight", "VScrollBar", sgh)
	t.set_stylebox("grabber_pressed", "VScrollBar", sgh)
	t.set_stylebox("scroll", "VScrollBar", sbg)
	var sep = StyleBoxLine.new()
	sep.color = Color(ACCENT, 0.45)
	sep.thickness = 2
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 10)
	var slb = _box(Color(0.05, 0.04, 0.05, 0.9), Color(0.3, 0.25, 0.22), 1, 3, 3)
	t.set_stylebox("slider", "HSlider", slb)
	t.set_stylebox("grabber_area", "HSlider", _box(ACCENT_DARK, Color(0, 0, 0, 0), 0, 3, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(ACCENT, Color(0, 0, 0, 0), 0, 3, 3))
	var cb_n = StyleBoxEmpty.new()
	cb_n.content_margin_left = 6; cb_n.content_margin_top = 4; cb_n.content_margin_bottom = 4
	var cb_h = _box(Color(ACCENT, 0.12), Color(0, 0, 0, 0), 0, 3, 4)
	for k in ["normal", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(k, "CheckBox", cb_n)
	t.set_stylebox("hover", "CheckBox", cb_h)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_pressed_color", "CheckBox", CREAM)
	t.set_color("font_hover_color", "CheckBox", CREAM)
	var tt = _box(Color(0.06, 0.05, 0.06, 0.96), ACCENT, 1, 3, 8)
	t.set_stylebox("panel", "TooltipPanel", tt)
	t.set_color("font_color", "TooltipLabel", TEXT)
	_theme = t
	return t


static func label(text: String, size := 18, col := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4 if size < 24 else (7 if size < 40 else 10))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Bölüm başlığı: turuncu kalın yazı + altında eğik fırça şeridi
static func header(text: String, size := 24) -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(label(text, size, ACCENT))
	var strip = Panel.new()
	strip.custom_minimum_size = Vector2(minf(420.0, text.length() * size * 0.55 + 40.0), 4)
	strip.add_theme_stylebox_override("panel", _box(ACCENT, Color(0, 0, 0, 0), 0, 2, 0, 0.8))
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(strip)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


## Üzerine gelince hafifçe büyüyüp parlayan kontrol
static func hover_anim(c: Control, amount := 1.04) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	c.mouse_entered.connect(func():
		var tw = c.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(c, "scale", Vector2.ONE * amount, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	c.mouse_exited.connect(func():
		var tw = c.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(c, "scale", Vector2.ONE, 0.1))


static func button(text: String, cb: Callable, minw := 260) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minw, 42)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.6, 0.3))
	hover_anim(b, 1.03)
	return b


## Eğik, parlak kenarlı dolum çubuğu
static func bar(col: Color, w := 340.0, h := 18.0, skew := 0.35) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.custom_minimum_size = Vector2(w, h)
	pb.show_percentage = false
	var bg = _box(Color(0.04, 0.03, 0.04, 0.85), Color(0, 0, 0, 0.95), 2, 2, 0, skew)
	var fg = _box(col, col.lightened(0.45), 0, 2, 0, skew)
	fg.border_width_top = int(maxf(1.0, h * 0.18))
	fg.border_color = col.lightened(0.45)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


static func panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.theme = theme()
	return p


## Küçük, düz kart paneli (envanter kartları, slotlar)
static func card(accent := ACCENT) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = _box(Color(0.11, 0.085, 0.09, 0.95), Color(accent, 0.7), 1, 4, 10)
	sb.border_width_left = 4
	sb.border_color = accent
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(2, 3)
	p.add_theme_stylebox_override("panel", sb)
	return p


## Tuş rozeti: "[F]" gibi küçük kutu
static func key_badge(k: String, size := 15) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = _box(CREAM, INK, 2, 4, 3)
	sb.content_margin_left = 7; sb.content_margin_right = 7
	p.add_theme_stylebox_override("panel", sb)
	var l = label(k, size, INK, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Açılış animasyonu (duraklatılmışken de çalışır)
static func pop_in(c: Control, from_scale := 0.94, dur := 0.16) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2.ONE * from_scale
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	var tw = c.create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(c, "modulate:a", 1.0, dur)
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func vbox(sep := 8) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h
