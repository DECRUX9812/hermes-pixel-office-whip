extends TestCase
## Deterministic coverage for the arena encounter: trigger -> begin, roster
## counting (including warden-summoned minions), completion only when every
## combatant is down, and the chapter wiring that turns a completed encounter
## into objective completion.

const WARDEN_SCENE := "res://scenes/world/entities/choir_warden.tscn"
const CUSTODIAN_SCENE := "res://scenes/world/entities/custodian.tscn"

var _completed: Array[Node] = []

func _ready() -> void:
	EventBus.encounter_completed.connect(_on_encounter_completed)

func _exit_tree() -> void:
	EventBus.encounter_completed.disconnect(_on_encounter_completed)

func _on_encounter_completed(encounter: Node) -> void:
	_completed.append(encounter)

func test_encounter_completes_when_all_combatants_dead() -> void:
	_completed.clear()
	var arena := Node3D.new()
	add_child(arena)
	var warden := _make_warden()
	arena.add_child(warden)
	var encounter := _make_encounter_controller(arena)
	await _wait_physics(20)

	encounter.begin()
	check(encounter.active, "encounter active after begin")
	check_eq(encounter.remaining_combatants(), 1, "warden counted in the roster")

	warden.take_hit(99999.0, Vector3.BACK, true)
	await _wait_physics(10)
	check_eq(_completed.size(), 1, "encounter_completed emitted when the warden fell")
	check(encounter.completed, "encounter marked completed")
	check_eq(encounter.remaining_combatants(), 0, "no combatants remain")
	arena.queue_free()

func test_encounter_counts_summoned_minions_and_requires_all_dead() -> void:
	_completed.clear()
	var arena := Node3D.new()
	add_child(arena)
	var warden := _make_warden()
	arena.add_child(warden)
	var encounter := _make_encounter_controller(arena)
	await _wait_physics(20)

	encounter.begin()
	var cust := _make_custodian()
	arena.add_child(cust)
	await _wait_physics(5)
	check_eq(encounter.remaining_combatants(), 2, "summoned minion counted in the roster")

	warden.take_hit(99999.0, Vector3.BACK, true)
	await _wait_physics(10)
	check(not encounter.completed, "encounter stays open while a minion lives")
	check(_completed.is_empty(), "no completion while a minion lives")

	cust.take_hit(99999.0, Vector3.BACK, true)
	await _wait_physics(10)
	check(encounter.completed, "encounter completed once every combatant fell")
	check_eq(_completed.size(), 1, "completion emitted exactly once")
	arena.queue_free()

func test_converted_minions_do_not_block_completion() -> void:
	_completed.clear()
	var arena := Node3D.new()
	add_child(arena)
	var warden := _make_warden()
	arena.add_child(warden)
	var encounter := _make_encounter_controller(arena)
	await _wait_physics(20)

	var cust_a := _make_custodian()
	arena.add_child(cust_a)
	var cust_b := _make_custodian()
	arena.add_child(cust_b)
	await _wait_physics(5)
	encounter.begin()
	check_eq(encounter.remaining_combatants(), 3, "three hostile combatants at start")

	cust_a.convert(30.0)
	cust_b.convert(30.0)
	await _wait_physics(5)
	check_eq(encounter.remaining_combatants(), 1, "converted minions no longer block completion")

	warden.take_hit(99999.0, Vector3.BACK, true)
	await _wait_physics(10)
	check(encounter.completed, "encounter completes with converted minions still alive")
	check_eq(_completed.size(), 1, "completion emitted exactly once")
	arena.queue_free()

func test_chapter_objective_wiring() -> void:
	var chapter_scene: PackedScene = load("res://scenes/world/chapter2_choir_below.tscn")
	var chapter := chapter_scene.instantiate()
	add_child(chapter)
	await _wait_physics(40)
	var flow := chapter.get_node("ObjectiveFlow") as ObjectiveFlow
	check(flow != null and flow.current != null, "objective flow running")
	check_eq(flow.current.id, "investigate_doves_row", "slice opens on the cold open")
	var ids := [
		"investigate_doves_row", "learn_the_surrender", "reconstruct_the_surrender",
		"descend_the_weep", "cross_the_conduit", "clear_the_threshold",
		"the_voices_return", "open_the_choir_door", "talk_with_nous",
		"defeat_the_warden", "hermes_speaks", "the_question",
	]
	for id in ids:
		check(flow.skip_to(id), "skip_to advanced past %s" % id)
	check(flow.current == null, "flow completes after the final objective")

	# Chapter2 listens to EventBus.encounter_completed -> skip_to("defeat_the_warden").
	# Idempotent: the flow is already past it, so it must not regress or error.
	var dummy_encounter := EncounterController.new()
	EventBus.encounter_completed.emit(dummy_encounter)
	await _wait_physics(5)
	check(flow.has_reached("defeat_the_warden"), "encounter completion advanced the warden objective")
	chapter.queue_free()
	dummy_encounter.free()

func _make_encounter_controller(arena: Node) -> EncounterController:
	var encounter := EncounterController.new()
	encounter.auto_trigger = false
	encounter.arena_root_path = ^".."
	encounter.warden_path = ^"../Warden"
	var trigger := Area3D.new()
	trigger.name = "Trigger"
	encounter.add_child(trigger)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	trigger.add_child(shape)
	arena.add_child(encounter)
	return encounter

func _make_warden() -> ChoirWarden:
	var scene: PackedScene = load(WARDEN_SCENE)
	var warden := scene.instantiate() as ChoirWarden
	warden.name = "Warden"
	return warden

func _make_custodian() -> Custodian:
	var scene: PackedScene = load(CUSTODIAN_SCENE)
	return scene.instantiate() as Custodian
