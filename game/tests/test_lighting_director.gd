extends TestCase

var _director: LightingDirector = null

func _build_director() -> LightingDirector:
	var director := LightingDirector.new()
	add_child(director)
	return director

func _exit_tree() -> void:
	if _director and is_instance_valid(_director):
		_director.queue_free()
	_director = null

func test_rigs_have_expected_names() -> void:
	var director := _build_director()
	_director = director
	check_eq(director.rig_state(), "ice", "director starts on the ICE rig")
	director.apply_rig("weep", true)
	check_eq(director.rig_state(), "weep", "rig switches to weep")
	director.apply_rig("arena", true)
	check_eq(director.rig_state(), "arena", "rig switches to arena")

func test_unknown_rig_rejected() -> void:
	var director := _build_director()
	_director = director
	director.apply_rig("bogus", true)
	check_eq(director.rig_state(), "ice", "unknown rig rejected")
