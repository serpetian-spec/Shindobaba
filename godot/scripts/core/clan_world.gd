extends Node
## Klanlı dünya (autoload "ClanWorld"):
## - Köylerde klan sakinleri (Uchiha bölgesi, Hyūga konağı, diğer klanlar sokaklarda): konuşma, dostça düello, klan dersi
## - Kaçak klan ninjaları: kendi klan/kekkei genkai/göz jutsularıyla savaşır, dōjutsu sahiplerinin gözü [F] ile alınabilir
## - Efsanevi S-rank ninjalar (özgün isimler): Bingo Kitabı'nda, imza teknikleriyle, bazıları bölgeler arasında gezer
## Klan jutsuları data/jutsu.json'dan çalışma anında seçilir (clan alanı, learn "clan:x", kekkei genkai doğası, göz).

const EYE_KIND := {"uchiha": 1, "hyuga": 2, "chinoike": 3, "otsutsuki": 2}
## Doğa jutsusu olmayan klanların savaş elementi (ek C/B jutsu için)
const MAIN_EL := {"uchiha": "katon", "sarutobi": "katon", "hatake": "raiton", "senju": "doton", "uzumaki": "suiton", "yuki": "suiton",
	"hozuki": "suiton", "hoshigaki": "suiton", "terumi": "suiton", "karatachi": "suiton", "kaguya": "", "fuma": "fuuton", "kazahana": "fuuton",
	"sabaku": "fuuton", "yotsuki": "raiton", "ikazuchi": "raiton", "kako": "doton", "iwao": "doton", "kamizuru": "doton",
	"iburi": "katon", "shimura": "fuuton", "tsuchigumo": "doton", "jugo": "doton", "funato": "suiton", "kaminarimon": "raiton", "otsutsuki": "", "namikaze": "fuuton", "yuhi": "", "gekko": "fuuton", "mitarashi": "katon", "shiranui": "katon", "momochi": "suiton", "kurosuki": "raiton", "hagoromo": "fuuton"}
const GIVEN_M := ["Raito", "Shun", "Haruki", "Daichi", "Kenta", "Riku", "Takumi", "Isamu", "Souta", "Jun", "Asahi", "Kiyoshi", "Tomoya", "Ryūsei",
	"Gaku", "Hayao", "Kōki", "Masaru", "Seiji", "Tatsuo", "Yūto", "Akihiro", "Benjirō", "Fumio"]
const GIVEN_F := ["Kaede", "Akane", "Mio", "Yua", "Nao", "Sayuri", "Hikari", "Mei", "Yuzuki", "Rin", "Hotaru", "Midori", "Chiyoko", "Emi",
	"Fuyuko", "Haruna", "Kasumi", "Natsuki", "Reika", "Shizue"]
const NAMES := {"uchiha": "Uchiha", "hyuga": "Hyūga", "nara": "Nara", "akimichi": "Akimichi", "yamanaka": "Yamanaka", "aburame": "Aburame",
	"inuzuka": "Inuzuka", "senju": "Senju", "uzumaki": "Uzumaki", "kaguya": "Kaguya", "yuki": "Yuki", "hozuki": "Hōzuki", "sarutobi": "Sarutobi",
	"hatake": "Hatake", "chinoike": "Chinoike", "hoshigaki": "Hoshigaki", "kurama": "Kurama", "fuma": "Fūma", "kamizuru": "Kamizuru",
	"sabaku": "Sabaku", "shirogane": "Shirogane", "hoki": "Hōki", "kazahana": "Kazahana", "terumi": "Terumi", "karatachi": "Karatachi",
	"yotsuki": "Yotsuki", "ikazuchi": "Ikazuchi", "kako": "Kako", "bakuha": "Bakuha", "iwao": "Iwao",
	"iburi": "Iburi", "shimura": "Shimura", "tsuchigumo": "Tsuchigumo", "jugo": "Jūgo", "funato": "Funato", "kaminarimon": "Kaminarimon", "otsutsuki": "Ōtsutsuki", "namikaze": "Namikaze", "yuhi": "Yūhi", "gekko": "Gekkō", "mitarashi": "Mitarashi", "shiranui": "Shiranui", "momochi": "Momochi", "kurosuki": "Kurosuki", "hagoromo": "Hagoromo"}
## Klan görünümü: saç rengi/stili, üst, özel işaretler (anime arketipleri; kanon karakter kopyası değil)
const LOOK := {
	"uchiha": {"hair": [Color(0.05, 0.05, 0.08)], "hs": ["diken", "dağınık", "uzun", "kakul", "atkuyruğu"], "top": Color(0.12, 0.14, 0.24), "top_style": "yakali"},
	"hyuga": {"hair": [Color(0.12, 0.09, 0.08), Color(0.08, 0.08, 0.1)], "hs": ["uzun", "yele", "orgu"], "top": Color(0.86, 0.83, 0.76), "top_style": "uzun"},
	"nara": {"hair": [Color(0.1, 0.08, 0.06)], "hs": ["ananas", "atkuyruğu"], "top": Color(0.3, 0.32, 0.28)},
	"akimichi": {"hair": [Color(0.55, 0.25, 0.15), Color(0.3, 0.18, 0.1)], "hs": ["dağınık", "yele"], "top": Color(0.65, 0.18, 0.15), "size": 1.18},
	"yamanaka": {"hair": [Color(0.95, 0.85, 0.5)], "hs": ["atkuyruğu", "uzun", "kisa_kakul"], "top": Color(0.45, 0.32, 0.55)},
	"aburame": {"hair": [Color(0.15, 0.13, 0.1)], "hs": ["kirpik", "kısa"], "top": Color(0.32, 0.36, 0.3), "top_style": "ceket", "mask": "cloth"},
	"inuzuka": {"hair": [Color(0.3, 0.18, 0.1)], "hs": ["dağınık", "diken"], "top": Color(0.35, 0.3, 0.32), "face_mark": "yanak çizgisi"},
	"senju": {"hair": [Color(0.1, 0.08, 0.06), Color(0.85, 0.85, 0.88)], "hs": ["uzun", "kısa"], "top": Color(0.55, 0.15, 0.12)},
	"uzumaki": {"hair": [Color(0.75, 0.12, 0.1)], "hs": ["uzun", "dağınık", "topuz"], "top": Color(0.85, 0.45, 0.15)},
	"kaguya": {"hair": [Color(0.94, 0.94, 0.96)], "hs": ["uzun", "kase", "geriye"], "top": Color(0.9, 0.88, 0.92), "skin": Color(0.98, 0.9, 0.86)},
	"yuki": {"hair": [Color(0.06, 0.06, 0.1)], "hs": ["uzun", "topuz"], "top": Color(0.55, 0.7, 0.85)},
	"hozuki": {"hair": [Color(0.78, 0.86, 0.95)], "hs": ["dağınık", "kısa"], "top": Color(0.45, 0.3, 0.55)},
	"sarutobi": {"hair": [Color(0.12, 0.1, 0.08)], "hs": ["diken", "kısa"], "top": Color(0.3, 0.3, 0.32)},
	"hatake": {"hair": [Color(0.86, 0.86, 0.88)], "hs": ["diken", "dağınık"], "top": Color(0.18, 0.22, 0.3), "mask": "cloth"},
	"chinoike": {"hair": [Color(0.45, 0.06, 0.08)], "hs": ["uzun", "dağınık"], "top": Color(0.2, 0.1, 0.12)},
	"hoshigaki": {"hair": [Color(0.2, 0.28, 0.45)], "hs": ["diken", "kısa"], "top": Color(0.2, 0.25, 0.3), "skin": Color(0.55, 0.68, 0.8)},
	"kurama": {"hair": [Color(0.35, 0.2, 0.4)], "hs": ["uzun", "orgu"], "top": Color(0.4, 0.25, 0.45)},
	"fuma": {"hair": [Color(0.15, 0.13, 0.12)], "hs": ["kısa", "atkuyruğu"], "top": Color(0.25, 0.28, 0.25)},
	"kamizuru": {"hair": [Color(0.75, 0.6, 0.2)], "hs": ["dağınık", "kısa"], "top": Color(0.7, 0.55, 0.15)},
	"sabaku": {"hair": [Color(0.7, 0.18, 0.12)], "hs": ["dağınık", "kısa"], "top": Color(0.55, 0.4, 0.28)},
	"shirogane": {"hair": [Color(0.75, 0.75, 0.78)], "hs": ["geriye", "kısa"], "top": Color(0.3, 0.25, 0.35), "face_mark": "yanak çizgisi"},
	"hoki": {"hair": [Color(0.1, 0.1, 0.12)], "hs": ["kase", "kısa"], "top": Color(0.2, 0.2, 0.25)},
	"kazahana": {"hair": [Color(0.55, 0.45, 0.3)], "hs": ["uzun", "atkuyruğu"], "top": Color(0.75, 0.68, 0.5)},
	"terumi": {"hair": [Color(0.7, 0.3, 0.12)], "hs": ["yele", "uzun"], "top": Color(0.2, 0.3, 0.45)},
	"karatachi": {"hair": [Color(0.35, 0.42, 0.55)], "hs": ["kısa", "geriye"], "top": Color(0.25, 0.32, 0.4)},
	"yotsuki": {"hair": [Color(0.95, 0.9, 0.8)], "hs": ["kirpik", "geriye"], "top": Color(0.85, 0.85, 0.82), "skin": Color(0.6, 0.42, 0.3)},
	"ikazuchi": {"hair": [Color(0.85, 0.82, 0.4)], "hs": ["diken", "dağınık"], "top": Color(0.3, 0.32, 0.45)},
	"kako": {"hair": [Color(0.55, 0.22, 0.12)], "hs": ["kısa", "topuz"], "top": Color(0.55, 0.28, 0.18)},
	"bakuha": {"hair": [Color(0.4, 0.36, 0.3)], "hs": ["kase", "kısa"], "top": Color(0.45, 0.4, 0.3)},
	"iwao": {"hair": [Color(0.3, 0.27, 0.24)], "hs": ["kirpik", "kısa"], "top": Color(0.5, 0.42, 0.34), "size": 1.1},
	"yuhi": {"hair": [Color(0.1, 0.08, 0.1)], "hs": ["uzun", "dağınık"], "top": Color(0.85, 0.85, 0.82), "top_style": "kimono"},
	"gekko": {"hair": [Color(0.3, 0.25, 0.2)], "hs": ["kısa", "dağınık"], "top": Color(0.3, 0.35, 0.3), "top_style": "yakali"},
	"mitarashi": {"hair": [Color(0.25, 0.18, 0.35)], "hs": ["atkuyruğu", "dağınık"], "top": Color(0.6, 0.45, 0.3), "top_style": "ceket"},
	"shiranui": {"hair": [Color(0.4, 0.3, 0.2)], "hs": ["dağınık", "uzun"], "top": Color(0.3, 0.35, 0.3), "top_style": "ceket"},
	"momochi": {"hair": [Color(0.12, 0.12, 0.14)], "hs": ["diken", "kısa"], "top": Color(0.4, 0.45, 0.48), "top_style": "kolsuz", "mask": "cloth"},
	"kurosuki": {"hair": [Color(0.15, 0.15, 0.2), Color(0.5, 0.55, 0.6)], "hs": ["uzun", "dağınık"], "top": Color(0.22, 0.22, 0.28), "top_style": "kolsuz"},
	"hagoromo": {"hair": [Color(0.85, 0.85, 0.88), Color(0.2, 0.3, 0.3)], "hs": ["uzun", "atkuyruğu"], "top": Color(0.85, 0.9, 0.88), "top_style": "kimono"},
	"namikaze": {"hair": [Color(0.98, 0.85, 0.3)], "hs": ["diken", "dağınık"], "top": Color(0.25, 0.35, 0.25), "top_style": "ceket"},
	"iburi": {"hair": [Color(0.7, 0.7, 0.72), Color(0.25, 0.25, 0.28)], "hs": ["dağınık", "atkuyruğu", "uzun"], "top": Color(0.35, 0.35, 0.4), "top_style": "kimono"},
	"shimura": {"hair": [Color(0.08, 0.08, 0.1)], "hs": ["kısa", "geriye"], "top": Color(0.15, 0.15, 0.18), "top_style": "yakali_uzun"},
	"tsuchigumo": {"hair": [Color(0.4, 0.25, 0.45), Color(0.12, 0.1, 0.12)], "hs": ["uzun", "orgu"], "top": Color(0.3, 0.22, 0.35)},
	"jugo": {"hair": [Color(0.95, 0.55, 0.2)], "hs": ["diken", "dağınık"], "top": Color(0.85, 0.85, 0.8), "size": 1.15},
	"funato": {"hair": [Color(0.15, 0.3, 0.45), Color(0.85, 0.85, 0.8)], "hs": ["dağınık", "kısa"], "top": Color(0.2, 0.35, 0.5), "top_style": "tek_kol"},
	"otsutsuki": {"hair": [Color(0.95, 0.95, 0.97)], "hs": ["uzun", "geriye"], "top": Color(0.95, 0.94, 0.9), "top_style": "kimono"},
	"kaminarimon": {"hair": [Color(0.95, 0.85, 0.35), Color(0.15, 0.15, 0.18)], "hs": ["kirpik", "diken"], "top": Color(0.2, 0.2, 0.25), "top_style": "ceket"},
}
const LORE := {
	"uchiha": ["Gözlerimiz acıyla uyanır. Sharingan'ı kazanmak istersen önce kaybetmeyi öğren.", "Ateş Uchiha'nın kanında. Gōkakyū'yu yapamayan yetişkin sayılmaz."],
	"hyuga": ["Byakugan her şeyi görür... chakra noktalarını bile.", "Jūken bedeni değil, chakra akışını yaralar. Bir dokunuş yeter."],
	"nara": ["Gölgem senin gölgenle birleştiğinde, ben ne yaparsam sen de onu yaparsın. Ama çok yorucu...", "Geyikleri besliyoruz; boynuzları ilaç olur."],
	"akimichi": ["Kalori chakradır! Aç ninja savaşamaz.", "Bize şişman deme. Kemikliyiz... ve büyüyebiliriz!"],
	"yamanaka": ["Zihnini benim zihnimle değiştirirsem bedenin artık benim. Çiçekçimizden bir şey alır mısın?"],
	"aburame": ["Böceklerim chakranı yer. Korkma, sana dokunmazlar... ben istemedikçe.", "Konuşmayı pek sevmeyiz. Ama dinleriz."],
	"inuzuka": ["Ninken'im kokunu bir kez aldı, artık dünyanın öbür ucunda da bulur.", "Dört ayak üstünde koşmak daha hızlı, dene!"],
	"senju": ["Yaşam gücümüz büyüktür. Ağaç Elementi ise... nesiller boyu bir kez uyanır."],
	"uzumaki": ["Mühürler bizim sanatımız. Bir zincir yeter, en vahşi canavarı bile bağlar.", "Uzun yaşarız; kızıl saçlarımızdan tanınırız."],
	"kaguya": ["Kemiklerim kılıcım, zırhım, mızrağım. Savaşmadan duramam.", "Dans eder gibi öldürürüz; Kemik Dansları beş tanedir."],
	"yuki": ["Rüzgarla suyu birleştiren buz... aynalar arasında hızımı göremezsin.", "Kanımız yüzünden avlandık. Şimdi saklanmıyoruz."],
	"hozuki": ["Bedenim su. Bıçağın içimden geçer, ben gülerim.", "Suyum azalırsa zayıflarım; yanında hep matara var."],
	"chinoike": ["Ketsuryūgan kanı kontrol eder... ve gözlerine bakanın aklını.", "Klanımız sürgün edildi. Gözlerimizden korktular."],
	"hoshigaki": ["Köpekbalıkları kardeşimdir. Chakranı ısırır, bana getirir."],
	"sabaku": ["Kum ve demir tozu mıknatıs gibi itaat eder. Rüzgar Ülkesi'nin kalbi buradan atar."],
	"shirogane": ["Kuklalarım benden hızlı, benden sert. İplerimi görebiliyor musun?"],
	"hoki": ["Fırçamdan çıkan aslanlar canlanır. Mürekkebim kurumadan savaş biter."],
	"yotsuki": ["Şimşek zırhı sinirlerimi hızlandırır. Göz kırpmadan arkandayım."],
	"kamizuru": ["Arılarımız balmumuyla kalkan yapar. Balı tatmak ister misin? Dikkat et, sokar."],
	"kako": ["Lav damarlarımda akar. Toprak Ülkesi'nin volkanları bizim yuvamız."],
	"bakuha": ["Dokunduğumu patlatırım. Sanat bir anlık patlamadır, derler."],
	"yuhi": ["Gördüğün ağaç gerçek mi? Sarmaşık boynuna dolanınca anlarsın.", "Yūhi ailesi savaşmaz; düşman kendi kâbusunda kaybolur."],
	"gekko": ["Ay doğduğunda kılıcım hafifler.", "Hilal Dansı'nı gören ikinci bir şey görmez."],
	"mitarashi": ["Yılanlarım kolumun içinde uyur. Uyandırma onları.", "Zehir en sabırlı silahtır."],
	"shiranui": ["Bir iğne yeter; doğru noktaya.", "Dudağımdaki senbon süs değil."],
	"momochi": ["Sekiz nokta var: gırtlak, omurga, akciğer, karaciğer, boyun damarı, köprücük, böbrek, kalp.", "Sis kalktığında iş bitmiş olur."],
	"kurosuki": ["Kılıçlarım şimşeği çağırır; yağmurlu günü severim.", "Kara bulut bir yangın gibidir, bir kıvılcım yeter."],
	"hagoromo": ["Pelerinimin her tüyü bir bıçak.", "Gördüğün kılıçların yarısı yok; hangisi olduğunu bilemezsin."],
	"namikaze": ["Hız işaret koymaktır. Nereye kunai saplarsam oradayım.", "Kanımızda sarı şimşek var; Uçan Yıldırım bize kolay gelir."],
	"iburi": ["Bedenim duman. Kılıcın içimden geçer, nefesin benimle dolar.", "Klanımızdan korkup kovdular... duman nereye isterse gider."],
	"shimura": ["Rüzgâr görünmez; en keskin bıçak da öyle.", "Kökler toprağın altında çalışır, ağaç görünür. Biz de öyleyiz."],
	"tsuchigumo": ["İpeğim çelikten sağlam. Ağıma takılan kurtulamaz.", "Atalarımızın yasak tekniği bir köyü siler. Mühürlü dursun."],
	"jugo": ["Doğa enerjisi damarlarımda kaynıyor. Öfkelenirsem... uzak dur.", "Lanet mühürlerin kaynağı bizim kanımızdır."],
	"funato": ["Deniz bizi doğurdu, deniz bizi korur. Dalgayı ben çağırırım.", "Zincirli kancam en hızlı gemiyi bile durdurur."],
	"otsutsuki": ["Biz bu dünyaya ait değiliz. Chakranın kendisi bizden doğdu.", "Kül kemiklerim dokunduğunu toza çevirir."],
	"kaminarimon": ["Şimşeği bir raya koyarsan kunai ses hızını aşar.", "Kara şimşek ailemizin sırrı. Görmeden çarpar."],
}
## Konoha'da klan bölgeleri (köy merkezine göre harita ofseti, yarıçap)
const KONOHA_DISTRICT := {"uchiha": [Vector2(-1020, -640), 95.0], "hyuga": [Vector2(-1050, 250), 45.0]}

## Efsanevi ninjalar: Bingo Kitabı'na oyuncu seviyesi yettikçe eklenir. Hepsi özgün; imza teknikleri sıradan düşmanlarda yoktur.
const LEGENDS := [
	{"key": "kurogane", "name": "Tenrai Kurogane", "alias": "Kara Şimşek", "v": "kumo", "el": "raiton", "minlv": 30, "lv": 52, "wander": true,
		"j": ["kuroi_kaminari", "raiton_armor", "raiton_jibashi", "cho_biburato_raitonto", "raiton_shiden"], "hair": "kirpik", "hc": Color(0.95, 0.92, 0.85),
		"top": Color(0.2, 0.2, 0.24), "skin": Color(0.55, 0.38, 0.28), "crime": "Kumo'nun şimşek zırhı sırlarını çalıp kaçtı"},
	{"key": "yugiri", "name": "Yūgiri Kamen", "alias": "Buhar Cadısı", "v": "kiri", "el": "suiton", "minlv": 32, "lv": 55, "wander": false, "f": true,
		"j": ["joki_boi", "suiton_daibakufu_no_jutsu", "kirigakure_no_jutsu"], "nat": ["futton"], "hair": "yele", "hc": Color(0.7, 0.3, 0.14),
		"top": Color(0.2, 0.3, 0.45), "crime": "Kaynar buharıyla bir kaleyi eritti"},
	{"key": "rinkai", "name": "Kagerō Rinkai", "alias": "Altı Yolun Vârisi", "v": "ame", "el": "", "minlv": 45, "lv": 88, "wander": true,
		"eye": 6, "style": "fuin", "j": ["shinra_tensei", "bansho_ten_in", "kuroki_jushinki", "chibaku_tensei"], "hair": "uzun", "hc": Color(0.85, 0.35, 0.2),
		"top": Color(0.12, 0.12, 0.16), "crime": "Halkalı gözleriyle bir dağ köyünü göğe kaldırıp yerle bir etti"},
	{"key": "senba", "name": "Uchiha Senba", "alias": "Bin Kuşun Gözü", "v": "konoha", "clan": "uchiha", "el": "katon", "minlv": 40, "lv": 64, "wander": true,
		"eye": 4, "j": ["katon_goka_messhitsu", "katon_goka_senpu", "chidori_eiso", "chidori_senbon", "katon_ryuen_hoka_no_jutsu"], "hair": "uzun",
		"hc": Color(0.05, 0.05, 0.08), "top": Color(0.1, 0.1, 0.14), "crime": "Mangekyō'sunu uyandırmak için kendi takımını feda etti"},
	{"key": "ginsetsu", "name": "Kinro Ginsetsu", "alias": "Hazine Avcısı", "v": "tetsu", "el": "fuuton", "minlv": 45, "lv": 68, "wander": true,
		"j": ["bashosen_kaze_no_maki", "bashosen_hi_no_maki", "kaze_no_yaiba", "ukojizai_no_jutsu"], "hair": "geriye", "hc": Color(0.85, 0.75, 0.35),
		"top": Color(0.55, 0.45, 0.2), "crime": "Altı Yol'un hazinelerinden ikisini mezar odasından çaldı"},
	{"key": "hakotsu", "name": "Kaguya Hakotsu", "alias": "Gezgin Kemik", "v": "kiri", "clan": "kaguya", "el": "", "minlv": 28, "lv": 46, "wander": true,
		"j": [], "hair": "uzun", "hc": Color(0.95, 0.95, 0.97), "top": Color(0.9, 0.88, 0.92), "crime": "Üç köyün sınır karakolunu tek başına yok etti"},
	{"key": "byakuren", "name": "Hyūga Byakuren", "alias": "Ak Göz", "v": "konoha", "clan": "hyuga", "el": "", "minlv": 35, "lv": 58, "wander": false,
		"eye": 2, "j": [], "hair": "yele", "hc": Color(0.1, 0.09, 0.09), "top": Color(0.85, 0.82, 0.75), "f": true, "crime": "Kafes Kuş Mühürü'nü kırıp yan aileden kaçtı"},
	{"key": "nekome", "name": "Mikazuki Nekome", "alias": "Kedi Alevi", "v": "kusa", "el": "katon", "minlv": 25, "lv": 40, "wander": true,
		"j": ["byoen_hoka", "nezumi_kedama", "katon_goukakyuu"], "hair": "topuz", "hc": Color(0.55, 0.55, 0.6), "top": Color(0.45, 0.25, 0.4), "f": true,
		"crime": "Daimyo sarayından kedi parşömenini kaçırdı"},
	{"key": "jinkai", "name": "Ōkabe Jinkai", "alias": "Toz Hükümdarı", "v": "iwa", "el": "doton", "minlv": 55, "lv": 80, "wander": false,
		"j": ["doton_kajugan_no_jutsu", "doton_chokajugan_no_jutsu"], "nat": ["jinton"], "hair": "kel", "hc": Color(0.8, 0.8, 0.8),
		"top": Color(0.45, 0.25, 0.2), "crime": "Bir dağı Jinton ile buharlaştırdı; arkasında hiçbir şey kalmadı"},
	{"key": "kessui", "name": "Chinoike Kessui", "alias": "Kan Gölgesi", "v": "kumo", "clan": "chinoike", "el": "", "minlv": 33, "lv": 54, "wander": true,
		"eye": 3, "j": [], "hair": "uzun", "hc": Color(0.45, 0.05, 0.08), "top": Color(0.18, 0.08, 0.1), "f": true, "crime": "Bir kasabayı kan genjutsusuyla birbirine düşürdü"},
	{"key": "raigo", "name": "Raigō", "alias": "Fırtına Ejderi", "v": "kumo", "clan": "", "el": "raiton", "minlv": 42, "lv": 62, "wander": true,
		"j": ["raiton_sandageto", "raiton_kage_bunshin_no_jutsu"], "hair": "diken", "hc": Color(0.85, 0.82, 0.4), "top": Color(0.3, 0.32, 0.45),
		"crime": "Ranton ile Kumo'nun gözetleme kulelerini yıktı"},
]

var _groups := {}        # köy id -> klan grupları (sakinler)
var _queue: Array = []   # bekleyen sakin doğumları [grup, nokta]
var _res_t := 0.0
var _legend_t := 5.0
var _wander_t := 480.0


# ------------------------------------------------------------------ klan verisi
static func clan_name(c: String) -> String:
	return NAMES.get(c, String(Data.clans.get(c, {}).get("name", c.capitalize())))


static func person_name(c: String, female: bool) -> String:
	return "%s %s" % [clan_name(c), (GIVEN_F if female else GIVEN_M).pick_random()]


## Klan jutsuları: clan alanı / learn "clan:c" / klan kekkei genkai doğası / klan gözü. Seviyeye göre rütbe sınırı.
static func clan_jutsu(c: String, lv: int, n := 4) -> Array:
	var info: Dictionary = Data.clans.get(c, {})
	var nat: Array = info.get("kg_natures", [])
	var eye := String(info.get("dojutsu", ""))
	var cap := Enemy._lv_cap(lv) + 1
	var pool := []
	for id in Data.jutsu:
		var j = Data.jutsu[id]
		if not j is Dictionary:
			continue
		var learn := String(j.get("learn", ""))
		var mine: bool = String(j.get("clan", "")) == c or learn == "clan:" + c
		if not mine and not nat.is_empty():
			mine = String(j.get("element", "")) in nat or learn.trim_prefix("kg:") in nat
		if not mine and eye != "":
			mine = learn == "eye:" + eye
		if not mine:
			continue
		var r := int(Enemy.RANK_I.get(String(j.get("canon_rank", "")), 2))
		if r > cap:
			continue
		pool.append(id)
	pool.shuffle()
	return pool.slice(0, n)


## Klan görünümü (Color'lı look sözlüğü)
static func clan_look(c: String, arch: String, vid: String, female := false, age := "adult") -> Dictionary:
	var lk := CharacterModel.default_look()
	lk.merge(Outfits.roll(arch, vid), true)
	var L: Dictionary = LOOK.get(c, {})
	lk["gender"] = "f" if female else "m"
	lk["age"] = age
	if L.has("hair"):
		lk["hair"] = (L["hair"] as Array).pick_random()
	if L.has("hs"):
		lk["hair_style"] = (L["hs"] as Array).pick_random()
	for k in ["top_style", "mask", "face_mark", "skin"]:
		if L.has(k):
			lk[k] = L[k]
	if L.has("top") and arch != "rogue":
		lk["top"] = L["top"]
		lk["top2"] = (L["top"] as Color).darkened(0.15)
	# Uchiha: klan kıyafetleri (dik yaka + sırtta yelpaze, kolluk, büyüklerde haori)
	if c == "uchiha":
		lk["top_pattern"] = 7
		lk["top_style"] = ["yakali", "yakali_uzun", "kolsuz_yakali"].pick_random()
		if arch != "rogue":
			lk["top"] = [Color(0.1, 0.12, 0.22), Color(0.08, 0.08, 0.1), Color(0.94, 0.93, 0.9), Color(0.2, 0.25, 0.24)].pick_random()
			lk["top2"] = lk["top"]
		lk["arm_wraps"] = randf() < 0.5
		if age == "adult" and randf() < 0.25:
			lk["outer_style"] = "haori_uzun"; lk["outer"] = Color(0.08, 0.08, 0.1); lk["outer_pattern"] = 1; lk["outer_accent"] = Color(0.8, 0.1, 0.1)
	var e = Data.clans.get(c, {}).get("eye")
	if e is Array and e.size() >= 3:
		lk["eye"] = Color(e[0], e[1], e[2])
	lk["village"] = vid
	return lk


static func _hexlook(lk: Dictionary) -> Dictionary:
	var out := {}
	for k in lk:
		out[k] = lk[k].to_html(false) if lk[k] is Color else lk[k]
	return out


# ------------------------------------------------------------------ kaçak klan ninjası (düşman)
## Klan ninjası arketipi: klan jutsuları + klan elementinden 1 jutsu, gözler, klan görünümü
static func make_enemy(c: String, lv: int, opts := {}) -> Dictionary:
	var info: Dictionary = Data.clans.get(c, {})
	var vids: Array = info.get("villages", ["konoha"])
	var vid: String = opts.get("village", vids.pick_random() if not vids.is_empty() else "konoha")
	var a := Enemy.archetype("rogue", randi() % 4)
	var el: String = MAIN_EL.get(c, "")   # doğa jutsusu olmayan klanlar (Nara, Hyūga...) yalnız klan teknikleriyle savaşır
	var female: bool = opts.get("female", randf() < 0.35)
	a["element"] = el
	a["level"] = lv
	a["hp"] = 130.0 + lv * 16.0
	a["power"] = 1.25 + lv * 0.032
	a["xp"] = 40 + lv * 22
	a["ryo"] = 30 + lv * 6
	a["guard"] = 0.3 + (0.15 if c in ["uchiha", "hyuga"] else 0.0)
	a["sub"] = 0.15 + (0.12 if c == "uchiha" else 0.0)
	a["aggr"] = 0.75
	a["respawn"] = false
	var js := clan_jutsu(c, lv, 4)
	if el != "":
		for x in Enemy.auto_jutsu("rogue", el, lv).slice(0, 1):
			if not x in js:
				js.append(x)
	if js.is_empty():
		js = Enemy.auto_jutsu("rogue", "katon", lv)
	a["jutsu"] = js
	a.erase("auto_jutsu")
	a["clan"] = c
	a["name"] = opts.get("name", "Kaçak %s — %s" % [clan_name(c), person_name(c, female).split(" ")[1]])
	a["look"] = clan_look(c, opts.get("outfit", "rogue"), vid, female)
	if opts.has("look"):
		a["look"] = (opts["look"] as Dictionary).duplicate()   # düello/saldırı: NPC'nin kendi görünüşü (cinsiyet, saç, kıyafet) aynen
	if opts.get("outfit", "rogue") == "rogue":
		a["look"]["band_style"] = "slashed"
	if LOOK.get(c, {}).has("size"):
		a["size"] = float(LOOK[c]["size"])
	return a


## Sahneye klan ninjası koy: gözler + klan davranışı (ClanTrait)
func spawn_enemy(c: String, lv: int, at: Vector3, opts := {}) -> Enemy:
	var a := make_enemy(c, lv, opts)
	var e := Enemy.new()
	e.setup(a)
	if opts.has("team"):
		e.team = opts["team"]
	get_tree().current_scene.add_child(e)
	at.y = Game.ground_height(at.x, at.z)
	e.global_position = at
	e.home = at
	after_spawn_enemy(e, c, lv, int(opts.get("eye", 0)))
	if lv >= 28 and randf() < 0.3 and not e.has_meta("contract"):   # güçlü kaçaklar zor durumda hayvan çağırır
		e.set_meta("contract", ["kurbağa", "yılan", "köpek", "şahin"].filter(func(x): return Contracts.DEFS.has(x)).pick_random())
	if opts.get("duel", false):
		e.get_node("ClanTrait").duel = true
	return e


func after_spawn_enemy(e: Enemy, c: String, lv: int, eye_override := 0) -> void:
	var kind := eye_override if eye_override > 0 else int(EYE_KIND.get(c, 0))
	if kind > 0:
		var lvl := clampi(1 + lv / 18, 1, 3)
		Eyes.give_enemy_eyes(e, kind, lvl)
	if c != "":
		var t := ClanTrait.new()
		t.name = "ClanTrait"
		t.clan = c
		t.eye_kind = kind
		e.add_child(t)


# ------------------------------------------------------------------ Bingo Kitabı kancaları (Missions._bb_new / _bb_spawn)
## Yeni aranan: bazen bir klanın kaçağı (gözleri alınabilir)
func decorate_bingo(e: Dictionary) -> void:
	if e.has("legend") or e.has("beast") or randf() > 0.4:
		return
	var by_v := {"konoha": ["uchiha", "hyuga", "nara", "akimichi", "aburame", "inuzuka", "uzumaki", "sarutobi", "iburi", "shimura", "tsuchigumo", "namikaze", "yuhi", "gekko", "mitarashi", "shiranui"],
		"kiri": ["kaguya", "yuki", "hozuki", "hoshigaki", "terumi", "karatachi", "funato", "momochi", "kurosuki", "hagoromo"], "suna": ["sabaku", "shirogane"],
		"kumo": ["chinoike", "yotsuki"], "iwa": ["kamizuru", "jugo"]}
	var lst: Array = by_v.get(String(e["village"]), [])
	if lst.is_empty():
		return
	var c: String = lst.pick_random()
	e["clan"] = c
	var female := String(e["look"].get("gender", "m")) == "f"
	e["name"] = person_name(c, female)
	var lk := clan_look(c, "rogue", String(e["village"]), female)
	lk["band_style"] = "slashed"
	e["look"] = _hexlook(lk)
	if MAIN_EL.has(c) and String(MAIN_EL[c]) != "":
		e["element"] = MAIN_EL[c]
	if EYE_KIND.has(c):
		e["crimes"].append("%s taşıyor — yenilirse gözleri alınabilir" % ["", "Sharingan", "Byakugan", "Ketsuryūgan"][int(EYE_KIND[c])])
	else:
		e["crimes"].append("%s klanının gizli tekniklerini biliyor" % clan_name(c))


## _bb_spawn: arketipi klan / efsane verisiyle süsle
func bingo_arch(e: Dictionary, a: Dictionary) -> void:
	var c := String(e.get("clan", ""))
	var lv := int(e["level"])
	var js: Array = []
	if e.has("jutsu"):
		for id in e["jutsu"]:
			if Data.jutsu.has(id):
				js.append(id)
	for n in e.get("nat", []):
		for id in Data.jutsu:
			var j = Data.jutsu[id]
			if j is Dictionary and (String(j.get("element", "")) == n or String(j.get("learn", "")) == "kg:" + n):
				js.append(id)
	if c != "":
		for id in clan_jutsu(c, lv, 4):
			if not id in js:
				js.append(id)
	if not js.is_empty():
		if String(e.get("element", "")) != "":
			for x in Enemy.auto_jutsu("rogue", String(e["element"]), lv).slice(0, 1):
				if not x in js:
					js.append(x)
		a["jutsu"] = js.slice(0, 6)
	a["clan"] = c
	if e.has("legend"):
		a["guard"] = 0.55
		a["sub"] = 0.4
		a["aggr"] = 0.95
		a["name"] = "★ «%s» %s" % [e["alias"], e["name"]]


func after_bingo_spawn(e: Dictionary, b: Enemy) -> void:
	var c := String(e.get("clan", ""))
	if c != "" or e.has("eye"):
		after_spawn_enemy(b, c, int(e["level"]), int(e.get("eye", 0)))
	if e.has("legend"):
		FX.aura(b, Color(0.95, 0.85, 0.5) if not e.has("eye") else Color(0.9, 0.2, 0.2), 1.4, Vector3(0, 0.9, 0), 0.0)
		Hud.banner("EFSANEVİ NİNJA", "«%s» %s seni fark etti!" % [e["alias"], e["name"]], Color(1, 0.6, 0.3))


## Efsaneleri oyuncunun seviyesi yettikçe Bingo Kitabı'na ekle
func _seed_legends() -> void:
	if Game.profile.is_empty() or not Missions.has_method("_bingo"):
		return
	var bb: Dictionary = Missions._bingo()
	var lst: Array = bb["list"]
	var have := {}
	for e in lst:
		if e.has("legend"):
			have[e["legend"]] = true
	for L in LEGENDS:
		if have.has(L["key"]) or Game.village(L["v"]).is_empty():   # oyuncunun gücünü beklemez (minlv artık kullanılmıyor)
			continue
		lst.append(_legend_entry(L, int(bb["next"])))
		bb["next"] = int(bb["next"]) + 1
		Hud.msg("Bingo Kitabı'na efsanevi bir isim eklendi: «%s»" % L["alias"], Color(1, 0.7, 0.4))


## Efsane kalıbı (teknik tarzı, köy, suç) sabit; onu taşıyan KİŞİ her oyunda başka: ad, takma ad, cinsiyet, saç, güç
const LEGEND_ALIAS := {"raiton": ["Kara Şimşek", "Gök Gürültüsü", "Mavi Kıvılcım", "Fırtına Ejderi", "Yıldırım Pençesi"],
	"suiton": ["Buhar Cadısı", "Sis Gölgesi", "Kaynar Dalga", "Derin Akıntı"], "katon": ["Kedi Alevi", "Kül Kuşu", "Kızıl Ejder", "Yanık Gölge"],
	"fuuton": ["Hazine Avcısı", "Rüzgar Hırsızı", "Kesen Esinti", "Boran"], "doton": ["Toz Hükümdarı", "Taş Kalp", "Dağ Yıkan", "Kum Kral"],
	"": ["Sessiz Ölüm", "Yarım Ay", "Gece Kuzgunu", "Soluk Gölge", "Kayıp Ruh", "Kırık Mühür"]}   # + efsanenin kendi kanon takma adı
const LEGEND_HAIR := ["uzun", "yele", "diken", "kısa", "atkuyruğu", "topuz", "dağınık", "geriye", "kirpik"]


func _legend_person(L: Dictionary) -> Dictionary:
	var f := randf() < 0.4
	var c := String(L.get("clan", ""))
	var nm := person_name(c, f) if c != "" else "%s %s" % [Missions.BB_FAMILY.pick_random(), (GIVEN_F if f else GIVEN_M).pick_random()]
	var pool: Array = (LEGEND_ALIAS.get(String(L.get("el", "")), LEGEND_ALIAS[""]) as Array).duplicate()
	if not L["alias"] in pool:
		pool.append(L["alias"])
	var hc: Color = L["hc"]
	if c == "":   # klansız: saç rengi de kişiye göre
		hc = [Color(0.06, 0.06, 0.08), Color(0.85, 0.82, 0.75), Color(0.55, 0.18, 0.12), Color(0.85, 0.72, 0.35), Color(0.3, 0.35, 0.5), Color(0.6, 0.6, 0.65)].pick_random()
	return {"name": nm, "alias": pool.pick_random(), "f": f, "hair": LEGEND_HAIR.pick_random() if String(L["hair"]) != "kel" else "kel", "hc": hc,
		"lv": maxi(20, int(L["lv"]) + randi_range(-8, 10))}


func _legend_entry(L: Dictionary, id: int) -> Dictionary:
	var hide: Array = Missions._spot(L["v"], 500, 1600)
	var who := _legend_person(L)
	var lk := clan_look(String(L.get("clan", "")), "rogue", L["v"], who["f"])
	lk.merge({"hair_style": who["hair"], "hair": who["hc"], "top": L["top"], "top2": (L["top"] as Color).darkened(0.2), "band_style": "slashed",
		"face_mark": ["burun yarası", "yanak çizgisi", "yok"].pick_random(), "gender": "f" if who["f"] else "m"}, true)
	if L.has("skin"):
		lk["skin"] = L["skin"]
	var lv := int(who["lv"])
	var e := {"id": id, "legend": L["key"], "name": who["name"], "alias": who["alias"], "village": L["v"], "rank": "S",
		"bounty": 40000 + lv * 900, "crimes": [L["crime"], "Efsanevi S-rank: imza teknikleri kullanır"], "element": L["el"],
		"hide": hide, "area": [hide[0] + randf_range(-400, 400), hide[1] + randf_range(-400, 400)], "known": 650.0, "status": "alive", "tracked": false,
		"level": lv, "hp": 900.0 + lv * 60.0, "power": 1.8 + lv * 0.04, "escorts": 2, "escort_kind": "rogue", "look": _hexlook(lk),
		"jutsu": L["j"], "wander": L.get("wander", false)}
	if L.has("clan"):
		e["clan"] = L["clan"]
	if L.has("eye"):
		e["eye"] = int(L["eye"])
	if L.has("style"):
		e["style"] = L["style"]
	if L.has("nat"):
		e["nat"] = L["nat"]
	if L.get("wander", false):
		e["crimes"].append("Bölgeler arasında dolaşır — son görüldüğü yer değişebilir")
	return e


## Gezgin efsaneler: oyuncu yakında değilken saklandığı yer başka bir köyün çevresine kayar
func _wander_legends() -> void:
	if Game.profile.is_empty():
		return
	var vids: Array = Game.world_info["villages"].map(func(v): return v["id"])
	for e in Missions._bingo()["list"]:
		if not e.get("wander", false) or e["status"] != "alive" or Missions._bb_spawned.has(int(e["id"])):
			continue
		if randf() < 0.5:
			continue
		var hide: Array = Missions._spot(vids.pick_random(), 500, 1600)
		e["hide"] = hide
		if not e.get("tracked", false):
			e["area"] = [hide[0] + randf_range(-400, 400), hide[1] + randf_range(-400, 400)]
			e["known"] = 650.0
		else:
			e["area"] = [hide[0] + randf_range(-250, 250), hide[1] + randf_range(-250, 250)]
			e["known"] = 400.0
			Hud.msg("Takip ettiğin «%s» yer değiştirdi: %s civarında görülmüş." % [e["alias"], Game.region_name(Game.from_map(Vector2(e["area"][0], e["area"][1])))], Color(1, 0.7, 0.4))


# ------------------------------------------------------------------ köy sakinleri
func _village_here(p: Vector3) -> Dictionary:
	var m := Game.to_map(p)
	for v in Game.world_info["villages"]:
		if m.distance_to(Vector2(v["x"], v["y"])) < float(v["r"]) * 0.95:
			return v
	return {}


func _clans_of(vid: String) -> Array:
	var out := []
	for c in Data.clans:
		if c == "none" or c in Progress.UNPLAYABLE_CLANS:
			continue   # Ōtsutsuki köylerde yaşamaz: yalnız Bingo Kitabı'nda
		if vid in Data.clans[c].get("villages", []):
			out.append(c)
	return out


## Sakinlerin duracağı yerler: Konoha'da klan bölgeleri, diğer klanlar köyün sokak noktalarında
func _resident_spots(v: Dictionary, c: String, n: int) -> Array:
	var cen := Vector2(float(v["x"]), float(v["y"]))
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(c + String(v["id"]))
	if v["id"] == "konoha" and KONOHA_DISTRICT.has(c):
		var d: Array = KONOHA_DISTRICT[c]
		for i in n:
			var off: Vector2
			if c == "uchiha":
				# ev halkaları (62 m ve 95 m) arasındaki ve tapınak çevresindeki boş sokaklar
				var a := rng.randf() * TAU
				off = Vector2(cos(a), sin(a)) * ([rng.randf_range(36.0, 52.0), rng.randf_range(74.0, 84.0)].pick_random())
			else:
				# Hyūga konağının avlusu ve kapı önü
				off = Vector2(rng.randf_range(-45.0, -5.0), rng.randf_range(-40.0, -18.0)) if i % 3 else Vector2(rng.randf_range(-12.0, 12.0), rng.randf_range(-62.0, -50.0))
			out.append(Game.from_map(cen + d[0] + off))
		return out
	var life = get_tree().current_scene.find_child("VillageLife", true, false)
	var pts: Array = life._streets(v) if life and life.has_method("_streets") else []
	if pts.is_empty():
		for i in n:
			var a := rng.randf() * TAU
			out.append(Game.from_map(cen + Vector2(cos(a), sin(a)) * rng.randf_range(0.15, 0.6) * float(v["r"])))
		return out
	# aynı klan bir mahallede toplansın: bir çekirdek nokta + en yakın sokak noktaları
	var core: Vector3 = pts[rng.randi() % pts.size()]
	var near := pts.duplicate()
	near.sort_custom(func(a, b): return a.distance_squared_to(core) < b.distance_squared_to(core))
	return near.slice(0, n)


## Köyün klan grupları (bir kez hesaplanır): [{clan, vid, spots}]. Sakinler yalnız oyuncu grubun yakınındayken doğar.
func _groups_of(v: Dictionary) -> Array:
	var vid := String(v["id"])
	if _groups.has(vid):
		return _groups[vid]
	var out := []
	for c in _clans_of(vid):
		var n: int = (6 if KONOHA_DISTRICT.has(c) and vid == "konoha" else 3)
		out.append({"clan": c, "vid": vid, "spots": _resident_spots(v, c, n), "nodes": []})
	_groups[vid] = out
	return out


func _make_resident(g: Dictionary, i: int) -> void:
	var c: String = g["clan"]
	var vid: String = g["vid"]
	var r := ClanResident.new()
	r.clan = c
	r.vid = vid
	var female := randf() < 0.45
	var age: String = ["adult", "adult", "young", "teen", "child", "adult"][i % 6]
	r.given = person_name(c, female)
	r.display_override = r.given if age != "child" else "%s (çocuk)" % r.given
	r.role = "nurse" if age != "child" else "kid"
	r.wander_r = 7.0
	var arch: String = "chunin" if age in ["adult", "young"] and randf() < 0.5 else ("genin" if age == "teen" else "civ")
	if age == "child":
		arch = "kid"
	r.look_extra = clan_look(c, arch, vid, female, age)
	r.lines_override = LORE.get(c, ["%s klanındanım. Köyümüzü korumak görevimiz." % clan_name(c)])
	# bu yuvada tanıştığın klan üyesi varsa o (adı, görünüşü, gözleri)
	var skey = Friends.site_key(g["spots"][i])
	r.set_meta("site_key", skey)
	var fid = Friends.at_site(skey)
	if fid != "" and String(Friends.all()[fid].get("clan", "")) == c:
		var f: Dictionary = Friends.all()[fid]
		r.given = String(f["name"])
		r.display_override = r.given
		r.look_extra = Friends.look_of(f)
		var ek: Array = f.get("eye", [0, 0])
		r.eye_kind = int(ek[0])
		r.eye_lvl = int(ek[1])
		r.set_meta("friend_id", fid)
	var kind := int(EYE_KIND.get(c, 0))
	if kind == 2:
		r.eye_kind = 2
		r.eye_lvl = 1
	elif kind == 1 and age in ["adult", "young"] and randf() < 0.45:
		r.eye_kind = 1
		r.eye_lvl = randi_range(1, 3)
	elif kind == 3 and age != "child":
		r.eye_kind = 3
		r.eye_lvl = 1
	get_tree().current_scene.add_child(r)
	var at: Vector3 = g["spots"][i]
	at.y = Game.ground_height(at.x, at.z)
	r.global_position = at
	r.home = at
	g["nodes"].append(r)


func _free_group(g: Dictionary) -> void:
	for r in g["nodes"]:
		if is_instance_valid(r):
			r.queue_free()
	g["nodes"] = []
	_queue = _queue.filter(func(q): return q[0] != g)


func _tick_residents() -> void:
	var p := Game.player.global_position
	var here := _village_here(p)
	for vid in _groups:
		for g in _groups[vid]:
			if g["nodes"].is_empty():
				continue
			var spot: Vector3 = g["spots"][0]
			if here.is_empty() or here["id"] != vid or Vector2(p.x - spot.x, p.z - spot.z).length() > 420.0:
				_free_group(g)
	if here.is_empty():
		return
	for g in _groups_of(here):
		if not g["nodes"].is_empty() or g["spots"].is_empty() or _queue.any(func(q): return q[0] == g):
			continue
		var spot: Vector3 = g["spots"][0]
		if Vector2(p.x - spot.x, p.z - spot.z).length() < 280.0:
			for i in g["spots"].size():
				_queue.append([g, i])


## Bir sakinin (mevcut) listesi — test / diğer sistemler için
func residents(vid: String) -> Array:
	var out := []
	for g in _groups.get(vid, []):
		for r in g["nodes"]:
			if is_instance_valid(r):
				out.append(r)
	return out


func _process(dt: float) -> void:
	if Game.paused or Game.profile.is_empty() or Game.player == null:
		return
	# karakter modeli pahalı: her karede en fazla bir sakin doğar
	if not _queue.is_empty():
		var q: Array = _queue.pop_front()
		_make_resident(q[0], q[1])
	_res_t -= dt
	if _res_t <= 0.0:
		_res_t = 1.5
		_tick_residents()
	_legend_t -= dt
	if _legend_t <= 0.0:
		_legend_t = 30.0
		_seed_legends()
	_wander_t -= dt
	if _wander_t <= 0.0:
		_wander_t = 480.0
		_wander_legends()
