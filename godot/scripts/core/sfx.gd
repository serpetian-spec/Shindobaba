extends Node
## Ses (autoload "Sfx"): sentezlenmiş efektler (3D konumlu) + müzik geçişleri.

var streams = {}
## Gerçek ses varyantları (CC0 paketlerinden, assets/sfx/<ad>_vN.ogg): aynı olay her seferinde farklı varyantla çalar
var variants := {}
var _last := {}
var pool: Array[AudioStreamPlayer3D] = []
var pool2d: Array[AudioStreamPlayer] = []
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var music_name = ""
## Rahatsız edici savuruş/rüzgâr sesleri arka planda kısık çalar
const QUIET := {"whoosh": 0.3, "wind": 0.35, "jutsu_cast": 0.35, "leap": 0.35, "seal": 0.6, "sharingan": 0.4}   # kullanıcı: jutsu atma ve Ctrl sıçrama sesi diğerlerine göre aşırı
## Dosyası olmayan eski adlar -> var olan ses
const ALIAS := {"smoke": "poof", "hit": "punch"}   # hit: temel yumruk sesi (kullanıcı: en güzeli o)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dir = DirAccess.open("res://assets/sfx")
	if dir:
		for f in dir.get_files():
			var base = f.get_basename()
			if f.ends_with(".wav.import") or f.ends_with(".wav"):
				base = f.replace(".import", "").get_basename()
				if not streams.has(base):
					streams[base] = load("res://assets/sfx/" + base + ".wav")
			elif f.ends_with(".mp3.import"):
				base = f.replace(".import", "").get_basename()
				if not streams.has(base):
					var st = load("res://assets/sfx/" + base + ".mp3")
					if st is AudioStreamMP3:
						st.loop = false
					streams[base] = st
	var vd = DirAccess.open("res://assets/sfx")
	if vd:
		for f in vd.get_files():
			var fn = f.replace(".import", "")
			if not fn.ends_with(".ogg"):
				continue
			var base = fn.get_basename()
			var k = base.rfind("_v")
			if k < 0 or not base.substr(k + 2).is_valid_int():
				continue
			var key = base.substr(0, k)
			if not variants.has(key):
				variants[key] = []
			var st = load("res://assets/sfx/" + fn)
			if st and not (variants[key] as Array).has(st):
				(variants[key] as Array).append(st)
	for i in 24:
		var p = AudioStreamPlayer3D.new()
		p.unit_size = 12.0
		p.max_distance = 120.0
		add_child(p)
		pool.append(p)
	for i in 6:
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool2d.append(p)
	music_a = AudioStreamPlayer.new(); add_child(music_a)
	music_b = AudioStreamPlayer.new(); add_child(music_b)


## Varyantlı ses seçimi: "step_dirt2" gibi numaralı eski adlar da kök ada ("step_dirt") düşer; son çalınanı tekrarlamaz
func _pick(name: String):
	var key = name
	if not variants.has(key):
		var i = key.length()
		while i > 0 and key[i - 1] >= "0" and key[i - 1] <= "9":
			i -= 1
		key = key.substr(0, i)
	if not variants.has(key):
		key = String(ALIAS.get(key, key))
		if variants.has(key):
			return (variants[key] as Array).pick_random()
		return streams.get(name, streams.get(key, null))
	var arr: Array = variants[key]
	if arr.size() == 1:
		return arr[0]
	var j = randi() % arr.size()
	if j == int(_last.get(key, -1)):
		j = (j + 1) % arr.size()
	_last[key] = j
	return arr[j]


func play(name: String, pos = null, pitch := 1.0, vol := 1.0) -> void:
	var stream = _pick(name)
	if stream == null:
		return
	var v = float(Game.settings["sfx"]) * vol * float(QUIET.get(name, 1.0))
	if v <= 0.01:
		return
	if pos == null:
		for p in pool2d:
			if not p.playing:
				p.stream = stream; p.pitch_scale = pitch; p.volume_db = linear_to_db(v); p.play()
				return
		return
	for p in pool:
		if not p.playing:
			p.stream = stream
			p.global_position = pos
			p.pitch_scale = pitch * randf_range(0.95, 1.05)
			p.volume_db = linear_to_db(v)
			p.play()
			return


## Tema sesleri (kullanıcı: "animedeki değişik şeylerin hepsine özel ses"): klan / doğa / jutsu adına göre (th_<tema>_vN.ogg)
const CLAN_TH := {"aburame": "th_bugs", "kamizuru": "th_bees", "sabaku": "th_sand", "inuzuka": "th_dog", "akimichi": "th_growth",
	"hyuga": "th_palm", "nara": "th_shadow", "yamanaka": "th_shadow", "kaguya": "th_bone", "iburi": "th_smoke", "yuki": "th_ice",
	"jugo": "growl", "shirogane": "th_puppet", "chinoike": "th_flesh"}
const ELEM_TH := {"hyoton": "th_ice", "futton": "th_steam", "yoton": "th_lava", "bakuton": "th_clay", "jiton": "th_sand", "shoton": "th_ice", "mokuton": "earth"}
const ID_TH := [["mushi", "th_bugs"], ["kikai", "th_bugs"], ["hachi", "th_bees"], ["suna", "th_sand"], ["sabaku", "th_sand"], ["satetsu", "th_sand"],
	["sawarabi", "th_bone"], ["hone", "th_bone"], ["teshi_sendan", "th_bone"], ["yanagi", "th_bone"], ["tsubaki", "th_bone"], ["karamatsu", "th_bone"], ["tessenka", "th_bone"],
	["shikigami", "th_paper"], ["kami_", "th_paper"], ["choju_giga", "th_ink"], ["chojugiga", "th_ink"], ["sumi", "th_ink"], ["nendo", "th_clay"], ["kibaku", "th_clay"],
	["kugutsu", "th_puppet"], ["chikamatsu", "th_puppet"], ["akahigi", "th_puppet"], ["shirohigi", "th_puppet"], ["kurohigi", "th_puppet"],
	["gatsuga", "th_dog"], ["tsuga", "th_dog"], ["garoga", "th_dog"], ["gama", "th_frog"], ["kawazu", "th_frog"],
	["hebi", "th_snake"], ["jahaku", "th_snake"], ["senei_ta", "th_snake"], ["senei_ja", "th_snake"], ["manda", "th_snake"], ["yamata", "th_snake"],
	["karasu", "th_crow"], ["kage_mane", "th_shadow"], ["kagemane", "th_shadow"], ["kage_kubi", "th_shadow"], ["kage_nui", "th_shadow"], ["kage_shibari", "th_shadow"],
	["hiraishin", "th_teleport"], ["baika", "th_growth"], ["nikudan", "th_growth"], ["chodan", "th_growth"],
	["kaiten", "th_palm"], ["hakke", "th_palm"], ["juken", "th_palm"], ["kusho", "th_palm"], ["kemuri", "th_smoke"], ["hanachiri", "th_leaves"], ["konoha", "th_leaves"],
	["hyoton", "th_ice"], ["futton", "th_steam"], ["yoton", "th_lava"]]
## Dövüş tarzı vuruş sesi: [tema, perde] — her adımda hafif, bitirişte (5) tam
const STYLE_TH := {"style_aburame": ["th_bugs", 1.0], "style_kamizuru": ["th_bees", 1.0], "style_sabaku": ["th_sand", 1.0], "style_jin_shukaku": ["th_sand", 0.85],
	"style_inuzuka": ["th_dog", 1.0], "style_akimichi": ["th_growth", 1.0], "style_juken": ["th_palm", 1.0], "style_nara": ["th_shadow", 1.1],
	"style_kaguya": ["th_bone", 1.0], "style_iburi": ["th_smoke", 1.0], "style_yuki": ["th_ice", 1.0], "style_jugo": ["growl", 1.0],
	"style_akasuna": ["th_puppet", 1.0], "style_kagit": ["th_paper", 1.0], "style_sumi": ["th_ink", 1.0], "style_kil": ["th_clay", 1.0],
	"style_senju": ["earth", 1.0], "style_gama": ["th_frog", 1.0], "style_yilan": ["th_snake", 1.0], "style_hiraishin": ["th_teleport", 1.2], "style_rinnegan": ["th_shadow", 1.25],
	"style_chidori": ["zap", 1.1], "style_hatake": ["zap", 1.2], "style_kurosuki": ["zap", 1.0], "style_yotsuki": ["zap", 0.9],
	"style_jashin": ["th_flesh", 1.0], "style_kakuzu": ["th_flesh", 0.9], "style_uzumaki": ["chain", 1.0], "style_hozuki": ["water", 1.1],
	"style_uchiha": ["fire", 1.2], "style_sarutobi": ["fire", 1.0], "style_tip": ["heal", 1.2], "style_kunai": ["blade", 1.1], "style_silah": ["blade", 1.0],
	"style_bulk": ["hit_heavy", 0.9], "style_kapi": ["wind", 0.9], "style_tok": ["punch", 1.0], "style_hachibi": ["roar", 1.1],
	"style_jin_matatabi": ["fire", 0.9], "style_jin_isobu": ["water", 0.8], "style_jin_son_goku": ["th_lava", 1.0], "style_jin_kokuo": ["th_steam", 1.0],
	"style_jin_saiken": ["th_ink", 0.8], "style_jin_chomei": ["th_bugs", 0.8], "style_jin_gyuki": ["roar", 1.0], "style_jin_kurama": ["roar", 0.9]}


func theme_for_jutsu(id: String) -> String:
	var jv = Data.jutsu.get(id, {})
	var j: Dictionary = jv if jv is Dictionary else {}
	var cl = String(j.get("clan", ""))
	if CLAN_TH.has(cl):
		return CLAN_TH[cl]
	var el = String(j.get("element", ""))
	if ELEM_TH.has(el):
		return ELEM_TH[el]
	for kv in ID_TH:
		if id.contains(kv[0]):
			return kv[1]
	return ""


func play_jutsu_theme(id: String, pos: Vector3) -> void:
	var th = theme_for_jutsu(id)
	if th != "":
		play(th, pos, randf_range(0.95, 1.05), 0.75)


func play_style(id: String, step: int, pos: Vector3) -> void:
	var st: Array = STYLE_TH.get(id, [])
	if st.is_empty():
		return
	var fin = step >= 5
	play(String(st[0]), pos, float(st[1]) * (0.88 if fin else randf_range(0.97, 1.1)), 0.9 if fin else 0.5)


func music(name: String) -> void:
	if name == music_name or not streams.has(name):
		return
	music_name = name
	var old = music_a
	music_a = music_b
	music_b = old
	var s: AudioStreamWAV = streams[name]
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = int(s.get_length() * s.mix_rate)
	music_a.stream = s
	music_a.volume_db = -60
	music_a.play()
	var target = linear_to_db(maxf(0.001, float(Game.settings["music"]) * 0.6))
	var tw = create_tween().set_parallel(true)
	tw.tween_property(music_a, "volume_db", target, 2.0)
	tw.tween_property(music_b, "volume_db", -60.0, 2.0)
	tw.chain().tween_callback(music_b.stop)
