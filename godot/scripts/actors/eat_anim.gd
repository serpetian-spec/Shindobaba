class_name EatAnim
extends Node
## Tezgâhta ramen yeme (referans: Ichiraku sahneleri): taburede oturur, "Itadakimasu!" ile ellerini birleştirir,
## kase sol avuçta göğüs hizasında, sağ elde yemek çubukları: çubuklar kaseye dalar, erişteyi kaldırıp ağza götürür (hüüp),
## birkaç lokmadan sonra kaseyi iki eliyle kaldırıp suyunu içer, "Gochisōsama!". Bu sürede oyuncu kilitli: ekranda
## "Ramen yiyorsun" ve kalan süre yazar (neden hareket etmediği belli olsun). Kase/çubuklar her kare ellerin konumuna yerleşir.

signal done

const T_START := 0.9     # Itadakimasu
const BITES := 5
const T_BITE := 1.05
const T_DRINK := 1.5

var f: Node3D
var model
var t := 0.0
var total := 0.0
var bowl: Node3D
var sticks: Node3D
var noodles: Array = []
var _bite_idx := -1
var _msg_t := 0.0
var seat_h := -1.0   # < 0: oturma yüksekliği ayarlanmaz


static func start(player: Node3D, seat := -1.0) -> EatAnim:
	var old = player.get_node_or_null("EatAnim")
	if old:
		old.queue_free()
	var e = EatAnim.new()
	e.name = "EatAnim"
	e.f = player
	e.model = player.get("model")
	e.seat_h = seat
	e.total = T_START + BITES * T_BITE + T_DRINK + 0.4
	player.add_child(e)
	return e


var on_counter := false
var counter_pt := Vector3.ZERO


func _ready() -> void:
	_make_props()
	# kanon: kase tezgâhın üstünde durur, eğilip çubuklarla yenir; tezgâh yoksa kase avuçta
	var fd: Vector3 = f.face_dir()
	# tezgâhın ön kenarını bul (yakından uzağa), kase kenarın biraz içine
	for k in 10:
		var dd = 0.25 + k * 0.05
		var from = f.global_position + fd * dd + Vector3.UP * 2.2
		var q = PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 2.3, 1)
		q.exclude = [f.get_rid()]
		var hit = f.get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			continue
		var hy = float(hit["position"].y) - f.global_position.y
		if hy > 0.5 and hy < 1.5:
			on_counter = true
			counter_pt = hit["position"] - fd * 0.06 + Vector3.UP * 0.115   # çarpışma kutusu üstü + kırmızı tezgâh levhası + kasenin yarısı
			break
	model.overlay.set_pose("cast", 1.0)
	f.input_locked = total + 0.3
	Combat.popup_text(f.global_position + Vector3.UP * 2.0, "Itadakimasu!", Color(1.0, 0.85, 0.5))


func _make_props() -> void:
	# oyunun toon malzemesiyle (düz StandardMaterial sahne ışığında koyu lacivert görünüyordu)
	var root = f.get_tree().current_scene
	var mat = Props.toon()
	var m = MB.new()
	m.add("hemi", Vector3(0, 0.035, 0), Vector3(0.17, 0.14, 0.17), Color(0.78, 0.16, 0.1), Vector3(180, 0, 0), 16)   # kase: dışı kırmızı
	m.add("cyl", Vector3(0, 0.034, 0), Vector3(0.178, 0.012, 0.178), Color(0.96, 0.94, 0.9), Vector3.ZERO, 16)       # ağzı beyaz bant
	m.add("cyl", Vector3(0, 0.037, 0), Vector3(0.152, 0.006, 0.152), Color(0.9, 0.62, 0.3), Vector3.ZERO, 16)        # et suyu
	m.add("cyl", Vector3(-0.012, 0.041, 0.012), Vector3(0.085, 0.008, 0.085), Color(1.0, 0.88, 0.5), Vector3.ZERO, 12) # erişte yığını
	m.add("cyl", Vector3(0.038, 0.043, 0.012), Vector3(0.042, 0.008, 0.042), Color(0.98, 0.97, 0.95), Vector3.ZERO, 12) # narutomaki
	m.add("cyl", Vector3(0.038, 0.046, 0.012), Vector3(0.018, 0.004, 0.018), Color(0.95, 0.4, 0.6), Vector3.ZERO, 8)   # pembe sarmal
	m.add("cyl", Vector3(-0.03, 0.044, -0.028), Vector3(0.055, 0.01, 0.055), Color(0.62, 0.36, 0.22), Vector3.ZERO, 12) # chashu
	m.add("box", Vector3(0.0, 0.045, -0.045), Vector3(0.05, 0.004, 0.02), Color(0.2, 0.45, 0.2))                      # nori / menma
	bowl = MeshInstance3D.new()
	bowl.mesh = m.build(mat)
	root.add_child(bowl)
	var ms = MB.new()
	for sd in [-1.0, 1.0]:
		ms.add("box", Vector3(sd * 0.009, 0, 0.115), Vector3(0.008, 0.008, 0.23), Color(0.9, 0.76, 0.52), Vector3(0, sd * 1.5, 0))
	sticks = MeshInstance3D.new()
	sticks.mesh = ms.build(mat)
	root.add_child(sticks)
	var mn = MB.new()
	mn.add("box", Vector3.ZERO, Vector3(0.005, 0.005, 1.0), Color(1.0, 0.9, 0.55))
	var nm = mn.build(mat)
	for k in 3:
		var n = MeshInstance3D.new()
		n.mesh = nm
		n.visible = false
		root.add_child(n)
		noodles.append(n)


func _bone(nm: String) -> Vector3:
	var sk: Skeleton3D = model.skel
	var bi = sk.find_bone(nm)
	if bi < 0:
		return f.global_position + Vector3.UP
	return sk.global_transform * sk.get_bone_global_pose(bi).origin


func _mouth() -> Vector3:
	return _bone("Head") + Vector3.UP * 0.02 + f.face_dir() * 0.12 * model.age_scale


func _process(dt: float) -> void:
	if not is_instance_valid(f) or model == null:
		_end()
		return
	t += dt
	if model.current != "sit":
		model.play("sit", 0.2)
	# kalça tabure minderine otursun (havada kalmasın / içine gömülmesin): kalça kemiği = minder + kalça kalınlığı
	if seat_h >= 0.0:
		var hr = _bone("Hips").y - model.global_position.y
		model.position.y = clampf(seat_h + 0.07 * model.age_scale - hr, -0.25, 0.35)
	var pose: Dictionary
	var lift := 0.0   # 0 = çubuklar kasede, 1 = ağızda
	var drink := 0.0
	if t < T_START:
		pose = _p_clap()
	elif t < T_START + BITES * T_BITE:
		var bt = t - T_START
		var i = int(bt / T_BITE)
		var k = fmod(bt, T_BITE) / T_BITE
		# dal (0-0.25), kaldır (0.25-0.55), ağızda hüüp (0.55-0.8), in (0.8-1)
		if k < 0.25:
			lift = 0.0
		elif k < 0.55:
			lift = smoothstep(0.25, 0.55, k)
		elif k < 0.8:
			lift = 1.0
		else:
			lift = 1.0 - smoothstep(0.8, 1.0, k)
		if i != _bite_idx and k > 0.55:
			_bite_idx = i
			Sfx.play("whoosh", f.global_position + Vector3.UP * 1.2, 2.2, 0.25)
			Combat.popup_text(_mouth() + Vector3.UP * 0.25, ["Hüüp!", "Mmm!", "Hüüüp!", "Nefis!", "Hüüp!"][i % 5], Color(1, 0.9, 0.6))
		pose = _p_counter(lift, 0.0) if on_counter else _p_eat(lift)
	elif t < T_START + BITES * T_BITE + T_DRINK:
		drink = smoothstep(0.0, 0.35, (t - T_START - BITES * T_BITE) / T_DRINK)
		pose = _p_counter(0.0, drink) if on_counter else _blend(_p_eat(0.0), _p_drink(), drink)
	else:
		drink = 1.0
		pose = _p_counter(0.0, 1.0) if on_counter else _p_drink()
		if t >= total:
			Combat.popup_text(f.global_position + Vector3.UP * 2.1, "Gochisōsama!", Color(1.0, 0.85, 0.5))
			_end()
			return
	model.overlay.cast_pose = pose
	_place(lift, drink)
	_msg_t -= dt
	if _msg_t <= 0.0:
		_msg_t = 1.0
		Hud.msg("Ramen yiyorsun... (%d sn)" % ceili(total - t), Color(1.0, 0.8, 0.45), 1.1)


## kase sol avuçta (içerken iki elin arasında, ağza eğik); çubuklar sağ elden kaseye ya da ağza
func _place(lift: float, drink: float) -> void:
	var fd: Vector3 = f.face_dir()
	var lh = _bone("LeftHand")
	var rh = _bone("RightHand")
	var right = fd.cross(Vector3.UP).normalized()
	var bp = lh + Vector3.UP * 0.03 + right * 0.05 * model.age_scale + fd * 0.02
	if on_counter:
		bp = _bowl_pos(drink)
	elif drink > 0.0:
		bp = bp.lerp((lh + rh) * 0.5 + Vector3.UP * 0.03, drink)
	bowl.global_position = bp
	var tilt = Basis(right, drink * 0.9)   # ağız tarafı kalkar, dibi dışa
	bowl.global_basis = tilt * Basis(Vector3.UP, f.facing)
	bowl.scale = Vector3.ONE * model.age_scale
	sticks.visible = drink < 0.3
	var target = (bp + Vector3.UP * 0.03).lerp(_mouth(), lift)
	var dir = (target - rh)
	if dir.length() < 0.05:
		dir = fd
	sticks.global_position = rh - dir.normalized() * 0.03
	sticks.look_at(rh + dir.normalized(), Vector3.UP if absf(dir.normalized().y) < 0.95 else fd)
	sticks.rotate_object_local(Vector3.UP, PI)   # BoxMesh +z boyunca uzanıyor; look_at -z'ye bakar
	sticks.scale = Vector3.ONE * model.age_scale
	var tip = sticks.global_position + dir.normalized() * 0.2 * model.age_scale
	for k in noodles.size():
		var n: MeshInstance3D = noodles[k]
		var show = lift > 0.1 and lift < 0.98 and drink <= 0.0
		n.visible = show
		if show:
			var a = tip + right * (k - 1) * 0.008
			var b = bp + Vector3.UP * 0.03 + right * (k - 1) * 0.01
			n.global_position = (a + b) * 0.5
			var L = maxf(0.01, a.distance_to(b))
			n.look_at(b, right if absf((b - a).normalized().dot(Vector3.UP)) > 0.95 else Vector3.UP)
			n.scale = Vector3(1, 1, L)


## iki kemik IK: omuzdan hedefe; dirsek aşağı-dışa. Kemik yönlerini model uzayında döndürür
func _ik(side: String, target: Vector3, lean_deg := 0.0) -> Array:
	var sk: Skeleton3D = model.skel
	var S = _bone(side + "UpperArm")
	if lean_deg != 0.0:
		# okunan kemik konumu eğilmeden önceki (animasyon) poz: bel eğilince omuz öne-aşağı kayar
		var hp = _bone("Hips")
		var ax = Vector3.UP.cross(f.face_dir()).normalized()
		S = hp + (S - hp).rotated(ax, deg_to_rad(lean_deg) * 0.85)
	var Eb = _bone(side + "LowerArm")
	var H = _bone(side + "Hand")
	var a = maxf(0.05, S.distance_to(Eb))
	var b = maxf(0.05, Eb.distance_to(H))
	var v = target - S
	var d = clampf(v.length(), 0.05, (a + b) * 0.995)
	var n = v.normalized()
	var along = (a * a - b * b + d * d) / (2.0 * d)
	var h = sqrt(maxf(0.0, a * a - along * along))
	var outw = f.face_dir().cross(Vector3.UP).normalized() * (1.0 if side == "Right" else -1.0)
	var pole = (Vector3.DOWN + outw * 0.6 - f.face_dir() * 0.2)
	pole = (pole - n * pole.dot(n)).normalized()
	var E = S + n * along + pole * h
	var T = S + n * d
	var inv = model.skel.global_basis.orthonormalized().inverse()   # yönler iskelet uzayında (iskelet modele göre dönük olabilir)
	var up_d = inv * (E - S).normalized()
	var lo_d = inv * (T - E).normalized()
	return [[side + "UpperArm", up_d], [side + "LowerArm", lo_d], [side + "Hand", (lo_d + inv * Vector3.DOWN * 0.25).normalized()]]


func _bowl_pos(drink: float) -> Vector3:
	var fd: Vector3 = f.face_dir()
	return counter_pt.lerp(_mouth() + fd * 0.1 * model.age_scale + Vector3.DOWN * 0.07, drink)


func _p_counter(lift: float, drink: float) -> Dictionary:
	var fd: Vector3 = f.face_dir()
	var left = -fd.cross(Vector3.UP).normalized()
	var bp = _bowl_pos(drink)
	var arms = []
	var lean = lerpf(20.0 - lift * 8.0, -4.0, drink)
	if drink > 0.0:
		arms.append_array(_ik("Left", bp + left * 0.1 * model.age_scale, lean))
		arms.append_array(_ik("Right", bp - left * 0.1 * model.age_scale, lean))
	else:
		arms.append_array(_ik("Left", bp + left * 0.11 * model.age_scale + Vector3.DOWN * 0.03, lean))   # kaseyi kenarından tutar
		var rt = (bp + Vector3.UP * 0.1 - left * 0.08 * model.age_scale - fd * 0.06).lerp(_mouth() + fd * 0.14 * model.age_scale + Vector3.DOWN * 0.06 - left * 0.03, lift)
		arms.append_array(_ik("Right", rt, lean))
	return {"arms": arms, "fL": [0.45, 0.45, 0.5, 0.5, 0.3], "fR": [0.9, 0.95, 1.2, 1.25, 0.6] if drink <= 0.0 else [0.5, 0.5, 0.5, 0.5, 0.3],
		"spine": lean, "neck": lerpf(6.0 - lift * 8.0, -20.0, drink)}


# ---------------------------------------------------------------- pozlar (model uzayı: +x sol, +y yukarı, +z ileri)
func _p_clap() -> Dictionary:
	return {"arms": [["LeftUpperArm", Vector3(0.25, -0.7, 0.65)], ["RightUpperArm", Vector3(-0.25, -0.7, 0.65)],
		["LeftLowerArm", Vector3(-0.55, 0.65, 0.5)], ["RightLowerArm", Vector3(0.55, 0.65, 0.5)],
		["LeftHand", Vector3(-0.15, 0.95, 0.25)], ["RightHand", Vector3(0.15, 0.95, 0.25)]],
		"fL": [0.05, 0.05, 0.05, 0.05, 0.2], "fR": [0.05, 0.05, 0.05, 0.05, 0.2], "spine": 8.0, "neck": 10.0}


func _p_eat(lift: float) -> Dictionary:
	# sol: kase göğüs önünde avuçta; sağ: çubuklar kaseden ağza
	var rua = Vector3(-0.3, -0.8, 0.5).lerp(Vector3(-0.25, -0.55, 0.8), lift).normalized()
	var rla = Vector3(0.65, 0.05, 0.75).lerp(Vector3(0.35, 0.85, 0.4), lift).normalized()
	var rha = Vector3(0.55, -0.35, 0.75).lerp(Vector3(0.45, 0.55, 0.7), lift).normalized()
	return {"arms": [["LeftUpperArm", Vector3(0.3, -0.85, 0.42)], ["LeftLowerArm", Vector3(-0.55, 0.12, 0.83)], ["LeftHand", Vector3(-0.7, -0.1, 0.7)],
		["RightUpperArm", rua], ["RightLowerArm", rla], ["RightHand", rha]],
		"fL": [0.35, 0.35, 0.4, 0.45, 0.3], "fR": [0.9, 0.95, 1.2, 1.25, 0.6],
		"spine": 14.0 - lift * 4.0, "neck": 18.0 - lift * 14.0}


func _p_drink() -> Dictionary:
	# kaseyi iki elle ağza kaldır, başı geriye eğ
	return {"arms": [["LeftUpperArm", Vector3(0.3, -0.45, 0.85)], ["RightUpperArm", Vector3(-0.3, -0.45, 0.85)],
		["LeftLowerArm", Vector3(-0.45, 0.8, 0.4)], ["RightLowerArm", Vector3(0.45, 0.8, 0.4)],
		["LeftHand", Vector3(-0.5, 0.5, 0.7)], ["RightHand", Vector3(0.5, 0.5, 0.7)]],
		"fL": [0.5, 0.5, 0.5, 0.5, 0.3], "fR": [0.5, 0.5, 0.5, 0.5, 0.3], "spine": -6.0, "neck": -22.0}


func _blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var o = {"arms": []}
	var bm = {}
	for x in b["arms"]:
		bm[x[0]] = x[1]
	for x in a["arms"]:
		o["arms"].append([x[0], (x[1] as Vector3).lerp(bm.get(x[0], x[1]), k).normalized()])
	for s in ["fL", "fR"]:
		var fa: Array = a[s]
		var fb: Array = b[s]
		var r = []
		for i in 5:
			r.append(lerpf(fa[i], fb[i], k))
		o[s] = r
	o["spine"] = lerpf(a["spine"], b["spine"], k)
	o["neck"] = lerpf(a["neck"], b["neck"], k)
	return o


func _end() -> void:
	if model and is_instance_valid(model):
		model.position.y = 0.0
		model.overlay.set_pose("cast", 0.0)
		model.overlay.cast_pose = {}
	for n in [bowl, sticks] + noodles:
		if n and is_instance_valid(n):
			n.queue_free()
	if is_instance_valid(f):
		f.input_locked = 0.0
	done.emit()
	queue_free()
