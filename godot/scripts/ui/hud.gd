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
	dialog_layer = Control.new()
	dialog_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dialog_layer)


func show_game_hud(on: bool) -> void:
	game_hud.visible = on


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
	var box = UI.vbox(4)
	box.position = Vector2(24, 20)
	game_hud.add_child(box)
	name_lbl = UI.label("", 20, Color(1, 0.85, 0.6))
	box.add_child(name_lbl)
	var hp_stack = Control.new()
	hp_stack.custom_minimum_size = Vector2(380, 22)
	box.add_child(hp_stack)
	hp_trail = UI.bar(Color(1, 0.85, 0.5), 380, 22)
	hp_stack.add_child(hp_trail)
	hp_bar = UI.bar(Color(0.9, 0.22, 0.2), 380, 22)
	var transparent = StyleBoxEmpty.new()
	hp_bar.add_theme_stylebox_override("background", transparent)
	hp_stack.add_child(hp_bar)
	ck_bar = UI.bar(Color(0.2, 0.55, 1.0), 340, 16)
	box.add_child(ck_bar)
	var row = UI.hbox(6)
	box.add_child(row)
	for i in 4:
		var p = Panel.new()
		p.custom_minimum_size = Vector2(26, 10)
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.4, 0.85, 0.5)
		s.set_corner_radius_all(2)
		p.add_theme_stylebox_override("panel", s)
		row.add_child(p)
		sub_pips.append(p)
	row.add_child(UI.label("Kawarimi", 12, Color(0.75, 0.85, 0.75)))
	xp_bar = UI.bar(Color(0.95, 0.8, 0.3), 380, 6)
	box.add_child(xp_bar)
	fps_lbl = UI.label("", 14, Color(0.7, 0.9, 0.7))
	fps_lbl.position = Vector2(24, 4)
	game_hud.add_child(fps_lbl)


func _build_slots() -> void:
	slots_box = UI.hbox(10)
	slots_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slots_box.position = Vector2(-260, -110)
	game_hud.add_child(slots_box)
	for i in 4:
		var p = PanelContainer.new()
		p.custom_minimum_size = Vector2(110, 74)
		var v = UI.vbox(0)
		p.add_child(v)
		var key = UI.label("[%d]" % (i + 1), 14, UI.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
		var nm = UI.label("—", 13, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size = Vector2(100, 0)
		var cd = UI.label("", 16, Color(0.6, 0.8, 1), HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(key); v.add_child(nm); v.add_child(cd)
		slots_box.add_child(p)
		slot_nodes.append([p, nm, cd])
	tool_lbl = UI.label("", 15, Color(0.85, 0.85, 0.85))
	tool_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tool_lbl.position = Vector2(230, -100)
	game_hud.add_child(tool_lbl)
	seal_box = UI.hbox(6)
	seal_box.set_anchors_preset(Control.PRESET_CENTER)
	seal_box.position = Vector2(-150, 120)
	game_hud.add_child(seal_box)


func _build_texts() -> void:
	msg_lbl = UI.label("", 22, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	msg_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	msg_lbl.position = Vector2(-500, -190)
	msg_lbl.size = Vector2(1000, 30)
	game_hud.add_child(msg_lbl)
	prompt_lbl = UI.label("", 20, Color(1, 0.88, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
	prompt_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_lbl.position = Vector2(-400, -150)
	prompt_lbl.size = Vector2(800, 30)
	game_hud.add_child(prompt_lbl)
	region_lbl = UI.label("", 40, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
	region_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	region_lbl.position = Vector2(-400, 70)
	region_lbl.size = Vector2(800, 60)
	region_lbl.modulate.a = 0.0
	game_hud.add_child(region_lbl)
	var obj = PanelContainer.new()
	obj.anchor_left = 1.0; obj.anchor_right = 1.0
	obj.offset_left = -432; obj.offset_right = -22; obj.offset_top = 280
	obj.custom_minimum_size = Vector2(400, 0)
	var ov = UI.vbox(4)
	obj.add_child(ov)
	ov.add_child(UI.label("GÖREV", 14, UI.ACCENT))
	objective_lbl = UI.label("", 16)
	objective_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_lbl.custom_minimum_size = Vector2(370, 0)
	ov.add_child(objective_lbl)
	obj_progress_lbl = UI.label("", 15, Color(0.7, 0.95, 0.7))
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
	minimap.offset_left = -262; minimap.offset_right = -22; minimap.offset_top = 20; minimap.offset_bottom = 260
	minimap.custom_minimum_size = Vector2(240, 240)
	minimap.size = Vector2(240, 240)
	var tr = TextureRect.new()
	tr.texture = map_tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.custom_minimum_size = Vector2(240, 240)
	tr.size = Vector2(240, 240)
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
	float edge = smoothstep(0.47, 0.5, length(q));
	COLOR = mix(col, vec4(0.96, 0.55, 0.16, 1.0), edge);
}"""
	sm.shader = sh
	tr.material = sm
	minimap.add_child(tr)
	minimap.set_meta("mat", sm)
	var over = Control.new()
	over.size = Vector2(240, 240)
	over.draw.connect(_draw_minimap_markers.bind(over))
	minimap.add_child(over)
	minimap.set_meta("over", over)
	game_hud.add_child(minimap)


func _build_boss() -> void:
	boss_box = UI.vbox(2)
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.position = Vector2(-300, 24)
	boss_lbl = UI.label("", 20, Color(1, 0.6, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
	boss_lbl.custom_minimum_size = Vector2(600, 0)
	boss_bar_pb = UI.bar(Color(0.85, 0.15, 0.2), 600, 18)
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
	var l = UI.label(text, 20, col, HORIZONTAL_ALIGNMENT_CENTER)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.position = Vector2(120 + randf_range(-30, 30), -40 + randf_range(-20, 20))
	game_hud.add_child(l)
	var tw = l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 60, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(l.queue_free)


## Storm tarzı büyük fırça banner'ı
func banner(title: String, sub: String, col: Color) -> void:
	for c in banner_box.get_children():
		c.queue_free()
	var strip = ColorRect.new()
	strip.color = Color(0, 0, 0, 0.6)
	strip.set_anchors_preset(Control.PRESET_CENTER)
	strip.position = Vector2(-2000, -70)
	strip.size = Vector2(4000, 120)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.add_child(strip)
	var line = ColorRect.new()
	line.color = col
	line.size = Vector2(4000, 4)
	line.position = Vector2(0, 0)
	strip.add_child(line)
	var line2 = line.duplicate()
	line2.position = Vector2(0, 116)
	strip.add_child(line2)
	var t = UI.label(title, 52, col, HORIZONTAL_ALIGNMENT_CENTER)
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


func objective_progress(t: String) -> void:
	obj_progress_lbl.text = t


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
	v.add_child(UI.label(title, 24, UI.ACCENT))
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
	name_lbl.text = "%s  •  %s  •  Sv.%d   %d Ryō" % [pr.get("name", ""), Data.RANKS[int(pr.get("rank", 0))], int(pr.get("level", 1)), int(pr.get("ryo", 0))]
	hp_bar.max_value = pl.max_hp; hp_bar.value = pl.hp
	hp_trail.max_value = pl.max_hp
	hp_trail.value = move_toward(hp_trail.value, pl.hp, dt * pl.max_hp * 0.35) if hp_trail.value > pl.hp else pl.hp
	ck_bar.max_value = pl.max_chakra; ck_bar.value = pl.chakra
	xp_bar.max_value = Data.xp_for_level(int(pr.get("level", 1))); xp_bar.value = int(pr.get("xp", 0))
	var comb = pl.combat
	if comb:
		for i in 4:
			sub_pips[i].modulate.a = 1.0 if comb.sub_bars >= i + 1 else 0.2
	(vignette.material as ShaderMaterial).set_shader_parameter("amount", clampf(1.0 - pl.hp / pl.max_hp * 2.5, 0.0, 0.8))
	var slots: Array = pr.get("slots", [])
	for i in 4:
		var jid = slots[i] if i < slots.size() else ""
		var sn: Array = slot_nodes[i]
		if jid == null or jid == "":
			sn[1].text = "—"; sn[2].text = ""
			continue
		var j: Dictionary = Data.jutsu.get(jid, {})
		sn[1].text = j.get("name", jid).split(":")[-1].strip_edges()
		var cd: float = comb.cooldowns.get(jid, 0.0) if comb else 0.0
		sn[2].text = ("%.1f" % cd) if cd > 0.0 else "%d ck" % int(j.get("cost", 0))
		sn[0].modulate = Color(0.55, 0.55, 0.6) if cd > 0.0 or pl.chakra < float(j.get("cost", 0)) else Color(1, 1, 1)
	var tool: String = pr.get("throw_sel", "kunai")
	tool_lbl.text = "[R] %s x%d   [T] değiştir\n[H] Merhem x%d  [Y] Asker Hapı x%d" % [Data.items.get(tool, {"name": tool})["name"], int(pr["inventory"].get(tool, 0)),
		int(pr["inventory"].get("salve", 0)), int(pr["inventory"].get("pill", 0))]
	if msg_t > 0.0:
		msg_t -= dt
		if msg_t <= 0.0:
			msg_lbl.text = ""
	var it = Interact.nearest(pl.global_position)
	var catch = _near_catchable(pl)
	var tk = _near_talker(pl) if it.is_empty() and not catch else null
	prompt_lbl.text = it.get("label", "") if not it.is_empty() else ("[F] Yakala!" if catch else ("[F] Konuş: %s" % tk.display if tk else ""))
	var rn = Game.region_name(pl.global_position) if Engine.get_process_frames() % 20 == 0 else region_name
	if rn != region_name:
		region_name = rn
		region_lbl.text = rn
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
		if dv.length() > R - 10:
			q = Vector2(R, R) + dv.normalized() * (R - 10)
		c.draw_circle(q, 7, Color(1, 0.85, 0.2))
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
