class_name Enemy
extends Fighter
## Düşman ninja yapay zekâsı.

static var attack_tokens = 0  # aynı anda saldıran düşman sayısı
static var swings = 0         # toplam savuruş (dövüş temposu ölçümü)

var arch = {}
var home = Vector3.ZERO
var target: Node3D = null
var think_t = 0.0
var attack_cd = 1.0
var jcd := {}      # jutsu -> hazır olacağı an (sn)
var jgap := 0.0    # iki jutsu arası en kısa ara
var ranged_cd = 3.0
var sub_cd = 0.0
var combo_left = 0
var has_token = false
var blind_t = 0.0
var guarding = false
var guard_cd = 0.0     # blok bittikten sonra tekrar bloklayana kadar
var guard_hits = 0     # bu blokta tutulan darbe; 3'te savunma kırılır
var level = 1
var xp = 20
var ryo = 15
var display_name = ""
var nameplate: Label3D
var wander_to = Vector3.ZERO
## Dövüş ustalığı 0..1 (stat değil, davranış): kaçınma, blok/karşılık, kawarimi, kombo uzunluğu, sıra bekleme.
## arch["skill"] verilmezse güçten türetilir: haydut ~0.1, chūnin ~0.4, jōnin ~0.6, S-rank/boss ~0.9
var skill := 0.2
var dodge_cd := 0.0
var hit_times: Array = []     # son darbelerin zamanı (kombodan sıyrılma)
var dodge_dir := Vector3.ZERO
var _saw_busy := false
var leap_cd := 2.0
var ammo := 8           # atılabilir alet sayısı (biter)
var maki := 1           # makibishi: kaçarken bir kez ayağının dibine saçar       # ninja sıçrayışı (oyuncunun Ctrl'i gibi): kaçan hedefi kovalar   # oyuncunun saldırısı başına tek okuma zarı


static func archetype(kind: String, i := 0) -> Dictionary:
	var base = {"kind": kind, "hp": 70.0, "level": 2, "power": 1.0, "speed": 8.5, "element": "", "jutsu": [], "aggr": 0.5,
		"xp": 25, "ryo": 20, "name": "Haydut", "size": 1.0, "guard": 0.15, "sub": 0.0, "tools": true}
	var L = CharacterModel.default_look()
	match kind:
		"bandit":
			L.merge({"top": Color(0.55, 0.42, 0.3), "top2": Color(0.45, 0.35, 0.25), "pants": Color(0.35, 0.3, 0.25), "band": null,
				"hair_style": ["kısa", "dağınık", "kase"][i % 3], "hair": Color(0.15, 0.12, 0.1), "mask": "cloth" if i % 2 else null, "sleeves": false}, true)
		"rogue":
			L.merge({"top": Color(0.25, 0.25, 0.28), "top2": Color(0.18, 0.18, 0.2), "pants": Color(0.2, 0.2, 0.22), "band": Color(0.2, 0.2, 0.25),
				"band_style": "slashed", "village": ["kiri", "iwa", "kumo", "konoha"][i % 4], "hair_style": ["uzun", "dağınık"][i % 2]}, true)
			base.merge({"hp": 120.0, "level": 8, "power": 1.4, "element": ["suiton", "doton", "raiton", "katon"][i % 4], "aggr": 0.7,
				"xp": 70, "ryo": 60, "name": "Kaçak Ninja", "guard": 0.3, "sub": 0.15}, true)
			base["jutsu"] = {"suiton": ["suiton_suikoudan"], "doton": ["doton_doryuusou"], "raiton": ["raiton_nagashi"], "katon": ["katon_goukakyuu"]}[base["element"]]
		"oto":
			L.merge({"top": Color(0.45, 0.4, 0.5), "top2": Color(0.3, 0.25, 0.35), "pants": Color(0.3, 0.28, 0.32), "band": Color(0.3, 0.3, 0.35),
				"village": "oto", "vest": null, "hair_style": "uzun"}, true)
			base.merge({"hp": 110.0, "level": 10, "power": 1.5, "element": "fuuton", "jutsu": ["fuuton_daitoppa"], "name": "Ses Ninjası", "xp": 80, "ryo": 50, "guard": 0.25, "sub": 0.1}, true)
		"kumo", "kiri", "iwa", "suna":
			var vc = {"kumo": [Color(0.85, 0.85, 0.82), Color(0.3, 0.35, 0.4)], "kiri": [Color(0.4, 0.5, 0.45), Color(0.3, 0.38, 0.45)],
				"iwa": [Color(0.55, 0.25, 0.2), Color(0.4, 0.35, 0.3)], "suna": [Color(0.75, 0.65, 0.45), Color(0.5, 0.45, 0.35)]}[kind]
			L.merge({"vest": vc[0], "top": vc[1], "top2": vc[1], "pants": vc[1], "village": kind, "band": Color(0.25, 0.25, 0.3)}, true)
			var el = {"kumo": "raiton", "kiri": "suiton", "iwa": "doton", "suna": "fuuton"}[kind]
			base.merge({"hp": 150.0, "level": 15, "power": 1.8, "element": el, "aggr": 0.65, "xp": 120, "ryo": 90, "guard": 0.35, "sub": 0.2,
				"name": {"kumo": "Kumo Chunin", "kiri": "Kiri Chunin", "iwa": "Iwa Chunin", "suna": "Suna Chunin"}[kind]}, true)
			base["jutsu"] = {"raiton": ["raiton_chidori", "raiton_nagashi"], "suiton": ["suiton_suiryuudan"], "doton": ["doton_doryuusou", "doton_doryuheki"], "fuuton": ["fuuton_shinkuu", "fuuton_daitoppa"]}[el]
		"samurai":
			L.merge({"top": Color(0.3, 0.32, 0.36), "top2": Color(0.5, 0.52, 0.55), "pants": Color(0.25, 0.26, 0.3), "band": null, "vest": Color(0.55, 0.57, 0.6)}, true)
			base.merge({"hp": 180.0, "level": 18, "power": 2.0, "aggr": 0.8, "name": "Samuray", "xp": 140, "ryo": 100, "guard": 0.5, "tools": false}, true)
		"genin_rival":
			L.merge({"top": Color(0.3, 0.45, 0.35), "band": Color(0.15, 0.22, 0.55), "hair_style": ["diken", "atkuyruğu", "kase"][i % 3]}, true)
			base.merge({"hp": 140.0, "level": 10, "power": 1.3, "element": ["katon", "fuuton", "suiton"][i % 3], "aggr": 0.75, "name": "Rakip Genin",
				"xp": 100, "ryo": 0, "guard": 0.35, "sub": 0.25}, true)
			base["jutsu"] = {"katon": ["katon_goukakyuu", "katon_housenka"], "fuuton": ["fuuton_daitoppa"], "suiton": ["suiton_suikoudan"]}[base["element"]]
		"jinchuriki":
			# içinde kuyruklu canavar taşıyan kaçak ninja: pelerin aurası + canavarın kendi teknikleri (BijuuArts)
			var bid: String = ["shukaku", "matatabi", "isobu", "son_goku", "kokuo", "saiken", "chomei", "gyuki"][i % 8]
			L.merge({"top": Color(0.22, 0.2, 0.24), "top2": Color(0.15, 0.14, 0.17), "pants": Color(0.18, 0.18, 0.2), "band": Color(0.2, 0.2, 0.25),
				"band_style": "slashed", "hair_style": ["uzun", "dağınık", "diken"][i % 3]}, true)
			base.merge({"hp": 900.0, "level": 40, "power": 3.0, "element": BeastModels.INFO[bid]["element"], "aggr": 0.8, "xp": 900, "ryo": 400,
				"name": "Jinchūriki — %s" % String(BeastModels.INFO[bid]["name"]).split(" — ")[0], "guard": 0.4, "sub": 0.25, "beast": bid}, true)
	# kıyafet seti: her arketip kendi havuzundan (haydut, kaçak, köy chūnin/jōnin, samuray...) rastgele giyinir
	var oarch: String = {"bandit": "bandit", "rogue": "rogue", "oto": "chunin", "kumo": "chunin", "kiri": "chunin", "iwa": "chunin", "suna": "chunin",
		"samurai": "samurai", "genin_rival": "genin", "jinchuriki": "rogue"}.get(kind, "")
	if oarch == "chunin" and randf() < 0.3:
		oarch = "jonin"
	if oarch != "":
		L.merge(Outfits.roll(oarch, String(L.get("village", "konoha"))), true)
	base["look"] = L
	# jutsu seviyeye ve tipe göre seçilir: haydut jutsu atmaz, düşük seviye kaçak ninja köpekbalığı fırlatmaz
	if kind in JUTSU_CAP:
		var auto = auto_jutsu(kind, String(base["element"]), int(base["level"]))
		if not auto.is_empty():
			base["jutsu"] = auto
		base["auto_jutsu"] = base["jutsu"].duplicate()
		base["auto_lv"] = int(base["level"])
	return base


## n kişilik grubun yerine tek güçlü ninja: can/güç/seviye artar, gerçek bir dövüş tarzı kuşanır
static func toughen(a: Dictionary, n: int, rank := "C") -> void:
	var k = float(maxi(0, n - 1))
	a["hp"] = float(a.get("hp", 120.0)) * (1.0 + 0.4 * k)
	a["power"] = float(a.get("power", 1.0)) * (1.0 + 0.05 * k)
	a["level"] = int(a.get("level", 5)) + int(2 * k)
	a["guard"] = maxf(float(a.get("guard", 0.2)), 0.35)
	a["sub"] = maxf(float(a.get("sub", 0.1)), 0.2)
	a["xp"] = int(float(a.get("xp", 20)) * (1.0 + 0.8 * k))
	a["ryo"] = int(float(a.get("ryo", 10)) * (1.0 + 0.8 * k))
	if n >= 3 and String(a.get("kind", "")) != "bandit":
		BossStyles.dress(a, rank, randi(), "")


## Tip başına en yüksek jutsu rütbesi (E0 D1 C2 B3 A4 S5); seviye de ayrıca sınırlar
const JUTSU_CAP := {"rogue": 5, "oto": 4, "kumo": 5, "kiri": 5, "iwa": 5, "suna": 5, "konoha": 5, "genin_rival": 3}
## Köy ninjalarının bir kısmı köylerinin klanlarından birindendir: klan teknikleri, gözleri ve klan davranışıyla savaşır
const CLAN_KINDS := ["konoha", "suna", "kiri", "kumo", "iwa", "rogue", "oto", "genin_rival"]
const CLAN_P := 0.45
const RANK_I := {"E": 0, "D": 1, "C": 2, "B": 3, "A": 4, "S": 5}
## Ünlü ninjaların imza teknikleri sıradan düşmana verilmez (Efsane Yolları ve boss'lar kullanır)
const SIGNATURE := ["raiton_armor", "kuroi_kaminari", "joki_boi", "raiton_chidori", "raiton_nagashi", "chidori_nagashi", "chidori_senbon", "chidori_eiso",
	"kusanagi_no_tsurugi_chidorigatana", "raiton_hebi_ikazuchi", "katon_ryuen_hoka_no_jutsu", "raiton_raiju_tsuiga", "bashosen_hi_no_maki", "bashosen_kaze_no_maki",
	"kaze_no_yaiba", "byoen_hoka", "kumo_ryu_kaengiri", "mujin_meisai", "doton_kajugan_no_jutsu", "doton_chokajugan_no_jutsu", "fang_s_rush", "katon_goka_messhitsu",
	"futon_rasengan", "cho_biburato_raitonto", "nezumi_kedama", "ukojizai_no_jutsu", "raiton_kage_bunshin_no_jutsu", "raiton_shiden", "katon_zukokku",
	"raiton_jibashi", "nadeshiko_ryu_koha_reppuken", "raiton_sandageto", "katon_goka_senpu"]


static func _lv_cap(lv: int) -> int:
	if lv < 6:
		return 1
	if lv < 12:
		return 2
	if lv < 25:
		return 3
	if lv < 45:
		return 4
	return 5


## Element havuzundan, klan/kekkei genkai/göz/yasak/imza jutsuları hariç, rütbesi izin verilen 2-3 jutsu
static func auto_jutsu(kind: String, el: String, lv: int) -> Array:
	if el == "":
		return []
	var cap = mini(int(JUTSU_CAP.get(kind, 2)), _lv_cap(lv))
	var by_rank = {}
	for id in Data.jutsu:
		var j = Data.jutsu[id]
		if not j is Dictionary or String(j.get("element", "")) != el or String(j.get("category", "")) != "ninjutsu":
			continue
		var lp = String(j.get("learn", "")).split(":")[0]
		if lp in ["clan", "kg", "eye", "kinjutsu", "quest", "sage", "path"] or id in SIGNATURE or String(id).begins_with("bashosen"):
			continue
		var r = int(RANK_I.get(String(j.get("canon_rank", "")), -1))
		if r < 0 or r > cap:
			continue
		if not by_rank.has(r):
			by_rank[r] = []
		by_rank[r].append(id)
	var out = []
	# en üst izinli rütbeden 1, alttakilerden 1-2 (çeşit olsun)
	for r in range(cap, -1, -1):
		if not by_rank.has(r):
			continue
		var pool: Array = by_rank[r].duplicate()
		pool.shuffle()
		for id in pool.slice(0, 1 if out.is_empty() else 2):
			out.append(id)
		if out.size() >= 3:
			break
	return out.slice(0, 3)


func setup(a: Dictionary) -> void:
	arch = a
	var k = String(a.get("kind", ""))
	set_meta("faction", String(a.get("faction", k if k in ["konoha", "suna", "kiri", "kumo", "iwa", "ame", "samurai", "bandit"] else ("rogue" if k in ["rogue", "jinchuriki", "oto"] else k))))
	look = a["look"]
	max_hp = a["hp"]; hp = max_hp
	power = a["power"]; element = a["element"]
	level = a["level"]; xp = a["xp"]; ryo = a["ryo"]
	# NPC "yetenek ağacı": oyuncunun seviyeyle aldığı yetenek puanlarının karşılığı (can + güç) düşman ninjalara da
	if k in CLAN_KINDS or k in ["samurai", "jinchuriki", "bandit"]:
		var lv = float(a["level"])
		# oyuncu yakın dövüşü %40 kısıldı: can da buna göre (öldürme süresi eskisi gibi kalsın)
		max_hp *= 0.75 + lv * 0.004
		hp = max_hp
		power *= 1.0 + lv * 0.003
	size = a.get("size", 1.0)
	display_name = a["name"]
	skill = clampf(float(a.get("skill", (float(a["power"]) - 1.0) / 2.2)), 0.05, 0.98)
	# zorluk = davranış (can/güç değil): ninjalar seviyeleriyle ustalaşır — daha çok blok, kawarimi, kaçış, karşı saldırı
	if not String(a.get("kind", "")) in ["bandit"] and not a.has("skill"):
		skill = maxf(skill, clampf(0.18 + int(a["level"]) * 0.009, 0.0, 0.85))
	# görev seviyeyi değiştirdiyse ve jutsu elle verilmediyse yeni seviyeye göre yeniden seç
	if a.has("auto_jutsu") and a["jutsu"] == a["auto_jutsu"] and int(a["level"]) != int(a.get("auto_lv", 0)):
		var auto = auto_jutsu(String(a["kind"]), String(a["element"]), int(a["level"]))
		if not auto.is_empty():
			a["jutsu"] = auto
	_maybe_clan(a)


## Rastgele klan: köyün klanlarından biri (kaçaklar herhangi bir köyden); klan teknikleri jutsu listesinin başına
func _maybe_clan(a: Dictionary) -> void:
	if a.has("clan") or a.get("no_clan", false) or a.has("beast") or int(a.get("level", 1)) < 5:
		return
	var k = String(a.get("kind", ""))
	if not k in CLAN_KINDS or randf() > CLAN_P:
		return
	var vid = String(a.get("look", {}).get("village", k))
	var cands = []
	for c in Data.clans:
		if c == "none" or c in Progress.UNPLAYABLE_CLANS:
			continue
		if k in ["rogue", "oto"] or vid in Data.clans[c].get("villages", []):
			cands.append(c)
	if cands.is_empty():
		return
	var c = String(cands.pick_random())
	a["clan"] = c
	a["clan_auto"] = true
	var cj = ClanWorld.clan_jutsu(c, int(a["level"]), 2)
	var js: Array = (a.get("jutsu", []) as Array).duplicate()
	for j in cj:
		if not j in js:
			js.push_front(j)
	a["jutsu"] = js.slice(0, 5)
	var L: Dictionary = ClanWorld.LOOK.get(c, {})
	if L.has("hair"):
		look["hair"] = (L["hair"] as Array).pick_random()
	if L.has("hs"):
		look["hair_style"] = (L["hs"] as Array).pick_random()
	if not ClanWorld.clan_name(c) in display_name:
		display_name = "%s %s" % [ClanWorld.clan_name(c), display_name]


func _ready() -> void:
	super._ready()
	home = global_position
	nameplate = Label3D.new()
	nameplate.text = "%s  Sv.%d" % [display_name, level]
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# uzaktaki isimler üst üste binmesin: dünya boyutunda, 30 m'den sonra solarak kaybolur
	nameplate.fixed_size = false
	nameplate.pixel_size = 0.0045
	nameplate.visibility_range_end = 30.0
	nameplate.visibility_range_end_margin = 6.0
	nameplate.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	nameplate.font_size = 36
	nameplate.outline_size = 8
	nameplate.modulate = Color(1, 0.6, 0.55)
	nameplate.position.y = height + 0.5
	nameplate.no_depth_test = false
	add_child(nameplate)
	facing = randf() * TAU
	wander_to = home
	if arch.has("beast"):
		FX.aura(self, BeastModels.INFO[arch["beast"]]["chakra"], 1.2, Vector3(0, 0.9, 0), 0.0)   # sönmeyen canavar chakrası
	if skill > 0.35:
		Jutsu.jutsu_cast.connect(_on_someone_cast)
	if arch.get("clan_auto", false) and not has_node("ClanTrait"):
		ClanWorld.after_spawn_enemy(self, String(arch["clan"]), level)   # klan gözleri (Sharingan/Byakugan...) + klan davranışı


## Usta düşman, hedefi jutsu yaparken mühürleri okur ve yana atılır
func _on_someone_cast(caster: Node, _id: String) -> void:
	if dead or caster != target or not is_instance_valid(caster) or dodge_cd > 0.0:
		return
	if caster.global_position.distance_to(global_position) < 30.0 and randf() < skill * 0.4:
		_dodge(caster, true)


## Kaçınma atılışı: yana (ya da geriye) hızlı chakra adımı
func _dodge(from: Node3D, side := true) -> void:
	if state in ["hitstun", "knockdown", "cast", "attack"] or has_status("stun") or has_status("bind"):
		return
	dodge_cd = lerpf(2.6, 1.0, skill)
	var away = global_position - from.global_position
	away.y = 0
	away = away.normalized() if away.length() > 0.01 else -face_dir()
	var lat = away.cross(Vector3.UP) * (1.0 if randf() < 0.5 else -1.0)
	dodge_dir = (lat * 0.85 + away * 0.35).normalized() if side else (away + lat * 0.3).normalized()
	state = "dodge"
	state_t = 0.0
	model.play("run", 0.05, 1.6)
	FX.speed_lines(global_position + Vector3.UP, dodge_dir)


func lose_target(t: float) -> void:
	blind_t = t
	target = null


func _physics_process(dt: float) -> void:
	if Game.paused or dead:
		if dead:
			step_move(Vector3.ZERO, dt, false)
		return
	var pl = Game.player
	var far = pl == null or global_position.distance_to(pl.global_position) > 170.0
	if far:
		return
	tick_status(dt)
	state_t += dt
	attack_cd -= dt
	ranged_cd -= dt
	sub_cd -= dt
	guard_cd -= dt
	dodge_cd -= dt
	blind_t -= dt
	nameplate.modulate.a = 1.0 if global_position.distance_to(pl.global_position) < 30 else 0.0
	match state:
		"hitstun":
			step_move(Vector3.ZERO, dt, false)
			if state_t > 0.45:
				state = "chase"
			return
		"knockdown":
			step_move(Vector3.ZERO, dt, false)
			if state_t > 0.9 and grounded and model.current != "getup":
				model.play("getup", 0.1, 1.5, true)
			if state_t > 1.8:
				state = "chase"
			return
	if has_status("stun") or has_status("bind"):
		step_move(Vector3.ZERO, dt, false)
		model.play("idle" if has_status("bind") else "hit", 0.2, 0.3)
		return
	_think(dt)
	if arch.has("style"):
		BossStyles.tick(self, dt)
	if EnemyArts.wants(self):
		EnemyArts.tick(self, dt)
	if arch.has("mist_sword"):
		Swordsmen.tick(self, dt)
	_footsteps(dt)
	match state:
		"idle":
			_patrol(dt)
		"chase":
			_chase(dt)
		"leap":
			# sıçrayış havada: hız korunur, yerçekimi; inince kovalamaya döner
			velocity.y -= 32.0 * dt
			move_and_slide()
			var g = Game.ground_height(global_position.x, global_position.z)
			if global_position.y < g:
				global_position.y = g
			if state_t > 0.25 and global_position.y <= g + 0.05:
				FX.dust(global_position, 0.6)
				model.overlay.set_pose("leap", 0.0)
				state = "chase"
		"attack":
			_attack(dt)
		"cast":
			step_move(Vector3.ZERO, dt, false)
			if state_t > 0.55:
				model.overlay.set_pose("seal", 0.0)
				Jutsu.execute(self, get_meta("cast_id"), target)
				model.play("cast_out", 0.05, 1.3, true)
				state = "recover"
				state_t = 0.0
		"recover", "throw":
			# geri çekilirken peşindekine makibishi saçar (bir kez)
			if maki > 0 and state == "recover" and target and is_instance_valid(target) and global_position.distance_to(target.global_position) < 5.0 and randf() < 0.02 and _is_ninja():
				maki -= 1
				Projectile.caltrops(self, global_position + (target.global_position - global_position).normalized() * 1.5, 7.0)
				Combat.popup_text(global_position + Vector3.UP * 2.2, "Makibishi!", Color(0.85, 0.85, 0.9))
			# toparlanırken boş durmaz: hedefin çevresinde yana adımlar (kolay hedef olmasın)
			var side = Vector3.ZERO
			if target and is_instance_valid(target) and state == "recover":
				var tv = target.global_position - global_position
				tv.y = 0
				side = tv.normalized().cross(Vector3.UP) * (1.0 if int(get_instance_id()) % 2 == 0 else -1.0) * 3.5
			step_move(side, dt, false)
			if state_t > 0.35:
				state = "chase"
				# taktik: komboyu bitiren usta ninja geri sıçrayıp mesafe açar ve jutsuya hazırlanır (dümdüz yüklenmesin)
				var jl0: Array = arch.get("jutsu", [])
				if target and is_instance_valid(target) and _is_ninja() and not jl0.is_empty() and dodge_cd <= 0.0 and randf() < skill * 0.6:
					_dodge(target, false)
					ranged_cd = minf(ranged_cd, 0.3)
		"dodge":
			step_move(dodge_dir * (16.0 + skill * 8.0), dt, false)
			if state_t > 0.22:
				state = "chase"
				attack_cd = minf(attack_cd, 0.15)   # kaçtıktan sonra hemen karşılık
		"guard":
			step_move(Vector3.ZERO, dt, false)
			if state_t > 0.6:
				guard_cd = lerpf(3.0, 1.6, skill)
				guarding = false
				model.overlay.set_pose("guard", 0.0)
				state = "chase"
		"flee":
			var away = global_position - target.global_position if target else Vector3.ZERO
			away.y = 0
			step_move(away.normalized() * arch["speed"], dt)
			model.play("run", 0.15)
			if state_t > 2.0:
				state = "chase"


func _think(dt: float) -> void:
	think_t -= dt
	if think_t > 0.0:
		return
	think_t = 0.25
	var pl = Game.player
	if blind_t > 0.0 or (target != null and is_instance_valid(target) and not Combat.hostile(self, target)):
		target = null   # hedef artık dost (yardım kabul edildi, takım değişti): bırak
	elif target == null or not is_instance_valid(target) or target.is_dead():
		var prev = target
		target = null
		# kovalama sürerken hedef bırakılmaz (oyuncu sıçrayıp kaçınca görüşten çıktı diye unutulmuyordu)
		if prev != null and is_instance_valid(prev) and not prev.is_dead() and Combat.hostile(self, prev) and state in ["chase", "leap", "attack", "recover"] 				and global_position.distance_to(prev.global_position) < (110.0 if _is_ninja() else 60.0) and not (prev == pl and Buffs.has("henge")):
			target = prev
		# görüş: ninja düşmanlar uzaktan fark eder (eskiden 26 m, yanına kadar gelmek gerekiyordu)
		var best = (55.0 if not (arch.get("jutsu", []) as Array).is_empty() else 40.0) if not Buffs.has("henge") else 0.0
		for f in (get_tree().get_nodes_in_group("fighters") if target == null else []):
			if not Combat.hostile(self, f) or f.is_dead():
				continue
			if f.get("team") == "dummy":
				continue
			var d = global_position.distance_to(f.global_position)
			if f == pl and Buffs.has("henge"):
				continue
			if f == pl:
				d /= maxf(0.35, 1.0 - Stats.skill(Game.profile, "stealth"))  # gizlilik: daha yakından fark edilir
			if d < best:
				best = d
				target = f
		if target and state == "idle":
			state = "chase"
			Combat.popup_text(global_position + Vector3.UP * (height + 0.8), "!", Color(1, 0.3, 0.2))
	if target == null and state in ["chase"]:
		state = "idle"
	# hedef yakında saldırıya kalktıysa: usta düşman darbeyi okuyup kaçar
	# (zar her karede değil, oyuncunun her saldırı dizisinde bir kez atılır — yoksa usta düşmana hiç vurulamıyordu)
	var busy = target != null and target == pl and pl.combat != null and pl.combat.busy()
	if busy and not _saw_busy:
		_saw_busy = true
		if state in ["chase", "recover", "idle"] and dodge_cd <= 0.0 and global_position.distance_to(pl.global_position) < 3.4 and randf() < skill * 0.3:
			_dodge(pl, randf() < 0.6)
	elif not busy:
		_saw_busy = false
	if global_position.distance_to(home) > (280.0 if _is_ninja() else 130.0) and state == "chase":
		target = null
		state = "idle"
		wander_to = home


func _patrol(dt: float) -> void:
	var v = wander_to - global_position
	v.y = 0
	if v.length() < 2.0 or state_t > 8.0:
		state_t = 0.0
		wander_to = home + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
		step_move(Vector3.ZERO, dt)
		model.play("idle", 0.2)
		return
	step_move(v.normalized() * 3.0, dt)
	model.play("walk", 0.2)


func _chase(dt: float) -> void:
	if target == null:
		state = "idle"
		return
	var v = target.global_position - global_position
	v.y = 0
	var d = v.length() - target.radius - radius
	facing = lerp_angle(facing, atan2(-v.x, -v.z), minf(1.0, dt * 8.0))
	# jinchūriki: canavarın kendi teknikleri
	if arch.has("beast") and d < 30.0 and ranged_cd <= 0.0 and randf() < 0.6:
		ranged_cd = randf_range(3.5, 6.0) / arch["aggr"]
		_beast_tech(d)
		return
	# hedef uzaklaşıyorsa ninja sıçrayışıyla kovala (oyuncu Ctrl ile kaçınca hiç yetişemiyorlardı)
	leap_cd -= dt
	if d > 16.0 and leap_cd <= 0.0 and _is_ninja() and global_position.y - Game.ground_height(global_position.x, global_position.z) < 0.5:
		_ninja_leap(v.normalized(), d)
		return
	# menzilli: jutsu ya da kunai
	# jutsu kullanan düşman: uzaktan ve sık atar, yakında da arada bir (eskiden 5-24 m, %30)
	var jl: Array = arch.get("jutsu", [])
	var far_ok = d > 4.0 and d < 42.0
	var near_ok = d <= 4.0 and not jl.is_empty() and randf() < 0.15
	if (far_ok or near_ok) and ranged_cd <= 0.0 and randf() < 0.8:
		ranged_cd = randf_range(1.6, 3.2) / (float(arch["aggr"]) * (1.0 + skill))   # usta ninja daha sık jutsu atar
		# her jutsu oyuncudakiyle aynı bekleme süresine tabi (aynı dalga jutsusu 15 sn'de 6 kez gelmez)
		var nowj = Time.get_ticks_msec() / 1000.0
		var ready = jl.filter(func(id): return nowj >= float(jcd.get(id, 0.0)))
		if not ready.is_empty() and nowj >= jgap and randf() < 0.85 and not has_status("sealed"):   # chakra noktaları kapalıysa jutsu yok
			var pick = String(ready.pick_random())
			jcd[pick] = nowj + Combat.jutsu_cd(Data.jutsu.get(pick, {})) * randf_range(1.0, 1.25)
			jgap = nowj + randf_range(2.5, 4.0)
			set_meta("cast_id", pick)
			state = "cast"
			CastAnim.play(self, get_meta("cast_id"), 0.55)  # mühür + atma koreografisi
			state_t = 0.0
			model.play("idle", 0.05)
			model.overlay.set_pose("seal", 1.0)
			Sfx.play("seal", global_position)
			return
		elif arch.get("tools", true) and ammo > 0:
			# aletleri biter (sonsuz kunai yok); bazı ninjalar senbon kullanır
			ammo -= 1
			state = "throw"
			state_t = 0.0
			model.play("throw", 0.05, 1.6, true)
			var s = global_position + Vector3.UP * 1.4
			var kinds = ["kunai", "kunai", "shuriken"] + (["senbon", "senbon"] if String(arch.get("kind", "")) in ["kiri", "oto", "rogue"] else [])
			var tk: String = kinds.pick_random()
			var nn = 3 if tk in ["shuriken", "senbon"] and randf() < 0.5 else 1
			var aim = (target.global_position + Vector3.UP - s).normalized()
			for i in nn:
				Projectile.tool(self, s, aim.rotated(Vector3.UP, deg_to_rad((i - (nn - 1) * 0.5) * 7.0)), tk, target)
			return
	if d > 1.6:
		# yakın dövüş sırası yoksa etrafında dolaş
		var sp: float = arch["speed"]
		var dir = v.normalized()
		# orta mesafeden atılma (usta ve saldırgan düşmanlar)
		if d > 3.5 and d < 11.0 and attack_cd <= 0.0 and (has_token or attack_tokens < _max_tokens()) and randf() < dt * (1.0 + skill * 3.0) * arch["aggr"]:
			_lunge()
			return
		var side_s = 1.0 if int(get_instance_id()) % 2 == 0 else -1.0
		if not has_token and attack_tokens >= _max_tokens() and d < 7.0:
			dir = dir.rotated(Vector3.UP, PI * 0.5 * side_s) * 0.6
			sp *= 0.6
		elif _is_ninja() and not (arch.get("jutsu", []) as Array).is_empty() and d > 5.0 and d < 16.0 and ranged_cd > 0.4 and skill > 0.3:
			# jutsucu: orta mesafede hedefin etrafında döner (yan adım), jutsu hazır olunca atar — dümdüz koşmaz
			dir = dir.rotated(Vector3.UP, PI * 0.42 * side_s * (1.0 if sin(Time.get_ticks_msec() * 0.001 + get_instance_id()) > -0.3 else -1.0))
		elif _is_ninja() and d > 6.0:
			# yaklaşırken zikzak (isabet almamak için)
			dir = dir.rotated(Vector3.UP, sin(Time.get_ticks_msec() * 0.003 + get_instance_id()) * 0.5 * skill)
		step_move(dir * sp, dt, false)
		model.play("run" if sp > 6 else "walk", 0.15, 1.1)
		model.rotation.y = facing
	else:
		step_move(Vector3.ZERO, dt, false)
		model.play("idle", 0.2)
		if attack_cd <= 0.0 and (has_token or attack_tokens < _max_tokens()):
			if not has_token:
				has_token = true
				attack_tokens += 1
			combo_left = randi_range(2, 3 + int(skill * 3.0))
			state = "attack"
			state_t = 0.0
			_swing()


func _is_ninja() -> bool:
	return not String(arch.get("kind", "")) in ["bandit", "samurai"] and not arch.has("beast") and float(arch.get("size", 1.0)) < 2.0


func _ninja_leap(dir: Vector3, d: float) -> void:
	leap_cd = randf_range(1.8, 3.2) / maxf(0.4, float(arch.get("aggr", 0.5)) + skill * 0.5)
	var k = clampf(d / 60.0, 0.3, 1.0)
	velocity = dir * lerpf(24.0, 44.0, k) + Vector3.UP * lerpf(10.0, 15.0, k)
	state = "leap"
	state_t = 0.0
	model.play("jump", 0.05, 1.5, true)
	model.overlay.set_pose("leap", 1.0)
	FX.dust(global_position, 0.8)
	Sfx.play("whoosh", global_position, 0.9, 0.6)


## Aynı anda yakın dövüşe girebilen düşman sayısı (eskiden 2: kalabalık bile sırayla bekliyordu)
func _max_tokens() -> int:
	return 3 if skill < 0.6 else 5


func _beast_tech(d: float) -> void:
	var bid: String = arch["beast"]
	var key = BijuuArts.pick_key(bid, d, 1.0)
	if key == "" or target == null:
		return
	state = "recover"
	state_t = 0.0
	model.play("throw", 0.05, 1.4, true)
	var col: Color = BeastModels.INFO[bid]["chakra"]
	BijuuArts.use(self, bid, key, {"s": 1.15, "dmg": 16.0 * power, "from": global_position + Vector3.UP * 1.4 + face_dir(), "aim": target.global_position + Vector3.UP,
		"tgt": target, "col": col})
	Combat.popup_text(global_position + Vector3.UP * (height + 1.2), String(BijuuArts.tech(bid, key).get("name", "")), col.lightened(0.3))


## Haritadan silinirken (uzaklaşınca, görev bitince) saldırı sırasını geri bırak — yoksa sayaç dolu kalıp
## bütün düşmanlar saldırmadan etrafında dolaşıyordu (pasif düşman hatası)
func _exit_tree() -> void:
	if has_token:
		has_token = false
		attack_tokens = maxi(0, attack_tokens - 1)


var _step_ph := -1.0


## Yakındaki (25 m) düşmanın ayak sesleri: animasyonda ayak yere bastığında
func _footsteps(_dt: float) -> void:
	if model == null or not grounded or Game.player == null or global_position.distance_to(Game.player.global_position) > 25.0:
		_step_ph = -1.0
		return
	if model.footstep_cross(_step_ph):
		Sfx.play(Game.step_sound(global_position), global_position, randf_range(0.88, 1.05), 0.2)
	_step_ph = model.anim_progress() if model.current in CharacterModel.FOOT_PHASES else -1.0


## Zemin: iç mekânda (mağara/in, dünyanın çok üstünde) arazi değil bulunduğu kat
func _floor_y(x: float, z: float) -> float:
	var g = Game.ground_height(x, z)
	return global_position.y if global_position.y - g > 30.0 else g


## Atılma saldırısı: orta mesafeden hedefe chakra adımıyla yaklaşıp kombo başlatır
func _lunge() -> void:
	var v = target.global_position - global_position
	v.y = 0
	var to = target.global_position - v.normalized() * (target.radius + radius + 1.0)
	to.y = _floor_y(to.x, to.z)
	FX.speed_lines(global_position + Vector3.UP, v.normalized())
	FX.smoke_puff(global_position + Vector3.UP * 0.3, 0.5, 6)
	global_position = to
	facing = atan2(-v.x, -v.z)
	if not has_token:
		has_token = true
		attack_tokens += 1
	combo_left = randi_range(2, 3 + int(skill * 3.0))
	state = "attack"
	state_t = 0.0
	_swing()


func _swing() -> void:
	swings += 1
	var anims = ["jab", "cross", "slash_a", "hook"] if arch.get("kind") != "samurai" and arch.get("kind_anim", "") != "sword" else ["slash_a", "slash_b", "slash_c"]
	model.play(anims.pick_random(), 0.05, 1.3 + skill * 0.45, true)
	model.flash(0.25)  # saldırı öncesi küçük uyarı
	set_meta("swung", false)


func _attack(dt: float) -> void:
	if target == null or not is_instance_valid(target):
		_end_attack()
		return
	var v = target.global_position - global_position
	v.y = 0
	facing = lerp_angle(facing, atan2(-v.x, -v.z), minf(1.0, dt * 10.0))
	step_move(face_dir() * (3.0 if state_t < 0.2 else 0.0), dt, false)
	if not get_meta("swung") and state_t > 0.28 / (1.0 + skill * 0.35):
		set_meta("swung", true)
		var pt = global_position + Vector3.UP * 1.1 + face_dir() * (radius + 0.9)
		var heavy = combo_left == 1 and randf() < 0.5
		var hits = Combat.hit_sphere(self, pt, 0.9, {"dmg": (4.5 if not heavy else 8.0) * power, "knock": 3.0 if not heavy else 10.0,
			"launch": 0.0 if not heavy else 4.0, "kind": "heavy" if heavy else "light", "hitstop": 0.04, "melee": true})
		var armed = look is Dictionary and look.get("weapon_r") != null and String(look.get("weapon_r", "")) != ""
		Sfx.play("swing_sword" if armed else "whoosh", global_position + Vector3.UP, randf_range(0.92, 1.1), 0.6)
		if not hits.is_empty():
			FX.hit_spark(pt, Color(1, 0.6, 0.4), 0.8)
			Sfx.play("hit_sword" if armed else "punch", pt, randf_range(0.92, 1.08))
	if state_t > 0.6 / (1.0 + skill * 0.35):
		combo_left -= 1
		if combo_left > 0:
			state_t = 0.0
			_swing()
		else:
			_end_attack()


func _end_attack() -> void:
	state = "recover"
	state_t = 0.0
	attack_cd = randf_range(0.35, 1.1) / arch["aggr"] / (1.0 + skill)
	if has_token:
		has_token = false
		attack_tokens = maxi(0, attack_tokens - 1)


func take_hit(info: Dictionary) -> void:
	if dead:
		return
	# Susanoo içindeki düşman: darbeler Susanoo'ya çarpar (oyuncunun İnsansı kademesiyle aynı azaltma; eskiden hiç azaltmıyordu)
	if has_meta("ea_susanoo") and is_instance_valid(get_meta("ea_susanoo")):
		info = info.duplicate()
		info["dmg"] = float(info.get("dmg", 5.0)) * 0.5
		info["knock"] = float(info.get("knock", 2.0)) * 0.2
		info["launch"] = 0.0
	# blok: yalnız önden gelen darbe, bekleme süresiyle; ağır darbe ya da üst üste 3 darbe savunmayı kırar
	var atk0: Node3D = info.get("attacker")
	var front = true
	if atk0 and is_instance_valid(atk0):
		var to_a = atk0.global_position - global_position
		to_a.y = 0
		front = to_a.length() < 0.1 or face_dir().dot(to_a.normalized()) > 0.2
	var kind_ok = info.get("kind", "light") == "light" or (skill > 0.8 and info.get("kind", "") == "heavy")
	if not guarding and guard_cd <= 0.0 and front and state in ["chase", "recover", "idle"] and randf() < minf(0.3, arch.get("guard", 0.15) * 0.5 + skill * 0.12) and kind_ok and not has_status("stun") and not has_status("bind"):
		state = "guard"
		state_t = 0.0
		guarding = true
		guard_hits = 0
		model.play("block", 0.05)
		model.overlay.set_pose("guard", 1.0)
	if guarding and (not front or info.get("kind", "") in ["heavy", "launch"] and skill <= 0.8 or guard_hits >= 2):
		# savunma kırıldı: kısa sersemleme, darbe tam geçer
		guarding = false
		guard_cd = 3.0
		model.overlay.set_pose("guard", 0.0)
		state = "chase"
		Combat.popup_text(global_position + Vector3.UP * 2.2, "Savunma kırıldı!", Color(1.0, 0.75, 0.4))
		apply_status("stun", 0.7)
	if guarding:
		guard_hits += 1
		FX.hit_spark(global_position + Vector3.UP * 1.2, Color(0.7, 0.85, 1.0), 0.5)
		var steel = info.get("attacker") is Player and Game.profile.get("weapon_drawn", false) and String(Gear.weapon(Game.profile).get("style", "fist")) in ["sword", "blade", "dual", "heavy", "sickle", "chain"]
		Sfx.play("clash" if steel else "block", global_position, randf_range(0.95, 1.08))
		info = info.duplicate()
		info["dmg"] = info.get("dmg", 5.0) * Combat.block_pass(info, 0.15) * Combat.jutsu_factor(info)   # jutsu bloğu deler (büyüdükçe daha çok)
		info["kind"] = "guarded"
		hp -= info["dmg"]
		if hp <= 0.0:   # bloklanan darbe de öldürebilir (yoksa can eksiye düşüp düşman ölümsüz kalıyordu)
			hp = 0.0
			guarding = false
			die(info)
			return
		if skill > 0.6 and randf() < skill * 0.5:   # bloktan karşı saldırı
			guarding = false
			model.overlay.set_pose("guard", 0.0)
			state = "chase"
			attack_cd = 0.0
		return
	# Kawarimi
	if sub_cd <= 0.0 and randf() < maxf(arch.get("sub", 0.0), skill * 0.25) and hp < max_hp * (0.7 + skill * 0.2):
		sub_cd = lerpf(16.0, 9.0, skill)
		FX.smoke_puff(global_position + Vector3.UP, 0.9, 14)
		var atk: Node3D = info.get("attacker")
		if atk:
			var behind = atk.global_position - atk.face_dir() * 2.0 if atk.has_method("face_dir") else global_position
			behind.y = _floor_y(behind.x, behind.z)
			global_position = behind
		Combat.popup_text(global_position + Vector3.UP * 2.2, "Kawarimi!", Color(0.9, 0.9, 0.6))
		state = "chase"
		attack_cd = 0.0
		return
	if has_token:
		has_token = false
		attack_tokens = maxi(0, attack_tokens - 1)
	super.take_hit(info)
	# yenilen kaçak pes eder: öldür / teslim et / bağışla (kaçak dostluğu)
	if not dead and hp > 0.0 and hp < max_hp * (0.25 + Stats.skill(Game.profile, "persuade") * 0.3) and RogueBonds.spareable(self, info):   # Sosyal: İkna
		set_physics_process(false)
		RogueBonds.yield_to(self)
		return
	if target == null and info.get("attacker"):
		target = info["attacker"]
	# kombodan sıyrılma: 1.4 sn'de 3+ darbe yiyen usta ninja geri sıçrar (tek komboyla dövüş bitmesin)
	var now = Time.get_ticks_msec() / 1000.0
	hit_times.append(now)
	hit_times = hit_times.filter(func(t2): return now - t2 < 1.4)
	if hit_times.size() >= 3 and not dead and dodge_cd <= 0.0 and randf() < skill * 0.55 and info.get("attacker") is Node3D and not has_status("bind"):
		hit_times.clear()
		state = "chase"
		_dodge(info["attacker"], false)
		if state == "dodge":
			Combat.popup_text(global_position + Vector3.UP * 2.2, "Sıyrıldı!", Color(0.8, 0.9, 1.0))


## Ceset ganimeti: para (eskiden doğrudan cebe giriyordu) + şansa göre merhem, asker hapı, kunai, shuriken, parşömen.
## Ceset "catchables" grubunda: yakında F -> üstünü ara.
func _make_loot() -> void:
	var lv = int(level)
	var l = {"ryo": int(ryo)}
	if randf() < 0.3: l["salve"] = 1
	if randf() < 0.12: l["pill"] = 1
	if randf() < 0.35: l["kunai"] = randi_range(1, 3)
	if randf() < 0.2: l["shuriken"] = randi_range(2, 5)
	if randf() < 0.06 + lv * 0.002: l["scroll"] = 1
	set_meta("loot", l)
	add_to_group("catchables")


var catch_label := "Üstünü ara"
func catch() -> void:
	if not has_meta("loot"):
		return
	var l: Dictionary = get_meta("loot")
	remove_meta("loot")
	remove_from_group("catchables")
	var pr = Game.profile
	var got = []
	if int(l.get("ryo", 0)) > 0:
		Progress.add_ryo(int(l["ryo"]))
		got.append("%d Ryō" % int(l["ryo"]))
	var inv: Dictionary = pr["inventory"]
	for k in ["salve", "pill", "kunai", "shuriken"]:
		if l.has(k):
			inv[k] = int(inv.get(k, 0)) + int(l[k])
			got.append("%s ×%d" % [{"salve": "Merhem", "pill": "Asker Hapı", "kunai": "Kunai", "shuriken": "Shuriken"}[k], int(l[k])])
	if l.has("scroll"):
		var opts = Progress.scroll_shop_items(6, 2)
		if not opts.is_empty():
			var iid = String(opts.pick_random())
			var jid = String(Data.items[iid]["jutsu"])
			if Progress.learn(jid, false):
				got.append("Parşömen: %s" % String(Data.jutsu[jid]["name"]))
	Hud.msg("Ganimet: " + (", ".join(got) if not got.is_empty() else "boş çıktı"), Color(1, 0.85, 0.4))
	Sfx.play("seal", global_position, 1.4, 0.4)
	FX.burst(global_position + Vector3.UP * 0.4, {"amount": 10, "life": 0.5, "size": 0.12, "vmin": 1.0, "vmax": 2.5, "colors": [Color(1, 0.85, 0.3, 1), Color(1, 0.85, 0.3, 0)]})


func die(info: Dictionary) -> void:
	if has_token:
		has_token = false
		attack_tokens = maxi(0, attack_tokens - 1)
	nameplate.visible = false
	if not has_meta("teammate") and size < 2.5:
		_make_loot()
	super.die(info)
	if has_meta("teammate"):
		return   # takım arkadaşı düştü: öldürme sayılmaz (XP, görev sayacı yok), yeniden doğmaz
	Progress.on_enemy_killed(self)
	if get_meta("respawn", true) and arch.get("respawn", true):
		var a = arch
		var h = home
		var parent = get_parent()
		parent.get_tree().create_timer(120.0).timeout.connect(func():
			if is_instance_valid(parent):
				var e = Enemy.new()
				e.setup(a)
				parent.add_child(e)
				e.global_position = h)
