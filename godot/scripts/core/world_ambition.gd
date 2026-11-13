class_name WorldAmbition
extends RefCounted
## Güce takmış kişiler (kullanıcı 2026-11-13: "oyunda 10 tane güçlenmeyle kafayı bozmuş NPC olur ... dinamik gelişir").
## Dünya nüfusundan (WorldPeople) en az TARGET kişi güç peşindedir; kim oldukları sabit liste değil, kişinin kendi verisinden
## çıkar (bağlılık, yas, rütbesine göre Güç, klan, göz, hayali). Her dünya turunda hedeflerine doğru GERÇEK adımlar atarlar:
##  · göz merdiveni (kanon): Sharingan -> yakınını öldürüp Mangekyō -> başka bir Mangekyō sahibinin gözleriyle Ebedi Mangekyō
##    -> bir Senju'nun hücreleriyle Rinnegan; gözü olmayan başkasının gözünü çalıp nakleder (Danzō)
##  · kuyruklu canavar: ya kendi bedenine mühürler (jinchūriki olur) ya da Mangekyō / Rinnegan ile emrine alır (Madara)
##  · yol / yasak jutsu / yeni doğa
## Adımların kurbanı dünyadaki gerçek kişilerdir (ölürler, gözsüz kalırlar, canavarları sökülür); oyuncuda istedikleri şey
## varsa (Mangekyō gözleri, içindeki canavar, Senju hücresi) onun da peşine düşerler.
## Dövüşte ulaştıklarını kullanırlar: tam gövde Susanoo, mühürlü canavara dönüşüm (+ Susanoo zırhı), emrindeki canavarı
## savaş alanına çağırma, Rinnegan. Kage'ler ayrıca güçlenir, nadiren köyün canavarını kendine mühürler, kaçağın peşine düşer.
## Kayıt kişide: p["amb"] = {"t", "ctrl": [canavar], "want": ""}, p["beast"] = mühürlü canavar; canavarda host["wp"] / "ctrl_by".

const TARGET := 12
const CTRL_MAX := {4: 1, 5: 2, 6: 9}
static var _hunt_t := 0.0
static var _hunt_next := 1200.0
static var _hunter: WeakRef = null


static func is_amb(p: Dictionary) -> bool:
	return p.has("amb")


static func people() -> Array:
	return WorldPeople.all().values().filter(func(p): return p.has("amb") and WorldPeople.alive(p))


static func _sync(p: Dictionary) -> void:
	var e = WorldPeople.bingo_of(p)
	if not e.is_empty():
		WorldPeople._sync_bingo(p, e)


static func _crime(p: Dictionary, text: String) -> void:
	WorldPeople.log_event(p, text)
	var cr: Array = p.get("crimes", [])
	cr.append(text)
	p["crimes"] = cr.slice(maxi(0, cr.size() - 5))
	_sync(p)


static func _go_rogue(p: Dictionary, why: String) -> void:
	if not WorldPeople.is_rogue(p) and String(p.get("kage", "")) == "":
		WorldPeople.defect(p, why)


# ------------------------------------------------------------------ kim güce takar
static func score(p: Dictionary) -> float:
	var s = float(p["level"]) / 40.0 + (60.0 - float(p.get("loyalty", 60))) / 25.0
	if p.get("grief", false):
		s += 1.5
	if p.get("behind", false):
		s += 1.0
	if WorldPeople.is_rogue(p):
		s += 1.0
	if String(p.get("clan", "")) == "uchiha":
		s += 2.0
	if int((p.get("eye", [0, 0]) as Array)[0]) > 0:
		s += 2.5
	if WorldDay.dream(p) in ["guc", "intikam", "rakip"]:
		s += 1.5
	return s + randf() * 1.5


static func _why(p: Dictionary) -> String:
	if p.get("grief", false):
		return "Yakınını kaybettikten sonra güçten başka bir şey düşünmez oldu"
	if p.get("behind", false):
		return "Rakibinin gerisinde kalmaya dayanamadı; ne pahasına olursa olsun güçlenmeye yemin etti"
	if int(p.get("loyalty", 60)) < 40:
		return "Köyünün onu geride tuttuğuna inanıyor; gücün her yolunu arıyor"
	return "Kendi sınırını görmek istiyor; hiçbir yasak onu durdurmuyor"


## Sayı TARGET'ın altındaysa dünyadan yeni biri güce takar (ilk kuruluşta hepsi birden, sonra birer birer)
## Sistem bitene dek kapalı (test: AMB=1 ortam değişkeni açar)
static var ON: bool = OS.get_environment("AMB") == "1"


static func ensure() -> void:
	var cur = people()
	if cur.size() >= TARGET:
		return
	var cands = WorldPeople.all().values().filter(func(p): return WorldPeople.alive(p) and not p.has("amb") and not p.get("missing", false) and String(p.get("kage", "")) == "" and int(p["level"]) >= 45)
	if cands.is_empty():
		return
	var sc = {}
	for p in cands:
		sc[String(p["id"])] = score(p)
	cands.sort_custom(func(a, b): return float(sc[String(a["id"])]) > float(sc[String(b["id"])]))
	var first = cur.is_empty()
	for p in cands.slice(0, (TARGET - cur.size()) if first else 1):
		p["amb"] = {"t": Aging.clock(), "ctrl": [], "want": ""}
		WorldPeople.log_event(p, _why(p))
		if not first and randf() < 0.5:
			WorldNews.headline("Söylenti: %s gücün peşinde tehlikeli yollara sapmış." % String(p["name"]), Color(0.9, 0.6, 0.9))


# ------------------------------------------------------------------ canavar kayıtları
static func _bs() -> Dictionary:
	return TailedBeasts.beasts()


## Kişinin bedenine mühürlü canavar (kayıt hâlâ geçerliyse)
static func beast_of(p: Dictionary) -> String:
	var id = String(p.get("beast", ""))
	if id == "":
		return ""
	var b: Dictionary = _bs().get(id, {})
	if String(b.get("state", "")) == "host" and String((b.get("host", {}) as Dictionary).get("wp", "")) == String(p["id"]):
		return id
	p.erase("beast")
	return ""


## Kişinin gözüyle emrine aldığı canavarlar (kayıt hâlâ geçerli olanlar)
static func ctrl_of(p: Dictionary) -> Array:
	if not p.has("amb"):
		return []
	var out = []
	for id in (p["amb"].get("ctrl", []) as Array):
		var b: Dictionary = _bs().get(String(id), {})
		if String(b.get("ctrl_by", "")) == String(p["id"]) and String(b.get("state", "")) in ["wild", "free"]:
			out.append(String(id))
	p["amb"]["ctrl"] = out
	return out


## Ölenlerin canavarı serbest kalır
static func cleanup() -> void:
	var bs = _bs()
	for id in bs:
		var b: Dictionary = bs[id]
		var wp = String((b.get("host", {}) as Dictionary).get("wp", "")) if String(b.get("state", "")) == "host" else ""
		if wp != "":
			var q = WorldPeople.get_p(wp)
			if q.is_empty() or not WorldPeople.alive(q):
				b["state"] = "wild"
				b.erase("host")
				TailedBeasts._news("SÖYLENTİ", "%s öldü; içindeki %s serbest kalıp inine döndü." % [String(q.get("name", "Taşıyıcısı")), TailedBeasts._bname(id)])
		var cb = String(b.get("ctrl_by", ""))
		if cb != "":
			var q2 = WorldPeople.get_p(cb)
			if q2.is_empty() or not WorldPeople.alive(q2) or int((q2.get("eye", [0, 0]) as Array)[0]) < 4:
				b.erase("ctrl_by")


# ------------------------------------------------------------------ adımlar
static func world_tick() -> void:
	if not ON:
		return
	if Game.profile.is_empty():
		return
	cleanup()
	ensure()
	for p in people():
		if not p.get("missing", false) and randf() < 0.35:
			step(p)
	kage_step()


static func step(p: Dictionary) -> void:
	p["level"] = mini(320, int(p["level"]) + randi_range(1, 4))
	var lv = int(p["level"])
	var e: Array = p.get("eye", [0, 0])
	var k = int(e[0])
	if k == 1 and int(e[1]) < 3:
		if WorldPeople._grow_eye(p):
			_sync(p)
			return
	if k == 1 and int(e[1]) >= 3 and lv >= 80 and randf() < 0.15 and _awaken_ms(p):
		return
	if k == 4 and lv >= 120 and randf() < 0.12 and _take_ems(p):
		return
	if k == 5 and lv >= 160 and randf() < 0.1 and _take_cells(p):
		return
	if k == 0 and lv >= 100 and randf() < 0.1 and _steal_eye(p):
		return
	if lv >= 150 and randf() < 0.07 and _beast(p):
		return
	if WorldPeople._try_path(p) or WorldPeople._kinjutsu(p):
		_sync(p)
		return
	if (p["els"] as Array).size() < 2 and lv >= 90 and randf() < 0.3:
		WorldPeople._second_element(p)
	WorldPeople._learn(p)
	_sync(p)


## Mangekyō (kanon: en yakınının ölümü). Yakını hayattaysa kendi eliyle öldürür ve köyden kaçar; yas tutuyorsa acısı yeter.
static func _awaken_ms(p: Dictionary) -> bool:
	var c = WorldPeople.get_p(String(p.get("close", "")))
	if not c.is_empty() and WorldPeople.alive(c) and String(c.get("kage", "")) == "":
		var cn = String(c["name"])
		p["eye"] = [4, 3]
		WorldPeople._die(c, "En yakını %s tarafından öldürüldü" % String(p["name"]))
		_go_rogue(p, "En yakınını, %s'yi kendi eliyle öldürdü" % cn)
		_crime(p, "Mangekyō Sharingan için en yakını %s'yi öldürdü" % cn)
		WorldPeople._learn(p)
		WorldNews.headline("Söylenti: %s en yakınını öldürmüş; gözlerinin biçimi değişmiş diyorlar." % String(p["name"]), Color(0.95, 0.4, 0.4))
		return true
	if p.get("grief", false):
		p["eye"] = [4, 3]
		WorldPeople.log_event(p, "Kaybının acısıyla Mangekyō Sharingan'ı uyandı")
		WorldPeople._learn(p)
		_sync(p)
		return true
	return false


## Ebedi Mangekyō: başka bir Mangekyō sahibinin gözleri (kanon: Madara - Izuna, Sasuke - Itachi)
static func _take_ems(p: Dictionary) -> bool:
	var vs = WorldPeople.all().values().filter(func(q): return q != p and WorldPeople.alive(q) and int((q.get("eye", [0, 0]) as Array)[0]) in [4, 5])
	if vs.is_empty():
		if Progress.has_eye("mangekyo"):
			p["amb"]["want"] = "player_eyes"
		return false
	var v: Dictionary = vs.pick_random()
	var vn = String(v["name"])
	if float(p["level"]) * randf_range(0.7, 1.3) < float(v["level"]) * randf_range(0.7, 1.3):
		WorldPeople.log_event(p, "%s'nin gözleri için saldırdı, püskürtüldü" % vn)
		WorldPeople.log_event(v, "Gözlerinin peşindeki %s'yi püskürttü" % String(p["name"]))
		return true
	p["eye"] = [5, 3]
	WorldPeople._die(v, "Gözleri için %s tarafından öldürüldü" % String(p["name"]))
	_go_rogue(p, "%s'yi gözleri için öldürdü" % vn)
	_crime(p, "%s'yi öldürüp gözlerini nakletti: Ebedi Mangekyō Sharingan" % vn)
	WorldPeople._learn(p)
	WorldNews.headline("Söylenti: %s, %s'nin gözlerini almış. Artık kör olmayacak." % [String(p["name"]), vn], Color(0.95, 0.35, 0.35))
	return true


## Rinnegan: Ebedi Mangekyō + bir Senju'nun hücreleri (kanon: Madara)
static func _take_cells(p: Dictionary) -> bool:
	var vs = WorldPeople.all().values().filter(func(q): return q != p and WorldPeople.alive(q) and String(q.get("clan", "")) == "senju")
	if vs.is_empty():
		if String(Game.profile.get("clan", "")) == "senju":
			p["amb"]["want"] = "player_cells"
		return false
	var v: Dictionary = vs.pick_random()
	var vn = String(v["name"])
	if float(p["level"]) * randf_range(0.7, 1.3) < float(v["level"]) * randf_range(0.6, 1.2):
		WorldPeople.log_event(p, "Senju %s'nin hücreleri için saldırdı, püskürtüldü" % vn)
		return true
	p["eye"] = [6, 3]
	WorldPeople._die(v, "Hücreleri için %s tarafından öldürüldü" % String(p["name"]))
	_crime(p, "Senju %s'yi öldürüp hücrelerini kendine nakletti: Rinnegan uyandı" % vn)
	WorldPeople._learn(p)
	WorldNews.headline("Söylenti: %s'nin gözlerinde halkalar görülmüş. Rinnegan geri döndü." % String(p["name"]), Color(0.75, 0.6, 1.0))
	return true


## Gözü olmayan başkasının gözünü çalıp nakleder (kanon: Danzō, Ao)
static func _steal_eye(p: Dictionary) -> bool:
	var vs = WorldPeople.all().values().filter(func(q): return q != p and WorldPeople.alive(q) and String(q.get("kage", "")) == "" and not q.has("amb") and ((int(q["eye"][0]) == 1 and int(q["eye"][1]) >= 3) or int(q["eye"][0]) == 2) and float(q["level"]) < float(p["level"]) * 1.1)
	if vs.is_empty():
		return false
	var v: Dictionary = vs.pick_random()
	var vn = String(v["name"])
	var ek = int(v["eye"][0])
	p["eye"] = [ek, int(v["eye"][1])]
	p["amb"]["implant"] = true
	var en = "Sharingan" if ek == 1 else "Byakugan"
	if randf() < 0.5:
		WorldPeople._die(v, "%s'ı için %s tarafından öldürüldü" % [en, String(p["name"])])
	else:
		v["eye"] = [0, 0]
		WorldPeople.log_event(v, "%s gözünü çaldı; artık göremiyor" % String(p["name"]))
	_go_rogue(p, "%s'nin gözünü çaldı" % vn)
	_crime(p, "%s'nin %s'ını söküp kendine nakletti" % [vn, en])
	WorldPeople._learn(p)
	WorldNews.headline("Söylenti: %s, %s'nin %s'ını çalmış." % [String(p["name"]), vn, en], Color(0.95, 0.5, 0.5))
	return true


## Kuyruklu canavar: bedenine mühürler ya da (Mangekyō / Rinnegan) emrine alır
static func _beast(p: Dictionary) -> bool:
	var bs = _bs()
	var k = int((p.get("eye", [0, 0]) as Array)[0])
	var can_ctrl = k >= 4 and ctrl_of(p).size() < int(CTRL_MAX.get(k, 0))
	var can_seal = beast_of(p) == ""
	if not can_ctrl and not can_seal:
		return false
	var opts = []
	for id in TailedBeasts.LAIRS:
		var b: Dictionary = bs.get(id, {})
		var st = String(b.get("state", "wild"))
		if not st in ["wild", "free", "host"] or (TailedBeasts.spawned.has(id) and is_instance_valid(TailedBeasts.spawned[id])):
			continue
		if String(b.get("ctrl_by", "")) != "" or (st == "host" and (String(b["host"].get("wp", "")) == String(p["id"]) or Missions.bingo_host_spawned(id))):
			continue
		opts.append(id)
	if opts.is_empty():
		if TailedBeasts.player_jinchuriki() != "":
			p["amb"]["want"] = "player_beast"
		return false
	var id: String = opts.pick_random()
	var b: Dictionary = bs[id]
	var bn = TailedBeasts._bname(id)
	var lv = float(p["level"])
	if randf() > clampf((lv - 110.0) / 150.0, 0.1, 0.8):
		WorldPeople.log_event(p, "%s ile boy ölçüştü, geri çekilmek zorunda kaldı" % bn)
		return true
	if String(b.get("state", "")) == "host":
		var h: Dictionary = b["host"]
		var hw = WorldPeople.get_p(String(h.get("wp", "")))
		if not hw.is_empty() and WorldPeople.alive(hw):
			hw.erase("beast")
			WorldPeople._die(hw, "İçindeki %s, %s tarafından söküldü" % [bn, String(p["name"])])
		if h.get("rogue", false):
			Missions.remove_rogue_jinchuriki(id)
		_crime(p, "Jinchūriki %s'yi öldürüp içindeki %s'yi söktü" % [String(h.get("name", "?")), bn])
		b.erase("host")
		b["state"] = "wild"
	if can_ctrl and (not can_seal or randf() < 0.5):
		b["ctrl_by"] = String(p["id"])
		(p["amb"]["ctrl"] as Array).append(id)
		_crime(p, "Gözleriyle %s'yi emrine aldı" % bn)
		TailedBeasts._news("SÖYLENTİ", "%s, %s'yi gözleriyle emrine almış; onu savaşa çağırabiliyor." % [String(p["name"]), bn], Color(0.9, 0.4, 0.5))
	else:
		b["state"] = "host"
		b["host"] = {"name": String(p["name"]), "village": String(p["village"]), "rogue": WorldPeople.is_rogue(p), "level": int(p["level"]), "gender": "f" if p["female"] else "m", "wp": String(p["id"])}
		p["beast"] = id
		_crime(p, "%s'yi kendi bedenine mühürledi" % bn)
		TailedBeasts._news("SÖYLENTİ", "%s, %s'yi kendi bedenine mühürledi." % [String(p["name"]), bn], Color(1.0, 0.5, 0.35))
	return true


# ------------------------------------------------------------------ Kage'ler
## Kage köyünün en güçlüsüdür ve güçlenmeye devam eder; nadiren köyün canavarını kendine mühürler; ara sıra köyünü
## tehdit eden güce takmış bir kaçağın peşine bizzat düşer (kim kazanır Güç'e bağlı)
static func kage_step() -> void:
	for p in WorldPeople.all().values():
		var vid = String(p.get("kage", ""))
		if vid == "" or not WorldPeople.alive(p):
			continue
		if int(p["level"]) < 200:
			p["level"] = 200
		elif int(p["level"]) < 270 and randf() < 0.3:
			p["level"] = int(p["level"]) + randi_range(1, 3)
		var bs = _bs()
		if beast_of(p) == "" and randf() < 0.01:
			for id in TailedBeasts.LAIRS:
				var b: Dictionary = bs.get(id, {})
				if String(TailedBeasts.HOME_VILLAGE.get(id, "")) == vid and String(b.get("state", "wild")) in ["wild", "free"] and String(b.get("ctrl_by", "")) == "" and not TailedBeasts.spawned.has(id):
					b["state"] = "host"
					b["host"] = {"name": String(p["name"]), "village": vid, "rogue": false, "level": int(p["level"]), "gender": "f" if p["female"] else "m", "wp": String(p["id"])}
					p["beast"] = id
					WorldPeople.log_event(p, "%s'yi kendi bedenine mühürledi" % TailedBeasts._bname(id))
					TailedBeasts._news("HABER", "%s Kage'si %s, %s'yi kendi bedenine mühürledi." % [WorldPeople.vname(vid), String(p["name"]), TailedBeasts._bname(id)], Color(1.0, 0.75, 0.4))
					break
		if randf() < 0.03:
			var rs = people().filter(func(q): return WorldPeople.is_rogue(q) and String(q["village"]) == vid and not q.get("missing", false))
			if rs.is_empty():
				continue
			var r: Dictionary = rs.pick_random()
			if float(p["level"]) * randf_range(0.7, 1.3) > float(r["level"]) * randf_range(0.7, 1.3):
				WorldPeople.log_event(p, "Kaçak %s'nin peşine bizzat düştü ve onu öldürdü" % String(r["name"]))
				WorldPeople._die(r, "%s Kage'si %s tarafından öldürüldü" % [WorldPeople.vname(vid), String(p["name"])])
				var be = WorldPeople.bingo_of(r)
				if not be.is_empty():
					be["status"] = "dead"
				WorldNews.headline("%s Kage'si %s, kaçak %s'yi bizzat bulup öldürdü." % [WorldPeople.vname(vid), String(p["name"]), String(r["name"])], Color(0.75, 1.0, 0.7))
			else:
				p["hurt_t"] = Aging.clock() + randf_range(400.0, 900.0)
				WorldPeople.log_event(p, "Kaçak %s'nin peşine düştü; yaralı döndü" % String(r["name"]))
				_crime(r, "%s Kage'si %s'yi yaralayıp kaçtı" % [WorldPeople.vname(vid), String(p["name"])])
				WorldNews.headline("%s Kage'si %s, kaçak %s ile çarpıştı ve yaralı döndü." % [WorldPeople.vname(vid), String(p["name"]), String(r["name"])], Color(1.0, 0.6, 0.5))


# ------------------------------------------------------------------ dövüş: ulaştıklarını kullanır
## WorldPeople.arch_of: bedenine canavar mühürlüyse jinchūriki olarak dövüşür (pelerin -> tam dönüşüm)
static func arch(a: Dictionary, p: Dictionary) -> void:
	if not ON:
		return
	var b = beast_of(p)
	if b != "":
		a["beast"] = b


## Susanoo kademesi: Mangekyō İnsansı / Zırhlı, Ebedi Mangekyō ve Rinnegan Güç yetince Mükemmel (tam gövde)
static func sus_tier(p: Dictionary) -> int:
	var k = int((p.get("eye", [0, 0]) as Array)[0])
	var lv = int(p["level"])
	if k == 4:
		return 4 if lv >= 140 else 3
	return 5 if lv >= 170 else 4


## WorldPeople.on_enemy_ready: sahneye çıkan güce takmış kişi
static func arm(e: Node, p: Dictionary) -> void:
	if not ON:
		return
	if not p.has("amb") and String(p.get("kage", "")) == "":
		return
	e.set_meta("amb", true)
	if int((p.get("eye", [0, 0]) as Array)[0]) >= 4:
		e.set_meta("sus_tier", sus_tier(p))
		var c = ctrl_of(p)
		if not c.is_empty():
			e.set_meta("amb_ctrl", c)


## EnemyArts: emrindeki canavarı savaş alanına çağırır (kanon: Madara - Kurama). Aynı anda bir canavar; sırayla.
static func summon(e: Enemy) -> bool:
	var ids: Array = e.get_meta("amb_ctrl", [])
	if ids.is_empty():
		return false
	for n in e.get_tree().get_nodes_in_group("fighters"):
		if n is TailedBeast and n.ally_owner == e and not n.dead:
			return false
	var i = int(e.get_meta("amb_ctrl_i", 0))
	e.set_meta("amb_ctrl_i", i + 1)
	var id = String(ids[i % ids.size()])
	if TailedBeasts.spawned.has(id) and is_instance_valid(TailedBeasts.spawned[id]):
		return false
	var b = TailedBeast.new()
	b.setup(id)
	var at = Missions.open_ground(e.global_position + Vector3(sin(e.facing), 0, cos(e.facing)) * -20.0, 25.0)
	e.get_tree().current_scene.add_child(b)
	b.global_position = at
	b.home = at
	b.make_ally(e, 45.0)
	b.display_name = "%s (%s'nin emrinde)" % [TailedBeasts._bname(id), e.display_name]
	b.rig.scale = Vector3.ONE * 0.05
	b.rig.create_tween().tween_property(b.rig, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_BACK)
	if Game.world:
		Game.world.env.add_shake(1.2)
	Sfx.play("roar", at, 0.7)
	Combat.popup_text(e.global_position + Vector3.UP * 2.6, "Kuchiyose no Jutsu!", Color(0.85, 0.6, 1.0))
	Hud.banner("BİJŪ KUCHİYOSE", "%s, %s'yi savaş alanına çağırdı!" % [e.display_name, TailedBeasts._bname(id)], BeastModels.INFO[id]["chakra"])
	return true


## EnemyJin tam dönüşüm: Mangekyō / Rinnegan sahibi jinchūriki'nin canavarı Susanoo'sunu zırh olarak giyer (oyuncuyla aynı sistem)
static func beast_armor(b: TailedBeast, e: Enemy) -> void:
	if not e.has_meta("eyes") or int(e.get_meta("eyes").get("kind", 0)) < 4 or b.rig == null:
		return
	var pr = EnemyArts.random_susanoo(e)
	var sn = Susanoo.new()
	sn.name = "Susanoo"
	b.add_child(sn)
	sn.build(pr, 5, e.model)
	sn.visible = false
	var bs = BeastSus.new()
	bs.name = "BeastSus"
	b.rig.add_child(bs)
	bs.wear(b.rig, sn)
	var col: Array = pr["susanoo"]["color"]
	Hud.banner(e.display_name, "SUSANOO + %s!" % TailedBeasts._bname(String(e.arch["beast"])).to_upper(), Color(col[0], col[1], col[2]).lightened(0.3))
	Sfx.play("susanoo_open", b.global_position, 1.0, 0.8)


# ------------------------------------------------------------------ oyuncunun peşine düşen
static func _want_text(w: String) -> String:
	return {"player_eyes": "Gözlerini istiyor.", "player_beast": "İçindeki canavarı istiyor.", "player_cells": "Senju hücrelerini istiyor."}.get(w, "")


static func _still_wants(p: Dictionary) -> bool:
	match String(p["amb"].get("want", "")):
		"player_eyes":
			return int(p["eye"][0]) == 4 and Progress.has_eye("mangekyo")
		"player_beast":
			return TailedBeasts.player_jinchuriki() != "" and (beast_of(p) == "" or int(p["eye"][0]) >= 4)
		"player_cells":
			return int(p["eye"][0]) == 5 and String(Game.profile.get("clan", "")) == "senju"
	return false


## Oyuncuda istediği şey olan biri onu bulur (av ninjalarıyla aynı kurallar: görevde / köy içinde gelmez, aynı anda tek kişi)
static func tick(dt: float) -> void:
	if not ON:
		return
	if Game.player == null or Game.profile.is_empty() or Missions.quiet():
		return
	_hunt_t += dt
	if _hunt_t < _hunt_next:
		return
	_hunt_t = _hunt_next - 20.0   # şart tutmuyorsa 20 sn sonra yeniden bak
	if _hunter != null and _hunter.get_ref() != null and not _hunter.get_ref().is_dead():
		return
	var m = Game.to_map(Game.player.global_position)
	for v in Game.world_info.get("villages", []):
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			return
	var cs = people().filter(func(p): return not p.get("missing", false) and not p.has("run") and _still_wants(p))
	if cs.is_empty():
		return
	_hunt_t = 0.0
	_hunt_next = randf_range(1200.0, 2400.0)
	come(cs.pick_random())


static func come(p: Dictionary) -> Enemy:
	var a = WorldPeople.arch_of(p)
	var e = Enemy.new()
	e.setup(a)
	Game.player.get_tree().current_scene.add_child(e)
	var ang = randf() * TAU
	var at = Missions.open_ground(Game.player.global_position + Vector3(cos(ang), 0, sin(ang)) * 45.0, 20.0)
	e.global_position = at
	e.home = at
	e.target = Game.player
	_hunter = weakref(e)
	Hud.banner(String(p["name"]), "Seni buldu. %s" % _want_text(String(p["amb"].get("want", ""))), Color(0.95, 0.35, 0.35))
	return e
