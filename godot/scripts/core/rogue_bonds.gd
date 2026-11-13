class_name RogueBonds
extends RefCounted
## Kaçak ninjalarla dostluk. Bağ yerine "güven" (Friends kaydındaki bond alanı; arayüzde Güven yazar).
## Tanışma: yendiğin kaçak %25 cana inince pes eder -> Öldür / Teslim et / Bağışla. Bağışlarsan sana borçlu bir kaçak dost olur.
## Etkinlikler: kamp ateşi başında gizli buluşma, yol hanında sake, ortak işler (kervan soygunu, arkadaşını kurtarma, avcıları püskürtme,
## yasak parşömen), ganimet paylaşma, geçmişini anlatması (güvenle açılır).
## Riskler: köy devriyesi seni onunla görürse itibar/suç; üç kez görülürsen Kage ültimatom verir (teslim et ya da sen de kaçaksın).
## Sonlar: kurtuluş (Kage'den af görevi), birlikte kaçış, ihanet (güveni düşük kaçak seni avcılara satar).

const MOTIVES := [
	["haksızlık", "Köyüm bir suçu benim üstüme yıktı. Kaçmasaydım idam edilecektim.", "Gerçek suçlu hâlâ köyde, konseyde oturuyor. Bir gün adımı temize çıkaracağım."],
	["intikam", "Kardeşimi göreve gönderip ölüme terk ettiler. Bandımı o gün çizdim.", "Onu terk eden komutanın adını biliyorum. Ama intikam... artık emin değilim."],
	["klan", "Klanımı 'tehlikeli' diye dağıttılar. Ben kaçabilen tek kişiyim.", "Kanımdaki tekniği yaşatmak zorundayım. Yoksa klanım tamamen yok olacak."],
	["özgürlük", "Bir köyün silahı olmaktan bıktım. Kendi yolumu seçtim.", "Bazen geri dönmeyi düşünüyorum... ama kimse bana zincirsiz bir hayat sunmadı."],
	["borç", "Ailem bir tefeciye borçlanmıştı. Köyün parasını çalıp borcu ödedim.", "Pişman değilim. Ailem yaşıyor. Ama bir daha asla köyüme bakamayacağım."],
]
const JOBS := [
	["soygun", "Kervan soygunu", "Daimyō'nun vergi kervanı ormandan geçiyor. Muhafızları sen tut, ben sandıkları alayım."],
	["kurtar", "Arkadaşını kurtar", "Eski bir dostum sınır karakolunda zincire vuruldu. Onu oradan çıkarmama yardım et."],
	["avci", "Avcıları püskürt", "Av ninjaları izimi buldu. Bu gece beni bulacaklar. Yanımda ol."],
	["parsomen", "Yasak parşömen", "Bir karakolda eski bir mühür parşömeni var. Fark edilmeden alırsak ikimiz de güçleniriz."],
]


static func pr() -> Dictionary:
	return Game.profile


## Bu düşman pes edip bağışlanabilir mi (kaçak, görev hedefi/örgüt üyesi/dost değil)
static func spareable(e: Enemy, info: Dictionary) -> bool:
	if not info.get("attacker") is Player or e.team != "enemy" or e.has_meta("yielded"):
		return false
	# dövüşü kazanmakta olan pes etmez: rakibinin canı (oran olarak) kendisininkinden azsa bitirmeye oynar
	var atk: Player = info.get("attacker")
	if atk.hp / maxf(atk.max_hp, 1.0) <= e.hp / maxf(e.max_hp, 1.0):
		return false
	if String(e.arch.get("kind", "")) not in ["rogue", "jinchuriki"] or e.arch.has("boss"):
		return false
	if e.has_meta("rorg") or e.has_meta("spar") or e.has_meta("friend_id") or e.has_meta("teammate") or (e.get_node_or_null("ClanTrait") != null and e.get_node("ClanTrait").duel):   # dostça düello: kendi teslim akışı var
		return false
	return e.has_meta("bingo_id") or not e.has_meta("mission")


## %25 canda pes eder: seçim oyuncunun
static func yield_to(e: Enemy) -> void:
	e.set_meta("yielded", true)
	e.team = "neutral"
	e.target = null
	e.state = "idle"
	e.velocity = Vector3.ZERO
	e.remove_from_group("fighters")
	e.model.play("crouch", 0.2)
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Dur! Pes ediyorum!", Color(1, 0.9, 0.6))
	var nm = String(e.display_name).split("  ")[0]
	var opts = [{"label": "Öldür", "cb": func():
		if is_instance_valid(e):
			e.set_physics_process(true)
			e.add_to_group("fighters")
			e.team = "enemy"
			e.hp = 1.0
			e.take_hit({"dmg": 99999.0, "attacker": Game.player, "kind": "heavy", "dir": Game.player.face_dir(), "melee": true})}]
	opts.append({"label": "Teslim et (ödül)" if e.has_meta("bingo_id") else "Muhafızlara teslim et", "cb": func():
		if not is_instance_valid(e):
			return
		if e.has_meta("bingo_id"):
			Missions._bingo_killed(e)
		else:
			Progress.add_ryo(100 + int(e.level) * 15)
			Missions._rep(Progress.home(), 5)
			Hud.msg("Kaçak muhafızlara teslim edildi.", Color(0.8, 0.9, 1.0))
		FX.smoke_puff(e.global_position + Vector3.UP, 0.9, 12)
		e.queue_free()})
	opts.append({"label": "Bağışla", "cb": func(): if is_instance_valid(e): spare(e)})
	Hud.dialog(nm, "Beni öldürecek misin? ...Ya da beni o ödül kâğıdı için teslim mi edeceksin?", opts)


## Ad değil unvan mı ("Av-Ninjası", "Konohagakure ANBU", "Kumo Chunin"...): kişi adı yerine geçmesin
static func generic_name(nm: String) -> bool:
	for w in ["Ninjası", "Ninja", "ANBU", "Muhafız", "Jōnin", "Jonin", "Chunin", "Chūnin", "Genin", "Haydut", "Samuray", "gakure"]:
		if nm.contains(w):
			return true
	return false


## Bağışlandı: sana borçlu bir kaçak dost olur (güven 25'ten başlar)
static func spare(e: Enemy) -> void:
	var fs = Friends.all()
	var id = "f%d" % (int(pr().get("friend_seq", 0)) + 1)
	pr()["friend_seq"] = int(pr().get("friend_seq", 0)) + 1
	var nm = String(e.display_name)
	if "»" in nm:
		nm = nm.split("» ")[-1]
	nm = nm.split(" — ")[0].split("  ")[0]
	for pre in ["Kaçak Ninja ", "Kaçak "]:   # unvan değil gerçek ad
		if nm.begins_with(pre):
			nm = nm.substr(pre.length())
	if nm == "" or nm == "Kaçak Ninja" or not " " in nm or RogueBonds.generic_name(nm):
		nm = "%s %s" % [Missions.BB_FAMILY.pick_random(), nm if nm != "" and nm != "Kaçak Ninja" else (ClanWorld.GIVEN_F if String((e.look as Dictionary).get("gender", "m")) == "f" else ClanWorld.GIVEN_M).pick_random()]
	var lk: Dictionary = (e.look as Dictionary).duplicate() if e.look is Dictionary else {}
	lk.erase("age")
	var lair = Missions._lair_site(e.global_position + Vector3(randf_range(-120, 120), 0, randf_range(-120, 120)))
	var m = MOTIVES.pick_random()
	var lm = Game.to_map(lair)
	fs[id] = {"name": nm, "role": "nurse", "ninja": true, "look": Friends._ser(lk), "bond": 25, "village": String(lk.get("village", "konoha")), "party": false,
		"last_talk": 0.0, "element": String(e.element), "clan": String(e.arch.get("clan", "")), "eye": [0, 0], "rank": clampi(int(e.level / 20), 0, 3),
		"family": [], "status": "kaçak", "log": [], "news": "", "title": "Kaçak ninja", "rogue": true, "motive": m[0], "lair": [lm.x, lm.y],
		"loyalty": randi_range(20, 90)}
	if e.has_meta("bingo_id"):
		for be in Missions._bingo()["list"]:
			if int(be["id"]) == int(e.get_meta("bingo_id")):
				be["friend_id"] = id
				be["tracked"] = false
				be["status"] = "spared"   # artık dost: Bingo'dan düşman olarak bir daha doğmaz (eskiden "alive" kalıp yanında ikinci kopyası doğuyordu)
		Missions._bb_spawned.erase(int(e.get_meta("bingo_id")))
	Friends.log_event(fs[id], "Onu öldürebilecekken bağışladın")
	Combat.popup_text(e.global_position + Vector3.UP * 2.4, "Bunu unutmayacağım.", Color(0.8, 1.0, 0.8))
	Hud.banner("BORÇLU KAÇAK", "%s sana hayatını borçlu. Kampı haritada işaretli (İlişkiler)." % nm, Color(0.75, 0.9, 0.7))
	FX.smoke_puff(e.global_position + Vector3.UP, 0.9, 12)
	e.queue_free()


static func motive_of(f: Dictionary) -> Array:
	for m in MOTIVES:
		if m[0] == String(f.get("motive", "")):
			return m
	return MOTIVES[0]


## Kaçak dostun konuşma seçenekleri (Friends._friend_opts içinden)
static func options(id: String) -> Array:
	var f: Dictionary = Friends.all()[id]
	var b = int(f["bond"])
	var now = Time.get_unix_time_from_system()
	var opts = []
	var kt = Kage.kage_name(Progress.home())
	if now - float(f.get("last_meet", 0.0)) >= 900.0:
		opts.append({"label": "Ateşin başına otur, konuş", "cb": func(): campfire(id)})
	if now - float(f.get("last_meal", 0.0)) >= 1200.0:
		opts.append({"label": "Yol hanında sake içelim", "cb": func(): Friends.begin_activity(id, "sake")})
	if Missions.active().is_empty() and now - float(f.get("last_job", 0.0)) >= 1500.0 and b >= 30:
		opts.append({"label": "Ortak bir iş var mı?", "cb": func(): _job_offer(id)})
	if now - float(f.get("last_share", 0.0)) >= 1800.0:
		opts.append({"label": "Ganimetini paylaş (400 Ryō)", "cb": func():
			if int(pr().get("ryo", 0)) < 400:
				Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
				return
			Progress.add_ryo(-400)
			f["last_share"] = Time.get_unix_time_from_system()
			Friends.add_bond(id, 5)
			Hud.dialog(String(f["name"]), "Kaçakken para nefes gibidir. Sağ ol... bunu hatırlayacağım.", [])})
	opts.append({"label": "Neden kaçtın?", "cb": func():
		var m = motive_of(f)
		if b < 40:
			Hud.dialog(String(f["name"]), "Bunu henüz anlatacak kadar sana güvenmiyorum.", [])
		elif b < 70:
			Hud.dialog(String(f["name"]), String(m[1]), [])
			f["motive_known"] = 1
		else:
			Hud.dialog(String(f["name"]), "%s\n\n%s" % [m[1], m[2]], [])
			f["motive_known"] = 2})
	if not Orgs.is_rogue():
		if b >= 85:
			opts.append({"label": "Köye dönmeye ikna et (af)", "cb": func(): _pardon_offer(id)})
		if b >= 70:
			opts.append({"label": "Birlikte kaçalım...", "cb": func():
				Hud.dialog(String(f["name"]), "Ciddi misin? Bandını çizersen geri dönüş yok. %s seni de Bingo Kitabı'na yazdırır." % kt, [
					{"label": "Evet, birlikte gidelim", "cb": func():
						Orgs.defect()
						f["party"] = true
						Friends.log_event(f, "Seninle birlikte köyden kaçtı")
						Hud.banner("BİRLİKTE KAÇIŞ", "%s ile yollarınız artık aynı." % f["name"], Color(1, 0.6, 0.45))},
					{"label": "Vazgeç", "cb": func(): pass}])})
	return opts


## Kamp ateşi başında oturup konuşma (gerçek sahne: ikiniz de oturursunuz, ateş çatırdar, konuşur)
static func campfire(id: String) -> void:
	var f: Dictionary = Friends.all()[id]
	var me = Friends.inst()
	var n: Node = null
	for x in me.get_tree().get_nodes_in_group("talkers"):
		if String(x.get_meta("friend_id", "")) == id:
			n = x
	f["last_meet"] = Time.get_unix_time_from_system()
	var pl = Game.player
	if n and n.model:
		n.wait = 14.0
		n.role = "customer"   # oturur ve arada konuşur (sabit rol; yoksa ayağa kalkıp dolaşıyordu)
		n.eat_mode = true
		n.wander_r = 0.0
		n.model.play("sit", 0.2)
	pl.model.play("sit", 0.2)
	pl.input_locked = 12.0
	var night = Game.world and (Game.world.env.time_of_day < 0.24 or Game.world.env.time_of_day > 0.78)
	var m = motive_of(f)
	var lines = ["Burada kimse bizi bulamaz. Şimdilik.", "Av ninjaları geçen hafta iki tepe ötedeydi. Her gece başka yerde uyuyorum."]
	if int(f["bond"]) >= 40:
		lines.append(String(m[1]))
	else:
		lines.append("Neden yardım ettiğini hâlâ anlamıyorum. Ama... iyi ki etmişsin.")
	lines.append("Yıldızlar güzel değil mi? Köyde onlara hiç bakmazdım." if night else "Gece olunca ateşi söndürmem gerekiyor. Duman uzaktan görünür.")
	for i in lines.size():
		var txt = lines[i]
		me.get_tree().create_timer(0.8 + i * 3.0).timeout.connect(func():
			if is_instance_valid(n):
				n.say(txt, 3.0))
	me.get_tree().create_timer(12.5).timeout.connect(func():
		Friends.add_bond(id, 4 + (2 if night else 0))
		Friends.log_event(f, "Kamp ateşinin başında konuştunuz")
		if is_instance_valid(pl):
			pl.input_locked = 0.0
		# sen de konuşursun
		Hud.dialog(String(f["name"]), "...Sen ne düşünüyorsun? Bana neden yardım ediyorsun?", [
			{"label": "Herkes ikinci bir şansı hak eder.", "cb": func():
				Friends.add_bond(id, 3)
				Hud.dialog(String(f["name"]), "İkinci şans... Kimse bana bunu söylememişti.", [])},
			{"label": "Seni anlıyorum. Ben de bazen kaçmak istiyorum.", "cb": func():
				Friends.add_bond(id, 2)
				Hud.dialog(String(f["name"]), "Kaçmak kolay. Kaçtıktan sonra yaşamak zor. Bunu unutma.", [])},
			{"label": "Yaptığın yanlıştı ama hâlâ düzeltebilirsin.", "cb": func():
				var tough = int(f.get("loyalty", 50)) >= 50
				Friends.add_bond(id, 3 if tough else -2)
				Hud.dialog(String(f["name"]), "...Belki haklısın. Dürüstlüğün için sağ ol." if tough else "Sen de onlardan birisin demek. Vaaz verme bana.", [])},
			{"label": "Henüz bilmiyorum.", "cb": func(): Hud.dialog(String(f["name"]), "Dürüst cevap. Hoşuma gitti.", [])}]))


static func _job_offer(id: String) -> void:
	var f: Dictionary = Friends.all()[id]
	var j = JOBS.pick_random()
	Hud.dialog(String(f["name"]), String(j[2]), [
		{"label": "Varım (%s)" % j[1], "cb": func(): _job(id, String(j[0]))},
		{"label": "Bu sefer olmaz", "cb": func(): Friends.add_bond(id, -2)}])


## Ortak iş: gerçek görev (kaçak dost takımına katılır, iş yerine gidilir)
static func _job(id: String, kind: String) -> void:
	var f: Dictionary = Friends.all()[id]
	f["last_job"] = Time.get_unix_time_from_system()
	var lv = int(pr().get("level", 1))
	var near = Missions._spot(Progress.home(), 500, 1200)
	var hunters = ["kiri", "kumo", "iwa", "suna"].pick_random()
	var base = {"rank": "B", "village": Progress.home(), "giver": String(f["name"]), "hook": "RogueBonds.job_done", "rogue_job": kind, "fid": id}
	var m = {}
	match kind:
		"soygun":
			m = {"title": "Kervan Soygunu", "brief": "Daimyō'nun vergi kervanını %s ile soyacaksın. Bu bir suç." % f["name"],
				"steps": [{"kind": "kill", "at": near, "enemy": "samurai", "ename": "Kervan Muhafızı", "n": 3, "text": "Kervan muhafızlarını etkisiz bırak."}]}
		"kurtar":
			m = {"title": "Zincirdeki Dost", "brief": "%s'in eski dostu bir karakolda tutsak." % f["name"],
				"steps": [{"kind": "kill", "at": near, "enemy": hunters, "ename": "Karakol Muhafızı", "n": 3, "camp": true,
					"hostage": {"id": "rehine", "name": "Tutsak Kaçak", "kind": "hostage"}, "text": "Karakol muhafızlarını yen, tutsağı çöz."}]}
		"avci":
			m = {"title": "Av Gecesi", "brief": "Av ninjaları %s'in izini buldu." % f["name"],
				"steps": [{"kind": "kill", "at": near, "enemy": hunters, "ename": "Av Ninjası", "n": Combat.foe_count(3), "text": "Av ninjalarını püskürt."}]}
		"parsomen":
			m = {"title": "Yasak Parşömen", "brief": "Karakoldaki mühür parşömenini fark edilmeden al.",
				"steps": [{"kind": "goto", "at": Missions._near_spot(near, 70, 90), "r": 10.0, "name": "Karakol yakını", "night": true, "text": "Gece karakolun yakınına git."},
					{"kind": "stealth", "at": near, "enemy": hunters, "ename": "Nöbetçi", "n": 3, "goal": "Mühür Parşömeni", "text": "Fark edilmeden parşömeni al [F]."}]}
	m.merge(base)
	f["party"] = true
	Missions.accept(m)
	Hud.msg("%s seninle geliyor." % f["name"], Color(0.75, 0.9, 0.7))


func job_done(m: Dictionary, ok: bool) -> void:
	var id = String(m.get("fid", ""))
	if not Friends.all().has(id):
		return
	var f: Dictionary = Friends.all()[id]
	f["party"] = false
	if not ok:
		Friends.add_bond(id, -6)
		return
	var lv = int(pr().get("level", 1))
	match String(m.get("rogue_job", "")):
		"soygun":
			Progress.add_ryo(500 + lv * 25)
			Crime.commit(25, "Kervan soygunu", Game.player.global_position)
		"kurtar":
			Crime.commit(20, "Tutsak kaçırma", Game.player.global_position)
		"parsomen":
			Progress.add_xp(120 + lv * 15)
			Crime.commit(12, "Parşömen hırsızlığı", Game.player.global_position)
		"avci":
			Missions._rep(Progress.home(), -5)
	Friends.add_bond(id, 10)
	Friends.log_event(f, "%s işini birlikte yaptınız" % m.get("title", ""))
	Hud.dialog(String(f["name"]), "Seninle iş yapmak... güvenli hissettiriyor. Bunu kimseye söylemem.", [])


## Kurtuluş: Kage af görevi (eski çetesini birlikte dağıtırsanız köye döner)
static func _pardon_offer(id: String) -> void:
	var f: Dictionary = Friends.all()[id]
	var kt = Kage.kage_name(Progress.home())
	Hud.dialog(String(f["name"]), "Geri mi döneyim? ...Beni kabul ederler mi sence?", [
		{"label": "%s ile konuşacağım. Bana güven." % kt, "cb": func():
			var camp = Missions._spot(Progress.home(), 400, 900)
			Missions.accept({"title": "Af: %s" % f["name"], "rank": "A", "village": Progress.home(), "giver": kt, "hook": "RogueBonds.pardon_done", "fid": id,
				"brief": "%s şartını koydu: %s eski çetesini kendi elleriyle dağıtırsa affedilecek." % [kt, f["name"]],
				"steps": [{"kind": "kill", "at": camp, "enemy": "rogue", "ename": "Eski Çete", "n": 3, "camp": true, "text": "Eski çeteyi birlikte dağıtın."}]})
			f["party"] = true},
		{"label": "Daha sonra", "cb": func(): pass}])


func pardon_done(m: Dictionary, ok: bool) -> void:
	var id = String(m.get("fid", ""))
	if not ok or not Friends.all().has(id):
		return
	var f: Dictionary = Friends.all()[id]
	f["rogue"] = false
	f["status"] = ""
	if f.get("look") is Dictionary and String(f["look"].get("band_style", "")) == "slashed":
		f["look"]["band_style"] = "head"   # affedildi: yeni bant (çizik bant kaçak sayılıyor)
	f["party"] = false
	f["village"] = Progress.home()
	f["title"] = "Affedilmiş ninja"
	f.erase("lair")
	for be in Missions._bingo()["list"]:
		if String(be.get("friend_id", "")) == id:
			be["status"] = "pardoned"
	Friends.add_bond(id, 15)
	Friends.log_event(f, "Kage tarafından affedildi, köye döndü")
	Hud.banner("AF", "%s yeniden köyün bir ninjası. Bandını sana gösterdi." % f["name"], Color(0.7, 1.0, 0.75))


## Her saniye (Friends._world_tick): köy yakınında kaçakla görülme, Kage ültimatomu, ihanet
static func tick() -> void:
	if Game.player == null:
		return
	var now = Time.get_unix_time_from_system()
	var pp = Game.player.global_position
	var fl: Dictionary = pr()["flags"]
	var in_vil = Crime._village_at(pp)
	for id in Friends.party_ids():
		var f: Dictionary = Friends.all()[id]
		if not f.get("rogue", false):
			continue
		# köye girmez: kapıda bekler; köye yakın görülürsen devriye fark eder
		if in_vil != "" and not Orgs.is_rogue():
			f["party"] = false
			f["waiting"] = true
			Hud.msg("%s: \"Köye giremem. Seni dışarıda beklerim.\"" % f["name"], Color(0.8, 0.8, 0.7), 5.0)
			if now - float(fl.get("rogue_seen_t", 0.0)) > 600.0:
				fl["rogue_seen_t"] = now
				fl["rogue_seen"] = int(fl.get("rogue_seen", 0)) + 1
				Missions._rep(in_vil, -5)
				if Crime.heat() < Crime.OUTLAW_AT - 5:
					fl["crime_heat"] = Crime.heat() + 8
				Hud.msg("Bir devriye seni bir kaçakla birlikte gördü (−5 itibar).", Color(1, 0.6, 0.45), 5.0)
	# kapıda bekleyen kaçak: köyden çıkınca yine yanına gelir
	if in_vil == "":
		for id in Friends.all():
			var f2: Dictionary = Friends.all()[id]
			if f2.get("waiting", false):
				f2["waiting"] = false
				f2["party"] = true
	# ihanet: güveni düşük kaçak (her ~6 dk bir zar)
	if now - float(fl.get("rogue_life_t", 0.0)) > 360.0:
		fl["rogue_life_t"] = now
		for id in Friends.all():
			var rf0: Dictionary = Friends.all()[id]
			if rf0.get("rogue", false) and String(rf0.get("status", "")) == "kaçak" and int(rf0["bond"]) < 25 and int(rf0.get("loyalty", 50)) < 50 and randf() < 0.12:
				betray(id)
				break
	# Kage ültimatomu: üç kez görüldün
	if int(fl.get("rogue_seen", 0)) >= 3 and in_vil == Progress.home() and Missions.active().is_empty() and not Orgs.is_rogue() and not Game.ui_open:
		var rid = ""
		for id in Friends.all():
			if Friends.all()[id].get("rogue", false) and String(Friends.all()[id].get("status", "")) == "kaçak":
				rid = id
		fl["rogue_seen"] = 0
		if rid != "":
			var rf: Dictionary = Friends.all()[rid]
			var kt = Kage.kage_name(Progress.home())
			Hud.dialog(kt, "Seni %s ile defalarca görmüşler. Bir kaçağı korumak ihanettir. Ya onu bize teslim edersin ya da sen de kaçak sayılırsın." % rf["name"], [
				{"label": "Onu teslim edeceğim", "cb": func():
					rf["status"] = "hapiste"
					rf["party"] = false
					rf["bond"] = -100
					Friends.log_event(rf, "Onu Kage'ye teslim ettin")
					Missions._rep(Progress.home(), 20)
					Hud.banner("TESLİM", "%s ANBU tarafından yakalandı. Sana bakışını unutamıyorsun." % rf["name"], Color(0.8, 0.8, 0.9))},
				{"label": "Asla. (Köyden kaçarsın)", "cb": func():
					Orgs.defect()
					rf["party"] = true
					Hud.banner("KAÇAK", "%s ile birlikte artık sen de bir kaçaksın." % rf["name"], Color(1, 0.5, 0.4))}])


## İhanet (yaşam olayı): güveni düşük kaçak seni av ninjalarına satar
static func betray(id: String) -> void:
	var f: Dictionary = Friends.all()[id]
	f["bond"] = -60
	f["party"] = false
	Friends.log_event(f, "Seni ödül için av ninjalarına sattı")
	Crime.commit(20, "Kaçak yardakçılığı (ihbar edildin)", Game.player.global_position)
	Hud.banner("İHANET", "%s yerini av ninjalarına satmış! Geliyorlar." % f["name"], Color(1, 0.4, 0.35))
	Friends.inst().ambush(id, ["kiri", "kumo", "iwa"].pick_random(), 3, "Av baskını", false)
