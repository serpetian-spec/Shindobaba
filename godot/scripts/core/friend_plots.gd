class_name FriendPlots
extends RefCounted
## Dostların büyük planları: her dostun gizli bir hevesi (Kage olmak, intikam, güç, para, barış...) ve sadakati vardır.
## Zaman zaman biri bir plan kurar; seni de dahil etmek isteyebilir. Seçimlerin: katıl / reddet / ihbar et.
## İyi ve kötü 32 senaryo; sonuçlar gerçek: darbe başarırsa dost Kage olur (başarısızsa ikiniz de kaçak), ihbar edersen tutuklanır,
## dövüş isteyen planlar yakınında gerçek bir çatışma başlatır, ihanet edenler seni satar...

## tür -> sonuç işleyicisi: coup (darbe), kage_bid (seçim kampanyası), fight (birlikte dövüş), crime (suç kazancı),
## donate (bağış/iyilik), defect (birlikte kaçış), diplomacy (barış), spy (casus ifşası), duel (onur düellosu), trap (tuzak: ihanet)
const SCENARIOS := [
	# --- kötü / karanlık
	{"id": "darbe", "kind": "coup", "good": false, "amb": ["kage", "güç"], "title": "Gece Yarısı Darbesi",
		"pitch": "Kage köyü zayıflatıyor. Birkaç jōninle konuştum; bir gece kuleyi alacağız. Yanımda olursan yeni düzende sağ kolum olursun.",
		"join": "Biliyordum! Üç gece sonra, kulenin arka kapısında.", "refuse": "Yazık... Bu konuşma hiç olmadı, anladın mı?"},
	{"id": "konsey_suikast", "kind": "crime", "good": false, "amb": ["güç", "intikam"], "title": "Konsey Suikastı",
		"pitch": "Danışmanlardan biri ailemi yıllar önce harcadı. Bu gece hesabını soracağım. Gözcülük yaparsan payını alırsın.",
		"join": "Sessiz ol, iz bırakma.", "refuse": "Sen de onlar gibisin demek."},
	{"id": "yasak_parsomen", "kind": "crime", "good": false, "amb": ["yasak bilgi", "güç"], "title": "Yasak Parşömen",
		"pitch": "Arşivde mühürlü bir parşömen var. İçinde yasak bir teknik. Birlikte çalarsak ikimiz de öğreniriz.",
		"join": "Yarın gece arşivin bekçisi değişiyor.", "refuse": "Korkak. Ben yalnız da yaparım."},
	{"id": "kacakcilik", "kind": "crime", "good": false, "amb": ["zenginlik"], "title": "Sınır Kaçakçılığı",
		"pitch": "Sınırdan silah geçiriyoruz. Devriye senin tanıdığın; göz yumarsan kesen dolar.", "join": "Akıllı seçim.", "refuse": "Tamam, tamam... unut gitsin."},
	{"id": "birlikte_kac", "kind": "defect", "good": false, "amb": ["özgürlük", "güç"], "title": "Bu Köyden Gidelim",
		"pitch": "Bu köy bize zincir vuruyor. Bandımızı çizip gidelim; dışarıda kendi kaderimizi yazarız. Benimle gel.",
		"join": "Gece yarısı, batı kapısında.", "refuse": "Sen kal o zaman. Ben gidiyorum."},
	{"id": "kage_zehir", "kind": "coup", "good": false, "amb": ["kage"], "title": "Zehirli Çay",
		"pitch": "Kage'nin çayına konacak bir damla... kimse anlamaz. Sonra konsey beni seçer, sen de yanımda olursun.",
		"join": "Tek yapman gereken o gün kulede olmamak.", "refuse": "Bunu duymamış ol."},
	{"id": "cete_lideri", "kind": "crime", "good": false, "amb": ["zenginlik", "güç"], "title": "Yeraltı Çetesi",
		"pitch": "Pazar esnafından haraç toplayan bir çete kuruyorum. Kas lazım, sen olursan kimse karşı çıkamaz.", "join": "Hoş geldin, ortak.", "refuse": "Pişman olacaksın."},
	{"id": "satis", "kind": "spy", "good": false, "amb": ["zenginlik"], "title": "Sırları Satmak",
		"pitch": "Başka bir köy, savunma planlarımıza servet ödüyor. Ben kopyaladım; sen sadece teslim et.", "join": "Buluşma yeri sınırdaki han.", "refuse": "Sus ve unut."},
	{"id": "klan_intikam", "kind": "duel", "good": false, "amb": ["intikam", "klan onuru"], "title": "Kan Davası",
		"pitch": "Rakip klandan biri ağabeyimi düelloda sakat bıraktı. Hesap soracağım; bana arka çık.", "join": "O zaman gidelim.", "refuse": "Kendi davamı kendim görürüm."},
	{"id": "tuzak", "kind": "trap", "good": false, "amb": ["zenginlik", "güç"], "title": "Gizli Hazine",
		"pitch": "Kuzeydeki ormanda eski bir sığınakta hazine buldum. İkimiz gidelim, kimseye söyleme.", "join": "Yalnız gel.", "refuse": "Sen bilirsin."},
	{"id": "kukla", "kind": "coup", "good": false, "amb": ["güç"], "title": "Gölge Kage",
		"pitch": "Yeni Kage'nin danışmanı olacağım ve ipleri ben tutacağım. Konseyde benim için oy topla.", "join": "Oyları sen toplarsın, gerisini ben hallederim.", "refuse": "Görürüz."},
	{"id": "akatsuki_yol", "kind": "defect", "good": false, "amb": ["güç", "yasak bilgi"], "title": "Kızıl Bulutlar",
		"pitch": "Kızıl bulutlu pelerinliler benimle temas kurdu. Güç vaat ediyorlar. Birlikte katılalım.", "join": "Doğru karar.", "refuse": "Bir gün anlayacaksın."},
	{"id": "hapis_kacir", "kind": "crime", "good": false, "amb": ["aile", "intikam"], "title": "Hapishaneden Kaçırma",
		"pitch": "Kardeşimi haksız yere tutukladılar. Bu gece hücreyi açacağım; nöbetçileri sen oyala.", "join": "Teşekkürler... gerçekten.", "refuse": "Demek kardeşim çürüsün, öyle mi?"},
	{"id": "sahte_gorev", "kind": "trap", "good": false, "amb": ["intikam"], "title": "Sahte Görev",
		"pitch": "Gizli bir A-rank görev aldım, iki kişilik. Yanımda sen olmalısın — kimseye söyleme.", "join": "Şehir dışındaki eski köprüde buluşalım.", "refuse": "Peki..."},
	{"id": "bijuu_avi", "kind": "fight", "good": false, "amb": ["güç"], "title": "Canavar Avcıları",
		"pitch": "Bir jinchūriki'nin yerini biliyorum. Onu yakalarsak içindeki güç bizim olur. Benimle gel.", "join": "Hazırlan, sert olacak.", "refuse": "Güçten korkuyorsun."},
	{"id": "rusvet", "kind": "crime", "good": false, "amb": ["zenginlik", "kage"], "title": "Rüşvet Ağı",
		"pitch": "Konseyde oy satın alıyorum. Para taşıyacak güvenilir biri lazım. Payın büyük.", "join": "Sessiz ol.", "refuse": "Sen kaybedersin."},
	# --- iyi / onurlu
	{"id": "kage_kampanya", "kind": "kage_bid", "good": true, "amb": ["kage"], "title": "Kage Adaylığı",
		"pitch": "Kage olmak istiyorum — dürüstçe. Köy halkının güvenini kazanmak için desteğine ihtiyacım var. Benimle köyü dolaşır mısın?",
		"join": "Seninle bu yol daha kolay!", "refuse": "Anlıyorum, belki sonra."},
	{"id": "yetimhane", "kind": "donate", "good": true, "amb": ["aile", "barış"], "title": "Savaş Yetimleri",
		"pitch": "Son savaşta öksüz kalan çocuklar için bir yuva açıyorum. Bağış toplamama yardım eder misin?", "join": "Çocuklar seni hiç unutmayacak.", "refuse": "Olsun, ben yine de deneyeceğim."},
	{"id": "aile_koru", "kind": "fight", "good": true, "amb": ["aile"], "title": "Ailemi Koru",
		"pitch": "Haydutlar ailemin çiftliğini tehdit ediyor. Tek başıma yetmem. Benimle gelir misin?", "join": "Hemen gidelim!", "refuse": "...Tamam. Ben giderim."},
	{"id": "baris_elcisi", "kind": "diplomacy", "good": true, "amb": ["barış"], "title": "Barış Elçisi",
		"pitch": "Komşu köyle aramız bozuk. Gizlice bir barış görüşmesi ayarladım. Yanımda güvendiğim biri olsun istiyorum.", "join": "Birlikte savaşı önleyebiliriz.", "refuse": "Yalnız gitmek riskli ama... peki."},
	{"id": "casus_ifsa", "kind": "spy", "good": true, "amb": ["klan onuru", "barış"], "title": "Köydeki Casus",
		"pitch": "Köyümüzde başka bir köyün casusu var, eminim. Onu birlikte yakalayalım.", "join": "Gece pazar meydanında iz sürelim.", "refuse": "Tek başıma bakarım o zaman."},
	{"id": "hoca_ol", "kind": "donate", "good": true, "amb": ["aile", "barış"], "title": "Akademiye Hoca",
		"pitch": "Akademide yeni nesli eğitmek istiyorum. Malzeme için biraz destek lazım. Katkın olur mu?", "join": "Gelecek nesil sana teşekkür edecek.", "refuse": "Anlıyorum."},
	{"id": "kayip_baba", "kind": "fight", "good": true, "amb": ["aile"], "title": "Kayıp Baba",
		"pitch": "Babam bir görevden dönmedi, ama haydutların elinde olduğunu duydum. Onu kurtarmama yardım et.", "join": "Teşekkürler... gidelim!", "refuse": "Tamam..."},
	{"id": "klan_onur", "kind": "duel", "good": true, "amb": ["klan onuru"], "title": "Klan Onuru Düellosu",
		"pitch": "Klanımın onuru için resmi bir düelloya çıkacağım. Şahidim olur musun? Kaybedersem beni sen götür.", "join": "Seninle cesaretim artıyor.", "refuse": "Peki."},
	{"id": "salgin", "kind": "donate", "good": true, "amb": ["barış", "aile"], "title": "Salgın",
		"pitch": "Bir mezrada salgın var. İlaç almak için para lazım. Yardım eder misin?", "join": "Hayat kurtardın.", "refuse": "Başka yol bulurum."},
	{"id": "eski_dost_kurtar", "kind": "fight", "good": true, "amb": ["intikam", "aile"], "title": "Esir Dost",
		"pitch": "Takım arkadaşım bir kaçak çetesinin elinde. Onu kurtarmak için birlikte gidelim.", "join": "Hemen!", "refuse": "...Peki."},
	{"id": "yeni_teknik", "kind": "donate", "good": true, "amb": ["güç"], "title": "Yeni Teknik Denemesi",
		"pitch": "Yeni bir teknik geliştiriyorum. Antrenman alanı kiralamak için katkın olursa sana da öğretirim.", "join": "Harika, birlikte çalışalım!", "refuse": "Tamam."},
	{"id": "kage_koruma", "kind": "spy", "good": true, "amb": ["kage", "barış"], "title": "Darbe İhbarı",
		"pitch": "Bazı jōninlerin Kage'ye darbe planladığını duydum. Kanıt topluyorum. Bana yardım eder misin?", "join": "Köyü birlikte koruyacağız.", "refuse": "Kendim hallederim."},
	{"id": "sinir_koru", "kind": "fight", "good": true, "amb": ["barış", "klan onuru"], "title": "Sınır Karakolu",
		"pitch": "Sınır karakoluna saldırı bekleniyor. Gönüllü olarak gidiyorum. Benimle gelir misin?", "join": "Omuz omuza!", "refuse": "Anlıyorum."},
	{"id": "bayram", "kind": "donate", "good": true, "amb": ["barış", "aile"], "title": "Köy Şenliği",
		"pitch": "Köyde bir şenlik düzenliyorum! Fener ve yemek için biraz katkı yapar mısın?", "join": "Herkes çok mutlu olacak!", "refuse": "Olsun!"},
	{"id": "kaçak_yakala", "kind": "fight", "good": true, "amb": ["intikam", "klan onuru"], "title": "Kaçak Avı",
		"pitch": "Klanımızdan biri köyden kaçıp masumları öldürüyor. Onu yakalamak boynumun borcu. Gel benimle.", "join": "Gidelim.", "refuse": "Peki."},
	{"id": "kage_secim_destek", "kind": "kage_bid", "good": true, "amb": ["kage", "barış"], "title": "Halkın Adayı",
		"pitch": "Köy halkı beni Kage adayı göstermek istiyor. Senin gibi tanınan biri yanımda olursa kazanırım.", "join": "Birlikte!", "refuse": "Anlıyorum."},
]
const AMBITIONS := ["kage", "güç", "intikam", "zenginlik", "aile", "barış", "yasak bilgi", "klan onuru", "özgürlük"]


static func pr() -> Dictionary:
	return Game.profile


## Dost için uygun bir senaryo: kötü senaryolar düşük sadakatli/karanlık hevesli dostlara, iyiler sadıklara
static func pick(f: Dictionary) -> Dictionary:
	var loyal = int(f.get("loyalty", 50))
	var amb = String(f.get("ambition", ""))
	var c = SCENARIOS.filter(func(s): return amb in s["amb"] and (s["good"] == (loyal >= 45)))
	if c.is_empty():
		c = SCENARIOS.filter(func(s): return s["good"] == (loyal >= 45))
	return c.pick_random() if not c.is_empty() else {}


## Plan başlar: dostun seninle konuşmak istediği bir şey olur (yanına gidip konuşunca seçenek çıkar)
static func start(id: String) -> void:
	var f: Dictionary = Friends.all()[id]
	var sc = pick(f)
	if sc.is_empty():
		return
	f["plot"] = {"id": sc["id"], "stage": "pitch", "t": Time.get_unix_time_from_system()}
	Friends.log_event(f, "Bir plan kuruyor...")
	Hud.msg("%s seninle gizlice konuşmak istiyor. (Tab > İlişkiler > Haritada göster)" % f["name"], Color(0.95, 0.85, 0.55), 6.0)


static func scenario(id: String) -> Dictionary:
	for s in SCENARIOS:
		if s["id"] == id:
			return s
	return {}


## Konuşma seçeneği: plan anlatılır, katıl / reddet / ihbar et
static func option(fid: String) -> Array:
	var f: Dictionary = Friends.all().get(fid, {})
	var p: Dictionary = f.get("plot", {})
	if p.is_empty() or String(p.get("stage", "")) != "pitch":
		return []
	var sc = scenario(String(p["id"]))
	if sc.is_empty():
		return []
	return [{"label": "★ \"Seninle konuşmam gereken bir şey var...\"", "cb": func():
		var ch = [{"label": "Katılıyorum", "cb": func(): _resolve(fid, "join")},
			{"label": "Hayır, bana göre değil", "cb": func(): _resolve(fid, "refuse")}]
		if not sc["good"]:
			ch.append({"label": "(Bunu Kage'ye ihbar et)", "cb": func(): _resolve(fid, "report")})
		Hud.dialog("%s — %s" % [f["name"], sc["title"]], String(sc["pitch"]), ch)}]


static func _resolve(fid: String, choice: String) -> void:
	var f: Dictionary = Friends.all()[fid]
	var sc = scenario(String(f["plot"]["id"]))
	f["plot"]["stage"] = "done"
	var name = String(f["name"])
	var vid = String(f.get("village", Progress.home()))
	match choice:
		"refuse":
			Hud.dialog(name, String(sc["refuse"]), [])
			Friends.add_bond(fid, -6 if not sc["good"] else -2)
			# reddedilen karanlık plan bazen yine de olur (onsuz)
			if not sc["good"] and randf() < 0.5:
				_outcome(fid, sc, false)
		"report":
			Friends.add_bond(fid, -100, true)
			f["status"] = "hapiste"
			f["party"] = false
			Friends.log_event(f, "İhbarın yüzünden tutuklandı (%s)" % sc["title"])
			Missions._rep(vid, 30)
			Progress.add_ryo(500 + int(pr().get("level", 1)) * 30)
			Hud.banner("İHBAR EDİLDİ", "%s planını Kage'ye bildirdin. Tutuklandı; köy sana minnettar (+30 itibar)." % name, Color(0.7, 0.85, 1.0))
		"join":
			Hud.dialog(name, String(sc["join"]), [])
			Friends.add_bond(fid, 8 if sc["good"] else 5)
			Friends.log_event(f, "Planına katıldın: %s" % sc["title"])
			_outcome(fid, sc, true)


## Sonuç (bazıları anında, dövüş isteyenler yakınında çatışma başlatır)
static func _outcome(fid: String, sc: Dictionary, joined: bool) -> void:
	var f: Dictionary = Friends.all()[fid]
	var name = String(f["name"])
	var vid = String(f.get("village", Progress.home()))
	var lv = int(pr().get("level", 1))
	match String(sc["kind"]):
		"coup":
			var ok = randf() < (0.55 if joined else 0.3) + int(f.get("rank", 0)) * 0.08
			if ok:
				f["rank"] = 3
				Kage.force_successor(vid, fid, "%s bir gece darbesiyle iktidarı aldı" % name)
				if joined:
					Missions._rep(vid, 20)
					Progress.add_ryo(2000 + lv * 80)
			else:
				f["status"] = "kaçak"
				f["party"] = false
				Friends.log_event(f, "Darbe başarısız oldu, kaçtı")
				Hud.banner("DARBE BASTIRILDI", "%s'in darbesi başarısız oldu; köyden kaçtı." % name, Color(1, 0.45, 0.4))
				if joined:
					Hud.msg("Darbeye katıldığın ortaya çıktı!", Color(1, 0.4, 0.35), 5.0)
					Crime.commit(Crime.OUTLAW_AT, "Darbe girişimine katıldın", Game.player.global_position)
		"kage_bid":
			if joined:
				Missions._rep(vid, 10)
				f["kage_bid"] = true
				f["rank"] = maxi(int(f.get("rank", 0)), 3)
				if randf() < 0.5:
					Kage.force_successor(vid, fid, "konsey ve halk %s'i yeni lider seçti" % name)
				else:
					Hud.msg("%s'in adaylığı güç kazandı; bir sonraki seçimde büyük şansı var." % name, Color(0.6, 1.0, 0.75), 5.0)
		"crime":
			if joined:
				Progress.add_ryo(800 + lv * 60)
				if randf() < 0.45:
					Crime.commit(45, "%s ile birlikte suça karıştın" % name, Game.player.global_position)
				else:
					Hud.msg("İş temiz bitti. Kimse fark etmedi... şimdilik.", Color(0.8, 0.8, 0.6))
			elif randf() < 0.4:
				f["status"] = "hapiste"
				Friends.log_event(f, "Yakalandı: %s" % sc["title"])
				Hud.msg("%s, '%s' yüzünden yakalanıp tutuklandı." % [name, sc["title"]], Color(0.9, 0.7, 0.5), 5.0)
		"defect":
			if joined:
				Friends.log_event(f, "Seninle birlikte köyden kaçtı")
				f["status"] = "kaçak"
				Orgs.defect()
				f["party"] = true
			else:
				var ff = Friends.inst()
				if ff:
					ff._defect(fid)
		"donate":
			if joined:
				var cost = 300 + lv * 20
				if int(pr().get("ryo", 0)) >= cost:
					Progress.add_ryo(-cost)
					Missions._rep(vid, 15)
					Friends.add_bond(fid, 6)
					Hud.msg("%d Ryō bağışladın (+15 itibar)." % cost, Color(0.6, 1.0, 0.75))
				else:
					Hud.msg("Yeterli paran yoktu ama zamanınla yardım ettin (+5 itibar).", Color(0.8, 0.9, 0.7))
					Missions._rep(vid, 5)
		"diplomacy":
			var others = Kage.GREAT.filter(func(x): return x != Progress.home())
			var o = String(others.pick_random())
			Kage.change_relation(o, 25 if joined else 8)
			Hud.msg("%s ile %s arasında yumuşama oldu." % [Game.village(Progress.home()).get("name", ""), Game.village(o).get("name", o)], Color(0.6, 0.9, 1.0), 5.0)
		"spy":
			if sc["good"]:
				var ff = Friends.inst()
				if joined and ff:
					ff.ambush(fid, "rogue", 3, "Köy Casusu", true)
			elif joined:
				Progress.add_ryo(1500 + lv * 50)
				Kage.change_relation(Kage.GREAT.filter(func(x): return x != Progress.home()).pick_random(), -10)
				Crime.commit(40, "Köyün sırlarını sattın", Game.player.global_position)
		"fight", "duel":
			var ff = Friends.inst()
			if joined and ff:
				ff.ambush(fid, "bandit" if sc["good"] else "rogue", 3 if String(sc["kind"]) == "fight" else 1, sc["title"], true)
		"trap":
			# tuzak: dost seni ıssız bir yere çağırıp üstüne çökmek istiyordu
			var ff = Friends.inst()
			if joined and ff:
				Hud.msg("Bir şeyler ters gidiyor...", Color(1, 0.5, 0.45))
				ff.betray_attack(fid)
