class_name TestCase
extends Node
## Minimal assertion base for headless unit tests. Failures are recorded, never
## thrown, so a crashing assertion still reports cleanly in the summary.

var _failures: Array[String] = []

func check(condition: bool, message: String = "") -> bool:
	if not condition:
		_failures.append(message)
		push_error("ASSERT FAILED: %s" % message)
	return condition

func check_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	var ok: bool = actual == expected
	if not ok:
		var text := "%s | expected %s == %s" % [message, str(actual), str(expected)]
		_failures.append(text)
		push_error("ASSERT FAILED: %s" % text)
	return ok

func failures() -> int:
	return _failures.size()

func reset_failures() -> void:
	_failures.clear()

func failed_messages() -> Array[String]:
	return _failures.duplicate()

func _wait_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame

func _wait_physics(frames: int) -> void:
	for _i in frames:
		await get_tree().physics_frame
