class_name OptionsMenu
extends Control
## Accessibility + audio + camera basics, bound to the Settings autoload.
## Reused on the title screen and in the pause menu.

@onready var subtitles_toggle: CheckButton = %SubtitlesToggle
@onready var subtitle_bg_toggle: CheckButton = %SubtitleBgToggle
@onready var subtitle_scale_slider: HSlider = %SubtitleScaleSlider
@onready var invert_y_toggle: CheckButton = %InvertYToggle
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var fov_slider: HSlider = %FovSlider
@onready var quality_option: OptionButton = %QualityOption
@onready var volume_slider: HSlider = %VolumeSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var voice_slider: HSlider = %VoiceSlider
@onready var ambience_slider: HSlider = %AmbienceSlider

func _ready() -> void:
	_sync_from_settings()
	subtitles_toggle.toggled.connect(_on_subtitles_toggled)
	subtitle_bg_toggle.toggled.connect(_on_subtitle_bg_toggled)
	subtitle_scale_slider.value_changed.connect(_on_subtitle_scale_changed)
	invert_y_toggle.toggled.connect(_on_invert_y_toggled)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	fov_slider.value_changed.connect(_on_fov_changed)
	quality_option.item_selected.connect(_on_quality_selected)
	volume_slider.value_changed.connect(_on_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	voice_slider.value_changed.connect(_on_voice_changed)
	ambience_slider.value_changed.connect(_on_ambience_changed)

func _sync_from_settings() -> void:
	subtitles_toggle.button_pressed = Settings.subtitles_enabled
	subtitle_bg_toggle.button_pressed = Settings.subtitle_background
	subtitle_scale_slider.value = Settings.subtitle_scale
	invert_y_toggle.button_pressed = Settings.invert_y
	sensitivity_slider.value = Settings.camera_sensitivity
	fov_slider.value = Settings.camera_fov
	quality_option.selected = _quality_index()
	volume_slider.value = Settings.master_volume
	sfx_slider.value = Settings.sfx_volume
	music_slider.value = Settings.music_volume
	voice_slider.value = Settings.voice_volume
	ambience_slider.value = Settings.ambience_volume

func _quality_index() -> int:
	match Settings.quality_preset:
		"balanced":
			return 1
		"low":
			return 2
		_:
			return 0

func _on_subtitles_toggled(on: bool) -> void:
	Settings.set_subtitles_enabled(on)

func _on_subtitle_bg_toggled(on: bool) -> void:
	Settings.set_subtitle_background(on)

func _on_subtitle_scale_changed(value: float) -> void:
	Settings.set_subtitle_scale(value)

func _on_invert_y_toggled(on: bool) -> void:
	Settings.set_invert_y(on)

func _on_sensitivity_changed(value: float) -> void:
	Settings.set_camera_sensitivity(value)

func _on_fov_changed(value: float) -> void:
	Settings.set_camera_fov(value)

func _on_quality_selected(index: int) -> void:
	var preset := "high"
	match index:
		1:
			preset = "balanced"
		2:
			preset = "low"
	Settings.set_quality_preset(preset)

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)

func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value)

func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)

func _on_voice_changed(value: float) -> void:
	Settings.set_voice_volume(value)

func _on_ambience_changed(value: float) -> void:
	Settings.set_ambience_volume(value)
