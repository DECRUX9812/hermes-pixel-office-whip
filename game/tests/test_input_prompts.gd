extends TestCase

func test_default_device_is_keyboard() -> void:
	check_eq(InputPrompts.is_gamepad(), false, "defaults to keyboard")

func test_forced_gamepad_device() -> void:
	InputPrompts.set_device_for_test(InputPrompts.Device.GAMEPAD)
	check(InputPrompts.is_gamepad(), "gamepad device forced")
	InputPrompts.set_device_for_test(InputPrompts.Device.KEYBOARD)
	check(not InputPrompts.is_gamepad(), "keyboard device restored")

func test_keyboard_glyph_for_known_action() -> void:
	InputPrompts.set_device_for_test(InputPrompts.Device.KEYBOARD)
	var glyph := InputPrompts.glyph("jump")
	check(glyph.begins_with("[") and glyph.ends_with("]"), "jump glyph is bracketed: %s" % glyph)

func test_gamepad_glyph_for_known_action() -> void:
	InputPrompts.set_device_for_test(InputPrompts.Device.GAMEPAD)
	var glyph := InputPrompts.glyph("jump")
	check(glyph.begins_with("[") and glyph.ends_with("]"), "jump gamepad glyph is bracketed: %s" % glyph)

func test_unknown_action_glyph() -> void:
	InputPrompts.set_device_for_test(InputPrompts.Device.KEYBOARD)
	check_eq(InputPrompts.glyph("no_such_action"), "[?]", "unknown action renders [?]")

func test_device_signal_fires() -> void:
	var fired: Array[bool] = [false]
	var callback := func(_d: int) -> void: fired[0] = true
	InputPrompts.input_device_changed.connect(callback)
	InputPrompts.set_device_for_test(InputPrompts.Device.GAMEPAD)
	check(fired[0], "device change emitted")
	InputPrompts.input_device_changed.disconnect(callback)
	InputPrompts.set_device_for_test(InputPrompts.Device.KEYBOARD)
