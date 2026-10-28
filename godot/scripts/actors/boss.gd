class_name Boss
extends Enemy
## Boss'lar: süper zırh (poise), aşamalar, özel saldırılar. Raijū dev canavardır (dev kapsül hitbox).

var kind = ""
var special_cd = 4.0
var phase = 1
var beast_mesh: MeshInstance3D = null


static func make(k: String) -> Dictionary:
	var a = Enemy.archetype("rogue", 0)
	a["kind"] = "boss_" + k
	a["respawn"] = false
	a["boss"] = k
	match k:
		"raiju":
			a.merge({"name": "Raijū — Fırtına Canavarı", "hp": 2400.0, "level": 32, "power": 3.0, "element": "raiton", "size": 4.5,
				"speed": 12.0, "xp": 3000, "ryo": 0, "aggr": 0.9, "guard": 0.0, "sub": 0.0, "jutsu": [], "tools": false}, true)
		"puppeteer":
			a.merge({"name": "Kuklacı Mukuro", "hp": 1400.0, "level": 26, "power": 2.6, "element": "", "xp": 2200, "ryo": 0, "aggr": 0.7,
				"guard": 0.3, "sub": 0.2, "jutsu": ["fuuton_daitoppa"]}, true)
			a["look"].merge({"cloak": Color(0.12, 0.12, 0.15), "band_style": "slashed", "village": "suna", "hair": Color(0.6, 0.15, 0.15), "hair_style": "kısa"}, true)
	return a


func setup(a: Dictionary) -> void:
	super.setup(a)
	kind = a["boss"]
	poise = 1.0
	if kind == "raiju":
		look = null


func _ready() -> void:
	if kind == "raiju":
		radius = 0.75; height = 1.3
	super._ready()
	if kind == "raiju":
		_make_beast()
	nameplate.modulate = Color(1, 0.35, 0.3)
	Hud.boss_bar(self)


func _make_beast() -> void:
	# yıldırım kurdu: dev, parlayan yeleli, 3 kuyruklu
	var b = MB.new()
	var c = Color(0.25, 0.3, 0.45)
	b.add("sphere", Vector3(0, 1.0, 0), Vector3(1.2, 1.0, 2.2), c, Vector3.ZERO, 14)
	b.add("sphere", Vector3(0, 1.25, -1.2), Vector3(0.9, 0.85, 1.0), c, Vector3.ZERO, 12)
	b.add("box", Vector3(0, 1.1, -1.75), Vector3(0.45, 0.35, 0.6), c.lightened(0.1))
	for sx in [-1.0, 1.0]:
		b.add("cone", Vector3(0.28 * sx, 1.75, -1.15), Vector3(0.22, 0.45, 0.18), c, Vector3(0, 0, -15 * sx), 5)
		b.add("box", Vector3(0.22 * sx, 1.38, -1.62), Vector3(0.14, 0.05, 0.05), Color(1, 0.95, 0.3))
		for fz in [-0.7, 0.7]:
			b.add("cyl", Vector3(0.4 * sx, 0.4, fz), Vector3(0.28, 0.85, 0.28), c.darkened(0.15), Vector3.ZERO, 8)
	for i in 3:
		b.add("cone", Vector3((i - 1) * 0.3, 1.4, 1.5), Vector3(0.3, 1.6, 0.3), Color(0.5, 0.75, 1.0), Vector3(-60, (i - 1) * 25, 0), 6)
	for i in 6:
		b.add("cone", Vector3(randf_range(-0.3, 0.3), 1.7, -0.6 + i * 0.25), Vector3(0.2, 0.5, 0.2), Color(0.55, 0.8, 1.0), Vector3(randf_range(-20, 20), 0, randf_range(-20, 20)), 5)
	beast_mesh = MeshInstance3D.new()
	beast_mesh.mesh = b.build(Props.toon())
	beast_mesh.scale = Vector3.ONE * size
	add_child(beast_mesh)
	var arcs = Arcs.new()
	arcs.radius = 1.6 * size
	arcs.count = 8
	beast_mesh.add_child(arcs)
	arcs.position = Vector3(0, 1.2, 0)
	# model arayüzü olmadan da Fighter kodu çalışsın diye görünmez bir model
	model = CharacterModel.new()
	add_child(model)
	model.setup({})
	model.visible = false


func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	if dead or Game.player == null:
		return
	if beast_mesh:
		beast_mesh.rotation.y = facing + PI
	special_cd -= dt
	if hp < max_hp * 0.5 and phase == 1:
		phase = 2
		Hud.banner(display_name, "ÖFKELENDİ!", Color(1, 0.3, 0.2))
		poise = 2.0
		FX.ring(global_position + Vector3.UP, Color(1, 0.4, 0.3), 14.0, 0.5)
		Sfx.play("roar", global_position)
	if target and special_cd <= 0.0 and state in ["chase", "recover"]:
		special_cd = randf_range(4.0, 7.0) / phase
		_special()


func _special() -> void:
	match kind:
		"raiju":
			var r = randi() % 3
			if r == 0:  # kükreme: alan elektrik
				Sfx.play("roar", global_position)
				FX.ring(global_position + Vector3.UP * 0.5, Color(0.5, 0.75, 1), 22.0, 0.6)
				FX.light(global_position + Vector3.UP * 3, Color(0.5, 0.75, 1), 15, 40, 0.6)
				Combat.hit_sphere(self, global_position + Vector3.UP, 9.0, {"dmg": 30.0, "element": "raiton", "knock": 16.0, "launch": 6.0, "kind": "heavy", "stun": 0.8})
				if Game.world: Game.world.env.add_shake(1.2)
			elif r == 1:  # yıldırım küresi
				var pr = Projectile.new()
				pr.shooter = self
				pr.vel = (target.global_position + Vector3.UP - (global_position + Vector3.UP * 5)).normalized() * 22.0
				pr.radius = 2.0
				pr.homing = target
				pr.homing_turn = 1.2
				pr.info = {"dmg": 40.0, "element": "raiton", "knock": 18.0, "launch": 6.0, "kind": "heavy", "hitstop": 0.08}
				pr.add_child(Projectile.energy_mesh(Color(0.9, 0.95, 1), Color(0.3, 0.55, 1.0), 3.5, 8.0, 0.0, 3.0))
				pr.on_hit = func(pos: Vector3, _t: Node3D) -> void: FX.explosion(pos, 1.5, Color(0.5, 0.75, 1.0))
				get_tree().current_scene.add_child(pr)
				pr.global_position = global_position + Vector3.UP * 5.0
			else:  # hücum
				var d = (target.global_position - global_position)
				d.y = 0
				velocity = d.normalized() * 38.0
				Combat.popup_text(global_position + Vector3.UP * 8, "HÜCUM!", Color(1, 0.6, 0.3))
				get_tree().create_timer(0.35).timeout.connect(func():
					if not dead:
						Combat.hit_sphere(self, global_position + face_dir() * 4.0 + Vector3.UP * 2, 4.5, {"dmg": 35.0, "knock": 20.0, "launch": 7.0, "kind": "heavy", "hitstop": 0.1}))
		"puppeteer":
			Combat.popup_text(global_position + Vector3.UP * 2.6, "Kukla Tekniği!", Color(0.9, 0.7, 1))
			# gerçek savaş kuklaları (iplerle bağlı, eklemli; eskiden rengi değiştirilmiş haydutlardı)
			var n = 2 + phase - get_tree().get_nodes_in_group("clan_construct").filter(func(u): return u.owner_f == self and not u.dead).size()
			if n > 0:
				ClanConstruct.spawn(self, "puppet", n, {"tier": 3 + phase})


func take_hit(info: Dictionary) -> void:
	super.take_hit(info)
	Hud.boss_bar(self)


func die(info: Dictionary) -> void:
	super.die(info)
	Hud.boss_bar(null)
	if kind == "raiju":   # Raijū bir çağrı canavarı: mühürlenmez (yalnız kuyruklu canavarlar mühürlenir), yenilince dağılır
		Hud.banner("RAIJŪ DAĞILDI", "Fırtına dindi. Kanyonda bir kudretli chakra kalıntısı kaldı.", Color(0.5, 0.8, 1.0))
