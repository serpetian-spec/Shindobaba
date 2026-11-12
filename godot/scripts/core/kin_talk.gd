class_name KinTalk
extends RefCounted
## Aile konuşmaları: anne, baba, büyük kardeş, küçük kardeş arkadaş gibi konuşmaz; her birinin kendi selamı,
## konu başlıkları, açtığı söz, cevaplara tepkisi ve sofra sohbeti vardır. (Kullanıcı: "anne babamla replikler niye arkadaşlarla aynı?")

## f: Friends kaydı -> "baba" / "anne" / "buyuk" / "kucuk" / "" (aile değil)
static func key(f: Dictionary) -> String:
	match String(f.get("kin", "")):
		"baba":
			return "baba"
		"anne":
			return "anne"
		"kardeş":
			return "buyuk" if f.get("elder", false) else "kucuk"
	return ""


const HELLO := {
	"baba": ["%s. Duruşun düzelmiş; omuzların artık bir ninjanın omuzları.", "Geldin mi evlat? Bıçaklarını bilemişsindir umarım; kör bıçak sahibini utandırır.",
		"%s, annen seni soruyordu. Ben de... merak ettim, yalan yok.", "Senin yaşındayken ben de eve böyle toz toprak içinde dönerdim. Deden hiçbir şey demezdi, sadece bakardı.",
		"Görevden sağ dönmek de bir beceridir evlat. Bunu kimse akademide öğretmez.", "Otur biraz. Bir baba oğluyla, kızıyla iki laf edemeyecek kadar meşgul olmamalı."],
	"anne": ["%s! Yüzün solmuş, yine yemek yemeden mi çıktın?", "Yavrum, gel bir bakayım... Bu çizik ne? Kim yaptı bunu?",
		"%s, üstün incecik. Hava döndü, üşüteceksin.", "Dün gece rüyamda küçüklüğünü gördüm; ayakkabılarını ters giymiş, kapıda bekliyordun.",
		"Geldin mi kuzum? Ocakta çorba var, sıcacık. Hayır deme.", "Görev panosuna her baktığımda adını arıyorum. Bulamayınca içim rahatlıyor, bilesin."],
	"buyuk": ["Ooo, küçük ninja gelmiş. Hâlâ benden kısasın, bakıyorum.", "%s! Akademide adımı lekeleme, hocalar hâlâ beni hatırlıyor.",
		"Geçen gün annem seni bana sordu. Seni ben mi doğurdum, bilmiyorum.", "Bir derdin olursa önce bana gel, babama sonra. Ben daha az bağırırım.",
		"Kunailerimi karıştıran sendin, değil mi? Biri eksik.", "Büyümüşsün be. Eskiden peşimden koşar, yetişemeyince ağlardın."],
	"kucuk": ["%s! %s! Bugün ne öğrendin? Bana da göster!", "Sen yokken kunailerine dokunmadım. ...Sadece birine. Azıcık.",
		"Annem dedi ki sen benim yaşımdayken ağaca çıkamıyormuşsun. Ben çıkıyorum!", "Büyüyünce senden güçlü olacağım. Ama sen yine de yanımda dur, olur mu?",
		"Görevden bana bir şey getirdin mi? Taş bile olur.", "Akademide herkese seni anlattım. Kimse inanmadı ama anlattım."],
}
const COLD := {
	"baba": ["...Geldin demek.", "Konuşacak bir şey varsa söyle. Yoksa işim var.", "Bir evlat evinin yolunu bu kadar unutmamalı."],
	"anne": ["...Hoş geldin.", "Sofrada yerin hep duruyor. Sen gelmiyorsun.", "Kırgınım sana. Ama anneyim, geçer."],
	"buyuk": ["Ne var?", "Şimdi mi aklına geldim?", "Annemi üzdün. Bunu unutmam."],
	"kucuk": ["...Sana küsüm.", "Söz vermiştin. Gelmedin.", "Konuşmuyorum seninle."],
}
const LABEL := {
	"baba": {"antrenman": "Tekniğimi sor: nerede hata yapıyorum?", "aile": "Dedemi, senin gençliğini sor", "şaka": "Onu güldürmeyi dene", "dedikodu": "Köyde olan biteni anlat", "övgü": "Ona minnetini söyle"},
	"anne": {"antrenman": "Görevlerini, antrenmanını anlat", "aile": "Küçüklüğümü sor", "şaka": "Onu güldür", "dedikodu": "Mahalleden haber ver", "övgü": "Yemeğini, emeğini öv"},
	"buyuk": {"antrenman": "Ondan püf noktası iste", "aile": "Annemle babamı konuş", "şaka": "Ona takıl", "dedikodu": "Akademiden, köyden haber ver", "övgü": "Ona hayran olduğunu söyle"},
	"kucuk": {"antrenman": "Ona bir hareket göster", "aile": "Evde neler olduğunu sor", "şaka": "Onu güldür", "dedikodu": "Akademide ne var ne yok, sor", "övgü": "Onu öv"},
}
## Açtığı söz + senin cevapların [üslup, söz]
const TALK := {
	"baba": {
		"antrenman": ["Bileğin sert, ama ayakların geç kalıyor. Ben bunu otuz yaşımda, bir kılıcın ucunda öğrendim. Sen daha erken öğren.",
			[["dinle", "Göster baba, bir daha yapayım."], ["dürüst", "Hocam tam tersini söylüyor."], ["şaka", "Otuz yaşında mı? Demek geç öğrenmek ailede var."]]],
		"aile": ["Deden az konuşurdu. Beni bir kez övdü, chūnin olduğum gün; o da başını sallayarak. Ben sana aynısını yapmak istemiyorum.",
			[["destek", "Yapmıyorsun zaten baba."], ["dinle", "Dedemi anlat biraz daha."], ["dürüst", "Bazen yapıyorsun ama."]]],
		"şaka": ["Hm. Bu şakayı deden de yapardı. O zaman da gülmemiştim.",
			[["şaka", "Demek gülmemek de dededen miras."], ["dürüst", "Bıyık altından güldüğünü gördüm."], ["dinle", "Dedem başka ne anlatırdı?"]]],
		"dedikodu": ["Köyün lafı köyde kalır evlat. Ama duyduğunu unutma; bir ninja için söylenti de bir istihbarattır.",
			[["dinle", "Sen neler duydun peki?"], ["dürüst", "Haklısın, lafı uzatmayayım."], ["şaka", "Yani dedikodu da görev sayılıyor!"]]],
		"övgü": ["...Bunu duymak için uzun süre bekledim. Bana değil, annene de söyle; evi ayakta tutan odur.",
			[["destek", "İkiniz de tutuyorsunuz."], ["övgü", "Senden öğrendim baba."], ["şaka", "Gözün mü doldu, baba?"]]],
	},
	"anne": {
		"antrenman": ["Her gidişinde kapıya kadar bakıyorum arkandan. Anlat, ne yaptırdılar sana? Tehlikeli miydi?",
			[["destek", "Merak etme anne, dikkatliyim."], ["dürüst", "Biraz tehlikeliydi, yalan söylemeyeyim."], ["şaka", "En tehlikelisi kedi yakalamaktı."]]],
		"aile": ["Sen üç yaşındayken babanın alın bandını takıp kapıya çıkmış, «göreve gidiyorum» demiştin. Sokağın sonuna kadar gidip ağlayarak döndün.",
			[["şaka", "İlk görevim, başarısız."], ["dinle", "Başka ne yapardım?"], ["destek", "O zaman da kapıda sen vardın."]]],
		"şaka": ["Ay sus, karnım ağrıdı! Baban da gençken böyle güldürürdü beni. Şimdi kaşlarını çatıp oturuyor.",
			[["şaka", "Kaş çatmak rütbeyle geliyor galiba."], ["dinle", "Babam gençken nasıldı?"], ["destek", "Sen gül yeter anne."]]],
		"dedikodu": ["Sorma, komşunun kızı yine görevden yaralı dönmüş. Annesi üç gecedir uyumuyor. İnsan evladı olunca...",
			[["destek", "Ben hep döneceğim anne."], ["dinle", "Şimdi nasılmış?"], ["dürüst", "Bu işte yara olur anne."]]],
		"övgü": ["Aman, ne yaptım ki... Önüne bir tabak yemek koydum. Asıl sen iyi ol, benim ödülüm o.",
			[["övgü", "Senin yemeğin gibisi yok."], ["destek", "Her şeyi sen yaptın anne."], ["şaka", "O zaman bir tabak daha?"]]],
	},
	"buyuk": {
		"antrenman": ["Püf noktası mı? Atmadan önce nefesini ver. Ben bunu üç ay kendi kendime buldum; sana bedavaya söylüyorum.",
			[["övgü", "Sen olmasan ne yapardım."], ["dürüst", "Bunu hoca ilk gün söyledi."], ["şaka", "Üç ay mı? Yavaşmışsın."]]],
		"aile": ["Babam sana bana davrandığından yumuşak davranıyor, fark ettin mi? İlk çocuk hep deneme tahtası.",
			[["dinle", "Sana nasıl davranırdı?"], ["destek", "Yolu sen açtın, biliyorum."], ["şaka", "Deneme iyi çıkmamış ama."]]],
		"şaka": ["Komik. Çok komik. Bir daha söyle de annemin önünde söyle, bakalım kim gülüyor.",
			[["şaka", "Annem bana güler, sana kızar."], ["dürüst", "Tamam, abarttım."], ["dinle", "Sen de bir tane patlat bari."]]],
		"dedikodu": ["Senin hocan var ya, benim zamanımda da aynı cezayı verirdi: kova taşıtırdı. Hâlâ taşıtıyor mu?",
			[["şaka", "Kovalar bile aynı."], ["dinle", "Sana niye ceza vermişti?"], ["dürüst", "Bana vermedi, uslu duruyorum."]]],
		"övgü": ["Hayran mı? ...Kimden ne istiyorsun, söyle. Bu kadar tatlı dil bedava olmaz.",
			[["övgü", "Ciddiyim, seni örnek alıyorum."], ["şaka", "Yeni kunai setin güzelmiş..."], ["destek", "Bir şey istemiyorum, öyle söyledim."]]],
	},
	"kucuk": {
		"antrenman": ["Öyle mi yapılıyor?! Bak ben de yaptım! ...Olmadı. Bir daha göster, yavaş göster!",
			[["destek", "Oldu sayılır, bir daha dene."], ["dürüst", "Dirseğin açık kalıyor."], ["şaka", "Kunaiyi ters tutuyorsun, şampiyon."]]],
		"aile": ["Annem dün ağladı ama bana söylemedi. Sen göreve gidince hep pencereye bakıyor. Ben de bakıyorum bazen.",
			[["destek", "Hep döneceğim, söz."], ["dinle", "Sen ne hissediyorsun?"], ["dürüst", "Bazen geç dönerim, korkma."]]],
		"şaka": ["Hahaha! Bir daha yap! Bir daha! Bunu yarın sınıfta anlatacağım!",
			[["şaka", "Yalnız benden duyduğunu söyleme."], ["dinle", "Sen de bana bir tane anlat."], ["destek", "Gülünce anneme benziyorsun."]]],
		"dedikodu": ["Sınıfta bir çocuk var, babası jōninmiş diye hava atıyor. Ben de dedim ki benim kardeşim daha güçlü!",
			[["şaka", "Çocuğun babasıyla dövüşmek zorunda mıyım şimdi?"], ["dürüst", "Hava atmak ninjaya yakışmaz."], ["övgü", "Sen ondan daha iyi olacaksın."]]],
		"övgü": ["Gerçekten mi? Anneme de söyle! Hayır dur, ben söyleyeceğim. Sen de yanımda dur ama.",
			[["övgü", "Gerçekten. Çok ilerledin."], ["destek", "Beraber söyleriz."], ["şaka", "Tamam ama burnun büyümesin."]]],
	},
}
const REPLY := {
	"baba": {"like": ["Hm. Bunu sorman hoşuma gitti.", "Otur, anlatayım.", "Aklın yerinde, evlat."], "neutral": ["Hm.", "Olur öyle.", "Peki."], "hate": ["Bunu benimle konuşma.", "Yaşına yakışmadı.", "...Annene sor onu."]},
	"anne": {"like": ["Ah, ne iyi ettin de sordun!", "Gel yanıma, anlatayım.", "Seninle konuşunca içim açılıyor."], "neutral": ["Öyle mi yavrum?", "Hmm, peki.", "Olur öyle şeyler."], "hate": ["Bunu annene mi söylüyorsun?", "Ağzından çıkanı kulağın duysun.", "...Sofrada konuşulmaz bunlar."]},
	"buyuk": {"like": ["Bak şimdi konuşuyoruz.", "Hah, sonunda akıllı bir soru.", "Gel, anlatayım."], "neutral": ["Eh.", "Olabilir.", "Öyle diyorsan."], "hate": ["Çocukluk etme.", "Bunu geç.", "Git annemle konuş bunu."]},
	"kucuk": {"like": ["Evet evet evet!", "Bunu çok seviyorum!", "Sen en iyisisin!"], "neutral": ["Hı hı.", "Olur.", "Tamam..."], "hate": ["Sıkıcı!", "Ben bunu sevmiyorum.", "Büyükler gibi konuşma."]},
}
const REACT := {
	"baba": {"like": ["Aferin. Bunu unutma.", "İşte benim evladım.", "...Gurur duyuyorum. Bir kere söyledim, tekrar etmem."], "ok": ["Hm. Peki.", "Olur.", "Görürüz."], "hate": ["Bu lafı beğenmedim.", "Daha çok ekmek yemen lazım.", "Sus ve dinle bazen."]},
	"anne": {"like": ["Canım benim.", "Sen böyle söyleyince dünyalar benim oluyor.", "Gel, bir sarılayım."], "ok": ["Peki yavrum.", "Sen bilirsin.", "Öyle olsun."], "hate": ["Kalbimi kırdın.", "Böyle konuşmayı kimden öğrendin?", "...Yemeğini ye."]},
	"buyuk": {"like": ["Eh, fena değilsin.", "Tamam, bu seferlik hakkını verdim.", "Büyüyorsun demek."], "ok": ["Eh işte.", "Peki peki.", "Neyse."], "hate": ["Haddini bil, küçük.", "Bu lafı not ettim.", "Yürü git."]},
	"kucuk": {"like": ["Yaşasın!", "Seni çok seviyorum!", "Yarın da gel, olur mu?"], "ok": ["Tamam.", "Peki...", "Hı hı."], "hate": ["Sana küstüm!", "Anneme söyleyeceğim!", "Öyle deme!"]},
}
## Sofra / ramen sohbeti: [açılış, konu, soru, kapanış]
const MEAL := {
	"baba": ["İtadakimasu. ...Yavaş ye, kimse elinden almıyor.", "Ben senin yaşındayken görev dönüşü bir kâse rameni üç kişi bölüşürdük.", "Takımın nasıl? Sırtını onlara verebiliyor musun?", "Hesap bende. Bir baba evladına ısmarlayamayacaksa ne anladım."],
	"anne": ["İtadakimasu. Sebzeyi kenara ayırma, görüyorum.", "Evdeki çorbam bundan iyidir ama dışarıda yemek de başka oluyor.", "Uykun düzenli mi? Gözlerinin altı mor.", "Bir kâse de eve yaptıralım, babana götürürüz."],
	"buyuk": ["İtadakimasu! Son parça et benim, baştan söyleyeyim.", "Akademideyken harçlığımla seni buraya getirirdim; yarısını yere dökerdin.", "Görevlerde seni zorlayan biri var mı? Adını ver yeter.", "Bu sefer ben ödüyorum. Bir dahakine sen; rütben arttı nasılsa."],
	"kucuk": ["İtadakimasu! Benimki seninkinden büyük olsun!", "Büyüyünce her gün burada yiyeceğim. Her gün!", "Görevde hiç korktun mu? Ben korkmam. ...Biraz korkarım.", "Yarın da gelelim mi? Anneme söylemeyiz."],
}


static func hello(k: String, name: String, cold := false) -> String:
	var l = String((COLD if cold else HELLO)[k].pick_random())
	var first = name.split(" ")[-1]
	if k == "kucuk" and l.count("%s") == 2:
		return l % [first, first]
	return (l % first) if l.contains("%s") else l
