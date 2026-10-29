extends Node
## Örgütler ve dünya olayları (autoload "Orgs"):
##  ANBU ve Kök (Ne) özel görevleri, kaçak ninja olmak (alın bandı çizik, av-ninjaları peşinde, Bingo Kitabı'nda kendi kaydın),
##  Akatsuki (özgün üyeler) — geç oyunda kuyruklu canavar avı (kuyruklu canavar ajanı için sinyaller/API),
##  dünya olayları: sınır savaşı, Chūnin finalinde istila (dev yılanlar), Büyük Ninja Savaşı.

signal beast_hunt_started()
signal jinchuriki_targeted(beast_id: int, where: Vector3)
signal jinchuriki_captured(beast_id: int)
signal war_started()
signal war_ended(won: bool)
signal player_defected()
signal player_pardoned()

## Akatsuki: iki kişilik takımlar (özgün üyeler; kanon karakter yok)
const AKATSUKI := [
	{"name": "Kuroshio Ren", "alias": "Derinlerin Dişi", "v": "kiri", "el": "suiton", "j": ["suiton_suiryuudan", "suiton_suikoudan"], "weapon": "nodachi", "hair": "dağınık", "hp": 3200.0, "pair": 0},
	{"name": "Hibana Seiji", "alias": "Kül Yağmuru", "v": "iwa", "el": "katon", "j": ["katon_goukakyuu", "katon_housenka"], "weapon": "", "hair": "uzun", "hp": 2900.0, "pair": 0},
	{"name": "Raikō Tsubasa", "alias": "Mavi Şimşek", "v": "kumo", "el": "raiton", "j": ["raiton_chidori", "raiton_nagashi"], "weapon": "katana", "hair": "diken", "hp": 3000.0, "pair": 1},
	{"name": "Sunagami Ezo", "alias": "Kum Kuklacısı", "v": "suna", "el": "fuuton", "j": ["fuuton_daitoppa", "fuuton_shinkuu"], "weapon": "", "hair": "kısa", "hp": 2800.0, "pair": 1},
	{"name": "Mukuro Shinya", "alias": "Mezar Bekçisi", "v": "konoha", "el": "doton", "j": ["doton_doryuheki", "doton_doryuusou"], "weapon": "kusarigama", "hair": "kase", "hp": 3400.0, "pair": 2},
	{"name": "Amane Kiyoha", "alias": "Kağıt Melek", "v": "ame", "el": "fuuton", "j": ["fuuton_shinkuu"], "weapon": "", "hair": "uzun", "hp": 2700.0, "pair": 2, "f": true},
	{"name": "Gekkō Saizō", "alias": "Ay Gölgesi", "v": "oto", "el": "katon", "j": ["katon_goukakyuu"], "weapon": "katana", "hair": "uzun", "hp": 3100.0, "pair": 3},
	{"name": "Tsuchigumo Bō", "alias": "Bin Yaralı", "v": "taki", "el": "doton", "j": ["doton_doryuusou"], "weapon": "savas_cekici", "hair": "kısa", "hp": 3800.0, "pair": 3},
	{"name": "Yoake no Kami", "alias": "Örgütün Lideri", "v": "ame", "el": "suiton", "j": ["suiton_suiryuudan", "raiton_nagashi", "fuuton_daitoppa"], "weapon": "", "hair": "diken", "hp": 6500.0, "pair": 4, "leader": true},
]

## Kaçak rütbeleri: şöhret (infamy) eşiği, ad, alınabilecek en yüksek iş rütbesi
const ROGUE_RANKS := [[0, "Firari", "C"], [300, "Kiralık Kılıç", "B"], [900, "Kara Listede", "A"], [2000, "Aranan Gölge", "S"], [4000, "Efsanevi Kaçak", "S"]]
## Kaçak bu büyük gizli köylerde düşmandır (muhafızlar saldırır); küçük kasabalarda saklanabilir
const ROGUE_BANNED := ["konoha", "suna", "kiri", "kumo", "iwa", "ame"]

var _hideout_node: Node3D = null
var _ban_msg_t := 0.0
var _raid := {}
var _t := 0.0
var _hunt_t := 0.0
var _hunter_t := 0.0
var _spawned: Array = []
var _invasion := {}


func p() -> Dictionary:
	return Game.profile


func state() -> Dictionary:
	if not p().has("orgs") or not p()["orgs"] is Dictionary:
		p()["orgs"] = {"hunt": false, "captured": [], "events": {}, "war": "none", "bounty": 0, "summit": false}
	return p()["orgs"]


func flags() -> Dictionary:
	return Exams.flags()


func is_akatsuki() -> bool:
	return bool(flags().get("akatsuki_member", false))


## Bingo Kitabı: Akatsuki üyeleri (izlenemez; kızıl bulutlar yollarda rastgele belirir)
func akatsuki_bingo_entries() -> Array:
	var out = []
	var dead: Array = state().get("akatsuki_dead", [])
	var i = 0
	for m in AKATSUKI:
		i += 1
		var lk = akatsuki_look(m)
		out.append({"id": -100 - i, "self": true, "org": true, "name": m["name"], "alias": m["alias"], "village": m["v"],
			"village_name": "Akatsuki (eski %s)" % String(Game.village(m["v"]).get("name", m["v"])), "rank": "S",
			"bounty": 90000 if m.get("leader", false) else 45000 + int(m["hp"]) * 5, "crimes": ["Akatsuki üyesi", "Kuyruklu canavar avı", "Köy baskınları"],
			"element": m["el"], "status": "dead" if String(m["name"]) in dead else "alive", "tracked": false, "level": 70 if m.get("leader", false) else 55,
			"look": lk, "region": "Bilinmiyor — ikili gezerler", "area": [0, 0], "hide": [0, 0], "known": 0.0})
	return out


func is_rogue() -> bool:
	return not Game.profile.is_empty() and bool(flags().get("rogue", false))


# ================================================================== Akatsuki API (kuyruklu canavar ajanı için)
func members() -> Array:
	return AKATSUKI


func is_hunting() -> bool:
	return bool(state().get("hunt", false))


func captured() -> Array:
	return state().get("captured", [])


## Kuyruklu canavar avını başlat (oyun ilerleyişi ya da kuyruklu canavar sistemi çağırır)
func start_beast_hunt() -> void:
	if is_hunting():
		return
	state()["hunt"] = true
	beast_hunt_started.emit()
	Hud.banner("AKATSUKİ HAREKETE GEÇTİ", "Kızıl bulutlu pelerinliler jinchūriki avına çıktı", Color(0.85, 0.15, 0.15))
	Hud.dialog(Progress.home_info()["kage"], "İstihbarat doğrulandı: Akatsuki adlı kaçak ninja örgütü kuyruklu canavarları topluyor. Dokuz S-rank kaçak, ikişerli takımlar halinde. Yollarda dikkatli ol; karşılaşırsan tek başına savaşma!", [])


## Bir jinchūriki hedef alındığında (kuyruklu canavar sistemi çağırır) — çifti yakına çıkarır
func target_jinchuriki(beast_id: int, where: Vector3) -> Array:
	jinchuriki_targeted.emit(beast_id, where)
	return spawn_pair(randi() % 4, where + Vector3(40, 0, 0))


func report_captured(beast_id: int) -> void:
	if not beast_id in captured():
		state()["captured"].append(beast_id)
	jinchuriki_captured.emit(beast_id)
	Hud.banner("JİNCHŪRİKİ YAKALANDI", "%d kuyruklu Akatsuki'nin elinde (%d/9)" % [beast_id, captured().size()], Color(0.85, 0.15, 0.15))


func akatsuki_look(m: Dictionary) -> Dictionary:
	# dik yakalı, bileğe inen siyah pelerin: beyaz kenarlı kızıl bulutlar
	var lk = Outfits.roll("akatsuki", m["v"])
	lk.merge({"gender": "f" if m.get("f", false) else "m", "hair_style": m["hair"], "hair": Color(0.1, 0.08, 0.1) if randf() < 0.5 else Color(0.55, 0.15, 0.15),
		"band": Color(0.2, 0.2, 0.25), "band_style": "slashed", "village": m["v"], "face_mark": "yok", "age": "adult", "weapon_r": m["weapon"] if m["weapon"] != "" else null}, true)
	return lk


func spawn_member(m: Dictionary, at: Vector3) -> Enemy:
	var e = Enemy.new()
	var a = Enemy.archetype("rogue", 0)
	var lv = maxi(40, int(p().get("level", 1)) + 5)
	a["name"] = "%s «%s»" % [m["name"], m["alias"]]
	a["hp"] = float(m["hp"])
	a["level"] = lv
	a["power"] = 3.0 if not m.get("leader", false) else 3.8
	a["element"] = m["el"]
	a["jutsu"] = m["j"]
	a["guard"] = 0.5
	a["sub"] = 0.4
	a["aggr"] = 0.85
	a["xp"] = lv * 40
	a["ryo"] = lv * 60
	a["respawn"] = false
	a["look"] = akatsuki_look(m)
	e.setup(a)
	e.set_meta("akatsuki", m["name"])
	get_tree().current_scene.add_child(e)
	at.y = Game.ground_height(at.x, at.z)
	e.global_position = at
	e.home = at
	_spawned.append(e)
	return e


func spawn_pair(pair: int, at: Vector3) -> Array:
	var out = []
	for m in AKATSUKI:
		if int(m["pair"]) == pair:
			out.append(spawn_member(m, at + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))))
	return out


# ================================================================== ANBU / Kök
func anbu_hq() -> void:
	var opts = []
	for m in anbu_missions():
		opts.append({"label": "[%s] %s" % [m["rank"], m["title"]], "tip": m["brief"], "cb": func(): Missions.accept(m)})
	if flags().get("root_member", false):
		opts.append({"label": "◼ Kök'ün gölgesindeki görevler", "cb": root_board})
	Hud.dialog("ANBU Karargâhı", "Maskeni tak. Bugünün özel görevleri:", opts)


func anbu_missions() -> Array:
	var vid = Progress.home()
	var out = []
	var rogue_camp = Missions._spot(vid, 600, 1200)
	out.append({"title": "ANBU: Kaçak Takibi", "rank": "A", "village": vid, "giver": "ANBU Komutanı", "brief": "Köyden kaçan bir chūnin gizli belgelerle sınıra ilerliyor. Yakala ya da etkisiz bırak.",
		"steps": [{"kind": "goto", "at": Missions._near_spot(rogue_camp, 120, 160), "r": 12.0, "name": "Son Görülen Yer", "text": "Kaçağın son görüldüğü yere git."},
			{"kind": "kill", "at": rogue_camp, "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kaçak Chūnin Hyōma", "hp": 1500.0, "level": 30, "power": 2.3, "flee": true}, "text": "Kaçağı ve yardakçılarını yakala."}]})
	var spy = Missions._spot(vid, 300, 800)
	out.append({"title": "ANBU: Casus Ağı", "rank": "S", "village": vid, "giver": "ANBU Komutanı", "brief": "Başka bir köyün casusları Kage'ye suikast planlıyor. Kampa gece sız, planı ele geçir, liderlerini sustur.",
		"steps": [{"kind": "goto", "at": Missions._near_spot(spy, 80, 100), "r": 10.0, "night": true, "name": "Casus Kampı", "text": "Gece kampın yakınına git."},
			{"kind": "stealth", "at": spy, "enemy": ["kumo", "iwa", "kiri", "suna"].pick_random(), "n": 5, "goal": "Suikast Planı", "text": "Planı fark edilmeden al [F]."},
			{"kind": "kill", "at": Missions._near_spot(spy, 120, 200), "enemy": "rogue", "n": 3, "boss": {"name": "Casus Şefi Kagerō", "hp": 2400.0, "level": 36, "power": 2.6}, "text": "Casus şefini sustur."}]})
	var bd = Missions._spot(vid, 400, 900)
	out.append({"title": "ANBU: Kage Muhafızlığı", "rank": "A", "village": vid, "giver": "ANBU Komutanı", "brief": "Kage sınırdaki bir görüşmeye gidiyor. Pusuya düşürülmeden geri getir.",
		"steps": [{"kind": "defend", "at": bd, "enemy": "rogue", "waves": [4, 4, 5], "text": "Görüşme yerini pusulara karşı koru."},
			{"kind": "goto", "at": Missions._inside(vid, 0.0, 0.25), "r": 20.0, "name": "Kage Kulesi", "text": "Köye dön."}]})
	return out


func root_board() -> void:
	var vid = Progress.home()
	var target = Missions._npc("hedef", "Muhalif Konsey Üyesi Sanada", "vip")
	var spot = Missions._inside(vid, 0.3, 0.6)
	var m = {"title": "Kök: Sessiz Emir", "rank": "S", "village": vid, "giver": "Kök", "brief": "Köyün içinde savaşa karşı çıkan bir konsey üyesi var. Kök onun 'ortadan kaybolmasını' istiyor. Ama gerçekten hain mi?",
		"steps": [{"kind": "talk", "at": spot, "npc": target, "text": "Hedefle gizlice konuş.", "say": "Sen... Kök'ten misin? Ben sadece barış istiyorum. Kök'ün gölgedeki yöntemleri köyü zehirliyor... (Yaşlı adam titreyerek sana bakıyor.)",
			"choices": [{"label": "Emri uygula", "ok": true, "vote": 0, "reply": "...Gölgeler sessizdir. Görev tamamlandı. Bu yükü taşıyacaksın."},
				{"label": "Onu köyden kaçır, Kök'e öldü de", "ok": true, "vote": 1, "reply": "Teşekkür ederim... Asla unutmayacağım. (Kök şüphelenebilir.)"},
				{"label": "Kage'ye götür, Kök'ü ifşa et", "ok": true, "vote": 2, "reply": "Gerçek ortaya çıkacak. (Kök senden intikam isteyecek.)"}]},
			{"kind": "goto", "at": Missions._inside(vid, 0.0, 0.2), "r": 16.0, "name": "Kök Karargâhı", "text": "Rapor ver."}], "hook": "Orgs.root_done"}
	Hud.dialog("Kök", "Görev kâğıdı yok. Sadece fısıltı: 'Köy için.'", [{"label": "Görevi al", "cb": func(): Missions.accept(m)}])


func root_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	var v = int(m.get("flags", {}).get("votes", 0))
	match v:
		0:
			Progress.add_ryo(3000)
			Missions._rep(Progress.home(), -10)
			Hud.msg("Kök ödülünü bıraktı. Vicdanın ağırlaştı (−10 itibar).", Color(0.7, 0.7, 0.8))
		1:
			Missions._rep(Progress.home(), 10)
			Hud.msg("Bir hayat kurtardın. Kök henüz bir şey sezmedi.", Color(0.7, 0.9, 0.8))
		2:
			flags()["root_member"] = false
			Missions._rep(Progress.home(), 40)
			Hud.banner("KÖK İFŞA EDİLDİ", "Kage gizli birimi dağıttı (+40 itibar). Kök'ün kalıntıları sana düşman.", Color(0.9, 0.8, 0.4))


# ================================================================== kaçak ninja (köyü terk etmek)
func defect_prompt() -> void:
	if is_rogue():
		pardon_prompt()
		return
	Hud.dialog("Köy Kapısı", "Alın koruyucunun sembolünü çizip köyü terk etmek üzeresin. Bundan sonra kaçak ninja olarak anılacaksın: av-ninjaları peşine düşer, köyünde düşman sayılırsın ve adın Bingo Kitabı'na yazılır. Emin misin?", [
		{"label": "Sembolü çiz ve köyü terk et", "cb": defect},
		{"label": "Hayır, köyüme sadığım", "cb": func(): pass}])


func defect() -> void:
	var f = flags()
	f["rogue"] = true
	f["rogue_from"] = Progress.home()
	state()["bounty"] = 5000 + int(p()["level"]) * 400
	Missions._rep(Progress.home(), -200)
	Gear.apply_look(p())
	if Game.player:
		Game.player.rebuild_model()
	f["infamy"] = 0
	f.erase("hideout")
	player_defected.emit()
	var hp = hideout_pos()
	Hud.banner("KAÇAK NİNJA", "Alın koruyucundaki sembol artık bir çizik. Av-ninjaları peşinde. Gizli köylere giremezsin; sığınağın: %s" % Game.region_name(hp), Color(0.85, 0.2, 0.2))
	Game.profile["waypoint"] = [hp.x, hp.y, hp.z, "Kaçak Sığınağı"]
	Game.profile["track"] = "waypoint"
	Sfx.play("roar", null, 0.6, 0.5)
	Game.save_game()


func pardon_prompt() -> void:
	Hud.dialog("Kapı Nöbetçisi", "Dur! Sen kaçak %s'sin! ...Ama gözlerinde pişmanlık var. Kage seni ancak köye büyük bir hizmetle affeder: Akatsuki'nin ya da bir S-rank kaçağın başını getir." % p()["name"], [
		{"label": "Af için görevi kabul et", "cb": func(): Missions.accept(_pardon_mission())},
		{"label": "Uzaklaş", "cb": func(): pass}])


func _pardon_mission() -> Dictionary:
	var vid = String(flags().get("rogue_from", Progress.home()))
	var camp = Missions._spot(vid, 900, 1600)
	return {"title": "Kefaret", "rank": "S", "village": vid, "giver": "Kapı Nöbetçisi", "hook": "Orgs.pardon_done",
		"brief": "Köye dönmenin tek yolu kanıtla: köyün en çok aradığı kaçağı yen.",
		"steps": [{"kind": "kill", "at": camp, "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Aranan Kaçak Shinra", "hp": 3000.0, "level": maxi(30, int(p()["level"])), "power": 2.8, "flee": true}, "text": "S-rank kaçağı yen."},
			{"kind": "goto", "at": Missions._inside(vid, 0.0, 0.25), "r": 20.0, "name": "Kage Kulesi", "text": "Kanıtla köye dön."}]}


func pardon_done(_m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	var f = flags()
	f["rogue"] = false
	f.erase("hideout")
	state()["bounty"] = 0
	Game.profile["rep"][String(f.get("rogue_from", Progress.home()))] = 0
	Gear.apply_look(p())
	if Game.player:
		Game.player.rebuild_model()
	player_pardoned.emit()
	Hud.banner("AFFEDİLDİN", "Köyüne yeniden hoş geldin. İtibarın sıfırdan başlıyor.", Color(0.6, 1, 0.7))


## Bingo Kitabı'nda kendi kaydın (kaçaksan)
func own_bingo_entry() -> Dictionary:
	if not is_rogue():
		return {}
	var pr = p()
	var L: Dictionary = (pr.get("look", {}) as Dictionary).duplicate(true)
	var vid = String(flags().get("rogue_from", Progress.home()))
	return {"id": -1, "self": true, "name": pr["name"], "alias": "Kaçak " + String(Game.village(vid).get("name", vid)), "village": vid,
		"village_name": Game.village(vid).get("name", vid), "rank": "S" if int(pr["rank"]) >= 3 else ("A" if int(pr["rank"]) >= 2 else "B"),
		"bounty": int(state().get("bounty", 5000)), "crimes": ["Köyünü terk etti", "Av-ninjalarına direndi (%d)" % int(flags().get("hunters_beaten", 0))],
		"element": (pr["elements"] as Array)[0], "status": "alive", "tracked": false, "level": int(pr["level"]), "look": L,
		"region": Game.region_name(Game.player.global_position) if Game.player else "", "area": [0, 0], "hide": [0, 0], "known": 0.0}


# ------------------------------------------------------------------ kaçak hayatı: sığınak, rütbe, işler, köy yasağı
## Kaçak sığınağı: terk edilen köyden uzak (1.5-3 km), karada sabit bir nokta (dünya yeri yoksa açık arazi)
func hideout_pos() -> Vector3:
	var f = flags()
	if not f.has("hideout"):
		var vid = String(f.get("rogue_from", Progress.home()))
		var v = Game.village(vid)
		var c = [float(v.get("x", 0)), float(v.get("y", 0))]
		var q = Missions._poi(["ruin", "camp", "hamlet"], c, 3200.0)
		if q == null or Vector2(q[0], q[1]).distance_to(Vector2(c[0], c[1])) < float(v.get("r", 500)) + 1200.0:
			q = Missions._spot(vid, 1500.0, 2600.0)
		f["hideout"] = [float(q[0]), float(q[1])]
	var h: Array = f["hideout"]
	var w = Game.from_map(Vector2(h[0], h[1]))
	w.y = Game.ground_height(w.x, w.z)
	return w


func infamy() -> int:
	return int(flags().get("infamy", 0))


func add_infamy(n: int) -> void:
	var before = rogue_rank()
	flags()["infamy"] = infamy() + n
	state()["bounty"] = int(state().get("bounty", 5000)) + n * 10
	var after = rogue_rank()
	if after > before:
		Hud.banner("KAÇAK RÜTBESİ: %s" % String(ROGUE_RANKS[after][1]).to_upper(), "Adın yeraltında yayılıyor. Simsar artık %s-rank işler veriyor; av-ninjaları da daha güçlü." % ROGUE_RANKS[after][2], Color(0.85, 0.25, 0.25))


func rogue_rank() -> int:
	var r = 0
	for i in ROGUE_RANKS.size():
		if infamy() >= int(ROGUE_RANKS[i][0]):
			r = i
	return r


func rogue_rank_name() -> String:
	return String(ROGUE_RANKS[rogue_rank()][1])


func _pardon_active() -> bool:
	return String(Missions.active().get("hook", "")) == "Orgs.pardon_done"


## Sığınak: kamp + yeraltı simsarı (iş panosu). Kaçakken sahnede durur
func _ensure_hideout() -> void:
	if not is_rogue():
		if is_instance_valid(_hideout_node):
			_hideout_node.queue_free()
			_hideout_node = null
			Interact.items = Interact.items.filter(func(it): return it.get("kind", "") != "rogue_broker")
		return
	if is_instance_valid(_hideout_node) or Game.world == null:
		return
	var at = hideout_pos()
	_hideout_node = Missions._camp(at)
	Interact.items = Interact.items.filter(func(it): return it.get("kind", "") != "rogue_broker")
	Interact.add({"pos": at + Vector3(0, 1.0, 4.0), "radius": 4.0, "kind": "rogue_broker", "label": "[F] Yeraltı Simsarı (kaçak işleri, rütbe, dinlen)"})


func broker_dialog() -> void:
	var r = rogue_rank()
	var nxt = ("  •  Sonraki rütbe: %d şöhret" % int(ROGUE_RANKS[r + 1][0])) if r + 1 < ROGUE_RANKS.size() else ""
	var opts = []
	if Missions.active().is_empty():
		var top = "CBAS".find(String(ROGUE_RANKS[r][2]))
		for rk in ["C", "B", "A", "S"]:
			if "CBAS".find(rk) > top:
				break
			var job = _rogue_job(rk)
			opts.append({"label": "[%s] %s" % [rk, job["title"]], "tip": job["brief"], "cb": func(): Missions.accept(job)})
	else:
		opts.append({"label": "(Önce elindeki işi bitir)", "cb": func(): pass})
	# kaçak köy eğitmenlerine/parşömencisine gidemez: jutsuyu yeraltından öğrenir, rütbe arttıkça daha çok ve daha üst seviye
	var sc = Progress.scroll_shop_items(6 + r * 3, r * 3)
	if not sc.is_empty():
		opts.append({"label": "Kara pazar parşömenleri (%d)" % sc.size(), "tip": "Rütben arttıkça daha fazla ve daha üst seviye element parşömeni.", "cb": func(): Hud.shop("Kara Pazar — Parşömenler", sc)})
	if r >= 2:
		opts.append({"label": "Yasak teknikler (kinjutsu)", "tip": "Kara Listede ve üstü: köylerin yasakladığı teknikleri ryō karşılığı öğret.", "cb": _kinjutsu_dialog})
	else:
		opts.append({"label": "(Yasak teknikler: «Kara Listede» rütbesinde açılır)", "cb": func(): pass})
	# Akatsuki: «Aranan Gölge» ve üstü kaçaklara davet
	if r >= 3 and not is_akatsuki():
		opts.append({"label": "Kızıl bulutlardan bir mesaj var...", "tip": "Akatsuki seni yanına istiyor.", "cb": _akatsuki_invite})
	elif is_akatsuki() and Missions.active().is_empty():
		var aj = _akatsuki_job()
		opts.append({"label": "[S] Akatsuki: %s" % aj["title"], "tip": aj["brief"], "cb": func(): Missions.accept(aj)})
	opts.append({"label": "Ateşin başında dinlen (can/chakra, kayıt)", "cb": func():
		if Game.player:
			Game.player.hp = Game.player.max_hp
			Game.player.chakra = Game.player.max_chakra
		Game.save_game()
		Hud.msg("Dinlendin. (Oyun kaydedildi)", Color(0.8, 0.9, 1))})
	Hud.dialog("Yeraltı Simsarı", "Kapüşonlu adam ateşi karıştırıyor: \"Kaçaklar için iş hep vardır, %s. Ödülü yüksek olanın riski de yüksek.\"\n\nKaçak rütben: %s  (şöhret %d)%s\nBaşındaki ödül: %d Ryō" % [p()["name"], rogue_rank_name(), infamy(), nxt, int(state().get("bounty", 0))], opts)


## Kaçak işleri: suikast, kervan soygunu, haraç, kaçakçılık (ödül + şöhret)
func _rogue_job(rk: String) -> Dictionary:
	var vid = String(flags().get("rogue_from", Progress.home()))
	var h: Array = flags().get("hideout", [0, 0])
	var back = {"kind": "goto", "at": h, "r": 14.0, "name": "Kaçak Sığınağı", "text": "Sığınağa dön, simsara haber ver."}
	var lv = maxi(int(p()["level"]), 10)
	var pw = float({"C": 1.4, "B": 1.9, "A": 2.4, "S": 3.0}[rk])
	var cnt = int({"C": 2, "B": 3, "A": 4, "S": 5}[rk])
	var far = Missions._near_spot(h, 500.0, 1100.0)
	var base = {"rank": rk, "village": "kacak", "giver": "Yeraltı Simsarı", "hook": "Orgs.rogue_job_done"}
	var kind = ["suikast", "soygun", "harac", "kacakcilik"].pick_random()
	match kind:
		"suikast":
			var t = ["Yozlaşmış Vali Takenori", "Köle Tüccarı Gonbei", "Rüşvetçi Komutan Isao", "Tefeci Kanemaru"].pick_random()
			return base.merged({"title": "Suikast: %s" % t, "brief": "%s korumalarıyla şehir dışında konaklıyor. Korumaları dağıt, hedefi indir." % t,
				"steps": [{"kind": "kill", "at": far, "enemy": "samurai", "n": cnt, "camp": true, "night": true,
					"boss": {"name": t, "hp": 500.0 + lv * 25.0, "level": lv, "power": pw}, "text": "Korumaları ve hedefi etkisiz hale getir."}, back]})
		"soygun":
			return base.merged({"title": "Kervan Soygunu", "brief": "Daimyo'nun vergi kervanı yakından geçiyor. Muhafızları yen, sandıkları al.",
				"steps": [{"kind": "kill", "at": far, "enemy": "samurai", "n": cnt + 1, "camp": true, "text": "Kervan muhafızlarını yen."},
					{"kind": "points", "at": far, "n": 3, "spread": 10, "label": "[F] Sandığı aç", "fx": "tag", "text": "Vergi sandıklarını boşalt (3)."}, back]})
		"harac":
			var gang = ["Kızıl Akrep", "Kara Tilki", "Demir Diş"].pick_random()
			return base.merged({"title": "Haraç: %s Çetesi" % gang, "brief": "%s Çetesi simsarın payını ödemiyor. Liderlerine kimin patron olduğunu hatırlat." % gang,
				"steps": [{"kind": "kill", "at": far, "enemy": "bandit", "n": cnt + 1, "camp": true,
					"boss": {"name": "%s Lideri" % gang, "hp": 400.0 + lv * 20.0, "level": lv, "power": pw * 0.9}, "text": "Çeteyi ve liderini yen."}, back]})
		_:
			var drop = Missions._near_spot(h, 900.0, 1600.0)
			return base.merged({"title": "Kaçakçılık", "brief": "Mühürlü bir sandığı sınırdaki alıcıya götür. Köyün av-ninjaları yolu tutmuş olabilir.",
				"steps": [{"kind": "goto", "at": drop, "r": 14.0, "name": "Buluşma Noktası", "text": "Sandığı buluşma noktasına götür."},
					{"kind": "kill", "at": drop, "enemy": vid if vid in ["kumo", "kiri", "iwa", "suna"] else "rogue", "n": cnt, "text": "Pusuya düşürüldün! Av-ninjalarını savuştur."}, back]})


## Yasak teknikler: yalnız "kinjutsu" öğrenme türü (karakter imzaları/yollar hariç), seviye ve rütbeye göre
func _kinjutsu_dialog() -> void:
	var pr = p()
	var r = rogue_rank()
	var opts = []
	for jid in Data.jutsu:
		var j = Data.jutsu[jid]
		if not j is Dictionary or String(j.get("learn", "")) != "kinjutsu" or jid in pr["learned"]:
			continue
		var lv = int(j.get("level", 10))
		if lv > int(pr["level"]) + r * 2:
			continue
		var price = 1500 + lv * 220
		opts.append({"label": "%s  (Sv.%d) — %d Ryō" % [j.get("name", jid), lv, price], "tip": String(j.get("desc", "")), "cb": func():
			if int(pr["ryo"]) < price:
				Hud.msg("Yeterli ryō yok.", Color(1, 0.6, 0.5))
				return
			pr["ryo"] = int(pr["ryo"]) - price
			Progress.learn(jid)
			add_infamy(30)})
	if opts.is_empty():
		Hud.dialog("Yeraltı Simsarı", "\"Şimdilik sana uygun yasak bir parşömen yok. Seviyen ya da adın büyüsün, gel.\"", [])
		return
	Hud.dialog("Yeraltı Simsarı — Yasak Teknikler", "Simsar sandığından mühürlü parşömenler çıkarıyor: \"Bunları köyler yakar... ben satarım.\"", opts)


func _akatsuki_invite() -> void:
	Hud.dialog("Kızıl Bulut Elçisi", "Gölgelerden kızıl bulutlu bir pelerin çıkıyor: \"Adın Bingo Kitabı'nda epey yükseldi. Örgütümüz kuyruklu canavarları topluyor; bize katıl, köylerin sana açamadığı kapıları biz açalım.\"", [
		{"label": "Akatsuki'ye katıl", "cb": func():
			flags()["akatsuki_member"] = true
			Gear.grant(p(), "akatsuki_pelerini", "dis")
			Gear.apply_look(p())
			if Game.player:
				Game.player.rebuild_model()
			add_infamy(300)
			Hud.banner("AKATSUKİ", "Kızıl bulutlu pelerini giydin. Akatsuki artık sana saldırmaz; simsardan örgüt görevleri al.", Color(0.85, 0.1, 0.12))
			Game.save_game()},
		{"label": "Reddet", "cb": func(): pass}])


## Akatsuki görevi: bir jinchūriki'yi bul ve yen (Bingo'daki taşıyıcı ya da yeni bir kaçak taşıyıcı)
func _akatsuki_job() -> Dictionary:
	var h: Array = flags().get("hideout", [0, 0])
	var at = Missions._near_spot(h, 1200.0, 2400.0)
	var lv = maxi(int(p()["level"]), 30)
	return {"title": "Jinchūriki Avı", "rank": "S", "village": "kacak", "giver": "Akatsuki", "hook": "Orgs.akatsuki_job_done",
		"brief": "Örgüt bir taşıyıcının yerini buldu. Onu yen; canavar mühürlenmek üzere örgüte götürülecek.",
		"steps": [{"kind": "kill", "at": at, "enemy": "jinchuriki", "n": 1, "boss": {"name": "Kaçak Jinchūriki", "hp": 2500.0 + lv * 50.0, "level": lv + 4, "power": 3.2},
			"text": "Jinchūriki'yi yen."}, {"kind": "goto", "at": h, "r": 14.0, "name": "Kaçak Sığınağı", "text": "Sığınağa dön, örgüte haber ver."}]}


func akatsuki_job_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	add_infamy(500)
	Progress.add_ryo(15000)
	Hud.msg("Örgüt memnun: 15000 Ryō, şöhret +500", Color(0.9, 0.3, 0.3))


func rogue_job_done(m: Dictionary, ok: bool) -> void:
	if not ok:
		return
	add_infamy(int({"C": 80, "B": 180, "A": 350, "S": 600}.get(String(m.get("rank", "C")), 80)))
	Hud.msg("Yeraltında adın büyüyor (şöhret %d — %s)" % [infamy(), rogue_rank_name()], Color(0.9, 0.5, 0.45))


## Kaçak büyük gizli köye girerse köy düşman olur: muhafızlar dalga dalga saldırır (Chūnin → Jōnin → ANBU → en son Kage).
## Köyden çıkıp uzak durunca alarm söner. Kefaret görevinin son adımında (köye kanıtla dönüş) alarm çalmaz.
const RAID_WAVES := [
	{"title": "Köy Muhafızları", "kind": "chunin", "n": 3, "lv": 0, "hp": 1.0},
	{"title": "Jōnin Takımı", "kind": "chunin", "n": 3, "lv": 6, "hp": 1.6},
	{"title": "ANBU Birliği", "kind": "anbu", "n": 4, "lv": 10, "hp": 2.0},
]


func _village_ban(dt: float) -> void:
	if not is_rogue() or Game.player == null:
		_end_raid()
		return
	var pl = Game.player
	var m = Game.to_map(pl.global_position)
	var inside = ""
	for vid in ROGUE_BANNED:
		var v = Game.village(vid)
		if v.is_empty():
			continue
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 0.95:
			inside = vid
			break
	if inside != "" and _pardon_active() and inside == String(flags().get("rogue_from", "")):
		var st: Array = Missions.active().get("steps", [])
		if int(Missions.active().get("step", 0)) >= st.size() - 1:
			inside = ""   # Kefaret: kanıtla dönüşte köy saldırmaz
	if _raid.is_empty():
		if inside == "":
			return
		_raid = {"vid": inside, "wave": 0, "t": 2.0, "out_t": 0.0, "nodes": [], "kage": false}
		Hud.banner("KAÇAK KÖYDE!", "%s alarmda: muhafızlar sana saldıracak. Kaldıkça daha güçlüleri gelir — en sonunda Kage." % Game.village(inside).get("name", inside), Color(0.95, 0.25, 0.2))
		Sfx.play("roar", null, 0.7, 0.5)
	var vid: String = _raid["vid"]
	_raid["nodes"] = (_raid["nodes"] as Array).filter(func(n): return is_instance_valid(n) and not n.dead)
	if inside != vid:
		_raid["out_t"] = float(_raid["out_t"]) + dt
		if float(_raid["out_t"]) > 25.0:
			Hud.msg("%s alarmı söndü." % Game.village(vid).get("name", vid), Color(0.8, 0.8, 0.8))
			_end_raid()
		return
	_raid["out_t"] = 0.0
	_raid["t"] = float(_raid["t"]) - dt
	if float(_raid["t"]) > 0.0 or (_raid["nodes"] as Array).size() > 1:
		return
	var w = int(_raid["wave"])
	if w < RAID_WAVES.size():
		_raid_wave(vid, RAID_WAVES[w])
		_raid["wave"] = w + 1
		_raid["t"] = 12.0
	elif not _raid["kage"] and (_raid["nodes"] as Array).is_empty():
		_raid["kage"] = true
		_raid_kage(vid)
	elif _raid["kage"] and (_raid["nodes"] as Array).is_empty():
		# Kage de yenildi: köy kısa süre nefes alır, sonra yeniden muhafız dalgaları
		_raid["wave"] = 0
		_raid["kage"] = false
		_raid["t"] = 90.0
		add_infamy(400)


## Köyün ninja arketipi (Konoha/Ame için Kumo şablonu + köyün kıyafeti ve doğası)
func _village_arch(vid: String, i: int, outfit := "chunin") -> Dictionary:
	var a = Enemy.archetype(vid if vid in ["kumo", "kiri", "iwa", "suna"] else "kumo", i)
	a["look"].merge(Outfits.roll(outfit, vid), true)
	a["look"]["village"] = vid
	if vid == "konoha":
		a["element"] = "katon"
		a["jutsu"] = ["katon_goukakyuu", "katon_housenka"]
	elif vid == "ame":
		a["element"] = "suiton"
		a["jutsu"] = ["suiton_suiryuudan", "suiton_suikoudan"]
	a.erase("auto_jutsu")
	return a


func _raid_wave(vid: String, wd: Dictionary) -> void:
	var pp = Game.player.global_position
	var vname = String(Game.village(vid).get("name", vid))
	Hud.banner(String(wd["title"]).to_upper(), "%s seni kuşatıyor!" % vname, Color(0.9, 0.35, 0.3))
	for i in int(wd["n"]):
		var a = _village_arch(vid, i, "chunin" if int(wd["lv"]) == 0 else "jonin")
		a["respawn"] = false
		a["name"] = "%s %s" % [vname, "ANBU" if wd["kind"] == "anbu" else ("Jōnin" if int(wd["lv"]) > 0 else "Muhafızı")]
		a["level"] = maxi(12, int(p()["level"])) + int(wd["lv"]) + rogue_rank()
		a["hp"] = (260.0 + a["level"] * 18.0) * float(wd["hp"])
		a["power"] = 1.5 + a["level"] * 0.02
		if wd["kind"] == "anbu":
			a["look"]["face_style"] = ["anbu_kedi", "anbu_kurt", "anbu_kus", "anbu_kedi"][i % 4]
		var e = Enemy.new()
		e.setup(a)
		e.set_meta("village_guard", vid)
		get_tree().current_scene.add_child(e)
		var q = Missions.open_ground(pp + Vector3(cos(i * 1.9), 0, sin(i * 1.9)) * 22.0, 15.0)
		e.global_position = q
		e.home = q
		(_raid["nodes"] as Array).append(e)
		_spawned.append(e)


func _raid_kage(vid: String) -> void:
	var title = Progress.kage_title(vid) if Progress.has_method("kage_title") else "Kage"
	var a = _village_arch(vid, 0, "jonin")
	a["respawn"] = false
	a["name"] = "%s — köyünü koruyor" % title
	a["level"] = maxi(50, int(p()["level"]) + 12)
	a["hp"] = 4000.0 + a["level"] * 60.0
	a["power"] = 3.0 + a["level"] * 0.02
	a["guard"] = 0.5
	a["sub"] = 0.35
	BossStyles.dress(a, "S", hash(vid) % 100000, "")
	var e = Enemy.new()
	e.setup(a)
	e.set_meta("village_guard", vid)
	get_tree().current_scene.add_child(e)
	var q = Missions.open_ground(Game.player.global_position + Vector3(0, 0, -28), 15.0)
	e.global_position = q
	e.home = q
	(_raid["nodes"] as Array).append(e)
	_spawned.append(e)
	Hud.banner(title.to_upper(), "Köyün lideri bizzat geldi!", Color(1, 0.6, 0.2))
	Hud.boss_bar(e)


func _end_raid() -> void:
	if _raid.is_empty():
		return
	for n in _raid.get("nodes", []):
		if is_instance_valid(n) and not n.dead:
			n.queue_free()
	_raid = {}


func _hunter_tick(dt: float) -> void:
	if not is_rogue() or Game.player == null or _pardon_active():
		return   # Kefaret görevinde av-ninjaları gelmez (köy affı bekliyor)
	_hunter_t += dt
	if _hunter_t < 150.0:
		return
	# köy içinde değilken av-ninjaları gelir
	var m = Game.to_map(Game.player.global_position)
	for v in Game.world_info.get("villages", []):
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			return
	_hunter_t = 0.0
	var vid = String(flags().get("rogue_from", "konoha"))
	var kind = vid if vid in ["kumo", "kiri", "iwa", "suna"] else "rogue"
	var pp = Game.player.global_position
	Hud.banner("AV-NİNJALARI", "%s seni buldu!" % Game.village(vid).get("name", vid), Color(0.9, 0.3, 0.3))
	for i in 3:
		var e = Enemy.new()
		var a = Enemy.archetype(kind, i)
		a["name"] = "Av-Ninjası"
		a["respawn"] = false
		a["level"] = maxi(15, int(p()["level"])) + rogue_rank() * 2
		a["hp"] = 300.0 + a["level"] * 20.0
		a["power"] = 1.8 + a["level"] * 0.02
		a["look"]["face_style"] = ["anbu_kedi", "anbu_kurt", "anbu_kus"][i]
		a["look"]["village"] = vid
		e.setup(a)
		e.set_meta("hunter_nin", true)
		get_tree().current_scene.add_child(e)
		var q = pp + Vector3(cos(i * 2.1), 0, sin(i * 2.1)) * 30.0
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.home = q
		_spawned.append(e)


func on_enemy_killed(e: Node) -> void:
	if e.has_meta("hunter_nin"):
		flags()["hunters_beaten"] = int(flags().get("hunters_beaten", 0)) + 1
		state()["bounty"] = int(state().get("bounty", 5000)) + 1500
		add_infamy(25)
	if e.has_meta("akatsuki"):
		var n = String(e.get_meta("akatsuki"))
		var dead: Array = state().get("akatsuki_dead", [])
		if not n in dead:
			dead.append(n)
		state()["akatsuki_dead"] = dead
		Hud.banner("AKATSUKİ ÜYESİ DÜŞTÜ", n, Color(0.95, 0.4, 0.3))
		Missions._rep(Progress.home(), 30)


# ================================================================== Chūnin finalinde istila
## Ses ninjaları + dev yılanlar stadyumu basar. done(won: bool)
func exam_invasion(center: Vector3, done: Callable) -> void:
	_invasion = {"done": done, "enemies": [], "t": 0.0}
	Hud.banner("İSTİLA!", "Ses ninjaları ve dev yılanlar stadyumu bastı!", Color(0.9, 0.2, 0.2))
	Sfx.play("roar", center, 0.6, 0.9)
	FX.smoke_puff(center + Vector3.UP * 6, 4.0, 40)
	for i in 8:
		var e = Enemy.new()
		var a = Enemy.archetype("oto", i)
		a["respawn"] = false
		a["level"] = maxi(12, int(p()["level"]))
		e.setup(a)
		get_tree().current_scene.add_child(e)
		var q = center + Vector3(cos(i * 0.8), 0, sin(i * 0.8)) * randf_range(15, 30)
		q.y = Game.ground_height(q.x, q.z)
		e.global_position = q
		e.home = q
		_invasion["enemies"].append(e)
	# dev yılanlar (Konoha Yıkımı'ndaki gibi tribünleri yıkarak gelir)
	for i in 3:
		var s = Summon.new()
		s.contract = "yılan"
		s.tier = 2 if i == 0 else 1
		s.def = Contracts.DEFS["yılan"]["tiers"][s.tier]
		s.team = "enemy"
		s.owner_f = null
		get_tree().current_scene.add_child(s)
		s.life = 99999.0
		var q = center + Vector3(-45 + i * 45, 0, 40 + (25 if i == 0 else 0))
		q.y = Game.ground_height(q.x, q.z)
		s.global_position = q
		_invasion["enemies"].append(s)
	Missions.target_marker = center
	Missions.has_marker = true
	Missions.target_name = "İstila — Stadyum"


func _invasion_tick(dt: float) -> void:
	if _invasion.is_empty():
		return
	_invasion["t"] = float(_invasion["t"]) + dt
	var alive = 0
	for e in _invasion["enemies"]:
		if is_instance_valid(e) and not e.is_dead():
			alive += 1
	Hud.objective_progress("İstilacılar: %d kaldı" % alive)
	if alive == 0 or float(_invasion["t"]) > 300.0:
		var cb: Callable = _invasion["done"]
		var won = alive == 0
		for e in _invasion["enemies"]:
			if is_instance_valid(e):
				e.queue_free()
		_invasion = {}
		Missions.has_marker = false
		if won:
			Progress.add_xp(500)
			Missions._rep(Progress.home(), 20)
		cb.call(won)


# ================================================================== dünya olayları (hikâyeye göre zamanlanır)
func _events_tick() -> void:
	var pr = p()
	var ev: Dictionary = state()["events"]
	var rank = int(pr["rank"])
	if not Missions.active().is_empty() or Game.ui_open:
		return
	# Sınır savaşı: chūnin olduktan bir süre sonra
	if rank >= 2 and Progress.story() >= Journal.FREE and not ev.has("border_war") and randf() < 0.02:
		ev["border_war"] = "active"
		_border_war()
		return
	# Kuyruklu canavar avı: jōnin olunca
	if rank >= 3 and not is_hunting() and randf() < 0.03:
		start_beast_hunt()
		return
	# Büyük Ninja Savaşı: Kage zirvesinden sonra
	if state().get("summit", false) and state().get("war", "none") == "none" and randf() < 0.05:
		_great_war_prompt()


func _border_war() -> void:
	var home = Progress.home()
	var rival = ["konoha", "suna", "kiri", "kumo", "iwa"].filter(func(x): return x != home and not Game.village(x).is_empty()).pick_random()
	if has_node("/root/Kage"):
		Kage.change_relation(rival, -30)
	var outpost = Missions._spot(home, 700, 1300)
	var kind = rival if rival in ["kumo", "kiri", "iwa", "suna"] else "rogue"
	var m = {"title": "Sınır Savaşı: %s Öncüleri" % Game.village(rival).get("name", rival), "rank": "B", "village": home, "giver": Progress.home_info()["kage"], "hook": "Orgs.event_done", "event": "border_war",
		"brief": "%s sınır karakolumuza saldırdı. Karakolu savun, komutanlarını püskürt; bu bir savaşa dönüşmeden önce." % Game.village(rival).get("name", rival),
		"steps": [{"kind": "goto", "at": Missions._near_spot(outpost, 60, 80), "r": 14.0, "name": "Sınır Karakolu", "text": "Sınır karakoluna yetiş."},
			{"kind": "defend", "at": outpost, "enemy": kind, "waves": [3, 4, 5], "text": "Saldırı dalgalarını püskürt."},
			{"kind": "kill", "at": Missions._near_spot(outpost, 80, 120), "enemy": kind, "n": 2, "boss": {"name": "Öncü Komutanı", "hp": 1800.0, "level": maxi(20, int(p()["level"])), "power": 2.3}, "text": "Öncü komutanını yen."}]}
	Hud.dialog("Ulak", "Acil haber! %s sınır karakolumuza saldırdı. %s seni hemen çağırıyor!" % [Game.village(rival).get("name", rival), Progress.home_info()["kage"]], [
		{"label": "Hemen yola çık", "cb": func(): Missions.accept(m)}, {"label": "Şimdi gidemem (itibar kaybı)", "cb": func():
			Missions._rep(Progress.home(), -15)
			state()["events"]["border_war"] = "ignored"}])


func event_done(m: Dictionary, ok: bool) -> void:
	var id = String(m.get("event", ""))
	if id != "":
		state()["events"][id] = "won" if ok else "lost"
	if ok:
		Missions._rep(Progress.home(), 25)


func _great_war_prompt() -> void:
	state()["war"] = "called"
	war_started.emit()
	Hud.banner("DÖRDÜNCÜ BÜYÜK NİNJA SAVAŞI", "Müttefik Shinobi Kuvvetleri toplanıyor", Color(1, 0.55, 0.2))
	var field = null
	for l in Game.world_info.get("landmarks", []):
		if l.get("arena", false):
			field = [float(l["x"]), float(l["y"])]
			break
	if field == null:
		field = Missions._spot(Progress.home(), 2000, 3000)
	var lead = AKATSUKI[AKATSUKI.size() - 1]
	var m = {"title": "Büyük Ninja Savaşı", "rank": "S", "village": Progress.home(), "giver": "Müttefik Kuvvetler Başkomutanı", "hook": "Orgs.war_done",
		"brief": "Beş büyük köy tek bir orduda birleşti. Akatsuki'nin beyaz klon ordusu ve liderleri savaş alanında. Cepheyi tut, liderleri düşür.",
		"steps": [{"kind": "goto", "at": Missions._near_spot(field, 150, 200), "r": 25.0, "name": "Müttefik Karargâhı", "text": "Savaş alanındaki müttefik karargâhına git."},
			{"kind": "defend", "at": field, "enemy": "rogue", "ename": "Beyaz Klon", "waves": [6, 7, 8, 9], "text": "Beyaz klon ordusunun dalgalarını durdur."},
			{"kind": "kill", "at": Missions._near_spot(field, 60, 100), "enemy": "rogue", "n": 1, "boss": {"name": "%s «%s»" % [AKATSUKI[0]["name"], AKATSUKI[0]["alias"]], "hp": 3600.0, "level": 45, "power": 3.0, "look": akatsuki_look(AKATSUKI[0])}, "text": "Akatsuki komutanını yen."},
			{"kind": "kill", "at": field, "enemy": "rogue", "n": 2, "boss": {"name": "%s «%s»" % [lead["name"], lead["alias"]], "hp": 7000.0, "level": 55, "power": 3.8, "look": akatsuki_look(lead)}, "text": "Örgütün liderini yen."}]}
	Hud.dialog("Müttefik Kuvvetler Başkomutanı", "Kage Zirvesi'nde verdiğimiz söz yerine geliyor: beş köy tek bir ordu. Sen cephenin kalbinde olacaksın.", [{"label": "Savaşa katıl", "cb": func(): Missions.accept(m)}, {"label": "Hazırlanmam lazım", "cb": func(): state()["war"] = "none"}])


func war_done(_m: Dictionary, ok: bool) -> void:
	state()["war"] = "won" if ok else "none"
	war_ended.emit(ok)
	if ok:
		Hud.banner("SAVAŞ BİTTİ", "Beş köy birlikte kazandı. Adın efsanelere yazıldı.", Color(1, 0.85, 0.4))
		Progress.add_xp(5000)
		var gid = Gear.random_legendary()
		if gid != "":
			Gear.grant(p(), gid)
		for v in ["konoha", "suna", "kiri", "kumo", "iwa"]:
			Missions._rep(v, 50)


# ================================================================== güncelleme
func _process(dt: float) -> void:
	if Game.player == null or Game.profile.is_empty() or Game.paused:
		return
	_invasion_tick(dt)
	_hunter_tick(dt)
	_village_ban(dt)
	_ensure_hideout()
	_t += dt
	if _t >= 20.0:
		_t = 0.0
		_events_tick()
	# Akatsuki avı sürerken: vahşi doğada ara sıra bir çift belirir
	if is_hunting() and int(p()["rank"]) >= 3 and not is_akatsuki():
		_hunt_t += dt
		if _hunt_t > 600.0:
			_hunt_t = 0.0
			var m = Game.to_map(Game.player.global_position)
			var inside = false
			for v in Game.world_info.get("villages", []):
				if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 1.2:
					inside = true
			if not inside and randf() < 0.5:
				var dead: Array = state().get("akatsuki_dead", [])
				var pairs = [0, 1, 2, 3].filter(func(i): return AKATSUKI.filter(func(x): return int(x["pair"]) == i and not String(x["name"]) in dead).size() > 0)
				if not pairs.is_empty():
					var pp = Game.player.global_position
					spawn_pair(pairs.pick_random(), pp + Vector3(50, 0, 30))
					Hud.banner("KIZIL BULUTLAR", "İki Akatsuki üyesi yolunu kesti!", Color(0.85, 0.15, 0.15))
	for e in _spawned.duplicate():
		if not is_instance_valid(e):
			_spawned.erase(e)
		elif e.global_position.distance_to(Game.player.global_position) > 600.0:
			e.queue_free()
			_spawned.erase(e)
