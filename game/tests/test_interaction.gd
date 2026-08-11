extends TestCase

var _beat_fired := false

func test_interactable_one_shot_consumed() -> void:
	var interactable := Interactable.new()
	add_child(interactable)
	interactable.one_shot = true
	interactable.interact(null)
	check(not interactable.can_interact(null), "one-shot interactable consumed after interact")
	check(not interactable.interactive, "interactive flag cleared")
	interactable.queue_free()

func test_interactable_allows_multiple() -> void:
	var interactable := Interactable.new()
	add_child(interactable)
	interactable.one_shot = false
	interactable.interact(null)
	interactable.interact(null)
	check(interactable.can_interact(null), "non-one-shot interactable stays available")
	interactable.queue_free()

func test_story_interactable_fires_beat() -> void:
	_beat_fired = false
	EventBus.story_beat_triggered.connect(_on_story_beat)
	var story := StoryInteractable.new()
	add_child(story)
	story.lines = PackedStringArray(["hello"])
	story.subtitle_seconds = 0.0
	story.beat_id = "unit_test_beat"
	story.interact(null)
	check(_beat_fired, "story beat fired synchronously after interact")
	EventBus.story_beat_triggered.disconnect(_on_story_beat)
	story.queue_free()

func _on_story_beat(beat_id: String) -> void:
	if beat_id == "unit_test_beat":
		_beat_fired = true
