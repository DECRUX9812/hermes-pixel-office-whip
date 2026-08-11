extends TestCase

func test_quality_presets_round_trip() -> void:
	var original := Settings.quality_preset
	Settings.set_quality_preset("low")
	check_eq(Settings.quality_preset, "low", "low preset stored")
	Settings.set_quality_preset("balanced")
	check_eq(Settings.quality_preset, "balanced", "balanced preset stored")
	Settings.set_quality_preset("high")
	check_eq(Settings.quality_preset, "high", "high preset stored")
	Settings.set_quality_preset("invalid")
	check_eq(Settings.quality_preset, "high", "invalid preset rejected")
	Settings.set_quality_preset(original)

func test_subtitle_scale_clamped() -> void:
	var original := Settings.subtitle_scale
	Settings.set_subtitle_scale(5.0)
	check(Settings.subtitle_scale <= 1.8, "subtitle scale clamps high")
	Settings.set_subtitle_scale(original)

func test_per_bus_volume_clamped() -> void:
	var original := Settings.sfx_volume
	Settings.set_sfx_volume(2.0)
	check(Settings.sfx_volume <= 1.0, "sfx volume clamps high")
	Settings.set_sfx_volume(original)

func test_subtitle_background_toggle() -> void:
	var original := Settings.subtitle_background
	Settings.set_subtitle_background(false)
	check(not Settings.subtitle_background, "background toggle off")
	Settings.set_subtitle_background(true)
	check(Settings.subtitle_background, "background toggle on")
	Settings.set_subtitle_background(original)

func test_camera_fov_clamped() -> void:
	var original := Settings.camera_fov
	Settings.set_camera_fov(140.0)
	check(Settings.camera_fov <= 90.0, "fov clamps high")
	Settings.set_camera_fov(30.0)
	check(Settings.camera_fov >= 55.0, "fov clamps low")
	Settings.set_camera_fov(original)
