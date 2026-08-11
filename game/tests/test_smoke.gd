extends TestCase

var _smoke_done := false
var _smoke_passed := false

func test_smoke_scene_passes() -> void:
	_smoke_done = false
	_smoke_passed = false
	var scene: PackedScene = load("res://tests/smoke_test.tscn")
	var smoke := scene.instantiate()
	add_child(smoke)
	smoke.finished.connect(_on_smoke_finished)
	await get_tree().create_timer(45.0).timeout
	check(_smoke_done, "smoke scene finished within timeout")
	if _smoke_done:
		check(_smoke_passed, "smoke scene passed")
	smoke.finished.disconnect(_on_smoke_finished)

func _on_smoke_finished(passed: bool) -> void:
	_smoke_done = true
	_smoke_passed = passed
