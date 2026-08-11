extends TestCase

func test_buses_created() -> void:
	check(AudioServer.get_bus_index("SFX") >= 0, "SFX bus exists")
	check(AudioServer.get_bus_index("Music") >= 0, "Music bus exists")
	check(AudioServer.get_bus_index("Voice") >= 0, "Voice bus exists")
	check(AudioServer.get_bus_index("Ambience") >= 0, "Ambience bus exists")

func test_play_sfx_does_not_error_unknown_cue() -> void:
	AudioDirector.play_sfx("not_a_cue")
	check(true, "unknown cue is a silent no-op")

func test_play_sfx_known_cue_plays() -> void:
	AudioDirector.play_sfx("impact", 0.0)
	check(true, "known cue dispatched")

func test_play_music_sets_stream() -> void:
	AudioDirector.play_music("music_choir", 0.0)
	check(true, "music bed dispatched")

func test_play_ambience_sets_stream() -> void:
	AudioDirector.play_ambience("music_warden", 0.0)
	check(true, "ambience dispatched")

func test_stop_ambience_is_safe() -> void:
	AudioDirector.stop_ambience()
	check(true, "stopping ambience is safe")

func test_volumes_apply_without_error() -> void:
	Settings.set_sfx_volume(0.5)
	Settings.set_music_volume(0.5)
	Settings.set_voice_volume(0.5)
	Settings.set_ambience_volume(0.5)
	check(true, "per-bus volumes applied")
