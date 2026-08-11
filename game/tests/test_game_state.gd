extends TestCase

func test_flags_round_trip() -> void:
	var state := get_node("/root/GameState")
	state.set_flag("nous_trust", 2)
	check_eq(state.get_flag("nous_trust", 0), 2, "flag set then read")
	state.set_flag("saw_reconstruction", true)
	check_eq(state.get_flag("saw_reconstruction"), true, "bool flag read")
	check_eq(state.get_flag("missing", "default"), "default", "missing flag returns default")
	state.flags = {}

func test_checkpoint_record_and_getters() -> void:
	var state := get_node("/root/GameState")
	state.record_checkpoint("res://scenes/world/chapter2_choir_below.tscn", Vector3(1, 2, 3), 1.5)
	check(state.has_checkpoint(), "checkpoint recorded")
	check_eq(state.get_checkpoint_position(), Vector3(1, 2, 3), "position read back")
	check(is_equal_approx(state.get_checkpoint_rotation(), 1.5), "rotation read back")
	state.last_checkpoint = {}

func test_save_load_round_trip() -> void:
	var state := get_node("/root/GameState")
	state.record_checkpoint("res://x.tscn", Vector3(5, 6, 7), 0.25)
	state.set_flag("street_allegiance", "exposed")
	state.save_game()
	state.last_checkpoint = {}
	state.flags = {}
	var loaded_ok: bool = state.load_game()
	check(loaded_ok, "save file loaded")
	check_eq(state.last_checkpoint.get("position", Vector3.ZERO), Vector3(5, 6, 7), "save/load position")
	check_eq(state.get_flag("street_allegiance", ""), "exposed", "save/load flag")
	state.delete_save()
	state.last_checkpoint = {}
	state.flags = {}
