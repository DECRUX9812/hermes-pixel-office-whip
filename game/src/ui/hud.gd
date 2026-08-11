class_name HUD
extends CanvasLayer
## Heads-up display: health and resolve bars, interaction prompt, current
## objective, and subtitles (gated by the accessibility setting).

@onready var health_bar: ProgressBar = %HealthBar
@onready var resolve_bar: ProgressBar = %ResolveBar
@onready var prompt_label: Label = %PromptLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var subtitle_timer: Timer = %SubtitleTimer
@onready var boss_panel: Control = %BossPanel
@onready var boss_name_label: Label = %BossNameLabel
@onready var boss_bar: ProgressBar = %BossBar
@onready var companion_label: Label = %CompanionLabel

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
	subtitle_label.visible = false
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
	prompt_label.text = "[%s]  %s" % [_action_hint("interact"), interactable.prompt_text]
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
	subtitle_label.visible = false

func _show_subtitle(speaker: String, text: String, seconds: float) -> void:
	if not Settings.subtitles_enabled:
		return
	var prefix := ""
	if speaker != "":
		prefix = "%s: " % speaker
	subtitle_label.text = prefix + text
	subtitle_label.visible = true
	subtitle_timer.start(seconds if seconds > 0.0 else 4.0)

func _on_subtitle_timer_timeout() -> void:
	subtitle_label.visible = false

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
	companion_label.text = "[%s] %s — %s (%d resolve)\nswitch companion: [%s]" % [
		_action_hint("companion_command"), companion.display_name,
		"%s — %s" % [ability, status], companion.ability_cost,
		_action_hint("switch_companion")]

func _action_hint(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "?"
	var event := events[0]
	if event is InputEventKey:
		var code := (event as InputEventKey).physical_keycode
		return OS.get_keycode_string(code)
	if event is InputEventMouseButton:
		return "Mouse%d" % (event as InputEventMouseButton).button_index
	if event is InputEventJoypadButton:
		return _joypad_button_label((event as InputEventJoypadButton).button_index)
	return "?"

func _joypad_button_label(index: int) -> String:
	match index:
		0:
			return "A"
		1:
			return "B"
		2:
			return "X"
		3:
			return "Y"
		4:
			return "LB"
		5:
			return "RB"
		_:
			return "Btn%d" % index
