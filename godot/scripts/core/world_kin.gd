class_name WorldKin
extends ScenePoser
## Dünya ninjalarının aile hayatı (WorldPeople üstünde; hepsi yaşanan veriden, kalıp yok).
## · Evlenirler (aynı köy), çocukları olur; çocuk büyüyünce akademiden mezun olup GERÇEK bir dünya ninjası olur
##   (klanı, saçı, gözü, doğası anne-babasından) — köyün yeni nesli artık bu çocuklardır.
## · Ölüm aileye dokunur: eş, çocuk, anne-baba, kardeş yas tutar (yas: kaçış / uyanış sistemlerini besler).
## · İntikam: bir dünya ninjasını SEN öldürürsen yakınları bunu unutmaz; biri köy dışında karşına çıkar.
## · Köyde görünür: evli çiftler çocuklarıyla gezer (durup konuşur, çocuğun saçını okşar, çocuk etraflarında koşar);
##   konuşursan kendi hayatlarını anlatırlar. Mezarlıkta yakınını kaybeden biri mezar başında diz çöker.

const KID_GROW := 5400.0      # sn (oyun süresi): doğumdan mezuniyete
const KID_WALK := 1200.0      # bu yaştan sonra anne-babasıyla gezmeye çıkar

static var walk: WorldKin
static var mourner: WorldKin
static var _av_t := 0.0
static var _walk_t := 6.0
static var auto := true        # test: döngüyü elle sürmek için kapatılır
static var force_moment := -1

var mode := ""            # "walk" | "mourn"
var vid := ""
var a: Node3D
var b: Node3D
var kid: Node3D
var pa := {}
var pb := {}
var busy := false
var _alive := true


static func D() -> Dictionary:
	var d = WorldPeople.data()
	if not d.has("kids"):
		d["kids"] = {}
		d["kid_seq"] = 0
		d["avengers"] = []
	return d


static func P(id) -> Dictionary:
	return WorldPeople.get_p(String(id))


static func _ok(p: Dictionary) -> bool:
	return not p.is_empty() and WorldPeople.alive(p) and not WorldPeople.is_rogue(p) and not p.get("missing", false)


static func spouse_of(p: Dictionary) -> Dictionary:
	return P(p.get("spouse", ""))


static func kids_of(p: Dictionary) -> Array:
	var o = []
	for k in D()["kids"].values():
		if String(k["fa"]) == String(p["id"]) or String(k["mo"]) == String(p["id"]):
			o.append(k)
	return o


## Yakınlar: [[kişi, "eşi" / "oğlu" / "kızı" / "babası" / "annesi" / "kardeşi"], ...] (ölenin gözünden)
static func relatives(p: Dictionary) -> Array:
	var o = []
	var sp = spouse_of(p)
	if not sp.is_empty():
		o.append([sp, "eşi"])
	for cid in p.get("children", []):
		var c = P(cid)
		if not c.is_empty():
			o.append([c, "kızı" if c["female"] else "oğlu"])
	var pars: Array = p.get("parents", [])
	for i in pars.size():
		var q = P(pars[i])
		if not q.is_empty():
			o.append([q, "annesi" if q["female"] else "babası"])
			for sid in q.get("children", []):
				var s = P(sid)
				if not s.is_empty() and String(s["id"]) != String(p["id"]) and not o.any(func(x): return String(x[0]["id"]) == String(s["id"])):
					o.append([s, "kardeşi"])
	return o


# ====================================================================== hayat (WorldPeople._life çağırır)
static func life(p: Dictionary) -> void:
	if not _ok(p):
		return
	var sp = spouse_of(p)
	if not sp.is_empty() and not WorldPeople.alive(sp):
		p["spouse"] = ""
		p["widow"] = true
		sp = {}
	if sp.is_empty():
		if int(p["rank"]) >= 1 and randf() < (0.12 if p.get("widow", false) else 0.5):
			_marry(p)
	elif _ok(sp) and p["female"] and kids_of(p).size() + (p.get("children", []) as Array).size() < 3 and randf() < 0.5:
		_birth(sp, p)


static func _marry(p: Dictionary) -> void:
	var pars: Array = p.get("parents", [])
	var c = WorldPeople.all().values().filter(func(q): return _ok(q) and String(q["village"]) == String(p["village"]) and bool(q["female"]) != bool(p["female"]) 		and String(q.get("spouse", "")) == "" and String(q["id"]) != String(p["id"]) and not String(q["id"]) in pars and not String(p["id"]) in (q.get("parents", []) as Array) 		and (pars.is_empty() or pars != (q.get("parents", []) as Array)))
	if c.is_empty():
		return
	var q: Dictionary = c.pick_random()
	p["spouse"] = String(q["id"])
	q["spouse"] = String(p["id"])
	p.erase("widow")
	q.erase("widow")
	WorldPeople.log_event(p, "%s ile evlendi" % String(q["name"]))
	WorldPeople.log_event(q, "%s ile evlendi" % String(p["name"]))


static func _birth(fa: Dictionary, mo: Dictionary) -> void:
	var d = D()
	d["kid_seq"] = int(d["kid_seq"]) + 1
	var fem = randf() < 0.5
	var dom: Dictionary = fa if randf() < 0.55 else mo
	var oth: Dictionary = mo if is_same(dom, fa) else fa
	var clan = String(dom["clan"]) if String(dom["clan"]) != "" else String(oth["clan"])
	var sur = String(fa["name"]).split(" ")[0] if clan == "" else ""
	var given = String((ClanWorld.GIVEN_F if fem else ClanWorld.GIVEN_M).pick_random())
	var nm = ClanWorld.person_name(clan, fem) if clan != "" else "%s %s" % [sur, given]
	var dl: Dictionary = dom.get("look", {})
	var ol: Dictionary = oth.get("look", {})
	var lk = {}
	for key in ["hair", "eye", "skin"]:
		lk[key] = (dl if randf() < 0.6 else ol).get(key, dl.get(key))
	var k = {"id": "k%d" % int(d["kid_seq"]), "name": nm, "female": fem, "fa": String(fa["id"]), "mo": String(mo["id"]), "village": String(mo["village"]),
		"clan": clan, "age": 0.0, "el": String(((dom["els"] as Array) + (oth["els"] as Array)).pick_random()), "look": lk}
	d["kids"][k["id"]] = k
	WorldPeople.log_event(fa, "%s adında bir %s oldu" % [nm, "kızı" if fem else "oğlu"])
	WorldPeople.log_event(mo, "%s adında bir %s oldu" % [nm, "kızı" if fem else "oğlu"])


## Dünya turu (90 sn'de bir): çocuklar büyür; mezun olan gerçek bir genin olur
static func world_tick(dt: float) -> void:
	var d = D()
	for kid_id in d["kids"].keys():
		var k: Dictionary = d["kids"][kid_id]
		k["age"] = float(k.get("age", 0.0)) + dt
		if float(k["age"]) >= KID_GROW:
			d["kids"].erase(kid_id)
			_graduate(k)


static func _graduate(k: Dictionary) -> void:
	var vid2 = String(k["village"])
	if Game.village(vid2).is_empty():
		return
	var p = WorldPeople.new_person(vid2, 0)
	p["female"] = bool(k["female"])
	p["clan"] = String(k["clan"])
	p["name"] = String(k["name"])
	p["els"] = [String(k["el"])]
	p["nat"] = []
	p["level"] = randi_range(12, 26)
	p["parents"] = [String(k["fa"]), String(k["mo"])]
	var ek = int(ClanWorld.EYE_KIND.get(String(p["clan"]), 0))
	p["eye"] = [ek, 1] if ek == 2 or ek == 3 or (ek == 1 and randf() < 0.3) else [0, 0]
	var lk = WorldPeople._make_look(p)
	for key in ["hair", "eye", "skin"]:
		if (k.get("look", {}) as Dictionary).get(key) != null:
			lk[key] = k["look"][key]
	p["look"] = lk
	p["jutsu"] = []
	WorldPeople._learn(p)
	p["log"] = []
	WorldPeople.log_event(p, "Akademiden mezun oldu")
	for par_id in p["parents"]:
		var q = P(par_id)
		if q.is_empty():
			continue
		if not q.has("children"):
			q["children"] = []
		q["children"].append(String(p["id"]))
		if WorldPeople.alive(q):
			WorldPeople.log_event(q, "%s %s akademiden mezun oldu" % ["Kızı" if p["female"] else "Oğlu", String(p["name"])])


## Ölüm (WorldPeople._die çağırır): aile yas tutar; seni sorumlu tutarlarsa intikam yemini
static func on_death(p: Dictionary) -> void:
	var by_player = p.get("slain_by_player", false)
	for r in relatives(p):
		var q: Dictionary = r[0]
		if not WorldPeople.alive(q):
			continue
		q["grief"] = true
		# r[1] ölenin gözünden ("oğlu"): yakının kaydına tersinden yazılır
		WorldPeople.log_event(q, "%s %s öldü" % [_inverse(r[1], p), String(p["name"])])
		if by_player and not String(q["id"]) in D()["avengers"]:
			q["vendetta"] = String(p["name"])
			q["vendetta_rel"] = _inverse(r[1], p)
			D()["avengers"].append(String(q["id"]))
	if String(p.get("spouse", "")) != "":
		var sp = spouse_of(p)
		if not sp.is_empty():
			sp["spouse"] = ""
			sp["widow"] = true
	# küçük çocuklar: öbür ebeveynle kalır (ikisi de öldüyse köy büyütür; kayıt sürer)


## "oğlu" (ölenin oğlu) -> yakının ağzından ölen kim: "Babası" / "Annesi"
static func _inverse(rel: String, dead: Dictionary) -> String:
	match rel:
		"eşi": return "Eşi"
		"oğlu", "kızı": return "Annesi" if dead["female"] else "Babası"
		"babası", "annesi": return "Kızı" if dead["female"] else "Oğlu"
	return "Kardeşi"


## Yakının ağzından, sana: "babamı", "eşimi"...
static func _my(rel: String) -> String:
	return {"Eşi": "eşimi", "Annesi": "annemi", "Babası": "babamı", "Kızı": "kızımı", "Oğlu": "oğlumu", "Kardeşi": "kardeşimi"}.get(rel, "yakınımı")


# ====================================================================== her kare (WorldPeople._process çağırır)
static func tick(dt: float) -> void:
	if Game.player == null or Game.profile.is_empty():
		return
	_avenger_tick(dt)
	_walk_t -= dt
	if _walk_t <= 0.0:
		_walk_t = 4.0
		_walk_tick()


static func _village_at(pos: Vector3) -> String:
	var m = Game.to_map(pos)
	for v in Game.world_info.get("villages", []):
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 0.92:
			return String(v["id"])
	return ""


# ------------------------------------------------------------------ intikam
static func _avenger_tick(dt: float) -> void:
	var av: Array = D()["avengers"]
	if av.is_empty():
		return
	_av_t += dt
	if _av_t < float(D().get("av_next", 300.0)):
		return
	var pl = Game.player
	if Missions.quiet() or pl.hp <= 0.0 or pl.get("scene_hold") or Interiors.inst == null or Interiors.inst.inside != "" or _village_at(pl.global_position) != "":
		return
	_av_t = 0.0
	D()["av_next"] = randf_range(900.0, 1500.0)
	var id = String(av[0])
	av.remove_at(0)
	var q = P(id)
	if q.is_empty() or not WorldPeople.alive(q):
		return
	spawn_avenger(q)


static func spawn_avenger(q: Dictionary) -> Node:
	var pl = Game.player
	var at = Missions.open_ground(pl.global_position + pl.face_dir() * 26.0, 14.0)
	var ar = WorldPeople.arch_of(q, "rogue" if WorldPeople.is_rogue(q) else ("jonin" if int(q["rank"]) >= 2 else "chunin"))
	var e = Enemy.new()
	e.setup(ar)
	Game.player.get_tree().current_scene.add_child(e)
	WorldPeople.after_spawn(e, q)
	e.global_position = at
	e.home = at
	e.team = "enemy"
	var who = String(q.get("vendetta", "birini"))
	var rel = String(q.get("vendetta_rel", ""))
	Combat.popup_text(at + Vector3.UP * 2.3, "%s! %s sen aldın benden. Bugün hesabını vereceksin!" % [String(Game.profile.get("name", "")), _my(rel).capitalize()], Color(1.0, 0.5, 0.45))
	Hud.msg("%s karşına çıktı — öldürdüğün %s onun %s." % [String(q["name"]), who, {"Eşi": "eşiydi", "Annesi": "annesiydi", "Babası": "babasıydı", "Kızı": "kızıydı", "Oğlu": "oğluydu", "Kardeşi": "kardeşiydi"}.get(rel, "yakınıydı")], Color(1.0, 0.6, 0.5), 8.0)
	WorldPeople.log_event(q, "%s'in hesabını sormak için %s'in karşısına çıktı" % [who, String(Game.profile.get("name", ""))])
	return e


# ------------------------------------------------------------------ köyde gezen aile
static func _walk_tick() -> void:
	var pl = Game.player
	var vid2 = _village_at(pl.global_position)
	var day = not HomeLife.night()
	if is_instance_valid(walk):
		if walk.vid != vid2 or not day or (is_instance_valid(walk.a) and walk.a.global_position.distance_to(pl.global_position) > 95.0):
			walk.leave()
		return
	if vid2 == "" or not day or Interiors.inst == null or Interiors.inst.inside != "" or Missions.quiet():
		return
	var cp = couple_in(vid2)
	if cp.is_empty():
		return
	start_walk(cp[0], cp[1], vid2)


## Köyde evli, sağ bir çift (çocuğu gezecek yaşta olan önce)
static func couple_in(vid2: String) -> Array:
	var best = []
	var plain = []
	for p in WorldPeople.all().values():
		if not _ok(p) or String(p["village"]) != vid2 or p["female"]:
			continue
		var sp = spouse_of(p)
		if not _ok(sp):
			continue
		if kids_of(p).any(func(k): return float(k["age"]) >= KID_WALK):
			best.append([p, sp])
		else:
			plain.append([p, sp])
	if not best.is_empty():
		return best.pick_random()
	return plain.pick_random() if not plain.is_empty() else []


static func start_walk(p1: Dictionary, p2: Dictionary, vid2: String, at = null) -> WorldKin:
	var s = WorldKin.new()
	s.mode = "walk"
	s.vid = vid2
	s.pa = p1
	s.pb = p2
	walk = s
	Game.player.get_tree().current_scene.add_child(s)
	s._spawn_family(at)
	return s


static func _villager(p: Dictionary, at: Vector3, lines: Array) -> Villager:
	var m = Villager.new()
	m.role = "walker"
	var lk = WorldPeople.look_of(p)
	lk["age"] = "adult"
	m.look_extra = lk
	m.display_override = String(p["name"])
	m.lines_override = lines
	Game.player.get_tree().current_scene.add_child(m)
	at.y = Game.ground_height(at.x, at.z)
	m.global_position = at
	m.home = at
	m.goal = at
	m.set_physics_process(false)
	m.set_meta("world_person", String(p["id"]))
	return m


## Kendi hayatından cümleler (kayıttan)
static func lines_of(p: Dictionary) -> Array:
	var o = []
	var sp = spouse_of(p)
	if not sp.is_empty():
		o.append("%s ile evliyiz. Görev aralarında böyle yürümek iyi geliyor." % String(sp["name"]).split(" ")[-1])
	for k in kids_of(p):
		var kn = String(k["name"]).split(" ")[-1]
		if float(k["age"]) < KID_WALK:
			o.append("%s daha çok küçük; bugün büyükannesinde." % kn)
		else:
			o.append("%s seneye akademiye başlıyor. Şimdiden shuriken istiyor." % kn)
	for cid in p.get("children", []):
		var c = P(cid)
		if c.is_empty():
			continue
		if WorldPeople.alive(c):
			o.append("%s artık %s. İnsan gurur duyuyor." % [String(c["name"]).split(" ")[-1], WorldPeople.RANK_NAMES[int(c["rank"])].to_lower()])
		else:
			o.append("%s... bir görevden dönmedi. Her gün aklımda." % String(c["name"]).split(" ")[-1])
	if o.is_empty():
		o.append("Köy bugün sakin. Böyle günlerin kıymetini bilmeli.")
	return o


func _spawn_family(at) -> void:
	var pl = Game.player
	var base: Vector3
	if at is Vector3:
		base = at
	else:
		var ang = randf() * TAU
		base = Missions.open_ground(pl.global_position + Vector3(cos(ang), 0, sin(ang)) * randf_range(26.0, 38.0), 18.0)
		if _village_at(base) != vid:
			base = Missions.open_ground(pl.global_position + pl.face_dir() * 22.0, 14.0)
	a = _villager(pa, base, lines_of(pa))
	b = _villager(pb, base + Vector3(0.8, 0, 0), lines_of(pb))
	var ks = kids_of(pa).filter(func(k): return float(k["age"]) >= KID_WALK)
	if not ks.is_empty():
		var k: Dictionary = ks.pick_random()
		kid = Villager.new()
		kid.role = "kid"
		var lk = CharacterModel.default_look()
		lk.merge(Outfits.roll("kid", vid), true)
		var kl: Dictionary = k.get("look", {})
		for key in kl:
			var v = kl[key]
			if v != null:
				lk[key] = Color.html(v) if v is String and v.length() == 6 and v.is_valid_hex_number() else v
		lk["gender"] = "f" if k["female"] else "m"
		lk["hair_style"] = String(ClanWorld.clan_look(String(k["clan"]), "genin", vid, bool(k["female"]), "child").get("hair_style", "diken"))
		if CharacterModel.CLAN_FACE_PAINT.has(String(k["clan"])):
			lk["face_paint"] = CharacterModel.CLAN_FACE_PAINT[String(k["clan"])]
		lk["age"] = "child"
		lk["keep_hair"] = true
		kid.look_extra = lk
		kid.display_override = String(k["name"])
		var par = "Babam" if randf() < 0.5 else "Annem"
		kid.lines_override = ["%s bana kunai tutmayı gösterdi!" % par, "Ben de ninja olacağım. %s gibi!" % par, "Dango alacaklar bana, söz verdiler!"]
		get_tree().current_scene.add_child(kid)
		kid.global_position = base + Vector3(0.4, 0, 0.9)
		kid.global_position.y = Game.ground_height(kid.global_position.x, kid.global_position.z)
		kid.home = kid.global_position
		kid.goal = kid.global_position
		kid.set_physics_process(false)
	if auto:
		_loop()


func leave() -> void:
	_alive = false
	if walk == self:
		walk = null
	if mourner == self:
		mourner = null
	for n in [a, b, kid]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	queue_free()


func _exit_tree() -> void:
	_alive = false
	if walk == self:
		walk = null
	if mourner == self:
		mourner = null


func _process(dt: float) -> void:
	_apply_poses(dt)


func _make(n: Node3D, s: Dictionary) -> Dictionary:
	if String(s["k"]) == "pat":   # çocuğun saçını okşar
		var o: Node3D = s.get("with")
		var arms = []
		if is_instance_valid(o):
			var fd = _fd(n)
			var right = fd.cross(Vector3.UP).normalized()
			var k = smoothstep(0.0, 0.5, float(s["t"]))
			var top = _bone(o, "Head") + Vector3.UP * 0.2 * o.model.age_scale + right * sin(float(s["t"]) * 7.0) * 0.07
			var rest = _bone(n, "RightUpperArm") + Vector3.DOWN * 0.5
			arms = _ik(n, "Right", rest.lerp(top, k), 8.0)
		return {"arms": arms, "fL": HALF, "fR": OPEN, "spine": 10.0, "neck": 18.0}
	return super._make(n, s)


func _ok_nodes() -> bool:
	return _alive and is_instance_valid(a) and is_instance_valid(b)


## Oyuncu yanlarındaysa (konuşuyor olabilir) dururlar
func _player_near() -> bool:
	return is_instance_valid(a) and Game.player.global_position.distance_to(a.global_position) < 3.2


func _loop() -> void:
	await _wait(0.6)
	while _ok_nodes():
		# yürüyüş
		var ang = randf() * TAU
		var tgt = Missions.open_ground(a.global_position + Vector3(cos(ang), 0, sin(ang)) * randf_range(12.0, 22.0), 10.0)
		if _village_at(tgt) != vid:
			await _wait(0.5)
			continue
		await _stroll(tgt)
		if not _ok_nodes():
			return
		# durak: küçük bir an
		await _moment()
		if not _ok_nodes():
			return


func _stroll(tgt: Vector3) -> void:
	var t0 := 0.0
	var hop := 0.0
	while _ok_nodes() and t0 < 40.0:
		var dt = get_process_delta_time()
		var to = tgt - a.global_position
		to.y = 0
		if to.length() < 0.6:
			break
		if _player_near():
			for n in [a, b, kid]:
				if n != null and is_instance_valid(n):
					n.model.play("idle", 0.3)
					_look_at(n, Game.player.global_position, 0.1)
			await get_tree().process_frame
			continue
		t0 += dt
		var dir = to.normalized()
		var side = dir.cross(Vector3.UP)
		_turn(a, atan2(-dir.x, -dir.z), dt * 6.0)
		a.global_position += dir * 1.25 * dt
		a.global_position.y = Game.ground_height(a.global_position.x, a.global_position.z)
		a.model.play("walk", 0.25, 0.85)
		# eşi yanında
		var want_b = a.global_position + side * 0.75
		var tb = want_b - b.global_position
		tb.y = 0
		_turn(b, atan2(-dir.x, -dir.z), dt * 6.0)
		b.global_position += tb.limit_length(1.6 * dt)
		b.global_position.y = Game.ground_height(b.global_position.x, b.global_position.z)
		b.model.play("walk", 0.25, 0.85)
		# çocuk önde koşturur, geri döner
		if kid != null and is_instance_valid(kid):
			hop += dt
			var lead = 1.6 + sin(hop * 0.9) * 1.3
			var want_k = a.global_position + dir * lead + side * (0.35 + sin(hop * 1.7) * 0.9)
			var tk = want_k - kid.global_position
			tk.y = 0
			if tk.length() > 0.15:
				_turn(kid, atan2(-tk.x, -tk.z), dt * 9.0)
				kid.global_position += tk.limit_length(2.6 * dt)
				kid.model.play("run" if tk.length() > 0.8 else "walk", 0.2, 0.75)
			kid.global_position.y = Game.ground_height(kid.global_position.x, kid.global_position.z)
		await get_tree().process_frame


func _moment() -> void:
	for n in [a, b, kid]:
		if n != null and is_instance_valid(n):
			n.model.play("idle", 0.3)
	var has_kid = kid != null and is_instance_valid(kid)
	var kind = force_moment if force_moment >= 0 else randi() % (4 if has_kid else 2)
	match kind:
		0:   # karı koca yüz yüze konuşur
			_look_at(a, b.global_position)
			_look_at(b, a.global_position)
			a.model.play("talk", 0.3)
			_say(a, ["Akşama ne pişirsek?", "Yarın nöbetim var, erken yatalım.", "Hatırlıyor musun, burada tanışmıştık."].pick_random(), 3.0)
			await _wait(3.0)
			if not _ok_nodes():
				return
			a.model.play("idle", 0.3)
			b.model.play("talk", 0.3)
			_say(b, ["Sen bilirsin. Ben pazara uğrarım.", "Yine mi nöbet... peki.", "Unutur muyum hiç."].pick_random(), 3.0)
			await _wait(3.0)
		1:   # yan yana durup köyü seyrederler
			var fd = _fd(a)
			_look_at(b, b.global_position + fd * 4.0)
			_pose(b, "stretch", {"anim": "idle"})
			await _wait(2.6)
			if not _ok_nodes():
				return
			_clear_pose(b)
			_say(b, ["Hava ne güzel bugün.", "Köy büyüyor, farkında mısın?"].pick_random(), 2.8)
			await _wait(2.6)
		2:   # baba çocuğun saçını okşar
			var kp = a.global_position + _fd(a) * 0.55
			await _go_w(kid, kp, 2.4)
			if not _ok_nodes() or not is_instance_valid(kid):
				return
			_look_at(kid, a.global_position)
			_look_at(a, kid.global_position)
			_pose(a, "pat", {"anim": "idle", "with": kid})
			_say(kid, ["Baba! Beni omzuna alsana!", "Bugün ben de antrenman yaptım!"].pick_random(), 2.8)
			await _wait(3.0)
			if not _ok_nodes():
				return
			_clear_pose(a)
			_say(a, ["Aferin. Ama önce yemeğini bitireceksin.", "Yavaş ol bakalım, küçük ninja."].pick_random(), 2.8)
			await _wait(2.6)
		3:   # çocuk etraflarında koşar, anne seslenir
			var c0 = (a.global_position + b.global_position) * 0.5
			_look_at(b, kid.global_position)
			var t0 := 0.0
			var a0 = randf() * TAU
			while t0 < 4.5 and _ok_nodes() and is_instance_valid(kid):
				var dt = get_process_delta_time()
				t0 += dt
				var ang = a0 + t0 * 1.7
				var want = c0 + Vector3(cos(ang), 0, sin(ang)) * 1.9
				var tk = want - kid.global_position
				tk.y = 0
				_turn(kid, atan2(-tk.x, -tk.z), dt * 10.0)
				kid.global_position += tk.limit_length(3.4 * dt)
				kid.global_position.y = Game.ground_height(kid.global_position.x, kid.global_position.z)
				kid.model.play("run", 0.2, 0.8)
				_look_at(b, kid.global_position, 0.1)
				if t0 > 1.2 and t0 - dt <= 1.2:
					_pose(b, "wave", {"anim": "idle"})
					_say(b, ["Yavaş! Düşeceksin!", "Uzaklaşma, buraya gel!"].pick_random(), 2.6)
				await get_tree().process_frame
			if not _ok_nodes():
				return
			_clear_pose(b)
			if is_instance_valid(kid):
				kid.model.play("idle", 0.3)
				_pose(kid, "cheer", {"anim": "idle"})
				await _wait(1.4)
				if is_instance_valid(kid):
					_clear_pose(kid)
	for n in [a, b]:
		if is_instance_valid(n):
			_clear_pose(n)


# ------------------------------------------------------------------ mezar başında yas tutan yakın
## Mezarlık kurulurken çağrılır: o köyde yakınını kaybetmiş biri varsa onun taşı başında diz çöker (taşta ölenin adı)
static func mourn_at(vid2: String, gy: Node3D) -> void:
	if is_instance_valid(mourner):
		mourner.leave()
	var c = WorldPeople.all().values().filter(func(p): return _ok(p) and String(p["village"]) == vid2 and p.get("grief", false) and not relatives(p).filter(func(r): return not WorldPeople.alive(r[0])).is_empty())
	if c.is_empty():
		return
	var p: Dictionary = c.pick_random()
	var dead: Array = relatives(p).filter(func(r): return not WorldPeople.alive(r[0])).pick_random()
	var s = WorldKin.new()
	s.mode = "mourn"
	s.vid = vid2
	s.pa = p
	mourner = s
	gy.add_child(s)
	var dn = String(dead[0]["name"])
	var slot = gy.global_position + Vector3(9.0, 0, -1.8)   # son sıranın köşe taşı
	var l = Label3D.new()
	l.text = dn
	l.font_size = 30
	l.pixel_size = 0.004
	l.outline_size = 6
	l.modulate = Color(0.95, 0.92, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.visibility_range_end = 14.0
	s.add_child(l)
	l.global_position = Vector3(slot.x, Game.ground_height(slot.x, slot.z) + 2.0, slot.z)
	# dead[1] p'nin gözünden ("oğlu" = p'nin oğlu)
	var mine = {"eşi": "Eşim", "oğlu": "Oğlum", "kızı": "Kızım", "babası": "Babam", "annesi": "Annem", "kardeşi": "Kardeşim"}.get(String(dead[1]), "Yakınım")
	var first = "%s %s burada yatıyor." % [mine, dn]
	if String(p.get("vendetta", "")) == dn:
		first += " ...Seni tanıyorum. Onu sen aldın benden."
	s.a = _villager(p, slot + Vector3(0, 0, 1.05), [first, "Her hafta gelirim. Anlatacak bir şeyler hep oluyor.", "Mezar taşları konuşmaz derler. Ben konuşuyorum yine de."])
	s._look_at(s.a, slot + Vector3(0, 0, -0.2))
	s._pose(s.a, "clap", {"anim": "idle", "sit": "seiza"})
