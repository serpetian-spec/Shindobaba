class_name Talk
extends RefCounted
## Tanıdıklarla konuşma: kim olduğuna (eş, sevgili, çocuğun, öğrencin, hocan, takım arkadaşın, dost, tanıdık) ve
## gerçek duruma (yaran, rütben, kilon, ağaran saçın, görevlerin, köy haberi, onun işi ve ailesi) göre söz.
## Anne / baba / kardeş: KinTalk. Kaçak dost: Friends.ROGUE_*. Buradaki sözler onların dışında kalan herkes için.


static func pr() -> Dictionary:
	return Game.profile


## İlişki anahtarı
static func rel(f: Dictionary) -> String:
	var kk = KinTalk.key(f)
	if kk != "":
		return kk
	match String(f.get("romance", "")):
		"eş":
			return "es"
		"sevgili":
			return "sevgili"
		"flört":
			return "flort"
	if f.get("child", false):
		return "cocuk"
	if f.get("pupil", false):
		return "ogrenci"
	if String(f.get("squad_key", "")) == "sensei":
		return "hoca"
	if String(f.get("squad_key", "")) != "":
		return "takim"
	var b = int(f.get("bond", 0))
	return "dost" if b >= 60 else "arkadas" if b >= 20 else "tanidik"


static func _parent_word() -> String:
	return "Anne" if Friends.player_gender() == "f" else "Baba"


const HELLO := {
	"es": ["Hoş geldin canım. Yüzünü görünce günüm düzeliyor.", "%s, geldin mi? Çay demledim, soğumadan otur.", "Ayak sesini kapıdan tanıdım. Yorgun musun?",
		"Bugün aklıma düştün, sebepsiz yere. Sonra kapı açıldı.", "Her görevden dönüşünde içimden bir yük kalkıyor, bilesin.", "Gel yanıma. Köyün derdi bir süre bekleyebilir."],
	"sevgili": ["%s! Tam seni düşünüyordum, inanır mısın?", "Geldin... Herkesin içinde böyle gülümseme, anlayacaklar.", "Bugün nöbette üç kez adını sayıkladım, takım arkadaşım dalga geçti.",
		"Seni görünce elim ayağıma dolaşıyor hâlâ. Geçmedi gitti.", "Akşam boş musun? Köprünün oradan gün batımı güzel oluyor."],
	"flort": ["Ah, %s... Tesadüf mü bu, yoksa beni mi arıyordun?", "Yine karşılaştık. Köy küçük mü, sen mi beni buluyorsun?", "Saçımı bugün farklı topladım. Fark etmedin tabii.",
		"Seninle konuşunca vakit çabuk geçiyor. Nöbete geç kalacağım yine."],
	"cocuk": ["%P! Bugün takımla suyun üstünde yürüdük, bir kez bile düşmedim!", "%P, hocam seni soruyor. «Onun çocuğu olmak kolay değil» diyor.", "Görev panosunda adımı gördün mü? İlk C rütbem!",
		"Evde olsaydın sana yeni öğrendiğim mührü gösterirdim. Şimdi göstereyim mi?", "%P... Sen benim yaşımdayken korkar mıydın görevlerde? Ben bazen korkuyorum."],
	"ogrenci": ["Hocam! Dün verdiğiniz hareketi yüz kez yaptım. Yüz birincide oldu.", "Hocam, bugün ders var mı? Kunailerimi biledim.", "%s hocam, takımdakiler sizi çok sert buluyor. Ben bulmuyorum.",
		"Hocam, bir gün sizin gibi olacağım. Ama önce şu ağaca çıkmam lazım."],
	"hoca": ["%s. Duruşun yine bozulmuş; geç yatmışsın.", "Geldin mi? Güzel. Bir ninja hocasını aramayı unutmaz.", "Seni ilk gün gördüğümde kunaiyi ters tutuyordun. Bak şimdi haline.",
		"Bugün ders yok. Ama bir hoca öğrencisiyle çay içebilir."],
	"takim": ["%s! Bizim takım sensiz eksik kalıyor, söyleyeyim.", "Ooo, kaptan gelmiş. Görev mi var, yoksa laf mı?", "Geçen görevdeki o hamlen... Hâlâ nasıl yaptın anlamadım.",
		"Hocanın bugün keyfi yok, haberin olsun. Yanına sessiz yaklaş."],
	"dost": ["%s! Seni gören gözlerim bayram etti.", "Tam zamanında. Anlatacak bir şeyim vardı, bir tek sana anlatırım.", "Gel otur şöyle. Senin yanında susmak bile rahat.",
		"Dün dangocuda yerimizi ayırdım, gelmedin. Bugün ısmarlıyorsun.", "Sırtımı kime dayarım diye sorsalar, düşünmeden seni söylerim."],
	"arkadas": ["Ooo, %s! Nasıl gidiyor?", "Selam %s. Antrenman alanına mı, ben de o tarafa gidiyorum.", "%s, iyi ki rastladım. Bir ara oturup konuşalım.",
		"Bugün hava tam idman havası. Sen ne yapıyorsun?", "Geçen gün pazarda güzel bir dangocu buldum, sana da gösteririm."],
	"tanidik": ["Ah, sen %s olacaksın, değil mi? Merhaba.", "Selam. Seni buralarda görüyorum ara sıra.", "İyi günler. Görevden mi?", "Merhaba. Adını unutmadım, merak etme."],
}
## Yaşlı tanıdık (60+): aynı ilişki, yaşının sesiyle
const ELDER := ["%s, evladım... Dizlerim hava değişimini senden önce haber veriyor artık.", "Gel gel. Benim yaşımda insan ziyaretçiyi geri çevirmez.",
	"Sizin kuşağınız koşuyor. Biz yürürdük, yine de varırdık.", "Bu köyün üç Kage'sini gördüm. Sen dördüncüyü görecek kadar yaşa, yeter."]
## İşinin başındayken
const JOB := {"nöbet": ["Nöbetteyim, uzun konuşamam; ama gel, iki laf edelim.", "Kapıdan bugün kırk kişi geçti. Yüzünü tanıdığım tek kişi sensin."],
	"antrenman": ["Dur, soluklanayım... Sabahtan beri aynı hareketi çalışıyorum.", "Tam zamanında, ara verecektim. Kollarım tutmuyor."],
	"görev": ["Yeni döndüm, üstüm başım toz. Kusura bakma.", "Görev raporunu daha yazmadım, sen yakaladın beni."]}

## Durum sözleri: {ilişki ya da "*": [sözler]}
const REMARK := {
	"hurt": {"*": ["Dur, kanıyorsun! Önce hastaneye uğra, laf sonra.", "Bu halin ne? Ayakta zor duruyorsun."],
		"anne": ["Yavrum bu ne hal! Otur şuraya, yaranı ben sarayım."], "baba": ["Yaran derin. Hastaneye git; inat, yarayı kapatmaz."],
		"es": ["Canım, kan içindesin! Otur, kıpırdama, sargı getiriyorum."], "cocuk": ["%P! Yaralısın! ...Ben seni hastaneye götüreyim mi?"], "ogrenci": ["Hocam, kolunuz... Hemşireyi çağırayım mı?"]},
	"rank": {"*": ["Rütbe atlamışsın! Hayırlı olsun, köyde herkes konuşuyor.", "Yeni rütben yakışmış. Artık sana selam mı durmam gerekiyor?"],
		"baba": ["Rütbe atlamışsın. ...Aferin evlat. Deden görseydi başını sallardı."], "anne": ["Rütbe atlamışsın, duydum! Sevindim de, görevlerin ağırlaşacak diye korkuyorum."],
		"es": ["Yeni rütben hayırlı olsun canım. Bu akşam sofrayı ona göre kuruyorum."], "hoca": ["Rütbe atladın. Öğrencisi kendini geçince bir hoca işini yapmış demektir."],
		"kucuk": ["Rütbe atlamışsın! Akademide herkese söyledim, bu sefer inandılar!"], "cocuk": ["%P, rütbe atlamışsın! Takımdakilere söyledim, hepsi kıskandı."],
		"ogrenci": ["Hocam, rütbe atlamışsınız! Artık en iyi hoca bizim hocamız."], "buyuk": ["Rütbe atlamışsın. Benden hızlı gidiyorsun, bozulmadım desem yalan."]},
	"wed": {"*": ["Evlenmişsin diyorlar! Hayırlı olsun, düğününe çağırmadın ama."], "anne": ["Evlendin... Evimden bir kuş uçtu ama yuvası oldu, ona seviniyorum."], "baba": ["Evlendin. Bir yuvayı ayakta tutmak göreve gitmekten zordur, bilesin."]},
	"grey": {"*": ["Saçına ak düşmüş... Zaman ikimize de uğramış demek.", "Şakakların ağarmış. Yakışmış ama, ağırbaşlı durmuşsun."],
		"kucuk": ["Saçın beyazlamış! Yaşlandın mı sen? Ben de mi yaşlanacağım?"], "es": ["Saçındaki aklar çoğalmış. Her birinde benim de payım vardır."],
		"anne": ["Saçına ak düşmüş yavrum. Ben seni hâlâ kapıda ayakkabısını ters giyen çocuk sanıyorum."], "cocuk": ["%P, saçın beyazlamış. ...Görevleri biraz bana bıraksan?"]},
	"fat_up": {"*": ["Yanakların dolmuş, ramenciye fazla mı uğruyorsun?", "Kemerin bir delik açılmış gibi. Antrenmanı mı aksattın?"],
		"anne": ["Kilo almışsın, oh! Yüzüne renk gelmiş, böyle iyi."], "es": ["Yemeklerim yaramış sana, kemerin bir delik açılmış."], "baba": ["Göbek bağlamışsın. Bir ninjanın karnı ayağına engel olmamalı."],
		"buyuk": ["Ooo, göbek! Annem seni iyi beslemiş."], "kucuk": ["Karnın büyümüş! İçinde ramen mi var?"]},
	"fat_down": {"*": ["Zayıflamışsın, yüzün çökmüş. Yemek yiyor musun sen?", "İncelmişsin. Görevler seni eritmiş."],
		"anne": ["Bir deri bir kemik kalmışsın! Otur, sofrayı kuruyorum, itiraz istemem."], "es": ["Zayıflamışsın canım. Dışarıda ne yiyorsun sen, hiçbir şey mi?"]},
	"mus_up": {"*": ["Omuzların genişlemiş. Antrenmanı aksatmadığın belli.", "Kolların kalınlaşmış. Seninle idman yapmaya korkar oldum."],
		"baba": ["Kolun kalınlaşmış. Güç iyidir; ama hız yoksa güç yalnızca yüktür."], "anne": ["Omuzların babanın gençliğindeki gibi olmuş."],
		"es": ["Kolların kalınlaşmış. ...Bir şey demedim, sadece fark ettim."], "ogrenci": ["Hocam, kollarınız kütük gibi olmuş! Bana da o idmanı yaptırır mısınız?"]},
	"missions": {"*": ["Görev panosunda adın sık geçiyor bu aralar. Dinlenmeyi unutma.", "Son görevlerini duydum. Köy seni konuşuyor."],
		"anne": ["Panoda yine adını gördüm. Her gördüğümde içim bir tuhaf oluyor."], "baba": ["Görevlerini duyuyorum. Sağ dönmeyi de görev say."], "hoca": ["Görevlerin kulağıma geliyor. Temiz iş çıkarıyorsun."]},
	"gap": {"*": ["Ne zamandır görünmüyordun, merak ettim.", "Yüzünü unutacaktım neredeyse. Neredeydin?"],
		"anne": ["Nerelerdeydin? Kapıya her ses geldiğinde sen sandım."], "baba": ["Uzun zaman oldu. Annen her akşam bir tabak fazla koydu."],
		"es": ["Sonunda geldin. Bu evde senin yokluğun çok ses çıkarıyor."], "kucuk": ["Çok uzun süre yoktun! Günleri saydım, parmaklarım yetmedi."]},
	"night": {"*": ["Bu saatte ayakta mısın? Gece nöbeti mi, uykusuzluk mu?", "Gece gece nereye? Sokaklar boş, sesin yankılanıyor."],
		"anne": ["Bu saatte sokakta ne işin var? Üstüne bir şey al bari."], "es": ["Gece oldu, hâlâ dışarıdasın. Eve gel artık."]},
}

const LABEL := {
	"es": {"antrenman": "Gününü, görevlerini anlat", "aile": "Evi, geleceği konuş", "şaka": "Onu güldür", "dedikodu": "Köyden haber ver", "övgü": "Ona iltifat et"},
	"sevgili": {"antrenman": "Gününü, görevlerini anlat", "aile": "Gelecekten konuş", "şaka": "Onu güldür", "dedikodu": "Köyden haber ver", "övgü": "Ona iltifat et"},
	"cocuk": {"antrenman": "Antrenmanını sor", "aile": "Evden, kendinden konuş", "şaka": "Onu güldür", "dedikodu": "Takımını, arkadaşlarını sor", "övgü": "Onunla gurur duyduğunu söyle"},
	"ogrenci": {"antrenman": "Hatalarını göster", "aile": "Ailesini sor", "şaka": "Onu güldür", "dedikodu": "Takımını sor", "övgü": "Onu öv"},
	"hoca": {"antrenman": "Tekniğimi sor: nerede hata yapıyorum?", "aile": "Gençliğini sor", "şaka": "Ona takıl", "dedikodu": "Köyden haber ver", "övgü": "Ona minnetini söyle"},
}

## Konu sözleri: {ilişki: {konu: [[söz, [[üslup, cevap], ...]], ...]}}; "*" = dost / arkadaş / tanıdık
const TALK := {
	"*": {
		"antrenman": [
			["Son zamanlarda chakrayı sıkıştırmaya kafayı taktım. Sence boşuna mı uğraşıyorum?",
				[["destek", "Hiç boşuna değil, başarırsın."], ["dürüst", "Önce temelini sağlamlaştır bence."], ["şaka", "Kafana taktığın tek şey o mu, ramen değil mi?"]]],
			["Dün ağaca çıkarken yarıda düştüm. Yirmi kişinin önünde. Hâlâ kulaklarım yanıyor.",
				[["şaka", "Düşüşün en azından zarif miydi?"], ["destek", "Herkes düşer, önemli olan yine çıkman."], ["dinle", "Sonra ne oldu?"]]],
			["%EL çalışıyorum bu aralar. Mühürleri doğru yapıyorum ama chakram yarı yolda dağılıyor.",
				[["dürüst", "Mühürde değil nefeste hata yapıyorsun."], ["destek", "Yakındır, dağılması iyiye işaret."], ["dinle", "Göster, bir bakayım."]]],
			["Geçen gün seni izledim: %BR konusunda epey ilerlemişsin. Bana birkaç şey gösterir misin?",
				[["destek", "Tabii, yarın sabah alanda buluşalım."], ["şaka", "Dersler ücretli ama, bir kâse ramen."], ["dürüst", "Daha kendim tam oturtamadım."]]]],
		"aile": [
			["%FAM1", [["dinle", "Anlat, dinliyorum."], ["destek", "Elinden geleni yapıyorsun zaten."], ["dürüst", "Belki yanlarında biraz daha vakit geçirmelisin."]]],
			["%FAM2", [["dinle", "Nasıl biriydi, anlatsana."], ["destek", "Seninle gurur duyardı."], ["şaka", "İnadını ondan almışsın demek."]]],
			["Senin ailen nasıl? Ben hep kendiminkini anlatıyorum, sen hiç açılmıyorsun.",
				[["dinle", "Önce sen bitir, sonra ben."], ["dürüst", "Anlatacak çok şey yok, sıradan bir ev."], ["şaka", "Bizimkiler mi? Sofrada kunai havada uçuşur."]]]],
		"şaka": [
			["Hah! Peki sen bunu dinle: Kage'nin şapkası neden bu kadar büyük?",
				[["şaka", "Kafasındaki dertlere yer açmak için!"], ["dinle", "Neden?"], ["dürüst", "Bu şakayı akademide duymuştum."]]],
			["Dur dur, bende de var: Bir genin, bir chūnin ve bir jōnin çay evine girmiş. Hesabı kim ödemiş?",
				[["şaka", "Genin. Çünkü D rütbe görev diye yazmışlar!"], ["dinle", "Kim?"], ["dürüst", "Senin şakaların hep parayla bitiyor."]]],
			["Haha! Geçen gün kedi yakalama görevinde kedi beni yakaladı. Yüzümdeki çizik ondan.",
				[["şaka", "Kediyi Bingo Kitabı'na yazdıralım."], ["destek", "En zor görev odur, herkes bilir."], ["dinle", "Sonunda yakalayabildin mi?"]]]],
		"dedikodu": [
			["%NEWS", [["dinle", "Başka ne duydun?"], ["dürüst", "Yarısı uydurmadır bunların."], ["şaka", "Senden iyi istihbaratçı olur."]]],
			["%FLOG", [["dinle", "Ciddi misin? Anlat."], ["dürüst", "Arkasından konuşmayalım."], ["şaka", "Köyde senden kaçan haber yok."]]],
			["Duydun mu? Akademi hocalarından biri her akşam çay evine gidiyormuş... hep aynı masaya.",
				[["şaka", "Demek dersler bu yüzden geç başlıyor!"], ["dürüst", "Başkalarının hayatı bizi ilgilendirmez."], ["dinle", "Kimmiş? Anlat!"]]]],
		"övgü": [
			["Gerçekten mi? ...Bunu bana pek kimse söylemez.",
				[["övgü", "Ciddiyim, köyün en iyilerindensin."], ["destek", "Kendine daha çok güvenmelisin."], ["şaka", "Tamam tamam, şımarma hemen."]]],
			["Bunu senden duymak başka. Sen boş laf etmezsin çünkü.",
				[["övgü", "Etmem. Gördüğümü söylüyorum."], ["dürüst", "Eksiklerin de var ama."], ["şaka", "Arada ederim, bu onlardan değil."]]]],
	},
	"es": {
		"antrenman": [
			["Anlat bakalım, bugün seni nereye yolladılar? Yüzünden okuyorum, kolay geçmemiş.",
				[["dürüst", "Zordu. Ama döndüm, sana döndüm."], ["destek", "Merak etme, hepsi yolunda."], ["şaka", "En zoru eve gelene kadar acıkmaktı."]]],
			["Sen görevdeyken ben de boş durmadım; mühürleri tekrar ettim. Elim hâlâ senden hızlı.",
				[["şaka", "O yüzden evde sana karşı gelmiyorum."], ["övgü", "Hep benden hızlıydın."], ["dinle", "Göster bakayım."]]]],
		"aile": [
			["Bazen düşünüyorum: bu ev on yıl sonra nasıl olur? Daha kalabalık mı, daha sessiz mi?",
				[["destek", "Nasıl olursa olsun, ikimiz içindeyiz."], ["dinle", "Sen nasıl olsun istersin?"], ["şaka", "Kalabalık olursa kunaileri yükseğe asarız."]]],
			["%KIDS", [["destek", "İkimize de çekmiş, iyi olacak."], ["dinle", "Bugün ne yaptı, anlat."], ["dürüst", "Biraz fazla üstüne düşüyoruz belki."]]]],
		"şaka": [
			["Ay dur, gülmekten yanaklarım ağrıdı! Seninle evlenirken bunu hesaba katmamıştım.",
				[["şaka", "Sözleşmede yazıyordu, okumadın."], ["destek", "Sen gül, gerisi kolay."], ["dinle", "Neyi hesaba katmıştın peki?"]]],
			["Sus, komşular duyacak! ...Yok, duysunlar. Bu evde gülündüğünü bilsinler.",
				[["şaka", "Yarın pazarda konu biziz."], ["destek", "Hep gülelim, yeter."], ["dürüst", "Komşular zaten her şeyi duyuyor."]]]],
		"dedikodu": [
			["%NEWS", [["dinle", "Sen başka ne duydun?"], ["dürüst", "Köyün lafı bitmez."], ["şaka", "Pazardan haber alman görev raporundan hızlı."]]]],
		"övgü": [
			["...Yıllar geçti, hâlâ böyle söyleyince yüzüm kızarıyor. Devam et, durma.",
				[["övgü", "Her gün biraz daha güzelleşiyorsun."], ["destek", "Bu evi ev yapan sensin."], ["şaka", "Devamı yarına, taksitle."]]],
			["Bunu görevden önce söyle bana, sonra değil. Yolda aklımda kalsın diye.",
				[["destek", "Her çıkışımda söyleyeceğim."], ["övgü", "Aklımdan zaten hiç çıkmıyorsun."], ["şaka", "Not alayım: önce iltifat, sonra kunai."]]]],
	},
	"sevgili": {
		"antrenman": [
			["Görevlerinden bana hep yarısını anlatıyorsun. Diğer yarısı ne kadar kötüydü?",
				[["dürüst", "Kötüydü. Ama seni düşününce geçti."], ["destek", "Yarısı sana yeter, gerisi dert."], ["şaka", "Diğer yarısı gizli, S rütbe."]]],
			["Bir gün birlikte idman yapalım mı? Seni yenersem akşam yemeği senden.",
				[["şaka", "Yenilirsem bilerek yenilmişimdir."], ["destek", "Olur, yarın sabah alanda."], ["dürüst", "Seni yormak istemem."]]]],
		"aile": [
			["Ailem seni soruyor artık. «O ninja ne zaman yemeğe gelecek» diyorlar.",
				[["destek", "Ne zaman istersen gelirim."], ["şaka", "Annenin yemeği güzelse yarın."], ["dürüst", "Biraz daha zaman verelim."]]],
			["Hiç düşündün mü... ileride, ikimiz? Yani bir ev, bir bahçe.",
				[["destek", "Düşündüm. Bahçede iki ağaç olsun."], ["dinle", "Sen nasıl hayal ediyorsun?"], ["şaka", "Bahçeye antrenman kütüğü dikersen olur."]]]],
		"şaka": [
			["Haha! Sus, biri görecek... İnsan içinde böyle güldürme beni.",
				[["şaka", "O zaman gizli gizli güldürürüm."], ["destek", "Görsünler, ne olacak."], ["dinle", "Kimden çekiniyorsun?"]]]],
		"dedikodu": [
			["%NEWS", [["dinle", "Başka?"], ["dürüst", "Bizi de konuşuyorlardır."], ["şaka", "Köyün en büyük dedikodusu biziz zaten."]]]],
		"övgü": [
			["...Yine yaptın. Ne diyeceğimi bilemiyorum böyle olunca.",
				[["övgü", "Bir şey deme, sadece gülümse."], ["destek", "Hak ediyorsun."], ["şaka", "İlk kez susturdum seni, not edeyim."]]]],
	},
	"cocuk": {
		"antrenman": [
			["Bugün hocam mührü yanlış yaptığımı söyledi. Herkesin önünde. Ama haklıydı.",
				[["destek", "Yanlışını bilen doğrusunu bulur."], ["dinle", "Göster, hangi mühür?"], ["dürüst", "Hocan haklıysa kızmak yok."]]],
			["Sen benim yaşımdayken hangi tekniği biliyordun? Ben geride miyim?",
				[["destek", "Geride değilsin, kendi yolundasın."], ["dürüst", "Ben senden yavaştım aslında."], ["şaka", "Ben senin yaşında kedi kovalıyordum."]]]],
		"aile": [
			["Evde olmadığın günlerde kapıya bakıyorum. Ama kimseye söylemedim, sen de söyleme.",
				[["destek", "Hep döneceğim, söz."], ["dinle", "Başka ne yapıyorsun ben yokken?"], ["dürüst", "Her zaman dönemeyebilirim; o yüzden güçlen."]]],
			["Ben küçükken nasıldım? Herkes «sana benziyor» diyor, ben göremiyorum.",
				[["şaka", "İnadın aynı, gerisi daha güzel."], ["dinle", "Kim söylüyor bunu?"], ["destek", "Benden iyisi olacaksın."]]]],
		"şaka": [
			["Hahaha! Bunu takımdakilere anlatacağım, «bizimki söyledi» diyeceğim!",
				[["şaka", "Telif isterim."], ["destek", "Anlat, gülsünler."], ["dinle", "Takımda en çok kim gülüyor?"]]]],
		"dedikodu": [
			["Takımdaki çocuk her sabah geç kalıyor, hocam kızıyor. Ama bence evde derdi var.",
				[["destek", "Sen ona iyi davran, yeter."], ["dinle", "Ne derdi varmış?"], ["dürüst", "Bir ninja bahanesiz gelir."]]]],
		"övgü": [
			["...Gerçekten mi? Bunu senden duymak, alın bandımı aldığım günden bile güzel.",
				[["övgü", "Her gün gurur duyuyorum seninle."], ["destek", "Daha da iyisini yapacaksın."], ["şaka", "Şımarma, yarın yine erken kalkacaksın."]]]],
	},
	"hoca": {
		"antrenman": [
			["Hatan elinde değil, gözünde. Rakibin omzuna bakıyorsun; kalçasına bak. Omuz yalan söyler.",
				[["dinle", "Gösterin hocam, bir daha deneyeyim."], ["dürüst", "Omza bakmayı da siz öğretmiştiniz."], ["şaka", "Demek omuzlar da ninja."]]]],
		"aile": [
			["Senin yaşında ben de hocamın sözünü dinlemezdim. O yüzden şu yara izini taşıyorum.",
				[["dinle", "Nasıl oldu, anlatır mısınız?"], ["destek", "İz de bir ders olmuş demek."], ["şaka", "Ben dinliyorum ama, bazen."]]]],
		"şaka": [
			["Hm. Görev raporuna bunu da yaz: «Hocamı güldürmeyi denedim, kısmen başardım.»",
				[["şaka", "Rütbesi D mi olur, S mi?"], ["dürüst", "Bıyık altından güldünüz, gördüm."], ["dinle", "Sizi en son kim güldürdü?"]]]],
		"dedikodu": [
			["%NEWS", [["dinle", "Siz ne düşünüyorsunuz?"], ["dürüst", "Bizi ilgilendirir mi hocam?"], ["şaka", "Hocam, siz de mi dedikodu?"]]]],
		"övgü": [
			["Minnet güzel şeydir. Ama bana borcunu, senden sonra gelene öğreterek ödersin.",
				[["destek", "Ödeyeceğim hocam."], ["övgü", "Sizden iyisini bulamazdım."], ["şaka", "Taksitle olur mu?"]]]],
	},
}


static func _pick(pool: Array, f: Dictionary, slot: String):
	if pool.is_empty():
		return null
	var last = int(f.get("said", {}).get(slot, -1))
	var i = randi() % pool.size()
	if pool.size() > 1 and i == last:
		i = (i + 1 + randi() % (pool.size() - 1)) % pool.size()
	if not f.has("said") or not f["said"] is Dictionary:
		f["said"] = {}
	f["said"][slot] = i
	return pool[i]


static func _fill(s: String) -> String:
	if s.contains("%P"):
		s = s.replace("%P", _parent_word())
	if s.contains("%s"):
		s = s.replace("%s", String(pr().get("name", "")))
	return s


# ---------------------------------------------------------------------- selam
## Selam: önce gerçek durumdan bir söz (yaran, yeni rütben, kilon, ağaran saçın...), yoksa ilişkinin kendi selamı
static func hello(f: Dictionary) -> String:
	var r = rel(f)
	var rm = remark(f, r)
	if rm != "":
		return _fill(rm)
	if not KinTalk.key(f).is_empty():
		return KinTalk.hello(r, String(pr().get("name", "")))
	if Aging.person_years(f) >= 60.0 and r in ["dost", "arkadas", "tanidik", "hoca"] and randf() < 0.5:
		return _fill(String(_pick(ELDER, f, "elder")))
	var job = Friends.job_of(f)
	if JOB.has(job) and r in ["dost", "arkadas", "tanidik", "takim"] and randf() < 0.3:
		return _fill(String(_pick(JOB[job], f, "job")))
	return _fill(String(_pick(HELLO.get(r, HELLO["arkadas"]), f, "hello")))


static func _now_state() -> Dictionary:
	var done = 0
	for k in pr().get("missions_done", {}):
		done += int(pr()["missions_done"][k])
	var sh = Aging.player_shape()
	var grey = 0.0
	var pl = Game.player
	if pl != null and is_instance_valid(pl) and pl.get("model") != null and pl.model.look.get("hair0") is Color:
		var a: Color = pl.model.look["hair0"]
		var b: Color = pl.model.look["hair"]
		grey = absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
	return {"rank": int(pr().get("rank", 0)), "fat": sh.x, "mus": sh.y, "grey": grey, "done": done, "wed": Friends.spouse_id()}


## Son görüşmeden bu yana sende ne değişti: tek söz (yoksa ""), ilişkiye göre
static func remark(f: Dictionary, r: String) -> String:
	var now = _now_state()
	var first = not f.has("seen") or not f["seen"] is Dictionary
	var seen: Dictionary = now if first else f["seen"]
	var gap = Time.get_unix_time_from_system() - float(f.get("last_seen_t", Time.get_unix_time_from_system()))
	f["last_seen_t"] = Time.get_unix_time_from_system()
	var key = ""
	var pl = Game.player
	if pl != null and is_instance_valid(pl) and float(pl.hp) < float(pl.max_hp) * 0.4:
		key = "hurt"
	elif int(now["rank"]) > int(seen.get("rank", 0)):
		key = "rank"
	elif String(now["wed"]) != "" and String(seen.get("wed", "")) == "" and r != "es":
		key = "wed"
	elif float(now["grey"]) - float(seen.get("grey", 0.0)) > 0.35:
		key = "grey"
	elif float(now["fat"]) - float(seen.get("fat", 0.0)) > 0.2 and float(now["fat"]) > 0.15:
		key = "fat_up"
	elif float(now["fat"]) - float(seen.get("fat", 0.0)) < -0.2 and float(now["fat"]) < 0.1:
		key = "fat_down"
	elif float(now["mus"]) - float(seen.get("mus", 0.0)) > 0.2:
		key = "mus_up"
	elif int(now["done"]) - int(seen.get("done", 0)) >= 3:
		key = "missions"
	elif gap > 3.0 * 3600.0:
		key = "gap"
	elif HomeLife.night() and randf() < 0.3:
		key = "night"
	# görülen değişiklik not edilir (her biri bir kez söylenir); yara ve gece kalıcı değişiklik değil
	if first:
		f["seen"] = now
	var fld = String({"rank": "rank", "wed": "wed", "grey": "grey", "fat_up": "fat", "fat_down": "fat", "mus_up": "mus", "missions": "done"}.get(key, ""))
	if fld != "":
		f["seen"][fld] = now[fld]   # yalnız söylenen değişiklik: ötekiler sonraki görüşmelere kalır
	if key == "":
		return ""
	var d: Dictionary = REMARK[key]
	return String(_pick(d.get(r, d["*"]), f, "rm_" + key))


# ---------------------------------------------------------------------- konular
static func label(f: Dictionary, key: String, base: String) -> String:
	return String(LABEL.get(rel(f), {}).get(key, base))


const BRANCH := {"taijutsu": "taijutsu", "ninjutsu": "ninjutsu", "genjutsu": "genjutsu", "kenjutsu": "kılıç", "shurikenjutsu": "atış", "chakra": "chakra kontrolü",
	"hiz": "hız", "dayaniklilik": "dayanıklılık", "fuinjutsu": "mühür"}
const EL_NAME := {"katon": "Katon", "suiton": "Suiton", "fuuton": "Fūton", "doton": "Doton", "raiton": "Raiton"}


## Konu: [açtığı söz, [[üslup, cevabın], ...]] — ilişkiye göre, gerçek veriyle (ailesi, elementi, köy haberi, senin ustalığın)
static func topic(f: Dictionary, key: String) -> Array:
	var r = rel(f)
	var pool: Array = TALK.get(r, TALK["*"]).get(key, TALK["*"][key])
	var ok = []
	for t in pool:
		var line = _data(String(t[0]), f)
		if line != "":
			ok.append([line, t[1]])
	if ok.is_empty():
		for t in TALK["*"][key]:
			var line = _data(String(t[0]), f)
			if line != "":
				ok.append([line, t[1]])
	return _pick(ok, f, "tp_%s" % key)


## Söz içindeki veri yerleri; veri yoksa "" (o söz atlanır)
static func _data(s: String, f: Dictionary) -> String:
	if not s.contains("%"):
		return s
	if s.contains("%EL"):
		return s.replace("%EL", String(EL_NAME.get(String(f.get("element", "")), "Yeni bir teknik")))
	if s.contains("%BR"):
		var best = ""
		var bv = 2.0
		for k in pr().get("mastery", {}):
			if BRANCH.has(k) and float(pr()["mastery"][k]) > bv:
				bv = float(pr()["mastery"][k])
				best = String(k)
		return "" if best == "" else s.replace("%BR", String(BRANCH[best]))
	if s == "%FAM1" or s == "%FAM2":
		return _family_line(f, s == "%FAM2")
	if s == "%KIDS":
		var kids = (pr().get("children", []) as Array)
		if kids.is_empty():
			return ""
		var k = kids.pick_random()
		var nm = String(k.get("name", "Çocuk")) if k is Dictionary else "Çocuk"
		return "%s bugün yine uyumadan önce seni sordu. Gözleri sana, inadı bana çekmiş." % nm.split(" ")[-1]
	if s == "%NEWS":
		var nw: Array = WorldNews.recent()
		if nw.is_empty():
			return ""
		return "Duydun mu? %s" % _dot(String(nw[randi() % nw.size()]))
	if s == "%FLOG":
		var c = []
		for id in Friends.all():
			var o: Dictionary = Friends.all()[id]
			if o != f and not (o.get("log", []) as Array).is_empty() and String(o.get("status", "")) != "öldü" and not o.has("kin"):
				c.append("%s var ya... Duyduğuma göre: %s." % [String(o["name"]), String(o["log"][-1]).to_lower()])
		return "" if c.is_empty() else String(c.pick_random())
	return _fill(s)


## Ailesinden gerçek biri (Friends kaydındaki "family"): hayattaysa hâli, öldüyse hatırası
static func _family_line(f: Dictionary, lost: bool) -> String:
	var fam: Array = f.get("family", [])
	var c = fam.filter(func(m): return bool(m.get("alive", true)) != lost)
	if c.is_empty():
		return ""
	var m: Dictionary = c.pick_random()
	var who = String(m["rel"])
	var mine = {"Babası": "Babam", "Annesi": "Annem", "Kız kardeşi": "Kız kardeşim", "Erkek kardeşi": "Erkek kardeşim", "Karısı": "Karım", "Kocası": "Kocam", "Kızı": "Kızım", "Oğlu": "Oğlum"}.get(who, "Bizimkiler")
	var given = String(m.get("name", "")).split(" ")[-1]
	if lost:
		return {"Babası": "Babam %s görevden dönmedi. Alın bandını kapının yanına astık; her çıkışımda elim ona değiyor." % given,
			"Annesi": "Annem %s öleli çok oldu. Yemeklerinin kokusunu hâlâ bazı sokaklarda duyar gibi oluyorum." % given}.get(who, "%s artık yok. Adını pek anmam, ama sen sorunca içim hafifledi." % mine)
	match who:
		"Babası":
			return "Babam %s hep görevde; evde olduğu günler parmakla sayılır. Bazen ona kızıyorum, sonra kendim de aynısını yapıyorum." % given
		"Annesi":
			return "Annem %s evi tek başına çeviriyor. Her gidişimde elime bir bento tutuşturuyor, ben de hâlâ utanıyorum." % given
		"Kız kardeşi", "Erkek kardeşi":
			return "%s %s akademiye başladı. Beni örnek alıyormuş. Bu beni korkutuyor aslında." % [mine, given]
		"Karısı", "Kocası":
			return "%s %s görevlerimden hoşlanmıyor. Haklı da. Ama başka bir işim yok ki." % [mine, given]
		"Kızı", "Oğlu":
			return "%s %s dün ilk kez adımı söyledi. Görevdeydim, kaçırdım. Bunu kendime affetmiyorum." % [mine, given]
	return ""


# ---------------------------------------------------------------------- köylüler
## "Köyde neler oluyor?": önce dünyada gerçekten olan (haber), sonra tanıdıklarının başına gelen, en son sıradan söylenti
static func village_news() -> String:
	var c = []
	for h in WorldNews.recent():
		c.append("Duymadın mı? %s" % _dot(String(h)))
	for id in Friends.all():
		var f: Dictionary = Friends.all()[id]
		var lg: Array = f.get("log", [])
		if not lg.is_empty() and String(f.get("village", "")) == Progress.home():
			c.append("%s mı? Duydum: %s." % [f["name"], String(lg[-1]).to_lower()])
	if c.is_empty() or randf() < 0.25:
		return String(Friends.RUMORS.pick_random())
	return String(c.pick_random())


## Tanımadığın köylünün ilk sözü: çoğu zaman rolünün kendi sözü; bazen yaşına ve senin hâline göre
const STR_ELDER := ["Evladım, şu yokuşu ben senin yaşında koşarak çıkardım. Şimdi yokuş beni çıkıyor.", "Bu köyün kuruluşunu dedem anlatırdı. Ben de torunuma anlatıyorum, dinlemiyor.",
	"Gençler hep acele ediyor. Varacağınız yer kaçmıyor ki.", "Eskiden kapıda nöbetçi olmazdı, herkes herkesi tanırdı."]
const STR_KID := ["Sen gerçek ninja mısın? Kunaine dokunabilir miyim?", "Ben de büyüyünce Kage olacağım! Annem önce sebzeni ye diyor.", "Suyun üstünde yürüyebiliyor musun? Göstersene!"]
const STR_HURT := ["Aman, üstün başın kan içinde! Hastane şu tarafta, hadi.", "İyi misin sen? Yüzün kireç gibi."]
const STR_RANK := ["Jōnin-sama! Köyümüzü koruduğunuz için sağ olun.", "Sizi tanıyorum, görevlerinizi duyduk. Elinize sağlık.", "Çocuğum sizi örnek alıyor, haberiniz olsun."]
const STR_NIGHT := ["Bu saatte sokakta mısın? Dikkat et, gece kimin dolaştığı belli olmaz.", "Uyku tutmadı, hava alıyorum. Sen de mi?"]


static func stranger(v: Node, base: String) -> String:
	if pr().is_empty() or Orgs.is_rogue() or v.get("interior"):
		return base
	var pl = Game.player
	if pl != null and float(pl.hp) < float(pl.max_hp) * 0.4:
		return String(STR_HURT.pick_random())
	if randf() > 0.4:
		return base
	var look: Dictionary = v.get("look") if v.get("look") is Dictionary else {}
	var y = float(look.get("years", 30.0))
	var c = []
	if y >= 62.0:
		c.append_array(STR_ELDER)
	elif y < 12.0:
		c.append_array(STR_KID)
	else:
		if int(pr().get("rank", 0)) >= 3:
			c.append_array(STR_RANK)
		if HomeLife.night():
			c.append_array(STR_NIGHT)
	return base if c.is_empty() else String(c.pick_random())


## Köylü sözü bulunduğun köye göre: Hokage / Ichiraku / kayadaki yüzler yalnız Konoha'da
const KAGE_TITLE := {"konoha": "Hokage", "suna": "Kazekage", "kiri": "Mizukage", "kumo": "Raikage", "iwa": "Tsuchikage"}
const LOCAL_FOOD := {"suna": "Pazardaki hurmalı çörek bugün sıcak çıkmış, kaçırma!", "kiri": "Limandan taze balık gelmiş, çorbacı sabahtan kazanı kurdu.",
	"kumo": "Yukarı sokaktaki ızgaracı yine sıra yaptırıyor; dağ havası acıktırıyor.", "iwa": "Taş fırının ekmeği bugün de çıtır çıtır, kokusu sokağı tutmuş."}
const LOCAL_SIGHT := {"suna": "Rüzgâr dinince surların üstünden çöl bambaşka görünüyor.", "kiri": "Sis bu sabah öyle kalındı ki kendi kapımı bulamadım.",
	"kumo": "Bulutlar bugün köyün altında kaldı; insan kendini gökte sanıyor.", "iwa": "Kayalıklara vuran akşam güneşi her seferinde içimi ısıtıyor."}


static func localize(line: String) -> String:
	if not (line.contains("Hokage") or line.contains("Ichiraku") or line.contains("Kayadaki")):
		return line
	var vid = Outfits.village_near()
	if vid == "konoha":
		return line
	if line.contains("Ichiraku"):
		return String(LOCAL_FOOD.get(vid, "Hanın çorbası bugün güzel olmuş, yolun düşerse uğra."))
	if line.contains("Kayadaki"):
		return String(LOCAL_SIGHT.get(vid, "Bu köy küçük ama akşamları pek huzurlu olur."))
	return line.replace("Hokage", String(KAGE_TITLE.get(vid, "Köy Lideri")))


# ====================================================================== tepkiler (hediye, flört, özür, kışkırtma, tanışma)
## Olay -> {ilişki ya da kişilik ya da "*": [sözler]}; önce ilişki (anne, baba, eş...), sonra kişilik, en son genel.
## %G hediyenin adı, %N kendi adı, %R rütbesi
const REACT := {
	"gift_like": {"*": ["%G! Bunu nasıl bildin? En sevdiğim!"],
		"ciddi": ["%G... Gözlemcisin. Bunu not ettim, teşekkür ederim."], "neşeli": ["%G! Yaşasın! Sana sarılabilir miyim?"],
		"utangaç": ["B-bunu bana mı aldın? %G... en sevdiğim şey. Nereden bildin?"], "gururlu": ["%G. Zevkli birisin, kabul ediyorum."],
		"sıcakkanlı": ["Ah, %G! Düşünmüşsün beni, yüreğine sağlık."], "alaycı": ["%G? Hm. İlk kez bir hediyeye laf bulamıyorum."],
		"anne": ["Yavrum, %G! Kendine harcasaydın... ama çok sevindim."], "baba": ["%G. ...Annene gösterme, kıskanır. Sağ ol evlat."],
		"buyuk": ["%G! Demek beni tanıyormuşsun. İlk kez borçlu kaldım sana."], "kucuk": ["%G! Bana mı?! En iyi kardeş sensin!"],
		"es": ["%G... Bunca zaman sonra hâlâ neyi sevdiğimi unutmamışsın."], "cocuk": ["%G! Takımdakilere göstereceğim, «bizimki aldı» diyeceğim!"]},
	"gift_hate": {"*": ["...%G? Ben bundan hiç hoşlanmam aslında."],
		"ciddi": ["%G. Bunu kullanmam. Yine de niyetin için sağ ol."], "neşeli": ["Hahaha, %G? Bunu sana geri hediye edeceğim, haberin olsun."],
		"utangaç": ["Ş-şey... Bunu pek sevmem ama... yine de saklarım."], "gururlu": ["%G? Beni kim sandın sen?"],
		"sıcakkanlı": ["Ah... %G. Pek bana göre değil ama düşünmen yeter."], "alaycı": ["%G. Harika. Düşmanıma verecek bir şeyim oldu."],
		"anne": ["Aman yavrum, %G benim neyime... Sen kullan, sen ye."], "baba": ["Hm. %G. Rafa koyarım."], "kucuk": ["%G? Ben bunu sevmiyorum ki... Sen unuttun mu?"]},
	"gift_ok": {"*": ["Teşekkür ederim, düşünmen güzel."],
		"ciddi": ["Gerek yoktu. Ama teşekkürler."], "neşeli": ["Oo, hediye! Günüm iyi başladı."], "utangaç": ["T-teşekkürler... Beklemiyordum."],
		"gururlu": ["Fena değil. Kabul ediyorum."], "sıcakkanlı": ["Eline sağlık, ne incesin."], "alaycı": ["Hediye ha? Benden ne isteyeceksin bakalım."],
		"anne": ["Sağ ol kuzum. Ama asıl hediye senin gelmen."], "baba": ["Sağ ol. Paranı boşa harcama ama."], "es": ["Durup dururken hediye... Bir şey mi kırdın evde?"]},
	"gift_cold": {"*": ["...Sağ ol.", "Hediyeyle unutulmaz bu. Ama aldım."], "anne": ["...Bırak şuraya."], "baba": ["Hediyeyle gönül alınmaz evlat."]},
	"gift_spam": {"*": ["Yine mi hediye? Beni satın almaya mı çalışıyorsun?"], "alaycı": ["Bir hediye daha. Suçun büyük olmalı."],
		"anne": ["Yavrum yeter, evi dükkâna çevirdin. Paran sende kalsın."], "baba": ["Bu kadar hediye, itiraf edilecek bir şey var demektir. Söyle."]},
	"provoke": {"*": ["Ne dedin sen?!", "Bunu unutmayacağım.", "Hadi oradan!"],
		"ciddi": ["Sözlerini tart. Bir dahaki sefere kunaimle cevap veririm."], "neşeli": ["Hey! Bu hiç komik değildi."], "utangaç": ["...Neden böyle söyledin? Ben sana ne yaptım?"],
		"gururlu": ["Bana mı söyledin onu? Tekrar et, cesaretin varsa."], "sıcakkanlı": ["Bunu senden beklemezdim. Kırıldım."], "alaycı": ["Aa, dişlerin varmış. Yazık ki küt."],
		"anne": ["Annenle böyle konuşulmaz. Git başımdan şimdi."], "baba": ["Sesini alçalt. Ben senin takım arkadaşın değilim."],
		"buyuk": ["Bana bak, seni hâlâ tek elimle yere yatırırım."], "kucuk": ["Çok kötüsün! Anneme söyleyeceğim!"], "es": ["Bunu bana mı söylüyorsun? ...Bu akşam sofrayı kendin kur."],
		"hoca": ["Dilini öğrettiğim gibi kullan. Yarın sabah iki yüz tur."], "ogrenci": ["H-hocam... Ben ne yaptım ki?"], "cocuk": ["...Bunu hak etmedim."]},
	"sorry_ok": {"*": ["...Peki. Bir şans daha."], "gururlu": ["Özür dilemek cesaret ister. Kabul."], "alaycı": ["Özür ha? Takvime yazayım. ...Tamam, geçti."],
		"sıcakkanlı": ["Gel buraya, uzatma. Küs kalmayı beceremiyorum zaten."], "anne": ["Gel buraya. Bir anne ne kadar küs kalabilir ki?"], "baba": ["Hatasını bilen adamdır. Otur."],
		"buyuk": ["İyi. Ama bir dahakine ensene yapıştırırım."], "kucuk": ["...Bir daha yapmayacaksan barışırım."]},
	"sorry_no": {"*": ["Özrün de sen de umurumda değil."], "utangaç": ["...Henüz hazır değilim. Sonra."], "ciddi": ["Söz yetmez. Davranışını görelim."],
		"anne": ["Kalbim kırık yavrum. Biraz zaman ver."], "baba": ["Söz ucuzdur. Davranışını görelim."], "kucuk": ["Hayır. Hâlâ küsüm."]},
	"flirt_start": {"*": ["Ben de seni fark etmiştim aslında."], "utangaç": ["Ö-öyle mi? ...Bunu duyduğuma sevindim."], "gururlu": ["Hmm, cesursun. Bakalım nereye varacak."],
		"ciddi": ["...Açık sözlüsün. Bunu takdir ederim. Düşüneceğim."], "neşeli": ["Gerçekten mi? Hah, bugünün en güzel haberi bu!"], "alaycı": ["Benden mi hoşlanıyorsun? Zevkin tartışılır ama... devam et."]},
	"friend_only": {"*": ["Tabii, iyi bir arkadaş her şeyden değerli."], "alaycı": ["Arkadaş. Tamam. Kalbimi kırmadan önce sormana gerek yoktu ama."], "utangaç": ["A-arkadaş... Evet. Bu da güzel."]},
	"compliment": {"*": ["Bunu bana mı söyledin? Hehe."], "utangaç": ["Ah... sağ ol. Yüzüm kızardı mı?"], "alaycı": ["Dalga geçmiyorsun değil mi?"],
		"ciddi": ["...İltifata alışık değilim. Ama hoşuma gitti."], "gururlu": ["Biliyorum. Yine de senden duymak güzel."], "sıcakkanlı": ["Sen de az değilsin, bilesin."], "neşeli": ["Devam et, devam et! Bütün gün dinlerim."]},
	"date_yes": {"*": ["...Ben de uzun zamandır bunu düşünüyordum. Evet!"], "ciddi": ["Evet. Bunu hafife almam, sen de alma."],
		"alaycı": ["Sonunda sordun. Yaşlanacaktım beklerken. ...Evet."], "utangaç": ["E-evet... Evet! Sesim titriyor, kusura bakma."], "gururlu": ["Doğru kişiye sordun. Evet."]},
	"date_no": {"*": ["Senden hoşlanıyorum ama... biraz daha zaman ver."], "ciddi": ["Henüz değil. Seni daha iyi tanımam gerek."], "alaycı": ["Acele etme. İyi şeyler bekletir."]},
	"breakup": {"*": ["...Anlıyorum. Yolun açık olsun."], "gururlu": ["Öyle olsun. Arkana bakma, ben bakmayacağım."], "utangaç": ["...Bir şey mi yaptım? ...Peki. Hoşça kal."],
		"alaycı": ["Demek bu kadardı. Güzel bir şakaydı."], "sıcakkanlı": ["Kalbim kırıldı ama sana kızamıyorum. Kendine iyi bak."], "ciddi": ["Kararını verdiysen söz uzatmam. Hoşça kal."]},
	"baby": {"*": ["Bir çocuk... Bizim çocuğumuz. Evet, hazırım."], "ciddi": ["Bir çocuk büyük sorumluluk. ...Seninle üstlenirim."],
		"neşeli": ["Bir bebek mi? Evin içinde küçük ayak sesleri! Evet, evet!"], "utangaç": ["B-bir bebek... Ben de düşünüyordum, söyleyemedim."]},
	"propose_no": {"*": ["Bu çok büyük bir adım... Biraz daha düşünmem lazım."], "alaycı": ["Evlilik mi? Önce bir yemeği yakmadan pişir, sonra konuşuruz."], "ciddi": ["Bu söz geri alınmaz. Emin olduğumda ben söyleyeceğim."]},
	"meet": {"*": ["Ben %N, %R. Tanıştığımıza memnun oldum! Bir gün birlikte savaşırız belki."],
		"ciddi": ["%N. %R. Görev başında tanışmayı tercih ederdim, ama bu da olur."], "neşeli": ["Selam! Ben %N, %R! Yeni yüz görmek ne güzel, buralar hep aynı insanlar."],
		"utangaç": ["B-ben %N. %R... Memnun oldum."], "gururlu": ["%N. %R. Adımı unutma, ileride çok duyacaksın."],
		"sıcakkanlı": ["Ben %N, %R. Hoş geldin! Aç mısın, bir şey ister misin?"], "alaycı": ["%N. %R. Sen de şu herkesin konuştuğu ninja mısın? Hm."]},
}


static func react(f: Dictionary, ev: String, gift := "") -> String:
	var d: Dictionary = REACT.get(ev, {})
	if d.is_empty():
		return "..."
	var r = rel(f)
	var tr = String(f.get("trait", ""))
	var pool: Array = d.get(r, d.get(tr, d["*"]))
	var s = String(_pick(pool, f, "re_" + ev))
	return s.replace("%G", gift).replace("%N", String(f.get("name", "")).split(" ")[-1]).replace("%R", Friends.rank_label(f))


# ====================================================================== kaçak dost
const ROGUE_MORE := {
	"antrenman": [["Dün gece tek başıma mühür çalıştım, ay ışığında. Köyde olsa biri «yanlış» derdi. Burada yalnızca yankı var.",
		[["dinle", "Göster, ben bakarım."], ["destek", "Yankı bile yalan söylemez, iyi gidiyorsun."], ["şaka", "Yankı sana hoca mı oldu?"]]]],
	"aile": [["Annemin sesini unutmaya başladım. Yüzünü değil; sesini. İnsan en son onu unuturmuş derlerdi, yalanmış.",
		[["dinle", "Nasıl bir sesti?"], ["destek", "Unutmadın, yalnızca uzakta kaldı."], ["dürüst", "Bu yolun bedeli bu."]]]],
	"şaka": [["Av ninjası geçen gün beş adım yanımdan geçti. Ben çalının içinde nefesimi tuttum, o da hapşırdı. Az kalsın «çok yaşa» diyecektim.",
		[["şaka", "Deseydin ödülünü ikiye bölerdi."], ["dinle", "Sonra ne oldu?"], ["dürüst", "Bir gün bu şans bitecek."]]]],
	"dedikodu": [["%RNEWS", [["dinle", "Başka ne duydun?"], ["dürüst", "Bizi ilgilendirmez, uzak dur."], ["şaka", "Simsardan çok sen haber getiriyorsun."]]]],
	"övgü": [["...Köyde beni övenler, kaçtığım gün adımı taşa kazıyıp üstünü çizdi. Senin sözün onlarınkinden ağır çekiyor.",
		[["övgü", "Çünkü ben gördüğümü söylüyorum."], ["destek", "Taş çizilir, yapılan kalır."], ["şaka", "Duygulandın mı? Kimseye söylemem."]]]],
}


## Kaçak dostun selamı: önce senin kaçak hayatının gerçek hâli (iz, ödül, baraka), yoksa kendi sözü
static func rogue_hello(f: Dictionary) -> String:
	var c = []
	if Orgs.is_rogue():
		var bounty = int(Orgs.state().get("bounty", 0))
		if RogueJobs.trail() >= 50.0:
			c.append("İzlerin sıcak. İz sürücüler kokunu almış; sığınağa dolanarak git.")
		if bounty >= 2000:
			c.append("Başındaki ödül %d Ryō olmuş. Benimkinden fazla; kıskandım desem yeridir." % bounty)
		match RogueHut.state():
			"ok":
				c.append("Barakanı gördüm. Dumanı uzaktan seçiliyor; ocağı gece yakma.")
			"burnt":
				c.append("Barakanı yakmışlar, duydum. Yeniden kur; ama izini önce soğut.")
	if c.is_empty() or randf() < 0.5:
		c = Friends.ROGUE_CHAT.duplicate()
	return "%s... %s" % [String(pr().get("name", "")), String(_pick(c, f, "rg_hello") if c.size() == Friends.ROGUE_CHAT.size() else c.pick_random())]


static func rogue_topic(f: Dictionary, key: String) -> Array:
	var pool = [Friends.ROGUE_TOPIC_TALK[key]]
	for t in ROGUE_MORE.get(key, []):
		var line = String(t[0])
		if line == "%RNEWS":
			var nw: Array = WorldNews.recent()
			if nw.is_empty():
				continue
			line = "Köylerden haber sızdı: %s Bizim için ya fırsat ya tuzak." % _dot(String(nw[randi() % nw.size()]))
		pool.append([line, t[1]])
	return _pick(pool, f, "rtp_%s" % key)


# ====================================================================== aile: ikinci sözler
## %AGE: kendi yaşı (yazıyla değil, sayı)
const KIN_MORE := {
	"baba": {
		"antrenman": ["%AGE yaşındayım; bileğim eskisi gibi dönmüyor. Ama göz hâlâ görüyor: son adımda omzun açılıyor. Kapat onu.",
			[["dinle", "Göster baba, nerede açılıyor?"], ["destek", "Gözün yeter, bileği ben döndürürüm."], ["şaka", "Yaşını söylediğine göre ciddi bir hata."]]],
		"aile": ["Annenle ilk tanıştığımızda bana kunai fırlattı. Iskaladı sandım. Sonradan öğrendim, ıskalamamış; uyarıymış.",
			[["şaka", "Demek isabet annemden geçmiş bana."], ["dinle", "Sonra ne oldu?"], ["destek", "İyi ki ıskalamamış."]]],
		"şaka": ["...Hah. Tamam, bu iyiydi. Annene söyleme güldüğümü; itibarım var.",
			[["şaka", "Sır tutarım, ücreti bir kunai seti."], ["destek", "Gülünce gençleşiyorsun baba."], ["dürüst", "Annem zaten kapıdan dinliyor."]]],
		"dedikodu": ["%NEWS Bunu çarşıda değil, nöbet değişiminde duydum. Demek ki doğru.",
			[["dinle", "Sen ne düşünüyorsun baba?"], ["dürüst", "Bana görev çıkar mı bundan?"], ["şaka", "Nöbet değişimi köyün asıl gazetesi."]]],
		"övgü": ["Bir babanın duyabileceği en ağır söz bu. Kılıç taşımak daha kolaydı.",
			[["destek", "Taşıdın ama, ikisini de."], ["övgü", "Senin oğlun, kızın olmak şans."], ["şaka", "Sırtın ağrıyorsa ondan değil, yaştan."]]]},
	"anne": {
		"antrenman": ["Senin o tekniklerinden anlamam ama ellerine bakıyorum: nasır tutmuş. Baban da böyleydi. Kremini sürüyor musun bari?",
			[["şaka", "Ninjalar krem sürmez anne."], ["destek", "Süreceğim, söz."], ["dinle", "Babamın elleri de mi böyleydi?"]]],
		"aile": ["Doğduğun gece yağmur yağıyordu. Baban görevdeydi, sabaha karşı sırılsıklam geldi; seni kucağına alırken elleri titriyordu.",
			[["dinle", "Babam mı titriyordu?"], ["destek", "İyi ki o gece doğmuşum."], ["şaka", "Demek ilk gördüğüm şey ıslak bir ninja."]]],
		"şaka": ["Hahah! Dur, çorba taşacak... Senin bu dilin kimden, bilmiyorum. Bizim sülalede yok.",
			[["şaka", "Çorbadan geçmiş bana."], ["destek", "Senden anne, başka kimden."], ["dinle", "Dedem nasıl biriydi?"]]],
		"dedikodu": ["%NEWS Pazarda herkes bunu konuşuyor. Ben de korkuyorum, sana görev diye verirler diye.",
			[["destek", "Verirlerse sağ dönerim anne."], ["dinle", "Başka ne diyorlar pazarda?"], ["dürüst", "Verirlerse giderim, işim bu."]]],
		"övgü": ["Ben %AGE yaşına geldim, böyle söz duymadım. Dur, mendilim neredeydi...",
			[["destek", "Ağlama anne, daha çok söyleyeceğim."], ["övgü", "Hepsini hak ediyorsun."], ["şaka", "Mendil sağ cebinde, her zamanki gibi."]]]},
	"buyuk": {
		"antrenman": ["Sana bir şey göstereyim ama babama söyleme; bunu bana o öğretmedi, kendim buldum.",
			[["dinle", "Göster, kimseye söylemem."], ["şaka", "Babam bilmiyorsa işe yarıyordur."], ["dürüst", "Babam bilse kızar mı?"]]],
		"aile": ["Sen doğduğunda beni odadan çıkardılar. Kapının önünde oturup «artık beni sevmeyecekler» diye ağladım. Sonra seni kucağıma verdiler.",
			[["dinle", "Sonra ne oldu?"], ["destek", "İyi ki vermişler."], ["şaka", "Demek ilk düşmanın bendim."]]],
		"şaka": ["Hah! Dilin uzamış. Küçükken bu kadar konuşmazdın, sadece ısırırdın.",
			[["şaka", "Isırmayı hâlâ biliyorum."], ["dinle", "Seni mi ısırırdım?"], ["destek", "Sen de sabırla katlanmışsın."]]],
		"dedikodu": ["%NEWS Takımda bunu konuştuk bugün. Bence arkasında başka bir şey var.",
			[["dinle", "Ne var sence?"], ["dürüst", "Kurcalama, başın yanar."], ["şaka", "Sen her şeyin arkasında bir şey görürsün."]]],
		"övgü": ["...Bunu kaydedeyim. Bir daha söylemezsin çünkü.",
			[["övgü", "Söylerim. Örnek aldığım sensin."], ["destek", "Daha çok söylemeliyim aslında."], ["şaka", "Yılda bir, kotam bu kadar."]]]},
	"kucuk": {
		"antrenman": ["Bak bak! Kunaiyi artık tahtaya saplıyorum! Bazen. Çoğu zaman sapı çarpıyor ama bazen saplanıyor!",
			[["destek", "Bazen bugün, hep yarın."], ["dinle", "Göster, bir at bakayım."], ["dürüst", "Bileğini çevirmiyorsun, o yüzden."]]],
		"aile": ["Sen yokken annem senin tabağını da koyuyor sofraya. Babam bir şey demiyor ama o tabağa bakıyor.",
			[["destek", "Bu akşam o tabak dolu olacak."], ["dinle", "Sen ne yapıyorsun o zaman?"], ["dürüst", "Her akşam gelemem, biliyorsun."]]],
		"şaka": ["Hahahaha! Bir daha, bir daha! ...Tamam, bir de ben anlatayım ama gülmezsen küserim.",
			[["dinle", "Anlat, söz gülerim."], ["şaka", "Güldürürsen bir dango."], ["destek", "Senin şakaların en iyisi."]]],
		"dedikodu": ["Akademide bir çocuk var, babası jōninmiş diye hava atıyor. Ben de «benim kardeşim...» dedim. Sonra ne dediğimi unuttum ama güzeldi.",
			[["şaka", "Umarım uçabildiğimi söylemedin."], ["destek", "Ne dediysen arkasında dururum."], ["dürüst", "Hava atmak ninjalık değil."]]],
		"övgü": ["Gerçekten mi?! Bunu yazıp yastığımın altına koyacağım!",
			[["övgü", "Yaz. Altına imzamı da atarım."], ["destek", "Daha çok övülecek şey yapacaksın."], ["şaka", "Yastığın altı dolmuştur artık."]]]},
}


static func kin_topic(f: Dictionary, kk: String, key: String) -> Array:
	var pool = [KinTalk.TALK[kk][key]]
	var t = KIN_MORE.get(kk, {}).get(key, [])
	if not t.is_empty():
		var line = String(t[0])
		if line.contains("%NEWS"):
			var nw: Array = WorldNews.recent()
			line = "" if nw.is_empty() else line.replace("%NEWS", "Duydun mu? %s" % _dot(String(nw[randi() % nw.size()])))
		if line.contains("%AGE"):
			line = line.replace("%AGE", str(int(Aging.person_years(f))))
		if line != "":
			pool.append([line, t[1]])
	return _pick(pool, f, "ktp_%s" % key)


# ====================================================================== dükkâncı, nöbetçi, klan sakini
## Sana nasıl seslenir: yaşına ve rütbene göre
static func you() -> String:
	if Kage.is_kage():
		return String(KAGE_TITLE.get(Progress.home(), "Kage")) + "-sama"
	var y = Aging.player_years()
	var rk = int(pr().get("rank", 0))
	if y < 13.0:
		return "ufaklık"
	if rk >= 3:
		return "usta"
	if y < 19.0:
		return "genç ninja"
	return "ninja"


static func _visit(kind: String) -> int:
	if not pr().has("visits") or not pr()["visits"] is Dictionary:
		pr()["visits"] = {}
	pr()["visits"][kind] = int(pr()["visits"].get(kind, 0)) + 1
	return int(pr()["visits"][kind])


## Esnafın karşılaması: kaçıncı gelişin, hâlin (yaralı, gece), kim olduğun
static func keeper(kind: String) -> String:
	var n = _visit(kind)
	var u = you()
	var pl = Game.player
	var hurt = pl != null and float(pl.hp) < float(pl.max_hp) * 0.4
	match kind:
		"inn":
			if hurt:
				return "Aman, bu ne hal! Geç otur %s; önce sıcak çorba, sonra yatak." % u
			if HomeLife.night():
				return "Bu saatte yol mu yürünür %s? Gir, ocak yanıyor; futon da hazır." % u
			return ["Hoş geldin yolcu! Sıcak yemek de var, yumuşak futon da.", "Buyur %s. Yolun tozu üstünde, önce bir çay koyayım." % u,
				"Yine mi sen? Odanı ayırmıştım zaten, hep aynı köşe." if n > 3 else "Hoş geldin. Buralarda ilk kez görüyorum seni."].pick_random()
		"weapon":
			if n == 1:
				return "Hoş geldin %s. Elin neye alışkınsa onu göstereyim; yanlış silah, sahibini satar." % u
			return ["Hoş geldin! Ne bakıyorsun?", "Yine geldin %s. Geçen aldıkların körelmiştir, bileyeyim mi dersin?" % u,
				"Yeni mal geldi, daha tezgâha dizmedim. Sana önce gösteririm." if n > 4 else "Buyur %s, tezgâh senin." % u].pick_random()
		"gate":
			if int(pr().get("rank", 0)) >= 3:
				return "Kapı açık, %s. Dışarıda bir şey görürseniz dönüşte bize de haber verin." % u
			if Aging.player_years() < 13.0:
				return "Dur bakalım ufaklık. Dışarısı tehlikeli; haritanı [M] aç, yoldan ayrılma."
			return "Dışarısı tehlikeli, %s. Haritayı [M] aç, yolları takip et. Diğer köylere varınca hızlı seyahat açılır." % u
		"ramen":
			var fat = Aging.player_shape().x
			if fat > 0.55:
				return "Sıcak bir kâse miso chashu ramen... Can ve chakra doldu! Yalnız %s, kemerin benden şikâyetçi olacak; yarın bir tur koş." % u
			if n > 5:
				return "Her zamankinden, değil mi? Sormadan koydum. Can ve chakra doldu! Bir kâse daha?"
			return "Sıcak bir kâse miso chashu ramen... Can ve chakra doldu! Bir kâse daha?"
	return "Hoş geldin."


## Klan sakininin ilk sözü: klanının kanon huyu; aynı klandansan içeriden biri gibi
const CLAN_HELLO := {
	"uchiha": "Yelpazemizi sırtında taşımayan birine fazla söz söylemeyiz. Kısa kes.", "hyuga": "Ana kol mu, yan kol mu diye sorma; o soru bu avluda sorulmaz.",
	"nara": "Konuşmak zahmetli iş... Neyse, geldin madem. Geyiklere yaklaşma yeter.", "akimichi": "Hoş geldin! Aç mısın? Aç görünüyorsun. Herkes aç görünür bana.",
	"yamanaka": "Çiçekçiye mi geldin, klana mı? İkisi de aynı kapı; aklından geçeni de duyarım, bilesin.", "inuzuka": "Köpeğim seni kokladı, ısırmadı. Demek ki fena biri değilsin.",
	"aburame": "...Böceklerim seni çoktan saydı. Sebebi şu: yabancıya önce onlar bakar.", "senju": "Orman bizim evimizdir; ağaca yaslanırken izin iste.",
	"uzumaki": "Kızıl saçımıza takılma; mühür mürekkebimiz daha kalıcıdır, dattebane!", "hoshigaki": "Dişlerime bakma. Suya girersen asıl o zaman bak.",
	"hozuki": "Susadım. Suyun var mı? Yoksa lafı kısa tutalım.", "kaguya": "Bizim klanda selam, kemiğin sesiyle verilir. Seninki tok mu çıkıyor?",
	"yuki": "Soğuk mu? Bize göre ılık. İçeri gir, kapıyı kapama.", "sarutobi": "Ateşin İradesi'ni bilir misin? Bilmezsen otur, anlatması uzun sürer.",
}


static func clan_hello(clan: String, given: String, eye_kind: int) -> String:
	var cn = ClanWorld.clan_name(clan)
	var head = "%s klanından %s. " % [cn, given.split(" ")[-1]]
	if String(pr().get("clan", "")) == clan:
		return head + ["Bizdensin; avluda yerin hep var.", "Klanın adını dışarıda iyi taşı. Burada herkes seni izliyor.", "Hoş geldin %s. Büyükler seni soruyordu." % you()].pick_random()
	if int(pr().get("rank", 0)) >= 3 and randf() < 0.4:
		return head + "Adını duyduk, %s. Klanımız güçlüyü tanır; buyur." % you()
	if eye_kind == 2:
		return head + "Byakugan'ım her yanı görür; yaklaştığını çoktan biliyordum."
	if eye_kind == 1 and randf() < 0.5:
		return head + "Gözlerimdeki tomoe'lara fazla bakma, genjutsuya düşersin."
	if eye_kind == 3:
		return head + "Kızıl gözlerimden korkma... henüz."
	return head + String(CLAN_HELLO.get(clan, "Ne istiyorsun, %s?" % you()))


## Rol sözü sana uymuyorsa (jōnine "akademi öğrencisi misin?") rütbene / yaşına uygun olanı
static func fit(v: Node, line: String) -> String:
	if pr().is_empty():
		return line
	var rk = int(pr().get("rank", 0))
	var role = String(v.get("role")) if v.get("role") != null else ""
	if rk >= 1 and (line.contains("Akademi öğrencisi") or line.contains("akademidensin")):
		if role == "kid":
			return String(STR_KID.pick_random())
		return ["Devriyedeyiz. Bir sorun görürsen haber ver.", "İyi görevler, %s. Yolun açık olsun." % you(), "Selam %s. Bugün köy sakin, böyle kalsın." % you()].pick_random()
	if role in ["guard", "patrol"] and rk >= 3 and randf() < 0.5:
		return ["%s! Nöbet yerinde, bildirecek bir şey yok." % you().capitalize(), "Sizi görünce dik durduk, belli oldu mu? Kolay gelsin %s." % you()].pick_random()
	if line.contains("Ateşin İradesi") and Outfits.village_near() != "konoha":
		return "Çok çalış; bu köy seninle ayakta duracak."
	if line.contains("Kumo'dan") and Outfits.village_near() == "kumo":
		return line.replace("Kumo'dan", "Konoha'dan")
	return line


static func _dot(t: String) -> String:
	t = t.strip_edges()
	return t if t.is_empty() or t[-1] in [".", "!", "?", "…"] else t + "."
