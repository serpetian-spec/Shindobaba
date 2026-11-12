class_name MissionGen
extends RefCounted
## Rastgele görev üreteci: MissionLocal ile aynı kalıp biçiminde (Missions._from_spec adımlara çevirir) her panoda
## farklı işveren, hedef, eşya, düşman ve metinle görevler üretir. Kalıplar: collect, defend, camp, escort, rescue,
## patrol, duel, investigate, chase, stealth. Son görülen başlıklar (profil "mis_recent") tekrar edilmez.

const FIRST_M := ["Takeshi", "Jiro", "Kenji", "Haruto", "Daisuke", "Ryo", "Shota", "Yuto", "Kaito", "Isamu", "Tetsuo", "Goro", "Hideo", "Masaru", "Noboru", "Akio", "Benji", "Shin", "Toru", "Yasu"]
const FIRST_F := ["Aiko", "Emi", "Haruka", "Kaori", "Mika", "Nanami", "Rina", "Sakiko", "Tomoe", "Yumi", "Chiyo", "Fumiko", "Hoshi", "Kiku", "Natsu", "Ume", "Midori", "Sachi", "Akane", "Rei"]
const JOBS := ["Çiftçi", "Balıkçı", "Tüccar", "Demirci", "Çömlekçi", "Han Sahibi", "Değirmenci", "Ormancı", "Rahip", "Şifacı", "Terzi", "Aşçı", "Yaşlı Bilge", "Kâtip", "Marangoz", "Arıcı", "Çay Ustası", "Köprü Bekçisi", "Seyyar Satıcı", "Muhtar"]
const BANDITS := ["Kızıl Bez Çetesi", "Kara Tilki Yağmacıları", "Demir Diş Haydutları", "Kırık Kılıç Çetesi", "Gece Kargaları", "Tuz Yolu Haydutları", "Sarı Toz Çetesi", "Kemik Maskeliler", "Dağ Kurtları", "Paslı Zincir Çetesi"]
const ROGUES := ["Kaçak Chūnin", "Kiralık Ninja", "Sahte Rahip", "Zehir Ustası", "Çapulcu Ninja", "Paralı Kılıççı", "Mühür Hırsızı", "Gölge Tüccarı"]
const BOSS_T := ["Tek Göz", "Kızıl Pençe", "Yaşlı Kurt", "Demir Yumruk", "Sessiz", "Yılan Dil", "Kara Kuzgun", "Altın Diş", "Kırık Burun", "Fırtına"]
const PLACES := ["değirmen", "eski köprü", "dağ geçidi", "orman tapınağı", "terk edilmiş maden", "nehir kıyısı", "pirinç tarlası", "eski kale", "bambu korusu", "han"]
const COLLECT := [
	["Şifalı Otlar", "şifalı ot", "Hastanede ilaç stoku bitti. Ormandan şifalı ot getir."],
	["Kayıp Mektuplar", "mektup", "Postacının çantası fırtınada yırtıldı, mektuplar etrafa saçıldı. Hepsini topla."],
	["Dağılmış Kargo", "kargo sandığı", "Devrilen bir arabanın yükü yamaca saçıldı. Sandıkları topla."],
	["Yabani Mantar", "yabani mantar", "Han sahibinin akşam yemeği için yabani mantar lazım. Zehirlileri karıştırma."],
	["Yabani Bal", "bal peteği", "Arıcının kovanları rüzgârda devrildi, petekler ormana dağıldı."],
	["Nehir Taşları", "yassı nehir taşı", "Tapınak bahçesi için nehirden yassı taşlar gerek."],
	["Kaçan Tavuklar", "tavuk", "Kümes kapısı açık kalmış, tavuklar her yere dağıldı!"],
	["Eski Mühür Kâğıtları", "mühür kâğıdı", "Eski bir savaş alanında hâlâ aktif mühür kâğıtları var. Toplayıp tapınağa götür."],
	["Kuş Yumurtaları", "nadir kuş yumurtası", "Bir bilgin nadir kuşların yumurtalarını inceliyor. Yuvaları bozmadan topla."],
	["Kayıp Oyuncaklar", "tahta oyuncak", "Çocuklar oynarken tahta oyuncaklarını ormana kaybetti."],
	["Kâğıt Fenerler", "kâğıt fener", "Festival fenerleri rüzgârla uçup gitti. Akşama kadar topla."],
	["Çay Yaprakları", "çay yaprağı", "Çay ustası dağ yamacındaki yabani çay yapraklarını istiyor."],
	["Kayıp Kunai", "eski kunai", "Eski bir antrenman alanında paslı kunailer toplanacak; çocuklar yaralanmasın."],
	["Odun Toplama", "kuru odun", "Kış yaklaşıyor; yaşlıların evi için kuru odun lazım."],
	["Balık Ağları", "balık ağı", "Fırtına balıkçı ağlarını kıyıya savurdu. Topla, onarılacak."],
]
const DEFEND := [
	["Çiftlik Baskını", "Gece çiftliğe %s baskın yapıyor. Hasadı koru."],
	["Pazar Kavgası", "Pazarda %s kabadayılık yapıp tezgâhları deviriyor. Düzeni sağla."],
	["Köprü Savunması", "Köyü kasabaya bağlayan köprüyü %s ele geçirmek istiyor."],
	["Değirmen Kuşatması", "Değirmenin un stoğunu %s yağmalamaya geliyor."],
	["Han Baskını", "Yol üstündeki hana %s dadandı; yolcular tehlikede."],
	["Tapınak Muhafızlığı", "Tapınağın kutsal emanetlerine %s göz koydu. Gece nöbet tut."],
	["Hasat Şenliği", "Hasat şenliği sırasında %s kargaşa çıkarmayı planlıyor."],
	["Maden Girişi", "Madencilerin girişini %s tuttu, içeride işçiler mahsur."],
	["Liman Rıhtımı", "Rıhtımdaki yük gemilerine %s saldırmaya hazırlanıyor."],
]
const CAMP := [
	["Yol Kesiciler", "Ticaret yolunda %s yolcuları soyuyor. Kamplarını dağıt."],
	["Kaçak Madenciler", "%s dağdaki madeni izinsiz kazıyor, köyün suyunu zehirliyor."],
	["Sahte Sikke Atölyesi", "%s sahte ryō basıp pazarlara sürüyor. Atölyelerini bas."],
	["Kaçak Silah Deposu", "%s yasak silahları bir kampta biriktiriyor."],
	["Yağmacı Kampı", "Komşu köyleri yağmalayan %s ormanda kamp kurmuş."],
	["Kaçakçı Kampı", "Sınırdan kaçak mal geçiren %s ormanda saklanıyor."],
	["Fidyeciler", "%s tüccarları kaçırıp fidye istiyor. Kampı dağıt, bir daha cesaret edemesinler."],
	["Eski Kale Yağmacıları", "Terk edilmiş kaleye %s yerleşti ve çevreye korku salıyor."],
	["Ormandaki Yangıncılar", "%s orman yakıp toprağı ucuza kapatıyor."],
]
const ESCORT := [
	["Tüccar Kervanı", "Tüccar %s mallarını komşu kasabaya taşıyor. Yolda haydutlar var.", "Mallarım değerli, gözünü dört aç.", "Sağ salim geldik! Payını hak ettin."],
	["Gezgin Hekim", "Gezgin hekim %s salgın olan köye ilaç götürüyor.", "İlaçlar zamanında yetişmezse çok kişi ölür.", "Zamanında yetiştik. Hastalar sana dua edecek."],
	["Gelin Alayı", "%s komşu kasabadaki düğününe gidiyor; kıskanç bir talip haydut tuttu.", "Bu yolculuk hayatımın en önemli günü...", "Düğünüme sen de gel, olur mu?"],
	["Yaşlı Rahip", "Yaşlı rahip %s kutsal bir parşömeni tapınağa götürüyor.", "Bu parşömen yüz yıldır korunuyor.", "Parşömen yerine ulaştı. Tanrılar seni korusun."],
	["Âlim ve Kitapları", "Âlim %s nadir kitaplarını kütüphaneye taşıyor.", "Kitaplarım altından değerli, dikkat et!", "Bilgi güvende. Teşekkürler genç ninja."],
	["Gezgin Tiyatro", "Gezgin tiyatro topluluğu ve lideri %s bir sonraki kasabaya gidiyor.", "Sahne kostümlerimiz arabada; onlara dokunmasınlar!", "Bu akşamki gösteriye ön sıradan bilet senin!"],
	["Köprü Ustası", "Köprü ustası %s yıkılan köprüyü onarmaya gidiyor; birileri onarılmasını istemiyor.", "Köprü onarılırsa birileri haraç kaybedecek.", "Köprü yeniden ayağa kalkacak. Senin sayende."],
	["Elçi Mektubu", "Daimyō elçisi %s gizli bir mektup taşıyor.", "Mektubun içeriğini sorma. Sadece beni oraya ulaştır.", "Görev tamam. Daimyō bu hizmeti unutmaz."],
]
const RESCUE := [
	# başlık, özet, köyde bekleyen yakını, kavuşunca rehinenin sözü, yakınının sözü, teşekkür
	["Kaçırılan Çırak", "Demircinin çırağı %s haydutlarca kaçırıldı.", "Demirci", "Usta!", "Evlat! Örsün başı sensiz bomboştu...", "Çırağımı sağ getirdin. Körüğü yeniden yakarız artık. Al, hak ettin."],
	["Kayıp Avcı", "Avcı %s günlerdir dönmedi; bir kampta esir tutulduğu söyleniyor.", "Avcının Eşi", "Döndüm, buradayım!", "Günlerdir kapıda bekliyorum... Döndün!", "Onu bana geri getirdin. Evde ne varsa topladım, lütfen al."],
	["Rehin Tüccar", "Tüccar %s fidye için kaçırıldı.", "Tüccarın Kardeşi", "Kardeşim!", "Fidyeyi toplayamamıştık... Yaşıyorsun!", "Fidyeye ayırdığımız para senin hakkın. Al."],
	["Kaçırılan Şifacı", "Köyün tek şifacısı %s yaralı haydutları tedavi etsin diye kaçırıldı.", "Muhtar", "Muhtar, hastalar nasıl?", "Şifacımız döndü! Hastalar seni bekliyor.", "Köy şifacısız kalsaydı kışı çıkaramazdık. Herkes bir şeyler koydu, al."],
	["Kayıp Öğrenci", "Akademi öğrencisi %s gizli antrenmana çıktı ve bir çeteye yakalandı.", "Akademi Hocası", "Sensei!", "Seni afacan! Bir daha izinsiz çıkmak yok... İyi ki sağsın.", "Öğrencimi kurtardın. Bu, hocaların kendi arasında topladığı. Kabul et."],
	["Esir Muhabir", "Gezgin muhabir %s bir çetenin sırlarını öğrenince yakalandı.", "Matbaacı", "Usta, haberi kaçırmadım!", "Haber de neymiş, canın sağ ya!", "Yarınki baskının ilk satırı senin adın olacak. Bu da emeğinin karşılığı."],
]
const CHASE := [
	["Yankesici", "Pazarda bir yankesici %s'in kesesini çaldı!", "Yankesici"],
	["Kaçan Mahkûm", "Hücreden bir mahkûm kaçtı, şehrin içinden geçiyor!", "Kaçak Mahkûm"],
	["Çalınan Kolye", "%s'in aile yadigârı kolyeyi bir hırsız kaptı!", "Kolye Hırsızı"],
	["Kaçak Kurye", "Gizli mesaj taşıyan bir kurye köyden kaçmaya çalışıyor.", "Şüpheli Kurye"],
	["Ramen Hırsızı", "Ramen dükkânının bütün tarif defterini biri kapıp kaçtı!", "Tarif Hırsızı"],
]
const STEALTH := [
	["Çalınan Parşömen", "Köyden çalınan eğitim parşömeni %s kampında. Fark edilmeden geri al.", "parşömen"],
	["Gizli Defter", "%s kara para defterini kampında saklıyor. Defteri al.", "kara defter"],
	["Mühür Anahtarı", "%s eski bir mühür anahtarını ele geçirdi; açarlarsa felaket olur.", "mühür anahtarı"],
	["Sahte Belgeler", "%s sahte geçiş belgeleri üretiyor; örneklerini kanıt olarak getir.", "sahte belge"],
	["Kayıp Harita", "Köyün gizli geçitlerini gösteren harita %s eline geçti.", "gizli harita"],
]
const DUEL := [
	["Dojo Meydan Okuması", "Bir dojonun ustası köyün gençlerine meydan okuyor."],
	["Gezgin Rōnin", "Efendisiz bir samuray köy meydanında rakip arıyor."],
	["Kumarhane Fedaisi", "Kumarhanenin fedaisi borçluları dövüyor; onu yen ki rahat bıraksın."],
	["Eski Rakip", "Akademiden eski bir rakip yeteneğini kanıtlamak istiyor."],
	["Turnuva Finali", "Kasaba turnuvasının finalinde karşına güçlü biri çıktı."],
]
const INVEST := [
	["Kayıp Pirinç Çuvalları", "Ambardan her gece pirinç çuvalları kayboluyor.", "pirinç izi",
		["Bekçi uyuyakalmıştı ama ayak izleri dağa doğru gidiyordu.", "Gece çalılıklarda fısıltılar duydum, birileri ambarı gözlüyordu."],
		[["Dağdaki haydutlar", true], ["Ambar sahibinin kendisi", false], ["Komşu çiftçi", false]]],
	["Zehirlenen Kuyu", "Köyün kuyusu zehirlendi; birçok kişi hasta.", "zehir şişesi",
		["Kuyu başında tanımadığım bir adam gördüm, kapüşonluydu.", "Kuyunun yanında boş bir şişe vardı, mor bir sıvı kokuyordu."],
		[["Zehir satıcısı çete", true], ["Kuyuyu kazan usta", false], ["Gezgin rahip", false]]],
	["Kundaklanan Ahır", "Bir ahır gece yakıldı; atlar zor kurtarıldı.", "yanık bez",
		["Yangından önce at sesleri ve gülüşmeler duydum.", "Sabah yolda yağ kokan bezler buldum."],
		[["Haraç isteyen çete", true], ["Ahır sahibinin oğlu", false], ["Yıldırım", false]]],
	["Kaybolan Yolcular", "Hana gelen yolcular bir daha görünmüyor.", "yırtık yolcu çantası",
		["Gece arabalar handan sessizce çıkıyordu.", "Hancının yeni yamakları çok sert bakışlı."],
		[["Hanı paravan kullanan çete", true], ["Kurtlar", false], ["Yolcular kendi isteğiyle gitti", false]]],
]


static func _rand(a: Array, rng: RandomNumberGenerator):
	return a[rng.randi() % a.size()]


static func _person(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [_rand(JOBS, rng), _rand(FIRST_M if rng.randf() < 0.5 else FIRST_F, rng)]


static func _name(rng: RandomNumberGenerator) -> String:
	return _rand(FIRST_M if rng.randf() < 0.5 else FIRST_F, rng)


## Rütbeye uygun düşman türü ve adı
static func _foe(r: String, here: String, rng: RandomNumberGenerator) -> Array:
	match r:
		"D":
			return ["bandit", "Kabadayı"]
		"C":
			return ["bandit", _rand(BANDITS, rng)] if rng.randf() < 0.7 else ["rogue", _rand(ROGUES, rng)]
		"B":
			if rng.randf() < 0.35:
				var fv = _rand(["oto", "kumo", "kiri", "iwa", "suna"].filter(func(x): return x != here), rng)
				return [fv, "%s Ajanı" % {"oto": "Ses", "kumo": "Bulut", "kiri": "Sis", "iwa": "Taş", "suna": "Kum"}[fv]]
			return ["rogue", _rand(ROGUES, rng)] if rng.randf() < 0.6 else ["bandit", _rand(BANDITS, rng)]
	if rng.randf() < 0.3:
		return ["samurai", "Paralı Samuray"]
	return ["rogue", _rand(ROGUES, rng)]


## Bir köy panosu için n görev kalıbı (MissionLocal biçimi)
static func specs(here: String, ranks: Array, n: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var recent: Array = Game.profile.get("mis_recent", [])
	var out = []
	var tries = 0
	while out.size() < n and tries < n * 8:
		tries += 1
		var r: String = _rand(ranks, rng)
		var sp = _one(here, r, rng)
		if sp.is_empty() or sp["t"] in recent or out.any(func(x): return x["t"] == sp["t"]):
			continue
		out.append(sp)
	return out


static func _one(here: String, r: String, rng: RandomNumberGenerator) -> Dictionary:
	var pats = {"D": ["collect", "collect", "defend", "chase"], "C": ["collect", "defend", "camp", "escort", "rescue", "patrol", "chase", "investigate", "duel"],
		"B": ["camp", "escort", "rescue", "stealth", "investigate", "defend", "duel", "patrol"], "A": ["camp", "escort", "stealth", "defend", "duel", "rescue"],
		"S": ["camp", "stealth"]}[r]
	var p: String = _rand(pats, rng)
	var foe = _foe(r, here, rng)
	var giver = _person(rng)
	var sp = {"r": r, "p": p, "e": foe[0], "en": foe[1], "g": giver}
	var gang: String = foe[1]
	match p:
		"collect":
			var c: Array = _rand(COLLECT, rng)
			sp.merge({"t": c[0], "b": c[2], "item": c[1], "n": 1 if r == "D" else rng.randi_range(4, 8),   # D-rank: tek iş, tek seferde biter
				"s1": "%s Biraz acele edersen iyi olur." % c[2], "s2": "Hepsini getirdin mi? Harika, eline sağlık!"})
			if r != "D":
				sp["ge"] = foe[0]
				sp["gn"] = 2 + (1 if r == "B" else 0)
				sp["b"] += " Bölgede %s dolaşıyor, dikkatli ol." % gang
		"defend":
			var d: Array = _rand(DEFEND, rng)
			var w = {"D": [2], "C": [3, 3], "B": [3, 4, 4], "A": [4, 4, 5], "S": [5, 5, 6]}[r]
			sp.merge({"t": d[0], "b": d[1] % gang, "w": w, "s1": "%s Lütfen yardım et!" % (d[1] % gang), "s2": "Gittiler! Sen olmasan her şey biterdi."})
		"camp":
			var cp: Array = _rand(CAMP, rng)
			sp.merge({"t": cp[0], "b": cp[1] % gang, "n": {"C": 4, "B": 5, "A": 6, "S": 7}.get(r, 4),
				"s1": "Kampları %s yakınında olmalı." % _rand(PLACES, rng), "s2": "Bir daha buralara uğrayamazlar. Teşekkürler!"})
			if r in ["B", "A", "S"]:
				sp["boss"] = "%s %s" % [_rand(BOSS_T, rng), gang.split(" ")[0]]
		"escort":
			var es: Array = _rand(ESCORT, rng)
			var who = _name(rng)
			sp.merge({"t": es[0], "b": es[1] % who, "npc": who, "s1": es[2], "s2": es[3]})
		"rescue":
			var rs: Array = _rand(RESCUE, rng)
			var h = _name(rng)
			sp.merge({"t": rs[0], "b": rs[1] % h + " Esir tutulduğu kamp %s yakınında." % _rand(PLACES, rng), "hostage": h, "kin": "%s %s" % [rs[2], _name(rng)], "k1": rs[3], "k2": rs[4], "s2": rs[5], "n": {"C": 3, "B": 4, "A": 5}.get(r, 4),
				"s": "Geldin! İpleri çöz, buradan gidelim!"})
		"patrol":
			sp.merge({"t": "%s Devriyesi" % String(_rand(PLACES, rng)).capitalize(), "b": "Son günlerde %s çevresinde şüpheli izler görüldü. Devriye rotasını yürü." % _rand(PLACES, rng),
				"n": 2 + (1 if r == "B" else 0)})
		"chase":
			var ch: Array = _rand(CHASE, rng)
			sp.merge({"t": ch[0], "b": ch[1] % _name(rng) if "%s" in ch[1] else ch[1], "en": ch[2]})
		"stealth":
			var st: Array = _rand(STEALTH, rng)
			sp.merge({"t": st[0], "b": st[1] % gang, "item": st[2]})
		"duel":
			var du: Array = _rand(DUEL, rng)
			var opp = "%s %s" % [_rand(["Usta", "Rōnin", "Fedai", "Genç", "Kılıççı"], rng), _name(rng)]
			sp.merge({"t": du[0], "b": du[1], "g": opp, "en": opp, "e": "samurai" if "Rōnin" in opp or "Kılıççı" in opp else "rogue",
				"hp": {"C": 450.0, "B": 700.0, "A": 1000.0}.get(r, 700.0), "lv": {"C": 14, "B": 22, "A": 32}.get(r, 22),
				"s1": "Demek meydan okumamı kabul eden sensin. Güzel.", "s2": "Kaybettim... ama iyi dövüştün."})
		"investigate":
			var iv: Array = _rand(INVEST, rng)
			sp.merge({"t": iv[0], "b": iv[1], "g": giver, "w1": _person(rng), "w1s": iv[3][0], "w2": _person(rng), "w2s": iv[3][1], "c": iv[4], "item": iv[2],
				"n": 3 + (1 if r == "B" else 0)})
	return sp


## Alınan görevin başlığını "son görülenler"e ekle (tekrar gelmesin)
static func remember(title: String) -> void:
	var p = Game.profile
	if p.is_empty():
		return
	if not p.has("mis_recent"):
		p["mis_recent"] = []
	var rc: Array = p["mis_recent"]
	rc.append(title)
	while rc.size() > 25:
		rc.pop_front()
