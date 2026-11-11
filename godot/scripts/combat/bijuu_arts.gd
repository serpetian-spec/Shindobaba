class_name BijuuArts
extends RefCounted
## Kuyruklu canavarların kendine özgü teknikleri (animedeki gibi): her canavarın üç imza tekniği + kendi pençe/vuruş tarzı.
## Hem oyuncu jinchūriki'si (pelerin / tam dönüşüm, BeastCloak), hem vahşi canavar boss'ları (TailedBeast), hem düşman
## jinchūriki'ler (Enemy "beast") aynı kodu kullanır; ölçek (s) insan boyu = 1, dev canavar ≈ boy / 10.
## Her teknik gerçek bir etki bırakır: gömme/bağlama, kör etme, aşındırma, yavaşlatma, lav/sümük/mercan zemini, çekip çarpma...
##   use(user, beast_id, key, ctx)   ctx: {"s": ölçek, "dmg": ana vuruş hasarı, "from": çıkış noktası, "aim": hedef nokta, "tgt": hedef}

const TECHS := {
	"shukaku": [
		{"key": "renkudan", "name": "Fūton: Renkūdan", "desc": "Sıkıştırılmış hava mermisi: ağaçları devirir, hedefi savurur", "cd": 6.0, "cost": 18.0},
		{"key": "sabaku_taiso", "name": "Sabaku Taisō", "desc": "Kum tsunamisi: yolundakileri kuma gömer (hareketsiz)", "cd": 10.0, "cost": 26.0},
		{"key": "suna_tate", "name": "Suna no Tate", "desc": "Kum kubbesi: gelen mermileri yutar, hasarı yarıya indirir", "cd": 16.0, "cost": 22.0},
		{"key": "ryusa_soso", "name": "Ryūsa Bakuryū: Sabaku Sōsō", "desc": "Yer kum seline döner: alandaki herkes kuma gömülür, kum sıkışıp ezer; alan uzun süre bataklık kum kalır", "cd": 22.0, "cost": 60.0, "epic": true},
		{"key": "renkudan_rensha", "name": "Fūton: Renkūdan Rensha", "desc": "Art arda beş dev hava mermisi yelpaze gibi", "cd": 16.0, "cost": 45.0, "epic": true},
	],
	"matatabi": [
		{"key": "neko_pounce", "name": "Bakeneko Sıçrayışı", "desc": "Mavi alevli kedi sıçrayışı + üç pençe yarığı", "cd": 5.0, "cost": 14.0},
		{"key": "aobi_dama", "name": "Ao-bi Dama", "desc": "Mavi ateş topları: düştüğü yer uzun süre yanar", "cd": 8.0, "cost": 22.0},
		{"key": "kaen_breath", "name": "Kaen: Mavi Alev Nefesi", "desc": "Sürekli mavi alev akışı, yakar", "cd": 12.0, "cost": 28.0},
		{"key": "aobi_rinkaku", "name": "Ao-bi Rinkaku", "desc": "Hedefin çevresine kaçış yolu bırakmayan mavi alev halkası; ortası patlar", "cd": 22.0, "cost": 55.0, "epic": true},
		{"key": "bakeneko_rengeki", "name": "Bakeneko Rengeki", "desc": "Hedefe üç kez art arda mavi alevli sıçrayış, ardında alev izi", "cd": 16.0, "cost": 45.0, "epic": true},
	],
	"isobu": [
		{"key": "sango", "name": "Sango: Mercan Büyütme", "desc": "Yerden mercan fışkırır: hedefi hapseder, mercan duvar olarak kalır", "cd": 9.0, "cost": 22.0},
		{"key": "shell_roll", "name": "Kabuk Yuvarlanışı", "desc": "Dikenli kabukla yuvarlanarak ezip geçer", "cd": 7.0, "cost": 18.0},
		{"key": "kiri_genjutsu", "name": "Kiri no Genjutsu", "desc": "Yanılsama sisi: düşmanlar hedef şaşırır, yavaşlar", "cd": 15.0, "cost": 26.0},
		{"key": "sango_mori", "name": "Sango Mori", "desc": "Sarmal büyüyen mercan ormanı: yakalananlar sıkışır, mercanlar siper olarak kalır", "cd": 22.0, "cost": 55.0, "epic": true},
		{"key": "suiro_kyudan", "name": "Suirō Kyūdan", "desc": "Hedef dev su küresine hapsolur, nefessiz kalır; küre patlayınca savrulur", "cd": 18.0, "cost": 50.0, "epic": true},
	],
	"son_goku": [
		{"key": "kakogan", "name": "Yōton: Kakōgan", "desc": "Lav kaya mermileri: düştüğü yerde lav gölü kalır", "cd": 6.0, "cost": 18.0},
		{"key": "funkatsu", "name": "Yōton: Funkatsu", "desc": "Yer patlar, lav fışkırıkları düşmanı havaya fırlatır", "cd": 11.0, "cost": 28.0},
		{"key": "yoton_yoroi", "name": "Yōton no Yoroi", "desc": "Lav zırhı: hasar azalır, değen düşman yanar", "cd": 18.0, "cost": 24.0},
		{"key": "kazan_u", "name": "Yōton: Kazan-u", "desc": "Gökten lav kayası yağmuru: düştükleri yer lav gölüne döner", "cd": 22.0, "cost": 60.0, "epic": true},
		{"key": "yoton_funka", "name": "Yōton: Funka", "desc": "Yer çizgi hâlinde yarılır, art arda lav sütunları fışkırır", "cd": 18.0, "cost": 50.0, "epic": true},
	],
	"kokuo": [
		{"key": "futton_boil", "name": "Futton: Kaishin", "desc": "Kaynar buhar bulutu: içindekiler haşlanır, savunması erir", "cd": 10.0, "cost": 24.0},
		{"key": "horn_ram", "name": "Boynuz Hücumu", "desc": "Buhar itişli dev hücum: her şeyi savurur", "cd": 6.0, "cost": 16.0},
		{"key": "steam_burst", "name": "Jōki Bōi: Buhar Patlaması", "desc": "Bedenden çevreye buhar patlaması", "cd": 9.0, "cost": 20.0},
		{"key": "futton_mojo", "name": "Futton: Mōjō", "desc": "Bedenden dev kaynar buhar fırtınası: yakındakiler haşlanıp savrulur, alan kaynar", "cd": 22.0, "cost": 55.0, "epic": true},
		{"key": "gokaku_totsugeki", "name": "Gōkaku Totsugeki", "desc": "Buhar itişli üç boynuz hücumu art arda", "cd": 16.0, "cost": 45.0, "epic": true},
	],
	"saiken": [
		{"key": "fukuso", "name": "Fukuso: Asit Baloncukları", "desc": "Süzülen baloncuklar patlayınca aşındırır (zırh erir)", "cd": 7.0, "cost": 18.0},
		{"key": "slime", "name": "Yapışkan Sümük", "desc": "Geniş sümük gölü: içindekiler saplanıp yavaşlar", "cd": 11.0, "cost": 22.0},
		{"key": "acid_mist", "name": "Asit Sisi", "desc": "Yakıcı yeşil sis bulutu", "cd": 13.0, "cost": 24.0},
		{"key": "fukuso_arashi", "name": "Fukuso Arashi", "desc": "Gökyüzünü dolduran asit baloncuğu fırtınası", "cd": 20.0, "cost": 55.0, "epic": true},
		{"key": "nenko_shinshoku", "name": "Nenkō Shinshoku", "desc": "Öne yayılan sümük seli: yollar yapışır, değen zırh erir", "cd": 18.0, "cost": 50.0, "epic": true},
	],
	"chomei": [
		{"key": "hane_flight", "name": "Hane: Böcek Kanatları", "desc": "Kanatlanıp havada süzül (Boşluk: yüksel)", "cd": 14.0, "cost": 20.0},
		{"key": "rinpun", "name": "Rinpun Hikōmei", "desc": "Pul tozu + kör eden ışık patlaması", "cd": 10.0, "cost": 22.0},
		{"key": "mushi_swarm", "name": "Mushi Dama: Böcek Sürüsü", "desc": "Güdümlü böcek sürüsü ısırır, chakra emer", "cd": 8.0, "cost": 18.0},
		{"key": "rinpun_kosen", "name": "Rinpun Kōsen", "desc": "Alanı pul tozu sisi kaplar, art arda kör eden ışık patlamaları", "cd": 22.0, "cost": 55.0, "epic": true},
		{"key": "mushi_arashi", "name": "Mushi Arashi", "desc": "Beş güdümlü böcek sürüsü birden", "cd": 18.0, "cost": 50.0, "epic": true},
	],
	"gyuki": [
		{"key": "sumi", "name": "Sumi Fūin: Mürekkep Püskürtme", "desc": "Mürekkep jeti: kör eder, yavaşlatır, zemini kaplar", "cd": 8.0, "cost": 18.0},
		{"key": "tako_ude", "name": "Tako Ude: Lariat", "desc": "Dokunaç uzanır, yakalar, çekip yere çarpar", "cd": 7.0, "cost": 20.0},
		{"key": "tako_bunshin", "name": "Tako Bunshin", "desc": "Mürekkep bulutunda klonlar bırakıp kaçış", "cd": 16.0, "cost": 26.0},
		{"key": "sumi_nami", "name": "Sumi Nami", "desc": "Öne kopan mürekkep tsunamisi: kör eder, yavaşlatır, zemini mürekkebe boğar", "cd": 20.0, "cost": 55.0, "epic": true},
		{"key": "hachi_ude", "name": "Hachibi Ude Rengeki", "desc": "Sekiz dokunaç hedefin çevresine art arda iner, yeri yarar", "cd": 16.0, "cost": 50.0, "epic": true},
	],
	"kurama": [
		{"key": "chakra_kaina", "name": "Chakra Kolu", "desc": "Dev chakra eli uzanır, yakalar, çekip ezer", "cd": 6.0, "cost": 18.0},
		{"key": "biju_hoko", "name": "Bijū Hōkō: Kükreme", "desc": "Koni şok dalgası: savurur, sersemletir, ağaçları yatırır", "cd": 9.0, "cost": 20.0},
		{"key": "bijudama_rasengan", "name": "Bijūdama Rasengan", "desc": "Dönen canavar topu: dev kubbe patlaması, çoklu vuruş (Rasenshuriken bilmek gerekir)", "cd": 14.0, "cost": 36.0},
		{"key": "kyubi_biso", "name": "Kyūbi Bisō", "desc": "Dokuz kuyruk sırayla yeri döver: önündeki her şey savrulur", "cd": 18.0, "cost": 55.0, "epic": true},
		{"key": "bijudama_rendan", "name": "Bijūdama Rendan", "desc": "Art arda üç dev Kuyruklu Canavar Topu", "cd": 28.0, "cost": 90.0, "epic": true},
	],
}

## Tam dönüşüm / boss pençesi: canavara özgü vuruş tarzı [element, renk, ek etki]
const MELEE := {
	"shukaku": ["fuuton", Color(0.86, 0.72, 0.48), "sand"], "matatabi": ["katon", Color(0.35, 0.55, 1.0), "burn"],
	"isobu": ["suiton", Color(0.45, 0.85, 0.8), "coral"], "son_goku": ["yoton", Color(1.0, 0.45, 0.1), "burn"],
	"kokuo": ["futton", Color(0.97, 0.95, 0.92), "steam"], "saiken": ["suiton", Color(0.7, 0.95, 0.8), "acid"],
	"chomei": ["fuuton", Color(0.6, 1.0, 0.45), "wind"], "gyuki": ["raiton", Color(0.25, 0.15, 0.3), "ink"],
	"kurama": ["katon", Color(1.0, 0.5, 0.12), "burn"], "raiju": ["raiton", Color(0.5, 0.75, 1.0), "shock"],
}

const SAND := Color(0.86, 0.72, 0.48)
const MAX_FIELDS := 14
static var _fields := 0
static var _epic_t := {}   # canavar türü -> son epik teknik zamanı (ms)


## Tekniğin canavar hareketi: [rig hareketi, süre sn, etkinin çıktığı an (0..1)] — tam dönüşümdeki oyuncu ve dünya canavarı aynı tabloyu kullanır
const ANIM := {
	"renkudan": ["cast", 1.0, 0.36], "aobi_dama": ["cast", 1.0, 0.36], "slime": ["cast", 1.0, 0.36], "sumi": ["cast", 1.0, 0.36],
	"bijudama_rasengan": ["cast", 1.1, 0.36], "mushi_swarm": ["cast", 1.0, 0.36], "fukuso": ["cast", 1.0, 0.36],
	"renkudan_rensha": ["cast", 1.4, 0.3], "bijudama_rendan": ["cast", 1.4, 0.3],
	"kaen_breath": ["breath", 1.8, 0.18], "futton_boil": ["breath", 1.6, 0.18], "steam_burst": ["breath", 1.4, 0.2], "acid_mist": ["breath", 1.6, 0.18],
	"rinpun": ["breath", 1.6, 0.18], "rinpun_kosen": ["breath", 1.8, 0.18], "sumi_nami": ["breath", 1.8, 0.18], "futton_mojo": ["breath", 1.8, 0.18],
	"kiri_genjutsu": ["breath", 1.8, 0.18], "fukuso_arashi": ["breath", 1.8, 0.18], "mushi_arashi": ["breath", 1.8, 0.18], "nenko_shinshoku": ["breath", 1.8, 0.18],
	"biju_hoko": ["roar", 1.4, 0.3],
	"sabaku_taiso": ["rear", 1.4, 0.58], "ryusa_soso": ["rear", 1.5, 0.58], "sango": ["rear", 1.3, 0.58], "sango_mori": ["rear", 1.5, 0.58],
	"funkatsu": ["rear", 1.4, 0.58], "kazan_u": ["rear", 1.5, 0.58], "yoton_funka": ["rear", 1.5, 0.58], "suiro_kyudan": ["rear", 1.4, 0.58],
	"aobi_rinkaku": ["rear", 1.4, 0.58],
	"suna_tate": ["guard", 1.3, 0.25], "yoton_yoroi": ["guard", 1.3, 0.25], "tako_bunshin": ["guard", 1.3, 0.25],
	"neko_pounce": ["charge", 1.0, 0.0], "bakeneko_rengeki": ["charge", 1.0, 0.0], "shell_roll": ["charge", 1.0, 0.0], "horn_ram": ["charge", 1.0, 0.0],
	"gokaku_totsugeki": ["charge", 1.0, 0.0], "hane_flight": ["charge", 1.0, 0.0],
	"kyubi_biso": ["tails", 1.2, 0.45], "hachi_ude": ["tails", 1.2, 0.45], "tako_ude": ["tails", 1.2, 0.45], "chakra_kaina": ["tails", 1.2, 0.45],
	"kakogan": ["slam", 1.1, 0.5],
}


static func anim(key: String) -> Array:
	return ANIM.get(key, ["cast", 1.0, 0.36])


static func techs(id: String) -> Array:
	return TECHS.get(id, [])


static func tech(id: String, key: String) -> Dictionary:
	for t in techs(id):
		if t["key"] == key:
			return t
	return {}


static func use(user: Node3D, id: String, key: String, ctx: Dictionary) -> void:
	if not is_instance_valid(user):
		return
	var c = ctx.duplicate()
	c["s"] = float(c.get("s", 1.0))
	c["dmg"] = float(c.get("dmg", 40.0))
	if not c.has("from"):
		c["from"] = user.global_position + Vector3.UP * 1.4
	if not c.has("aim"):
		c["aim"] = c["from"] + _fwd(user) * 20.0
	match key:
		"renkudan": _renkudan(user, c)
		"sabaku_taiso": _sabaku_taiso(user, c)
		"suna_tate": _suna_tate(user, c)
		"neko_pounce": _neko_pounce(user, c)
		"aobi_dama": _aobi_dama(user, c)
		"kaen_breath": _kaen_breath(user, c)
		"sango": _sango(user, c)
		"shell_roll": _shell_roll(user, c)
		"kiri_genjutsu": _kiri_genjutsu(user, c)
		"kakogan": _kakogan(user, c)
		"funkatsu": _funkatsu(user, c)
		"yoton_yoroi": _yoton_yoroi(user, c)
		"futton_boil": _futton_boil(user, c)
		"horn_ram": _horn_ram(user, c)
		"steam_burst": _steam_burst(user, c)
		"fukuso": _fukuso(user, c)
		"slime": _slime(user, c)
		"acid_mist": _acid_mist(user, c)
		"hane_flight": _hane_flight(user, c)
		"rinpun": _rinpun(user, c)
		"mushi_swarm": _mushi_swarm(user, c)
		"sumi": _sumi(user, c)
		"tako_ude": _tako_ude(user, c)
		"tako_bunshin": _tako_bunshin(user, c)
		"chakra_kaina": _chakra_kaina(user, c)
		"biju_hoko": _biju_hoko(user, c)
		"bijudama_rasengan": _bijudama_rasengan(user, c)
		"ryusa_soso": _ryusa_soso(user, c)
		"renkudan_rensha": _renkudan_rensha(user, c)
		"aobi_rinkaku": _aobi_rinkaku(user, c)
		"bakeneko_rengeki": _bakeneko_rengeki(user, c)
		"sango_mori": _sango_mori(user, c)
		"suiro_kyudan": _suiro_kyudan(user, c)
		"kazan_u": _kazan_u(user, c)
		"yoton_funka": _yoton_funka(user, c)
		"futton_mojo": _futton_mojo(user, c)
		"gokaku_totsugeki": _gokaku_totsugeki(user, c)
		"fukuso_arashi": _fukuso_arashi(user, c)
		"nenko_shinshoku": _nenko_shinshoku(user, c)
		"rinpun_kosen": _rinpun_kosen(user, c)
		"mushi_arashi": _mushi_arashi(user, c)
		"sumi_nami": _sumi_nami(user, c)
		"hachi_ude": _hachi_ude(user, c)
		"kyubi_biso": _kyubi_biso(user, c)
		"bijudama_rendan": _bijudama_rendan(user, c)
	var t = tech(id, key)
	if not t.is_empty() and user is Player:
		Combat.popup_text(user.global_position + Vector3.UP * (2.6 + c["s"]), t["name"], MELEE.get(id, MELEE["kurama"])[1].lightened(0.3))


# ================================================================== ortak yardımcılar
static func _fwd(user: Node3D) -> Vector3:
	if user.has_method("face_dir"):
		return user.face_dir()
	return -user.global_transform.basis.z


static func _flat(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 0.001 else Vector3.FORWARD


static func _gp(p: Vector3) -> Vector3:
	return Vector3(p.x, Game.jutsu_floor(p.x, p.z), p.z)


static func _shake(a: float) -> void:
	if Game.world:
		Game.world.env.add_shake(a)


static func _hit(user: Node3D, pos: Vector3, r: float, info: Dictionary, excl: Array = []) -> Array:
	if not is_instance_valid(user):
		return []
	return Combat.hit_sphere(user, pos, r, info, excl)


## Hasar vermeden, küre içindeki düşman savaşçılar
static func _foes(user: Node3D, pos: Vector3, r: float) -> Array:
	var out = []
	if not is_instance_valid(user):
		return out
	for f in VFX.tree().get_nodes_in_group("fighters"):
		if Combat.hostile(user, f) and not f.is_dead() and Combat.capsule_hit(pos, f, r):
			out.append(f)
	return out


static func _is_giant(f: Node) -> bool:
	# dev canavarlar ve dev çağrılar (küçük çağrılar da hit_test taşır: boyla ayır)
	return f.has_method("hit_test") and (not f is Summon or float(f.height) >= 8.0)


## Kullanıcının görünen boyu (tam dönüşümde canavar modeli, boss'ta dev gövde)
static func _body_h(user: Node3D, c: Dictionary) -> float:
	if c.has("base_h"):
		return float(c["base_h"]) / 0.45
	var h = user.get("height")
	return float(h) if h != null else 1.8


## Çıkış noktası: sürekli tekniklerde (nefes, püskürtme) her an yeniden hesaplanır
static func _live_from(user: Node3D, c: Dictionary, s: float) -> Vector3:
	if c.get("from_fn") is Callable and (c["from_fn"] as Callable).is_valid():
		return c["from_fn"].call()
	if user.get("rig") and is_instance_valid(user.rig):
		return user.rig.mouth_pos()
	return user.global_position + Vector3.UP * 1.5 * minf(s, 3.0) + _fwd(user) * 0.8 * s


## Hareketsiz bırak (gömme, hapsetme, yakalama). Dev canavarlar etkilenmez; oyuncuya daha kısa.
static func _bind(f: Node3D, t: float) -> void:
	if _is_giant(f):
		return
	f.apply_status("bind", t * (0.55 if f is Player else 1.0))


## Kör et: düşman hedefini kaybeder; oyuncunun ekranı bembeyaz/kapkara olur
static func _blind(f: Node3D, t: float, col := Color(1, 1, 0.92, 0.75)) -> void:
	if f is Player:
		_tint(col, minf(t, 2.2))
		f.apply_status("stun", minf(0.7, t * 0.3))
	elif f.has_method("lose_target"):
		f.lose_target(t)
		f.apply_status("stun", t * 0.35)
		Combat.popup_text(f.global_position + Vector3.UP * (f.height + 1.0), "KÖR!", Color(1, 1, 0.7))


static func _tint(col: Color, dur: float) -> void:
	if Game.world == null:
		return
	Game.world.env.flash_tint(col, dur)


## Aşındırma (Saiken asidi, Kokuō buharı): oyuncuda zırh erir, düşmanda süreli eriyen can + yavaşlık
static func _corrode(f: Node3D, dur: float, dps: float, col: Color, label := "AŞINDI!") -> void:
	if f is Player:
		Buffs.add("bijuu_asit", dur, {"armor": 1.35})
		_tint(Color(col.r, col.g, col.b, 0.22), 0.6)
		return
	if _is_giant(f) or f.get_meta("corroding", false):
		return
	f.set_meta("corroding", true)
	f.apply_status("slow", dur * 0.6)
	Combat.popup_text(f.global_position + Vector3.UP * (f.height + 1.0), label, col.lightened(0.3))
	var st = {"t": 0.0}
	var tm = Timer.new()
	tm.wait_time = 0.5
	tm.autostart = true
	f.add_child(tm)
	tm.timeout.connect(func():
		st["t"] += 0.5
		if not is_instance_valid(f) or f.is_dead():
			return
		f.hp -= dps * 0.5
		Combat.damage_number(f.global_position + Vector3.UP * f.height, dps * 0.5, col)
		FX.burst(f.global_position + Vector3.UP * f.height * 0.6, {"amount": 4, "life": 0.6, "size": 0.35, "vmin": 0.5, "vmax": 1.5, "gravity": Vector3(0, 2, 0),
			"colors": [col.lightened(0.4), Color(col.r, col.g, col.b, 0)]})
		if f.hp <= 0.0 and f.has_method("die"):
			f.hp = 0.0
			f.die({})
		if st["t"] >= dur:
			f.set_meta("corroding", false)
			tm.queue_free())


## Süreli zemin/alan: her `every` saniyede fn(node, geçen) çağırır, `dur` sonunda kendini siler
static func _ticker(pos: Vector3, dur: float, every: float, fn: Callable) -> Node3D:
	var n = Node3D.new()
	VFX.scene().add_child(n)
	n.global_position = pos
	_fields += 1
	n.tree_exited.connect(func(): _fields = maxi(0, _fields - 1))
	var st = {"t": 0.0}
	var tm = Timer.new()
	tm.wait_time = every
	tm.autostart = true
	n.add_child(tm)
	tm.timeout.connect(func():
		st["t"] += every
		fn.call(n, st["t"])
		if st["t"] >= dur:
			n.queue_free())
	return n


## Sis / buhar hacmi: yarı saydam kubbe (içinden de görünür) + kenarında dönen bulutlar; yavaşça belirir ve söner
static func _fog(center: Vector3, R: float, col: Color, alpha: float, dur: float) -> void:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, 0.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var dome = _mi(VFX._sphere(0.5, 24, 12), m)
	VFX.scene().add_child(dome)
	dome.global_position = center
	dome.scale = Vector3(R * 2.0, R * 0.9, R * 2.0)
	var tw = dome.create_tween()
	tw.tween_property(m, "albedo_color:a", alpha, 0.6)
	tw.tween_interval(maxf(0.1, dur - 1.4))
	tw.tween_property(m, "albedo_color:a", 0.0, 0.8)
	tw.tween_callback(dome.queue_free)


static func _fade_free(n: Node3D, after: float, sink := true) -> void:
	var tw = n.create_tween()
	tw.tween_interval(after)
	if sink:
		tw.tween_property(n, "scale", Vector3(n.scale.x, 0.02, n.scale.z), 0.6).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(n, "scale", Vector3.ONE * 0.01, 0.4)
	tw.tween_callback(n.queue_free)


static func _mi(mesh: Mesh, mat: Material) -> MeshInstance3D:
	return VFX._mi(mesh, mat)


static var _mats := {}
static func _toon(col: Color) -> Material:
	var k = "t%s" % col
	if not _mats.has(k):
		_mats[k] = Props.toon_color(col)
	return _mats[k]


## Yarı saydam parlak yüzey (sümük, mercan kristali, kubbe, mürekkep)
static func _glass(col: Color, alpha: float, emit := 0.0) -> StandardMaterial3D:
	var k = "g%s%.2f%.2f" % [col, alpha, emit]
	if not _mats.has(k):
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(col.r, col.g, col.b, alpha)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.15
		m.metallic_specular = 0.9
		m.rim_enabled = true
		m.rim = 0.6
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = emit
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[k] = m
	return _mats[k]


static func _cone(r0: float, r1: float, h: float, seg := 7) -> CylinderMesh:
	var k = "cone%.2f%.2f%.2f%d" % [r0, r1, h, seg]
	if not _mats.has(k):
		var cm = CylinderMesh.new()
		cm.bottom_radius = r0; cm.top_radius = r1; cm.height = h; cm.radial_segments = seg; cm.rings = 1
		_mats[k] = cm
	return _mats[k]


## Sürekli akış konisi (nefes / püskürtme): ağızdan hedefe uzanan, akan malzemeli koni; her tikte yeniden yönlenir
static func _stream(mat: Material, r_end: float) -> MeshInstance3D:
	var cm = CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = 14
	cm.rings = 3
	cm.cap_top = false
	cm.cap_bottom = false
	var mi = _mi(cm, mat)
	VFX.scene().add_child(mi)
	mi.set_meta("r_end", r_end)
	return mi


static func _aim_stream(mi: MeshInstance3D, from: Vector3, dir: Vector3, length: float, k: float) -> void:
	if not is_instance_valid(mi):
		return
	var mid = from + dir * length * 0.5
	var up = Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	# silindirin Y ekseni akış yönü: tepe (ince) ağızda, taban (geniş) uzakta
	var b = Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, PI * 0.5)
	var r = float(mi.get_meta("r_end")) * k
	mi.global_transform = Transform3D(b.orthonormalized(), mid)
	mi.scale = Vector3(r, length, r)
	mi.rotate_object_local(Vector3.UP, k * 9.0)


## Projeksiyon mermisi (görsel düğüm verilir)
static func _shot(user: Node3D, from: Vector3, vel: Vector3, r: float, info: Dictionary, visual: Node3D, on_hit: Callable, grav := 0.0, life := 4.0) -> Projectile:
	var pr = Projectile.new()
	pr.shooter = user
	pr.vel = vel
	pr.radius = r
	pr.life = life
	pr.gravity = grav
	pr.info = info
	if visual:
		pr.add_child(visual)
	pr.on_hit = on_hit
	VFX.scene().add_child(pr)
	pr.global_position = from
	return pr


## Kullanıcıyı bir noktaya taşı (sıçrayış/hücum/yuvarlanma): yol boyu on_step(k, pos), sonda on_done(pos)
class Mover extends Node:
	var user: Node3D
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var dur := 0.5
	var arc := 0.0
	var t := 0.0
	var on_step := Callable()
	var on_done := Callable()

	func _physics_process(dt: float) -> void:
		if not is_instance_valid(user) or user.is_dead():
			queue_free()
			return
		t += dt
		var k = clampf(t / dur, 0.0, 1.0)
		var p = a.lerp(b, k) + Vector3.UP * arc * 4.0 * k * (1.0 - k)
		p.y = maxf(p.y, Game.jutsu_floor(p.x, p.z))
		if user is CharacterBody3D and user.collision_mask != 0:
			var col = user.move_and_collide(p - user.global_position)
			user.velocity = Vector3.ZERO
			if col and arc <= 0.0 and k > 0.15:
				k = 1.0   # duvara çarptı: hücum burada biter
		else:
			user.global_position = p
		if on_step.is_valid():
			on_step.call(k, user.global_position)
		if k >= 1.0:
			if on_done.is_valid():
				on_done.call(user.global_position)
			queue_free()


static func _move(user: Node3D, to: Vector3, dur: float, arc: float, on_step := Callable(), on_done := Callable()) -> void:
	var m = Mover.new()
	m.user = user
	m.a = user.global_position
	m.b = to
	m.dur = dur
	m.arc = arc
	m.on_step = on_step
	m.on_done = on_done
	VFX.scene().add_child(m)
	if user is Player:
		user.input_locked = maxf(user.input_locked, dur)


## Uzanan dokunaç / chakra kolu: uca doğru incelen boğumlu kol hedefe uzanır, yakalarsa geri çeker, sonra bırakır
class Reach extends Node3D:
	var user: Node3D
	var base_fn := Callable()
	var tip_to := Vector3.ZERO
	var target: Node3D = null
	var n := 14
	var radius := 0.4
	var mat: Material
	var segs: Array = []
	var t := 0.0
	var out_t := 0.32
	var hold_t := 0.2
	var back_t := 0.45
	var reached := false
	var grabbed: Node3D = null
	var on_reach := Callable()   # func(tip: Vector3) -> Node3D (yakalanan ya da null)
	var on_back := Callable()    # func(grabbed: Node3D)
	var claws := 0
	var claw_mat: Material
	var tipnode: Node3D
	var wiggle := 1.0

	func _ready() -> void:
		for i in n:
			var mi = VFX._mi(VFX._sphere(0.5, 14, 7), mat)
			add_child(mi)
			segs.append(mi)
		tipnode = Node3D.new()
		add_child(tipnode)
		for k in claws:
			var cl = VFX._mi(BijuuArts._cone(0.5, 0.02, 1.0, 6), claw_mat if claw_mat else mat)
			var a = (float(k) - (claws - 1) * 0.5) * 0.45
			cl.rotation = Vector3(-PI * 0.5 + 0.35, a, 0)
			cl.position = Vector3(sin(a), 0, -0.6) * radius
			cl.scale = Vector3(radius * 0.45, radius * 2.2, radius * 0.45)
			tipnode.add_child(cl)

	func _goal() -> Vector3:
		if target and is_instance_valid(target) and not target.is_dead():
			return target.global_position + Vector3.UP * float(target.height) * 0.5
		return tip_to

	func _process(dt: float) -> void:
		if not is_instance_valid(user):
			queue_free()
			return
		t += dt
		var base: Vector3 = base_fn.call()
		var goal = _goal()
		var e := 0.0
		if t < out_t:
			e = ease(t / out_t, 0.4)
		elif t < out_t + hold_t:
			e = 1.0
			if not reached:
				reached = true
				if on_reach.is_valid():
					grabbed = on_reach.call(goal)
		elif t < out_t + hold_t + back_t:
			e = 1.0 - ease((t - out_t - hold_t) / back_t, 1.8)
		else:
			if on_back.is_valid():
				on_back.call(grabbed if is_instance_valid(grabbed) else null)   # yakalanan yok olduysa (öldü/silindi) serbest bırakılmış nesne geçmesin
			queue_free()
			return
		var tip = base.lerp(goal, e)
		if grabbed and is_instance_valid(grabbed) and t >= out_t + hold_t and not BijuuArts._is_giant(grabbed):
			grabbed.global_position = tip - Vector3.UP * float(grabbed.height) * 0.5
			if grabbed is CharacterBody3D:
				grabbed.velocity = Vector3.ZERO
		var dist = base.distance_to(tip)
		var mid = base.lerp(tip, 0.5) + Vector3.UP * dist * 0.22
		var side = (tip - base).cross(Vector3.UP).normalized()
		var prev = base
		for i in n:
			var k = float(i + 1) / n
			var p = base.lerp(mid, k).lerp(mid.lerp(tip, k), k)
			p += side * sin(t * 9.0 + k * 7.0) * wiggle * radius * 1.5 * sin(k * PI)
			var seg: MeshInstance3D = segs[i]
			seg.global_position = (prev + p) * 0.5
			var L = maxf(prev.distance_to(p) * 1.35, radius * 0.6)
			var r = radius * lerpf(1.0, 0.55, k)
			if prev.distance_to(p) > 0.01:
				seg.look_at(p, Vector3.UP if absf((p - prev).normalized().y) < 0.95 else Vector3.RIGHT)
			seg.scale = Vector3(r * 2.0, r * 2.0, L)
			prev = p
		tipnode.global_position = prev
		if base.distance_to(prev) > 0.1:
			tipnode.look_at(prev + (prev - base).normalized(), Vector3.UP)


static func _reach(user: Node3D, base_fn: Callable, target: Node3D, tip_to: Vector3, radius: float, mat: Material, on_reach: Callable, on_back: Callable, claws := 0, claw_mat: Material = null) -> Reach:
	var r = Reach.new()
	r.user = user
	r.base_fn = base_fn
	r.target = target
	r.tip_to = tip_to
	r.radius = radius
	r.mat = mat
	r.on_reach = on_reach
	r.on_back = on_back
	r.claws = claws
	r.claw_mat = claw_mat
	var d = (base_fn.call() as Vector3).distance_to(tip_to if target == null else target.global_position)
	r.out_t = clampf(d / 90.0, 0.2, 0.55)
	VFX.scene().add_child(r)
	return r


## Nişan yönündeki en yakın düşman (yoksa null)
static func _pick(user: Node3D, c: Dictionary, rng: float) -> Node3D:
	if c.get("tgt") is Node3D and is_instance_valid(c["tgt"]) and not c["tgt"].is_dead():
		if (c["tgt"] as Node3D).global_position.distance_to(user.global_position) < rng * 1.3:
			return c["tgt"]
	var dir = _flat(c["aim"] - user.global_position)
	return Combat.nearest_enemy(user, rng, dir, 0.55)


# ================================================================== SHUKAKU — kum ve rüzgar
static func _renkudan(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var dir = (c["aim"] - from).normalized()
	VFX.shockwave(from + dir * s, Color(0.95, 0.9, 0.75), 3.0 * s, 0.3, false)
	VFX.puffs(from, {"amount": 14, "life": 0.6, "size": 0.8 * s, "radius": 0.6 * s, "vmin": 2, "vmax": 6, "dir": dir, "spread": 40.0,
		"colors": [Color(0.95, 0.88, 0.7, 0.9), Color(0.85, 0.72, 0.5, 0)]})
	Sfx.play("wind", from, 0.6)
	var vis = VFX.wind_ball(1.4 * s)
	var st = {"r": 0.0}
	var dmg: float = c["dmg"]
	var info = {"dmg": dmg, "element": "fuuton", "knock": 30.0, "launch": 7.0, "kind": "heavy", "hitstop": 0.08}
	var boom = func(pos: Vector3, _t: Node3D) -> void:
		VFX.shockwave(_gp(pos) + Vector3.UP * 0.2, Color(0.95, 0.9, 0.78), 12.0 * s, 0.5)
		VFX.shockwave(pos, Color(1, 1, 1), 6.0 * s, 0.25, false)
		VFX.puffs(_gp(pos) + Vector3.UP * s, {"amount": 26, "life": 1.2, "size": 1.6 * s, "radius": 2.0 * s, "vmin": 6, "vmax": 14, "dir": Vector3.UP, "spread": 80.0,
			"gravity": Vector3(0, -3, 0), "colors": [Color(0.92, 0.84, 0.64, 0.95), Color(0.8, 0.68, 0.48, 0)]})
		# patlama doğrudan vurulanı ikinci kez vurmaz (eskiden mermi + patlama aynı hedefe x1.6)
		var ex = st["pr"].hit_list if st.has("pr") and is_instance_valid(st["pr"]) else []
		_hit(user, pos, 6.0 * s, {"dmg": dmg * 0.5, "element": "fuuton", "knock": 42.0, "launch": 10.0, "kind": "heavy"}, ex)
		Sfx.play("boom", pos, 0.8)
		_shake(0.5 + s * 0.1)
	var pr = _shot(user, from + dir * s, dir * 75.0, 0.7 * s, info, vis, boom)
	st["pr"] = pr
	# arkasında hava basıncı halkaları
	pr.on_tick = func(p: Projectile, dt: float) -> void:
		st["r"] += dt
		if st["r"] > 0.07:
			st["r"] = 0.0
			FX.ring(p.global_position, Color(0.95, 0.92, 0.8, 0.8), 2.2 * s, 0.25, true, p.vel.normalized())


static func _sabaku_taiso(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = _gp(user.global_position)
	var dir = _flat(c["aim"] - o)
	var L = 26.0 * s
	var W = 4.5 * s
	var n = 14
	var hitlist: Array = [user]
	var dmg: float = c["dmg"]
	var mat = _toon(SAND)
	Sfx.play("earth", o, 0.6)
	for i in n:
		VFX.tree().create_timer(0.05 * i).timeout.connect(func():
			if not is_instance_valid(user):
				return
			var p = _gp(o + dir * (2.0 * s + L * float(i) / n))
			var side = dir.cross(Vector3.UP)
			for k in 3:
				var m = _mi(VFX._sphere(0.5, 12, 6), mat)
				VFX.scene().add_child(m)
				m.global_position = p + side * (k - 1) * W * 0.5 + Vector3.DOWN * s
				m.scale = Vector3(W * 0.7, 0.1, W * 0.6)
				m.rotation = Vector3(0, 0, 0)
				m.look_at(m.global_position + dir, Vector3.UP)
				m.rotate_object_local(Vector3.RIGHT, -0.45)   # dalga öne kıvrılır
				var tw = m.create_tween()
				tw.tween_property(m, "scale", Vector3(W * 0.75, 5.0 * s * randf_range(0.85, 1.2), W * 0.65), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(m, "scale", Vector3(W * 0.85, 1.4 * s, W * 0.75), 0.5)
				_fade_free(m, 3.5)
			VFX.puffs(p + Vector3.UP * 2.0 * s, {"amount": 10, "life": 0.9, "size": 1.2 * s, "radius": W * 0.5, "vmin": 4, "vmax": 9, "dir": Vector3.UP + dir * 0.4, "spread": 35.0,
				"gravity": Vector3(0, -14, 0), "colors": [Color(0.95, 0.85, 0.62, 1), Color(0.82, 0.68, 0.45, 0)]})
			var hits = _hit(user, p + Vector3.UP * s, W, {"dmg": dmg / 3.0, "element": "doton", "knock": 4.0, "kind": "light"}, hitlist)
			for f in hits:
				hitlist.append(f)
				_sand_coffin(f, 2.6, hitlist.size() <= 2))
	_shake(0.4 + 0.1 * s)


## Kum tabutu: hedefi saran kum kabuğu, bağlı kaldığı süre kadar durur sonra dağılır
static func _sand_coffin(f: Node3D, t: float, label := true) -> void:
	_bind(f, t)
	if _is_giant(f):
		return
	var m = _mi(VFX._sphere(0.5, 14, 7), _toon(SAND.darkened(0.05)))
	f.add_child(m)
	m.position = Vector3.UP * float(f.height) * 0.4
	m.scale = Vector3(1.2, 0.05, 1.2) * float(f.height)
	var tw = m.create_tween()
	tw.tween_property(m, "scale", Vector3(0.75, 0.95, 0.75) * float(f.height), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(t * (0.55 if f is Player else 1.0))
	tw.tween_callback(func():
		if is_instance_valid(m):
			VFX.puffs(m.global_position, {"amount": 12, "life": 0.8, "size": 0.7, "radius": 0.6, "vmin": 2, "vmax": 5, "gravity": Vector3(0, -10, 0),
				"colors": [Color(0.95, 0.85, 0.62, 1), Color(0.82, 0.68, 0.45, 0)]})
			m.queue_free())
	if label:
		Combat.popup_text(f.global_position + Vector3.UP * (float(f.height) + 1.0), "KUMA GÖMÜLDÜ!", SAND)


static func _suna_tate(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var r = maxf(2.4 * s, _body_h(user, c) * 0.55) if (c.has("base_h") or _is_giant(user)) else 2.4 * s
	var dur = 7.0
	var dome = _mi(VFX._sphere(0.5, 24, 12), _glass(SAND, 0.32, 0.15))
	var root = Node3D.new()
	VFX.scene().add_child(root)
	root.add_child(dome)
	dome.scale = Vector3.ONE * 0.1
	var tw = dome.create_tween()
	tw.tween_property(dome, "scale", Vector3(r * 2.0, r * 1.7, r * 2.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.burst(Vector3.ZERO, {"amount": 60, "life": dur, "size": 0.3 * r, "radius": r, "vmin": 0.3, "vmax": 1.2, "gravity": Vector3.ZERO, "parent": root, "local": true,
		"explosive": 0.0, "orbit": 0.4, "colors": [Color(0.95, 0.85, 0.62, 0.9), Color(0.85, 0.7, 0.45, 0.0)]})
	if user is Player:
		Buffs.add("suna_tate", dur, {"armor": 0.5})
	Sfx.play("earth", user.global_position, 0.9)
	var st = {"spin": 0.0}
	var n = _ticker(user.global_position, dur, 0.05, func(_n: Node3D, el: float) -> void:
		if not is_instance_valid(user) or user.is_dead() or not is_instance_valid(root):
			return
		var cpos = user.global_position + Vector3.UP * r * 0.55
		root.global_position = cpos
		st["spin"] += 0.08
		dome.rotation.y = st["spin"]
		# gelen düşman mermilerini kum yutar
		for pr in VFX.tree().get_nodes_in_group("projectiles"):
			if pr is Projectile and not pr.dead and pr.shooter != user and is_instance_valid(pr.shooter) and Combat.hostile(user, pr.shooter):
				if pr.global_position.distance_to(cpos) < r * 1.05:
					VFX.puffs(pr.global_position, {"amount": 10, "life": 0.6, "size": 0.6 * s, "radius": 0.5, "vmin": 2, "vmax": 5,
						"colors": [Color(0.95, 0.85, 0.62, 1), Color(0.82, 0.68, 0.45, 0)]})
					Sfx.play("block", pr.global_position, 0.7)
					pr.queue_free()
		if el >= dur - 0.1:
			root.queue_free())
	n.tree_exited.connect(func():
		if is_instance_valid(root):
			root.queue_free())


# ================================================================== MATATABI — mavi alev kedisi
const BLUE := Color(0.3, 0.5, 1.0)


static func _claw_marks(pos: Vector3, dir: Vector3, s: float, preset := "blue") -> void:
	var side = dir.cross(Vector3.UP).normalized()
	for k in 3:
		var bm = BoxMesh.new()
		bm.size = Vector3(0.12, 0.12, 1.0)
		var m = _mi(bm, VFX.mat_fire(preset, 3.0, 2.0, 0.2, 1.6, 0.05))
		VFX.scene().add_child(m)
		var p = pos + side * (k - 1) * 0.9 * s
		m.global_transform = Transform3D(Basis.looking_at((dir + Vector3.DOWN * 0.6 + side * 0.25).normalized(), Vector3.UP), p)
		m.scale = Vector3(1.0 * s, 1.0 * s, 0.1)
		var tw = m.create_tween()
		tw.tween_property(m, "scale", Vector3(1.4 * s, 0.6 * s, 7.0 * s), 0.12).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "scale", Vector3(0.05, 0.05, 8.0 * s), 0.25)
		tw.tween_callback(m.queue_free)
	VFX.cracks(_gp(pos), 3.5 * s, Color(0.05, 0.08, 0.2, 0.9), 5.0)


static func _neko_pounce(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var tgt = _pick(user, c, 30.0 * s)
	var to: Vector3 = tgt.global_position if tgt else c["aim"]
	var d = _flat(to - user.global_position)
	var dist = minf(user.global_position.distance_to(to), 28.0 * s)
	var end = _gp(user.global_position + d * maxf(dist - 1.2 * s, 2.0))
	var dmg: float = c["dmg"]
	Sfx.play("whoosh", user.global_position, 0.7)
	var st = {"r": 0.0}
	var step = func(_k: float, p: Vector3) -> void:
		st["r"] += 1
		if int(st["r"]) % 2 == 0:
			VFX.puffs(p + Vector3.UP * s, {"amount": 4, "life": 0.5, "size": 0.9 * s, "radius": 0.4 * s, "vmin": 0.5, "vmax": 2,
				"colors": [Color(0.9, 1, 1, 1), BLUE, Color(0.1, 0.2, 0.8, 0)], "glow": 1.4, "hot": 0.6})
	var land = func(p: Vector3) -> void:
		_claw_marks(p + d * 1.5 * s + Vector3.UP * 1.2 * s, d, s)
		_hit(user, p + d * 1.8 * s + Vector3.UP * s, 3.8 * s, {"dmg": dmg, "element": "katon", "burn": 3.0, "knock": 16.0, "launch": 5.0, "kind": "heavy", "dir": d, "hitstop": 0.07})
		VFX.shockwave(p + Vector3.UP * 0.1, BLUE.lightened(0.4), 6.0 * s, 0.35)
		Sfx.play("hit_heavy", p, 0.9)
		_shake(0.35)
	_move(user, end, 0.5, 5.0 * s, step, land)


## Yerde uzun süre yanan mavi alev öbeği
static func _blue_patch(user: Node3D, pos: Vector3, s: float, dps: float, dur := 6.0, preset := "blue") -> void:
	if _fields >= MAX_FIELDS:
		return
	var gp = _gp(pos)
	var col = BLUE if preset == "blue" else Color(1.0, 0.45, 0.1)
	VFX.linger(gp, "katon", col, 1.15 * s, dur)
	_ticker(gp, dur, 0.5, func(_n: Node3D, _e: float) -> void:
		_hit(user, gp + Vector3.UP * s, 2.4 * s, {"dmg": dps * 0.5, "element": "katon", "burn": 2.0, "knock": 0.0, "kind": "light"}))


static func _aobi_dama(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var aim: Vector3 = c["aim"]
	var dmg: float = c["dmg"]
	Sfx.play("fire", from, 0.8)
	for i in 5:
		VFX.tree().create_timer(0.09 * i).timeout.connect(func():
			if not is_instance_valid(user):
				return
			var side = _flat(aim - from).cross(Vector3.UP)
			var tg = aim + side * (i - 2) * 3.0 * s + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * s
			var tt = clampf(from.distance_to(tg) / 45.0, 0.45, 1.4)
			var g = 22.0
			var vel = (tg - from) / tt + Vector3.UP * g * tt * 0.5
			var oh = func(pos: Vector3, _t: Node3D) -> void:
				VFX.explosion(pos, 0.6 * s, BLUE)
				_blue_patch(user, pos, s, dmg * 0.12)
			_shot(user, from, vel, 0.7 * s, {"dmg": dmg * 0.45, "element": "katon", "burn": 3.0, "knock": 10.0, "launch": 3.0, "kind": "heavy"}, VFX.fireball(0.8 * s, "blue"), oh, g, 3.0))


static func _kaen_breath(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var dmg: float = c["dmg"]
	var dur = 1.6
	var aim: Vector3 = c["aim"]
	var fixed_from: Vector3 = c["from"]
	Sfx.play("fire", fixed_from, 0.6)
	if user is Player:
		user.input_locked = maxf(user.input_locked, dur)
	var hitc = {"n": 0}
	var jet = _stream(VFX.mat_fire("blue", 4.0, 2.2, 0.35, 1.5, 0.12, Vector3(0, 1, 0), true), 3.2 * s)
	var tk = _ticker(fixed_from, dur, 0.04, func(_n: Node3D, el: float) -> void:
		if not is_instance_valid(user):
			return
		var from = _live_from(user, c, s)
		var dir = (aim - from).normalized()
		_aim_stream(jet, from + dir * 0.6 * s, dir, 17.0 * s * minf(1.0, el / 0.2), clampf(minf(el / 0.15, (dur - el) / 0.2), 0.05, 1.0))
		if int(el / 0.04) % 2 == 1:
			return
		VFX.puffs(from + dir * 6.0 * s, {"amount": 6, "life": 0.5, "size": 1.0 * s, "radius": 0.6 * s, "vmin": 16.0 * sqrt(s), "vmax": 26.0 * sqrt(s), "dir": dir, "spread": 14.0,
			"damp": 0.5, "gravity": Vector3(0, 3, 0), "colors": [Color(0.6, 0.9, 1, 1), Color(0.25, 0.5, 1, 1), Color(0.08, 0.15, 0.7, 0)], "glow": 1.4, "hot": 0.4})
		hitc["n"] += 1
		if int(hitc["n"]) % 2 == 0:
			for k in 3:
				var dd = (4.0 + k * 6.0) * s
				_hit(user, from + dir * dd, (1.5 + k * 1.0) * s, {"dmg": dmg * 0.06, "element": "katon", "burn": 3.0, "knock": 2.0, "kind": "light"}))
	tk.tree_exited.connect(func():
		if is_instance_valid(jet):
			jet.queue_free())


# ================================================================== ISOBU — mercan ve su
const CORAL := Color(1.0, 0.55, 0.55)
const CORAL2 := Color(0.45, 0.85, 0.8)


## Mercan dalı: üç kollu sivri mercan + çarpıştırıcı (yol keser)
static func _coral(at: Vector3, h: float, life: float, col: Color) -> Node3D:
	var root = StaticBody3D.new()
	root.collision_layer = 1
	VFX.scene().add_child(root)
	root.global_position = at
	var mat = _toon(col)
	var trunk = _mi(_cone(0.45, 0.12, 1.0, 7), mat)
	trunk.position = Vector3.UP * 0.5
	var arm = Node3D.new()
	arm.add_child(trunk)
	for k in 3:
		var br = _mi(_cone(0.22, 0.03, 0.7, 6), mat)
		var a = k * TAU / 3.0 + randf()
		br.position = Vector3(cos(a) * 0.18, 0.45 + k * 0.15, sin(a) * 0.18)
		br.rotation = Vector3(sin(a) * 0.8, 0, -cos(a) * 0.8)
		arm.add_child(br)
	var tip = _mi(VFX._sphere(0.5, 8, 4), _glass(CORAL2.lightened(0.3), 0.85, 0.4))
	tip.position = Vector3.UP * 1.0
	tip.scale = Vector3.ONE * 0.22
	arm.add_child(tip)
	root.add_child(arm)
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = 0.35 * h * 0.5
	sh.height = h
	cs.shape = sh
	cs.position = Vector3.UP * h * 0.5
	root.add_child(cs)
	arm.scale = Vector3(h * 0.5, 0.05, h * 0.5)
	arm.rotation = Vector3(randf_range(-0.2, 0.2), randf() * TAU, randf_range(-0.2, 0.2))
	var tw = arm.create_tween()
	tw.tween_property(arm, "scale", Vector3(h * 0.5, h, h * 0.5), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(life)
	tw.tween_property(arm, "scale", Vector3(h * 0.5, 0.02, h * 0.5), 0.5)
	tw.tween_callback(root.queue_free)
	return root


static func _sango(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var tgt = _pick(user, c, 45.0 * s)
	var center = _gp(tgt.global_position if tgt else c["aim"])
	var R = 6.5 * s
	var dmg: float = c["dmg"]
	Sfx.play("earth", center, 1.2)
	VFX.cracks(center, R * 1.2, Color(0.12, 0.2, 0.22, 0.9), 8.0)
	for i in 12:
		VFX.tree().create_timer(0.03 * i).timeout.connect(func():
			var a = randf() * TAU
			var rr = R * sqrt(randf())
			var p = _gp(center + Vector3(cos(a), 0, sin(a)) * rr)
			_coral(p + Vector3.DOWN * 0.3 * s, randf_range(2.2, 4.2) * s, 8.0, CORAL if i % 3 else CORAL2))
	VFX.puffs(center + Vector3.UP * s, {"amount": 20, "life": 0.9, "size": 1.0 * s, "radius": R * 0.6, "vmin": 3, "vmax": 9, "dir": Vector3.UP, "spread": 50.0,
		"gravity": Vector3(0, -16, 0), "colors": [Color(0.9, 1, 1, 1), Color(0.5, 0.85, 1, 1), Color(0.3, 0.6, 1, 0)]})
	var hits = _hit(user, center + Vector3.UP * s, R, {"dmg": dmg * 0.75, "element": "suiton", "knock": 3.0, "launch": 6.0, "kind": "heavy"})
	for f in hits:
		_bind(f, 3.0)
		if not _is_giant(f):
			for k in 5:
				var a2 = k * TAU / 5.0
				var cr = _mi(_cone(0.25, 0.02, 1.0, 6), _glass(CORAL2.lightened(0.2), 0.9, 0.5))
				f.add_child(cr)
				cr.position = Vector3(cos(a2) * 0.45, float(f.height) * 0.45, sin(a2) * 0.45)
				cr.rotation = Vector3(sin(a2) * 0.5, 0, -cos(a2) * 0.5)
				cr.scale = Vector3(1, float(f.height) * 0.9, 1)
				_fade_free(cr, 2.8, false)
			Combat.popup_text(f.global_position + Vector3.UP * (float(f.height) + 1.0), "MERCANA HAPSOLDU!", CORAL2)


## Dikenli dönen kabuk görseli (yuvarlanma)
static func _spike_shell(parent: Node3D, r: float, col: Color) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	var body = _mi(VFX._sphere(0.5, 18, 9), _toon(col))
	body.scale = Vector3.ONE * r * 2.0
	root.add_child(body)
	for k in 14:
		var dirv = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var sp = _mi(_cone(0.18, 0.0, 1.0, 5), _toon(Color(0.92, 0.9, 0.82)))
		sp.position = dirv * r
		sp.look_at_from_position(dirv * r, dirv * r * 2.0, Vector3.UP if absf(dirv.y) < 0.9 else Vector3.RIGHT)
		sp.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		sp.scale = Vector3(r, r * 0.7, r)
		root.add_child(sp)
	return root


static func _shell_roll(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var d = _flat(c["aim"] - user.global_position)
	var end = _gp(user.global_position + d * 30.0 * s)
	var dmg: float = c["dmg"]
	# tam dönüşümde (ya da dev canavarın kendisinde) gövde modeli gizlenir, kabuk topu gövde boyunda olur
	var rig: Node3D = null
	if user is Player:
		var cl = user.combat.modes.cloak
		if cl != null and cl.level == 6 and is_instance_valid(cl.rig):
			rig = cl.rig
	elif "rig" in user and is_instance_valid(user.rig):
		rig = user.rig
	var R = 1.3 * s
	if rig != null:
		R = maxf(R, float(rig.height_m) * 0.42)
		rig.visible = false
	var shell: Node3D = BeastIsobu.shell_ball(R)   # Isobu'nun kendi kabuğu (model ile aynı)
	VFX.scene().add_child(shell)
	shell.rotation.y = atan2(-d.x, -d.z)
	var hitlist: Array = [user]
	Sfx.play("whoosh", user.global_position, 0.5)
	var st = {"n": 0}
	var mv = true
	if user is Player:
		mv = user.model.visible
		user.model.visible = false
	var step = func(_k: float, p: Vector3) -> void:
		if is_instance_valid(shell):
			shell.global_position = p + Vector3.UP * R
			shell.rotate(d.cross(Vector3.UP).normalized(), -0.45)
		st["n"] += 1
		if int(st["n"]) % 3 == 0:
			if int(st["n"]) % 9 == 0:
				VFX.splash(_gp(p - d * 2.0 * s), 0.6 * s)
			var hits = _hit(user, p + Vector3.UP * maxf(s, R * 0.6), maxf(2.6 * s, R * 1.3), {"dmg": dmg * 0.7, "element": "suiton", "knock": 30.0, "launch": 9.0, "kind": "heavy", "dir": d, "hitstop": 0.05}, hitlist)
			hitlist.append_array(hits)
	var done = func(p: Vector3) -> void:
		if is_instance_valid(shell):
			shell.queue_free()
		if is_instance_valid(user) and user is Player:
			user.model.visible = mv
		if is_instance_valid(rig):
			rig.visible = true
		VFX.splash(_gp(p + d * 2.0 * s), 1.4 * s)
		_shake(0.4)
	_move(user, end, 0.9, 0.0, step, done)


static func _kiri_genjutsu(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var center = _gp(c["aim"] if user is Player or not _is_giant(user) else user.global_position)
	var R = 13.0 * s
	var dur = 8.0
	Sfx.play("genjutsu", center, 0.7)
	var fooled := {}
	_fog(center, R, Color(0.75, 0.95, 0.95), 0.42, dur)
	VFX.puffs(center + Vector3.UP * 1.5 * s, {"amount": 20, "life": 2.2, "size": 3.0 * s, "radius": R * 0.8, "vmin": 0.2, "vmax": 1.0, "gravity": Vector3.ZERO,
		"colors": [Color(0.85, 0.97, 0.97, 0.8), Color(0.78, 0.95, 0.95, 0.7), Color(0.7, 0.9, 0.92, 0.0)], "glow": 1.0})
	_ticker(center, dur, 0.5, func(_n: Node3D, el: float) -> void:
		if fmod(el, 1.5) < 0.25:
			VFX.puffs(center + Vector3.UP * 1.5 * s, {"amount": 20, "life": 2.2, "size": 3.0 * s, "radius": R * 0.8, "vmin": 0.2, "vmax": 1.0, "gravity": Vector3.ZERO,
				"colors": [Color(0.85, 0.97, 0.97, 0.8), Color(0.78, 0.95, 0.95, 0.7), Color(0.7, 0.9, 0.92, 0.0)], "glow": 1.0})
		for f in _foes(user, center + Vector3.UP * s, R):
			f.apply_status("slow", 1.0)
			if f is Player:
				_tint(Color(0.55, 0.85, 0.85, 0.35), 0.6)
				if randf() < 0.2:
					f.apply_status("stun", 0.4)   # yanılsama: sendeleme
			elif f.has_method("lose_target"):
				f.lose_target(1.0)
				if not fooled.has(f):
					fooled[f] = true
					Combat.popup_text(f.global_position + Vector3.UP * (float(f.height) + 1.0), "YANILSAMA!", CORAL2))


# ================================================================== SON GOKŪ — lav
const LAVA := Color(1.0, 0.42, 0.08)


## Lav gölü: yerde parlayan lav + alev dilleri, içine basan yanar
static func _lava_pool(user: Node3D, pos: Vector3, s: float, dps: float, dur := 7.0) -> void:
	if _fields >= MAX_FIELDS:
		return
	var gp = _gp(pos)
	var disc = _mi(VFX._sphere(0.5, 20, 6), VFX.lava_mat("molten", true))   # sarı-turuncu erimiş lav, içinde kırık kaya
	VFX.scene().add_child(disc)
	disc.global_position = gp + Vector3.UP * 0.05
	disc.scale = Vector3(0.2, 0.05, 0.2)
	var tw = disc.create_tween()
	tw.tween_property(disc, "scale", Vector3(5.0 * s, 0.12 * s, 5.0 * s), 0.3)
	_fade_free(disc, dur, false)
	VFX.linger(gp, "yoton", LAVA, 1.3 * s, dur)
	_ticker(gp, dur, 0.5, func(_n: Node3D, _e: float) -> void:
		for f in _hit(user, gp + Vector3.UP * 0.5 * s, 2.5 * s, {"dmg": dps * 0.5, "element": "yoton", "burn": 2.5, "knock": 0.0, "kind": "light"}):
			f.apply_status("slow", 0.6))


static func _kakogan(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var aim: Vector3 = c["aim"]
	var dmg: float = c["dmg"]
	Sfx.play("fire", from, 0.5)
	for i in 5:
		VFX.tree().create_timer(0.12 * i).timeout.connect(func():
			if not is_instance_valid(user):
				return
			var tg = aim + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 5.0 * s
			var tt = clampf(from.distance_to(tg) / 40.0, 0.5, 1.6)
			var g = 26.0
			var vel = (tg - from) / tt + Vector3.UP * g * tt * 0.5
			var vis = VFX.lava_ball(1.1 * s)   # ateş topu değil: pürüzlü lav kayası
			var oh = func(pos: Vector3, _t: Node3D) -> void:
				VFX.lava_splash(pos, 0.9 * s)
				VFX.debris(pos, Color(0.25, 0.12, 0.08), 8, 9.0, 0.35 * s)
				_lava_pool(user, pos, s * 0.8, dmg * 0.14)
			_shot(user, from, vel, 0.6 * s, {"dmg": dmg * 0.5, "element": "yoton", "burn": 3.0, "knock": 12.0, "launch": 4.0, "kind": "heavy"}, vis, oh, g, 3.5))


static func _funkatsu(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var tgt = _pick(user, c, 45.0 * s)
	var center = _gp(tgt.global_position if tgt else c["aim"])
	var dmg: float = c["dmg"]
	var pts = [center]
	for i in 5:
		var a = randf() * TAU
		pts.append(_gp(center + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 8.0) * s))
	for i in pts.size():
		var p: Vector3 = pts[i]
		VFX.tree().create_timer(0.14 * i).timeout.connect(func():
			VFX.cracks(p, 3.0 * s, Color(1.0, 0.45, 0.05, 0.95), 3.0))
		VFX.tree().create_timer(0.14 * i + 0.45).timeout.connect(func():
			if not is_instance_valid(user):
				return
			# yerden fışkıran lav sütunu: koni mesh/alev yok — yapışkan lav seli yukarı fışkırır, lav parçaları ve kırık kaya saçılır
			PathJutsu.get_pinst().stream_fx(p, Vector3.UP, 11.0 * s, 1.4 * s, VFX.mat_water(Color(0.45, 0.08, 0.02), Color(1.0, 0.45, 0.1), Color(1.0, 0.85, 0.4), Vector3.UP, 1.0, 0.7, 0.15), 0.5)
			VFX.debris(p + Vector3.UP, Color(0.22, 0.12, 0.08), 10, 14.0, 0.4 * s)
			VFX.goo_drops(p + Vector3.UP * 4.0 * s, "molten", 10, 1.4 * s, 10.0)
			_hit(user, p + Vector3.UP * 1.5 * s, 2.6 * s, {"dmg": dmg * 0.4, "element": "yoton", "burn": 4.0, "knock": 4.0, "launch": 18.0, "kind": "heavy"})
			Sfx.play("boom", p, 1.1)
			_shake(0.3))


static func _yoton_yoroi(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var dur = 8.0
	var dmg: float = c["dmg"]
	var root = Node3D.new()
	user.add_child(root)
	var h = _body_h(user, c)
	var big = c.has("base_h") or _is_giant(user)
	for k in 7:
		# lav zırhı: alev dilleri değil — bedene yapışmış pürüzlü erimiş lav kütleleri (içinde kırık kaya)
		var lb = MB.new()
		lb.add("boulder", Vector3.ZERO, Vector3.ONE, Color.WHITE, Vector3.ZERO, k % 6)
		var t = _mi(lb.build(null), VFX.lava_mat("molten"))
		var a = k * TAU / 7.0
		t.position = Vector3(cos(a) * 0.45 * s, h * (0.2 + 0.1 * (k % 3)), sin(a) * 0.45 * s)
		t.position = Vector3(cos(a) * (0.45 * s if not big else h * 0.3), h * (0.2 + 0.1 * (k % 3)), sin(a) * (0.45 * s if not big else h * 0.3))
		t.scale = Vector3(0.6, 1.4, 0.6) * (s * 0.7 if not big else h * 0.25)
		root.add_child(t)
	if user is Player:
		Buffs.add("yoton_yoroi", dur, {"armor": 0.6, "melee": 1.3})
	Sfx.play("fire", user.global_position, 0.5)
	VFX.shockwave(_gp(user.global_position) + Vector3.UP * 0.1, LAVA, 5.0 * s, 0.4)
	_ticker(user.global_position, dur, 0.4, func(_n: Node3D, el: float) -> void:
		if not is_instance_valid(user):
			return
		VFX.goo_drops(user.global_position + Vector3.UP * h * 0.6, "molten", 1, s * 0.8, 1.5)   # zırhtan damlayan lav
		_hit(user, user.global_position + Vector3.UP * h * 0.5, maxf(2.3 * s, h * 0.45 if big else 0.0), {"dmg": dmg * 0.05, "element": "yoton", "burn": 3.0, "knock": 3.0, "kind": "light"})
		if el >= dur - 0.4 and is_instance_valid(root):
			root.queue_free())


# ================================================================== KOKUŌ — buhar (Futton)
const STEAM := Color(0.97, 0.95, 0.92)


static func _steam_cloud(pos: Vector3, s: float, R: float, life: float) -> void:
	VFX.puffs(pos, {"amount": 22, "life": life, "size": 2.6 * s, "radius": R * 0.7, "vmin": 0.8, "vmax": 2.5, "dir": Vector3.UP, "spread": 60.0, "gravity": Vector3(0, 1.5, 0),
		"colors": [Color(1, 1, 1, 0.85), Color(1, 0.97, 0.95, 0.75), Color(0.95, 0.92, 0.9, 0.0)], "glow": 1.0, "outline_col": Color(0.55, 0.5, 0.55)})


static func _futton_boil(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var tgt = _pick(user, c, 45.0 * s)
	var center = _gp(tgt.global_position if tgt else c["aim"])
	var R = 8.0 * s
	var dur = 7.0
	var dmg: float = c["dmg"]
	Sfx.play("water", center, 0.5)
	VFX.shockwave(center + Vector3.UP * 0.2, STEAM, R * 2.0, 0.5)
	_fog(center, R, Color(1.0, 0.95, 0.93), 0.5, dur)
	_steam_cloud(center + Vector3.UP * s, s, R, 1.8)
	_ticker(center, dur, 0.5, func(_n: Node3D, el: float) -> void:
		if fmod(el, 1.0) < 0.25:
			_steam_cloud(center + Vector3.UP * s, s, R, 1.8)
		for f in _hit(user, center + Vector3.UP * s, R, {"dmg": dmg * 0.07, "element": "futton", "knock": 0.0, "kind": "light"}):
			f.apply_status("slow", 0.8)
			_corrode(f, 4.0, dmg * 0.05, Color(1.0, 0.75, 0.6), "HAŞLANIYOR!"))


static func _horn_ram(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var d = _flat(c["aim"] - user.global_position)
	var end = _gp(user.global_position + d * 32.0 * s)
	var dmg: float = c["dmg"]
	var hitlist: Array = [user]
	Sfx.play("whoosh", user.global_position, 0.45)
	var st = {"n": 0}
	var step = func(_k: float, p: Vector3) -> void:
		st["n"] += 1
		if int(st["n"]) % 2 == 0:
			_steam_cloud(p - d * 2.0 * s + Vector3.UP * s, s * 0.6, 2.0 * s, 0.9)
		var hits = _hit(user, p + d * 1.5 * s + Vector3.UP * s, 2.8 * s, {"dmg": dmg, "element": "futton", "knock": 45.0, "launch": 12.0, "kind": "heavy", "dir": d, "hitstop": 0.1}, hitlist)
		if not hits.is_empty():
			hitlist.append_array(hits)
			VFX.star(p + d * 2.0 * s + Vector3.UP * s, STEAM, 3.0 * s, 0.18)
			_shake(0.6)
	var done = func(p: Vector3) -> void:
		_steam_cloud(p + Vector3.UP * s, s, 4.0 * s, 1.4)
	_move(user, end, 0.6, 0.0, step, done)


static func _steam_burst(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = user.global_position + Vector3.UP * s
	var R = 8.0 * s
	var dmg: float = c["dmg"]
	FX.flash_sphere(o, STEAM, 3.0 * s, 0.3)
	VFX.shockwave(_gp(o) + Vector3.UP * 0.2, STEAM, R * 2.2, 0.45)
	VFX.shockwave(o, Color(1, 1, 1), R, 0.3, false)
	for k in 3:
		VFX.tree().create_timer(0.08 * k).timeout.connect(func(): _steam_cloud(o, s * (1.0 + k * 0.3), R * (0.4 + k * 0.3), 1.6))
	Sfx.play("boom", o, 1.3)
	for f in _hit(user, o, R, {"dmg": dmg * 0.7, "element": "futton", "knock": 38.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.08}):
		_corrode(f, 3.0, dmg * 0.04, Color(1.0, 0.75, 0.6), "HAŞLANDI!")
	_shake(0.6)


# ================================================================== SAIKEN — asit ve sümük
const ACID := Color(0.75, 1.0, 0.55)
const SLIME := Color(0.62, 0.85, 1.0)


static func _fukuso(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var dmg: float = c["dmg"]
	Sfx.play("water", from, 1.4)
	for i in 8:
		VFX.tree().create_timer(0.07 * i).timeout.connect(func():
			if not is_instance_valid(user):
				return
			var dir = ((c["aim"] - from).normalized() + Vector3(randf_range(-0.35, 0.35), randf_range(0.0, 0.3), randf_range(-0.35, 0.35))).normalized()
			var vis = Node3D.new()
			var b = _mi(VFX._sphere(0.5, 16, 8), _glass(Color(0.85, 1.0, 0.9), 0.45, 0.3))
			b.scale = Vector3.ONE * randf_range(0.9, 1.4) * s
			vis.add_child(b)
			var core = _mi(VFX._sphere(0.5, 8, 4), _glass(ACID, 0.8, 0.8))
			core.scale = Vector3.ONE * 0.3 * s
			vis.add_child(core)
			var oh = func(pos: Vector3, _t: Node3D) -> void:
				VFX.puffs(pos, {"amount": 14, "life": 0.7, "size": 0.7 * s, "radius": 0.5 * s, "vmin": 3, "vmax": 7, "gravity": Vector3(0, -12, 0),
					"colors": [Color(0.95, 1, 0.9, 1), ACID, Color(0.4, 0.8, 0.2, 0)]})
				Sfx.play("water", pos, 1.6, 0.6)
				for f in _hit(user, pos, 2.6 * s, {"dmg": dmg * 0.2, "element": "suiton", "knock": 3.0, "kind": "light"}):
					_corrode(f, 5.0, dmg * 0.06, ACID)
			var pr = _shot(user, from, dir * 13.0 * sqrt(s), 0.6 * s, {"dmg": dmg * 0.3, "element": "suiton", "knock": 4.0, "kind": "light"}, vis, oh, 0.0, 5.0)
			pr.homing = Combat.nearest_enemy(user, 50.0 * s)
			pr.homing_turn = 1.2
			var st = {"t": randf() * 6.0}
			pr.on_tick = func(p: Projectile, dt: float) -> void:
				st["t"] += dt
				vis.scale = Vector3(1.0 + sin(st["t"] * 7.0) * 0.08, 1.0 - sin(st["t"] * 7.0) * 0.08, 1.0)
				p.vel.y += sin(st["t"] * 3.0) * 2.0 * dt)


## Parlak sümük gölü: içindekiler saplanır (çamur), Saiken'in izi
static func _slime(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var center = _gp(c["aim"] if not _is_giant(user) else (user.global_position + _fwd(user) * float(user.height) * 0.6))
	var R = 9.0 * s
	var dur = 9.0
	var dmg: float = c["dmg"]
	var pool = _mi(VFX._sphere(0.5, 24, 6), _glass(SLIME, 0.7, 0.15))
	VFX.scene().add_child(pool)
	pool.global_position = center + Vector3.UP * 0.05
	pool.scale = Vector3(0.5, 0.05, 0.5)
	var tw = pool.create_tween()
	tw.tween_property(pool, "scale", Vector3(R * 2.0, 0.25 * s, R * 2.0), 0.4).set_ease(Tween.EASE_OUT)
	_fade_free(pool, dur, true)
	VFX.splash(center, 2.0 * s)
	Sfx.play("water", center, 0.4)
	_ticker(center, dur, 0.4, func(_n: Node3D, el: float) -> void:
		if randf() < 0.5:
			var a = randf() * TAU
			VFX.puffs(center + Vector3(cos(a), 0.3, sin(a)) * R * randf() * 0.8, {"amount": 3, "life": 0.6, "size": 0.5 * s, "vmin": 0.3, "vmax": 1.0, "gravity": Vector3(0, 1, 0),
				"colors": [Color(0.95, 1, 1, 0.9), Color(0.75, 0.9, 1, 0)]})
		for f in _foes(user, center + Vector3.UP * 0.5, R):
			f.apply_status("mud", 0.6)
			f.apply_status("slow", 0.6)
			if int(el / 0.4) % 4 == 0:
				_hit(user, f.global_position + Vector3.UP, 0.5, {"dmg": dmg * 0.04, "element": "suiton", "knock": 0.0, "kind": "light"}))


static func _acid_mist(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var center = _gp(c["aim"])
	if _is_giant(user):
		center = _gp(user.global_position + _fwd(user) * float(user.height) * 0.5)
	var R = 8.0 * s
	var dur = 6.0
	var dmg: float = c["dmg"]
	Sfx.play("wind", center, 0.6)
	_fog(center, R, Color(0.65, 0.95, 0.4), 0.38, dur)
	var acid_puff = {"amount": 16, "life": 1.8, "size": 2.4 * s, "radius": R * 0.75, "vmin": 0.2, "vmax": 1.2, "gravity": Vector3(0, 0.6, 0),
		"colors": [Color(0.8, 1, 0.6, 0.8), Color(0.7, 0.95, 0.45, 0.6), Color(0.5, 0.8, 0.3, 0.0)], "glow": 1.0, "outline_col": Color(0.2, 0.35, 0.1)}
	VFX.puffs(center + Vector3.UP * 1.5 * s, acid_puff)
	_ticker(center, dur, 0.5, func(_n: Node3D, el: float) -> void:
		if fmod(el, 1.0) < 0.25:
			VFX.puffs(center + Vector3.UP * 1.5 * s, acid_puff)
		for f in _hit(user, center + Vector3.UP * s, R, {"dmg": dmg * 0.06, "element": "suiton", "knock": 0.0, "kind": "light"}):
			_corrode(f, 3.0, dmg * 0.05, ACID))


# ================================================================== CHŌMEI — böcek kanatları ve pul tozu
const SCALE := Color(0.75, 1.0, 0.45)


## Oyuncu kanatlanır: süzülür (düşüş yavaş), Boşluk ile yükselir. TODO: oyuncunun ortak uçuş modu (player.start_flight) gelince ona geçir.
class Flight extends Node:
	var p: Player
	var dur := 7.0
	var t := 0.0
	var wings: Array = []

	func _physics_process(dt: float) -> void:
		if not is_instance_valid(p) or p.is_dead():
			_end()
			return
		t += dt
		for i in wings.size():
			var w: Node3D = wings[i]
			if is_instance_valid(w):
				w.rotation.z = (0.35 + sin(t * 26.0 + i) * 0.45) * (1.0 if i % 2 == 0 else -1.0)
		if not p.grounded:
			if Input.is_action_pressed("jump"):
				p.velocity.y = minf(p.velocity.y + 40.0 * dt, 10.0)
			else:
				p.velocity.y = maxf(p.velocity.y, -1.8)
		if t >= dur:
			_end()

	func _end() -> void:
		for w in wings:
			if is_instance_valid(w):
				w.queue_free()
		queue_free()


static func _hane_flight(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	if user is Player:
		var fl = Flight.new()
		fl.p = user
		VFX.scene().add_child(fl)
		var mat = _glass(Color(0.55, 0.85, 1.0), 0.45, 0.6)
		for k in 4:
			var piv = Node3D.new()
			user.add_child(piv)
			piv.position = Vector3(0, 1.35 - (k / 2) * 0.25, 0.18)
			var wing = _mi(VFX._sphere(0.5, 10, 5), mat)
			var sx = -1.0 if k % 2 == 0 else 1.0
			wing.position = Vector3(sx * 0.9, 0.15, 0.15)
			wing.scale = Vector3(1.7, 0.05, 0.6) * (1.0 - (k / 2) * 0.25) * minf(s, 2.0)
			piv.add_child(wing)
			fl.wings.append(piv)
		user.velocity.y = 12.0
		Buffs.add("hane", 7.0, {"speed": 1.35})
		Sfx.play("wind", user.global_position, 1.5)
		VFX.puffs(user.global_position, {"amount": 14, "life": 0.6, "size": 0.8, "radius": 1.0, "vmin": 4, "vmax": 8, "dir": Vector3.DOWN, "spread": 60.0,
			"colors": [Color(0.9, 1, 0.8, 0.8), Color(0.7, 0.95, 0.5, 0)]})
		return
	# dev Chōmei / düşman: havaya yükselir, sonra hedefe dalış
	var tgt = _pick(user, c, 60.0 * s)
	var to = _gp(tgt.global_position if tgt else c["aim"])
	var up = user.global_position + Vector3.UP * 8.0 * s
	var dmg: float = c["dmg"]
	Sfx.play("wind", user.global_position, 0.6)
	VFX.puffs(_gp(user.global_position) + Vector3.UP, {"amount": 24, "life": 1.0, "size": 2.0 * s, "radius": 3.0 * s, "vmin": 6, "vmax": 14, "dir": Vector3.UP, "spread": 70.0,
		"colors": [Color(0.9, 1, 0.8, 0.8), Color(0.7, 0.95, 0.5, 0)]})
	var tw = user.create_tween()
	tw.tween_property(user, "global_position", up, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(user, "global_position", to, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		VFX.shockwave(to + Vector3.UP * 0.2, SCALE, 14.0 * s, 0.5)
		VFX.puffs(to + Vector3.UP * s, {"amount": 26, "life": 1.2, "size": 2.0 * s, "radius": 3.0 * s, "vmin": 6, "vmax": 14, "dir": Vector3.UP, "spread": 80.0,
			"gravity": Vector3(0, -4, 0), "colors": [Color(0.85, 0.8, 0.65, 0.9), Color(0.7, 0.62, 0.5, 0)]})
		_hit(user, to + Vector3.UP * s, 6.0 * s, {"dmg": dmg, "element": "fuuton", "knock": 34.0, "launch": 10.0, "kind": "heavy"})
		Sfx.play("boom", to, 0.6)
		_shake(1.0))


static func _rinpun(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var dir = (c["aim"] - from).normalized()
	var R = 16.0 * s
	var dmg: float = c["dmg"]
	Sfx.play("wind", from, 1.3)
	FX.burst(from, {"amount": 90, "life": 0.9, "tex": FX.tex_spark, "add": true, "size": 0.35 * s, "radius": 0.6 * s, "vmin": 10.0 * sqrt(s), "vmax": 22.0 * sqrt(s),
		"dir": dir, "spread": 28.0, "damp": 1.2, "gravity": Vector3.ZERO, "colors": [Color(1, 1, 0.85, 1), SCALE, Color(0.5, 1, 0.3, 0)]})
	VFX.tree().create_timer(0.35).timeout.connect(func():
		if not is_instance_valid(user):
			return
		var ctr = from + dir * R * 0.6
		VFX.star(ctr, Color(1, 1, 0.85), 7.0 * s, 0.25)
		FX.light(ctr, Color(1, 1, 0.8), 14.0, 30.0 * s, 0.35)
		VFX.shockwave(ctr, Color(1, 1, 0.85), 10.0 * s, 0.3, false)
		Sfx.play("chidori", ctr, 1.6, 0.6)
		for f in _hit(user, ctr, R * 0.6, {"dmg": dmg * 0.4, "element": "fuuton", "knock": 4.0, "kind": "light"}):
			_blind(f, 3.0))


static func _mushi_swarm(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var dmg: float = c["dmg"]
	var tgt = _pick(user, c, 50.0 * s)
	Sfx.play("wind", from, 1.8, 0.7)
	for i in 14:
		VFX.tree().create_timer(0.04 * i).timeout.connect(func():
			if not is_instance_valid(user):
				return
			var dir = ((c["aim"] - from).normalized() + Vector3(randf_range(-0.6, 0.6), randf_range(-0.2, 0.5), randf_range(-0.6, 0.6))).normalized()
			var vis = Projectile.energy_mesh(Color(0.9, 1, 0.6), Color(0.15, 0.4, 0.1), 0.35 * sqrt(s), 6.0, 0.0, 1.6)
			var oh = func(pos: Vector3, t: Node3D) -> void:
				FX.hit_spark(pos, SCALE, 0.5)
				if t and is_instance_valid(user) and user is Player:
					user.chakra = minf(user.max_chakra, user.chakra + 1.5)   # böcekler chakra emip getirir
			var pr = _shot(user, from, dir * 28.0, 0.35 * s, {"dmg": dmg * 0.08, "element": "fuuton", "knock": 1.0, "kind": "light"}, vis, oh, 0.0, 3.5)
			pr.homing = tgt if tgt else Combat.nearest_enemy(user, 50.0 * s)
			pr.homing_turn = 4.0
			var st = {"t": randf() * 10.0}
			pr.on_tick = func(p: Projectile, dt: float) -> void:
				st["t"] += dt
				var side = p.vel.cross(Vector3.UP).normalized()
				p.vel += side * sin(st["t"] * 14.0) * 40.0 * dt + Vector3.UP * cos(st["t"] * 11.0) * 20.0 * dt)


# ================================================================== GYŪKI — mürekkep ve dokunaçlar
const INK := Color(0.05, 0.03, 0.08)
const TENTACLE := Color(0.55, 0.35, 0.4)


static func _ink_puddle(pos: Vector3, s: float, dur: float) -> void:
	var gp = _gp(pos)
	var pd = _mi(VFX._sphere(0.5, 18, 5), _glass(Color(0.06, 0.04, 0.1), 0.92, 0.0))
	VFX.scene().add_child(pd)
	pd.global_position = gp + Vector3.UP * 0.04
	pd.scale = Vector3(4.0 * s, 0.08, 3.4 * s)
	pd.rotation.y = randf() * TAU
	_fade_free(pd, dur, true)


static func _sumi(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var aim: Vector3 = c["aim"]
	var dur = 1.2
	var dmg: float = c["dmg"]
	var fixed_from: Vector3 = c["from"]
	if user is Player:
		user.input_locked = maxf(user.input_locked, dur)
	Sfx.play("water", fixed_from, 0.6)
	var blinded := {}
	var jet = _stream(VFX.mat_fire("black", 4.5, 2.6, 0.3, 1.0, 0.1, Vector3(0, 1, 0), true), 2.4 * s)
	var tk = _ticker(fixed_from, dur, 0.08, func(_n: Node3D, el: float) -> void:
		if not is_instance_valid(user):
			return
		var from = _live_from(user, c, s)
		var dir = (aim - from).normalized()
		_aim_stream(jet, from + dir * 0.5 * s, dir, 20.0 * s * minf(1.0, el / 0.2), clampf(minf(el / 0.15, (dur - el) / 0.2), 0.05, 1.0))
		VFX.puffs(from + dir * s, {"amount": 7, "life": 0.6, "size": 1.0 * s, "radius": 0.3 * s, "vmin": 24.0 * sqrt(s), "vmax": 34.0 * sqrt(s), "dir": dir, "spread": 9.0,
			"damp": 0.4, "gravity": Vector3(0, -6, 0), "colors": [Color(0.12, 0.08, 0.18, 1), Color(0.05, 0.03, 0.08, 1), Color(0.02, 0.01, 0.03, 0)], "glow": 0.6,
			"outline_col": Color(0.4, 0.25, 0.5)})
		if fmod(el, 0.4) < 0.08:
			_ink_puddle(from + dir * randf_range(8.0, 18.0) * s, s * 0.8, 6.0)
		for k in 3:
			var dd = (5.0 + k * 6.0) * s
			for f in _hit(user, from + dir * dd, (1.4 + k * 0.9) * s, {"dmg": dmg * 0.04, "element": "suiton", "knock": 1.0, "kind": "light"}):
				f.apply_status("slow", 3.0)
				if not blinded.has(f):
					blinded[f] = true
					_blind(f, 2.5, Color(0.02, 0.0, 0.05, 0.8)))
	tk.tree_exited.connect(func():
		if is_instance_valid(jet):
			jet.queue_free())


static func _tako_ude(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var tgt = _pick(user, c, 32.0 * s)
	var dmg: float = c["dmg"]
	var base_fn = func() -> Vector3:
		if not is_instance_valid(user):
			return Vector3.ZERO
		if c.has("base_h"):
			return user.global_position + Vector3.UP * float(c["base_h"]) * 0.7
		if _is_giant(user):
			return user.global_position + Vector3.UP * float(user.height) * 0.3
		return user.global_position + Vector3.UP * 1.0 * minf(s, 3.0) - _fwd(user) * 0.3 * s
	var tip_to: Vector3 = c["aim"] if tgt == null else tgt.global_position
	Sfx.play("whoosh", user.global_position, 0.6)
	var grab = func(tip: Vector3) -> Node3D:
			var hits = _hit(user, tip, 2.2 * s, {"dmg": dmg * 0.25, "element": "raiton", "knock": 0.0, "kind": "light"})
			FX.hit_spark(tip, Color(1, 0.8, 0.9), 1.2 * s)
			for f in hits:
				if not _is_giant(f):
					_bind(f, 1.0)
					return f
			return null
	var slam = func(g: Node3D) -> void:
			if not is_instance_valid(user):
				return
			# Lariat: yakalananı yere çarp
			var p = user.global_position + _fwd(user) * 2.5 * s
			if g and is_instance_valid(g):
				p = g.global_position
			VFX.shockwave(_gp(p) + Vector3.UP * 0.1, Color(0.85, 0.7, 1.0), 8.0 * s, 0.4)
			VFX.cracks(_gp(p), 4.0 * s)
			VFX.debris(_gp(p), Color(0.45, 0.38, 0.3), 12, 12.0, 0.4 * s)
			_hit(user, p + Vector3.UP * s, 3.5 * s, {"dmg": dmg * 0.5, "element": "raiton", "knock": 26.0, "launch": 14.0, "kind": "heavy", "hitstop": 0.12})
			Combat.popup_text(p + Vector3.UP * 3.0 * s, "LARIAT!", Color(0.9, 0.6, 1.0))
			Sfx.play("hit_heavy", p, 0.7)
			_shake(0.7)
	_reach(user, base_fn, tgt, tip_to, 0.55 * s, _toon(TENTACLE), grab, slam, 0)


static func _tako_bunshin(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = user.global_position
	VFX.puffs(o + Vector3.UP * 1.5 * s, {"amount": 30, "life": 1.6, "size": 2.4 * s, "radius": 2.0 * s, "vmin": 2, "vmax": 6, "gravity": Vector3(0, 0.5, 0),
		"colors": [Color(0.12, 0.08, 0.18, 1), Color(0.05, 0.03, 0.08, 0.9), Color(0.02, 0.01, 0.03, 0)], "glow": 0.6, "outline_col": Color(0.4, 0.25, 0.5)})
	_ink_puddle(o, s, 6.0)
	Sfx.play("poof", o, 0.8)
	# yakındaki düşmanlar hedefini kaybeder
	for f in _foes(user, o, 30.0 * s):
		if f.has_method("lose_target"):
			f.lose_target(2.5)
		elif f is Player:
			_tint(Color(0.02, 0.0, 0.05, 0.7), 1.2)
	if user is Player:
		for i in 2:
			var cl = ShadowClone.new()
			cl.team = user.team
			cl.look = user.model.look.duplicate()
			cl.life = 10.0
			VFX.scene().add_child(cl)
			cl.global_position = _gp(o + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 2.5)
		var back = _gp(o - user.face_dir() * 12.0)
		_move(user, back, 0.35, 2.0)
		Combat.popup_text(o + Vector3.UP * 3.0, "TAKO BUNSHIN!", Color(0.85, 0.6, 1.0))
	else:
		# dev Gyūki: mürekkep bulutunda yer değiştirir
		var side = _fwd(user).cross(Vector3.UP).normalized() * (1.0 if randf() < 0.5 else -1.0)
		var to = _gp(o + side * 22.0 * s)
		var tw = user.create_tween()
		tw.tween_interval(0.4)
		tw.tween_property(user, "global_position", to, 0.5)


# ================================================================== KURAMA — chakra kolları, kükreme, Bijūdama Rasengan
const FOX := Color(1.0, 0.5, 0.12)


static func _chakra_kaina(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var tgt = _pick(user, c, 36.0 * s)
	var dmg: float = c["dmg"]
	var col: Color = c.get("col", FOX)
	var mat = Projectile.energy_mesh(col.lightened(0.5), col, 1.0, 4.0, 0.0, 1.8).material_override
	var base_fn = func() -> Vector3:
		if not is_instance_valid(user):
			return Vector3.ZERO
		if c.has("base_h"):
			return user.global_position + Vector3.UP * float(c["base_h"])
		if _is_giant(user):
			return user.global_position + Vector3.UP * float(user.height) * 0.45
		return user.global_position + Vector3.UP * 1.3 * minf(s, 3.0) + _fwd(user).cross(Vector3.UP) * 0.4 * s
	var tip_to: Vector3 = c["aim"] if tgt == null else tgt.global_position
	Sfx.play("rasengan", user.global_position, 0.5, 0.6)
	var grab = func(tip: Vector3) -> Node3D:
			var hits = _hit(user, tip, 2.4 * s, {"dmg": dmg * 0.25, "element": "katon", "knock": 0.0, "kind": "light"})
			VFX.star(tip, col.lightened(0.4), 2.5 * s, 0.15)
			for f in hits:
				if not _is_giant(f):
					_bind(f, 1.0)
					return f
			return null
	var slam = func(g: Node3D) -> void:
			if not is_instance_valid(user):
				return
			if g and is_instance_valid(g):
				var p = g.global_position
				VFX.shockwave(_gp(p) + Vector3.UP * 0.1, col, 9.0 * s, 0.4)
				VFX.cracks(_gp(p), 4.5 * s, Color(0.15, 0.06, 0.02, 0.9))
				_hit(user, p + Vector3.UP * s, 3.5 * s, {"dmg": dmg * 0.65, "element": "katon", "burn": 2.0, "knock": 20.0, "launch": 12.0, "kind": "heavy", "hitstop": 0.12})
				Sfx.play("hit_heavy", p, 0.6)
				_shake(0.7)
	_reach(user, base_fn, tgt, tip_to, 0.6 * s, mat, grab, slam, 3, _toon(col.lightened(0.35)))


static func _biju_hoko(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var dir = (c["aim"] - from).normalized()
	var dmg: float = c["dmg"]
	var col: Color = c.get("col", FOX)
	Sfx.play("roar", from, 0.7 if not _is_giant(user) else 0.5)
	_shake(0.8 + s * 0.08)
	for k in 5:
		VFX.tree().create_timer(0.07 * k).timeout.connect(func():
			if not is_instance_valid(user):
				return
			var p = from + dir * (3.0 + k * 5.0) * s
			VFX.shockwave(p, col.lightened(0.3) if k % 2 == 0 else Color(1, 1, 1), (4.0 + k * 3.0) * s, 0.3, true, dir)
			for f in _hit(user, p, (2.0 + k * 1.6) * s, {"dmg": dmg * 0.3, "element": "fuuton", "knock": 40.0, "launch": 6.0, "kind": "heavy", "dir": dir}):
				if not _is_giant(f):
					f.apply_status("stun", 1.0 if not f is Player else 0.4))
	if user is Player:
		VFX.screen_lines(0.4, 0.8, col.lightened(0.5))


static func _bijudama_rasengan(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var from: Vector3 = c["from"]
	var dir = (c["aim"] - from).normalized()
	var dmg: float = c["dmg"]
	var col: Color = c.get("col", FOX)
	# Bijūdama'nın koyu topu + çevresinde canavar chakrası renginde dönen Rasengan halkası (Naruto: Bijūdama Rasengan)
	var vis = BijudamaFX.ball(1.6 * s)
	var ring = VFX.rasengan(2.3 * s, col.darkened(0.2), col.lightened(0.5))
	ring.scale = Vector3(1.0, 0.35, 1.0)
	vis.add_child(ring)
	Sfx.play("rasengan", from, 0.5)
	BijudamaFX.gather(from, 1.6 * s, 0.35)
	var boom = func(pos: Vector3, _t: Node3D) -> void:
			var R = 9.0 * s
			BijudamaFX.explode(pos, R)
			for k in 3:
				VFX.tree().create_timer(0.15 * k).timeout.connect(func():
					if is_instance_valid(user):
						_hit(user, pos, R, {"dmg": dmg * 0.35, "knock": 30.0 + k * 10.0, "launch": 10.0, "kind": "heavy"}))
	var prb = _shot(user, from + dir * 1.5 * s, dir * 55.0, 1.0 * s, {"dmg": dmg * 0.5, "knock": 20.0, "kind": "heavy"}, vis, boom, 0.0, 4.0)
	BijudamaFX.launch(from + dir * 1.5 * s, dir, 1.6 * s, prb)


# ================================================================== BİJŪ ŌGİ: epik teknikler (tam dönüşüm + vahşi canavar)
## Kullanıcı (2026-11-11): "bijūların havalı skilleri yok, Shukaku ortalığı kuma gömmüyor; tiplerine göre epik skiller, oyuncu da kullanabilsin".
## Her canavar kendi tipinde iki büyük teknik: alanı değiştirir (kum çölü, mavi alev halkası, mercan ormanı, lav yağmuru, buhar,
## asit fırtınası, pul tozu, mürekkep seli, kuyruk darbeleri). Mevcut küçük teknikler büyük ölçekte zincirlenir + kendi alan etkileri.
static func _c2(c: Dictionary, s_mul: float, aim = null) -> Dictionary:
	var d = c.duplicate()
	d["s"] = float(c["s"]) * s_mul
	if aim != null:
		d["aim"] = aim
	return d


static func _later(t: float, user: Node3D, fn: Callable) -> void:
	VFX.tree().create_timer(t).timeout.connect(func():
		if is_instance_valid(user):
			fn.call())


static func _center(user: Node3D, c: Dictionary, rng: float) -> Vector3:
	var tgt = _pick(user, c, rng)
	return _gp(tgt.global_position if tgt else c["aim"])


const SAND_PUFF := [Color(0.95, 0.85, 0.62, 1), Color(0.82, 0.68, 0.45, 0)]


## --- Shukaku: Ryūsa Bakuryū + Sabaku Sōsō — yer kum seline döner, alandaki herkes kuma gömülür, sonra kum sıkışıp ezer
static func _ryusa_soso(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 60.0 * s)
	var R = 13.0 * s
	var dmg: float = c["dmg"]
	var mat = _toon(SAND)
	Sfx.play("earth", ctr, 0.45)
	_shake(0.8)
	for ring in 4:
		_later(0.12 * ring, user, func():
			var rr = R * (0.3 + ring * 0.25)
			var n = 10 + ring * 5
			for i in n:
				var a = TAU * i / n + ring * 0.3
				var p = _gp(ctr + Vector3(cos(a), 0, sin(a)) * rr)
				var m = _mi(VFX._sphere(0.5, 10, 6), mat)
				VFX.scene().add_child(m)
				m.global_position = p + Vector3.DOWN * s
				m.scale = Vector3(2.4, 0.1, 2.4) * s
				var tw = m.create_tween()
				tw.tween_property(m, "scale", Vector3(2.8 * s, 4.5 * s * randf_range(0.7, 1.3), 2.8 * s), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(m, "scale", Vector3(3.2 * s, 0.9 * s, 3.2 * s), 0.6)
				_fade_free(m, 8.0)
			VFX.puffs(ctr + Vector3.UP * 2.0 * s, {"amount": 30, "life": 1.2, "size": 2.0 * s, "radius": rr, "vmin": 5, "vmax": 12, "dir": Vector3.UP, "spread": 50.0,
				"gravity": Vector3(0, -14, 0), "colors": SAND_PUFF}))
	var caught: Array = []
	_later(0.55, user, func():
		for f in _hit(user, ctr + Vector3.UP * s, R, {"dmg": dmg * 0.5, "element": "doton", "knock": 2.0, "kind": "light"}):
			_sand_coffin(f, 4.0, caught.size() < 2)
			caught.append(f))
	_later(2.3, user, func():
		# Sabaku Sōsō: kum sıkışır — gömülenler ezilir
		VFX.shockwave(ctr + Vector3.UP * 0.2, SAND.lightened(0.2), R * 1.6, 0.5)
		Sfx.play("boom", ctr, 0.6)
		_shake(1.0)
		for f in caught:
			if is_instance_valid(f) and not f.is_dead():
				_hit(user, f.global_position + Vector3.UP * float(f.height) * 0.5, 1.2, {"dmg": dmg * 1.4, "element": "doton", "knock": 6.0, "launch": 4.0, "kind": "heavy", "hitstop": 0.12})
				VFX.puffs(f.global_position + Vector3.UP, {"amount": 26, "life": 0.9, "size": 1.0 * s, "radius": 1.0 * s, "vmin": 5, "vmax": 12, "gravity": Vector3(0, -10, 0), "colors": SAND_PUFF})
				Combat.popup_text(f.global_position + Vector3.UP * (float(f.height) + 1.0), "SABAKU SŌSŌ!", SAND))
	# kum çölü: alan uzun süre gevşek kum — içindekiler yavaşlar
	_later(0.7, user, func():
		_ticker(ctr, 9.0, 0.5, func(_n: Node3D, _e: float) -> void:
			for f in _foes(user, ctr + Vector3.UP * 0.5, R):
				f.apply_status("slow", 0.7)
				f.apply_status("mud", 0.7)))


## --- Shukaku: Renkūdan Rensha — art arda beş dev hava mermisi yelpaze gibi
static func _renkudan_rensha(user: Node3D, c: Dictionary) -> void:
	var dir = _flat(c["aim"] - c["from"])
	var side = dir.cross(Vector3.UP)
	for k in 5:
		_later(0.28 * k, user, func():
			var a = c["aim"] + side * (k - 2) * 4.0 * float(c["s"])
			var cc = _c2(c, 1.25, a)
			cc["from"] = _live_from(user, c, float(c["s"]))
			_renkudan(user, cc))


## --- Matatabi: Ao-bi Rinkaku — hedefin çevresine kaçış yolu bırakmayan mavi alev halkası, ortası patlar
static func _aobi_rinkaku(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 60.0 * s)
	var R = 10.0 * s
	var dmg: float = c["dmg"]
	Sfx.play("fire", ctr, 0.5)
	var n = 16
	for i in n:
		_later(0.035 * i, user, func():
			var a = TAU * i / n
			var p = ctr + Vector3(cos(a), 0, sin(a)) * R
			VFX.explosion(_gp(p) + Vector3.UP * s, 0.55 * s, BLUE)
			VFX.linger(_gp(p), "katon", BLUE, 1.2 * s, 9.0))
	# halka: kenardan geçen yanar (alan sayacını tek tek doldurmasın diye tek ticker)
	_ticker(ctr, 9.0, 0.5, func(_n: Node3D, _e: float) -> void:
		for f in _foes(user, ctr + Vector3.UP * s, R + 2.0 * s):
			var d = Vector2(f.global_position.x - ctr.x, f.global_position.z - ctr.z).length()
			if absf(d - R) < 2.6 * s:
				_hit(user, f.global_position + Vector3.UP, 0.8, {"dmg": dmg * 0.12, "element": "katon", "burn": 2.5, "knock": 6.0, "kind": "light"}))
	_later(0.9, user, func():
		VFX.explosion(ctr + Vector3.UP * s, 1.6 * s, BLUE)
		VFX.shockwave(ctr + Vector3.UP * 0.2, BLUE.lightened(0.4), R * 1.5, 0.45)
		_hit(user, ctr + Vector3.UP * s, R * 0.8, {"dmg": dmg * 1.2, "element": "katon", "burn": 5.0, "knock": 10.0, "launch": 8.0, "kind": "heavy"})
		_shake(0.8))


## --- Matatabi: Bakeneko Rengeki — hedefe üç kez art arda mavi alevli sıçrayış
static func _bakeneko_rengeki(user: Node3D, c: Dictionary) -> void:
	for k in 3:
		_later(0.75 * k, user, func():
			var cc = _c2(c, 1.15)
			var t = _pick(user, c, 60.0 * float(c["s"]))
			if t:
				cc["aim"] = t.global_position
			_neko_pounce(user, cc)
			_blue_patch(user, user.global_position, float(c["s"]), float(c["dmg"]) * 0.15, 5.0))


## --- Isobu: Sango Mori — hedefin çevresinde sarmal büyüyen mercan ormanı; yakalananları hapseder, orman siper kalır
static func _sango_mori(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 60.0 * s)
	var dmg: float = c["dmg"]
	VFX.splash(ctr, 2.5 * s)
	Sfx.play("earth", ctr, 0.6)
	var n = 22
	for i in n:
		_later(0.05 * i, user, func():
			var a = i * 2.4
			var r = (0.8 + i * 0.5) * s
			var p = _gp(ctr + Vector3(cos(a), 0, sin(a)) * r)
			_coral(p, randf_range(3.0, 6.0) * s, 10.0, CORAL if i % 2 else CORAL2)
			VFX.splash(p, 0.8 * s)
			for f in _hit(user, p + Vector3.UP * s, 2.0 * s, {"dmg": dmg * 0.18, "element": "suiton", "knock": 3.0, "launch": 6.0, "kind": "heavy"}):
				_bind(f, 2.5)
				Combat.popup_text(f.global_position + Vector3.UP * (float(f.height) + 1.0), "MERCANA SIKIŞTI!", CORAL))


## --- Isobu: Suirō Kyūdan — hedef dev su küresine hapsolur (nefessiz kalır), sonra küre patlar
static func _suiro_kyudan(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 60.0 * s)
	var dmg: float = c["dmg"]
	var R = 4.5 * s
	var ball = _mi(VFX._sphere(0.5, 24, 12), _glass(Color(0.35, 0.65, 1.0), 0.45, 0.25))
	VFX.scene().add_child(ball)
	ball.global_position = ctr + Vector3.UP * R * 0.6
	ball.scale = Vector3.ONE * 0.2
	ball.create_tween().tween_property(ball, "scale", Vector3.ONE * R * 2.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	VFX.splash(ctr, 3.0 * s)
	Sfx.play("water", ctr, 0.5)
	var held = _foes(user, ball.global_position, R)
	for f in held:
		_bind(f, 3.5)
		Combat.popup_text(f.global_position + Vector3.UP * (float(f.height) + 1.0), "SU HAPSİ!", Color(0.5, 0.8, 1))
	_ticker(ctr, 3.2, 0.4, func(_n: Node3D, _e: float) -> void:
		for f in held:
			if is_instance_valid(f) and not f.is_dead():
				_hit(user, f.global_position + Vector3.UP, 0.6, {"dmg": dmg * 0.07, "element": "suiton", "knock": 0.0, "kind": "light"}))
	_later(3.3, user, func():
		if is_instance_valid(ball):
			VFX.splash(ball.global_position, 3.5 * s)
			VFX.shockwave(ball.global_position, Color(0.6, 0.85, 1.0), R * 2.5, 0.4, false)
			_hit(user, ball.global_position, R * 1.3, {"dmg": dmg * 0.8, "element": "suiton", "knock": 30.0, "launch": 10.0, "kind": "heavy"})
			ball.queue_free()
		_shake(0.6))


## --- Son Gokū: Yōton Kazan-u — gökten yağan lav kayaları, düştüğü yerler lav gölü
static func _kazan_u(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 70.0 * s)
	var dmg: float = c["dmg"]
	var R = 14.0 * s
	Sfx.play("fire", user.global_position, 0.4)
	VFX.goo_drops(_live_from(user, c, s), "molten", 24, 1.6 * s, 22.0)   # ağızdan göğe lav fışkırması
	for i in 16:
		_later(0.6 + 0.11 * i, user, func():
			var tg = _gp(ctr + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * R)
			var from = tg + Vector3(randf_range(-6, 6) * s, 34.0 * s, randf_range(-6, 6) * s)
			var vis = VFX.lava_ball(1.3 * s)
			var oh = func(pos: Vector3, _t: Node3D) -> void:
				VFX.lava_splash(pos, 1.1 * s)
				VFX.debris(pos, Color(0.25, 0.12, 0.08), 8, 10.0, 0.4 * s)
				if i % 3 == 0:
					_lava_pool(user, pos, s * 0.9, dmg * 0.14, 8.0)
				_shake(0.25)
			_shot(user, from, (tg - from).normalized() * 45.0, 0.8 * s, {"dmg": dmg * 0.4, "element": "yoton", "burn": 3.0, "knock": 12.0, "launch": 5.0, "kind": "heavy"}, vis, oh, 0.0, 3.0))


## --- Son Gokū: Yōton Funka — yer çizgi hâlinde yarılır, ucuna kadar art arda lav sütunları fışkırır
static func _yoton_funka(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = _gp(user.global_position)
	var dir = _flat(c["aim"] - o)
	var dmg: float = c["dmg"]
	for i in 9:
		var p = _gp(o + dir * (5.0 + i * 4.5) * s)
		_later(0.09 * i, user, func():
			VFX.cracks(p, 3.5 * s, Color(1.0, 0.45, 0.05, 0.95), 4.0))
		_later(0.09 * i + 0.5, user, func():
			PathJutsu.get_pinst().stream_fx(p, Vector3.UP, 14.0 * s, 1.7 * s, VFX.mat_water(Color(0.45, 0.08, 0.02), Color(1.0, 0.45, 0.1), Color(1.0, 0.85, 0.4), Vector3.UP, 1.0, 0.7, 0.15), 0.6)
			VFX.debris(p + Vector3.UP, Color(0.22, 0.12, 0.08), 10, 16.0, 0.45 * s)
			VFX.goo_drops(p + Vector3.UP * 5.0 * s, "molten", 8, 1.5 * s, 10.0)
			_hit(user, p + Vector3.UP * 2.0 * s, 3.2 * s, {"dmg": dmg * 0.45, "element": "yoton", "burn": 4.0, "knock": 6.0, "launch": 20.0, "kind": "heavy"})
			if i % 3 == 2:
				_lava_pool(user, p, s, dmg * 0.12, 7.0)
			Sfx.play("boom", p, 1.0)
			_shake(0.3))


## --- Kokuō: Futton Mōjō — bedenden dev kaynar buhar fırtınası: yakındakiler haşlanır, savrulur, alan uzun süre kaynar
static func _futton_mojo(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = _gp(user.global_position)
	var R = 15.0 * s
	var dmg: float = c["dmg"]
	Sfx.play("wind", o, 0.5)
	for k in 4:
		_later(0.15 * k, user, func():
			_steam_cloud(o + Vector3.UP * (1.0 + k) * s, s * (1.2 + k * 0.3), R * (0.4 + k * 0.2), 2.5)
			VFX.shockwave(o + Vector3.UP * 0.3, STEAM, R * (0.6 + k * 0.4), 0.4))
	_hit(user, o + Vector3.UP * s, R * 0.7, {"dmg": dmg * 0.9, "element": "futton", "knock": 40.0, "launch": 10.0, "kind": "heavy", "hitstop": 0.1})
	_shake(1.0)
	_ticker(o, 7.0, 0.5, func(_n: Node3D, el: float) -> void:
		if int(el / 0.5) % 2 == 0:
			_steam_cloud(o + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)) * R * 0.6, s * 0.8, 3.0 * s, 1.5)
		for f in _hit(user, o + Vector3.UP * s, R, {"dmg": dmg * 0.05, "element": "futton", "knock": 0.0, "kind": "light"}):
			f.apply_status("slow", 0.6))


## --- Kokuō: Gōkaku Totsugeki — buhar itişli üç boynuz hücumu art arda, her seferinde hedefe dönerek
static func _gokaku_totsugeki(user: Node3D, c: Dictionary) -> void:
	for k in 3:
		_later(0.85 * k, user, func():
			var cc = _c2(c, 1.1)
			var t = _pick(user, c, 70.0 * float(c["s"]))
			if t:
				cc["aim"] = t.global_position
			_horn_ram(user, cc))


## --- Saiken: Fukuso Arashi — gökyüzünü dolduran asit baloncuğu fırtınası
static func _fukuso_arashi(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 60.0 * s)
	for k in 5:
		_later(0.22 * k, user, func():
			var a = randf() * TAU
			var cc = _c2(c, 1.2, ctr + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 9.0) * s)
			cc["from"] = _live_from(user, c, s)
			_fukuso(user, cc))


## --- Saiken: Nenkō Shinshoku — öne doğru yayılan sümük seli: yollar yapış yapış, değen zırh erir
static func _nenko_shinshoku(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = _gp(user.global_position)
	var dir = _flat(c["aim"] - o)
	var dmg: float = c["dmg"]
	VFX.splash(o + dir * 4.0 * s, 3.0 * s)
	Sfx.play("water", o, 0.4)
	for k in 3:
		_later(0.25 * k, user, func():
			var p = o + dir * (8.0 + k * 11.0) * s
			_slime(user, _c2(c, 0.85, p))
			for f in _hit(user, p + Vector3.UP * s, 7.0 * s, {"dmg": dmg * 0.4, "element": "suiton", "knock": 18.0, "launch": 3.0, "kind": "heavy", "dir": dir}):
				_corrode(f, 6.0, dmg * 0.05, ACID))


## --- Chōmei: Rinpun Kōsen — alanı pul tozu sisi kaplar, art arda kör eden ışık patlamaları
static func _rinpun_kosen(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 70.0 * s)
	var dmg: float = c["dmg"]
	var R = 18.0 * s
	_fog(ctr, R, SCALE, 0.35, 7.0)
	for k in 6:
		_later(0.25 * k, user, func():
			var a = TAU * k / 6.0
			var p = ctr + Vector3(cos(a), 0, sin(a)) * R * 0.45 + Vector3.UP * 3.0 * s
			VFX.star(p, Color(1, 1, 0.85), 6.0 * s, 0.25)
			FX.light(p, Color(1, 1, 0.8), 12.0, 25.0 * s, 0.3)
			for f in _hit(user, p, R * 0.4, {"dmg": dmg * 0.25, "element": "fuuton", "knock": 4.0, "kind": "light"}):
				_blind(f, 3.5))
	Sfx.play("chidori", ctr, 1.6, 0.6)


## --- Chōmei: Mushi Arashi — beş güdümlü böcek sürüsü birden
static func _mushi_arashi(user: Node3D, c: Dictionary) -> void:
	for k in 5:
		_later(0.18 * k, user, func():
			var cc = _c2(c, 1.1)
			cc["from"] = _live_from(user, c, float(c["s"]))
			_mushi_swarm(user, cc))


## --- Gyūki: Sumi Nami — öne kopan mürekkep tsunamisi: kör eder, yavaşlatır, zemini mürekkebe boğar
static func _sumi_nami(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = _gp(user.global_position)
	var dir = _flat(c["aim"] - o)
	var side = dir.cross(Vector3.UP)
	var dmg: float = c["dmg"]
	var hitlist: Array = [user]
	Sfx.play("water", o, 0.35)
	for i in 10:
		_later(0.06 * i, user, func():
			var p = o + dir * (4.0 + i * 3.5) * s
			for k in 3:
				var q = p + side * (k - 1) * 5.0 * s
				_ink_puddle(q, s * 1.3, 8.0)
				VFX.puffs(_gp(q) + Vector3.UP * 2.0 * s, {"amount": 10, "life": 1.0, "size": 1.8 * s, "radius": 2.0 * s, "vmin": 4, "vmax": 10, "dir": Vector3.UP + dir, "spread": 40.0,
					"gravity": Vector3(0, -14, 0), "colors": [Color(0.12, 0.08, 0.18, 1), Color(0.02, 0.01, 0.03, 0)]})
			for f in _hit(user, p + Vector3.UP * 2.0 * s, 8.0 * s, {"dmg": dmg * 0.3, "element": "suiton", "knock": 22.0, "launch": 4.0, "kind": "heavy", "dir": dir}, hitlist):
				hitlist.append(f)
				_blind(f, 3.0, Color(0, 0, 0, 0.85))
				f.apply_status("slow", 4.0))
	_shake(0.7)


## --- Gyūki: Hachibi Ude Rengeki — sekiz dokunaç hedefin çevresine art arda iner, yeri yarar
static func _hachi_ude(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var ctr = _center(user, c, 50.0 * s)
	var dmg: float = c["dmg"]
	var mat = _toon(Color(0.42, 0.22, 0.28))
	for k in 8:
		_later(0.16 * k, user, func():
			var a = k * 2.2
			var p = _gp(ctr + Vector3(cos(a), 0, sin(a)) * randf_range(0.0, 6.0) * s)
			var base = user.global_position + Vector3.UP * _body_h(user, c) * 0.35
			var arm = _mi(_cone(1.4 * s, 0.5 * s, 1.0, 8), mat)
			VFX.scene().add_child(arm)
			var L = base.distance_to(p)
			arm.global_position = base.lerp(p, 0.5)
			var dv = (p - base).normalized()
			arm.basis = Basis(Quaternion(Vector3.UP, dv))
			arm.scale = Vector3(1, L * 0.05, 1)
			var tw = arm.create_tween()
			tw.tween_property(arm, "scale", Vector3(1, L, 1), 0.12)
			tw.tween_interval(0.25)
			tw.tween_property(arm, "scale", Vector3(0.6, L * 0.05, 0.6), 0.2)
			tw.tween_callback(arm.queue_free)
			_later(0.12, user, func():
				VFX.cracks(p, 3.0 * s, Color(0.15, 0.1, 0.1, 0.9), 3.0)
				VFX.shockwave(p + Vector3.UP * 0.2, Color(0.9, 0.85, 0.95), 7.0 * s, 0.3)
				VFX.debris(p, Color(0.35, 0.3, 0.25), 8, 10.0, 0.35 * s)
				_hit(user, p + Vector3.UP * s, 3.2 * s, {"dmg": dmg * 0.35, "element": "raiton", "knock": 16.0, "launch": 9.0, "kind": "heavy", "hitstop": 0.06})
				Sfx.play("hit_heavy", p, 0.7)
				_shake(0.3)))


## --- Kurama: Kyūbi Bisō — dokuz kuyruk sırayla yeri döver, önündeki her şey savrulur
static func _kyubi_biso(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	var o = _gp(user.global_position)
	var fwd = _flat(c["aim"] - o)
	var dmg: float = c["dmg"]
	var col: Color = c.get("col", FOX)
	for k in 9:
		_later(0.11 * k, user, func():
			var a = atan2(fwd.x, fwd.z) + (k - 4) * 0.42
			var p = _gp(o + Vector3(sin(a), 0, cos(a)) * 11.0 * s)
			VFX.cracks(p, 4.0 * s, Color(1.0, 0.5, 0.1, 0.9), 3.5)
			VFX.shockwave(p + Vector3.UP * 0.2, col.lightened(0.3), 9.0 * s, 0.35)
			VFX.debris(p, Color(0.35, 0.3, 0.25), 10, 14.0, 0.45 * s)
			_hit(user, p + Vector3.UP * s, 4.0 * s, {"dmg": dmg * 0.4, "element": "katon", "burn": 2.0, "knock": 35.0, "launch": 12.0, "kind": "heavy", "dir": (p - o).normalized()})
			Sfx.play("boom", p, 0.8)
			_shake(0.35))


## --- Kurama: Bijūdama Rendan — art arda üç dev Bijūdama
static func _bijudama_rendan(user: Node3D, c: Dictionary) -> void:
	var s: float = c["s"]
	for k in 3:
		_later(0.9 * k, user, func():
			var from = _live_from(user, c, s)
			var t = _pick(user, c, 90.0 * s)
			var aim: Vector3 = (t.global_position + Vector3.UP * float(t.height) * 0.5) if t else c["aim"]
			var dir = (aim - from).normalized()
			var vis = BijudamaFX.ball(1.8 * s)
			BijudamaFX.gather(from, 1.8 * s, 0.4)
			var boom = func(pos: Vector3, _t: Node3D) -> void:
				var R = 10.0 * s
				BijudamaFX.explode(pos, R)
				_hit(user, pos, R, {"dmg": float(c["dmg"]) * 1.1, "knock": 40.0, "launch": 12.0, "kind": "heavy"})
				_shake(1.2)
			var prb = _shot(user, from + dir * 1.5 * s, dir * 60.0, 1.2 * s, {"dmg": float(c["dmg"]) * 0.4, "knock": 20.0, "kind": "heavy"}, vis, boom, 0.0, 4.0)
			BijudamaFX.launch(from + dir * 1.5 * s, dir, 1.8 * s, prb)
			Sfx.play("rasengan", from, 0.4))


# ================================================================== canavara özgü pençe / vuruş
## Tam dönüşüm sol tık ve boss pençesi: element + canavarın izi (kum, mavi alev, mercan, lav, buhar, asit, rüzgar bıçağı, mürekkep, tilki ateşi)
static func melee(user: Node3D, id: String, pt: Vector3, r: float, dmg: float, dir: Vector3) -> Array:
	var m: Array = MELEE.get(id, MELEE["kurama"])
	var col: Color = m[1]
	var info = {"dmg": dmg, "element": m[0], "knock": 30.0, "launch": 6.0, "kind": "heavy", "dir": dir, "hitstop": 0.08}
	match String(m[2]):
		"burn":
			info["burn"] = 3.0
		"shock":
			info["stun"] = 0.5
	var hits = _hit(user, pt, r, info)
	var s = r / 3.0
	match String(m[2]):
		"sand":
			VFX.puffs(pt, {"amount": 20, "life": 1.0, "size": 1.0 * s, "radius": r * 0.4, "vmin": 4, "vmax": 10, "gravity": Vector3(0, -12, 0),
				"colors": [Color(0.95, 0.85, 0.62, 1), Color(0.82, 0.68, 0.45, 0)]})
		"burn":
			_claw_marks(pt, dir, s * 0.8, "blue" if id == "matatabi" else "fire")
		"coral":
			VFX.splash(pt, 1.2 * s)
			for k in 3:
				_coral(_gp(pt + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * r * 0.6), r * 0.6, 3.0, CORAL if k % 2 else CORAL2)
		"steam":
			_steam_cloud(pt, s * 0.6, r * 0.6, 1.2)
		"acid":
			VFX.puffs(pt, {"amount": 14, "life": 0.7, "size": 0.8 * s, "radius": r * 0.3, "vmin": 3, "vmax": 7, "gravity": Vector3(0, -12, 0),
				"colors": [Color(0.95, 1, 0.9, 1), ACID, Color(0.4, 0.8, 0.2, 0)]})
			for f in hits:
				_corrode(f, 3.0, dmg * 0.04, ACID)
		"wind":
			for k in 3:
				FX.ring(pt + dir * k * r * 0.4, Color(0.8, 1.0, 0.7, 0.9), r * (1.0 + k * 0.4), 0.25, true, dir)
		"ink":
			VFX.puffs(pt, {"amount": 14, "life": 0.9, "size": 1.0 * s, "radius": r * 0.3, "vmin": 2, "vmax": 6,
				"colors": [Color(0.12, 0.08, 0.18, 1), Color(0.02, 0.01, 0.03, 0)], "glow": 0.6})
			for f in hits:
				f.apply_status("slow", 2.0)
		"shock":
			FX.hit_spark(pt, col, 1.5 * s)
	FX.impact(pt, col, maxf(0.6, s * 0.5))
	return hits


## Canavar için hazır seçim: mesafeye göre uygun teknik (boss/düşman jinchūriki yapay zekâsı)
static func pick_key(id: String, dist: float, s: float) -> String:
	var l = techs(id)
	if l.is_empty():
		return ""
	var now = Time.get_ticks_msec()
	var epics = l.filter(func(t): return t.get("epic", false))
	if not epics.is_empty() and now - int(_epic_t.get(id, -100000)) > 14000 and randf() < 0.45:
		_epic_t[id] = now
		return String(epics.pick_random()["key"])
	l = l.filter(func(t): return not t.get("epic", false))
	var near_keys = ["neko_pounce", "shell_roll", "horn_ram", "steam_burst", "yoton_yoroi", "suna_tate", "tako_bunshin", "slime", "biju_hoko", "funkatsu"]
	var opts = []
	for t in l:
		var k: String = t["key"]
		if dist < 10.0 * s and k in near_keys:
			opts += [k, k]
		else:
			opts.append(k)
	return opts.pick_random()
