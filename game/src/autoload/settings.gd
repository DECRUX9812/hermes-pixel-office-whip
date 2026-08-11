extends Node
## User settings: subtitles (accessibility), camera sensitivity, invert Y,
## master volume. Persisted to a ConfigFile under user://.

signal settings_changed(key: String, value: Variant)

const SAVE_PATH := "user://last_open_door_settings.cfg"

var subtitles_enabled := true
var subtitle_background := true
var subtitle_scale := 1.0
var camera_sensitivity := 1.0
var camera_fov := 70.0
var invert_y := false
var quality_preset := "high"
var master_volume := 1.0
var sfx_volume := 1.0
var music_volume := 0.7
var voice_volume := 1.0
var ambience_volume := 0.6

func _ready() -> void:
	load_settings()
	apply_audio()
	apply_quality()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	subtitles_enabled = cfg.get_value("display", "subtitles_enabled", subtitles_enabled)
	subtitle_background = cfg.get_value("display", "subtitle_background", subtitle_background)
	subtitle_scale = cfg.get_value("display", "subtitle_scale", subtitle_scale)
	camera_sensitivity = cfg.get_value("camera", "sensitivity", camera_sensitivity)
	camera_fov = cfg.get_value("camera", "fov", camera_fov)
	invert_y = cfg.get_value("camera", "invert_y", invert_y)
	quality_preset = cfg.get_value("rendering", "quality_preset", quality_preset)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	voice_volume = cfg.get_value("audio", "voice_volume", voice_volume)
	ambience_volume = cfg.get_value("audio", "ambience_volume", ambience_volume)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "subtitles_enabled", subtitles_enabled)
	cfg.set_value("display", "subtitle_background", subtitle_background)
	cfg.set_value("display", "subtitle_scale", subtitle_scale)
	cfg.set_value("camera", "sensitivity", camera_sensitivity)
	cfg.set_value("camera", "fov", camera_fov)
	cfg.set_value("camera", "invert_y", invert_y)
	cfg.set_value("rendering", "quality_preset", quality_preset)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.set_value("audio", "ambience_volume", ambience_volume)
	cfg.save(SAVE_PATH)

func set_subtitles_enabled(value: bool) -> void:
	subtitles_enabled = value
	settings_changed.emit("subtitles_enabled", value)
	save_settings()

func set_subtitle_background(value: bool) -> void:
	subtitle_background = value
	settings_changed.emit("subtitle_background", value)
	save_settings()

func set_subtitle_scale(value: float) -> void:
	subtitle_scale = clampf(value, 0.75, 1.8)
	settings_changed.emit("subtitle_scale", subtitle_scale)
	save_settings()

## Quality preset for the target GPU (Radeon Pro W6400, 4 GB VRAM):
##   "high"        -> full-resolution forward rendering, SSAO on
##   "balanced"    -> 0.85x 3D scale, SSAO on (default-ish laptop GPU)
##   "low"         -> 0.7x 3D scale, SSAO off (Compatibility fallback)
func set_quality_preset(value: String) -> void:
	if not ["high", "balanced", "low"].has(value):
		return
	quality_preset = value
	settings_changed.emit("quality_preset", value)
	apply_quality()
	save_settings()

func apply_quality() -> void:
	var viewport := _find_viewport()
	if viewport == null:
		return
	match quality_preset:
		"high":
			viewport.scaling_3d_scale = 1.0
		"balanced":
			viewport.scaling_3d_scale = 0.85
		"low":
			viewport.scaling_3d_scale = 0.7

func _find_viewport() -> Viewport:
	var root := get_tree().root if get_tree() else null
	return root

func set_camera_sensitivity(value: float) -> void:
	camera_sensitivity = clampf(value, 0.1, 3.0)
	settings_changed.emit("camera_sensitivity", camera_sensitivity)
	save_settings()

func set_camera_fov(value: float) -> void:
	camera_fov = clampf(value, 55.0, 90.0)
	settings_changed.emit("camera_fov", camera_fov)
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

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit("sfx_volume", sfx_volume)
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit("music_volume", music_volume)
	save_settings()

func set_voice_volume(value: float) -> void:
	voice_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit("voice_volume", voice_volume)
	save_settings()

func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	settings_changed.emit("ambience_volume", ambience_volume)
	save_settings()

func apply_audio() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(maxf(master_volume, 0.0001)))
