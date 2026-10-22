class_name MissionLocal
extends RefCounted
## Köylere özgü görev havuzları (yerel renk). Her girdi bir kalıp (p) + metinlerdir; Missions._from_spec adımlara çevirir.
## Kalıplar: escort, camp, collect, defend, rescue, patrol, duel, investigate, chase, stealth
## r: rank, t: başlık, b: brifing, g: görevi veren, s1/s2: giverin repliği (başta/sonda), e: düşman türü, en: düşman adı, n: sayı

const POOL := {
	"konoha": [
		{"r": "D", "p": "collect", "t": "Hokage Kayası Temizliği", "b": "Kayadaki dev yüzlerin üstüne kuşlar yuva yapmış. Yuva artıklarını topla — aşağı bakma!", "g": "Kaya Bakımcısı Ishida", "item": "kuş yuvası", "n": 6, "s1": "Yüzlerin burnunda bile yuva var! Duvar koşusunu bilirsin değil mi?", "s2": "Tertemiz! Hokage'ler sana minnettar olurdu."},
		{"r": "D", "p": "collect", "t": "Akademi Deposu", "b": "Akademi'nin antrenman kunai'leri ormana saçılmış. Topla, sayım yarın!", "g": "Akademi Hademesi Goro", "item": "eğitim kunaisi", "n": 8, "s1": "Öğrenciler her yere atıyor! 8 tane eksik.", "s2": "Tamam, sayım tuttu. Sen de bir zamanlar böyleydin."},
		{"r": "C", "p": "camp", "t": "Orman Kaçakçıları", "b": "Ateş Ülkesi ormanında yasadışı tomruk kesen bir çete var. Kamplarını dağıt.", "g": "Orman Bekçisi Moku", "e": "bandit", "en": "Kaçak Tomrukçu", "n": 4, "s1": "Ağaçlar yüz yıllık! Kampları kuzeyde bir yerde.", "s2": "Orman nefes aldı. Ateşin İradesi ağaçlarda da yaşar."},
		{"r": "B", "p": "stealth", "t": "Ses Casusları", "b": "Ses Köyü'nden casuslar sınır yakınında Konoha haritalarını kopyalıyor. Belgeleri gece gizlice geri al.", "e": "oto", "item": "çalıntı harita"},
		{"r": "A", "p": "duel", "t": "Kılıç Ustası Düellosu", "b": "Gezgin bir kılıç ustası Konoha'nın en iyisiyle dövüşmek istiyor. Köyün onurunu koru.", "g": "Yabancı Kılıççı Hayabusa", "e": "samurai", "en": "Kılıç Ustası Hayabusa", "hp": 900.0, "lv": 28, "s1": "Ateş Ülkesi'nin ninjaları ne kadar güçlü, görelim!", "s2": "Kılıcım kırıldı ama gururum yerinde. İyi dövüştün."},
	],
	"suna": [
		{"r": "C", "p": "escort", "t": "Çöl Kervanı", "b": "Su ve baharat taşıyan kervan kum fırtınası mevsiminde yola çıkıyor. Kum haydutları pusuda.", "npc": "Kervan Başı Rashid", "e": "bandit", "en": "Kum Haydudu", "s1": "Güneş batmadan vahaya varmalıyız. Kum fırtınası gelirse yolu kaybederiz!", "s2": "Vaha! Bu yolculukta sen olmasan kervan kumlara gömülürdü."},
		{"r": "B", "p": "rescue", "t": "Kum Fırtınasında Kayıplar", "b": "Fırtınada kaybolan bir keşif ekibi kumlara gömülü bir kampta esir tutuluyor.", "hostage": "Keşifçi Leyla", "e": "bandit", "en": "Çöl Yağmacısı", "n": 4, "s": "Su... Fırtınada bizi bu haydutlar yakaladı. Diğerleri kaçtı, beni çıkar!"},
		{"r": "C", "p": "investigate", "t": "Kukla Atölyesi Hırsızlığı", "b": "Kuklacıların atölyesinden mekanik kukla parçaları çalınıyor.", "g": "Kuklacı Usta Sasago", "w1": "Çırak Kanta", "w1s": "Gece atölyenin çatısında ip sesleri duydum, kukla ipi gibi.", "w2": "Bekçi Bakir", "w2s": "Batı kapısından çıkan biri bir çuval taşıyordu. Kum izleri kanyona gidiyor.", "item": "kukla parçası", "c": [["Kanyondaki parça kaçakçıları", true], ["Çırak Kanta", false], ["Rakip kuklacı", false]], "e": "bandit", "en": "Parça Kaçakçısı", "n": 3},
		{"r": "C", "p": "camp", "t": "Akrep Yuvası Çetesi", "b": "'Akrep' lakaplı zehir satıcıları kanyonda yuvalanmış. Zehirli iğnelere dikkat.", "g": "Şifacı Nadia", "e": "rogue", "en": "Akrep Çetesi", "n": 3, "s1": "Zehirleri iki çocuğu yatağa düşürdü. Yuvalarını dağıt!", "s2": "Panzehir hazırlayabilirim artık. Sağ ol, ninja."},
		{"r": "D", "p": "defend", "t": "Vaha Su Kavgası", "b": "Vaha başında iki kervan su yüzünden kavgaya tutuştu, kiralık kabadayılar geldi. Düzeni sağla.", "g": "Vaha Bekçisi Omar", "e": "bandit", "en": "Kiralık Kabadayı", "w": [2, 3], "s1": "Su herkesin! Ama şu kabadayılar dinlemiyor.", "s2": "Sakinleştiler. Su sırayla dağıtılacak, söz."},
	],
	"kiri": [
		{"r": "C", "p": "defend", "t": "Balıkçı Köyü Savunması", "b": "Korsanlar sis çökünce balıkçı köyüne çıkarma yapıyor. Sahili koru.", "g": "Balıkçı Reis Umihiko", "e": "bandit", "en": "Sis Korsanı", "w": [3, 3, 4], "s1": "Sis kalktığında tekneleri görürüz ama iş işten geçmiş olur!", "s2": "Korsanlar denize döndü. Ağlarımız artık güvende."},
		{"r": "B", "p": "stealth", "t": "Korsan Hazinesi", "b": "Korsanların sisli koydaki kampından köyden çalınan deniz haritasını al.", "e": "bandit", "en": "Korsan Nöbetçi", "item": "deniz haritası"},
		{"r": "B", "p": "escort", "t": "Sığınmacı Kafilesi", "b": "Kan soyu yüzünden kaçmak zorunda kalan bir aile güvenli limana götürülmeli. Avcılar peşlerinde.", "npc": "Kaçak Aile Reisi Yukiya", "e": "rogue", "en": "Avcı Ninja", "s1": "Sadece doğduğumuz kan yüzünden... Lütfen çocuklarım hayatta kalsın.", "s2": "Liman... Yeni bir hayat. Seni asla unutmayacağız."},
		{"r": "A", "p": "duel", "t": "Kılıççı Sınavı", "b": "Kiri'nin efsanevi kılıççılar geleneği: aday, bir eski kılıç ustasını yenmeli.", "g": "Eski Kılıççı Shiomaru", "e": "kiri", "en": "Eski Kılıççı Shiomaru", "hp": 950.0, "lv": 30, "s1": "Sis kılıcımın sesini duyamazsan ölürsün. Hazır mısın?", "s2": "Sisin içinde bile beni gördün. Kılıççı olmaya layıksın."},
		{"r": "C", "p": "patrol", "t": "Sis Devriyesi", "b": "Sis yoğunlaşınca kıyıda kaybolan devriyelerin rotasını yürü, şüpheliyi yakala.", "e": "rogue", "en": "Sis Pusucusu", "n": 2},
	],
	"kumo": [
		{"r": "C", "p": "patrol", "t": "Uçurum Devriyesi", "b": "Kumo'nun dik kayalıklarında devriye rotasını tamamla — duvar koşusu şart. Son noktada casus izi var.", "e": "iwa", "en": "Iwa Casusu", "n": 2},
		{"r": "B", "p": "collect", "t": "Yıldırım Fırtınası Araştırması", "b": "Araştırmacılar yıldırım çarpan kayalardan şarjlı kristal istiyor. Fırtına dinmeden topla.", "g": "Araştırmacı Ikazuchi", "item": "yıldırım kristali", "n": 6, "ge": "rogue", "gn": 2, "s1": "Fırtına sadece bir saat sürer! Kayalardaki parlayan kristaller lazım.", "s2": "Muhteşem! Bu kristallerle yeni bir chakra zırhı deneyeceğiz."},
		{"r": "A", "p": "camp", "t": "Bulut Harabeleri Seferi", "b": "Dağlardaki eski harabelerde kaçak ninjalar yasak teknikler arıyor. Onları durdur.", "g": "Arkeolog Sora", "e": "rogue", "en": "Harabe Yağmacısı", "n": 4, "boss": "Yağmacı Lideri Kongo", "s1": "Harabelerdeki mühürler açılırsa felaket olur!", "s2": "Mühürler sağlam. Bulut köyü sana borçlu."},
		{"r": "B", "p": "chase", "t": "Rakip Köy Casusu", "b": "Pazarda kılık değiştirmiş bir casus Raikage'nin takvimini çaldı. Yakala!"},
	],
	"iwa": [
		{"r": "C", "p": "rescue", "t": "Heyelan Kurtarması", "b": "Bir heyelan maden işçilerini mahsur bıraktı, fırsatçı yağmacılar mağara ağzını tuttu.", "hostage": "Madenci Tetsuo", "e": "bandit", "en": "Maden Yağmacısı", "n": 4, "s": "Kayalar düştü, sonra bu herifler geldi! Bacağım sıkıştı ama yürürüm."},
		{"r": "C", "p": "camp", "t": "Maden Haydutları", "b": "Taş Ülkesi madenlerine dadanan haydutlar cevher arabalarını soyuyor.", "g": "Maden Ustası Gansuke", "e": "bandit", "en": "Maden Haydudu", "n": 5, "s1": "Üç araba cevher kayıp! Kampları eski ocakta.", "s2": "Cevher geri geldi. Taş gibi sağlam bir ninjasın."},
		{"r": "B", "p": "investigate", "t": "Patlayıcı Kil Kazası", "b": "Bir atölyede patlayıcı kil patladı. Kaza mı, sabotaj mı?", "g": "Atölye Şefi Bakuro", "w1": "Kalfa Nendo", "w1s": "Patlamadan önce biri kil fıçılarını kurcalıyordu, eldivenleri kumdan sarıydı.", "w2": "Bekçi Iwaki", "w2s": "Gece doğu sırtına doğru giden izler gördüm, yanlarında kil kokusu vardı.", "item": "kil parçası", "c": [["Kiralık sabotajcılar", true], ["Kalfa Nendo", false], ["Sadece bir kaza", false]], "e": "rogue", "en": "Sabotajcı", "n": 3},
		{"r": "A", "p": "defend", "t": "Sınır Taş Kalesi Tatbikatı", "b": "Taş kalede gerçek mermilerle tatbikat: saldıran birlikleri püskürt, komutanı yen.", "g": "Kale Komutanı Ganryu", "e": "genin_rival", "en": "Tatbikat Askeri", "w": [3, 4, 4], "s1": "Bu tatbikatta kimse yumuşak davranmaz. Kale düşerse, sen düşersin!", "s2": "Kale yerinde. Tsuchikage raporunu okuyunca gülümseyecek."},
	],
	"ame": [
		{"r": "C", "p": "investigate", "t": "Yetim Çetesi", "b": "Yağmurun altındaki fabrika şehrinde bir çocuk çetesi hırsızlık yapıyor — ama arkalarında biri var.", "g": "Fabrika Ustası Kurokawa", "w1": "Sokak Çocuğu Ame", "w1s": "Biz sadece yemek için çalıyoruz! Bize iş veren adam şehrin dışında bekliyor...", "w2": "Bekçi Sabi", "w2s": "Kanalın ötesinde, yağmurdan korunan bir çadır kampı var. Oradan geliyorlar.", "item": "ıslak makbuz", "c": [["Çocukları kullanan kaçakçılar", true], ["Yetim çocuklar", false], ["Fabrika işçileri", false]], "e": "rogue", "en": "Çocuk Sömürücüsü", "n": 3},
		{"r": "B", "p": "stealth", "t": "Kule Entrikası", "b": "Yağmur köyünün liderleri arasında bir hain düşmanla yazışıyor. Mektupları gizlice ele geçir.", "e": "rogue", "en": "Hain Muhafız", "item": "gizli mektup"},
	],
	"nami": [
		{"r": "C", "p": "escort", "t": "Köprü Ustası", "b": "Köprü ustası malzeme almaya gidiyor; nakliye şirketinin kiralık adamları onu durdurmak istiyor.", "npc": "Köprü Ustası Kaiji", "e": "bandit", "en": "Şirket Kabadayısı", "s1": "Bu köprü bitince köyümüz özgür olacak. Şirket de bunu biliyor...", "s2": "Malzemeler geldi! Köprü sana selam verecek, söz."},
		{"r": "B", "p": "camp", "t": "Nakliye Şirketi Gangsterleri", "b": "Limanı kapatan gangster şirketin silah deposuna baskın yap.", "g": "Liman İşçisi Sanpei", "e": "rogue", "en": "Şirket Paralısı", "n": 4, "boss": "Şirket Patronu Kurofune", "s1": "Tekneler yüzünden balık tutamıyoruz. Depoları kıyıdaki ambarlarda!", "s2": "Liman özgür! Bu gece balık şenliği var, sen de gel."},
	],
	"taki": [
		{"r": "C", "p": "collect", "t": "Kahraman Suyu", "b": "Kutsal ağacın kökündeki 'kahraman suyu' kaçakçılar tarafından çalınıyor. Kalan şişeleri koruma altına al.", "g": "Ağaç Muhafızı Midori", "item": "kahraman suyu", "n": 5, "ge": "rogue", "gn": 2, "s1": "Bu su çok güç verir ama ömür kısaltır. Yanlış ellere geçmemeli!", "s2": "Su güvende. Ağaç bile rahatlamış gibi."},
		{"r": "B", "p": "defend", "t": "Kutsal Ağaç Muhafızlığı", "b": "Kahraman suyunu ele geçirmek isteyen paralı ninjalar ağaca saldıracak.", "g": "Muhafız Komutanı Seiryu", "e": "rogue", "en": "Paralı Ninja", "w": [3, 4], "s1": "Ağaç düşerse Taki düşer. Yanımızda savaş!", "s2": "Kökler sağlam. Taki seni kahraman olarak anacak."},
	],
	"yu": [
		{"r": "D", "p": "chase", "t": "Kaplıca Röntgencisi", "b": "Kadınlar kaplıcasını gözetleyen utanmaz biri var! Yakalanınca kaçıyor. Bu sefer kaçmasın."},
		{"r": "C", "p": "escort", "t": "Turist Kafilesi", "b": "Zengin turistler kaplıca tepesine çıkacak; yol kenarı soyguncularıyla dolu.", "npc": "Turist Rehberi Onsuke", "e": "bandit", "en": "Yol Soyguncusu", "s1": "Misafirlerimiz kaplıca keyfi için geldi, korku için değil!", "s2": "Turistler mutlu, bahşişler bol! Kaplıca bileti benden."},
	],
	"shimo": [
		{"r": "C", "p": "rescue", "t": "Kar Fırtınasında Mahsur", "b": "Dağ geçidinde mahsur kalan yolcuları kurtar, kar haydutları geçidi tutmuş.", "hostage": "Yolcu Fuyuko", "e": "bandit", "en": "Kar Haydudu", "n": 3, "s": "Ellerimi hissetmiyorum... Lütfen beni köye götür."},
	],
	"tani": [
		{"r": "C", "p": "camp", "t": "Vadi Yağmacıları", "b": "Vadi köyünün hasadını yağmalayan bir çete dağ yamacında kamp kurmuş.", "g": "Muhtar Tanigawa", "e": "bandit", "en": "Vadi Yağmacısı", "n": 4, "s1": "Kış için ne varsa aldılar. Lütfen...", "s2": "Ambarlar doldu! Kış artık korkutmuyor."},
	],
	"uzushio": [
		{"r": "B", "p": "collect", "t": "Girdap Harabeleri", "b": "Yıkık girdap köyünün harabelerinde mühür parşömenleri yağmalanıyor. Kalanları kurtar.", "g": "Tarihçi Uzuki", "item": "mühür parşömeni", "n": 5, "ge": "rogue", "gn": 3, "s1": "Bu harabeler mühür ustalarının mirası. Yağmacılara bırakamayız!", "s2": "Parşömenler güvende. Girdap ruhu hâlâ yaşıyor."},
	],
	"tetsu": [
		{"r": "B", "p": "duel", "t": "Onur Düellosu", "b": "Bir samuray, köyünün onuruna hakaret edildiğini iddia ediyor ve düello istiyor. Ninjalar ve samuraylar arasında barış tehlikede.", "g": "Samuray Kenshiro", "e": "samurai", "en": "Samuray Kenshiro", "hp": 700.0, "lv": 22, "s1": "Ninja! Kılıcımla sana onurun ne demek olduğunu öğreteceğim.", "s2": "Yenildim... ama onurlu bir düelloydu. Barış sürsün."},
		{"r": "C", "p": "escort", "t": "Karlı Geçit", "b": "Demir Ülkesi'ne giden elçiyi karlı geçitten geçir; geçit haydutlarla dolu.", "npc": "Elçi Fubuki", "e": "bandit", "en": "Geçit Haydudu", "s1": "Bu geçitte kar fırtınası insanı yutar. Yakınımda kal.", "s2": "Generale ulaştık. Samuraylar ninjaların sözüne güvenir artık."},
	],
	"kusa": [
		{"r": "C", "p": "patrol", "t": "Çimen Sınırı Devriyesi", "b": "Kusa'nın uzun çimenlerinde saklanan casusları bul. Devriye noktalarını dolaş.", "e": "oto", "en": "Ses Gözcüsü", "n": 2},
	],
	"oto": [
		{"r": "B", "p": "stealth", "t": "Ses Laboratuvarı", "b": "Gizli bir laboratuvardan kaçırılan deneklerin kayıtlarını çal. Yakalanırsan sonun deney masası olur.", "e": "oto", "en": "Laboratuvar Muhafızı", "item": "deney kaydı"},
	],
	"hamlet": [
		{"r": "D", "p": "collect", "t": "Pirinç Hasadı", "b": "Köylülerin pirinç tarlasında hasada yardım et.", "g": "Köy Kadını Haru", "item": "pirinç demeti", "n": 8, "s1": "Yağmur gelmeden toplamazsak çürür!", "s2": "Bu kış aç kalmayacağız. Al, ev yapımı mochi."},
		{"r": "C", "p": "defend", "t": "Mezra Savunması", "b": "Haydutlar küçük mezrayı tehdit ediyor.", "g": "Mezra Yaşlısı", "e": "bandit", "en": "Haydut", "w": [2, 3, 3], "s1": "Bizim savaşçımız yok, ninja. Sadece sen varsın.", "s2": "Çocuklar güvende. Bu mezra seni unutmaz."},
	],
}
