class_name Icons
extends RefCounted
## Prosedürel simge seti: tüm simgeler bir kez GPU'da beyaz olarak bir atlasa çizilir (SubViewport),
## sonra AtlasTexture olarak her yerde kullanılır (düğme simgesi, TextureRect). Renk: modulate / tema ile.

const CELL := 128
const COLS := 8
const KINDS := ["bag", "armor", "scroll", "star", "map", "mission", "book", "gear", "close", "shuriken",
	"kunai", "sword", "eye", "flame", "drop", "wind", "rock", "bolt", "chakra", "headband",
	"sandal", "pants", "shirt", "vest", "cloak", "glove", "back", "mask", "hair", "coin",
	"heart", "lock", "check", "plus", "play", "save", "exit", "home", "person", "skull",
	"potion", "pill", "bomb", "seal", "leaf", "target", "tree", "susanoo", "staff", "fan",
	"hand", "arrow", "info", "hourglass", "village", "chest", "settings", "controls", "sound", "monitor"]

static var _vp: SubViewport
static var _cache := {}


## Hud._ready içinden bir kez çağrılır (atlas sahneye eklenir)
static func ensure(parent: Node) -> void:
	if _vp != null:
		return
	_vp = SubViewport.new()
	var rows = int(ceil(float(KINDS.size()) / COLS))
	_vp.size = Vector2i(COLS * CELL, rows * CELL)
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_vp.msaa_2d = Viewport.MSAA_4X
	var c = Control.new()
	c.size = Vector2(_vp.size)
	c.draw.connect(func():
		for i in KINDS.size():
			var o = Vector2((i % COLS) * CELL, (i / COLS) * CELL)
			_draw_kind(c, KINDS[i], Rect2(o + Vector2(CELL, CELL) * 0.08, Vector2(CELL, CELL) * 0.84)))
	_vp.add_child(c)
	parent.add_child(_vp)


static func tex(kind: String, _px := 0, _col := Color.WHITE) -> Texture2D:
	if _cache.has(kind):
		return _cache[kind]
	var i = KINDS.find(kind)
	if i < 0 or _vp == null:
		i = maxi(0, KINDS.find("info"))
	var at = AtlasTexture.new()
	at.atlas = _vp.get_texture() if _vp else null
	at.region = Rect2((i % COLS) * CELL, (i / COLS) * CELL, CELL, CELL)
	_cache[kind] = at
	return at


## Boyutlandırılabilir simge kontrolü
static func view(kind: String, size := 24, col := Color.WHITE) -> TextureRect:
	var t = TextureRect.new()
	t.texture = tex(kind)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.size = Vector2(size, size)
	t.modulate = col
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


# ------------------------------------------------------------------ çizim (birim kare 0..1 → r)
static func _draw_kind(c: Control, k: String, r: Rect2) -> void:
	var W = Color.WHITE
	var P = func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var poly = func(pts: Array) -> void:
		var a = PackedVector2Array()
		for q in pts:
			a.append(P.call(q[0], q[1]))
		c.draw_colored_polygon(a, W)
	var circ = func(x: float, y: float, rad: float) -> void:
		c.draw_circle(P.call(x, y), rad * r.size.x, W, true, -1.0, true)
	var ring = func(x: float, y: float, rad: float, w: float) -> void:
		c.draw_arc(P.call(x, y), rad * r.size.x, 0, TAU, 48, W, w * r.size.x, true)
	var arc = func(x: float, y: float, rad: float, a0: float, a1: float, w: float) -> void:
		c.draw_arc(P.call(x, y), rad * r.size.x, a0, a1, 32, W, w * r.size.x, true)
	var line = func(x1: float, y1: float, x2: float, y2: float, w: float) -> void:
		c.draw_line(P.call(x1, y1), P.call(x2, y2), W, w * r.size.x, true)
		c.draw_circle(P.call(x1, y1), w * r.size.x * 0.5, W, true, -1.0, true)
		c.draw_circle(P.call(x2, y2), w * r.size.x * 0.5, W, true, -1.0, true)
	var rbox = func(x: float, y: float, w: float, h: float, rad: float) -> void:
		var sb = StyleBoxFlat.new()
		sb.bg_color = W
		sb.set_corner_radius_all(int(rad * r.size.x))
		sb.anti_aliasing = true
		c.draw_style_box(sb, Rect2(P.call(x, y), Vector2(w, h) * r.size))
	var hole = func(x: float, y: float, rad: float) -> void:
		# siyah değil: atlas saydam, delik yerine koyu nokta kullanmak yerine arka plan rengiyle çiz
		c.draw_circle(P.call(x, y), rad * r.size.x, Color(0, 0, 0, 0), true, -1.0, true)
	match k:
		"bag":
			rbox.call(0.16, 0.3, 0.68, 0.6, 0.12)
			arc.call(0.5, 0.32, 0.17, PI, TAU, 0.07)
			line.call(0.16, 0.5, 0.84, 0.5, 0.05)
		"armor", "shirt":
			poly.call([[0.3, 0.12], [0.42, 0.18], [0.58, 0.18], [0.7, 0.12], [0.95, 0.3], [0.82, 0.48], [0.74, 0.42], [0.74, 0.9], [0.26, 0.9], [0.26, 0.42], [0.18, 0.48], [0.05, 0.3]])
		"scroll":
			rbox.call(0.18, 0.28, 0.64, 0.44, 0.03)
			rbox.call(0.08, 0.2, 0.14, 0.6, 0.07)
			rbox.call(0.78, 0.2, 0.14, 0.6, 0.07)
		"star":
			var pts = []
			for i in 10:
				var a = -PI / 2 + i * PI / 5
				var rr = 0.45 if i % 2 == 0 else 0.19
				pts.append([0.5 + cos(a) * rr, 0.53 + sin(a) * rr])
			poly.call(pts)
		"map":
			poly.call([[0.08, 0.2], [0.36, 0.1], [0.64, 0.2], [0.92, 0.1], [0.92, 0.8], [0.64, 0.9], [0.36, 0.8], [0.08, 0.9]])
		"mission":
			rbox.call(0.22, 0.08, 0.56, 0.84, 0.05)
			ring.call(0.5, 0.66, 0.12, 0.05)
			line.call(0.34, 0.26, 0.66, 0.26, 0.05)
			line.call(0.34, 0.38, 0.6, 0.38, 0.05)
		"book":
			poly.call([[0.12, 0.18], [0.48, 0.24], [0.48, 0.9], [0.12, 0.84]])
			poly.call([[0.52, 0.24], [0.88, 0.18], [0.88, 0.84], [0.52, 0.9]])
		"gear", "settings":
			ring.call(0.5, 0.5, 0.24, 0.14)
			for i in 8:
				var a = i * TAU / 8
				line.call(0.5 + cos(a) * 0.3, 0.5 + sin(a) * 0.3, 0.5 + cos(a) * 0.42, 0.5 + sin(a) * 0.42, 0.13)
		"close":
			line.call(0.2, 0.2, 0.8, 0.8, 0.1)
			line.call(0.8, 0.2, 0.2, 0.8, 0.1)
		"shuriken":
			for i in 4:
				var a = i * PI / 2
				var d = Vector2(cos(a), sin(a)); var s = Vector2(-d.y, d.x)
				poly.call([[0.5 + s.x * 0.1, 0.5 + s.y * 0.1], [0.5 + d.x * 0.46, 0.5 + d.y * 0.46], [0.5 + d.x * 0.1 - s.x * 0.12, 0.5 + d.y * 0.1 - s.y * 0.12]])
			circ.call(0.5, 0.5, 0.14)
		"kunai":
			poly.call([[0.5, 0.04], [0.62, 0.42], [0.5, 0.52], [0.38, 0.42]])
			rbox.call(0.455, 0.5, 0.09, 0.28, 0.02)
			ring.call(0.5, 0.86, 0.08, 0.05)
		"sword":
			poly.call([[0.82, 0.08], [0.9, 0.16], [0.36, 0.7], [0.3, 0.64]])
			line.call(0.2, 0.56, 0.44, 0.8, 0.07)
			line.call(0.3, 0.7, 0.12, 0.88, 0.09)
		"eye":
			poly.call([[0.04, 0.5], [0.25, 0.28], [0.5, 0.22], [0.75, 0.28], [0.96, 0.5], [0.75, 0.72], [0.5, 0.78], [0.25, 0.72]])
			c.draw_circle(P.call(0.5, 0.5), 0.17 * r.size.x, Color(0, 0, 0, 1), true, -1.0, true)
			circ.call(0.5, 0.5, 0.08)
		"flame":
			poly.call([[0.5, 0.06], [0.68, 0.3], [0.78, 0.5], [0.76, 0.72], [0.62, 0.9], [0.38, 0.9], [0.24, 0.72], [0.24, 0.5], [0.36, 0.36], [0.42, 0.5], [0.46, 0.28]])
		"drop":
			poly.call([[0.5, 0.06], [0.7, 0.4], [0.76, 0.6], [0.7, 0.8], [0.5, 0.92], [0.3, 0.8], [0.24, 0.6], [0.3, 0.4]])
		"wind":
			arc.call(0.42, 0.34, 0.16, -PI, PI * 0.5, 0.07)
			line.call(0.08, 0.5, 0.42, 0.5, 0.07)
			arc.call(0.6, 0.62, 0.14, -PI * 0.5, PI, 0.07)
			line.call(0.08, 0.48, 0.6, 0.48, 0.07)
			line.call(0.08, 0.72, 0.5, 0.72, 0.07)
		"rock":
			poly.call([[0.1, 0.8], [0.22, 0.4], [0.42, 0.22], [0.62, 0.3], [0.8, 0.24], [0.92, 0.56], [0.86, 0.8]])
		"bolt":
			poly.call([[0.58, 0.04], [0.22, 0.56], [0.46, 0.56], [0.38, 0.96], [0.78, 0.42], [0.54, 0.42]])
		"chakra":
			arc.call(0.5, 0.5, 0.36, 0, PI * 1.5, 0.08)
			arc.call(0.5, 0.5, 0.2, PI, PI * 2.6, 0.08)
			circ.call(0.5, 0.5, 0.06)
		"headband":
			rbox.call(0.06, 0.38, 0.88, 0.24, 0.06)
			rbox.call(0.32, 0.32, 0.36, 0.36, 0.05)
			line.call(0.06, 0.5, 0.0, 0.8, 0.06)
		"sandal":
			poly.call([[0.1, 0.78], [0.16, 0.62], [0.88, 0.66], [0.94, 0.78], [0.88, 0.86], [0.14, 0.86]])
			line.call(0.3, 0.64, 0.42, 0.42, 0.07)
			line.call(0.42, 0.42, 0.6, 0.64, 0.07)
			line.call(0.2, 0.62, 0.2, 0.36, 0.07)
		"pants":
			poly.call([[0.22, 0.08], [0.78, 0.08], [0.86, 0.92], [0.6, 0.92], [0.5, 0.38], [0.4, 0.92], [0.14, 0.92]])
		"vest":
			poly.call([[0.22, 0.1], [0.4, 0.1], [0.5, 0.3], [0.6, 0.1], [0.78, 0.1], [0.86, 0.3], [0.82, 0.92], [0.18, 0.92], [0.14, 0.3]])
			rbox.call(0.24, 0.5, 0.18, 0.16, 0.03)
			rbox.call(0.58, 0.5, 0.18, 0.16, 0.03)
		"cloak":
			poly.call([[0.42, 0.06], [0.58, 0.06], [0.66, 0.18], [0.92, 0.92], [0.08, 0.92], [0.34, 0.18]])
		"glove":
			poly.call([[0.26, 0.92], [0.24, 0.5], [0.3, 0.2], [0.4, 0.2], [0.42, 0.42], [0.46, 0.12], [0.56, 0.12], [0.58, 0.42], [0.62, 0.18], [0.72, 0.2], [0.72, 0.5], [0.82, 0.4], [0.88, 0.48], [0.72, 0.72], [0.7, 0.92]])
		"back":
			rbox.call(0.2, 0.18, 0.6, 0.72, 0.14)
			rbox.call(0.3, 0.52, 0.4, 0.24, 0.05)
			arc.call(0.5, 0.2, 0.14, PI, TAU, 0.06)
		"mask":
			poly.call([[0.14, 0.2], [0.86, 0.2], [0.86, 0.5], [0.72, 0.82], [0.5, 0.9], [0.28, 0.82], [0.14, 0.5]])
			c.draw_circle(P.call(0.34, 0.42), 0.08 * r.size.x, Color(0, 0, 0, 1), true, -1.0, true)
			c.draw_circle(P.call(0.66, 0.42), 0.08 * r.size.x, Color(0, 0, 0, 1), true, -1.0, true)
		"hair":
			poly.call([[0.12, 0.72], [0.14, 0.4], [0.06, 0.2], [0.3, 0.26], [0.36, 0.04], [0.5, 0.22], [0.66, 0.04], [0.7, 0.26], [0.94, 0.2], [0.86, 0.4], [0.88, 0.72], [0.7, 0.5], [0.3, 0.5]])
		"coin":
			ring.call(0.5, 0.5, 0.36, 0.12)
			rbox.call(0.42, 0.42, 0.16, 0.16, 0.02)
		"heart":
			circ.call(0.33, 0.38, 0.19)
			circ.call(0.67, 0.38, 0.19)
			poly.call([[0.15, 0.46], [0.85, 0.46], [0.5, 0.88]])
		"lock":
			rbox.call(0.2, 0.44, 0.6, 0.46, 0.08)
			arc.call(0.5, 0.44, 0.2, PI, TAU, 0.08)
		"check":
			line.call(0.16, 0.52, 0.4, 0.76, 0.11)
			line.call(0.4, 0.76, 0.86, 0.24, 0.11)
		"plus":
			line.call(0.5, 0.16, 0.5, 0.84, 0.12)
			line.call(0.16, 0.5, 0.84, 0.5, 0.12)
		"play":
			poly.call([[0.26, 0.12], [0.86, 0.5], [0.26, 0.88]])
		"save":
			rbox.call(0.12, 0.12, 0.76, 0.76, 0.06)
			c.draw_rect(Rect2(P.call(0.28, 0.12), Vector2(0.44, 0.26) * r.size), Color(0, 0, 0, 1))
			c.draw_rect(Rect2(P.call(0.26, 0.56), Vector2(0.48, 0.32) * r.size), Color(0, 0, 0, 1))
		"exit":
			rbox.call(0.14, 0.1, 0.44, 0.8, 0.04)
			line.call(0.5, 0.5, 0.9, 0.5, 0.09)
			line.call(0.76, 0.34, 0.9, 0.5, 0.09)
			line.call(0.76, 0.66, 0.9, 0.5, 0.09)
		"home", "village":
			poly.call([[0.5, 0.08], [0.94, 0.46], [0.82, 0.46], [0.82, 0.9], [0.18, 0.9], [0.18, 0.46], [0.06, 0.46]])
		"person":
			circ.call(0.5, 0.28, 0.18)
			poly.call([[0.16, 0.92], [0.22, 0.6], [0.36, 0.5], [0.64, 0.5], [0.78, 0.6], [0.84, 0.92]])
		"skull":
			circ.call(0.5, 0.42, 0.34)
			rbox.call(0.32, 0.6, 0.36, 0.28, 0.06)
			c.draw_circle(P.call(0.37, 0.44), 0.09 * r.size.x, Color(0, 0, 0, 1), true, -1.0, true)
			c.draw_circle(P.call(0.63, 0.44), 0.09 * r.size.x, Color(0, 0, 0, 1), true, -1.0, true)
		"potion":
			rbox.call(0.4, 0.06, 0.2, 0.2, 0.03)
			circ.call(0.5, 0.62, 0.3)
			rbox.call(0.42, 0.2, 0.16, 0.2, 0.02)
		"pill":
			c.draw_set_transform(P.call(0.5, 0.5), -0.7, Vector2.ONE)
			var sb = StyleBoxFlat.new()
			sb.bg_color = W
			sb.set_corner_radius_all(int(0.17 * r.size.x))
			c.draw_style_box(sb, Rect2(Vector2(-0.4, -0.17) * r.size, Vector2(0.8, 0.34) * r.size))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bomb":
			circ.call(0.46, 0.58, 0.32)
			line.call(0.64, 0.32, 0.78, 0.14, 0.06)
			circ.call(0.82, 0.1, 0.07)
		"seal":
			ring.call(0.5, 0.5, 0.36, 0.08)
			line.call(0.5, 0.2, 0.5, 0.8, 0.07)
			line.call(0.26, 0.42, 0.74, 0.42, 0.07)
			line.call(0.3, 0.64, 0.7, 0.64, 0.07)
		"leaf":
			poly.call([[0.5, 0.06], [0.76, 0.3], [0.8, 0.56], [0.62, 0.8], [0.5, 0.92], [0.38, 0.8], [0.2, 0.56], [0.24, 0.3]])
			c.draw_line(P.call(0.5, 0.2), P.call(0.5, 0.86), Color(0, 0, 0, 1), 0.04 * r.size.x, true)
		"target":
			ring.call(0.5, 0.5, 0.38, 0.07)
			ring.call(0.5, 0.5, 0.2, 0.07)
			circ.call(0.5, 0.5, 0.06)
		"tree":
			for q in [[0.5, 0.18], [0.3, 0.34], [0.7, 0.34], [0.5, 0.4]]:
				circ.call(q[0], q[1], 0.2)
			rbox.call(0.44, 0.5, 0.12, 0.42, 0.03)
		"susanoo":
			circ.call(0.5, 0.2, 0.13)
			poly.call([[0.1, 0.92], [0.18, 0.44], [0.34, 0.34], [0.66, 0.34], [0.82, 0.44], [0.9, 0.92]])
			line.call(0.82, 0.44, 0.96, 0.08, 0.06)
		"staff":
			line.call(0.18, 0.86, 0.82, 0.14, 0.08)
			circ.call(0.82, 0.14, 0.08)
		"fan":
			var fp = [[0.5, 0.86]]
			for i in 9:
				var a = PI * 1.15 + i * (PI * 0.7 / 8)
				fp.append([0.5 + cos(a) * 0.46, 0.86 + sin(a) * 0.46 * 1.4])
			poly.call(fp)
		"hand":
			poly.call([[0.3, 0.92], [0.26, 0.48], [0.3, 0.16], [0.4, 0.16], [0.42, 0.44], [0.46, 0.08], [0.56, 0.08], [0.58, 0.44], [0.62, 0.14], [0.72, 0.16], [0.7, 0.52], [0.82, 0.36], [0.9, 0.44], [0.72, 0.76], [0.68, 0.92]])
		"arrow":
			line.call(0.14, 0.5, 0.78, 0.5, 0.1)
			poly.call([[0.92, 0.5], [0.6, 0.24], [0.6, 0.76]])
		"info":
			ring.call(0.5, 0.5, 0.38, 0.08)
			circ.call(0.5, 0.3, 0.06)
			rbox.call(0.45, 0.42, 0.1, 0.32, 0.03)
		"hourglass":
			poly.call([[0.22, 0.1], [0.78, 0.1], [0.52, 0.5], [0.78, 0.9], [0.22, 0.9], [0.48, 0.5]])
		"chest":
			rbox.call(0.1, 0.36, 0.8, 0.52, 0.06)
			poly.call([[0.1, 0.36], [0.2, 0.16], [0.8, 0.16], [0.9, 0.36]])
			c.draw_rect(Rect2(P.call(0.44, 0.4), Vector2(0.12, 0.16) * r.size), Color(0, 0, 0, 1))
		"controls":
			rbox.call(0.08, 0.3, 0.84, 0.44, 0.2)
			c.draw_circle(P.call(0.3, 0.52), 0.07 * r.size.x, Color(0, 0, 0, 1))
			c.draw_circle(P.call(0.66, 0.46), 0.05 * r.size.x, Color(0, 0, 0, 1))
			c.draw_circle(P.call(0.76, 0.58), 0.05 * r.size.x, Color(0, 0, 0, 1))
		"sound":
			poly.call([[0.1, 0.38], [0.3, 0.38], [0.52, 0.16], [0.52, 0.84], [0.3, 0.62], [0.1, 0.62]])
			arc.call(0.52, 0.5, 0.2, -0.9, 0.9, 0.06)
			arc.call(0.52, 0.5, 0.34, -0.9, 0.9, 0.06)
		"monitor":
			rbox.call(0.08, 0.14, 0.84, 0.56, 0.06)
			rbox.call(0.36, 0.76, 0.28, 0.08, 0.02)
		_:
			circ.call(0.5, 0.5, 0.3)
