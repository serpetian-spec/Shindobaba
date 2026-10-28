extends Node
## Ses (autoload "Sfx"): sentezlenmiş efektler (3D konumlu) + müzik geçişleri.

var streams = {}
var pool: Array[AudioStreamPlayer3D] = []
var pool2d: Array[AudioStreamPlayer] = []
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var music_name = ""


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


func play(name: String, pos = null, pitch := 1.0, vol := 1.0) -> void:
	if not streams.has(name):
		return
	var v = float(Game.settings["sfx"]) * vol
	if v <= 0.01:
		return
	if pos == null:
		for p in pool2d:
			if not p.playing:
				p.stream = streams[name]; p.pitch_scale = pitch; p.volume_db = linear_to_db(v); p.play()
				return
		return
	for p in pool:
		if not p.playing:
			p.stream = streams[name]
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
