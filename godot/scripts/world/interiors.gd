class_name Interiors
extends Node3D
## Girilebilir binalar. Kapıda [F] -> ekran kararır -> köyün çok üstünde (gökte, karada) iç mekân kurulur,
## oyuncu oraya taşınır. Çıkış kapısında [F] -> geri döner. Aynı anda tek oda vardır.
## Oda yerel koordinatı: x sağ, y yukarı, d = kapıdan içeri derinlik (Godot'da -Z).

static var inst: Interiors
const ALT := 1500.0

const TITLES := {
	"academy": "Ninja Akademisi", "hokage": "Hokage Kulesi — Görev Ofisi", "weapon_shop": "Silah Dükkânı",
	"pharmacy": "Eczane", "tailor": "Terzi", "bbq": "Yakiniku Restoranı", "hospital": "Konoha Hastanesi",
	"home_player": "Senin Evin", "home": "Bir Ev", "teahouse": "Dango ve Çay Evi", "inn": "Han (Ryokan)",
}

var inside := ""
var room: Node3D
var door := {}
var items: Array = []
var npcs: Array = []
var fade: ColorRect
var title_lbl: Label
var origin := Vector3.ZERO
var mb: MB
var glow_mb: MB
var body: StaticBody3D
var busy := false
var spawn_q: Array = []
var entry_yaw := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	inst = self
	var cl = CanvasLayer.new()
	cl.layer = 60
	add_child(cl)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(fade)
	title_lbl = UI.label("", 34, Color(1, 0.92, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_lbl.position = Vector2(-400, 150)
	title_lbl.size = Vector2(800, 50)
	title_lbl.modulate.a = 0.0
	cl.add_child(title_lbl)


func _fade(to: float, dur := 0.35) -> void:
	var tw = create_tween()
	tw.tween_property(fade, "color:a", to, dur)
	await tw.finished


func _teleport(pos: Vector3, yaw_deg: float) -> void:
	var pl = Game.player
	if pl == null:
		return
	pl.global_position = pos
	pl.velocity = Vector3.ZERO
	pl.wall_n = Vector3.ZERO
	pl.yaw = yaw_deg
	pl.facing = deg_to_rad(yaw_deg)
	pl.reset_physics_interpolation()
	pl.cam_pivot.global_position = pos + Vector3.UP * 1.6
	pl.model.transform = Transform3D(Basis(Vector3.UP, pl.facing), Vector3.ZERO)
	pl.model.scale = Vector3.ONE * pl.model.age_scale
	pl.model.play("idle", 0.0)


# ------------------------------------------------------------------ giriş / çıkış
func enter(it: Dictionary) -> void:
	if busy or inside != "" or Game.player == null:
		return
	busy = true
	door = it
	entry_yaw = Game.player.yaw
	Sfx.play("step", Game.player.global_position, 0.8)
	await _fade(1.0)
	# oda kapının tam üstünde kurulur (görev masası vb. hangi köyde olduğunu konumdan anlar)
	var op: Vector3 = it.get("out", it["pos"])
	origin = Vector3(op.x, Game.terrain_height(op.x, op.z) + ALT, op.z)
	var kind: String = it.get("room", "home")
	_build(kind, int(it.get("seed", 0)))
	inside = kind
	_teleport(origin + Vector3(0, 0.05, -2.4), 0.0)
	_rain(false)
	title_lbl.text = TITLES.get(kind, "İç Mekân")
	if kind in ["hokage", "kage"]:
		title_lbl.text = "%s Kulesi — Kage Ofisi" % Progress.kage_title(String(it.get("vid", "konoha")))
	await _fade(0.0)
	var tw = create_tween()
	tw.tween_property(title_lbl, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.4)
	tw.tween_property(title_lbl, "modulate:a", 0.0, 0.6)
	busy = false


func exit() -> void:
	if busy or inside == "":
		return
	busy = true
	await _fade(1.0)
	_clear()
	inside = ""
	var p: Vector3 = door.get("out", door["pos"])
	p.y = Game.ground_height(p.x, p.z) + 0.05
	_teleport(p, entry_yaw + 180.0)
	_rain(true)
	await _fade(0.0)
	busy = false


func _rain(on: bool) -> void:
	if Game.world and Game.world.env and Game.world.env.rain:
		Game.world.env.rain.visible = on
		Game.world.env.splash.visible = on
		Game.world.env.snow.visible = on


func _clear() -> void:
	for it in items:
		Interact.items.erase(it)
	items.clear()
	for n in npcs:
		if is_instance_valid(n):
			n.queue_free()
	npcs.clear()
	spawn_q.clear()
	if room:
		room.queue_free()
		room = null


func _process(_dt: float) -> void:
	if inside == "" or Game.player == null:
		return
	# güvenlik ağı: oda dünyanın 1500 m üstünde; duvar koşusuyla duvarı aşıp düşen oyuncu kapıdan dışarı çıkarılır
	var pp: Vector3 = Game.player.global_position
	if not busy and (pp.y < origin.y - 4.0 or pp.y > origin.y + 14.0 or Vector2(pp.x - origin.x, pp.z - origin.z).length() > 45.0):
		exit()
		return
	# odada duvar koşusu yok (tavana tırmanıp üstünden aşılıyordu)
	if Game.player.wall_n != Vector3.ZERO and Game.player.has_method("_leave_wall"):
		Game.player._leave_wall()
	if not spawn_q.is_empty():
		_spawn_npc(spawn_q.pop_front())
	# odadan düşme güvenliği
	if Game.player.global_position.y < origin.y - 6.0:
		_teleport(origin + Vector3(0, 0.05, -2.4), 0.0)


# ------------------------------------------------------------------ yapı yardımcıları
func L(x: float, y: float, d: float) -> Vector3:
	return origin + Vector3(x, y, -d)


func bx(x: float, y: float, d: float, sx: float, sy: float, sd: float, col: Color, collide := false, rot := Vector3.ZERO) -> void:
	var p = L(x, y, d)
	mb.add("box", p, Vector3(sx, sy, sd), col, rot)
	if collide:
		var cs = CollisionShape3D.new()
		var sh = BoxShape3D.new()
		sh.size = Vector3(sx, sy, sd)
		cs.shape = sh
		cs.transform = Transform3D(Basis.from_euler(rot * PI / 180.0), p)
		body.add_child(cs)


func cy(x: float, y: float, d: float, dia: float, h: float, col: Color, seg := 10, rot := Vector3.ZERO) -> void:
	mb.add("cyl", L(x, y, d), Vector3(dia, h, dia), col, rot, seg)


func sp(x: float, y: float, d: float, s: Vector3, col: Color, seg := 8) -> void:
	mb.add("sphere", L(x, y, d), s, col, Vector3.ZERO, seg)


## Parlayan (ışık saçan) parça: pencere, fener kâğıdı, ateş
func gl(kind: String, x: float, y: float, d: float, s: Vector3, col: Color, rot := Vector3.ZERO) -> void:
	glow_mb.add(kind, L(x, y, d), s, col, rot, 10)


func lamp(x: float, y: float, d: float, col := Color(1.0, 0.78, 0.5), energy := 1.3, rng_ := 9.0) -> void:
	var l = OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_
	l.omni_attenuation = 1.2
	l.shadow_enabled = false
	room.add_child(l)
	l.global_position = L(x, y, d)


func act(x: float, d: float, radius: float, kind: String, label: String, data := {}) -> void:
	var it = {"pos": L(x, 0, d), "radius": radius, "kind": kind, "label": label, "interior": true}
	it.merge(data)
	Interact.items.append(it)
	items.append(it)


## İnsan: rol + yerel konum + bakış (derece; 0 = kapıya doğru bakar) + isteğe bağlı ad/replikler
func person(role: String, x: float, d: float, face_deg: float, display := "", lines: Array = [], extra := {}) -> void:
	spawn_q.append({"role": role, "pos": L(x, 0.05, d), "face": face_deg, "display": display, "lines": lines, "extra": extra})


func _spawn_npc(req: Dictionary) -> void:
	var vg = Villager.new()
	vg.role = req["role"]
	vg.interior = true
	if req["display"] != "":
		vg.display_override = req["display"]
	vg.lines_override = req["lines"]
	for k in req["extra"]:
		if k != "kage_vid":
			vg.set(k, req["extra"][k])
	room.add_child(vg)
	if req["extra"].has("kage_vid"):
		KageAttire.hat(vg.model, req["extra"]["kage_vid"])
	vg.global_position = req["pos"]
	vg.home = req["pos"]
	vg.facing = deg_to_rad(180.0 + float(req["face"]))
	vg.stand_face = vg.facing
	vg.fixed_face = true
	if vg.model:
		vg.model.rotation.y = vg.facing
	npcs.append(vg)


## Ahşap zemin, sıvalı duvarlar + ahşap dikmeler, tavan kirişleri, kapı + çıkış, shoji pencereler
func shell(W: float, D: float, H: float, wall := Color(0.93, 0.88, 0.76), floor_col := Color(0.62, 0.44, 0.28), windows := true) -> void:
	var wood = Color(0.42, 0.29, 0.18)
	# zemin (çarpışma tek kutu, görsel tahta şeritler)
	bx(0, -0.1, D * 0.5, W + 0.4, 0.2, D + 0.4, floor_col, true)
	var n = int(W / 0.6)
	for i in n:
		var x = -W * 0.5 + (i + 0.5) * W / n
		bx(x, 0.005, D * 0.5, W / n - 0.03, 0.01, D, floor_col.darkened(0.06 if i % 2 else -0.04))
	# duvarlar (çarpışmalı)
	bx(-W * 0.5 - 0.1, H * 0.5, D * 0.5, 0.2, H, D + 0.4, wall, true)
	bx(W * 0.5 + 0.1, H * 0.5, D * 0.5, 0.2, H, D + 0.4, wall, true)
	bx(0, H * 0.5, D + 0.1, W + 0.4, H, 0.2, wall, true)
	var dw = 1.8
	bx(-(W + dw) * 0.25 - 0.1, H * 0.5, -0.1, (W - dw) * 0.5 + 0.2, H, 0.2, wall, true)
	bx((W + dw) * 0.25 + 0.1, H * 0.5, -0.1, (W - dw) * 0.5 + 0.2, H, 0.2, wall, true)
	bx(0, (H + 2.4) * 0.5, -0.1, dw, H - 2.4, 0.2, wall, true)
	# kapı boşluğu: görünmez çarpışma (kamera dışarı kaçmasın, çıkış [F] ile)
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = Vector3(dw, 2.4, 0.2)
	cs.shape = sh
	cs.position = L(0, 1.2, -0.1)
	body.add_child(cs)
	# kapı: koyu kasa + kapı dışında sokak ışığı
	bx(-dw * 0.5 - 0.06, 1.2, 0.0, 0.12, 2.4, 0.3, wood)
	bx(dw * 0.5 + 0.06, 1.2, 0.0, 0.12, 2.4, 0.3, wood)
	bx(0, 2.44, 0.0, dw + 0.24, 0.12, 0.3, wood)
	gl("box", 0, 1.2, -0.25, Vector3(dw, 2.4, 0.05), Color(1.0, 0.92, 0.75))
	# noren perdesi
	for k in 3:
		bx(-0.6 + k * 0.6, 2.05, 0.18, 0.56, 0.7, 0.03, Color(0.15, 0.25, 0.5))
	# tavan + kirişler
	bx(0, H + 0.1, D * 0.5, W + 0.4, 0.2, D + 0.4, wall.darkened(0.15), true)
	for k in int(D / 2.2) + 1:
		bx(0, H - 0.12, 0.3 + k * 2.2, W, 0.22, 0.22, wood)
	# dikmeler + pervaz + süpürgelik
	for side in [-1.0, 1.0]:
		var k = 0.0
		while k <= D:
			bx(side * (W * 0.5 - 0.06), H * 0.5, k, 0.16, H, 0.16, wood)
			k += 2.5
		bx(side * (W * 0.5 - 0.03), 2.2, D * 0.5, 0.06, 0.12, D, wood)
		bx(side * (W * 0.5 - 0.03), 0.08, D * 0.5, 0.06, 0.16, D, wood)
	bx(0, 2.2, D - 0.03, W, 0.12, 0.06, wood)
	# shoji pencereler (yan duvarlar): parlak kâğıt + ızgara
	if windows:
		for side in [-1.0, 1.0]:
			var k = 2.0
			while k < D - 1.0:
				gl("box", side * (W * 0.5 - 0.02), 1.6, k, Vector3(0.04, 1.1, 1.4), Color(1.0, 0.95, 0.82))
				for q in 3:
					bx(side * (W * 0.5 - 0.05), 1.6, k - 0.47 + q * 0.47, 0.04, 1.14, 0.04, wood)
				for q in 3:
					bx(side * (W * 0.5 - 0.05), 1.1 + q * 0.5, k, 0.04, 0.04, 1.44, wood)
				k += 3.2
	act(0, 0.9, 1.6, "exit", "[F] Dışarı çık")


func scroll(x: float, y: float, d: float, side := 0.0, col := Color(0.95, 0.93, 0.86)) -> void:
	## Duvar parşömeni (kakemono). side: 0 = arka duvar, ±1 = yan duvar
	if side == 0.0:
		bx(x, y, d, 0.7, 1.4, 0.03, col)
		bx(x, y + 0.72, d - 0.02, 0.8, 0.06, 0.06, Color(0.3, 0.2, 0.12))
		bx(x, y - 0.72, d - 0.02, 0.8, 0.06, 0.06, Color(0.3, 0.2, 0.12))
		bx(x, y + 0.15, d - 0.02, 0.08, 0.6, 0.01, Color(0.1, 0.1, 0.12))
	else:
		bx(x, y, d, 0.03, 1.4, 0.7, col)
		bx(x - side * 0.02, y + 0.15, d, 0.01, 0.6, 0.08, Color(0.1, 0.1, 0.12))


func paper_lantern(x: float, y: float, d: float, col := Color(1.0, 0.85, 0.6)) -> void:
	bx(x, y + 0.45, d, 0.03, 0.3, 0.03, Color(0.2, 0.15, 0.1))
	cy(x, y + 0.28, d, 0.3, 0.05, Color(0.15, 0.12, 0.1))
	gl("sphere", x, y, d, Vector3(0.42, 0.5, 0.42), col)
	cy(x, y - 0.26, d, 0.26, 0.05, Color(0.15, 0.12, 0.1))


func plant(x: float, d: float) -> void:
	cy(x, 0.2, d, 0.45, 0.4, Color(0.55, 0.35, 0.25))
	sp(x, 0.65, d, Vector3(0.7, 0.6, 0.7), Color(0.28, 0.55, 0.3))
	sp(x + 0.1, 0.95, d - 0.1, Vector3(0.45, 0.4, 0.45), Color(0.35, 0.62, 0.32))


func shelf(x: float, d: float, w: float, h: float, side: float, goods: Array, depth := 0.45) -> void:
	## side: ±1 yan duvara dayalı (x yönünde derinlik), 0 = arka duvar
	var wood = Color(0.45, 0.31, 0.19)
	var rows = int(h / 0.55)
	for r in rows + 1:
		var y = 0.15 + r * 0.55
		if side == 0.0:
			bx(x, y, d, w, 0.05, depth, wood)
		else:
			bx(x, y, d, depth, 0.05, w, wood)
		if r < rows:
			var cnt = int(w / 0.28)
			for k in cnt:
				var col: Color = goods[(k + r * 3) % goods.size()]
				var o = -w * 0.5 + (k + 0.5) * w / cnt
				var hh = rng.randf_range(0.18, 0.4)
				if side == 0.0:
					if k % 3 == 0:
						cy(x + o, y + 0.03 + hh * 0.5, d, 0.14, hh, col, 8)
					else:
						bx(x + o, y + 0.03 + hh * 0.5, d, 0.2, hh, 0.25, col)
				else:
					if k % 3 == 0:
						cy(x, y + 0.03 + hh * 0.5, d + o, 0.14, hh, col, 8)
					else:
						bx(x, y + 0.03 + hh * 0.5, d + o, 0.25, hh, 0.2, col)
	if side == 0.0:
		for sx in [-0.5, 0.5]:
			bx(x + sx * w, 0.15 + rows * 0.55 * 0.5, d, 0.06, rows * 0.55 + 0.1, depth, wood)
	else:
		for sx in [-0.5, 0.5]:
			bx(x, 0.15 + rows * 0.55 * 0.5, d + sx * w, depth, rows * 0.55 + 0.1, 0.06, wood)


func counter(x: float, d: float, w: float, col := Color(0.5, 0.34, 0.2)) -> void:
	bx(x, 0.5, d, w, 1.0, 0.7, col, true)
	bx(x, 1.03, d, w + 0.1, 0.06, 0.82, col.lightened(0.15))


func low_table(x: float, d: float, w := 1.4, dd := 0.9) -> void:
	var c = Color(0.38, 0.24, 0.14)
	bx(x, 0.34, d, w, 0.06, dd, c)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			bx(x + sx * (w * 0.5 - 0.08), 0.16, d + sz * (dd * 0.5 - 0.08), 0.06, 0.32, 0.06, c)


func cushion(x: float, d: float, col := Color(0.55, 0.2, 0.22)) -> void:
	bx(x, 0.05, d, 0.55, 0.1, 0.55, col)


func tatami(x0: float, d0: float, cols: int, rows: int) -> void:
	for i in cols:
		for j in rows:
			var x = x0 + i * 0.95
			var d = d0 + j * 1.9
			bx(x, 0.03, d, 0.93, 0.05, 1.88, Color(0.78, 0.74, 0.5))
			bx(x, 0.035, d - 0.9, 0.93, 0.055, 0.06, Color(0.2, 0.25, 0.2))
			bx(x, 0.035, d + 0.9, 0.93, 0.055, 0.06, Color(0.2, 0.25, 0.2))


func bench(x: float, d: float, w: float, along_x := true) -> void:
	var c = Color(0.45, 0.3, 0.18)
	if along_x:
		bx(x, 0.45, d, w, 0.06, 0.42, c)
		for sx in [-1.0, 1.0]:
			bx(x + sx * (w * 0.5 - 0.1), 0.22, d, 0.08, 0.44, 0.36, c)
	else:
		bx(x, 0.45, d, 0.42, 0.06, w, c)
		for sz in [-1.0, 1.0]:
			bx(x, 0.22, d + sz * (w * 0.5 - 0.1), 0.36, 0.44, 0.08, c)


func stool(x: float, d: float, col := Color(0.7, 0.18, 0.15)) -> void:
	cy(x, 0.45, d, 0.42, 0.08, col, 12)
	cy(x, 0.22, d, 0.08, 0.44, Color(0.25, 0.25, 0.27), 6)


# ------------------------------------------------------------------ odalar
func _build(kind: String, seed: int) -> void:
	_clear()
	rng.seed = hash(kind) + seed
	room = Node3D.new()
	room.name = "Ic_" + kind
	add_child(room)
	body = StaticBody3D.new()
	body.collision_layer = 1
	room.add_child(body)
	mb = MB.new()
	glow_mb = MB.new()
	match kind:
		"academy": _academy()
		"hokage", "kage": _kage_office(String(door.get("vid", "konoha")))
		"weapon_shop": _weapon_shop()
		"pharmacy": _pharmacy()
		"tailor": _tailor()
		"bbq": _bbq()
		"hospital": _hospital()
		"home_player": _home(true)
		"teahouse": _teahouse()
		"inn": _inn()
		_: _home(false)
	var mi = MeshInstance3D.new()
	mi.mesh = mb.build(Props.toon())
	room.add_child(mi)
	if not glow_mb.verts.is_empty():
		var gm = MeshInstance3D.new()
		gm.mesh = glow_mb.build()
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		gm.material_override = m
		gm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		room.add_child(gm)


func _academy() -> void:
	var W = 12.0; var D = 15.0; var H = 3.6
	shell(W, D, H, Color(0.92, 0.86, 0.7))
	# koridor hissi: girişte ayakkabılık + duyuru panosu
	shelf(-W * 0.5 + 0.35, 1.6, 1.6, 1.0, 1.0, [Color(0.3, 0.25, 0.2), Color(0.2, 0.2, 0.3), Color(0.45, 0.3, 0.2)], 0.4)
	bx(W * 0.5 - 0.05, 1.7, 2.0, 0.04, 1.0, 1.6, Color(0.55, 0.42, 0.28))
	for k in 5:
		bx(W * 0.5 - 0.08, 1.5 + (k % 2) * 0.35, 1.5 + k * 0.25, 0.02, 0.26, 0.2, [Color(1, 1, 0.9), Color(0.95, 0.85, 0.7), Color(0.9, 0.95, 1)][k % 3])
	# kara tahta + öğretmen kürsüsü
	bx(0, 1.7, D - 0.05, 6.0, 1.6, 0.06, Color(0.16, 0.26, 0.2))
	bx(0, 0.9, D - 0.09, 6.2, 0.06, 0.12, Color(0.5, 0.35, 0.2))
	for k in 4:  # tebeşir mühür çizimleri
		bx(-2.2 + k * 1.4, 1.9, D - 0.1, 0.9, 0.04, 0.01, Color(0.92, 0.92, 0.9))
		bx(-2.2 + k * 1.4, 1.6, D - 0.1, 0.5, 0.04, 0.01, Color(0.92, 0.92, 0.9))
	bx(0, 0.5, D - 2.0, 1.8, 1.0, 0.7, Color(0.48, 0.32, 0.19), true)
	# öğrenci sıraları: kademeli
	for row in 3:
		for col in 3:
			var x = -3.6 + col * 3.6
			var d = 4.0 + row * 2.4
			bx(x, 0.75, d + 0.35, 2.6, 0.06, 0.5, Color(0.6, 0.42, 0.25))
			bx(x, 0.38, d + 0.35, 2.4, 0.7, 0.05, Color(0.5, 0.34, 0.2))
			bench(x, d - 0.15, 2.4)
			if rng.randf() < 0.75:
				person("student", x + rng.randf_range(-0.7, 0.7), d - 0.15, 180.0)
	scroll(-4.5, 1.9, D - 0.05, 0.0, Color(0.95, 0.9, 0.8))
	scroll(4.5, 1.9, D - 0.05)
	plant(-W * 0.5 + 0.6, D - 0.7)
	plant(W * 0.5 - 0.6, D - 0.7)
	lamp(0, H - 0.5, 4.0, Color(1.0, 0.92, 0.8), 1.4, 11.0)
	lamp(0, H - 0.5, 11.0, Color(1.0, 0.92, 0.8), 1.4, 11.0)
	person("teacher", 0, D - 1.2, 0.0, "Hoshino-sensei", ["Mühürleri ezberlemeden jutsu olmaz!", "Bugün Kawarimi'yi tekrar edeceğiz.", "Ateşin İradesi'ni unutma."])
	act(0, D - 2.9, 2.2, "academy", "[F] Akademi hocasıyla konuş")
	act(-4.2, D - 1.6, 1.8, "trainer", "[F] Yardımcı hoca: temel teknikler", {"kinds": ["academy", "taijutsu", "genjutsu"], "title": "Akademi Yardımcı Hocası"})
	person("teacher", -4.2, D - 1.0, 0.0, "Yardımcı Hoca", ["Temel teknikleri öğrenmeden ileri gidemezsin.", "Kawarimi, Henge, Bunshin: üç temel!"], {"wander_r": 0.6})


## Köy temaları: [duvar, zemin, vurgu, kanji, gök (pencere), çatı silueti]
const OFFICE := {
	"konoha": [Color(0.95, 0.9, 0.78), Color(0.55, 0.38, 0.24), Color(0.72, 0.16, 0.13), "火", Color(0.55, 0.8, 1.0), Color(0.36, 0.5, 0.36)],
	"suna": [Color(0.9, 0.8, 0.62), Color(0.66, 0.5, 0.34), Color(0.16, 0.45, 0.38), "風", Color(0.98, 0.84, 0.6), Color(0.72, 0.58, 0.42)],
	"kiri": [Color(0.82, 0.86, 0.88), Color(0.36, 0.4, 0.44), Color(0.18, 0.38, 0.72), "水", Color(0.72, 0.82, 0.9), Color(0.42, 0.5, 0.56)],
	"kumo": [Color(0.95, 0.95, 0.93), Color(0.48, 0.48, 0.52), Color(0.92, 0.74, 0.14), "雷", Color(0.62, 0.78, 0.98), Color(0.5, 0.52, 0.58)],
	"iwa": [Color(0.72, 0.62, 0.5), Color(0.42, 0.32, 0.25), Color(0.58, 0.22, 0.15), "土", Color(0.95, 0.75, 0.55), Color(0.48, 0.38, 0.3)],
}
const KAGE_LINES := {
	"konoha": ["Ateşin İradesi bu köyün her taşında yaşar.", "Bir ninjanın değeri, koruduğu insanlarla ölçülür.", "Kayadaki yüzlere bak... onlar da senin gibi başladı."],
	"suna": ["Çöl acımasızdır; köyümüz onun içinde bir vaha.", "Rüzgâr yön değiştirir ama Suna eğilmez.", "Kum fırtınası çıkmadan görevini bitir."],
	"kiri": ["Sis, gerçeği saklar ama yok etmez.", "Kanlı Sis günleri geride kaldı. Artık köyü birlikte kuruyoruz.", "Suyun sabrını öğren; taşı bile deler."],
	"kumo": ["Bulutların üstünde güç, disiplinle kazanılır!", "Yıldırım tek seferde düşer — sen de öyle hareket et.", "Bu köyde zayıflığa yer yok, ama yoldaşa hep yer var."],
	"iwa": ["Taş sabırlıdır; sen de sabırlı ol.", "Dağ rüzgârla eğilmez, Iwa da baskıyla.", "Sağlam temel, sağlam ninja."],
}


static func kage_name(vid: String) -> String:
	return Kage.KAGE_NAMES.get(vid, Progress.kage_title(vid))


## Kage ofisi: köy temalı geniş oda, büyük manzara penceresi, masa, eski Kage portreleri, ANBU muhafızlar, Kage'nin kendisi
func _kage_office(vid: String) -> void:
	var th: Array = OFFICE.get(vid, OFFICE["konoha"])
	var wall: Color = th[0]
	var floor_c: Color = th[1]
	var acc: Color = th[2]
	var kj: String = th[3]
	var W = 18.0; var D = 15.0; var H = 5.4
	var wood = Color(0.36, 0.23, 0.13)
	var gold = Color(0.85, 0.68, 0.3)
	shell(W, D, H, wall, floor_c)
	# halı: kapıdan masaya köy renginde yol + altın kenar
	bx(0, 0.025, 6.0, 2.8, 0.02, 9.6, acc.darkened(0.1))
	for sx in [-1.0, 1.0]:
		bx(sx * 1.32, 0.03, 6.0, 0.12, 0.02, 9.6, gold)
	bx(0, 0.03, 6.0, 1.2, 0.025, 1.2, gold, false, Vector3(0, 45, 0))
	# --- arka duvar: panoramik pencere (gökyüzü + köy silueti) + çerçeve
	var sky: Color = th[4]
	var ww = 12.0
	gl("box", 0, 3.35, D - 0.03, Vector3(ww, 1.5, 0.04), sky.lightened(0.15))
	gl("box", 0, 2.0, D - 0.03, Vector3(ww, 1.3, 0.04), sky)
	var sil: Color = th[5]
	var srng = RandomNumberGenerator.new()
	srng.seed = hash(vid)
	var x = -ww * 0.5 + 0.4
	while x < ww * 0.5 - 0.4:
		var bw = srng.randf_range(0.4, 1.0)
		var bh = srng.randf_range(0.25, 0.9)
		bx(x + bw * 0.5, 1.35 + bh * 0.5, D - 0.07, bw, bh, 0.02, sil.darkened(srng.randf_range(0.0, 0.2)))
		if srng.randf() < 0.5:
			bx(x + bw * 0.5, 1.35 + bh + 0.07, D - 0.075, bw + 0.15, 0.14, 0.02, sil.darkened(0.3))
		x += bw + srng.randf_range(0.05, 0.3)
	bx(0, 1.3, D - 0.08, ww, 0.1, 0.03, sil.darkened(0.35))
	for k in 9:
		bx(-ww * 0.5 + k * ww / 8.0, 2.7, D - 0.1, 0.14, 2.9, 0.1, wood)
	for yy in [1.25, 2.7, 4.12]:
		bx(0, yy, D - 0.1, ww + 0.14, 0.12, 0.1, wood)
	bx(0, 1.0, D - 0.3, ww + 0.6, 0.12, 0.5, wood)  # pencere pervazı
	# köy amblemi + iki yanda uzun sancak
	cy(0, 4.75, D - 0.08, 1.1, 0.06, acc, 20, Vector3(90, 0, 0))
	cy(0, 4.75, D - 0.06, 1.25, 0.04, gold, 20, Vector3(90, 0, 0))
	_kj(kj, Vector3(0, 4.75, D - 0.13), 0.75, Color(0.98, 0.96, 0.9))
	for sx in [-1.0, 1.0]:
		bx(sx * 7.6, 2.7, D - 0.12, 1.3, 4.2, 0.04, acc)
		bx(sx * 7.6, 4.85, D - 0.15, 1.5, 0.1, 0.1, gold)
		bx(sx * 7.6, 0.55, D - 0.15, 1.5, 0.1, 0.1, gold)
		bx(sx * 7.6, 2.7, D - 0.15, 0.9, 3.2, 0.01, acc.lightened(0.12))
		_kj(kj, Vector3(sx * 7.6, 3.3, D - 0.17), 0.8, Color(0.98, 0.95, 0.88))
		_kj("影", Vector3(sx * 7.6, 2.2, D - 0.17), 0.65, Color(0.98, 0.95, 0.88))
	# --- masa: geniş, köy renginde ön panel; kâğıt yığınları, mühür, mürekkep, fırça, lamba
	var dd = D - 3.6
	bx(0, 0.52, dd, 4.4, 1.04, 1.6, wood, true)
	bx(0, 1.07, dd, 4.6, 0.07, 1.75, wood.lightened(0.18))
	bx(0, 0.55, dd - 0.81, 3.6, 0.7, 0.02, acc)
	cy(0, 0.55, dd - 0.83, 0.5, 0.02, gold, 16, Vector3(90, 0, 0))
	for k in 7:
		var h = rng.randf_range(0.06, 0.22)
		bx(-1.9 + k * 0.28 + rng.randf_range(-0.04, 0.04), 1.1 + h * 0.5, dd + rng.randf_range(-0.35, 0.3), 0.26, h, 0.34, Color(0.97, 0.95, 0.9).darkened(rng.randf_range(0.0, 0.08)))
	cy(1.3, 1.16, dd - 0.2, 0.14, 0.14, Color(0.8, 0.14, 0.12))
	bx(1.75, 1.12, dd - 0.1, 0.4, 0.04, 0.3, Color(0.12, 0.12, 0.14))
	cy(1.95, 1.22, dd + 0.25, 0.1, 0.22, Color(0.3, 0.22, 0.15), 8)
	for k in 3:
		cy(1.92 + k * 0.03, 1.4, dd + 0.25, 0.015, 0.25, Color(0.2, 0.15, 0.1), 4)
	cy(-1.9, 1.32, dd + 0.4, 0.06, 0.5, Color(0.2, 0.2, 0.2), 6)
	gl("sphere", -1.9, 1.62, dd + 0.4, Vector3(0.3, 0.26, 0.3), Color(1.0, 0.9, 0.7))
	lamp(-1.9, 1.7, dd + 0.2, Color(1.0, 0.86, 0.6), 0.8, 4.0)
	# yüksek arkalıklı koltuk
	bx(0, 0.5, D - 1.6, 1.1, 0.12, 0.9, acc.darkened(0.2))
	bx(0, 1.35, D - 1.15, 1.1, 1.7, 0.14, acc.darkened(0.2))
	bx(0, 2.25, D - 1.15, 1.25, 0.12, 0.2, gold)
	for sx in [-1.0, 1.0]:
		bx(sx * 0.6, 0.7, D - 1.6, 0.12, 0.5, 0.9, wood)
	# --- sol duvar: eski Kage portreleri (çerçeve, renkli arka plan, siluet, şapka, isim plakası)
	for k in 4:
		var pd = 3.4 + k * 2.6
		var px = -W * 0.5 + 0.06
		bx(px, 3.25, pd, 0.06, 1.7, 1.35, gold.darkened(0.2))
		bx(px + 0.03, 3.25, pd, 0.04, 1.5, 1.15, acc.lightened(0.35).lerp(Color(0.9, 0.88, 0.8), 0.5))
		sp(px + 0.06, 3.5, pd, Vector3(0.04, 0.42, 0.36), Color(0.25, 0.22, 0.2))
		bx(px + 0.06, 2.95, pd, 0.04, 0.5, 0.8, Color(0.92, 0.92, 0.9))
		bx(px + 0.08, 3.74, pd, 0.03, 0.12, 0.66, Color(0.95, 0.95, 0.93))
		bx(px + 0.09, 3.84, pd, 0.03, 0.1, 0.36, acc)
		bx(px + 0.05, 2.25, pd, 0.04, 0.16, 0.7, gold)
	# --- sağ duvar: parşömen rafları + çerçeveli harita
	shelf(W * 0.5 - 0.3, 4.2, 3.6, 2.2, -1.0, [Color(0.95, 0.9, 0.75), acc, Color(0.3, 0.4, 0.6), Color(0.85, 0.82, 0.7)], 0.45)
	shelf(W * 0.5 - 0.3, 10.8, 3.2, 2.2, -1.0, [Color(0.95, 0.9, 0.75), Color(0.55, 0.3, 0.25), acc], 0.45)
	var mx = W * 0.5 - 0.06
	bx(mx, 3.0, 7.5, 0.06, 1.8, 2.6, wood)
	bx(mx - 0.03, 3.0, 7.5, 0.04, 1.6, 2.4, Color(0.93, 0.87, 0.7))
	for k in 6:
		sp(mx - 0.06, 2.6 + rng.randf() * 0.8, 6.6 + rng.randf() * 1.8, Vector3(0.03, rng.randf_range(0.2, 0.45), rng.randf_range(0.3, 0.6)), [Color(0.45, 0.62, 0.35), Color(0.75, 0.62, 0.4), Color(0.4, 0.55, 0.75)][k % 3])
	# --- misafir köşesi: alçak masa, minderler, çay takımı
	low_table(-5.6, 3.6, 1.6, 1.0)
	for c in [[-6.6, 3.6], [-4.6, 3.6], [-5.6, 2.6], [-5.6, 4.6]]:
		cushion(c[0], c[1], acc.darkened(0.15))
	cy(-5.6, 0.45, 3.6, 0.18, 0.18, Color(0.3, 0.42, 0.35), 10)
	for k in 3:
		cy(-6.0 + k * 0.4, 0.41, 3.9, 0.09, 0.1, Color(0.92, 0.9, 0.85), 8)
	# --- sağ ön: görev kayıt masası (memur)
	counter(5.6, 3.4, 2.8, wood)
	for k in 5:
		cy(4.6 + k * 0.45, 1.12, 3.4, 0.12, 0.3, Color(0.95, 0.92, 0.82), 8, Vector3(0, 0, 90))
	# --- köşelerde bitki, tavanda vurgu halkası, fenerler
	for c in [[-W * 0.5 + 0.8, D - 0.9], [W * 0.5 - 0.8, D - 0.9], [-W * 0.5 + 0.8, 0.9]]:
		plant(c[0], c[1])
	cy(0, H - 0.05, D * 0.5, 4.0, 0.08, acc, 24)
	cy(0, H - 0.1, D * 0.5, 3.2, 0.08, gold, 24)
	for c in [[-4.0, 7.0], [4.0, 7.0], [-4.0, 12.0], [4.0, 12.0]]:
		paper_lantern(c[0], H - 1.0, c[1], Color(1.0, 0.88, 0.65))
	lamp(0, H - 0.6, 3.5, Color(1.0, 0.94, 0.85), 1.4, 11.0)
	lamp(0, H - 0.6, 10.5, Color(1.0, 0.94, 0.85), 1.5, 11.0)
	# --- insanlar: Kage (oyuncu bu köyün Kage'si değilse), ANBU muhafızlar, memur
	var title = Progress.kage_title(vid)
	var player_is_kage = Kage.is_kage() and Progress.home() == vid
	var kn = kage_name(vid)
	if player_is_kage:
		person("keeper", 2.4, D - 2.2, -30.0, "Kıdemli Danışman", ["Masan seni bekliyor, %s-sama." % title, "Konsey raporları masanın sağında.", "Bugün üç diplomatik mektup geldi."])
	else:
		person("keeper", 0, D - 2.15, 0.0, kn, KAGE_LINES.get(vid, KAGE_LINES["konoha"]), {"look_extra": KageAttire.look(vid), "kage_vid": vid})
	var masks = ["anbu_kedi", "anbu_kurt", "anbu_kus", "anbu_ayi"]
	for sx in [-1.0, 1.0]:
		var mk = masks[(absi(hash(vid)) + int(sx + 1.0)) % masks.size()]
		person("guard", sx * 4.6, D - 1.2, sx * 25.0, "ANBU Muhafız", ["...", "%s-sama'nın güvenliği bizden sorulur." % title, "Masaya fazla yaklaşma."],
			{"look_extra": {"face_style": mk, "facegear": Color(0.96, 0.96, 0.94), "vest": Color(0.62, 0.62, 0.64), "top": Color(0.12, 0.12, 0.15), "top2": Color(0.12, 0.12, 0.15),
				"pants": Color(0.12, 0.12, 0.15), "top_style": "kolsuz", "band": null}})
	var clerk = "Raporlar sıraya kondu, efendim." if player_is_kage else "%s seni bekliyor; görevleri bizzat dağıtır." % kn
	person("keeper", 5.6, 4.3, 0.0, "Görev Kayıt Memuru", [clerk, "Raporunu teslim etmeyi unutma.", "Bugün D-rank çok, kediler yine kaçmış..."])
	var lbl = "[F] Kage masana geç" if player_is_kage else "[F] %s ile konuş (görevler)" % kn
	act(0, D - 5.2, 2.8, "mission_board", lbl, {"giver": kn, "vid": vid, "kage_office": true})


## İç mekân kanjisi (ön yüzü kapıya bakar)
func _kj(text: String, p: Vector3, size: float, col: Color) -> void:
	var l = Label3D.new()
	l.text = text
	l.font = KageAttire._font()
	l.font_size = 96
	l.pixel_size = size / 96.0
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	room.add_child(l)
	l.global_position = L(p.x, p.y, p.z)
	l.rotation.y = 0.0  # Label3D +Z yönüne bakar: kapıdan bakana dönük


func _weapon_shop() -> void:
	var W = 9.0; var D = 9.0; var H = 3.4
	shell(W, D, H, Color(0.86, 0.8, 0.68), Color(0.5, 0.36, 0.24))
	counter(0, D - 2.6, 5.0, Color(0.42, 0.28, 0.17))
	# arka duvar silah raflı panolar: gerçek silah modelleri
	for side in [-1.0, 1.0]:
		bx(side * (W * 0.5 - 0.05), 1.7, D * 0.5, 0.05, 2.2, D - 2.0, Color(0.38, 0.26, 0.16))
	var wids = ["kunai", "tanto", "katana", "musta", "tonfa", "yelpaze"]
	for k in 6:
		var wm = CharacterModel.weapon_mesh(wids[k])
		var mi = MeshInstance3D.new()
		mi.mesh = wm
		room.add_child(mi)
		var side = -1.0 if k < 3 else 1.0
		var d = 2.2 + (k % 3) * 2.0
		mi.global_position = L(side * (W * 0.5 - 0.15), 1.9, d)
		mi.rotation = Vector3(0, PI * 0.5 * side, PI * 0.5)
	# kunai/shuriken kutuları tezgâhta
	for k in 5:
		bx(-2.0 + k * 1.0, 1.12, D - 2.6, 0.6, 0.12, 0.4, Color(0.3, 0.3, 0.33))
		for q in 3:
			cy(-2.2 + k * 1.0 + q * 0.18, 1.2, D - 2.6, 0.1, 0.02, Color(0.75, 0.77, 0.8), 4)
	# zırh mankeni + varil içinde sopalar
	for x in [-W * 0.5 + 1.2, W * 0.5 - 1.2]:
		cy(x, 0.75, D - 1.0, 0.1, 1.5, Color(0.35, 0.25, 0.15), 6)
		bx(x, 1.3, D - 1.0, 0.6, 0.6, 0.35, Color(0.38, 0.48, 0.28))
		sp(x, 1.75, D - 1.0, Vector3(0.25, 0.28, 0.25), Color(0.85, 0.8, 0.7))
	cy(2.8, 0.45, 1.6, 0.6, 0.9, Color(0.45, 0.3, 0.18))
	for k in 5:
		cy(2.7 + (k % 3) * 0.12, 1.1, 1.55 + (k / 3) * 0.15, 0.05, 1.4, Color(0.35, 0.25, 0.15), 5, Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8)))
	scroll(0, 2.3, D - 0.05, 0.0, Color(0.9, 0.85, 0.75))
	lamp(0, H - 0.5, 3.0, Color(1.0, 0.85, 0.6), 1.3, 9.0)
	lamp(0, H - 0.5, 7.0, Color(1.0, 0.85, 0.6), 1.2, 9.0)
	person("keeper", 0, D - 1.7, 0.0, "Silahçı Tetsuo", ["Bu kunailer Demir Ülkesi çeliği!", "Katana mı? Önce Chunin ol evlat.", "Patlayıcı etiketleri yeni geldi."])
	person("customer", -2.4, 3.5, -60.0)
	act(0, D - 3.4, 2.2, "shop_weapons", "[F] Silahçıyla konuş (alet, silah, zırh)")


func _pharmacy() -> void:
	var W = 8.0; var D = 8.0; var H = 3.3
	shell(W, D, H, Color(0.95, 0.94, 0.9), Color(0.6, 0.48, 0.34))
	counter(0, D - 2.4, 4.0, Color(0.55, 0.42, 0.28))
	shelf(0, D - 0.3, 6.0, 2.2, 0.0, [Color(0.4, 0.75, 0.45), Color(0.85, 0.85, 0.9), Color(0.75, 0.4, 0.3), Color(0.9, 0.8, 0.4), Color(0.45, 0.55, 0.8)])
	shelf(-W * 0.5 + 0.3, D * 0.5 - 0.5, 3.0, 1.6, 1.0, [Color(0.6, 0.45, 0.3), Color(0.35, 0.6, 0.35), Color(0.85, 0.82, 0.7)])
	# kurutulmuş otlar tavandan
	for k in 7:
		var x = -2.4 + k * 0.8
		bx(x, H - 0.45, 2.2, 0.02, 0.5, 0.02, Color(0.3, 0.25, 0.2))
		sp(x, H - 0.8, 2.2, Vector3(0.25, 0.35, 0.25), Color(0.35, 0.55, 0.25).darkened(rng.randf_range(0, 0.3)))
	# havan + terazi tezgâhta
	cy(-1.2, 1.15, D - 2.4, 0.3, 0.2, Color(0.5, 0.5, 0.52))
	bx(1.0, 1.15, D - 2.4, 0.5, 0.06, 0.06, Color(0.75, 0.62, 0.3))
	cy(0.78, 1.1, D - 2.4, 0.18, 0.03, Color(0.75, 0.62, 0.3))
	cy(1.22, 1.1, D - 2.4, 0.18, 0.03, Color(0.75, 0.62, 0.3))
	lamp(0, H - 0.5, 3.5, Color(1.0, 0.95, 0.85), 1.3, 9.0)
	person("keeper", 0, D - 1.6, 0.0, "Eczacı Yumi", ["Asker hapları çok güçlü, dikkatli kullan.", "Merhem yaralara iyi gelir.", "Taze şifalı otlar geldi!"])
	act(0, D - 3.2, 2.2, "shop_items", "[F] Eczacıyla konuş (merhem, haplar)")


func _tailor() -> void:
	var W = 9.0; var D = 9.0; var H = 3.4
	shell(W, D, H, Color(0.96, 0.9, 0.84), Color(0.58, 0.42, 0.3))
	counter(1.5, D - 2.5, 3.6, Color(0.5, 0.35, 0.22))
	# kumaş topları rafı (renkli silindirler yatay)
	var cols = [Color(0.95, 0.5, 0.12), Color(0.15, 0.2, 0.33), Color(0.38, 0.48, 0.28), Color(0.75, 0.15, 0.15), Color(0.35, 0.25, 0.45), Color(0.85, 0.82, 0.75), Color(0.15, 0.4, 0.45), Color(0.12, 0.12, 0.14)]
	for r in 3:
		bx(-W * 0.5 + 0.3, 0.6 + r * 0.7, D * 0.5, 0.5, 0.05, D - 2.0, Color(0.45, 0.31, 0.19))
		for k in 8:
			cy(-W * 0.5 + 0.35, 0.78 + r * 0.7, 1.6 + k * 0.75, 0.3, 0.6, cols[(k + r * 3) % cols.size()], 10, Vector3(0, 0, 90))
	# mankenler (giydirilmiş ninja kıyafetleri)
	for k in 3:
		var x = 0.6 + k * 1.3
		var c: Color = cols[k * 2]
		cy(x, 0.5, 2.6, 0.1, 1.0, Color(0.35, 0.25, 0.15), 6)
		cy(x, 0.1, 2.6, 0.5, 0.1, Color(0.35, 0.25, 0.15), 10)
		bx(x, 1.35, 2.6, 0.62, 0.7, 0.34, c)
		bx(x, 0.95, 2.6, 0.55, 0.25, 0.3, c.darkened(0.3))
		for sx in [-1.0, 1.0]:
			bx(x + sx * 0.38, 1.3, 2.6, 0.14, 0.62, 0.16, c)
		sp(x, 1.85, 2.6, Vector3(0.24, 0.28, 0.24), Color(0.9, 0.85, 0.75))
	# masa: makas + kumaş
	bx(1.5, 1.08, D - 2.5, 1.2, 0.02, 0.6, Color(0.85, 0.3, 0.3))
	scroll(-1.5, 2.3, D - 0.05, 0.0, Color(0.95, 0.88, 0.8))
	lamp(0, H - 0.5, 3.0, Color(1.0, 0.9, 0.75), 1.3, 9.0)
	lamp(0, H - 0.5, 7.0, Color(1.0, 0.9, 0.75), 1.1, 9.0)
	person("keeper", 1.5, D - 1.6, 0.0, "Terzi Kaede", ["Her ninjanın kendine özgü bir stili olmalı!", "Bu yelek kumaşı kunai'ye dayanır.", "Renk mi? Dilediğin rengi boyarım."])
	person("customer", -1.2, 4.0, 90.0)
	act(1.5, D - 3.3, 2.2, "tailor", "[F] Terziyle konuş (kıyafet ve zırh)")


func _bbq() -> void:
	var W = 12.0; var D = 12.0; var H = 3.4
	shell(W, D, H, Color(0.86, 0.74, 0.58), Color(0.42, 0.3, 0.2))
	var seat_cols = [Color(0.7, 0.2, 0.15), Color(0.6, 0.18, 0.14)]
	for row in 2:
		for col in 3:
			var x = -3.5 + col * 3.5
			var d = 3.4 + row * 3.6
			# ızgaralı masa: masa + ortada ızgara + kızgın kömür parıltısı + duman
			bx(x, 0.72, d, 1.6, 0.08, 1.2, Color(0.35, 0.22, 0.12), true)
			cy(x, 0.78, d, 0.5, 0.06, Color(0.2, 0.2, 0.22), 12)
			gl("cyl", x, 0.8, d, Vector3(0.42, 0.02, 0.42), Color(1.0, 0.45, 0.15))
			for q in 4:
				bx(x - 0.15 + q * 0.1, 0.83, d, 0.06, 0.02, 0.18, Color(0.55, 0.25, 0.2))
			for sx in [-1.0, 1.0]:
				bench(x, d + sx * 0.95, 1.6)
			_smoke(x, 0.9, d)
			if rng.randf() < 0.7:
				person("customer", x - 0.4, d - 0.95, 0.0, "", [], {"eat_mode": true})
			if rng.randf() < 0.5:
				person("customer", x + 0.4, d + 0.95, 180.0, "", [], {"eat_mode": true})
	# mutfak tezgâhı + davul fenerler
	counter(0, D - 1.0, 6.0, Color(0.4, 0.26, 0.15))
	for k in 4:
		paper_lantern(-4.5 + k * 3.0, H - 0.7, 1.6, Color(1.0, 0.55, 0.35))
	lamp(0, H - 0.6, 4.0, Color(1.0, 0.7, 0.45), 1.4, 11.0)
	lamp(0, H - 0.6, 9.0, Color(1.0, 0.7, 0.45), 1.2, 11.0)
	person("keeper", 0, D - 0.4, 0.0, "Garson", ["Yakiniku seti hazır! Taze sığır eti!", "Bir porsiyon daha mı?", "Akimichi'ler gelince et yetmiyor!"])
	act(0, D - 1.9, 2.4, "bbq", "[F] Barbekü (Yakiniku) ye — 80 Ryō")


func _smoke(x: float, y: float, d: float) -> void:
	var p = GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 2.2
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, 0.15, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var grad = Gradient.new()
	grad.set_color(0, Color(0.85, 0.85, 0.85, 0.35))
	grad.set_color(1, Color(0.9, 0.9, 0.9, 0.0))
	var gt = GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var q = QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	q.material = m
	p.draw_pass_1 = q
	room.add_child(p)
	p.global_position = L(x, y, d)


func _hospital() -> void:
	var W = 13.0; var D = 13.0; var H = 3.6
	shell(W, D, H, Color(0.97, 0.97, 0.95), Color(0.75, 0.75, 0.72))
	# resepsiyon
	counter(-3.5, 2.8, 3.0, Color(0.85, 0.85, 0.82))
	bx(-3.5, 2.6, 2.8 + 0.42, 3.0, 0.4, 0.04, Color(0.75, 0.25, 0.22))
	# yataklar + perdeler
	for k in 4:
		var d = 4.5 + k * 2.1
		var x = 3.6
		bx(x, 0.45, d, 2.0, 0.12, 0.95, Color(0.55, 0.55, 0.6), true)
		bx(x, 0.58, d, 1.95, 0.14, 0.9, Color(0.97, 0.97, 0.98))
		bx(x + 0.75, 0.7, d, 0.4, 0.12, 0.6, Color(1, 1, 1))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				bx(x + sx * 0.92, 0.22, d + sz * 0.42, 0.05, 0.44, 0.05, Color(0.6, 0.6, 0.65))
		bx(x - 1.3, 1.6, d + 0.9, 0.04, 2.6, 0.04, Color(0.7, 0.7, 0.72))
		bx(x - 1.3, 1.5, d + 0.6, 0.02, 1.8, 0.65, Color(0.78, 0.88, 0.9))
		if k % 2 == 0:
			person("patient", x - 1.15, d, -90.0, "Hasta", ["Bir görevde kolumu kırdım...", "Tıbbi ninjalar mucize yaratıyor."])
	shelf(-W * 0.5 + 0.3, 8.5, 4.0, 1.6, 1.0, [Color(0.95, 0.95, 0.95), Color(0.5, 0.75, 0.55), Color(0.8, 0.4, 0.35)])
	for k in 3:
		plant(-W * 0.5 + 0.6 + k * 0.0, 4.5 + k * 0.0)
	lamp(0, H - 0.5, 3.5, Color(0.95, 0.98, 1.0), 1.4, 12.0)
	lamp(0, H - 0.5, 9.5, Color(0.95, 0.98, 1.0), 1.4, 12.0)
	person("keeper", -3.5, 3.6, 0.0, "Resepsiyon Hemşiresi", ["Yaralı mısın? Hemen bakalım.", "Lütfen koridorda koşmayın!"])
	person("nurse", 0.5, 7.0, 90.0, "Tıbbi Ninja", ["Chakra dolaşımın düzgün.", "Dinlenmen lazım."], {"wander_r": 3.0})
	act(-3.5, 1.9, 2.2, "hospital", "[F] Hastane: iyileş (ücretsiz)")
	act(0.5, 6.0, 1.8, "trainer", "[F] Tıbbi ninja: tıbbi jutsu öğren", {"kinds": ["hospital"], "title": "Tıbbi Ninja Eğitmeni"})


func _home(player_home: bool) -> void:
	var W = 8.0 + rng.randf_range(-1.0, 1.0); var D = 8.0 + rng.randf_range(-1.0, 1.5); var H = 3.0
	var walls = [Color(0.94, 0.9, 0.8), Color(0.9, 0.86, 0.74), Color(0.96, 0.93, 0.86)]
	shell(W, D, H, walls[rng.randi() % walls.size()], Color(0.6, 0.45, 0.3))
	# giriş basamağı (genkan) + tatami odası
	bx(0, 0.06, 1.0, 1.8, 0.12, 1.2, Color(0.45, 0.42, 0.4))
	tatami(-W * 0.5 + 0.6, 2.6, int(W / 0.95) - 1, 2)
	low_table(0, D * 0.5 + 0.5)
	for k in 4:
		var a = k * PI * 0.5
		cushion(sin(a) * 0.95, D * 0.5 + 0.5 + cos(a) * 0.75, [Color(0.55, 0.2, 0.22), Color(0.2, 0.3, 0.55), Color(0.3, 0.5, 0.3)][k % 3])
	cy(0.2, 0.42, D * 0.5 + 0.5, 0.12, 0.14, Color(0.3, 0.45, 0.35))  # çaydanlık
	# tokonoma: parşömen + vazo
	bx(W * 0.25, 0.1, D - 0.35, 1.6, 0.2, 0.6, Color(0.45, 0.3, 0.18))
	scroll(W * 0.25, 1.6, D - 0.05, 0.0, [Color(0.95, 0.93, 0.86), Color(0.9, 0.85, 0.95)][rng.randi() % 2])
	cy(W * 0.25 + 0.5, 0.4, D - 0.35, 0.2, 0.4, Color(0.3, 0.4, 0.6))
	sp(W * 0.25 + 0.5, 0.75, D - 0.35, Vector3(0.3, 0.35, 0.3), Color(0.85, 0.35, 0.45))
	# dolap + çekmeceler
	bx(-W * 0.5 + 0.4, 0.8, D - 1.0, 0.7, 1.6, 1.4, Color(0.48, 0.32, 0.19), true)
	for k in 3:
		bx(-W * 0.5 + 0.77, 0.35 + k * 0.5, D - 1.0, 0.02, 0.06, 0.5, Color(0.25, 0.18, 0.1))
	paper_lantern(0, H - 0.6, D * 0.5)
	lamp(0, H - 0.8, D * 0.5, Color(1.0, 0.82, 0.55), 1.2, 9.0)
	if player_home:
		# futon yatak + çalışma masası + bitki (oyuncunun evi)
		bx(W * 0.5 - 1.2, 0.1, 3.4, 1.1, 0.2, 2.1, Color(0.95, 0.95, 0.98), true)
		bx(W * 0.5 - 1.2, 0.22, 3.0, 1.12, 0.06, 1.4, Color(0.25, 0.4, 0.7))
		bx(W * 0.5 - 1.2, 0.24, 4.2, 0.6, 0.12, 0.35, Color(1, 1, 1))
		low_table(-W * 0.5 + 1.2, D - 2.4, 1.0, 0.6)
		bx(-W * 0.5 + 1.2, 0.42, D - 2.4, 0.4, 0.04, 0.3, Color(0.95, 0.93, 0.85))
		plant(W * 0.5 - 0.5, D - 0.6)
		act(W * 0.5 - 1.2, 3.4, 1.6, "bed", "[F] Uyu (sabaha kadar, kaydet)")
		act(-W * 0.5 + 1.2, D - 2.4, 1.4, "home_note", "[F] Masadaki notlara bak")
	else:
		var fam = rng.randi_range(1, 3)
		person("sitter", 0.95, D * 0.5 + 0.5, 90.0, "Ev Sahibi", ["Hoş geldin! Çay ister misin?", "Ninjalar köyü koruduğu için huzurluyuz.", "Oğlum da akademiye gidiyor."], {"floor_sit": true})
		if fam > 1:
			person("sitter", -0.95, D * 0.5 + 0.5, -90.0, "", [], {"floor_sit": true})
		if fam > 2:
			person("kid", 1.5, 3.0, 0.0, "", [], {"wander_r": 1.5})


func _teahouse() -> void:
	var W = 10.0; var D = 9.0; var H = 3.2
	shell(W, D, H, Color(0.93, 0.86, 0.72), Color(0.5, 0.36, 0.22))
	counter(0, D - 1.6, 4.0, Color(0.45, 0.3, 0.18))
	# vitrinde renkli dango şişleri
	for k in 6:
		var x = -1.5 + k * 0.6
		bx(x, 1.18, D - 1.6, 0.02, 0.32, 0.02, Color(0.8, 0.7, 0.5))
		for q in 3:
			sp(x, 1.1 + q * 0.09, D - 1.6, Vector3(0.09, 0.09, 0.09), [Color(1.0, 0.75, 0.8), Color(1, 1, 0.95), Color(0.6, 0.85, 0.5)][q])
	for k in 3:
		var d = 2.4 + k * 1.7
		low_table(-2.8, d, 1.2, 0.8)
		cushion(-3.7, d)
		cushion(-1.9, d)
		bench(2.8, d, 1.8)
		if rng.randf() < 0.6:
			person("customer", 2.8, d - 0.35, 0.0, "", [], {"eat_mode": true})
	paper_lantern(-2.8, H - 0.6, 3.0, Color(1.0, 0.75, 0.5))
	paper_lantern(2.8, H - 0.6, 5.0, Color(1.0, 0.75, 0.5))
	scroll(-3.5, 1.8, D - 0.05, 0.0, Color(0.95, 0.9, 0.8))
	plant(W * 0.5 - 0.5, D - 0.5)
	lamp(0, H - 0.5, 4.0, Color(1.0, 0.82, 0.6), 1.3, 10.0)
	person("keeper", 0, D - 0.9, 0.0, "Çay Evi Sahibi", ["Üç renkli dango, en sevilenimiz!", "Yeşil çay taze demlendi.", "Görevden döndün mü? Otur biraz."])
	act(0, D - 2.5, 2.2, "teahouse", "[F] Dango ve çay (20 Ryō)")


func _inn() -> void:
	var W = 12.0; var D = 11.0; var H = 3.4
	shell(W, D, H, Color(0.9, 0.84, 0.7), Color(0.48, 0.34, 0.22))
	counter(-3.0, 3.0, 2.8, Color(0.42, 0.28, 0.17))
	bx(-3.0, 1.12, 3.0, 0.5, 0.08, 0.35, Color(0.92, 0.9, 0.85))
	# anahtar panosu
	bx(-3.0, 1.9, 3.0 + 0.9, 1.6, 0.8, 0.04, Color(0.45, 0.3, 0.18))
	for k in 8:
		cy(-3.6 + (k % 4) * 0.4, 1.7 + (k / 4) * 0.35, 3.0 + 0.86, 0.05, 0.12, Color(0.75, 0.62, 0.3))
	# shoji bölmeli misafir odası (sağ): tatami + futon
	tatami(1.0, 4.0, 5, 3)
	for k in 3:
		bx(1.2 + k * 1.6, 0.12, 6.0, 0.9, 0.12, 2.0, Color(0.95, 0.95, 0.98))
		bx(1.2 + k * 1.6, 0.2, 5.5, 0.92, 0.05, 1.2, [Color(0.6, 0.25, 0.3), Color(0.25, 0.35, 0.6), Color(0.35, 0.5, 0.35)][k])
	for k in 5:
		bx(0.6, 1.0, 3.7 + k * 1.2, 0.05, 2.0, 1.1, Color(1.0, 0.97, 0.9))
		bx(0.6, 1.0, 3.7 + k * 1.2 - 0.57, 0.08, 2.0, 0.05, Color(0.4, 0.27, 0.16))
	# lobi: alçak masa + yastıklar + bitki
	low_table(-3.0, 7.5)
	cushion(-3.9, 7.5)
	cushion(-2.1, 7.5)
	plant(-W * 0.5 + 0.6, D - 0.6)
	scroll(-3.0, 1.9, D - 0.05, 0.0, Color(0.95, 0.92, 0.85))
	for k in 3:
		paper_lantern(-4.5 + k * 4.5, H - 0.6, D * 0.5)
	lamp(-2, H - 0.6, 4.0, Color(1.0, 0.82, 0.58), 1.3, 11.0)
	lamp(3, H - 0.6, 7.0, Color(1.0, 0.82, 0.58), 1.1, 10.0)
	person("keeper", -3.0, 3.8, 0.0, "Han Sahibi", ["Yorgun yolcuya sıcak oda!", "Kaplıcamız yok ama futonlarımız yumuşak.", "Bir gece 30 Ryō."])
	person("sitter", -3.9, 7.5, 90.0, "Yolcu", ["Suna'dan geldim, yol çok uzundu.", "Bu köyde yemekler harika."], {"floor_sit": true})
	act(-3.0, 2.1, 2.2, "inn_sleep", "[F] Han sahibiyle konuş (yemek, oda)")
