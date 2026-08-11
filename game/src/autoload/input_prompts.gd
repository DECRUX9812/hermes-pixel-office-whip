extends Node
## InputPrompts — device-aware prompt labels for the HUD and menus.
##
## Tracks whether the most recent input event came from a gamepad or from
## keyboard/mouse, and renders compact, consistent glyphs for any InputMap action.
## This is what makes "E interact / A interact" style prompts feel native on
## both controller and keyboard without any per-scene branching.
##
## Glyph language (kept minimal and accessibility-friendly; always paired with
## the action's meaning in nearby text, never icon-only):
##   Keyboard: the physical key name (E, Shift, F, Tab, Q ...)
##   Mouse:    LMB / RMB
##   Gamepad:  A B X Y LB RB LT RT START SELECT

signal input_device_changed(device: int)

enum Device { KEYBOARD, GAMEPAD }

const GAMEPAD_BUTTONS := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "SELECT",
	JOY_BUTTON_START: "START",
	JOY_BUTTON_DPAD_UP: "D-PAD UP",
	JOY_BUTTON_DPAD_DOWN: "D-PAD DOWN",
	JOY_BUTTON_DPAD_LEFT: "D-PAD LEFT",
	JOY_BUTTON_DPAD_RIGHT: "D-PAD RIGHT",
}

var device := Device.KEYBOARD

func _input(event: InputEvent) -> void:
	var next := _classify(event)
	if next != device:
		device = next
		input_device_changed.emit(device)

func _classify(event: InputEvent) -> int:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.GAMEPAD
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return Device.KEYBOARD
	return device

## Public, test-friendly entry point so unit tests can force a device without
## fabricating real input events.
func set_device_for_test(value: int) -> void:
	device = value
	input_device_changed.emit(device)

func is_gamepad() -> bool:
	return device == Device.GAMEPAD

## Returns a short glyph label for an InputMap action, e.g. "[E]", "[A]",
## "[LMB]", "[RB]". Returns "[?]" if the action or its first event is unknown.
func glyph(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "[?]"
	var event := events[0]
	if is_gamepad():
		var label := _gamepad_label(event)
		if label != "":
			return "[%s]" % label
		# Fall through: gamepad action also bound to a key uses the key glyph.
		var keyboard := _keyboard_label(event)
		if keyboard != "":
			return "[%s]" % keyboard
		return "[?]"
	var key := _keyboard_label(event)
	if key != "":
		return "[%s]" % key
	return "[?]"

func _gamepad_label(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return GAMEPAD_BUTTONS.get((event as InputEventJoypadButton).button_index, "")
	if event is InputEventJoypadMotion:
		var joy := event as InputEventJoypadMotion
		if joy.axis == JOY_AXIS_TRIGGER_LEFT:
			return "LT"
		if joy.axis == JOY_AXIS_TRIGGER_RIGHT:
			return "RT"
	return ""

func _keyboard_label(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	if event is InputEventMouseButton:
		return "LMB" if (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT else "RMB"
	return ""
