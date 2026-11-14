class_name LegendPaths
extends Node
## Efsane Yolları: kanon ninjaların imza teknikleri, dünyada saklı özgün ustalardan öğrenilir (kanon karakter yok).
## Hikâyeye bağlı değil, isteğe bağlı keşif içeriği:
##   söylenti (seviye gelince) → inini bul (yaklaşınca) → ustanın sınav görevi → yola katıl (pasif bonus + ilk teknik)
##   → teknikleri seviyeye göre ustadan öğren (Ryō; bazıları ayrı görev, karanlık olanlar köy itibarı düşürür).
## Teknik verisi: tools/build_data.py NEW_PATH / PATH_TAG ("path:<id>"), uygulamalar: PathJutsu.
## Profil: profile["paths"][id] = {"s": durum, "q": ""}  durum: 0 bilinmiyor, 1 söylenti, 2 in bulundu, 3 sınavda, 4 yolda

enum {UNKNOWN, RUMOR, FOUND, TRIAL, JOINED}

## Yol mekânlarındaki antrenman noktaları (PathLairs yazar): pid -> {"posts": [..], "weights": [..], "boulder": .., "pushup": ..}
static var drill_spots: Dictionary = {}
## Teknik öğrenme antrenmanları (ustanın gözetiminde, mekânda gerçek iş — tıkla-öğren değil):
## jid -> {"type": "hits"|"laps", "n": hedef, "time": süre (sn, 0 = süresiz), "weights": bacak ağırlıklı mı, "say": ustanın sözü}
const DRILLS := {
	"omote_renge": {"type": "hits", "n": 40, "time": 0.0, "say": "Lotus bedenin sağlamlığıyla başlar. Şu kütüklere kırk kez vur — yumruk da tekme de sayılır!"},
	"ura_renge": {"type": "laps", "n": 3, "time": 0.0, "say": "Ters Lotus kapıları açık tutacak nefes ister. Avlunun çevresinde üç tur koş, durmak yok!"},
	"asakujaku": {"type": "hits", "n": 80, "time": 60.0, "say": "Sabah Tavuskuşu yumruk yağmurudur. Bir dakikada seksen vuruş! Hızın ateş gibi olmalı!"},
	"hirudora": {"type": "laps", "n": 5, "time": 0.0, "weights": true, "say": "Gündüz Kaplanı tek darbede her şeyi toplar. Bacak ağırlıklarını tak ve beş tur koş — ağırlıkla!"},
	# Yılan Yolu: zehir (kanon: yılan ustaları zehre bağışık, yılanlardan zehir toplar)
	"jagei_jubaku": {"type": "collect", "n": 6, "time": 120.0, "item": "zehir kesesi", "say": "Gölge yılanlar zehirden beslenir. İnin çevresindeki ölü yılanlardan altı zehir kesesi topla, iki dakikan var."},
	"hebi_bunshin_no_jutsu": {"type": "survive", "n": 20, "time": 0.0, "say": "Deri değiştiren beden zehre dayanır. Şu mor sisin içinde yirmi saniye dur — kaçarsan baştan."},
	"sen_ei_tajashu": {"type": "survive", "n": 30, "time": 0.0, "say": "Bin yılan kolundan fışkırır; damarların zehri tanımalı. Otuz saniye sisin içinde kal."},
	# Kurbağa Bilgesi Yolu: kurbağa yağı toplama, saç iğnesi talimi, diken kalkanıyla yağan silaha dayanma (savunma tekniği)
	"gamayudan": {"type": "collect", "n": 6, "time": 100.0, "item": "yağ kabağı", "color": Color(0.85, 0.55, 0.15), "say": "Kurbağa yağı ateşin canıdır. Göletin çevresine bıraktığım altı yağ kabağını topla — yüz saniye, devirmeden!"},
	"kebari_senbon": {"type": "hits", "n": 30, "time": 40.0, "say": "Saç, chakrayla sertleşince iğne olur. Şu kuklalara kırk saniyede otuz isabet — saçını savur!"},
	"hari_jizo": {"type": "survive", "n": 20, "time": 0.0, "rain": true, "say": "Diken Bekçisi kaçmaz, karşılar. Çemberin içinde yirmi saniye dur; yağan kunailere saçınla kalkan ol, çemberden çıkma!"},
	# Kâğıt Yolu (Konan): kâğıdı anlamak (figür katlama), dağılan kelebekleri toplamak, kanatla zirveye çıkmak, kâğıt mızrak
	"kami_bunshin": {"type": "tend", "n": 3, "dwell": 4.0, "spots": "mats", "item": "kâğıt figür", "say": "Kâğıt beden, kâğıdı anlamakla başlar. Üç masada birer insan figürü katla — her birine dört saniye chakra ver, elin titremesin."},
	"kami_chocho": {"type": "collect", "n": 8, "time": 60.0, "item": "kelebek", "look": "butterfly", "say": "Kâğıt kelebeklerim rüzgârla dağıldı. Bir dakikada sekizini yakala; seninle uçmayı öğrensinler."},
	"kami_tsubasa": {"type": "tend", "n": 1, "dwell": 2.0, "spots": "top", "item": "zirve", "time": 90.0, "say": "Kanat, yükseklikten korkmayana açılır. Kulenin tepesindeki çiçeğe çık — kat çıkıntılarından zıpla, duvarlardan koş. Doksan saniye."},
	"kami_yari": {"type": "hits", "n": 30, "time": 40.0, "say": "Kâğıt mızrak sertleşmiş chakradır. Şu kuklalara kırk saniyede otuz darbe."},
	# Şifacı Yolu (kanon: Mistik Avuç ölmek üzere olan balıkla öğrenilir — Sakura/Tsunade; zehir çekme yaralı başında; chakra neşteri hassas kesik)
	"shousen": {"type": "tend", "n": 3, "dwell": 4.0, "spots": "basins", "item": "balık", "say": "Mistik Avuç sabır ister. Leğenlerdeki üç balık ölmek üzere; avucunu üstlerinde tutup her birini dört saniye chakranla besle. Kıpırdarsan chakran dağılır, baştan başlarsın."},
	"saikan_chushutsu_no_jutsu": {"type": "tend", "n": 4, "dwell": 3.0, "spots": "patients", "item": "hasta", "say": "Koğuştaki dört yaralı zehirlendi. Her birinin başında dur, zehri chakranla dışarı çek — üç saniye ayrılma."},
	"chakura_no_mesu": {"type": "hits", "n": 30, "time": 45.0, "say": "Chakra neşteri kası keser, deriyi değil. Şu kuklalara kırk beş saniyede otuz hassas vuruş — yalnız yakından."},
	# Silah Yolu (kanon: Tenten'in hedef talimi, parşömene geri mühürlenen silahlar, yağan silahları okuyan göz)
	"buki_kuchiyose": {"type": "throws", "n": 24, "time": 60.0, "min_d": 8.0, "say": "Parşömenden çıkan silah, onu yönlendiren el kadar isabetlidir. Sekiz adım geriden şu dört hedefe bir dakikada yirmi dört atış isabet ettir! Kılıçla vurmak sayılmaz."},
	"tesso_kusari": {"type": "collect", "n": 8, "time": 90.0, "item": "silah", "look": "weapon", "say": "Dünkü talimin silahları avluya saplı kaldı. Sekizini topla ve parşömene geri mühürle — doksan saniye. Bir ninja silahını yerde bırakmaz."},
	# Patlayıcı Kil Yolu (kanon: kil avuçtaki ağızda chakrayla yoğrulur; C1 atılan küçük figürler; kuşun sırtında uçuş; gömülü mayınlar)
	"kibaku_nendo": {"type": "tend", "n": 3, "dwell": 4.0, "spots": "vats", "item": "kil teknesi", "say": "Kil, chakrayla yoğrulmadan çamurdur, hm. Üç teknenin başında dur, her birine dört saniye chakra yedir — elin titrerse baştan."},
	"shi_wan": {"type": "throws", "n": 20, "time": 60.0, "min_d": 8.0, "say": "C1 uzaktan konuşur! Sekiz adım geriden şu dört hedefe bir dakikada yirmi isabet. Yumrukla vurursan sanat olmaz, hm."},
	"kil_ucan_kus": {"type": "tend", "n": 1, "dwell": 2.0, "spots": "top", "item": "zirve", "time": 90.0, "say": "Sanata yukarıdan bakılır. Kaya kulesinin tepesindeki kuşun yanına çık — basamak kayalardan zıpla. Doksan saniye."},
	"bakuha_jirai": {"type": "collect", "n": 8, "time": 90.0, "item": "kil mayını", "color": Color(0.93, 0.9, 0.8), "say": "Dünkü denemeden sekiz mayın alanda gömülü kaldı. Doksan saniyede hepsini topla; nereye gömüldüğünü okuyamayan kendi mayınına basar, hm."},
	# Toprak Kini Yolu (kanon: kara iplik kırbaç gibi savrulur ve bedeni diker; Domu deriyi taş yapar)
	"jiongu_ito_kirbac": {"type": "hits", "n": 30, "time": 45.0, "say": "İplik koldan çıkmadan önce kolun onu tanımalı. Şu kuklalara kırk beş saniyede otuz darbe."},
	"doton_domu": {"type": "survive", "n": 20, "time": 0.0, "rain": true, "say": "Taşlaşan deri kaçmaz. Çemberin içinde yirmi saniye dur; yağan çeliğe bedenini siper et, çemberden çıkma."},
	"jiongu": {"type": "tend", "n": 3, "dwell": 4.0, "spots": "slabs", "item": "beden", "say": "Morgdaki üç bedenin dikişi yarım. Her sedirin başında dur, ipliği chakranla dört saniye yürüt. Elin titrerse dikiş atar, baştan."},
	# Uçan Yıldırım Yolu (kanon: işaretli kunai atılır, işarete ışınlanılır; hız her şeydir)
	"hiraishin_kunai": {"type": "throws", "n": 20, "time": 60.0, "min_d": 8.0, "say": "İşaret, kunainin düştüğü yerdir. Sekiz adım geriden dört hedefe bir dakikada yirmi isabet."},
	"hiraishingiri": {"type": "tend", "n": 8, "dwell": 1.0, "spots": "marks", "item": "işaret", "time": 50.0, "say": "Avluda sekiz işaret var. Elli saniyede her birine dokun, birer saniye chakranı bırak — işareti tanımayan ona sıçrayamaz."},
	"hiraishin_ranbu": {"type": "hits", "n": 40, "time": 40.0, "say": "Işınlanan vurur, vuran ışınlanır. Kırk saniyede kırk darbe — hedef değiştir, durma!"},
	"hiraishin_ni_no_dan": {"type": "survive", "n": 20, "time": 0.0, "rain": true, "say": "İkinci adım, gelen silahın arkasına geçmektir. Yirmi saniye çemberde kal; yağan kunailerin arasından sıyrıl."},
	# Şimşek Kılıcı Yolu (kanon: Chidori hızla koşarak saplanır, kaya yarar; akım bedenden boşalır; iğne ve mızrak olur)
	"raiton_chidori": {"type": "hits", "n": 30, "time": 40.0, "say": "Bin kuş kayayı yarar. Şu yarık kayalara kırk saniyede otuz vuruş!"},
	"chidori_nagashi": {"type": "survive", "n": 20, "time": 0.0, "rain": true, "say": "Akım bedenden dışarı akar, içeri değil. Yirmi saniye çemberde dur; yağan çeliği üstünde taşı."},
	"chidori_senbon": {"type": "throws", "n": 20, "time": 60.0, "min_d": 8.0, "say": "Şimşek iğne olunca uzaktan sokar. Sekiz adım geriden yarık kayalara bir dakikada yirmi isabet."},
	"chidori_eiso": {"type": "laps", "n": 4, "time": 0.0, "say": "Mızrak uzar ama onu taşıyan bacaktır. Kayaların çevresinde dört tur — hızın düşerse şimşek söner."},
	# Jashin Yolu (kanon: ayin kanla çizilen çemberde yapılır; tırpan ve geri çekilen kazık; bedeni ölmez)
	"jashin_sanjin_kama": {"type": "hits", "n": 30, "time": 45.0, "say": "Üç ağız tek savuruşta üç yara açar. Şu kuklalara kırk beş saniyede otuz darbe."},
	"jashin_kazik": {"type": "throws", "n": 20, "time": 60.0, "min_d": 8.0, "say": "Kazık atılır, saplanır, geri çekilir. Sekiz adım geriden bir dakikada yirmi isabet."},
	"jashin_ketsueki": {"type": "collect", "n": 6, "time": 90.0, "item": "kan şişesi", "color": Color(0.75, 0.08, 0.1), "say": "Ayin kansız olmaz. Çevreye bıraktığım altı kan şişesini doksan saniyede getir."},
	"jashin_fumetsu": {"type": "survive", "n": 20, "time": 0.0, "say": "Acı, Jashin-sama'ya duadır. Çemberdeki lanet sisinin içinde yirmi saniye dur — kaçan inançsızdır."},
	# Sekiz Kuyruk Yolu (kanon: Gerçekler Şelalesi'nin önünde meditasyon; lariat; yedi kılıç; ritim)
	"hachibi_murekkep": {"type": "tend", "n": 1, "dwell": 6.0, "spots": "island", "item": "meditasyon", "say": "Şelalenin önündeki adaya otur, yo! Altı saniye kıpırdama; içindeki sesi duymadan mürekkep akmaz, yeah!"},
	"hachibi_lariat": {"type": "hits", "n": 30, "time": 40.0, "say": "Lariat kolun değil, tüm bedenin vuruşu! Kırk saniyede otuz darbe, bakayım ritmine!"},
	"hachibi_yedi_kilic": {"type": "collect", "n": 7, "time": 90.0, "item": "kılıç", "look": "weapon", "say": "Yedi kılıcım talimde etrafa saplandı. Doksan saniyede yedisini de topla, aptal sersem!"},
	"takoashi_bunshin_no_jutsu": {"type": "laps", "n": 3, "time": 0.0, "say": "Kopan kol kaçar, sen de kaç! Kuklaların çevresinde üç tur, ritmi bozma!"},
	# Mürekkep Yolu (kanon: Sai her şeyi parşömene çizer; mürekkep sisi; Kök eğitimi duygusuz ve hassas)
	"sumi_bunshin_no_jutsu": {"type": "tend", "n": 3, "dwell": 4.0, "spots": "desks", "item": "çizim", "say": "Üç masada yarım kalmış üç çizim var. Her birinin başına geç, dört saniye fırçayı chakranla yürüt. Elin titrerse mürekkep dağılır."},
	"choju_giga": {"type": "hits", "n": 30, "time": 45.0, "say": "Çizdiğin canavar senin kadar hızlı vurur. Kırk beş saniyede otuz darbe."},
	"sumigasumi_no_jutsu": {"type": "survive", "n": 20, "time": 0.0, "say": "Mürekkep sisi önce çizeni boğar. Yirmi saniye sisin içinde dur; nefesini tut, duygunu da."},
	"hoki_sumi_ryu": {"type": "collect", "n": 6, "time": 90.0, "item": "mürekkep kabı", "color": Color(0.12, 0.12, 0.18), "say": "Büyük çizim çok mürekkep ister. Karakolun çevresine saklanmış altı mürekkep kabını doksan saniyede topla."},
	# Akasuna Kukla Yolu (kanon: kukla parçaları elde birleştirilir; ağızdan iğne; zehir sisi)
	"gishu_senbon": {"type": "throws", "n": 20, "time": 60.0, "min_d": 8.0, "say": "Kuklanın kolundaki iğne uzaktan öldürür. Sekiz adım geriden bir dakikada yirmi isabet."},
	"shikomi_shinshin_happa": {"type": "tend", "n": 3, "dwell": 4.0, "spots": "benches", "item": "kukla parçası", "say": "Üç tezgâhta yarım kuklalar bekliyor. Her birinin gizli haznesini dört saniyede chakra ipliğinle kur; ipliğin koparsa baştan."},
	"sasori_doku_kemuri": {"type": "survive", "n": 20, "time": 0.0, "say": "Zehrini tanımayan kuklacı kendi sisinde ölür. Yirmi saniye zehir sisinin içinde kal."},
	"kugutsu_hiruko": {"type": "hits", "n": 40, "time": 50.0, "say": "Zırh kuklanın kuyruğu durmaz. Elli saniyede kırk darbe."},
	"tekkosen": {"type": "survive", "n": 20, "time": 0.0, "rain": true, "say": "Demir yelpaze ancak gelen silahı gören göze yarar. Şu çemberin içinde yirmi saniye dur; yağdıracağım kunailerden kaçarken çemberden çıkma!"},
}
var drill := {}   # aktif antrenman: {pid, jid, type, n, c, t, time, center, ang, dummies}

const PATHS := {
	"yilan": {
		"name": "Yılan Yolu", "icon": "seal", "color": Color(0.7, 0.5, 0.9),
		"style": "Yılan elleri, Kusanagi, lanetli mühür ve yasak diriltme sanatları",
		"site": {"country": "sound", "off": Vector2(-1900, 1300), "kind": "snake", "clear": 52.0, "place": "Ryūchi İni (Ses Ülkesi dağları)"},
		"mentor": {"name": "Yamikage Jaen", "title": "Yılan Ustası",
			"look": {"gender": "m", "skin": Color(0.94, 0.91, 0.9), "hair": Color(0.07, 0.07, 0.1), "hair_style": "uzun", "eye": Color(0.9, 0.78, 0.15),
				"top": Color(0.88, 0.85, 0.78), "top2": Color(0.6, 0.5, 0.75), "pants": Color(0.28, 0.2, 0.38), "band": null, "vest": null, "age": "adult"}},
		"rumor_level": 52, "join_level": 60,
		"rumor": "Gezginler, Ses Ülkesi'nin sisli dağlarında yılanların bekçilik ettiği bir mağaradan söz ediyor. İçeride ölümsüzlüğü arayan solgun bir usta yaşarmış...",
		"intro": "Solgun usta sarı gözlerini sana dikiyor: \"Merak... ne güzel bir koku. Yılanlar yalnızca bedelini ödemeye hazır olanlara sırlarını açar. Sınavımı geçersen sana deri değiştirmeyi öğretirim.\"",
		"passive": {"poison_resist": 0.3, "speed": 0.04},
		"passive_desc": "Zehir direnci +%30, hız +%4",
		"order": ["sen_ei_jashu", "jagei_jubaku", "hebi_bunshin_no_jutsu", "sen_ei_tajashu", "kuchiyose_rashomon", "kusanagi_kuchi", "gogyo_fuin",
			"sen_ei_ranjashu", "ten_no_juin", "mandara_no_jin", "orochimaru_ryu_no_kawarimi_no_jutsu", "hakuja_sennin_modo", "juin_ni_no_dankai",
			"kuchiyose_sanju_rashomon", "yamata_no_jutsu", "kuchiyose_edo_tensei", "sojasosai_no_jutsu", "sennyu_no_jutsu", "satsui_no_shisen", "hebi_nyoro", "chakura_kyuin_jutsu", "jaguchi_shibari", "shikokujaijin", "hebi_saisetsugo", "hakuja_shintai", "soma_no_ko"],
		"quest": {"kusanagi_kuchi": "sword", "ten_no_juin": "curse"},
		"dark": {"ten_no_juin": 15, "juin_ni_no_dankai": 20, "kuchiyose_edo_tensei": 40, "sojasosai_no_jutsu": 30},
	},
	"silah": {
		"name": "Silah Ustası Yolu", "icon": "sword", "color": Color(0.95, 0.6, 0.35),
		"style": "Parşömenden silah çağırma, telli silah fırtınaları ve efsanevi araçlar",
		"site": {"country": "fire", "off": Vector2(-2840, 1300), "kind": "forge", "clear": 62.0, "place": "Tetsuyama Demirhanesi (Ateş Ülkesi tepeleri)"},
		"mentor": {"name": "Tetsuno Kanae", "title": "Silah Ustası Demirci",
			"look": {"gender": "f", "skin": Color(0.93, 0.78, 0.64), "hair": Color(0.28, 0.16, 0.1), "hair_style": "atkuyruğu", "eye": Color(0.35, 0.22, 0.12),
				"top": Color(0.82, 0.28, 0.22), "top2": Color(0.6, 0.18, 0.14), "pants": Color(0.18, 0.17, 0.2), "vest": Color(0.42, 0.28, 0.16),
				"band": Color(0.2, 0.2, 0.25), "age": "adult"}},
		"rumor_level": 18, "join_level": 24,
		"rumor": "Konoha'nın batısındaki tepelerde, örsünden kıvılcım eksik olmayan bir demirhane varmış. Ustası, parşömeninden yüz silahı aynı anda yağdırabiliyormuş.",
		"intro": "Demirci çekicini bırakıp alnını siliyor: \"Silah, onu tutanın iradesi kadar keskindir. Önce ellerinin işe yarar olduğunu göster, sonra parşömenlerimi açarım.\"",
		"passive": {"throw_dmg": 0.3, "w_all": 0.12},
		"passive_desc": "Atış hasarı +%30, tüm silahlar +%12",
		"order": ["buki_kuchiyose", "tesso_kusari", "soshoryu", "tekkosen", "ito_buki_arashi", "kuchiyose_tetsuzan",
			"bashosen_kaze_no_maki", "bashosen_hi_no_maki", "bashosen_rai_no_maki", "bashosen_mizu_no_maki", "kaifujutsu_shuriken", "enbu_ni_no_dan", "sogu_tensasai"],
		"quest": {"soshoryu": "dragons", "bashosen_kaze_no_maki": "fan"},
		"dark": {},
	},
	"tip": {
		"name": "Şifacı Yolu (Tıbbi Ninja)", "icon": "potion", "color": Color(0.45, 0.9, 0.6),
		"style": "Mistik Avuç ile iyileştirme, chakra neşteri, zehir ve panzehir, yaşlanmayı durduran mühür",
		"site": {"country": "hotwater", "off": Vector2(900, -700), "kind": "clinic", "clear": 50.0, "place": "Yuge Şifa Tapınağı (Sıcak Su Ülkesi)"},
		"mentor": {"name": "Hōseki Rindō", "title": "Şifacı Usta",
			"look": {"gender": "f", "skin": Color(0.96, 0.84, 0.72), "hair": Color(0.85, 0.75, 0.45), "hair_style": "atkuyruğu", "eye": Color(0.55, 0.4, 0.2),
				"top": Color(0.92, 0.92, 0.9), "top2": Color(0.45, 0.75, 0.55), "pants": Color(0.3, 0.32, 0.36), "band": Color(0.2, 0.2, 0.25), "age": "adult"}},
		"rumor_level": 22, "join_level": 28,
		"rumor": "Sıcak Su Ülkesi'nde, buharı şifa veren bir tapınakta yaralı askerleri ölümden döndüren bir şifacı varmış. Öğrenci arıyormuş.",
		"intro": "Şifacı ellerini yeşil chakrayla ısıtıyor: \"Yıkmak kolay, onarmak zor. Chakra kontrolün yeterince ince mi? Önce yaralılara yetiş, sonra konuşuruz.\"",
		"passive": {"heal_power": 0.3, "chakra_regen": 0.15},
		"passive_desc": "İyileştirme gücü +%30, chakra yenilenmesi +%15",
		"order": ["shousen", "senpuku", "shikon_no_jutsu", "saikan_chushutsu_no_jutsu", "dokugiri", "ranshinsho", "chakura_no_mesu", "in_yu_shometsu", "sozo_saisei"],
		"quest": {"sozo_saisei": "seal"},
		"dark": {},
	},
	"kapi": {
		"name": "Sekiz Kapı Yolu", "icon": "hand", "color": Color(0.35, 0.85, 0.35),
		"style": "Bedenin sekiz chakra kapısını zorla açmak: Lotus, Sabah Tavuskuşu, Gündüz Kaplanı, Akşam Fili",
		"site": {"country": "fire", "off": Vector2(1500, 900), "kind": "dojo", "clear": 50.0, "place": "Seishun Dojosu (Ateş Ülkesi dağları)"},
		"mentor": {"name": "Kōtetsu Gōriki", "title": "Taijutsu Ustası",
			"look": {"gender": "m", "skin": Color(0.93, 0.78, 0.62), "hair": Color(0.08, 0.08, 0.1), "hair_style": "kase", "eye": Color(0.1, 0.1, 0.1),
				"top": Color(0.2, 0.5, 0.25), "top2": Color(0.2, 0.5, 0.25), "pants": Color(0.2, 0.5, 0.25), "vest": Color(0.38, 0.48, 0.28), "band": Color(0.75, 0.15, 0.15), "age": "adult"}},
		"rumor_level": 28, "join_level": 35,
		"rumor": "Ateş Ülkesi dağlarında, şafakta binlerce şınav çeken yeşil tulumlu bir ustanın dojosu varmış. Azmi olan her genci kabul ediyormuş.",
		"intro": "Usta tek elle amuda kalkmış: \"Gençliğin ateşi! Ninjutsu yoksa ne olmuş? Bedenin sekiz kapısı var ve onları açacak kadar azimliysen dünyayı yerinden oynatırsın!\"",
		"passive": {"gates": 0.3, "melee": 0.1},
		"passive_desc": "Kapı ustalığı +%30 (daha güçlü, daha az bedel), yakın dövüş +%10",
		"order": ["omote_renge", "ura_renge", "hachimon_tonko_no_jin", "asakujaku", "hirudora", "sekizo", "yagai"],
		"quest": {"hachimon_tonko_no_jin": "gates", "yagai": "gates"},
		"dark": {},
	},
	"kagit": {
		"name": "Kâğıt Yolu", "icon": "scroll", "color": Color(0.85, 0.82, 0.95),
		"style": "Bedeni kâğıda çeviren sanat: kâğıt klonlar, kelebek sürüleri, kanatlar, mızrak ormanı ve patlayıcı kâğıt denizi",
		"site": {"country": "rain", "off": Vector2(-700, 600), "kind": "paper", "clear": 50.0, "place": "Kâğıt Çiçek Kulesi (Yağmur Ülkesi)"},
		"mentor": {"name": "Shirobana Ayame", "title": "Kâğıt Ustası",
			"look": {"gender": "f", "skin": Color(0.96, 0.88, 0.84), "hair": Color(0.45, 0.35, 0.65), "hair_style": "topuz", "eye": Color(0.85, 0.75, 0.4),
				"top": Color(0.15, 0.15, 0.2), "top2": Color(0.15, 0.15, 0.2), "pants": Color(0.15, 0.15, 0.2), "band": Color(0.3, 0.3, 0.35), "age": "adult"}},
		"rumor_level": 40, "join_level": 48,
		"rumor": "Yağmur Ülkesi'nde, tepesinde kâğıt çiçek açan bir kulede yaşayan sessiz bir kadın varmış. Rüzgârla dağılıp yeniden toplanırmış.",
		"intro": "Kadının bedeni bir an kâğıt yapraklara dağılıp yeniden birleşiyor: \"Kâğıt zayıf görünür. Ama bin kat katlanınca çelik keser. Sabrın varsa öğretirim.\"",
		"passive": {"jutsu": 0.1, "speed": 0.03},
		"passive_desc": "Jutsu gücü +%10, hız +%3",
		"order": ["kami_bunshin", "kami_chocho", "kami_tsubasa", "shikigami_no_mai", "kami_yari", "kami_no_shisha_no_jutsu", "kami_shigure", "kami_chakuramu"],
		"quest": {"kami_no_shisha_no_jutsu": "sea"},
		"dark": {},
	},
	"gama": {
		"name": "Kurbağa Bilgesi Yolu", "icon": "seal", "color": Color(1.0, 0.6, 0.25),
		"style": "Kurbağa yağı ve ateş, savaş saçı (iğneler, aslan yelesi, diken kalkanı), kurbağa midesi mühürü ve bilge çağrısı",
		"site": {"country": "waterfall", "off": Vector2(500, -800), "kind": "toad", "clear": 50.0, "place": "Yosunlu Kurbağa Tapınağı (Şelale Ülkesi)"},
		"mentor": {"name": "Hōrō Gamasuke", "title": "Gezgin Kurbağa Bilgesi",
			"look": {"gender": "m", "skin": Color(0.94, 0.8, 0.68), "hair": Color(0.92, 0.92, 0.9), "hair_style": "uzun", "eye": Color(0.3, 0.25, 0.2),
				"top": Color(0.3, 0.45, 0.3), "top2": Color(0.75, 0.2, 0.15), "pants": Color(0.3, 0.45, 0.3), "band": Color(0.85, 0.85, 0.82), "age": "adult", "face_mark": "yanak çizgisi"}},
		"rumor_level": 50, "join_level": 58,
		"rumor": "Şelale Ülkesi'nde, yosunlu bir kurbağa tapınağında roman yazan beyaz saçlı bir bilge görülmüş. Kurbağalarla konuşurmuş.",
		"intro": "Beyaz saçlı adam kaleminden başını kaldırıyor: \"Bir öğrenci mi? Hah! Önce bana kurbağaların gözünden dünyayı göstermelisin. Sonra saçımın bile silah olduğunu görürsün.\"",
		"passive": {"chakra": 0.12, "hp": 0.06},
		"passive_desc": "Chakra +%12, can +%6",
		"order": ["gamayudan", "kebari_senbon", "ranjishigami_no_jutsu", "hari_jizo", "kuchiyose_gamaguchi_shibari", "katon_gamayu_endan", "senpo_kawazu_naki"],
		"quest": {"senpo_kawazu_naki": "sage"},
		"dark": {},
	},
	"kil": {
		"name": "Patlayıcı Kil Yolu", "icon": "seal", "color": Color(0.95, 0.85, 0.6),
		"style": "Avuçtaki ağızlarla chakra yoğrulmuş kil: uçan kuşlar, örümcekler, ejderler, kasaba yıkan heykeller ve sanatın son patlaması",
		"site": {"country": "earth", "off": Vector2(-1200, -900), "kind": "clay", "clear": 50.0, "place": "Kil Atölyesi (Toprak Ülkesi kanyonları)"},
		"mentor": {"name": "Bakufū Gen", "title": "Kil Sanatçısı",
			"look": {"gender": "m", "skin": Color(0.95, 0.84, 0.72), "hair": Color(0.95, 0.85, 0.45), "hair_style": "uzun", "eye": Color(0.3, 0.45, 0.75),
				"top": Color(0.18, 0.18, 0.22), "top2": Color(0.75, 0.15, 0.15), "pants": Color(0.18, 0.18, 0.22), "band": Color(0.4, 0.35, 0.3), "age": "adult"}},
		"rumor_level": 42, "join_level": 50,
		"rumor": "Toprak Ülkesi'nin kanyonlarında patlamalar duyuluyormuş. Kilden kuşlar uçuran, sanatın bir an olduğuna inanan bir zanaatkâr yaşarmış.",
		"intro": "Sarışın adam elindeki kili yoğuruyor, avucundaki ağız sırıtıyor: \"Sanat bir patlamadır! Kalıcı olan sıkıcıdır, hm. Gözlerinle görmek istiyorsan önce benim işimi kanıtla.\"",
		"passive": {"jutsu": 0.12, "chakra": 0.05},
		"passive_desc": "Jutsu gücü +%12, chakra +%5",
		"order": ["nendo_bunshin", "kibaku_nendo", "shi_wan", "bakuha_kibaku_te", "kil_ucan_kus", "ningyo_kibaku_nendo", "shi_tsu", "shi_tsu_hiko", "bakuha_jirai", "bakuha_rensa", "shi_suri", "shi_fo", "shi_o", "nendo_kawarimi", "kibaku_jirai", "shi_tsu_bakuretsu_hiryu"],
		"quest": {"shi_fo": "art", "shi_o": "art"},
		"dark": {"shi_o": 10},
	},
	"kakuzu": {
		"name": "Toprak Kini Yolu", "icon": "seal", "color": Color(0.35, 0.3, 0.28),
		"style": "Bedeni dikip onaran kara iplikler, taş gibi sertleşen deri ve maskeli kalplerin ateş, rüzgâr, şimşek saldırıları",
		"site": {"country": "waterfall", "off": Vector2(-900, 700), "kind": "thread", "clear": 50.0, "place": "Kara İplik Mezarlığı (Şelale Ülkesi)"},
		"mentor": {"name": "Kurogane Zeni", "title": "İplik Ustası",
			"look": {"gender": "m", "skin": Color(0.75, 0.6, 0.48), "hair": Color(0.1, 0.1, 0.12), "hair_style": "uzun", "eye": Color(0.3, 0.7, 0.3),
				"top": Color(0.2, 0.22, 0.2), "top2": Color(0.15, 0.15, 0.15), "pants": Color(0.2, 0.2, 0.2), "band": Color(0.4, 0.4, 0.42), "age": "adult"}},
		"rumor_level": 50, "join_level": 58,
		"rumor": "Şelale Ülkesi'nin mezarlığında, para için ödül avlayan, yüzü dikişlerle dolu yaşlı bir paralı askerden söz ediliyor. Kalbi bir değil beşmiş...",
		"intro": "Dikişli adam paranı sayar gibi sana bakıyor: \"Para asla ihanet etmez. Sen de etmeyeceksen... bedenini dikmeyi öğretirim. Önce ödülünü getir.\"",
		"passive": {"hp": 0.15, "def": 0.05},
		"passive_desc": "Can +%15, savunma +%5",
		"order": ["jiongu_ito_kirbac", "doton_domu", "jiongu", "kakuzu_kalp_calma", "kakuzu_maske_katon", "kakuzu_maske_futon", "kakuzu_maske_raiton", "kakuzu_maske_suiton"],
		"quest": {"kakuzu_kalp_calma": "heart"},
		"dark": {"kakuzu_kalp_calma": 25},
	},
	"hiraishin": {
		"name": "Uçan Yıldırım Yolu", "icon": "seal", "color": Color(1.0, 0.85, 0.3),
		"style": "İşaretli kunailer, göz açıp kapayana kadar ışınlanma, zincirleme kesikler ve ışınlanırken Rasengan",
		"site": {"country": "whirlpool", "off": Vector2(400, 300), "kind": "thunder", "clear": 50.0, "place": "Yıldırım Mührü Tapınağı (Girdap harabeleri)"},
		"mentor": {"name": "Kōsoku Hayate", "title": "Sarı Şimşek",
			"look": {"gender": "m", "skin": Color(0.95, 0.82, 0.7), "hair": Color(0.98, 0.85, 0.3), "hair_style": "diken", "eye": Color(0.25, 0.5, 0.85),
				"top": Color(0.25, 0.35, 0.25), "top2": Color(0.95, 0.95, 0.92), "pants": Color(0.15, 0.2, 0.35), "band": Color(0.15, 0.22, 0.55), "age": "adult"}},
		"rumor_level": 62, "join_level": 72,
		"rumor": "Girdap Ülkesi'nin harabelerinde, sarı bir şimşek gibi göz açıp kapayana kadar yer değiştiren bir ninja görülmüş. Ardında yalnız üç kollu kunailer kalırmış.",
		"intro": "Sarı saçlı adam gülümsüyor, bir an yerinde, bir an arkanda: \"Hız, işaret koymaktır. Nereye işaret koyarsan oradasın. Önce işaretlerimi bul.\"",
		"passive": {"speed": 0.1, "seal_speed": 0.15},
		"passive_desc": "Hız +%10, mühür hızı +%15",
		"order": ["hiraishin_kunai", "hiraishingiri", "hiraishin_ranbu", "hiraishin_ni_no_dan", "hiraishin_no_jutsu", "hiraishin_rasengan", "hiraishin_dorai"],
		"quest": {"hiraishin_no_jutsu": "marks"},
		"dark": {},
	},
	"chidori": {
		"name": "Şimşek Kılıcı Yolu", "icon": "sword", "color": Color(0.55, 0.75, 1.0),
		"style": "Chidori'nin bin kuş sesi: elde, kılıçta, iğne ve mızrakta şimşek, bedenden akan akım ve gökten inen Kirin",
		"site": {"country": "iron", "off": Vector2(-500, 800), "kind": "chidori", "clear": 50.0, "place": "Bin Kuş Uçurumu (Demir Ülkesi)"},
		"mentor": {"name": "Raikō Shinobu", "title": "Şimşek Kılıcı",
			"look": {"gender": "m", "skin": Color(0.95, 0.84, 0.74), "hair": Color(0.08, 0.08, 0.12), "hair_style": "diken", "eye": Color(0.15, 0.15, 0.2),
				"top": Color(0.9, 0.9, 0.92), "top2": Color(0.3, 0.25, 0.45), "pants": Color(0.15, 0.15, 0.2), "band": null, "age": "adult"}},
		"rumor_level": 40, "join_level": 48,
		"rumor": "Demir Ülkesi'nin karlı uçurumlarında bin kuşun ötüşü gibi bir ses yankılanıyormuş. Elinde şimşek taşıyan sessiz bir kılıç ustası...",
		"intro": "Kara saçlı adam kılıcını kınından yarım çekiyor, namlu boyunca şimşek akıyor: \"Şimşek keskinliktir. Zayıf olan kırılır. Bana keskin olduğunu göster.\"",
		"passive": {"melee": 0.08, "el_raiton": 0.15},
		"passive_desc": "Yakın dövüş +%8, Raiton gücü +%15",
		"order": ["raiton_chidori", "chidori_nagashi", "chidori_senbon", "chidori_eiso", "chidori_ranbu", "kusanagi_no_tsurugi_chidorigatana", "chidori_jinrai", "kirin"],
		"quest": {"kirin": "storm"},
		"dark": {},
	},
	"jashin": {
		"name": "Jashin Yolu", "icon": "seal", "color": Color(0.75, 0.1, 0.12),
		"style": "Kan ritüelleri: düşmanın kanıyla lanet çemberi, üç bıçaklı tırpan, geri çekilen mızrak ve ölmeyen beden",
		"site": {"country": "hotwater", "off": Vector2(-800, 900), "kind": "jashin", "clear": 50.0, "place": "Kanlı Ayin Tapınağı (Sıcak Su Ülkesi)"},
		"mentor": {"name": "Chimatsuri Ren", "title": "Ayin Rahibi",
			"look": {"gender": "m", "skin": Color(0.95, 0.88, 0.82), "hair": Color(0.85, 0.85, 0.9), "hair_style": "geriye", "eye": Color(0.7, 0.2, 0.55),
				"top": Color(0.12, 0.12, 0.14), "top2": Color(0.7, 0.1, 0.12), "pants": Color(0.12, 0.12, 0.14), "band": Color(0.35, 0.35, 0.38), "age": "adult"}},
		"rumor_level": 45, "join_level": 52,
		"rumor": "Sıcak Su Ülkesi'nin terk edilmiş bir tapınağında kanla çizilmiş çemberlerin içinde dua eden, ölmeyen bir rahipten bahsediliyor.",
		"intro": "Rahip boynundaki kolyeyi öpüyor: \"Jashin-sama acıyı sever. Acı çekmekten korkmuyor musun? O zaman ayine katıl... ama önce kurbanları getir.\"",
		"passive": {"hp": 0.1, "regen_hp": 0.5},
		"passive_desc": "Can +%10, can yenilenmesi artar",
		"order": ["jashin_sanjin_kama", "jashin_kazik", "jashin_ketsueki", "jujutsu_shiji_hyoketsu", "jashin_fumetsu", "jashin_kurban"],
		"quest": {"jujutsu_shiji_hyoketsu": "ritual"},
		"dark": {"jujutsu_shiji_hyoketsu": 20, "jashin_kurban": 20},
	},
	"hachibi": {
		"name": "Sekiz Kuyruk Yolu", "icon": "seal", "color": Color(0.85, 0.5, 0.75),
		"style": "Ahtapot kolları, mürekkep perdesi, yedi kılıç dansı, kuyruklu lariat ve ritimle akan savaş",
		"site": {"country": "lightning", "off": Vector2(900, -900), "kind": "octo", "clear": 50.0, "place": "Hileler ve Gerçekler Şelalesi (Yıldırım Ülkesi)"},
		"mentor": {"name": "Hachiryū Biito", "title": "Ritim Ustası",
			"look": {"gender": "m", "skin": Color(0.42, 0.3, 0.22), "hair": Color(0.92, 0.92, 0.9), "hair_style": "kisa", "eye": Color(0.15, 0.15, 0.15),
				"top": Color(0.9, 0.9, 0.88), "top2": Color(0.25, 0.25, 0.28), "pants": Color(0.2, 0.2, 0.22), "band": Color(0.15, 0.22, 0.55), "age": "adult"}},
		"rumor_level": 58, "join_level": 66,
		"rumor": "Yıldırım Ülkesi'nin şelalesinde ritimle konuşan, sırtında yedi kılıç taşıyan güçlü bir savaşçı yaşarmış. Bazen ahtapot kolları çıkarırmış!",
		"intro": "İri adam ritim tutarak sana bakıyor: \"Yo! Ritmini bulamazsan kılıcın da şaşar, bebeğim! Şelalenin altında kendinle yüzleş, sonra rap yapalım!\"",
		"passive": {"melee": 0.1, "hp": 0.08},
		"passive_desc": "Yakın dövüş +%10, can +%8",
		"order": ["hachibi_murekkep", "takoashi_bunshin_no_jutsu", "hachibi_lariat", "hachibi_ahtapot_kollari", "hachibi_yedi_kilic", "hachibi_kuyruk_zirhi", "hachibi_ahtapot_topu"],
		"quest": {"hachibi_ahtapot_topu": "falls"},
		"dark": {},
	},
	"sumi": {
		"name": "Kök: Mürekkep Yolu", "icon": "scroll", "color": Color(0.55, 0.55, 0.62),
		"style": "Fırçayla çizilen mürekkep canavarları (Chōjū Giga), mürekkep klonları ve sisi, mürekkep mühürleri; duygusuz Kök eğitimi",
		"site": {"country": "fire", "off": Vector2(1800, 2600), "kind": "ink", "clear": 48.0, "place": "Yıkık Kök Karakolu (Ateş Ülkesi ormanı)"},
		"mentor": {"name": "Sumizome Kōji", "title": "Mürekkep Ustası",
			"look": {"gender": "m", "skin": Color(0.95, 0.9, 0.86), "hair": Color(0.06, 0.06, 0.08), "hair_style": "kisa", "eye": Color(0.08, 0.08, 0.1),
				"top": Color(0.12, 0.12, 0.14), "top2": Color(0.4, 0.4, 0.45), "pants": Color(0.12, 0.12, 0.14), "band": Color(0.2, 0.2, 0.22), "age": "adult"}},
		"rumor_level": 30, "join_level": 38,
		"rumor": "Ateş Ülkesi ormanında, dağıtılmış eski bir Kök karakolunda sessizce resim yapan solgun bir adam varmış. Çizdiği kuşlar sayfadan kalkıp uçarmış.",
		"intro": "Solgun adam fırçasını kaldırmadan konuşuyor: \"Kök duyguları siler, yalnız görev kalır. Ben resmimle bir şeyler geri kazandım. Önce elinin titremediğini göster.\"",
		"passive": {"chakra": 0.1, "jutsu": 0.05},
		"passive_desc": "Chakra +%10, jutsu gücü +%5",
		"order": ["sumi_bunshin_no_jutsu", "sumigasumi_no_jutsu", "choju_giga", "hoki_sumi_ryu", "fuinjutsu_okutopasu_horudo", "choshin_giga", "hoki_sumi_tora", "hoki_sumi_tori"],
		"quest": {"choshin_giga": "god"},
		"dark": {},
	},
	"akasuna": {
		"name": "Akasuna Kukla Yolu", "icon": "seal", "color": Color(0.75, 0.3, 0.25),
		"style": "Zehirli silahlarla dolu kuklalar, chakra iplikleri, zırh kuklası, Üçüncü Kazekage kuklası, bin kol ve yenilen rakiplerden yapılan insan kuklaları",
		"site": {"country": "wind", "off": Vector2(2600, 1800), "kind": "puppet", "clear": 48.0, "place": "Kızıl Kum Atölyesi (Rüzgâr Ülkesi)"},
		"mentor": {"name": "Akabane Sōen", "title": "Kukla Ustası",
			"look": {"gender": "m", "skin": Color(0.95, 0.85, 0.78), "hair": Color(0.65, 0.18, 0.14), "hair_style": "dağınık", "eye": Color(0.45, 0.35, 0.3),
				"top": Color(0.2, 0.18, 0.2), "top2": Color(0.55, 0.15, 0.15), "pants": Color(0.2, 0.18, 0.2), "band": Color(0.4, 0.4, 0.42), "age": "adult"}},
		"rumor_level": 48, "join_level": 56,
		"rumor": "Rüzgâr Ülkesi'nin kızıl kumlarında, hiç yaşlanmayan genç yüzlü bir kuklacının atölyesi varmış. Kuklalarının bazıları bir zamanlar insanmış...",
		"intro": "Genç görünen adamın gözleri cansız: \"Gerçek sanat sonsuza kadar kalır. Kuklalar çürümez, ihanet etmez. Parmaklarına ip bağlamayı öğrenmek istiyorsan önce elinin hızını göster.\"",
		"passive": {"jutsu": 0.08, "poison_resist": 0.3},
		"passive_desc": "Jutsu gücü +%8, zehir direnci +%30",
		"order": ["gishu_senbon", "shikomi_shinshin_happa", "kugutsu_hiruko", "sasori_doku_kemuri", "kaen_hosha", "suiryu_hosha", "kugutsu_sandaime", "senju_sobu", "hitokugutsu", "akahigi_hyakki_no_soen"],
		"quest": {"kugutsu_sandaime": "kazekage", "hitokugutsu": "body"},
		"dark": {"hitokugutsu": 25},
	},
}
## Sıradaki yollar (ROADMAP): kurbağa sennin, kil sanatı, kukla ustası, Hiraishin, köpekbalığı...

## Yollara ait, veri dosyasında olmayan teknikler: Data.jutsu'ya yüklenir
const EXTRA_JUTSU := {
	"kami_chocho": {"name": "Kami Chōchō (Kâğıt Kelebekler)", "cost": 30, "cd": 10, "element": "", "level": 12, "rank": 2, "tier": 3, "shape": "debuff", "learn": "path:kagit", "category": "ninjutsu",
		"seals": ["Tora", "Hitsuji"], "desc": "Bedenden kopan yüzlerce kâğıt kelebek düşmanları sarar: görüşü kapanır (3 sn sersem), küçük kesikler."},
	"kami_tsubasa": {"name": "Kami Tsubasa (Kâğıt Kanatlar)", "cost": 35, "cd": 25, "element": "", "level": 14, "rank": 2, "tier": 3, "shape": "transform", "learn": "path:kagit", "category": "ninjutsu",
		"seals": ["Tori"], "desc": "Sırtından kâğıt kanatlar açılır: 20 sn uçarsın (Space yüksel, Ctrl alçal), kanat çırpışı kâğıt bıçakları savurur."},
	"kami_yari": {"name": "Kami Yari no Mori (Kâğıt Mızrak Ormanı)", "cost": 45, "cd": 14, "element": "", "level": 22, "rank": 3, "tier": 4, "shape": "spikes", "learn": "path:kagit", "category": "ninjutsu",
		"seals": ["I", "Tatsu"], "desc": "Yerden sivri kâğıt mızraklar fışkırır; hedef ve çevresi delinir, havaya atılır."},
	"hari_jizo": {"name": "Ninpō: Hari Jizō (Diken Bekçisi)", "cost": 30, "cd": 16, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "buff", "learn": "path:gama", "category": "ninjutsu",
		"seals": ["Mi"], "desc": "Saçın bedenini saran dikenli bir kozaya döner: 4 sn neredeyse hasar almazsın, yakın dövüşle vuranlar dikenlere batar."},
	"katon_gamayu_endan": {"name": "Katon: Gamayu Kaen (Kurbağa Yağı Alev Bombası)", "cost": 50, "cd": 16, "element": "katon", "level": 26, "rank": 3, "tier": 4, "shape": "breath", "learn": "path:gama", "category": "ninjutsu",
		"seals": ["Mi", "Hitsuji", "Tora"], "desc": "Bir kurbağa yağ fışkırtır, sen ateşi üflersin: yağla büyüyen dev alev seli, yerde yanan yağ gölü bırakır."},
	"shi_tsu_hiko": {"name": "Shī Tsū Doragon: Hikō (C2 Ejderhası Uçuşu)", "cost": 60, "cd": 45, "element": "", "level": 24, "rank": 3, "tier": 4, "shape": "transform", "learn": "path:kil", "category": "ninjutsu",
		"seals": ["Tora", "Tatsu"], "desc": "Dev C2 kil ejderhası yoğrulur, başının ardına binersin: 25 sn uçarsın; ejderha ağzından hedefe güdümlü kil kuşlar, altına gözlü kil mayınlar bırakır."},
	"kil_ucan_kus": {"name": "Kibaku Nendo: Tori (Kil Kuşu Uçuşu)", "cost": 40, "cd": 30, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "transform", "learn": "path:kil", "category": "ninjutsu",
		"seals": ["Tora"], "desc": "Dev kil kuş yoğrulur, sırtına binersin: 20 sn uçarsın, uçarken altına küçük kil bombalar düşer."},
	"jiongu_ito_kirbac": {"name": "Jiongu: Ito Muchi (Kara İplik Kırbacı)", "cost": 26, "cd": 8, "element": "", "level": 14, "rank": 2, "tier": 3, "shape": "melee", "learn": "path:kakuzu", "category": "kinjutsu",
		"seals": [], "desc": "İplikli el göğse dalar ve kalbi söker: güçlü hedefin kalbi (canı %30 altına inen ya da ölen) senin olur. En fazla 4 çalınmış kalp: her biri sahibinin doğasının maskeli tekniğini açar ve seni bir kez ölümden döndürür."},
	"doton_domu": {"name": "Doton: Domu", "cost": 30, "cd": 20, "element": "doton", "level": 15, "rank": 2, "tier": 3, "shape": "buff", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": ["Ushi", "Tori"], "desc": "Ten kararıp taş kadar sertleşir: 8 sn fiziksel hasarı neredeyse almazsın, yumrukların ağırlaşır."},
	"kakuzu_maske_katon": { "dmg_k": 0.58,"name": "Jiongu: Katon Zukokku (Ateş Maskeli Kalp)", "cost": 45, "cd": 16, "element": "katon", "level": 18, "rank": 3, "tier": 4, "shape": "breath", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Sırtından ateş maskeli canavar çıkar, ağzından dev patlayan alev topu kusar. Çalınmış bir Katon kalbi ister."},
	"kakuzu_maske_futon": {"name": "Jiongu: Fūton Atsugai (Rüzgâr Maskeli Kalp)", "cost": 45, "cd": 16, "element": "fuuton", "level": 20, "rank": 3, "tier": 4, "shape": "beam", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Rüzgâr maskeli canavar sıkıştırılmış kasırga üfler; geniş alanı yıkar. Çalınmış bir Fūton kalbi ister."},
	"kakuzu_maske_raiton": {"name": "Jiongu: Raiton Gian (Şimşek Maskeli Kalp)", "cost": 45, "cd": 16, "element": "raiton", "level": 22, "rank": 3, "tier": 4, "shape": "beam", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Şimşek maskeli canavar kara-mavi şimşek ışını fırlatır; hattı delip geçer. Çalınmış bir Raiton kalbi ister."},
	"kakuzu_maske_suiton": {"name": "Jiongu: Suiton Mizu Kiba (Su Maskeli Kalp)", "cost": 45, "cd": 16, "element": "suiton", "level": 24, "rank": 3, "tier": 4, "shape": "beam", "learn": "path:kakuzu", "category": "ninjutsu",
		"seals": [], "desc": "Su maskeli canavar basınçlı su dişleri fırlatır. Çalınmış bir Suiton kalbi ister."},
	"kakuzu_kalp_calma": {"name": "Jiongu: Shinzō Ubai (Kalp Çalma)", "cost": 50, "cd": 40, "element": "", "level": 15, "rank": 2, "tier": 5, "shape": "melee", "learn": "path:kakuzu", "category": "kinjutsu",
		"seals": [], "desc": "İplikli el göğse dalar ve kalbi söker: güçlü hedefin kalbi (canı %30 altına inen ya da ölen) senin olur. En fazla 4 çalınmış kalp: her biri sahibinin doğasının maskeli tekniğini açar ve seni bir kez ölümden döndürür."},
	"hiraishin_kunai": {"name": "Hiraishin Kunai (Uçan Yıldırım Kunaisi)", "cost": 20, "cd": 6, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "projectile", "learn": "path:hiraishin", "category": "ninjutsu",
		"seals": [], "desc": "Mühürlü üç kollu kunai fırlatılır; saplandığı yere 0.3 sn sonra ışınlanıp kesersin."},
	"hiraishin_ranbu": { "dmg_k": 2.0,"name": "Hiraishin Ranbu (Uçan Yıldırım Dansı)", "cost": 40, "cd": 14, "element": "", "level": 20, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:hiraishin", "category": "ninjutsu",
		"seals": [], "desc": "Çevredeki düşmanlar arasında sarı şimşek gibi zıplayıp her birini art arda kesersin."},
	"hiraishin_rasengan": {"name": "Hiraishin Rasengan (Uçan Yıldırım Rasengan)", "cost": 50, "cd": 16, "element": "", "level": 26, "rank": 4, "tier": 5, "shape": "melee", "learn": "path:hiraishin", "category": "ninjutsu",
		"seals": [], "desc": "Elinde Rasengan yoğrulur, hedefin arkasına ışınlanıp çarparsın."},
	"chidori_ranbu": {"name": "Chidori Ranbu (Chidori Kılıç Dansı)", "cost": 35, "cd": 12, "element": "raiton", "level": 20, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:chidori", "category": "ninjutsu",
		"seals": [], "desc": "Kılıca akan Chidori ile beş hızlı kesik; her kesik şimşek yarığı bırakır."},
	"chidori_jinrai": { "dmg_k": 1.58,"name": "Chidori: Jinrai", "cost": 45, "cd": 16, "element": "raiton", "level": 24, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:chidori", "category": "ninjutsu",
		"seals": [], "desc": "Chidori'yle hat boyunca şimşek gibi ileri atılır, yolundaki her düşmanı delersin."},
	"jashin_sanjin_kama": { "need": "weapon:uc_tirpan", "dmg_k": 0.39,"name": "Sanjin no Ōgama (Üç Bıçaklı Tırpan)", "cost": 25, "cd": 7, "element": "", "level": 16, "rank": 2, "tier": 3, "shape": "projectile", "learn": "path:jashin", "category": "taijutsu",
		"seals": [], "desc": "Kabloya bağlı kızıl üç bıçaklı tırpan fırlatılır; kanatıp geri çekilir."},
	"jashin_kazik": {"name": "Jashin: Kaeri Yari (Geri Çekilen Kazık)", "cost": 22, "cd": 6, "element": "", "level": 17, "rank": 2, "tier": 3, "shape": "projectile", "learn": "path:jashin", "category": "taijutsu",
		"seals": [], "desc": "Kolundan uzayan siyah kazık hedefe saplanır; kanını alırsın (ayin için)."},
	"jashin_ketsueki": { "need": "weapon:uc_tirpan","name": "Jashin: Chi no Chikai (Kan Yemini)", "cost": 20, "cd": 12, "element": "", "level": 18, "rank": 2, "tier": 3, "shape": "buff", "learn": "path:jashin", "category": "kinjutsu",
		"seals": [], "desc": "Kendi kanını içip bedeni siyah-beyaz ölüm desenine bürünür: 10 sn vuruşların kanatır ve can çalar."},
	"jashin_fumetsu": {"name": "Jashin: Fujimi (Ölümsüz Beden)", "cost": 40, "cd": 60, "element": "", "level": 22, "rank": 3, "tier": 4, "shape": "buff", "learn": "path:jashin", "category": "kinjutsu",
		"seals": [], "desc": "Jashin'in lütfu: 8 sn canın 1'in altına inmez, aldığın her darbe yakındaki düşmanlara da yansır."},
	"jashin_kurban": { "need": "weapon:uc_tirpan","name": "Jashin: Ikenie no Gi (Kurban Ayini)", "cost": 55, "cd": 30, "element": "", "level": 26, "rank": 4, "tier": 5, "shape": "aoe", "learn": "path:jashin", "category": "kinjutsu",
		"seals": [], "desc": "Yere dev kan çemberi çizilir; içindeki düşmanlar her saniye senin aldığın kadar hasar alır."},
	"hachibi_murekkep": {"need": "jin:gyuki", "name": "Hachibi: Tako Sumi (Mürekkep Perdesi)", "cost": 20, "cd": 10, "element": "", "level": 18, "rank": 2, "tier": 3, "shape": "aoe", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Ağızdan fışkıran kara mürekkep: önündekiler kör olur, yapışkan mürekkep yavaşlatır."},
	"hachibi_lariat": { "dmg_k": 0.57,"need": "jin:gyuki", "name": "Bijū Rariatto (Kuyruklu Lariat)", "cost": 35, "cd": 12, "element": "raiton", "level": 20, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:hachibi", "category": "taijutsu",
		"seals": [], "desc": "Şimşekli kol ve ahtapot koluyla çift lariat; yolundakiler savrulur."},
	"hachibi_ahtapot_kollari": {"need": "jin:gyuki", "name": "Takoashi Ude (Ahtapot Kolları)", "cost": 40, "cd": 14, "element": "", "level": 22, "rank": 3, "tier": 4, "shape": "aoe", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Sırttan çıkan dev ahtapot kolları yeri döver, yakalayıp sıkar."},
	"hachibi_yedi_kilic": { "dmg_k": 0.26,"name": "Nanatō Ranbu (Yedi Kılıç Dansı)", "cost": 45, "cd": 16, "element": "", "level": 24, "rank": 3, "tier": 4, "shape": "melee", "learn": "path:hachibi", "category": "kenjutsu",
		"seals": [], "desc": "Kollar, koltuk altı, ağız: yedi kılıçla dönen kasırga kesik dansı."},
	"hachibi_kuyruk_zirhi": {"need": "jin:gyuki", "name": "Bijū Koromo (Kuyruk Örtüsü)", "cost": 40, "cd": 40, "element": "", "level": 26, "rank": 4, "tier": 5, "shape": "mode", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Mor çakra örtüsü ve sekiz kuyruk: 20 sn güç, dayanıklılık, kollar otomatik saldırır."},
	"hachibi_ahtapot_topu": {"need": "jin:gyuki", "name": "Hachibi: Bijūdama (Sekiz Kuyruk Topu)", "cost": 60, "cd": 30, "element": "", "level": 28, "rank": 4, "tier": 5, "shape": "projectile", "learn": "path:hachibi", "category": "ninjutsu",
		"seals": [], "desc": "Ağızda siyah-mor canavar topu sıkıştırılır ve fırlatılır: dev patlama."},
}

static var lairs := {}   # yol id -> [x, y] harita noktası (ustanın önü)
static var _node: LegendPaths = null
var _t := 0.0


# ------------------------------------------------------------------ durum
static func pr() -> Dictionary:
	return Game.profile


static func st_of(pid: String) -> Dictionary:
	var p = pr()
	if p.is_empty():
		return {"s": UNKNOWN}
	if not p.has("paths"):
		p["paths"] = {}
	if not p["paths"].has(pid):
		p["paths"][pid] = {"s": UNKNOWN}
	return p["paths"][pid]


static func state(pid: String) -> int:
	return int(st_of(pid).get("s", UNKNOWN))


static func set_state(pid: String, s: int) -> void:
	var d = st_of(pid)
	if int(d.get("s", 0)) < s:
		d["s"] = s


## ------------------------------------------------------------------ ipucu (söylenti sistemi yok)
## Her yolun yalnız kısa bir ipucu var (ülke + yerin alameti). İn ancak keşfedilerek (45 m yakına gelince) bulunur.
const SIGNS := {"snake": "kayalara dökülmüş dev yılan derileri ve ıslak bir mağara ağzı", "forge": "geceleri tepeden yükselen kıvılcımlar ve örs sesleri",
	"clinic": "buharı ilaç kokan sıcak bir pınar ve basamaklı bir tapınak", "dojo": "şafakta yankılanan sayma sesleri ve kırık ağaç kütükleri",
	"paper": "rüzgârda uçuşan kâğıt yapraklar ve yağmurda kurumayan bir kule", "toad": "yosun tutmuş kurbağa heykelleri ve sürekli damlayan bir kaya",
	"clay": "kanyon duvarlarında patlama izleri ve yerde kurumuş kil parçaları", "thread": "kazılmış mezarlar ve dallara takılmış kara iplikler",
	"thunder": "eski bir girdap mührü taşıyan harabeler ve yerde yanık işaretler", "chidori": "yıldırım düşmüş, yarılmış kayalar ve kuş cıvıltısına benzer bir çatırtı",
	"jashin": "yerde kanla çizilmiş üçgenli halkalar", "octo": "şelalenin dibinde dev vantuz izleri ve dövülmüş kayalar",
	"ink": "yıkık bir karakol ve ağaçlarda mürekkeple çizilmiş hayvan resimleri", "puppet": "kumda yarı gömülü kukla uzuvları ve kızıl kum"}


static func country_name(pid: String) -> String:
	var cid = String(PATHS[pid]["site"]["country"])
	for c in Game.world_info.get("countries", []):
		if c["id"] == cid:
			return String(c.get("name", cid))
	return cid


## Tek kısa ipucu: hangi ülkede, neye benzeyen bir yer (tam yer, ok, işaret yok — oyuncu kendisi bulur)
static func hint(pid: String) -> String:
	return "%s'nde bir yerde; %s." % [country_name(pid).split(" (")[0], SIGNS.get(String(PATHS[pid]["site"]["kind"]), "tuhaf izler")]


static func joined(pid: String) -> bool:
	return state(pid) >= JOINED


## Kan yatkınlığı: Namikaze soyu Uçan Yıldırım Yolu'na, Mitarashi soyu (Anko: Orochimaru'nun öğrencisi) Yılan Yolu'na erken çağrılır, sınavsız kabul edilir, yarı fiyata öğrenir, pasif 1.5 kat
const BLOOD := {"hiraishin": "namikaze", "yilan": "mitarashi"}


static func blood(pid: String) -> bool:
	return BLOOD.has(pid) and String(pr().get("clan", "")) == BLOOD[pid]


static func lv_need(pid: String, key: String) -> int:
	return int(PATHS[pid][key]) - (10 if blood(pid) else 0)   # kan yatkınlığı biraz erken açar


## Stats.skill eklentisi: katıldığın yolların pasif bonusları
static func passive(p: Dictionary, key: String) -> float:
	var v = 0.0
	var ps = p.get("paths", {})
	if not ps is Dictionary:
		return 0.0
	for pid in ps:
		if int(ps[pid].get("s", 0)) >= JOINED and PATHS.has(pid):
			v += float(PATHS[pid]["passive"].get(key, 0.0)) * (1.5 if BLOOD.has(pid) and String(p.get("clan", "")) == BLOOD[pid] else 1.0)
	return v


static func price(jid: String) -> int:
	var base = 100 + int(Data.jutsu.get(jid, {}).get("level", 1)) * 55
	var lp = String(Data.jutsu.get(jid, {}).get("learn", ""))
	if lp.begins_with("path:") and blood(lp.substr(5)):
		return base / 2
	return base


## Sıradaki adımın kısa metni (sekme ve diyalog)
static func next_step(pid: String) -> String:
	var P: Dictionary = PATHS[pid]
	match state(pid):
		UNKNOWN, RUMOR:
			return "İpucu: " + hint(pid) + " Yeri kendin bulmalısın."
		FOUND:
			if int(pr().get("level", 1)) < lv_need(pid, "join_level"):
				return "Ustan seni Güç %d olunca kabul edecek." % lv_need(pid, "join_level")
			return "%s ile konuş ve sınavını kabul et." % P["mentor"]["name"]
		TRIAL:
			return "Ustanın sınavını tamamla."
	for jid in P["order"]:
		if not jid in pr().get("learned", []):
			var lv = int(Data.jutsu.get(jid, {}).get("level", 1))
			var nm = String(Data.jutsu.get(jid, {}).get("name", jid)).split(" (")[0]
			if int(pr().get("level", 1)) < lv:
				return "Sıradaki teknik: %s (Güç %d)." % [nm, lv]
			return "Ustana dön: %s öğrenmeye hazırsın." % nm
	return "Bu yolun bütün tekniklerini öğrendin. Usta artık seninle gurur duyuyor."


# ------------------------------------------------------------------ düğüm (keşif denetimi + görev kancası /root/LegendPaths)
static func node() -> LegendPaths:
	if _node == null or not is_instance_valid(_node):
		_node = LegendPaths.new()
		_node.name = "LegendPaths"
		var root = (Engine.get_main_loop() as SceneTree).root
		var old = root.get_node_or_null("LegendPaths")
		if old:
			old.queue_free()
			old.name = "LegendPaths_old"
		root.add_child.call_deferred(_node)
	return _node


func _process(dt: float) -> void:
	_drill_tick(dt)
	_t -= dt
	if _t > 0.0 or Game.profile.is_empty() or Game.player == null or Game.paused:
		return
	_t = 2.0
	var lv = int(pr().get("level", 1))
	for pid in PATHS:
		var P: Dictionary = PATHS[pid]
		var s = state(pid)
		if s < FOUND and lairs.has(pid):
			var lp = Game.from_map(Vector2(lairs[pid][0], lairs[pid][1]))
			if Vector2(lp.x - Game.player.global_position.x, lp.z - Game.player.global_position.z).length() < 45.0:
				set_state(pid, FOUND)
				Hud.banner("GİZLİ YER BULUNDU", P["site"]["place"], P["color"])
				Hud.msg("%s burada yaşıyor. Onunla konuş [F]." % P["mentor"]["title"], P["color"].lightened(0.3), 5.0)
				if Game.profile.get("waypoint") is Array and String(Game.profile["waypoint"][3]) == P["site"]["place"]:
					Game.profile.erase("waypoint")


## Görev kancası: Missions "LegendPaths.quest_done"
func quest_done(m: Dictionary, ok: bool) -> void:
	var pid: String = m.get("path", "")
	if pid == "" or not PATHS.has(pid):
		return
	var d = st_of(pid)
	d["q"] = ""
	if not ok:
		if int(d.get("s", 0)) == TRIAL:
			d["s"] = FOUND
		Hud.msg("Usta başarısızlığını sessizce izledi. Hazır olunca yeniden dene.", Color(0.9, 0.7, 0.6))
		return
	var P: Dictionary = PATHS[pid]
	if m.get("trial", false):
		d["s"] = JOINED
		Hud.banner("YOLA KATILDIN", "%s — %s" % [P["name"], P["passive_desc"]], P["color"])
		Sfx.play("levelup", null, 0.9)
		var first: String = P["order"][0]
		if not first in pr().get("learned", []):
			Progress.learn(first)
		if Game.player:
			Game.player.apply_profile_stats()
	var jid: String = m.get("teach", "")
	if jid != "":
		_teach(pid, jid, true)
	Game.save_game()


# ------------------------------------------------------------------ usta diyaloğu
static func interact(it: Dictionary) -> void:
	var pid: String = it.get("path", "")
	if not PATHS.has(pid):
		return
	var P: Dictionary = PATHS[pid]
	var M: Dictionary = P["mentor"]
	set_state(pid, FOUND)
	var title = "%s — %s" % [M["name"], M["title"]]
	var lv = int(pr().get("level", 1))
	var s = state(pid)
	if s < JOINED:
		if s == TRIAL or String(st_of(pid).get("q", "")) != "":
			Hud.dialog(title, "\"Sınavın bitmedi. Sözünü tut.\"", [])
			return
		if lv < lv_need(pid, "join_level"):
			Hud.dialog(title, P["intro"] + "\n\n\"Ama henüz çok zayıfsın. Güç %d olunca gel.\"" % lv_need(pid, "join_level"), [])
			return
		if blood(pid):
			Hud.dialog(title, P["intro"] + "\n\nUsta bir an duraksıyor: \"Bu saçlar, bu hız... Sen Namikaze kanındansın. Sınava gerek yok; kanın seni zaten buraya getirdi.\"", [{"label": "Yola katıl", "cb": func():
				st_of(pid)["s"] = JOINED
				Hud.banner("YOLA KATILDIN: " + P["name"].to_upper(), "Kan yatkınlığı: yarı fiyat, pasif ×1.5", P["color"])
				Game.save_game()}])
			return
		var opts = []
		if Missions.active().is_empty():
			opts.append({"label": "Sınavı kabul et", "cb": func():
				st_of(pid)["s"] = TRIAL
				st_of(pid)["q"] = "trial"
				Missions.accept(_quest(pid, "trial", ""))})
		Hud.dialog(title, P["intro"] + ("" if Missions.active().is_empty() else "\n\n(Önce elindeki görevi bitir.)"), opts)
		return
	# yolda: teknik öğretme
	var opts = []
	var learned: Array = pr().get("learned", [])
	var shown = 0
	for jid in P["order"]:
		if jid in learned:
			continue
		var j: Dictionary = Data.jutsu.get(jid, {})
		var need = int(j.get("level", 1))
		var nm = String(j.get("name", jid)).split(" (")[0]
		var dark = int(P["dark"].get(jid, 0))
		var qk = String(P["quest"].get(jid, ""))
		var pc = price(jid)
		var tag = ("  ⚠ karanlık: köy itibarı -%d" % dark) if dark > 0 else ""
		var creq = canon_req(jid)
		if creq != "":   # kanon şartı (ör. yalnız Sekiz Kuyruk jinchūrikisi): usta öğretmez
			var cr = creq
			opts.append({"label": "%s — %s" % [nm, cr], "tip": j.get("desc", ""), "cb": func():
				Hud.msg("\"Bu teknik canavarın chakrasıyla yapılır — %s.\"" % cr, Color(1, 0.7, 0.5))})
		elif lv < need:
			opts.append({"label": "%s — Güç %d gerekli" % [nm, need], "tip": j.get("desc", ""), "cb": func():
				Hud.msg("Bu teknik için Güç %d olmalısın." % need, Color(1, 0.7, 0.4))})
		elif qk != "":
			var k = jid
			opts.append({"label": "%s — özel sınav (%d Ryō)%s" % [nm, pc, tag], "tip": j.get("desc", ""), "cb": func():
				if not Missions.active().is_empty():
					Hud.msg("Önce elindeki görevi bitir.", Color(1, 0.7, 0.4))
					return
				if int(pr()["ryo"]) < pc:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-pc)
				st_of(pid)["q"] = k
				Missions.accept(_quest(pid, qk, k))})
		elif DRILLS.has(jid) and drill_spots.has(pid):
			var k3 = jid
			opts.append({"label": "Antrenman: %s (%d Ryō)%s" % [nm, pc, tag], "tip": j.get("desc", ""), "cb": func():
				if int(pr()["ryo"]) < pc:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-pc)
				node().start_drill(pid, k3)})
		else:
			var k2 = jid
			opts.append({"label": "Öğren: %s (%d Ryō)%s" % [nm, pc, tag], "tip": j.get("desc", ""), "cb": func():
				if int(pr()["ryo"]) < pc:
					Hud.msg("Yeterli Ryō yok.", Color(1, 0.5, 0.4))
					return
				Progress.add_ryo(-pc)
				_teach(pid, k2, false)})
		shown += 1
		if shown >= 4:
			break
	var txt = "\"%s\"\n\n%s" % [["Bugün ne öğrenmeye geldin?", "Pratik yapmadan yeni teknik yok... ama sen çalışkansın.", "Göster bakalım ne kadar ilerledin."][lv % 3], next_step(pid)]
	if opts.is_empty():
		txt = "\"Sana öğretebileceğim her şeyi öğrendin. Artık kendi yolunu çiz.\""
	Hud.dialog(title, txt, opts)


## Antrenman başlar: vuruşta kütüklere görünmez kukla konur (kütük zaten modelli), turda avlu merkezi etrafında açı izlenir
func start_drill(pid: String, jid: String) -> void:
	end_drill(false)
	var D: Dictionary = DRILLS[jid]
	var sp: Dictionary = drill_spots[pid]
	var M: Dictionary = PATHS[pid]["mentor"]
	drill = {"pid": pid, "jid": jid, "type": D["type"], "n": int(D["n"]), "c": 0, "t": 0.0, "time": float(D.get("time", 0.0)), "dummies": [],
		"weights": bool(D.get("weights", false)), "last_ang": 0.0, "acc": 0.0}
	var posts: Array = sp.get("posts", [])
	var center = Vector3.ZERO
	for q in posts:
		center += q
	center /= maxf(1.0, posts.size())
	drill["center"] = center + Vector3(0, 0, 4.0)
	if D["type"] in ["collect", "survive", "throws"]:
		center = sp.get("center", Game.player.global_position)
		drill["center"] = center
	drill["rain"] = bool(D.get("rain", false))
	drill["min_d"] = float(D.get("min_d", 0.0))
	if D["type"] == "collect" and String(D.get("look", "")) == "weapon":
		# talimden kalan silahlar avluya eğik saplanmış: yaklaşınca toplanır (parşömene mühürlenir)
		var pj = PathJutsu.get_pinst()
		for k in int(D["n"]):
			var a = TAU * k / float(D["n"]) + randf_range(-0.3, 0.3)
			var q: Vector3 = center + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 11.0)
			q.y = Game.ground_height(q.x, q.z)
			var w = pj.mi_of(pj.weapon_mesh(PathJutsu.WEAPON_KINDS[k % PathJutsu.WEAPON_KINDS.size()]))
			get_tree().current_scene.add_child(w)
			w.global_position = q + Vector3.UP * 0.6
			w.rotation_degrees = Vector3(-90 + randf_range(-25, 25), randf() * 360.0, randf_range(-20, 20))   # ucu toprakta
			w.scale = Vector3.ONE * 2.0
			drill["dummies"].append(w)
	elif D["type"] == "tend":
		# her hedefin çevresinde yeşil halka: içinde durdukça dolar (çıkarsan sıfırlanır), dolunca şifa parıltısı + halka altın olur
		drill["tend"] = []
		for q in sp.get(String(D.get("spots", "")), []):
			var ring = MeshInstance3D.new()
			var tm3 = TorusMesh.new()
			tm3.inner_radius = 0.72
			tm3.outer_radius = 0.86   # yan yana sedirlerde halkalar iç içe geçmesin
			ring.mesh = tm3
			var rm3 = StandardMaterial3D.new()
			rm3.albedo_color = Color(0.45, 1.0, 0.6)
			rm3.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ring.material_override = rm3
			get_tree().current_scene.add_child(ring)
			ring.global_position = (q as Vector3) + Vector3.UP * 0.08
			drill["dummies"].append(ring)
			drill["tend"].append({"pos": q, "t": 0.0, "done": false, "ring": ring, "mat": rm3})
		drill["dwell"] = float(D.get("dwell", 3.0))
		drill["n"] = mini(int(D["n"]), (drill["tend"] as Array).size())
		if drill.has("center") and not (drill["tend"] as Array).is_empty():
			drill["center"] = drill["tend"][0]["pos"]
	elif D["type"] == "collect" and String(D.get("look", "")) == "butterfly":
		# rüzgârla dağılmış kâğıt kelebekler: avluda daireler çizip süzülür, kanat çırpar; yaklaşınca yakalanır
		for k in int(D["n"]):
			var a = TAU * k / float(D["n"])
			var q: Vector3 = center + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 12.0)
			q.y = Game.ground_height(q.x, q.z) + randf_range(0.9, 1.8)
			var bf = Node3D.new()
			for sd in [-1.0, 1.0]:
				var wing = MeshInstance3D.new()
				var qm = QuadMesh.new()
				qm.size = Vector2(0.32, 0.26)
				wing.mesh = qm
				var wm = StandardMaterial3D.new()
				wm.albedo_color = [Color(0.97, 0.96, 0.92), Color(0.75, 0.65, 0.95), Color(0.95, 0.75, 0.8)][k % 3]
				wm.cull_mode = BaseMaterial3D.CULL_DISABLED
				wm.emission_enabled = true
				wm.emission = wm.albedo_color * 0.4
				wing.material_override = wm
				wing.rotation_degrees = Vector3(-90, 0, 0)
				var hinge = Node3D.new()
				hinge.add_child(wing)
				wing.position = Vector3(sd * 0.16, 0, 0)
				bf.add_child(hinge)
				var ft = hinge.create_tween().set_loops()
				ft.tween_property(hinge, "rotation_degrees:z", sd * 55.0, 0.12)
				ft.tween_property(hinge, "rotation_degrees:z", -sd * 15.0, 0.12)
			get_tree().current_scene.add_child(bf)
			bf.global_position = q
			var ph = randf() * TAU
			var rr = randf_range(1.5, 3.0)
			var mt = bf.create_tween().set_loops()
			mt.tween_method(func(v: float):
				if is_instance_valid(bf):
					bf.global_position = q + Vector3(cos(v + ph) * rr, sin(v * 2.0) * 0.4, sin(v + ph) * rr)
					bf.rotation.y = -(v + ph), 0.0, TAU, randf_range(5.0, 8.0))
			drill["dummies"].append(bf)
	elif D["type"] == "collect":
		# in çevresine dağılmış zehir keseleri (mor parlayan küçük keseler): yaklaşınca toplanır
		for k in int(D["n"]):
			var a = TAU * k / float(D["n"]) + randf_range(-0.3, 0.3)
			var q: Vector3 = Missions.open_ground(center + Vector3(cos(a), 0, sin(a)) * randf_range(9.0, 20.0), 8.0) + Vector3.UP * 0.3   # kaya/ağaç/yapı içine düşmesin
			var bag = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = 0.28
			sm.height = 0.46
			bag.mesh = sm
			var bm = StandardMaterial3D.new()
			var bc: Color = D.get("color", Color(0.6, 0.25, 0.85))   # antrenmana göre renk (zehir kesesi mor, yağ kabağı kehribar)
			bm.albedo_color = bc
			bm.emission_enabled = true
			bm.emission = bc.darkened(0.08)
			bm.emission_energy_multiplier = 1.4
			bag.material_override = bm
			get_tree().current_scene.add_child(bag)
			bag.global_position = q
			var bt = bag.create_tween().set_loops()
			bt.tween_property(bag, "position:y", q.y + 0.25, 0.8).set_trans(Tween.TRANS_SINE)
			bt.tween_property(bag, "position:y", q.y, 0.8).set_trans(Tween.TRANS_SINE)
			drill["dummies"].append(bag)
	elif D["type"] == "survive" and drill["rain"]:
		# silah yağmuru çemberi: yerde turuncu halka; kunailer _rain_tick ile gökten düşer
		var ring2 = MeshInstance3D.new()
		var tm2 = TorusMesh.new()
		tm2.inner_radius = 6.6
		tm2.outer_radius = 7.0
		ring2.mesh = tm2
		var rmat2 = StandardMaterial3D.new()
		rmat2.albedo_color = Color(0.95, 0.6, 0.3)
		rmat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring2.material_override = rmat2
		get_tree().current_scene.add_child(ring2)
		ring2.global_position = center + Vector3.UP * 0.1
		drill["dummies"].append(ring2)
		drill["rain_t"] = 1.0
	elif D["type"] == "survive":
		# zehirli mor sis alanı (yerde halka + yükselen zehir zerreleri); içinde durdukça can erir
		var ring = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 6.6
		tm.outer_radius = 7.0
		ring.mesh = tm
		var rmat = StandardMaterial3D.new()
		rmat.albedo_color = Color(0.7, 0.3, 1.0)
		rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = rmat
		get_tree().current_scene.add_child(ring)
		ring.global_position = center + Vector3.UP * 0.1
		drill["dummies"].append(ring)
		var mist = FX.burst(center + Vector3.UP * 0.6, {"amount": 50, "life": 2.0, "tex": FX.tex_spark, "size": 0.5, "radius": 6.0, "vmin": 0.2, "vmax": 0.8,
			"dir": Vector3.UP, "spread": 20.0, "gravity": Vector3(0, 0.4, 0), "colors": [Color(0.75, 0.4, 1.0, 0.0), Color(0.7, 0.35, 1.0, 0.6), Color(0.5, 0.2, 0.8, 0.0)]})
		if mist:
			mist.one_shot = false
			drill["dummies"].append(mist)
	if D["type"] in ["hits", "throws"]:
		for q in posts:
			var d = TrainingDummy.new()
			d.set_meta("drill", true)
			if D["type"] == "throws":
				d.set_meta("drill_throw", true)   # hedef tahtası: yalnız atış sayılır
			d.max_hp = 1e9
			d.hp = 1e9
			get_tree().current_scene.add_child(d)
			d.global_position = (q as Vector3) + (Vector3(0, 1.3, 0) if D["type"] == "throws" else Vector3(0, 0, 1.0))
			d.vis.visible = false
			drill["dummies"].append(d)
	else:
		var v = Game.player.global_position - Vector3(drill["center"])
		drill["last_ang"] = atan2(v.z, v.x)
		if drill["weights"]:
			Buffs.add("drill_weights", 9999.0, {"speed": 0.7, "_name": "Bacak Ağırlıkları", "_desc": "antrenman: hız -%30"})
	Hud.dialog("%s — %s" % [M["name"], M["title"]], "\"%s\"" % D["say"], [])
	Hud.banner("ANTRENMAN", "%s: %s" % [String(Data.jutsu.get(jid, {}).get("name", jid)), _drill_text()], PATHS[pid]["color"])


func _drill_text() -> String:
	var unit = {"hits": "vuruş", "throws": "isabet", "tend": String(DRILLS.get(String(drill["jid"]), {}).get("item", "")), "laps": "tur", "collect": String(DRILLS.get(String(drill["jid"]), {}).get("item", "parça")), "survive": "sn"}.get(String(drill["type"]), "")
	var tl = (" — %d sn" % int(maxf(0.0, float(drill["time"]) - float(drill["t"])))) if float(drill["time"]) > 0.0 else ""
	return "%d / %d %s%s" % [int(drill["c"]), int(drill["n"]), unit, tl]


## Kukla vuruşu (Progress.on_dummy_hit çağırır)
func on_drill_hit(d: Node) -> void:
	if drill.is_empty() or not d.has_meta("drill") or not drill["type"] in ["hits", "throws"]:
		return
	if float(drill.get("min_d", 0.0)) > 0.0 and Game.player:
		var dd = Game.player.global_position - (d as Node3D).global_position
		if Vector2(dd.x, dd.z).length() < float(drill["min_d"]):
			Combat.popup_text((d as Node3D).global_position + Vector3.UP * 2.4, "Çok yakın! Geri çekil", Color(1, 0.7, 0.4))
			return
	drill["c"] = int(drill["c"]) + 1
	Hud.objective_progress(_drill_text())
	if int(drill["c"]) >= int(drill["n"]):
		end_drill(true)


func _drill_tick(dt: float) -> void:
	if drill.is_empty() or Game.player == null:
		return
	if Interiors.inst and Interiors.inst.inside != "":
		return   # usta içeride (laboratuvar) anlattı: antrenman dışarıda, çıkana kadar sayaç bekler
	drill["t"] = float(drill["t"]) + dt
	var c: Vector3 = drill["center"]
	var pp = Game.player.global_position
	if Vector2(pp.x - c.x, pp.z - c.z).length() > 45.0:
		Hud.msg("Antrenmandan ayrıldın. Usta başını iki yana salladı.", Color(1, 0.6, 0.45))
		end_drill(false)
		return
	if float(drill["time"]) > 0.0 and float(drill["t"]) > float(drill["time"]):
		Hud.msg("Süre doldu! \"Yeniden! Gençlik pes etmez!\"", Color(1, 0.6, 0.45))
		end_drill(false)
		return
	if drill["type"] == "laps":
		var v = pp - c
		var a = atan2(v.z, v.x)
		var da = wrapf(a - float(drill["last_ang"]), -PI, PI)
		drill["last_ang"] = a
		if Vector2(v.x, v.z).length() > 7.0:   # koşu izinde (avlunun kenarı)
			drill["acc"] = float(drill["acc"]) + da
		var laps = int(absf(float(drill["acc"])) / TAU)
		if laps != int(drill["c"]):
			drill["c"] = laps
			Hud.objective_progress(_drill_text())
			if laps >= int(drill["n"]):
				end_drill(true)
	elif drill["type"] == "tend":
		for td in drill["tend"]:
			if td["done"]:
				continue
			var q: Vector3 = td["pos"]
			if Vector2(pp.x - q.x, pp.z - q.z).length() < 1.1:
				td["t"] = float(td["t"]) + dt
				(td["mat"] as StandardMaterial3D).albedo_color = Color(0.45, 1.0, 0.6).lerp(Color(1.0, 0.95, 0.5), clampf(float(td["t"]) / float(drill["dwell"]), 0.0, 1.0))
				if int(float(td["t"]) * 4.0) != int((float(td["t"]) - dt) * 4.0):
					FX.burst(q + Vector3.UP * 0.9, {"amount": 6, "life": 0.7, "size": 0.18, "radius": 0.3, "vmin": 0.4, "vmax": 1.0, "dir": Vector3.UP, "spread": 30.0,
						"colors": [Color(0.5, 1.0, 0.6, 1.0), Color(0.4, 0.9, 0.5, 0.0)]})   # avuçtan yeşil chakra
				Hud.objective_progress("%s  —  %d%%" % [_drill_text(), int(100.0 * float(td["t"]) / float(drill["dwell"]))])
				if float(td["t"]) >= float(drill["dwell"]):
					td["done"] = true
					(td["mat"] as StandardMaterial3D).albedo_color = Color(1.0, 0.85, 0.35)
					FX.burst(q + Vector3.UP, {"amount": 30, "life": 1.0, "size": 0.3, "radius": 0.5, "vmin": 1.0, "vmax": 3.0, "dir": Vector3.UP, "spread": 50.0,
						"colors": [Color(0.6, 1.0, 0.7, 1.0), Color(0.4, 0.9, 0.5, 0.0)]})
					Sfx.play("heal", q, 1.1, 0.6)
					drill["c"] = int(drill["c"]) + 1
					Hud.objective_progress(_drill_text())
					if int(drill["c"]) >= int(drill["n"]):
						end_drill(true)
						return
			elif float(td["t"]) > 0.0:
				td["t"] = 0.0   # ayrıldın: chakra dağıldı, baştan
				(td["mat"] as StandardMaterial3D).albedo_color = Color(0.45, 1.0, 0.6)
				Hud.msg("Ayrıldın — chakran dağıldı, baştan.", Color(1, 0.7, 0.5))
	elif drill["type"] == "collect":
		for bag in drill["dummies"]:
			if is_instance_valid(bag) and bag.visible and bag.global_position.distance_to(pp + Vector3.UP * 0.5) < 1.6:
				bag.visible = false
				drill["c"] = int(drill["c"]) + 1
				Sfx.play("pickup", pp, 1.2, 0.6)
				Hud.objective_progress(_drill_text())
				if int(drill["c"]) >= int(drill["n"]):
					end_drill(true)
					return
	elif drill["type"] == "survive":
		var inside = Vector2(pp.x - c.x, pp.z - c.z).length() < 6.8
		if not inside:
			if float(drill["c"]) > 0.0:
				Hud.msg("Sisten çıktın — baştan!", Color(1, 0.6, 0.45))
			drill["c"] = 0
			drill["acc"] = 0.0
		else:
			drill["acc"] = float(drill["acc"]) + dt
			if drill.get("rain", false):
				_rain_tick(dt, c, pp)
			else:
				Game.player.hp = maxf(1.0, Game.player.hp - Game.player.max_hp * 0.012 * dt * (1.0 - passive(pr(), "poison_resist")))   # zehir yavaşça yakar (asla öldürmez)
			if int(drill["acc"]) != int(drill["c"]):
				drill["c"] = int(drill["acc"])
				Hud.objective_progress(_drill_text())
			if int(drill["c"]) >= int(drill["n"]):
				Mastery.gain(pr(), "dayaniklilik", 0.5)
				end_drill(true)
				return
	if drill.is_empty():
		return
	if drill["type"] in ["hits", "throws"] and int(drill["t"] * 4.0) % 4 == 0:
		Hud.objective_progress(_drill_text())


## Tekkōsen antrenmanı: usta çemberin içine kunai yağdırır. Düşüş noktası yerde kırmızı işaretle 0.45 sn önceden görünür
## (gelen silahı okuyan göz); işaretin üstünde kalan isabet alır (öldürmez). Saplanan kunailer biraz kalır.
func _rain_tick(dt: float, c: Vector3, pp: Vector3) -> void:
	drill["rain_t"] = float(drill.get("rain_t", 0.0)) - dt
	if float(drill["rain_t"]) > 0.0:
		return
	drill["rain_t"] = randf_range(0.28, 0.45)
	# yarısı oyuncunun ayağına, yarısı çemberde rastgele
	var q: Vector3
	if randf() < 0.5:
		q = pp + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	else:
		var a = randf() * TAU
		q = c + Vector3(cos(a), 0, sin(a)) * randf_range(0.0, 6.5)
	q.y = Game.ground_height(q.x, q.z)
	var mark = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.75
	cm.bottom_radius = 0.75
	cm.height = 0.02
	mark.mesh = cm
	var mm = StandardMaterial3D.new()
	mm.albedo_color = Color(1.0, 0.25, 0.15, 0.55)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark.material_override = mm
	get_tree().current_scene.add_child(mark)
	mark.global_position = q + Vector3.UP * 0.05
	var pj = PathJutsu.get_pinst()
	var k = pj.mi_of(pj.weapon_mesh("kunai"))
	get_tree().current_scene.add_child(k)
	k.scale = Vector3.ONE * 1.4
	k.global_position = q + Vector3(randf_range(-2, 2), 14.0, randf_range(-2, 2))
	k.rotation_degrees = Vector3(-90, randf() * 360.0, 0)   # uç aşağı
	var tw = k.create_tween()
	tw.tween_interval(0.45)
	tw.tween_property(k, "global_position", q + Vector3.UP * 0.3, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_instance_valid(mark):
			mark.queue_free()
		Sfx.play("hit", q, randf_range(1.3, 1.6), 0.35)
		FX.dust(q, 0.25)
		var pl = Game.player
		if pl and not drill.is_empty() and Vector2(pl.global_position.x - q.x, pl.global_position.z - q.z).length() < 0.9:
			pl.hp = maxf(1.0, pl.hp - pl.max_hp * 0.06)   # antrenman: acıtır ama öldürmez
			Combat.popup_text(pl.global_position + Vector3.UP * 2.2, "Gelen silahı gör!", Color(1, 0.5, 0.35)))
	tw.tween_interval(1.6)
	tw.tween_callback(k.queue_free)


func end_drill(ok: bool) -> void:
	if drill.is_empty():
		return
	for d in drill.get("dummies", []):
		if is_instance_valid(d):
			d.queue_free()
	Buffs.remove("drill_weights")
	var pid = String(drill["pid"])
	var jid = String(drill["jid"])
	drill = {}
	Hud.objective_progress("")
	if ok:
		Hud.banner("ANTRENMAN TAMAM", "Usta gözleri dolu dolu başparmağını kaldırdı!", PATHS[pid]["color"])
		_teach(pid, jid, false)


## Kanon şartı: "jin:<bijū>" — yalnız o kuyruklu canavarın jinchūrikisi öğrenir/kullanır. "" = şart yok ya da karşılanıyor
static func canon_req(jid: String) -> String:
	var need = String(Data.jutsu.get(jid, {}).get("need", ""))
	var jin = TailedBeasts.player_jinchuriki()
	if need == "jin:any" or need == "beast":   # kuyruklu canavar chakrası: herhangi bir jinchūriki
		if jin == "":
			return "yalnız jinchūriki"
	elif need.begins_with("jin:"):
		var b = need.substr(4)
		if jin != b:
			return "yalnız %s jinchūrikisi" % ("Sekiz Kuyruk" if b == "gyuki" else b.capitalize())
	return ""


static func _teach(pid: String, jid: String, from_quest: bool) -> void:
	var P: Dictionary = PATHS[pid]
	if jid in pr().get("learned", []):
		return
	Progress.learn(jid)
	if jid.begins_with("bashosen_") and not "bashosen" in Gear.owned_ids(pr()):
		Gear.grant(pr(), "bashosen")
		Hud.msg("Bashōsen artık senin: Bashōsen teknikleri için yelpazeyi kuşan.", Color(1, 0.6, 0.6), 5.0)
	if pid == "kapi" and not "gates" in pr().get("skills", []):
		pr()["skills"].append("gates")   # Sekiz Kapı modu (B) bu yolla açılır
		Hud.msg("Sekiz Kapı açıldı: B tuşuyla kapıları zorla.", Color(0.5, 1, 0.5))
	var dark = int(P["dark"].get(jid, 0))
	if dark > 0:
		Missions._rep(Progress.home(), -dark)
		Hud.msg("Yasak bir sanat öğrendin. Köyün seni şüpheyle izliyor (itibar -%d)." % dark, Color(0.85, 0.5, 0.9), 5.0)
	if Game.player:
		FX.aura(Game.player, P["color"], 1.4)
	Sfx.play("levelup", null, 1.2, 0.6)
	if not from_quest:
		Game.save_game()


# ------------------------------------------------------------------ görevler (Missions adım türleri)
static func _near(at: Array, d: float) -> Array:
	var a = randf() * TAU
	return [float(at[0]) + cos(a) * d, float(at[1]) + sin(a) * d]


static func _quest(pid: String, kind: String, teach: String) -> Dictionary:
	var at: Array = lairs.get(pid, [Game.to_map(Game.player.global_position).x, Game.to_map(Game.player.global_position).y])
	var base = {"rank": "B", "village": Progress.home(), "hook": "LegendPaths.quest_done", "path": pid, "teach": teach, "trial": kind == "trial"}
	var q = {}
	match pid + ":" + kind:
		"kil:trial":
			q = {"title": "Sanatın Kanıtı", "rank": "C",
				"brief": "Sanatçı, kanyondaki kil damarlarından yoğrulabilir kil toplamanı ve atölyeyi soymaya gelen haydutları 'sanatla' kovmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 280.0), "item": "chakra kili", "n": 6, "spread": 32, "text": "Kanyondan chakra kili topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [3, 3], "text": "Atölyeye saldıran haydutları püskürt."}]}
		"kil:art":
			q = {"title": "Son Sanat Eseri", "rank": "A",
				"brief": "Ustanın en büyük eseri için eski bir taş kale yıkılmalı. Kaleyi tutan kaçak kayaninjalarını dağıt ve sanatın gürültüsünü göster.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 900.0), "text": "Taş kaleye git."},
					{"kind": "kill", "at": _near(at, 900.0), "enemy": "rogue", "n": 4, "camp": true, "boss": {"name": "Taş Muhafız Ganseki", "hp": 3200.0, "level": 30, "power": 2.6}, "text": "Kalenin muhafızlarını yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kil Atölyesi", "text": "Atölyeye dön."}]}
		"kakuzu:trial":
			q = {"title": "Ödülün Bedeli", "rank": "C",
				"brief": "İplik ustası, başına ödül konmuş üç kaçağı getirmeni istiyor. Para asla ihanet etmez.",
				"steps": [
					{"kind": "kill", "at": _near(at, 450.0), "enemy": "rogue", "n": 3, "camp": true, "text": "Ödüllü kaçakları avla."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kara İplik Mezarlığı", "text": "Ödülü ustaya getir."}]}
		"kakuzu:heart":
			q = {"title": "Beşinci Kalp", "rank": "A",
				"brief": "Kalp çalmak için güçlü bir rakibin kalbini sökmen gerek. Mezarlığa dadanan şimşek ninjasını yen.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 800.0), "text": "Şimşek ninjasının izini sür."},
					{"kind": "kill", "at": _near(at, 800.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Raijin Kogane", "hp": 3400.0, "level": 31, "power": 2.7}, "text": "Rakibi yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kara İplik Mezarlığı", "text": "Mezarlığa dön."}]}
		"hiraishin:trial":
			q = {"title": "Sarı Şimşeğin İşaretleri", "rank": "C",
				"brief": "Usta harabelerin dört bir yanına mühürlü kunailer saplamış. Hepsini bul — hızlı ol!",
				"steps": [
					{"kind": "collect", "at": _near(at, 320.0), "item": "mühürlü kunai", "n": 6, "spread": 40, "text": "Mühürlü kunaileri topla (6)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Yıldırım Mührü Tapınağı", "text": "Tapınağa dön."}]}
		"hiraishin:marks":
			q = {"title": "Zaman-Uzay Formülü", "rank": "A",
				"brief": "Gerçek ışınlanma için beş mühür taşına formül yaz ve formülü çalmaya gelenleri püskürt.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 18, "label": "[F] Mühür formülünü yaz", "fx": "seal", "text": "Beş mühür taşına formül yaz (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Formülü çalmaya gelenleri püskürt."}]}
		"chidori:trial":
			q = {"title": "Keskinliğin Sınavı", "rank": "C",
				"brief": "Usta, uçurumun dibindeki samuray kaçaklarını yalnızca kılıçla yenmeni istiyor.",
				"steps": [
					{"kind": "kill", "at": _near(at, 420.0), "enemy": "samurai", "n": 4, "camp": true, "text": "Kaçak samurayları yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Bin Kuş Uçurumu", "text": "Uçuruma dön."}]}
		"chidori:storm":
			q = {"title": "Gökteki Ejder", "rank": "A",
				"brief": "Kirin için doğal bir fırtına gerekir. Beş zirvede ateş topu yakarak bulutları ısıt, sonra fırtınayı bölmeye gelenleri kov.",
				"steps": [
					{"kind": "points", "at": _near(at, 60.0), "n": 5, "spread": 24, "label": "[F] Zirvede bulutları ısıt", "fx": "seal", "text": "Beş zirvede bulutları ısıt (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Fırtınayı bölenleri püskürt."}]}
		"jashin:trial":
			q = {"title": "İlk Kurban", "rank": "C",
				"brief": "Rahip, tapınağa saldıran kâfir paralı askerleri Jashin'e kurban etmeni istiyor.",
				"steps": [
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [3, 4], "text": "Tapınağa saldıranları püskürt."},
					{"kind": "collect", "at": _near(at, 200.0), "item": "kan şişesi", "n": 4, "spread": 24, "text": "Ayin için kan şişelerini topla (4)."}]}
		"jashin:ritual":
			q = {"title": "Lanet Çemberi", "rank": "A",
				"brief": "Ölüm mahkûmiyeti ayini için güçlü bir rakibin kanı gerekir. Onu bul, yen ve çembere dön.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 850.0), "text": "Kurbanın izini sür."},
					{"kind": "kill", "at": _near(at, 850.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Gümüş Muhafız Asuka", "hp": 3300.0, "level": 31, "power": 2.6}, "text": "Kurbanı yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kanlı Ayin Tapınağı", "text": "Çembere dön."}]}
		"hachibi:trial":
			q = {"title": "Ritmini Bul", "rank": "C",
				"brief": "Usta, şelalenin çevresindeki beş ritim taşını çalmanı ve ritmi bozan haydutları kovmanı istiyor. Yo!",
				"steps": [
					{"kind": "points", "at": _near(at, 50.0), "n": 5, "spread": 20, "label": "[F] Ritim taşını çal", "fx": "seal", "text": "Beş ritim taşını çal (5)."},
					{"kind": "kill", "at": _near(at, 380.0), "enemy": "bandit", "n": 4, "camp": true, "text": "Ritmi bozan haydutları kov."}]}
		"hachibi:falls":
			q = {"title": "Gerçekler Şelalesi", "rank": "A",
				"brief": "Canavar topu için içindeki karanlıkla yüzleşmelisin. Şelalenin altına git ve kendi gölgeni yen.",
				"steps": [
					{"kind": "goto", "at": _near(at, 120.0), "r": 10.0, "name": "Şelalenin Altı", "text": "Şelalenin altına git."},
					{"kind": "kill", "at": _near(at, 120.0), "enemy": "rogue", "n": 2, "camp": true, "boss": {"name": "Karanlık Benlik", "hp": 3600.0, "level": 32, "power": 2.8}, "text": "Karanlık benliğini yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Şelale", "text": "Ustaya dön."}]}
		"sumi:trial":
			q = {"title": "Titremeyen El", "rank": "C",
				"brief": "Usta, karakolun çevresine dağılmış eski Kök mühür parşömenlerini toplamanı ve onları arayan kaçak Kök ajanlarını durdurmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 240.0), "item": "Kök parşömeni", "n": 6, "spread": 30, "text": "Dağılmış Kök parşömenlerini topla (6)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [2, 3], "text": "Parşömenlerin peşindeki kaçak ajanları püskürt."}]}
		"sumi:god":
			q = {"title": "Tanrı Çizimi", "rank": "A",
				"brief": "Dev mürekkep figürü için ustanın eski Kök arkadaşının mühürlü fırçası gerek. Fırçayı çalan kaçak Kök komutanını bul ve yen.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 850.0), "text": "Kaçak komutanın izini sür."},
					{"kind": "kill", "at": _near(at, 850.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kök Komutanı Kurosen", "hp": 2800.0, "level": 26, "power": 2.5}, "text": "Kaçak Kök komutanını yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Yıkık Kök Karakolu", "text": "Fırçayla ustaya dön."}]}
		"akasuna:trial":
			q = {"title": "Elin Hızı", "rank": "C",
				"brief": "Usta, kumulların arasına gömülmüş eski kukla parçalarını toplamanı ve atölyeyi soymaya gelen haydutları kovmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 260.0), "item": "kukla parçası", "n": 6, "spread": 32, "text": "Kuma gömülü kukla parçalarını topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [2, 3], "text": "Atölyeye saldıran haydutları püskürt."}]}
		"akasuna:kazekage":
			q = {"title": "Kayıp Kazekage", "rank": "A",
				"brief": "Yıllar önce kaybolan Üçüncü Kazekage'nin bedenini taşıyan bir kervanın izi bulundu. Kervanı basan kaçak kuklacıyı yen, kukla parşömenini getir.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 900.0), "text": "Kervanın izini sür."},
					{"kind": "kill", "at": _near(at, 900.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kaçak Kuklacı Kugiri", "hp": 3000.0, "level": 30, "power": 2.6}, "text": "Kaçak kuklacıyı yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kızıl Kum Atölyesi", "text": "Parşömenle ustaya dön."}]}
		"akasuna:body":
			q = {"title": "Sonsuz Sanat", "rank": "S",
				"brief": "İnsan kuklası için güçlü bir shinobinin bedeni gerek. Çölde avlanan ödüllü kaçak ninjayı yen: bedeni ilk insan kuklan olacak.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 1000.0), "text": "Ödüllü kaçağın izini sür."},
					{"kind": "kill", "at": _near(at, 1000.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kızıl Akrep Rōshi", "hp": 4200.0, "level": 34, "power": 3.0}, "text": "Kaçağı yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kızıl Kum Atölyesi", "text": "Bedeni atölyeye getir."}]}
		"kagit:trial":
			q = {"title": "Kâğıdın Sabrı", "rank": "C",
				"brief": "Usta, rüzgârın dağıttığı yüz kâğıt turnayı toplamanı ve onları çalmaya gelen haydutları kovmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 260.0), "item": "kâğıt turna", "n": 6, "spread": 34, "text": "Dağılan kâğıt turnaları topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [2, 3], "text": "Kuleye saldıran haydutları püskürt."}]}
		"kagit:sea":
			q = {"title": "Kâğıt Denizi", "rank": "A",
				"brief": "Bin patlayıcı etiketlik bir deniz için yasak bir mühür kâğıdı gerek. Onu saklayan kaçak kâğıt ustasını bul ve yen.",
				"steps": [
					{"kind": "track", "from": at, "to": _near(at, 900.0), "text": "Kaçak kâğıt ustasının izini sür."},
					{"kind": "kill", "at": _near(at, 900.0), "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kara Origami Shiga", "hp": 3000.0, "level": 30, "power": 2.6}, "text": "Kaçak kâğıt ustasını yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kâğıt Çiçek Kulesi", "text": "Mühür kâğıdıyla ustaya dön."}]}
		"gama:trial":
			q = {"title": "Kurbağanın Gözü", "rank": "C",
				"brief": "Bilge, kayıp genç kurbağaları bulup tapınağa getirmeni ve onları avlayan yılan avcılarını dağıtmanı istiyor.",
				"steps": [
					{"kind": "collect", "at": _near(at, 300.0), "item": "kayıp kurbağa", "n": 5, "spread": 30, "text": "Kayıp kurbağaları bul (5)."},
					{"kind": "kill", "at": _near(at, 420.0), "enemy": "oto", "n": 3, "camp": true, "text": "Kurbağa avcılarını dağıt."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Kurbağa Tapınağı", "text": "Tapınağa dön."}]}
		"gama:sage":
			q = {"title": "Doğanın Sesi", "rank": "A",
				"brief": "Kurbağa yaşlılarının şarkısını taşıyabilmek için doğa enerjisini hissetmelisin. Beş yosun taşında meditasyon yap ve rahatsız edenleri kov.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 16, "label": "[F] Yosun taşında meditasyon", "fx": "seal", "text": "Beş yosun taşında meditasyon yap (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Meditasyonu bölenleri püskürt."}]}
		"tip:trial":
			q = {"title": "Şifacının Sınavı", "rank": "C",
				"brief": "Dağ yolunda pusuya düşen bir kervanın yaralıları ölmek üzere. Haydutları dağıt, yaralıların yanına git ve şifa otlarını topla.",
				"steps": [
					{"kind": "kill", "at": _near(at, 380.0), "enemy": "bandit", "n": 4, "camp": true, "text": "Kervanı basan haydutları dağıt."},
					{"kind": "collect", "at": _near(at, 200.0), "item": "şifa otu", "n": 5, "spread": 24, "text": "Şifa otlarını topla (5)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Yuge Şifa Tapınağı", "text": "Otlarla ustaya dön."}]}
		"tip:seal":
			q = {"title": "Yaradılış Mührü", "rank": "A",
				"brief": "Yaradılış Yenilenmesi için alnına yıllarca chakra biriktiren bir mühür gerekir. Beş şifa taşını uyandır ve mührü korurken gelen kaçakları püskürt.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 16, "label": "[F] Şifa taşına chakra ver", "fx": "seal", "text": "Beş şifa taşını uyandır (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 4], "text": "Mührü korurken saldıranları püskürt."}]}
		"kapi:trial":
			q = {"title": "Gençliğin Sınavı", "rank": "C",
				"brief": "Usta, dağın tepesine kadar koşmanı ve oradaki haydut çetesini yalnızca yumruklarınla dağıtmanı istiyor. Sonra geri koş!",
				"steps": [
					{"kind": "goto", "at": _near(at, 600.0), "r": 14.0, "name": "Dağın Tepesi", "text": "Dağın tepesine koş."},
					{"kind": "kill", "at": _near(at, 600.0), "enemy": "bandit", "n": 5, "camp": true, "text": "Haydut çetesini dağıt."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Seishun Dojosu", "text": "Dojoya geri koş."}]}
		"kapi:gates":
			var cliff = _near(at, 900.0)
			q = {"title": "Kapıların Bedeli", "rank": "A",
				"brief": "Kapıları açmak bedeni parçalar. Usta, seni bir şelalenin altında dayanıklılığını sınamaya ve ardından güçlü bir rakibi yenmeye gönderiyor.",
				"steps": [
					{"kind": "goto", "at": cliff, "r": 14.0, "name": "Şelale", "text": "Şelalenin altına git."},
					{"kind": "kill", "at": cliff, "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Demir Yumruk Gōzan", "hp": 2400.0, "level": 26, "power": 2.6}, "text": "Demir Yumruk'u yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Seishun Dojosu", "text": "Dojoya dön."}]}
		"yilan:trial":
			var den = _near(at, 420.0)
			q = {"title": "Yılanın Sınavı", "rank": "B",
				"brief": "Usta, kabuk değiştiren dev yılanın izinden gidip o yılanı besleyen Ses ninjalarının inini dağıtmanı istiyor. Dönüşte yılanın döktüğü pulları getir.",
				"steps": [
					{"kind": "track", "from": at, "to": den, "text": "Kabuk değiştiren dev yılanın izini sür."},
					{"kind": "kill", "at": den, "enemy": "oto", "n": 4, "camp": true, "boss": {"name": "Zehirli Diş Kōja", "hp": 900.0, "level": 14, "power": 1.8}, "text": "Ses ninjalarının inini dağıt."},
					{"kind": "collect", "at": _near(at, 160.0), "item": "yılan pulu", "n": 5, "spread": 24, "text": "Dökülmüş yılan pullarını topla (5)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Ryūchi İni", "text": "Pullarla ustaya dön."}]}
		"yilan:sword":
			var shrine = _near(at, 650.0)
			q = {"title": "Kılıcın Yuvası", "rank": "A",
				"brief": "Kusanagi'nin bir eşi, terk edilmiş bir tapınakta kılıç yutan bir muhafızın midesinde saklanıyor. Muhafızı yen; kılıcı yutmayı ustan öğretecek.",
				"steps": [
					{"kind": "goto", "at": shrine, "r": 14.0, "name": "Terk Edilmiş Tapınak", "text": "Terk edilmiş tapınağa git."},
					{"kind": "kill", "at": shrine, "enemy": "rogue", "n": 3, "camp": true, "boss": {"name": "Kılıç Yutan Muhafız", "hp": 1600.0, "level": 22, "power": 2.2}, "text": "Kılıç yutan muhafızı yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Ryūchi İni", "text": "Kılıçla ustaya dön."}]}
		"yilan:curse":
			q = {"title": "Lanetin Bedeli", "rank": "A",
				"brief": "Lanetli mühür, bedeni yanmayan beş mühür taşına bağlanmadan uyanmaz. Taşları uyandır ve mührün çektiği kaçak ninjalara karşı ayakta kal.",
				"steps": [
					{"kind": "points", "at": _near(at, 40.0), "n": 5, "spread": 16, "label": "[F] Mühür taşını uyandır", "fx": "seal", "text": "Beş mühür taşını uyandır (5)."},
					{"kind": "defend", "at": at, "enemy": "rogue", "waves": [3, 3, 4], "text": "Mührün çektiği kaçak ninjaları püskürt."}]}
		"silah:trial":
			q = {"title": "Demircinin Sınavı", "rank": "C",
				"brief": "Demirci, iyi çelik için tepedeki eski madenden cevher istiyor. Madeni haydutlar basmış. Cevheri getir ve demirhaneyi koru.",
				"steps": [
					{"kind": "collect", "at": _near(at, 220.0), "item": "demir cevheri", "n": 6, "spread": 30, "guard": {"enemy": "bandit", "n": 3}, "text": "Eski madenden demir cevheri topla (6)."},
					{"kind": "defend", "at": at, "enemy": "bandit", "waves": [2, 3], "text": "Demirhaneye saldıran haydutları püskürt."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Tetsuyama Demirhanesi", "text": "Ustaya dön."}]}
		"silah:dragons":
			q = {"title": "İkiz Ejderin Parşömenleri", "rank": "B",
				"brief": "Sōshōryū'nun iki ana parşömeni, ustanın eski rakibi olan kaçak bir ninja tarafından çalındı. Parşömenleri geri getir.",
				"steps": [
					{"kind": "collect", "at": _near(at, 520.0), "item": "ejderha parşömeni", "n": 2, "spread": 40, "guard": {"enemy": "rogue", "n": 4}, "text": "Çalınan ikiz ejderha parşömenlerini bul (2)."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Tetsuyama Demirhanesi", "text": "Parşömenleri ustaya getir."}]}
		"silah:fan":
			var far = _near(at, 1300.0)
			q = {"title": "Efsanevi Yelpaze", "rank": "A",
				"brief": "Altı Yolun Bilgesi'nin hazine yelpazesi Bashōsen (kırmızı uçlu beyaz tüyler), dağ geçidindeki samuray kalesinde mühürlü. Bekçisini yen ve yelpazeyi kazan.",
				"steps": [
					{"kind": "track", "from": at, "to": far, "text": "Eski haritadaki dağ geçidine giden yolu izle."},
					{"kind": "kill", "at": far, "enemy": "samurai", "n": 4, "camp": true, "boss": {"name": "Yelpaze Bekçisi Hōkaze", "hp": 3500.0, "level": 32, "power": 2.6}, "text": "Yelpaze bekçisini yen."},
					{"kind": "goto", "at": at, "r": 9.0, "name": "Tetsuyama Demirhanesi", "text": "Yelpazeyle ustaya dön."}]}
	base.merge(q, true)
	return base


# ------------------------------------------------------------------ dünyaya yerleştirme (World.build -> Sites)
static func build_all(parent: Node3D) -> void:
	node()
	for pid in PATHS:
		var s: Dictionary = PATHS[pid]["site"]
		var c = {}
		for cc in Game.world_info["countries"]:
			if cc["id"] == s["country"]:
				c = cc
		if c.is_empty():
			continue
		var p = Vector2(float(c["x"]), float(c["y"])) + s["off"]
		# kara olmalı: denizdeyse ülke merkezine doğru kaydır
		for k in 6:
			if Game.terrain_height(p.x, -p.y) > 2.0:
				break
			p = p.lerp(Vector2(float(c["x"]), float(c["y"])), 0.3)
		var base = Game.terrain_height(p.x, -p.y)
		var b = Builder.new(parent, p.x, p.y, base, "Yol_%s" % pid)
		b.view_dist = 1800.0
		Roadside._add_clear(p.x, p.y, float(s.get("clear", 46.0)))   # inin çevresinde orman/ot açıklığı
		var front = PathLairs.build(String(s["kind"]), b, pid, p, base)
		b.finish()
		lairs[pid] = [p.x, p.y + front]   # ustanın önü (yerel kuzey = harita +y)


static func _mentor(b: Builder, pid: String, at: Vector3, yaw: float) -> void:
	var M: Dictionary = PATHS[pid]["mentor"]
	var look = CharacterModel.default_look()
	look.merge(M["look"], true)
	var m = CharacterModel.new()
	b.root.add_child(m)
	m.setup(look)
	m.global_position = b.w(at)
	m.rotation.y = yaw   # PI: yüzü güneye, meydana dönük
	m.play("idle", 0.0)
	var nl = Label3D.new()
	nl.text = "%s\n%s" % [M["name"], M["title"]]
	nl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nl.font_size = 34
	nl.outline_size = 8
	nl.pixel_size = 0.0045
	nl.modulate = PATHS[pid]["color"].lightened(0.35)
	nl.visibility_range_end = 26.0
	m.add_child(nl)
	nl.position = Vector3(0, 2.25, 0)
