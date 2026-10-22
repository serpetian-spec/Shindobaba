extends CanvasLayer
## Oyun içi arayüz (autoload "Hud"): barlar, slotlar, mini harita, mesajlar, banner'lar, diyaloglar, dükkân.

var root: Control
var hp_bar: ProgressBar
var hp_trail: ProgressBar
var ck_bar: ProgressBar
var xp_bar: ProgressBar
var name_lbl: Label
var sub_pips: Array[Panel] = []
var slots_box: HBoxContainer
var slot_nodes: Array = []
var tool_lbl: Label
var msg_lbl: Label
var msg_t = 0.0
var prompt_lbl: Label
var region_lbl: Label
var region_name = ""
var objective_lbl: Label
var obj_progress_lbl: Label
var banner_box: Control
var seal_box: HBoxContainer
var boss: Node = null
var boss_box: VBoxContainer
var boss_bar_pb: ProgressBar
var boss_lbl: Label
var lock_ret: Control
var minimap: Control
var vignette: ColorRect
var fps_lbl: Label
var dialog_layer: Control
var game_hud: Control
var map_tex: Texture2D
var compass: Control
var compass_lbl: Label
var compass_dir = Vector2.UP
var beam: MeshInstance3D
const SLOT_COUNT := 6
var slot_state: Array = []
var portrait: Control
var portrait_hp = 1.0
var rank_lbl: Label
var ryo_lbl: Label
var hp_txt: Label
var ck_txt: Label
var tool_box: PanelContainer
var item_box: PanelContainer
var item_lbl: Label
var prompt_box: PanelContainer
var prompt_key: PanelContainer
var mm_region: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	add_child(root)
	game_hud = Control.new()
	game_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_hud.visible = false
	root.add_child(game_hud)
	map_tex = load("res://data/world/map.png")
	_build_vitals()
	_build_slots()
	_build_texts()
	_build_minimap()
	_build_boss()
	_build_compass()
	dialog_layer = Control.new()
	dialog_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dialog_layer)


func show_game_hud(on: bool) -> void:
	game_hud.visible = on
	if beam and is_instance_valid(beam) and not on:
		beam.visible = false


# ------------------------------------------------------------------ yapım
func _build_vitals() -> void:
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = ShaderMaterial.new()
	var sh = Shader.new()
	sh.code = "shader_type canvas_item; uniform float amount = 0.0; void fragment(){ vec2 q = UV - 0.5; float v = smoothstep(0.25, 0.75, length(q)); COLOR = vec4(0.6, 0.0, 0.0, v * amount); }"
	sm.shader = sh
	vignette.material = sm
	game_hud.add_child(vignette)
	# --- oyuncu çerçevesi (sol üst): portre + isim + barlar
	var frame = Control.new()
	frame.position = Vector2(18, 14)
	frame.size = Vector2(500, 130)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_hud.add_child(frame)
	# arka eğik mürekkep şeridi
	var strip = Panel.new()
	strip.position = Vector2(44, 10)
	strip.size = Vector2(440, 104)
	var ssb = UI._box(Color(0.04, 0.03, 0.04, 0.62), Color(0, 0, 0, 0), 0, 3, 0, 0.28)
	ssb.border_width_bottom = 3
	ssb.border_color = UI.ACCENT
	strip.add_theme_stylebox_override("panel", ssb)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(strip)
	portrait = Control.new()
	portrait.position = Vector2(0, 8)
	portrait.size = Vector2(108, 108)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.draw.connect(_draw_portrait)
	frame.add_child(portrait)
	name_lbl = UI.label("", 22, UI.CREAM)
	name_lbl.position = Vector2(118, 10)
	frame.add_child(name_lbl)
	rank_lbl = UI.label("", 14, UI.ACCENT)
	rank_lbl.position = Vector2(120, 38)
	frame.add_child(rank_lbl)
	var hp_stack = Control.new()
	hp_stack.position = Vector2(116, 60)
	hp_stack.size = Vector2(340, 20)
	hp_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(hp_stack)
	hp_trail = UI.bar(Color(1, 0.88, 0.55), 340, 20)
	hp_stack.add_child(hp_trail)
	hp_bar = UI.bar(Color(0.35, 0.9, 0.35), 340, 20)
	hp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	hp_stack.add_child(hp_bar)
	hp_txt = UI.label("", 13, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_RIGHT)
	hp_txt.position = Vector2(116, 61)
	hp_txt.size = Vector2(330, 18)
	frame.add_child(hp_txt)
	ck_bar = UI.bar(Color(0.25, 0.6, 1.0), 300, 13)
	ck_bar.position = Vector2(110, 85)
	frame.add_child(ck_bar)
	ck_txt = UI.label("", 11, Color(0.85, 0.93, 1), HORIZONTAL_ALIGNMENT_RIGHT)
	ck_txt.position = Vector2(110, 83)
	ck_txt.size = Vector2(292, 14)
	frame.add_child(ck_txt)
	xp_bar = UI.bar(Color(0.98, 0.8, 0.3), 280, 5, 0.6)
	xp_bar.position = Vector2(104, 104)
	frame.add_child(xp_bar)
	# kawarimi elmasları
	var row = UI.hbox(5)
	row.position = Vector2(394, 102)
	frame.add_child(row)
	for i in 4:
		var p = Panel.new()
		p.custom_minimum_size = Vector2(14, 10)
		p.add_theme_stylebox_override("panel", UI._box(Color(0.45, 0.95, 0.55), Color(0, 0, 0, 0.9), 1, 1, 0, 0.6))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(p)
		sub_pips.append(p)
	ryo_lbl = UI.label("", 15, Color(1, 0.86, 0.4))
	ryo_lbl.position = Vector2(26, 124)
	frame.add_child(ryo_lbl)
	fps_lbl = UI.label("", 13, Color(0.7, 0.9, 0.7))
	fps_lbl.position = Vector2(20, 154)
	game_hud.add_child(fps_lbl)


## Portre: element renkli halka içinde köy sembolü ve ismin baş harfi
func _draw_portrait() -> void:
	var c = Vector2(54, 54)
	var pr = Game.profile
	var el: String = pr.get("elements", [""])[0] if not pr.is_empty() else ""
	var ec: Color = UI.ELEMENT_COLORS.get(el, UI.ACCENT)
	portrait.draw_circle(c + Vector2(3, 4), 52, Color(0, 0, 0, 0.45))
	portrait.draw_circle(c, 52, UI.INK)
	portrait.draw_circle(c, 46, Color(0.16, 0.12, 0.12))
	portrait.draw_circle(c, 40, ec.darkened(0.55))
	portrait.draw_arc(c, 50, 0, TAU, 48, UI.ACCENT, 4.0, true)
	portrait.draw_arc(c, 44, -PI * 0.5, -PI * 0.5 + TAU * portrait_hp, 48, Color(0.4, 0.95, 0.45), 4.0, true)
	var nm: String = String(pr.get("name", "?")) if not pr.is_empty() else "?"
	var ch = nm.substr(0, 1).to_upper()
	var f = ThemeDB.fallback_font
	var fs = 50
	var w = f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	portrait.draw_string_outline(f, c + Vector2(-w * 0.5, 18), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.9))
	portrait.draw_string(f, c + Vector2(-w * 0.5, 18), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.CREAM)
	# rütbe şeridi
	var rk = int(pr.get("rank", 0)) if not pr.is_empty() else 0
	for i in rk + 1:
		portrait.draw_circle(c + Vector2(-18 + i * 9, 40), 3.5, UI.ACCENT)


func _build_slots() -> void:
	slots_box = UI.hbox(8)
	slots_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slots_box.position = Vector2(-327, -112)
	game_hud.add_child(slots_box)
	for i in SLOT_COUNT:
		var p = Control.new()
		p.custom_minimum_size = Vector2(102, 96)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.draw.connect(_draw_slot.bind(i))
		var nm = UI.label("—", 12, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.position = Vector2(4, 26)
		nm.size = Vector2(94, 44)
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(nm)
		var cd = UI.label("", 13, Color(0.7, 0.85, 1), HORIZONTAL_ALIGNMENT_CENTER)
		cd.position = Vector2(4, 70)
		cd.size = Vector2(94, 20)
		p.add_child(cd)
		slots_box.add_child(p)
		slot_nodes.append([p, nm, cd])
		slot_state.append({"el": "", "cd": 0.0, "max": 1.0, "ok": true, "empty": true})
	# sol: atılabilir alet kutusu, sağ: eşya kutusu
	tool_box = _side_box(Vector2(-327 - 214, -100))
	tool_lbl = UI.label("", 15, UI.TEXT)
	tool_box.get_child(0).add_child(tool_lbl)
	item_box = _side_box(Vector2(327 + 14, -100))
	item_lbl = UI.label("", 15, UI.TEXT)
	item_box.get_child(0).add_child(item_lbl)
	seal_box = UI.hbox(6)
	seal_box.set_anchors_preset(Control.PRESET_CENTER)
	seal_box.position = Vector2(-150, 120)
	game_hud.add_child(seal_box)


func _side_box(pos: Vector2) -> PanelContainer:
	var p = PanelContainer.new()
	var sb = UI._box(Color(0.05, 0.04, 0.05, 0.78), UI.ACCENT, 0, 3, 8, 0.2)
	sb.border_width_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.position = pos
	p.custom_minimum_size = Vector2(200, 76)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v = UI.vbox(2)
	p.add_child(v)
	game_hud.add_child(p)
	return p


## Jutsu slotu: eğik kart, üstte element şeridi, sol üstte tuş rozeti, bekleme süresi için saat yönünde karartma
func _draw_slot(i: int) -> void:
	var p: Control = slot_nodes[i][0]
	var st: Dictionary = slot_state[i]
	var sz = p.size
	var ec: Color = UI.ELEMENT_COLORS.get(st["el"], UI.ELEMENT_COLORS[""])
	var sk = 10.0
	var poly = PackedVector2Array([Vector2(sk, 0), Vector2(sz.x, 0), Vector2(sz.x - sk, sz.y), Vector2(0, sz.y)])
	p.draw_colored_polygon(PackedVector2Array([Vector2(sk + 3, 4), Vector2(sz.x + 3, 4), Vector2(sz.x - sk + 3, sz.y + 4), Vector2(3, sz.y + 4)]), Color(0, 0, 0, 0.45))
	p.draw_colored_polygon(poly, Color(0.07, 0.055, 0.065, 0.9) if not st["empty"] else Color(0.05, 0.04, 0.05, 0.6))
	if not st["empty"]:
		p.draw_colored_polygon(PackedVector2Array([Vector2(sk, 0), Vector2(sz.x, 0), Vector2(sz.x - 1.2, 7), Vector2(sk - 1.2, 7)]), ec)
		p.draw_colored_polygon(PackedVector2Array([Vector2(sk * 0.5, sz.y * 0.5), Vector2(sz.x - sk * 0.5, sz.y * 0.5), Vector2(sz.x - sk, sz.y), Vector2(0, sz.y)]), Color(ec, 0.12))
	# bekleme süresi süpürmesi
	if st["cd"] > 0.0:
		# kalan süre kadar karttan aşağı doğru inen karartma (eğik kartın içinde kalır)
		var k = clampf(st["cd"] / maxf(0.01, st["max"]), 0.0, 1.0)
		var y = sz.y * k
		var xl = sk * (1.0 - y / sz.y)
		var xr = sz.x - sk * (y / sz.y)
		p.draw_colored_polygon(PackedVector2Array([Vector2(sk, 0), Vector2(sz.x, 0), Vector2(xr, y), Vector2(xl, y)]), Color(0, 0, 0, 0.62))
		p.draw_line(Vector2(xl, y), Vector2(xr, y), Color(UI.ACCENT, 0.9), 2.0)
	elif not st["ok"] and not st["empty"]:
		p.draw_colored_polygon(poly, Color(0.05, 0.08, 0.25, 0.45))
	var bc = UI.ACCENT if not st["empty"] else Color(0.35, 0.3, 0.28)
	p.draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), bc, 2.0, true)
	# tuş rozeti
	var kb = Rect2(Vector2(-4, -8), Vector2(24, 22))
	p.draw_rect(kb, UI.CREAM)
	p.draw_rect(kb, UI.INK, false, 2.0)
	p.draw_string(ThemeDB.fallback_font, Vector2(3, 9), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UI.INK)


func _build_texts() -> void:
	msg_lbl = UI.label("", 22, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	msg_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	msg_lbl.position = Vector2(-500, -210)
	msg_lbl.size = Vector2(1000, 30)
	game_hud.add_child(msg_lbl)
	# etkileşim ipucu: tuş rozeti + metin, mürekkep hap
	prompt_box = PanelContainer.new()
	var psb = UI._box(Color(0.05, 0.04, 0.05, 0.82), UI.ACCENT, 0, 14, 6, 0.0)
	psb.border_width_bottom = 2
	psb.content_margin_left = 10; psb.content_margin_right = 16
	prompt_box.add_theme_stylebox_override("panel", psb)
	prompt_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ph = UI.hbox(10)
	prompt_box.add_child(ph)
	prompt_key = UI.key_badge("F", 16)
	ph.add_child(prompt_key)
	prompt_lbl = UI.label("", 19, Color(1, 0.9, 0.6))
	ph.add_child(prompt_lbl)
	prompt_box.visible = false
	game_hud.add_child(prompt_box)
	region_lbl = UI.label("", 40, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	region_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	region_lbl.position = Vector2(-400, 122)
	region_lbl.size = Vector2(800, 60)
	region_lbl.modulate.a = 0.0
	game_hud.add_child(region_lbl)
	# görev paneli (sağda, minimap altında)
	var obj = PanelContainer.new()
	var osb = UI._box(Color(0.05, 0.04, 0.05, 0.72), UI.ACCENT, 0, 3, 12)
	osb.border_width_left = 4
	obj.add_theme_stylebox_override("panel", osb)
	obj.anchor_left = 1.0; obj.anchor_right = 1.0
	obj.offset_left = -392; obj.offset_right = -18; obj.offset_top = 312
	obj.custom_minimum_size = Vector2(374, 0)
	obj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ov = UI.vbox(4)
	obj.add_child(ov)
	ov.add_child(UI.label("◆ GÖREV", 15, UI.ACCENT))
	objective_lbl = UI.label("", 15)
	objective_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_lbl.custom_minimum_size = Vector2(346, 0)
	ov.add_child(objective_lbl)
	obj_progress_lbl = UI.label("", 14, UI.GOOD)
	obj_progress_lbl.visible = false
	ov.add_child(obj_progress_lbl)
	game_hud.add_child(obj)
	banner_box = Control.new()
	banner_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_hud.add_child(banner_box)
	lock_ret = Control.new()
	lock_ret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_ret.draw.connect(func():
		var c = Color(1, 0.35, 0.25)
		lock_ret.draw_arc(Vector2.ZERO, 22, 0, TAU, 32, c, 3.0)
		for k in 4:
			var a = k * PI * 0.5 + Time.get_ticks_msec() * 0.003
			lock_ret.draw_line(Vector2(cos(a), sin(a)) * 16, Vector2(cos(a), sin(a)) * 30, c, 3.0))
	game_hud.add_child(lock_ret)


func _build_minimap() -> void:
	minimap = Control.new()
	minimap.anchor_left = 1.0; minimap.anchor_right = 1.0
	minimap.offset_left = -270; minimap.offset_right = -30; minimap.offset_top = 20; minimap.offset_bottom = 260
	minimap.custom_minimum_size = Vector2(240, 240)
	minimap.size = Vector2(240, 240)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# çerçeve gölgesi + mürekkep halkası
	var ring = Control.new()
	ring.size = Vector2(240, 240)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(func():
		ring.draw_circle(Vector2(124, 125), 126, Color(0, 0, 0, 0.45))
		ring.draw_circle(Vector2(120, 120), 126, UI.INK))
	minimap.add_child(ring)
	var tr = TextureRect.new()
	tr.texture = map_tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(240, 240)
	tr.size = Vector2(240, 240)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = ShaderMaterial.new()
	var sh = Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2 center; uniform float zoom; uniform float rot;
void fragment(){
	vec2 q = UV - 0.5;
	if (length(q) > 0.5) discard;
	float c = cos(rot), s = sin(rot);
	vec2 r = vec2(q.x * c - q.y * s, q.x * s + q.y * c);
	vec2 uv = center + r * zoom;
	vec4 col = texture(TEXTURE, uv);
	col.rgb = mix(col.rgb, col.rgb * vec3(1.05, 1.0, 0.9), 0.5);
	float vig = smoothstep(0.3, 0.5, length(q));
	col.rgb *= 1.0 - vig * 0.35;
	float edge = smoothstep(0.465, 0.48, length(q)) - smoothstep(0.49, 0.5, length(q));
	COLOR = mix(col, vec4(0.98, 0.55, 0.12, 1.0), edge);
}"""
	sm.shader = sh
	tr.material = sm
	minimap.add_child(tr)
	minimap.set_meta("mat", sm)
	var over = Control.new()
	over.size = Vector2(240, 240)
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.draw.connect(_draw_minimap_markers.bind(over))
	minimap.add_child(over)
	minimap.set_meta("over", over)
	# bölge adı şeridi (haritanın altında)
	var rp = PanelContainer.new()
	var rsb = UI._box(Color(0.05, 0.04, 0.05, 0.82), UI.ACCENT, 0, 3, 5, 0.25)
	rsb.border_width_bottom = 2
	rsb.content_margin_left = 14; rsb.content_margin_right = 14
	rp.add_theme_stylebox_override("panel", rsb)
	rp.position = Vector2(10, 236)
	rp.custom_minimum_size = Vector2(220, 0)
	rp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm_region = UI.label("", 15, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	mm_region.clip_text = true
	rp.add_child(mm_region)
	minimap.add_child(rp)
	game_hud.add_child(minimap)


# ------------------------------------------------------------------ hedef oku (pusula) + dünyadaki ışık sütunu
func _build_compass() -> void:
	compass = Control.new()
	compass.set_anchors_preset(Control.PRESET_CENTER_TOP)
	compass.position = Vector2(-170, 14)
	compass.size = Vector2(340, 96)
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass.draw.connect(_draw_compass)
	game_hud.add_child(compass)
	compass_lbl = UI.label("", 18, Color(1, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER)
	compass_lbl.position = Vector2(0, 62)
	compass_lbl.size = Vector2(340, 28)
	compass.add_child(compass_lbl)


func _draw_compass() -> void:
	var c = Vector2(170, 32)
	compass.draw_circle(c, 29, Color(0.05, 0.04, 0.06, 0.6))
	compass.draw_arc(c, 29, 0, TAU, 40, Color(0.96, 0.55, 0.16, 0.9), 2.5)
	var d = compass_dir.normalized()
	var side = Vector2(-d.y, d.x)
	var tip = c + d * 24
	var back = c - d * 14
	var pts = PackedVector2Array([tip, back + side * 13, c - d * 6, back - side * 13])
	compass.draw_colored_polygon(pts, Color(1, 0.8, 0.2))
	compass.draw_polyline(PackedVector2Array([tip, back + side * 13, c - d * 6, back - side * 13, tip]), Color(0.25, 0.1, 0.0), 2.0)


## Hedefin kameraya göre ekrandaki yönü (yukarı = kameranın baktığı yön); minimap ile aynı dönüşüm
func _target_screen_dir(pl: Node3D, wp: Vector3) -> Vector2:
	var d = Vector2(wp.x - pl.global_position.x, wp.z - pl.global_position.z)
	return d.rotated(deg_to_rad(pl.yaw))


func _update_objective_pointer(pl: Node3D) -> void:
	var on = Missions.has_marker and not Game.paused
	compass.visible = on
	if on:
		var wp: Vector3 = Missions.target_marker
		compass_dir = _target_screen_dir(pl, wp)
		var dist = Vector2(wp.x - pl.global_position.x, wp.z - pl.global_position.z).length()
		var nm: String = Missions.target_name if Missions.target_name != "" else "Hedef"
		compass_lbl.text = "%s — %d m" % [nm, int(dist)] if dist > 6.0 else "%s — buradasın" % nm
		compass.position.y = 84.0 if boss_box.visible else 14.0
		compass.queue_redraw()
	# dünyadaki ışık sütunu
	if beam == null or not is_instance_valid(beam):
		if not Missions.has_marker or pl.get_parent() == null:
			return
		beam = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 1.6
		cm.bottom_radius = 1.6
		cm.height = 260.0
		cm.radial_segments = 16
		cm.rings = 1
		cm.cap_top = false
		cm.cap_bottom = false
		beam.mesh = cm
		var sm = ShaderMaterial.new()
		sm.shader = load("res://shaders/beam.gdshader")
		beam.material_override = sm
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pl.get_parent().add_child(beam)
	beam.visible = Missions.has_marker
	if beam.visible:
		var tp: Vector3 = Missions.target_marker
		beam.global_position = Vector3(tp.x, Game.terrain_height(tp.x, tp.z) + 130.0, tp.z)
		var dist = Vector2(tp.x - pl.global_position.x, tp.z - pl.global_position.z).length()
		(beam.material_override as ShaderMaterial).set_shader_parameter("fade", clampf((dist - 8.0) / 14.0, 0.0, 1.0))


func _build_boss() -> void:
	boss_box = UI.vbox(3)
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.position = Vector2(-310, 22)
	boss_lbl = UI.label("", 22, Color(1, 0.62, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
	boss_lbl.custom_minimum_size = Vector2(620, 0)
	boss_bar_pb = UI.bar(Color(0.9, 0.16, 0.2), 620, 20)
	boss_box.add_child(boss_lbl)
	boss_box.add_child(boss_bar_pb)
	boss_box.visible = false
	game_hud.add_child(boss_box)


# ------------------------------------------------------------------ API
func msg(text: String, col := Color(1, 1, 1), dur := 3.5) -> void:
	msg_lbl.text = text
	msg_lbl.modulate = col
	msg_t = dur


func float_text(text: String, col: Color) -> void:
	var l = UI.label(text, 24, col, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_constant_override("outline_size", 8)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.position = Vector2(120 + randf_range(-30, 30), -40 + randf_range(-20, 20))
	l.pivot_offset = Vector2(40, 15)
	l.scale = Vector2.ONE * 1.6
	game_hud.add_child(l)
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 70, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(l.queue_free)


## Storm tarzı büyük fırça banner'ı
func banner(title: String, sub: String, col: Color) -> void:
	for c in banner_box.get_children():
		c.queue_free()
	var strip = Panel.new()
	var ssb = UI._box(Color(0.03, 0.02, 0.03, 0.72), col, 0, 0, 0, 0.0)
	ssb.border_width_top = 4
	ssb.border_width_bottom = 4
	strip.add_theme_stylebox_override("panel", ssb)
	strip.set_anchors_preset(Control.PRESET_CENTER)
	strip.position = Vector2(-2000, -70)
	strip.size = Vector2(4000, 120)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.add_child(strip)
	var brush = Panel.new()
	brush.add_theme_stylebox_override("panel", UI._box(Color(col, 0.22), Color(0, 0, 0, 0), 0, 0, 0, 0.5))
	brush.position = Vector2(1640, 10)
	brush.size = Vector2(720, 100)
	brush.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(brush)
	var t = UI.label(title, 54, col, HORIZONTAL_ALIGNMENT_CENTER)
	t.size = Vector2(4000, 70)
	t.position = Vector2(0, 4)
	strip.add_child(t)
	var s = UI.label(sub, 20, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	s.size = Vector2(4000, 30)
	s.position = Vector2(0, 76)
	strip.add_child(s)
	strip.scale = Vector2(1, 0.0)
	strip.pivot_offset = Vector2(2000, 60)
	var tw = strip.create_tween()
	tw.tween_property(strip, "scale:y", 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tw2 = brush.create_tween()
	tw2.tween_property(brush, "position:x", 1560.0, 3.0)
	tw.tween_interval(2.4)
	tw.tween_property(strip, "modulate:a", 0.0, 0.5)
	tw.tween_callback(strip.queue_free)


func show_seals(seals: Array) -> void:
	for c in seal_box.get_children():
		c.queue_free()
	for i in seals.size():
		var l = UI.label(seals[i], 18, Color(1, 0.9, 0.7), HORIZONTAL_ALIGNMENT_CENTER)
		l.modulate.a = 0.0
		seal_box.add_child(l)
		var tw = l.create_tween()
		tw.tween_interval(i * 0.075)
		tw.tween_property(l, "modulate:a", 1.0, 0.05)
		tw.tween_interval(0.8)
		tw.tween_property(l, "modulate:a", 0.0, 0.3)
		tw.tween_callback(l.queue_free)


func objective_changed() -> void:
	if Game.profile.is_empty():
		return
	var s = Progress.story()
	var t: String = Progress.STORY[mini(s, Progress.STORY.size() - 1)]
	var m: Dictionary = Game.profile.get("active_mission", {})
	if not m.is_empty():
		t += "\n\n[%s] %s: %s (%d/%d)" % [m["rank"], m["title"], m["desc"], m.get("progress", 0), m["count"]]
	objective_lbl.text = t
	obj_progress_lbl.text = ""
	obj_progress_lbl.visible = false


func objective_progress(t: String) -> void:
	obj_progress_lbl.text = t
	obj_progress_lbl.visible = t != ""


func boss_bar(b: Node) -> void:
	boss = b
	boss_box.visible = b != null and is_instance_valid(b)
	if boss_box.visible:
		boss_lbl.text = b.display_name
		boss_bar_pb.max_value = b.max_hp
		boss_bar_pb.value = b.hp


# ------------------------------------------------------------------ diyalog / dükkân
func dialog(title: String, text: String, options: Array) -> void:
	close_dialog()
	Game.ui_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p = UI.panel()
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.custom_minimum_size = Vector2(760, 0)
	p.position = Vector2(-380, -380)
	var v = UI.vbox(10)
	p.add_child(v)
	v.add_child(UI.header(title, 24))
	var body = UI.label(text, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(720, 0)
	v.add_child(body)
	for o in options:
		var b = UI.button(o["label"], func():
			close_dialog()
			o["cb"].call(), 720)
		if o.has("tip"):
			b.tooltip_text = o["tip"]
		v.add_child(b)
	v.add_child(UI.button("Kapat [Esc]", close_dialog, 720))
	dialog_layer.add_child(p)
	p.set_meta("dialog", true)
	var tw = p.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	p.modulate.a = 0.0
	tw.tween_property(p, "modulate:a", 1.0, 0.12)


func close_dialog() -> void:
	for c in dialog_layer.get_children():
		c.queue_free()
	Game.ui_open = false
	if not Game.paused and Game.player:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func dialog_open() -> bool:
	return dialog_layer.get_child_count() > 0


func shop(title: String, items: Array) -> void:
	var opts = []
	for id in items:
		var it: Dictionary = Data.items.get(id, {})
		if it.is_empty():
			continue
		var have = int(Game.profile["inventory"].get(id, 0))
		var lbl = "%s — %d Ryō   (sende: %d)" % [it["name"], it["price"], have]
		opts.append({"label": lbl, "tip": it["desc"], "cb": func(): _buy(id, title, items)})
	dialog("%s   (Ryō: %d)" % [title, int(Game.profile["ryo"])], "Ne almak istersin?", opts)


## Ekipman dükkânı: silah ve kıyafetler (alınca Tab > Ekipman'dan giyilir)
func gear_shop(title: String, ids: Array) -> void:
	var pr = Game.profile
	Gear.ensure(pr)
	var opts = []
	for id in ids:
		var it = Gear.item(id)
		var have = 0
		for g in pr["gear"]:
			if g["id"] == id:
				have += 1
		var locked = int(it.get("rank", 0)) > int(pr["rank"])
		var lbl = "%s — %d Ryō   [%s]%s" % [it["name"], int(it["price"]), Gear.stats_text(id), ("   (sende: %d)" % have) if have > 0 else ""]
		if locked:
			lbl = "🔒 %s — %s rütbesi gerekir" % [it["name"], Data.RANKS[int(it["rank"])]]
		opts.append({"label": lbl, "tip": it["desc"], "cb": func():
			if locked:
				msg("Bu ekipman için rütben yetersiz.", Color(1, 0.6, 0.4))
			elif int(pr["ryo"]) < int(it["price"]):
				msg("Yeterli Ryō yok!", Color(1, 0.5, 0.4))
			else:
				Progress.add_ryo(-int(it["price"]))
				Gear.grant(pr, id)
				Sfx.play("coin")
				msg("%s alındı! Giymek için: Tab > Ekipman" % it["name"], Color(0.6, 1, 0.6))
			gear_shop(title, ids)})
	dialog("%s   (Ryō: %d)" % [title, int(pr["ryo"])], "Ne almak istersin?", opts)


func _buy(id: String, title: String, items: Array) -> void:
	var it: Dictionary = Data.items[id]
	if int(Game.profile["ryo"]) < int(it["price"]):
		msg("Yeterli Ryō yok!", Color(1, 0.5, 0.4))
	else:
		if it["kind"] == "scroll":
			var jid: String = it["jutsu"]
			var j: Dictionary = Data.jutsu[jid]
			if j["element"] != "" and not j["element"] in Game.profile["elements"]:
				msg("Bu parşömen %s elementine sahip olanlar için." % j["element"], Color(1, 0.6, 0.4))
				shop(title, items)
				return
			if int(Game.profile["level"]) < int(j["level"]):
				msg("Bu parşömen için Seviye %d gerekli." % j["level"], Color(1, 0.6, 0.4))
				shop(title, items)
				return
			if jid in Game.profile["learned"]:
				msg("Bunu zaten biliyorsun.", Color(1, 0.8, 0.5))
				shop(title, items)
				return
			Progress.add_ryo(-int(it["price"]))
			Progress.learn(jid)
		else:
			Progress.add_ryo(-int(it["price"]))
			var n = 5 if id in ["kunai", "shuriken"] else 1
			Game.profile["inventory"][id] = int(Game.profile["inventory"].get(id, 0)) + n
			Sfx.play("coin")
	shop(title, items)


# ------------------------------------------------------------------ güncelleme
func _process(dt: float) -> void:
	if not game_hud.visible:
		return
	var pl = Game.player
	if pl == null:
		return
	var pr = Game.profile
	fps_lbl.text = "FPS %d" % Engine.get_frames_per_second() if Game.settings["show_fps"] else ""
	name_lbl.text = String(pr.get("name", ""))
	rank_lbl.text = "%s  •  Seviye %d" % [Data.RANKS[int(pr.get("rank", 0))].to_upper(), int(pr.get("level", 1))]
	ryo_lbl.text = "両 %d Ryō" % int(pr.get("ryo", 0))
	hp_bar.max_value = pl.max_hp; hp_bar.value = pl.hp
	var hk = clampf(pl.hp / maxf(1.0, pl.max_hp), 0.0, 1.0)
	var hcol = Color(0.35, 0.9, 0.35) if hk > 0.5 else (Color(1, 0.8, 0.2) if hk > 0.25 else Color(1, 0.3, 0.25))
	(hp_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = hcol
	hp_txt.text = "%d / %d" % [int(pl.hp), int(pl.max_hp)]
	if absf(portrait_hp - hk) > 0.005:
		portrait_hp = hk
		portrait.queue_redraw()
	elif Engine.get_process_frames() % 60 == 0:
		portrait.queue_redraw()
	hp_trail.max_value = pl.max_hp
	hp_trail.value = move_toward(hp_trail.value, pl.hp, dt * pl.max_hp * 0.35) if hp_trail.value > pl.hp else pl.hp
	ck_bar.max_value = pl.max_chakra; ck_bar.value = pl.chakra
	ck_txt.text = "%d" % int(pl.chakra)
	xp_bar.max_value = Data.xp_for_level(int(pr.get("level", 1))); xp_bar.value = int(pr.get("xp", 0))
	var comb = pl.combat
	if comb:
		for i in 4:
			sub_pips[i].modulate.a = 1.0 if comb.sub_bars >= i + 1 else 0.18
	(vignette.material as ShaderMaterial).set_shader_parameter("amount", clampf(1.0 - pl.hp / pl.max_hp * 2.5, 0.0, 0.8))
	var slots: Array = pr.get("slots", [])
	for i in SLOT_COUNT:
		var jid = slots[i] if i < slots.size() else ""
		var sn: Array = slot_nodes[i]
		var st: Dictionary = slot_state[i]
		if jid == null or jid == "":
			sn[1].text = "—"; sn[2].text = ""
			if not st["empty"]:
				st["empty"] = true; st["cd"] = 0.0
				sn[0].queue_redraw()
			continue
		var j: Dictionary = Data.jutsu.get(jid, {})
		sn[1].text = String(j.get("name", jid)).split(":")[-1].split("(")[0].strip_edges()
		var cd: float = comb.cooldowns.get(jid, 0.0) if comb else 0.0
		var ok = pl.chakra >= float(j.get("cost", 0))
		sn[2].text = ("%.1f sn" % cd) if cd > 0.0 else "%d ck" % int(j.get("cost", 0))
		sn[2].add_theme_color_override("font_color", Color(0.7, 0.85, 1) if ok else Color(1, 0.5, 0.45))
		var el = String(j.get("element", ""))
		var mx = maxf(float(j.get("cd", 5)), cd)
		if st["empty"] or st["el"] != el or absf(st["cd"] - cd) > 0.001 or st["ok"] != ok or st["max"] != mx:
			st["empty"] = false; st["el"] = el; st["cd"] = cd; st["ok"] = ok; st["max"] = mx
			sn[0].queue_redraw()
	var tool: String = pr.get("throw_sel", "kunai")
	tool_lbl.text = "[R]  %s  ×%d\n[T]  alet değiştir" % [Data.items.get(tool, {"name": tool})["name"], int(pr["inventory"].get(tool, 0))]
	item_lbl.text = "[H]  Merhem  ×%d\n[Y]  Asker Hapı  ×%d" % [int(pr["inventory"].get("salve", 0)), int(pr["inventory"].get("pill", 0))]
	if msg_t > 0.0:
		msg_t -= dt
		if msg_t <= 0.0:
			msg_lbl.text = ""
	var it = Interact.nearest(pl.global_position)
	var catch = _near_catchable(pl)
	var tk = _near_talker(pl) if it.is_empty() and not catch else null
	var ptxt = it.get("label", "") if not it.is_empty() else ("Yakala!" if catch else ("Konuş: %s" % tk.display if tk else ""))
	ptxt = String(ptxt).replace("[F] ", "").replace("[F]", "").strip_edges()
	prompt_box.visible = ptxt != ""
	if prompt_box.visible and prompt_lbl.text != ptxt:
		prompt_lbl.text = ptxt
		prompt_box.reset_size()
		prompt_box.position = Vector2(-prompt_box.size.x * 0.5, -168)
	var rn = Game.region_name(pl.global_position) if Engine.get_process_frames() % 20 == 0 else region_name
	if rn != region_name:
		region_name = rn
		region_lbl.text = rn
		mm_region.text = rn
		var tw = region_lbl.create_tween()
		tw.tween_property(region_lbl, "modulate:a", 1.0, 0.4)
		tw.tween_interval(2.5)
		tw.tween_property(region_lbl, "modulate:a", 0.0, 1.0)
	# kilit nişanı
	var lt = comb.lock_target if comb else null
	if lt and is_instance_valid(lt) and not lt.is_dead():
		var cam = pl.cam
		var wp: Vector3 = lt.global_position + Vector3.UP * lt.height * 0.6
		lock_ret.visible = not cam.is_position_behind(wp)
		lock_ret.position = cam.unproject_position(wp)
		lock_ret.queue_redraw()
	else:
		lock_ret.visible = false
	_update_objective_pointer(pl)
	if boss and is_instance_valid(boss):
		boss_bar_pb.value = boss.hp
	elif boss_box.visible:
		boss_box.visible = false
	# mini harita
	var sm: ShaderMaterial = minimap.get_meta("mat")
	var m = Game.to_map(pl.global_position)
	var W = Game.hw * Game.res
	var H = Game.hh * Game.res
	sm.set_shader_parameter("center", Vector2((m.x - Game.x0) / W, (Game.y1 - m.y) / H))
	sm.set_shader_parameter("zoom", 900.0 / W)
	sm.set_shader_parameter("rot", deg_to_rad(pl.yaw) * -1.0)
	(minimap.get_meta("over") as Control).queue_redraw()


func _near_talker(pl: Node3D) -> Node:
	var best: Node = null
	var bd = 2.6
	for c in get_tree().get_nodes_in_group("talkers"):
		var d = c.global_position.distance_to(pl.global_position)
		if d < bd:
			bd = d; best = c
	return best


func _near_catchable(pl: Node3D) -> Node:
	for c in get_tree().get_nodes_in_group("catchables"):
		if c.global_position.distance_to(pl.global_position) < 2.5:
			return c
	return null


func _draw_minimap_markers(c: Control) -> void:
	var pl = Game.player
	if pl == null:
		return
	var R = 120.0
	var scale = R / 450.0  # 900 m çap
	var rot = deg_to_rad(pl.yaw)
	var to_mm = func(wp: Vector3) -> Vector2:
		var d = Vector2(wp.x - pl.global_position.x, wp.z - pl.global_position.z)
		d = d.rotated(rot)
		return Vector2(R, R) + d * scale
	for f in get_tree().get_nodes_in_group("fighters"):
		if Combat.hostile(pl, f) and f.get("team") != "dummy" and not f.is_dead():
			var q: Vector2 = to_mm.call(f.global_position)
			if q.distance_to(Vector2(R, R)) < R - 4:
				c.draw_circle(q, 3.5, Color(1, 0.25, 0.2))
	if Missions.has_marker:
		var q: Vector2 = to_mm.call(Missions.target_marker)
		var dv = q - Vector2(R, R)
		if dv.length() > R - 12:
			# menzil dışı: kenarda hedefe bakan ok
			var dn = dv.normalized()
			var sd = Vector2(-dn.y, dn.x)
			var tp = Vector2(R, R) + dn * (R - 4)
			var bk = Vector2(R, R) + dn * (R - 22)
			c.draw_colored_polygon(PackedVector2Array([tp, bk + sd * 9, bk - sd * 9]), Color(1, 0.85, 0.2))
			c.draw_polyline(PackedVector2Array([tp, bk + sd * 9, bk - sd * 9, tp]), Color(0.25, 0.1, 0.0), 2.0)
		else:
			c.draw_circle(q, 8, Color(1, 0.85, 0.2))
			c.draw_circle(q, 4, Color(0.2, 0.1, 0.0))
	# oyuncu oku (yukarı = kamera yönü)
	var fr = pl.facing - deg_to_rad(pl.yaw)
	var tip = Vector2(R, R) + Vector2(0, -12).rotated(-fr)
	var l = Vector2(R, R) + Vector2(-7, 8).rotated(-fr)
	var r = Vector2(R, R) + Vector2(7, 8).rotated(-fr)
	c.draw_colored_polygon(PackedVector2Array([tip, l, r]), Color(1, 0.95, 0.9))
	c.draw_polyline(PackedVector2Array([tip, l, r, tip]), Color(0.1, 0.05, 0.0), 2.0)
	var npos = Vector2(R, R) + Vector2(0, -1).rotated(rot) * (R - 14)
	c.draw_circle(npos, 10, Color(0.1, 0.06, 0.04, 0.85))
	c.draw_string(ThemeDB.fallback_font, npos + Vector2(-5, 6), "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.6, 0.3))
