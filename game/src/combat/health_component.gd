class_name HealthComponent
extends Node
## Health pool with bounded invulnerability windows (dodge i-frames, post-hit
## i-frames). Emits locally and on the shared EventBus so HUD / systems react.

signal changed(current: float, maximum: float, delta: float, source: Node)
signal depleted(source: Node)
signal invulnerability_started
signal invulnerability_ended

@export var max_health := 100.0
@export var invulnerable := false
@export var hit_invulnerability_window := 0.5

var current_health := 100.0
var invulnerability_timer := 0.0
var _depleted_emitted := false

func _ready() -> void:
	current_health = max_health

func reset() -> void:
	current_health = max_health
	_depleted_emitted = false
	invulnerability_timer = 0.0
	changed.emit(current_health, max_health, 0.0, null)
	EventBus.health_changed.emit(self, current_health, max_health, 0.0)

func take_damage(amount: float, source: Node = null) -> bool:
	if invulnerable or invulnerability_timer > 0.0 or amount <= 0.0:
		return false
	if _depleted_emitted:
		return false
	current_health = maxf(0.0, current_health - amount)
	_apply_invulnerability_window()
	changed.emit(current_health, max_health, -amount, source)
	EventBus.health_changed.emit(self, current_health, max_health, -amount)
	if current_health <= 0.0 and not _depleted_emitted:
		_depleted_emitted = true
		depleted.emit(source)
	return true

func heal(amount: float) -> void:
	if _depleted_emitted or amount <= 0.0:
		return
	current_health = minf(max_health, current_health + amount)
	changed.emit(current_health, max_health, amount, null)
	EventBus.health_changed.emit(self, current_health, max_health, amount)

func is_full() -> bool:
	return is_equal_approx(current_health, max_health)

func is_dead() -> bool:
	return _depleted_emitted

func grant_invulnerability_window(seconds: float) -> void:
	if seconds <= 0.0:
		return
	invulnerability_timer = maxf(invulnerability_timer, seconds)
	invulnerability_started.emit()

func _apply_invulnerability_window() -> void:
	if hit_invulnerability_window > 0.0:
		invulnerability_timer = maxf(invulnerability_timer, hit_invulnerability_window)

func _physics_process(delta: float) -> void:
	if invulnerability_timer > 0.0:
		invulnerability_timer = maxf(0.0, invulnerability_timer - delta)
		if is_zero_approx(invulnerability_timer):
			invulnerability_ended.emit()
