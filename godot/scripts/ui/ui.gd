class_name UI
extends RefCounted
## Ortak arayüz stili ve küçük widget fabrikaları (Storm tarzı: koyu panel, turuncu vurgu).

const ACCENT := Color(0.96, 0.55, 0.16)
const PANEL := Color(0.07, 0.06, 0.08, 0.9)
const TEXT := Color(0.96, 0.94, 0.9)

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t = Theme.new()
	t.default_font_size = 18
	var sb = StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = ACCENT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	t.set_stylebox("panel", "PanelContainer", sb)
	t.set_stylebox("panel", "Panel", sb)
	var bn = StyleBoxFlat.new()
	bn.bg_color = Color(0.14, 0.12, 0.15, 0.95)
	bn.border_color = Color(0.35, 0.3, 0.3)
	bn.set_border_width_all(1)
	bn.set_corner_radius_all(4)
	bn.set_content_margin_all(8)
	var bh = bn.duplicate()
	bh.bg_color = Color(0.3, 0.17, 0.08, 0.95)
	bh.border_color = ACCENT
	var bp = bh.duplicate()
	bp.bg_color = ACCENT.darkened(0.3)
	var bd = bn.duplicate()
	bd.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	t.set_stylebox("normal", "Button", bn)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("focus", "Button", bh)
	t.set_stylebox("disabled", "Button", bd)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 0.9, 0.7))
	t.set_color("font_color", "Label", TEXT)
	var le = bn.duplicate()
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", bh)
	_theme = t
	return t


static func label(text: String, size := 18, col := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4 if size < 30 else 8)
	l.horizontal_alignment = align
	return l


static func button(text: String, cb: Callable, minw := 260) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minw, 40)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	b.mouse_entered.connect(func(): Sfx.play("click", null, 1.6, 0.3))
	return b


static func bar(col: Color, w := 340.0, h := 18.0) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.custom_minimum_size = Vector2(w, h)
	pb.show_percentage = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.05, 0.8)
	bg.border_color = Color(0, 0, 0, 0.9)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(3)
	var fg = StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(2)
	fg.border_color = col.lightened(0.35)
	fg.border_width_top = 2
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	return pb


static func panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.theme = theme()
	return p


static func vbox(sep := 8) -> VBoxContainer:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h
