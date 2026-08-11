extends TestCase
## Full-slice spine test: drives the scene director through every beat from the
## cold open to the question and asserts the objective flow can always advance.
## This is the "no progression dead ends" gate — every step completes through the
## same event paths the game uses (interactions, reconstruction, checkpoints,
## combat, encounter, cutscene beats), with cutscenes force-finished to prove the
## flow never depends on watching them.

var _titles: Array[String] = []

func _ready() -> void:
	EventBus.title_card_requested.connect(_on_title)

func _exit_tree() -> void:
	EventBus.title_card_requested.disconnect(_on_title)

func _on_title(title: String) -> void:
	_titles.append(title)

func test_slice_spine_has_no_dead_ends() -> void:
	var scene: PackedScene = load("res://scenes/world/chapter2_choir_below.tscn")
	var chapter := scene.instantiate()
	add_child(chapter)
	await _wait_physics(30)

	var flow := chapter.get_node("ObjectiveFlow") as ObjectiveFlow
	var player := chapter.get_node("Player") as Player
	check(flow != null and player != null, "chapter systems present")

	# 2.1 Cold open: investigate Juno's door.
	var door := chapter.get_node("Beats/Interactables/DoorJuno") as StoryInteractable
	door.interact(player)
	await _wait_frames(2)
	check(_completed(flow, "investigate_doves_row"), "door investigation completes")

	# 2.2 Nadia: the director chains door -> truth-scan -> Nadia; finish each.
	var door_runner := chapter.get_node("Beats/Narrative/Cinematics/DoorScene") as DialogueRunner
	var truth_runner := chapter.get_node("Beats/Narrative/Cinematics/TruthScanExchange") as DialogueRunner
	var nadia_runner := chapter.get_node("Beats/Narrative/Cinematics/NadiaScene") as DialogueRunner
	_force_finish(door_runner)
	await _wait_frames(2)
	_force_finish(truth_runner)
	await _wait_frames(2)
	_force_finish(nadia_runner)
	await _wait_frames(2)
	check(_completed(flow, "learn_the_surrender"), "Nadia's silence explained")

	# 2.3 Reconstruction: collect the three fragments in a shuffled order.
	var fragment_nodes := chapter.get_node("Beats/Narrative/Fragments")
	for runner_name in ["GatheringRunner", "JunoRunner", "FarewellRunner"]:
		var runner := fragment_nodes.get_node(runner_name) as DialogueRunner
		_force_finish(runner)
		await _wait_frames(2)
	var gate := chapter.get_node("Beats/Gates/WeepGate") as SlidingDoor
	check(_completed(flow, "reconstruct_the_surrender"), "reconstruction completes in any fragment order")
	check(gate.is_open(), "Weep gate opens once the surrender is legible")
	var reveal_runner := chapter.get_node("Beats/Narrative/Cinematics/RevealScene") as DialogueRunner
	_force_finish(reveal_runner)
	await _wait_frames(2)

	# 2.4-2.5 Descent + conduit via their checkpoints.
	var cp_weep := chapter.get_node("Beats/Checkpoints/CP_WeepDescent") as CheckpointArea
	EventBus.checkpoint_reached.emit(cp_weep)
	var cp_threshold := chapter.get_node("Beats/Checkpoints/CP_ChoirThreshold") as CheckpointArea
	EventBus.checkpoint_reached.emit(cp_threshold)
	await _wait_frames(2)
	check(_completed(flow, "cross_the_conduit"), "descent and conduit crossed")

	# 2.6 First contact: the guard is armed when its objective is active, then falls.
	var guard := chapter.get_node("Beats/FirstContactCustodian") as Custodian
	check(guard.aggro_range > 0.0, "threshold custodian armed for the fight")
	guard.take_hit(99999.0, Vector3.BACK, true)
	await _wait_frames(4)
	check(_completed(flow, "clear_the_threshold"), "first contact cleared")
	var after_fight := chapter.get_node("Beats/Narrative/Cinematics/AfterTheFight") as DialogueRunner
	_force_finish(after_fight)
	await _wait_frames(2)

	# 2.7 Payoff echo, 2.8 Teknium & Nous.
	var payoff := chapter.get_node("Beats/Narrative/Cinematics/PayoffEcho") as DialogueRunner
	_force_finish(payoff)
	await _wait_frames(2)
	check(_completed(flow, "the_voices_return"), "payoff echo resolves")
	var convo := chapter.get_node("Beats/Narrative/Cinematics/NousConversation") as DialogueRunner
	_force_finish(convo)
	await _wait_frames(2)
	check(_completed(flow, "talk_with_nous"), "Teknium and Nous conversation resolves")

	# 2.9 The Warden arena: a completed encounter must open the epilogue chain.
	var encounter := chapter.get_node("Beats/Arena/Encounter") as EncounterController
	EventBus.encounter_completed.emit(encounter)
	await _wait_frames(2)
	check(_completed(flow, "defeat_the_warden"), "warden objective completes")
	var coda := chapter.get_node("Beats/Narrative/Cinematics/TekniumCoda") as DialogueRunner
	_force_finish(coda)
	await _wait_frames(2)

	# 2.10 Hermes's eleven seconds -> 2.11 the question -> slice ends.
	var eleven := chapter.get_node("Beats/Narrative/Cinematics/HermesElevenSeconds") as DialogueRunner
	_force_finish(eleven)
	await _wait_frames(2)
	check(_completed(flow, "hermes_speaks"), "Hermes contact advances the flow")
	var question := chapter.get_node("Beats/Narrative/Cinematics/TheQuestion") as DialogueRunner
	_force_finish(question)
	await _wait_frames(2)
	check(flow.current == null, "flow completes at the end of the slice")
	check(_completed(flow, "the_question"), "the question is the final objective")
	check(_titles.has("HERMES: THE LAST OPEN DOOR"), "title card requested after the question")
	check(GameState.get_flag("slice_complete") == true, "slice completion persisted")

	chapter.queue_free()

## A Heart-Bind conversion of the first-contact Custodian is a valid, first-class
## resolution: it must clear the objective without killing the construct, and it
## must record the street's allegiance for later chapters.
func test_conversion_resolves_first_contact() -> void:
	var scene: PackedScene = load("res://scenes/world/chapter2_choir_below.tscn")
	var chapter := scene.instantiate()
	add_child(chapter)
	await _wait_physics(30)

	var flow := chapter.get_node("ObjectiveFlow") as ObjectiveFlow
	GameState.flags.clear()
	flow.skip_to("cross_the_conduit") # first contact is now the active objective
	var guard := chapter.get_node("Beats/FirstContactCustodian") as Custodian
	check(not _completed(flow, "clear_the_threshold"), "first contact is active, not yet cleared")
	check(guard.convert(30.0), "Heart-Bind converts the first-contact Custodian")
	await _wait_frames(4)
	check(_completed(flow, "clear_the_threshold"),
		"conversion resolves the first contact without a kill")
	check_eq(GameState.get_flag("street_allegiance"), "converted", "allegiance recorded for later")

	chapter.queue_free()

func _completed(flow: ObjectiveFlow, id: String) -> bool:
	return flow.index_of(id) < flow.current_index

func _force_finish(runner: DialogueRunner) -> void:
	if runner == null:
		return
	if not runner.is_playing():
		runner.play()
	runner.skip_all()
