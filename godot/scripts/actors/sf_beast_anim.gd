class_name SFBeastAnim
extends Node
## İskeletsiz hayran yapımı canavar modelini (Shukaku, Kurama...) canlandırır: BeastRig'in durumunu (yürüyüş, kükreme,
## pençe, tepme, kuyruk süpürme, top, diz çökme) okuyup beast.gdshader'ın bölgesel deformasyonunu sürer
## (kuyruklar ayrı evrelerle dalgalanır, göğüs nefes alır, baş hedefe döner, bacaklar adım atar, kol savrulur),
## gövdeyi sallar/eğer/atılır ve her kare ayak izini araziye oturtur (havada durmaz, eğime yatar). Adımda toz kalkar.

var rig: BeastRig
var holder: Node3D
var mats: Array = []
var size := Vector3.ONE
var H := 10.0
var zf := -5.0
var zb := 5.0
var hw := 3.0
var regions := Vector4(0.62, 0.28, 0.3, 0.55)
var t := 0.0
var gait := 0.0
var pitch := 0.0
var yaw := 0.0
var lunge := 0.0
var lift := 0.0
var g_off := 0.0
var slope := Vector2.ZERO
var head := Vector2.ZERO
var mouth: Node3D
var last_step := 0.0
var _gt := 0.0


func setup(r: BeastRig, h: Node3D, sz: Vector3, reg: Vector4) -> void:
	rig = r
	holder = h
	size = sz
	H = sz.y
	zf = -sz.z * 0.5
	zb = sz.z * 0.5
	hw = sz.x * 0.5
	regions = reg
	for mi in holder.find_children("*", "MeshInstance3D", true, false):
		mi.extra_cull_margin = H * 0.35   # deformasyon AABB dışına taşar
		if mi.mesh == null:
			continue
		for si in mi.mesh.get_surface_count():
			var m = mi.get_surface_override_material(si)
			if m is ShaderMaterial and not m in mats:
				mats.append(m)
	for m in mats:
		m.set_shader_parameter("deform", true)
		m.set_shader_parameter("dims", Vector4(H, zf, zb, hw))
		m.set_shader_parameter("regions", regions)
	# ağız: modelin kendi başının önünde (top/nefes buradan çıkar)
	mouth = Node3D.new()
	mouth.name = "SFMouth"
	holder.add_child(mouth)
	mouth.position = Vector3(0, H * (regions.w + 0.14), zf + (zb - zf) * 0.04)
	rig.mouth = mouth


func _target() -> Node3D:
	var b = rig.get_parent()
	if b is TailedBeast and b.aggro and Game.player:
		return Game.player
	return null


func _process(dt: float) -> void:
	if not is_instance_valid(rig) or not is_instance_valid(holder) or not holder.is_inside_tree():
		return
	t += dt
	var walk: float = rig.move_speed
	gait += dt * (1.6 + 1.2 * walk) * (1.0 if walk > 0.02 else 0.0)
	var a: String = rig.action
	var k: float = rig.action_k()
	var s := sin(k * PI)
	var want_p := 0.0
	var want_y := 0.0
	var want_l := 0.0
	var want_up := absf(sin(gait)) * 0.012 * H * walk
	var sweep := 0.0
	var sw := Vector2.ZERO
	var roar := 0.0
	var hp := sin(t * 0.5) * 0.04
	match a:
		"roar":
			want_p = 0.1 * s
			hp = 0.45 * s
			roar = s
		"stomp":
			want_up += (sin(k * PI / 0.6) * 0.07 * H) if k < 0.6 else 0.0
			want_p = 0.08 * s if k < 0.6 else -0.05 * (1.0 - k)
			if k > 0.55 and last_step < 0.55:
				_dust(Vector3(hw * 0.5, 0, zf * 0.3), 2.0)
		"swipe_l", "swipe_r":
			var side = 1.0 if a == "swipe_l" else -1.0
			want_y = side * 0.2 * s
			want_l = -0.05 * (zb - zf) * s
			sw = Vector2(side, sin(minf(1.0, k * 1.4) * PI))
		"charge":
			want_l = -0.12 * (zb - zf) * s
			want_p = -0.08 * s
		"ball":
			want_p = 0.06 if k < 0.7 else -0.05
			hp = 0.25 if k < 0.75 else -0.1
			roar = 0.6 * s
		"tail":
			want_y = sin(k * TAU) * 0.55
			sweep = sin(k * TAU)
		"kneel":
			want_up -= minf(1.0, rig.action_t * 1.2) * 0.12 * H
			want_p = -0.16
			hp = -0.3
	last_step = k
	var f = minf(1.0, dt * 6.0)
	pitch = lerpf(pitch, want_p, f)
	yaw = lerp_angle(yaw, want_y, f)
	lunge = lerpf(lunge, want_l, f)
	lift = lerpf(lift, want_up, minf(1.0, dt * 10.0))
	# baş hedefe döner
	var hy := sin(t * 0.3) * 0.12
	var tg = _target()
	if tg and is_instance_valid(tg):
		var lv = holder.global_transform.affine_inverse() * tg.global_position
		hy = clampf(atan2(-lv.x, -lv.z), -0.6, 0.6)
	head = head.lerp(Vector2(hp, hy - yaw * 0.5), minf(1.0, dt * 4.0))
	# zemine oturtma: ayak izinin en alçak noktası + eğime yatma
	_gt -= dt
	if _gt <= 0.0:
		_gt = 0.1
		_ground()
	var bx = Basis.from_euler(Vector3(pitch + slope.x, yaw, slope.y))
	holder.transform = Transform3D(bx, Vector3(0, lift + g_off, lunge))
	# adım tozu
	if walk > 0.3 and int((gait - dt * (1.6 + 1.2 * walk)) / PI) != int(gait / PI):
		_dust(Vector3((hw * 0.5) * (1.0 if int(gait / PI) % 2 == 0 else -1.0), 0, zf * 0.25), 1.0)
	var to_b = Projection(holder.global_transform.affine_inverse())
	var from_b = Projection(holder.global_transform)
	var tail_amp = 0.07 + 0.04 * walk + (0.06 if a in ["roar", "ball"] else 0.0)
	for m in mats:
		m.set_shader_parameter("to_beast", to_b)
		m.set_shader_parameter("from_beast", from_b)
		m.set_shader_parameter("anim_t", t)
		m.set_shader_parameter("walk", walk)
		m.set_shader_parameter("gait", gait)
		m.set_shader_parameter("tail_amp", tail_amp)
		m.set_shader_parameter("tail_sweep", sweep)
		m.set_shader_parameter("head_rot", head)
		m.set_shader_parameter("roar", roar)
		m.set_shader_parameter("breath", sin(t * 1.3) * 0.02)
		m.set_shader_parameter("swipe", sw)
	# ağız düğümü başla birlikte döner
	if mouth:
		var piv = Vector3(0, H * regions.w, zf + (zb - zf) * (regions.z + 0.05))
		var mp = Vector3(0, H * (regions.w + 0.14), zf + (zb - zf) * 0.04) - piv
		mouth.position = piv + Basis.from_euler(Vector3(head.x, head.y, 0)) * mp


## Ayak izi köşelerinde arazi yüksekliği: en alçak noktaya iner (hiçbir ayak havada kalmaz), ön-arka / sağ-sol eğime yatar
func _ground() -> void:
	var r: Node3D = rig
	var o = r.global_position
	var xf = r.global_transform
	var pts = [Vector3(0, 0, zf * 0.7), Vector3(0, 0, zb * 0.5), Vector3(hw * 0.7, 0, 0), Vector3(-hw * 0.7, 0, 0), Vector3.ZERO]
	var hs = []
	for p in pts:
		var w = xf * p
		hs.append(Game.ground_height(w.x, w.z))
	var lo = hs.min()
	g_off = lerpf(g_off, clampf(lo - o.y, -H * 0.25, H * 0.05), 0.5)
	var sp = clampf(atan2(float(hs[1]) - float(hs[0]), maxf(1.0, zb * 0.5 - zf * 0.7)), -0.3, 0.3) * 0.7
	var sr = clampf(atan2(float(hs[3]) - float(hs[2]), maxf(1.0, hw * 1.4)), -0.3, 0.3) * 0.7
	slope = slope.lerp(Vector2(-sp, sr), 0.4)


func _dust(local: Vector3, k: float) -> void:
	if not is_instance_valid(holder) or Game.player == null:
		return
	var w = holder.global_transform * local
	w.y = Game.ground_height(w.x, w.z)
	if w.distance_to(Game.player.global_position) > 400.0:
		return
	VFX.puffs(w + Vector3.UP * H * 0.02, {"amount": int(10 * k), "life": 1.2, "size": H * 0.05 * k, "radius": H * 0.04, "vmin": 2, "vmax": 6 * k, "dir": Vector3.UP, "spread": 80.0,
		"gravity": Vector3(0, -2, 0), "colors": [Color(0.8, 0.72, 0.6, 0.9), Color(0.7, 0.62, 0.5, 0)]})
	if Game.world and w.distance_to(Game.player.global_position) < H * 2.0:
		Game.world.env.add_shake(0.15 * k)
