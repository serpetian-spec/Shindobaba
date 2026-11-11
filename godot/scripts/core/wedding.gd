class_name Wedding
extends ScenePoser
## Düğün töreni (Shinto usulü, gerçek sahne): torii önünde kırmızı yol, iki yanda konuklar (dostların, eşinin ailesi, köy ninjaları),
## nikâhı köyün Kage'si (eşin klanlıysa klan büyüğü) kıyar. Sen yolu yürürsün, ardından eşin gelin/damat kıyafetiyle gelir;
## san-san-kudo (üçer yudum sake), yemin + karşılıklı eğilme, sarılma; konuklar alkışlar, çiçek yaprakları yağar.
## Rakip klanlar evleniyorsa konuklardan biri törene itiraz eder, nikâhı kıyan susturur.

const RM = preload("res://scripts/world/road_map.gd")
const RIVAL_CLANS := [["uchiha", "senju"], ["uchiha", "hyuga"], ["hozuki", "yuki"], ["kaguya", "uchiha"]]

static var cur: Wedding

var sid := ""
var vid := ""
var c := Vector3.ZERO      # tören alanı merkezi (yolun ortası)
var yaw := 0.0
var officiant: Node3D
var bride: Node3D          # eşin (gelin / damat)
var guests: Array = []
var objector: Node3D
var focus: Node3D
var busy := false
var done := false
var started := false
var cheer := false
var props: Node3D
var petals: CPUParticles3D
var _life := 0.0
var _lane: Array = []
var plat_y := 0.0
var miko: Node3D
var holder: Node3D
var drummer: Node3D
var drum_on := false
var _beat := 0.0
var _saved_look = null
var escort := false


# ------------------------------------------------------------------ durum
static func pr() -> Dictionary:
	return Game.profile


static func pending() -> bool:
	return pr().has("wedding") and Friends.all().has(String(pr()["wedding"].get("id", "")))


static func site() -> Vector3:
	var w: Dictionary = pr().get("wedding", {})
	if not w.has("pos"):
		return Vector3.INF
	var p = Game.from_map(Vector2(float(w["pos"][0]), float(w["pos"][1])))
	p.y = Game.ground_height(p.x, p.z)
	return p


## Teklif kabul edildi: tören yeri seçilir ve haritada işaretlenir (kaçaksan tören yok: false)
static func plan(id: String) -> bool:
	if Orgs.is_rogue() or Game.player == null:
		return false
	var home = Progress.home()
	var pt = Exams.find_point(["shrine"], home)
	if pt == Vector3.ZERO or pt.distance_to(Game.player.global_position) > 2500.0:
		pt = HomeLife.door_pos()
		if pt == Vector3.INF:
			pt = Exams.find_point(["training"], home)
	if pt == Vector3.ZERO or pt.distance_to(Game.player.global_position) > 2500.0:
		pt = Game.player.global_position
	pt = Missions.open_ground(pt + Vector3(22, 0, 22), 60.0)
	var mp = Game.to_map(pt)
	pr()["wedding"] = {"id": id, "pos": [mp.x, mp.y]}
	mark()
	return true


static func mark() -> void:
	var p = site()
	if p == Vector3.INF:
		return
	Game.profile["waypoint"] = [p.x, p.y, p.z, "Düğün töreni"]
	Game.profile["track"] = "waypoint"
	Hud.msg("Tören alanı haritada işaretlendi. Konuklar seni bekliyor.", Color(1, 0.75, 0.85))


static func tick(_dt: float) -> void:
	if is_instance_valid(cur) or not pending() or Game.player == null:
		return
	if Interiors.inst and Interiors.inst.inside != "":
		return
	var p = site()
	if p == Vector3.INF or p.distance_to(Game.player.global_position) > 130.0:
		return
	var w = Wedding.new()
	w.sid = String(pr()["wedding"]["id"])
	w.vid = Progress.home()
	w.c = p
	cur = w
	Friends.inst().get_parent().add_child(w)


# ------------------------------------------------------------------ kurulum
func P(x: float, z: float, lift := 0.0) -> Vector3:
	var q = c + Vector3(x, 0, z).rotated(Vector3.UP, yaw)
	q.y = (plat_y if _on_plat(x, z) else Game.ground_height(q.x, q.z)) + lift
	return q


## Tören sahnesi (düz ahşap platform): yerel x ±4.6, z -10.2 .. -2.4
func _on_plat(x: float, z: float) -> bool:
	return plat_y != 0.0 and absf(x) <= 4.6 and z <= -1.75 and z >= -10.2


func _local(p: Vector3) -> Vector3:
	return (p - c).rotated(Vector3.UP, -yaw)


func _floor_y(p: Vector3) -> float:
	var l = _local(p)
	if plat_y != 0.0 and absf(l.x) <= 1.6 and l.z > -2.4 and l.z <= 0.0:   # basamak rampası (çarpışma kamasıyla aynı eğim)
		return maxf(Game.ground_height(p.x, p.z), plat_y - 0.45 * (l.z + 2.4) / 2.4)
	return plat_y if _on_plat(l.x, l.z) else Game.ground_height(p.x, p.z)


func _ready() -> void:
	# yol oyuncunun geldiği yöne açılır
	var to = Game.player.global_position - c
	yaw = atan2(to.x, to.z)
	# sahne: altındaki zeminin en yüksek noktasına oturan düz platform (eğimli arazide gömülmez)
	var top := -1e9
	for gx in [-4.6, 0.0, 4.6]:
		for gz in [-10.2, -6.3, -2.4]:
			var q = c + Vector3(gx, 0, gz).rotated(Vector3.UP, yaw)
			top = maxf(top, Game.ground_height(q.x, q.z))
	plat_y = top + 0.3
	_build_site()
	_spawn_people()


func _exit_tree() -> void:
	if cur == self:
		cur = null
	if not _lane.is_empty():
		RM.lanes.erase(_lane)
		RM.lanes_dirty = true
	_release_player()
	if _saved_look != null:
		_dress_player(false)
	for n in [officiant, bride, objector, miko, holder, drummer] + guests:
		if is_instance_valid(n):
			n.queue_free()


func _pm(b: MB, at: Vector3, yaw_add := 0.0) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.mesh = b.build(mat)
	props.add_child(m)
	m.global_position = at
	m.rotation.y = yaw + yaw_add
	return m


func _build_site() -> void:
	props = Node3D.new()
	add_child(props)
	props.top_level = true
	# tören alanında çimen biçilir (yol ve konukların durduğu şerit)
	var la = P(0, 13.0)
	var lb = P(0, -9.0)
	_lane = [Vector2(la.x, la.z), Vector2(lb.x, lb.z), 6.5, false]
	RM.lanes.append(_lane)
	RM.lanes_dirty = true
	# kırmızı yol
	var red = Color(0.75, 0.1, 0.12)
	for i in 16:
		var b = MB.new()
		b.add("box", Vector3(0, 0.03, 0), Vector3(1.7, 0.05, 1.02), red)
		b.add("box", Vector3(-0.82, 0.035, 0), Vector3(0.07, 0.05, 1.02), Color(0.95, 0.8, 0.3))
		b.add("box", Vector3(0.82, 0.035, 0), Vector3(0.07, 0.05, 1.02), Color(0.95, 0.8, 0.3))
		_pm(b, P(0, 10.0 - i))
	# torii (girişte: altından geçilerek yola çıkılır)
	var t = MB.new()
	var vr = Color(0.82, 0.16, 0.1)
	for sx in [-1.0, 1.0]:
		t.add("cyl", Vector3(sx * 2.1, 2.3, 0), Vector3(0.36, 4.6, 0.36), vr, Vector3(0, 0, -sx * 2.0), 12)
		t.add("cyl", Vector3(sx * 2.15, 0.25, 0), Vector3(0.5, 0.5, 0.5), Color(0.15, 0.15, 0.16), Vector3.ZERO, 12)
	t.add("box", Vector3(0, 4.75, 0), Vector3(5.8, 0.3, 0.42), vr)
	t.add("box", Vector3(0, 5.0, 0), Vector3(6.4, 0.2, 0.55), Color(0.12, 0.12, 0.13))
	for sx in [-1.0, 1.0]:
		t.add("box", Vector3(sx * 3.1, 5.1, 0), Vector3(0.5, 0.16, 0.55), Color(0.12, 0.12, 0.13), Vector3(0, 0, sx * 14.0))
	t.add("box", Vector3(0, 3.9, 0), Vector3(4.6, 0.24, 0.3), vr)
	t.add("box", Vector3(0, 4.32, 0), Vector3(0.5, 0.62, 0.12), Color(0.12, 0.12, 0.13))
	_pm(t, P(0, 11.2))
	var body = StaticBody3D.new()
	props.add_child(body)
	for sx in [-1.0, 1.0]:
		var cs = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = 0.25
		cyl.height = 4.6
		cs.shape = cyl
		body.add_child(cs)
		cs.global_position = P(sx * 2.1, 11.2, 2.3)
	# ahşap tören sahnesi + basamak (katı)
	var pc = c + Vector3(0, 0, -6.3).rotated(Vector3.UP, yaw)
	var wood = Color(0.55, 0.38, 0.22)
	var pl = MB.new()
	pl.add("box", Vector3(0, -0.9, 0), Vector3(9.4, 1.8, 8.0), wood.darkened(0.25))
	pl.add("box", Vector3(0, -0.04, 0), Vector3(9.6, 0.08, 8.2), wood)
	for k in 9:
		pl.add("box", Vector3(-4.2 + k * 1.05, 0.002, 0), Vector3(0.03, 0.01, 8.2), wood.darkened(0.3))
	pl.add("box", Vector3(0, -0.17, 4.35), Vector3(3.2, 0.14, 0.5), wood.lightened(0.08))
	pl.add("box", Vector3(0, -1.0, 4.35), Vector3(3.2, 1.6, 0.5), wood.darkened(0.25))
	pl.add("box", Vector3(0, -0.27, 4.85), Vector3(3.2, 0.14, 0.5), wood.lightened(0.04))   # alt basamak
	pl.add("box", Vector3(0, -1.1, 4.85), Vector3(3.2, 1.6, 0.5), wood.darkened(0.25))
	_pm(pl, Vector3(pc.x, plat_y, pc.z))
	# çarpışma: sahne kutusu + basamakların üstünde eğik rampa (yürüyerek çıkılır, takılmaz)
	var cs2 = CollisionShape3D.new()
	var bs = BoxShape3D.new()
	bs.size = Vector3(9.4, 1.8, 8.0)
	cs2.shape = bs
	body.add_child(cs2)
	cs2.global_position = Vector3(pc.x, plat_y - 0.9, pc.z)
	cs2.global_basis = Basis(Vector3.UP, yaw)
	# rampa: köşe noktalarıyla verilen kama (sahne kenarında sahne hizası, 2.3 m ötede zeminin altı) -> eğim yönü şaşmaz
	var cs3 = CollisionShape3D.new()
	var wedge = ConvexPolygonShape3D.new()
	wedge.points = PackedVector3Array([Vector3(-1.6, 0.0, 3.9), Vector3(1.6, 0.0, 3.9), Vector3(-1.6, -0.45, 6.3), Vector3(1.6, -0.45, 6.3), Vector3(-1.6, -1.2, 3.9), Vector3(1.6, -1.2, 3.9), Vector3(-1.6, -1.2, 6.3), Vector3(1.6, -1.2, 6.3)])
	cs3.shape = wedge
	body.add_child(cs3)
	cs3.global_position = Vector3(pc.x, plat_y, pc.z)
	cs3.global_basis = Basis(Vector3.UP, yaw)
	# tapınak köşkü (haiden): dört direk, kat kat koyu çatı, arkada kapaklı sunak, kutsal halat ve kâğıt şeritler, adak sandığı
	var h = MB.new()
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			h.add("cyl", Vector3(sx * 2.6, 1.7, sz * 1.1), Vector3(0.3, 3.4, 0.3), vr, Vector3.ZERO, 10)
	h.add("box", Vector3(0, 3.45, 0), Vector3(6.0, 0.22, 3.0), vr)
	var rc = Color(0.16, 0.17, 0.2)
	for k in 4:
		h.add("box", Vector3(0, 3.7 + k * 0.26, 0), Vector3(7.4 - k * 1.5, 0.28, 4.4 - k * 0.9), rc.lightened(k * 0.03))
	h.add("box", Vector3(0, 4.78, 0), Vector3(2.6, 0.2, 0.5), rc)
	for sx in [-1.0, 1.0]:
		h.add("box", Vector3(sx * 3.85, 3.78, 0), Vector3(0.7, 0.2, 4.4), rc, Vector3(0, 0, sx * 16.0))
		h.add("box", Vector3(sx * 1.3, 4.95, 0), Vector3(0.14, 0.5, 0.14), Color(0.9, 0.75, 0.3), Vector3(0, 0, -sx * 25.0))
	h.add("box", Vector3(0, 1.6, -1.15), Vector3(5.2, 3.2, 0.12), Color(0.93, 0.9, 0.82))
	h.add("box", Vector3(0, 1.3, -1.05), Vector3(1.6, 2.2, 0.1), Color(0.4, 0.26, 0.14))
	h.add("box", Vector3(0, 1.3, -0.99), Vector3(0.04, 2.2, 0.02), Color(0.2, 0.13, 0.07))
	h.add("sphere", Vector3(0, 2.75, -0.98), Vector3(0.5, 0.5, 0.06), Color(0.95, 0.8, 0.3), Vector3.ZERO, 12)
	h.add("cyl", Vector3(0, 3.1, 1.15), Vector3(0.16, 5.0, 0.16), Color(0.86, 0.78, 0.5), Vector3(0, 0, 90), 8)
	for k in 6:
		h.add("box", Vector3(-2.0 + k * 0.8, 2.78, 1.18), Vector3(0.13, 0.46, 0.02), Color(0.98, 0.98, 0.96), Vector3(0, 0, 12 if k % 2 == 0 else -12))
	h.add("box", Vector3(0, 0.3, -0.55), Vector3(1.3, 0.6, 0.6), Color(0.42, 0.28, 0.15))
	for k in 6:
		h.add("box", Vector3(-0.5 + k * 0.2, 0.61, -0.55), Vector3(0.05, 0.03, 0.6), Color(0.25, 0.16, 0.08))
	_pm(h, P(0, -8.6))
	# konuk sıraları (kırmızı örtülü)
	for row in 4:
		for sx in [-1.0, 1.0]:
			var be = MB.new()
			be.add("box", Vector3(0, 0.36, 0), Vector3(2.7, 0.08, 0.5), Color(0.72, 0.12, 0.12))
			be.add("box", Vector3(0, 0.3, 0), Vector3(2.6, 0.06, 0.46), Color(0.45, 0.3, 0.18))
			for lx in [-1.15, 1.15]:
				be.add("box", Vector3(lx, 0.14, 0), Vector3(0.08, 0.28, 0.42), Color(0.4, 0.26, 0.15))
			_pm(be, P(sx * 3.3, 5.4 - row * 2.1), PI * 0.5)
	# taiko davulu (sahnenin sol önünde)
	var dr = MB.new()
	dr.add("cyl", Vector3(0, 1.0, 0), Vector3(0.95, 0.8, 0.95), Color(0.5, 0.2, 0.12), Vector3(90, 0, 0), 14)
	dr.add("cyl", Vector3(0, 1.0, 0.41), Vector3(0.9, 0.02, 0.9), Color(0.93, 0.88, 0.76), Vector3(90, 0, 0), 14)
	dr.add("cyl", Vector3(0, 1.0, -0.41), Vector3(0.9, 0.02, 0.9), Color(0.93, 0.88, 0.76), Vector3(90, 0, 0), 14)
	for lx in [-0.4, 0.4]:
		dr.add("box", Vector3(lx, 0.3, 0), Vector3(0.1, 0.6, 0.7), Color(0.3, 0.2, 0.12))
	_pm(dr, P(-3.6, -4.2))
	# sake masası: beyaz örtü, üç kat kırmızı kupa, sake testisi
	var a = MB.new()
	a.add("box", Vector3(0, 0.36, 0), Vector3(1.1, 0.72, 0.6), Color(0.97, 0.97, 0.95))
	a.add("box", Vector3(0, 0.74, 0), Vector3(1.16, 0.04, 0.66), Color(0.75, 0.1, 0.12))
	for k in 3:
		a.add("cyl", Vector3(-0.2, 0.775 + k * 0.022, 0), Vector3(0.2 - k * 0.04, 0.02, 0.2 - k * 0.04), Color(0.8, 0.12, 0.1), Vector3.ZERO, 12)
	a.add("cyl", Vector3(0.25, 0.85, 0), Vector3(0.13, 0.2, 0.13), Color(0.95, 0.95, 0.92), Vector3.ZERO, 10)
	a.add("cyl", Vector3(0.25, 0.98, 0), Vector3(0.05, 0.08, 0.05), Color(0.95, 0.95, 0.92), Vector3.ZERO, 8)
	_pm(a, P(0, -5.6))
	# yol boyunca fenerler + sakura dalı vazoları
	for i in 4:
		for sx in [-1.0, 1.0]:
			var l = MB.new()
			l.add("cyl", Vector3(0, 0.75, 0), Vector3(0.07, 1.5, 0.07), Color(0.2, 0.15, 0.1), Vector3.ZERO, 6)
			l.add("cyl", Vector3(0, 1.62, 0), Vector3(0.3, 0.4, 0.3), Color(1.0, 0.86, 0.6), Vector3.ZERO, 8)
			l.add("cyl", Vector3(0, 1.84, 0), Vector3(0.34, 0.05, 0.34), Color(0.75, 0.1, 0.12), Vector3.ZERO, 8)
			l.add("cyl", Vector3(0, 1.4, 0), Vector3(0.34, 0.05, 0.34), Color(0.75, 0.1, 0.12), Vector3.ZERO, 8)
			_pm(l, P(sx * 1.35, 9.6 - i * 3.6))
			var ol = OmniLight3D.new()
			ol.light_color = Color(1.0, 0.8, 0.5)
			ol.light_energy = 0.7
			ol.omni_range = 5.0
			props.add_child(ol)
			ol.global_position = P(sx * 1.35, 9.6 - i * 3.6, 1.7)
	# çiçek yaprakları (tören boyunca hafif, kutlamada sağanak)
	petals = CPUParticles3D.new()
	petals.amount = 90
	petals.lifetime = 6.0
	petals.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	petals.emission_box_extents = Vector3(6, 0.3, 9)
	petals.direction = Vector3(0.3, -1, 0.1)
	petals.spread = 25.0
	petals.gravity = Vector3(0, -0.5, 0)
	petals.initial_velocity_min = 0.3
	petals.initial_velocity_max = 0.8
	petals.angular_velocity_min = -90.0
	petals.angular_velocity_max = 90.0
	var qm = QuadMesh.new()
	qm.size = Vector2(0.09, 0.07)
	var pm = StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.albedo_color = Color(1.0, 0.72, 0.8)
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = pm
	petals.mesh = qm
	petals.amount = 40
	props.add_child(petals)
	petals.global_position = P(0, 1.0, 6.0)


func _person(nm: String, lk: Dictionary, at: Vector3, face_to: Vector3) -> Villager:
	var v = Villager.new()
	v.role = "guard"
	v.display_override = nm
	v.look_extra = lk
	get_parent().add_child(v)
	v.global_position = at
	v.home = at
	v.goal = at
	v.wander_r = 0.0
	v.fixed_face = true
	var to = face_to - at
	v.facing = atan2(-to.x, -to.z)
	v.stand_face = v.facing
	if v.model:
		v.model.rotation.y = v.facing
	return v


func _spawn_people() -> void:
	var f: Dictionary = Friends.all()[sid]
	var clan = String(f.get("clan", ""))
	var vname = String(Game.village(vid).get("name", "Köy"))
	# nikâhı kıyan
	if clan != "" and clan != String(pr().get("clan", "")):
		var el = ClanWorld.clan_look(clan, "jonin", vid, false, "adult")
		el["top_style"] = "kimono"
		el["hair"] = Color(0.82, 0.82, 0.84)
		officiant = _person("%s Klan Büyüğü" % ClanWorld.person_name(clan, false).split(" ")[0], el, P(0, -6.6), P(0, 0))
	else:
		var kl = KageAttire.look(vid)
		kl["village"] = vid
		officiant = _person(Kage.kage_name(vid), kl, P(0, -6.6), P(0, 0))
		KageAttire.hat(officiant.model, vid)
	# eş: gelin / damat kıyafeti
	var lk = Friends.look_of(f)
	var fem = String(lk.get("gender", "m")) == "f"
	lk["vest"] = null
	lk["band"] = null
	if fem:
		# beyaz gelinlik (oyundaki gelinlik takımı, beyaza boyanmış) + uzun beyaz eldiven
		Gear.preview_set_look(lk, "ss_gelinlik")
		var wh = Color(0.98, 0.97, 0.96)
		for k in ["top", "top2", "pants", "outer", "acc", "sandal", "wraps"]:
			lk[k] = wh
		lk["outer2"] = Color(0.96, 0.86, 0.88)
	else:
		# montsuki-hakama: siyah kimono üst, gri hakama
		Gear.preview_set_look(lk, "set_kenshi")
		lk["top"] = Color(0.08, 0.08, 0.1)
		lk["top2"] = Color(0.92, 0.92, 0.9)
		lk["pants"] = Color(0.42, 0.42, 0.45)
		lk.erase("acc")
	lk["age"] = "adult"
	bride = _person(String(f["name"]), lk, P(0, 15.0), P(0, 0))
	bride.set_physics_process(false)
	bride.model.play("idle", 0.0)
	# konuklar: eşinin ailesi (ön sıra), dostların, köy ninjaları
	var list: Array = []
	for m in f.get("family", []):
		if m.get("alive", true) and String(m["rel"]) in ["Babası", "Annesi", "Kardeşi", "Ablası", "Ağabeyi"]:
			var mf = String(m["rel"]) in ["Annesi", "Ablası"]
			var ml = ClanWorld.clan_look(clan, "genin", vid, mf, "adult")
			ml["top_style"] = "kimono"
			ml["vest"] = null
			ml["band"] = null
			list.append([String(m["name"]), ml])
	for oid in Friends.all():
		var o: Dictionary = Friends.all()[oid]
		if oid != sid and String(o.get("status", "")) == "" and int(o.get("bond", 0)) >= 0 and Friends.available(o) and list.size() < 9:
			list.append([String(o["name"]), Friends.look_of(o)])
	while list.size() < 16:
		var gl = Outfits.roll(["chunin", "chunin", "jonin", "genin"].pick_random(), vid)
		gl["gender"] = ["m", "f"].pick_random()
		gl["age"] = "adult"
		list.append(["%s ninjası" % vname, gl])
	for i in list.size():
		var sx = -1.0 if i % 2 == 0 else 1.0
		var row = int(i / 4)
		var seat = int(i / 2) % 2
		var gz = 5.4 - row * 2.1 + (0.62 if seat == 0 else -0.62)
		var g = _person(String(list[i][0]), list[i][1], P(sx * 3.3, gz), P(0, gz))
		g.set_physics_process(false)
		guests.append(g)
		_pose(g, "rest", {"anim": "sit", "bench": 0.4})
	# tapınak görevlisi (miko), şemsiye tutan, davulcu
	var ml2 = Outfits.roll("genin", vid)
	ml2["gender"] = "f"
	ml2["age"] = "adult"
	ml2["vest"] = null
	ml2["band"] = null
	Gear.preview_set_look(ml2, "set_kenshi")
	ml2["top"] = Color(0.98, 0.98, 0.97)
	ml2["top2"] = Color(0.98, 0.98, 0.97)
	ml2["pants"] = Color(0.8, 0.12, 0.12)
	ml2.erase("acc")
	miko = _person("Miko", ml2, P(-0.5, 13.0), P(0, 0))
	var hl2 = ml2.duplicate()
	hl2["gender"] = "m"
	hl2["top"] = Color(0.2, 0.22, 0.3)
	hl2["top2"] = Color(0.9, 0.9, 0.88)
	hl2["pants"] = Color(0.3, 0.3, 0.34)
	holder = _person("Tapınak görevlisi", hl2, P(0.8, 16.0), P(0, 0))
	drummer = _person("Davulcu", hl2.duplicate(), P(-3.6, -3.3), P(-3.6, -4.2))
	for n in [miko, holder, drummer]:
		n.set_physics_process(false)
		n.model.play("idle", 0.0)
	_pose(holder, "wagasa", {"anim": "idle"})
	# rakip klan: itirazcı arka sırada bekler
	var mine = String(pr().get("clan", ""))
	if clan != "" and mine != "" and (RIVAL_CLANS.has([mine, clan]) or RIVAL_CLANS.has([clan, mine])):
		var ol = ClanWorld.clan_look(clan, "jonin", vid, false, "adult")
		objector = _person(ClanWorld.person_name(clan, false), ol, P(5.6, 7.5), P(0, 0))


# ------------------------------------------------------------------ akış
func _process(dt: float) -> void:
	_apply_poses(dt)
	_life += dt
	_tick_extras(dt)
	var pl = Game.player
	if pl == null or not is_instance_valid(pl):
		return
	var d = pl.global_position.distance_to(c)
	if not started:
		if d > 260.0:
			queue_free()
		elif pl.global_position.distance_to(P(0, 10.5)) < 5.0 and (Interiors.inst == null or Interiors.inst.inside == ""):
			started = true
			_run()
		return
	if done and (d > 140.0 or _life > 400.0):
		queue_free()


func _tick_extras(dt: float) -> void:
	# sırada oturanlar: kalça sıra hizasında
	for g in guests:
		if is_instance_valid(g) and st.has(g) and st[g].has("bench"):
			var hr = _bone(g, "Hips").y - g.model.global_position.y
			g.model.position.y = clampf(float(st[g]["bench"]) + 0.09 * g.model.age_scale - hr, -0.4, 0.4)
	# gelinin arkasında şemsiye tutan + önde miko
	if escort and is_instance_valid(bride):
		var bf = _fd(bride)
		for pr2 in [[holder, -bf * 0.75 + bf.cross(Vector3.UP) * 0.45], [miko, bf * 2.2]]:
			var n: Node3D = pr2[0]
			if not is_instance_valid(n):
				continue
			var tg: Vector3 = bride.global_position + pr2[1]
			var to = tg - n.global_position
			to.y = 0
			if to.length() > 0.08:
				n.global_position += to.normalized() * minf(to.length(), 1.6 * dt)
				n.global_position.y = _floor_y(n.global_position)
				_turn(n, bride.facing, dt * 6.0)
				if st.has(n):
					st[n]["anim"] = "walk"
				elif n.model.current != "walk":
					n.model.play("walk", 0.2, 0.85)
			elif st.has(n):
				st[n]["anim"] = "idle"
			elif n.model.current != "idle":
				n.model.play("idle", 0.25)
	# davul
	if drum_on and is_instance_valid(drummer):
		_beat -= dt
		if _beat <= 0.0:
			_beat = 0.62
			Sfx.play("hit_staff", drummer.global_position, 0.35)


func _make(n: Node3D, s: Dictionary) -> Dictionary:
	var t: float = s["t"]
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	match String(s["k"]):
		"wagasa":
			# büyük kırmızı tören şemsiyesi: sapı iki elle, gelinin başının üstüne eğik
			var grip = n.global_position + Vector3.UP * 1.25 * n.model.age_scale + fd * 0.3
			var arms0 = _ik(n, "Right", grip)
			arms0.append_array(_ik(n, "Left", grip + Vector3.DOWN * 0.22))
			var um = _prop(s, "wagasa")
			var hand = (_hand(n, "Right") + _hand(n, "Left")) * 0.5
			_aim(um, hand + Vector3.DOWN * 0.3, hand + Vector3.UP * 1.0 + fd * 0.45 - right * 0.25)
			return {"arms": arms0, "fL": GRIP, "fR": GRIP, "spine": 0.0, "neck": 0.0}
		"drum":
			var ph0 = t / 0.62
			var hr2 = absf(sin(ph0 * PI))
			var hl3 = absf(cos(ph0 * PI))
			return {"arms": [["RightUpperArm", Vector3(-0.3, -0.2 + hr2 * 0.9, 0.7)], ["RightLowerArm", Vector3(-0.1, 0.2 + hr2 * 0.75, 0.9 - hr2 * 0.5)],
				["LeftUpperArm", Vector3(0.3, -0.2 + hl3 * 0.9, 0.7)], ["LeftLowerArm", Vector3(0.1, 0.2 + hl3 * 0.75, 0.9 - hl3 * 0.5)]], "fL": GRIP, "fR": GRIP, "spine": 6.0, "neck": 0.0}
		"cheer":
			var w = sin(t * 8.0 + float(s.get("off", 0.0)))
			return {"arms": [["LeftUpperArm", Vector3(0.45, 0.85, 0.1)], ["RightUpperArm", Vector3(-0.45, 0.85, 0.1)],
				["LeftLowerArm", Vector3(0.2 + w * 0.3, 0.95, 0.1)], ["RightLowerArm", Vector3(-0.2 + w * 0.3, 0.95, 0.1)]], "fL": OPEN, "fR": OPEN, "spine": -4.0, "neck": -6.0}
		"applaud":
			var k = absf(sin(t * 9.0 + float(s.get("off", 0.0)))) * 0.16
			return {"arms": [["LeftUpperArm", Vector3(0.3, -0.6, 0.7)], ["RightUpperArm", Vector3(-0.3, -0.6, 0.7)],
				["LeftLowerArm", Vector3(-0.5 + k, 0.6, 0.6)], ["RightLowerArm", Vector3(0.5 - k, 0.6, 0.6)],
				["LeftHand", Vector3(-0.4 + k, 0.8, 0.4)], ["RightHand", Vector3(0.4 - k, 0.8, 0.4)]], "fL": OPEN, "fR": OPEN, "spine": 3.0, "neck": 0.0}
		"sip":
			# sake kupası iki elle: göğüs hizasından ağza üç yudum
			var ph = fmod(t, 1.0)
			var up = smoothstep(0.1, 0.4, ph) * (1.0 - smoothstep(0.65, 0.95, ph)) if t < 3.0 else 0.0
			var hold = (n.global_position + Vector3.UP * 1.18 * n.model.age_scale + fd * 0.3).lerp(_mouth(n) + fd * 0.06 + Vector3.DOWN * 0.05, up)
			var arms = _ik(n, "Left", hold - right * 0.07 + Vector3.DOWN * 0.02)
			arms.append_array(_ik(n, "Right", hold + right * 0.07))
			var cup = _prop(s, "sakazuki")
			cup.global_position = hold
			cup.global_basis = Basis(right, up * 0.6) * Basis(Vector3.UP, n.facing)
			return {"arms": arms, "fL": HALF, "fR": HALF, "spine": 0.0, "neck": -up * 12.0}
		"offer":
			return {"arms": [["LeftUpperArm", Vector3(0.45, -0.3, 0.8)], ["RightUpperArm", Vector3(-0.45, -0.3, 0.8)],
				["LeftLowerArm", Vector3(0.3, 0.35, 0.85)], ["RightLowerArm", Vector3(-0.3, 0.35, 0.85)]], "fL": OPEN, "fR": OPEN, "spine": 0.0, "neck": 4.0}
		"halt":
			return {"arms": [["RightUpperArm", Vector3(-0.3, 0.25, 0.9)], ["RightLowerArm", Vector3(-0.1, 0.6, 0.75)], ["RightHand", Vector3(0.0, 0.95, 0.3)]], "fL": HALF, "fR": OPEN, "spine": 0.0, "neck": 0.0}
		"point":
			return {"arms": [["RightUpperArm", Vector3(-0.2, 0.05, 0.98)], ["RightLowerArm", Vector3(-0.1, 0.1, 0.99)], ["RightHand", Vector3(0.0, 0.05, 1.0)]], "fL": GRIP, "fR": [0.05, 1.0, 1.1, 1.2, 0.6], "spine": 6.0, "neck": 0.0}
	return super._make(n, s)


func _prop(s: Dictionary, name: String) -> MeshInstance3D:
	if not name in ["sakazuki", "wagasa"]:
		return super._prop(s, name)
	if not s.has("props"):
		s["props"] = {}
	if s["props"].has(name) and is_instance_valid(s["props"][name]):
		return s["props"][name]
	var b = MB.new()
	if name == "wagasa":   # +z boyunca: sap, tepede geniş kırmızı koni, uçta topuz, kenarda açık şerit
		b.add("box", Vector3(0, 0, 0.95), Vector3(0.035, 0.035, 1.9), Color(0.25, 0.16, 0.1))
		b.add("cone", Vector3(0, 0, 1.75), Vector3(1.9, 0.42, 1.9), Color(0.8, 0.1, 0.1), Vector3(90, 0, 0), 20)
		b.add("cyl", Vector3(0, 0, 1.56), Vector3(1.9, 0.03, 1.9), Color(0.95, 0.85, 0.75), Vector3(90, 0, 0), 20)
		b.add("sphere", Vector3(0, 0, 1.98), Vector3(0.09, 0.09, 0.09), Color(0.15, 0.1, 0.08), Vector3.ZERO, 8)
	else:
		b.add("cyl", Vector3(0, 0.012, 0), Vector3(0.16, 0.022, 0.16), Color(0.8, 0.12, 0.1), Vector3.ZERO, 12)
		b.add("cyl", Vector3(0, 0.024, 0), Vector3(0.13, 0.004, 0.13), Color(0.95, 0.85, 0.5), Vector3.ZERO, 12)
	var m = _mesh(b)
	s["props"][name] = m
	return m


func _freeze(n: Node3D) -> void:
	if is_instance_valid(n):
		n.set_physics_process(false)


func _run() -> void:
	busy = true
	var pl = Game.player
	var f: Dictionary = Friends.all()[sid]
	var vname = String(Game.village(vid).get("name", "Köy"))
	_lock(200.0)
	Game.profile.erase("waypoint")
	_freeze(officiant)
	_dress_player(true)
	pl = Game.player
	drum_on = true
	_pose(drummer, "drum", {"anim": "idle"})
	_say(officiant, "Herkes yerini alsın. Tören başlıyor.", 3.5)
	Sfx.play("crowd", c, 0.5)
	focus = pl
	await _go_w(pl, P(0, 12.5), 1.6)
	await _wait(0.4)
	# torii altından geçip yolu yürürsün
	await _go_w(pl, P(0, -1.8), 1.3)
	await _go_w(pl, P(0.6, -4.3), 1.1)
	_look_at(pl, P(-0.6, 8.0))
	pl.model.rotation.y = pl.facing
	# eşin gelir
	focus = bride
	escort = true
	if guests.size() > 2:
		_say(guests[1], ["Ne kadar yakışmış...", "Şuna bak, ışıl ışıl.", "Ağlayacağım galiba."].pick_random(), 3.5)
	await _go_w(bride, P(0, -1.6), 1.05)
	# sahnenin önünde miko ve şemsiye kenara çekilir, gelin tek başına çıkar
	escort = false
	_side(miko, P(-2.6, -3.2))
	_side(holder, P(3.0, -3.2))
	await _go_w(bride, P(-0.6, -4.3), 1.0)
	drum_on = false
	_clear_pose(drummer)
	_look_at(bride, officiant.global_position)
	_look_at(pl, officiant.global_position)
	pl.model.rotation.y = pl.facing
	_pose(officiant, "offer", {"anim": "idle"})
	_say(officiant, "Bugün %s ile %s'in yolları tek yol oluyor. %s buna tanıktır." % [pr().get("name", "Sen"), f["name"], vname], 5.0)
	await _wait(5.2)
	if is_instance_valid(objector):
		await _objection()
	# san-san-kudo
	_say(officiant, "Üç kupa, üçer yudum. Önce sen.", 3.5)
	await _wait(1.6)
	_clear_pose(officiant)
	_pose(pl, "sip", {"anim": "idle"})
	await _wait(3.4)
	_clear_pose(pl)
	_pose(bride, "sip", {"anim": "idle"})
	await _wait(3.4)
	_clear_pose(bride)
	# yemin + karşılıklı eğilme
	_say(officiant, "Şimdi birbirinize dönün ve sözünüzü verin.", 3.5)
	await _wait(1.8)
	await _face_each(pl, bride)
	Combat.popup_text(_bone(pl, "Head") + Vector3.UP * 0.45, "Seni ve yuvamızı koruyacağıma söz veriyorum.", Color(1, 0.92, 0.75))
	await _wait(3.0)
	_say(bride, "Ben de nereye gidersen git, dönüşünü bekleyeceğime.", 3.5)
	await _wait(3.2)
	_pose(pl, "bow", {"anim": "idle", "len": 2.2})
	_pose(bride, "bow", {"anim": "idle", "len": 2.2})
	await _wait(2.4)
	_clear_pose(pl)
	_clear_pose(bride)
	_pose(officiant, "cheer", {"anim": "idle"})
	_say(officiant, "%s adına sizi evli ilan ediyorum!" % vname, 4.0)
	# kutlama: sarılma, alkış, yaprak sağanağı
	petals.amount = 260
	Sfx.play("crowd", c, 1.0)
	Sfx.play("levelup", c, 0.6)
	drum_on = true
	_pose(drummer, "drum", {"anim": "idle"})
	for i in guests.size():
		if is_instance_valid(guests[i]):
			guests[i].model.position.y = 0.0   # sıradan kalkıp alkışlarlar
			_pose(guests[i], "cheer" if i % 3 == 0 else "applaud", {"anim": "idle", "off": i * 0.7})
			if i % 4 == 1:
				_say(guests[i], ["Omedetō!", "Mutluluklar!", "Bir yastıkta kocayın!", "Yaşasın!"][int(i / 4) % 4], 4.0)
	await _embrace(pl, bride)
	Friends.wed_done(sid)
	Hud.banner("DÜĞÜN", "%s ile evlendiniz ♥" % f["name"], Color(1, 0.6, 0.75))
	await _wait(1.5)
	_clear_pose(officiant)
	_release_player()
	_dress_player(false)
	drum_on = false
	_clear_pose(drummer)
	_say(bride, "Hadi, evimize gidelim. Seni orada bekliyorum.", 4.5)
	done = true
	_life = 0.0
	busy = false
	await _wait(5.0)
	for g in guests:
		if is_instance_valid(g):
			_clear_pose(g)
			g.set_physics_process(true)
	if is_instance_valid(bride):
		await _go_w(bride, P(0, 14.0), 1.5)
		if is_instance_valid(bride):
			bride.vanish()
	await _wait(25.0)
	for g in guests + [officiant, miko, holder, drummer]:
		if is_instance_valid(g):
			_clear_pose(g)
			g.set_physics_process(true)
			g.vanish()


func _guest_turn(_to: Node3D) -> void:
	pass   # konuklar sırada oturur


func _side(n: Node3D, to: Vector3) -> void:
	if not is_instance_valid(n):
		return
	await _go_w(n, to, 1.4, st.has(n))
	if is_instance_valid(n):
		_look_at(n, P(0, -4.5))
		if st.has(n):
			st[n]["anim"] = "idle"
		else:
			n.model.play("idle", 0.25)


## Tören kıyafeti: sen de damatlık / gelinlik giyersin; tören bitince kendi kıyafetine dönersin
func _dress_player(on: bool) -> void:
	var p = pr()
	if on:
		if _saved_look != null:
			return
		_saved_look = (p["look"] as Dictionary).duplicate(true)
		var L: Dictionary = p["look"]
		for k in ["vest", "band", "weapon_r", "weapon_l", "back_item", "mask", "outer_style", "head_style", "face_style", "hood", "guards"]:
			L[k] = null
		L["band_style"] = "none"
		if String(p.get("gender", "m")) == "f":
			Gear.preview_set_look(L, "ss_gelinlik")
			for k in ["top", "top2", "pants", "outer", "acc", "sandal", "wraps"]:
				L[k] = Color(0.98, 0.97, 0.96)
			L["outer2"] = Color(0.96, 0.86, 0.88)
		else:
			Gear.preview_set_look(L, "set_kenshi")
			L["top"] = Color(0.08, 0.08, 0.1)
			L["top2"] = Color(0.92, 0.92, 0.9)
			L["pants"] = Color(0.42, 0.42, 0.45)
			L["acc"] = null
	else:
		if _saved_look == null:
			return
		p["look"] = _saved_look
		_saved_look = null
		Gear.apply_look(p)
	if is_instance_valid(Game.player):
		Game.player.rebuild_model()


func _face_each(a: Node3D, b: Node3D) -> void:
	var a0 = a.facing
	var b0 = b.facing
	var ta = b.global_position - a.global_position
	var a1 = atan2(-ta.x, -ta.z)
	var b1 = atan2(ta.x, ta.z)
	var k := 0.0
	while k < 1.0:
		k += get_process_delta_time() / 0.7
		_face(a, lerp_angle(a0, a1, smoothstep(0.0, 1.0, k)))
		_face(b, lerp_angle(b0, b1, smoothstep(0.0, 1.0, k)))
		await get_tree().process_frame


func _embrace(pl: Node3D, o: Node3D) -> void:
	var t0 := 0.0
	while is_instance_valid(o) and t0 < 4.0:
		var to = pl.global_position - o.global_position
		to.y = 0
		if to.length() < 0.34:
			break
		var dt = get_process_delta_time()
		t0 += dt
		o.global_position += to.normalized() * minf(1.2 * dt, to.length() - 0.32)
		o.model.play("walk", 0.2, 0.8)
		await get_tree().process_frame
	o.model.play("idle", 0.2)
	_pose(o, "hug", {"with": pl, "anim": "idle", "hi": 0.14})
	_pose(pl, "hug", {"with": o, "anim": "idle", "hi": -0.16})
	await _wait(1.2)
	Combat.popup_text((_bone(pl, "Head") + _bone(o, "Head")) * 0.5 + Vector3.UP * 0.35, "♥", Color(1, 0.5, 0.65))
	await _wait(3.0)
	_clear_pose(o)
	_clear_pose(pl)


## Rakip klan itirazı: konuklardan biri yola çıkar, nikâhı kıyan eliyle durdurur; öfkeyle çekip gider
func _objection() -> void:
	var f: Dictionary = Friends.all()[sid]
	_freeze(objector)
	focus = objector
	_guest_turn(objector)
	_say(objector, "Durun! Bu nikâh kıyılamaz!", 3.0)
	await _go_w(objector, P(0.3, 2.0), 2.4)
	_look_at(Game.player, objector.global_position)
	Game.player.model.rotation.y = Game.player.facing
	_look_at(bride, objector.global_position)
	_pose(objector, "point", {"anim": "idle"})
	_say(objector, "Bir %s, bir %s ile mi? Atalarımızın kanı kurumadı daha!" % [String(f.get("clan", "")).capitalize(), String(pr().get("clan", "")).capitalize()], 4.5)
	if guests.size() > 3:
		_say(guests[3], "Yine mi eski kavga...", 3.0)
	await _wait(4.4)
	_pose(officiant, "halt", {"anim": "idle"})
	_say(officiant, "Yeter! Bu yolda kin değil, iki insanın sözü yürür. Yerine geç ya da çık.", 5.0)
	await _wait(4.6)
	_say(bride, "...Ben seçimimi yaptım, amca.", 3.5)
	await _wait(3.2)
	_clear_pose(objector)
	_say(objector, "Tch. Bunu klan unutmayacak.", 3.0)
	await _go_w(objector, P(6.0, 16.0), 2.2)
	if is_instance_valid(objector):
		objector.vanish()
	Friends.log_event(f, "Düğününüzde klanından biri itiraz etti; nikâhı kıyan susturdu")
	_clear_pose(officiant)
	_look_at(Game.player, officiant.global_position)
	Game.player.model.rotation.y = Game.player.facing
	_look_at(bride, officiant.global_position)
	focus = officiant
	_guest_turn(officiant)
	_pose(officiant, "offer", {"anim": "idle"})
