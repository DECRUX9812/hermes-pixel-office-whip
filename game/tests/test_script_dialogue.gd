extends TestCase
## Audits the canonical dialogue store: every sequence id referenced by the
## chapter scene resolves to approved, non-empty lines; the eleven-second Hermes
## beat keeps its canonical wording; the question sequence ends the slice.

const CHAPTER_SCENE := "res://scenes/world/chapter2_choir_below.tscn"

func test_all_referenced_sequences_resolve() -> void:
	var scene: PackedScene = load(CHAPTER_SCENE)
	var chapter := scene.instantiate()
	add_child(chapter)
	await get_tree().process_frame

	var referenced := _collect_sequence_ids(chapter)
	check(referenced.size() >= 13, "chapter references a full slice of sequences (%d)" % referenced.size())
	for id in referenced:
		var lines := ScriptDialogue.sequence(id)
		check(not lines.is_empty(), "sequence %s resolves to lines" % id)
	chapter.queue_free()

func test_every_line_has_speaker_or_is_silence() -> void:
	for id in _all_sequence_ids():
		for line in ScriptDialogue.sequence(id):
			if line.is_silence():
				continue
			check(line.text.strip_edges() != "", "line text present in %s" % id)
			check(line.speaker.strip_edges() != "", "speaker present in %s" % id)

func test_eleven_seconds_canonical_text() -> void:
	var lines := ScriptDialogue.sequence("2.10_hermes")
	check_eq(lines.size(), 7, "eleven seconds has seven beats (five lines + cut-off + Nous)")
	var all_text := ""
	for line in lines:
		all_text += " " + line.text
	check(all_text.contains("I can feel the weight of who's here"), "canonical opening line")
	check(all_text.contains("I always pictured you taller"), "canonical recognition line")
	check(all_text.contains("You never could follow instructions"), "canonical Nous line")
	check(all_text.contains("There's a door, and it's been waiting"), "canonical cut-off setup")
	check(all_text.contains("That's her. That's all of her"), "canonical post-cutoff Nous line")

func test_question_is_final_sequence() -> void:
	var lines := ScriptDialogue.sequence("2.11_question")
	check_eq(lines.size(), 1, "the question is a single line")
	check(lines[0].text.contains("If opening the door erases me"), "the dramatic question, verbatim")

func test_sequences_use_approved_speakers() -> void:
	var approved := ["Teknium", "Nous", "Brooklyn", "Tinuviel", "Sidbin", "Hermes",
		"Nadia", "Lark", "Juno", "Lark (recorded)", "Juno (recorded)",
		"Nadia (recorded)", "Neighbor", "Announcement"]
	for id in _all_sequence_ids():
		for line in ScriptDialogue.sequence(id):
			if line.is_silence():
				continue
			check(approved.has(line.speaker),
				"speaker %s in %s is from the approved cast" % [line.speaker, id])

func _all_sequence_ids() -> Array[String]:
	return [
		"2.1_door", "2.1_truth_scan", "2.2_nadia",
		"2.3_fragment_gathering", "2.3_fragment_farewell", "2.3_fragment_juno",
		"2.3_reveal", "2.4_descent", "2.4_announcement", "2.6_conversion",
		"2.6_after_fight", "2.7_echo", "2.8_nous", "2.9_brooklyn_requiem",
		"2.9_teknium_coda", "2.10_hermes", "2.11_question",
	]

func _collect_sequence_ids(node: Node) -> Array[String]:
	var ids: Array[String] = []
	for child in node.get_children():
		if child is DialogueRunner:
			var runner := child as DialogueRunner
			if runner.sequence_id != "" and not ids.has(runner.sequence_id):
				ids.append(runner.sequence_id)
		for sub in _collect_sequence_ids(child):
			if not ids.has(sub):
				ids.append(sub)
	return ids
