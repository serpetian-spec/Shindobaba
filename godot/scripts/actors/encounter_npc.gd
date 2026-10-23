class_name EncounterNPC
extends QuestNPC
## Yol karşılaşması NPC'si (Encounters doğurur): konuşunca karşılaşmanın kendi diyaloğunu açar.

var on_talk: Callable


func talk() -> void:
	if Game.player:
		var to = Game.player.global_position - global_position
		facing = atan2(-to.x, -to.z)
		model.rotation.y = facing
	if mode != "cower":
		model.play("talk", 0.2)
	if on_talk.is_valid():
		on_talk.call(self)
	elif line != "":
		Hud.dialog(display, line, [])
