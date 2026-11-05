class_name SleeveSnake
extends Node3D
## Yenden çıkan yılan (Sen'ei Jashu / Tajashu; anime: kuyruğu yenin içinde kalır, gövde koldan hedefe uzanır).
## Gövde her kare çıkış noktasından (bilek) başa kıvrık bir eğri boyunca tüp olarak çizilir; hedefe varınca
## son kısmı hedefin gövdesine sarmal sarılır, baş omuza/boyna ısırır. extend 0→1 uzanma, retract geri çekilme.

var anchor: Callable          # -> Vector3: yenin ağzı (her kare)
var aim_dir := Vector3.FORWARD
var target: Node3D = null     # sarılacak hedef (yoksa free_to'ya uzanır)
var free_to := Vector3.ZERO
var radius := 0.085           # önkol kalınlığına yakın (Anko'nun yılanları kolundan biraz ince)
var side := 0.0               # eğrinin yana açılması (-1..1): dört yılan yelpaze gibi ayrılsın
var lift := 0.0               # eğrinin yukarı/aşağı kavisi
var phase := 0.0
var coil_turns := 1.4
var coil_y0 := 0.35           # sarmalın hedef boyuna göre alt/üst sınırı
var coil_y1 := 0.72
var reach := 0.0              # 0..1 görünen uzunluk
var wrapped := false
var back_col := Color(0.24, 0.26, 0.17)
var belly_col := Color(0.86, 0.8, 0.64)

const RING := 9
const MAX_PTS := 64

var _mi: MeshInstance3D
var _im := ImmediateMesh.new()
var _head: Node3D
var _mat: ShaderMaterial
var _t := 0.0


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/vfx_snake_skin.gdshader")
	_mat.set_shader_parameter("back_col", back_col)
	_mat.set_shader_parameter("belly_col", belly_col)
	_mi = MeshInstance3D.new()
	_mi.mesh = _im
	_mi.material_override = _mat
	_mi.extra_cull_margin = 60.0
	add_child(_mi)


func set_head(h: Node3D) -> void:
	_head = h
	add_child(h)
	h.top_level = true


## Tam yol: yenden hedefin yanına kavisli uzanış (+ sarılıyorsa sarmal)
func _path() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var a: Vector3 = anchor.call()
	var tgt_ok = target != null and is_instance_valid(target) and target.is_inside_tree()
	var c_axis := Vector3.ZERO
	var rr := 0.0
	var h := 1.7
	var end: Vector3
	if tgt_ok:
		h = float(target.get("height")) if target.get("height") != null else 1.7
		rr = (float(target.get("radius")) if target.get("radius") != null else 0.4) * 0.75 + radius * 1.3
		c_axis = target.global_position
		# sarmalın başladığı nokta: hedefin bize bakan yanı, belden biraz aşağı
		var to_me = (a - c_axis)
		to_me.y = 0
		to_me = to_me.normalized() if to_me.length() > 0.01 else -aim_dir
		var a0 = atan2(to_me.z, to_me.x) + phase
		end = c_axis + Vector3(cos(a0) * rr, h * coil_y0, sin(a0) * rr)
	else:
		end = free_to
	var d = end - a
	var L = d.length()
	var dn = d / maxf(L, 0.001)
	var sd = dn.cross(Vector3.UP).normalized()
	if sd.length() < 0.1:
		sd = Vector3.RIGHT
	var up = sd.cross(dn).normalized()
	var n_reach = clampi(int(L / 0.18), 10, 40)
	for i in n_reach + 1:
		var k = float(i) / n_reach
		# kavis: yenden çıkınca önce dışa açılır, hedefe yaklaşırken toplanır; kıvrım dalgası sürünme hissi verir
		var bow = sin(k * PI)
		var wig = sin(k * TAU * 1.5 + _t * 9.0 + phase * 3.0) * 0.18 * bow * (0.4 if wrapped else 1.0)
		var p = a.lerp(end, k) + sd * (side * L * 0.16 * bow + wig) + up * (lift * L * 0.1 * bow + absf(wig) * 0.3)
		pts.append(p)
	if tgt_ok:
		var n_coil = 26
		var to_me2 = (a - c_axis)
		to_me2.y = 0
		to_me2 = to_me2.normalized() if to_me2.length() > 0.01 else -aim_dir
		var a0 = atan2(to_me2.z, to_me2.x) + phase
		var dir = 1.0 if int(phase * 10.0) % 2 == 0 else -1.0
		for i in range(1, n_coil + 1):
			var k = float(i) / n_coil
			var ang = a0 + dir * k * coil_turns * TAU
			pts.append(c_axis + Vector3(cos(ang) * rr, h * lerpf(coil_y0, coil_y1, k), sin(ang) * rr))
	return pts


func _process(dt: float) -> void:
	_t += dt
	if not anchor.is_valid():
		queue_free()
		return
	var full = _path()
	# görünen kısım: yol uzunluğunun reach kadarı (baş yolun ucunda)
	var lens := [0.0]
	for i in range(1, full.size()):
		lens.append(lens[i - 1] + full[i].distance_to(full[i - 1]))
	var total: float = lens[-1]
	var want = total * clampf(reach, 0.0, 1.0)
	var pts := PackedVector3Array()
	for i in full.size():
		if lens[i] <= want:
			pts.append(full[i])
		else:
			if i > 0:
				var seg = lens[i] - lens[i - 1]
				pts.append(full[i - 1].lerp(full[i], (want - lens[i - 1]) / maxf(seg, 0.001)))
			break
	_build(pts)


func _build(pts: PackedVector3Array) -> void:
	_im.clear_surfaces()
	if pts.size() < 2:
		if _head:
			_head.visible = false
		return
	_head.visible = true if _head else false
	var n = pts.size()
	var frames := []
	var prev_up := Vector3.UP
	var acc := 0.0
	var us := []
	for i in n:
		var tng = (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var b = tng.cross(prev_up)
		if b.length() < 0.05:
			b = tng.cross(Vector3.RIGHT)
		b = b.normalized()
		var u = b.cross(tng).normalized()
		prev_up = u
		frames.append([u, b])
		if i > 0:
			acc += pts[i].distance_to(pts[i - 1])
		us.append(acc)
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		for j in RING:
			for q in [[i, j], [i + 1, j], [i, j + 1], [i, j + 1], [i + 1, j], [i + 1, j + 1]]:
				var ii: int = q[0]
				var jj: int = q[1]
				var ang = TAU * float(jj) / RING
				# kuyruk yenin içinde: çıkışta biraz ince; başa yakın boyun incelir
				var kk = float(ii) / (n - 1)
				var r = radius * (0.8 + 0.2 * minf(1.0, kk * 6.0)) * (1.0 - 0.25 * smoothstep(0.9, 1.0, kk))
				var fr: Array = frames[ii]
				var nrm: Vector3 = fr[0] * cos(ang) + fr[1] * sin(ang)
				_im.surface_set_normal(nrm)
				_im.surface_set_uv(Vector2(float(us[ii]), float(jj) / RING))   # 0 sırt (yukarı), 0.5 karın (aşağı)
				_im.surface_add_vertex(pts[ii] + nrm * r)
	_im.surface_end()
	if _head:
		var tip = pts[n - 1]
		var tng2 = (pts[n - 1] - pts[n - 2]).normalized()
		_head.global_position = tip + tng2 * radius * 1.2
		var upv = frames[n - 1][0]
		if absf(tng2.dot(upv)) > 0.95:
			upv = Vector3.UP
		_head.look_at(_head.global_position + tng2, upv)


## Uzan: reach 0→1 (sec); bitince done
func extend(sec: float, done := Callable()) -> void:
	var tw = create_tween()
	tw.tween_property(self, "reach", 1.0, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if done.is_valid():
		tw.tween_callback(done)


## Geri çekil ve yok ol
func retract(sec: float) -> void:
	var tw = create_tween()
	tw.tween_property(self, "reach", 0.0, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
