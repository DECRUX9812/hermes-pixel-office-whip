class_name CompanionController
extends Node3D
## Player-side companion command interface. Owns the active companion and routes
## the companion_command input (F) plus companion cycling (C). The command targets
## the player's active combat target (lock-on, else soft-target); without a target
## the command is a no-op that reports itself so the player reads the miss.

var companions: Array[Companion] = []
var active_index := 0
var _sync_timer := 0.0

func _ready() -> void:
	_sync_companions()

func active() -> Companion:
	if companions.is_empty():
		return null
	return companions[active_index % companions.size()]

func register(companion: Companion) -> void:
	if companion == null or companions.has(companion):
		return
	companions.append(companion)
	EventBus.companion_joined.emit(companion)
	if companions.size() == 1:
		active_index = 0

func switch_active() -> void:
	if companions.size() <= 1:
		EventBus.combat_event.emit("No other companion to switch to")
		return
	active_index = (active_index + 1) % companions.size()
	EventBus.combat_event.emit("Commanding %s" % active().display_name)

func try_command(executor: Node3D) -> bool:
	var companion := active()
	if companion == null:
		EventBus.combat_event.emit("No companion present to command")
		return false
	var target: Node = null
	if executor is Player:
		target = (executor as Player).get_combat_target()
	return companion.use_ability(executor, target)

func _physics_process(delta: float) -> void:
	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_companions()
		_sync_timer = 0.5

func _sync_companions() -> void:
	for node in get_tree().get_nodes_in_group("companion"):
		var candidate := node as Companion
		if candidate and not companions.has(candidate):
			register(candidate)
