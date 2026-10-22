class_name Pickup
extends Node3D
## Yerden toplanabilir parlayan eşya (yaklaşınca alınır).

var item = "herb"
var t = 0.0
var vis: MeshInstance3D


func _ready() -> void:
	global_position.y = Game.ground_height(global_position.x, global_position.z)
	vis = MeshInstance3D.new()
	var b = MB.new()
	match item:
		"herb":
			for k in 5:
				b.add("box", Vector3(0, 0.25, 0), Vector3(0.08, 0.5, 0.25), Color(0.35, 0.8, 0.4), Vector3(0, k * 36, 20))
			b.add("sphere", Vector3(0, 0.55, 0), Vector3(0.15, 0.15, 0.15), Color(0.95, 0.9, 0.4))
		_:
			b.add("box", Vector3(0, 0.3, 0), Vector3(0.4, 0.3, 0.3), Color(0.8, 0.6, 0.3))
	vis.mesh = b.build(Props.toon())
	add_child(vis)
	FX.aura(self, Color(0.6, 1.0, 0.5), 0.35, Vector3(0, 0.3, 0), 0.0)


func _process(dt: float) -> void:
	t += dt
	vis.rotation.y = t * 1.5
	vis.position.y = 0.1 + sin(t * 3.0) * 0.08
	if Game.player and Game.player.global_position.distance_to(global_position) < 1.8:
		var inv: Dictionary = Game.profile["inventory"]
		inv[item] = int(inv.get(item, 0)) + 1
		Hud.float_text("+1 %s" % Data.items.get(item, {"name": item})["name"], Color(0.6, 1, 0.6))
		Sfx.play("coin", global_position, 1.3)
		Missions.on_pickup(item)
		queue_free()
