class_name BeastCloak
extends Node
## Jinchūriki modları (X):
##   X dokun: Sürüm 1 pelerin (1→4 kuyruk) → Sürüm 2 → Tam Kuyruklu Canavar dönüşümü; en üst seviyede X = Kuyruklu Canavar Topu
##   X basılı (açıkken): modu kapat   •   X basılı (kapalıyken, savaş dışında): zihin dünyası
##   Tam dönüşümde: sol tık canavara özgü pençe, sağ tık Kuyruklu Canavar Topu
##   Canavarın kendi teknikleri (BijuuArts): [R] 1. teknik (Sürüm 1), [T] 2. teknik (3+ kuyruk), [C] 3. teknik (Sürüm 2 ve üstü)
## Güven (bağ) düşükken üst seviyeler canavarın kontrolü ele geçirmesine (öfke krizi) yol açabilir.

const NAMES := ["", "Sürüm 1 — Tek Kuyruk", "Sürüm 1 — İki Kuyruk", "Sürüm 1 — Üç Kuyruk", "Sürüm 1 — Dört Kuyruk", "Sürüm 2", "Tam Dönüşüm"]
const SAFE_TRUST := [0.0, 0.0, 0.0, 20.0, 35.0, 55.0, 70.0]

var p: Player
var c: PlayerCombat
var level = 0
var held = -1.0
var bomb_cd = 0.0
var rampage_t = 0.0
var cloak_mesh: MeshInstance3D
var mat: ShaderMaterial
var tails: Array = []        # [Node3D segmentleri]
var ears: Node3D
var tail_root: Node3D
var rig: BeastRig            # tam dönüşüm modeli
var saved_cam = 5.5
var t = 0.0
var tech_cd := {}            # teknik anahtarı -> kalan bekleme
const TECH_KEYS := ["throw", "tool_next", "charge"]
const TECH_LABEL := ["R", "T", "C"]
const TECH_NEED := [1, 3, 5]


func setup(combat: PlayerCombat) -> void:
	c = combat
	p = combat.p


func beast_id() -> String:
	return TailedBeasts.player_jinchuriki()


func max_level() -> int:
	var id = beast_id()
	if id == "":
		return 0
	if id == "raiju":
		return 2
	return 6


func chakra_col() -> Color:
	# Kurama ile tam bağ (Sürüm 2+): altın "Kurama Bağı" pelerini
	if beast_id() == "kurama" and level >= 5 and TailedBeasts.trust() >= 55.0:
		return Color(1.0, 0.82, 0.28)
	return BeastModels.INFO.get(beast_id(), BeastModels.INFO["kurama"])["chakra"]


func handle_input(e: InputEvent) -> bool:
	if e.is_action_pressed("beast"):
		if beast_id() == "":
			Hud.msg("İçinde mühürlü bir canavar yok. (Bir Kuyruklu Canavarı yenip kendine mühürle)", Color(0.7, 0.8, 1))
			return true
		held = 0.0
		return true
	if e.is_action_released("beast") and held >= 0.0:
		var h = held
		held = -1.0
		if h < 0.45 and rampage_t <= 0.0:
			_tap()
		return true
	if level == 6 and rampage_t <= 0.0:
		if e.is_action_pressed("attack"):
			_giant_swipe()
			return true
		if e.is_action_pressed("guard"):
			_bomb()
			return true
	return false


func _tap() -> void:
	if level < max_level():
		set_level(level + 1)
	else:
		_bomb()


func set_level(l: int) -> void:
	if l > 0 and level == 0 and c and c.modes and c.modes.has_method("exclusive"):
		c.modes.exclusive("beast")   # güç modları üst üste binmez
	var before = level
	if l <= 0:
		deactivate()
		return
	level = clampi(l, 0, max_level())
	var tr = TailedBeasts.trust()
	var col = chakra_col()
	Buffs.add("beast", 9999.0, {"melee": 1.2 + level * 0.15, "speed": 1.08 + level * 0.06, "armor": maxf(0.35, 1.0 - level * 0.1), "jutsu": 1.1 + level * 0.1})
	Hud.banner("JİNCHŪRİKİ: %s" % NAMES[level].to_upper(), "Güven %d/100%s" % [int(tr), "  —  DİKKAT: canavar kontrolü ele geçirebilir!" if tr < SAFE_TRUST[level] else ""], col)
	var hint = tech_hint()
	if hint != "":
		Hud.msg(hint, col.lightened(0.3), 6.0)
	Sfx.play("roar", p.global_position, 1.3 - level * 0.08, 0.7)
	FX.ring(p.global_position + Vector3.UP * 0.3, col, 6.0 + level * 3.0, 0.5)
	if Game.world:
		Game.world.env.add_shake(0.3 + level * 0.15)
	if level == 6:
		_full_transform()
	else:
		if before == 6:
			_end_transform()
		_ensure_cloak()
		_set_tails(mini(level, int(BeastModels.INFO.get(beast_id(), {}).get("tails", 4))) if level <= 4 else int(BeastModels.INFO.get(beast_id(), {}).get("tails", 4)))   # iki kuyruklu canavar 4 kuyruklu pelerin çıkarmasın
		mat.set_shader_parameter("col", chakra_col())
		mat.set_shader_parameter("dark", 0.85 if level == 5 and chakra_col() == BeastModels.INFO.get(beast_id(), {}).get("chakra", Color.BLACK) else 0.0)
		mat.set_shader_parameter("grow", 0.05 + level * 0.012)


func deactivate() -> void:
	if level == 6:
		_end_transform()
	level = 0
	Buffs.remove("beast")
	if is_instance_valid(cloak_mesh):
		cloak_mesh.queue_free()
	if is_instance_valid(tail_root):
		var ba = tail_root.get_parent()
		if ba:
			ba.queue_free()
	if is_instance_valid(ears):
		ears.queue_free()
	tails.clear()
	cloak_mesh = null
	tail_root = null
	Hud.msg("Chakra pelerini söndü.", Color(0.7, 0.8, 1))


# ------------------------------------------------------------------ pelerin görseli
func _ensure_cloak() -> void:
	if is_instance_valid(cloak_mesh) and cloak_mesh.get_parent() != null and cloak_mesh.get_parent() == p.model.skel:
		return
	var m = p.model
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/beast_cloak.gdshader")
	mat.set_shader_parameter("col", chakra_col())
	cloak_mesh = MeshInstance3D.new()
	cloak_mesh.mesh = m.body_mesh.mesh
	m.skel.add_child(cloak_mesh)
	cloak_mesh.skin = m.body_mesh.skin
	cloak_mesh.skeleton = cloak_mesh.get_path_to(m.skel)
	cloak_mesh.material_override = mat
	cloak_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# chakra kulakları (kafaya bağlı)
	var hc = m._head_center()
	var eb = MB.new()
	for sx in [-1.0, 1.0]:
		eb.add("cone", Vector3(0.09 * sx, 0.16, -0.02), Vector3(0.09, 0.22, 0.06), Color.WHITE, Vector3(0, 0, -18 * sx), 6)
	ears = m._mesh_on("Head", eb.build(null), Transform3D(Basis.IDENTITY, hc))
	ears.material_override = mat
	# kuyruk kökü (kalça, arkaya)
	var hp = m.skel.get_bone_global_rest(m.skel.find_bone("Hips")).origin
	var ba = m._attach("Hips", Transform3D(Basis.IDENTITY, hp + Vector3(0, 0.0, -0.16)))
	tail_root = ba.get_child(0)


func _set_tails(n: int) -> void:
	for tl in tails:
		if is_instance_valid(tl[0]):
			tl[0].queue_free()
	tails.clear()
	var length = 1.3 if level <= 4 else 2.2
	for i in n:
		var yaw = 0.0 if n == 1 else lerpf(-55.0, 55.0, float(i) / (n - 1))
		var root = Node3D.new()
		tail_root.add_child(root)
		root.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(180.0 + yaw), 0)
		var segs = [root]
		var parent = root
		var nseg = 7
		for k in nseg:
			var sg = Node3D.new()
			sg.position = Vector3(0, 0, length / nseg) if k > 0 else Vector3.ZERO
			parent.add_child(sg)
			var mi = MeshInstance3D.new()
			var sm = SphereMesh.new()
			var r = lerpf(0.13, 0.2, sin(float(k) / nseg * PI)) * (1.0 - pow(float(k) / nseg, 3.0) * 0.8)
			sm.radius = r
			sm.height = length / nseg * 1.8
			sm.radial_segments = 8
			sm.rings = 4
			mi.mesh = sm
			mi.rotation.x = PI * 0.5
			mi.position = Vector3(0, 0, length / nseg * 0.5)
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sg.add_child(mi)
			segs.append(sg)
			parent = sg
		tails.append(segs)


# ------------------------------------------------------------------ tam dönüşüm
func _full_transform() -> void:
	if is_instance_valid(cloak_mesh):
		cloak_mesh.visible = false
	if is_instance_valid(ears):
		ears.visible = false
	for tl in tails:
		if is_instance_valid(tl[0]):
			tl[0].visible = false
	var id = beast_id()
	var h = maxf(22.0, float(BeastModels.INFO[id]["height"]) * 0.4)
	rig = BeastModels.build(id, h)
	p.add_child(rig)
	rig.remove_colliders()   # oyuncunun kendi canavarı ona çarpmasın
	rig.show_weak(false)
	# kendi canavarın: kameraya yakın kısımlar (kuyruklar, sırt) noktalı şeffaflaşır, ekranı kapatmaz
	var fades := {}
	for mi in rig.find_children("*", "MeshInstance3D", true, false):
		var m = mi.material_override
		if m is ShaderMaterial and (m as ShaderMaterial).shader and String((m as ShaderMaterial).shader.resource_path).ends_with("beast.gdshader"):
			if not fades.has(m):
				fades[m] = m.duplicate()
				fades[m].set_shader_parameter("near_fade", h * 1.1)
			mi.material_override = fades[m]
	p.model.visible = false
	saved_cam = p.cam_dist
	# kamera canavarın boyuna göre: omuz üstünden, tüm gövde ve önündeki alan görünür; tekerle h*0.9..h*3 arası
	p.cam_range = Vector2(h * 1.2, h * 3.5)
	p.cam_dist = h * 1.8
	p.cam_lift = h * 0.8
	p.cam_giant = true
	p.cam.far = maxf(p.cam.far, 6000.0)
	Buffs.add("beast", 9999.0, {"melee": 3.5, "speed": 2.0, "armor": 0.25, "jutsu": 1.8})
	FX.smoke_puff(p.global_position + Vector3.UP * h * 0.4, h * 0.25, 30)
	Hud.banner("KUYRUKLU CANAVAR", "%s ile tam dönüşüm!  Sol tık: pençe  •  Sağ tık / X: Kuyruklu Canavar Topu" % BeastModels.INFO[id]["name"].split(" — ")[0], chakra_col())


func _end_transform() -> void:
	if is_instance_valid(rig):
		FX.smoke_puff(p.global_position + Vector3.UP * 3.0, 4.0, 30)
		rig.queue_free()
	rig = null
	p.model.visible = true
	p.cam_dist = saved_cam
	p.cam_lift = 0.0
	p.cam_range = Vector2(2.2, 14.0)
	p.cam_giant = false
	if is_instance_valid(cloak_mesh):
		cloak_mesh.visible = true
	if is_instance_valid(ears):
		ears.visible = true


func _giant_swipe() -> void:
	if not is_instance_valid(rig):
		return
	rig.play_action(["swipe_l", "swipe_r"].pick_random(), 0.9)
	var h = rig.height_m
	var dir = p.cam_forward()
	var id = beast_id()
	get_tree().create_timer(0.35).timeout.connect(func():
		var pt = p.global_position + dir * h * 0.5 + Vector3.UP * h * 0.2
		var got = BijuuArts.melee(p, id, pt, h * 0.3, 90.0 * Stats.melee_mult(Game.profile), dir)
		# pençenin önündeki yelpaze alan: ayak dibindeki küçük düşmanlar da ezilir
		Combat.hit_zone(p, p.global_position, dir, h * 0.85, 60.0, h * 1.1, {"dmg": 90.0 * Stats.melee_mult(Game.profile), "knock": 30.0, "launch": 6.0, "kind": "heavy", "dir": dir}, got)
		Sfx.play("whoosh", pt, 0.5))


## Kuyruklu Canavar Topu (pelerin seviyesine göre boy/hasar)
func _bomb() -> void:
	if bomb_cd > 0.0:
		Hud.msg("Kuyruklu Canavar Topu hazırlanıyor (%.1f)" % bomb_cd, chakra_col())
		return
	if level < 2:
		Hud.msg("Top için en az iki kuyruklu pelerin gerekir.", chakra_col())
		return
	var cost = 25.0 + level * 8.0
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok!", Color(0.6, 0.8, 1))
		return
	p.chakra -= cost
	bomb_cd = 8.0 - level * 0.6
	var from: Vector3
	var size: float
	if level == 6 and is_instance_valid(rig):
		rig.play_action("ball", 1.2)
		from = rig.mouth_pos()
		size = rig.height_m * 0.07
	else:
		from = p.global_position + Vector3.UP * 1.6 + p.face_dir() * 1.2
		size = 0.6 + level * 0.25
	var dir = (p.aim_point() - from).normalized()
	var dmg = (70.0 + level * 35.0) * Stats.melee_mult(Game.profile)
	var delay = 0.9 if level == 6 else 0.4
	if beast_id() == "gyuki":
		# Gyūki: Renzoku Bijūdama — art arda dört küçük top
		for i in 4:
			get_tree().create_timer(delay + i * 0.28).timeout.connect(func():
				var f3 = rig.mouth_pos() if (level == 6 and is_instance_valid(rig)) else p.global_position + Vector3.UP * 1.6 + p.face_dir() * 1.2
				var d3 = (p.aim_point() - f3).normalized()
				TailedBeasts.fire_ball(p, f3, d3, size * 0.6, chakra_col(), dmg * 0.45, 90.0))
		return
	FX.burst(from, {"amount": 50, "life": delay, "tex": FX.tex_spark, "add": true, "size": size, "vmin": -6, "vmax": -2, "gravity": Vector3.ZERO,
		"colors": [Color(0.7, 0.4, 1.0, 0.9), Color(0.1, 0.0, 0.2, 0.0)]})
	get_tree().create_timer(delay).timeout.connect(func():
		var f2 = rig.mouth_pos() if (level == 6 and is_instance_valid(rig)) else from
		TailedBeasts.fire_ball(p, f2, dir, size, chakra_col(), dmg, 80.0))


# ------------------------------------------------------------------ canavarın kendi teknikleri (BijuuArts)
## HUD ipucu: açık teknikler ve tuşları
func tech_hint() -> String:
	var l = BijuuArts.techs(beast_id())
	var parts = []
	for i in l.size():
		if level >= TECH_NEED[i]:
			parts.append(l[i]["name"])
	if parts.is_empty():
		return ""
	return "Slottan kullanılabilir: " + "  •  ".join(parts) + ("  •  [Sol] pençe  [Sağ] Kuyruklu Canavar Topu" if level == 6 else "")


func _scale() -> float:
	if level == 6 and is_instance_valid(rig):
		return rig.height_m / 7.0
	return 1.0 + level * 0.12


func _tech(i: int) -> void:
	var l = BijuuArts.techs(beast_id())
	if i >= l.size():
		return
	var tdef: Dictionary = l[i]
	if level < TECH_NEED[i]:
		Hud.msg("%s için en az: %s" % [tdef["name"], NAMES[TECH_NEED[i]]], chakra_col())
		return
	var key: String = tdef["key"]
	if float(tech_cd.get(key, 0.0)) > 0.0:
		Hud.msg("%s hazırlanıyor (%.1f)" % [tdef["name"], float(tech_cd[key])], chakra_col())
		return
	var cost = float(tdef["cost"]) * (1.6 if level == 6 else 1.0)
	if p.chakra < cost:
		Hud.msg("Yeterli chakra yok!", Color(0.6, 0.8, 1))
		return
	p.chakra -= cost
	tech_cd[key] = float(tdef["cd"]) * (0.75 if level == 6 else 1.0)
	var aim = p.aim_point()
	var lt = c.lock_target
	if lt and is_instance_valid(lt) and not lt.is_dead():
		aim = lt.global_position + Vector3.UP * float(lt.height) * 0.5   # kilitliyse hedefe
	var v = aim - p.global_position
	p.facing = atan2(-v.x, -v.z)
	var giant = level == 6 and is_instance_valid(rig)
	var s = _scale()
	var from = rig.mouth_pos() if giant else p.global_position + Vector3.UP * 1.4 + p.face_dir() * 1.0
	if giant:
		rig.rotation.y = p.facing
		rig.play_action({"neko_pounce": "charge", "shell_roll": "charge", "horn_ram": "charge", "kaen_breath": "roar", "sumi": "roar", "biju_hoko": "roar",
			"renkudan": "ball", "bijudama_rasengan": "ball"}.get(key, ["swipe_l", "swipe_r"].pick_random()), 1.0)
	else:
		p.model.play("throw", 0.05, 1.6, true)
	var dmg = (45.0 + level * 14.0) * Stats.jutsu_mult(Game.profile) * (2.4 if giant else 1.0)
	var ctx = {"s": s, "dmg": dmg, "from": from, "aim": aim, "tgt": c.lock_target, "col": chakra_col()}
	if giant:
		ctx["base_h"] = rig.height_m * 0.45
		ctx["from_fn"] = func() -> Vector3: return rig.mouth_pos() if is_instance_valid(rig) else p.global_position + Vector3.UP * 2.0
	BijuuArts.use(p, beast_id(), key, ctx)
	if Game.world:
		Game.world.env.add_shake(0.15 + (0.4 if giant else 0.0))


# ------------------------------------------------------------------ öfke krizi (güven düşükken)
func _rampage() -> void:
	rampage_t = 4.0
	p.input_locked = maxf(p.input_locked, 4.0)
	TailedBeasts.add_trust(-2.0)
	Hud.banner("KONTROLÜ KAYBEDİYORSUN!", "Canavarın öfkesi bedenini ele geçirdi...", Color(1, 0.15, 0.1))
	Sfx.play("roar", p.global_position, 0.8)
	if Game.world:
		Game.world.env.set_tint(Color(0.8, 0.05, 0.0, 0.25))
	for i in 4:
		get_tree().create_timer(0.6 + i * 0.8).timeout.connect(func():
			if level == 0: return
			Combat.hit_sphere(p, p.global_position + Vector3.UP, 8.0 + level * 2.0, {"dmg": 30.0 + level * 10.0, "knock": 20.0, "launch": 6.0, "kind": "heavy"})
			FX.ring(p.global_position + Vector3.UP * 0.3, chakra_col(), 10.0 + level * 3.0, 0.4)
			p.hp -= 4.0)


func _process(dt: float) -> void:
	if Game.paused or p == null:
		return
	t += dt
	bomb_cd = maxf(0.0, bomb_cd - dt)
	for k in tech_cd.keys():
		tech_cd[k] = float(tech_cd[k]) - dt
		if tech_cd[k] <= 0.0:
			tech_cd.erase(k)
	if held >= 0.0:
		held += dt
		if held >= 0.45 and level > 0:
			held = -1.0
			set_level(0)
		elif held >= 1.0 and level == 0:
			held = -1.0
			if Combat.nearest_enemy(p, 40.0) == null:
				TailedBeasts.enter_mindscape()
			else:
				Hud.msg("Savaşın ortasında zihin dünyasına giremezsin.", Color(0.8, 0.8, 0.8))
	if rampage_t > 0.0:
		rampage_t -= dt
		if rampage_t <= 0.0 and Game.world:
			Game.world.env.set_tint(Color(0, 0, 0, 0))
	if level == 0:
		return
	# chakra / beden
	if level == 6:
		p.chakra -= 5.0 * dt
		if p.chakra <= 0.0:
			p.chakra = 0.0
			Hud.msg("Chakra tükendi, dönüşüm çözüldü.", chakra_col())
			set_level(4 if max_level() >= 4 else 1)
			return
	else:
		p.chakra = minf(p.max_chakra, p.chakra + (2.0 + level * 2.0) * dt)
	var tr = TailedBeasts.trust()
	var unbound = bool(TailedBeasts.beasts().get(beast_id(), {}).get("unbound", false))
	if level >= 5 and tr < 55.0 and not unbound:
		p.hp -= 1.5 * dt   # pelerin bedeni yakıyor
	var risk = maxf(0.0, SAFE_TRUST[level] - tr) / 100.0
	if unbound:
		risk = 0.0
	if risk > 0.0 and rampage_t <= 0.0 and randf() < risk * 0.12 * dt:
		_rampage()
	# kuyruk dalgası
	for i in tails.size():
		var segs: Array = tails[i]
		for k in range(1, segs.size()):
			segs[k].rotation.y = sin(t * 3.0 - k * 0.6 + i) * 0.22
			segs[k].rotation.x = sin(t * 2.3 - k * 0.5 + i * 1.7) * 0.15
	# tam dönüşüm modeli oyuncuyu izler
	if level == 6 and is_instance_valid(rig):
		rig.rotation.y = p.facing
		rig.move_speed = clampf(Vector2(p.velocity.x, p.velocity.z).length() / 15.0, 0.0, 1.0)
