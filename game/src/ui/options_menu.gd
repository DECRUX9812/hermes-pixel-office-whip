class_name OptionsMenu
extends Control
## Accessibility + audio basics, bound to the Settings autoload. Reused on the
## title screen and in the pause menu.

@onready var subtitles_toggle: CheckButton = %SubtitlesToggle
@onready var invert_y_toggle: CheckButton = %InvertYToggle
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var volume_slider: HSlider = %VolumeSlider

func _ready() -> void:
	subtitles_toggle.button_pressed = Settings.subtitles_enabled
	invert_y_toggle.button_pressed = Settings.invert_y
	sensitivity_slider.value = Settings.camera_sensitivity
	volume_slider.value = Settings.master_volume
	subtitles_toggle.toggled.connect(_on_subtitles_toggled)
	invert_y_toggle.toggled.connect(_on_invert_y_toggled)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	volume_slider.value_changed.connect(_on_volume_changed)

func _on_subtitles_toggled(on: bool) -> void:
	Settings.set_subtitles_enabled(on)

func _on_invert_y_toggled(on: bool) -> void:
	Settings.set_invert_y(on)

func _on_sensitivity_changed(value: float) -> void:
	Settings.set_camera_sensitivity(value)

func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
