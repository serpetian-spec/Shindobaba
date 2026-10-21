extends Node
## Aktör oluşturma (autoload "Spawner"). Dünya kurulurken istekler sıraya alınır, oyun başlayınca yaratılır.

var pending: Array = []
var ready_to_spawn = false


func dummy(pos: Vector3) -> void:
	pending.append(["dummy", pos])


func camp(pos: Vector3, kind: String, count: int) -> void:
	pending.append(["camp", pos, kind, count])


func flush(parent: Node3D) -> void:
	for p in pending:
		match p[0]:
			"dummy":
				var d = TrainingDummy.new()
				parent.add_child(d)
				d.global_position = p[1]
			"camp":
				for i in p[3]:
					var e = Enemy.new()
					e.setup(Enemy.archetype(p[2], i))
					parent.add_child(e)
					e.global_position = p[1] + Vector3(randf_range(-18, 18), 0, randf_range(-18, 18))
					e.home = e.global_position
	pending.clear()
