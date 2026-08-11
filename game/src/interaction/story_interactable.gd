class_name StoryInteractable
extends Interactable
## Scripted interaction beat. Plays approved dialogue lines as subtitles and then
## raises a story beat the scene director (chapter script) reacts to. Canonical
## dialogue comes from game/docs/VERTICAL_SLICE_SCRIPT.md — not placeholder banter.

@export var speaker := ""
@export_multiline var lines: PackedStringArray = []
@export var subtitle_seconds := 3.0
@export var beat_id := ""

func _on_interact(_interactor: Node3D) -> void:
	for line in lines:
		EventBus.subtitle_requested.emit(speaker, line)
		if subtitle_seconds > 0.0:
			await get_tree().create_timer(subtitle_seconds).timeout
	if beat_id != "":
		EventBus.story_beat_triggered.emit(beat_id)
