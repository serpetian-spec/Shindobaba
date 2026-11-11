class_name ScenePoser
extends Node
## Sahne oynatıcı tabanı (ev hayatı, düğün...): oyuncu ve NPC'leri aynı poz sistemiyle yönetir.
## _pose(düğüm, poz, ek) ile bir duruş verilir; her kare kollar hedefe IK ile gider, eldeki eşya (kase, çubuk, bardak, kepçe,
## bıçak, süpürge, tepsi) ellere oturur; "sit" verilirse yere seiza / bağdaş oturulur. _go_w ile yürütülür.

const OPEN := [0.05, 0.05, 0.05, 0.05, 0.2]
const GRIP := [0.9, 0.95, 1.1, 1.2, 0.6]
const HALF := [0.45, 0.45, 0.5, 0.5, 0.3]

var st := {}          # düğüm -> {"k": poz, "t": süre, ...}
var mat: Material = Props.toon()
var tray: Node3D
var pot_pos := Vector3.ZERO
var board_pos := Vector3.ZERO


func _apply_poses(dt: float) -> void:
	for n in st.keys():
		if not is_instance_valid(n):
			st.erase(n)
			continue
		var s: Dictionary = st[n]
		s["t"] = float(s["t"]) + dt
		if s.has("anim") and n.model.current != s["anim"]:
			n.model.play(String(s["anim"]), 0.25)
		var cp = _make(n, s)
		if s.has("sit"):
			cp["arms"] = _legs(n, String(s["sit"])) + cp.get("arms", [])
			var hr = _bone(n, "Hips").y - n.model.global_position.y
			var want = (0.15 if String(s["sit"]) == "agura" else 0.24) * n.model.age_scale + float(s.get("lift", 0.05))
			var cur_y: float = n.model_lift if n == Game.player else n.model.position.y
			cur_y = lerpf(cur_y, clampf(want - hr, -1.3, 0.2), minf(1.0, dt * 7.0))
			if n == Game.player:
				n.model_lift = cur_y   # oyuncu modelinin yüksekliğini kendi kodu yazar
			else:
				n.model.position.y = cur_y
		n.model.overlay.cast_pose = cp
		n.model.overlay.set_pose("cast", 1.0)


## Yürüyen NPC'nin bastığı yükseklik (sahne kendi platformunu verir)
func _floor_y(p: Vector3) -> float:
	return Game.ground_height(p.x, p.z)


## Dünya konumuna yürüt (keep: verilmiş pozu bozmadan, ör. tepsi taşırken)
func _go_w(n: Node3D, tgt: Vector3, spd := 1.5, keep := false, stop := 0.1) -> void:
	var t0 := 0.0
	while is_instance_valid(n):
		var to = tgt - n.global_position
		to.y = 0
		if to.length() < stop or t0 > 30.0:
			break
		var dt = get_process_delta_time()
		t0 += dt
		_turn(n, atan2(-to.x, -to.z), dt * 9.0)
		n.global_position += to.normalized() * minf(spd * dt, to.length())
		if n == Game.player:
			n.velocity = Vector3.ZERO
			var fy = maxf(_floor_y(n.global_position), _floor_y(n.global_position + to.normalized() * 0.55))
			if fy > n.global_position.y and fy - n.global_position.y < 0.6:
				n.global_position.y = fy + 0.02   # basamak / sahne kenarı: üstüne çıkar
		elif n.get("interior") != true:
			n.global_position.y = _floor_y(n.global_position)
		if not keep:
			n.model.play("walk" if spd < 2.6 else "run", 0.2, spd / 1.5 if spd < 2.6 else 0.8)
		await get_tree().process_frame
	if is_instance_valid(n) and not keep:
		n.model.play("idle", 0.25)



# ------------------------------------------------------------------ yardımcılar
func _fd(n: Node3D) -> Vector3:
	return Vector3(-sin(n.facing), 0, -cos(n.facing))


func _face(n: Node3D, a: float) -> void:
	n.facing = a
	if n.get("stand_face") != null:
		n.stand_face = a
	n.model.rotation.y = a


func _turn(n: Node3D, a: float, k: float) -> void:
	_face(n, lerp_angle(n.facing, a, clampf(k, 0.0, 1.0)))


func _look_at(n: Node3D, p: Vector3, k := 1.0) -> void:
	var to = p - n.global_position
	if Vector2(to.x, to.z).length() > 0.05:
		_turn(n, atan2(-to.x, -to.z), k)


func _bone(n: Node3D, nm: String) -> Vector3:
	var sk: Skeleton3D = n.model.skel
	var bi = sk.find_bone(nm)
	if bi < 0:
		return n.global_position + Vector3.UP
	return sk.global_transform * sk.get_bone_global_pose(bi).origin


func _mouth(n: Node3D) -> Vector3:
	return _bone(n, "Head") + Vector3.UP * 0.02 + _fd(n) * 0.12 * n.model.age_scale


func _lock(sec: float) -> void:
	var pl = Game.player
	pl.input_locked = sec
	pl.velocity = Vector3.ZERO
	pl.set("scene_hold", true)


func _release_player() -> void:
	var pl = Game.player
	if pl == null or not is_instance_valid(pl):
		return
	if pl.get("scene_hold"):
		pl.set("scene_hold", false)
		pl.input_locked = 0.0
		pl.model_lift = 0.0
		pl.model.overlay.foot_ik = true
		pl.model.overlay.set_pose("cast", 0.0)
		pl.model.overlay.cast_pose = {}


func _pose(n: Node3D, kind: String, extra := {}) -> void:
	_drop_props(n)
	var s = {"k": kind, "t": 0.0}
	s.merge(extra)
	st[n] = s
	n.model.overlay.foot_ik = not s.has("sit")


func _clear_pose(n: Node3D) -> void:
	_drop_props(n)
	st.erase(n)
	if is_instance_valid(n) and n.get("model") != null:
		n.model.overlay.set_pose("cast", 0.0)
		n.model.overlay.cast_pose = {}
		n.model.overlay.foot_ik = true
		if n == Game.player:
			n.model_lift = 0.0
		else:
			n.model.position.y = 0.0


func _drop_props(n: Node3D) -> void:
	if st.has(n):
		for p in st[n].get("props", {}).values():
			if is_instance_valid(p):
				p.queue_free()


func _mesh(b: MB) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.mesh = b.build(mat)
	add_child(m)
	m.top_level = true
	return m


func _prop(s: Dictionary, name: String) -> MeshInstance3D:
	if not s.has("props"):
		s["props"] = {}
	if s["props"].has(name) and is_instance_valid(s["props"][name]):
		return s["props"][name]
	var b = MB.new()
	match name:
		"ladle":
			b.add("box", Vector3(0, 0, 0.16), Vector3(0.016, 0.016, 0.34), Color(0.75, 0.6, 0.4))
			b.add("hemi", Vector3(0, 0, 0.34), Vector3(0.08, 0.05, 0.08), Color(0.75, 0.6, 0.4), Vector3(90, 0, 0), 8)
		"knife":
			b.add("box", Vector3(0, 0, -0.04), Vector3(0.02, 0.025, 0.1), Color(0.3, 0.2, 0.12))
			b.add("box", Vector3(0, -0.012, 0.11), Vector3(0.004, 0.05, 0.2), Color(0.85, 0.87, 0.9))
		"bowl":
			b.add("hemi", Vector3(0, 0.03, 0), Vector3(0.12, 0.1, 0.12), Color(0.2, 0.25, 0.45), Vector3(180, 0, 0), 12)
			b.add("cyl", Vector3(0, 0.03, 0), Vector3(0.125, 0.008, 0.125), Color(0.95, 0.94, 0.9), Vector3.ZERO, 12)
			b.add("sphere", Vector3(0, 0.032, 0), Vector3(0.105, 0.05, 0.105), Color(0.98, 0.98, 0.96), Vector3.ZERO, 10)
		"sticks":
			for sd in [-1.0, 1.0]:
				b.add("box", Vector3(sd * 0.008, 0, 0.1), Vector3(0.007, 0.007, 0.2), Color(0.35, 0.2, 0.12), Vector3(0, sd * 1.5, 0))
		"cup":
			b.add("cyl", Vector3(0, 0.035, 0), Vector3(0.065, 0.07, 0.065), Color(0.55, 0.62, 0.5), Vector3.ZERO, 10)
			b.add("cyl", Vector3(0, 0.068, 0), Vector3(0.052, 0.006, 0.052), Color(0.45, 0.6, 0.3), Vector3.ZERO, 10)
		"broom":
			b.add("box", Vector3(0, 0, 0.7), Vector3(0.025, 0.025, 1.4), Color(0.7, 0.55, 0.3))
			b.add("box", Vector3(0, 0, 0.1), Vector3(0.3, 0.05, 0.26), Color(0.8, 0.68, 0.35))
		"tray":
			b.add("box", Vector3(0, 0, 0), Vector3(0.5, 0.02, 0.34), Color(0.35, 0.12, 0.1))
			for q in [Vector3(-0.14, 0.01, 0.05), Vector3(0.14, 0.01, 0.05)]:
				b.add("hemi", q + Vector3(0, 0.03, 0), Vector3(0.12, 0.1, 0.12), Color(0.2, 0.25, 0.45), Vector3(180, 0, 0), 10)
				b.add("sphere", q + Vector3(0, 0.032, 0), Vector3(0.105, 0.05, 0.105), Color(0.98, 0.98, 0.96), Vector3.ZERO, 8)
			b.add("box", Vector3(0, 0.02, -0.09), Vector3(0.22, 0.012, 0.1), Color(0.9, 0.9, 0.85))
			b.add("box", Vector3(0, 0.035, -0.09), Vector3(0.17, 0.02, 0.05), Color(0.75, 0.5, 0.3))
	var m = _mesh(b)
	s["props"][name] = m
	return m


func _aim(m: Node3D, from: Vector3, to: Vector3, up := Vector3.UP) -> void:
	m.global_position = from
	var d = to - from
	if d.length() < 0.01:
		return
	if absf(d.normalized().dot(up)) > 0.95:
		up = Vector3.FORWARD
	m.look_at(from + d, up)
	m.rotate_object_local(Vector3.UP, PI)   # parçalar +z boyunca uzanır


## İki kemik IK (EatAnim ile aynı çözüm): omuzdan hedefe, dirsek aşağı-dışa
func _ik(n: Node3D, side: String, target: Vector3, lean_deg := 0.0) -> Array:
	var fd = _fd(n)
	var S = _bone(n, side + "UpperArm")
	if lean_deg != 0.0:
		var hp = _bone(n, "Hips")
		var ax = Vector3.UP.cross(fd).normalized()
		S = hp + (S - hp).rotated(ax, deg_to_rad(lean_deg) * 0.85)
	var a = maxf(0.05, S.distance_to(_bone(n, side + "LowerArm")))
	var b = maxf(0.05, _bone(n, side + "LowerArm").distance_to(_bone(n, side + "Hand")))
	var v = target - S
	var d = clampf(v.length(), 0.05, (a + b) * 0.995)
	var nn = v.normalized()
	var along = (a * a - b * b + d * d) / (2.0 * d)
	var h = sqrt(maxf(0.0, a * a - along * along))
	var outw = fd.cross(Vector3.UP).normalized() * (1.0 if side == "Right" else -1.0)
	var pole = (Vector3.DOWN + outw * 0.6 - fd * 0.2)
	pole = (pole - nn * pole.dot(nn)).normalized()
	var E = S + nn * along + pole * h
	var T = S + nn * d
	var inv = n.model.skel.global_basis.orthonormalized().inverse()
	var up_d = inv * (E - S).normalized()
	var lo_d = inv * (T - E).normalized()
	return [[side + "UpperArm", up_d], [side + "LowerArm", lo_d], [side + "Hand", (lo_d + inv * Vector3.DOWN * 0.25).normalized()]]


func _hand(n: Node3D, side: String) -> Vector3:
	return _bone(n, side + "Hand")


## Yere oturuş bacakları: seiza (dizler önde, baldırlar altta) ya da bağdaş
func _legs(n: Node3D, style: String) -> Array:
	var o = []
	for sd in [["Left", 1.0], ["Right", -1.0]]:
		var x: float = sd[1]
		if style == "agura":
			o.append([sd[0] + "UpperLeg", Vector3(0.8 * x, -0.14, 0.58)])
			o.append([sd[0] + "LowerLeg", Vector3(-0.96 * x, -0.06, 0.2 if x > 0.0 else 0.05)])
			o.append([sd[0] + "Foot", Vector3(-0.8 * x, -0.25, 0.5)])
		else:
			o.append([sd[0] + "UpperLeg", Vector3(0.1 * x, -0.1, 0.99)])
			o.append([sd[0] + "LowerLeg", Vector3(0.02 * x, -0.12, -0.99)])
			o.append([sd[0] + "Foot", Vector3(0.0, -0.25, -0.97)])
	return o


func _make(n: Node3D, s: Dictionary) -> Dictionary:
	var t: float = s["t"]
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	var sc: float = n.model.age_scale
	match String(s["k"]):
		"wave":
			var sw = sin(t * 9.0) * 0.4
			return {"arms": [["RightUpperArm", Vector3(-0.6, 0.5, 0.35)], ["RightLowerArm", Vector3(-0.15 + sw, 0.95, 0.2)], ["RightHand", Vector3(-0.1 + sw * 1.3, 0.98, 0.15)]],
				"fL": HALF, "fR": OPEN, "spine": 0.0, "neck": 0.0}
		"bow":
			var k = smoothstep(0.0, 0.5, t) * (1.0 - smoothstep(float(s.get("len", 1.6)) - 0.4, float(s.get("len", 1.6)), t))
			return {"arms": [["LeftUpperArm", Vector3(0.12, -0.9, 0.3 * k)], ["RightUpperArm", Vector3(-0.12, -0.9, 0.3 * k)]], "fL": HALF, "fR": HALF, "spine": 58.0 * k, "neck": 12.0 * k}
		"stretch":
			var k2 = smoothstep(0.0, 0.6, t) * (1.0 - smoothstep(1.8, 2.4, t))
			return {"arms": [["LeftUpperArm", Vector3(0.35, 0.9 * k2 - 0.9 * (1.0 - k2), 0.05)], ["RightUpperArm", Vector3(-0.35, 0.9 * k2 - 0.9 * (1.0 - k2), 0.05)],
				["LeftLowerArm", Vector3(0.1, 1.0 * k2 - (1.0 - k2), -0.15 * k2)], ["RightLowerArm", Vector3(-0.1, 1.0 * k2 - (1.0 - k2), -0.15 * k2)]],
				"fL": OPEN, "fR": OPEN, "spine": -12.0 * k2, "neck": -14.0 * k2}
		"hug":
			var o: Node3D = s["with"]
			var arms = []
			if is_instance_valid(o):
				var c = _bone(o, "Chest") + fd * 0.1
				var k3 = smoothstep(0.0, 0.5, t)
				var rest_l = _bone(n, "LeftUpperArm") + Vector3.DOWN * 0.5
				var rest_r = _bone(n, "RightUpperArm") + Vector3.DOWN * 0.5
				arms.append_array(_ik(n, "Left", rest_l.lerp(c + right * 0.04 + Vector3.UP * float(s.get("hi", 0.05)), k3)))
				arms.append_array(_ik(n, "Right", rest_r.lerp(c - right * 0.04 + Vector3.UP * float(s.get("hi", 0.05)), k3)))
			return {"arms": arms, "fL": HALF, "fR": HALF, "spine": 7.0, "neck": 16.0}
		"clap":
			return {"arms": [["LeftUpperArm", Vector3(0.25, -0.7, 0.65)], ["RightUpperArm", Vector3(-0.25, -0.7, 0.65)],
				["LeftLowerArm", Vector3(-0.55, 0.65, 0.5)], ["RightLowerArm", Vector3(0.55, 0.65, 0.5)],
				["LeftHand", Vector3(-0.15, 0.95, 0.25)], ["RightHand", Vector3(0.15, 0.95, 0.25)]],
				"fL": OPEN, "fR": OPEN, "spine": 10.0, "neck": 12.0}
		"rest":   # eller dizde
			return {"arms": [["LeftUpperArm", Vector3(0.18, -0.85, 0.45)], ["RightUpperArm", Vector3(-0.18, -0.85, 0.45)],
				["LeftLowerArm", Vector3(-0.1, -0.5, 0.86)], ["RightLowerArm", Vector3(0.1, -0.5, 0.86)]], "fL": HALF, "fR": HALF, "spine": 2.0, "neck": 4.0}
		"eat":
			# sol avuçta pirinç kasesi göğüs önünde, sağ elde çubuklar kaseden ağza
			var ph = fmod(t + float(s.get("off", 0.0)), 2.2) / 2.2
			var lift = smoothstep(0.2, 0.45, ph) * (1.0 - smoothstep(0.7, 0.9, ph))
			var rua = Vector3(-0.3, -0.8, 0.5).lerp(Vector3(-0.25, -0.55, 0.8), lift).normalized()
			var rla = Vector3(0.65, 0.05, 0.75).lerp(Vector3(0.35, 0.85, 0.4), lift).normalized()
			var rha = Vector3(0.55, -0.35, 0.75).lerp(Vector3(0.45, 0.55, 0.7), lift).normalized()
			var bowl = _prop(s, "bowl")
			var sticks = _prop(s, "sticks")
			var lh = _hand(n, "Left")
			var rh = _hand(n, "Right")
			var bp = lh + Vector3.UP * 0.035 * sc + right * 0.05 * sc + fd * 0.03
			bowl.global_position = bp
			bowl.scale = Vector3.ONE * sc
			var tip = (bp + Vector3.UP * 0.05).lerp(_mouth(n), lift)
			_aim(sticks, rh - (tip - rh).normalized() * 0.03, tip)
			sticks.scale = Vector3.ONE * sc
			if lift > 0.9 and not s.get("bit", false):
				s["bit"] = true
				s["bites"] = int(s.get("bites", 0)) + 1
			elif lift < 0.1:
				s["bit"] = false
			return {"arms": [["LeftUpperArm", Vector3(0.3, -0.85, 0.42)], ["LeftLowerArm", Vector3(-0.55, 0.12, 0.83)], ["LeftHand", Vector3(-0.7, -0.1, 0.7)],
				["RightUpperArm", rua], ["RightLowerArm", rla], ["RightHand", rha]], "fL": [0.35, 0.35, 0.4, 0.45, 0.3], "fR": GRIP,
				"spine": 12.0 - lift * 4.0, "neck": 16.0 - lift * 12.0}
		"tea":
			var ph2 = fmod(t, 6.0)
			var up = smoothstep(0.6, 1.5, ph2) * (1.0 - smoothstep(3.0, 3.9, ph2))
			var cup = _prop(s, "cup")
			var tp: Vector3 = s["table"]
			var hold = tp.lerp(_mouth(n) + fd * 0.07 + Vector3.DOWN * 0.08, up)
			var arms2 = _ik(n, "Right", hold + right * 0.04 + Vector3.UP * 0.03, 6.0)
			arms2.append_array([["LeftUpperArm", Vector3(0.18, -0.85, 0.45)], ["LeftLowerArm", Vector3(-0.1, -0.5, 0.86)]])
			cup.global_position = hold
			cup.global_basis = Basis(right, up * 0.5) * Basis(Vector3.UP, n.facing)
			return {"arms": arms2, "fL": HALF, "fR": [0.7, 0.7, 0.75, 0.8, 0.5], "spine": 6.0, "neck": 4.0 - up * 14.0}
		"stir":
			var a = t * 3.2
			var top = pot_pos + Vector3(cos(a) * 0.07, 0.3, sin(a) * 0.07)
			var bot = pot_pos + Vector3(cos(a) * 0.09, 0.0, sin(a) * 0.09)
			var arms3 = _ik(n, "Right", top, 12.0)
			arms3.append_array(_ik(n, "Left", pot_pos + Vector3(0, -0.02, 0) + fd.cross(Vector3.UP) * -0.24 - fd * 0.12, 12.0))
			var ladle = _prop(s, "ladle")
			_aim(ladle, _hand(n, "Right"), bot)
			return {"arms": arms3, "fL": HALF, "fR": GRIP, "spine": 12.0, "neck": 18.0}
		"chop":
			var cyc = fmod(t * 3.4, 1.0)
			var upk = 1.0 - absf(cyc * 2.0 - 1.0)
			var kp = board_pos + Vector3.UP * (0.1 + upk * 0.13) - fd * 0.14 + right * (0.02 + sin(t * 0.7) * 0.03)
			var arms4 = _ik(n, "Right", kp, 14.0)
			arms4.append_array(_ik(n, "Left", board_pos + Vector3.UP * 0.07 - right * 0.13 - fd * 0.04, 14.0))
			var knife = _prop(s, "knife")
			_aim(knife, _hand(n, "Right"), _hand(n, "Right") + fd * 0.3 + Vector3.DOWN * (0.1 - upk * 0.08))
			if cyc < 0.12 and not s.get("tk", false):
				s["tk"] = true
				Sfx.play("step_wood", board_pos, 0.5)
			elif cyc > 0.5:
				s["tk"] = false
			return {"arms": arms4, "fL": HALF, "fR": GRIP, "spine": 14.0, "neck": 20.0}
		"carry":
			var mid = n.global_position + Vector3.UP * 1.0 * sc + fd * 0.36
			var arms5 = _ik(n, "Left", mid - right * 0.24)
			arms5.append_array(_ik(n, "Right", mid + right * 0.24))
			if is_instance_valid(tray):
				tray.global_position = (_hand(n, "Left") + _hand(n, "Right")) * 0.5 + Vector3.UP * 0.03
				tray.global_basis = Basis(Vector3.UP, n.facing)
			return {"arms": arms5, "fL": HALF, "fR": HALF, "spine": 0.0, "neck": 0.0}
		"sweep":
			var sw2 = sin(t * 2.6)
			var base = n.global_position + fd * 0.75 + right * sw2 * 0.4 + Vector3.UP * 0.03
			var topb = n.global_position + Vector3.UP * 1.25 * sc + fd * 0.12 - right * 0.1
			var dir = (topb - base).normalized()
			var arms6 = _ik(n, "Right", base + dir * 0.72, 10.0)
			arms6.append_array(_ik(n, "Left", base + dir * 1.12, 10.0))
			var broom = _prop(s, "broom")
			_aim(broom, base, topb)
			return {"arms": arms6, "fL": GRIP, "fR": GRIP, "spine": 10.0, "neck": 12.0, "twist": sw2 * 14.0}
	return _make_more(n, s)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout


func _say(n: Node3D, text: String, dur := 3.0) -> void:
	if not is_instance_valid(n):
		return
	if n.has_method("say"):
		n.say(text, dur)
		# sahnede dondurulmuş NPC'nin balonu kendi kendine kapanmaz: süre dolunca kapat
		get_tree().create_timer(dur, false).timeout.connect(func():
			if is_instance_valid(n) and n.get("bubble") != null and is_instance_valid(n.bubble) and n.bubble.text == text:
				n.bubble.visible = false)
	else:
		Combat.popup_text(n.global_position + Vector3.UP * 2.0, text, Color(1.0, 0.9, 0.7))


## Ortak ek pozlar (ders / oyun / aile sahneleri): reach, coo, aim, guide, pout, pat, pads, tired, seal, cheer, lift, fly
func _make_more(n: Node3D, s: Dictionary) -> Dictionary:
	var t: float = s["t"]
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	var sc: float = n.model.age_scale
	match String(s["k"]):
		"reach":
			var k = smoothstep(0.0, 0.6, t)
			var at: Vector3 = s["at"]
			var rl = _bone(n, "LeftUpperArm") + Vector3.DOWN * 0.5
			var rr = _bone(n, "RightUpperArm") + Vector3.DOWN * 0.5
			var arms = _ik(n, "Left", rl.lerp(at - right * 0.13, k), 34.0 * k)
			arms.append_array(_ik(n, "Right", rr.lerp(at + right * 0.13, k), 34.0 * k))
			return {"arms": arms, "fL": HALF, "fR": HALF, "spine": 34.0 * k, "neck": 14.0 * k}
		"coo":    # işaret parmağıyla bebeği sever
			var tgt = n.global_position + Vector3.UP * 1.18 * sc + fd * 0.5 + right * 0.05 + Vector3.UP * sin(t * 7.0) * 0.025
			var arms3 = _ik(n, "Right", tgt, 12.0)
			return {"arms": arms3, "fL": HALF, "fR": [0.05, 0.9, 1.0, 1.1, 0.5], "spine": 12.0, "neck": 16.0}
		"aim":    # atış duruşu: sağ kol geride kalkık, sol kol hedefi gösterir
			return {"arms": [["RightUpperArm", Vector3(-0.62, 0.55, -0.35)], ["RightLowerArm", Vector3(-0.1, 0.92, 0.3)], ["RightHand", Vector3(0.0, 0.9, 0.45)],
				["LeftUpperArm", Vector3(0.2, -0.05, 0.97)], ["LeftLowerArm", Vector3(0.05, 0.02, 1.0)]], "fL": OPEN, "fR": GRIP, "spine": 0.0, "neck": 0.0, "twist": -12.0}
		"guide":  # arkasından kolunu düzeltir
			var o: Node3D = s["with"]
			var arms5 = []
			if is_instance_valid(o):
				arms5 = _ik(n, "Right", _bone(o, "RightLowerArm") + Vector3.UP * 0.03, 20.0)
				arms5.append_array(_ik(n, "Left", _bone(o, "LeftUpperArm") + Vector3.UP * 0.06, 20.0))
			return {"arms": arms5, "fL": HALF, "fR": HALF, "spine": 20.0, "neck": 18.0}
		"pout":
			return {"arms": [["LeftUpperArm", Vector3(0.1, -0.98, 0.12)], ["RightUpperArm", Vector3(-0.1, -0.98, 0.12)]], "fL": HALF, "fR": HALF, "spine": 14.0, "neck": 30.0}
		"pat":    # saçını okşar
			var o2: Node3D = s["with"]
			var arms6 = []
			if is_instance_valid(o2):
				var top = _bone(o2, "Head") + Vector3.UP * 0.17 * o2.model.age_scale + right * sin(t * 8.0) * 0.05
				var rest = _bone(n, "RightUpperArm") + Vector3.DOWN * 0.5
				arms6 = _ik(n, "Right", rest.lerp(top, smoothstep(0.0, 0.45, t)), 12.0)
			return {"arms": arms6, "fL": HALF, "fR": OPEN, "spine": 12.0, "neck": 20.0}
		"pads":   # avuçlarını hedef tutar; her vuruşta geri teper
			s["rec"] = move_toward(float(s.get("rec", 0.0)), 0.0, get_process_delta_time() * 0.6)
			var c2: Vector3 = s["c"] + fd * (0.04 - float(s["rec"]))
			var arms7 = _ik(n, "Left", c2 - right * 0.13, 16.0)
			arms7.append_array(_ik(n, "Right", c2 + right * 0.13, 16.0))
			return {"arms": arms7, "fL": OPEN, "fR": OPEN, "spine": 16.0 - float(s["rec"]) * 40.0, "neck": 14.0, "crouch": 0.4}
		"tired":  # eller dizde, soluk soluğa
			var br = sin(t * 6.0)
			var arms8 = _ik(n, "Left", _bone(n, "LeftLowerLeg") + Vector3.UP * 0.03 + fd * 0.05, 36.0)
			arms8.append_array(_ik(n, "Right", _bone(n, "RightLowerLeg") + Vector3.UP * 0.03 + fd * 0.05, 36.0))
			return {"arms": arms8, "fL": HALF, "fR": HALF, "spine": 36.0 + br * 3.0, "neck": -6.0 + br * 2.0}
		"seal":   # eller göğüs önünde birleşik (koç mührü)
			var c3 = _bone(n, "Chest") + fd * 0.2 * sc + Vector3.UP * 0.02
			var arms9 = _ik(n, "Left", c3 - right * 0.012)
			arms9.append_array(_ik(n, "Right", c3 + right * 0.012))
			return {"arms": arms9, "fL": [0.05, 0.05, 0.9, 0.95, 0.3], "fR": [0.05, 0.05, 0.9, 0.95, 0.3], "spine": 2.0, "neck": 4.0}
		"cheer":
			var w = sin(t * 10.0) * 0.12
			return {"arms": [["LeftUpperArm", Vector3(0.45, 0.88, 0.1)], ["LeftLowerArm", Vector3(0.2 + w, 0.97, 0.05)], ["RightUpperArm", Vector3(-0.45, 0.88, 0.1)], ["RightLowerArm", Vector3(-0.2 - w, 0.97, 0.05)]],
				"fL": OPEN, "fR": OPEN, "spine": -6.0, "neck": -10.0}
		"lift":   # çocuğu koltuk altlarından tutar
			var o3: Node3D = s["with"]
			var arms10 = []
			if is_instance_valid(o3):
				var ch = _bone(o3, "Chest")
				arms10 = _ik(n, "Left", ch - right * 0.15 * o3.model.age_scale)
				arms10.append_array(_ik(n, "Right", ch + right * 0.15 * o3.model.age_scale))
			return {"arms": arms10, "fL": HALF, "fR": HALF, "spine": -4.0, "neck": -12.0}
		"fly":    # kollar iki yana açık
			return {"arms": [["LeftUpperArm", Vector3(0.95, 0.25, 0.1)], ["LeftLowerArm", Vector3(0.97, 0.2, 0.1)], ["RightUpperArm", Vector3(-0.95, 0.25, 0.1)], ["RightLowerArm", Vector3(-0.97, 0.2, 0.1)]],
				"fL": OPEN, "fR": OPEN, "spine": -8.0, "neck": -10.0}
	return {"arms": [], "fL": HALF, "fR": HALF, "spine": 0.0, "neck": 0.0}
