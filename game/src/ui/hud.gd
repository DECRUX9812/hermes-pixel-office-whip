class_name HUD
extends CanvasLayer
## Heads-up display: health and resolve bars, interaction prompt, current
## objective, and accessible subtitles.
##
## Accessibility contract:
##   - Subtitles render with a high-contrast backing panel (toggleable), a
##     configurable scale, and per-speaker color so the source is readable
##     without audio or colour alone.
##   - Prompts render device-aware glyphs via InputPrompts ([E] on keyboard,
##     [A] on gamepad) and re-render on device switch.

@onready var health_bar: ProgressBar = %HealthBar
@onready var resolve_bar: ProgressBar = %ResolveBar
@onready var prompt_label: Label = %PromptLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var subtitle_label: RichTextLabel = %SubtitleLabel
@onready var subtitle_panel: PanelContainer = %SubtitlePanel
@onready var subtitle_timer: Timer = %SubtitleTimer
@onready var boss_panel: Control = %BossPanel
@onready var boss_name_label: Label = %BossNameLabel
@onready var boss_bar: ProgressBar = %BossBar
@onready var companion_label: Label = %CompanionLabel

const SPEAKER_COLORS := {
	"Teknium": Color(0.4, 0.95, 0.7),
	"Hermes": Color(0.0, 1.0, 0.6),
	"Nous": Color(0.78, 0.5, 1.0),
	"Brooklyn": Color(1.0, 0.5, 0.7),
	"Tinuviel": Color(0.5, 0.6, 1.0),
	"Sidbin": Color(1.0, 0.75, 0.4),
	"Nadia": Color(0.95, 0.85, 0.6),
	"Juno": Color(0.5, 1.0, 0.8),
	"Juno (recorded)": Color(0.5, 1.0, 0.8),
	"Lark": Color(0.6, 0.9, 1.0),
	"Lark (recorded)": Color(0.6, 0.9, 1.0),
	"Nadia (recorded)": Color(0.95, 0.85, 0.6),
	"Announcement": Color(0.8, 0.83, 0.88),
	"Neighbor": Color(0.9, 0.8, 0.65),
}

const SUBTITLE_BASE_SIZE := 22

var _player_health: HealthComponent = null
var _player_resolve: ResolveComponent = null
var _player: Player = null
var _warden: ChoirWarden = null

func _ready() -> void:
	health_bar.max_value = 1.0
	health_bar.value = 1.0
	resolve_bar.max_value = 1.0
	resolve_bar.value = 1.0
	prompt_label.visible = false
	subtitle_panel.visible = false
	boss_panel.visible = false
	companion_label.text = ""
	subtitle_timer.timeout.connect(_on_subtitle_timer_timeout)
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.resolve_changed.connect(_on_resolve_changed)
	EventBus.interactable_focused.connect(_on_interactable_focused)
	EventBus.interactable_unfocused.connect(_on_interactable_unfocused)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.subtitle_requested.connect(_on_subtitle_requested)
	EventBus.subtitle_requested_timed.connect(_on_subtitle_requested_timed)
	EventBus.subtitle_clear.connect(_on_subtitle_clear)
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_completed.connect(_on_encounter_completed)
	InputPrompts.input_device_changed.connect(_on_input_device_changed)
	Settings.settings_changed.connect(_on_setting_changed)
	_apply_subtitle_style()

func _on_player_spawned(player: Node3D) -> void:
	if player is Player:
		_player = player as Player
		_player_health = _player.health
		_player_resolve = _player.resolve
		_sync_bars()

func _on_health_changed(node: Node, current: float, maximum: float, _delta: float) -> void:
	if node == _player_health and maximum > 0.0:
		health_bar.value = current / maximum

func _on_resolve_changed(node: Node, current: float, maximum: float, _delta: float) -> void:
	if node == _player_resolve and maximum > 0.0:
		resolve_bar.value = current / maximum

func _sync_bars() -> void:
	if _player_health and _player_health.max_health > 0.0:
		health_bar.value = _player_health.current_health / _player_health.max_health
	if _player_resolve and _player_resolve.max_resolve > 0.0:
		resolve_bar.value = _player_resolve.current_resolve / _player_resolve.max_resolve

func _on_interactable_focused(interactable: Interactable) -> void:
	prompt_label.text = "%s  %s" % [InputPrompts.glyph("interact"), interactable.prompt_text]
	prompt_label.visible = true

func _on_interactable_unfocused() -> void:
	prompt_label.visible = false

func _on_objective_updated(objective: Objective) -> void:
	objective_label.text = objective.label

func _on_subtitle_requested(speaker: String, text: String) -> void:
	_show_subtitle(speaker, text, 4.0)

func _on_subtitle_requested_timed(speaker: String, text: String, seconds: float) -> void:
	_show_subtitle(speaker, text, seconds)

func _on_subtitle_clear() -> void:
	subtitle_timer.stop()
	subtitle_panel.visible = false

func _show_subtitle(speaker: String, text: String, seconds: float) -> void:
	if not Settings.subtitles_enabled:
		return
	subtitle_label.text = _format_subtitle(speaker, text)
	_apply_subtitle_style()
	subtitle_panel.visible = true
	subtitle_timer.start(seconds if seconds > 0.0 else 4.0)

func _format_subtitle(speaker: String, text: String) -> String:
	if speaker == "":
		return text
	var color: Color = SPEAKER_COLORS.get(speaker, Color(0.95, 0.96, 0.98))
	return "[color=#%s]%s[/color]  %s" % [color.to_html(false), speaker, text]

func _apply_subtitle_style() -> void:
	var size := int(round(SUBTITLE_BASE_SIZE * Settings.subtitle_scale))
	subtitle_label.add_theme_font_size_override("normal_font_size", size)
	subtitle_label.add_theme_color_override("default_color", Color(0.95, 0.96, 0.98))
	if Settings.subtitle_background:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.02, 0.02, 0.025, 0.72)
		panel_style.border_color = Color(0.0, 0.85, 0.5, 0.55)
		panel_style.set_border_width_all(1)
		panel_style.set_corner_radius_all(6)
		panel_style.content_margin_left = 16
		panel_style.content_margin_right = 16
		panel_style.content_margin_top = 8
		panel_style.content_margin_bottom = 8
		subtitle_panel.add_theme_stylebox_override("panel", panel_style)
	else:
		subtitle_panel.add_theme_stylebox_override("panel", null)

func _on_subtitle_timer_timeout() -> void:
	subtitle_panel.visible = false

func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "subtitle_scale" or key == "subtitle_background":
		_apply_subtitle_style()
		_refresh_prompt()

func _on_input_device_changed(_device: int) -> void:
	_refresh_prompt()
	_refresh_companion_label()

func _refresh_prompt() -> void:
	if prompt_label.visible:
		var text := prompt_label.text
		var idx := text.find("]")
		if idx >= 0:
			prompt_label.text = InputPrompts.glyph("interact") + text.substr(idx)

func _refresh_companion_label() -> void:
	_update_companion_label()

func _on_encounter_started(encounter: Node) -> void:
	if encounter is EncounterController and encounter.warden_node:
		_warden = encounter.warden_node
		boss_name_label.text = _warden.display_health_name
		boss_bar.max_value = _warden.health.max_health
		boss_bar.value = _warden.health.current_health
		boss_panel.visible = true

func _on_encounter_completed(_encounter: Node) -> void:
	_warden = null
	boss_panel.visible = false

func _process(_delta: float) -> void:
	_update_boss_bar()
	_update_companion_label()

func _update_boss_bar() -> void:
	if _warden == null:
		return
	if not is_instance_valid(_warden) or _warden.is_queued_for_deletion() or _warden.health.current_health <= 0.0:
		boss_panel.visible = false
		_warden = null
		return
	boss_bar.value = _warden.health.current_health

func _update_companion_label() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var controller := _player.companions
	var companion := controller.active() if controller else null
	if companion == null:
		if companion_label.text != "":
			companion_label.text = ""
		return
	var status := "READY" if companion.is_ready() else "%.1fs" % companion.current_cooldown
	var ability := companion.ability_id().replace("_", " ").to_upper()
	companion_label.text = "%s %s — %s (%d resolve)  ·  switch: %s" % [
		InputPrompts.glyph("companion_command"), companion.display_name,
		"%s — %s" % [ability, status], companion.ability_cost,
		InputPrompts.glyph("switch_companion")]
