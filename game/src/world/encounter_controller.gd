class_name EncounterController
extends Node3D
## Arena encounter director. Owns the Choir Warden fight:
##   - a Trigger area that starts the encounter when the player crosses it,
##   - the roster of arena combatants (the Warden plus any it summons),
##   - completion when every arena combatant is dead,
##   - the boss-bar hook for the HUD (warden_node).
##
## Emits EventBus.encounter_started / encounter_completed so the chapter director
## can move objectives without knowing the fight's internals.

signal encounter_started(encounter: EncounterController)
signal encounter_completed(encounter: EncounterController)

@export var encounter_id := "choir_house"
@export var arena_root_path: NodePath = ^".."
@export var warden_path: NodePath = ^"../Warden"
@export var auto_trigger := true

var active := false
var completed := false

@onready var trigger_area: Area3D = $Trigger
@onready var warden_node: ChoirWarden = get_node_or_null(warden_path) as ChoirWarden

func _ready() -> void:
	trigger_area.collision_layer = 0
	trigger_area.collision_mask = 2
	trigger_area.monitoring = true
	EventBus.enemy_spawned.connect(_on_enemy_spawned)

func begin() -> void:
	if active or completed:
		return
	active = true
	if warden_node:
		warden_node.begin_encounter()
	EventBus.encounter_started.emit(self)
	encounter_started.emit(self)
	EventBus.combat_event.emit("Encounter %s begins — the choir-house is sealed" % encounter_id)

func complete() -> void:
	if completed:
		return
	completed = true
	active = false
	EventBus.encounter_completed.emit(self)
	encounter_completed.emit(self)
	EventBus.combat_event.emit("Encounter %s complete" % encounter_id)

func remaining_combatants() -> int:
	var count := 0
	var root := _arena_root()
	if root == null:
		return 0
	for child in root.get_children():
		if child is Combatant and is_instance_valid(child) and not child.dead:
			count += 1
	return count

func _physics_process(_delta: float) -> void:
	if completed:
		return
	if not active:
		if auto_trigger:
			_check_trigger()
	elif remaining_combatants() == 0:
		complete()

func _check_trigger() -> void:
	for body in trigger_area.get_overlapping_bodies():
		if body is Player:
			begin()
			return

func _on_enemy_spawned(_enemy: Node) -> void:
	# Spawned minions (Warden summons) are added under the arena root and count
	# toward completion automatically via remaining_combatants().
	pass

func _arena_root() -> Node:
	return get_node_or_null(arena_root_path)
