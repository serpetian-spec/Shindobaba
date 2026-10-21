extends Node
## RPG ilerleme (autoload "Progress"): XP/seviye, rütbe, hikâye zinciri, hocalar, etkileşimler, öğrenme.

const STORY := [
	"Ninja Akademisi'ne git ve hocan Hoshino-sensei ile konuş. (Akademi, köyün kuzeybatısı)",
	"Akademi avlusundaki kuklalara 25 darbe vur, sonra hocana dön.",
	"Hocandan Henge no Jutsu'yu öğren ve bir kez kullan [slot 1].",
	"Mezuniyet Sınavı: avludaki 3 kuklayı devir, sonra hocana rapor ver.",
	"Chakra kontrolü: duvar koşusuyla 35 m yüksekliğe tırman (Hokage Kayası ideal).",
	"Antrenman Alanı 3'te (köyün doğusu) chakra kâğıdı testini yap.",
	"Hokage Kulesi'ndeki görev masasından 3 D-rank görev tamamla.",
	"Seviye 6 ol ve Hokage Kulesi'ne git: Yasak Parşömen görevi.",
	"Yasak Parşömen: Haydut Kampı'ndaki (köyün güneydoğusu) haydut liderini yen.",
	"Seviye 10'a ulaş ve Stadyumda Chunin Sınavına başvur.",
	"Chunin Sınavı devam ediyor...",
	"Chunin oldun! Diğer köylere görevlerle seyahat et. Rasengan ve çağırma için Gizli Şelale'ye git (Sv.12).",
	"Jonin olmak için: Seviye 20 + 3 A-rank görev.",
	"ANBU için: Seviye 30 + 1 S-rank görev. ANBU Karargâhı.",
	"Efsane bir shinobi oldun. Dünya senin.",
]


func p() -> Dictionary:
	return Game.profile


func story() -> int:
	return int(p().get("story", 0))


func set_story(i: int) -> void:
	p()["story"] = i
	Hud.objective_changed()
	Sfx.play("levelup", null, 1.3, 0.5)
	Game.save_game()


func new_profile(opts: Dictionary) -> Dictionary:
	var pr = {
		"slot": opts.get("slot", 1), "name": opts.get("name", "İsimsiz"), "gender": opts.get("gender", "m"),
		"clan": opts.get("clan", "none"), "elements": [opts.get("element", "katon")], "element_known": false,
		"look": opts.get("look", {}), "level": 1, "xp": 0, "rank": 0, "ryo": 150, "sp": 0, "skills": [],
		"learned": [], "slots": ["", "", "", ""], "inventory": {"kunai": 12, "shuriken": 6, "salve": 2},
		"throw_sel": "kunai", "summon": "kurbağa", "story": 0, "flags": {}, "missions_done": {"D": 0, "C": 0, "B": 0, "A": 0, "S": 0},
		"active_mission": {}, "visited": ["konoha"], "stats": {"kills": 0}, "time": 0.32,
	}
	# akademi öğrencisi: alın koruyucu yok
	pr["look"]["band"] = null
	return pr


# ------------------------------------------------------------------ XP / seviye
func add_xp(amount: int) -> void:
	var pr = p()
	pr["xp"] = int(pr["xp"]) + amount
	Hud.float_text("+%d XP" % amount, Color(0.7, 0.9, 1.0))
	while int(pr["xp"]) >= Data.xp_for_level(int(pr["level"])):
		pr["xp"] = int(pr["xp"]) - Data.xp_for_level(int(pr["level"]))
		pr["level"] = int(pr["level"]) + 1
		pr["sp"] = int(pr["sp"]) + 1
		Hud.banner("SEVİYE %d" % pr["level"], "Yetenek puanı kazandın [K]", Color(1, 0.85, 0.35))
		Sfx.play("levelup")
		if Game.player:
			Game.player.apply_profile_stats()
			Game.player.hp = Game.player.max_hp
			Game.player.chakra = Game.player.max_chakra
			FX.aura(Game.player, Color(1, 0.85, 0.4), 1.4)
		_check_story_levels()


func add_ryo(amount: int) -> void:
	p()["ryo"] = int(p()["ryo"]) + amount
	if amount > 0:
		Hud.float_text("+%d Ryō" % amount, Color(1, 0.85, 0.4))
		Sfx.play("coin")


func learn(jid: String, announce := true) -> bool:
	var pr = p()
	if jid in pr["learned"]:
		return false
	pr["learned"].append(jid)
	var slots: Array = pr["slots"]
	for i in slots.size():
		if slots[i] == "" or slots[i] == null:
			slots[i] = jid
			break
	if announce:
		Hud.banner("YENİ JUTSU", Data.jutsu[jid]["name"], Color(0.5, 0.85, 1.0))
		Sfx.play("levelup", null, 0.8)
	Game.save_game()
	return true


func promote(rank: int) -> void:
	var pr = p()
	pr["rank"] = rank
	var look: Dictionary = pr["look"]
	match rank:
		1:
			look["band"] = Color(0.15, 0.22, 0.55)
		2:
			look["vest"] = Color(0.38, 0.48, 0.28)
		4:
			look["vest"] = Color(0.75, 0.75, 0.78)
	Hud.banner(Data.RANKS[rank].to_upper(), "Rütbe atladın!", Color(1, 0.6, 0.25))
	Sfx.play("levelup", null, 0.7)
	if Game.player:
		Game.player.rebuild_model()
	Game.save_game()


# ------------------------------------------------------------------ olay kancaları
func on_enemy_killed(e: Node) -> void:
	add_xp(int(e.xp))
	add_ryo(int(e.ryo))
	p()["stats"]["kills"] = int(p()["stats"].get("kills", 0)) + 1
	Missions.on_kill(e)
	if story() == 8 and e.get_meta("scroll_thief", false):
		Game.profile["active_mission"] = {}
		Missions.has_marker = false
		learn("bunshin")
		Hud.dialog("Hokage", "Yasak Parşömeni geri getirdin. İçindeki Kage Bunshin tekniğini öğrenmeyi hak ettin.", [])
		set_story(9)


func on_hit_landed(_t: Node) -> void:
	pass


func on_dummy_hit(_d: Node, _dmg: float) -> void:
	var pr = p()
	if story() == 1:
		pr["flags"]["dummy_hits"] = int(pr["flags"].get("dummy_hits", 0)) + 1
		Hud.objective_progress("Kukla darbeleri: %d/25" % pr["flags"]["dummy_hits"])
	if pr["flags"].get("grad_exam", false):
		pass


func on_dummy_broken(_d: Node) -> void:
	var pr = p()
	if story() == 3:
		pr["flags"]["grad_broken"] = int(pr["flags"].get("grad_broken", 0)) + 1
		Hud.objective_progress("Devrilen kukla: %d/3" % pr["flags"]["grad_broken"])
	Missions.on_dummy_broken()


func on_technique_used(id: String) -> void:
	if story() == 2 and id == "henge":
		p()["flags"]["henge_used"] = true
		Hud.objective_progress("Henge kullanıldı! Hocana dön.")


func on_player_died() -> void:
	Hud.banner("YENİLDİN", "Hastanede uyanıyorsun...", Color(0.9, 0.3, 0.3))
	var pr = p()
	pr["ryo"] = int(int(pr["ryo"]) * 0.9)
	get_tree().create_timer(2.5).timeout.connect(func():
		var v = Game.village("konoha")
		var pos = Game.from_map(Vector2(v["x"] + 140, v["y"] + 60))
		Game.player.respawn(pos))


func _process(_dt: float) -> void:
	if Game.player == null or Game.profile.is_empty():
		return
	# hikâye: yüksekliğe tırman
	if story() == 4:
		var pl = Game.player
		var h: float = pl.global_position.y - Game.terrain_height(pl.global_position.x, pl.global_position.z)
		if pl.wall_n != Vector3.ZERO and h > 35.0:
			Hud.dialog("Kurogane-sensei", "Harika! Chakrayı ayaklarında dengeleyip tırmandın. Şimdi Antrenman Alanı 3'e gel, doğanı öğrenelim.", [])
			if not "nin1" in p()["skills"]:
				p()["skills"].append("nin1")
			set_story(5)
	# ziyaret edilen köyler (hızlı seyahat)
	var m = Game.to_map(Game.player.global_position)
	for v in Game.world_info["villages"]:
		if not v["id"] in p()["visited"] and m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]):
			p()["visited"].append(v["id"])
			Hud.banner(v["name"], "Keşfedildi — haritadan hızlı seyahat açıldı", Color(0.8, 0.95, 1.0))
			add_xp(60)


func _check_story_levels() -> void:
	var lv = int(p()["level"])
	if story() == 7 and lv >= 6:
		Hud.msg("Hokage Kulesi'ne git: önemli bir görev var!", Color(1, 0.8, 0.4))
	if story() == 9 and lv >= 10:
		Hud.msg("Chunin Sınavı başvuruları açık! (Stadyum)", Color(1, 0.8, 0.4))
	if story() == 12 and lv >= 20 and int(p()["missions_done"].get("A", 0)) >= 3:
		promote(3)
		set_story(13)


# ------------------------------------------------------------------ etkileşimler [F]
func interact(it: Dictionary) -> void:
	var kind: String = it["kind"]
	var pr = p()
	match kind:
		"academy":
			_academy()
		"mission_board":
			_mission_board(it)
		"ramen":
			_eat(50, "Sıcak bir kase miso chashu ramen... Can ve chakra doldu!", "Teuchi'nin çırağı")
		"bbq":
			_eat(80, "Yakiniku! Can ve chakra doldu, 60sn boyunca +%20 güç.", "Garson")
			Buffs.add("bbq", 60.0, {"melee": 1.2})
		"hospital":
			Game.player.hp = Game.player.max_hp
			var opts = []
			if int(pr["level"]) >= 4 and not "shousen" in pr["learned"]:
				opts.append({"label": "Tıbbi ninjutsu öğren (200 Ryō)", "cb": func(): _buy_learn("shousen", 200)})
			Hud.dialog("Hastane", "Yaraların sarıldı. Tamamen iyileştin.", opts)
		"training":
			_training_ground()
		"swing":
			Game.player.sit(it["pos"])
		"lookout":
			Game.save_game()
			Hud.dialog("Hokage Kayası", "Köy ayaklarının altında. Ateşin İradesi'ni hissediyorsun... (Oyun kaydedildi)", [])
		"memorial":
			Hud.dialog("Anıt Taşı", "Köy için canını veren shinobilerin isimleri burada yazılı. Bir an saygıyla eğiliyorsun.", [])
		"gate":
			Hud.dialog("Kapı Nöbetçisi", "Dışarısı tehlikeli genç ninja. Haritayı [M] aç, yolları takip et. Diğer köylere varınca hızlı seyahat açılır.", [])
		"shop_weapons":
			Hud.shop("Silah Dükkânı", ["kunai", "shuriken", "tag", "smoke", "scroll_katon_housenka", "scroll_suiton_suijinheki", "scroll_fuuton_daitoppa", "scroll_doton_doryuheki"])
		"shop_items":
			Hud.shop("Eczane", ["salve", "pill", "smoke", "scroll_kokuangyo"])
		"chunin_exam":
			ChuninExam.apply()
		"onsen":
			Game.player.hp = Game.player.max_hp
			Game.player.chakra = Game.player.max_chakra
			Hud.dialog("Kaplıca", "Sıcak su tüm yorgunluğunu aldı. Tamamen iyileştin.", [])
		"sage":
			_sage_falls()
		"valley":
			Hud.dialog("Sonun Vadisi", "İki dev heykelin arasında nehir köpürüyor. Burada bir zamanlar büyük bir savaş olmuş... (Sv.35'te gizli bir uyanış seni bekliyor)", [])
		"anbu":
			if int(pr["rank"]) >= 3 and int(pr["level"]) >= 30 and int(pr["missions_done"].get("S", 0)) >= 1:
				promote(4)
				set_story(14)
			else:
				Hud.dialog("ANBU", "Burası yetkisiz girişe kapalı. (Jonin + Sv.30 + 1 S-rank görev)", [])
		_:
			Hud.dialog(it.get("label", "").replace("[F] ", ""), "Burada şimdilik yapacak bir şey yok.", [])
	Missions.on_interact(it)


func _eat(price: int, text: String, who: String) -> void:
	if int(p()["ryo"]) < price:
		Hud.dialog(who, "Kusura bakma, %d Ryō lazım." % price, [])
		return
	add_ryo(-price)
	Game.player.hp = Game.player.max_hp
	Game.player.chakra = Game.player.max_chakra
	Game.player.model.play("eat", 0.1, 1.0, true)
	Hud.dialog(who, text, [])


func _buy_learn(jid: String, price: int) -> void:
	if int(p()["ryo"]) < price:
		Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
		return
	add_ryo(-price)
	learn(jid)


func _academy() -> void:
	var s = story()
	var pr = p()
	var sensei = "Hoshino-sensei"
	match s:
		0:
			Hud.dialog(sensei, "Hoş geldin %s! Bir ninja olmak için önce temeli sağlam atmalısın. Avludaki kuklalara 25 darbe vur [Sol tık], kombolarını çalış. Kawarimi [Q] ile kaçmayı da unutma!" % pr["name"], [])
			set_story(1)
		1:
			if int(pr["flags"].get("dummy_hits", 0)) >= 25:
				Hud.dialog(sensei, "Güzel taijutsu! Şimdi sana Akademi'nin üç temel tekniğinden birini öğreteceğim: Henge. Mühürler: Köpek - Domuz - Koç.", [])
				learn("henge")
				set_story(2)
			else:
				Hud.dialog(sensei, "Daha %d darbe kaldı. Tembellik yok!" % (25 - int(pr["flags"].get("dummy_hits", 0))), [])
		2:
			if pr["flags"].get("henge_used", false):
				Hud.dialog(sensei, "Mükemmel dönüşüm! Mezuniyet sınavına hazırsın. Avludaki 3 kuklayı devir ve bana rapor ver.", [])
				pr["flags"]["grad_broken"] = 0
				set_story(3)
			else:
				Hud.dialog(sensei, "Henge'yi [1] tuşuyla kullan ve bana göster.", [])
		3:
			if int(pr["flags"].get("grad_broken", 0)) >= 3:
				Hud.dialog(sensei, "Tebrikler... Bu alın koruyucuyu takmayı hak ettin. Artık Konoha'nın bir Genin'isin! Jonin hocan Kurogane-sensei seni bekliyor: önce chakra kontrolünü geliştir, duvarlara tırman!", [])
				promote(1)
				add_xp(150)
				add_ryo(200)
				set_story(4)
			else:
				Hud.dialog(sensei, "Henüz %d kukla devrildi. 3 lazım!" % int(pr["flags"].get("grad_broken", 0)), [])
		_:
			var opts = []
			if int(pr["level"]) >= 3 and not "shunshin" in pr["learned"]:
				opts.append({"label": "Shunshin öğren (150 Ryō)", "cb": func(): _buy_learn("shunshin", 150)})
			if int(pr["level"]) >= 5 and not "narakumi" in pr["learned"]:
				opts.append({"label": "Genjutsu dersi: Narakumi (250 Ryō)", "cb": func():
					if not "genjutsu" in pr["skills"]:
						pr["skills"].append("genjutsu")
					_buy_learn("narakumi", 250)})
			Hud.dialog(sensei, "Seninle gurur duyuyorum %s. Ateşin İradesi seninle!" % pr["name"], opts)


func _training_ground() -> void:
	var pr = p()
	var s = story()
	if s == 5:
		var el: String = pr["elements"][0]
		var names = {"katon": "kâğıt yanıp kül oldu: ATEŞ (Katon)", "suiton": "kâğıt ıslandı: SU (Suiton)", "fuuton": "kâğıt ikiye bölündü: RÜZGAR (Fuuton)",
			"doton": "kâğıt ufalandı: TOPRAK (Doton)", "raiton": "kâğıt buruştu: YILDIRIM (Raiton)"}
		pr["element_known"] = true
		Hud.dialog("Kurogane-sensei", "Chakra kâğıdına chakranı akıt... %s! İlk element tekniğini öğretiyorum." % names[el], [])
		var starter = {"katon": "katon_goukakyuu", "suiton": "suiton_suikoudan", "fuuton": "fuuton_shinkuu", "doton": "doton_doryuusou", "raiton": "raiton_nagashi"}[el]
		learn(starter)
		set_story(6)
		return
	var opts = []
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 12 and "raiton" in pr["elements"] and not "raiton_chidori" in pr["learned"]:
		opts.append({"label": "Chidori eğitimi (800 Ryō)", "cb": func(): _buy_learn("raiton_chidori", 800)})
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 16 and "katon" in pr["elements"] and not "katon_karyuu" in pr["learned"]:
		opts.append({"label": "Karyuu Endan eğitimi (1200 Ryō)", "cb": func(): _buy_learn("katon_karyuu", 1200)})
	Hud.dialog("Antrenman Alanı 3", "Kuklalarla kombolarını çalışabilirsin. Chakra şarjı [C], blok [Sağ tık], Kawarimi [Q].", opts)


func _sage_falls() -> void:
	var pr = p()
	var opts = []
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 12 and not "rasengan" in pr["learned"]:
		opts.append({"label": "Rasengan eğitimi (3 aşama)", "cb": func(): RasenganTraining.start()})
	if int(pr["rank"]) >= 2 and int(pr["level"]) >= 12 and not "kuchiyose" in pr["learned"]:
		opts.append({"label": "Kurbağa sözleşmesini imzala", "cb": func():
			pr["summon"] = "kurbağa"
			if not "contract" in pr["skills"]:
				pr["skills"].append("contract")
			learn("kuchiyose")})
	Hud.dialog("Yaşlı Kurbağa Bilge", "Doğanın enerjisini dinle genç... Sabırlı olanlar burada güç bulur." if opts.is_empty() else "Hazırsın. Ne öğrenmek istersin?", opts)


func _mission_board(it: Dictionary) -> void:
	var pr = p()
	var s = story()
	if s == 7 and int(pr["level"]) >= 6 and it["label"].contains("Hokage"):
		Hud.dialog("Hokage", "Bir haydut çetesi köyün Yasak Parşömenini çaldı! Köyün güneydoğusundaki Haydut Kampı'na git ve liderlerini yen.", [])
		Missions.spawn_scroll_thief()
		set_story(8)
		return
	if s == 9 and int(pr["level"]) >= 10:
		Hud.msg("Chunin Sınavı için Stadyuma git!", Color(1, 0.8, 0.4))
	if s >= 12 and int(pr["rank"]) == 2 and int(pr["level"]) >= 20 and int(pr["missions_done"].get("A", 0)) >= 3:
		promote(3)
		set_story(13)
		return
	Missions.open_board(it)
