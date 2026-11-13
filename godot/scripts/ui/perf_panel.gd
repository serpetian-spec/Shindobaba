extends Control
## Performans paneli (F3): anlık / ortalama / en düşük FPS, son 2 dakikanın ve tüm oturumun FPS grafiği,
## sahnedeki kişi / düğüm / bellek sayıları (açılıştan beri artışıyla: sızıntı buradan görülür) ve
## F4 ile "şunu kapatınca FPS kaç oluyor" denemesi. F5: ekran eşitlemesi (60 sınırı) aç / kapa.
## Gizliyken de toplar (oturum grafiği baştan dolsun); yalnız FPS ve sayı gösterir.

const TESTS := ["normal", "gölge kapalı", "kişiler gizli", "kişiler durdu", "bitki örtüsü gizli", "dış çizgi kapalı", "yarı çözünürlük"]

var sec_fps: Array = []      # son 120 sn, saniyelik ortalama
var min_fps: Array = []      # oturum, dakikalık ortalama
var min_nodes: Array = []    # oturum, dakikalık düğüm sayısı
var _n := 0
var _t := 0.0
var _mn := 0
var _mt := 0.0
var _all_n := 0
var _all_t := 0.0
var cur := 0.0
var base_nodes := -1
var base_mem := 0.0
var people_near := 0
var people_all := 0
var people_anim := 0
var test_i := 0
var test_fps := {}           # deneme adı -> ölçülen FPS
var _test_wait := 0.0
var _test_n := 0
var _test_t := 0.0
var _hidden: Array = []
var _stopped: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func toggle() -> void:
	visible = not visible
	if not visible:
		_apply_test(0)
		test_i = 0


func next_test() -> void:
	if not visible:
		return
	test_i = (test_i + 1) % TESTS.size()
	_apply_test(test_i)
	_test_wait = 1.5
	_test_n = 0
	_test_t = 0.0


func toggle_vsync() -> void:
	if not visible:
		return
	var on = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED if on else DisplayServer.VSYNC_ENABLED)
	test_fps.clear()


func _people() -> Array:
	var out := []
	for grp in ["fighters", "talkers"]:   # köylüler dövüşçü grubundan çıkar, konuşanlar grubundadır
		for f in get_tree().get_nodes_in_group(grp):
			if is_instance_valid(f) and f != Game.player and f is CharacterBody3D and not out.has(f):
				out.append(f)
	return out


func _apply_test(i: int) -> void:
	# önce her şeyi eski hâline getir
	var w = Game.world
	for n in _hidden:
		if is_instance_valid(n):
			n.visible = true
	_hidden.clear()
	for n in _stopped:
		if is_instance_valid(n):
			n.process_mode = Node.PROCESS_MODE_INHERIT
	_stopped.clear()
	get_viewport().scaling_3d_scale = 1.0
	if w == null or w.get("env") == null:
		return
	if w.env.sun:
		w.env.sun.shadow_enabled = bool(Game.settings.get("shadows", true))
	if w.env.post:
		w.env.post.visible = bool(Game.settings.get("outline", true))
	if w.vegetation:
		w.vegetation.visible = true
	match TESTS[i]:
		"gölge kapalı":
			w.env.sun.shadow_enabled = false
		"kişiler gizli":
			for f in _people():
				if f.visible:
					f.visible = false
					_hidden.append(f)
		"kişiler durdu":
			for f in _people():
				if f.process_mode != Node.PROCESS_MODE_DISABLED:
					f.process_mode = Node.PROCESS_MODE_DISABLED
					_stopped.append(f)
		"bitki örtüsü gizli":
			w.vegetation.visible = false
		"dış çizgi kapalı":
			w.env.post.visible = false
		"yarı çözünürlük":
			get_viewport().scaling_3d_scale = 0.5


func _process(dt: float) -> void:
	# gerçek kare süresi (oyun yavaşlatılmış / durmuş olsa da doğru)
	var rdt = dt / maxf(Engine.time_scale, 0.001)
	_n += 1
	_t += rdt
	_mn += 1
	_mt += rdt
	if Game.player != null:
		_all_n += 1
		_all_t += rdt
	if _test_wait > 0.0:
		_test_wait -= rdt
	elif visible:
		_test_n += 1
		_test_t += rdt
		if _test_t >= 1.0:
			test_fps[TESTS[test_i]] = _test_n / _test_t if not test_fps.has(TESTS[test_i]) else lerpf(float(test_fps[TESTS[test_i]]), _test_n / _test_t, 0.3)
			_test_n = 0
			_test_t = 0.0
	if _t >= 1.0:
		cur = _n / _t
		sec_fps.append(cur)
		if sec_fps.size() > 120:
			sec_fps.pop_front()
		_n = 0
		_t = 0.0
		if base_nodes < 0 and Game.player != null:
			base_nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			base_mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		if visible:
			_count_people()
			queue_redraw()
	if _mt >= 60.0:
		min_fps.append(_mn / _mt)
		min_nodes.append(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		if min_fps.size() > 240:
			min_fps.pop_front()
			min_nodes.pop_front()
		_mn = 0
		_mt = 0.0


func _count_people() -> void:
	people_near = 0
	people_all = 0
	people_anim = 0
	if Game.player == null:
		return
	var pp = Game.player.global_position
	for f in _people():
		people_all += 1
		if f.global_position.distance_squared_to(pp) < 70.0 * 70.0:
			people_near += 1
		var m = f.get("model")
		if m != null and is_instance_valid(m) and m.get("anim") != null and m.anim.is_playing() and m.anim.process_mode != Node.PROCESS_MODE_DISABLED:
			people_anim += 1


func _col(f: float) -> Color:
	return UI.GOOD if f >= 50.0 else (Color(1.0, 0.85, 0.35) if f >= 35.0 else UI.BAD)


func _txt(p: Vector2, s: String, size := 15, col := UI.TEXT, bold := false) -> void:
	draw_string(UI.font(bold), p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _graph(r: Rect2, data: Array, top: float, title: String, over: Array = []) -> void:
	draw_rect(r, Color(0, 0, 0, 0.35))
	for mark in [30.0, 60.0]:
		if mark <= top:
			var y = r.end.y - r.size.y * mark / top
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.16), 1.0)
			_txt(Vector2(r.end.x - 22, y - 3), "%d" % int(mark), 11, Color(1, 1, 1, 0.5))
	_txt(r.position + Vector2(6, 14), title, 12, Color(1, 1, 1, 0.6))
	if data.size() < 2:
		return
	# üstüne binen çizgi (düğüm sayısı): kendi en küçük-en büyüğüne göre, soluk mavi
	if over.size() == data.size():
		var lo = float(over.min())
		var hi = maxf(float(over.max()), lo + 1.0)
		var pts2 := PackedVector2Array()
		for i in over.size():
			pts2.append(Vector2(r.position.x + r.size.x * i / float(over.size() - 1), r.end.y - 4.0 - (r.size.y - 22.0) * (float(over[i]) - lo) / (hi - lo)))
		draw_polyline(pts2, Color(0.45, 0.7, 1.0, 0.75), 1.5, true)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in data.size():
		var f = float(data[i])
		pts.append(Vector2(r.position.x + r.size.x * i / float(data.size() - 1), r.end.y - r.size.y * clampf(f / top, 0.0, 1.0)))
		cols.append(_col(f))
	draw_polyline_colors(pts, cols, 2.0, true)


func _draw() -> void:
	var w = 470.0
	var x0 = 18.0
	var y0 = minf(176.0, get_viewport_rect().size.y - 648.0)
	draw_rect(Rect2(x0, y0, w, 640), UI.PANEL)
	draw_rect(Rect2(x0, y0, w, 640), Color(UI.ACCENT, 0.5), false, 1.5)
	var x = x0 + 16.0
	var y = y0 + 26.0
	_txt(Vector2(x, y), "PERFORMANS", 14, UI.ACCENT, true)
	_txt(Vector2(x0 + w - 186, y), "F3 kapat · F4 deneme · F5 sınır", 11, Color(1, 1, 1, 0.5))
	y += 50.0
	_txt(Vector2(x, y), "%d" % int(round(cur)), 46, _col(cur), true)
	_txt(Vector2(x + 96, y - 20), "FPS", 16, Color(1, 1, 1, 0.7), true)
	var lo = float(sec_fps.min()) if not sec_fps.is_empty() else 0.0
	var avg = 0.0
	for f in sec_fps:
		avg += float(f)
	avg = avg / maxf(sec_fps.size(), 1)
	_txt(Vector2(x + 150, y - 24), "son 2 dk ortalama  %d" % int(round(avg)), 14)
	_txt(Vector2(x + 150, y - 5), "son 2 dk en düşük  %d" % int(round(lo)), 14, _col(lo))
	y += 18.0
	var vs = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	_txt(Vector2(x, y), "oturum ortalaması %d FPS · süre %d dk · ekran sınırı %s" % [int(round(_all_n / maxf(_all_t, 0.001))), int(_all_t / 60.0),
		("%d (açık)" % int(DisplayServer.screen_get_refresh_rate())) if vs else "kapalı"], 12, Color(1, 1, 1, 0.65))
	y += 12.0
	_graph(Rect2(x, y, w - 32, 92), sec_fps, 120.0 if not vs else 75.0, "son 2 dakika")
	y += 100.0
	_graph(Rect2(x, y, w - 32, 92), min_fps, 120.0 if not vs else 75.0, "tüm oturum (dakikalık) · mavi: sahnedeki düğüm sayısı", min_nodes)
	y += 116.0
	_txt(Vector2(x, y), "SAHNE", 12, UI.ACCENT, true)
	y += 20.0
	var nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var rows = [
		["Kişi (70 m içinde / toplam)", "%d / %d" % [people_near, people_all], ""],
		["Animasyonu işleyen kişi", "%d" % people_anim, ""],
		["Düğüm", "%d" % nodes, "%+d" % (nodes - maxi(base_nodes, 0))],
		["Yetim düğüm", "%d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), ""],
		["Bellek", "%d MB" % int(mem), "%+d MB" % int(mem - base_mem)],
		["Ekran belleği", "%d MB" % int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0), ""],
		["Çizilen nesne", "%d" % int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)), ""],
		["Çizilen üçgen", "%.1f milyon" % (RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1e6), ""],
	]
	for rw in rows:
		_txt(Vector2(x, y), rw[0], 13, Color(1, 1, 1, 0.75))
		_txt(Vector2(x + 220, y), rw[1], 13)
		if rw[2] != "":
			_txt(Vector2(x + 310, y), rw[2] + "  (açılıştan beri)", 11, Color(0.45, 0.7, 1.0))
		y += 18.0
	y += 12.0
	_txt(Vector2(x, y), "DENEME (F4): şunu kapatınca FPS kaç oluyor", 12, UI.ACCENT, true)
	y += 20.0
	var base = float(test_fps.get("normal", 0.0))
	for i in TESTS.size():
		var name = TESTS[i]
		var on = i == test_i
		_txt(Vector2(x, y), ("▶ " if on else "   ") + name, 13, UI.TEXT if on else Color(1, 1, 1, 0.6), on)
		if test_fps.has(name):
			var f = float(test_fps[name])
			_txt(Vector2(x + 220, y), "%d FPS" % int(round(f)), 13, _col(f))
			if i > 0 and base > 0.0:
				_txt(Vector2(x + 310, y), "%+d" % int(round(f - base)), 13, UI.GOOD if f - base >= 3.0 else Color(1, 1, 1, 0.5))
		y += 18.0
