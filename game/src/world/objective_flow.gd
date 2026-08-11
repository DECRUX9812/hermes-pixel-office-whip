class_name ObjectiveFlow
extends Node
## Event-driven objective sequencing. The scene director completes objectives by
## id; the flow only advances in order so the slice cannot deadlock. Emits on
## EventBus so the HUD and telemetry can react without coupling.

signal objective_updated(current: Objective, index: int)
signal flow_completed

@export var objectives: Array[Objective] = []
@export var begin_on_ready := false

var current: Objective = null
var current_index := -1
var _started := false

func _ready() -> void:
	if begin_on_ready:
		begin()

func begin() -> void:
	_started = true
	current_index = -1
	_advance()

func complete(id: String) -> bool:
	if not _started or current == null:
		return false
	if current.id != id:
		return false
	EventBus.objective_completed.emit(id)
	_advance()
	return true

## Deadlock-safe forward jump: marks every objective up to and including `id`
## complete and advances past it. Used by checkpoint / encounter / beat handlers
## that can fire while an earlier objective is still open — a player who reaches
## a further checkpoint (or skips a cutscene) can never strand the flow. Never
## moves backward; already-reached targets are a no-op.
func skip_to(id: String) -> bool:
	if not _started:
		return false
	var target := index_of(id)
	if target < 0:
		return false
	if target < current_index:
		return true
	while current_index < target:
		var completed_id := current.id if current != null else objectives[current_index].id
		EventBus.objective_completed.emit(completed_id)
		if not _advance():
			return true
	if current != null and current.id == id:
		EventBus.objective_completed.emit(current.id)
		if not _advance():
			return true
	return true

func has_reached(id: String) -> bool:
	var index := index_of(id)
	return index >= 0 and index <= current_index

func index_of(id: String) -> int:
	for i in objectives.size():
		if objectives[i].id == id:
			return i
	return -1

func _advance() -> bool:
	current_index += 1
	if current_index >= objectives.size():
		current = null
		flow_completed.emit()
		return false
	current = objectives[current_index]
	EventBus.objective_updated.emit(current)
	objective_updated.emit(current, current_index)
	return true
