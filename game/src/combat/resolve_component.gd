class_name ResolveComponent
extends Node
## Resolve: the squad's shared willpower/presence pool. Gates special actions
## (companion commands and truth-layer work arrive in later phases). Regenerates
## after a short delay; provides a min-cost guard so abilities stay readable.

signal changed(current: float, maximum: float, delta: float)

@export var max_resolve := 100.0
@export var regen_rate := 6.0
@export var regen_delay := 1.5

var current_resolve := 100.0
var _regen_timer := 0.0

func _ready() -> void:
	current_resolve = max_resolve

func reset() -> void:
	current_resolve = max_resolve
	_regen_timer = 0.0
	changed.emit(current_resolve, max_resolve, 0.0)
	EventBus.resolve_changed.emit(self, current_resolve, max_resolve, 0.0)

func spend(amount: float) -> bool:
	if amount <= 0.0 or current_resolve < amount:
		return false
	current_resolve = maxf(0.0, current_resolve - amount)
	_regen_timer = 0.0
	changed.emit(current_resolve, max_resolve, -amount)
	EventBus.resolve_changed.emit(self, current_resolve, max_resolve, -amount)
	return true

func restore(amount: float) -> void:
	if amount <= 0.0:
		return
	current_resolve = minf(max_resolve, current_resolve + amount)
	changed.emit(current_resolve, max_resolve, amount)
	EventBus.resolve_changed.emit(self, current_resolve, max_resolve, amount)

func has(amount: float) -> bool:
	return current_resolve >= amount

func is_full() -> bool:
	return is_equal_approx(current_resolve, max_resolve)

func _physics_process(delta: float) -> void:
	if current_resolve >= max_resolve:
		_regen_timer = 0.0
		return
	_regen_timer += delta
	if _regen_timer < regen_delay:
		return
	var amount := regen_rate * delta
	current_resolve = minf(max_resolve, current_resolve + amount)
	changed.emit(current_resolve, max_resolve, amount)
	EventBus.resolve_changed.emit(self, current_resolve, max_resolve, amount)
