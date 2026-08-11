extends Node
## User settings: subtitles (accessibility), camera sensitivity, invert Y,
## master volume. Persisted to a ConfigFile under user://.

signal settings_changed(key: String, value: Variant)

const SAVE_PATH := "user://last_open_door_settings.cfg"

var subtitles_enabled := true
var camera_sensitivity := 1.0
var invert_y := false
var master_volume := 1.0

func _ready() -> void:
	load_settings()
	apply_audio()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	subtitles_enabled = cfg.get_value("display", "subtitles_enabled", subtitles_enabled)
	camera_sensitivity = cfg.get_value("camera", "sensitivity", camera_sensitivity)
	invert_y = cfg.get_value("camera", "invert_y", invert_y)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "subtitles_enabled", subtitles_enabled)
	cfg.set_value("camera", "sensitivity", camera_sensitivity)
	cfg.set_value("camera", "invert_y", invert_y)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.save(SAVE_PATH)

func set_subtitles_enabled(value: bool) -> void:
	subtitles_enabled = value
	settings_changed.emit("subtitles_enabled", value)
	save_settings()

func set_camera_sensitivity(value: float) -> void:
	camera_sensitivity = clampf(value, 0.1, 3.0)
	settings_changed.emit("camera_sensitivity", camera_sensitivity)
	save_settings()

func set_invert_y(value: bool) -> void:
	invert_y = value
	settings_changed.emit("invert_y", value)
	save_settings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit("master_volume", master_volume)
	apply_audio()
	save_settings()

func apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(maxf(master_volume, 0.0001)))
