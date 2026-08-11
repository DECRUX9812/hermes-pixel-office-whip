extends SceneTree
## Headless test runner. Run from the game/ directory with:
##   godot4 --headless --path . -s res://tests/run_tests.gd
## Exits 0 on success, 1 on any failure.

const TEST_MODULES: Array[String] = [
	"res://tests/test_health.gd",
	"res://tests/test_resolve.gd",
	"res://tests/test_game_state.gd",
	"res://tests/test_interaction.gd",
	"res://tests/test_objective_flow.gd",
	"res://tests/test_checkpoint.gd",
	"res://tests/test_player.gd",
	"res://tests/test_melee_combo.gd",
	"res://tests/test_custodian.gd",
	"res://tests/test_companion.gd",
	"res://tests/test_encounter.gd",
	"res://tests/test_dialogue_runner.gd",
	"res://tests/test_script_dialogue.gd",
	"res://tests/test_slice_spine.gd",
	"res://tests/test_traversal_path.gd",
	"res://tests/test_synth.gd",
	"res://tests/test_audio_director.gd",
	"res://tests/test_input_prompts.gd",
	"res://tests/test_settings_extra.gd",
	"res://tests/test_lighting_director.gd",
	"res://tests/test_cinematic_camera.gd",
	"res://tests/test_combat_vfx.gd",
	"res://tests/test_smoke.gd",
]

var _passed := 0
var _failed := 0

func _initialize() -> void:
	call_deferred("_run_suite")

func _run_suite() -> void:
	for path in TEST_MODULES:
		await _run_module(path)
	print("")
	print("TEST SUMMARY: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		print("TEST RUN FAILED")
		quit(1)
	else:
		print("TEST RUN OK")
		quit(0)

func _run_module(path: String) -> void:
	print("== %s ==" % path.get_file())
	var script: GDScript = load(path)
	if script == null:
		_failed += 1
		push_error("failed to load %s" % path)
		return
	var instance: Node = script.new()
	root.add_child(instance)
	var method_names: Array[String] = []
	for entry in instance.get_method_list():
		var name := str(entry.name)
		if name.begins_with("test_"):
			method_names.append(name)
	method_names.sort()
	for method in method_names:
		instance.reset_failures()
		await instance.call(method)
		if instance.failures() > 0:
			_failed += 1
			print("  FAIL %s.%s" % [path.get_file(), method])
			for msg in instance.failed_messages():
				print("       - %s" % msg)
		else:
			_passed += 1
			print("  ok   %s.%s" % [path.get_file(), method])
	instance.queue_free()
	await process_frame
