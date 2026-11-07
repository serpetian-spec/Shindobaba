extends Node
## Kuyruklu canavarlar yöneticisi (autoload "TailedBeasts"): inler, doğma/silinme, mühürleme,
## jinchūriki durumu, güven (bağ), zihin dünyası. Organizasyonlar için API:
##   player_jinchuriki() -> String, beast_state(id), extract_from_player(), signal beast_sealed(id, how), jinchuriki_changed(id)

signal beast_sealed(id: String, how: String)
signal jinchuriki_changed(id: String)

## inler (harita x,y). 5 arena + bölgeye uygun yerler (Shukaku çölde, Isobu gölde, Saiken bataklıkta...)
const LAIRS := {
	"shukaku": Vector2(-27000, -14000),
	"isobu": Vector2(24000, -16000),
	"son_goku": Vector2(-26000, 27000),
	"gyuki": Vector2(30000, 29000),
	"matatabi": Vector2(26500, 23500),
	"kokuo": Vector2(15900, -7100),     # açık çayır (eskiden denizin içindeydi)
	"saiken": Vector2(-10400, 5940),    # ormandan çıkarıldı, açık alan
	"chomei": Vector2(-4500, 17500),    # ormandan çıkarıldı, açık alan
	"kurama": Vector2(-9000, 33000),   # Donmuş Vadi arenası: en büyüğü için açık alan
}
const SPAWN_R := 1800.0
const DESPAWN_R := 2800.0
const MIN_LEVEL := 20

var spawned := {}        # id -> TailedBeast
var warned := {}
var tick = 0.0
var last_missions = -1
var mind: Node3D = null   # zihin dünyası sahnesi
var mind_return := Vector3.ZERO
var host_t := 900.0      # dünya olayı sayacı (gerçek sn)
var host_npcs := {}      # canavar id -> köyde duran jinchūriki karakteri

## Dinamik jinchūriki: canavarlar köylerin taşıyıcılarında ("host") ya da inlerinde ("wild") olabilir; zamanla değişir.
## Köyün geleneksel canavarları (başlangıçta çoğunlukla taşıyıcıda):
const HOME_VILLAGE := {"shukaku": "suna", "isobu": "kiri", "saiken": "kiri", "son_goku": "iwa", "kokuo": "iwa",
	"matatabi": "kumo", "gyuki": "kumo", "chomei": "taki", "kurama": "konoha"}
const HOST_GIVEN := ["Hayate", "Rinka", "Sōma", "Akane", "Kairi", "Tōya", "Mizuki", "Raiga", "Fuyu", "Jinpachi", "Sayo", "Kōen", "Nagi", "Ibuki", "Tenma", "Yura"]
const HOST_FAMILY := ["Kazahana", "Mibu", "Kurenai", "Tsuchigumo", "Hōzuki", "Yotsuki", "Sakigake", "Kamizuru", "Shirogane", "Nanase", "Hagane", "Kirigaya"]
const HOST_EVENT_T := 3600.0   # ~saatte bir olay ihtimali (jinchūriki güçlüdür; her gün ölmez, el değiştirmez)


# ------------------------------------------------------------------ profil durumu
func beasts() -> Dictionary:
	var pr = Game.profile
	if pr.is_empty():
		return {}
	if not pr.has("beasts"):
		pr["beasts"] = {}
		for id in LAIRS:
			pr["beasts"][id] = {"state": "wild", "trust": 0.0}
	# eski Raijū jinchūriki kaydı
	# eski sürümde Raijū yenilince "jinchūriki" yapıyordu: gerçek bir kuyruklu canavar yoksa kaldır
	if String(pr.get("jinchuriki", "")) == "raiju":
		pr["jinchuriki"] = ""
		pr["beasts"].erase("raiju")
	if "jinchuriki" in pr.get("skills", []) and String(pr.get("jinchuriki", "")) == "":
		pr["skills"].erase("jinchuriki")
	if not pr.get("hosts_init", false):
		pr["hosts_init"] = true
		_init_hosts(pr["beasts"])
	return pr["beasts"]


# ------------------------------------------------------------------ dinamik jinchūriki (köy taşıyıcıları, kaçaklar)
func _new_host(id: String, vid: String, rogue := false) -> Dictionary:
	var lv = randi_range(32, 55)
	return {"name": "%s %s" % [HOST_FAMILY.pick_random(), HOST_GIVEN.pick_random()], "village": vid, "rogue": rogue, "level": lv,
		"gender": ["m", "f"].pick_random()}


## Yeni ya da eski kayıt: inde duran canavarların bir kısmı köylerin taşıyıcılarına geçer (Kurama hep inde başlar — en büyük av)
func _init_hosts(bs: Dictionary) -> void:
	for id in LAIRS:
		var b: Dictionary = bs.get(id, {})
		if String(b.get("state", "wild")) != "wild" or id == "kurama" or spawned.has(id):
			continue
		if randf() < 0.55:
			b["state"] = "host"
			b["host"] = _new_host(id, HOME_VILLAGE.get(id, "kumo"))
			bs[id] = b


func host_of(id: String) -> Dictionary:
	var b: Dictionary = beasts().get(id, {})
	return b.get("host", {}) if String(b.get("state", "")) == "host" else {}


func _bname(id: String) -> String:
	return String(BeastModels.INFO[id]["name"]).split(" — ")[0]


func _vname(vid: String) -> String:
	return String(Game.village(vid).get("name", vid.capitalize()))


func _news(title: String, text: String, col := Color(1, 0.6, 0.35)) -> void:
	# ekranı doldurmasın: büyük başlık yok, kısa bir satır; tam metin haber listesinde
	Hud.msg("Haber: " + text, col.lerp(Color.WHITE, 0.3), 4.0)
	var pr = Game.profile
	if not pr.has("beast_news"):
		pr["beast_news"] = []
	pr["beast_news"].append(text)
	if pr["beast_news"].size() > 12:
		pr["beast_news"].pop_front()


## Bingo Kitabı S-rank kaçak jinchūriki isterse: köyden kaçan bir taşıyıcı (yoksa "")
func take_rogue_host() -> Dictionary:
	var ids = []
	for id in LAIRS:
		var h = host_of(id)
		if not h.is_empty() and not h.get("rogue", false):
			ids.append(id)
	if ids.is_empty():
		return {}
	var id: String = ids.pick_random()
	var h: Dictionary = host_of(id)
	h["rogue"] = true
	return {"id": id, "host": h}


## Kaçak jinchūriki yenildi: canavar bedeninden fışkırır ve yorgun düşüp diz çöker — mühürlemek için kısa fırsat
func release_from_host(id: String, at: Vector3) -> void:
	var b: Dictionary = beasts().get(id, {})
	if String(b.get("state", "")) != "host":
		return
	var h: Dictionary = b.get("host", {})
	b["state"] = "wild"
	b.erase("host")
	if spawned.has(id) and is_instance_valid(spawned[id]):
		return
	var tb = TailedBeast.new()
	tb.setup(id)
	get_tree().current_scene.add_child(tb)
	var p = at + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
	p.y = Game.ground_height(p.x, p.z)
	tb.global_position = p
	tb.home = p
	spawned[id] = tb
	FX.ring(p + Vector3.UP * 2.0, BeastModels.INFO[id]["chakra"], tb.height * 1.2, 1.0)
	FX.aura(tb, BeastModels.INFO[id]["chakra"], tb.height * 0.4, Vector3(0, tb.height * 0.4, 0), 3.0)
	if Game.world:
		Game.world.env.add_shake(1.5)
	tb.hp = tb.max_hp * TailedBeast.SUBDUE
	tb._subdue()
	Hud.banner("%s SERBEST KALDI" % _bname(id).to_upper(), "%s yenildi; canavar bedeninden fışkırıp yorgun düştü. Mühürle ya da salıver! [F]" % String(h.get("name", "Taşıyıcı")), BeastModels.INFO[id]["chakra"])


## Dünya olayları: köyler canavar yakalar, taşıyıcılar kaçar, kaçaklar avlanır, taşıyıcılar kontrolü kaybeder
func _host_events() -> void:
	var bs = beasts()
	var wild = []
	var village_h = []
	var rogue_h = []
	for id in LAIRS:
		var st = String(bs.get(id, {}).get("state", "wild"))
		if st in ["wild", "free"] and not (spawned.has(id) and is_instance_valid(spawned[id])):
			wild.append(id)
		elif st == "host":
			(rogue_h if bs[id]["host"].get("rogue", false) else village_h).append(id)
	var roll = randf()
	if roll > 0.45:
		return   # çoğu saat hiçbir şey olmaz
	roll = randf()
	if roll < 0.45 and not wild.is_empty():
		var id: String = wild.pick_random()
		var vid: String = HOME_VILLAGE.get(id, "kumo") if randf() < 0.6 else ["konoha", "suna", "kiri", "kumo", "iwa"].pick_random()
		bs[id]["state"] = "host"
		bs[id]["host"] = _new_host(id, vid)
		_news("SÖYLENTİ", "%s yakalandı! %s onu yeni jinchūriki'sine mühürledi: %s." % [_bname(id), _vname(vid), bs[id]["host"]["name"]])
	elif roll < 0.6 and not village_h.is_empty() and randf() < 0.35:
		var id: String = village_h.pick_random()
		var h: Dictionary = bs[id]["host"]
		Missions.add_rogue_jinchuriki(id, h)
		_news("KAÇAK JİNCHŪRİKİ", "%s köyünden %s kaçtı; içinde %s var. Bingo Kitabı'na girdi." % [_vname(String(h["village"])), h["name"], _bname(id)], Color(1, 0.4, 0.3))
	elif roll < 0.8 and not rogue_h.is_empty() and randf() < 0.3:
		var id: String = rogue_h.pick_random()
		var h: Dictionary = bs[id]["host"]
		if Missions.bingo_host_spawned(id):
			return
		Missions.remove_rogue_jinchuriki(id)
		bs[id]["state"] = "wild"
		bs[id].erase("host")
		_news("SÖYLENTİ", "Kaçak jinchūriki %s avcı ninjalarca öldürüldü; %s serbest kalıp inine döndü." % [h["name"], _bname(id)])
	elif not village_h.is_empty() and randf() < 0.08:   # kontrol kaybı: çok nadir
		var id: String = village_h.pick_random()
		var h: Dictionary = bs[id]["host"]
		bs[id]["state"] = "wild"
		bs[id].erase("host")
		_news("SÖYLENTİ", "%s köyünün jinchūriki'si %s canavarın kontrolünü kaybetti; %s köyden kaçıp inine döndü." % [_vname(String(h["village"])), h["name"], _bname(id)], Color(1, 0.45, 0.3))


func beast_state(id: String) -> String:
	return String(beasts().get(id, {}).get("state", "wild"))


func player_jinchuriki() -> String:
	if Game.profile.is_empty():
		return ""
	beasts()
	return String(Game.profile.get("jinchuriki", ""))


## Oyuncunun içinde taşıdığı tüm canavarlar (biri aktif: pelerin/dönüşüm onunla)
func held() -> Array:
	var pr = Game.profile
	if pr.is_empty():
		return []
	if not pr.has("beasts_held"):
		pr["beasts_held"] = []
	var a = String(pr.get("jinchuriki", ""))
	if a != "" and not a in pr["beasts_held"]:
		pr["beasts_held"].append(a)
	return pr["beasts_held"]


## Mühür kabında/parşömeninde tutulan canavarlar
func jarred() -> Array:
	var out = []
	for id in beasts():
		if String(beasts()[id].get("state", "")) == "sealed_jar":
			out.append(id)
	return out


## Taşınan canavarlardan birini aktif yap (pelerin/dönüşüm/canavar topu artık onun)
func set_active(id: String) -> void:
	if not id in held() or id == player_jinchuriki():
		return
	if Game.player and Game.player.combat and Game.player.combat.modes and Game.player.combat.modes.cloak:
		Game.player.combat.modes.cloak.deactivate()
	Game.profile["jinchuriki"] = id
	Hud.msg("Aktif canavar: %s" % _bname(id), BeastModels.INFO[id]["chakra"])
	jinchuriki_changed.emit(id)
	Game.save_game()


## Mühür kabındaki canavarı kendi içine aktar
func transfer_from_jar(id: String) -> void:
	if beast_state(id) != "sealed_jar":
		return
	var tr = float(beasts()[id].get("trust", 0.0))
	beasts()[id] = {"state": "sealed_player", "trust": tr}
	held().append(id)
	if player_jinchuriki() == "":
		Game.profile["jinchuriki"] = id
	if not "jinchuriki" in Game.profile["skills"]:
		Game.profile["skills"].append("jinchuriki")
	Sfx.play("seal", null, 0.6)
	Hud.banner("AKTARILDI", "%s mühür kabından senin içine geçti. (Tab > Kuyruklu Canavarlar: aktif olanı seç)" % _bname(id), BeastModels.INFO[id]["chakra"])
	teach_beast_arts()
	jinchuriki_changed.emit(player_jinchuriki())
	Game.save_game()


func trust(id := "") -> float:
	if id == "":
		id = player_jinchuriki()
	return float(beasts().get(id, {}).get("trust", 0.0))


func add_trust(amount: float, id := "") -> void:
	if id == "":
		id = player_jinchuriki()
	if id == "" or not beasts().has(id):
		return
	var b: Dictionary = beasts()[id]
	var before = int(b["trust"]) / 10
	b["trust"] = clampf(float(b["trust"]) + amount, 0.0, 100.0)
	if amount > 0 and int(b["trust"]) / 10 > before:
		Hud.msg("%s ile bağın güçlendi (güven %d)" % [BeastModels.INFO.get(id, {}).get("name", id).split(" — ")[0], int(b["trust"])], Color(1, 0.75, 0.4))


## Canavarın chakrasından gelen kekkei genkai doğası (Rōshi'nin lavı Son Gokū'dan, Han'ın buharı Kokuō'dan)
const BEAST_NATURE := {"son_goku": "yoton", "kokuo": "futton"}


## Canavara özgü teknikler (learn "beast:<id>"): o canavarın jinchūriki'si olunca ve seviye yetince öğrenilir
func teach_beast_arts() -> void:
	var pr = Game.profile
	if pr.is_empty():
		return
	for bid in held():
		if BEAST_NATURE.has(bid) and not Progress.has_nature(BEAST_NATURE[bid]):
			Progress.awaken_nature(BEAST_NATURE[bid])
			Hud.msg("%s chakrası bedenine karıştı: %s" % [_bname(bid), Elements.NAMES.get(BEAST_NATURE[bid], BEAST_NATURE[bid])], BeastModels.INFO.get(bid, {}).get("chakra", Color(1, 0.6, 0.3)), 4.0)
	for jid in Data.jutsu:
		var j = Data.jutsu[jid]
		if not j is Dictionary or jid in pr.get("learned", []):
			continue
		var lp = String(j.get("learn", ""))
		if not lp.begins_with("beast:") or not lp.substr(6) in held() or int(pr["level"]) < int(j.get("level", 1)):
			continue
		Progress.learn(jid, false)
		Hud.msg("%s sana öğretti: %s" % [_bname(lp.substr(6)), String(j.get("name", jid))], BeastModels.INFO.get(lp.substr(6), {}).get("chakra", Color(1, 0.6, 0.3)))


func make_jinchuriki(id: String) -> void:
	var pr = Game.profile
	# birden çok canavar taşınabilir: eskisi serbest kalmaz, yeni gelen aktif olur
	if not id in held():
		held().append(id)
	pr["jinchuriki"] = id
	beasts()[id] = {"state": "sealed_player", "trust": float(beasts().get(id, {}).get("trust", 0.0))}
	if not "jinchuriki" in pr["skills"]:
		pr["skills"].append("jinchuriki")
	teach_beast_arts()
	Hud.banner("JİNCHŪRİKİ", "%s artık içinde mühürlü. [X] chakra pelerini • [X] basılı: zihin dünyası%s" % [BeastModels.INFO[id]["name"].split(" — ")[0], "  •  Tab > Kuyruklu Canavarlar: aktif olanı seç" if held().size() > 1 else ""], BeastModels.INFO[id]["chakra"])
	jinchuriki_changed.emit(id)
	Game.save_game()


## Organizasyon (Akatsuki tarzı) canavarı söküp alırsa
func extract_from_player() -> String:
	var id = player_jinchuriki()
	if id == "":
		return ""
	beasts()[id]["state"] = "captured_org"
	held().erase(id)
	Game.profile["jinchuriki"] = held()[0] if not held().is_empty() else ""
	if held().is_empty():
		Game.profile["skills"].erase("jinchuriki")
	if Game.player and Game.player.combat and Game.player.combat.modes:
		var m = Game.player.combat.modes
		if m.cloak:
			m.cloak.deactivate()
	jinchuriki_changed.emit(String(Game.profile["jinchuriki"]))
	return id


# ------------------------------------------------------------------ doğma / silinme
func _process(dt: float) -> void:
	if Game.paused or Game.player == null or Game.world == null:
		return
	tick -= dt
	if tick > 0.0:
		return
	tick = 0.5
	host_t -= 0.5
	if host_t <= 0.0:
		host_t = HOST_EVENT_T * randf_range(0.7, 1.3)
		_host_events()
	_host_npcs()
	var pp = Game.to_map(Game.player.global_position)
	for id in LAIRS:
		var st = beast_state(id)
		var lair: Vector2 = LAIRS[id]
		var d = pp.distance_to(lair)
		if st == "wild":
			if d < SPAWN_R + 900.0 and not warned.has(id):
				warned[id] = true
				var lvl = int(Game.profile.get("level", 1))
				Hud.banner("DEVASA BİR CHAKRA", "Yakında bir Kuyruklu Canavar var: %s%s" % [BeastModels.INFO[id]["name"], "  (Güç %d+ önerilir)" % MIN_LEVEL if lvl < MIN_LEVEL else ""], Color(1, 0.4, 0.3))
			if d < SPAWN_R and not (spawned.has(id) and is_instance_valid(spawned[id])):
				_spawn(id, lair)
		# (uzaklık canavarın bulunduğu yerden: taşıyıcıdan fışkıran canavar inden uzakta olabilir)
		if spawned.has(id) and is_instance_valid(spawned[id]) and pp.distance_to(Game.to_map(spawned[id].global_position)) > DESPAWN_R and not spawned[id].aggro and not spawned[id].subdued:
			spawned[id].queue_free()
			spawned.erase(id)
	# görev tamamlandıkça canavarla bağ güçlenir
	var md: Dictionary = Game.profile.get("missions_done", {})
	var tot = 0
	for k in md:
		tot += int(md[k])
	if last_missions >= 0 and tot > last_missions:
		add_trust(2.0 * (tot - last_missions))
	last_missions = tot


func _spawn(id: String, lair: Vector2) -> void:
	var b = TailedBeast.new()
	b.setup(id)
	var p = Game.from_map(lair)
	p.y = Game.ground_height(p.x, p.z)
	get_tree().current_scene.add_child(b)
	b.global_position = p
	b.home = p
	spawned[id] = b


## Mangekyō ile bağlı canavarı müttefik olarak çağır (40 sn); birden çoksa sırayla
var _ms_idx := 0
func summon_ms_beast(c: Node3D) -> bool:
	var lst: Array = Game.profile.get("beast_ms", [])
	if lst.is_empty():
		return false
	var id = String(lst[_ms_idx % lst.size()])
	_ms_idx += 1
	for n in get_tree().get_nodes_in_group("fighters"):
		if n is TailedBeast and n.ally_owner == c:
			n.ally_life = 0.0   # eskisi geri döner
	var b = TailedBeast.new()
	b.setup(id)
	var p = Missions.open_ground(c.global_position + c.face_dir() * 18.0, 20.0)
	get_tree().current_scene.add_child(b)
	b.global_position = p
	b.home = p
	b.make_ally(c, 40.0)
	b.rig.scale = Vector3.ONE * 0.05
	b.rig.create_tween().tween_property(b.rig, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_BACK)
	FX.smoke_puff(p + Vector3.UP * b.height * 0.5, b.height * 0.5, 60)
	if Game.world:
		Game.world.env.add_shake(1.2)
	Sfx.play("roar", p, 0.7)
	Hud.banner("BİJŪ KUCHİYOSE", "%s Sharingan'ın emrinde! (40 sn)" % BeastModels.INFO[id]["name"].split(" — ")[0], BeastModels.INFO[id]["chakra"])
	return true


## Dünya haritası için: canavarların bilinen yerleri
func lair_markers() -> Array:
	var out = []
	for id in LAIRS:
		if beast_state(id) == "wild":
			out.append({"id": id, "name": BeastModels.INFO[id]["name"], "x": LAIRS[id].x, "y": LAIRS[id].y})
	return out


# ------------------------------------------------------------------ ortak: Kuyruklu Canavar Topu
func fire_ball(owner_f: Node3D, from: Vector3, dir: Vector3, size: float, col: Color, dmg: float, spd := 70.0) -> Projectile:
	var pr = Projectile.new()
	pr.shooter = owner_f
	pr.vel = dir.normalized() * spd
	pr.radius = maxf(1.2, size)
	pr.life = 5.0
	pr.blockable = false
	pr.info = {"dmg": dmg, "knock": 40.0, "launch": 14.0, "kind": "heavy", "hitstop": 0.15}
	# anime Bijūdama (BijudamaFX): koyu girdaplı top, atışta şok halkaları + iz, çarpınca parlama + kubbe + dev zemin halkası
	var vis = BijudamaFX.ball(maxf(1.0, size * 2.0))
	pr.add_child(vis)
	var boom = maxf(5.0, size * 6.0)
	pr.on_hit = func(pos: Vector3, _t: Node3D) -> void:
		BijudamaFX.explode(pos, boom)
		Combat.hit_sphere(owner_f, pos, boom, {"dmg": dmg * 0.6, "knock": 44.0, "launch": 16.0, "kind": "heavy"}, pr.hit_list)
	get_tree().current_scene.add_child(pr)
	pr.global_position = from
	BijudamaFX.launch(from, dir.normalized(), maxf(1.0, size * 2.0), pr)
	Sfx.play("roar", from, 0.7)
	return pr


# ------------------------------------------------------------------ etkileşimler (Progress.interact yönlendirir)
func interact(it: Dictionary) -> void:
	match String(it.get("kind", "")):
		"beast_seal":
			_seal_dialog(it.get("beast"))
		"beast_talk":
			_mind_dialog()
		"mind_exit":
			exit_mindscape()


func _seal_dialog(b) -> void:
	if b == null or not is_instance_valid(b):
		return
	var pl = Game.player
	var knows_seal = false
	for j in Game.profile.get("learned", []):
		if "fuin" in String(j) or "fuuin" in String(j) or "seal" in String(j):
			knows_seal = true
			break
	var cost = 40.0 if knows_seal else 70.0
	if pl.chakra < cost:
		Hud.msg("Mühürlemek için %d chakra gerekli! (C basılı: chakra topla)" % int(cost), Color(0.6, 0.8, 1))
		return
	var nm = String(b.display_name).split(" — ")[0]
	var opts = []
	if true:
		opts.append({"label": "İçime mühürle — Jinchūriki ol", "tip": "Canavar seninle yaşar: chakra pelerini, dönüşüm, Kuyruklu Canavar Topu. Güven düşükse kontrolü kaybedebilirsin.", "cb": func():
			pl.chakra -= cost
			_finish_seal(b, "player")})
	opts.append({"label": "Mühür kabına hapset", "tip": "Büyük ödül; canavar kabda saklanır, dilediğinde Tab > Kuyruklu Canavarlar'dan içine aktarabilirsin.", "cb": func():
		pl.chakra -= cost
		_finish_seal(b, "jar")})
	if Progress.has_eye("mangekyo"):
		opts.append({"label": "Sharingan ile boyun eğdir (Mangekyō)", "tip": "Canavar iradeni taşır: sonra jutsu yuvasından «Bijū Kuchiyose» ile savaşa çağırırsın (gözler açıkken).", "cb": func():
			pl.chakra -= cost
			_finish_seal(b, "ms")})
	opts.append({"label": "Serbest bırak", "tip": "Canavar sana saygı duyar; ileride bağ kurmak kolaylaşır.", "cb": func(): _finish_seal(b, "free")})
	Hud.dialog("%s — Mühürleme" % nm, "Canavar diz çökmüş, chakrası dağılıyor. Ne yapacaksın?", opts)


func _finish_seal(b, how: String) -> void:
	if b == null or not is_instance_valid(b):
		return
	var id: String = b.id
	var pr = Game.profile
	Sfx.play("seal", Game.player.global_position, 0.6)
	match how:
		"player":
			b.sealed_away(Game.player)
			make_jinchuriki(id)
		"jar":
			b.sealed_away(null)
			beasts()[id]["state"] = "sealed_jar"
			Progress.add_xp(4000 + 800 * int(BeastModels.INFO[id]["num"]))
			Progress.add_ryo(20000 + 5000 * int(BeastModels.INFO[id]["num"]))
			var lg = Gear.random_legendary()
			if lg != "":
				Gear.grant(pr, lg)
				Hud.msg("Efsanevi ödül: %s" % Gear.item(lg).get("name", lg), Color(1, 0.8, 0.3))
			Hud.banner("MÜHÜRLENDİ", "%s mühür kabına hapsedildi. İstersen sonra kendi içine aktarabilirsin: Tab > Kuyruklu Canavarlar" % BeastModels.INFO[id]["name"], Color(1, 0.8, 0.4))
		"ms":
			b.sealed_away(null)
			beasts()[id]["state"] = "ms_bound"
			if not pr.has("beast_ms"):
				pr["beast_ms"] = []
			if not id in pr["beast_ms"]:
				pr["beast_ms"].append(id)
			Hud.banner("BOYUN EĞDİ", "%s Mangekyō'nun iradesine bağlandı. Jutsular (K) > «Bijū Kuchiyose» yuvaya koy; gözler açıkken çağır." % BeastModels.INFO[id]["name"].split(" — ")[0], Color(0.95, 0.15, 0.15))
		"free":
			beasts()[id]["state"] = "free"
			beasts()[id]["trust"] = 30.0
			Progress.add_xp(2500)
			b.subdued = false
			b._end_fight()
			b.dead = true
			var tw = b.create_tween()
			tw.tween_property(b, "global_position", b.global_position + Vector3.DOWN * b.height * 1.2, 4.0)
			tw.tween_callback(b.queue_free)
			Interact.items.erase(b.seal_item)
			Hud.banner("SERBEST", "%s sana uzun uzun baktı ve toprağa gömülüp kayboldu." % BeastModels.INFO[id]["name"].split(" — ")[0], Color(0.8, 0.9, 1))
	beast_sealed.emit(id, how)
	spawned.erase(id)
	Game.save_game()


# ------------------------------------------------------------------ zihin dünyası (kafes, kanalizasyon)
func enter_mindscape() -> void:
	var id = player_jinchuriki()
	if id == "" or mind != null:
		return
	var pl = Game.player
	mind_return = pl.global_position
	mind = Mindscape.new()
	mind.beast_id = id
	mind.position = Vector3(0, 7000, 0)
	get_tree().current_scene.add_child(mind)
	Interact.add(mind.talk_item)
	Interact.add(mind.exit_item)
	_fade(func():
		pl.respawn(mind.spawn_point())
		_rain(false))
	Hud.banner("ZİHİN DÜNYASI", "Kafese yaklaş ve [F] ile konuş. Çıkmak için arkadaki ışığa git.", Color(0.6, 0.8, 0.9))


func exit_mindscape() -> void:
	if mind == null:
		return
	var pl = Game.player
	Interact.items.erase(mind.talk_item)
	Interact.items.erase(mind.exit_item)
	_fade(func():
		pl.respawn(mind_return)
		_rain(true)
		if mind:
			mind.queue_free()
		mind = null)


func _rain(on: bool) -> void:
	if Game.world and Game.world.env and Game.world.env.rain:
		Game.world.env.rain.visible = on


func _fade(mid: Callable) -> void:
	var cl = CanvasLayer.new()
	cl.layer = 90
	add_child(cl)
	var r = ColorRect.new()
	r.color = Color(0, 0, 0, 0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(r)
	var tw = r.create_tween()
	tw.tween_property(r, "color:a", 1.0, 0.45)
	tw.tween_callback(mid)
	tw.tween_property(r, "color:a", 0.0, 0.6)
	tw.tween_callback(cl.queue_free)


const LINES := {
	"kurama": ["Kafesin önünde ne arıyorsun, velet?", "Gücümü istiyorsan önce bana kim olduğunu göster.", "İnsanların nefreti... hepsini hissedebiliyorum."],
	"shukaku": ["Uyu da kontrolü bana bırak, hehehe!", "Kum her şeyi örter... seni de.", "Beni rahatsız etmesen iyi edersin!"],
	"matatabi": ["Alevlerim seni yakmaz, eğer bana saygı duyarsan.", "Sakin ol. Kediler sabırlıdır."],
	"isobu": ["...Ben... kalabalıktan hoşlanmam.", "Su sakin olduğunda derinlik görünür."],
	"son_goku": ["Ben Su Bilgesi Son Gokū'yum! Bana adımla seslen!", "Lavım kadar sıcak bir yüreğin var mı bakalım?"],
	"kokuo": ["Buharım öfkemi değil, gücümü taşır.", "Sessizce gözlemliyorum seni."],
	"saiken": ["Hey hey, kavga etmeyelim, olur mu?", "Sümüğüm zararsız... düşmanlarına değil ama!"],
	"chomei": ["Kanatlarım seni uçurur, şansın varsa!", "Bugün şanslı bir gün, değil mi?"],
	"gyuki": ["Yo! Ritmi hisset, birlikte vuralım!", "Bir canavar ve bir ninja: iyi bir ikili oluruz."],
	"raiju": ["Gökgürültüsü... içinde kükrüyor."],
}


func _mind_dialog() -> void:
	var id = player_jinchuriki()
	var b: Dictionary = beasts().get(id, {})
	var tr = float(b.get("trust", 0.0))
	var nm = BeastModels.INFO.get(id, {}).get("name", id).split(" — ")[0]
	var slot = int(Time.get_unix_time_from_system() / 120.0)  # gerçek 2 dakikada bir konuşma bağı +10 artırır
	var opts = []
	opts.append({"label": "Konuş", "tip": "Her konuşma güveni +10 artırır (2 dakikada bir)", "cb": func():
		if int(b.get("last_talk", -1)) != slot:
			b["last_talk"] = slot
			add_trust(10.0, id)
		else:
			Hud.msg("%s şimdilik konuşmak istemiyor (biraz sonra tekrar dene)" % nm, Color(0.9, 0.7, 0.5))
		Hud.dialog(nm, LINES.get(id, LINES["kurama"]).pick_random() + "\n\n(Güven: %d/100)" % int(trust(id)), [])})
	opts.append({"label": "Gücünü iste", "tip": "Güven 30+: chakra yenilenir. Düşük güvende canavar öfkelenir.", "cb": func():
		if trust(id) >= 30.0:
			Game.player.chakra = Game.player.max_chakra
			Game.player.hp = Game.player.max_hp
			Hud.dialog(nm, "Al bakalım... ama bunu boşa harcama.", [])
		else:
			add_trust(-3.0, id)
			Hud.dialog(nm, "GRRRR! Bana emir veremezsin!", [])})
	if tr >= 80.0 and not b.get("unbound", false):
		opts.append({"label": "Mührü birlikte gevşet (tam kontrol)", "cb": func():
			b["unbound"] = true
			Hud.banner("TAM UYUM", "%s ile uyum sağlandı: tam dönüşüm artık kontrollü." % nm, Color(1, 0.7, 0.3))})
	opts.append({"label": "Geri dön", "cb": func(): exit_mindscape()})
	Hud.dialog(nm, "Kafesin ardından devasa gözler sana bakıyor. (Güven: %d/100)" % int(tr), opts)


## Köydeki jinchūriki'ler köylerinde yaşar: köye yaklaşınca antrenman alanının yanında durur (adı + canavarı başında).
## Gidip bulunabilir; liste dünya haritasında (Menus) — "kim nerede".
func _host_npcs() -> void:
	var pp: Vector3 = Game.player.global_position
	for id in LAIRS:
		var h: Dictionary = host_of(id)
		var npc = host_npcs.get(id)
		var vid = String(h.get("village", ""))
		var ok = not h.is_empty() and not h.get("rogue", false) and vid != ""
		var v = Game.village(vid) if ok else {}
		var near = ok and not v.is_empty() and Game.to_map(pp).distance_to(Vector2(float(v["x"]), float(v["y"]))) < float(v.get("r", 300)) * 1.2
		if near and (npc == null or not is_instance_valid(npc)):
			var at = Exams.find_point(["training"], vid)
			var off = Vector3(cos(LAIRS.keys().find(id) * 0.8), 0, sin(LAIRS.keys().find(id) * 0.8)) * 9.0
			at = Missions.open_ground(at + off, 12.0)
			var vg = Villager.new()
			vg.role = "spar"
			vg.display_override = "%s (%s jinchūriki)" % [String(h["name"]), _bname(id)]
			vg.lines_override = ["İçimdeki %s'i kontrol etmek ömür boyu süren bir antrenman." % _bname(id), "Köyüm beni silah olarak görüyor... ama ben onu korumayı seçtim.",
				"Bana bakan gözlerden korku okuyorum. Alıştım."]
			vg.look_extra = {"gender": String(h.get("gender", "m")), "age": "adult"}
			get_tree().current_scene.add_child(vg)
			vg.global_position = at
			vg.home = at
			vg.goal = at
			vg.set_meta("jinchuriki_of", id)
			host_npcs[id] = vg
		elif not near and npc != null and is_instance_valid(npc):
			npc.queue_free()
			host_npcs.erase(id)


## Köydeki jinchūriki'ye saldırı: köylü NPC gerçek jinchūriki düşmanına döner (canavarının teknikleri, pelerin aşamaları —
## Bingo kaçak jinchūriki'siyle aynı kurulum). Yenilince release_from_host: canavar fışkırır, mühürle ya da salıver [F].
func attack_host(vg: Node3D) -> void:
	if vg == null or not is_instance_valid(vg):
		return
	var id = String(vg.get_meta("jinchuriki_of", ""))
	var h: Dictionary = host_of(id)
	if id == "" or h.is_empty():
		return
	var at = vg.global_position
	var vid = String(h.get("village", "konoha"))
	var a = Enemy.archetype("jinchuriki", 0)
	var lv = int(h.get("level", 90 + LAIRS.keys().find(id) * 8))
	Stats.npc_ninja(a, lv, 1.6)
	a["name"] = "%s (%s jinchūriki)" % [String(h.get("name", "Jinchūriki")), _bname(id)]
	a["beast"] = id
	a["respawn"] = false
	a["no_clan"] = true
	a["skill"] = clampf(0.25 + lv * 0.005, 0.3, 0.85)
	a["look"]["gender"] = String(h.get("gender", "m"))
	a["look"]["village"] = vid
	var e = Enemy.new()
	e.setup(a)
	e.adopt_model(vg)
	get_tree().current_scene.add_child(e)
	e.global_position = at
	e.home = at
	e.team = "enemy"
	e.target = Game.player
	e.state = "chase"
	e.set_meta("host_beast", id)
	host_npcs.erase(id)
	vg.queue_free()
	Hud.banner("JINCHŪRIKI", "%s içindeki %s'in gücünü serbest bırakıyor!" % [String(h.get("name", "")), _bname(id)], BeastModels.INFO.get(id, {}).get("chakra", Color(1, 0.6, 0.3)))
	if not Orgs.is_rogue():
		Crime.commit(Crime.ATTACK, "Köyün jinchūriki'sine saldırdın", at, vid)


## Dünya haritası listesi: [ad, canavar, köy adı, köy id] (yalnız köyünde yaşayan taşıyıcılar)
func host_list() -> Array:
	var out = []
	for id in LAIRS:
		var h: Dictionary = host_of(id)
		if h.is_empty() or h.get("rogue", false):
			continue
		out.append([String(h["name"]), _bname(id), _vname(String(h["village"])), String(h["village"])])
	return out
