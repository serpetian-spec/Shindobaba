class_name SchoolVisit
extends ScenePoser
## Akademi çağındaki çocuğun gündüz okul avlusundadır: hedef kütüğüne shuriken talimi yapar (uzaktan da görülür).
## Yanına gidince: talimini izle (atar, sen alkışlarsın) ya da getirdiğin bentoyu birlikte ye (yere oturulur, çubuklarla yenir).

static var cur: SchoolVisit

var c := Vector3.ZERO
var post := Vector3.ZERO
var nodes: Array = []     # [Villager]
var busy := false
var stuck: Array = []
var _t := 2.0


static func pr() -> Dictionary:
	return Game.profile


static func tick() -> void:
	if Game.player == null or pr().is_empty():
		return
	if Interiors.inst and Interiors.inst.inside != "":
		return
	var any = false
	if not Orgs.is_rogue():
		for kid in pr().get("children", []):
			if KidLife.at_school(kid):
				any = true
	var ac = Exams.find_point(["academy"])
	var near = any and ac != Vector3.ZERO and ac.distance_to(Game.player.global_position) < 90.0
	if is_instance_valid(cur):
		if not near and not cur.busy:
			cur.queue_free()
			cur = null
		return
	if not near:
		return
	var s = SchoolVisit.new()
	s.c = Missions.open_ground(ac, 30.0)
	cur = s
	Friends.inst().get_parent().add_child(s)


## Haritada işaretlemek için
static func yard() -> Vector3:
	var ac = Exams.find_point(["academy"])
	return Vector3.INF if ac == Vector3.ZERO else ac


func _gy(p: Vector3) -> Vector3:
	p.y = Game.ground_height(p.x, p.z)
	return p


func _ready() -> void:
	post = _gy(c + Vector3(2.6, 0, 0))
	var b = MB.new()
	var wood = Color(0.5, 0.36, 0.22)
	b.add("cyl", Vector3(0, 0.8, 0), Vector3(0.3, 1.6, 0.3), wood, Vector3.ZERO, 12)
	b.add("cyl", Vector3(0, 1.62, 0), Vector3(0.33, 0.05, 0.33), wood.darkened(0.2), Vector3.ZERO, 12)
	for k in 3:
		b.add("cyl", Vector3(0, 0.75 + k * 0.3, 0), Vector3(0.36, 0.14, 0.36), Color(0.86, 0.76, 0.5) if k != 1 else Color(0.8, 0.2, 0.15), Vector3.ZERO, 12)   # hasır sargılar
	var m = _mesh(b)
	m.global_position = post
	var body = StaticBody3D.new()
	add_child(body)
	var cs = CollisionShape3D.new()
	var cy = CylinderShape3D.new()
	cy.radius = 0.2
	cy.height = 1.6
	cs.shape = cy
	body.add_child(cs)
	cs.global_position = post + Vector3.UP * 0.8
	var i := 0
	for kid in pr().get("children", []):
		if not KidLife.at_school(kid) or i >= 3:
			continue
		var vg = Villager.new()
		vg.role = "kid"
		vg.display_override = String(kid["name"])
		vg.look_extra = KidLife.look(kid, "child")
		vg.lines_override = ["%s! Okula mı geldin?" % KidLife.parent_word(kid), "Bak, hedefe atıyoruz!"]
		vg.set_meta("school_kid", String(kid["name"]))
		add_child(vg)
		vg.set_physics_process(false)
		vg.global_position = _gy(c + Vector3(-1.6, 0, (i - 1) * 1.3 + (0.65 if i == 0 else 0.0)))
		vg.home = vg.global_position
		vg.goal = vg.global_position
		_look_at(vg, post)
		var cl: Array = kid.get("clans", [])
		if not cl.is_empty() and int(ClanWorld.EYE_KIND.get(String(cl[0]), 0)) == 2:
			vg.model.set_dojutsu_eyes(2, 1, 2, 1, false)
		nodes.append(vg)
		i += 1


func _exit_tree() -> void:
	if cur == self:
		cur = null
	_release_player()


func _process(dt: float) -> void:
	_apply_poses(dt)
	if busy:
		return
	# kendi kendine talim: sırayla biri atar
	_t -= dt
	if _t <= 0.0 and not nodes.is_empty():
		_t = randf_range(3.5, 5.5)
		var k = nodes.pick_random()
		if is_instance_valid(k) and Game.player.global_position.distance_to(k.global_position) > 2.2:
			_look_at(k, post)
			_throw(k, randf() < 0.3 + KidLife.skill(_kid(k), "shuriken") * 0.1)


func _kid(v: Node) -> Dictionary:
	for kid in pr().get("children", []):
		if String(kid["name"]) == String(v.get_meta("school_kid", "")):
			return kid
	return {}


static func opts(v: Node) -> Array:
	if not is_instance_valid(cur) or cur.busy:
		return []
	var me = cur
	var kid = me._kid(v)
	if kid.is_empty():
		return []
	var o = []
	if KidLife.cd_left(kid, "watch") <= 0.0:
		o.append({"label": "Talimini izle", "cb": func(): me._watch(v, kid)})
	if KidLife.cd_left(kid, "bento") <= 0.0:
		o.append({"label": "Sana bento getirdim (birlikte yiyelim)", "cb": func(): me._bento(v, kid)})
	o.append({"label": "Akşam evde görüşürüz", "cb": func(): Hud.dialog(String(v.display_override), ["Tamam! Geç kalma ama!", "Akşam sana yeni öğrendiğimi göstereceğim!"].pick_random(), [])})
	return o


## Kütüğe atış. Isabet: kütüğe saplanır; ıska: yanından geçip yere düşer
func _throw(n: Node3D, hit: bool) -> void:
	n.model.play("throw", 0.1, 1.25, true)
	await _wait(0.36)
	if not is_instance_valid(n):
		return
	var b = MB.new()
	var steel = Color(0.72, 0.74, 0.78)
	for a in [0.0, 90.0]:
		b.add("box", Vector3.ZERO, Vector3(0.17, 0.034, 0.006), steel, Vector3(0, 0, a))
	b.add("cyl", Vector3.ZERO, Vector3(0.035, 0.012, 0.035), Color(0.2, 0.2, 0.22), Vector3(90, 0, 0), 8)
	var m = _mesh(b)
	stuck.append(m)
	if stuck.size() > 8:
		var old = stuck.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var from = _hand(n, "Right")
	var dir = post - n.global_position
	dir.y = 0
	dir = dir.normalized()
	var side = dir.cross(Vector3.UP).normalized()
	var end = post + Vector3.UP * randf_range(0.75, 1.35) - dir * 0.17 + side * randf_range(-0.06, 0.06)
	if not hit:
		end = _gy(post + dir * randf_range(1.2, 2.2) + side * (1.0 if randf() < 0.5 else -1.0) * randf_range(0.4, 0.8)) + Vector3.UP * 0.02
	Sfx.play("throw", from, 0.5)
	var dur = from.distance_to(end) / 13.0
	var bas = Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var k := 0.0
	while k < 1.0 and is_instance_valid(m):
		k += get_process_delta_time() / dur
		var p = from.lerp(end, minf(k, 1.0))
		p.y += sin(minf(k, 1.0) * PI) * (0.1 if hit else 0.35)
		m.global_position = p
		m.global_basis = bas * Basis(Vector3(0, 0, 1), -k * dur * 42.0)
		await get_tree().process_frame
	if not is_instance_valid(m):
		return
	m.global_position = end
	if hit:
		m.global_basis = bas * Basis(Vector3(0, 0, 1), randf_range(0.2, 1.2))
		Sfx.play("kunai", end, 0.6)
	else:
		m.global_basis = Basis(Vector3(1, 0, 0), PI * 0.5)
		Sfx.play("clink", end, 0.4)
	await _wait(0.3)
	if is_instance_valid(n):
		n.model.play("idle", 0.3)


func _begin() -> void:
	busy = true
	_lock(60.0)
	Hud.close_dialog()


func _end() -> void:
	var pl = Game.player
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	_release_player()
	busy = false
	_t = 4.0


func _watch(k: Node3D, kid: Dictionary) -> void:
	if busy:
		return
	_begin()
	var pl = Game.player
	_say(k, ["İzle! Bugün hoca övdü beni!", "Tam zamanında geldin, bak!"].pick_random(), 2.4)
	var dir = (post - k.global_position)
	dir.y = 0
	dir = dir.normalized()
	var side = dir.cross(Vector3.UP).normalized()
	await _go_w(pl, _gy(k.global_position + side * 1.3 - dir * 0.5), 1.6)
	_look_at(pl, post)
	_look_at(k, post)
	await _wait(0.5)
	var hits = 0
	for i in 3:
		if not is_instance_valid(k):
			break
		var ok = randf() < clampf(0.4 + KidLife.skill(kid, "shuriken") * 0.12, 0.4, 0.95)
		await _throw(k, ok)
		if ok:
			hits += 1
		await _wait(0.35)
	if is_instance_valid(k):
		_look_at(k, pl.global_position)
		_look_at(pl, k.global_position)
		_pose(pl, "clap", {"anim": "idle"})
		Sfx.play("click", pl.global_position, 0.4)
		_say(k, ["Üçte üç! Gördün mü?!", "İkisi saplandı!", "Bir tane... ama en zoru oydu!", "Bugün elim titredi..."][3 - hits], 2.6)
		if hits >= 2:
			k.model.play("jump", 0.1, 1.2, true)
		await _wait(2.0)
		if is_instance_valid(k):
			k.model.play("idle", 0.2)
			Combat.popup_text(_bone(k, "Head") + Vector3.UP * 0.4, "Shuriken +0.3", Color(0.6, 1.0, 0.7))
	if not kid.has("tr"):
		kid["tr"] = {}
	kid["tr"]["shuriken"] = KidLife.skill(kid, "shuriken") + 0.3
	KidLife.mark(kid, "watch")
	_end()


func _bento(k: Node3D, kid: Dictionary) -> void:
	if busy:
		return
	_begin()
	var pl = Game.player
	_say(k, ["Bento mu?! Karnım zil çalıyordu!", "Yaşasın! Arkadaşlarım kıskanacak!"].pick_random(), 2.4)
	var spot = _gy(c + Vector3(-2.6, 0, 2.4))
	_go_w(k, spot + Vector3(-0.5, 0, 0), 2.4)
	await _go_w(pl, spot + Vector3(0.5, 0, 0), 1.6)
	await _wait(0.6)
	if not is_instance_valid(k):
		_end()
		return
	_look_at(pl, k.global_position)
	_look_at(k, pl.global_position)
	_pose(pl, "rest", {"anim": "idle", "sit": "agura"})
	_pose(k, "rest", {"anim": "idle", "sit": "seiza"})
	await _wait(1.0)
	_pose(k, "clap", {"anim": "idle", "sit": "seiza"})
	_say(k, "Itadakimasu!", 1.6)
	await _wait(1.3)
	_pose(pl, "eat", {"anim": "idle", "sit": "agura"})
	_pose(k, "eat", {"anim": "idle", "sit": "seiza", "off": 0.9})
	await _wait(2.6)
	_say(k, ["Bugün Bunshin çalıştık, benimki yere yığıldı...", "Hoca beni tahtaya kaldırdı, hepsini bildim!", "Yanımdaki çocuk hedefi hiç ıskalamıyor. Onu geçeceğim."].pick_random(), 3.6)
	await _wait(4.2)
	if is_instance_valid(k):
		_say(k, "Çok güzeldi! Yarın da getirir misin?", 2.6)
		Combat.popup_text(_bone(k, "Head") + Vector3.UP * 0.45, "♥", Color(1, 0.5, 0.65))
	await _wait(1.6)
	_clear_pose(pl)
	if is_instance_valid(k):
		_clear_pose(k)
		k.global_position = _gy(k.global_position)
		k.model.play("idle", 0.3)
	if not kid.has("tr"):
		kid["tr"] = {}
	kid["tr"]["bond"] = KidLife.skill(kid, "bond") + 1.0
	KidLife.mark(kid, "bento")
	pl.hp = minf(pl.max_hp, pl.hp + pl.max_hp * 0.15)
	_end()
