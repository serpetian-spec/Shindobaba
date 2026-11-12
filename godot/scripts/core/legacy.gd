class_name Legacy
extends ScenePoser
## Miras: yolunu mezun olmuş çocuğuna bırakırsın — bundan sonra ONUNLA oynarsın.
## · Tören (sahne): alın koruyucunu çözersin, uzatırsın; çocuğun eğilip alır, alnına bağlar; sarılırsınız.
## · Geçiş: adı, görünüşü, klanı, doğası, rütbesi çocuğundan. Sana kalanlar: evin, paran, eşyaların, öğrettiğin / öğrendiğin
##   teknikler (doğası tutanlar; göz, yol, canavar, sennin teknikleri eski bedende kalır), ustalıklarının %35'i (çocuğun kendi
##   emeğinden az olmamak üzere), kuyruklu canavarın (kanon: çocuğa geçer).
## · Eski sen köyde yaşamaya devam eder: baban / annen olur (ders verir, bento, sofra — Kin). Eşin diğer ebeveynin,
##   anne-baban deden / büyükannen, diğer çocukların kardeşin olur. Dostların seni "onun çocuğu" olarak tanır (bağ yarıya iner).

const KEEP := 0.35

static var cur: Legacy

var id := ""
var v: Node3D
var band: MeshInstance3D
var band_at: Node3D
var _was_phys := true
var death := false       # yaşlılıktan ölüm: tören yok, son nefes + geçiş


static func pr() -> Dictionary:
	return Game.profile


static func block() -> String:
	if Orgs.is_rogue():
		return "Kaçak hayatında devredecek bir yol yok."
	if Kage.is_kage():
		return "Kage görevini bırakmadan yolunu devredemezsin."
	if not Missions.active().is_empty() or int(ChuninExam.stage) != 0 or Exams.cur != "":
		return "Önce elindeki işi bitir."
	return ""


## Mezun çocuğunla konuşurken
static func opts(fid: String, node: Node) -> Array:
	var f: Dictionary = Friends.all().get(fid, {})
	if not f.get("child", false) or String(f.get("status", "")) != "" or node == null or node.get("interior") == true or is_instance_valid(cur):
		return []
	return [{"label": "Yolumu sana bırakıyorum... (miras)", "cb": func(): ask(fid, node)}]


static func ask(fid: String, node: Node) -> void:
	var f: Dictionary = Friends.all()[fid]
	var b = block()
	if b != "":
		Hud.dialog(String(f["name"]), b, [])
		return
	var nm = String(f["name"])
	Hud.dialog("Miras", "Alın koruyucunu %s'e (bu isimle anılacak: %s) bırakırsan bundan sonra ONUNLA oynarsın. Sen köyde yaşamaya devam edersin, ama artık sahne onundur.\n\nOna geçenler: evin, paran, eşyaların, doğası tutan tekniklerin, ustalıklarının bir kısmı.\nSende kalanlar: gözlerin, yol / sennin tekniklerin, rütben.\n\nBu kararın geri dönüşü yok." % [nm.split(" ")[-1], nm], [
		{"label": "Evet — yolumu ona bırakıyorum", "cb": func(): start(fid, node)},
		{"label": "Henüz değil", "cb": func(): pass}])


static func start(fid: String, node: Node) -> void:
	if is_instance_valid(cur) or node == null or not is_instance_valid(node):
		return
	var s = Legacy.new()
	s.id = fid
	s.v = node
	cur = s
	Friends.inst().get_parent().add_child(s)


# ====================================================================== yaşlılıktan ölüm
## Yolu devralacak çocuk: mezun, hayatta, köyde; en yakın olan
static func heir() -> String:
	var hs = Lineage.heirs()
	return String(hs[0]) if not hs.is_empty() else ""


static func _die_with(h: String) -> void:
	if is_instance_valid(cur) or not Friends.all().has(h):
		return
	var s = Legacy.new()
	s.id = h
	s.death = true
	cur = s
	Friends.inst().get_parent().add_child(s)


## Aging her birkaç saniyede çağırır (ömrün son 3 yılından itibaren)
static func old_age(y: float, life: float) -> void:
	if is_instance_valid(cur) or Game.player == null:
		return
	var p = pr()
	if not p.has("flags"):
		p["flags"] = {}
	var fl: Dictionary = p["flags"]
	var h = heir()
	if y < life:
		if not fl.get("old_warned", false):
			fl["old_warned"] = true
			Hud.banner("ÖMRÜN SONBAHARI", "Nefesin eskisi gibi değil. Yolunu bırakacağın kişiyi düşünme vakti." if h != "" else "Nefesin eskisi gibi değil. Yolunu bırakacak bir çocuğun yok.", Color(0.85, 0.8, 0.7))
			Journal.add("Yaş %d. Vücudum artık eskisi gibi değil; ömrümün sonbaharındayım." % int(y), "milestone")
		return
	if h == "":
		if not fl.get("old_noheir", false):
			fl["old_noheir"] = true
			Hud.msg("Ömrün doldu sayılır, ama yolunu bırakacak mezun bir çocuğun yok. İnatla yaşamaya devam ediyorsun.", Color(0.85, 0.8, 0.7), 7.0)
		return
	var pl = Game.player
	if not Missions.active().is_empty() or int(ChuninExam.stage) != 0 or Exams.cur != "" or Interiors.inst.inside != "" or not pl.grounded 			or pl.combat.action != "" or pl.hp < pl.max_hp * 0.6 or pl.get("scene_hold") or float(pl.input_locked) > 0.0 or Hud.dialog_open():
		return   # iş / dövüş ortasında değil: sakin bir anda
	var hs = Lineage.heirs()
	if hs.size() == 1:
		_die_with(h)
		return
	# birden fazla çocuk: yolu kime bırakacağını sen seçersin
	var opts = []
	for hid in hs:
		var hf: Dictionary = Friends.all()[hid]
		var fam = ""
		if not Lineage.spouse_entry(hf).is_empty():
			fam = ", evli" + (", %d çocuk" % Lineage.kid_entries(hf).size() if not Lineage.kid_entries(hf).is_empty() else "")
		opts.append({"label": "%s (%d yaş, %s, Güç %d%s)" % [String(hf["name"]), int(Aging.person_years(hf)), Friends.rank_label(hf), int(hf.get("pupil_lv", 1)), fam],
			"cb": func(): _die_with(String(hid))})
	Hud.dialog("Son Nefes", "Ömrün doldu; gözlerin kapanmadan önce çocukların başucunda. Alın koruyucunu hangisine uzatıyorsun?", opts)


func _last_breath() -> void:
	var pl = Game.player
	var p = pr()
	var old_name = String(p.get("name", ""))
	var yrs = int(Aging.player_years())
	var cf: Dictionary = Friends.all()[id]
	var kid_short = String(cf["name"]).split(" ")[-1]
	var was_kage = Kage.is_kage()
	var home = Progress.home()
	pl.model.play("idle", 0.3)
	Hud.banner("SON NEFES", "%s, %d yaşında. Dizlerin tutmuyor; gözünün önünde koca bir ömür." % [old_name, yrs], Color(0.85, 0.8, 0.7))
	await _wait(3.2)
	_say(pl, "%s... yol artık senin." % kid_short, 3.4)
	await _wait(2.4)
	pl.model.play("death", 0.25, 0.6, true)
	await _wait(3.0)
	await Interiors.inst._fade(1.0, 1.4)
	var kid_years = Aging.person_years(cf)
	var me_id = Legacy.inherit(id)
	var me: Dictionary = Friends.all()[me_id]
	Aging.set_years(me, float(yrs))
	me["status"] = "öldü"      # köy mezarlığı + cenaze: Friends'in kendi akışı
	me["party"] = false
	me["title"] = "Rahmetli annen" if String(me.get("kin", "")) == "anne" else "Rahmetli baban"
	Friends.log_event(me, "%d yaşında, yaşlılıktan öldü" % yrs)
	Aging.set_years(p, kid_years)
	p.erase("life")
	p["body"] = {"fat": 0.0, "mus": 0.0}
	p["flags"].erase("old_warned")
	p["flags"].erase("old_noheir")
	if Orgs.is_rogue():        # suç eski bedenle gömülür
		Orgs.flags()["rogue"] = false
		Orgs.flags().erase("hideout")
		Orgs.state()["bounty"] = 0
	if was_kage:
		Kage.succeed(home, "%s yaşlılıktan öldü" % old_name)
	pl.velocity = Vector3.ZERO
	pl.rebuild_model()
	pl.apply_profile_stats()
	pl.hp = pl.max_hp
	pl.chakra = pl.max_chakra
	Progress.on_power_changed()
	Journal.add("%s %d yaşında son nefesini verdi. Başucundaydım; alın koruyucusu artık bende." % [old_name, yrs], "milestone")
	Game.save_game()
	await _wait(1.6)
	await Interiors.inst._fade(0.0, 1.4)
	Hud.banner("YENİ NESİL", "%s — %s'in yolu sende yaşıyor" % [String(p["name"]), old_name.split(" ")[-1]], Color(1.0, 0.85, 0.45))
	_pose(pl, "bow", {"anim": "idle", "len": 2.6})
	await _wait(2.8)
	_clear_pose(pl)


# ====================================================================== geçiş (kayıt)
static func _avg_for(power: float) -> float:
	return 100.0 * pow(maxf(power, 1.0) / 100.0, 1.0 / 0.7)


## Kayıt çocuğa döner; eski sen bir aile kaydı olur. Dönüş: eski senin kayıt kimliği
static func inherit(fid: String) -> String:
	var p = pr()
	var fs = Friends.all()
	var cf: Dictionary = fs[fid]
	var old_name = String(p.get("name", ""))
	var old_f = String(p.get("gender", "m")) == "f"
	var old_power = int(p.get("level", 1))
	var old_rank = int(p.get("rank", 0))
	var old_clan = String(p.get("clan", "none"))
	# --- eski sen: aile kaydı
	var olk: Dictionary = (p.get("look", {}) as Dictionary).duplicate()
	olk["gender"] = "f" if old_f else "m"
	var me_id = Friends._make_friend(old_name, old_clan if old_clan != "none" else "", olk, 95, "Annen" if old_f else "Baban")
	var me: Dictionary = fs[me_id]
	me["rank"] = clampi(old_rank, 0, 3)
	me["pupil_lv"] = float(old_power)
	me["taught"] = []
	me["loyalty"] = 100
	me["retired"] = true
	me["element"] = String((p.get("elements", ["katon"]) as Array)[0])
	var eye_lvl := 0
	for slot in ["sag_goz", "sol_goz"]:
		var g = Gear.equipped(p, slot)
		if not g.is_empty():
			eye_lvl = maxi(eye_lvl, int(g.get("lvl", 1)))
	if eye_lvl > 0:
		me["eye"] = [int(ClanWorld.EYE_KIND.get(old_clan, 0)), mini(eye_lvl, 3)]
	Friends.log_event(me, "Alın koruyucusunu %s'e bıraktı" % String(cf["name"]).split(" ")[-1])
	# --- eski ailen: bir kuşak yukarı
	var oldk: Dictionary = p.get("kin_ids", {})
	for rel in oldk:
		if not fs.has(String(oldk[rel])):
			continue
		var kf: Dictionary = fs[String(oldk[rel])]
		var kfem = String(kf.get("look", {}).get("gender", "m")) == "f"
		kf.erase("kin")
		kf["elder_kin"] = true
		match String(rel):
			"baba": kf["title"] = "Deden"
			"anne": kf["title"] = "Büyükannen"
			"kardeş": kf["title"] = ("Teyzen" if kfem else "Dayın") if old_f else ("Halan" if kfem else "Amcan")
	var kin_ids = {"anne" if old_f else "baba": me_id}
	me["kin"] = "anne" if old_f else "baba"
	# --- eşin: diğer ebeveynin
	var sid = Friends.spouse_id()
	if sid != "" and fs.has(sid):
		var sf: Dictionary = fs[sid]
		sf["kin"] = "baba" if old_f else "anne"
		sf["title"] = "Baban" if old_f else "Annen"
		sf.erase("romance")
		sf["love"] = 0
		kin_ids[sf["kin"]] = sid
	p.erase("spouse")
	p.erase("baby_due")
	p.erase("birth_wait")
	# --- diğer çocukların: kardeşlerin
	for oid in fs:
		var of: Dictionary = fs[oid]
		if oid != fid and of.get("child", false):
			of.erase("child")
			of["kin"] = "kardeş"
			of["title"] = "Kardeşin"
			if not kin_ids.has("kardeş"):
				kin_ids["kardeş"] = oid
	var young = []
	for kid in p.get("children", []):
		if String(kid.get("name", "")) == String(cf["name"]):
			continue   # mirasçının kendi kaydı
		kid["sib"] = true   # evdeki küçükler artık kardeşin
		young.append(kid)
	p["children"] = young
	p["kin_ids"] = kin_ids
	p["kin_made"] = true
	p["sib_score"] = [0, 0]
	# --- dostlar: seni onun çocuğu olarak tanır
	for oid in fs:
		var of2: Dictionary = fs[oid]
		if oid == me_id or oid == fid or of2.has("kin") or of2.get("elder_kin", false):
			continue
		of2["title"] = "Annenin tanıdığı" if old_f else "Babanın tanıdığı"
		of2["bond"] = int(int(of2.get("bond", 0)) * 0.5)
		of2["love"] = 0
		of2.erase("romance")
		of2.erase("pupil")
		of2["party"] = false
	# --- kimlik
	var anc: Array = p.get("ancestors", [])
	anc.append({"name": old_name, "rank": old_rank, "power": old_power})
	p["ancestors"] = anc
	p["name"] = String(cf["name"])
	p["gender"] = String(cf.get("look", {}).get("gender", "m"))
	var nclan = String(cf.get("clan", ""))
	p["clan"] = nclan if nclan != "" else "none"
	p["soy"] = ""
	p["elements"] = [String(cf.get("element", "katon"))]
	p["element_known"] = true
	p["rank"] = clampi(int(cf.get("rank", 0)), 0, 3)
	p["missions_done"] = {"D": 0, "C": 0, "B": 0, "A": 0, "S": 0}
	var lk = Friends.look_of(cf)
	lk["village"] = p["village"]
	lk.erase("keep_hair")
	lk.erase("age")
	p["look"] = lk
	# --- ustalık: bir kısmı miras, çocuğun kendi emeğinden az değil
	var m: Dictionary = p.get("mastery", {})
	var floor_v = _avg_for(float(cf.get("pupil_lv", 6.0)))
	for k in Mastery.KEYS:
		var nv = float(m.get(k, 0.0)) * KEEP
		if k in ["ninjutsu", "taijutsu", "chakra", "dayaniklilik"]:
			nv = maxf(nv, floor_v)
		m[k] = nv
	p["mastery"] = m
	p["skills"] = []
	p["sp"] = int(Mastery.total(p) / Mastery.SP_PER)
	Mastery.refresh_level(p)
	# --- gözler eski bedende kalır; çocuğun kendi gözü (klanı varsa) doğuştan
	var gear: Array = p.get("gear", [])
	var eq: Dictionary = p.get("equip", {})
	for g2 in gear.duplicate():
		if String(Gear.item(String(g2["id"])).get("slot", "")) == "goz":
			gear.erase(g2)
	for slot2 in ["sag_goz", "sol_goz"]:
		eq.erase(slot2)
	if not p.has("flags"):
		p["flags"] = {}
	p["flags"].erase("born_eyes")
	p["flags"].erase("dormant_eye")
	# şartı tutmayan takılı parçalar çıkar (rütbe / klan / cinsiyet); eşya sende kalır
	for slot3 in eq.keys():
		var g3 = Gear.find(p, eq[slot3])
		if g3.is_empty():
			continue
		if Gear.req_text(String(g3["id"]), p) != "" or (slot3 == "set" and not Gear.sex_ok(String(g3["id"]), String(p["gender"]))):
			eq.erase(slot3)
	# --- teknikler: doğası tutanlar; göz / yol / canavar / sennin / başka klanın gizli tekniği eski bedende
	var keep = []
	for jid in p.get("learned", []):
		var j: Dictionary = Data.jutsu.get(jid, {})
		var lp = String(j.get("learn", ""))
		if lp.begins_with("eye:") or lp.begins_with("path:") or lp.begins_with("sage") or lp.begins_with("kg:"):
			continue
		var jc = String(j.get("clan", ""))
		if lp.begins_with("clan") and jc != "" and jc != String(p["clan"]) and lp != "clan:" + String(p["clan"]):
			continue
		if lp.begins_with("clan:") and lp != "clan:" + String(p["clan"]):
			continue
		if Progress.element_block(String(jid)) != "":
			continue
		keep.append(jid)
	for t in cf.get("taught", []):
		if not t in keep and Data.jutsu.has(t):
			keep.append(t)
	p["learned"] = keep
	var sl = []
	for jid2 in keep:
		if sl.size() < 9:
			sl.append(jid2)
	while sl.size() < 9:
		sl.append("")
	p["slots"] = sl
	Lineage.on_inherit(fid, cf)   # mirasçının eşi eşin, çocukları çocukların olur
	# --- çocuğun dost kaydı kapanır (artık sensin)
	fs.erase(fid)
	Gear.ensure(p)
	var lvl = int((cf.get("eye", [0, 0]) as Array)[1]) if cf.get("eye") is Array else 0
	if lvl > 1:
		for slot4 in ["sag_goz", "sol_goz"]:
			var g4 = Gear.equipped(p, slot4)
			if not g4.is_empty():
				g4["lvl"] = lvl
	ClanMech.ensure(p)
	Progress.ensure_rank_outfit()
	Gear.apply_look(p)
	Journal.add("%s alın koruyucusunu bana bıraktı. Artık yol benim: %s." % [old_name, String(p["name"])], "milestone")
	return me_id


# ====================================================================== tören
func _ready() -> void:
	Hud.close_dialog()
	_lock(120.0)
	if death:
		await _last_breath()
		if cur == self:
			cur = null
		_release_player()
		queue_free()
		return
	_was_phys = v.is_physics_processing()
	v.set_physics_process(false)
	await _ceremony()
	if cur == self:
		cur = null
	_release_player()
	queue_free()


func _exit_tree() -> void:
	if cur == self:
		cur = null
		_release_player()


func _process(dt: float) -> void:
	_apply_poses(dt)
	if is_instance_valid(band) and is_instance_valid(band_at):
		# el kemikleri oyuncuda gecikmeli okunur: bant poz formülünden yerleşir (avuçların üstü)
		var reach = float(st[band_at].get("reach", 0.4)) if st.has(band_at) else 0.4
		var p = band_at.global_position + Vector3.UP * (1.24 * band_at.model.age_scale - 0.01) + _fd(band_at) * (reach + 0.03)
		band.global_position = band.global_position.lerp(p, minf(1.0, dt * 12.0))
		band.global_basis = Basis(Vector3.UP, band_at.facing)


func _tell(text: String, dur := 2.4) -> void:
	Combat.popup_text(_bone(Game.player, "Head") + Vector3.UP * 0.35, text, Color(1.0, 0.92, 0.72))
	await _wait(dur)


func _make(n: Node3D, s: Dictionary) -> Dictionary:
	var fd = _fd(n)
	var right = fd.cross(Vector3.UP).normalized()
	var sc: float = n.model.age_scale
	match String(s["k"]):
		"knot":    # iki el başın arkasında: bandın düğümü
			var c = _bone(n, "Head") - fd * 0.1 * sc + Vector3.UP * 0.03 + Vector3.UP * sin(float(s["t"]) * 9.0) * 0.012
			var a = _ik(n, "Left", c - right * 0.07)
			a.append_array(_ik(n, "Right", c + right * 0.07))
			return {"arms": a, "fL": GRIP, "fR": GRIP, "spine": 4.0, "neck": 14.0}
		"offer":   # iki avuçta uzatır / alır
			var mid = n.global_position + Vector3.UP * 1.24 * sc + fd * float(s.get("reach", 0.4))
			var a2 = _ik(n, "Left", mid - right * 0.09)
			a2.append_array(_ik(n, "Right", mid + right * 0.09))
			return {"arms": a2, "fL": HALF, "fR": HALF, "spine": float(s.get("lean", 6.0)), "neck": 8.0}
	return super._make(n, s)


func _band_mesh() -> MeshInstance3D:
	var b = MB.new()
	b.add("box", Vector3.ZERO, Vector3(0.6, 0.014, 0.075), Color(0.16, 0.22, 0.5))
	b.add("box", Vector3(0, 0.014, 0), Vector3(0.17, 0.016, 0.07), Color(0.8, 0.82, 0.86))
	return _mesh(b)


func _ceremony() -> void:
	var pl = Game.player
	var cf: Dictionary = Friends.all()[id]
	var me_parent = "Anne" if String(pr().get("gender", "m")) == "f" else "Baba"
	var kid_short = String(cf["name"]).split(" ")[-1]
	# karşısına geç
	var to = pl.global_position - v.global_position
	to.y = 0
	if to.length() < 0.1:
		to = Vector3(0, 0, 1)
	_look_at(v, pl.global_position)
	var spot = v.global_position + to.normalized() * 1.0
	spot.y = Game.ground_height(spot.x, spot.z)
	await _go_w(pl, spot, 1.5)
	_look_at(pl, v.global_position)
	_look_at(v, pl.global_position)
	await _tell("%s. Sana verecek bir şeyim var." % kid_short, 2.8)
	_say(v, "...%s? Ciddi görünüyorsun." % me_parent, 2.8)
	await _wait(2.4)
	# bandını çözer
	_pose(pl, "knot", {"anim": "idle"})
	Sfx.play("pickup", pl.global_position, 0.5, 0.8)
	await _wait(2.4)
	band = _band_mesh()
	band.global_position = _bone(pl, "Head")
	band_at = pl
	_pose(pl, "offer", {"anim": "idle", "reach": 0.26})
	await _wait(1.0)
	await _tell("Bu bantla çok yol yürüdüm. Düştüm, kalktım.", 3.0)
	_pose(pl, "offer", {"anim": "idle", "reach": 0.4, "lean": 10.0})
	await _tell("Artık sıra sende. Benden ileriye git.", 3.0)
	_say(v, "%s... ben... hazır mıyım?" % me_parent, 2.8)
	await _wait(2.4)
	await _tell("Benden daha hazırsın.", 2.2)
	# eğilir, iki eliyle alır
	_pose(v, "bow", {"anim": "idle", "len": 2.0})
	await _wait(2.0)
	_pose(v, "offer", {"anim": "idle", "reach": 0.4, "lean": 12.0})
	await _wait(0.7)
	band_at = v
	_clear_pose(pl)
	pl.model.play("idle", 0.3)
	await _wait(0.9)
	# alnına bağlar
	_pose(v, "knot", {"anim": "idle"})
	band_at = null
	band.queue_free()
	Sfx.play("pickup", v.global_position, 0.5, 0.8)
	await _wait(2.4)
	_clear_pose(v)
	v.model.play("idle", 0.3)
	_say(v, "Seni utandırmayacağım. Söz.", 3.0)
	await _wait(1.6)
	# sarılırlar
	var near = v.global_position + to.normalized() * 0.33
	near.y = Game.ground_height(near.x, near.z)
	await _go_w(pl, near, 1.2)
	_look_at(pl, v.global_position)
	_pose(pl, "hug", {"with": v, "anim": "idle", "hi": 0.08})
	_pose(v, "hug", {"with": pl, "anim": "idle", "hi": -0.08})
	await _wait(3.0)
	# --- geçiş
	await Interiors.inst._fade(1.0, 0.8)
	_clear_pose(pl)
	_clear_pose(v)
	var kid_pos = v.global_position
	var kid_face: float = v.facing
	var old_pos = spot
	v.queue_free()
	var old_years = Aging.player_years()
	var kid_years = Aging.person_years(Friends.all()[id])
	var me_id = Legacy.inherit(id)
	Aging.set_years(Friends.all()[me_id], old_years)
	Aging.set_years(pr(), kid_years)
	pr().erase("life")
	pr()["body"] = {"fat": 0.0, "mus": 0.0}
	pl.global_position = kid_pos + Vector3.UP * 0.05
	pl.velocity = Vector3.ZERO
	pl.rebuild_model()
	pl.apply_profile_stats()
	pl.hp = pl.max_hp
	pl.chakra = pl.max_chakra
	Progress.on_power_changed()
	_face(pl, kid_face)
	var old = Friends.inst()._spawn_npc(me_id, old_pos, false)
	old.set_physics_process(false)
	await _wait(1.8)
	_look_at(old, pl.global_position)
	_look_at(pl, old.global_position)
	Game.save_game()
	await Interiors.inst._fade(0.0, 1.0)
	Hud.banner("YENİ NESİL", "%s — yol artık senin" % String(pr()["name"]), Color(1.0, 0.85, 0.45))
	old.model.play("yes", 0.2, 1.0, true)
	_say(old, "Bak sana... yakıştı. Artık senin yolun, %s." % kid_short, 3.6)
	await _wait(3.0)
	_pose(pl, "bow", {"anim": "idle", "len": 2.2})
	await _wait(2.4)
	_clear_pose(pl)
	_say(old, "Ben hep evdeyim. Takıldığın yerde gel, bildiğimi öğretirim.", 3.6)
	await _wait(2.6)
	_release_player()
	var away = old.global_position + (old.global_position - pl.global_position).normalized() * 16.0
	await _go_w(old, away, 1.4)
	if is_instance_valid(old):
		old.home = old.global_position
		old.goal = old.global_position
		old.wander_r = 6.0
		old.set_physics_process(true)
		var o2 = old
		Friends.inst().get_tree().create_timer(60.0, false).timeout.connect(func():
			if is_instance_valid(o2):
				o2.queue_free())
