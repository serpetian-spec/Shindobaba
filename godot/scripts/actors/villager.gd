class_name Villager
extends Fighter
## Köy halkı. Roller: walker, kid, chat, vendor, sitter, patrol, roof. [F] ile konuşulur.

const LINES := {
	"walker": ["Bugün hava çok güzel, değil mi?", "Ichiraku'nun yeni ramen tarifi efsaneymiş!", "Hokage Kulesi'nde yine görev kuyruğu var.",
		"Pazardan taze balık aldım, akşam ızgara yapacağım.", "Son zamanlarda sınırda tuhaf ninjalar görülüyormuş... dikkatli ol.",
		"Kayadaki yüzlere her bakışımda içim ısınıyor."],
	"kid": ["Hey! Sen de akademidensin değil mi? Yarışalım mı?", "Ben büyüyünce Hokage olacağım!", "Kawarimi'yi daha yapamıyorum, hep kütük düşüyor...",
		"Shuriken atmayı öğretir misin? Lütfeeen!", "Saklambaç oynuyoruz, sen ebesin!", "Annem akademiden sonra eve gel dedi ama..."],
	"chat": ["...ve sonra Chunin sınavında rakibini tek hamlede yenmiş!", "Duydun mu? Kumo'dan elçiler gelmiş.", "Fiyatlar yine artmış, bu Ryō nereye gidiyor?",
		"Oğlum Genin oldu, gururluyum!"],
	"vendor": ["Taze sebzeler! Bugün toplandı!", "Kunai, shuriken! Akademi öğrencilerine indirim!", "Dango, sıcacık dango!", "Ninja çantası lazım mı? En sağlamı bende!"],
	"sitter": ["Biraz dinleniyorum... Gençler hep koşturuyor.", "Benim gençliğimde savaş vardı, şimdi barış... kıymetini bilin.", "Bu bankta oturup köyü izlemeyi seviyorum."],
	"patrol": ["Devriyedeyiz. Bir sorun görürsen haber ver.", "Akademi öğrencisi misin? Çok çalış, Ateşin İradesi seninle.", "Kapıdan çıkarken dikkatli ol, ormanlar tehlikeli."],
	"roof": ["Çatılar en hızlı yol! Yakala beni!"],
}

var role := "walker"
var home := Vector3.ZERO
var goal := Vector3.ZERO
var wait := 0.0
var speed := 2.6
var buddy: Node3D = null
var points: Array = []      # sokak noktaları / çatılar (yönetici verir)
var hop_t := -1.0
var hop_from := Vector3.ZERO
var hop_to := Vector3.ZERO
var display := "Köylü"


func _ready() -> void:
	team = "neutral"
	var tops := [Color(0.5, 0.6, 0.45), Color(0.6, 0.35, 0.3), Color(0.8, 0.75, 0.55), Color(0.4, 0.45, 0.6), Color(0.7, 0.55, 0.65),
		Color(0.85, 0.85, 0.85), Color(0.55, 0.3, 0.45), Color(0.9, 0.6, 0.3)]
	var t: Color = tops.pick_random()
	var lk = {"gender": ["m", "f"].pick_random(), "top": t, "top2": t.darkened(0.12), "pants": [Color(0.35, 0.3, 0.28), Color(0.2, 0.22, 0.3), Color(0.4, 0.35, 0.25)].pick_random(),
		"band": null, "hair_style": ["kısa", "uzun", "atkuyruğu", "kase", "dağınık", "diken"].pick_random(),
		"hair": [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.6, 0.6, 0.62), Color(0.75, 0.45, 0.2), Color(0.85, 0.75, 0.4)].pick_random(),
		"sleeves": randf() < 0.6, "pants_style": "sivil", "sandal": Color(0.3, 0.22, 0.15), "skin": [Color(0.96, 0.8, 0.66), Color(0.88, 0.7, 0.55), Color(0.98, 0.86, 0.75)].pick_random()}
	match role:
		"kid":
			lk["age"] = "child"
			speed = 6.5
			display = "Çocuk"
		"patrol", "roof":
			lk.merge({"vest": Color(0.38, 0.48, 0.28), "top": Color(0.18, 0.22, 0.3), "top2": Color(0.18, 0.22, 0.3), "pants": Color(0.18, 0.22, 0.3),
				"band": Color(0.15, 0.22, 0.55), "age": "adult"}, true)
			speed = 4.5 if role == "patrol" else 14.0
			display = "Konoha Chunin"
		"sitter":
			lk["hair"] = Color(0.8, 0.8, 0.82)
			lk["age"] = "adult"
			display = "Yaşlı Köylü"
		"vendor":
			display = "Satıcı"
		_:
			lk["age"] = ["adult", "adult", "young", "teen"].pick_random()
	look = lk
	super._ready()
	remove_from_group("fighters")
	add_to_group("talkers")
	collision_layer = 4
	if model and look.get("age", "adult") != "adult":
		model.apply_age(look["age"])
		radius *= model.age_scale
		height *= model.age_scale
	goal = global_position
	home = global_position


func talk() -> void:
	var pool: Array = LINES.get(role, LINES["walker"])
	if Game.player:
		var to = Game.player.global_position - global_position
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
	model.play("talk", 0.2)
	wait = 4.0
	Hud.dialog(display, pool.pick_random(), [])


func _physics_process(dt: float) -> void:
	if Game.paused or Game.player == null:
		return
	var dist = global_position.distance_to(Game.player.global_position)
	if dist > 65.0:
		# uzaktakiler: animasyon ve hareket durur (performans)
		if model.anim.is_playing():
			model.anim.pause()
		return
	elif not model.anim.is_playing():
		model.anim.play()
	match role:
		"roof":
			_roof(dt)
			return
		"vendor", "sitter":
			step_move(Vector3.ZERO, dt, false)
			model.play("sit" if role == "sitter" else ("talk" if fmod(Time.get_ticks_msec() * 0.001 + home.x, 9.0) < 4.0 else "fold"), 0.3)
			return
		"chat":
			step_move(Vector3.ZERO, dt, false)
			if buddy and is_instance_valid(buddy):
				var to = buddy.global_position - global_position
				facing = atan2(-to.x, -to.z)
				model.rotation.y = facing
			model.play("talk" if fmod(Time.get_ticks_msec() * 0.001 + home.z, 6.0) < 3.0 else "idle", 0.3)
			return
	if wait > 0.0:
		wait -= dt
		step_move(Vector3.ZERO, dt)
		model.play("idle", 0.3)
		return
	var v = goal - global_position
	v.y = 0
	if v.length() < 1.5:
		_new_goal()
		return
	step_move(v.normalized() * speed, dt)
	model.play("run" if speed > 5.0 else "walk", 0.2, 1.0)
	if is_on_wall():
		_new_goal()


func _new_goal() -> void:
	match role:
		"kid":
			# kovalamaca: ev noktası etrafında hızlı koşuşturma
			goal = home + Vector3(randf_range(-14, 14), 0, randf_range(-14, 14))
			wait = randf_range(0.0, 0.6)
			if randf() < 0.15:
				Sfx.play("jump", global_position, 1.5, 0.4)
		_:
			if not points.is_empty() and randf() < 0.8:
				goal = points.pick_random()
			else:
				goal = home + Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))
			wait = randf_range(0.5, 6.0) if role == "walker" else randf_range(0.0, 1.0)


## Çatıdan çatıya sekerek koşan ninja
func _roof(dt: float) -> void:
	if points.size() < 2:
		return
	if hop_t < 0.0:
		var best: Vector3 = points[0]
		var bd = 1e9
		for i in 6:
			var q: Vector3 = points.pick_random()
			var d = q.distance_to(global_position)
			if d > 8.0 and d < 40.0 and d < bd:
				bd = d; best = q
		if bd > 1e8:
			best = points.pick_random()
			global_position = best
			return
		hop_from = global_position
		hop_to = best
		hop_t = 0.0
		var to = hop_to - hop_from
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
		model.play("jump", 0.05, 1.4, true)
	var dur = maxf(0.6, hop_from.distance_to(hop_to) / speed)
	hop_t += dt / dur
	var k = clampf(hop_t, 0.0, 1.0)
	var p = hop_from.lerp(hop_to, k)
	p.y += sin(k * PI) * (4.0 + hop_from.distance_to(hop_to) * 0.15)
	global_position = p
	if k > 0.25 and k < 0.9:
		model.play("air", 0.2)
	if hop_t >= 1.0:
		hop_t = -1.0
		model.play("land", 0.05, 1.5, true)
		if randf() < 0.3:
			hop_t = -0.4  # kısa bekleme (negatif sayaç)
