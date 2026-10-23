class_name Gear
extends RefCounted
## Ekipman: kafa, yüz, üst/alt kıyafet, ayak, yelek, dış giysi, kol, sırt, sağ el / sol el silahı.
## profile["gear"] = sahip olunan parçalar [{uid, id, c1, c2}], profile["equip"] = {yuva: uid}

const SLOTS := [["kafa", "Kafa"], ["sag_goz", "Sağ Göz"], ["sol_goz", "Sol Göz"], ["yuz", "Yüz"], ["govde", "Üst Kıyafet"], ["bacak", "Alt Kıyafet"], ["ayak", "Ayak"], ["zirh", "Yelek / Zırh"], ["dis", "Dış Giysi"], ["kol", "Kol / Koruma"], ["sirt", "Sırt / Bel"], ["sag", "Sağ El"], ["sol", "Sol El"]]
## Boş bırakılamayan yuvalar (çıplak kalınmaz)
const REQUIRED := ["govde", "bacak", "ayak"]

## stats: def (hasar azaltma puanı), hp, chakra, speed (oran), melee (oran)
## silah: dmg (oran), reach (m), style: blade | dual | sword | heavy | staff | chain | sickle | claw | fan | fist
const ITEMS := {
	# --- kafa
	"alin_koruyucu": {"name": "Alın Koruyucu", "slot": "kafa", "price": 0, "rank": 1, "desc": "Köyünün sembolü. Genin olunca verilir.", "stats": {"def": 2}, "look": {"band_style": "head"}, "c1": Color(0.15, 0.22, 0.55)},
	"alin_boyun": {"name": "Alın Koruyucu (Boyunda)", "slot": "kafa", "price": 0, "rank": 1, "desc": "Alın koruyucuyu boynuna bağlarsın.", "stats": {"def": 2}, "look": {"band_style": "neck"}, "c1": Color(0.15, 0.22, 0.55)},
	"bandana": {"name": "Bandana Alın Koruyucu", "slot": "kafa", "price": 260, "rank": 1, "desc": "Başın tepesini saran bez, önünde köy plakası.", "stats": {"def": 3}, "look": {"head_style": "bandana", "band_style": "none"}, "c1": Color(0.15, 0.22, 0.55)},
	"kasa": {"name": "Hasır Şapka (Kasa)", "slot": "kafa", "price": 120, "rank": 0, "desc": "Geniş kenarlı gezgin şapkası. Güneşten ve yağmurdan korur.", "stats": {"def": 1, "chakra": 10}, "look": {"head_style": "kasa"}, "c1": Color(0.78, 0.66, 0.42)},
	"kapuson": {"name": "Bez Kapüşon", "slot": "kafa", "price": 150, "rank": 0, "desc": "Kafayı ve enseyi örten kapüşon. Gizlilik ustalarının tercihi.", "stats": {"def": 2, "speed": 0.02}, "look": {"head_style": "kapuson"}, "c1": Color(0.22, 0.2, 0.24)},
	"kafa_bandaji": {"name": "Kafa Bandajı", "slot": "kafa", "price": 40, "rank": 0, "desc": "Alnı saran bandaj. Savaşın izlerini taşır.", "stats": {"hp": 10}, "look": {"head_style": "bandaj"}, "c1": Color(0.92, 0.9, 0.86)},
	# --- yüz
	"bez_maske": {"name": "Bez Maske", "slot": "yuz", "price": 90, "rank": 0, "desc": "Yüzün alt yarısını ve boynu örter. Kimliğini gizler.", "stats": {"def": 1, "chakra": 10}, "look": {"face_style": "cloth"}, "c1": Color(0.15, 0.15, 0.2)},
	"anbu_maske": {"name": "ANBU Maskesi: Kedi", "slot": "yuz", "price": 900, "rank": 4, "desc": "Gizli birliklerin kedi maskesi.", "stats": {"def": 6, "melee": 0.05}, "look": {"face_style": "anbu_kedi"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_kurt": {"name": "ANBU Maskesi: Kurt", "slot": "yuz", "price": 900, "rank": 4, "desc": "Kurt maskesi: avcı içgüdüsü.", "stats": {"def": 5, "melee": 0.08}, "look": {"face_style": "anbu_kurt"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_kus": {"name": "ANBU Maskesi: Kuş", "slot": "yuz", "price": 900, "rank": 4, "desc": "Gagalı kuş maskesi: hız ve keşif.", "stats": {"def": 5, "speed": 0.05}, "look": {"face_style": "anbu_kus"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_ayi": {"name": "ANBU Maskesi: Ayı", "slot": "yuz", "price": 900, "rank": 4, "desc": "Yuvarlak kulaklı ayı maskesi: dayanıklılık.", "stats": {"def": 8, "hp": 30}, "look": {"face_style": "anbu_ayi"}, "c1": Color(0.95, 0.95, 0.95)},
	"kitsune_maske": {"name": "Kitsune Maskesi", "slot": "yuz", "price": 420, "rank": 1, "desc": "Festival tilki maskesi. Kimliğini gizler.", "stats": {"def": 2, "chakra": 15}, "look": {"face_style": "kitsune"}, "c1": Color(0.95, 0.95, 0.95)},
	"tengu_maske": {"name": "Tengu Maskesi", "slot": "yuz", "price": 650, "rank": 2, "desc": "Uzun burunlu dağ ruhu maskesi.", "stats": {"def": 3, "speed": 0.04}, "look": {"face_style": "tengu"}, "c1": Color(0.75, 0.12, 0.1)},
	"oni_maske": {"name": "Oni Maskesi", "slot": "yuz", "price": 800, "rank": 2, "desc": "Samuray iblis yüz zırhı. Düşmanı korkutur.", "stats": {"def": 5, "melee": 0.04}, "look": {"face_style": "oni"}, "c1": Color(0.2, 0.2, 0.22)},
	"gaz_maskesi": {"name": "Gaz Maskesi", "slot": "yuz", "price": 380, "rank": 1, "desc": "Zehirli bulutlara karşı filtreli maske.", "stats": {"def": 3, "hp": 15}, "look": {"face_style": "gas"}, "c1": Color(0.2, 0.22, 0.2)},
	"gozluk": {"name": "Ninja Gözlüğü", "slot": "yuz", "price": 140, "rank": 0, "desc": "Rüzgar ve kum fırtınasında gözleri korur.", "stats": {"speed": 0.02, "chakra": 5}, "look": {"face_style": "goggles"}, "c1": Color(0.95, 0.55, 0.15)},
	# --- üst
	"tisort": {"name": "Kısa Kollu Tişört", "slot": "govde", "price": 40, "rank": 0, "desc": "Hafif ve rahat.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort"}, "c1": Color(0.75, 0.2, 0.25), "c2": Color(0.12, 0.12, 0.14)},
	"uzun_gomlek": {"name": "Uzun Kollu Ninja Gömleği", "slot": "govde", "price": 120, "rank": 0, "desc": "Klasik shinobi gömleği.", "stats": {"def": 2}, "look": {"top_style": "uzun"}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"ceket": {"name": "Fermuarlı Ceket", "slot": "govde", "price": 200, "rank": 0, "desc": "İki renkli, yüksek yakalı eğitim ceketi.", "stats": {"def": 3, "hp": 10}, "look": {"top_style": "ceket"}, "c1": Color(0.95, 0.5, 0.12), "c2": Color(0.12, 0.12, 0.14)},
	"yakali": {"name": "Yüksek Yakalı Gömlek", "slot": "govde", "price": 180, "rank": 0, "desc": "Bilek sargılı, kısa kollu. Chakra akışını rahatlatır.", "stats": {"def": 2, "chakra": 15}, "look": {"top_style": "yakali"}, "c1": Color(0.15, 0.2, 0.33), "c2": Color(0.12, 0.12, 0.14)},
	"zirhli_gomlek": {"name": "Zincir Örgü Gömlek", "slot": "govde", "price": 450, "rank": 1, "desc": "Uzun kollu, ince zincir örgü ağ gömlek. Kesiklere dayanır.", "stats": {"def": 6, "speed": -0.02}, "look": {"top_style": "uzun", "top_pattern": 1}, "c1": Color(0.2, 0.22, 0.24), "c2": Color(0.12, 0.12, 0.14)},
	"file_atlet": {"name": "File Atlet", "slot": "govde", "price": 160, "rank": 0, "desc": "Kısa kollu ağ fanila. Hafif koruma, tam hareket.", "stats": {"def": 3, "speed": 0.02}, "look": {"top_style": "tisort", "top_pattern": 1}, "c1": Color(0.15, 0.15, 0.17), "c2": Color(0.12, 0.12, 0.14)},
	"kolsuz_yakali": {"name": "Kolsuz Yakalı Gömlek", "slot": "govde", "price": 150, "rank": 0, "desc": "Kolları açık, boğazlı savaş gömleği. Taijutsu ustalarına göre.", "stats": {"melee": 0.06}, "look": {"top_style": "kolsuz"}, "c1": Color(0.85, 0.82, 0.75), "c2": Color(0.12, 0.12, 0.14)},
	"sargili_kolsuz": {"name": "Sargılı Savaşçı Üstü", "slot": "govde", "price": 220, "rank": 0, "desc": "Kolsuz üst, ön kollar bandajla sarılı.", "stats": {"melee": 0.08, "def": 1}, "look": {"top_style": "kolsuz", "arm_wraps": true}, "c1": Color(0.2, 0.38, 0.22), "c2": Color(0.12, 0.12, 0.14)},
	"kimono_ust": {"name": "Kimono Üstü ve Obi", "slot": "govde", "price": 300, "rank": 0, "desc": "Çapraz yakalı, geniş kollu üst; belde obi kuşağı.", "stats": {"chakra": 25}, "look": {"top_style": "kimono"}, "c1": Color(0.3, 0.32, 0.5), "c2": Color(0.75, 0.2, 0.25)},
	# --- alt
	"ninja_pant": {"name": "Ninja Pantolonu", "slot": "bacak", "price": 100, "rank": 0, "desc": "Baldırdan sargılı, hareket kısıtlamaz.", "stats": {"def": 2}, "look": {"pants_style": "ninja"}, "c1": Color(0.15, 0.2, 0.33)},
	"sort": {"name": "Diz Altı Şort", "slot": "bacak", "price": 80, "rank": 0, "desc": "Hafif. Koşu hızı biraz artar.", "stats": {"speed": 0.04}, "look": {"pants_style": "sort"}, "c1": Color(0.15, 0.15, 0.17)},
	"sivil_pant": {"name": "Uzun Pantolon", "slot": "bacak", "price": 40, "rank": 0, "desc": "Sivil kıyafeti.", "stats": {}, "look": {"pants_style": "sivil"}, "c1": Color(0.35, 0.3, 0.28)},
	"sargili_pant": {"name": "Sargılı Pantolon", "slot": "bacak", "price": 160, "rank": 0, "desc": "Dizden aşağısı sıkıca sarılı. Tekmeler daha keskin.", "stats": {"melee": 0.05, "speed": 0.02}, "look": {"pants_style": "sargi"}, "c1": Color(0.12, 0.12, 0.14)},
	"hakama": {"name": "Hakama", "slot": "bacak", "price": 340, "rank": 1, "desc": "Bol, pilili geniş paçalı pantolon. Kılıç ustalarının giysisi.", "stats": {"def": 3, "chakra": 10}, "look": {"pants_style": "sivil", "hakama": true}, "c1": Color(0.18, 0.18, 0.24)},
	# --- ayak
	"sandalet": {"name": "Ninja Sandaleti", "slot": "ayak", "price": 60, "rank": 0, "desc": "Açık burunlu shinobi sandaleti ve baldır sargıları.", "stats": {"speed": 0.03}, "look": {"foot_style": "sandal"}, "c1": Color(0.15, 0.2, 0.32), "c2": Color(0.92, 0.92, 0.9)},
	"takviyeli_sandalet": {"name": "Takviyeli Sandalet", "slot": "ayak", "price": 260, "rank": 1, "desc": "Metal tabanlı, tekmeler daha sert.", "stats": {"def": 2, "melee": 0.06}, "look": {"foot_style": "sandal"}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.92, 0.92, 0.9)},
	"tabi": {"name": "Tabi Ayakkabı", "slot": "ayak", "price": 180, "rank": 0, "desc": "Ayağı tamamen saran sessiz ninja ayakkabısı.", "stats": {"speed": 0.05}, "look": {"foot_style": "tabi"}, "c1": Color(0.12, 0.12, 0.15), "c2": Color(0.92, 0.92, 0.9)},
	"zori": {"name": "Hasır Zori", "slot": "ayak", "price": 30, "rank": 0, "desc": "Parmak arası hasır terlik. Sivil işi.", "stats": {}, "look": {"foot_style": "zori"}, "c1": Color(0.78, 0.68, 0.45), "c2": Color(0.92, 0.92, 0.9)},
	# --- yelek / zırh
	"chunin_yelek": {"name": "Konoha Taktik Yeleği", "slot": "zirh", "price": 0, "rank": 2, "desc": "Chunin ve Jonin'lerin parşömen cepli yeleği.", "stats": {"def": 10, "hp": 20}, "look": {"vest_style": 0}, "c1": Color(0.38, 0.48, 0.28)},
	"suna_yelek": {"name": "Kum Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Bej yelek, omuzdan çapraz kayış.", "stats": {"def": 9, "speed": 0.03}, "look": {"vest_style": 1}, "c1": Color(0.72, 0.62, 0.45)},
	"kiri_yelek": {"name": "Sis Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Yatay dikişli, sudan etkilenmeyen yelek.", "stats": {"def": 9, "chakra": 20}, "look": {"vest_style": 2}, "c1": Color(0.45, 0.52, 0.46)},
	"kumo_yelek": {"name": "Bulut Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Tek omuz askılı hafif yelek.", "stats": {"def": 8, "melee": 0.06}, "look": {"vest_style": 3}, "c1": Color(0.85, 0.85, 0.82)},
	"iwa_yelek": {"name": "Kaya Köyü Yeleği", "slot": "zirh", "price": 850, "rank": 2, "desc": "Kırmızı yelek, tek kolu zırhlı.", "stats": {"def": 12, "speed": -0.02}, "look": {"vest_style": 4}, "c1": Color(0.62, 0.18, 0.15)},
	"anbu_zirh": {"name": "ANBU Zırhı", "slot": "zirh", "price": 0, "rank": 4, "desc": "Hafif metal göğüs plakası ve omuz koruması.", "stats": {"def": 14, "speed": 0.03}, "look": {"vest_style": 5}, "c1": Color(0.75, 0.75, 0.78)},
	"samuray_zirh": {"name": "Hafif Samuray Zırhı", "slot": "zirh", "price": 1400, "rank": 3, "desc": "Lamel plakalı göğüslük ve omuzluklar. Ağır ama sağlam.", "stats": {"def": 18, "hp": 40, "speed": -0.05}, "look": {"vest_style": 6}, "c1": Color(0.35, 0.2, 0.18)},
	"deri_yelek": {"name": "Deri Yelek", "slot": "zirh", "price": 350, "rank": 1, "desc": "Paralı askerlerin sevdiği kalın yelek.", "stats": {"def": 6}, "look": {"vest_style": 0}, "c1": Color(0.4, 0.3, 0.2)},
	# --- dış giysi
	"kage_cubbesi": {"name": "Kage Cübbesi", "slot": "dis", "price": 0, "rank": 6, "desc": "Köyün liderinin beyaz cübbesi; eteğinde köyün rengi ve Kage yazısı.", "stats": {"def": 10, "chakra": 60, "hp": 40}, "look": {"outer_style": "palto"}, "c1": Color(0.96, 0.95, 0.92)},
	"kage_sapkasi": {"name": "Kage Şapkası", "slot": "kafa", "price": 0, "rank": 6, "desc": "Geniş kenarlı tören şapkası. Önünde köyün kanjisi.", "stats": {"def": 4, "chakra": 30}, "look": {"head_style": "kage"}, "c1": Color(0.95, 0.94, 0.9)},
	"jonin_komutan_paltosu": {"name": "Jōnin Komutanı Haorisi", "slot": "dis", "price": 0, "rank": 3, "desc": "Jōnin komutanlarına verilen yeşil-gri haori.", "stats": {"def": 6, "chakra": 25}, "look": {"outer_style": "haori"}, "c1": Color(0.3, 0.38, 0.3)},
	"kok_maskesi": {"name": "Kök Birliği Maskesi", "slot": "yuz", "price": 0, "rank": 4, "desc": "Kök (Ne) biriminin ifadesiz beyaz maskesi. Varlığı resmî kayıtlarda yok.", "stats": {"def": 6, "speed": 0.04}, "look": {"face_style": "anbu_kus"}, "c1": Color(0.88, 0.88, 0.86)},
	"seyahat_pelerini": {"name": "Seyahat Pelerini", "slot": "dis", "price": 280, "rank": 0, "desc": "Dizlere inen kalın yolcu pelerini.", "stats": {"def": 3, "hp": 15}, "look": {"outer_style": "pelerin"}, "c1": Color(0.4, 0.32, 0.24)},
	"kisa_pelerin": {"name": "Kısa Pelerin ve Atkı", "slot": "dis", "price": 220, "rank": 0, "desc": "Omuzdan sırta inen pelerin, boyunda kalın atkı.", "stats": {"def": 2, "speed": 0.02}, "look": {"outer_style": "kisa"}, "c1": Color(0.6, 0.15, 0.15)},
	"uzun_palto": {"name": "Komutan Paltosu", "slot": "dis", "price": 1100, "rank": 3, "desc": "Önü açık, eteği dalgalanan uzun palto.", "stats": {"def": 6, "chakra": 30}, "look": {"outer_style": "palto"}, "c1": Color(0.9, 0.9, 0.88)},
	"haori": {"name": "Haori", "slot": "dis", "price": 420, "rank": 1, "desc": "Kalçaya inen geniş kollu üst ceket.", "stats": {"chakra": 20, "def": 2}, "look": {"outer_style": "haori"}, "c1": Color(0.15, 0.15, 0.2)},
	"atki": {"name": "Uzun Atkı", "slot": "dis", "price": 70, "rank": 0, "desc": "Boyna sarılan, ucu sırtta uçuşan atkı.", "stats": {"speed": 0.01}, "look": {"outer_style": "atki"}, "c1": Color(0.75, 0.2, 0.25)},
	# --- kol / koruma
	"kolluk": {"name": "Metal Kolluk", "slot": "kol", "price": 200, "rank": 0, "desc": "Ön kolu saran metal plakalı koruyucu. Bloklar daha sağlam.", "stats": {"def": 4}, "look": {"guards": "kol"}, "c1": Color(0.55, 0.58, 0.62)},
	"eldiven": {"name": "Parmaksız Eldiven", "slot": "kol", "price": 90, "rank": 0, "desc": "Elin üstünde metal plaka, parmaklar açık.", "stats": {"melee": 0.05}, "look": {"gloves": true}, "c1": Color(0.12, 0.12, 0.14)},
	"kol_sargisi": {"name": "Kol Sargısı", "slot": "kol", "price": 30, "rank": 0, "desc": "Ön kolları saran bandaj.", "stats": {"melee": 0.03}, "look": {"arm_wraps": true}, "c1": Color(0.92, 0.92, 0.9)},
	"bacak_koruma": {"name": "Kaval Koruyucu", "slot": "kol", "price": 180, "rank": 0, "desc": "Kaval kemiğini saran metal plaka.", "stats": {"def": 3, "melee": 0.03}, "look": {"guards": "bacak"}, "c1": Color(0.55, 0.58, 0.62)},
	"tam_koruma": {"name": "Tam Takım Koruyucu", "slot": "kol", "price": 520, "rank": 1, "desc": "Kolluk, eldiven ve kaval koruyucu bir arada.", "stats": {"def": 8, "melee": 0.05, "speed": -0.02}, "look": {"guards": "ikisi", "gloves": true}, "c1": Color(0.45, 0.47, 0.52)},
	# --- sırt / bel
	"kum_kabagi": {"name": "Kum Su Kabağı", "slot": "sirt", "price": 900, "rank": 2, "desc": "Sırtta taşınan dev kabak. Sabaku klanı kumunu içinde saklar.", "stats": {"def": 4, "chakra": 25}, "look": {"back_item": "kabak"}, "c1": Color(0.7, 0.5, 0.35)},
	"sake_kabagi": {"name": "Sake Kabağı", "slot": "sirt", "price": 60, "rank": 0, "desc": "Belde taşınan küçük kabak matara.", "stats": {"hp": 10}, "look": {"back_item": "sake"}, "c1": Color(0.75, 0.5, 0.25)},
	"dev_parsomen": {"name": "Dev Parşömen", "slot": "sirt", "price": 300, "rank": 1, "desc": "Sırtta taşınan çağırma parşömeni. Chakra deposu.", "stats": {"chakra": 35}, "look": {"back_item": "parsomen"}, "c1": Color(0.85, 0.78, 0.6)},
	"sirt_shuriken": {"name": "Sırt Shurikeni", "slot": "sirt", "price": 350, "rank": 1, "desc": "Sırtta taşınan dev katlanır shuriken.", "stats": {"melee": 0.05, "def": 1}, "look": {"back_item": "shuriken"}, "c1": Color(0.45, 0.48, 0.52)},
	"kilic_kini": {"name": "Sırt Kılıç Kını", "slot": "sirt", "price": 120, "rank": 0, "desc": "Çapraz takılan kılıç kını.", "stats": {"melee": 0.03}, "look": {"back_item": "kin"}, "c1": Color(0.15, 0.12, 0.12)},
	"sirt_cantasi": {"name": "Sırt Çantası", "slot": "sirt", "price": 100, "rank": 0, "desc": "Uzun görevler için erzak çantası ve rulo yatak.", "stats": {"hp": 20}, "look": {"back_item": "canta"}, "c1": Color(0.4, 0.33, 0.22)},
	"aletli_kemer": {"name": "Alet Kemeri", "slot": "sirt", "price": 150, "rank": 0, "desc": "Belde dört alet cebi ve parşömen tutucu.", "stats": {"def": 1, "chakra": 10}, "look": {"back_item": "kemer"}, "c1": Color(0.3, 0.24, 0.16)},
	# ================================================================ genişletilmiş gardırop
	# --- kafa
	"hachimaki": {"name": "Hachimaki", "slot": "kafa", "price": 60, "rank": 0, "desc": "Alına sıkıca bağlanan, uçları ensede uçuşan kararlılık bandı.", "stats": {"melee": 0.03}, "look": {"head_style": "hachimaki"}, "c1": Color(0.95, 0.94, 0.9)},
	"hachimaki_kizil": {"name": "Kızıl Hachimaki", "slot": "kafa", "price": 90, "rank": 0, "desc": "Savaş yemini edenlerin kırmızı alın bandı.", "stats": {"melee": 0.04}, "look": {"head_style": "hachimaki"}, "c1": Color(0.78, 0.12, 0.12)},
	"haydut_bandana": {"name": "Haydut Bandanası", "slot": "kafa", "price": 50, "rank": 0, "desc": "Başa bağlanan, arkası düğümlü kaba bez.", "stats": {"def": 1, "speed": 0.01}, "look": {"head_style": "basortu"}, "c1": Color(0.55, 0.2, 0.15)},
	"col_sarigi": {"name": "Çöl Sarığı", "slot": "kafa", "price": 180, "rank": 0, "desc": "Kat kat sarılmış kum rengi sarık. Güneşten ve kum fırtınasından korur.", "stats": {"def": 2, "hp": 15}, "look": {"head_style": "sarik"}, "c1": Color(0.85, 0.76, 0.58)},
	"jingasa": {"name": "Jingasa", "slot": "kafa", "price": 240, "rank": 1, "desc": "Lake kaplı yassı asker şapkası; önünde pirinç arma.", "stats": {"def": 4}, "look": {"head_style": "jingasa"}, "c1": Color(0.16, 0.14, 0.14)},
	"kabuto": {"name": "Samuray Kabutosu", "slot": "kafa", "price": 1300, "rank": 3, "desc": "Katmanlı boyun korumalı, altın boynuz armalı savaş miğferi.", "stats": {"def": 10, "hp": 30, "speed": -0.03}, "look": {"head_style": "kabuto"}, "c1": Color(0.22, 0.2, 0.22)},
	"kabuto_kizil": {"name": "Kızıl Lake Kabuto", "slot": "kafa", "price": 1600, "rank": 3, "desc": "Komutanların kırmızı lake miğferi.", "stats": {"def": 11, "hp": 35, "speed": -0.03}, "look": {"head_style": "kabuto"}, "c1": Color(0.55, 0.1, 0.1)},
	"tengai": {"name": "Tengai", "slot": "kafa", "price": 220, "rank": 0, "desc": "Yüzü tamamen örten derin hasır sepet şapka. Gezgin keşişlerin kimliği gizlidir.", "stats": {"def": 2, "chakra": 25}, "look": {"head_style": "tengai"}, "c1": Color(0.72, 0.6, 0.38)},
	"golge_kapuson": {"name": "Gölge Kapüşonu", "slot": "kafa", "price": 380, "rank": 1, "desc": "Koyu, derin kapüşon. Suikastçıların sevdiği.", "stats": {"def": 2, "speed": 0.04}, "look": {"head_style": "kapuson"}, "c1": Color(0.1, 0.1, 0.12)},
	"col_kapusonu": {"name": "Çöl Kapüşonu", "slot": "kafa", "price": 160, "rank": 0, "desc": "Kum rengi hafif kapüşon.", "stats": {"def": 2, "hp": 10}, "look": {"head_style": "kapuson"}, "c1": Color(0.78, 0.68, 0.5)},
	"yirtik_kasa": {"name": "Yırtık Gezgin Kasası", "slot": "kafa", "price": 70, "rank": 0, "desc": "Kenarları yıpranmış eski hasır şapka. Ronin işi.", "stats": {"def": 1}, "look": {"head_style": "kasa"}, "c1": Color(0.48, 0.4, 0.28)},
	"cizik_alin": {"name": "Çizik Alın Koruyucu", "slot": "kafa", "price": 0, "rank": 1, "desc": "Köyüne sırt çevirenlerin sembolü üstünden çizilmiş plakası.", "stats": {"def": 2, "melee": 0.04}, "look": {"band_style": "slashed"}, "c1": Color(0.2, 0.2, 0.24)},
	# --- yüz
	"mempo": {"name": "Mempo", "slot": "yuz", "price": 700, "rank": 2, "desc": "Samurayların dişli, bıyıklı demir alt yüz zırhı.", "stats": {"def": 5, "hp": 20}, "look": {"face_style": "mempo"}, "c1": Color(0.2, 0.18, 0.2)},
	"mempo_kizil": {"name": "Kızıl Mempo", "slot": "yuz", "price": 900, "rank": 3, "desc": "Kırmızı lake, korkutucu yüz zırhı.", "stats": {"def": 6, "melee": 0.04}, "look": {"face_style": "mempo"}, "c1": Color(0.6, 0.1, 0.1)},
	"goz_bandi": {"name": "Göz Bandı", "slot": "yuz", "price": 40, "rank": 0, "desc": "Eski bir yaradan kalan siyah göz bandı.", "stats": {"melee": 0.02}, "look": {"face_style": "goz_bandi"}, "c1": Color(0.1, 0.1, 0.1)},
	"col_pecesi": {"name": "Çöl Peçesi", "slot": "yuz", "price": 110, "rank": 0, "desc": "Burun ve ağzı örten ince kumaş. Kum ve zehre karşı.", "stats": {"def": 1, "hp": 10}, "look": {"face_style": "pece"}, "c1": Color(0.82, 0.74, 0.58)},
	"kizil_maske": {"name": "Kızıl Bez Maske", "slot": "yuz", "price": 120, "rank": 0, "desc": "Yüzün alt yarısını saran kırmızı bez.", "stats": {"def": 1, "speed": 0.02}, "look": {"face_style": "cloth"}, "c1": Color(0.55, 0.1, 0.12)},
	"anbu_tilki": {"name": "ANBU Maskesi: Tilki", "slot": "yuz", "price": 900, "rank": 4, "desc": "Sivri burunlu tilki maskesi: kurnazlık.", "stats": {"def": 5, "chakra": 30}, "look": {"face_style": "anbu_tilki"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_kaplan": {"name": "ANBU Maskesi: Kaplan", "slot": "yuz", "price": 900, "rank": 4, "desc": "Çizgili kaplan maskesi: saldırganlık.", "stats": {"def": 5, "melee": 0.08}, "look": {"face_style": "anbu_kaplan"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_yilan": {"name": "ANBU Maskesi: Yılan", "slot": "yuz", "price": 900, "rank": 4, "desc": "Ortasından yeşil çizgi inen yılan maskesi: sinsilik.", "stats": {"def": 4, "speed": 0.06}, "look": {"face_style": "anbu_yilan"}, "c1": Color(0.95, 0.95, 0.95)},
	"anbu_maymun": {"name": "ANBU Maskesi: Maymun", "slot": "yuz", "price": 900, "rank": 4, "desc": "Kulaklı maymun maskesi: çeviklik.", "stats": {"def": 4, "speed": 0.05, "melee": 0.03}, "look": {"face_style": "anbu_maymun"}, "c1": Color(0.95, 0.95, 0.95)},
	# --- üst
	"gi_beyaz": {"name": "Beyaz Dövüş Gi'si", "slot": "govde", "price": 160, "rank": 0, "desc": "Geniş V yakalı, dirsek boyu kollu taijutsu gi'si; siyah kuşaklı.", "stats": {"melee": 0.06}, "look": {"top_style": "gi"}, "c1": Color(0.94, 0.93, 0.9), "c2": Color(0.85, 0.84, 0.8)},
	"gi_siyah": {"name": "Siyah Dövüş Gi'si", "slot": "govde", "price": 200, "rank": 0, "desc": "Gece antrenmanlarının koyu gi'si.", "stats": {"melee": 0.07}, "look": {"top_style": "gi"}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.55, 0.1, 0.1)},
	"kesis_ustu": {"name": "Keşiş Üstü", "slot": "govde", "price": 140, "rank": 0, "desc": "Safran rengi, çapraz yakalı tapınak giysisi.", "stats": {"chakra": 25}, "look": {"top_style": "gi"}, "c1": Color(0.9, 0.55, 0.15), "c2": Color(0.7, 0.35, 0.1)},
	"arma_gomlek": {"name": "Armalı Yüksek Yakalı Gömlek", "slot": "govde", "price": 340, "rank": 1, "desc": "Uzun kollu, dik yakalı klan gömleği; sırtında yuvarlak klan arması.", "stats": {"def": 3, "chakra": 20}, "look": {"top_style": "yakali_uzun", "top_pattern": 5}, "c1": Color(0.12, 0.13, 0.2), "c2": Color(0.85, 0.15, 0.15)},
	"beyaz_arma": {"name": "Beyaz Klan Cübbe-Gömleği", "slot": "govde", "price": 360, "rank": 1, "desc": "Soluk lila-beyaz, kenarları biyeli soylu klan üstü.", "stats": {"def": 2, "chakra": 30}, "look": {"top_style": "yakali_uzun", "top_pattern": 6}, "c1": Color(0.92, 0.9, 0.95), "c2": Color(0.55, 0.5, 0.7)},
	"cizgili_tisort": {"name": "Çizgili Tişört", "slot": "govde", "price": 60, "rank": 0, "desc": "Enine çizgili rahat tişört.", "stats": {"speed": 0.03}, "look": {"top_style": "tisort", "top_pattern": 2}, "c1": Color(0.85, 0.85, 0.82), "c2": Color(0.2, 0.3, 0.55)},
	"denizci_ust": {"name": "Çizgili Uzun Kollu", "slot": "govde", "price": 110, "rank": 0, "desc": "Liman köylerinin çizgili gömleği.", "stats": {"def": 1, "hp": 10}, "look": {"top_style": "uzun", "top_pattern": 2}, "c1": Color(0.9, 0.9, 0.88), "c2": Color(0.15, 0.25, 0.45)},
	"panel_ceket": {"name": "Yan Panelli Eğitim Ceketi", "slot": "govde", "price": 260, "rank": 0, "desc": "Yanlarından ve kollarından şerit geçen fermuarlı ceket.", "stats": {"def": 3, "speed": 0.03}, "look": {"top_style": "ceket", "top_pattern": 3}, "c1": Color(0.2, 0.35, 0.6), "c2": Color(0.95, 0.75, 0.2)},
	"kizil_ceket": {"name": "Kızıl Dövüş Ceketi", "slot": "govde", "price": 260, "rank": 0, "desc": "Kırmızı gövde, siyah omuzlu yüksek yakalı ceket.", "stats": {"def": 3, "melee": 0.04}, "look": {"top_style": "ceket", "top_pattern": 3}, "c1": Color(0.7, 0.12, 0.12), "c2": Color(0.1, 0.1, 0.12)},
	"atlet": {"name": "Atlet", "slot": "govde", "price": 30, "rank": 0, "desc": "Askılı, kolları ve omuzları açık atlet.", "stats": {"speed": 0.04}, "look": {"top_style": "atlet"}, "c1": Color(0.9, 0.9, 0.88), "c2": Color(0.9, 0.9, 0.88)},
	"tek_kol_ust": {"name": "Tek Kollu Savaş Üstü", "slot": "govde", "price": 230, "rank": 1, "desc": "Bir kolu açık, asimetrik kesim. Bulut köyü tarzı.", "stats": {"melee": 0.06, "speed": 0.02}, "look": {"top_style": "tek_kol"}, "c1": Color(0.22, 0.24, 0.28), "c2": Color(0.22, 0.24, 0.28)},
	"yamali_gomlek": {"name": "Yamalı Gömlek", "slot": "govde", "price": 20, "rank": 0, "desc": "Yamalarla tutturulmuş, eskimiş gömlek.", "stats": {"hp": 5}, "look": {"top_style": "uzun", "top_pattern": 4}, "c1": Color(0.48, 0.38, 0.28), "c2": Color(0.48, 0.38, 0.28)},
	"yamali_kolsuz": {"name": "Yırtık Kolsuz Üst", "slot": "govde", "price": 20, "rank": 0, "desc": "Kolları kopmuş, yamalı kaba üst.", "stats": {"melee": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 4}, "c1": Color(0.4, 0.34, 0.26), "c2": Color(0.4, 0.34, 0.26)},
	"file_kolsuz": {"name": "File Kolsuz", "slot": "govde", "price": 140, "rank": 0, "desc": "Ağ örgü kolsuz fanila.", "stats": {"def": 2, "speed": 0.03}, "look": {"top_style": "kolsuz", "top_pattern": 1}, "c1": Color(0.15, 0.15, 0.17), "c2": Color(0.15, 0.15, 0.17)},
	"biyeli_kimono": {"name": "Biyeli Kimono", "slot": "govde", "price": 420, "rank": 1, "desc": "Etek ve kol ağızları kontrast biyeli soylu kimono.", "stats": {"chakra": 35}, "look": {"top_style": "kimono", "top_pattern": 6}, "c1": Color(0.2, 0.22, 0.35), "c2": Color(0.85, 0.75, 0.45)},
	"yukata": {"name": "Çizgili Yukata", "slot": "govde", "price": 160, "rank": 0, "desc": "Hafif yazlık kimono. Festival akşamları için.", "stats": {"hp": 10}, "look": {"top_style": "kimono", "top_pattern": 2}, "c1": Color(0.9, 0.88, 0.82), "c2": Color(0.25, 0.35, 0.6)},
	"tunik": {"name": "Biyeli Tunik", "slot": "govde", "price": 150, "rank": 0, "desc": "Uzun kollu, kenarları biyeli gezgin tuniği.", "stats": {"def": 1, "chakra": 10}, "look": {"top_style": "uzun", "top_pattern": 6}, "c1": Color(0.45, 0.32, 0.22), "c2": Color(0.75, 0.6, 0.35)},
	"deri_ceket": {"name": "Deri Ceket", "slot": "govde", "price": 280, "rank": 1, "desc": "Kalın deri, yüksek yakalı paralı asker ceketi.", "stats": {"def": 5, "speed": -0.01}, "look": {"top_style": "ceket"}, "c1": Color(0.38, 0.25, 0.15), "c2": Color(0.22, 0.15, 0.1)},
	"golge_ust": {"name": "Gölge Ninja Üstü", "slot": "govde", "price": 320, "rank": 2, "desc": "Uzun kollu, yüksek yakalı simsiyah üst. Gece görevleri için.", "stats": {"def": 2, "speed": 0.05}, "look": {"top_style": "yakali_uzun"}, "c1": Color(0.08, 0.08, 0.1), "c2": Color(0.08, 0.08, 0.1)},
	# --- alt
	"bol_pantolon": {"name": "Bol Paçalı Pantolon", "slot": "bacak", "price": 120, "rank": 0, "desc": "Baldırda balon gibi kabaran, bilekte toplanan pantolon.", "stats": {"def": 2, "speed": 0.02}, "look": {"pants_style": "bol"}, "c1": Color(0.25, 0.28, 0.35)},
	"col_salvari": {"name": "Çöl Şalvarı", "slot": "bacak", "price": 140, "rank": 0, "desc": "Kum rengi bol şalvar. Sıcakta serin tutar.", "stats": {"hp": 15}, "look": {"pants_style": "bol"}, "c1": Color(0.8, 0.7, 0.5)},
	"kapri": {"name": "Kapri", "slot": "bacak", "price": 70, "rank": 0, "desc": "Baldır ortasında biten hafif pantolon.", "stats": {"speed": 0.03}, "look": {"pants_style": "kapri"}, "c1": Color(0.3, 0.3, 0.33)},
	"kisa_sort": {"name": "Kısa Şort", "slot": "bacak", "price": 50, "rank": 0, "desc": "Diz üstü şort. Bacaklar serbest.", "stats": {"speed": 0.05}, "look": {"pants_style": "kisa_sort"}, "c1": Color(0.18, 0.18, 0.2)},
	"yamali_pant": {"name": "Yamalı Pantolon", "slot": "bacak", "price": 15, "rank": 0, "desc": "Dizleri yamalı, eskimiş pantolon.", "stats": {}, "look": {"pants_style": "sivil"}, "c1": Color(0.38, 0.32, 0.25)},
	"kizil_hakama": {"name": "Kızıl Hakama", "slot": "bacak", "price": 380, "rank": 1, "desc": "Tapınak muhafızlarının kırmızı hakaması.", "stats": {"def": 3, "chakra": 15}, "look": {"pants_style": "sivil", "hakama": true}, "c1": Color(0.65, 0.12, 0.12)},
	"siyah_pant": {"name": "Siyah Taktik Pantolon", "slot": "bacak", "price": 180, "rank": 1, "desc": "Baldırdan sargılı koyu pantolon.", "stats": {"def": 2, "speed": 0.03}, "look": {"pants_style": "ninja"}, "c1": Color(0.1, 0.1, 0.12)},
	# --- ayak
	"deri_cizme": {"name": "Deri Çizme", "slot": "ayak", "price": 220, "rank": 0, "desc": "Baldıra kadar çıkan kalın çizme.", "stats": {"def": 3}, "look": {"foot_style": "cizme"}, "c1": Color(0.28, 0.2, 0.14), "c2": Color(0.28, 0.2, 0.14)},
	"zirhli_cizme": {"name": "Zırhlı Çizme", "slot": "ayak", "price": 520, "rank": 2, "desc": "Metal plakalı ağır çizme.", "stats": {"def": 6, "speed": -0.02}, "look": {"foot_style": "cizme"}, "c1": Color(0.35, 0.36, 0.4), "c2": Color(0.35, 0.36, 0.4)},
	"yuksek_sandal": {"name": "Dize Sargılı Sandalet", "slot": "ayak", "price": 140, "rank": 0, "desc": "Bacağı dize kadar saran bandajlı sandalet.", "stats": {"speed": 0.04, "melee": 0.02}, "look": {"foot_style": "yuksek_sandal"}, "c1": Color(0.12, 0.12, 0.14), "c2": Color(0.92, 0.92, 0.9)},
	"siyah_tabi": {"name": "Siyah Tabi", "slot": "ayak", "price": 220, "rank": 1, "desc": "Sessiz adım için koyu tabi.", "stats": {"speed": 0.06}, "look": {"foot_style": "tabi"}, "c1": Color(0.06, 0.06, 0.08), "c2": Color(0.92, 0.92, 0.9)},
	# --- yelek / zırh
	"kok_yelek": {"name": "Kök Birliği Yeleği", "slot": "zirh", "price": 0, "rank": 4, "desc": "Dikey dikişli simsiyah gizli birlik yeleği.", "stats": {"def": 11, "speed": 0.04}, "look": {"vest_style": 7}, "c1": Color(0.1, 0.1, 0.12)},
	"zincir_yelek": {"name": "Zincir Örgü Yelek", "slot": "zirh", "price": 600, "rank": 1, "desc": "Halka halka örülmüş metal yelek.", "stats": {"def": 9, "speed": -0.02}, "look": {"vest_style": 8}, "c1": Color(0.55, 0.57, 0.6)},
	"kayis_kosum": {"name": "Kayış Koşum", "slot": "zirh", "price": 90, "rank": 0, "desc": "Göğüste çapraz deri kayışlar ve bel kemeri.", "stats": {"def": 2, "melee": 0.03}, "look": {"vest_style": 9}, "c1": Color(0.35, 0.24, 0.15)},
	"deri_pul_zirh": {"name": "Deri Pullu Zırh", "slot": "zirh", "price": 720, "rank": 2, "desc": "Sıra sıra deri pullarla kaplı hafif zırh.", "stats": {"def": 11, "hp": 20, "speed": -0.02}, "look": {"vest_style": 10}, "c1": Color(0.42, 0.28, 0.18)},
	"gogus_plakasi": {"name": "Göğüs Plakası", "slot": "zirh", "price": 480, "rank": 1, "desc": "Yalnızca göğsü saran hafif metal plaka.", "stats": {"def": 7, "speed": 0.01}, "look": {"vest_style": 11}, "c1": Color(0.6, 0.62, 0.66)},
	"lake_zirh": {"name": "Kızıl Lake Zırh", "slot": "zirh", "price": 1800, "rank": 3, "desc": "Kırmızı lakeli lamel zırh, omuzluklarıyla birlikte.", "stats": {"def": 20, "hp": 45, "speed": -0.05}, "look": {"vest_style": 6}, "c1": Color(0.55, 0.1, 0.1)},
	"ame_yelek": {"name": "Yağmur Köyü Yeleği", "slot": "zirh", "price": 700, "rank": 2, "desc": "Gri, nem tutmayan dikişli yelek.", "stats": {"def": 8, "chakra": 15}, "look": {"vest_style": 2}, "c1": Color(0.45, 0.48, 0.52)},
	"jonin_koyu": {"name": "Gece Taktik Yeleği", "slot": "zirh", "price": 900, "rank": 2, "desc": "Koyu zeytin rengi, parşömen cepli yelek.", "stats": {"def": 10, "speed": 0.02}, "look": {"vest_style": 0}, "c1": Color(0.2, 0.26, 0.18)},
	# --- dış giysi
	"org_pelerini": {"name": "Kızıl Hilal Pelerini", "slot": "dis", "price": 0, "rank": 3, "desc": "Bilinmeyen bir örgütün dik yakalı, kızıl hilal desenli uzun pelerini.", "stats": {"def": 8, "chakra": 40, "hp": 30}, "look": {"outer_style": "org_pelerin", "outer_pattern": 3}, "c1": Color(0.08, 0.08, 0.12), "c2": Color(0.75, 0.1, 0.12)},
	"panco": {"name": "Panço", "slot": "dis", "price": 150, "rank": 0, "desc": "Omuzlardan kalçaya inen geniş yağmurluk.", "stats": {"def": 2, "hp": 15}, "look": {"outer_style": "panco", "outer_pattern": 1}, "c1": Color(0.45, 0.35, 0.25), "c2": Color(0.7, 0.3, 0.15)},
	"yirtik_pelerin": {"name": "Yırtık Gezgin Pelerini", "slot": "dis", "price": 90, "rank": 0, "desc": "Eteği parça parça olmuş, delikli eski pelerin.", "stats": {"def": 2, "speed": 0.02}, "look": {"outer_style": "yirtik", "outer_pattern": 5}, "c1": Color(0.3, 0.27, 0.24)},
	"jinbaori": {"name": "Jinbaori", "slot": "dis", "price": 900, "rank": 2, "desc": "Samuray komutanlarının kolsuz, yandan yırtmaçlı savaş cüppesi.", "stats": {"def": 6, "hp": 30}, "look": {"outer_style": "jinbaori", "outer_pattern": 1}, "c1": Color(0.15, 0.15, 0.22), "c2": Color(0.85, 0.68, 0.25)},
	"kesis_cubbesi": {"name": "Keşiş Cübbesi", "slot": "dis", "price": 260, "rank": 0, "desc": "Ayak bileğine inen kollu tapınak cübbesi.", "stats": {"chakra": 40}, "look": {"outer_style": "cuppe", "outer_pattern": 1}, "c1": Color(0.3, 0.28, 0.35), "c2": Color(0.9, 0.55, 0.15)},
	"kesa": {"name": "Kesa", "slot": "dis", "price": 120, "rank": 0, "desc": "Tek omuzdan çapraz inen keşiş örtüsü.", "stats": {"chakra": 25}, "look": {"outer_style": "kesa"}, "c1": Color(0.62, 0.18, 0.1)},
	"sennin_haorisi": {"name": "Alev Etekli Uzun Haori", "slot": "dis", "price": 1400, "rank": 3, "desc": "Dize inen, eteği alev desenli uzun haori.", "stats": {"chakra": 45, "def": 4}, "look": {"outer_style": "haori_uzun", "outer_pattern": 2}, "c1": Color(0.9, 0.88, 0.84), "c2": Color(0.8, 0.15, 0.1)},
	"bantli_palto": {"name": "Bantlı Komutan Paltosu", "slot": "dis", "price": 1200, "rank": 3, "desc": "Eteği renkli bantla biten uzun palto.", "stats": {"def": 6, "chakra": 35}, "look": {"outer_style": "palto", "outer_pattern": 1}, "c1": Color(0.2, 0.22, 0.28), "c2": Color(0.85, 0.65, 0.2)},
	"mino": {"name": "Hasır Yağmurluk (Mino)", "slot": "dis", "price": 80, "rank": 0, "desc": "Saman liflerinden örülmüş kaba yağmurluk. Köylü ve gezgin işi.", "stats": {"def": 2, "hp": 20}, "look": {"outer_style": "mino", "outer_pattern": 4}, "c1": Color(0.68, 0.58, 0.36)},
	"gece_pelerini": {"name": "Gece Pelerini", "slot": "dis", "price": 520, "rank": 2, "desc": "Bileğe inen kapalı, koyu pelerin.", "stats": {"def": 4, "speed": 0.03}, "look": {"outer_style": "org_pelerin", "outer_pattern": 1}, "c1": Color(0.1, 0.1, 0.12), "c2": Color(0.25, 0.25, 0.3)},
	# --- kol / koruma
	"omuz_zirhi": {"name": "Omuz Zırhı", "slot": "kol", "price": 300, "rank": 1, "desc": "Tek omuza takılan katmanlı plaka ve göğüs kayışı.", "stats": {"def": 5}, "look": {"guards": "omuz"}, "c1": Color(0.5, 0.52, 0.56)},
	"dizlik": {"name": "Dizlik", "slot": "kol", "price": 120, "rank": 0, "desc": "Dizleri koruyan sert ped.", "stats": {"def": 3, "melee": 0.02}, "look": {"guards": "dizlik"}, "c1": Color(0.3, 0.3, 0.32)},
	"agir_zirh": {"name": "Ağır Zırh Takımı", "slot": "kol", "price": 950, "rank": 2, "desc": "İki omuzluk ve dizlikler. Darbeleri sırtında taşırsın.", "stats": {"def": 10, "hp": 30, "speed": -0.04}, "look": {"guards": "agir", "gloves": true}, "c1": Color(0.4, 0.42, 0.46)},
	"uzun_sargi_eldiven": {"name": "Sargılı Eldiven", "slot": "kol", "price": 110, "rank": 0, "desc": "Parmaksız eldiven ve ön kol sargısı bir arada.", "stats": {"melee": 0.06}, "look": {"gloves": true, "arm_wraps": true}, "c1": Color(0.15, 0.15, 0.17)},
	# --- sırt / bel
	"tespih": {"name": "Dev Tespih", "slot": "sirt", "price": 200, "rank": 0, "desc": "Boyuna asılan iri ahşap tespih.", "stats": {"chakra": 30}, "look": {"back_item": "tespih"}, "c1": Color(0.35, 0.22, 0.12)},
	"sirt_sepeti": {"name": "Sırt Sepeti", "slot": "sirt", "price": 60, "rank": 0, "desc": "Tüccar ve gezginlerin hasır sırt sepeti.", "stats": {"hp": 25}, "look": {"back_item": "sepet"}, "c1": Color(0.7, 0.58, 0.35)},
	"bel_parsomenleri": {"name": "Bel Parşömenleri", "slot": "sirt", "price": 260, "rank": 1, "desc": "Kalçanın iki yanında taşınan çağırma parşömenleri.", "stats": {"chakra": 25}, "look": {"back_item": "bel_parsomen"}, "c1": Color(0.88, 0.82, 0.65)},
	"bel_cantasi": {"name": "Bel Çantası Takımı", "slot": "sirt", "price": 130, "rank": 0, "desc": "Yan cep, arka kese ve sarkan kunai kılıfı.", "stats": {"def": 1, "hp": 10}, "look": {"back_item": "kemer_canta"}, "c1": Color(0.3, 0.26, 0.2)},
	"sashimono": {"name": "Sashimono Bayrağı", "slot": "sirt", "price": 400, "rank": 2, "desc": "Sırta takılan samuray birlik sancağı.", "stats": {"def": 2, "hp": 20}, "look": {"back_item": "sashimono"}, "c1": Color(0.55, 0.12, 0.12)},
	"ip_kangali": {"name": "İp Kangalı", "slot": "sirt", "price": 25, "rank": 0, "desc": "Belde taşınan sağlam ip. Tırmanış ve tuzak için.", "stats": {"speed": 0.01}, "look": {"back_item": "ip_kangal"}, "c1": Color(0.7, 0.62, 0.45)},
	# --- silahlar (el = iki ele de takılabilir)
	"kunai": {"name": "Kunai", "slot": "el", "price": 30, "rank": 0, "desc": "Her ninjanın yakın dövüş bıçağı.", "stats": {}, "weapon": {"dmg": 1.15, "reach": 0.15, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"altin_kunai": {"name": "Chakra Metali Kunai", "slot": "el", "price": 600, "rank": 2, "desc": "Chakra iletebilen özel metalden kunai.", "stats": {"chakra": 15}, "weapon": {"dmg": 1.35, "reach": 0.2, "style": "blade"}, "c1": Color(0.85, 0.7, 0.3)},
	"patlayici_kunai": {"name": "Etiketli Kunai", "slot": "el", "price": 260, "rank": 1, "desc": "Sapına patlayıcı etiket sarılı kunai. Darbeler sert.", "stats": {}, "weapon": {"dmg": 1.3, "reach": 0.15, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"zincirli_kunai": {"name": "Zincirli Kunai", "slot": "el", "price": 300, "rank": 1, "desc": "Halkasına zincir bağlı kunai: menzil uzar.", "stats": {}, "weapon": {"dmg": 1.2, "reach": 0.6, "style": "blade"}, "c1": Color(0.6, 0.62, 0.66)},
	"senbon": {"name": "Senbon İğneleri", "slot": "el", "price": 120, "rank": 0, "desc": "İnce iğneler: hızlı, isabetli, düşük hasar.", "stats": {"speed": 0.02}, "weapon": {"dmg": 1.1, "reach": 0.1, "style": "dual"}, "c1": Color(0.75, 0.77, 0.8)},
	"tanto": {"name": "Tantō", "slot": "el", "price": 320, "rank": 1, "desc": "Kısa kılıç. Hızlı ve keskin.", "stats": {}, "weapon": {"dmg": 1.35, "reach": 0.35, "style": "blade"}, "c1": Color(0.75, 0.77, 0.8)},
	"ikiz_hancer": {"name": "Hançer", "slot": "el", "price": 240, "rank": 0, "desc": "Çift taşınmak için dengelenmiş kısa hançer.", "stats": {"speed": 0.02}, "weapon": {"dmg": 1.25, "reach": 0.25, "style": "dual"}, "c1": Color(0.7, 0.72, 0.76)},
	"kama": {"name": "Kama (Orak)", "slot": "el", "price": 280, "rank": 1, "desc": "Kavisli tarım orağından savaş aleti.", "stats": {}, "weapon": {"dmg": 1.35, "reach": 0.3, "style": "sickle"}, "c1": Color(0.7, 0.72, 0.76)},
	"pence": {"name": "Pençe", "slot": "el", "price": 400, "rank": 1, "desc": "Parmaklara takılan üç metal tırnak.", "stats": {"melee": 0.08}, "weapon": {"dmg": 1.25, "reach": 0.2, "style": "claw"}, "c1": Color(0.6, 0.62, 0.66)},
	"musta": {"name": "Muşta Bıçağı", "slot": "el", "price": 450, "rank": 1, "desc": "Parmak korumalı bıçak. Rüzgar chakrası akıtılabilir.", "stats": {"melee": 0.1}, "weapon": {"dmg": 1.3, "reach": 0.25, "style": "blade"}, "c1": Color(0.55, 0.57, 0.6)},
	"chakra_bicak": {"name": "Chakra Bıçakları", "slot": "el", "price": 1100, "rank": 3, "desc": "Chakra ile parlayan çift bıçak. Elementini taşır.", "stats": {"melee": 0.12, "chakra": 15}, "weapon": {"dmg": 1.55, "reach": 0.3, "style": "dual"}, "c1": Color(0.55, 0.8, 1.0)},
	"tonfa": {"name": "Tonfa", "slot": "el", "price": 220, "rank": 0, "desc": "Savunma sopası. Gelen hasarı azaltır.", "stats": {"def": 4}, "weapon": {"dmg": 1.2, "reach": 0.3, "style": "blade"}, "c1": Color(0.35, 0.25, 0.15)},
	"wakizashi": {"name": "Wakizashi", "slot": "el", "price": 520, "rank": 1, "desc": "Orta boy yan kılıç. Çift kılıç tekniğine uygun.", "stats": {}, "weapon": {"dmg": 1.45, "reach": 0.55, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"katana": {"name": "Katana", "slot": "sag", "price": 900, "rank": 2, "desc": "Uzun kılıç. Geniş kesişler, yüksek hasar.", "stats": {"speed": -0.02}, "weapon": {"dmg": 1.7, "reach": 0.9, "style": "sword"}, "c1": Color(0.78, 0.8, 0.84)},
	"nodachi": {"name": "Nodachi", "slot": "sag", "price": 1500, "rank": 3, "desc": "İnsan boyunda dev kılıç. Yavaş ama yıkıcı.", "stats": {"speed": -0.05}, "weapon": {"dmg": 2.1, "reach": 1.3, "style": "heavy"}, "c1": Color(0.75, 0.77, 0.8)},
	"savas_cekici": {"name": "Savaş Çekici", "slot": "sag", "price": 1200, "rank": 2, "desc": "Uzun saplı demir çekiç. Zırhı ezer.", "stats": {"speed": -0.06, "def": 2}, "weapon": {"dmg": 2.0, "reach": 0.9, "style": "heavy"}, "c1": Color(0.4, 0.4, 0.42)},
	"bo": {"name": "Bō Sopası", "slot": "sag", "price": 180, "rank": 0, "desc": "Uzun ahşap sopa. Geniş vuruş alanı.", "stats": {"def": 2}, "weapon": {"dmg": 1.3, "reach": 1.0, "style": "staff"}, "c1": Color(0.45, 0.32, 0.2)},
	"mizrak": {"name": "Yari Mızrağı", "slot": "sag", "price": 650, "rank": 2, "desc": "Uzun mızrak. En uzun menzil.", "stats": {}, "weapon": {"dmg": 1.55, "reach": 1.4, "style": "staff"}, "c1": Color(0.75, 0.77, 0.8)},
	"kusarigama": {"name": "Kusarigama", "slot": "sag", "price": 780, "rank": 2, "desc": "Zincirli orak: uzak ve yakın dövüş bir arada.", "stats": {"melee": 0.05}, "weapon": {"dmg": 1.5, "reach": 1.1, "style": "chain"}, "c1": Color(0.7, 0.72, 0.76)},
	"el_shuriken": {"name": "Dev Shuriken", "slot": "sag", "price": 700, "rank": 2, "desc": "Elde tutulan dev dört kollu shuriken. Kesici savuruşlar.", "stats": {}, "weapon": {"dmg": 1.6, "reach": 0.8, "style": "heavy"}, "c1": Color(0.5, 0.52, 0.56)},
	"yelpaze": {"name": "Savaş Yelpazesi", "slot": "sag", "price": 700, "rank": 2, "desc": "Büyük demir yelpaze. Fuuton jutsularını güçlendirir.", "stats": {"chakra": 30}, "weapon": {"dmg": 1.4, "reach": 0.8, "style": "fan"}, "c1": Color(0.85, 0.82, 0.75)},
	# --- gözler (goz = sağ/sol göz yuvasına takılır; satılmaz). Örnek başına "lvl" (tomoe 1-3) ve "origin" (dogustan/nakil)
	"goz_sharingan": {"name": "Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Uchiha'nın kopyalayan gözü. Hareketleri önceden okur.", "stats": {"melee": 0.05, "chakra": 10}, "eye": {"kind": 1, "name": "Sharingan"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_mangekyo": {"name": "Mangekyō Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Büyük acıyla uyanan kaleydoskop göz. Güçlü ama kör eder.", "stats": {"melee": 0.1, "chakra": 30}, "eye": {"kind": 4, "name": "Mangekyō Sharingan"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_ems": {"name": "Ebedi Mangekyō Sharingan", "slot": "goz", "price": 0, "rank": 0, "desc": "Kardeş gözüyle birleşen, ışığı sönmeyen Mangekyō.", "stats": {"melee": 0.15, "chakra": 50}, "eye": {"kind": 5, "name": "Ebedi Mangekyō"}, "c1": Color(0.8, 0.05, 0.08)},
	"goz_rinnegan": {"name": "Rinnegan", "slot": "goz", "price": 0, "rank": 0, "desc": "Halkalı efsanevi göz. Altı yolun gücü.", "stats": {"chakra": 80}, "eye": {"kind": 6, "name": "Rinnegan"}, "c1": Color(0.6, 0.5, 0.85)},
	"goz_byakugan": {"name": "Byakugan", "slot": "goz", "price": 0, "rank": 0, "desc": "Hyūga'nın her yönü gören beyaz gözü.", "stats": {"melee": 0.08, "def": 2}, "eye": {"kind": 2, "name": "Byakugan"}, "c1": Color(0.9, 0.9, 0.96)},
	"goz_ketsuryugan": {"name": "Ketsuryūgan", "slot": "goz", "price": 0, "rank": 0, "desc": "Chinoike'nin kan rengi gözü: genjutsu ve kan teknikleri.", "stats": {"chakra": 20, "melee": 0.05}, "eye": {"kind": 3, "name": "Ketsuryūgan"}, "c1": Color(0.7, 0.08, 0.1)},
	"goz_tenseigan": {"name": "Tenseigan", "slot": "goz", "price": 0, "rank": 0, "desc": "Ay ışığı gibi parlayan, çekim ve itme gücü veren göz.", "stats": {"chakra": 60, "def": 4}, "eye": {"kind": 7, "name": "Tenseigan"}, "c1": Color(0.55, 0.75, 1.0)},
	"goz_jogan": {"name": "Jōgan", "slot": "goz", "price": 0, "rank": 0, "desc": "Görünmeyeni gören gizemli göz.", "stats": {"chakra": 40, "speed": 0.04}, "eye": {"kind": 8, "name": "Jōgan"}, "c1": Color(0.45, 0.65, 1.0)},
	# --- efsanevi silahlar (satılmaz: S/A görevleri ve boss ödülü). special: vuruş yeteneği
	"kubikiribocho": {"name": "Kubikiribōchō", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Sis'in Yedi Kılıcı'ndan dev satır. Delikli ağzı kesilenin kanıyla kendini onarır: vuruşlar can çalar.", "stats": {"hp": 40, "speed": -0.06}, "weapon": {"dmg": 2.4, "reach": 1.3, "style": "heavy", "special": "lifesteal"}, "c1": Color(0.78, 0.8, 0.84)},
	"samehada": {"name": "Samehada", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Pullarla kaplı, sargılı canlı kılıç. Değdiği düşmanın chakrasını emer.", "stats": {"chakra": 60, "speed": -0.05}, "weapon": {"dmg": 2.2, "reach": 1.2, "style": "heavy", "special": "drain"}, "c1": Color(0.25, 0.32, 0.5)},
	"kiba": {"name": "Kiba (İkiz Yıldırım Kılıcı)", "slot": "el", "price": 0, "rank": 4, "legend": true, "desc": "Yedi Kılıç'tan ikiz dişli kılıçlar. Raiton taşır: sersemletir. İki ele birden kuşan.", "stats": {"speed": 0.04}, "weapon": {"dmg": 1.8, "reach": 0.8, "style": "sword", "special": "raiton"}, "c1": Color(0.95, 0.85, 0.35)},
	"hiramekarei": {"name": "Hiramekarei", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Çift saplı geniş kılıç. Chakra depolar, ağzını uzatıp devasa bir bıçağa çevirir.", "stats": {"chakra": 40}, "weapon": {"dmg": 2.1, "reach": 1.7, "style": "heavy", "special": "extend"}, "c1": Color(0.3, 0.45, 0.75)},
	"shibuki": {"name": "Shibuki", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Patlayıcı etiket parşömeniyle sarılı kılıç. Her darbe patlar.", "stats": {"def": 2}, "weapon": {"dmg": 2.0, "reach": 1.1, "style": "heavy", "special": "explode"}, "c1": Color(0.85, 0.8, 0.65)},
	"nuibari": {"name": "Nuibari", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Telli dev iğne-kılıç. Saplanır ve düşmanı sana çeker.", "stats": {"speed": 0.05}, "weapon": {"dmg": 1.7, "reach": 1.6, "style": "staff", "special": "pull"}, "c1": Color(0.8, 0.82, 0.86)},
	"kabutowari": {"name": "Kabutowari", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Zincirle bağlı balta ve çekiç. Savunmayı ve zırhı parçalar.", "stats": {"def": 4, "speed": -0.06}, "weapon": {"dmg": 2.3, "reach": 1.0, "style": "heavy", "special": "armor_break"}, "c1": Color(0.45, 0.45, 0.48)},
	"chokuto": {"name": "Kusanagi Tarzı Chokutō", "slot": "sag", "price": 0, "rank": 3, "legend": true, "desc": "Düz ağızlı efsanevi kılıç. İçinden akıtılan chakra keskinliği arttırır.", "stats": {"speed": 0.04, "melee": 0.1}, "weapon": {"dmg": 1.95, "reach": 1.0, "style": "sword", "special": "flow"}, "c1": Color(0.85, 0.87, 0.9)},
	"raijin": {"name": "Raijin Kılıcı", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Saf yıldırım chakrasından oluşan ağız. Gök gürültüsüyle keser.", "stats": {"chakra": 30}, "weapon": {"dmg": 2.0, "reach": 1.2, "style": "sword", "special": "raiton"}, "c1": Color(1.0, 0.9, 0.3)},
	"ruzgar_bicak": {"name": "Rüzgar Chakra Bıçakları", "slot": "el", "price": 0, "rank": 3, "legend": true, "desc": "Fuuton chakrası akıtılan muşta bıçakları: görünmez ağız menzili uzatır.", "stats": {"melee": 0.12}, "weapon": {"dmg": 1.75, "reach": 0.8, "style": "dual", "special": "wind"}, "c1": Color(0.55, 1.0, 0.75)},
	"fuma_shuriken": {"name": "Fūma Shuriken", "slot": "sag", "price": 0, "rank": 3, "legend": true, "desc": "Yel değirmeni gibi açılan dev dört kollu shuriken.", "stats": {"speed": 0.02}, "weapon": {"dmg": 1.9, "reach": 1.1, "style": "heavy", "special": "wind"}, "c1": Color(0.55, 0.57, 0.62)},
	"gunbai": {"name": "Gunbai Savaş Yelpazesi", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Dev yuvarlak demir yelpaze. Savuruşu fırtına gibi iter, kendisi kalkan olur.", "stats": {"def": 10, "chakra": 20}, "weapon": {"dmg": 1.8, "reach": 1.1, "style": "fan", "special": "gust"}, "c1": Color(0.75, 0.15, 0.15)},
	"uc_tirpan": {"name": "Üç Bıçaklı Tırpan", "slot": "sag", "price": 0, "rank": 4, "legend": true, "desc": "Kırmızı üç bıçaklı dev tırpan, ucunda ip. Geniş savuruşlu, ağır.", "stats": {"melee": 0.1}, "weapon": {"dmg": 2.15, "reach": 1.4, "style": "heavy"}, "c1": Color(0.75, 0.12, 0.12)},
	"sai": {"name": "Sai", "slot": "el", "price": 380, "rank": 1, "desc": "Üç dişli savunma hançeri. Bloklarken saldırıyı kilitler.", "stats": {"def": 3}, "weapon": {"dmg": 1.25, "reach": 0.2, "style": "dual"}, "c1": Color(0.7, 0.72, 0.76)},
}

## Efsanevi silahlar (dükkânda yok; A/S görevleri, boss düşürmesi)
const LEGENDARY := ["kubikiribocho", "samehada", "kiba", "hiramekarei", "shibuki", "nuibari", "kabutowari", "chokuto", "raijin", "ruzgar_bicak", "fuma_shuriken", "gunbai", "uc_tirpan"]


static func random_legendary() -> String:
	return LEGENDARY.pick_random()

## Mağazada satılanlar
const SHOP_CLOTHES := ["kitsune_maske", "tengu_maske", "oni_maske", "kum_kabagi", "sake_kabagi", "tisort", "uzun_gomlek", "ceket", "yakali", "kolsuz_yakali", "sargili_kolsuz", "file_atlet", "zirhli_gomlek", "kimono_ust",
	"ninja_pant", "sort", "sivil_pant", "sargili_pant", "hakama", "sandalet", "takviyeli_sandalet", "tabi", "zori",
	"kasa", "kapuson", "kafa_bandaji", "bandana", "bez_maske", "gozluk", "gaz_maskesi", "anbu_maske", "anbu_kurt", "anbu_kus", "anbu_ayi",
	"deri_yelek", "suna_yelek", "kiri_yelek", "kumo_yelek", "iwa_yelek", "samuray_zirh",
	"atki", "kisa_pelerin", "seyahat_pelerini", "haori", "uzun_palto",
	"kol_sargisi", "eldiven", "kolluk", "bacak_koruma", "tam_koruma", "aletli_kemer", "kilic_kini", "sirt_cantasi", "dev_parsomen", "sirt_shuriken",
	# genişletilmiş gardırop
	"hachimaki", "hachimaki_kizil", "haydut_bandana", "col_sarigi", "jingasa", "kabuto", "tengai", "golge_kapuson", "col_kapusonu", "yirtik_kasa",
	"mempo", "goz_bandi", "col_pecesi", "kizil_maske", "anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun",
	"gi_beyaz", "gi_siyah", "kesis_ustu", "arma_gomlek", "beyaz_arma", "cizgili_tisort", "denizci_ust", "panel_ceket", "kizil_ceket", "atlet", "tek_kol_ust",
	"yamali_gomlek", "yamali_kolsuz", "file_kolsuz", "biyeli_kimono", "yukata", "tunik", "deri_ceket", "golge_ust",
	"bol_pantolon", "col_salvari", "kapri", "kisa_sort", "yamali_pant", "kizil_hakama", "siyah_pant",
	"deri_cizme", "zirhli_cizme", "yuksek_sandal", "siyah_tabi",
	"zincir_yelek", "kayis_kosum", "deri_pul_zirh", "gogus_plakasi", "ame_yelek", "jonin_koyu",
	"panco", "yirtik_pelerin", "jinbaori", "kesis_cubbesi", "kesa", "bantli_palto", "mino", "gece_pelerini",
	"omuz_zirhi", "dizlik", "agir_zirh", "uzun_sargi_eldiven", "tespih", "sirt_sepeti", "bel_parsomenleri", "bel_cantasi", "sashimono", "ip_kangali"]
const SHOP_WEAPONS := ["sai", "kunai", "senbon", "ikiz_hancer", "tonfa", "bo", "tanto", "kama", "patlayici_kunai", "zincirli_kunai", "pence", "musta",
	"wakizashi", "altin_kunai", "katana", "mizrak", "yelpaze", "el_shuriken", "kusarigama", "savas_cekici", "chakra_bicak", "nodachi"]
## Sadece görev ödülü olarak düşen (dükkânda satılmayan) parçalar dahil ödül havuzu
const REWARD_POOL := ["kafa_bandaji", "gozluk", "kasa", "kapuson", "atki", "kol_sargisi", "eldiven", "kolluk", "bacak_koruma", "tabi", "hakama",
	"kisa_pelerin", "haori", "dev_parsomen", "sirt_shuriken", "senbon", "kama", "pence", "zincirli_kunai", "wakizashi", "altin_kunai",
	"suna_yelek", "kiri_yelek", "kumo_yelek", "iwa_yelek", "chakra_bicak", "nodachi", "samuray_zirh", "uzun_palto", "anbu_kurt", "anbu_kus", "anbu_ayi",
	"hachimaki_kizil", "jingasa", "kabuto", "kabuto_kizil", "mempo", "mempo_kizil", "golge_kapuson", "arma_gomlek", "beyaz_arma", "golge_ust", "panel_ceket",
	"siyah_pant", "kizil_hakama", "zirhli_cizme", "siyah_tabi", "zincir_yelek", "deri_pul_zirh", "lake_zirh", "jonin_koyu", "jinbaori", "sennin_haorisi",
	"bantli_palto", "gece_pelerini", "omuz_zirhi", "agir_zirh", "bel_parsomenleri", "sashimono", "anbu_tilki", "anbu_kaplan", "anbu_yilan", "anbu_maymun",
	"org_pelerini", "kok_yelek", "cizik_alin"]


## Görev ödülü: rütbeye uygun rastgele parça (yoksa "")
static func random_reward(rank: int) -> String:
	var pool = REWARD_POOL.filter(func(id): return int(ITEMS[id].get("rank", 0)) <= rank)
	return pool.pick_random() if not pool.is_empty() else ""


static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func fits(id: String, slot: String) -> bool:
	var s: String = item(id).get("slot", "")
	return s == slot or (s == "el" and slot in ["sag", "sol"]) or (s == "goz" and slot in ["sag_goz", "sol_goz"])


static func _hex(c) -> String:
	return Color(c).to_html(false)


## Envantere parça ekler, uid döner
static func grant(p: Dictionary, id: String, equip_slot := "", c1 = null, c2 = null, extra := {}) -> int:
	var it = item(id)
	if it.is_empty():
		return -1
	var uid = int(p.get("gear_uid", 0)) + 1
	p["gear_uid"] = uid
	var g = {"uid": uid, "id": id, "c1": _hex(c1 if c1 != null else it.get("c1", Color.WHITE)), "c2": _hex(c2 if c2 != null else it.get("c2", it.get("c1", Color.WHITE)))}
	g.merge(extra, true)
	p["gear"].append(g)
	if equip_slot != "":
		p["equip"][equip_slot] = uid
	return uid


static func find(p: Dictionary, uid) -> Dictionary:
	for g in p.get("gear", []):
		if int(g["uid"]) == int(uid):
			return g
	return {}


static func equipped(p: Dictionary, slot: String) -> Dictionary:
	return find(p, p.get("equip", {}).get(slot, -1))


## Yuvaya uyan tüm eşyalar; şartı tutmayanlar da listelenir (kilitli gösterilir, takılamaz)
static func owned_for(p: Dictionary, slot: String) -> Array:
	var out = []
	for g in p.get("gear", []):
		if fits(g["id"], slot):
			out.append(g)
	return out


## Takma şartı karşılanmıyorsa nedenini döndürür ("Chunin rütbesi gerekli"); karşılanıyorsa ""
static func req_text(id: String, p: Dictionary) -> String:
	var it = item(id)
	var need = int(it.get("rank", 0))
	if need > int(p.get("rank", 0)):
		return "%s rütbesi gerekli" % Data.RANKS[mini(need, Data.RANKS.size() - 1)]
	var cl = String(it.get("clan", ""))
	if cl != "" and cl != String(p.get("clan", "")):
		return "Yalnızca %s klanı giyebilir" % Data.clans.get(cl, {}).get("name", cl.capitalize())
	var lv = int(it.get("level", 0))
	if lv > int(p.get("level", 1)):
		return "Seviye %d gerekli" % lv
	return ""


## Eşyanın şartlarının kısa özeti (şart yoksa ""): kartlarda her zaman gösterilir
static func req_summary(id: String) -> String:
	var it = item(id)
	var parts = []
	if int(it.get("rank", 0)) > 0:
		parts.append("%s rütbesi" % Data.RANKS[mini(int(it["rank"]), Data.RANKS.size() - 1)])
	if String(it.get("clan", "")) != "":
		parts.append("%s klanı" % Data.clans.get(String(it["clan"]), {}).get("name", String(it["clan"]).capitalize()))
	if int(it.get("level", 0)) > 0:
		parts.append("Seviye %d" % int(it["level"]))
	return ("Gerekli: " + ", ".join(parts)) if not parts.is_empty() else ""


static func is_eye(id: String) -> bool:
	return String(item(id).get("slot", "")) == "goz"


## Eski kayıtlar / yeni karakter: görünümden başlangıç ekipmanı üretir
static func ensure(p: Dictionary) -> void:
	if p.has("gear") and p.has("equip"):
		if _ensure_eyes(p):
			apply_look(p)
		return
	p["gear"] = []
	p["equip"] = {}
	var L: Dictionary = p.get("look", {})
	var top_id = {"tisort": "tisort", "uzun": "uzun_gomlek", "ceket": "ceket", "yakali": "yakali"}.get(L.get("top_style", "ceket"), "ceket")
	grant(p, top_id, "govde", L.get("top", null), L.get("top2", null))
	grant(p, {"sort": "sort", "sivil": "sivil_pant"}.get(L.get("pants_style", "ninja"), "ninja_pant"), "bacak", L.get("pants", null))
	grant(p, "sandalet", "ayak", L.get("sandal", null), L.get("wraps", null))
	grant(p, "kunai", "sag")
	if L.get("band") != null:
		grant(p, "alin_koruyucu", "kafa", L["band"])
		grant(p, "alin_boyun", "", L["band"])
	if L.get("vest") != null:
		grant(p, "anbu_zirh" if int(p.get("rank", 0)) >= 4 else "chunin_yelek", "zirh", L["vest"])
	_ensure_eyes(p)
	apply_look(p)


## Doğuştan klan gözleri (eski kayıtlar dahil bir kez verilir)
static func _ensure_eyes(p: Dictionary) -> bool:
	var eid = {"uchiha": "goz_sharingan", "hyuga": "goz_byakugan", "chinoike": "goz_ketsuryugan"}.get(String(p.get("clan", "")), "")
	# eski kayıt: uyuyan Sharingan -> doğrudan ver (1 tomoe)
	var dormant = String(p.get("flags", {}).get("dormant_eye", ""))
	if dormant != "":
		p["flags"].erase("dormant_eye")
		grant(p, dormant, "sag_goz", null, null, {"lvl": 1, "origin": "dogustan"})
		grant(p, dormant, "sol_goz", null, null, {"lvl": 1, "origin": "dogustan"})
		return true
	if eid == "" or p.get("flags", {}).get("born_eyes", false):
		return false
	for g in p["gear"]:
		if item(g["id"]).get("slot", "") == "goz":
			return false
	grant(p, eid, "sag_goz", null, null, {"lvl": 1, "origin": "dogustan"})
	grant(p, eid, "sol_goz", null, null, {"lvl": 1, "origin": "dogustan"})
	if not p.has("flags"):
		p["flags"] = {}
	p["flags"]["born_eyes"] = true
	return true


## Takılı parçalardan görünüm sözlüğünü yeniden kurar
static func apply_look(p: Dictionary) -> void:
	var L: Dictionary = p["look"]
	for k in ["band", "vest", "mask", "weapon_r", "weapon_l", "head_style", "face_style", "outer_style", "back_item", "guards", "eye_r", "eye_l"]:
		L[k] = null
	L["band_style"] = "none"
	L["gloves"] = false
	L["arm_wraps"] = false
	L["top_pattern"] = 0
	L["hakama"] = false
	L["vest_style"] = 0
	L["foot_style"] = "sandal"
	L["outer_pattern"] = 0
	L["outer_accent"] = null
	L["wear"] = 0.0
	L["rope_belt"] = false
	for s in SLOTS:
		var g = equipped(p, s[0])
		if g.is_empty():
			continue
		var it = item(g["id"])
		if it.is_empty():
			continue
		var c1 = Color.html(g["c1"]); var c2 = Color.html(g["c2"])
		for k in it.get("look", {}):
			# iki parça aynı bayrağı açabilir (ör. kol sargısı + sargılı üst): açık olan kalsın
			if it["look"][k] is bool and L.get(k) == true:
				continue
			L[k] = it["look"][k]
		var islot: String = it["slot"] if not it["slot"] in ["el", "goz"] else s[0]
		match islot:
			"kafa":
				if it["look"].get("band_style", "none") != "none":
					L["band"] = c1
				if it["look"].has("head_style"):
					L["headgear"] = c1
					if it["look"]["head_style"] == "bandana":
						L["band"] = c1
			"yuz":
				L["facegear"] = c1
			"govde":
				L["top"] = c1
				L["top2"] = c2
				L["sleeves"] = it["look"]["top_style"] not in ["tisort", "kolsuz"]
			"bacak":
				L["pants"] = c1
			"ayak":
				L["sandal"] = c1
				L["wraps"] = c2
			"zirh":
				L["vest"] = c1
			"dis":
				L["outer"] = c1
				if it.has("c2"):
					L["outer_accent"] = c2
			"kol":
				L["acc"] = c1
			"sirt":
				L["backc"] = c1
			"sag_goz", "sol_goz":
				L["eye_r" if s[0] == "sag_goz" else "eye_l"] = {"kind": int(it["eye"]["kind"]), "lvl": int(g.get("lvl", 3)), "id": g["id"], "origin": g.get("origin", "dogustan")}
			"sag":
				L["weapon_r"] = g["id"]
			"sol":
				L["weapon_l"] = g["id"]
	# kaçak ninja: alın bandının sembolü çizik
	if p.get("flags", {}).get("rogue", false) and L.get("band") != null and String(L.get("band_style", "none")) != "none":
		L["band_style"] = "slashed"


## Takılı parçaların toplam istatistiği
static func stat(p: Dictionary, key: String) -> float:
	var v = 0.0
	for s in SLOTS:
		var g = equipped(p, s[0])
		if not g.is_empty():
			v += float(item(g["id"]).get("stats", {}).get(key, 0.0))
	return v


## Sağ el (yoksa sol el) silahı: {dmg, reach, style}
static func weapon(p: Dictionary) -> Dictionary:
	for s in ["sag", "sol"]:
		var g = equipped(p, s)
		if not g.is_empty() and item(g["id"]).has("weapon"):
			var w: Dictionary = item(g["id"])["weapon"].duplicate()
			# iki elde de silah varsa küçük bonus
			var other = equipped(p, "sol" if s == "sag" else "sag")
			if not other.is_empty() and item(other["id"]).has("weapon"):
				w["dmg"] = float(w["dmg"]) + 0.15
			return w
	return {"dmg": 1.0, "reach": 0.0, "style": "fist"}


static func stats_text(id: String) -> String:
	var it = item(id)
	var parts = []
	var names = {"def": "Savunma", "hp": "Can", "chakra": "Chakra", "speed": "Hız", "melee": "Yakın dövüş"}
	for k in it.get("stats", {}):
		var v = float(it["stats"][k])
		if k in ["speed", "melee"]:
			parts.append("%s %+d%%" % [names[k], int(round(v * 100))])
		else:
			parts.append("%s %+d" % [names[k], int(v)])
	if it.has("weapon"):
		parts.push_front("Hasar x%.2f, menzil +%.1fm" % [it["weapon"]["dmg"], it["weapon"]["reach"]])
	return ", ".join(parts) if not parts.is_empty() else "—"
