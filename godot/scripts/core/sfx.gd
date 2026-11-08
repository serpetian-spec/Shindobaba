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
const QUIET := {"whoosh": 0.3, "wind": 0.35}
## Dosyası olmayan eski adlar -> var olan ses
const ALIAS := {"smoke": "poof"}


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
