extends Node
## Çok aşamalı olaylar: Chunin Sınavı (autoload "ChuninExam"). Rasengan eğitimi ayrı autoload'da aynı dosya sınıfıyla değil,
## RasenganTraining için rasengan_training.gd kullanılır.

var stage = 0
var rivals: Array = []

const QUIZ := [
	["Beş Büyük Ülke'nin gizli köyleri hangileridir?", ["Konoha, Suna, Kiri, Kumo, Iwa", "Konoha, Ame, Oto, Kusa, Taki", "Suna, Yu, Shimo, Tani, Kiri"], 0],
	["Su elementi hangi elemente karşı güçlüdür?", ["Rüzgar", "Ateş", "Yıldırım"], 1],
	["Mühür sistemi kaç temel el mührüne dayanır?", ["8", "10", "12"], 2],
	["Akademi'nin üç temel tekniği hangisidir?", ["Bunshin, Henge, Kawarimi", "Rasengan, Chidori, Shunshin", "Kuchiyose, Henge, Katon"], 0],
	["Bir Chunin'in tipik yelek rengi Konoha'da nedir?", ["Kırmızı", "Yeşil", "Siyah"], 1],
]
var answers_right = 0
var qi = 0


func apply() -> void:
	var pr = Game.profile
	if int(pr["rank"]) >= 2:
		Hud.dialog("Sınav Gözetmeni", "Sen zaten bir Chunin'sin. Stadyum turnuvaları yakında!", [])
		return
	if int(pr["level"]) < 10 or Progress.story() < 9:
		Hud.dialog("Sınav Gözetmeni", "Chunin Sınavı için en az Seviye 10 Genin olmalısın ve Yasak Parşömen görevini tamamlamış olmalısın.", [])
		return
	Progress.set_story(10)
	stage = 1
	qi = 0
	answers_right = 0
	Hud.dialog("Sınav Gözetmeni", "CHUNIN SINAVI 1. AŞAMA: Yazılı sınav. 5 sorudan en az 3'ünü doğru cevapla. Hile yapmak... yakalanmamak şartıyla serbest. Başla!", [{"label": "Başla", "cb": _ask}])


func _ask() -> void:
	if qi >= QUIZ.size():
		if answers_right >= 3:
			stage = 2
			Hud.dialog("Sınav Gözetmeni", "%d/5 doğru. Geçtin! 2. AŞAMA: Ölüm Ormanı. Elinde 'Gök Parşömeni' var. Rakip takımdan 'Yer Parşömeni'ni al ve ormanın merkezindeki kuleye ulaş!" % answers_right, [])
			Game.profile["inventory"]["scroll_heaven"] = 1
			_spawn_forest_rivals()
		else:
			stage = 0
			Progress.set_story(9)
			Hud.dialog("Sınav Gözetmeni", "%d/5 doğru. Kaldın. Daha çok çalış ve tekrar başvur." % answers_right, [])
		return
	var q: Array = QUIZ[qi]
	var opts = []
	for i in q[1].size():
		opts.append({"label": q[1][i], "cb": _answer.bind(i == q[2])})
	Hud.dialog("Soru %d/5" % (qi + 1), q[0], opts)


func _answer(right: bool) -> void:
	if right:
		answers_right += 1
	qi += 1
	_ask.call_deferred()


func _spawn_forest_rivals() -> void:
	var fd = Game.village("forest_death")
	var c = Game.from_map(Vector2(fd["x"] - 120, fd["y"]))
	rivals.clear()
	for i in 3:
		var e = Enemy.new()
		var a = Enemy.archetype("genin_rival", i)
		a["name"] = ["Kumo Genin Rai", "Kusa Genin Midori", "Ame Genin Shizuku"][i]
		a["respawn"] = false
		e.setup(a)
		if i == 0:
			e.set_meta("earth_scroll", true)
		get_tree().current_scene.add_child(e)
		var p = c + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
		p.y = Game.ground_height(p.x, p.z)
		e.global_position = p
		e.home = p
		rivals.append(e)
	Missions.target_marker = c
	Missions.has_marker = true
	Game.profile["active_mission"] = {"title": "Ölüm Ormanı", "desc": "Rakip genin'leri yen, Yer Parşömenini al ve kuleye git.", "type": "story", "rank": "C", "count": 1, "progress": 0}
	Hud.objective_changed()


func _process(_dt: float) -> void:
	if stage == 2:
		var have = int(Game.profile["inventory"].get("scroll_earth", 0)) > 0
		if not have:
			for r in rivals:
				if is_instance_valid(r) and r.dead and r.get_meta("earth_scroll", false):
					Game.profile["inventory"]["scroll_earth"] = 1
					Hud.banner("YER PARŞÖMENİ", "Şimdi kuleye git!", Color(0.9, 0.8, 0.5))
					var fd = Game.village("forest_death")
					Missions.target_marker = Game.from_map(Vector2(fd["x"], fd["y"]))
		elif Game.player:
			var fd = Game.village("forest_death")
			if Game.to_map(Game.player.global_position).distance_to(Vector2(fd["x"], fd["y"])) < 28.0:
				stage = 3
				_final()


func _final() -> void:
	Hud.dialog("Sınav Gözetmeni", "Kuleye ulaştın! 3. AŞAMA: Stadyumda final turnuvası. Seni oraya götürüyoruz...", [{"label": "Hazırım", "cb": _start_tournament}])


func _start_tournament() -> void:
	var v = Game.village("konoha")
	var arena = Game.from_map(Vector2(v["x"] + 260, v["y"] - 40))
	Game.player.respawn(arena + Vector3(0, 0.5, 15))
	rivals.clear()
	_next_duel(0, arena)


func _next_duel(i: int, arena: Vector3) -> void:
	if i >= 2:
		stage = 0
		Game.profile["active_mission"] = {}
		Game.profile["inventory"].erase("scroll_heaven")
		Game.profile["inventory"].erase("scroll_earth")
		Missions.has_marker = false
		Progress.promote(2)
		Progress.add_xp(800)
		Progress.add_ryo(1000)
		Progress.set_story(11)
		Hud.dialog(Progress.home_info()["kage"], "Turnuvadaki stratejin ve cesaretin takdire değer. Bugünden itibaren bir CHUNIN'sin!", [])
		return
	var e = Enemy.new()
	var a = Enemy.archetype("genin_rival", i + 1)
	a["name"] = ["Finalist Kaito", "Finalist Rin"][i]
	a["hp"] = 260.0 + i * 80.0
	a["level"] = 11 + i
	a["power"] = 1.5 + i * 0.3
	a["respawn"] = false
	e.setup(a)
	get_tree().current_scene.add_child(e)
	e.global_position = arena + Vector3(0, 0.5, -15)
	e.home = e.global_position
	Hud.banner("DÜELLO %d" % (i + 1), a["name"], Color(1, 0.6, 0.3))
	e.tree_exited.connect(func(): get_tree().create_timer(2.0).timeout.connect(func(): _next_duel(i + 1, arena)))
