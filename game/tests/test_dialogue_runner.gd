extends TestCase
## Deterministic coverage for the DialogueRunner:
##   - line playback emits timed subtitles and the finish beat,
##   - cutscene skip recovery: skipping a sequence still fires its beat and the
##     downstream objective flow still advances (no dead end from skipping),
##   - cinematic lock is applied on play and always released on finish.

var _beats_fired: Array[String] = []
var _finished_ids: Array[String] = []
var _subtitles: Array[String] = []
var _skip_handled := false

func _ready() -> void:
	EventBus.story_beat_triggered.connect(_on_story_beat)
	EventBus.dialogue_sequence_finished.connect(_on_sequence_finished)
	EventBus.subtitle_requested_timed.connect(_on_subtitle_timed)

func _exit_tree() -> void:
	EventBus.story_beat_triggered.disconnect(_on_story_beat)
	EventBus.dialogue_sequence_finished.disconnect(_on_sequence_finished)
	EventBus.subtitle_requested_timed.disconnect(_on_subtitle_timed)

func _on_story_beat(beat_id: String) -> void:
	_beats_fired.append(beat_id)

func _on_sequence_finished(sequence_id: String) -> void:
	_finished_ids.append(sequence_id)

func _on_subtitle_timed(speaker: String, text: String, _seconds: float) -> void:
	_subtitles.append("%s:%s" % [speaker, text])

func _make_runner(sequence_id: String) -> DialogueRunner:
	var runner := DialogueRunner.new()
	runner.sequence_id = sequence_id
	runner.beat_id = "test_beat_%s" % sequence_id
	add_child(runner)
	return runner

func test_plays_lines_then_fires_beat() -> void:
	_beats_fired.clear()
	_subtitles.clear()
	var runner := _make_runner("2.1_door")
	runner.play()
	check(runner.is_playing(), "runner playing after play()")
	check_eq(runner.current_line_index(), 0, "first line active")
	while runner.is_playing():
		runner.advance_line()
	check(not runner.is_playing(), "runner finished after advancing all lines")
	check_eq(_subtitles.size(), 4, "one subtitle per spoken line")
	check(_beats_fired.has("test_beat_2.1_door"), "finish beat fired after natural playback")
	check(_finished_ids.has("2.1_door"), "sequence_finished emitted")
	runner.queue_free()

func test_skip_whole_sequence_still_fires_beat() -> void:
	_beats_fired.clear()
	var runner := _make_runner("2.8_nous")
	runner.play()
	check(runner.is_playing(), "long sequence playing")
	runner.skip_all()
	check(not runner.is_playing(), "skip_all finished the sequence")
	check(_beats_fired.has("test_beat_2.8_nous"), "finish beat fired after a full skip")
	runner.queue_free()

func test_skip_recovery_advances_objective_flow() -> void:
	_beats_fired.clear()
	_skip_handled = false
	var flow := ObjectiveFlow.new()
	var make := func(id: String) -> Objective:
		var o := Objective.new()
		o.id = id
		return o
	flow.objectives = [make.call("a"), make.call("b")]
	add_child(flow)
	flow.begin()
	var runner := _make_runner("2.10_hermes")
	EventBus.story_beat_triggered.connect(_skip_beat_handler.bind(flow, runner.sequence_id))
	# Simulate the scene director: on the beat, advance the flow.
	runner.play()
	runner.skip_all()
	await get_tree().process_frame
	EventBus.story_beat_triggered.disconnect(_skip_beat_handler.bind(flow, runner.sequence_id))
	check(_beats_fired.has("test_beat_2.10_hermes"), "hermes beat fired despite skip")
	check(flow.has_reached("a"), "objective flow advanced past a after the skipped cutscene")
	check(_skip_handled, "beat handler ran for the skipped sequence")
	runner.queue_free()
	flow.queue_free()

func _skip_beat_handler(beat_id: String, flow: ObjectiveFlow, expected: String) -> void:
	if beat_id == "test_beat_%s" % expected:
		_skip_handled = true
		flow.skip_to("a")

func test_lock_applied_on_play_and_released_on_skip() -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player := player_scene.instantiate() as Player
	add_child(player)
	var runner := DialogueRunner.new()
	runner.sequence_id = "2.2_nadia"
	runner.lock_player = true
	add_child(runner)
	runner.play()
	check(player.control_locked, "player control locked while cinematic plays")
	runner.skip_all()
	check(not player.control_locked, "player control released after skip")
	runner.queue_free()
	player.queue_free()

func test_empty_sequence_finishes_immediately() -> void:
	_beats_fired.clear()
	var runner := DialogueRunner.new()
	runner.sequence_id = "does_not_exist"
	runner.beat_id = "test_beat_empty"
	add_child(runner)
	runner.play()
	check(not runner.is_playing(), "unknown/empty sequence finishes immediately")
	check(_beats_fired.has("test_beat_empty"), "beat still fires for an empty sequence")
	runner.queue_free()
