extends Node
var main: Node
func _ready() -> void:
	var m = CharacterModel.new()
	main.add_child(m)
	m.setup({"gender": "m"})
	var want = ["a/Sword_Attack", "a/Punch_Jab", "a/Spell_Simple_Shoot", "b/Sword_Regular_A", "b/Sword_Regular_B", "b/Sword_Regular_C", "b/Sword_Regular_Combo", "b/Sword_Dash_RM", "b/Melee_Hook", "b/OverhandThrow", "b/Shield_OneShot", "b/TreeChopping", "b/Farm_Harvest", "b/Zombie_Scratch"]
	for w in want:
		print("ANIM ", w, " ", m.anim.has_animation(w), " ", m.anim.get_animation(w).length if m.anim.has_animation(w) else -1)
	get_tree().quit()
