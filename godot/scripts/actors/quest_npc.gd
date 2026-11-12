class_name QuestNPC
extends Fighter
## Görev NPC'si: konuşulan tanık/müşteri, eskort edilen tüccar, kurtarılan rehine, bakıcılık çocuğu.
## mode: "idle" (durur, konuşur), "escort" (path boyunca yürür, oyuncuyu bekler), "follow" (oyuncuyu izler),
## "kid" (etrafta koşturur), "cower" (çömelir)

var display := "Köylü"
var mode := "idle"
var path: Array = []          # escort: Vector3 noktaları
var path_i := 0
var speed := 3.0
var home := Vector3.ZERO
var goal := Vector3.ZERO
var wait := 0.0
var quest_tag := ""           # Missions hangi adıma ait olduğunu bilsin
var line := ""                # sabit replik (Missions.on_quest_talk ele almazsa)
var label3d: Label3D
var nav := {}                 # NpcNav durumu (engelden dolaşma, takılma)
var stuck_n := 0
var hold_anim := ""           # beklerken oynatılacak animasyon (pusu sırasında sinme: "crouch")


func _ready() -> void:
	if look.is_empty():
		look = Outfits.roll("civ", Outfits.village_near())
		look.merge({"gender": ["m", "f"].pick_random(), "hair_style": ["kısa", "uzun", "kase"].pick_random(), "age": "adult"}, true)
	super._ready()
	add_to_group("talkers")
	if team == "neutral":
		remove_from_group("fighters")
	collision_layer = 4
	home = global_position
	goal = home
	if model and look.get("age", "adult") != "adult":
		model.apply_age(look["age"])
	label3d = Label3D.new()
	label3d.text = display
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# dünya boyutunda isim: uzaktan dev görünmez, mesafeyle söner
	label3d.fixed_size = false
	label3d.pixel_size = 0.005
	label3d.visibility_range_end = 35.0
	label3d.visibility_range_end_margin = 6.0
	label3d.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	label3d.font_size = 34
	label3d.outline_size = 8
	label3d.modulate = Color(1.0, 0.85, 0.4)
	label3d.position.y = height * (model.age_scale if model else 1.0) + 0.45
	add_child(label3d)


func talk() -> void:
	if Game.player:
		var to = Game.player.global_position - global_position
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
	model.play("talk", 0.2)
	if not Missions.on_quest_talk(self) and line != "":
		Hud.dialog(display, line, [])


func die(info: Dictionary) -> void:
	super.die(info)
	Missions.on_quest_npc_died(self)


## Takıldı: duman bulutuyla engelin ötesine sıçrar (ninja gibi), sonra yoluna devam eder
func _hop_to(q: Vector3) -> void:
	stuck_n = 0
	q = Missions.open_ground(q, 6.0)
	q.y = Game.ground_height(q.x, q.z)
	FX.smoke_puff(global_position + Vector3.UP, 0.6, 8)
	global_position = q
	velocity = Vector3.ZERO
	FX.smoke_puff(q + Vector3.UP, 0.6, 8)
	NpcNav.reset(self)


func _physics_process(dt: float) -> void:
	if Game.paused or dead or Game.player == null:
		return
	tick_status(dt)
	state_t += dt
	if state in ["hitstun", "knockdown"]:
		step_move(Vector3.ZERO, dt, false)
		if state_t > 0.6:
			state = "idle"
		return
	var pl = Game.player
	var dpl = global_position.distance_to(pl.global_position)
	match mode:
		"escort":
			if path_i >= path.size() or dpl > 16.0 or wait > 0.0:
				wait -= dt
				step_move(Vector3.ZERO, dt)
				model.play(hold_anim if hold_anim != "" else "idle", 0.25)
				return
			var v: Vector3 = path[path_i] - global_position
			v.y = 0
			if v.length() < 2.0:
				path_i += 1
				NpcNav.reset(self)
				return
			# engelden (bina, sur, çit, ağaç) dolaş; yine de ilerleyemezse duvarın ardına geç (eskiden duvara takılıp kalıyordu)
			step_move(NpcNav.steer(self, v.normalized(), dt) * speed, dt)
			model.play("walk", 0.2)
			if NpcNav.stuck(self, path[path_i], dt):
				stuck_n += 1
				if stuck_n >= 2:
					_hop_to(global_position + v.normalized() * minf(v.length(), 8.0))
		"follow":
			var v = pl.global_position - global_position
			v.y = 0
			if v.length() > 3.0:
				step_move(NpcNav.steer(self, v.normalized(), dt) * minf(10.0, 2.5 + v.length() * 0.8), dt)
				model.play("run" if v.length() > 6.0 else "walk", 0.2)
				if NpcNav.stuck(self, pl.global_position, dt):
					stuck_n += 1
					if stuck_n >= 2 or v.length() > 30.0:
						_hop_to(pl.global_position - pl.face_dir() * 2.5 if pl.has_method("face_dir") else pl.global_position)
			else:
				stuck_n = 0
				step_move(Vector3.ZERO, dt)
				model.play("idle", 0.25)
		"kid":
			wait -= dt
			var v = goal - global_position
			v.y = 0
			if v.length() < 1.2 or wait < -6.0:
				goal = home + Vector3(randf_range(-22, 22), 0, randf_range(-22, 22))
				wait = randf_range(0.0, 1.2)
			if wait > 0.0:
				step_move(Vector3.ZERO, dt)
				model.play("idle", 0.2)
			else:
				step_move(v.normalized() * 6.0, dt)
				model.play("run", 0.2)
		"cower":
			step_move(Vector3.ZERO, dt, false)
			model.play("crouch", 0.25)
		"march":
			# yürüyen takım (AmbientTeams): goal'e yürür; yöneticisi goal'i her an günceller
			var v = goal - global_position
			v.y = 0
			if v.length() > 1.4:
				step_move(NpcNav.steer(self, v.normalized(), dt) * speed, dt)
				model.play("jog" if speed > 4.5 else "walk", 0.2)
				facing = atan2(-v.x, -v.z)
				model.rotation.y = facing
			else:
				step_move(Vector3.ZERO, dt)
				model.play("idle", 0.25)
		_:
			step_move(Vector3.ZERO, dt, false)
			if model.current not in ["talk"] or model.anim_progress() > 0.98:
				model.play("idle", 0.3)
	label3d.modulate.a = 1.0 if dpl < 35.0 else 0.0
