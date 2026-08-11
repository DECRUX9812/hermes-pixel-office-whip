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

var _player_health: HealthComponent = null
var _player_resolve: ResolveComponent = null

func _ready() -> void:
	health_bar.max_value = 1.0
	health_bar.value = 1.0
	resolve_bar.max_value = 1.0
	resolve_bar.value = 1.0
	prompt_label.visible = false
	subtitle_label.visible = false
	subtitle_timer.timeout.connect(_on_subtitle_timer_timeout)
	EventBus.player_spawned.connect(_on_player_spawned)
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.resolve_changed.connect(_on_resolve_changed)
	EventBus.interactable_focused.connect(_on_interactable_focused)
	EventBus.interactable_unfocused.connect(_on_interactable_unfocused)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.subtitle_requested.connect(_on_subtitle_requested)

func _on_player_spawned(player: Node3D) -> void:
	if player is Player:
		_player_health = (player as Player).health
		_player_resolve = (player as Player).resolve
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
	if not Settings.subtitles_enabled:
		return
	var prefix := ""
	if speaker != "":
		prefix = "%s: " % speaker
	subtitle_label.text = prefix + text
	subtitle_label.visible = true
	subtitle_timer.start(4.0)

func _on_subtitle_timer_timeout() -> void:
	subtitle_label.visible = false

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
