class_name Crime
extends Node
## Suç sistemi: köyde herkese saldırabilirsin (konuşmada "Saldır!"). Saldırılan kişi gerçek bir savaşçıya dönüşür
## (klan üyesi kendi klan teknikleri ve gözleriyle). Suçlar "aranma" puanı biriktirir (0-100):
##   saldırı +30, öldürme +70 (sivil +50), göz çalma +40, takım arkadaşına ihanet +40.
##   30+: köy muhafızları peşine düşer  •  70+: köy seni doğrudan KAÇAK ilan eder (Orgs.defect)
## Kurban dostsa ilişki biter; ölürse kalıcıdır, haber köye yayılır (diğer dostlar küser). Dışarıda puan yavaşça düşer.
## Zaten kaçaksan suçların kaçak şöhretini artırır.

const KILL := 70
const KILL_CIV := 50
const ATTACK := 30
const EYES := 40
const BETRAY := 40
const GUARDS_AT := 30
const OUTLAW_AT := 70

var victims: Array = []    # [{"node": Enemy, "vid", "fid", "civ", "dead"}]
var guards: Array = []
var t := 0.0
var decay_t := 0.0


static func inst() -> Crime:
	var tree = Engine.get_main_loop() as SceneTree
	return tree.current_scene.find_child("Crime", true, false) if tree and tree.current_scene else null


static func heat() -> int:
	return int(Game.profile.get("flags", {}).get("crime_heat", 0))


static func _village_at(p: Vector3) -> String:
	var m := Game.to_map(p)
	for v in Game.world_info["villages"]:
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			return String(v["id"])
	return ""


## Suç işlendi: köyündeysen aranma puanı, başka köydeysen o köyle itibar/ilişki bozulur
static func commit(points: int, what: String, at: Vector3) -> void:
	var pr = Game.profile
	if pr.is_empty():
		return
	var vid = _village_at(at)
	if Orgs.is_rogue():
		Orgs.flags()["infamy"] = int(Orgs.flags().get("infamy", 0)) + points / 3
		Hud.msg("Kaçak şöhretin arttı: %s" % what, Color(1, 0.5, 0.45))
		return
	if vid == "":
		return   # tanıksız yaban: kimse görmedi
	Missions._rep(vid, -points / 2)
	if vid != Progress.home():
		Kage.change_relation(vid, -points / 4)
		Hud.msg("%s: %s (itibar −%d)" % [Game.village(vid).get("name", vid), what, points / 2], Color(1, 0.5, 0.45))
		return
	var fl: Dictionary = pr["flags"]
	var before = int(fl.get("crime_heat", 0))
	fl["crime_heat"] = mini(100, before + points)
	var h = int(fl["crime_heat"])
	Hud.msg("SUÇ: %s  —  aranma %d/100" % [what, h], Color(1, 0.4, 0.35), 4.0)
	if h >= OUTLAW_AT:
		fl["crime_heat"] = 0
		Hud.banner("KAÇAK İLAN EDİLDİN", "Köy konseyi suçların yüzünden seni kaçak ilan etti!", Color(0.9, 0.15, 0.15))
		Orgs.defect()
	elif h >= GUARDS_AT and before < GUARDS_AT:
		Hud.banner("MUHAFIZLAR PEŞİNDE", "Köyün seni arıyor. Teslim olmazsan kaçak ilan edileceksin.", Color(1, 0.55, 0.3))
		var c = inst()
		if c:
			c._send_guards()


## Konuşma seçeneği: herkese (Kage gibi özel kişiler hariç) saldırabilirsin
static func attack_option(v: Node) -> Array:
	if Game.profile.is_empty() or v == null or not is_instance_valid(v):
		return []
	if v.interior or (v.display_override != "" and not v is ClanResident and not v.has_meta("friend_id")):
		return []
	return [{"label": "Saldır!", "cb": func():
		var c = inst()
		if c:
			c.attack(v)}]


## Oyuncunun vuruşu (yumruk/silah/jutsu) bir köylüye değdi: konuşmadaki "Saldır!" ile aynı suç (eskiden vuruşlar köylünün
## içinden geçiyordu, saldırı sayılmıyordu — köyden atılmıyordun)
static func on_struck(v: Node) -> void:
	if v == null or not is_instance_valid(v) or v.is_queued_for_deletion() or v.has_meta("struck"):
		return
	if attack_option(v).is_empty():
		return
	v.set_meta("struck", true)
	var c = inst()
	if c:
		c.attack(v)


## Köylü / klan üyesi -> gerçek düşman savaşçı (aynı yerde, aynı görünüşle)
func attack(v: Node) -> void:
	if not is_instance_valid(v):
		return
	var at: Vector3 = v.global_position
	var fid = String(v.get_meta("friend_id", ""))
	var civ = not Friends.is_ninja(v) and fid == ""
	var plv = int(Game.profile.get("level", 1))
	var e: Enemy
	if v is ClanResident:
		var rank = int(Friends.all().get(fid, {}).get("rank", 1))
		e = ClanWorld.spawn_enemy(String(v.clan), 6 + rank * 9 + randi_range(0, 4), at, {"outfit": "chunin", "village": String(v.vid), "name": String(v.given),
			"female": v.look.get("gender", "m") == "f", "eye": int(v.eye_kind), "look": v.look})
		if e == null:
			return
		if int(v.eye_kind) > 0:
			Eyes.give_enemy_eyes(e, int(v.eye_kind), maxi(1, int(v.eye_lvl)))
	else:
		var a = Enemy.archetype("bandit" if civ else "genin_rival", 0)
		a["no_clan"] = true
		a["name"] = String(v.display)
		a["respawn"] = false
		a["level"] = randi_range(2, 5) if civ else randi_range(12, 22)
		a["hp"] = 90.0 + a["level"] * (4.0 if civ else 14.0)
		a["xp"] = 0 if civ else 20
		a["ryo"] = 10
		if civ:
			a["jutsu"] = []
			a["power"] = 0.5
		a["look"] = v.look.duplicate()
		e = Enemy.new()
		e.setup(a)
		get_tree().current_scene.add_child(e)
		at.y = Game.ground_height(at.x, at.z)
		e.global_position = at
		e.home = at
	e.team = "enemy"
	e.target = Game.player
	victims.append({"node": e, "vid": _village_at(at), "fid": fid, "civ": civ, "dead": false})
	var who = String(v.display)
	v.queue_free()
	if fid != "":
		var f: Dictionary = Friends.all()[fid]
		f["bond"] = -100
		f["party"] = false
		Friends.log_event(f, "Ona saldırdın")
	commit(ATTACK, "%s kişisine saldırdın" % who, at)


## Takımdaki dosta ihanet
func betray(node: Node, fid: String) -> void:
	if not is_instance_valid(node):
		return
	var f: Dictionary = Friends.all().get(fid, {})
	if not f.is_empty():
		f["party"] = false
		f["bond"] = -100
		f["status"] = "ihanet"
		Friends.log_event(f, "Ona ihanet ettin")
	node.team = "enemy"
	node.set_meta("teammate", false)
	if node.has_meta("friend_id"):
		node.remove_meta("friend_id")
	node.target = Game.player
	if node.nameplate:
		node.nameplate.modulate = Color(1, 0.45, 0.4)
	victims.append({"node": node, "vid": _village_at(node.global_position), "fid": fid, "civ": false, "dead": false})
	commit(BETRAY, "Takım arkadaşına ihanet ettin", node.global_position)


## Göz çalma (Eyes._steal çağırır): kurban köylüyse suç
static func on_eyes_taken(f: Node) -> void:
	var c = inst()
	if c == null:
		return
	for vc in c.victims:
		if vc["node"] == f:
			commit(EYES, "Bir köy ninjasının gözlerini çaldın", f.global_position)
			if String(vc["fid"]) != "":
				Friends.log_event(Friends.all()[vc["fid"]], "Gözlerini çaldın")
			return


func _send_guards() -> void:
	if Game.player == null:
		return
	var hi = Progress.home_info()
	var lv = randi_range(24, 34)   # köy muhafızı: köyün kendi gücü (oyuncuya göre değil)
	for i in 3:
		var a = Enemy.archetype("genin_rival", i)
		a["name"] = "Köy Muhafızı"
		a["respawn"] = false
		a["level"] = lv
		a["hp"] = 260.0 + lv * 18.0
		a["power"] = 1.1 + lv * 0.02
		a["xp"] = 30 + lv * 6
		a["ryo"] = 0
		var auto = Enemy.auto_jutsu("genin_rival", String(hi.get("element", ["katon", "suiton", "fuuton", "doton", "raiton"][absi(hash(String(hi.get("name", "")))) % 5])), lv)
		if not auto.is_empty():
			a["jutsu"] = auto
		var L: Dictionary = a["look"]
		L["vest"] = hi["vest"]
		L["band"] = hi["band"]
		L["band_style"] = "head"
		L["village"] = Progress.home()
		L["mask"] = "anbu" if i == 0 else L.get("mask")
		var e = Enemy.new()
		e.setup(a)
		e.team = "enemy"
		get_tree().current_scene.add_child(e)
		var d = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 18.0
		var q = Game.player.global_position + d
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.home = q
		e.target = Game.player
		FX.smoke_puff(q + Vector3.UP, 0.9, 10)
		guards.append(e)


func _process(dt: float) -> void:
	if Game.paused or Game.profile.is_empty() or Game.player == null:
		return
	t -= dt
	if t > 0.0:
		return
	t = 0.5
	for vc in victims.duplicate():
		var n = vc["node"]
		if not is_instance_valid(n):
			victims.erase(vc)
			continue
		if not vc["dead"] and n.is_dead():
			vc["dead"] = true
			var fid = String(vc["fid"])
			if fid != "" and Friends.all().has(fid):
				var f: Dictionary = Friends.all()[fid]
				f["status"] = "öldü"
				Friends.log_event(f, "Onu sen öldürdün")
				for oid in Friends.all():
					if oid != fid and String(Friends.all()[oid].get("status", "")) == "":
						Friends.add_bond(oid, -30, true)
				Hud.msg("%s'in ölüm haberi köye yayıldı. Dostların senden uzaklaşıyor." % f["name"], Color(1, 0.5, 0.45), 5.0)
			commit(KILL_CIV if vc["civ"] else KILL, "Bir köylüyü öldürdün" if vc["civ"] else "Bir köy ninjasını öldürdün", n.global_position)
	guards = guards.filter(func(g): return is_instance_valid(g) and not g.is_dead())
	# aranma puanı: köy dışında ve muhafızlar yokken yavaşça düşer
	decay_t += 0.5
	if decay_t >= 20.0:
		decay_t = 0.0
		var fl: Dictionary = Game.profile.get("flags", {})
		if int(fl.get("crime_heat", 0)) > 0 and guards.is_empty() and _village_at(Game.player.global_position) != Progress.home():
			fl["crime_heat"] = int(fl["crime_heat"]) - 1
